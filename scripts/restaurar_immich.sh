#!/bin/bash

# --- Configuración ajustable ---
MOUNT_BASE="/mnt/backup"                                  # Directorio base de montaje
BACKUP_DIR="$MOUNT_BASE/immich"                           # Directorio específico de backups
DOCKER_COMPOSE_DIR="/home/mloco/kronos-server/immich-app" # Ruta donde está tu docker-compose.yml
UPLOAD_LOCATION="/mnt/storage/immich/photos"              # Ruta ABSOLUTA de los archivos multimedia
PG_CONTAINER="immich_postgres"                            # Nombre del contenedor PostgreSQL
PG_DB="immich"                                            # Nombre de la base de datos
PG_USER="postgres"                                        # Usuario de PostgreSQL

# --- Verificación de permisos ---
if [ "$(id -u)" != "0" ]; then
    echo "Ejecuta este script con sudo:"
    echo "  sudo $0"
    exit 1
fi

# --- Verificación de disco de backup ---
if ! mountpoint -q "$MOUNT_BASE"; then
    echo "Error: El directorio base de backups ($MOUNT_BASE) no está montado"
    exit 1
fi

set -eo pipefail

# --- Función para reiniciar todos los contenedores de Immich ---
docker_restart() {
    echo -e "\nReiniciando todos los servicios de Immich..."
    (cd "$DOCKER_COMPOSE_DIR" && docker compose up -d)
}

trap 'docker_restart' EXIT

# --- Menú interactivo para seleccionar backup ---
echo -e "\nBackups disponibles en $BACKUP_DIR:"
PS3="Selecciona el número del backup a restaurar (0 para salir): "

select backup_file in "$BACKUP_DIR"/immich_backup_*.tar.gz; do
    if [[ $REPLY -eq 0 ]]; then 
        echo "Saliendo sin restaurar."
        exit 0
    elif [[ -f "$backup_file" ]]; then
        echo -e "\nBackup seleccionado: $(basename "$backup_file")"
        break
    else
        echo "Opción inválida. Intenta nuevamente."
    fi
done

# --- Detener Immich ---
echo "Deteniendo contenedores de Immich..."
(cd "$DOCKER_COMPOSE_DIR" && docker compose down)

# --- Preparar restauración ---
RESTORE_DIR="/tmp/immich_restore_$(date +%s)"
mkdir -p "$RESTORE_DIR"

echo -e "\nExtrayendo backup..."
tar -xzf "$backup_file" -C "$RESTORE_DIR"
BACKUP_CONTENT_DIR=$(find "$RESTORE_DIR" -mindepth 1 -maxdepth 1 -type d)

# --- Preguntar si se eliminan los datos actuales ---
read -p "¿Quieres borrar los datos actuales antes de restaurar? (recomendado para restauración completa) [s/N]: " BORRAR
if [[ "$BORRAR" =~ ^[sS]$ ]]; then
    echo "Eliminando datos actuales..."
    rm -rf "$UPLOAD_LOCATION/library" "$UPLOAD_LOCATION/upload" "$UPLOAD_LOCATION/profile"
fi

# --- Restaurar archivos multimedia ---
echo -e "\nRestaurando archivos multimedia..."
mkdir -p "$UPLOAD_LOCATION"
tar --overwrite --no-same-owner --delay-directory-restore \
    -xzf "$BACKUP_CONTENT_DIR/files.tar.gz" -C "$UPLOAD_LOCATION"

# --- Arrancar sólo la base de datos ---
echo -e "\nLevantando sólo el contenedor de la base de datos para restaurar..."
(cd "$DOCKER_COMPOSE_DIR" && docker compose up -d $PG_CONTAINER)

# --- Esperar a que la base de datos esté lista ---
echo "Esperando que el contenedor de la base de datos esté listo..."
for i in {1..30}; do
    if docker exec $PG_CONTAINER pg_isready -U $PG_USER -d postgres >/dev/null 2>&1; then
        echo "Base de datos lista."
        break
    else
        sleep 2
    fi
    if [[ $i -eq 30 ]]; then
        echo "La base de datos no está lista después de 60 segundos. Abortando."
        exit 1
    fi
done

# --- Eliminar y recrear la base de datos antes de restaurar ---
echo "Eliminando base de datos PostgreSQL actual ($PG_DB)..."
docker exec -i $PG_CONTAINER dropdb $PG_DB -U $PG_USER || true
echo "Creando base de datos PostgreSQL vacía ($PG_DB)..."
docker exec -i $PG_CONTAINER createdb $PG_DB -U $PG_USER

# --- Restaurar base de datos ---
echo "Restaurando base de datos..."
gunzip -c "$BACKUP_CONTENT_DIR/db.sql.gz" | docker exec -i $PG_CONTAINER psql -U $PG_USER -d $PG_DB

# --- Limpieza final ---
echo -e "\nLimpiando temporales..."
rm -rf "$RESTORE_DIR"

echo -e "\n✅ Restauración completada exitosamente!"

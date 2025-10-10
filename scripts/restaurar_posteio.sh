#!/bin/bash

# --- Configuración ---
MOUNT_BASE="/mnt/backup"                               # Directorio base de montaje
BACKUP_DIR="$MOUNT_BASE/posteio"                       # Directorio específico de backups
DOCKER_COMPOSE_DIR="/home/mloco/kronos-server/postie"   # Ruta del docker-compose
POSTE_DATA="/mnt/mail"                                 # Directorio de datos de Poste.io
CONTAINER_NAME="postie"                                # Nombre del contenedor

# --- Verificar ejecución como root ---
if [ "$(id -u)" != "0" ]; then
    echo "Ejecuta este script con sudo:"
    echo "  sudo $0"
    exit 1
fi

# Verificar si el disco de backup está montado
if ! mountpoint -q "$MOUNT_BASE"; then
    echo "Error: El directorio base de backups ($MOUNT_BASE) no está montado"
    exit 1
fi

set -eo pipefail

# --- Función para reiniciar el contenedor de Poste.io ---
docker_restart() {
    echo -e "\nReiniciando el servicio de Poste.io..."
    (cd "$DOCKER_COMPOSE_DIR" && docker compose up -d)
}

trap 'docker_restart' EXIT

# --- Menú interactivo para seleccionar backup ---
echo -e "\nBackups disponibles en $BACKUP_DIR:"
PS3="Selecciona el número del backup a restaurar (0 para salir): "

select backup_file in "$BACKUP_DIR"/posteio_backup_*.tar.gz; do
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

# --- Detener Poste.io ---
echo "Deteniendo contenedor de Poste.io..."
(cd "$DOCKER_COMPOSE_DIR" && docker compose down)

# --- Preparar restauración ---
RESTORE_DIR="/tmp/posteio_restore_$(date +%s)"
mkdir -p "$RESTORE_DIR"

echo -e "\nExtrayendo backup..."
# Extraer el backup y guardar el nombre del directorio extraído
tar -xzf "$backup_file" -C "$RESTORE_DIR"
BACKUP_NAME=$(basename "$backup_file" .tar.gz)

# --- Preguntar si se eliminan los datos actuales ---
read -p "¿Quieres borrar los datos actuales antes de restaurar? (recomendado para restauración completa) [s/N]: " BORRAR
if [[ "$BORRAR" =~ ^[sS]$ ]]; then
    echo "Eliminando datos actuales..."
    rm -rf "${POSTE_DATA:?}"/*
fi

# --- Restaurar datos ---
echo -e "\nRestaurando datos de Poste.io..."
mkdir -p "$POSTE_DATA"

# Encontrar y extraer el archivo mail_data.tar.gz
if [ -f "$RESTORE_DIR/$BACKUP_NAME/mail_data.tar.gz" ]; then
    echo "Extrayendo datos del correo..."
    tar -xzf "$RESTORE_DIR/$BACKUP_NAME/mail_data.tar.gz" -C /mnt
else
    echo "❌ Error: No se encontró el archivo mail_data.tar.gz en el backup"
    exit 1
fi

# Restaurar archivos de configuración
echo "Restaurando archivos de configuración..."
if [ -f "$RESTORE_DIR/$BACKUP_NAME/docker-compose.yml" ]; then
    cp "$RESTORE_DIR/$BACKUP_NAME/docker-compose.yml" "$DOCKER_COMPOSE_DIR/" && echo "✅ docker-compose.yml restaurado"
fi
if [ -f "$RESTORE_DIR/$BACKUP_NAME/.env" ]; then
    cp "$RESTORE_DIR/$BACKUP_NAME/.env" "$DOCKER_COMPOSE_DIR/" && echo "✅ .env restaurado"
fi

# Ajustar permisos
echo "Ajustando permisos..."
chown -R 991:991 "$POSTE_DATA"  # 991 es el UID/GID del usuario dentro del contenedor poste.io

# --- Limpieza final ---
echo -e "\nLimpiando temporales..."
rm -rf "$RESTORE_DIR"

echo -e "\n✅ Restauración completada exitosamente!"
echo "El servicio de Poste.io se reiniciará automáticamente..."

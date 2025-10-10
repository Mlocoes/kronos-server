#!/bin/bash

# --- Configuración ajustable ---
BACKUP_DIR="/mnt/backup/immich"                           # Directorio donde se guardarán los backups
DOCKER_COMPOSE_DIR="/home/mloco/kronos-server/immich-app" # Ruta donde está tu docker-compose.yml
UPLOAD_LOCATION="/mnt/storage/immich/photos"              # Ruta ABSOLUTA en el host de tus archivos Immich
PG_CONTAINER="immich_postgres"                            # Nombre de tu contenedor PostgreSQL
PG_DB="immich"                                            # Nombre de la base de datos
PG_USER="postgres"                                        # Usuario de PostgreSQL
PG_PASSWORD="postgres"                                    # Contraseña de PostgreSQL
MIN_SPACE_GB=100                                          # Espacio mínimo requerido en GB
RETENTION_DAYS=3					  # Dias de backup

# --- Verificación de permisos ---
if [ "$EUID" -ne 0 ]; then 
    echo "Este script necesita ejecutarse con privilegios de root"
    echo "Por favor, ejecutar como: sudo $0"
    exit 1
fi

# --- Función para verificar espacio ---
check_space() {
    local available_space
    available_space=$(df -BG "$BACKUP_DIR" | awk 'NR==2 {gsub("G","",$4); print $4}')

    if [ "$available_space" -lt "$MIN_SPACE_GB" ]; then
        echo "ERROR: Espacio insuficiente en $BACKUP_DIR ($available_space GB disponibles, mínimo requerido: $MIN_SPACE_GB GB)"
        return 1
    fi
    return 0
}

# --- Verificación de disco de backup ---
if ! mountpoint -q /mnt/backup; then
    echo "Error: El directorio /mnt/backup no está montado"
    exit 1
fi

# --- Variables generadas ---
TIMESTAMP=$(date +'%Y%m%d-%H%M%S')
BACKUP_NAME="immich_backup_$TIMESTAMP"
TEMP_DIR="$BACKUP_DIR/$BACKUP_NAME"

# --- Verificaciones preliminares ---
# Verificar si existe el directorio de origen
if [ ! -d "$UPLOAD_LOCATION" ]; then
    echo "Error: El directorio de origen $UPLOAD_LOCATION no existe"
    exit 1
fi

# Verificar si el contenedor PostgreSQL está ejecutándose
if ! docker ps | grep -q $PG_CONTAINER; then
    echo "Error: El contenedor PostgreSQL ($PG_CONTAINER) no está en ejecución"
    exit 1
fi

# Verificar espacio disponible
if ! check_space; then
    exit 1
fi

# Crear directorio temporal para el backup
mkdir -p "$TEMP_DIR"

# --- 1. Backup de archivos multimedia ---
echo "1. Creando backup de archivos multimedia..."
tar -czf "$TEMP_DIR/files.tar.gz" \
    -C "$UPLOAD_LOCATION" \
    library \
    upload \
    profile \
    || { echo "❌ Error: Fallo al hacer backup de archivos multimedia"; exit 1; }

# --- 2. Backup de la base de datos PostgreSQL ---
echo "2. Creando backup de la base de datos..."
if docker exec $PG_CONTAINER pg_dump -U $PG_USER -d $PG_DB | gzip > "$TEMP_DIR/db.sql.gz"; then
    echo "✅ Backup de base de datos completado"
else
    echo "❌ Error: Fallo al hacer backup de la base de datos"
    exit 1
fi

# --- 3. Copia de archivos de configuración ---
echo "3. Copiando archivos de configuración..."
cp "$DOCKER_COMPOSE_DIR/docker-compose.yml" "$TEMP_DIR/" 2>/dev/null || echo "⚠️  docker-compose.yml no encontrado, omitiendo"
cp "$DOCKER_COMPOSE_DIR/.env" "$TEMP_DIR/" 2>/dev/null || echo "⚠️  .env no encontrado, omitiendo"
cp "$DOCKER_COMPOSE_DIR/hwaccel.ml.yml" "$TEMP_DIR/" 2>/dev/null || echo "⚠️  hwaccel.ml.yml no encontrado, omitiendo"
cp "$DOCKER_COMPOSE_DIR/hwaccel.transcoding.yml" "$TEMP_DIR/" 2>/dev/null || echo "⚠️  hwaccel.transcoding.yml no encontrado, omitiendo"

# --- 4. Comprimir todo el backup ---
echo "4. Comprimiendo backup final..."
tar -czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" -C "$BACKUP_DIR" "$BACKUP_NAME" \
    || { echo "❌ Error: Fallo al comprimir el backup final"; exit 1; }

# --- 5. Limpiar temporales ---
echo "5. Limpiando archivos temporales..."
rm -rf "$TEMP_DIR"

# --- 6. Eliminar backups antiguos ---
echo "6. Eliminando backups antiguos (más de $RETENTION_DAYS días)..."
find "$BACKUP_DIR" -name "immich_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

# --- Verificar y mostrar resultado ---
if [ -f "$BACKUP_DIR/$BACKUP_NAME.tar.gz" ]; then
    echo -e "\n✅ Backup completado exitosamente"
    echo "📁 Ubicación: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
    echo "📦 Tamaño: $(du -h "$BACKUP_DIR/$BACKUP_NAME.tar.gz" | cut -f1)"
    echo "🗑️ Backups antiguos eliminados: > $RETENTION_DAYS días"
else
    echo "❌ Error: El backup falló"
    exit 1
fi

#!/bin/bash

# --- Configuración ajustable ---
MOUNT_BASE="/mnt/backup"                                # Directorio base de montaje
BACKUP_DIR="$MOUNT_BASE/posteio"                        # Directorio específico de backups
DOCKER_COMPOSE_DIR="/home/mloco/kronos-server/postie"   # Ruta donde está tu docker-compose.yml
SOURCE_DIR="/mnt/mail"                                  # Ruta ABSOLUTA de los datos de Poste.io
CONTAINER_NAME="postie"                                 # Nombre del contenedor de Poste.io
RETENTION_DAYS=3					# Dias de backup

# --- Verificación de permisos ---
if [ "$EUID" -ne 0 ]; then 
    echo "Este script necesita ejecutarse con privilegios de root"
    echo "Por favor, ejecutar como: sudo $0"
    exit 1
fi

# --- Verificación de disco de backup ---
if ! mountpoint -q "$MOUNT_BASE"; then
    echo "Error: El directorio base de backups ($MOUNT_BASE) no está montado"
    exit 1
fi

# --- Variables generadas ---
TIMESTAMP=$(date +'%Y%m%d-%H%M%S')
BACKUP_NAME="posteio_backup_$TIMESTAMP"
TEMP_DIR="$BACKUP_DIR/$BACKUP_NAME"

# --- Verificaciones preliminares ---
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: El directorio de origen $SOURCE_DIR no existe"
    exit 1
fi

# Crear directorio temporal para el backup
mkdir -p "$TEMP_DIR"

# --- 1. Backup de los datos de correo ---
echo "1. Creando backup de los datos de correo..."
tar -czf "$TEMP_DIR/mail_data.tar.gz" -C "$(dirname $SOURCE_DIR)" "$(basename $SOURCE_DIR)"

# --- 2. (Opcional) Copia del docker-compose.yml y .env ---
echo "2. Copiando archivos de configuración..."
cp "$DOCKER_COMPOSE_DIR/docker-compose.yml" "$TEMP_DIR/" 2>/dev/null || echo "docker-compose.yml no encontrado, omitiendo"
cp "$DOCKER_COMPOSE_DIR/.env" "$TEMP_DIR/" 2>/dev/null || echo ".env no encontrado, omitiendo"

# --- 3. Comprimir todo el backup ---
echo "3. Comprimiendo backup final..."
tar -czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" -C "$BACKUP_DIR" "$BACKUP_NAME"

# --- 4. Limpiar temporales ---
echo "4. Limpiando archivos temporales..."
rm -rf "$TEMP_DIR"

# --- 5. Eliminar backups antiguos ---
echo "5. Eliminando backups antiguos (más de $RETENTION_DAYS días)..."
find "$BACKUP_DIR" -name "posteio_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

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

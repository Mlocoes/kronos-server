#!/bin/bash

# --- Configuración ajustable ---
#KRONOS_ROOT="$(cd "$(dirname "$0")/.." && pwd)"  # Directorio raíz de Kronos
SOURCE_DIR="/home/mloco/kronos-server"            # Directorio a respaldar
BACKUP_DIR="/mnt/backup/kronos"                   # Directorio de backups
MIN_SPACE_GB=20                                   # Espacio mínimo requerido en GB
RETENTION_DAYS=3				  # Dias de backup

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

# --- Verificación del directorio de backups ---
mkdir -p "$BACKUP_DIR"

# Verificar que podemos escribir en el directorio de backups
if [ ! -w "$BACKUP_DIR" ]; then
    echo "Error: No se puede escribir en el directorio de backups ($BACKUP_DIR)"
    exit 1
fi

# Verificar espacio disponible
if ! check_space; then
    exit 1
fi

# --- Variables generadas ---
TIMESTAMP=$(date +'%Y%m%d-%H%M%S')
BACKUP_NAME="kronos_backup_$TIMESTAMP"
TEMP_DIR="$BACKUP_DIR/$BACKUP_NAME"

# --- Verificaciones preliminares ---
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: El directorio de origen $SOURCE_DIR no existe"
    exit 1
fi

# Crear directorio temporal para el backup
mkdir -p "$TEMP_DIR"

# --- 1. Crear el backup completo del sistema ---
echo "1. Creando backup completo del servidor..."

# Creamos el directorio temporal y copiamos todo el contenido manteniendo la estructura
cd "$(dirname "$SOURCE_DIR")" || exit 1
tar -czf "$TEMP_DIR/kronos-server.tar.gz" \
    --exclude="*/backups/*" \
    --exclude="*.log" \
    --exclude="*/.git/*" \
    "$(basename "$SOURCE_DIR")" || {
    echo "❌ Error: Fallo al crear el backup"
    exit 1
}

# --- 4. Crear archivo de metadatos ---
echo "4. Guardando metadatos del backup..."
cat > "$TEMP_DIR/metadata.txt" << EOF
Fecha de backup: $(date)
Hostname: $(hostname)
Usuario: $(whoami)
Versión del sistema: $(uname -a)
Espacio total en disco: $(df -h "$SOURCE_DIR" | tail -1)
EOF

# --- 5. Comprimir todo el backup ---
echo "5. Comprimiendo backup final..."
tar -czf "$BACKUP_DIR/$BACKUP_NAME.tar.gz" -C "$BACKUP_DIR" "$BACKUP_NAME" \
    || { echo "❌ Error: Fallo al comprimir el backup final"; exit 1; }

# --- 6. Limpiar temporales ---
echo "6. Limpiando archivos temporales..."
rm -rf "$TEMP_DIR"

# --- 7. Eliminar backups antiguos ---
echo "7. Eliminando backups antiguos (más de $RETENTION_DAYS días)..."
find "$BACKUP_DIR" -name "kronos_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

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

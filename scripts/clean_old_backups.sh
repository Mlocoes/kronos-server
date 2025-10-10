#!/bin/bash

# Script para limpiar backups antiguos basado en políticas de retención
# Retención:
# - Diario: 7 días
# - Semanal: 4 semanas
# - Mensual: 12 meses
# - Anual: 2 años

# Configuración
BACKUP_ROOT="/mnt/backup"
LOG_FILE="/var/log/kronos/backup.log"
EMAIL_CONF="/home/mloco/kronos-server/scripts/email.conf"

# Espacio mínimo requerido (en GB)
MIN_SPACE_GB=50

# Servicios con backups
SERVICES=("kronos" "immich" "postie")

# Función para verificar espacio
check_space() {
    local available_space
    available_space=$(df -BG "$BACKUP_ROOT" | awk 'NR==2 {gsub("G","",$4); print $4}')
    
    if [ "$available_space" -lt "$MIN_SPACE_GB" ]; then
        log "ERROR: Espacio insuficiente en $BACKUP_ROOT ($available_space GB disponibles, mínimo requerido: $MIN_SPACE_GB GB)"
        notify "Espacio insuficiente en disco: $available_space GB disponibles" "Error"
        return 1
    fi
    return 0
}

# Función para logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Función para enviar notificaciones
notify() {
    if [ -f "$EMAIL_CONF" ]; then
        source "$EMAIL_CONF"
        echo "$1" | mail -s "Kronos Backup Cleanup: $2" "$NOTIFY_EMAIL"
    fi
}

# Función para limpiar backups por servicio y política
clean_backups() {
    local service=$1
    local backup_path="$BACKUP_ROOT/$service"
    local error_count=0
    
    if [ ! -d "$backup_path" ]; then
        log "ERROR: Directorio de backup no encontrado: $backup_path"
        return 1
    }

    # Verificar permisos
    if [ ! -w "$backup_path" ]; then
        log "ERROR: Sin permisos de escritura en: $backup_path"
        return 1
    }

    # Crear directorio temporal para verificación
    local test_dir="$backup_path/test_$$"
    if ! mkdir "$test_dir" 2>/dev/null; then
        log "ERROR: No se puede crear directorio de prueba en: $backup_path"
        return 1
    fi
    rmdir "$test_dir"

    # Eliminar backups diarios más antiguos que 7 días
    # (excepto el primer día de cada semana)
    log "Limpiando backups diarios antiguos de $service..."
    find "$backup_path" -maxdepth 1 -type d -name "20*" -mtime +7 \
        ! -name "*-01" ! -name "*-08" ! -name "*-15" ! -name "*-22" ! -name "*-29" \
        -exec sh -c 'rm -rf "{}" || echo "Error al eliminar: {}"' \;

    # Mantener solo 4 backups semanales
    # (eliminar backups semanales más antiguos que 4 semanas)
    log "Limpiando backups semanales antiguos de $service..."
    for week in $(find "$backup_path" -maxdepth 1 -type d -name "*-01" -o -name "*-08" -o -name "*-15" -o -name "*-22" -o -name "*-29" | sort -r | tail -n +5); do
        rm -rf "$week"
    done

    # Mantener solo 12 backups mensuales
    # (primer día de cada mes)
    log "Limpiando backups mensuales antiguos de $service..."
    for month in $(find "$backup_path" -maxdepth 1 -type d -name "*-01" | sort -r | tail -n +13); do
        rm -rf "$month"
    done

    # Mantener solo 2 años de backups anuales
    # (primer día del año)
    log "Limpiando backups anuales antiguos de $service..."
    for year in $(find "$backup_path" -maxdepth 1 -type d -name "*-01-01" | sort -r | tail -n +3); do
        rm -rf "$year"
    done
}

# Inicio del script
log "Iniciando limpieza de backups antiguos..."
notify "Iniciando limpieza de backups antiguos" "Inicio"

# Verificar espacio y punto de montaje
if ! mountpoint -q "$BACKUP_ROOT"; then
    log "ERROR: $BACKUP_ROOT no está montado"
    notify "Error: Sistema de archivos de backup no está montado" "Error Crítico"
    exit 1
fi

if ! check_space; then
    exit 1
fi

# Verificar espacio antes
SPACE_BEFORE=$(df -h "$BACKUP_ROOT" | awk 'NR==2 {print $4}')

# Procesar cada servicio
for service in "${SERVICES[@]}"; do
    log "Procesando backups de $service..."
    clean_backups "$service"
    if [ $? -ne 0 ]; then
        notify "Error al limpiar backups de $service" "Error"
    fi
done

# Verificar espacio después
SPACE_AFTER=$(df -h "$BACKUP_ROOT" | awk 'NR==2 {print $4}')

# Resumen
SUMMARY="Limpieza completada\n"
SUMMARY+="Espacio antes: $SPACE_BEFORE\n"
SUMMARY+="Espacio después: $SPACE_AFTER"

log "$SUMMARY"
notify "$SUMMARY" "Completado"

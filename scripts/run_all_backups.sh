#!/bin/bash

# --- Configuración ---
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="/var/log/kronos/backups"
DATE=$(date '+%Y%m%d-%H%M%S')
LOG_FILE="$LOG_DIR/backup_$DATE.log"
BACKUP_ROOT="/mnt/backup"
EMAIL_CONF="/home/mloco/kronos-server/scripts/email.conf"

# Asegurar que el directorio de logs existe
mkdir -p "$LOG_DIR"

# Función para notificaciones por correo
notify() {
    if [ -f "$EMAIL_CONF" ]; then 
        source "$EMAIL_CONF"
        echo "$1" | mail -s "Kronos Backup: $2" "$NOTIFY_EMAIL"
    fi
}

# Función para verificar espacio disponible
check_backup_space() {
    if ! mountpoint -q "$BACKUP_ROOT"; then
        echo "ERROR: $BACKUP_ROOT no está montado" | tee -a "$LOG_FILE"
        notify "Error: Sistema de archivos de backup no está montado" "Error Crítico"
        return 1
    fi

    local available_space total_space used_percent
    available_space=$(df -h "$BACKUP_ROOT" | awk 'NR==2 {print $4}')
    total_space=$(df -h "$BACKUP_ROOT" | awk 'NR==2 {print $2}')
    used_percent=$(df -h "$BACKUP_ROOT" | awk 'NR==2 {print $5}')

    echo "Estado del almacenamiento de backup:" | tee -a "$LOG_FILE"
    echo "- Espacio total: $total_space" | tee -a "$LOG_FILE"
    echo "- Espacio disponible: $available_space" | tee -a "$LOG_FILE"
    echo "- Uso actual: $used_percent" | tee -a "$LOG_FILE"

    if [[ "${used_percent%\%}" -gt 90 ]]; then
        echo "ADVERTENCIA: Espacio crítico en disco de backup" | tee -a "$LOG_FILE"
        notify "Espacio crítico en disco de backup: $used_percent usado" "Advertencia"
    fi
}

# Función para ejecutar un backup y registrar su salida
run_backup() {
    local script=$1
    echo "🔄 Ejecutando $script..." | tee -a "$LOG_FILE"
    if sudo "$SCRIPTS_DIR/$script" >> "$LOG_FILE" 2>&1; then
        echo "✅ $script completado exitosamente" | tee -a "$LOG_FILE"
        return 0
    else
        echo "❌ Error en $script" | tee -a "$LOG_FILE"
        return 1
    fi
}

# Iniciar el log
echo "=== Inicio de backups automáticos $(date) ===" > "$LOG_FILE"

# Verificar espacio antes de comenzar
check_backup_space
if [ $? -ne 0 ]; then
    echo "ERROR: Verificación de espacio fallida" | tee -a "$LOG_FILE"
    notify "Verificación de espacio fallida - Backups cancelados" "Error Crítico"
    exit 1
fi

# Ejecutar todos los backups
FAILED_BACKUPS=0

run_backup "backup_kronos.sh" || ((FAILED_BACKUPS++))
run_backup "backup_immich.sh" || ((FAILED_BACKUPS++))
run_backup "backup_posteio.sh" || ((FAILED_BACKUPS++))

# Verificar espacio después de los backups
check_backup_space

# Rotar logs antiguos (mantener últimos 30 días)
find "$LOG_DIR" -name "backup_*.log" -type f -mtime +30 -delete

# Generar resumen final
SUMMARY="=== Resumen de backups $(date) ===\n"
SUMMARY+="Total de backups ejecutados: 3\n"
SUMMARY+="Backups fallidos: $FAILED_BACKUPS\n"
if [ $FAILED_BACKUPS -eq 0 ]; then
    SUMMARY+="Estado: ✅ Todos los backups completados exitosamente\n"
    NOTIFY_SUBJECT="Backups Completados"
else
    SUMMARY+="Estado: ⚠️ Algunos backups fallaron\n"
    NOTIFY_SUBJECT="Backups con Errores"
fi

echo -e "$SUMMARY" >> "$LOG_FILE"
echo "=== Fin de backups automáticos $(date) ===" >> "$LOG_FILE"

# Enviar notificación por correo
notify "$SUMMARY" "$NOTIFY_SUBJECT"

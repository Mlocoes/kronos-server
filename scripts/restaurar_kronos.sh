#!/bin/bash

# --- Configuración basada en el script de backup ---
DEFAULT_RESTORE_DIR="/home/mloco/kronos-server"  # Directorio de destino por defecto
BACKUP_DIR="/mnt/backup/kronos"                         # Directorio de backups
TEMP_DIR="/tmp/kronos_restore_$(date +%s)"
SELECTED_BACKUP=""
RESTORE_DIR=""

# --- Verificación de permisos ---
if [ "$EUID" -ne 0 ]; then
    echo "Este script necesita ejecutarse con privilegios de root"
    echo "Por favor, ejecutar como: sudo $0"
    exit 1
fi

# --- Funciones del menú ---
select_backup() {
    # Corrección SC2207: Usar mapfile para evitar splitting
    mapfile -t backups < <(find "$BACKUP_DIR" -name "kronos_backup_*.tar.gz" -printf "%f\n" | sort -r)
    
    if [ "${#backups[@]}" -eq 0 ]; then
        echo "❌ No se encontraron backups disponibles"
        return 1
    fi
    
    PS3="Seleccione un backup (1-${#backups[@]}): "
    select backup in "${backups[@]}"; do
        if [ -n "$backup" ]; then
            SELECTED_BACKUP="$BACKUP_DIR/$backup"
            echo "✅ Backup seleccionado: $backup"
            return 0
        else
            echo "❌ Selección inválida"
            return 1
        fi
    done
}

select_destination() {
    read -r -p "Ingrese directorio destino [$DEFAULT_RESTORE_DIR]: " dir
    RESTORE_DIR="${dir:-$DEFAULT_RESTORE_DIR}"
    
    mkdir -p "$RESTORE_DIR" || {
        echo "❌ No se pudo crear el directorio destino"
        return 1
    }
    
    echo "✅ Directorio destino: $RESTORE_DIR"
}

extract_backup() {
    # Validaciones iniciales
    if [ -z "$SELECTED_BACKUP" ]; then
        echo "❌ Primero seleccione un backup"
        return 1
    fi

    if [ -z "$RESTORE_DIR" ]; then
        echo "❌ Primero seleccione el directorio destino"
        return 1
    fi

    echo "📦 Preparando restauración del backup..."
    
    # Limpiar y crear directorio temporal
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR" 2>/dev/null
    fi
    
    if ! mkdir -p "$TEMP_DIR"; then
        echo "❌ Error al crear directorio temporal"
        return 1
    fi
    
    echo "📦 Restaurando el sistema..."
    # Ya no necesitamos parent_dir aquí, restauramos directamente en RESTORE_DIR
    
    # Primero extraemos el backup al directorio temporal
    echo "📦 Extrayendo el archivo principal..."
    cd "$TEMP_DIR" || exit 1
    
    # Extraer el backup principal
    if ! tar -xzf "$SELECTED_BACKUP"; then
        echo "❌ Error al extraer el backup principal"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # Encontrar y extraer kronos-server.tar.gz
    BACKUP_INNER=$(find . -name "kronos-server.tar.gz" -type f)
    if [ -z "$BACKUP_INNER" ]; then
        echo "❌ Error: No se encontró el archivo kronos-server.tar.gz"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    echo "📦 Restaurando en el directorio destino..."
    if ! tar -xzf "$BACKUP_INNER" -C "$RESTORE_DIR" --strip-components=1; then
        echo "❌ Error al restaurar el sistema"
        rm -rf "$TEMP_DIR"
        return 1
    fi

    # Corregir permisos del directorio restaurado
    echo "🔒 Corrigiendo permisos..."
    # Obtener el usuario no-root que ejecutó sudo
    REAL_USER=$(logname || echo "${SUDO_USER:-$USER}")
    REAL_GROUP=$(id -gn "$REAL_USER")
    
    if ! chown -R "$REAL_USER:$REAL_GROUP" "$RESTORE_DIR"; then
        echo "⚠️ Advertencia: No se pudieron corregir todos los permisos"
    fi
    
    # Asegurar que los scripts sean ejecutables
    find "$RESTORE_DIR" -type f -name "*.sh" -exec chmod +x {} \;

    # Limpiar
    rm -rf "$TEMP_DIR"
    
    echo "✅ Sistema restaurado exitosamente en: $RESTORE_DIR"
}

# --- Menú interactivo ---
while true; do
    clear
    echo "🛠️  Restauración de Kronos"
    echo "-------------------------------------"
    [ -n "$SELECTED_BACKUP" ] && echo "Backup actual: $(basename "$SELECTED_BACKUP")"
    [ -n "$RESTORE_DIR" ] && echo "Directorio destino: $RESTORE_DIR"
    echo "-------------------------------------"
    
    PS3="Seleccione una opción: "
    options=(
        "Selección de backup"
        "Selección de directorio destino"
        "Extraer y restaurar backup"
        "Salir"
    )
    
    # shellcheck disable=SC2034
    select opt in "${options[@]}"; do
        case $REPLY in
            1) select_backup; break ;;
            2) select_destination; break ;;
            3) extract_backup; break ;;
            4) exit 0 ;;
            *) echo "❌ Opción inválida"; break ;;
        esac
    done
done

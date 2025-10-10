#!/bin/bash

# ============================================================================
# KRONOS SERVER - SCRIPT DE VERIFICACIÓN DE ACTUALIZACIONES
# ============================================================================
# Este script verifica si hay actualizaciones disponibles para las imágenes
# Docker sin aplicarlas, permitiendo al usuario decidir si actualizar.
#
# Uso: ./check-updates.sh
# ============================================================================

BASE_DIR="/home/mloco/kronos-server"
LOG_FILE="/home/mloco/kronos-server/check-updates-$(date +%Y%m%d-%H%M%S).log"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

check_service_updates() {
    local service_dir=$1
    local service_name=$2

    log "${BLUE}🔍 Verificando actualizaciones para $service_name...${NC}"

    if [ ! -d "$BASE_DIR/$service_dir" ]; then
        log "${YELLOW}⚠️  Directorio $service_dir no encontrado${NC}"
        return
    fi

    cd "$BASE_DIR/$service_dir" || return

    if [ ! -f "docker-compose.yml" ]; then
        log "${YELLOW}⚠️  docker-compose.yml no encontrado en $service_dir${NC}"
        return
    fi

    # Verificar actualizaciones disponibles
    if docker-compose pull --dry-run 2>/dev/null | grep -q "Downloaded"; then
        log "${YELLOW}📦 Actualización disponible para $service_name${NC}"
    else
        log "${GREEN}✅ $service_name está actualizado${NC}"
    fi
}

main() {
    log "${BLUE}🔍 VERIFICANDO ACTUALIZACIONES DISPONIBLES${NC}"
    log "Log file: $LOG_FILE"
    log "================================================================"

    services=(
        "pihole:pihole"
        "traefik:traefik"
        "portainer:portainer"
        "plex:plex"
        "transmission:transmission"
        "flexget:flexget"
        "immich-app:immich_server"
        "AlugueV3:alugueis_backend"
    )

    for service_info in "${services[@]}"; do
        IFS=':' read -r service_dir service_name <<< "$service_info"
        check_service_updates "$service_dir" "$service_name"
        sleep 1
    done

    log "================================================================"
    log "${GREEN}✅ Verificación completada. Revisa el log para detalles.${NC}"
    log "Para aplicar actualizaciones, ejecuta: ./update-all.sh"
}

main "$@"
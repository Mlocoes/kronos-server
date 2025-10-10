#!/bin/bash

# ============================================================================
# KRONOS SERVER - SCRIPT DE ACTUALIZACIÓN DE TODOS LOS SERVICIOS DOCKER
# ============================================================================
# Este script actualiza todas las imágenes Docker y reinicia los servicios
# en el orden correcto para mantener la estabilidad del sistema.
#
# Servicios actualizados:
# - Pi-hole (DNS)
# - Traefik (Proxy Reverso)
# - Portainer (Gestión Docker)
# - Plex (Media Server)
# - Transmission (Torrents)
# - Flexget (Automatización)
# - Immich (Fotos)
# - AlugueV3 (Sistema de Aluguéis)
#
# ============================================================================

# Configuración
LOG_FILE="/home/mloco/kronos-server/update-$(date +%Y%m%d-%H%M%S).log"
BASE_DIR="/home/mloco/kronos-server"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función de logging
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Función para verificar si un servicio está saludable
check_service_health() {
    local service_name=$1
    local max_attempts=30
    local attempt=1

    log "Verificando salud de $service_name..."

    while [ $attempt -le $max_attempts ]; do
        if docker ps --filter "name=$service_name" --filter "status=running" | grep -q "$service_name"; then
            log "${GREEN}✅ $service_name está ejecutándose correctamente${NC}"
            return 0
        fi

        log "Intento $attempt/$max_attempts: $service_name aún no está listo..."
        sleep 10
        ((attempt++))
    done

    log "${RED}❌ ERROR: $service_name no se inició correctamente después de $max_attempts intentos${NC}"
    return 1
}

# Función para actualizar un servicio
update_service() {
    local service_dir=$1
    local service_name=$2

    log "${BLUE}🔄 Actualizando $service_name...${NC}"

    # Verificar que el directorio existe
    if [ ! -d "$BASE_DIR/$service_dir" ]; then
        log "${YELLOW}⚠️  ADVERTENCIA: Directorio $service_dir no encontrado, saltando...${NC}"
        return 0
    fi

    cd "$BASE_DIR/$service_dir" || {
        log "${RED}❌ ERROR: No se pudo acceder al directorio $service_dir${NC}"
        return 1
    }

    # Verificar que existe docker-compose.yml
    if [ ! -f "docker-compose.yml" ]; then
        log "${YELLOW}⚠️  ADVERTENCIA: docker-compose.yml no encontrado en $service_dir, saltando...${NC}"
        return 0
    fi

    # Detener el servicio
    log "Deteniendo $service_name..."
    docker-compose down || {
        log "${YELLOW}⚠️  ADVERTENCIA: Error al detener $service_name, continuando...${NC}"
    }

    # Actualizar imágenes
    log "Descargando nuevas imágenes para $service_name..."
    docker-compose pull || {
        log "${RED}❌ ERROR: Falló la descarga de imágenes para $service_name${NC}"
        return 1
    }

    # Iniciar el servicio
    log "Iniciando $service_name con imágenes actualizadas..."
    docker-compose up -d || {
        log "${RED}❌ ERROR: Falló el inicio de $service_name${NC}"
        return 1
    }

    # Verificar salud del servicio
    check_service_health "$service_name" || return 1

    log "${GREEN}✅ $service_name actualizado exitosamente${NC}"
    return 0
}

# Función principal
main() {
    log "${BLUE}🚀 INICIANDO ACTUALIZACIÓN COMPLETA DE KRONOS SERVER${NC}"
    log "Log file: $LOG_FILE"
    log "Base directory: $BASE_DIR"
    log "================================================================"

    # Lista de servicios a actualizar (en orden de importancia)
    # Formato: "directorio:container_name"
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

    local total_services=${#services[@]}
    local updated=0
    local failed=0

    log "Actualizando $total_services servicios..."

    # Actualizar cada servicio
    for service_info in "${services[@]}"; do
        IFS=':' read -r service_dir service_name <<< "$service_info"

        if update_service "$service_dir" "$service_name"; then
            ((updated++))
        else
            ((failed++))
            log "${RED}❌ Falló la actualización de $service_name${NC}"
        fi

        # Pequeña pausa entre servicios
        sleep 2
    done

    # Resumen final
    log "================================================================"
    log "${BLUE}📊 RESUMEN DE ACTUALIZACIÓN${NC}"
    log "Total de servicios: $total_services"
    log "Actualizados exitosamente: $updated"
    log "Fallidos: $failed"
    log "================================================================"

    if [ $failed -eq 0 ]; then
        log "${GREEN}🎉 ¡ACTUALIZACIÓN COMPLETA EXITOSA!${NC}"
        log "Todos los servicios han sido actualizados y están funcionando correctamente."
        exit 0
    else
        log "${RED}⚠️  ACTUALIZACIÓN COMPLETADA CON ERRORES${NC}"
        log "$failed servicios fallaron. Revisa el log para más detalles."
        exit 1
    fi
}

# Verificar que estamos en el directorio correcto
if [ ! -d "$BASE_DIR" ]; then
    echo -e "${RED}ERROR: Directorio base $BASE_DIR no encontrado${NC}"
    exit 1
fi

# Verificar que Docker está ejecutándose
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}ERROR: Docker no está ejecutándose${NC}"
    exit 1
fi

# Ejecutar la función principal
main "$@"
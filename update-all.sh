#!/bin/bash

# ============================================================================
# KRONOS SERVER - SCRIPT DE ACTUALIZACIÓN DE TODOS LOS SERVICIOS DOCKER
# ============================================================================
# Este script actualiza todas las imágenes Docker y reinicia los servicios
# respetando el ORDEN DE DEPENDENCIAS definido en start-all.sh para mantener
# la estabilidad del sistema. Primero descarga imágenes con el DNS todavía
# disponible y después reinicia cada servicio en orden.
#
# Secuencia de actualización (orden crítico):
# 1. Networks - Red compartida (172.20.0.0/16)
# 2. Pi-hole - DNS (CRÍTICO: otros servicios lo necesitan)
# 3. Traefik - Proxy Reverso (CRÍTICO: depende de DNS funcional)
# 4. Cloudflare - DDNS (actualización de IPs dinámicas)
# 5. AlugueisV3 - Sistema de Aluguéis (depende de DNS y Traefik)
# 6. Servicios Media:
#    - Immich (Fotos)
#    - Portainer (Gestión Docker)
#    - Plex (Media Server)
#    - Transmission (Torrents)
#    - Flexget (Automatización)
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

# Función para verificar si la red compartida existe
check_network_health() {
    log "Verificando salud de networks..."

    if docker network inspect kronos-net >/dev/null 2>&1; then
        log "${GREEN}✅ Red kronos-net está disponible${NC}"
        return 0
    fi

    log "${RED}❌ ERROR: Red kronos-net no está disponible${NC}"
    return 1
}

# Función para verificar si un servicio está saludable
check_service_health() {
    local service_dir=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1

    log "Verificando salud de $service_name..."

    cd "$BASE_DIR/$service_dir" || return 1

    while [ $attempt -le $max_attempts ]; do
        local container_status
        container_status=$(docker inspect -f '{{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' "$service_name" 2>/dev/null)

        if [ -n "$container_status" ]; then
            if echo "$container_status" | grep -q '^running healthy$\|^running no-healthcheck$'; then
                log "${GREEN}✅ $service_name está ejecutándose correctamente${NC}"
                return 0
            fi
        fi

        log "Intento $attempt/$max_attempts: $service_name aún no está listo..."
        sleep 10
        ((attempt++))
    done

    log "${RED}❌ ERROR: $service_name no se inició correctamente después de $max_attempts intentos${NC}"
    return 1
}

# Descargar imágenes sin apagar servicios críticos antes de tiempo
pull_service() {
    local service_dir=$1
    local service_name=$2

    if [ ! -d "$BASE_DIR/$service_dir" ]; then
        log "${YELLOW}⚠️  ADVERTENCIA: Directorio $service_dir no encontrado, saltando...${NC}"
        return 0
    fi

    cd "$BASE_DIR/$service_dir" || {
        log "${RED}❌ ERROR: No se pudo acceder al directorio $service_dir${NC}"
        return 1
    }

    if [ ! -f "docker-compose.yml" ]; then
        log "${YELLOW}⚠️  ADVERTENCIA: docker-compose.yml no encontrado en $service_dir, saltando...${NC}"
        return 0
    fi

    log "Descargando nuevas imágenes para $service_name..."
    docker-compose pull || {
        log "${RED}❌ ERROR: Falló la descarga de imágenes para $service_name${NC}"
        return 1
    }

    return 0
}

# Reiniciar un servicio después de descargar sus imágenes
restart_service() {
    local service_dir=$1
    local service_name=$2
    local wait_time=${3:-0}

    log "${BLUE}🔄 Reiniciando $service_name...${NC}"

    cd "$BASE_DIR/$service_dir" || {
        log "${RED}❌ ERROR: No se pudo acceder al directorio $service_dir${NC}"
        return 1
    }

    if [ "$service_dir" = "networks" ]; then
        log "Aplicando red kronos-net..."
        docker-compose up -d || {
            log "${RED}❌ ERROR: Falló la aplicación de networks${NC}"
            return 1
        }

        check_network_health || return 1
    else
        log "Deteniendo $service_name..."
        docker-compose down || {
            log "${YELLOW}⚠️  ADVERTENCIA: Error al detener $service_name, continuando...${NC}"
        }

        log "Iniciando $service_name con imágenes actualizadas..."
        docker-compose up -d || {
            log "${RED}❌ ERROR: Falló el inicio de $service_name${NC}"
            return 1
        }

        check_service_health "$service_dir" "$service_name" || return 1
    fi

    if [ $wait_time -gt 0 ]; then
        log "Esperando $wait_time segundos para estabilización de $service_name..."
        sleep $wait_time
    fi

    log "${GREEN}✅ $service_name actualizado exitosamente${NC}"
    return 0
}

# Función principal
main() {
    log "${BLUE}🚀 INICIANDO ACTUALIZACIÓN COMPLETA DE KRONOS SERVER${NC}"
    log "Log file: $LOG_FILE"
    log "Base directory: $BASE_DIR"
    log "================================================================"

    # Lista de servicios a actualizar en orden de dependencias (siguiendo start-all.sh)
    # Formato: "directorio:container_name:segundos_espera"
    # Los servicios críticos necesitan espera para estabilización de dependencias
    services=(
        "networks:networks:0"                    # PASO 1: Red (no espera)
        "pihole:pihole:15"                        # PASO 2: DNS (CRÍTICO - espera 15s)
        "traefik:traefik:10"                      # PASO 3: Proxy (CRÍTICO - espera 10s)
        "cloudflare:cloudflare:2"                # PASO 4: Cloudflare DDNS (espera 2s)
        "AlugueisV3:alugueis_postgres:5"          # PASO 5: AlugueisV3 (espera 5s)
        "immich-app:immich_server:3"              # PASO 6: Servicios media...
        "portainer:portainer:3"
        "plex:plex:3"
        "transmission:transmission:3"
        "flexget:flexget:3"
    )

    local total_services=${#services[@]}
    local updated=0
    local failed=0

    log "Fase 1/2: descargando imágenes de $total_services servicios con DNS activo..."

    for service_info in "${services[@]}"; do
        IFS=':' read -r service_dir service_name wait_time <<< "$service_info"

        if pull_service "$service_dir" "$service_name"; then
            ((updated++))
        else
            ((failed++))
            log "${RED}❌ Falló la descarga de $service_name${NC}"
        fi
    done

    log "Fase 2/2: reiniciando servicios en el orden de dependencias..."

    local restarted=0
    local restart_failed=0

    for service_info in "${services[@]}"; do
        IFS=':' read -r service_dir service_name wait_time <<< "$service_info"

        if restart_service "$service_dir" "$service_name" "$wait_time"; then
            ((restarted++))
        else
            ((restart_failed++))
            log "${RED}❌ Falló el reinicio de $service_name${NC}"
        fi
    done

    # Resumen final
    log "================================================================"
    log "${BLUE}📊 RESUMEN DE ACTUALIZACIÓN${NC}"
    log "Total de servicios: $total_services"
    log "Imágenes descargadas exitosamente: $updated"
    log "Descargas fallidas: $failed"
    log "Servicios reiniciados exitosamente: $restarted"
    log "Reinicios fallidos: $restart_failed"
    log "================================================================"

    if [ $failed -eq 0 ] && [ $restart_failed -eq 0 ]; then
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
#!/bin/bash

# ============================================================================
# KRONOS SERVER - AUDITORÍA DE SEGURIDAD COMPLETA
# ============================================================================
# Este script realiza una auditoría exhaustiva de seguridad del sistema
# Kronos Server, identificando vulnerabilidades y proporcionando
# recomendaciones de corrección.
#
# Ejecutar como: ./security-audit.sh
# ============================================================================

# Configuración
REPORT_FILE="/home/mloco/kronos-server/security-audit-$(date +%Y%m%d-%H%M%S).txt"
BASE_DIR="/home/mloco/kronos-server"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Contadores de vulnerabilidades
CRITICAL=0
HIGH=0
MEDIUM=0
LOW=0
INFO=0

# Función de logging
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$REPORT_FILE"
}

# Función para reportar vulnerabilidades
report_vulnerability() {
    local severity=$1
    local title=$2
    local description=$3
    local recommendation=$4
    local affected=$5

    case $severity in
        "CRITICAL")
            ((CRITICAL++))
            echo -e "${RED}🔴 CRÍTICA${NC}" | tee -a "$REPORT_FILE"
            ;;
        "HIGH")
            ((HIGH++))
            echo -e "${RED}🟠 ALTA${NC}" | tee -a "$REPORT_FILE"
            ;;
        "MEDIUM")
            ((MEDIUM++))
            echo -e "${YELLOW}🟡 MEDIA${NC}" | tee -a "$REPORT_FILE"
            ;;
        "LOW")
            ((LOW++))
            echo -e "${BLUE}🔵 BAJA${NC}" | tee -a "$REPORT_FILE"
            ;;
        "INFO")
            ((INFO++))
            echo -e "${CYAN}ℹ️  INFO${NC}" | tee -a "$REPORT_FILE"
            ;;
    esac

    echo "Título: $title" | tee -a "$REPORT_FILE"
    echo "Descripción: $description" | tee -a "$REPORT_FILE"
    echo "Afectado: $affected" | tee -a "$REPORT_FILE"
    echo "Recomendación: $recommendation" | tee -a "$REPORT_FILE"
    echo "----------------------------------------" | tee -a "$REPORT_FILE"
}

# Función para verificar privilegios de contenedores
check_container_privileges() {
    log "${BLUE}🔍 Verificando privilegios de contenedores...${NC}"

    # Contenedores con --privileged
    local privileged_containers=$(docker ps --format "table {{.Names}}\t{{.Image}}" | grep -v NAMES | while read name image; do
        if docker inspect "$name" | grep -q '"Privileged": true'; then
            echo "$name ($image)"
        fi
    done)

    if [ -n "$privileged_containers" ]; then
        report_vulnerability "CRITICAL" "Contenedores con privilegios excesivos" \
            "Los siguientes contenedores ejecutan con --privileged, lo que les da acceso completo al host" \
            "Remover --privileged de docker-compose.yml y usar capabilities específicas si son necesarias" \
            "$privileged_containers"
    fi

    # Contenedores con capabilities peligrosas
    local dangerous_caps=$(docker ps -q | xargs docker inspect | jq -r '.[] | select(.HostConfig.CapAdd != null) | .Name + ": " + (.HostConfig.CapAdd | join(", "))' 2>/dev/null | grep -E "(NET_ADMIN|SYS_ADMIN|SYS_PTRACE)" | sed 's|^/||')

    if [ -n "$dangerous_caps" ]; then
        report_vulnerability "HIGH" "Capabilities peligrosas detectadas" \
            "Contenedores con capabilities que pueden comprometer la seguridad del sistema" \
            "Revisar y remover capabilities innecesarias como NET_ADMIN, SYS_ADMIN, SYS_PTRACE" \
            "$dangerous_caps"
    fi
}

# Función para verificar configuraciones de red
check_network_security() {
    log "${BLUE}🔍 Verificando configuración de red...${NC}"

    # Puertos expuestos sin restricciones
    local exposed_ports=$(docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -v NAMES | grep "0.0.0.0:" | wc -l)

    if [ "$exposed_ports" -gt 0 ]; then
        report_vulnerability "MEDIUM" "Puertos expuestos públicamente" \
            "Se encontraron $exposed_ports contenedores con puertos expuestos a todas las interfaces (0.0.0.0)" \
            "Configurar bind mounts específicos o usar redes internas cuando sea posible" \
            "Verificar: docker ps --format 'table {{.Names}}\t{{.Ports}}'"
    fi

    # Verificar si hay contenedores en host network
    local host_network_containers=$(docker ps --filter "network=host" --format "{{.Names}}" | wc -l)

    if [ "$host_network_containers" -gt 0 ]; then
        local host_containers=$(docker ps --filter "network=host" --format "{{.Names}}")
        report_vulnerability "HIGH" "Contenedores usando red host" \
            "Contenedores ejecutándose en modo host network tienen acceso directo a la red del host" \
            "Usar redes bridge específicas con IPs controladas cuando sea posible" \
            "$host_containers"
    fi
}

# Función para verificar archivos sensibles
check_sensitive_files() {
    log "${BLUE}🔍 Verificando archivos sensibles...${NC}"

    # Archivos .env
    local env_files=$(find "$BASE_DIR" -name "*.env*" -type f 2>/dev/null | wc -l)

    if [ "$env_files" -gt 0 ]; then
        local env_list=$(find "$BASE_DIR" -name "*.env*" -type f 2>/dev/null)
        report_vulnerability "HIGH" "Archivos de entorno encontrados" \
            "Se encontraron archivos .env que pueden contener credenciales sensibles" \
            "Asegurar que los archivos .env estén en .gitignore y tengan permisos restrictivos (600)" \
            "$env_list"
    fi

    # Archivos con contraseñas
    local password_files=$(grep -r -l "PASSWORD\|SECRET\|KEY" "$BASE_DIR" --include="*.yml" --include="*.yaml" --include="*.sh" 2>/dev/null | grep -v ".git" | wc -l)

    if [ "$password_files" -gt 0 ]; then
        local pwd_list=$(grep -r -l "PASSWORD\|SECRET\|KEY" "$BASE_DIR" --include="*.yml" --include="*.yaml" --include="*.sh" 2>/dev/null | grep -v ".git")
        report_vulnerability "MEDIUM" "Credenciales en archivos de configuración" \
            "Se encontraron posibles credenciales en archivos de configuración" \
            "Usar variables de entorno o Docker secrets para manejar credenciales sensibles" \
            "$pwd_list"
    fi

    # Permisos de archivos
    local world_writable=$(find "$BASE_DIR" -type f -perm -002 2>/dev/null | grep -v ".git" | wc -l)

    if [ "$world_writable" -gt 0 ]; then
        report_vulnerability "MEDIUM" "Archivos con permisos excesivos" \
            "Se encontraron archivos escribibles por cualquier usuario" \
            "Establecer permisos más restrictivos (644 para archivos, 755 para directorios)" \
            "$world_writable archivos encontrados"
    fi
}

# Función para verificar configuraciones de Traefik
check_traefik_security() {
    log "${BLUE}🔍 Verificando configuración de Traefik...${NC}"

    # Verificar si Traefik está ejecutándose
    if docker ps --filter "name=traefik" --filter "status=running" | grep -q traefik; then
        # Verificar configuración HTTPS
        local traefik_config=$(docker exec traefik traefik version 2>/dev/null)
        if [ $? -eq 0 ]; then
            # Verificar routers sin TLS
            local http_routers=$(docker logs traefik 2>&1 | grep -c "http://" | tail -1)
            if [ "$http_routers" -gt 0 ]; then
                report_vulnerability "MEDIUM" "Routers HTTP sin encriptación" \
                    "Se detectaron routers HTTP sin configuración TLS" \
                    "Configurar TLS para todos los routers o usar redirects HTTP->HTTPS" \
                    "Traefik configuration"
            fi
        fi
    else
        report_vulnerability "HIGH" "Traefik no está ejecutándose" \
            "El proxy reverso Traefik no está activo, dejando servicios potencialmente expuestos" \
            "Verificar estado de Traefik y reiniciar si es necesario" \
            "Servicio Traefik"
    fi
}

# Función para verificar versiones de imágenes
check_image_versions() {
    log "${BLUE}🔍 Verificando versiones de imágenes Docker...${NC}"

    # Imágenes usando latest
    local latest_images=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep ":latest$" | wc -l)

    if [ "$latest_images" -gt 0 ]; then
        local latest_list=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep ":latest$")
        report_vulnerability "MEDIUM" "Imágenes usando tag 'latest'" \
            "Se encontraron $latest_images imágenes usando el tag 'latest', lo que puede causar actualizaciones inesperadas" \
            "Especificar versiones fijas en docker-compose.yml para mayor predictibilidad" \
            "$latest_list"
    fi

    # Verificar imágenes con vulnerabilidades conocidas (básico)
    local old_images=$(docker images --format "{{.Repository}}:{{.Tag}} {{.CreatedSince}}" | grep -E "(weeks|months|years)" | wc -l)

    if [ "$old_images" -gt 0 ]; then
        report_vulnerability "LOW" "Imágenes antiguas detectadas" \
            "Se encontraron imágenes creadas hace semanas/meses, pueden tener vulnerabilidades conocidas" \
            "Actualizar imágenes regularmente usando el script update-all.sh" \
            "$old_images imágenes antiguas encontradas"
    fi
}

# Función para verificar configuración de Docker
check_docker_configuration() {
    log "${BLUE}🔍 Verificando configuración de Docker...${NC}"

    # Verificar si Docker está ejecutándose con user namespace
    if docker info 2>/dev/null | grep -q "userns"; then
        log "${GREEN}✅ User namespaces habilitados${NC}"
    else
        report_vulnerability "MEDIUM" "User namespaces no habilitados" \
            "Docker no está usando user namespaces, lo que puede afectar el aislamiento" \
            "Considerar habilitar user namespaces en daemon.json" \
            "Configuración de Docker daemon"
    fi

    # Verificar logging driver
    local log_driver=$(docker info --format "{{.LoggingDriver}}")
    if [ "$log_driver" = "json-file" ]; then
        report_vulnerability "LOW" "Logging driver básico" \
            "Usando json-file logging que puede consumir mucho espacio en disco" \
            "Considerar configurar límites de log o usar logrotate" \
            "Docker logging configuration"
    fi
}

# Función para verificar servicios críticos
check_critical_services() {
    log "${BLUE}🔍 Verificando servicios críticos...${NC}"

    # Verificar Pi-hole
    if ! docker ps --filter "name=pihole" --filter "status=running" | grep -q pihole; then
        report_vulnerability "HIGH" "Pi-hole no está ejecutándose" \
            "El servidor DNS Pi-hole no está activo, afectando resolución de nombres" \
            "Verificar estado de Pi-hole y reiniciar si es necesario" \
            "Servicio Pi-hole"
    fi

    # Verificar servicios con bases de datos
    local db_services=("immich_postgres" "alugueis_postgres")
    for service in "${db_services[@]}"; do
        if ! docker ps --filter "name=$service" --filter "status=running" | grep -q "$service"; then
            report_vulnerability "HIGH" "Servicio de base de datos detenido" \
                "El servicio de base de datos $service no está ejecutándose" \
                "Verificar estado y reiniciar el servicio afectado" \
                "$service"
        fi
    done
}

# Función para verificar backups
check_backup_configuration() {
    log "${BLUE}🔍 Verificando configuración de backups...${NC}"

    # Verificar existencia de scripts de backup
    local backup_scripts=$(find "$BASE_DIR/scripts" -name "*backup*" -type f 2>/dev/null | wc -l)

    if [ "$backup_scripts" -lt 3 ]; then
        report_vulnerability "MEDIUM" "Scripts de backup insuficientes" \
            "Se encontraron pocos scripts de backup ($backup_scripts), riesgo de pérdida de datos" \
            "Implementar backups automáticos para bases de datos y configuraciones" \
            "Directorio scripts/"
    fi

    # Verificar permisos de scripts de backup
    local executable_scripts=$(find "$BASE_DIR/scripts" -name "*backup*" -type f -executable 2>/dev/null | wc -l)

    if [ "$executable_scripts" -lt "$backup_scripts" ]; then
        report_vulnerability "LOW" "Scripts de backup sin permisos de ejecución" \
            "Algunos scripts de backup no tienen permisos de ejecución" \
            "Establecer permisos 755 en scripts de backup" \
            "Scripts en $BASE_DIR/scripts/"
    fi
}

# Función principal
main() {
    log "${PURPLE}🔒 INICIANDO AUDITORÍA DE SEGURIDAD - KRONOS SERVER${NC}"
    log "Report file: $REPORT_FILE"
    log "Base directory: $BASE_DIR"
    log "Timestamp: $(date)"
    log "================================================================================\n"

    # Verificar prerrequisitos
    if ! docker info >/dev/null 2>&1; then
        log "${RED}❌ ERROR: Docker no está ejecutándose${NC}"
        exit 1
    fi

    if [ ! -d "$BASE_DIR" ]; then
        log "${RED}❌ ERROR: Directorio base $BASE_DIR no encontrado${NC}"
        exit 1
    fi

    # Ejecutar verificaciones
    check_container_privileges
    check_network_security
    check_sensitive_files
    check_traefik_security
    check_image_versions
    check_docker_configuration
    check_critical_services
    check_backup_configuration

    # Resumen final
    log "\n================================================================================
${PURPLE}📊 RESUMEN DE AUDITORÍA DE SEGURIDAD${NC}"
    log "================================================================================
${RED}🔴 Vulnerabilidades CRÍTICAS: $CRITICAL${NC}"
    log "${RED}🟠 Vulnerabilidades ALTAS: $HIGH${NC}"
    log "${YELLOW}🟡 Vulnerabilidades MEDIAS: $MEDIUM${NC}"
    log "${BLUE}🔵 Vulnerabilidades BAJAS: $LOW${NC}"
    log "${CYAN}ℹ️  Información: $INFO${NC}"

    local total=$((CRITICAL + HIGH + MEDIUM + LOW + INFO))

    if [ $total -eq 0 ]; then
        log "\n${GREEN}🎉 ¡FELICITACIONES! No se encontraron vulnerabilidades de seguridad.${NC}"
    elif [ $CRITICAL -eq 0 ] && [ $HIGH -eq 0 ]; then
        log "\n${GREEN}✅ Sistema relativamente seguro. Solo vulnerabilidades menores encontradas.${NC}"
    else
        log "\n${RED}⚠️  Se encontraron vulnerabilidades importantes que requieren atención inmediata.${NC}"
    fi

    log "\n📄 Reporte completo guardado en: $REPORT_FILE"
    log "================================================================================\n"
}

# Ejecutar auditoría
main "$@"
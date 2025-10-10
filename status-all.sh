#!/bin/bash

# ============================================================================
# KRONOS SERVER - SCRIPT DE VERIFICACIÓN DE ESTADO DE SERVICIOS
# ============================================================================
# 
# Verifica el estado de todos los servicios y muestra información de red
#
# ============================================================================

echo "📊 ESTADO DE KRONOS SERVER - TODOS LOS SERVICIOS"
echo "============================================================================"

# Función para verificar estado de servicio
check_service_status() {
    local service_name=$1
    local directory=$2
    
    if [ -d "$directory" ]; then
        cd "$directory"
        local containers=$(docker-compose ps -q)
        if [ -n "$containers" ]; then
            local running=$(docker-compose ps --services --filter "status=running" | wc -l)
            local total=$(docker-compose ps --services | wc -l)
            if [ $running -eq $total ] && [ $total -gt 0 ]; then
                echo "   ✅ $service_name: EJECUTÁNDOSE ($running/$total contenedores)"
            elif [ $running -gt 0 ]; then
                echo "   ⚠️  $service_name: PARCIAL ($running/$total contenedores)"
            else
                echo "   🔴 $service_name: DETENIDO ($running/$total contenedores)"
            fi
        else
            echo "   ⚫ $service_name: NO CONFIGURADO"
        fi
        cd ..
    else
        echo "   ❌ $service_name: DIRECTORIO NO ENCONTRADO"
    fi
}

# Verificar red
echo "📡 RED KRONOS-NET:"
if docker network ls | grep -q "kronos-net"; then
    echo "   ✅ kronos-net: ACTIVA"
    echo "   📋 Subnet: 172.20.0.0/16"
else
    echo "   🔴 kronos-net: NO ENCONTRADA"
fi

echo ""
echo "🔧 INFRAESTRUCTURA CORE:"
check_service_status "Pi-hole (DNS)" "pihole"
check_service_status "Traefik (Proxy)" "traefik"

echo ""
echo "📧 SERVICIOS BASE:"
check_service_status "Postie (Email)" "postie"

echo ""
echo "🏠 ALUGUEISV3 (SISTEMA DE ALUGUÉIS):"
check_service_status "AlugueV3" "AlugueV3"

echo ""
echo "🎬 SERVICIOS MEDIA:"
check_service_status "Immich (Fotos)" "immich-app"
check_service_status "Portainer (Management)" "portainer"
check_service_status "Transmission (Torrents)" "transmission"
check_service_status "Flexget" "flexget"

echo ""
echo "🌐 MAPA DE IPs (kronos-net):"
if docker network inspect kronos-net > /dev/null 2>&1; then
    echo "   📍 Contenedores conectados:"
    docker network inspect kronos-net --format='{{range .Containers}}   {{.Name}}: {{.IPv4Address}}{{"\n"}}{{end}}' | sort
else
    echo "   ❌ Red kronos-net no disponible"
fi

echo ""
echo "🔗 SERVICIOS WEB PRINCIPALES:"
echo "   🏠 AlugueV3: https://aluguel.kronos.cloudns.ph"
echo "   📸 Immich: https://immich.kronos.cloudns.ph"
echo "   🐳 Portainer: https://portainer.kronos.cloudns.ph"
echo "   📧 Postie: https://postie.kronos.cloudns.ph"
echo "   🌐 Pi-hole: https://pihole.kronos.cloudns.ph"
echo "   🔀 Traefik: https://traefik.kronos.cloudns.ph"

echo ""
echo "============================================================================"
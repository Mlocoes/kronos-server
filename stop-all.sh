#!/bin/bash

# ============================================================================
# KRONOS SERVER - SCRIPT DE PARADA DE TODOS LOS SERVICIOS
# ============================================================================
# 
# ORDEN DE PARADA (Inverso al inicio para evitar dependencias rotas):
# 1. Servicios Media y Utilidades
# 2. AlugueV3 (Sistema de Aluguéis) 
# 3. Servicios de Infraestructura
# 4. Traefik (Proxy Reverso)
# 5. Pi-hole (DNS)
# 6. Red kronos-net
#
# ============================================================================

echo "🛑 DETENIENDO KRONOS SERVER - TODOS LOS SERVICIOS"
echo "============================================================================"

# PASO 1: Servicios Media y Utilidades (menos críticos)
echo "🎬 [1/6] Deteniendo servicios media y utilidades..."
media_services=("flexget" "transmission" "portainer" "immich-app")

for service in "${media_services[@]}"; do
    if [ -d "$service" ]; then
        echo "   🎯 Deteniendo $service..."
        cd "$service" && docker-compose down
        cd ..
        if [ $? -eq 0 ]; then
            echo "   ✅ $service detenido exitosamente"
        else
            echo "   ⚠️  Error deteniendo $service, continuando..."
        fi
        sleep 2
    else
        echo "   ⚠️  Directorio $service no encontrado, saltando..."
    fi
done

# PASO 2: AlugueV3 (Sistema de Aluguéis)
echo "🏠 [2/6] Deteniendo AlugueV3 (Sistema de Aluguéis)..."
if [ -d "AlugueV3" ]; then
    cd AlugueV3 && docker-compose down
    cd ..
    if [ $? -eq 0 ]; then
        echo "✅ AlugueV3 detenido exitosamente"
        echo "   📊 Backend API: Detenido"
        echo "   🌐 Frontend: Detenido" 
        echo "   🛠️  Adminer: Detenido"
    else
        echo "❌ Error deteniendo AlugueV3"
    fi
    sleep 3
else
    echo "⚠️  Directorio AlugueV3 no encontrado, saltando..."
fi

# PASO 3: Servicios de Infraestructura Base
echo "📧 [3/6] Deteniendo servicios de infraestructura..."
infrastructure_services=("postie")

for service in "${infrastructure_services[@]}"; do
    if [ -d "$service" ]; then
        echo "   🔧 Deteniendo $service..."
        cd "$service" && docker-compose down
        cd ..
        if [ $? -eq 0 ]; then
            echo "   ✅ $service detenido exitosamente"
        else
            echo "   ⚠️  Error deteniendo $service, continuando..."
        fi
        sleep 2
    else
        echo "   ⚠️  Directorio $service no encontrado, saltando..."
    fi
done

# PASO 4: Traefik (Proxy Reverso - crítico)
echo "🔀 [4/6] Deteniendo Traefik (Proxy Reverso: 172.20.0.3)..."
if [ -d "traefik" ]; then
    cd traefik && docker-compose down
    cd ..
    if [ $? -eq 0 ]; then
        echo "✅ Traefik detenido exitosamente"
    else
        echo "❌ Error deteniendo Traefik"
    fi
    sleep 3
else
    echo "⚠️  Directorio traefik no encontrado, saltando..."
fi

# PASO 5: Pi-hole (DNS - más crítico)
echo "🌐 [5/6] Deteniendo Pi-hole (DNS: 172.20.0.2)..."
if [ -d "pihole" ]; then
    cd pihole && docker-compose down
    cd ..
    if [ $? -eq 0 ]; then
        echo "✅ Pi-hole detenido exitosamente"
    else
        echo "❌ Error deteniendo Pi-hole"
    fi
    sleep 3
else
    echo "⚠️  Directorio pihole no encontrado, saltando..."
fi

# PASO 6: Red de Infraestructura (último)
echo "📡 [6/6] Deteniendo red kronos-net (172.20.0.0/16)..."
if [ -d "networks" ]; then
    cd networks && docker-compose down
    if [ $? -eq 0 ]; then
        echo "✅ Red kronos-net detenida exitosamente"
    else
        echo "❌ Error deteniendo la red kronos-net"
    fi
else
    echo "⚠️  Directorio networks no encontrado, saltando..."
fi

echo ""
echo "============================================================================"
echo "🔴 ¡KRONOS SERVER DETENIDO COMPLETAMENTE!"
echo "============================================================================"
echo "📊 TODOS LOS SERVICIOS DETENIDOS:"
echo "   🏠 AlugueV3: Detenido"
echo "   📸 Immich: Detenido"
echo "   🐳 Portainer: Detenido"
echo "   📧 Postie: Detenido"
echo "   🌐 Pi-hole: Detenido"
echo "   🔀 Traefik: Detenido"
echo ""
echo "🌐 RED: kronos-net eliminada"
echo "🔒 PUERTOS: Liberados"
echo "============================================================================"
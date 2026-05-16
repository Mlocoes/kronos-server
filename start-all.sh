#!/bin/bash

# ============================================================================
# KRONOS SERVER - SCRIPT DE INICIALIZACIÓN DE TODOS LOS SERVICIOS
# ============================================================================
# 
# ESQUEMA DE IPs (Red: 172.20.0.0/16):
# ├── Infraestructura Core:
# │   ├── 172.20.0.2  - Pi-hole (DNS) [FIJA]
# │   ├── 172.20.0.3  - Traefik (Proxy Reverso) [FIJA]
# │   └── 172.20.0.4  - AlugueV3 Backend (API FastAPI) [FIJA]
# ├── Servicios Media:
# │   ├── 172.20.0.5  - AlugueV3 Frontend (Nginx) [FIJA]
# │   ├── 172.20.0.6  - Immich Machine Learning [FIJA]
# │   ├── 172.20.0.7  - Immich Redis [FIJA]
# │   ├── 172.20.0.8  - Immich PostgreSQL [FIJA]
# │   ├── 172.20.0.9  - Immich Server [FIJA]
# │   ├── 172.20.0.10 - Portainer (Management) [FIJA]
# │   ├── 172.20.0.11 - Plex (Media Server) [FIJA]
# │   ├── 172.20.0.12 - Transmission (Torrents) [FIJA]
# │   └── 172.20.0.13 - Flexget [FIJA]
# └── AlugueV3 (Sistema de Aluguéis):
#     ├── 172.20.0.4  - AlugueV3 Backend (API FastAPI) [FIJA]
#     ├── 172.20.0.5  - AlugueV3 Frontend (Nginx) [FIJA]
#     └── AlugueV3 Adminer - Solo red interna (alugueis_network)
#
# ============================================================================

echo "🚀 INICIANDO KRONOS SERVER - TODOS LOS SERVICIOS"
echo "============================================================================"

# PASO 1: Infraestructura de Red
echo "📡 [1/6] Iniciando red kronos-net (172.20.0.0/16)..."
cd networks && docker-compose up -d
if [ $? -eq 0 ]; then
    echo "✅ Red kronos-net iniciada exitosamente"
else
    echo "❌ Error iniciando la red. Abortando."
    exit 1
fi

# PASO 2: Servicio DNS (Crítico - debe iniciarse primero)
echo "🌐 [2/6] Iniciando Pi-hole (DNS: 172.20.0.2)..."
cd ../pihole && docker-compose up -d
if [ $? -eq 0 ]; then
    echo "✅ Pi-hole iniciado. Esperando 15 segundos para estabilización DNS..."
    sleep 15
else
    echo "❌ Error iniciando Pi-hole. Abortando."
    exit 1
fi

# PASO 3: Proxy Reverso (Crítico - maneja todo el tráfico HTTPS)
echo "🔀 [3/6] Iniciando Traefik (Proxy: 172.20.0.3)..."
cd ../traefik && docker-compose up -d
if [ $? -eq 0 ]; then
    echo "✅ Traefik iniciado. Esperando 10 segundos para activar proxy..."
    sleep 10
else
    echo "❌ Error iniciando Traefik. Abortando."
    exit 1
fi

# PASO 4: Servicios de Infraestructura Base
echo "📧 [4/6] Servicios de infraestrutura base..."
echo "   ℹ️  Postie (serviço de email) DESABILITADO conforme solicitado"
echo "   ✅ Pulando inicialização do Postie"

# PASO 5: AlugueV3 (Sistema de Aluguéis)
echo "🏠 [5/6] Iniciando AlugueV3 (Sistema de Aluguéis)..."
cd ../AlugueV3 && docker-compose up -d
if [ $? -eq 0 ]; then
    echo "✅ AlugueV3 iniciado exitosamente:"
    echo "   📊 Backend API: https://aluguel.kronos.cloudns.ph/api/"
    echo "   🌐 Frontend: https://aluguel.kronos.cloudns.ph"
    echo "   🛠️  Adminer: (acceso interno solamente)"
    sleep 5
else
    echo "❌ Error iniciando AlugueV3"
fi

# PASO 6: Servicios Media y Utilidades
echo "🎬 [6/6] Iniciando servicios media y utilidades..."
media_services=("immich-app" "portainer" "plex" "transmission" "flexget")

for service in "${media_services[@]}"; do
    echo "   🎯 Iniciando $service..."
    cd "../$service" && docker-compose up -d
    if [ $? -eq 0 ]; then
        echo "   ✅ $service iniciado exitosamente"
        sleep 3
    else
        echo "   ⚠️  Error iniciando $service, continuando..."
    fi
done

echo ""
echo "============================================================================"
echo "🎉 ¡KRONOS SERVER INICIADO COMPLETAMENTE!"
echo "============================================================================"
echo "📊 SERVICIOS PRINCIPALES DISPONIBLES:"
echo "   🏠 AlugueV3: https://aluguel.kronos.cloudns.ph"
echo "   📸 Immich: https://immich.kronos.cloudns.ph" 
echo "   🎬 Plex: https://plex.kronos.cloudns.ph"
echo "   🐳 Portainer: https://portainer.kronos.cloudns.ph"
echo "   🌐 Pi-hole: https://pihole.kronos.cloudns.ph"
echo "   🔀 Traefik: https://dashboard.kronos.cloudns.ph"
echo "   📧 Postie: DESABILITADO (problemas de configuração DNS)"
echo ""
echo "🌐 RED: kronos-net (172.20.0.0/16)"
echo "🔒 SSL: Certificados automáticos Let's Encrypt"
echo "============================================================================"
# KRONOS SERVER - DOCUMENTACIÓN DE RED Y SERVICIOS

## 🌐 ESQUEMA DE RED

**Red Principal:** `kronos-net` (172.20.0.0/16)

### 📊 MAPA DE IPs ASIGNADAS

```
🔧 INFRAESTRUCTURA CORE:
├── 172.20.0.2  - Pi-hole (DNS Server)
├── 172.20.0.3  - Traefik (Reverse Proxy)
└── 172.20.0.4  - Postie (Email Service)

🎬 SERVICIOS MEDIA:
├── 172.20.0.5  - Immich Machine Learning
├── 172.20.0.6  - Immich PostgreSQL
├── 172.20.0.7  - Immich Redis
├── 172.20.0.8  - Immich Server
├── 172.20.0.9  - Portainer (Container Management)
├── 172.20.0.10 - Transmission (BitTorrent Client)
└── 172.20.0.11 - Flexget (Media Automation)

🏠 ALUGUEISV3 (SISTEMA DE ALUGUÉIS):
├── 172.20.0.12 - AlugueV3 Backend (FastAPI)
├── 172.20.0.13 - AlugueV3 Adminer (Database Admin)
└── 172.20.0.14 - AlugueV3 Frontend (Nginx)

🔮 RESERVADO PARA FUTUROS SERVICIOS:
└── 172.20.0.15-20 - Disponible para nuevos servicios
```

## 🚀 SECUENCIA DE INICIALIZACIÓN

### Orden Crítico (start-all.sh):
1. **Red kronos-net** - Base de toda la infraestructura
2. **Pi-hole (DNS)** - Resolución de nombres crítica
3. **Traefik (Proxy)** - Maneja todo el tráfico HTTPS
4. **Servicios Base** - Postie (Email)
5. **AlugueV3** - Sistema de Aluguéis principal
6. **Servicios Media** - Immich, Portainer, Transmission, Flexget

### Orden de Parada (stop-all.sh):
1. **Servicios Media** - Menos críticos
2. **AlugueV3** - Sistema de aplicación
3. **Servicios Base** - Postie
4. **Traefik** - Proxy reverso
5. **Pi-hole** - DNS
6. **Red kronos-net** - Infraestructura base

## 🌍 SERVICIOS WEB ACCESIBLES

| Servicio | URL | IP Interna | Descripción |
|----------|-----|------------|-------------|
| **AlugueV3** | https://aluguel.kronos.cloudns.ph | 172.20.0.12-14 | Sistema de Gestión de Aluguéis |
| **Immich** | https://immich.kronos.cloudns.ph | 172.20.0.5-8 | Gestión de Fotos Personal |
| **Portainer** | https://portainer.kronos.cloudns.ph | 172.20.0.9 | Management de Containers |
| **Postie** | https://postie.kronos.cloudns.ph | 172.20.0.4 | Servidor de Email |
| **Pi-hole** | https://pihole.kronos.cloudns.ph | 172.20.0.2 | DNS + Ad Blocker |
| **Traefik** | https://traefik.kronos.cloudns.ph | 172.20.0.3 | Proxy Reverso Dashboard |

## 🛠️ SCRIPTS DE GESTIÓN

| Script | Función | Descripción |
|--------|---------|-------------|
| `./start-all.sh` | Iniciar todos | Inicia todos los servicios en orden correcto |
| `./stop-all.sh` | Detener todos | Detiene todos los servicios en orden inverso |
| `./status-all.sh` | Ver estado | Muestra estado de todos los servicios y red |

## 🔒 SEGURIDAD Y SSL

- **Certificados SSL**: Let's Encrypt automático vía Traefik
- **DNS**: Pi-hole filtra publicidad y malware
- **Proxy**: Traefik maneja todo el tráfico HTTPS
- **Red**: Aislada en subnet privada 172.20.0.0/16

## 📝 NOTAS IMPORTANTES

1. **DNS**: Pi-hole debe iniciarse primero para resolver nombres
2. **Proxy**: Traefik debe estar activo antes que los servicios web
3. **Red**: kronos-net es la base de toda la comunicación
4. **IPs**: Asignadas estáticamente para consistencia
5. **SSL**: Certificados renovados automáticamente cada 90 días

## 🚨 TROUBLESHOOTING

- **Servicio no responde**: Verificar con `./status-all.sh`
- **Error SSL**: Reiniciar Traefik: `cd traefik && docker-compose restart`
- **DNS issues**: Reiniciar Pi-hole: `cd pihole && docker-compose restart`  
- **Reset completo**: `./stop-all.sh && ./start-all.sh`
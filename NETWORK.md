# 📡 NETWORK - KRONOS SERVER

## Descripción General

Este documento describe la configuración de red completa del servidor Kronos, incluyendo el esquema de direcciones IP fijas asignadas a todos los servicios Docker.

## 🏗️ Arquitectura de Red

**Red Principal:** `kronos-net` (172.20.0.0/16)
- Tipo: Bridge externa
- Propósito: Conexión entre todos los servicios principales

**Redes Adicionales:**
- `alugueis_network`: Red interna para servicios de AlugueV3
- `host`: Network mode para servicios que requieren acceso directo al host (Plex)

## 📋 ESQUEMA COMPLETO DE IPs

### Infraestructura Core
| IP | Servicio | Estado | Descripción |
|----|---------|--------|-------------|
| `172.20.0.2` | Pi-hole | ✅ FIJA | Servidor DNS y bloqueador de anuncios |
| `172.20.0.3` | Traefik | ✅ FIJA | Proxy reverso y balanceador de carga |
| `172.20.0.4` | AlugueV3 Backend | ✅ FIJA | API FastAPI del sistema de alquileres |

### Servicios Media
| IP | Servicio | Estado | Descripción |
|----|---------|--------|-------------|
| `172.20.0.5` | AlugueV3 Frontend | ✅ FIJA | Interfaz web Nginx del sistema de alquileres |
| `172.20.0.6` | Immich Machine Learning | ✅ FIJA | Servicio de IA para reconocimiento de imágenes |
| `172.20.0.7` | Immich Redis | ✅ FIJA | Cache y base de datos en memoria para Immich |
| `172.20.0.8` | Immich PostgreSQL | ✅ FIJA | Base de datos principal de Immich |
| `172.20.0.9` | Immich Server | ✅ FIJA | Servidor principal de Immich |
| `172.20.0.10` | Portainer | ✅ FIJA | Interfaz de gestión de Docker |
| `172.20.0.11` | Transmission | ✅ FIJA | Cliente de torrents |
| `172.20.0.12` | Flexget | ✅ FIJA | Automatizador de descargas |

### Sistema AlugueV3
| IP/Red | Servicio | Estado | Descripción |
|--------|---------|--------|-------------|
| `172.20.0.4` | Backend (API) | ✅ FIJA | API REST FastAPI |
| `172.20.0.5` | Frontend (Web) | ✅ FIJA | Interfaz de usuario Nginx |
| `alugueis_network` | Adminer | ✅ INTERNA | Interfaz de gestión de base de datos |
| `alugueis_network` | PostgreSQL | ✅ INTERNA | Base de datos del sistema de alquileres |

## 🔧 Configuración Técnica

### Variables de Entorno Comunes
```bash
TRAEFIK_NETWORK=kronos-net
PIHOLE_IP=172.20.0.2
```

### DNS
- **Servidor DNS principal:** `172.20.0.2` (Pi-hole)
- **Dominio base:** Configurado en variables de entorno de cada servicio

### Proxy Reverso (Traefik)
- **IP:** `172.20.0.3`
- **Puerto HTTP:** 80
- **Puerto HTTPS:** 443
- **Configuración:** Labels en docker-compose.yml

## 📊 Servicios Actualmente Activos

### ✅ Servicios en Funcionamiento
- **Pi-hole** - DNS y bloqueador de anuncios
- **Traefik** - Proxy reverso
- **Portainer** - Gestión de Docker
- **Transmission** - Cliente de torrents
- **Flexget** - Automatización de descargas
- **Immich Stack** - Servidor de fotos (Server, PostgreSQL, Redis, ML)
- **AlugueV3 Stack** - Sistema de alquileres (Backend, Frontend, Adminer, PostgreSQL)
- **Plex** - Servidor multimedia (network: host)

### ⚠️ Notas Importantes
- **Plex** utiliza `network_mode: host` por requerimientos de rendimiento
- **AlugueV3 Adminer** solo es accesible desde la red interna `alugueis_network`
- Todas las IPs están configuradas como fijas para evitar problemas tras reinicios del servidor

## 🚀 Inicio de Servicios

Los servicios se inician en orden específico mediante el script `start-all.sh`:

```bash
# Orden de inicio recomendado:
1. Pi-hole (DNS)
2. Traefik (Proxy)
3. Bases de datos (PostgreSQL)
4. Servicios principales
5. Interfaces web
```

## 🔍 Verificación de IPs

Para verificar las IPs asignadas actualmente:

```bash
# Ver todas las IPs en kronos-net
docker network inspect kronos-net

# Ver IPs de un servicio específico
docker inspect <container_name> | grep -A 5 "Networks"
```

## 📝 Última Actualización

- **Fecha:** 10 de octubre de 2025
- **Cambios:** Configuración de IPs fijas para AlugueV3
- **Estado:** Todas las IPs principales configuradas y verificadas

---

**Nota:** Este documento se mantiene actualizado con cada cambio en la configuración de red. Para modificaciones, actualizar tanto los archivos `docker-compose.yml` como este documento.
# Kronos Server

Sistema de servicios auto-gestionado basado en Docker para entorno doméstico.

## Estructura del Sistema

```
/home/mloco/kronos-server/    # Directorio principal de la aplicación
├── services/                 # Archivos docker-compose.yml de cada servicio
├── scripts/                  # Scripts de mantenimiento y backup
├── networks/                 # Configuración de redes Docker
└── docs/                     # Documentación completa del sistema

/mnt/
├── backup/                   # Almacenamiento de backups
│   ├── kronos/              # Backups del sistema principal
│   ├── immich/              # Backups de Immich
│   └── posteio/             # Backups del servidor de correo
└── storage/                  # Almacenamiento principal
    ├── media/               # Contenido multimedia (Plex)
    └── immich/              # Fotos y videos (Immich)
```

## Servicios Principales

### Gestión y Seguridad
- **Traefik**: Proxy inverso y gestión SSL
- **Cloudflare**: DNS dinámico y seguridad
- **Pi-hole**: Servidor DNS y bloqueo de anuncios
- **Portainer**: Gestión de contenedores

### Multimedia y Almacenamiento
- **Immich**: Servidor de fotos con ML
- **Plex**: Servidor de streaming multimedia

### Comunicaciones
- **Poste.io**: Servidor de correo completo

### Automatización
- **Transmission**: Cliente BitTorrent
- **Flexget**: Automatización de descargas

## Mantenimiento

### Scripts Principales
- `start-all.sh`: Inicia todos los servicios
- `stop-all.sh`: Detiene todos los servicios
- `run_all_backups.sh`: Ejecuta todos los backups

### Scripts de Gestión

El sistema incluye varios scripts para facilitar la administración:

- **`start-all.sh`** - Inicia todos los servicios en el orden correcto
- **`stop-all.sh`** - Detiene todos los servicios
- **`status-all.sh`** - Muestra el estado de todos los servicios
- **`update-all.sh`** - Actualiza todas las imágenes Docker y reinicia los servicios
- **`check-updates.sh`** - Verifica si hay actualizaciones disponibles sin aplicarlas

#### Uso de Scripts

```bash
# Verificar actualizaciones disponibles
./check-updates.sh

# Actualizar todo el sistema
./update-all.sh

# Ver estado de servicios
./status-all.sh

# Reiniciar todo el sistema
./stop-all.sh && ./start-all.sh
```

### Backups Automáticos
Los backups se ejecutan diariamente a las 2 AM y se almacenan en `/mnt/backup/`

## Documentación

### General
- [Visión General](docs/overview.md)
- [Backups y Restauración](docs/backups.md)
- [Mantenimiento](docs/maintenance.md)
- [Red y DNS](docs/networking.md)
- [Notificaciones](docs/email-notifications.md)

### Servicios
- [Documentación de Servicios](docs/services/README.md)

### Scripts
- [Documentación de Scripts](docs/scripts.md)

## Requisitos

### Hardware Recomendado
- CPU: 4+ cores
- RAM: 16GB+
- Almacenamiento: 500GB+ para sistema
- Red: Gigabit Ethernet

### Software Base
- Ubuntu Server 22.04 LTS
- Docker y Docker Compose
- Git (para actualizaciones)
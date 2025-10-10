# Servicios de Kronos Server

## Resumen de Servicios

### Gestión de Tráfico y Seguridad

#### [Traefik](./traefik.md)
- Proxy inverso y balanceador de carga
- Gestión automática de certificados SSL
- Integración con Cloudflare
- Ubicación: `/traefik/`
- Dashboard: `traefik.kronos.cloudns.ph`

#### [Cloudflare](./cloudflare.md)
- DNS dinámico y protección DDoS
- Gestión de registros DNS
- Ubicación: `/cloudflare/`
- Configuración en `cf_api_token.txt`

#### [Pi-hole](./pihole.md)
- Servidor DNS local
- Bloqueo de anuncios y malware
- Ubicación: `/pihole/`
- Panel: `http://pihole.kronos.cloudns.ph/admin`
- Datos: `/etc-pihole/`

### Multimedia y Almacenamiento

#### [Immich](./immich.md)
- Servidor de fotos con ML
- Aceleración por hardware
- Ubicación: `/immich-app/`
- URL: `immich.kronos.cloudns.ph`
- Almacenamiento: `/mnt/storage/immich/`

#### [Plex](./plex.md)
- Servidor de streaming multimedia
- Transcoding por hardware
- Ubicación: `/plex/`
- URL: `plex.kronos.cloudns.ph`
- Biblioteca: `/mnt/storage/media/`

### Gestión y Monitoreo

#### [Portainer](./portainer.md)
- Gestión de contenedores Docker
- Monitoreo de recursos
- Ubicación: `/portainer/`
- URL: `portainer.kronos.cloudns.ph`
- Datos: `/portainer/data/`

### Comunicaciones

#### [Poste.io](./postie.md)
- Servidor de correo completo
- Webmail y administración
- Ubicación: `/postie/`
- URL: `mail.kronos.cloudns.ph`
- Backups: `/mnt/backup/posteio/`

### Descargas y Automatización

#### [Transmission](./transmission.md)
- Cliente BitTorrent
- Panel web
- Ubicación: `/transmission/`
- URL: `transmission.kronos.cloudns.ph`
- Config: `/transmission/transmission/`

#### [Flexget](./flexget.md)
- Automatización de descargas
- Integración con Transmission
- Ubicación: `/flexget/`
- Config: `/flexget/flexget/config.yml`

## Redes

### Red Principal: kronos-net
- Tipo: overlay
- CIDR: 172.16.0.0/16
- Servicios conectados: Todos

## Backups

### Ubicaciones
- Kronos: `/mnt/backup/kronos/`
- Immich: `/mnt/backup/immich/`
- Poste.io: `/mnt/backup/posteio/`

### Scripts
- backup_kronos.sh
- backup_immich.sh
- backup_posteio.sh
- run_all_backups.sh (automatizado)
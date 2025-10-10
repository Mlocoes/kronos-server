# Transmission

## Descripción
Transmission es el cliente BitTorrent utilizado para la descarga automática de contenido multimedia.

## Ubicación
- Directorio: `/transmission/`
- Configuración: `/transmission/transmission/`
- Descargas: `/mnt/downloads/`

## Configuración

### docker-compose.yml
```yaml
services:
  transmission:
    image: lscr.io/linuxserver/transmission:latest
    container_name: transmission
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ}
      - USER=${TRANSMISSION_USER}
      - PASS=${TRANSMISSION_PASS}
    volumes:
      - ./transmission:/config
      - ${DOWNLOADS_PATH}:/downloads
      - ${WATCH_PATH}:/watch
    ports:
      - 51413:51413
      - 51413:51413/udp
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.transmission-secure.entrypoints=https"
      - "traefik.http.routers.transmission-secure.rule=Host(`${TRANSMISSION_URL}`)"
      - "traefik.http.routers.transmission-secure.tls=true"
      - "traefik.http.routers.transmission-secure.tls.certresolver=myresolver"
      - "traefik.http.services.transmission.loadbalancer.server.port=9091"
    restart: unless-stopped
    networks:
      kronos-net: {}
```

### Variables de Entorno
```env
TZ=America/Lima
TRANSMISSION_USER=admin
TRANSMISSION_PASS=password
TRANSMISSION_URL=transmission.kronos.cloudns.ph
DOWNLOADS_PATH=/mnt/downloads
WATCH_PATH=/mnt/downloads/watch
```

### settings.json
Configuraciones importantes:
```json
{
    "download-dir": "/downloads/complete",
    "incomplete-dir": "/downloads/incomplete",
    "watch-dir": "/watch",
    "watch-dir-enabled": true,
    "rpc-whitelist-enabled": false,
    "rpc-authentication-required": true
}
```

## Acceso
- Web: `https://transmission.kronos.cloudns.ph`
- RPC: Puerto 9091
- Peer: Puerto 51413 (TCP/UDP)

## Uso

### Directorios
- `/downloads/complete/` - Descargas completadas
- `/downloads/incomplete/` - Descargas en progreso
- `/watch/` - Torrents automáticos

### Configuración de Red
- Port Forwarding: 51413
- Encryption: Preferido
- DHT y PEX: Habilitados

### Automatización
- Watch Directory
- RSS vía Flexget
- Scripts post-descarga

## Mantenimiento

### Verificar Estado
```bash
docker compose ps transmission
docker compose logs -f transmission
```

### Actualización
1. Backup de configuración:
   ```bash
   cp -r transmission/ backup/
   ```
2. Actualizar imagen:
   ```bash
   docker compose down
   docker compose pull
   docker compose up -d
   ```

### Problemas Comunes
1. **Velocidad Baja**
   - Verificar port forwarding
   - Comprobar límites de ancho de banda
   - Revisar peers disponibles

2. **Error de Permisos**
   - Verificar PUID/PGID
   - Comprobar permisos en directorios
   - Revisar ownership de archivos

3. **Web UI No Accesible**
   - Verificar configuración de Traefik 
   - Comprobar autenticación
   - Revisar logs del servicio

## Backup

### Datos a Respaldar
- `/transmission/` - Configuración completa
- `settings.json` - Preferencias
- `torrents/` - Estado de descargas
- `resume/` - Datos de progreso

### Restauración
1. Detener servicio:
   ```bash
   docker compose down
   ```
2. Restaurar configuración:
   ```bash
   cp -r backup/transmission/ ./
   ```
3. Verificar permisos:
   ```bash
   chown -R 1000:1000 transmission/
   ```
4. Reiniciar servicio:
   ```bash
   docker compose up -d
   ```

### Verificación
1. Acceder a interfaz web
2. Comprobar descargas activas
3. Verificar directorios
4. Probar nueva descarga
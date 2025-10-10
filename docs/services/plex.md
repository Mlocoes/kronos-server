# Plex Media Server

## Descripción
Plex Media Server es el servidor de streaming multimedia que gestiona y transmite contenido de video, música y fotos.

## Ubicación
- Directorio: `/plex/`
- Configuración: `/plex/config/`
- Biblioteca: `/mnt/media/`

## Configuración

### docker-compose.yml
```yaml
services:
  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: plex
    network_mode: host
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ}
      - VERSION=docker
      - PLEX_CLAIM=${PLEX_CLAIM}
    volumes:
      - ./config:/config
      - ${MOVIES_PATH}:/data/movies
      - ${TV_PATH}:/data/tv
      - ${MUSIC_PATH}:/data/music
    devices:
      - /dev/dri:/dev/dri
    restart: unless-stopped
```

### Variables de Entorno
```env
TZ=America/Lima
PLEX_CLAIM=claim-XXXXX
MOVIES_PATH=/mnt/media/Movies
TV_PATH=/mnt/media/TV
MUSIC_PATH=/mnt/media/Music
```

## Acceso
- Local: `http://localhost:32400/web`
- Remoto: `https://app.plex.tv/`
- Puertos:
  - 32400/tcp - Acceso web
  - 1900/udp - DLNA
  - 32469/tcp - DLNA
  - 32410-32414/udp - GDM

## Uso

### Configuración Inicial
1. Reclamar servidor
2. Configurar bibliotecas
3. Organizar contenido

### Bibliotecas
- Películas
  - Estructura: `/movies/Movie Name (Year)/Movie.mkv`
  - Metadata: NFO, posters
- Series TV
  - Estructura: `/tv/Show Name/Season XX/Episode.mkv`
  - Metadata: TheTVDB
- Música
  - Estructura: `/music/Artist/Album/Track.mp3`
  - Metadata: ID3, artwork

### Transcoding
- Hardware: Intel QuickSync
- Calidad: Automática
- Límites: Configurables

## Mantenimiento

### Verificar Estado
```bash
docker compose ps plex
docker compose logs -f plex
```

### Actualización
1. Backup de configuración:
   ```bash
   cp -r config/ backup/
   ```
2. Actualizar imagen:
   ```bash
   docker compose down
   docker compose pull
   docker compose up -d
   ```

### Problemas Comunes
1. **No Accesible**
   - Verificar estado del servicio
   - Comprobar red host
   - Revisar logs

2. **Transcoding Lento**
   - Verificar aceleración por hardware
   - Comprobar recursos disponibles
   - Ajustar calidad de streaming

3. **Biblioteca No Actualiza**
   - Verificar permisos de archivos
   - Comprobar escaneo de biblioteca
   - Revisar logs de análisis

## Backup

### Datos a Respaldar
- `/plex/config/` - Configuración y base de datos
- Preferencias de usuario
- Metadata personalizada

### Restauración
1. Detener servicio:
   ```bash
   docker compose down
   ```
2. Restaurar configuración:
   ```bash
   cp -r backup/config/ ./
   ```
3. Verificar permisos:
   ```bash
   chown -R 1000:1000 config/
   ```
4. Reiniciar servicio:
   ```bash
   docker compose up -d
   ```

### Verificación
1. Acceder a interfaz web
2. Comprobar bibliotecas
3. Verificar metadata
4. Probar transcoding
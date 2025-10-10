# Flexget

## Descripción
Flexget es el automatizador de descargas que gestiona la obtención y organización de contenido multimedia mediante RSS y otras fuentes.

## Ubicación
- Directorio: `/flexget/`
- Configuración: `/flexget/flexget/config.yml`
- Scripts: `/flexget/flexget/custom-cont-init.d/`

## Configuración

### docker-compose.yml
```yaml
services:
  flexget:
    build: .
    container_name: flexget
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ}
      - FG_WEBUI_PASSWD=${FLEXGET_PASSWORD}
    volumes:
      - ./flexget:/config
      - ${DOWNLOADS_PATH}:/downloads
      - ${LIBRARY_PATH}:/library
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.flexget-secure.entrypoints=https"
      - "traefik.http.routers.flexget-secure.rule=Host(`${FLEX_URL}`)"
      - "traefik.http.routers.flexget-secure.tls=true"
      - "traefik.http.routers.flexget-secure.tls.certresolver=myresolver"
      - "traefik.http.services.flexget.loadbalancer.server.port=5050"
    networks:
      kronos-net: {}
```

### Variables de Entorno
```env
TZ=America/Lima
FLEXGET_PASSWORD=password
FLEX_URL=flexget.kronos.cloudns.ph
DOWNLOADS_PATH=/mnt/downloads
LIBRARY_PATH=/mnt/media
```

### config.yml
```yaml
web_server:
  bind: 0.0.0.0
  port: 5050
  web_ui: yes

tasks:
  download_tv:
    rss: file:///config/received/eztvrss-eztv.to.xml
    regexp:
      reject:
        - \b(720p|1080p)\b: {from: title}
    series:
      settings:
        shows:
          quality: webdl|hdtv
          propers: yes
      shows:
        - Show Name 1
        - Show Name 2
    transmission:
      host: transmission
      port: 9091
      username: '{{secrets.transmission.user}}'
      password: '{{secrets.transmission.pass}}'
```

## Acceso
- Web UI: `https://flexget.kronos.cloudns.ph`
- CLI: Dentro del contenedor

## Uso

### Tareas Configuradas
- Series TV via RSS
- Películas vía IMDb
- Música vía RSS

### Filtros
- Calidad de video
- Tamaño de archivo
- Fuentes confiables

### Procesamiento
- Renombrado automático
- Organización en carpetas
- Notificaciones

## Mantenimiento

### Verificar Estado
```bash
docker compose ps flexget
docker compose logs -f flexget
```

### Actualización
1. Backup de configuración:
   ```bash
   cp -r flexget/ backup/
   ```
2. Reconstruir imagen:
   ```bash
   docker compose down
   docker compose build --no-cache
   docker compose up -d
   ```

### Problemas Comunes
1. **Tareas No Ejecutan**
   - Verificar configuración RSS
   - Comprobar schedule
   - Revisar logs de tareas

2. **Error de Transmisión**
   - Verificar conexión con Transmission
   - Comprobar credenciales
   - Revisar permisos

3. **Web UI No Responde**
   - Verificar configuración de Traefik
   - Comprobar estado del contenedor
   - Revisar logs del servicio

## Backup

### Datos a Respaldar
- `/flexget/` - Configuración completa
- `config.yml` - Tareas y filtros
- Base de datos - Estado de series
- Scripts personalizados

### Restauración
1. Detener servicio:
   ```bash
   docker compose down
   ```
2. Restaurar configuración:
   ```bash
   cp -r backup/flexget/ ./
   ```
3. Verificar permisos:
   ```bash
   chown -R 1000:1000 flexget/
   ```
4. Reconstruir y reiniciar:
   ```bash
   docker compose build
   docker compose up -d
   ```

### Verificación
1. Acceder a Web UI
2. Ejecutar tarea de prueba
3. Verificar descarga en Transmission
4. Comprobar procesamiento
# Immich

## Descripción
Immich es un servicio de backup y gestión de fotos y videos, auto-hospedado y con soporte para aplicaciones móviles.

## Ubicación
- Directorio: `/immich-app/`
- Docker Compose: `docker-compose.yml`
- Aceleración por Hardware: `hwaccel.ml.yml`, `hwaccel.transcoding.yml`

## Configuración

### docker-compose.yml
```yaml
services:
  immich-server:
    container_name: immich-server
    image: ghcr.io/immich-app/immich-server:${IMMICH_VERSION}
    command: ["start.sh", "immich"]
    volumes:
      - ${UPLOAD_LOCATION}:/usr/src/app/upload
      - /etc/localtime:/etc/localtime:ro
    env_file:
      - .env
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.immich-secure.entrypoints=https"
      - "traefik.http.routers.immich-secure.rule=Host(`${IMMICH_URL}`)"
      - "traefik.http.routers.immich-secure.tls=true"
      - "traefik.http.routers.immich-secure.tls.certresolver=myresolver"
      - "traefik.http.services.immich.loadbalancer.server.port=3001"
    depends_on:
      - redis
      - database
      - typesense
```

### Variables de Entorno
```env
# Versión
IMMICH_VERSION=release

# Ubicaciones
UPLOAD_LOCATION=/mnt/media/Photos
DB_DATA_LOCATION=/mnt/data/immich/database

# Base de datos
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_DATABASE_NAME=immich

# URLs
IMMICH_URL=photos.kronos.cloudns.ph

# Redis
REDIS_HOSTNAME=redis
REDIS_PASSWORD=redis_password

# Machine Learning
MACHINE_LEARNING_ENABLED=true
```

## Acceso
- Web: `https://photos.kronos.cloudns.ph`
- API: `https://photos.kronos.cloudns.ph/api`
- App Móvil:
  - Android: Play Store
  - iOS: App Store

## Uso

### Configuración Inicial
1. Crear cuenta de administrador
2. Configurar ubicaciones de almacenamiento
3. Habilitar características deseadas

### Gestión de Bibliotecas
- Importar colecciones existentes
- Organizar por álbumes
- Compartir colecciones

### Machine Learning
- Reconocimiento facial
- Etiquetado automático
- Búsqueda inteligente

## Mantenimiento

### Verificar Estado
```bash
docker compose ps
docker compose logs -f immich-server
```

### Backup
Usar script dedicado:
```bash
./scripts/backup_immich.sh
```

### Actualización
1. Backup previo:
   ```bash
   ./scripts/backup_immich.sh
   ```
2. Actualizar imágenes:
   ```bash
   docker compose down
   docker compose pull
   docker compose up -d
   ```

### Problemas Comunes
1. **Error de Base de Datos**
   - Verificar conexión PostgreSQL
   - Comprobar permisos
   - Revisar logs de la DB

2. **Fallo en Uploads**
   - Verificar permisos en UPLOAD_LOCATION
   - Comprobar espacio disponible
   - Revisar logs del servidor

3. **ML No Funciona**
   - Verificar estado del servicio ML
   - Comprobar recursos disponibles
   - Revisar configuración de GPU

## Backup y Restauración

### Backup Automático
El script `backup_immich.sh` realiza:
- Backup de la base de datos
- Copia de archivos multimedia
- Backup de configuración

### Restauración
Usar script dedicado:
```bash
./scripts/restaurar_immich.sh
```

### Verificación Post-Restauración
1. Comprobar acceso web
2. Verificar integridad de la biblioteca
3. Validar metadatos y etiquetas
4. Comprobar funciones ML
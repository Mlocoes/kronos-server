# Traefik

## Descripción
Traefik actúa como punto de entrada único para todos los servicios web del sistema, gestionando SSL y enrutamiento.

## Ubicación
- Directorio: `/traefik/`
- Configuración: `/traefik/data/traefik.yml`
- Certificados: `/traefik/data/acme.json`
- Token Cloudflare: `/traefik/cf_api_token.txt`

## Configuración

### docker-compose.yml
```yaml
version: '3'
services:
  traefik:
    image: traefik:latest
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - kronos-net
    ports:
      - 80:80
      - 443:443
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./data/traefik.yml:/traefik.yml:ro
      - ./data/acme.json:/acme.json
    environment:
      - CF_API_TOKEN_FILE=/run/secrets/cf_api_token
    secrets:
      - cf_api_token
```

### traefik.yml
```yaml
api:
  dashboard: true
  debug: true

entryPoints:
  http:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: https
          scheme: https
  https:
    address: ":443"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false

certificatesResolvers:
  cloudflare:
    acme:
      email: admin@kronos.cloudns.ph
      storage: acme.json
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
```

## Acceso
- Dashboard: `https://traefik.kronos.cloudns.ph`
- API: `https://traefik.kronos.cloudns.ph/api`

## Uso

### Labels para Servicios
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.servicio.rule=Host(\`servicio.kronos.cloudns.ph\`)"
  - "traefik.http.routers.servicio.entrypoints=https"
  - "traefik.http.routers.servicio.tls.certresolver=cloudflare"
```

### Middlewares Comunes
```yaml
# Seguridad básica
- "traefik.http.middlewares.secure-headers.headers.forceSTSHeader=true"
- "traefik.http.middlewares.secure-headers.headers.stsSeconds=31536000"

# Autenticación
- "traefik.http.middlewares.auth.basicauth.users=admin:$$apr1$$xyz..."
```

## Mantenimiento

### Verificar Estado
```bash
docker compose ps traefik
docker compose logs -f traefik
```

### Renovación de Certificados
- Automática vía Cloudflare DNS
- Verificar permisos de acme.json: `600`
- Monitorear logs por errores

### Problemas Comunes
1. **Error de Certificados**
   - Verificar token de Cloudflare
   - Comprobar permisos de acme.json
   - Revisar registros DNS

2. **Servicio No Accesible**
   - Verificar labels del servicio
   - Comprobar red Docker
   - Revisar logs de Traefik

3. **Dashboard No Disponible**
   - Verificar configuración en traefik.yml
   - Comprobar middleware de autenticación
   - Revisar registros DNS

## Backup

### Archivos a Respaldar
- `data/traefik.yml`
- `data/acme.json`
- `cf_api_token.txt`

### Restauración
```bash
# Detener Traefik
docker compose down

# Restaurar archivos
cp backup/traefik.yml data/
cp backup/acme.json data/
chmod 600 data/acme.json

# Iniciar servicio
docker compose up -d
```
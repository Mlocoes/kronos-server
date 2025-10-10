# Cloudflare DDNS

## Descripción
Servicio que mantiene actualizada la IP pública del servidor en los registros DNS de Cloudflare, permitiendo acceso remoto consistente.

## Ubicación
- Directorio: `/cloudflare/`
- Configuración: `docker-compose.yml`
- Credenciales: Variables de entorno

## Configuración

### docker-compose.yml
```yaml
services:
  cloudflare-ddns:
    image: oznu/cloudflare-ddns:latest
    container_name: cloudflare-ddns
    restart: unless-stopped
    environment:
      - API_TOKEN=${CF_API_TOKEN}
      - ZONE=${CF_ZONE}
      - SUBDOMAIN=${CF_SUBDOMAIN}
      - PROXIED=${CF_PROXIED}
    networks:
      kronos-net: {}
```

### Variables de Entorno
```env
# Token de API de Cloudflare
CF_API_TOKEN=your_cloudflare_api_token

# Zona DNS (dominio principal)
CF_ZONE=kronos.cloudns.ph

# Subdominio a actualizar
CF_SUBDOMAIN=*

# Proxy de Cloudflare
CF_PROXIED=true
```

## Acceso
- No requiere acceso directo
- Logs vía docker logs
- Estado vía Cloudflare Dashboard

## Uso

### Registros DNS
- Tipo A para IPv4
- Tipo AAAA para IPv6 (si está habilitado)
- Proxied para servicios web

### Intervalos de Actualización
- Cada 5 minutos por defecto
- Al detectar cambio de IP
- Forzado vía reinicio

### Monitoreo
- Logs del contenedor
- Panel de Cloudflare
- Estado de proxied

## Mantenimiento

### Verificar Estado
```bash
docker compose ps cloudflare-ddns
docker compose logs -f cloudflare-ddns
```

### Actualización
1. Actualizar imagen:
   ```bash
   docker compose down
   docker compose pull
   docker compose up -d
   ```

### Problemas Comunes
1. **No Actualiza DNS**
   - Verificar token de API
   - Comprobar permisos en Cloudflare
   - Revisar logs por errores

2. **Error de Autenticación**
   - Validar token de API
   - Verificar zona DNS
   - Comprobar permisos de token

3. **Servicios No Accesibles**
   - Verificar estado de proxy
   - Comprobar reglas de firewall
   - Revisar SSL/TLS en Cloudflare

## Backup

### Datos a Respaldar
- Variables de entorno
- Token de API (seguro)
- Configuración de proxy

### Restauración
1. Configurar variables:
   ```bash
   cp backup/.env .env
   ```
2. Verificar token:
   ```bash
   docker compose up -d
   docker compose logs -f
   ```

### Verificación
1. Comprobar actualización DNS:
   ```bash
   dig +short kronos.cloudns.ph @1.1.1.1
   ```
2. Verificar registros en Cloudflare
3. Probar acceso a servicios
4. Monitorear logs por errores

## Seguridad

### Token de API
- Permisos mínimos necesarios
- Rotación periódica
- Almacenamiento seguro

### Proxy Settings
- HTTPS obligatorio
- WAF habilitado
- Rate limiting configurado

### Monitoreo
- Alertas de cambios de IP
- Logs de actualizaciones
- Estado de servicios proxied
# Pi-hole

## Descripción
Pi-hole actúa como servidor DNS y bloqueador de publicidad a nivel de red para todo el sistema Kronos.

## Ubicación
- Directorio: `/pihole/`
- Configuración: `/pihole/etc-pihole/`
- DNS Config: `/pihole/etc-dnsmasq.d/`
- Variables: `.env`

## Configuración

### docker-compose.yml
```yaml
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    restart: unless-stopped
    environment:
      TZ: ${TZ}
      WEBPASSWORD: ${PIHOLE_PASSWORD}
      ServerIP: ${PIHOLE_SERVER_IP}
    volumes:
      - ./etc-pihole:/etc/pihole
      - ./etc-dnsmasq.d:/etc/dnsmasq.d
    networks:
      kronos-net:
        ipv4_address: 172.20.0.2
    dns:
      - 127.0.0.1
      - 1.1.1.1
    cap_add:
      - NET_ADMIN
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.pihole-secure.entrypoints=https"
      - "traefik.http.routers.pihole-secure.rule=Host(`${PIHOLE_URL}`)"
      - "traefik.http.routers.pihole-secure.tls=true"
      - "traefik.http.routers.pihole-secure.tls.certresolver=myresolver"
      - "traefik.http.services.pihole.loadbalancer.server.port=80"
```

### Variables de Entorno
```env
TZ=America/Lima
PIHOLE_PASSWORD=tu_contraseña_segura
PIHOLE_SERVER_IP=172.20.0.2
PIHOLE_URL=pihole.kronos.cloudns.ph
```

## Acceso
- Dashboard: `https://pihole.kronos.cloudns.ph/admin`
- DNS: `172.20.0.2`
- Puertos: 
  - 53/tcp - DNS
  - 53/udp - DNS
  - 80/tcp - Web Interface

## Uso

### Configuración DNS
1. Usar `172.20.0.2` como servidor DNS primario
2. Configurar DNS secundario (ej: 1.1.1.1)
3. Verificar resolución de nombres

### Listas de Bloqueo
- Administrar listas negras/blancas
- Añadir fuentes personalizadas
- Monitorear estadísticas

### Registros
- Consultar queries DNS
- Analizar bloqueos
- Exportar estadísticas

## Mantenimiento

### Verificar Estado
```bash
docker compose ps pihole
docker compose logs -f pihole
```

### Actualización
1. Backup de configuración:
   ```bash
   cp -r etc-pihole/ backup/
   cp -r etc-dnsmasq.d/ backup/
   ```
2. Actualizar imagen:
   ```bash
   docker compose down
   docker compose pull
   docker compose up -d
   ```

### Problemas Comunes
1. **DNS No Responde**
   - Verificar estado del contenedor
   - Comprobar configuración de red
   - Revisar logs por errores

2. **Dashboard Inaccesible**
   - Verificar configuración de Traefik
   - Comprobar contraseña de admin
   - Revisar logs de acceso

3. **Alto Uso de Recursos**
   - Limpiar base de datos
   - Optimizar listas de bloqueo
   - Considerar limitar retención de logs

## Backup

### Datos a Respaldar
- `/pihole/etc-pihole/` - Configuración principal
- `/pihole/etc-dnsmasq.d/` - Configuración DNS
- Lista de dominios personalizados
- Contraseña de administración

### Restauración
1. Detener servicio:
   ```bash
   docker compose down
   ```
2. Restaurar directorios:
   ```bash
   cp -r backup/etc-pihole/ ./
   cp -r backup/etc-dnsmasq.d/ ./
   ```
3. Verificar permisos:
   ```bash
   chown -R root:root etc-pihole/
   chown -R root:root etc-dnsmasq.d/
   ```
4. Reiniciar servicio:
   ```bash
   docker compose up -d
   ```

### Verificación
1. Comprobar resolución DNS:
   ```bash
   dig @172.20.0.2 google.com
   ```
2. Verificar bloqueos:
   ```bash
   dig @172.20.0.2 doubleclick.net
   ```
3. Acceder al dashboard y revisar estadísticas
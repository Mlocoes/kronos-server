# Postie (Poste.io)

## Descripción
Postie (Poste.io) es el servidor de correo completo que proporciona servicios SMTP, IMAP y webmail para el sistema Kronos.

## Ubicación
- Directorio: `/postie/`
- Base de Datos: `/postie/data/`
- Scripts: `/postie/scripts/`

## Configuración

### docker-compose.yml
```yaml
services:
  mailserver:
    image: analogic/poste.io
    container_name: postie
    restart: unless-stopped
    environment:
      - TZ=${POSTEIO_TZ}
      - h=${POSTEIO_HOSTNAME}
      - DISABLE_CLAMAV=TRUE
      - DISABLE_LETSENCRYPT=TRUE
      - HTTPS=OFF
    volumes:
      - ${POSTEIO_BASE_DADOS}:/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.mailserver-secure.entrypoints=https"
      - "traefik.http.routers.mailserver-secure.rule=Host(`${POSTEIO_HOSTNAME}`)"
      - "traefik.http.routers.mailserver-secure.service=mailserver"
      - "traefik.http.routers.mailserver-secure.tls=true"
      - "traefik.http.services.mailserver-secure.loadbalancer.server.port=443"
      - "traefik.http.routers.mailserver-secure.tls.certresolver=myresolver"

      # SMTP
      - "traefik.tcp.routers.smtp.rule=HostSNI(`*`)"
      - "traefik.tcp.routers.smtp.entrypoints=smtp"
      - "traefik.tcp.services.smtp.loadbalancer.server.port=25"
      - "traefik.tcp.routers.smtp.service=smtp"

      # SUBMISSION
      - "traefik.tcp.routers.submission.rule=HostSNI(`*`)"
      - "traefik.tcp.routers.submission.entrypoints=submission"
      - "traefik.tcp.services.submission.loadbalancer.server.port=587"
      - "traefik.tcp.routers.submission.service=submission"

      # IMAPS
      - "traefik.tcp.routers.imaps.rule=HostSNI(`*`)"
      - "traefik.tcp.routers.imaps.entrypoints=imaps"
      - "traefik.tcp.services.imaps.loadbalancer.server.port=993"
      - "traefik.tcp.routers.imaps.service=imaps"
```

### Variables de Entorno
```env
POSTEIO_TZ=America/Lima
POSTEIO_HOSTNAME=mail.kronos.cloudns.ph
POSTEIO_BASE_DADOS=/mnt/data/postie
```

## Acceso
- Webmail: `https://mail.kronos.cloudns.ph`
- Admin: `https://mail.kronos.cloudns.ph/admin`
- Puertos:
  - 25/tcp - SMTP
  - 587/tcp - SUBMISSION
  - 993/tcp - IMAPS
  - 443/tcp - HTTPS

## Uso

### Configuración DNS
```
# Registros MX
mail.kronos.cloudns.ph. IN MX 10 mail.kronos.cloudns.ph.

# SPF
kronos.cloudns.ph. IN TXT "v=spf1 mx -all"

# DKIM
mail._domainkey.kronos.cloudns.ph. IN TXT "v=DKIM1; k=rsa; p=..."

# DMARC
_dmarc.kronos.cloudns.ph. IN TXT "v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s;"
```

### Gestión de Dominios
- Añadir/eliminar dominios
- Configurar DNS
- Verificar DKIM/SPF

### Usuarios y Buzones
- Crear/eliminar usuarios
- Establecer cuotas
- Gestionar aliases

## Mantenimiento

### Verificar Estado
```bash
docker compose ps postie
docker compose logs -f postie
```

### Backup
Usar script dedicado:
```bash
./scripts/backup_posteio.sh
```

### Actualización
1. Backup previo:
   ```bash
   ./scripts/backup_posteio.sh
   ```
2. Actualizar imagen:
   ```bash
   docker compose down
   docker compose pull
   docker compose up -d
   ```

### Problemas Comunes
1. **Envío Fallido**
   - Verificar configuración DNS
   - Comprobar registros SPF/DKIM
   - Revisar logs SMTP

2. **Recepción Fallida**
   - Verificar registro MX
   - Comprobar firewalls
   - Revisar logs de recepción

3. **Webmail No Accesible**
   - Verificar configuración de Traefik
   - Comprobar certificados SSL
   - Revisar logs del servicio

## Backup y Restauración

### Backup Automático
El script `backup_posteio.sh` realiza:
- Backup de la base de datos
- Copia de buzones
- Backup de configuración

### Restauración
Usar script dedicado:
```bash
./scripts/restaurar_posteio.sh
```

### Verificación
1. Probar envío de correo
2. Verificar recepción
3. Acceder a webmail
4. Comprobar admin panel

## Seguridad

### SSL/TLS
- Certificados vía Traefik
- STARTTLS habilitado
- Cipher suites seguros

### Autenticación
- SASL requerido
- Contraseñas seguras
- Rate limiting

### Spam/Malware
- Listas negras
- Greylisting
- SPF/DKIM/DMARC
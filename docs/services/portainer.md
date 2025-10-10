# Portainer

## Descripción
Portainer es la interfaz de gestión de contenedores Docker que permite administrar el sistema Kronos de forma visual.

## Ubicación
- Directorio: `/portainer/`
- Datos: `/portainer/data/`
- Configuración: Variables de entorno en `.env`

## Configuración

### docker-compose.yml
```yaml
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./data:/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.portainer-secure.entrypoints=https"
      - "traefik.http.routers.portainer-secure.rule=Host(`${PORTAINER_URL}`)"
      - "traefik.http.routers.portainer-secure.tls=true"
      - "traefik.http.routers.portainer-secure.tls.certresolver=myresolver"
      - "traefik.http.routers.portainer-secure.service=portainer"
      - "traefik.http.services.portainer.loadbalancer.server.port=9000"
    networks:
      kronos-net: {}
    dns:
      - 172.20.0.2  # Usa Pi-hole como DNS
```

### Variables de Entorno
```env
PORTAINER_URL=portainer.kronos.cloudns.ph
```

## Acceso
- URL: `https://portainer.kronos.cloudns.ph`
- Puerto: 9000
- Autenticación: Usuario y contraseña definidos en la primera ejecución

## Uso

### Gestión de Contenedores
- Vista general de contenedores
- Estado y logs
- Iniciar/detener/reiniciar contenedores
- Acceso a consola

### Gestión de Volúmenes
- Crear/eliminar volúmenes
- Monitorear espacio
- Limpiar volúmenes no utilizados

### Redes
- Visualizar redes Docker
- Crear/eliminar redes
- Conectar contenedores

## Mantenimiento

### Verificar Estado
```bash
docker compose ps portainer
docker compose logs -f portainer
```

### Actualización
1. Detener servicio:
   ```bash
   docker compose down
   ```
2. Actualizar imagen:
   ```bash
   docker compose pull
   ```
3. Reiniciar servicio:
   ```bash
   docker compose up -d
   ```

### Problemas Comunes
1. **No Accesible**
   - Verificar estado del contenedor
   - Comprobar configuración de Traefik
   - Revisar logs

2. **Error de Permisos**
   - Verificar permisos de /var/run/docker.sock
   - Comprobar permisos del directorio data/

3. **Rendimiento Lento**
   - Limpiar logs antiguos
   - Verificar uso de recursos
   - Considerar limpieza de volúmenes

## Backup

### Datos a Respaldar
- `/portainer/data/` - Configuración y datos de Portainer
- Credenciales de acceso (respaldo seguro)

### Restauración
1. Detener servicio:
   ```bash
   docker compose down
   ```
2. Restaurar directorio data:
   ```bash
   cp -r backup/data/ ./
   ```
3. Verificar permisos:
   ```bash
   chown -R root:root data/
   ```
4. Reiniciar servicio:
   ```bash
   docker compose up -d
   ```
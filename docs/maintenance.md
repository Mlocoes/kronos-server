# Mantenimiento del Sistema

## Tareas Diarias Automatizadas

### Backups
- Ejecutados automáticamente a las 2 AM
- Script: `run_all_backups.sh`
- Logs en `/var/log/kronos/backups/`

### Monitoreo
- Verificación de servicios vía Portainer
- Logs de sistema
- Reportes de estado

## Tareas Semanales

### Limpieza
- Rotación de backups antiguos (>7 días)
- Limpieza de logs antiguos
- Verificación de espacio en disco

### Verificación
- Estado de certificados SSL
- Funcionamiento de DNS
- Estado de servicios críticos

## Tareas Mensuales

### Mantenimiento
- Verificación de actualizaciones de contenedores
- Pruebas de restauración
- Revisión de configuraciones

### Seguridad
- Revisión de logs de acceso
- Verificación de firewalls
- Actualización de listas de bloqueo

## Procedimientos

### Actualización de Servicios
1. Crear backup previo
2. Detener servicio: `docker compose down`
3. Actualizar imagen: `docker compose pull`
4. Iniciar servicio: `docker compose up -d`
5. Verificar funcionamiento

### Restauración de Backups
1. Seleccionar backup a restaurar
2. Elegir directorio destino
3. Ejecutar script de restauración
4. Verificar integridad

### Gestión de Logs
- Ubicación: `/var/log/kronos/`
- Rotación automática cada 30 días
- Compresión de logs antiguos

## Monitoreo

### Recursos
- CPU y memoria vía Portainer
- Espacio en disco
- Ancho de banda

### Servicios
- Estado de contenedores
- Tiempos de respuesta
- Errores y advertencias

### Red
- Tráfico DNS (Pi-hole)
- Conexiones activas
- Estado de certificados

## Resolución de Problemas

### Servicios Caídos
1. Verificar logs del servicio
2. Reiniciar contenedor
3. Verificar dependencias
4. Restaurar desde backup si es necesario

### Problemas de Red
1. Verificar Traefik
2. Comprobar DNS
3. Verificar certificados SSL
4. Revisar firewall

### Errores de Backup
1. Verificar espacio en disco
2. Comprobar permisos
3. Revisar logs
4. Ejecutar backup manual

# Scripts de Mantenimiento

## Scripts Principales

### Backup y Restauración

#### backup_kronos.sh
Script principal de backup del sistema completo.
```bash
./scripts/backup_kronos.sh
```
- Respalda todos los servicios
- Guarda configuraciones
- Crea snapshot de bases de datos
- Archiva datos críticos

#### backup_immich.sh
Backup específico del servicio Immich.
```bash
./scripts/backup_immich.sh
```
- Respalda base de datos PostgreSQL
- Copia archivos multimedia
- Guarda configuración y metadatos
- Genera registro de backup

#### backup_posteio.sh
Backup del servidor de correo.
```bash
./scripts/backup_posteio.sh
```
- Respalda buzones de correo
- Guarda configuración de dominios
- Backup de bases de datos
- Preserva certificados y claves

#### run_all_backups.sh
Ejecuta todos los backups secuencialmente.
```bash
./scripts/run_all_backups.sh
```
- Coordina backups individuales
- Verifica espacio disponible
- Genera logs consolidados
- Notifica resultados

### Restauración

#### restaurar_kronos.sh
Restauración completa del sistema.
```bash
./scripts/restaurar_kronos.sh
```
- Restaura servicios
- Recupera configuraciones
- Reconstruye bases de datos
- Verifica integridad

#### restaurar_immich.sh
Restauración específica de Immich.
```bash
./scripts/restaurar_immich.sh
```
- Restaura base de datos
- Recupera archivos multimedia
- Reconstruye índices
- Verifica metadatos

#### restaurar_posteio.sh
Restauración del servidor de correo.
```bash
./scripts/restaurar_posteio.sh
```
- Restaura buzones
- Recupera configuraciones
- Reconstruye índices
- Verifica DNS y certificados

### Configuración

#### configure_email.sh
Configuración del sistema de notificaciones.
```bash
./scripts/configure_email.sh
```
- Configura servidor SMTP
- Establece destinatarios
- Define plantillas
- Prueba conexión

## Ubicación de Backups

### Estructura
```
/mnt/backup/
├── kronos/
│   ├── YYYY-MM-DD/
│   │   ├── config/
│   │   ├── data/
│   │   └── databases/
├── immich/
│   ├── YYYY-MM-DD/
│   │   ├── db/
│   │   └── media/
└── postie/
    └── YYYY-MM-DD/
        ├── mail/
        └── config/
```

### Retención
- Diario: 7 días
- Semanal: 4 semanas
- Mensual: 12 meses
- Anual: 2 años

## Programación

### Backups Automáticos
```bash
# Ejemplo de entrada crontab
# Backup diario a las 2 AM
0 2 * * * /home/mloco/kronos-server/scripts/run_all_backups.sh

# Limpieza mensual de backups antiguos
0 3 1 * * /home/mloco/kronos-server/scripts/clean_old_backups.sh
```

## Notificaciones

### Eventos Notificados
- Inicio/fin de backups
- Errores durante backup
- Espacio insuficiente
- Restauraciones completadas

### Configuración de Correo
```bash
# Archivo: /home/mloco/kronos-server/scripts/email.conf
SMTP_SERVER=mail.kronos.cloudns.ph
SMTP_PORT=587
SMTP_USER=admin
SMTP_PASS=****
NOTIFY_EMAIL=admin@kronos.cloudns.ph
```

## Verificación

### Verificar Backup
```bash
# Verificar último backup
ls -l /mnt/backup/kronos/$(date +%Y-%m-%d)/

# Verificar logs
tail -f /var/log/kronos/backup.log
```

### Verificar Restauración
```bash
# Verificar servicios después de restauración
docker compose ps
docker compose logs
```

## Solución de Problemas

### Problemas Comunes

1. **Backup Fallido**
   - Verificar espacio en disco
   - Comprobar permisos
   - Revisar logs de error

2. **Restauración Incompleta**
   - Verificar integridad del backup
   - Comprobar dependencias
   - Revisar logs del sistema

3. **Notificaciones No Llegan**
   - Verificar configuración SMTP
   - Comprobar conexión
   - Revisar logs de correo
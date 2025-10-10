# Documentación de Kronos Server

## Índice

### 1. Documentación General
- [Visión General](./overview.md) - Arquitectura y componentes del sistema
- [Backups](./backups.md) - Sistema de respaldos y restauración
- [Mantenimiento](./maintenance.md) - Procedimientos de mantenimiento
- [Networking](./networking.md) - Configuración de red y DNS
- [Notificaciones](./email-notifications.md) - Configuración de alertas por correo

### 2. Servicios
- [Servicios](./services/README.md) - Documentación detallada de cada servicio

### 3. Scripts y Automatización
- [Scripts](./scripts.md) - Documentación de scripts de sistema

## Estructura del Sistema

```
kronos-server/
├── services/          # Servicios individuales
├── scripts/          # Scripts de mantenimiento
├── networks/         # Configuración de red
└── templates/        # Plantillas del sistema
```

## Directorios Principales

- `/mnt/backup` - Backups del sistema
- `/mnt/storage` - Almacenamiento principal
- `/home/mloco/kronos-server` - Directorio de instalación

## Mantenimiento del Sistema

### Backups Automáticos
Los backups se realizan automáticamente cada noche a las 2 AM mediante el script `run_all_backups.sh`.

### Actualizaciones
Las actualizaciones se gestionan a través de los scripts individuales de cada servicio.

### Monitoreo
El monitoreo se realiza a través de Portainer y los scripts de sistema.
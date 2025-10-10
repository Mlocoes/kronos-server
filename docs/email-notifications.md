# Configuración de Notificaciones por Correo

## Resumen
El sistema utiliza el comando `mail` para enviar notificaciones por correo sobre el estado de los backups. Para que esto funcione, necesitamos configurar el sistema de correo local para usar nuestro servidor Poste.io.

## Pasos de Configuración

### 1. Instalar las Herramientas Necesarias
```bash
sudo apt-get update
sudo apt-get install mailutils
```

### 2. Configurar el Servidor SMTP
Crear o editar el archivo `/etc/ssmtp/ssmtp.conf`:

```conf
# Servidor SMTP de Poste.io
root=admin@kronos.cloudns.ph
mailhub=localhost:25
hostname=kronos.cloudns.ph
FromLineOverride=YES
```

### 3. Configurar el Alias de Root
Editar `/etc/aliases`:
```text
root: admin@kronos.cloudns.ph
```

Luego ejecutar:
```bash
sudo newaliases
```

## Prueba de Configuración

Para probar que la configuración funciona:

```bash
echo "Prueba de correo" | mail -s "Test de Notificación" admin@kronos.cloudns.ph
```

## Configuración de Notificaciones

Los reportes de backup se enviarán automáticamente a:
- Destinatario: `root` (redirigido a admin@kronos.cloudns.ph)
- Asunto: "Kronos Backup Report YYYY-MM-DD"
- Contenido: Últimas 50 líneas del log de backup

## Personalización

Para cambiar el destinatario del correo, editar la última línea del script `run_all_backups.sh`:

```bash
tail -n 50 "$LOG_FILE" | mail -s "Kronos Backup Report $(date '+%Y-%m-%d')" admin@kronos.cloudns.ph
```

## Troubleshooting

### Verificar el Estado del Correo
```bash
# Verificar la cola de correo
mailq

# Verificar los logs de correo
sudo tail -f /var/log/mail.log
```

### Problemas Comunes
1. **No se envían correos**: Verificar que Poste.io esté funcionando
2. **Errores de SMTP**: Comprobar la configuración en ssmtp.conf
3. **Correos marcados como spam**: Verificar la configuración DKIM/SPF en Poste.io

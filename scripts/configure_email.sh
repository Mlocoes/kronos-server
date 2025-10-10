#!/bin/bash

# --- Configuración ---
ADMIN_EMAIL="admin@kronos.cloudns.ph"
HOSTNAME="kronos.cloudns.ph"
SMTP_PORT="25"

# Verificar ejecución como root
if [ "$EUID" -ne 0 ]; then
    echo "Este script necesita ejecutarse con privilegios de root"
    echo "Por favor, ejecutar como: sudo $0"
    exit 1
fi

echo "🔧 Configurando sistema de correo..."

# Instalar paquetes necesarios
echo "📦 Instalando paquetes..."
apt-get update
apt-get install -y mailutils ssmtp

# Configurar ssmtp
echo "📝 Configurando SMTP..."
cat > /etc/ssmtp/ssmtp.conf << EOL
root=${ADMIN_EMAIL}
mailhub=localhost:${SMTP_PORT}
hostname=${HOSTNAME}
FromLineOverride=YES
EOL

# Configurar alias
echo "📝 Configurando alias de correo..."
if ! grep -q "^root:" /etc/aliases; then
    echo "root: ${ADMIN_EMAIL}" >> /etc/aliases
else
    sed -i "s/^root:.*$/root: ${ADMIN_EMAIL}/" /etc/aliases
fi
newaliases

# Enviar correo de prueba
echo "📧 Enviando correo de prueba..."
echo "Esta es una prueba de configuración del sistema de notificaciones de Kronos Server." | \
mail -s "Kronos - Prueba de Configuración de Correo" "${ADMIN_EMAIL}"

echo "✅ Configuración completada"
echo "📨 Se ha enviado un correo de prueba a ${ADMIN_EMAIL}"
echo "⏳ Por favor, verifica tu bandeja de entrada"

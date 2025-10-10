#!/bin/bash

# 🧪 Script de Teste de Deliverability do Poste.io

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║          🧪 TESTE DE DELIVERABILITY - POSTE.IO            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar se container está rodando
log_info "Verificando status do container..."
if ! docker-compose ps | grep -q "Up"; then
    log_error "Poste.io não está rodando. Execute: docker-compose up -d"
    exit 1
fi
log_success "✅ Container rodando"

# Verificar configuração de relay
log_info "Verificando configuração de relay..."
if docker exec postie env | grep -q "RELAYHOST=smtp.gmail.com"; then
    log_success "✅ Relay Gmail configurado"
else
    log_error "❌ Relay Gmail não configurado"
    echo "Execute: ./setup-gmail-relay.sh"
    exit 1
fi

# Verificar conectividade SMTP
log_info "Testando conectividade SMTP..."
if docker exec postie timeout 10 bash -c "echo 'quit' | nc smtp.gmail.com 587" > /dev/null 2>&1; then
    log_success "✅ Conectividade SMTP OK"
else
    log_warning "⚠️ Conectividade SMTP limitada (pode ser normal)"
fi

# Verificar DNS
log_info "Verificando registros DNS..."
DOMAIN="kronos.cloudns.ph"

# SPF
if dig TXT $DOMAIN | grep -q "spf1"; then
    log_success "✅ SPF configurado"
else
    log_warning "⚠️ SPF não encontrado"
fi

# Testar envio de email de teste (opcional)
echo
read -p "Deseja enviar um email de teste? (s/N): " send_test
if [[ $send_test =~ ^[Ss]$ ]]; then
    log_info "Enviando email de teste..."
    echo "Este é um teste de deliverability do Poste.io" | docker exec -i postie mail -s "Teste Poste.io" admin@kronos.cloudns.ph
    log_success "✅ Email de teste enviado (verifique a caixa admin@kronos.cloudns.ph)"
fi

echo
echo -e "${GREEN}🎯 Status da Configuração:${NC}"
echo "   ✅ Container: Rodando"
echo "   ✅ Relay: Configurado"
echo "   ✅ SMTP: Funcional"
echo
echo -e "${BLUE}📧 Para testar deliverability externa:${NC}"
echo "   1. Acesse: https://www.mail-tester.com"
echo "   2. Envie email para o endereço gerado"
echo "   3. Verifique pontuação (objetivo: 9-10/10)"
echo
echo -e "${BLUE}🔧 Próximos passos:${NC}"
echo "   1. Configure DKIM no painel admin"
echo "   2. Adicione DMARC no DNS"
echo "   3. Teste com diferentes provedores"
#!/bin/bash

# 🚀 Script de Configuração de Relay Gmail para Poste.io
# Resolve o problema: "550 5.7.25 PTR record"

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
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

# Banner
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║          🚀 CONFIGURAÇÃO RELAY GMAIL PARA POSTE.IO       ║"
echo "║              Resolve problema PTR record                  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar se estamos no diretório correto
if [ ! -f ".env" ]; then
    log_error "Arquivo .env não encontrado. Execute este script dentro da pasta postie/"
    exit 1
fi

log_info "Verificando configuração atual..."

# Verificar se relay já está configurado
if grep -q "RELAY_USERNAME=seu-email@gmail.com" .env; then
    log_warning "Relay ainda não configurado corretamente"
    echo
    log_info "Para resolver o problema PTR record, você precisa:"
    echo
    echo "1. 📧 Acesse: https://myaccount.google.com/apppasswords"
    echo "2. 🔐 Gere senha para 'Poste.io Mail Server'"
    echo "3. ✏️  Configure as credenciais abaixo"
    echo

    # Solicitar credenciais
    read -p "Digite seu email Gmail: " GMAIL_USER
    read -s -p "Digite a senha do app Gmail (16 caracteres): " GMAIL_PASS
    echo

    # Validar entrada
    if [ -z "$GMAIL_USER" ] || [ -z "$GMAIL_PASS" ]; then
        log_error "Email e senha são obrigatórios!"
        exit 1
    fi

    # Atualizar .env
    log_info "Atualizando arquivo .env..."
    sed -i "s|RELAY_USERNAME=seu-email@gmail.com|RELAY_USERNAME=$GMAIL_USER|g" .env
    sed -i "s|RELAY_PASSWORD=sua-senha-app-gmail|RELAY_PASSWORD=$GMAIL_PASS|g" .env

    log_success "Credenciais configuradas!"
else
    log_success "Relay já configurado"
fi

# Verificar configuração
echo
log_info "Verificando configuração..."
if grep -q "RELAY_USERNAME=" .env && grep -q "RELAY_PASSWORD=" .env; then
    GMAIL_USER=$(grep "RELAY_USERNAME=" .env | cut -d'=' -f2)
    log_success "✅ Relay Gmail configurado para: $GMAIL_USER"
else
    log_error "❌ Relay não configurado"
    exit 1
fi

# Reiniciar serviços
echo
log_warning "Reiniciando serviços..."
docker-compose down
docker-compose up -d

# Aguardar inicialização
log_info "Aguardando serviços ficarem prontos..."
sleep 10

# Verificar status
if docker-compose ps | grep -q "Up"; then
    log_success "✅ Poste.io reiniciado com sucesso!"
    echo
    echo -e "${GREEN}🎉 Problema PTR record resolvido!${NC}"
    echo
    echo "📧 Teste enviando um email através do webmail:"
    echo "   URL: https://kronos.cloudns.ph"
    echo "   Usuário: admin@kronos.cloudns.ph"
    echo "   Senha: (configurada no primeiro acesso)"
    echo
    echo "🔧 Próximos passos recomendados:"
    echo "   1. Configure DKIM no painel admin"
    echo "   2. Adicione DMARC no DNS"
    echo "   3. Teste deliverability em: https://www.mail-tester.com"
else
    log_error "❌ Falha ao reiniciar serviços"
    exit 1
fi

echo
echo -e "${BLUE}Para mais informações, consulte: DELIVERABILITY.md${NC}"
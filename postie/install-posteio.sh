#!/bin/bash

# Script de instalação e configuração do Poste.io
# Autor: GitHub Copilot
# Data: Outubro 2025

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

# Verificar pré-requisitos
check_prerequisites() {
    log_info "Verificando pré-requisitos..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker não está instalado"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose não está instalado"
        exit 1
    fi

    # Verificar se Traefik está rodando
    if ! docker ps | grep -q traefik; then
        log_warning "Traefik não parece estar rodando. Certifique-se de que está configurado."
    fi

    log_success "Pré-requisitos verificados"
}

# Criar diretório de dados se não existir
setup_data_directory() {
    local data_dir="${POSTEIO_BASE_DADOS:-/mnt/mail}"

    if [ ! -d "$data_dir" ]; then
        log_info "Criando diretório de dados: $data_dir"
        sudo mkdir -p "$data_dir"
        sudo chown -R 1000:1000 "$data_dir" 2>/dev/null || true
    fi

    # Verificar se temos permissão de escrita
    if [ ! -w "$data_dir" ]; then
        log_warning "Sem permissão de escrita em $data_dir"
        log_info "Tentando ajustar permissões..."
        sudo chown -R $(id -u):$(id -g) "$data_dir" 2>/dev/null || {
            log_error "Não foi possível ajustar permissões. Execute como root ou ajuste manualmente:"
            echo "  sudo chown -R $(id -u):$(id -g) $data_dir"
            exit 1
        }
    fi

    log_success "Diretório de dados configurado: $data_dir"
}

# Backup dos dados existentes
backup_data() {
    local data_dir="${POSTEIO_BASE_DADOS:-/mnt/mail}"
    local backup_dir="${data_dir}/backup-$(date +%Y%m%d-%H%M%S)"

    if [ -d "$data_dir" ] && [ "$(ls -A $data_dir 2>/dev/null)" ]; then
        log_info "Criando backup dos dados existentes..."

        # Verificar se temos permissão para escrever no diretório pai
        if [ -w "$(dirname "$data_dir")" ]; then
            cp -r "$data_dir" "$backup_dir" 2>/dev/null && log_success "Backup criado em: $backup_dir" || {
                log_warning "Não foi possível criar backup automático"
                log_info "Dados existentes serão preservados no container"
            }
        else
            log_warning "Sem permissão para criar backup em $(dirname "$data_dir")"
            log_info "Tentando criar backup com sudo..."
            sudo cp -r "$data_dir" "$backup_dir" 2>/dev/null && log_success "Backup criado com sudo em: $backup_dir" || {
                log_warning "Não foi possível criar backup. Execute manualmente se necessário:"
                echo "  sudo cp -r $data_dir $backup_dir"
            }
        fi
    else
        log_info "Nenhum dado existente encontrado - primeiro instalação"
    fi
}

# Parar serviços existentes
stop_services() {
    if docker ps -q -f name=postie | grep -q .; then
        log_info "Parando serviço Poste.io existente..."
        docker-compose down
    fi
}

# Iniciar serviços
start_services() {
    log_info "Iniciando serviços Poste.io..."
    docker-compose up -d

    log_info "Aguardando inicialização..."
    sleep 30

    # Verificar se o serviço está saudável
    if docker ps -q -f name=postie | grep -q .; then
        log_success "Poste.io iniciado com sucesso"
    else
        log_error "Falha ao iniciar Poste.io"
        docker-compose logs postie
        exit 1
    fi
}

# Configurar DNS (informações)
show_dns_config() {
    local domain="${POSTEIO_HOSTNAME:-kronos.cloudns.ph}"

    echo
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}                    CONFIGURAÇÃO DNS RECOMENDADA               ${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${BLUE}Domínio:${NC} $domain"
    echo
    echo -e "${GREEN}Registros MX:${NC}"
    echo "  $domain.  MX  10 $domain."
    echo
    echo -e "${GREEN}Registros SPF:${NC}"
    echo "  $domain.  TXT  \"v=spf1 mx a:$domain -all\""
    echo
    echo -e "${GREEN}Registros DKIM:${NC}"
    echo "  mail._domainkey.$domain.  TXT  \"[DKIM key será gerado automaticamente]\""
    echo
    echo -e "${GREEN}Registros DMARC:${NC}"
    echo "  _dmarc.$domain.  TXT  \"v=DMARC1; p=quarantine; rua=mailto:admin@$domain\""
    echo
    echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
    echo "  - Configure o reverse DNS (PTR) no seu provedor"
    echo "  - IPs dinâmicos podem causar problemas de deliverability"
    echo "  - Considere usar um relay SMTP (Gmail, SendGrid, etc.)"
    echo
}

# Mostrar informações de acesso
show_access_info() {
    local domain="${POSTEIO_HOSTNAME:-kronos.cloudns.ph}"

    echo
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    POSTE.IO INSTALADO!                       ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${BLUE}🌐 Interface Web:${NC} https://$domain"
    echo -e "${BLUE}👤 Admin:${NC} admin@$domain"
    echo -e "${BLUE}🔑 Senha:${NC} admin (altere imediatamente!)"
    echo
    echo -e "${BLUE}📧 Configuração de Clientes:${NC}"
    echo "  SMTP: $domain:587 (TLS)"
    echo "  IMAP: $domain:993 (SSL)"
    echo "  POP3: $domain:995 (SSL)"
    echo
    echo -e "${YELLOW}⚠️  Problema Conhecido:${NC}"
    echo "  IPs dinâmicos podem causar rejeição de emails pelo Gmail"
    echo "  Considere configurar relay SMTP ou obter IP estático"
    echo
}

# Menu principal
main() {
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    POSTE.IO - INSTALAÇÃO                     ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo

    # Carregar variáveis de ambiente
    if [ -f .env ]; then
        source .env
    fi

    check_prerequisites
    setup_data_directory
    backup_data
    stop_services
    start_services
    show_dns_config
    show_access_info

    log_success "Instalação concluída!"
}

# Executar menu principal
main "$@"
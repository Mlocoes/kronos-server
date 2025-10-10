# 🚨 SOLUÇÃO URGENTE: Problema PTR Record

## ❌ Erro Atual do Gmail
```
Error: 550 5.7.25 [148.56.154.80] The IP address sending this message does not have a PTR record setup...
```

## ✅ Solução Rápida (5 minutos)

```bash
# 1. Execute o script de configuração
cd /home/mloco/kronos-server/postie
./setup-gmail-relay.sh

# 2. Siga as instruções na tela
# 3. Reinicie os serviços (automático)
```

**Resultado:** Emails enviados através do Gmail (PTR válido) ✅

---

# 📧 Poste.io - Servidor de Email

Servidor de email completo baseado em Docker, integrado com Traefik como proxy reverso.

## 🚀 Instalação Rápida

```bash
cd /home/mloco/kronos-server/postie
chmod +x install-posteio.sh
./install-posteio.sh
```

## 📋 Pré-requisitos

- Docker >= 20.10
- Docker Compose >= 1.29
- Traefik funcionando como proxy reverso
- Domínio configurado (Cloudns.ph ou similar)

## ⚙️ Configuração Atual

### Arquivo `.env`:
```bash
POSTEIO_HOSTNAME=kronos.cloudns.ph
POSTEIO_BASE_DADOS=/mnt/mail
POSTEIO_TZ=Europe/Madrid
```

### Características da Configuração:
- ✅ **Host Network**: Melhor compatibilidade com firewall
- ✅ **Traefik Integration**: SSL termination e roteamento
- ✅ **Antispam**: RSPAMD habilitado
- ✅ **Webmail**: Roundcube disponível
- ⚠️ **IP Dinâmico**: Pode causar problemas de deliverability

## 🌐 Acesso ao Sistema

Após a instalação:
- **Interface Web**: `https://kronos.cloudns.ph`
- **Usuário Admin**: `admin@kronos.cloudns.ph`
- **Senha**: `admin` (altere imediatamente!)

## 📧 Configuração de Clientes

### SMTP (Envio):
- **Servidor**: `kronos.cloudns.ph`
- **Porta**: `587` (TLS)
- **Autenticação**: Obrigatória

### IMAP (Recebimento):
- **Servidor**: `kronos.cloudns.ph`
- **Porta**: `993` (SSL)
- **Autenticação**: Obrigatória

### POP3 (Alternativo):
- **Servidor**: `kronos.cloudns.ph`
- **Porta**: `995` (SSL)

## 🔧 Configuração DNS Necessária

### Registros Essenciais:
```dns
# MX Record
kronos.cloudns.ph.  MX  10 kronos.cloudns.ph.

# SPF Record
kronos.cloudns.ph.  TXT  "v=spf1 mx a:kronos.cloudns.ph -all"

# DKIM (gerado automaticamente pelo Poste.io)
mail._domainkey.kronos.cloudns.ph.  TXT  "[chave-gerada]"

# DMARC
_dmarc.kronos.cloudns.ph.  TXT  "v=DMARC1; p=quarantine; rua=mailto:admin@kronos.cloudns.ph"
```

### ⚠️ Problema Crítico: IP Dinâmico

**Erro comum**: `550 5.7.25 The IP address... does not have a PTR record`

#### Causas:
- IPs gratuitos (Cloudns.ph, Cloudflare) não têm reverse DNS
- Gmail e outros provedores rejeitam emails sem PTR record

#### Soluções Possíveis:

1. **Obter IP Estático** (recomendado):
   - Contratar IP dedicado do seu provedor
   - Configurar reverse DNS (PTR record)

2. **Usar Relay SMTP** (alternativa temporária):
   ```bash
   # No .env, descomente e configure:
   RELAY_USERNAME=seu-email@gmail.com
   RELAY_PASSWORD=sua-senha-app-gmail
   ```

3. **Configurar SPF/DKIM/DMARC** (melhora deliverability):
   - Configure os registros DNS acima
   - Use ferramentas online para validar

## 🔄 Gerenciamento

### Comandos Úteis:
```bash
# Ver status
docker-compose ps

# Ver logs
docker-compose logs -f postie

# Reiniciar
docker-compose restart

# Backup dos dados
cp -r /mnt/mail /mnt/mail-backup-$(date +%Y%m%d)
```

### Atualização:
```bash
# Parar serviços
docker-compose down

# Fazer backup
cp -r /mnt/mail /mnt/mail-backup

# Atualizar imagem
docker-compose pull

# Reiniciar
docker-compose up -d
```

## 🛠️ Resolução de Problemas

### ❌ Emails rejeitados pelo Gmail:
1. Verifique se tem IP estático
2. Configure reverse DNS (PTR)
3. Use relay SMTP temporariamente
4. Configure SPF/DKIM/DMARC

### ❌ Não consegue conectar:
1. Verifique se Traefik está rodando
2. Confirme portas abertas no firewall
3. Teste conectividade: `telnet kronos.cloudns.ph 587`

### ❌ Interface web não carrega:
1. Verifique certificado SSL do Traefik
2. Confirme DNS apontando corretamente
3. Verifique logs: `docker-compose logs postie`

## 🔐 Segurança

### Configurações Atuais:
- ✅ TLS obrigatório em todos os protocolos
- ✅ Autenticação obrigatória para envio
- ✅ Antispam (RSPAMD) habilitado
- ✅ Senhas hasheadas com SHA512
- ✅ Isolamento Docker completo

### Recomendações Adicionais:
- Altere senha do admin imediatamente
- Configure 2FA se disponível
- Monitore logs regularmente
- Mantenha backups atualizados

## 📊 Recursos do Poste.io

- ✅ **SMTP/IMAP/POP3** completos
- ✅ **Webmail** (Roundcube)
- ✅ **Administração Web** completa
- ✅ **Antivirus** (ClamAV - desabilitado por recursos)
- ✅ **Antispam** (RSPAMD)
- ✅ **Filtros Sieve** programáveis
- ✅ **Quotas** de armazenamento
- ✅ **Redirecionamento/Auto-reply**
- ✅ **SPF/DKIM/DMARC** nativos

## 🎯 Próximos Passos Recomendados

1. **Obter IP Estático** - Essencial para deliverability
2. **Configurar DNS** - SPF, DKIM, DMARC
3. **Testar Deliverability** - Usar ferramentas como Mail-Tester
4. **Configurar Backup** - Automatizar backup dos dados
5. **Monitoramento** - Configurar alertas e logs

---

**Nota**: Poste.io é uma solução robusta, mas IPs dinâmicos limitam sua efetividade. Considere upgrade para IP estático para uso profissional.
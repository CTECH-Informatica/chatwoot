# CTECH — Chatwoot Customizado

Este repositório contém o fork da CTECH baseado no Chatwoot **v4.17.0**. A branch padrão de desenvolvimento e produção é `main-ctech`.

## Branch base

| Item | Valor |
|------|-------|
| Versão upstream | Chatwoot v4.17.0 |
| Branch padrão | `main-ctech` |
| Repositório | `CTECH-Informatica/chatwoot` |

## Customizações CTECH

### 1. Atalho de envio de mensagens fixo em Ctrl+Enter

Por política organizacional, os agentes **não podem** usar Enter para enviar mensagens. Apenas **Cmd/Ctrl + Enter** é permitido.

**Comportamento:**
- A opção "Enter (↵)" nas configurações de perfil fica desabilitada.
- Exibe o rótulo "Not allowed" e a mensagem "Not allowed by your administrator." na opção bloqueada.
- O atalho ativo é forçado para `cmd_enter` automaticamente.
- A descrição da seção informa que a organização exige Ctrl+Enter.

**Configuração:** `FORCE_CTRL_ENTER_FOR_MESSAGES` em `config/installation_config.yml` (padrão: `true`, bloqueada).

**Arquivos alterados:**
- `config/installation_config.yml`
- `app/controllers/dashboard_controller.rb`
- `app/javascript/shared/store/globalConfig.js`
- `app/javascript/dashboard/composables/useUISettings.js`
- `app/javascript/dashboard/routes/dashboard/settings/profile/Index.vue`
- `app/javascript/dashboard/i18n/locale/en/settings.json`

## CI/CD

O workflow `.github/workflows/ctech_ci.yml` roda automaticamente em push e pull requests para `main-ctech`.

### Jobs

| Job | Descrição |
|-----|-----------|
| `lint-backend` | RuboCop |
| `lint-frontend` | ESLint |
| `frontend-tests` | Testes Vitest com cobertura |
| `backend-tests` | RSpec completo (PostgreSQL + Redis) |
| `docker-build` | Build multi-arquitetura (amd64 + arm64) |
| `docker-merge` | Publica manifest no GitHub Container Registry |

### Imagem Docker

Após merge na `main-ctech`, a imagem é publicada em:

```
ghcr.io/ctech-informatica/chatwoot:main-ctech
ghcr.io/ctech-informatica/chatwoot:latest
```

**Uso em produção:**

```bash
docker pull ghcr.io/ctech-informatica/chatwoot:latest
```

> **Importante:** Utilize sempre a imagem gerada a partir desta branch (`main-ctech`), e não a imagem oficial do Chatwoot, para garantir as customizações CTECH em produção.

### Execução manual

O workflow também pode ser disparado manualmente em **Actions → CTECH CI → Run workflow**.

## SSO (Single Sign-On)

O SSO via **SAML** no Chatwoot é uma funcionalidade da **edição Enterprise**. Não está disponível na versão Community (CE) pura.

### Requisitos para habilitar SAML SSO

1. **Edição Enterprise** — o diretório `enterprise/` deve estar presente (já incluso neste fork).
2. **Plano de instalação** — `INSTALLATION_PRICING_PLAN` deve ser `enterprise` (não `community`).
   - Super Admin → Settings, ou via Rails console:
     ```ruby
     InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN').update!(value: 'enterprise')
     GlobalConfig.clear_cache
     ```
3. **Login SAML habilitado** — `ENABLE_SAML_SSO_LOGIN` = `true` (padrão).
4. **Configuração por conta** — em **Settings → Security → SAML SSO**, configure:
   - SSO URL do IdP
   - Certificado (PEM)
   - Identity Provider Entity ID
   - Mapeamento de atributos no seu IdP (ACS URL e SP Entity ID são gerados automaticamente)

### Por que o SSO pode não aparecer

| Causa | Solução |
|-------|---------|
| `INSTALLATION_PRICING_PLAN` = `community` | Alterar para `enterprise` |
| `ENABLE_SAML_SSO_LOGIN` = `false` | Habilitar em Super Admin → App Configs |
| Enterprise desabilitado (`DISABLE_ENTERPRISE=true`) | Remover a variável de ambiente |
| SAML não configurado na conta | Configurar em Settings → Security |

### Login disponível

Com SSO habilitado, a tela de login exibe a opção **"Login via SSO"** (além de email/senha e Google OAuth, se configurados).

## Desenvolvimento local

```bash
bundle install && pnpm install
bundle exec rails db:setup
pnpm dev
```

Consulte `AGENTS.md` para detalhes completos de build, testes e lint.

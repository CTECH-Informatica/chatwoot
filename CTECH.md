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

### 2. Desativação do Chatwoot Hub (cloud)

Por padrão, a instalação CTECH **não consulta** serviços externos do Chatwoot (`hub.2.chatwoot.com`). Isso evita problemas de sincronização de plano, telemetria, reset de features premium e dependência de rede.

**Comportamento quando `DISABLE_CHATWOOT_HUB=true` (padrão CTECH):**

| Consulta bloqueada | Impacto |
|--------------------|---------|
| `sync_with_hub` (job diário) | Não sincroniza plano/licença com a cloud |
| `register_instance` (onboarding) | Não registra a instalação no Hub |
| `emit_event` (telemetria) | Não envia eventos de uso |
| `send_push` via Hub | Push FCM via relay do Hub desativado — configure `FIREBASE_PROJECT_ID` + `FIREBASE_CREDENTIALS` para push mobile |
| Changelog no sidebar | Não busca novidades do Hub |
| `ReconcilePlanConfigService` | Não desativa features premium automaticamente |

**Configuração:** `DISABLE_CHATWOOT_HUB` em `config/installation_config.yml` (padrão: `true`, bloqueada).

Também pode ser controlado via variável de ambiente `DISABLE_CHATWOOT_HUB=true`.

**Plano padrão:** `INSTALLATION_PRICING_PLAN` definido como `enterprise` (sem depender do Hub).

**Arquivos alterados:**
- `lib/chatwoot_hub.rb`
- `config/installation_config.yml`
- `app/jobs/internal/check_new_versions_job.rb`
- `app/jobs/internal/trigger_daily_scheduled_items_job.rb`
- `enterprise/app/jobs/enterprise/internal/check_new_versions_job.rb`
- `enterprise/app/services/internal/reconcile_plan_config_service.rb`
- `app/controllers/super_admin/settings_controller.rb`
- `app/controllers/dashboard_controller.rb`
- `app/javascript/shared/store/globalConfig.js`
- `app/javascript/dashboard/components-next/sidebar/SidebarChangelogCard.vue`

### 3. Super Admin sem billing/cloud

Com `DISABLE_CHATWOOT_HUB=true`, o Super Admin não exibe:
- Alerta de "premium changes" com link para vendas
- Card "Current plan" com botão **Manage** (billing)
- Aviso de limite de licenças de agentes
- Botões **Upgrade now** nas features
- Widget de suporte Chatwoot (chat ao vivo)
- Botão **Chat Support**

**Arquivos alterados:**
- `app/views/super_admin/settings/show.html.erb`
- `app/views/super_admin/application/_javascript.html.erb`

## CI/CD

O workflow `.github/workflows/ctech_ci.yml` roda automaticamente em push e pull requests para `main-ctech`.

### O que o CI faz (alinhado ao build oficial EE)

O build Docker do CTECH CI replica o processo de `publish_ee_docker.yml` (imagem Enterprise oficial):

| Etapa | Oficial EE | CTECH CI |
|-------|-----------|----------|
| Dockerfile | `docker/Dockerfile` | `docker/Dockerfile` |
| Edição | `ENV CW_EDITION="ee"` | `ENV CW_EDITION="ee"` |
| Plataformas | linux/amd64 + linux/arm64 | linux/amd64 + linux/arm64 |
| Build multi-arch | buildx + merge manifest | buildx + merge manifest |
| Registry | DockerHub (`chatwoot/chatwoot`) | GHCR (`ghcr.io/ctech-informatica/chatwoot`) |

**Diferença intencional:** o destino é o GHCR privado da CTECH, não o DockerHub público.

**Em PR:** apenas valida que a imagem compila (sem publicar).
**Em push na `main-ctech`:** compila e publica no GHCR.

### Imagem privada no GHCR

Por padrão, pacotes no GHCR **herdam a visibilidade do repositório**:
- Repositório **privado** → imagem **privada**
- Repositório **público** → imagem **pública**

Para garantir que a imagem seja privada:

1. Mantenha o repositório `CTECH-Informatica/chatwoot` como **privado**, **ou**
2. Acesse **GitHub → Packages → chatwoot → Package settings → Change visibility → Private**

**Login para pull em produção:**

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
docker pull ghcr.io/ctech-informatica/chatwoot:latest
```

Use um Personal Access Token (classic) com permissão `read:packages`.

### Workflows upstream desativados

Workflows herdados do Chatwoot OSS que não se aplicam ao fork CTECH foram desativados:

| Workflow | Motivo |
|----------|--------|
| `run_foss_spec.yml` | CI upstream (develop/master); CTECH usa `ctech_ci.yml` |
| `deploy_check.yml` | Checagem de review app Heroku (inexistente na CTECH) |
| `lint_pr.yml` | Validação de título semântico de PR (OSS público) |
| `run_mfa_spec.yml` | Restrito a develop/master |
| `auto-assign-pr.yml` | Automação OSS |
| `stale.yml` / `lock.yml` | Automação de issues/PRs do projeto público |
| `ghsa-linear-sync.yml` | Sync Linear do time Chatwoot |
| `nightly_installer.yml` | Teste do instalador Linux upstream |

### Jobs do CTECH CI

| Job | PR | Push `main-ctech` |
|-----|----|-------------------|
| `docker-build` | Build multi-arch (sem push) | Build + push digest |
| `docker-merge` | — | Publica manifest com tags |

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
2. **Plano de instalação** — `INSTALLATION_PRICING_PLAN` = `enterprise` (padrão CTECH, sem sincronização com Hub).
3. **Login SAML habilitado** — `ENABLE_SAML_SSO_LOGIN` = `true` (padrão).
4. **Configuração por conta** — em **Settings → Security → SAML SSO**, configure:
   - SSO URL do IdP
   - Certificado (PEM)
   - Identity Provider Entity ID
   - Mapeamento de atributos no seu IdP (ACS URL e SP Entity ID são gerados automaticamente)

### Por que o SSO pode não aparecer

| Causa | Solução |
|-------|---------|
| Feature `saml` desabilitada na conta | Habilitar em Super Admin → Accounts → Features |
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

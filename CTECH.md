# CTECH — Chatwoot Customizado

Este repositório contém o fork da CTECH baseado no Chatwoot **v4.18.0**. A branch padrão de desenvolvimento e produção é `main-ctech`.

## Branch base

| Item | Valor |
|------|-------|
| Versão upstream | Chatwoot v4.18.0 |
| Branch padrão | `main-ctech` |
| Repositório | `CTECH-Informatica/chatwoot` |

## Customizações CTECH

### Atalho de envio de mensagens fixo em Ctrl+Enter

Por política organizacional, os agentes **não podem** usar Enter para enviar mensagens. Apenas **Cmd/Ctrl + Enter** é permitido.

**Comportamento:**
- A opção "Enter (↵)" nas configurações de perfil fica desabilitada.
- Exibe o rótulo "Não permitido" e a mensagem "Não permitido pelo seu administrador." (pt_BR/pt).
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
- `app/javascript/dashboard/i18n/locale/pt_BR/settings.json`
- `app/javascript/dashboard/i18n/locale/pt/settings.json`

## CI/CD

O workflow `.github/workflows/ctech_ci.yml` publica a imagem Docker da CTECH no GHCR, seguindo o mesmo processo da edição Community do Chatwoot:

| Etapa | Descrição |
|-------|-----------|
| Strip enterprise | Remove `enterprise/` e `spec/enterprise/` |
| Edição | `ENV CW_EDITION="ce"` |
| Plataforma | linux/amd64 |
| Registry | `ghcr.io/ctech-informatica/chatwoot` |

**Em PR:** valida que a imagem compila (sem publicar).
**Em push na `main-ctech`:** compila e publica no GHCR.

### Imagem Docker

```
ghcr.io/ctech-informatica/chatwoot:main-ctech
ghcr.io/ctech-informatica/chatwoot:latest
```

**Uso em produção:**

```bash
docker pull ghcr.io/ctech-informatica/chatwoot:latest
```

> Utilize sempre a imagem gerada a partir desta branch (`main-ctech`), e não a imagem oficial do Chatwoot, para garantir a customização do atalho de envio em produção.

### Login no GHCR

```bash
echo "$GHCR_PAT" | docker login ghcr.io -u SEU_USUARIO_GITHUB --password-stdin
docker pull ghcr.io/ctech-informatica/chatwoot:latest
```

## Desenvolvimento local

```bash
bundle install && pnpm install
bundle exec rails db:setup
pnpm dev
```

Consulte `AGENTS.md` para detalhes completos de build, testes e lint.

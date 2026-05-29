# AGENTS.md

Guia operacional para agentes trabalhando neste repositorio.

## Projeto

API Rails do MVP **Inimigos da Bola**.

O backend gerencia autenticacao, jogadores, racha semanal, presencas, avaliacoes de habilidade, estatisticas, sincronizacao offline-first e notificacoes push. O sorteio de times e qualquer logica de partidas curtas ficam fora do backend.

## Fonte de Verdade

- Documento base: `api-rails.md`.
- Specs derivadas: `.ia/specs`.
- Em caso de conflito, preserve as regras de dominio do `api-rails.md` e atualize a spec correspondente.

## Stack Esperada

- Rails API only.
- PostgreSQL.
- Devise + devise-jwt.
- Pundit.
- Sidekiq.
- FCM.
- Serializers com Blueprinter ou jsonapi-serializer.
- Testes com RSpec, FactoryBot, request specs e policy specs.

O app Rails ainda pode estar no esqueleto. Ao implementar, adicione dependencias e estrutura de forma incremental.

## Docker First

O desenvolvimento e a validacao devem acontecer primeiro via Docker Compose.

Comandos padrao:

- Subir API e dependencias: `docker compose up api`.
- Subir worker Sidekiq (para jobs e recurring): `docker compose up sidekiq`.
- Preparar banco: `docker compose run --rm api bin/rails db:prepare`.
- Rodar specs: `docker compose run --rm api bundle exec rspec`.
- Rodar RuboCop: `docker compose run --rm api bin/rubocop`.
- Abrir console Rails: `docker compose run --rm api bin/rails console`.

Use comandos locais somente para diagnostico rapido quando o container nao for necessario ou quando o usuario pedir explicitamente.

## Convencoes Gerais

- Codigo, classes, metodos, arquivos e branches em ingles.
- Comentarios de codigo em portugues quando forem necessarios.
- Mensagens de erro para usuario em pt-BR, com acentuacao correta.
- Commits em portugues usando Conventional Commits.
- Nao criar multi-tenant: sem `group_id` e sem `tenant_id`.
- Usar UUID v7 como PK em toda entidade sincronizavel.
- Timestamps em UTC.
- Entidades sincronizaveis devem ter `created_at`, `updated_at`, `deleted_at` e `version`.
- Soft-delete via `deleted_at`.
- Lock otimista via `version`.
- Server e autoridade mesmo quando a UI esconder acoes.

## Escopo Positivo do MVP

Implementar:

- Auth versionado em `/api/v1`.
- Convites de usuarios por admin.
- Config fixa do racha via variaveis de ambiente.
- Sessao semanal criada automaticamente.
- Presenca de jogador cadastrado.
- Presenca avulsa criada/removida por admin.
- Lista de espera e promocao automatica.
- Avaliacoes de habilidade privadas.
- Estatisticas agregadas por racha semanal.
- Pull/push sync para entidades permitidas.
- Idempotencia de mutacoes.
- Jobs recorrentes e notificacoes FCM.
- Policies Pundit e testes cobrindo regras criticas.

## Fora do Escopo

Nao criar no backend:

- Tabela de partidas curtas.
- Tabela de times sorteados.
- Tabela de placar.
- Tabela de cronometro.
- Multi-tenant.
- Pagamentos.
- Chat.
- Web admin.

O sorteio de times e 100% client-side. Presencas avulsas confirmadas entram no sorteio como participantes, mas avulsos temporarios adicionados diretamente na tela de sorteio nao vao para o backend.

## Ambiente

Variaveis esperadas:

```env
DATABASE_URL=
REDIS_URL=
JWT_SECRET=
FCM_SERVER_KEY=

RACHA_WEEKDAY=monday
RACHA_TIME=20:00
RACHA_LOCATION=Arena X
RACHA_MAX_PLAYERS=20
```

`RACHA_WEEKDAY`, `RACHA_TIME`, `RACHA_LOCATION` e `RACHA_MAX_PLAYERS` sao configuracao fixa do deploy. Nao criar tela ou endpoint de edicao para esses valores.

## Arquitetura Recomendada

Use services para regras com efeitos colaterais e retornos previsiveis:

- `WeeklySessions::CreateCurrent`
- `Attendance::Confirm`
- `Attendance::Decline`
- `GuestAttendance::Create`
- `GuestAttendance::Destroy`
- `Attendance::PromoteWaitlist`
- `SkillRatings::Upsert`
- `SkillRatings::RecalculateScore`
- `SessionStats::UpsertBatch`
- `Sync::ApplyMutation`
- `Sync::PullChanges`
- `Notifications::Push`

Services devem retornar `Success(data)` ou `Failure(code, message)`.

## Seguranca e Privacidade

- Nunca salvar senha em texto puro.
- Usar Devise/Bcrypt para senha.
- Nunca serializar `encrypted_password`.
- `skill_score` nao e editavel pela UI.
- Cada usuario ve apenas o proprio `skill_score`.
- Notas individuais de `skill_ratings` nunca sao exibidas.
- Nao retornar `skill_ratings` individuais de outros usuarios no sync.

## Testes Esperados

Ao implementar uma funcionalidade, adicionar cobertura proporcional:

- Request specs para endpoints.
- Policy specs para autorizacao.
- Model/service specs para regras de dominio, lista de espera, lock otimista, soft-delete e sync.
- Factories para entidades persistidas.

Antes de finalizar mudancas, rode os testes relevantes disponiveis no projeto.

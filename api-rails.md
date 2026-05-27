# API Rails — Inimigos da Bola

Este documento consolida o que a API Rails precisa implementar para o MVP.

## Stack backend

- Rails API only
- PostgreSQL
- Devise + devise-jwt
- Pundit
- Sidekiq
- FCM
- Serializers: Blueprinter ou jsonapi-serializer
- Testes: RSpec, FactoryBot, request specs, policy specs

## Regras gerais

- Single-tenant: não criar `group_id` nem `tenant_id`.
- Toda entidade sincronizável usa UUID v7 como PK.
- Timestamps em UTC.
- Toda tabela sincronizável tem `created_at`, `updated_at`, `deleted_at`, `version`.
- Soft-delete via `deleted_at`.
- Lock otimista via `version`.
- Comentários em português.
- Código, classes, métodos, arquivos e branches em inglês.
- Commits em português com Conventional Commits.

## Variáveis de ambiente

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

`RACHA_WEEKDAY`, `RACHA_TIME`, `RACHA_LOCATION` e `RACHA_MAX_PLAYERS` são configuração fixa do deploy. Não há tela para editar esses valores.

## Entidades

### `users`

Campos:

- `id`: uuid v7, PK
- `email`: citext, unique, not null
- `name`: string, not null
- `phone`: string, opcional
- `admin`: boolean, default `false`
- `player_type`: enum `monthly` | `casual`, default `casual`
- `skill_score`: decimal(5,2), média 0–100 calculada pelo sistema
- `goalkeeper`: boolean, default `false`
- campos Devise, incluindo `encrypted_password`
- `fcm_token`: string, quando push for implementado
- `created_at`, `updated_at`, `deleted_at`, `version`

Regras:

- Admin é um player com `admin: true`; usuário comum é player com `admin: false`.
- Primeiro usuário criado via seed é admin.
- `skill_score` não é editável pela UI.
- Cada usuário vê apenas o próprio `skill_score`.
- Outros usuários não veem notas nem médias de terceiros.
- Senha nunca é salva em texto puro; usar Devise/Bcrypt.
- `encrypted_password` não vai para o app/Drift.

### `weekly_sessions`

Representa o racha semanal, não uma partida curta.

Campos:

- `id`: uuid v7, PK
- `scheduled_at`: timestamp UTC
- `max_players`: integer, default vindo de `RACHA_MAX_PLAYERS` ou 20
- `status`: enum `scheduled` | `closed` | `canceled`
- `created_at`, `updated_at`, `deleted_at`, `version`

Regras:

- Criada automaticamente por `WeeklySessions::CreateCurrentJob`.
- `scheduled_at` vem de `RACHA_WEEKDAY` + `RACHA_TIME`.
- Não existem tabelas para partidas curtas, placar, cronômetro ou times sorteados.

### `attendances`

Representa presença no racha semanal.

Campos:

- `id`: uuid v7, PK
- `user_id`: FK users, `NULL` para presença avulsa sem cadastro
- `weekly_session_id`: FK weekly_sessions
- `kind`: enum `registered` | `guest`
- `guest_name`: string, obrigatório quando `kind = guest`
- `created_by_admin_id`: FK users, admin que criou presença avulsa
- `status`: enum `confirmed` | `declined` | `pending`
- `waitlist_position`: integer, `NULL` quando confirmado dentro do limite
- `created_at`, `updated_at`, `deleted_at`, `version`

Índices:

- unique parcial `(user_id, weekly_session_id)` onde `deleted_at IS NULL AND kind = 'registered'`
- índice em `(weekly_session_id, guest_name)`
- índice em `weekly_session_id`

Regras:

- Player cadastrado usa `kind = registered`, `user_id` obrigatório, `guest_name = NULL`.
- Presença avulsa usa `kind = guest`, `user_id = NULL`, `guest_name` obrigatório.
- Presença avulsa só pode ser criada/removida por admin.
- Presença avulsa não cria `User`.
- Presença avulsa conta no contador de confirmados e na lista de espera.
- Quando confirmados atingem `max_players`, novas confirmações entram em lista de espera.
- Quando alguém confirmado cancela, o primeiro da lista de espera é promovido.
- Confirmação/cancelamento de presença é online obrigatório, não vai para `sync_queue`.

### `skill_ratings`

Notas de habilidade entre players.

Campos:

- `id`: uuid v7, PK
- `evaluator_user_id`: FK users
- `evaluated_user_id`: FK users
- `score`: integer 0–100
- `created_at`, `updated_at`, `deleted_at`, `version`

Índices:

- unique parcial `(evaluator_user_id, evaluated_user_id)` onde `deleted_at IS NULL`
- índice em `evaluated_user_id`

Regras:

- Player avalia outros players com slider 0–100 no app.
- Autoavaliação não é permitida.
- Cada par avaliador/avaliado tem uma nota ativa.
- Reavaliar o mesmo player só após 1 mês.
- Notas individuais nunca são exibidas.
- Ao criar/atualizar nota, recalcular `users.skill_score` do avaliado.
- `skill_score` é média das notas recebidas, limitado a 0–100.

### `session_stats`

Estatísticas agregadas por jogador cadastrado no racha semanal.

Campos:

- `id`: uuid v7, PK
- `weekly_session_id`: FK weekly_sessions
- `user_id`: FK users
- `goals`: integer, default 0
- `assists`: integer, default 0
- `created_at`, `updated_at`, `deleted_at`, `version`

Índices:

- unique parcial `(weekly_session_id, user_id)` onde `deleted_at IS NULL`

Regras:

- Apenas admin registra stats.
- Stats são agregados do racha, não de cada partida curta.
- Presenças avulsas sem cadastro não entram em ranking/perfil.
- Stats podem ser editados até 24h após o racha.

### `processed_mutations`

Para idempotência do sync.

Campos:

- `mutation_id`: uuid, PK
- `applied_at`: timestamp

Pode ser substituída por Redis com TTL, mas tabela é mais simples no MVP.

## Endpoints

Todos versionados em `/api/v1`.

### Config do racha

```http
GET /api/v1/club
```

Resposta:

```json
{
  "weekday": "monday",
  "time": "20:00",
  "location": "Arena X",
  "max_players": 20
}
```

### Auth

```http
POST /api/v1/auth/sign_in
DELETE /api/v1/auth/sign_out
POST /api/v1/auth/refresh
POST /api/v1/auth/password
PUT /api/v1/auth/password
```

Login retorna:

- `access_token`: curto, 15 min
- `refresh_token`: longo, 30 dias

O app usa senha no primeiro acesso/login manual. Depois abre com biometria local ou senha como fallback. Biometria não autentica no backend.

### Convites

```http
POST /api/v1/users/invitations
POST /api/v1/users/accept_invitation
```

Fluxo:

- Admin convida por email/nome.
- Server cria `User` convidado com `admin: false`, `player_type: casual` inicial, sem senha.
- App de convite pede senha, confirmação, `player_type` com `casual` pré-selecionado e `goalkeeper`.
- Ao aceitar, server define senha, ativa usuário e emite tokens.

### Sessão semanal

```http
GET /api/v1/weekly_sessions/current
GET /api/v1/weekly_sessions/:id
```

`current` cria a sessão semanal se ainda não existir.

### Presença do próprio player

```http
POST /api/v1/weekly_sessions/:id/attendances
GET /api/v1/weekly_sessions/:id/attendances
```

Body:

```json
{
  "status": "confirmed"
}
```

ou:

```json
{
  "status": "declined"
}
```

Regras:

- Exige rede.
- Não entra no sync offline-first.
- Server decide `confirmed` ou lista de espera.
- Depois da hora de `scheduled_at`, presença vira read-only.

### Presença avulsa do admin

```http
POST /api/v1/weekly_sessions/:id/guest_attendances
DELETE /api/v1/weekly_sessions/:id/guest_attendances/:attendance_id
```

Body:

```json
{
  "guest_name": "Nome do avulso"
}
```

Regras:

- Apenas admin.
- Tela separada no app.
- Não reutilizar botão "Vou!" / "Não vou".
- Exige rede.
- Atualiza contador público de confirmados.

### Avaliação de habilidade

```http
POST /api/v1/skill_ratings
```

Body:

```json
{
  "evaluated_user_id": "uuid",
  "score": 75
}
```

Regras:

- Usuário logado é o avaliador.
- `score` de 0 a 100.
- Sem autoavaliação.
- Só pode alterar avaliação do mesmo player após 1 mês.
- Recalcular `skill_score` do avaliado.

### Stats

```http
POST /api/v1/weekly_sessions/:id/stats
GET /api/v1/stats/leaderboard?period=month|year
```

Batch de stats:

```json
{
  "stats": [
    { "user_id": "uuid", "goals": 3, "assists": 1 },
    { "user_id": "uuid", "goals": 0, "assists": 2 }
  ]
}
```

### FCM

```http
POST /api/v1/users/me/fcm_token
```

Body:

```json
{
  "fcm_token": "token"
}
```

## Sync

### Pull

```http
GET /api/v1/sync?since=<iso8601>&entities=users,weekly_sessions,attendances,session_stats
```

Resposta:

```json
{
  "server_time": "2026-05-26T20:15:00Z",
  "entities": {
    "users": [],
    "weekly_sessions": [],
    "attendances": [],
    "session_stats": []
  }
}
```

Regras:

- Retornar apenas registros alterados desde `since`.
- Incluir tombstones com `deleted_at`.
- Não retornar `encrypted_password`.
- Não retornar `skill_ratings` individuais de outros usuários.
- `users.skill_score` pode ser retornado, mas o app só exibe o do usuário logado.

### Push

```http
POST /api/v1/sync/{entity}
Idempotency-Key: <mutation_id>
```

Body:

```json
{
  "op": "create",
  "record": {
    "id": "...",
    "updated_at": "...",
    "version": 3
  }
}
```

Respostas:

- `200 OK`
- `409 Conflict`
- `422 Unprocessable Entity`
- `401 Unauthorized`

Importante:

- `attendances` não usa este fluxo.
- Presença do player e presença avulsa do admin são chamadas online imediatas.

## Jobs

### `WeeklySessions::CreateCurrentJob`

- Roda no dia configurado em `RACHA_WEEKDAY`, às 8h.
- Cria sessão semanal se não existir.
- Usa `RACHA_TIME` para `scheduled_at`.
- Usa `RACHA_MAX_PLAYERS`.
- Dispara notificação "Racha aberto".

### `Sync::CleanupTombstonesJob`

- Remove fisicamente registros com `deleted_at` há mais de 90 dias.

### `Notifications::PushJob`

Envia FCM.

Notificações:

- Todos: "O racha de hoje está aberto. Você vai?"
- Todos: "Em 1h tem racha. Já confirmou?"
- Player promovido: "Abriu vaga! Você está confirmado para hoje."
- Admin: nova confirmação.
- Admin: cancelamento de presença.
- Admin: presença avulsa adicionada/removida.
- Data message silenciosa para disparar sync.

## Services sugeridos

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

Services retornam `Success(data)` ou `Failure(code, message)`.

## Policies

- `WeeklySessionPolicy`
- `AttendancePolicy`
- `GuestAttendancePolicy`
- `SkillRatingPolicy`
- `SessionStatPolicy`
- `UserPolicy`

Regras principais:

- Qualquer logado vê sessão, listas e ranking.
- Player só confirma/cancela a própria presença.
- Admin cria/remove presença avulsa.
- Admin convida jogadores.
- Admin lança stats.
- Usuário pode avaliar outros players, mas não a si mesmo.
- Server continua sendo autoridade, mesmo que a UI esconda botões.

## Erros

Envelope padrão:

```json
{
  "error": {
    "code": "ATTENDANCE_LIMIT_REACHED",
    "message": "O racha já está com vagas preenchidas; você entrou na lista de espera."
  }
}
```

Códigos sugeridos:

- `UNAUTHORIZED`
- `FORBIDDEN`
- `VALIDATION_ERROR`
- `ATTENDANCE_LOCKED`
- `ATTENDANCE_LIMIT_REACHED`
- `WAITLIST_PROMOTED`
- `GUEST_ATTENDANCE_ONLY_ADMIN`
- `SKILL_RATING_SELF_NOT_ALLOWED`
- `SKILL_RATING_TOO_SOON`
- `SYNC_CONFLICT`

Mensagens para usuário em pt-BR, com acentuação correta.

## O que não criar no backend

- Tabela de partidas curtas.
- Tabela de times sorteados.
- Tabela de placar.
- Tabela de cronômetro.
- Multi-tenant.
- Pagamentos no MVP.
- Chat.
- Web admin.

## Observações importantes

- Sorteio de times é 100% client-side.
- Presenças avulsas confirmadas entram no sorteio como participantes.
- Avulsos temporários adicionados diretamente na tela de sorteio não vão para backend.
- Para sorteio, presenças avulsas e avulsos temporários recebem skill mediano dos confirmados cadastrados; se não houver confirmados cadastrados, usar 50.
- Comentários no código em português.
- Identificadores/classes/métodos em inglês.

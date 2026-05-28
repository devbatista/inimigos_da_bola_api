# Inimigos da Bola API

API Rails do MVP do Inimigos da Bola.

## Setup Local

O projeto e Docker-first. Para subir a API com PostgreSQL e Redis:

```sh
docker compose up api
```

A API fica disponivel em:

```text
API_HOST=http://localhost:4500
```

Preparar ou atualizar o banco:

```sh
docker compose run --rm api bin/rails db:prepare
```

Variaveis de ambiente locais ficam em `.env`. O arquivo nao e versionado; use `.env_example` como base.

Rodar a suite:

```sh
docker compose run --rm api bundle exec rspec
```

Rodar lint:

```sh
docker compose run --rm api bin/rubocop
```

## Mobile

Use uma destas bases no app:

```text
API_BASE_URL=http://localhost:4500/api/v1
```

Para Android emulator:

```text
ANDROID_EMULATOR_API_BASE_URL=http://10.0.2.2:4500/api/v1
```

Headers esperados:

```http
Content-Type: application/json
Authorization: Bearer <access_token>
```

Endpoints de sync push tambem devem enviar:

```http
Idempotency-Key: <mutation_id>
```

## Auth

### Login

```http
POST /api/v1/auth/sign_in
Content-Type: application/json
```

Body:

```json
{
  "email": "admin@inimigosdabola.dev",
  "password": "inimigos123"
}
```

Resposta `200 OK`:

```json
{
  "access_token": "<jwt>",
  "access_token_expires_at": "2026-05-27T20:15:00Z",
  "refresh_token": "<opaque-token>",
  "refresh_token_expires_at": "2026-06-26T20:00:00Z",
  "user": {
    "id": "0193...",
    "email": "admin@inimigosdabola.dev",
    "name": "Admin Inimigos",
    "phone": "+5511999999999",
    "admin": true,
    "player_type": "monthly",
    "skill_score": 75,
    "goalkeeper": false
  }
}
```

- `access_token` expira em 15 minutos.
- `refresh_token` expira em 30 dias.
- Datas em UTC, formato ISO-8601.

Credenciais seedadas para teste mobile:

```text
ADMIN_EMAIL=admin@inimigosdabola.dev
ADMIN_PASSWORD=inimigos123

PLAYER_EMAIL=player@inimigosdabola.dev
PLAYER_PASSWORD=inimigos123

goleiro@inimigosdabola.dev / inimigos123
mensalista@inimigosdabola.dev / inimigos123
casual@inimigosdabola.dev / inimigos123
```

### Refresh

```http
POST /api/v1/auth/refresh
Content-Type: application/json
```

Body:

```json
{
  "refresh_token": "<refresh_token>"
}
```

Resposta `200 OK`: mesmo shape do login, com `access_token` e `refresh_token` novos. O `refresh_token` anterior e revogado.

### Erros

Envelope padrao:

```json
{
  "error": {
    "code": "<code>",
    "message": "<mensagem em pt-BR>"
  }
}
```

Codes relevantes para o cliente mobile:

- `token_expired` (`401`): access token JWT expirado. Mobile deve chamar `POST /api/v1/auth/refresh`.
- `UNAUTHORIZED` (`401`): credenciais invalidas, refresh token invalido/revogado ou requisicao sem token.
- `FORBIDDEN` (`403`): autenticado, mas sem permissao para a acao.
- `NOT_FOUND` (`404`): recurso inexistente.
- `VALIDATION_ERROR` (`422`): payload invalido.
- `ATTENDANCE_LOCKED` (`422`): presenca ja nao pode mais ser alterada (depois de `scheduled_at`).
- `SKILL_RATING_SELF_NOT_ALLOWED` (`422`): tentativa de autoavaliacao.
- `SKILL_RATING_TOO_SOON` (`422`): tentativa de reavaliar antes de 1 mes.
- `SYNC_CONFLICT` (`409`): versao do registro no servidor diverge da enviada pelo cliente.

Exemplo de token expirado (`401`):

```json
{
  "error": {
    "code": "token_expired",
    "message": "Token expirado."
  }
}
```

## Endpoints minimos para mobile

Todos exigem `Authorization: Bearer <access_token>`.

### `GET /api/v1/users/me`

Retorna o usuario autenticado. Resposta `200`:

```json
{
  "id": "uuid",
  "email": "...",
  "name": "...",
  "phone": null,
  "admin": false,
  "player_type": "casual",
  "skill_score": "75.5",
  "goalkeeper": false
}
```

### `POST /api/v1/weekly_sessions/:id/attendances`

Confirma ou cancela presenca do proprio player. Body:

```json
{ "status": "confirmed" }
```

`status` aceita `confirmed` ou `declined`. Quando lotado, a confirmacao entra na lista de espera com `waitlist_position > 0`. Apos `scheduled_at`, retorna `ATTENDANCE_LOCKED`.

### `POST /api/v1/weekly_sessions/:id/guest_attendances` (admin)

Body:

```json
{ "guest_name": "Visitante" }
```

Cria presenca avulsa confirmada. Avulsos contam para `max_players`. Usuario comum recebe `403`.

### `DELETE /api/v1/weekly_sessions/:id/guest_attendances/:attendance_id` (admin)

Remove o avulso e promove o primeiro da waitlist se houver vaga aberta. `204 No Content`.

### `POST /api/v1/skill_ratings`

Body:

```json
{ "evaluated_user_id": "uuid", "score": 80 }
```

`score` integer 0..100. Recalcula `users.skill_score` do avaliado. Autoavaliacao bloqueada e reavaliacao so depois de 1 mes da ultima.

### `GET /api/v1/sync`

Pull sync. Query params opcionais:

- `since`: ISO-8601 (`2026-05-26T20:00:00Z`). Sem `since` retorna tudo.
- `entities`: CSV de `users,weekly_sessions,attendances,session_stats`. Sem `entities` retorna todas.

Resposta:

```json
{
  "server_time": "2026-05-27T20:15:00Z",
  "entities": {
    "users": [ { "id": "...", "...": "...", "deleted_at": null, "version": 3 } ],
    "weekly_sessions": [ ... ],
    "attendances": [ ... ],
    "session_stats": [ ... ]
  }
}
```

Tombstones vem com `deleted_at` preenchido. `skill_ratings` nao sao expostos em pull. `users` nao inclui `encrypted_password`, `jti`, `fcm_token`, tokens de recuperacao ou de convite.

### `POST /api/v1/sync/:entity`

Push sync. Entidades aceitas: `users`, `weekly_sessions`, `session_stats`, `skill_ratings`. `attendances` e bloqueado (`403 FORBIDDEN`).

Headers obrigatorios:

```http
Content-Type: application/json
Idempotency-Key: <mutation_uuid>
```

Body:

```json
{
  "op": "update",
  "record": { "id": "uuid", "version": 3, "...campos...": "..." }
}
```

`op` aceita `create`, `update`, `delete`. Em `update`/`delete`, `record.version` deve casar com a versao no servidor — divergencia retorna `409 SYNC_CONFLICT`. A mesma `Idempotency-Key` aplicada novamente retorna `200` com `{ "idempotent_replay": true }` sem reaplicar a mutacao.

Autorizacao por entidade:

- `users`: apenas o proprio usuario.
- `weekly_sessions` / `session_stats`: apenas admin.
- `skill_ratings`: apenas o proprio avaliador.

## CORS

Em desenvolvimento, a API aceita qualquer origem por padrao. Para restringir:

```sh
CORS_ORIGINS=http://localhost:5173,http://10.0.2.2:4500
```

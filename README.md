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

Login:

```http
POST /api/v1/auth/sign_in
```

```json
{
  "email": "${ADMIN_EMAIL}",
  "password": "${ADMIN_PASSWORD}"
}
```

Refresh:

```http
POST /api/v1/auth/refresh
```

```json
{
  "refresh_token": "<refresh_token>"
}
```

## CORS

Em desenvolvimento, a API aceita qualquer origem por padrao. Para restringir:

```sh
CORS_ORIGINS=http://localhost:5173,http://10.0.2.2:4500
```

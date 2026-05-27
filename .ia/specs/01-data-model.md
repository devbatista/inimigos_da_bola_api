# Spec 01 - Modelo de Dados

## Regras Globais

Toda entidade sincronizavel deve ter:

- `id`: UUID v7 como PK.
- `created_at`: timestamp UTC.
- `updated_at`: timestamp UTC.
- `deleted_at`: timestamp UTC nullable para soft-delete.
- `version`: inteiro para lock otimista.

Entidades sincronizaveis no MVP:

- `users`
- `weekly_sessions`
- `attendances`
- `skill_ratings`
- `session_stats`

## users

Campos:

- `id`: uuid v7, PK.
- `email`: citext, unique, not null.
- `name`: string, not null.
- `phone`: string opcional.
- `admin`: boolean, default `false`.
- `player_type`: enum `monthly` ou `casual`, default `casual`.
- `skill_score`: decimal(5,2), media 0-100 calculada pelo sistema.
- `goalkeeper`: boolean, default `false`.
- Campos Devise, incluindo `encrypted_password`.
- `fcm_token`: string, quando push for implementado.
- Campos globais de sync.

Regras:

- Admin e um player com `admin: true`.
- Usuario comum e player com `admin: false`.
- Primeiro usuario criado via seed e admin.
- `skill_score` nao e editavel pela UI.
- Usuario ve apenas o proprio `skill_score`.
- Outros usuarios nao veem notas nem medias de terceiros.
- Senha nunca e salva em texto puro.
- `encrypted_password` nunca vai para o app/Drift.

## weekly_sessions

Campos:

- `id`: uuid v7, PK.
- `scheduled_at`: timestamp UTC.
- `max_players`: integer, default de `RACHA_MAX_PLAYERS` ou 20.
- `status`: enum `scheduled`, `closed`, `canceled`.
- Campos globais de sync.

Regras:

- Representa o racha semanal, nao uma partida curta.
- Criada automaticamente por `WeeklySessions::CreateCurrentJob`.
- `scheduled_at` vem de `RACHA_WEEKDAY` + `RACHA_TIME`.

## attendances

Campos:

- `id`: uuid v7, PK.
- `user_id`: FK users nullable para presenca avulsa.
- `weekly_session_id`: FK weekly_sessions.
- `kind`: enum `registered`, `guest`.
- `guest_name`: string obrigatorio quando `kind = guest`.
- `created_by_admin_id`: FK users, admin que criou presenca avulsa.
- `status`: enum `confirmed`, `declined`, `pending`.
- `waitlist_position`: integer nullable quando confirmado dentro do limite.
- Campos globais de sync.

Indices:

- Unique parcial `(user_id, weekly_session_id)` onde `deleted_at IS NULL AND kind = 'registered'`.
- Indice em `(weekly_session_id, guest_name)`.
- Indice em `weekly_session_id`.

Regras:

- Player cadastrado usa `kind = registered`, `user_id` obrigatorio e `guest_name = NULL`.
- Presenca avulsa usa `kind = guest`, `user_id = NULL` e `guest_name` obrigatorio.
- Presenca avulsa so pode ser criada/removida por admin.
- Presenca avulsa nao cria `User`.
- Presenca avulsa conta no contador de confirmados e na lista de espera.
- Ao atingir `max_players`, novas confirmacoes entram em lista de espera.
- Quando alguem confirmado cancela, o primeiro da lista de espera e promovido.
- Confirmacao/cancelamento exige rede e nao vai para `sync_queue`.
- Depois de `scheduled_at`, presenca vira read-only.

## skill_ratings

Campos:

- `id`: uuid v7, PK.
- `evaluator_user_id`: FK users.
- `evaluated_user_id`: FK users.
- `score`: integer 0-100.
- Campos globais de sync.

Indices:

- Unique parcial `(evaluator_user_id, evaluated_user_id)` onde `deleted_at IS NULL`.
- Indice em `evaluated_user_id`.

Regras:

- Usuario logado avalia outros players.
- Autoavaliacao nao e permitida.
- Cada par avaliador/avaliado tem uma nota ativa.
- Reavaliar o mesmo player so apos 1 mes.
- Notas individuais nunca sao exibidas.
- Ao criar/atualizar nota, recalcular `users.skill_score` do avaliado.
- `skill_score` e a media das notas recebidas, limitado a 0-100.

## session_stats

Campos:

- `id`: uuid v7, PK.
- `weekly_session_id`: FK weekly_sessions.
- `user_id`: FK users.
- `goals`: integer, default 0.
- `assists`: integer, default 0.
- Campos globais de sync.

Indices:

- Unique parcial `(weekly_session_id, user_id)` onde `deleted_at IS NULL`.

Regras:

- Apenas admin registra stats.
- Stats sao agregados do racha semanal, nao de partidas curtas.
- Presencas avulsas sem cadastro nao entram em ranking/perfil.
- Stats podem ser editados ate 24h apos o racha.

## processed_mutations

Campos:

- `mutation_id`: uuid, PK.
- `applied_at`: timestamp.

Uso:

- Garante idempotencia do sync.
- Pode ser substituida por Redis com TTL, mas tabela e a opcao simples para o MVP.


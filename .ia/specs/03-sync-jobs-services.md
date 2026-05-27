# Spec 03 - Sync, Jobs e Services

## Sync Pull

Endpoint:

`GET /api/v1/sync?since=<iso8601>&entities=users,weekly_sessions,attendances,session_stats`

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
- Nao retornar `encrypted_password`.
- Nao retornar `skill_ratings` individuais de outros usuarios.
- `users.skill_score` pode ser retornado no payload, mas o app so deve exibir o do usuario logado.

## Sync Push

Endpoint:

`POST /api/v1/sync/{entity}`

Header:

`Idempotency-Key: <mutation_id>`

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

Respostas esperadas:

- `200 OK`
- `409 Conflict`
- `422 Unprocessable Entity`
- `401 Unauthorized`

Regras:

- `attendances` nao usa push sync.
- Presenca do player e presenca avulsa do admin sao chamadas online imediatas.
- Usar `processed_mutations` para idempotencia no MVP.
- Conflitos de `version` devem retornar `SYNC_CONFLICT`.

## Jobs

### WeeklySessions::CreateCurrentJob

- Roda no dia configurado em `RACHA_WEEKDAY`, as 8h.
- Cria sessao semanal se nao existir.
- Usa `RACHA_TIME` para `scheduled_at`.
- Usa `RACHA_MAX_PLAYERS`.
- Dispara notificacao "Racha aberto".

### Sync::CleanupTombstonesJob

- Remove fisicamente registros com `deleted_at` ha mais de 90 dias.

### Notifications::PushJob

- Envia FCM.

Notificacoes:

- Todos: "O racha de hoje esta aberto. Voce vai?"
- Todos: "Em 1h tem racha. Ja confirmou?"
- Player promovido: "Abriu vaga! Voce esta confirmado para hoje."
- Admin: nova confirmacao.
- Admin: cancelamento de presenca.
- Admin: presenca avulsa adicionada/removida.
- Data message silenciosa para disparar sync.

## Services

Services sugeridos:

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

Contrato:

- Sucesso: `Success(data)`.
- Falha: `Failure(code, message)`.

Regras de implementacao:

- Concentrar regras com efeitos colaterais nos services.
- Controllers devem validar autenticacao/autorizacao, chamar services e traduzir resultado em HTTP.
- Policies continuam sendo a fonte de autorizacao.


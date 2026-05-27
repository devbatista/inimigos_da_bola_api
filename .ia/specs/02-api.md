# Spec 02 - API HTTP

## Padroes

- Todos os endpoints devem ser versionados em `/api/v1`.
- Erros devem usar envelope padrao.
- Mensagens de erro para usuario devem estar em pt-BR.
- Autorizacao deve ser aplicada no backend com Pundit.

Envelope de erro:

```json
{
  "error": {
    "code": "ATTENDANCE_LIMIT_REACHED",
    "message": "O racha ja esta com vagas preenchidas; voce entrou na lista de espera."
  }
}
```

Codigos sugeridos:

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

## Config do Racha

`GET /api/v1/club`

Resposta:

```json
{
  "weekday": "monday",
  "time": "20:00",
  "location": "Arena X",
  "max_players": 20
}
```

## Auth

Endpoints:

- `POST /api/v1/auth/sign_in`
- `DELETE /api/v1/auth/sign_out`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/password`
- `PUT /api/v1/auth/password`

Login retorna:

- `access_token`: curto, 15 min.
- `refresh_token`: longo, 30 dias.

O app usa senha no primeiro acesso/login manual. Depois abre com biometria local ou senha como fallback. Biometria nao autentica no backend.

## Convites

Endpoints:

- `POST /api/v1/users/invitations`
- `POST /api/v1/users/accept_invitation`

Fluxo:

- Admin convida por email/nome.
- Server cria `User` convidado com `admin: false`, `player_type: casual` inicial e sem senha.
- App de convite pede senha, confirmacao, `player_type` com `casual` pre-selecionado e `goalkeeper`.
- Ao aceitar, server define senha, ativa usuario e emite tokens.

## Sessao Semanal

Endpoints:

- `GET /api/v1/weekly_sessions/current`
- `GET /api/v1/weekly_sessions/:id`

Regras:

- `current` cria a sessao semanal se ainda nao existir.
- Qualquer usuario logado pode ver a sessao.

## Presenca do Proprio Player

Endpoints:

- `POST /api/v1/weekly_sessions/:id/attendances`
- `GET /api/v1/weekly_sessions/:id/attendances`

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
- Nao entra no sync offline-first.
- Server decide confirmacao ou lista de espera.
- Depois de `scheduled_at`, presenca vira read-only.
- Player so confirma/cancela a propria presenca.

## Presenca Avulsa do Admin

Endpoints:

- `POST /api/v1/weekly_sessions/:id/guest_attendances`
- `DELETE /api/v1/weekly_sessions/:id/guest_attendances/:attendance_id`

Body:

```json
{
  "guest_name": "Nome do avulso"
}
```

Regras:

- Apenas admin.
- Tela separada no app.
- Nao reutilizar botao "Vou!" / "Nao vou".
- Exige rede.
- Atualiza contador publico de confirmados.

## Avaliacao de Habilidade

Endpoint:

- `POST /api/v1/skill_ratings`

Body:

```json
{
  "evaluated_user_id": "uuid",
  "score": 75
}
```

Regras:

- Usuario logado e o avaliador.
- `score` de 0 a 100.
- Sem autoavaliacao.
- So pode alterar avaliacao do mesmo player apos 1 mes.
- Recalcular `skill_score` do avaliado.

## Stats

Endpoints:

- `POST /api/v1/weekly_sessions/:id/stats`
- `GET /api/v1/stats/leaderboard?period=month|year`

Batch de stats:

```json
{
  "stats": [
    { "user_id": "uuid", "goals": 3, "assists": 1 },
    { "user_id": "uuid", "goals": 0, "assists": 2 }
  ]
}
```

Regras:

- Apenas admin registra stats.
- Avulsos sem cadastro nao entram em ranking/perfil.
- Edicao permitida ate 24h apos o racha.

## FCM

Endpoint:

- `POST /api/v1/users/me/fcm_token`

Body:

```json
{
  "fcm_token": "token"
}
```


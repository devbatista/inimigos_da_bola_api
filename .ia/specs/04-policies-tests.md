# Spec 04 - Policies e Testes

## Policies

Policies esperadas:

- `WeeklySessionPolicy`
- `AttendancePolicy`
- `GuestAttendancePolicy`
- `SkillRatingPolicy`
- `SessionStatPolicy`
- `UserPolicy`

Regras principais:

- Qualquer logado ve sessao, listas e ranking.
- Player so confirma/cancela a propria presenca.
- Admin cria/remove presenca avulsa.
- Admin convida jogadores.
- Admin lanca stats.
- Usuario pode avaliar outros players, mas nao a si mesmo.
- Server continua sendo autoridade, mesmo que a UI esconda botoes.

## Cobertura de Testes

Usar:

- RSpec.
- FactoryBot.
- Request specs.
- Policy specs.
- Specs de models/services quando houver regra de dominio.

## Cenarios Criticos

### Auth e Usuarios

- Primeiro usuario seedado e admin.
- Convite cria usuario sem senha e com defaults corretos.
- Aceite de convite define senha e emite tokens.
- `encrypted_password` nunca aparece em resposta.
- `skill_score` nao pode ser alterado por endpoint de usuario.

### Sessoes Semanais

- `current` cria a sessao se nao existir.
- `scheduled_at` respeita `RACHA_WEEKDAY` e `RACHA_TIME`.
- `max_players` respeita `RACHA_MAX_PLAYERS`.

### Presencas

- Player cadastrado confirma propria presenca.
- Player nao confirma presenca de outro usuario.
- Confirmacoes acima de `max_players` entram na lista de espera.
- Cancelamento promove o primeiro da lista de espera.
- Presenca fica read-only depois de `scheduled_at`.
- Presenca avulsa exige admin.
- Presenca avulsa nao cria `User`.

### Avaliacoes

- Score aceita apenas 0-100.
- Autoavaliacao retorna erro.
- Reavaliacao antes de 1 mes retorna erro.
- Criar/atualizar nota recalcula `skill_score`.
- Notas individuais nao sao expostas.

### Stats

- Apenas admin cria/atualiza stats.
- Stats sao agregados por racha semanal.
- Avulsos sem cadastro nao aparecem no ranking.
- Edicao bloqueada apos 24h do racha.

### Sync

- Pull retorna apenas alterados desde `since`.
- Pull inclui tombstones.
- Pull nao retorna `encrypted_password`.
- Push respeita `Idempotency-Key`.
- Push detecta conflito por `version`.
- `attendances` nao aceita push sync.

### Jobs

- Job de sessao cria apenas uma sessao por semana configurada.
- Cleanup remove tombstones com mais de 90 dias.
- Push job envia payload esperado para FCM.


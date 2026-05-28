# Spec 99 - Checklist Geral de Implementacao

Use este arquivo para acompanhar o progresso do MVP. Marque cada item como concluido somente depois de implementado, testado e validado.

## 1. Fundacao do Projeto

- [x] Criar `AGENTS.md` com regras operacionais do projeto.
- [x] Criar specs em `.ia/specs` a partir de `api-rails.md`.
- [x] Adicionar dependencias base do MVP no `Gemfile`.
- [x] Configurar RSpec e FactoryBot.
- [x] Configurar Pundit no controller base.
- [x] Configurar Devise e devise-jwt.
- [x] Configurar CORS para API.
- [x] Configurar ambiente Docker-first de desenvolvimento.
- [x] Configurar timezone da aplicacao e timestamps em UTC.
- [x] Criar envelope padrao de erro no `ApplicationController`.
- [x] Rodar `db:prepare`, RSpec e RuboCop para validar a fundacao.

## 2. Banco e Modelos

- [x] Habilitar extensoes PostgreSQL `citext` e `pgcrypto`.
- [x] Criar concern para UUID v7, soft-delete e versionamento.
- [x] Criar tabela/model `users`.
- [x] Criar tabela/model `weekly_sessions`.
- [x] Criar tabela/model `attendances`.
- [x] Criar tabela/model `skill_ratings`.
- [x] Criar tabela/model `session_stats`.
- [x] Criar tabela/model `processed_mutations`.
- [x] Criar tabela/model `refresh_tokens`.
- [x] Revisar constraints e indices depois dos primeiros fluxos reais.
- [x] Adicionar factories completas para todos os modelos.
- [x] Adicionar specs de validacao/associacao para os modelos principais.

## 3. Config do Clube

- [x] Implementar `GET /api/v1/club`.
- [x] Ler `RACHA_WEEKDAY`, `RACHA_TIME`, `RACHA_LOCATION` e `RACHA_MAX_PLAYERS` do ambiente.
- [x] Adicionar request spec do endpoint.

## 4. Auth e Tokens

- [x] Implementar `POST /api/v1/auth/sign_in`.
- [x] Retornar `access_token` com duracao de 15 min.
- [x] Retornar `refresh_token` com duracao de 30 dias.
- [x] Implementar `DELETE /api/v1/auth/sign_out`.
- [x] Implementar `POST /api/v1/auth/refresh`.
- [x] Invalidar/rotacionar refresh token quando necessario.
- [x] Implementar `POST /api/v1/auth/password`.
- [x] Implementar `PUT /api/v1/auth/password`.
- [x] Garantir que senha nunca seja salva em texto puro.
- [x] Garantir que `encrypted_password` nunca seja serializado.
- [x] Adicionar request specs de login, logout, refresh e password.

## 5. Convites

- [x] Implementar `POST /api/v1/users/invitations`.
- [x] Permitir convite apenas para admin.
- [x] Criar usuario convidado com `admin: false`.
- [x] Criar usuario convidado com `player_type: casual`.
- [x] Criar usuario convidado sem senha ativa.
- [x] Implementar `POST /api/v1/users/accept_invitation`.
- [x] No aceite, definir senha e confirmacao.
- [x] No aceite, permitir escolher `player_type`.
- [x] No aceite, permitir definir `goalkeeper`.
- [x] No aceite, ativar usuario e emitir tokens.
- [x] Adicionar specs de convite por admin.
- [x] Adicionar specs bloqueando convite por usuario comum.
- [x] Adicionar specs de aceite de convite.

## 6. Sessao Semanal

- [x] Implementar service `WeeklySessions::CreateCurrent`.
- [x] Implementar `WeeklySessions::CreateCurrentJob`.
- [x] Implementar `GET /api/v1/weekly_sessions/current`.
- [x] Implementar `GET /api/v1/weekly_sessions/:id`.
- [x] Criar sessao automaticamente quando `current` for chamado.
- [x] Calcular `scheduled_at` usando `RACHA_WEEKDAY` e `RACHA_TIME`.
- [x] Usar `RACHA_MAX_PLAYERS` na criacao da sessao.
- [ ] Agendar job recorrente para o dia configurado as 8h.
- [ ] Disparar notificacao "Racha aberto" ao criar sessao.
- [ ] Adicionar specs de autorizacao para sessoes.
- [ ] Adicionar specs de idempotencia semanal do service/job.

## 7. Presenca do Player

- [ ] Implementar service `Attendance::Confirm`.
- [ ] Implementar service `Attendance::Decline`.
- [ ] Implementar service `Attendance::PromoteWaitlist`.
- [ ] Implementar `POST /api/v1/weekly_sessions/:id/attendances`.
- [ ] Implementar `GET /api/v1/weekly_sessions/:id/attendances`.
- [ ] Confirmar presenca propria de player cadastrado.
- [ ] Cancelar/declinar presenca propria de player cadastrado.
- [ ] Bloquear confirmacao/cancelamento de outro player.
- [ ] Aplicar limite de `max_players`.
- [ ] Colocar novas confirmacoes em lista de espera quando lotado.
- [ ] Promover primeiro da lista de espera quando confirmado cancela.
- [ ] Bloquear alteracoes depois de `scheduled_at`.
- [ ] Garantir que presencas nao entrem no push sync.
- [ ] Adicionar request specs do fluxo de presenca.
- [ ] Adicionar specs de lista de espera e promocao.

## 8. Presenca Avulsa do Admin

- [ ] Implementar service `GuestAttendance::Create`.
- [ ] Implementar service `GuestAttendance::Destroy`.
- [ ] Implementar `POST /api/v1/weekly_sessions/:id/guest_attendances`.
- [ ] Implementar `DELETE /api/v1/weekly_sessions/:id/guest_attendances/:attendance_id`.
- [ ] Permitir criar/remover avulso apenas para admin.
- [ ] Exigir `guest_name`.
- [ ] Garantir que presenca avulsa nao crie `User`.
- [ ] Contabilizar avulso em confirmados e lista de espera.
- [ ] Atualizar contador publico de confirmados.
- [ ] Adicionar request specs de avulso por admin.
- [ ] Adicionar specs bloqueando usuario comum.

## 9. Avaliacoes de Habilidade

- [ ] Implementar service `SkillRatings::Upsert`.
- [ ] Implementar service `SkillRatings::RecalculateScore`.
- [ ] Implementar `POST /api/v1/skill_ratings`.
- [ ] Validar `score` entre 0 e 100.
- [ ] Bloquear autoavaliacao.
- [ ] Permitir apenas uma nota ativa por avaliador/avaliado.
- [ ] Bloquear reavaliacao antes de 1 mes.
- [ ] Recalcular `users.skill_score` ao criar/atualizar nota.
- [ ] Garantir que notas individuais nunca sejam exibidas.
- [ ] Garantir que usuario veja apenas o proprio `skill_score`.
- [ ] Adicionar request specs de avaliacao.
- [ ] Adicionar specs de recalculo de media.

## 10. Stats e Ranking

- [ ] Implementar service `SessionStats::UpsertBatch`.
- [ ] Implementar `POST /api/v1/weekly_sessions/:id/stats`.
- [ ] Implementar `GET /api/v1/stats/leaderboard?period=month|year`.
- [ ] Permitir lancamento de stats apenas para admin.
- [ ] Registrar stats agregados por racha semanal.
- [ ] Bloquear stats para presenca avulsa sem cadastro.
- [ ] Permitir edicao ate 24h apos o racha.
- [ ] Bloquear edicao depois de 24h.
- [ ] Adicionar request specs de stats.
- [ ] Adicionar specs de ranking mensal/anual.

## 11. FCM e Notificacoes

- [ ] Implementar `POST /api/v1/users/me/fcm_token`.
- [ ] Salvar `fcm_token` do usuario logado.
- [ ] Implementar service `Notifications::Push`.
- [ ] Implementar `Notifications::PushJob`.
- [ ] Notificar todos quando o racha abrir.
- [ ] Notificar todos 1h antes do racha.
- [ ] Notificar player promovido da lista de espera.
- [ ] Notificar admin sobre nova confirmacao.
- [ ] Notificar admin sobre cancelamento.
- [ ] Notificar admin sobre avulso adicionado/removido.
- [ ] Enviar data message silenciosa para disparar sync.
- [ ] Adicionar specs do endpoint de FCM.
- [ ] Adicionar specs do payload de push.

## 12. Sync Pull

- [ ] Implementar service `Sync::PullChanges`.
- [ ] Implementar `GET /api/v1/sync`.
- [ ] Aceitar parametro `since`.
- [ ] Aceitar parametro `entities`.
- [ ] Retornar `server_time`.
- [ ] Retornar registros alterados desde `since`.
- [ ] Incluir tombstones com `deleted_at`.
- [ ] Nao retornar `encrypted_password`.
- [ ] Nao retornar `skill_ratings` individuais de outros usuarios.
- [ ] Retornar entidades permitidas: `users`, `weekly_sessions`, `attendances`, `session_stats`.
- [ ] Adicionar request specs de pull sync.

## 13. Sync Push

- [ ] Implementar service `Sync::ApplyMutation`.
- [ ] Implementar `POST /api/v1/sync/{entity}`.
- [ ] Exigir header `Idempotency-Key`.
- [ ] Registrar `mutation_id` em `processed_mutations`.
- [ ] Garantir idempotencia para mutacoes repetidas.
- [ ] Implementar operacoes `create`, `update` e `delete` quando aplicavel.
- [ ] Validar lock otimista por `version`.
- [ ] Retornar `409 Conflict` em conflito de versao.
- [ ] Retornar `422 Unprocessable Entity` em payload invalido.
- [ ] Bloquear push sync de `attendances`.
- [ ] Adicionar request specs de push sync.
- [ ] Adicionar specs de conflito e idempotencia.

## 14. Jobs de Manutencao

- [ ] Implementar `Sync::CleanupTombstonesJob`.
- [ ] Remover fisicamente registros com `deleted_at` ha mais de 90 dias.
- [ ] Agendar cleanup recorrente.
- [ ] Adicionar specs do cleanup.

## 15. Serializers e Privacidade

- [ ] Criar blueprints/serializers para `User`.
- [ ] Criar blueprints/serializers para `Attendance`.
- [ ] Criar blueprints/serializers para `SkillRating` somente quando seguro.
- [ ] Criar blueprints/serializers para `SessionStat`.
- [ ] Revisar todos os payloads para nao expor dados sensiveis.
- [ ] Garantir que `encrypted_password`, tokens e notas individuais nao vazem.

## 16. Policies

- [x] Criar `ApplicationPolicy`.
- [x] Criar `WeeklySessionPolicy`.
- [x] Criar `AttendancePolicy`.
- [x] Criar `GuestAttendancePolicy`.
- [x] Criar `SkillRatingPolicy`.
- [x] Criar `SessionStatPolicy`.
- [x] Criar `UserPolicy`.
- [ ] Adicionar policy specs para sessoes.
- [ ] Adicionar policy specs para presencas.
- [ ] Adicionar policy specs para avulsos.
- [ ] Adicionar policy specs para avaliacoes.
- [ ] Adicionar policy specs para stats.
- [ ] Adicionar policy specs para convites.

## 17. Qualidade e Validacao Final

- [ ] Garantir que todos os endpoints estejam em `/api/v1`.
- [ ] Garantir que erros usem envelope padrao.
- [ ] Garantir mensagens de usuario em pt-BR com acentuacao correta.
- [ ] Garantir comentarios de codigo em portugues quando existirem.
- [ ] Garantir identificadores em ingles.
- [ ] Rodar suite completa RSpec.
- [ ] Rodar RuboCop.
- [ ] Rodar Brakeman.
- [ ] Rodar Bundler Audit.
- [ ] Atualizar README com setup local.
- [ ] Revisar `AGENTS.md` e specs apos implementacao.

## 18. Prioridade para Teste Mobile

Objetivo: deixar o app mobile testavel contra backend local/docker com dados reais e contratos documentados.

### Ambiente e Acesso

- [x] Documentar `API_BASE_URL` local: `http://localhost:4500/api/v1`.
- [x] Documentar `API_BASE_URL` Android emulator: `http://10.0.2.2:4500/api/v1`.
- [x] Garantir que `docker compose up api` exponha a API em `localhost:4500`.
- [x] Confirmar suporte a `Authorization: Bearer <token>`.
- [x] Confirmar suporte a `Content-Type: application/json`.
- [x] Confirmar suporte a `Idempotency-Key` nos endpoints de sync.
- [x] Documentar CORS/headers esperados para o app mobile.

### Credenciais e Seeds de Teste

- [x] Criar seed de admin com email `admin@inimigosdabola.dev`.
- [x] Criar seed de admin com senha `inimigos123`.
- [x] Criar seed de player comum com email/senha documentados.
- [x] Criar alguns players extras para listas, avaliacao e sync.
- [x] Garantir pelo menos um goleiro nos seeds.
- [x] Garantir pelo menos um mensalista nos seeds.
- [x] Garantir pelo menos um casual nos seeds.
- [x] Criar sessao semanal atual nos seeds.
- [x] Criar presencas em estados diferentes: `confirmed`, `declined`, `pending`.
- [x] Criar pelo menos uma presenca avulsa/guest nos seeds.
- [x] Documentar todas as credenciais de teste no README.

### Contratos de Auth para Mobile

- [x] Implementar `POST /api/v1/auth/sign_in`.
- [x] Implementar `POST /api/v1/auth/refresh`.
- [x] Documentar body exato do login.
- [x] Documentar resposta exata do login com `access_token` e `refresh_token`.
- [x] Documentar body exato do refresh.
- [x] Documentar resposta exata do refresh.
- [x] Padronizar erro de access token expirado como `token_expired`.
- [x] Retornar erro de token expirado no shape:
  ```json
  {
    "error": {
      "code": "token_expired",
      "message": "Token expirado."
    }
  }
  ```
- [x] Adicionar request spec para token expirado.

### Endpoints Minimos para Teste Mobile

- [ ] Implementar `GET /api/v1/users/me`.
- [x] Implementar `GET /api/v1/weekly_sessions/current`.
- [ ] Implementar `POST /api/v1/weekly_sessions/:id/attendances`.
- [ ] Implementar `POST /api/v1/weekly_sessions/:id/guest_attendances`.
- [ ] Implementar `DELETE /api/v1/weekly_sessions/:id/guest_attendances/:attendance_id`.
- [ ] Implementar `POST /api/v1/skill_ratings`.
- [ ] Implementar `GET /api/v1/sync`.
- [ ] Implementar `POST /api/v1/sync/:entity`.

### Shapes de JSON para Mobile

- [ ] Criar/documentar shape de `user`.
- [x] Criar shape de `weekly_session`.
- [ ] Criar/documentar shape de `attendance`.
- [ ] Criar/documentar shape de erro padrao.
- [ ] Garantir que `encrypted_password` nunca aparece em payload mobile.
- [ ] Garantir que notas individuais de habilidade nao aparecem em payload mobile.

## 19. Itens Explicitamente Fora do Escopo

- [ ] Confirmar que nao foi criada tabela de partidas curtas.
- [ ] Confirmar que nao foi criada tabela de times sorteados.
- [ ] Confirmar que nao foi criada tabela de placar.
- [ ] Confirmar que nao foi criada tabela de cronometro.
- [ ] Confirmar que nao foi criado multi-tenant.
- [ ] Confirmar que nao foram criados pagamentos.
- [ ] Confirmar que nao foi criado chat.
- [ ] Confirmar que nao foi criado web admin.

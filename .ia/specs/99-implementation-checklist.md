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
- [ ] Revisar constraints e indices depois dos primeiros fluxos reais.
- [ ] Adicionar factories completas para todos os modelos.
- [ ] Adicionar specs de validacao/associacao para os modelos principais.

## 3. Config do Clube

- [x] Implementar `GET /api/v1/club`.
- [x] Ler `RACHA_WEEKDAY`, `RACHA_TIME`, `RACHA_LOCATION` e `RACHA_MAX_PLAYERS` do ambiente.
- [x] Adicionar request spec do endpoint.

## 4. Auth e Tokens

- [ ] Implementar `POST /api/v1/auth/sign_in`.
- [ ] Retornar `access_token` com duracao de 15 min.
- [ ] Retornar `refresh_token` com duracao de 30 dias.
- [ ] Implementar `DELETE /api/v1/auth/sign_out`.
- [ ] Implementar `POST /api/v1/auth/refresh`.
- [ ] Invalidar/rotacionar refresh token quando necessario.
- [ ] Implementar `POST /api/v1/auth/password`.
- [ ] Implementar `PUT /api/v1/auth/password`.
- [ ] Garantir que senha nunca seja salva em texto puro.
- [ ] Garantir que `encrypted_password` nunca seja serializado.
- [ ] Adicionar request specs de login, logout, refresh e password.

## 5. Convites

- [ ] Implementar `POST /api/v1/users/invitations`.
- [ ] Permitir convite apenas para admin.
- [ ] Criar usuario convidado com `admin: false`.
- [ ] Criar usuario convidado com `player_type: casual`.
- [ ] Criar usuario convidado sem senha ativa.
- [ ] Implementar `POST /api/v1/users/accept_invitation`.
- [ ] No aceite, definir senha e confirmacao.
- [ ] No aceite, permitir escolher `player_type`.
- [ ] No aceite, permitir definir `goalkeeper`.
- [ ] No aceite, ativar usuario e emitir tokens.
- [ ] Adicionar specs de convite por admin.
- [ ] Adicionar specs bloqueando convite por usuario comum.
- [ ] Adicionar specs de aceite de convite.

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

## 18. Itens Explicitamente Fora do Escopo

- [ ] Confirmar que nao foi criada tabela de partidas curtas.
- [ ] Confirmar que nao foi criada tabela de times sorteados.
- [ ] Confirmar que nao foi criada tabela de placar.
- [ ] Confirmar que nao foi criada tabela de cronometro.
- [ ] Confirmar que nao foi criado multi-tenant.
- [ ] Confirmar que nao foram criados pagamentos.
- [ ] Confirmar que nao foi criado chat.
- [ ] Confirmar que nao foi criado web admin.

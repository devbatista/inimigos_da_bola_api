# Spec 00 - Visao Geral do MVP

## Objetivo

Construir uma API Rails para o MVP do Inimigos da Bola. A API centraliza jogadores, racha semanal, presencas, avaliacoes, stats, sync e notificacoes.

## Principios

- API versionada em `/api/v1`.
- Backend single-tenant.
- Backend nao conhece partidas curtas, placar, cronometro ou times sorteados.
- Dados sincronizaveis usam UUID v7, soft-delete, versionamento e timestamps UTC.
- Operacoes de presenca sao online obrigatorias e nao entram no push sync.
- Server decide limites, lista de espera, promocao e autorizacao.

## Stack

- Rails API only.
- PostgreSQL.
- Devise + devise-jwt.
- Pundit.
- Sidekiq.
- FCM.
- Blueprinter ou jsonapi-serializer.
- RSpec, FactoryBot, request specs e policy specs.

## Configuracao de Deploy

Variaveis:

- `DATABASE_URL`
- `REDIS_URL`
- `JWT_SECRET`
- `FCM_SERVER_KEY`
- `RACHA_WEEKDAY`, default `monday`
- `RACHA_TIME`, default `20:00`
- `RACHA_LOCATION`, default `Arena X`
- `RACHA_MAX_PLAYERS`, default `20`

As variaveis `RACHA_*` definem o racha fixo do deploy e nao devem ser editaveis via UI.

## Linguagem e Convencoes

- Codigo e identificadores em ingles.
- Comentarios em portugues.
- Mensagens para usuario em pt-BR.
- Commits em portugues com Conventional Commits.

## Fora do Escopo

- Multi-tenant.
- Pagamentos.
- Chat.
- Web admin.
- Tabelas para partidas curtas.
- Tabelas para times sorteados.
- Tabelas para placar.
- Tabelas para cronometro.


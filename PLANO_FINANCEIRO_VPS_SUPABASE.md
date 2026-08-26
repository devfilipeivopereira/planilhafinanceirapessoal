# Controle Financeiro Pessoal — especificação de implantação

## Decisões confirmadas

- Aplicação: monólito modular em Next.js 16 e Supabase compartilhado, com RLS para CRUD e operações privilegiadas apenas no servidor.
- Usar `https://supabase.filipeivopereira.com`; não instalar segundo Supabase nem atualizar Kong/chaves neste projeto.
- Publicar em `https://financeiro.filipeivopereira.com` pela VPS Swarm/Traefik na rede `FilipeNet`.
- Usar o schema exposto `finance`; dados regulares usam chave anônima e RLS.
- V1: família, contas, categorias, lançamentos, transferências, cartões/faturas, orçamento e painel. Todos os dados são cadastrados manualmente.
- Backups ficam somente na VPS por decisão consciente: isso não cobre perda total do servidor.

## Fase 0 — segurança e recuperação (gate obrigatório)

1. Ignorar `.env*`, chaves, dumps e backups; manter somente `.env.example`; varrer segredos antes do primeiro push.
2. Criar `deploy` com chave Ed25519 e validar uma segunda sessão antes de desativar root e senha. Acesso Docker é privilegiado.
3. Backups diários: `pg_dumpall --globals-only`, dump custom do banco `postgres`, archive de `supabase_storage`, configuração de recuperação e manifesto de versões/SHA-256.
4. Retenção independente: 7 diários, 4 semanais, 12 mensais. Restaurar isoladamente com a mesma imagem PostgreSQL antes da primeira migration e mensalmente.
5. Comparar Compose do Portainer aos serviços vivos, registrar/reconciliar divergências antes de redeploy e restringir configuração sensível a `0600`. Não rotacionar isoladamente a chave de serviço legada.

## Fase 1 — aplicação e entrega

- Node 22, lockfile, TypeScript estrito, Tailwind 4, shadcn/ui, Lucide, Zod, React Hook Form, Recharts, Vitest e Playwright.
- Recursos em `src/features`, clientes Supabase em `src/lib/supabase`, rotas nos grupos `(auth)` e `(app)`.
- Server Components para leitura; Server Actions com Zod para mutations; handlers `server-only` para convites e lotes.
- `output: 'standalone'`, Docker multi-stage não-root. CI de PR: `npm ci`, lint, tipos, testes, migrations descartáveis, build, E2E e secret scan. `main` publica imagem privada GHCR pelo SHA.
- Swarm somente com imagem imutável, sem `build`/`latest`: uma réplica, sem porta pública, Traefik na 3000, `start-first`, 768 MiB, healthcheck e logs rotacionados.
- `service_role` fica em Docker secret versionado, montado em `/run/secrets`, nunca em imagem ou env pública.

## Fase 2 — banco, Auth e isolamento

- Acrescentar `finance` a `PGRST_DB_SCHEMAS`, preservando `public`, `storage` e `graphql_public`; conceder privilégios mínimos.
- Tipos: `household_role`, `transaction_kind`, `transaction_status`, `statement_status`, `import_status`, `recurrence_frequency`.
- Tabelas: `profiles`, `households`, `household_members`, `household_invitations`, `accounts`, `categories`, `transactions`, `transfers`, `credit_cards`, `card_statements`, `installment_plans`, `installments`, `recurring_rules`, `budget_items` e `audit_logs`.
- UUID, `timestamptz`, competência, `numeric(15,2)` positivo e moeda; BRL é a moeda consolidada inicial.
- RLS em tudo; `anon` sem privilégios; views `security_invoker`; policies por household/papel. Papéis: owner (tudo), admin (financeiro/convites), member (CRUD financeiro) e viewer (leitura).
- Signup global permanece. O app não cria usuários e envia quem não tem membership a `/sem-acesso`. Preservar `GOTRUE_SITE_URL` e acrescentar apenas domínio financeiro/localhost à allowlist. Usar `@supabase/ssr`, PKCE, cookies e rotas dinâmicas.
- Bootstrap idempotente cria/encontra administrador inicial e household `Família` como owner.

## Fase 3 — produto

- Contas/categorias hierárquicas; saldo = inicial + lançamentos liquidados.
- Lançamentos previsto/liquidado, caixa e competência. `create_transfer` é atômica e não afeta resultado.
- Cartões com fechamento, vencimento, limite e ciclos; dia inválido usa último dia. Compra é despesa por competência; `pay_card_statement` registra só saída de caixa.
- Parcelas únicas por plano/número; recorrências idempotentes por `pg_cron` diário. Orçamento único por household/ano/mês/categoria.
- Rotas: `/login`, `/recuperar-senha`, `/auth/callback`, `/convite`, `/sem-acesso`, `/dashboard`, `/lancamentos`, `/contas`, `/cartoes`, `/orcamento` e configurações.
- Desktop com sidebar/tabelas, mobile com navegação inferior/cards/ação rápida. Exclusões confirmadas. PWA sem cache offline financeiro ou push na V1.

## Fase 4 — produção

- Fazer o primeiro aceite com household sintético. Fixar digest aprovado e manter o anterior para rollback.
- Cadastrar contas, categorias e lançamentos reais somente depois dos gates de segurança, RLS e operação.

## Contratos e gates

- Públicas: `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`. Servidor: `APP_URL`, `ADMIN_EMAIL`, `SUPABASE_SERVICE_ROLE_FILE`.
- `GET /api/health` responde somente `{ "status": "ok" }`. RPCs autenticadas: `create_transfer`, `pay_card_statement` e `generate_scheduled_transactions`.
- Mutations retornam `ActionResult<T> = { ok: true; data: T } | { ok: false; code: string; fieldErrors?: Record<string,string[]> }`.
- IDs UUID, datas ISO-8601 e valores monetários como strings decimais. Sem exposição de service role, household externo ou diagnóstico interno.
- Liberar somente após testes de RLS/papéis, contabilidade, datas, idempotência, segredo, E2E desktop/mobile, TLS/Swarm/Uptime/rollback e restauração de backup.

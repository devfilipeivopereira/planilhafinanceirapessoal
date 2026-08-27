# Livro-caixa pessoal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar CRUD manual de finanças pessoais com uma interface de livro-caixa responsiva.

**Architecture:** Server Components consultam o schema `finance`; componentes cliente controlam filtros e formulários. Server Actions validam com Zod e revalidam a rota afetada.

**Tech Stack:** Next.js 16, React 19, Supabase SSR, Zod, React Hook Form, Lucide e CSS tokens.

---

### Task 1: Camada de dados financeira

**Files:** `app/src/features/finance/queries.ts`, `app/src/features/finance/actions.ts`, `app/src/features/finance/actions.test.ts`

- [ ] Criar testes de serialização decimal, mapeamento de lançamentos e validação de formulário.
- [ ] Implementar consultas de household, categorias, contas, cartões, orçamento e lançamentos.
- [ ] Implementar actions de criar, editar e arquivar, retornando `ActionResult`.
- [ ] Executar `npm test` e `npm run typecheck` em `app`.

### Task 2: Componentes de operação

**Files:** `app/src/features/finance/components/*`, `app/src/app/globals.css`

- [ ] Criar tabela de lançamentos, painel de formulário, árvore de categorias e cards de conta.
- [ ] Cobrir estados de carregamento, vazio, erro, confirmação e mobile.
- [ ] Executar testes e build Linux.

### Task 3: Telas e publicação

**Files:** `app/src/app/(app)/*/page.tsx`, `app/Dockerfile`

- [ ] Conectar dashboard, lançamentos, contas, cartões, orçamento e categorias aos componentes.
- [ ] Validar login, CRUD e RLS no navegador.
- [ ] Construir imagem, fazer deploy Swarm `start-first` e validar healthcheck/TLS.

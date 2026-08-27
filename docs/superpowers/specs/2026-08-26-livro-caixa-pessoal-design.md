# Livro-caixa pessoal — design

O produto adota a referência operacional do módulo financeiro do sistema IFC: cabeçalho de período, resumo financeiro, tabela de lançamentos como área central e categorias em árvore. A implementação preserva a proposta pessoal: visual editorial sóbrio, uma família por contexto e operações simples.

## Fluxos

- Dashboard: filtro de mês, saldo, receitas, despesas, resultado, orçamento e últimos lançamentos.
- Lançamentos: tabela filtrável, criação/edição/exclusão em painel lateral; receita, despesa e transferência.
- Categorias: árvore por tipo, expansão de subcategorias e modal para criar/editar/remover.
- Contas e cartões: cards com saldo/limite e formulários de cadastro.
- Orçamento: limites mensais por categoria e consumo calculado por competência.

## Limites

Não inclui importação, anexos, OFX, dízimos, recibos ou relatórios institucionais. Toda operação usa o schema `finance`, as policies existentes e valores monetários decimais como string.

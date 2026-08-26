begin;

create schema if not exists finance;
revoke all on schema finance from public, anon;
grant usage on schema finance to authenticated, service_role;

create type finance.household_role as enum ('owner', 'admin', 'member', 'viewer');
create type finance.transaction_kind as enum ('income', 'expense', 'transfer');
create type finance.transaction_status as enum ('planned', 'settled');
create type finance.recurrence_frequency as enum ('weekly', 'monthly', 'yearly');

create table finance.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(trim(display_name)) between 1 and 120),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table finance.households (
  id uuid primary key default gen_random_uuid(), name text not null check (char_length(trim(name)) between 1 and 120),
  currency_code char(3) not null default 'BRL' check (currency_code = 'BRL'), created_at timestamptz not null default now()
);
create table finance.household_members (
  household_id uuid not null references finance.households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role finance.household_role not null, created_at timestamptz not null default now(),
  primary key (household_id, user_id)
);
create table finance.categories (
  id uuid primary key default gen_random_uuid(), household_id uuid not null references finance.households(id) on delete cascade,
  parent_id uuid references finance.categories(id) on delete restrict,
  name text not null check (char_length(trim(name)) between 1 and 80), kind finance.transaction_kind not null check (kind <> 'transfer'),
  color text, archived_at timestamptz, created_at timestamptz not null default now(),
  unique nulls not distinct (household_id, parent_id, name, kind)
);
create table finance.accounts (
  id uuid primary key default gen_random_uuid(), household_id uuid not null references finance.households(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 80), account_type text not null check (account_type in ('checking','savings','cash','investment')),
  opening_balance numeric(15,2) not null default 0, opening_balance_date date not null default current_date,
  archived_at timestamptz, created_at timestamptz not null default now(), unique (household_id, name)
);
create table finance.credit_cards (
  id uuid primary key default gen_random_uuid(), household_id uuid not null references finance.households(id) on delete cascade,
  account_id uuid references finance.accounts(id) on delete set null, name text not null,
  limit_amount numeric(15,2) not null check (limit_amount >= 0), closing_day smallint not null check (closing_day between 1 and 31),
  due_day smallint not null check (due_day between 1 and 31), archived_at timestamptz, created_at timestamptz not null default now(), unique (household_id, name)
);
create table finance.transactions (
  id uuid primary key default gen_random_uuid(), household_id uuid not null references finance.households(id) on delete cascade,
  account_id uuid references finance.accounts(id) on delete restrict, credit_card_id uuid references finance.credit_cards(id) on delete restrict,
  category_id uuid references finance.categories(id) on delete set null, kind finance.transaction_kind not null,
  status finance.transaction_status not null default 'settled', amount numeric(15,2) not null check (amount > 0),
  description text not null check (char_length(trim(description)) between 1 and 240), cash_date date, competency_date date not null,
  transfer_group_id uuid, created_by uuid not null references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check ((kind = 'transfer') = (transfer_group_id is not null)),
  check ((account_id is not null)::integer + (credit_card_id is not null)::integer = 1)
);
create table finance.recurring_rules (
  id uuid primary key default gen_random_uuid(), household_id uuid not null references finance.households(id) on delete cascade,
  account_id uuid references finance.accounts(id) on delete restrict, category_id uuid references finance.categories(id) on delete set null,
  kind finance.transaction_kind not null check (kind <> 'transfer'), amount numeric(15,2) not null check (amount > 0), description text not null,
  frequency finance.recurrence_frequency not null, day_of_month smallint check (day_of_month between 1 and 31), starts_on date not null, ends_on date,
  active boolean not null default true, created_by uuid not null references auth.users(id), created_at timestamptz not null default now()
);
create table finance.budget_items (
  id uuid primary key default gen_random_uuid(), household_id uuid not null references finance.households(id) on delete cascade,
  category_id uuid not null references finance.categories(id) on delete restrict, year smallint not null check (year between 2000 and 2100),
  month smallint not null check (month between 1 and 12), amount numeric(15,2) not null check (amount >= 0),
  unique (household_id, category_id, year, month)
);

grant select, insert, update, delete on all tables in schema finance to authenticated;
alter default privileges in schema finance grant select, insert, update, delete on tables to authenticated;

create or replace function finance.has_household_role(target_household uuid, allowed finance.household_role[])
returns boolean language sql stable security definer set search_path = finance, public as $$
  select exists (select 1 from finance.household_members m where m.household_id = target_household and m.user_id = auth.uid() and m.role = any(allowed));
$$;
grant execute on function finance.has_household_role(uuid, finance.household_role[]) to authenticated;

alter table finance.profiles enable row level security;
alter table finance.households enable row level security;
alter table finance.household_members enable row level security;
alter table finance.categories enable row level security;
alter table finance.accounts enable row level security;
alter table finance.credit_cards enable row level security;
alter table finance.transactions enable row level security;
alter table finance.recurring_rules enable row level security;
alter table finance.budget_items enable row level security;

create policy profiles_self on finance.profiles for all to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy households_member_read on finance.households for select to authenticated using (finance.has_household_role(id, array['owner','admin','member','viewer']::finance.household_role[]));
create policy household_members_read on finance.household_members for select to authenticated using (finance.has_household_role(household_id, array['owner','admin','member','viewer']::finance.household_role[]));

create policy finance_read_categories on finance.categories for select to authenticated using (finance.has_household_role(household_id, array['owner','admin','member','viewer']::finance.household_role[]));
create policy finance_write_categories on finance.categories for all to authenticated using (finance.has_household_role(household_id, array['owner','admin','member']::finance.household_role[])) with check (finance.has_household_role(household_id, array['owner','admin','member']::finance.household_role[]));
create policy finance_read_accounts on finance.accounts for select to authenticated using (finance.has_household_role(household_id, array['owner','admin','member','viewer']::finance.household_role[]));
create policy finance_write_accounts on finance.accounts for all to authenticated using (finance.has_household_role(household_id, array['owner','admin','member']::finance.household_role[])) with check (finance.has_household_role(household_id, array['owner','admin','member']::finance.household_role[]));
create policy finance_read_cards on finance.credit_cards for select to authenticated using (finance.has_household_role(household_id, array['owner','admin','member','viewer']::finance.household_role[]));
create policy finance_write_cards on finance.credit_cards for all to authenticated using (finance.has_household_role(household_id, array['owner','admin','member']::finance.household_role[])) with check (finance.has_household_role(household_id, array['owner','admin','member']::finance.household_role[]));
create policy finance_read_transactions on finance.transactions for select to authenticated using (finance.has_household_role(household_id, array['owner','admin','member','viewer']::finance.household_role[]));
create policy finance_write_transactions on finance.transactions for all to authenticated using (finance.has_household_role(household_id, array['owner','admin','member']::finance.household_role[])) with check (finance.has_household_role(household_id, array['owner','admin','member']::finance.household_role[]));
create policy finance_read_recurring on finance.recurring_rules for select to authenticated using (finance.has_household_role(household_id, array['owner','admin','member','viewer']::finance.household_role[]));
create policy finance_write_recurring on finance.recurring_rules for all to authenticated using (finance.has_household_role(household_id, array['owner','admin','member']::finance.household_role[])) with check (finance.has_household_role(household_id, array['owner','admin','member']::finance.household_role[]));
create policy finance_read_budget on finance.budget_items for select to authenticated using (finance.has_household_role(household_id, array['owner','admin','member','viewer']::finance.household_role[]));
create policy finance_write_budget on finance.budget_items for all to authenticated using (finance.has_household_role(household_id, array['owner','admin','member']::finance.household_role[])) with check (finance.has_household_role(household_id, array['owner','admin','member']::finance.household_role[]));

commit;

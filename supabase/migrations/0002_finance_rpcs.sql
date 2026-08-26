begin;

create or replace function finance.create_transfer(
  p_household_id uuid, p_from_account_id uuid, p_to_account_id uuid, p_amount numeric,
  p_description text, p_cash_date date, p_competency_date date
) returns uuid language plpgsql security invoker set search_path = finance, public as $$
declare transfer_id uuid := gen_random_uuid();
begin
  if p_amount <= 0 or p_from_account_id = p_to_account_id then raise exception 'invalid_transfer'; end if;
  if not finance.has_household_role(p_household_id, array['owner','admin','member']::finance.household_role[]) then raise exception 'forbidden'; end if;
  insert into finance.transactions (household_id, account_id, kind, status, amount, description, cash_date, competency_date, transfer_group_id, created_by)
  values (p_household_id, p_from_account_id, 'transfer', 'settled', p_amount, p_description, p_cash_date, p_competency_date, transfer_id, auth.uid()),
         (p_household_id, p_to_account_id, 'transfer', 'settled', p_amount, p_description, p_cash_date, p_competency_date, transfer_id, auth.uid());
  return transfer_id;
end $$;
grant execute on function finance.create_transfer(uuid, uuid, uuid, numeric, text, date, date) to authenticated;

create or replace function finance.generate_scheduled_transactions(p_until date default current_date)
returns integer language plpgsql security definer set search_path = finance, public as $$
declare rule finance.recurring_rules%rowtype; generated integer := 0; occurrence date;
begin
  for rule in select * from finance.recurring_rules where active and starts_on <= p_until and (ends_on is null or ends_on >= starts_on) loop
    occurrence := case rule.frequency when 'weekly' then greatest(rule.starts_on, p_until - 6) else make_date(extract(year from p_until)::int, extract(month from p_until)::int, least(coalesce(rule.day_of_month, 1), extract(day from (date_trunc('month', p_until)::date + interval '1 month - 1 day'))::int)) end;
    if occurrence between rule.starts_on and p_until and (rule.ends_on is null or occurrence <= rule.ends_on) and not exists (select 1 from finance.transactions where household_id = rule.household_id and description = rule.description and competency_date = occurrence and account_id = rule.account_id and amount = rule.amount) then
      insert into finance.transactions (household_id, account_id, category_id, kind, status, amount, description, cash_date, competency_date, created_by)
      values (rule.household_id, rule.account_id, rule.category_id, rule.kind, 'planned', rule.amount, rule.description, occurrence, occurrence, rule.created_by);
      generated := generated + 1;
    end if;
  end loop;
  return generated;
end $$;
revoke all on function finance.generate_scheduled_transactions(date) from public;
grant execute on function finance.generate_scheduled_transactions(date) to service_role;

commit;

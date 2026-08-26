"use server";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import type { ActionResult } from "@/features/shared/action-result";
import { accountSchema, cardSchema, categorySchema } from "./schemas";

function failure(error: ReturnType<typeof categorySchema.safeParse>): ActionResult<never> {
  return { ok: false, code: "validation_error", fieldErrors: error.success ? undefined : error.error.flatten().fieldErrors };
}
export async function createCategory(input: unknown): Promise<ActionResult<{ id: string }>> {
  const parsed = categorySchema.safeParse(input); if (!parsed.success) return failure(parsed);
  const db = await createClient(); const { data, error } = await db.schema("finance").from("categories").insert({ household_id: parsed.data.householdId, parent_id: parsed.data.parentId ?? null, name: parsed.data.name, kind: parsed.data.kind, color: parsed.data.color ?? null }).select("id").single();
  if (error) return { ok: false, code: "category_create_failed" }; revalidatePath("/configuracoes"); return { ok: true, data };
}
export async function createAccount(input: unknown): Promise<ActionResult<{ id: string }>> {
  const parsed = accountSchema.safeParse(input); if (!parsed.success) return failure(parsed as never);
  const db = await createClient(); const { data, error } = await db.schema("finance").from("accounts").insert({ household_id: parsed.data.householdId, name: parsed.data.name, account_type: parsed.data.accountType, opening_balance: parsed.data.openingBalance, opening_balance_date: parsed.data.openingBalanceDate }).select("id").single();
  if (error) return { ok: false, code: "account_create_failed" }; revalidatePath("/contas"); return { ok: true, data };
}
export async function createCard(input: unknown): Promise<ActionResult<{ id: string }>> {
  const parsed = cardSchema.safeParse(input); if (!parsed.success) return failure(parsed as never);
  const db = await createClient(); const { data, error } = await db.schema("finance").from("credit_cards").insert({ household_id: parsed.data.householdId, account_id: parsed.data.accountId ?? null, name: parsed.data.name, limit_amount: parsed.data.limitAmount, closing_day: parsed.data.closingDay, due_day: parsed.data.dueDay }).select("id").single();
  if (error) return { ok: false, code: "card_create_failed" }; revalidatePath("/cartoes"); return { ok: true, data };
}

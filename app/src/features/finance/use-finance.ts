"use client";
import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/browser";

export type FinanceContext = { householdId: string; userId: string };
export function useFinance() {
  const [context, setContext] = useState<FinanceContext | null>(null); const [error, setError] = useState<string | null>(null);
  useEffect(() => { const db = createClient(); void (async () => { const { data: { user } } = await db.auth.getUser(); if (!user) return setError("Sessão expirada."); const { data, error: memberError } = await db.schema("finance").from("household_members").select("household_id").eq("user_id", user.id).maybeSingle(); if (memberError || !data) return setError("Você não possui acesso a uma família."); setContext({ householdId: data.household_id, userId: user.id }); })(); }, []);
  return { context, error };
}

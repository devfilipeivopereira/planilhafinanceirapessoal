import { z } from "zod";

export const categorySchema = z.object({ householdId: z.uuid(), name: z.string().trim().min(1).max(80), kind: z.enum(["income", "expense"]), parentId: z.uuid().nullable().optional(), color: z.string().trim().max(16).nullable().optional() });
export const accountSchema = z.object({ householdId: z.uuid(), name: z.string().trim().min(1).max(80), accountType: z.enum(["checking", "savings", "cash", "investment"]), openingBalance: z.string().regex(/^[-]?\d+(\.\d{1,2})?$/), openingBalanceDate: z.iso.date() });
export const cardSchema = z.object({ householdId: z.uuid(), accountId: z.uuid().nullable().optional(), name: z.string().trim().min(1).max(80), limitAmount: z.string().regex(/^\d+(\.\d{1,2})?$/), closingDay: z.coerce.number().int().min(1).max(31), dueDay: z.coerce.number().int().min(1).max(31) });

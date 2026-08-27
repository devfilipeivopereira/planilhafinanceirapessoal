import { centsToDecimal, decimalToCents } from "./money";

export type DashboardTransaction = { kind: "income" | "expense" | "transfer"; status: "planned" | "settled"; amount: string; competency_date: string; account_id: string | null };

export function calculateDashboard({ openingBalances, transactions, budget, monthPrefix }: { openingBalances: string[]; transactions: DashboardTransaction[]; budget: string; monthPrefix: string }) {
  let balance = openingBalances.reduce((total, amount) => total + decimalToCents(amount), 0);
  let income = 0; let expense = 0;
  for (const transaction of transactions) {
    if (transaction.status !== "settled" || transaction.kind === "transfer") continue;
    const cents = decimalToCents(transaction.amount);
    if (transaction.account_id) balance += transaction.kind === "income" ? cents : -cents;
    if (!transaction.competency_date.startsWith(monthPrefix)) continue;
    if (transaction.kind === "income") income += cents;
    if (transaction.kind === "expense") expense += cents;
  }
  const budgetCents = decimalToCents(budget);
  return { balance: centsToDecimal(balance), income: centsToDecimal(income), expense: centsToDecimal(expense), budget, budgetRemaining: centsToDecimal(budgetCents - expense) };
}

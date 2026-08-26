export type CashTransaction = { kind: "income" | "expense" | "transfer"; status: "planned" | "settled"; amount: string };

export function decimalToCents(value: string): number {
  if (!/^\d+(\.\d{1,2})?$/.test(value)) throw new Error("invalid_decimal");
  const [whole, fraction = ""] = value.split(".");
  return Number(whole) * 100 + Number(fraction.padEnd(2, "0"));
}
export function centsToDecimal(cents: number): string {
  const sign = cents < 0 ? "-" : ""; const absolute = Math.abs(cents);
  return `${sign}${Math.floor(absolute / 100)}.${String(absolute % 100).padStart(2, "0")}`;
}
export function sumSettledBalance(openingBalance: string, transactions: CashTransaction[]): string {
  const cents = transactions.reduce((total, transaction) => {
    if (transaction.status !== "settled" || transaction.kind === "transfer") return total;
    const amount = decimalToCents(transaction.amount);
    return total + (transaction.kind === "income" ? amount : -amount);
  }, decimalToCents(openingBalance));
  return centsToDecimal(cents);
}
export function formatBRL(value: string): string {
  return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(decimalToCents(value) / 100);
}

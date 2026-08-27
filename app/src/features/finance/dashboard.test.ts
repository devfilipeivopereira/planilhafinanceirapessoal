import { describe, expect, it } from "vitest";
import { calculateDashboard } from "./dashboard";

describe("calculateDashboard", () => {
  it("separates settled monthly cashflow and keeps transfers outside the result", () => {
    const result = calculateDashboard({
      openingBalances: ["100.00"],
      transactions: [
        { kind: "income", status: "settled", amount: "400.00", competency_date: "2026-08-02", account_id: "a" },
        { kind: "expense", status: "settled", amount: "120.00", competency_date: "2026-08-03", account_id: "a" },
        { kind: "transfer", status: "settled", amount: "50.00", competency_date: "2026-08-04", account_id: "a" },
        { kind: "expense", status: "planned", amount: "25.00", competency_date: "2026-08-05", account_id: "a" },
      ],
      budget: "200.00",
      monthPrefix: "2026-08",
    });

    expect(result).toEqual({ balance: "380.00", income: "400.00", expense: "120.00", budget: "200.00", budgetRemaining: "80.00" });
  });
});

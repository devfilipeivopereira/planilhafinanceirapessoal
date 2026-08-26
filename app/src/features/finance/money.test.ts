import { describe, expect, it } from "vitest";
import { decimalToCents, formatBRL, sumSettledBalance } from "./money";

describe("money domain rules", () => {
  it("does not use floating point for decimal values", () => {
    expect(decimalToCents("0.10")).toBe(10);
    expect(decimalToCents("1234.56")).toBe(123456);
  });

  it("only includes settled cash transactions in an account balance", () => {
    expect(sumSettledBalance("100.00", [
      { kind: "income", status: "settled", amount: "50.00" },
      { kind: "expense", status: "settled", amount: "12.30" },
      { kind: "expense", status: "planned", amount: "99.00" },
      { kind: "transfer", status: "settled", amount: "20.00" },
    ])).toBe("137.70");
  });

  it("formats Brazilian currency", () => {
    expect(formatBRL("137.70")).toBe("R$ 137,70");
  });
});

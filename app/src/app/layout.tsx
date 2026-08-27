import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Pessoal | Controle financeiro",
  description: "Controle financeiro familiar, privado e simples.",
  icons: { icon: "/icon.svg" },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="pt-BR"><body>{children}</body></html>;
}

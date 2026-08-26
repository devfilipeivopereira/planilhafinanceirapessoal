import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
const links = [["/dashboard","Visão geral"],["/lancamentos","Lançamentos"],["/contas","Contas"],["/cartoes","Cartões"],["/orcamento","Orçamento"],["/configuracoes","Categorias"]];
export default async function AppLayout({ children }: { children: React.ReactNode }) { const db = await createClient(); const { data: { user } } = await db.auth.getUser(); if (!user) redirect("/login"); const { data: member } = await db.schema("finance").from("household_members").select("household_id").eq("user_id", user.id).maybeSingle(); if (!member) redirect("/sem-acesso"); return <div className="app-shell"><aside className="sidebar"><p className="brand">pessoal.</p><nav className="nav">{links.map(([href,label]) => <Link key={href} href={href}>{label}</Link>)}</nav></aside><main className="main">{children}</main></div>; }

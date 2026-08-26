import Link from "next/link";
const links = [["/dashboard","Visão geral"],["/lancamentos","Lançamentos"],["/contas","Contas"],["/cartoes","Cartões"],["/orcamento","Orçamento"],["/configuracoes","Categorias"]];
export default function AppLayout({ children }: { children: React.ReactNode }) { return <div className="app-shell"><aside className="sidebar"><p className="brand">pessoal.</p><nav className="nav">{links.map(([href,label]) => <Link key={href} href={href}>{label}</Link>)}</nav></aside><main className="main">{children}</main></div>; }

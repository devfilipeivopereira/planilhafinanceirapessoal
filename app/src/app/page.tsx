import Link from "next/link";

export default function Home() {
  return <main className="welcome"><p className="eyebrow">PESSOAL · CONTROLE FINANCEIRO</p><h1>Clareza para decidir o que importa.</h1><p className="lede">Organize a vida financeira da sua família com lançamentos, cartões e orçamento em um único lugar privado.</p><Link className="button" href="/login">Entrar no controle</Link></main>;
}

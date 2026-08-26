import Link from "next/link";
export default function NoAccess() { return <main className="welcome"><p className="eyebrow">ACESSO RESTRITO</p><h1>Esta conta ainda não participa de uma família.</h1><p className="lede">Peça a um administrador para enviar um convite.</p><Link className="button" href="/login">Voltar ao login</Link></main>; }

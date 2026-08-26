import Link from "next/link";
import { LoginForm } from "@/features/auth/login-form";
export default function Login() { return <main className="welcome"><p className="eyebrow">ACESSO SEGURO</p><h1>Entre na sua vida financeira.</h1><p className="lede">Use o e-mail e a senha da sua conta. O acesso é liberado somente para membros da família.</p><LoginForm /><Link href="/recuperar-senha">Esqueci minha senha</Link></main>; }

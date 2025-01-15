import "@/styles/globals.css";
import type { AppProps } from "next/app";
import { Exo_2, Faustina } from "next/font/google";

const exo2 = Exo_2({
  variable: "--font-exo-2",
  subsets: ["latin"],
});

const faustina = Faustina({
  variable: "--font-faustina",
  subsets: ["latin"],
});

export default function App({ Component, pageProps }: AppProps) {
  return <main className={`${exo2.variable} ${faustina.variable}`}><Component {...pageProps} /></main>;
}

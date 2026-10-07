import type { ComponentChildren } from "preact";
import { skip, visuallyHidden, wrap } from "../app/global.css.ts";
import * as s from "./shell.css.ts";

export const Header = () => (
  <header class={s.nav}>
    <div class={`${wrap} ${s.navInner}`}>
      <a class={s.brand} href="https://peculiar.systems">
        Pecul<i class={s.brandMark}>i</i>ar Systems
      </a>
      <div class={s.navRight}>
        <a class={s.navProduct} href="/">
          Insights
        </a>
        <span class={s.status}>
          <span class={s.statusDot} aria-hidden="true" />
          Beta
        </span>
        <a class={s.navLink} href="/why">
          Why
        </a>
        <a class={s.navLink} href="/privacy">
          Data & consent
        </a>
        <a class={s.navLink} href="/architecture">
          Architecture
        </a>
        <a class={s.navDocs} href="/docs">
          Docs
        </a>
        <a class={s.navBack} href="https://peculiar.systems">
          All products ↗
        </a>
      </div>
    </div>
  </header>
);

export const Footer = () => (
  <footer class={s.footer}>
    <div class={`${wrap} ${s.footerInner}`}>
      <span>Insights · a Peculiar Systems product · MIT</span>
      <span>
        <a class={s.footerLink} href="/why">
          Why
        </a>
        {" · "}
        <a class={s.footerLink} href="/privacy">
          Data & consent
        </a>
        {" · "}
        <a class={s.footerLink} href="/architecture">
          Architecture
        </a>
        {" · "}
        <a class={s.footerLink} href="/docs">
          Docs
        </a>
        {" · "}
        <a class={s.footerLink} href="https://github.com/peculiar-systems/peculiar-insights">
          Source
        </a>
      </span>
      <span>
        A peculiar product ·{" "}
        <a class={s.footerLink} href="https://peculiar.systems/privacy">
          Privacy
        </a>
        {" · "}
        <a class={s.footerLink} href="https://peculiar.systems/terms">
          Terms
        </a>
        {" · "}
        <a class={s.footerLink} href="https://peculiar.systems/refunds">
          Refunds
        </a>
        {" · "}
        <a class={s.footerLink} href="https://peculiar.systems">
          peculiar.systems
        </a>
      </span>
    </div>
  </footer>
);

export const Shell = ({ children }: { readonly children: ComponentChildren }) => (
  <>
    <a class={skip} href="#main">
      Skip to content
    </a>
    <Header />
    <main id="main" class={s.main}>
      {children}
    </main>
    <Footer />
    <span class={visuallyHidden} aria-hidden="true" />
  </>
);

import { button, wrap } from "../app/global.css.ts";
import { Funnel } from "./Funnel.tsx";
import * as s from "./pages.css.ts";

export const NotFound = () => (
  <div class={`${wrap} ${s.notFound}`}>
    <p class={s.kicker}>404</p>
    <h1>Nothing here.</h1>
    <p style={{ marginTop: "12px", marginBottom: "24px" }}>
      The page does not exist, or it moved. As a funnel, it looks like this.
    </p>
    <Funnel />
    <a class={button} href="/">
      Back to Insights
    </a>
  </div>
);

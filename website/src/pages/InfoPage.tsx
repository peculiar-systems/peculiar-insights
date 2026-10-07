import { prose, wrap } from "../app/global.css.ts";
import { infoPages, findPage } from "../content.ts";
import { NotFound } from "./NotFound.tsx";
import * as s from "./pages.css.ts";

export const InfoPage = ({ path }: { readonly path: string }) => {
  const page = findPage(infoPages, path);
  if (page === undefined) {
    return <NotFound />;
  }
  return (
    <article class={`${wrap} ${s.article}`}>
      <p class={s.kicker}>{page.section}</p>
      <div class={prose} dangerouslySetInnerHTML={{ __html: page.html }} />
    </article>
  );
};

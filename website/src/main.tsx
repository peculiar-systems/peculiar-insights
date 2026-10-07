import { hydrate, prerender as ssr } from "preact-iso";
import { App } from "./app/App.tsx";
import { docPages, infoPages } from "./content.ts";

const titleFor = (url: string): string => {
  const trimmed = url.replace(/\/$/u, "");
  const path = trimmed === "" ? "/" : trimmed;
  if (path === "/") {
    return "Insights by Peculiar Systems";
  }
  const page = [...docPages, ...infoPages].find((candidate) => candidate.path === path);
  return page === undefined ? "Insights by Peculiar Systems" : `${page.title} · Insights`;
};

if ("document" in globalThis) {
  const root = globalThis.document.querySelector("#app");
  if (root !== null) {
    hydrate(<App />, root);
  }
}

export const prerender = async (data: { readonly url: string }) => {
  const { html, links } = await ssr(<App />);
  return {
    html,
    links,
    head: {
      title: titleFor(data.url),
      lang: "en",
    },
  };
};

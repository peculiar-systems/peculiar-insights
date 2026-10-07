import { hydrate, prerender as ssr } from "preact-iso";
import { App } from "./app/App.tsx";
import { docPages, findPage, infoPages } from "./content.ts";

const site = "https://insights.peculiar.systems";
const description =
  "Self-hosted product analytics and crash tracking with consent built in. Haskell over gRPC, PostgreSQL, Grafana.";

const pathOf = (url: string): string => {
  const trimmed = url.replace(/[?#].*$/u, "").replace(/\/$/u, "");
  return trimmed === "" ? "/" : trimmed;
};

type HeadElement = {
  readonly type: string;
  readonly props: { readonly [key: string]: string };
};

const headFor = (url: string, title: string): Set<HeadElement> => {
  const path = pathOf(url);
  if (path === "/404") {
    return new Set([{ type: "meta", props: { name: "robots", content: "noindex" } }]);
  }
  const address = `${site}${path === "/" ? "/" : path}`;
  return new Set<HeadElement>([
    { type: "link", props: { rel: "canonical", href: address } },
    { type: "meta", props: { property: "og:type", content: "website" } },
    { type: "meta", props: { property: "og:site_name", content: "Peculiar Systems" } },
    { type: "meta", props: { property: "og:title", content: title } },
    { type: "meta", props: { property: "og:description", content: description } },
    { type: "meta", props: { property: "og:url", content: address } },
    { type: "meta", props: { property: "og:image", content: `${site}/og.png` } },
    { type: "meta", props: { name: "twitter:card", content: "summary_large_image" } },
  ]);
};

const titleFor = (url: string): string => {
  const trimmed = url.replace(/\/$/u, "");
  const path = trimmed === "" ? "/" : trimmed;
  if (path === "/") {
    return "Insights by Peculiar Systems";
  }
  const page = findPage([...docPages, ...infoPages], path);
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
      elements: headFor(data.url, titleFor(data.url)),
    },
  };
};

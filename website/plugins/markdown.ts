import { marked } from "marked";
import type { Plugin } from "vite";

type FrontMatter = { readonly [key: string]: string };

const parseFrontMatter = (
  source: string,
): { readonly meta: FrontMatter; readonly body: string } => {
  const match = /^---\n([\s\S]*?)\n---\n/u.exec(source);
  if (match === null || match[1] === undefined) {
    return { meta: {}, body: source };
  }
  const meta = Object.fromEntries(
    match[1]
      .split("\n")
      .map((line) => line.split(/:\s(.*)/u))
      .filter((parts): parts is [string, string, string] => parts.length >= 2)
      .map(([key, value]) => [key.trim(), value.trim()]),
  );
  return { meta, body: source.slice(match[0].length) };
};

export const markdown = (): Plugin => ({
  name: "peculiar-markdown",
  enforce: "pre",
  transform: (code, id) => {
    if (!id.endsWith(".md")) {
      return null;
    }
    const { meta, body } = parseFrontMatter(code);
    const html = marked.parse(body, { async: false, gfm: true });
    return {
      code: `export const meta = ${JSON.stringify(meta)};\nexport const html = ${JSON.stringify(html)};`,
      map: null,
    };
  },
});

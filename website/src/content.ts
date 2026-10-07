type Document = {
  readonly meta: { readonly [key: string]: string };
  readonly html: string;
};

export type Page = {
  readonly path: string;
  readonly title: string;
  readonly order: number;
  readonly section: string;
  readonly html: string;
};

const docs = import.meta.glob<Document>("../content/docs/**/*.md", { eager: true });
const info = import.meta.glob<Document>("../content/info/*.md", { eager: true });

const toPage = (file: string, document: Document, prefix: string, base: string): Page => {
  const relative = file.slice(base.length).replace(/\.md$/u, "");
  const order = Number(document.meta["order"] ?? "999");
  return {
    path: `${prefix}${relative === "index" ? "" : `/${relative}`}`,
    title: document.meta["title"] ?? relative,
    order: Number.isNaN(order) ? 999 : order,
    section: document.meta["section"] ?? "",
    html: document.html,
  };
};

const sorted = (pages: readonly Page[]): readonly Page[] =>
  pages.toSorted((a, b) =>
    a.order === b.order ? a.title.localeCompare(b.title) : a.order - b.order,
  );

export const docPages: readonly Page[] = sorted(
  Object.entries(docs).map(([file, document]) =>
    toPage(file, document, "/docs", "../content/docs/"),
  ),
);

export const infoPages: readonly Page[] = sorted(
  Object.entries(info).map(([file, document]) => toPage(file, document, "", "../content/info/")),
);

export const findPage = (pages: readonly Page[], path: string): Page | undefined => {
  const wanted = path.replace(/\/$/u, "");
  const exact = pages.find((page) => page.path === wanted);
  return exact ?? (wanted === "/docs" ? pages[0] : undefined);
};

export const docSections = (): readonly {
  readonly name: string;
  readonly pages: readonly Page[];
}[] => {
  const names = [...new Set(docPages.map((page) => page.section))];
  return names.map((name) => ({ name, pages: docPages.filter((page) => page.section === name) }));
};

import { mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { persistedOf, type Persisted, type Storage } from "../core/storage.ts";

const fileName = "state.json";

const missing = (error: unknown): boolean =>
  typeof error === "object" && error !== null && "code" in error && error.code === "ENOENT";

export const fileStorage = (directory: string): Storage => {
  const path = join(directory, fileName);
  const temporary = join(directory, `${fileName}.tmp`);
  return {
    load: async () => {
      try {
        const raw: unknown = JSON.parse(await readFile(path, "utf8"));
        return persistedOf(raw);
      } catch (error: unknown) {
        if (missing(error)) {
          return undefined;
        }
        throw error;
      }
    },
    save: async (state: Persisted) => {
      await mkdir(directory, { recursive: true });
      await writeFile(temporary, JSON.stringify(state), "utf8");
      await rename(temporary, path);
    },
    clear: async () => {
      await rm(path, { force: true });
    },
  };
};

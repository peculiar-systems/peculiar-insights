import { persistedOf, type Persisted, type Storage } from "../core/storage.ts";

const databaseName = "peculiar-insights";
const storeName = "state";
const key = "state";
const version = 1;

const open = (): Promise<IDBDatabase> =>
  new Promise((resolve, reject) => {
    const request = indexedDB.open(databaseName, version);
    request.addEventListener("upgradeneeded", () => {
      request.result.createObjectStore(storeName);
    });
    request.addEventListener("success", () => {
      resolve(request.result);
    });
    request.addEventListener("error", () => {
      reject(request.error ?? new Error("indexeddb open failed"));
    });
  });

const transact = async <T>(
  mode: IDBTransactionMode,
  action: (store: IDBObjectStore) => IDBRequest<T>,
): Promise<T> => {
  const database = await open();
  return new Promise<T>((resolve, reject) => {
    const transaction = database.transaction(storeName, mode);
    const request = action(transaction.objectStore(storeName));
    request.addEventListener("success", () => {
      resolve(request.result);
    });
    request.addEventListener("error", () => {
      reject(request.error ?? new Error("indexeddb request failed"));
    });
    transaction.addEventListener("complete", () => {
      database.close();
    });
  });
};

export const indexedDbStorage = (): Storage => ({
  load: async () => {
    const raw: unknown = await transact("readonly", (store) => store.get(key));
    return raw === undefined ? undefined : persistedOf(raw);
  },
  save: async (state: Persisted) => {
    await transact("readwrite", (store) => store.put(state, key));
  },
  clear: async () => {
    await transact("readwrite", (store) => store.delete(key));
  },
});

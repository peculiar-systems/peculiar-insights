import type { Code } from "@connectrpc/connect";

export type DropCause =
  | "no-user"
  | "empty-name"
  | "no-device"
  | "not-device"
  | "queue-full"
  | "storage";

export type Diagnostic =
  | {
      readonly kind: "rejected";
      readonly id: string;
      readonly outcome: "invalid" | "not-consented";
      readonly reason: string;
    }
  | {
      readonly kind: "transport-failed";
      readonly code: Code;
      readonly message: string;
      readonly willRetry: boolean;
    }
  | { readonly kind: "dropped"; readonly cause: DropCause; readonly detail: string };

export type Listener = (diagnostic: Diagnostic) => void;

export type Diagnostics = (listener: Listener) => () => void;

export const diagnosticsHub = (): {
  readonly subscribe: Diagnostics;
  readonly emit: (diagnostic: Diagnostic) => void;
} => {
  const listeners = new Set<Listener>();
  return {
    subscribe: (listener) => {
      listeners.add(listener);
      return () => {
        listeners.delete(listener);
      };
    },
    emit: (diagnostic) => {
      for (const listener of listeners) {
        listener(diagnostic);
      }
    },
  };
};

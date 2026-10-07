export type Session = {
  readonly id: string;
  readonly lastActivity: number;
};

export type SessionStore = {
  readonly load: () => Session | undefined;
  readonly save: (session: Session) => void;
};

export const sessionTimeoutMs = 30 * 60 * 1000;

export const advanced = (
  session: Session | undefined,
  now: number,
  fresh: () => string,
  timeoutMs: number = sessionTimeoutMs,
): Session =>
  session !== undefined && now - session.lastActivity <= timeoutMs && now >= session.lastActivity
    ? { id: session.id, lastActivity: now }
    : { id: fresh(), lastActivity: now };

export const memorySessionStore = (): SessionStore => {
  const cell: { current: Session | undefined } = { current: undefined };
  return {
    load: () => cell.current,
    save: (session) => {
      cell.current = session;
    },
  };
};

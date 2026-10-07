type Request = {
  readonly device: string;
  readonly session: string;
  readonly user?: string;
  readonly consentVersion?: string;
};
export declare const onOrderPlaced: (request: Request, total: number) => Promise<void>;
export declare const runJob: (name: string, job: () => Promise<void>) => Promise<void>;
export {};

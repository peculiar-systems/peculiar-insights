export declare const acceptAll: () => Promise<void>;
export declare const acceptCrashesOnly: () => Promise<void>;
export declare const onLogin: (id: string, plan: string) => Promise<void>;
export declare const onCheckoutOpened: (total: number, items: number) => Promise<void>;
export declare const pay: (charge: () => Promise<void>) => Promise<void>;
export declare const onLogout: () => Promise<void>;
export declare const forgetMe: () => Promise<void>;

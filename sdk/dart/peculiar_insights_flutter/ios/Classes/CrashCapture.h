#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

void PeculiarCrashInstall(void);

void PeculiarCrashConfigure(NSString *directory, NSString *appVersion, NSString *appBuild,
                            BOOL capture);

NS_ASSUME_NONNULL_END

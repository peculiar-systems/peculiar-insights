#import "CrashCapture.h"

#include "../../src/crash_report.h"

enum { exception_frame_limit = 128 };

static NSUncaughtExceptionHandler *previous_exception_handler;

static void capture_exception(NSException *exception) {
  NSArray<NSNumber *> *stack = exception.callStackReturnAddresses;
  uintptr_t addresses[exception_frame_limit];
  NSUInteger count = MIN(stack.count, (NSUInteger)exception_frame_limit);
  for (NSUInteger index = 0; index < count; index++) {
    addresses[index] = (uintptr_t)stack[index].unsignedLongLongValue;
  }
  peculiar_crash_report_exception(exception.name.UTF8String ?: "NSException",
                                  exception.reason.UTF8String ?: "", addresses, count);
  if (previous_exception_handler != NULL) {
    previous_exception_handler(exception);
  }
}

void PeculiarCrashInstall(void) {
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    previous_exception_handler = NSGetUncaughtExceptionHandler();
    NSSetUncaughtExceptionHandler(&capture_exception);
    peculiar_crash_install_signal_handlers();
  });
}

void PeculiarCrashConfigure(NSString *directory, NSString *appVersion, NSString *appBuild,
                            BOOL capture) {
  peculiar_crash_configure(directory.fileSystemRepresentation, appVersion.UTF8String,
                           appBuild.UTF8String, NSBundle.mainBundle.bundlePath.fileSystemRepresentation,
                           capture);
}

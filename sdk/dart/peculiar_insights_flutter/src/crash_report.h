#ifndef PECULIAR_CRASH_REPORT_H
#define PECULIAR_CRASH_REPORT_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

void peculiar_crash_configure(const char *directory, const char *app_version,
                              const char *app_build, const char *in_app_prefix,
                              bool capture);

void peculiar_crash_install_signal_handlers(void);

void peculiar_crash_report_exception(const char *exception_type,
                                     const char *message,
                                     const uintptr_t *addresses, size_t count);

#endif

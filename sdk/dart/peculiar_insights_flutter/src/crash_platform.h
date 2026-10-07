#ifndef PECULIAR_CRASH_PLATFORM_H
#define PECULIAR_CRASH_PLATFORM_H

#include <stddef.h>
#include <stdint.h>

size_t peculiar_platform_unwind(uintptr_t *frames, size_t limit);

uintptr_t peculiar_platform_context_pc(const void *context);

void peculiar_platform_thread_name(char *name, size_t size);

void peculiar_platform_image_identifier(const void *base, char *identifier,
                                        size_t size);

#endif

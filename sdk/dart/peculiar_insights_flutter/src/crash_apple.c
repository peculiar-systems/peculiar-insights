#include <execinfo.h>
#include <mach-o/loader.h>
#include <pthread.h>
#include <string.h>
#include <sys/ucontext.h>

#include "crash_platform.h"

enum { unwind_limit = 128 };

size_t peculiar_platform_unwind(uintptr_t *frames, size_t limit) {
  void *raw[unwind_limit];
  int count = backtrace(raw, (int)(limit < unwind_limit ? limit : unwind_limit));
  for (int index = 0; index < count; index++) {
    frames[index] = (uintptr_t)raw[index];
  }
  return count < 0 ? 0 : (size_t)count;
}

uintptr_t peculiar_platform_context_pc(const void *context) {
  const ucontext_t *machine = context;
#if defined(__arm64__)
  return (uintptr_t)__darwin_arm_thread_state64_get_pc(machine->uc_mcontext->__ss);
#elif defined(__x86_64__)
  return (uintptr_t)machine->uc_mcontext->__ss.__rip;
#else
  (void)machine;
  return 0;
#endif
}

void peculiar_platform_thread_name(char *name, size_t size) {
  name[0] = '\0';
  if (pthread_main_np() != 0) {
    strlcpy(name, "main", size);
    return;
  }
  pthread_getname_np(pthread_self(), name, size);
}

void peculiar_platform_image_identifier(const void *base, char *identifier, size_t size) {
  const struct mach_header_64 *header = base;
  identifier[0] = '\0';
  if (header->magic != MH_MAGIC_64) {
    return;
  }
  const unsigned char *command = (const unsigned char *)(header + 1);
  for (uint32_t index = 0; index < header->ncmds; index++) {
    const struct load_command *load = (const struct load_command *)command;
    if (load->cmd == LC_UUID) {
      const struct uuid_command *uuid = (const struct uuid_command *)command;
      size_t position = 0;
      for (size_t byte = 0; byte < sizeof uuid->uuid && position + 3 < size; byte++) {
        if (byte == 4 || byte == 6 || byte == 8 || byte == 10) {
          identifier[position++] = '-';
        }
        identifier[position++] = "0123456789ABCDEF"[uuid->uuid[byte] >> 4];
        identifier[position++] = "0123456789ABCDEF"[uuid->uuid[byte] & 0xf];
      }
      identifier[position] = '\0';
      return;
    }
    command += load->cmdsize;
  }
}

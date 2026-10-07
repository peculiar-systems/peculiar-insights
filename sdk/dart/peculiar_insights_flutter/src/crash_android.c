#define _GNU_SOURCE

#include <elf.h>
#include <link.h>
#include <string.h>
#include <sys/prctl.h>
#include <ucontext.h>
#include <unwind.h>

#include "crash_platform.h"

typedef struct {
  uintptr_t *frames;
  size_t limit;
  size_t count;
} unwind_state;

static _Unwind_Reason_Code collect_frame(struct _Unwind_Context *context, void *argument) {
  unwind_state *state = argument;
  uintptr_t pc = _Unwind_GetIP(context);
  if (pc == 0) {
    return _URC_NO_REASON;
  }
  if (state->count == state->limit) {
    return _URC_END_OF_STACK;
  }
  state->frames[state->count++] = pc;
  return _URC_NO_REASON;
}

size_t peculiar_platform_unwind(uintptr_t *frames, size_t limit) {
  unwind_state state = {frames, limit, 0};
  _Unwind_Backtrace(collect_frame, &state);
  return state.count;
}

uintptr_t peculiar_platform_context_pc(const void *context) {
  const ucontext_t *machine = context;
#if defined(__aarch64__)
  return (uintptr_t)machine->uc_mcontext.pc;
#elif defined(__arm__)
  return (uintptr_t)machine->uc_mcontext.arm_pc;
#elif defined(__x86_64__)
  return (uintptr_t)machine->uc_mcontext.gregs[REG_RIP];
#elif defined(__i386__)
  return (uintptr_t)machine->uc_mcontext.gregs[REG_EIP];
#else
  (void)machine;
  return 0;
#endif
}

void peculiar_platform_thread_name(char *name, size_t size) {
  char current[17];
  memset(current, 0, sizeof current);
  prctl(PR_GET_NAME, current);
  size_t length = strnlen(current, size - 1);
  memcpy(name, current, length);
  name[length] = '\0';
}

static void hex_into(const unsigned char *bytes, size_t count, char *identifier, size_t size) {
  size_t position = 0;
  for (size_t index = 0; index < count && position + 2 < size; index++) {
    identifier[position++] = "0123456789abcdef"[bytes[index] >> 4];
    identifier[position++] = "0123456789abcdef"[bytes[index] & 0xf];
  }
  identifier[position] = '\0';
}

static size_t align4(size_t value) { return (value + 3) & ~(size_t)3; }

static int build_id_in(const unsigned char *notes, size_t length, char *identifier, size_t size) {
  size_t offset = 0;
  while (offset + sizeof(ElfW(Nhdr)) <= length) {
    const ElfW(Nhdr) *note = (const ElfW(Nhdr) *)(notes + offset);
    size_t name_offset = offset + sizeof(ElfW(Nhdr));
    size_t description_offset = name_offset + align4(note->n_namesz);
    size_t next = description_offset + align4(note->n_descsz);
    if (next > length) {
      return 0;
    }
    if (note->n_type == NT_GNU_BUILD_ID && note->n_namesz == 4 &&
        memcmp(notes + name_offset, "GNU", 4) == 0) {
      hex_into(notes + description_offset, note->n_descsz, identifier, size);
      return 1;
    }
    offset = next;
  }
  return 0;
}

void peculiar_platform_image_identifier(const void *base, char *identifier, size_t size) {
  const ElfW(Ehdr) *header = base;
  identifier[0] = '\0';
  if (memcmp(header->e_ident, ELFMAG, SELFMAG) != 0) {
    return;
  }
  const ElfW(Phdr) *segments = (const ElfW(Phdr) *)((const char *)base + header->e_phoff);
  uintptr_t bias = (uintptr_t)base;
  for (size_t index = 0; index < header->e_phnum; index++) {
    if (segments[index].p_type == PT_LOAD && segments[index].p_offset == 0) {
      bias = (uintptr_t)base - segments[index].p_vaddr;
      break;
    }
  }
  for (size_t index = 0; index < header->e_phnum; index++) {
    if (segments[index].p_type == PT_NOTE &&
        build_id_in((const unsigned char *)(bias + segments[index].p_vaddr),
                    segments[index].p_memsz, identifier, size)) {
      return;
    }
  }
}

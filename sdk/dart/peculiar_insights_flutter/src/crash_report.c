#define _GNU_SOURCE

#include "crash_report.h"

#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdatomic.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include "crash_platform.h"

enum {
  path_size = 1024,
  text_size = 256,
  frame_limit = 128,
  buffer_size = 4096,
  number_size = 24,
  alternate_stack_size = 65536,
};

typedef struct {
  char *data;
  size_t size;
  size_t used;
} text;

typedef struct {
  int fd;
  size_t used;
  char data[buffer_size];
} writer;

typedef struct {
  int number;
  const char *name;
} signal_name;

static const signal_name fatal_signals[] = {
    {SIGSEGV, "SIGSEGV"}, {SIGBUS, "SIGBUS"},   {SIGILL, "SIGILL"},
    {SIGFPE, "SIGFPE"},   {SIGABRT, "SIGABRT"}, {SIGTRAP, "SIGTRAP"},
};

enum { fatal_signal_count = sizeof fatal_signals / sizeof fatal_signals[0] };

static char crash_directory[path_size];
static char app_version[text_size];
static char app_build[text_size];
static char in_app_prefix[path_size];
static atomic_bool capturing;
static atomic_flag reported = ATOMIC_FLAG_INIT;
static atomic_flag installed = ATOMIC_FLAG_INIT;
static struct sigaction previous_actions[fatal_signal_count];
static char alternate_stack[alternate_stack_size];
static writer report_writer;

static void copy_text(char *target, size_t size, const char *source) {
  size_t length = source == NULL ? 0 : strnlen(source, size - 1);
  if (length > 0) {
    memcpy(target, source, length);
  }
  target[length] = '\0';
}

static const char *format_unsigned(uint64_t value, unsigned base,
                                   char digits[number_size]) {
  size_t position = number_size - 1;
  digits[position] = '\0';
  do {
    digits[--position] = "0123456789abcdef"[value % base];
    value /= base;
  } while (value != 0 && position > 0);
  return digits + position;
}

static void text_append(text *target, const char *source) {
  for (; *source != '\0' && target->used + 1 < target->size; source++) {
    target->data[target->used++] = *source;
  }
  target->data[target->used] = '\0';
}

static void text_append_number(text *target, uint64_t value, unsigned base) {
  char digits[number_size];
  text_append(target, format_unsigned(value, base, digits));
}

static void flush_writer(writer *output) {
  size_t done = 0;
  while (done < output->used) {
    ssize_t written = write(output->fd, output->data + done, output->used - done);
    if (written < 0 && errno == EINTR) {
      continue;
    }
    if (written <= 0) {
      break;
    }
    done += (size_t)written;
  }
  output->used = 0;
}

static void put_char(writer *output, char character) {
  if (output->used == buffer_size) {
    flush_writer(output);
  }
  output->data[output->used++] = character;
}

static void put_raw(writer *output, const char *source) {
  for (; *source != '\0'; source++) {
    put_char(output, *source);
  }
}

static void put_string(writer *output, const char *source) {
  put_char(output, '"');
  for (const unsigned char *at = (const unsigned char *)source;
       source != NULL && *at != '\0'; at++) {
    if (*at == '"' || *at == '\\') {
      put_char(output, '\\');
      put_char(output, (char)*at);
    } else if (*at < 0x20) {
      put_raw(output, "\\u00");
      put_char(output, "0123456789abcdef"[*at >> 4]);
      put_char(output, "0123456789abcdef"[*at & 0xf]);
    } else {
      put_char(output, (char)*at);
    }
  }
  put_char(output, '"');
}

static void put_key(writer *output, const char *key) {
  put_string(output, key);
  put_char(output, ':');
}

static void put_field(writer *output, const char *key, const char *value) {
  put_key(output, key);
  put_string(output, value);
  put_char(output, ',');
}

static void put_number(writer *output, uint64_t value, unsigned base) {
  char digits[number_size];
  put_raw(output, format_unsigned(value, base, digits));
}

static void put_hex_field(writer *output, const char *key, uintptr_t value) {
  char digits[number_size];
  put_key(output, key);
  put_string(output, format_unsigned(value, 16, digits));
}

static const char *file_name_of(const char *path) {
  const char *slash = strrchr(path, '/');
  return slash == NULL ? path : slash + 1;
}

static void put_frame(writer *output, uintptr_t address) {
  Dl_info info;
  memset(&info, 0, sizeof info);
  int found = dladdr((const void *)address, &info) != 0 && info.dli_fbase != NULL;
  const char *path = found && info.dli_fname != NULL ? info.dli_fname : "";
  const char *image = file_name_of(path);
  char function[text_size];
  text function_text = {function, sizeof function, 0};
  function[0] = '\0';
  if (found && info.dli_sname != NULL) {
    text_append(&function_text, info.dli_sname);
  } else if (found) {
    text_append(&function_text, "0x");
    text_append_number(&function_text, address - (uintptr_t)info.dli_fbase, 16);
  }
  put_char(output, '{');
  put_field(output, "module", image);
  put_field(output, "function", function);
  put_field(output, "file", "");
  put_raw(output, "\"line\":0,\"inApp\":");
  size_t prefix_length = strlen(in_app_prefix);
  put_raw(output, prefix_length > 0 && strncmp(path, in_app_prefix, prefix_length) == 0
                      ? "true,"
                      : "false,");
  put_hex_field(output, "address", address);
  if (found) {
    char identifier[text_size];
    identifier[0] = '\0';
    peculiar_platform_image_identifier(info.dli_fbase, identifier, sizeof identifier);
    put_raw(output, ",\"image\":{");
    put_field(output, "name", image);
    put_field(output, "identifier", identifier);
    put_hex_field(output, "loadAddress", (uintptr_t)info.dli_fbase);
    put_char(output, '}');
  }
  put_char(output, '}');
}

static void mint_uuid(char uuid[37]) {
  unsigned char bytes[16];
  memset(bytes, 0, sizeof bytes);
  int random = open("/dev/urandom", O_RDONLY | O_CLOEXEC);
  if (random >= 0) {
    ssize_t ignored = read(random, bytes, sizeof bytes);
    (void)ignored;
    close(random);
  }
  struct timespec now;
  clock_gettime(CLOCK_REALTIME, &now);
  for (size_t index = 0; index < sizeof(now.tv_nsec); index++) {
    bytes[index] ^= (unsigned char)((uint64_t)now.tv_nsec >> (index * 8));
  }
  bytes[6] = (unsigned char)((bytes[6] & 0x0f) | 0x40);
  bytes[8] = (unsigned char)((bytes[8] & 0x3f) | 0x80);
  size_t position = 0;
  for (size_t index = 0; index < sizeof bytes; index++) {
    if (index == 4 || index == 6 || index == 8 || index == 10) {
      uuid[position++] = '-';
    }
    uuid[position++] = "0123456789abcdef"[bytes[index] >> 4];
    uuid[position++] = "0123456789abcdef"[bytes[index] & 0xf];
  }
  uuid[position] = '\0';
}

static uint64_t now_millis(void) {
  struct timespec now;
  clock_gettime(CLOCK_REALTIME, &now);
  return (uint64_t)now.tv_sec * 1000u + (uint64_t)now.tv_nsec / 1000000u;
}

static void report_path(char *path, size_t size, const char *uuid, const char *suffix) {
  text target = {path, size, 0};
  path[0] = '\0';
  text_append(&target, crash_directory);
  text_append(&target, "/");
  text_append(&target, uuid);
  text_append(&target, suffix);
}

static void write_report(const char *exception_type, const char *message,
                         const uintptr_t *addresses, size_t count) {
  char uuid[37];
  char thread[text_size];
  char temporary[path_size + 64];
  char complete[path_size + 64];
  mint_uuid(uuid);
  thread[0] = '\0';
  peculiar_platform_thread_name(thread, sizeof thread);
  report_path(temporary, sizeof temporary, uuid, ".json.tmp");
  report_path(complete, sizeof complete, uuid, ".json");
  int fd = open(temporary, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC, 0600);
  if (fd < 0) {
    return;
  }
  writer *output = &report_writer;
  output->fd = fd;
  output->used = 0;
  put_char(output, '{');
  put_field(output, "id", uuid);
  put_key(output, "timeMillis");
  put_number(output, now_millis(), 10);
  put_char(output, ',');
  put_field(output, "exceptionType", exception_type);
  put_field(output, "message", message);
  put_field(output, "thread", thread);
  put_field(output, "appVersion", app_version);
  put_field(output, "appBuild", app_build);
  put_raw(output, "\"frames\":[");
  for (size_t index = 0; index < count; index++) {
    if (index > 0) {
      put_char(output, ',');
    }
    put_frame(output, addresses[index]);
  }
  put_raw(output, "]}");
  flush_writer(output);
  close(fd);
  rename(temporary, complete);
}

static size_t signal_frames(const void *context, uintptr_t *frames, size_t limit) {
  uintptr_t unwound[frame_limit];
  size_t count = peculiar_platform_unwind(unwound, frame_limit);
  uintptr_t pc = context == NULL ? 0 : peculiar_platform_context_pc(context);
  size_t start = 0;
  while (start < count && unwound[start] != pc) {
    start++;
  }
  size_t written = 0;
  if (start == count) {
    start = 0;
    if (pc != 0 && limit > 0) {
      frames[written++] = pc;
    }
  }
  for (size_t index = start; index < count && written < limit; index++) {
    frames[written++] = unwound[index];
  }
  return written;
}

static int signal_index(int number) {
  for (int index = 0; index < fatal_signal_count; index++) {
    if (fatal_signals[index].number == number) {
      return index;
    }
  }
  return -1;
}

static void describe_signal(int number, const siginfo_t *info, char *message, size_t size) {
  text target = {message, size, 0};
  message[0] = '\0';
  text_append(&target, "code ");
  if (info->si_code < 0) {
    text_append(&target, "-");
  }
  text_append_number(&target, (uint64_t)(info->si_code < 0 ? -(int64_t)info->si_code : info->si_code), 10);
  if (number == SIGSEGV || number == SIGBUS || number == SIGILL || number == SIGFPE) {
    text_append(&target, ", fault address 0x");
    text_append_number(&target, (uintptr_t)info->si_addr, 16);
  }
}

static int sent_by_process(int number, const siginfo_t *info) {
  if (number == SIGABRT || info->si_code == SI_USER || info->si_code == SI_QUEUE) {
    return 1;
  }
#ifdef SI_TKILL
  return info->si_code == SI_TKILL;
#else
  return 0;
#endif
}

static void chain(int number, siginfo_t *info, void *context) {
  int index = signal_index(number);
  if (index < 0) {
    return;
  }
  const struct sigaction *previous = &previous_actions[index];
  if ((previous->sa_flags & SA_SIGINFO) != 0 && previous->sa_sigaction != NULL) {
    previous->sa_sigaction(number, info, context);
    return;
  }
  if ((previous->sa_flags & SA_SIGINFO) == 0 && previous->sa_handler != SIG_DFL &&
      previous->sa_handler != SIG_IGN) {
    previous->sa_handler(number);
    return;
  }
  struct sigaction fallback;
  memset(&fallback, 0, sizeof fallback);
  fallback.sa_handler = SIG_DFL;
  sigemptyset(&fallback.sa_mask);
  sigaction(number, &fallback, NULL);
  if (sent_by_process(number, info)) {
    raise(number);
  }
}

static void handle_signal(int number, siginfo_t *info, void *context) {
  int index = signal_index(number);
  if (index >= 0 && atomic_load(&capturing) && !atomic_flag_test_and_set(&reported)) {
    uintptr_t frames[frame_limit];
    size_t count = signal_frames(context, frames, frame_limit);
    char message[text_size];
    describe_signal(number, info, message, sizeof message);
    write_report(fatal_signals[index].name, message, frames, count);
  }
  chain(number, info, context);
}

static void install_alternate_stack(void) {
  stack_t current;
  if (sigaltstack(NULL, &current) == 0 && (current.ss_flags & SS_DISABLE) == 0) {
    return;
  }
  stack_t stack;
  memset(&stack, 0, sizeof stack);
  stack.ss_sp = alternate_stack;
  stack.ss_size = sizeof alternate_stack;
  sigaltstack(&stack, NULL);
}

void peculiar_crash_configure(const char *directory, const char *version,
                              const char *build, const char *prefix, bool capture) {
  atomic_store(&capturing, false);
  copy_text(crash_directory, sizeof crash_directory, directory);
  copy_text(app_version, sizeof app_version, version);
  copy_text(app_build, sizeof app_build, build);
  copy_text(in_app_prefix, sizeof in_app_prefix, prefix);
  atomic_store(&capturing, capture && crash_directory[0] != '\0');
}

void peculiar_crash_install_signal_handlers(void) {
  if (atomic_flag_test_and_set(&installed)) {
    return;
  }
  install_alternate_stack();
  for (int index = 0; index < fatal_signal_count; index++) {
    struct sigaction action;
    memset(&action, 0, sizeof action);
    sigemptyset(&action.sa_mask);
    action.sa_sigaction = handle_signal;
    action.sa_flags = SA_SIGINFO | SA_ONSTACK;
    sigaction(fatal_signals[index].number, &action, &previous_actions[index]);
  }
}

void peculiar_crash_report_exception(const char *exception_type, const char *message,
                                     const uintptr_t *addresses, size_t count) {
  if (atomic_load(&capturing) && !atomic_flag_test_and_set(&reported)) {
    write_report(exception_type, message, addresses, count);
  }
}

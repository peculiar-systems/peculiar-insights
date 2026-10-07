#include <jni.h>

#include "crash_report.h"

typedef struct {
  JNIEnv *env;
  jstring value;
  const char *chars;
} borrowed_string;

static borrowed_string borrow(JNIEnv *env, jstring value) {
  borrowed_string borrowed = {env, value, NULL};
  if (value != NULL) {
    borrowed.chars = (*env)->GetStringUTFChars(env, value, NULL);
  }
  return borrowed;
}

static void give_back(borrowed_string borrowed) {
  if (borrowed.chars != NULL) {
    (*borrowed.env)->ReleaseStringUTFChars(borrowed.env, borrowed.value, borrowed.chars);
  }
}

JNIEXPORT void JNICALL Java_systems_peculiar_insights_flutter_NativeSignals_configure(
    JNIEnv *env, jclass type, jstring directory, jstring version, jstring build,
    jstring prefix, jboolean capture) {
  (void)type;
  borrowed_string directory_chars = borrow(env, directory);
  borrowed_string version_chars = borrow(env, version);
  borrowed_string build_chars = borrow(env, build);
  borrowed_string prefix_chars = borrow(env, prefix);
  peculiar_crash_configure(directory_chars.chars, version_chars.chars, build_chars.chars,
                           prefix_chars.chars, capture == JNI_TRUE);
  give_back(prefix_chars);
  give_back(build_chars);
  give_back(version_chars);
  give_back(directory_chars);
}

JNIEXPORT void JNICALL Java_systems_peculiar_insights_flutter_NativeSignals_install(
    JNIEnv *env, jclass type) {
  (void)env;
  (void)type;
  peculiar_crash_install_signal_handlers();
}

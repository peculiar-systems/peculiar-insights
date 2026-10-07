cmake_minimum_required(VERSION 3.10)

project(peculiar_insights_crash VERSION 0.1.0 LANGUAGES C)

add_library(peculiar_insights_crash SHARED
  "crash_report.c"
  "crash_android.c"
  "../android/src/main/cpp/jni_bridge.c"
)

target_include_directories(peculiar_insights_crash PRIVATE ".")

set_target_properties(peculiar_insights_crash PROPERTIES
  C_STANDARD 11
  OUTPUT_NAME "peculiar_insights_crash"
)

target_link_libraries(peculiar_insights_crash PRIVATE dl)

target_link_options(peculiar_insights_crash PRIVATE "-Wl,-z,max-page-size=16384")

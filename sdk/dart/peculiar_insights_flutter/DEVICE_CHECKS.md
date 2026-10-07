# Device checks for native crash capture

The native crash handlers run inside a real app process on Android and iOS.
Neither can run on the Linux host that runs `nix flake check`: there is no
Android device or emulator, no Xcode, and the plugin's Kotlin, Objective-C
and Swift are not compiled there. What the host does check is the Dart side,
in `test/native_crashes_test.dart`: a report in the format below is sent at
start and its file removed, nothing is sent without diagnostics consent, and
withdrawing diagnostics or erasing removes waiting reports.

Run these by hand on a device or emulator before releasing a change to the
handlers.

## Setup

1. Build an app that starts `FlutterInsights` against a development server,
   with a consent screen, as in `example/main.dart`.
2. Grant diagnostics in the app.
3. Add one of the triggers below, run the app in release mode
   (`flutter run --release`), and let it crash.
4. Launch the app again and open the crashes dashboard in Grafana.

Every check expects, on the second launch:

- one new fatal crash report, under the diagnostics purpose;
- the exception type named in the check;
- the thread the crash happened on;
- the app version and build of the run that crashed, not the one that sent it;
- native frames carrying an instruction address and an image with name,
  identifier (the ELF build id on Android, the Mach-O UUID on iOS) and load
  address, readable from `reporting.crash`; JVM frames carrying class,
  method, file and line;
- no file left in the app support directory under `peculiar_insights_crashes`.

The system still sees the crash too, because the handlers chain to the ones
they replaced: Android's logcat shows `FATAL EXCEPTION` or `Fatal signal`
with a tombstone, and iOS keeps its own crash log.

## Android: JVM crash

Trigger, in the app's `MainActivity.onCreate`:

```kotlin
android.os.Handler(android.os.Looper.getMainLooper()).postDelayed(
    { throw IllegalStateException("device check") },
    5000,
)
```

Expect exception type `java.lang.IllegalStateException`, message
`device check`, thread `main`, frames from `MainActivity` marked in-app.

## Android: NDK SIGSEGV

Trigger, from Dart, a fault inside native code of the NDK's libc:

```dart
import "dart:ffi";

void crashInNativeCode() => DynamicLibrary.process()
    .lookupFunction<
      Pointer<Void> Function(Pointer<Void>, Int32, IntPtr),
      Pointer<Void> Function(Pointer<Void>, int, int)
    >("memset")(nullptr, 0, 16);
```

Expect exception type `SIGSEGV`, a message naming fault address `0x0`, a top
frame in `libc.so` with its build id, followed by frames in `libapp.so`.

## iOS: Objective-C exception

Trigger, in the app's `AppDelegate`, after launch:

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
  NSException(name: .internalInconsistencyException, reason: "device check", userInfo: nil).raise()
}
```

Expect exception type `NSInternalInconsistencyException`, message
`device check`, thread `main`, frames from the exception's call stack with
images such as `CoreFoundation` and `Runner` and their UUIDs. Exactly one
report: the `SIGABRT` that follows the uncaught exception adds none.

## iOS: Swift trap

Trigger, in the app's `AppDelegate`, after launch:

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
  let values: [Int] = []
  _ = values[1]
}
```

Expect exception type `SIGTRAP`, thread `main`, a top frame in `Runner`
with its UUID.

## Without consent

Repeat any trigger with diagnostics not granted, or withdrawn before the
crash. Expect no report on the next launch and no file under
`peculiar_insights_crashes`.

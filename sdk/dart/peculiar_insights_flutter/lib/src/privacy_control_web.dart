import "dart:js_interop";
import "dart:js_interop_unsafe";

import "package:web/web.dart" as web;

bool globalPrivacyControl() {
  final navigator = web.window.navigator as JSObject;
  final signal = navigator.getProperty<JSBoolean?>("globalPrivacyControl".toJS);
  return signal?.toDart ?? false;
}

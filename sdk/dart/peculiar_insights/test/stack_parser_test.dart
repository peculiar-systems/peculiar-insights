import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:fixnum/fixnum.dart";
import "package:peculiar_insights/internal.dart";
import "package:peculiar_insights/peculiar_insights.dart";
import "package:test/test.dart";

const trace = """
#0      Cart.checkout (package:shop/cart/store/cart.dart:42:7)
#1      _Button.build (package:flutter/src/widgets/basic.dart:100:3)
#2      List.forEach (dart:core/list.dart:12:1)
#3      main (file:///build/app/main.dart:3:5)
""";

const aotTrace = """
*** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
pid: 7461, tid: 7493, name 1.ui
os: android arch: arm64 comp: yes sim: no
build_id: '6d4e2e6fc9dd23b6c8c19a4c7ae3c95f'
isolate_dso_base: 7b2a8c4000, vm_dso_base: 7b2a8c4000
isolate_instructions: 7b2a95c000, vm_instructions: 7b2a94d000
    #00 abs 0000007b2aa2b1a7 virt 00000000001671a7 _kDartIsolateSnapshotInstructions+0xcf1a7
    #01 abs 0000007b2a9512c3 _kDartVmSnapshotInstructions+0x42c3
<asynchronous suspension>
""";

const v8Trace = """
Error: boom
    at Object.checkout (https://shop.example/main.dart.js:1204:17)
    at https://shop.example:8080/main.dart.js:88:3
""";

const geckoTrace = """
checkout@https://shop.example/main.dart.js:1204:17
@https://shop.example/main.dart.js:88:3
""";

IList<Frame> parse(String text) =>
    parseStackTrace(text, inAppPackages: const IListConst(["shop"]));

void main() {
  test("dart stack frames are parsed with locations", () {
    final frames = parse(trace);
    expect(frames.length, 4);
    expect(frames[0].moduleName, "shop");
    expect(frames[0].function, "Cart.checkout");
    expect(frames[0].line, 42);
    expect(frames[0].column, 7);
    expect(frames[0].inApp, isTrue);
    expect(frames[1].inApp, isFalse);
    expect(frames[2].moduleName, "dart:core/list.dart");
    expect(frames[2].inApp, isFalse);
    expect(frames[3].inApp, isTrue);
    expect(frames[0].instructionAddress, isNull);
    expect(frames[0].image, isNull);
  });

  test("noise lines are skipped", () {
    expect(parse("not a frame"), isEmpty);
  });

  test("a non-symbolic AOT trace carries build id and addresses", () {
    final frames = parse(aotTrace);
    expect(frames.length, 2);
    expect(frames[0].instructionAddress, Int64.parseHex("1671a7"));
    expect(
      frames[0].image,
      BinaryImage(
        name: "_kDartIsolateSnapshotInstructions",
        identifier: "6d4e2e6fc9dd23b6c8c19a4c7ae3c95f",
        loadAddress: Int64.parseHex("7b2a95c000"),
      ),
    );
    expect(frames[0].function, "_kDartIsolateSnapshotInstructions+0xcf1a7");
    expect(frames[0].inApp, isTrue);
    expect(
      frames[1].instructionAddress,
      Int64.parseHex("7b2a9512c3") - Int64.parseHex("7b2a8c4000"),
    );
    expect(frames[1].image?.name, "_kDartVmSnapshotInstructions");
    expect(frames[1].image?.loadAddress, Int64.parseHex("7b2a94d000"));
    expect(frames[1].inApp, isFalse);
  });

  test("an AOT frame reaches the contract with its address and image", () {
    final proto = parse(aotTrace).first.toProto();
    expect(proto.hasInstructionAddress(), isTrue);
    expect(proto.instructionAddress, Int64.parseHex("1671a7"));
    expect(proto.image.identifier, "6d4e2e6fc9dd23b6c8c19a4c7ae3c95f");
    expect(proto.image.loadAddress, Int64.parseHex("7b2a95c000"));
  });

  test("V8 web frames keep script URL, line and column", () {
    final frames = parse(v8Trace);
    expect(frames.length, 2);
    expect(frames[0].function, "Object.checkout");
    expect(frames[0].file, "https://shop.example/main.dart.js");
    expect(frames[0].line, 1204);
    expect(frames[0].column, 17);
    expect(frames[1].function, "");
    expect(frames[1].file, "https://shop.example:8080/main.dart.js");
    expect(frames[1].line, 88);
    expect(frames[1].column, 3);
  });

  test("Firefox and Safari web frames keep script URL, line and column", () {
    final frames = parse(geckoTrace);
    expect(frames.length, 2);
    expect(frames[0].function, "checkout");
    expect(frames[0].file, "https://shop.example/main.dart.js");
    expect(frames[0].line, 1204);
    expect(frames[0].column, 17);
    expect(frames[1].function, "");
    expect(frames[1].line, 88);
  });
}

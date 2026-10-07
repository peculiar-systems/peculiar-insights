{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.fileset) toSource;

  sources = toSource {
    root = ../backend/server/test/symbols;
    fileset = ../backend/server/test/symbols;
  };

  llvm = pkgs.llvmPackages;

  symbol-fixtures =
    pkgs.runCommandCC "peculiar-insights-symbol-fixtures"
      {
        nativeBuildInputs = [
          pkgs.dart
          pkgs.nodejs
          pkgs.binutils
          llvm.clang-unwrapped
          llvm.lld
          llvm.llvm
        ];
      }
      ''
        export HOME="$TMPDIR"
        mkdir -p "$out"/{dart,web,ndk,ios,r8} work
        cp ${sources}/main.dart work/main.dart
        cp ${sources}/crash.c work/crash.c
        cp ${sources}/mapping.txt "$out/r8/mapping.txt"

        dart --disable-analytics compile exe -S "$out/dart/app.symbols" -o work/main.exe work/main.dart
        work/main.exe > "$out/dart/trace.txt"

        dart --disable-analytics compile js -O2 -o work/main.js work/main.dart
        cp work/main.js.map "$out/web/main.js.map"
        (cd work && node main.js > "$out/web/trace.txt")

        gcc -g -O0 -shared -fPIC -Wl,--build-id=sha1 -o "$out/ndk/libcrash.so" work/crash.c
        readelf -n "$out/ndk/libcrash.so" | sed -n 's/.*Build ID: \([0-9a-f]*\).*/\1/p' > "$out/ndk/build-id.txt"
        nm "$out/ndk/libcrash.so" | sed -n 's/^\([0-9a-f]*\) T \(fault_here\|entry\)$/\2 \1/p' > "$out/ndk/symbols.txt"

        clang -target arm64-apple-ios15.0 -g -O0 -c work/crash.c -o work/crash.o
        ld64.lld -arch arm64 -platform_version ios 15.0 15.0 -dylib -o work/libcrash.dylib work/crash.o
        dsymutil work/libcrash.dylib -o "$out/ios/libcrash.dylib.dSYM"
        llvm-dwarfdump --uuid "$out/ios/libcrash.dylib.dSYM" | sed -n 's/^UUID: \([0-9A-F-]*\) .*/\1/p' > "$out/ios/uuid.txt"
        llvm-nm work/libcrash.dylib | sed -n 's/^\([0-9a-f]*\) T _\(fault_here\|entry\)$/\2 \1/p' > "$out/ios/symbols.txt"

        for file in dart/trace.txt web/trace.txt ndk/build-id.txt ndk/symbols.txt ios/uuid.txt ios/symbols.txt; do
          test -s "$out/$file"
        done
      '';
in
{
  flake.packages = { inherit symbol-fixtures; };
}

---
title: Uploading symbols
section: SDKs
order: 4
---

# Uploading symbols

A release build of a Flutter app reports stack traces the server cannot read on its own: Dart frames as addresses when the build splits its debug info, minified script positions on the web, obfuscated class names from R8 on Android, and native addresses from NDK code and iOS. The server symbolicates them from the symbols the build produced, once the build uploads them.

## What a build uploads

A build's symbols come in five kinds, each from where the Flutter and platform toolchains leave it:

| Kind            | Flag                | What to pass                                                                                                                      |
| --------------- | ------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| Dart symbols    | `--dart-symbols`    | The directory given to `flutter build --split-debug-info`, or one of its `.symbols` files. Covers every Flutter target built AOT. |
| Web source maps | `--web-source-maps` | A `.map` file, or the build's web output directory; its `.map` files are taken. Built with `flutter build web --source-maps`.     |
| R8 mapping      | `--r8-mapping`      | The `mapping.txt` an Android release build writes when R8 shrinks it.                                                             |
| NDK symbols     | `--ndk-symbols`     | An unstripped `.so`, or a directory of them, such as the build's merged native libraries.                                         |
| dSYMs           | `--dsyms`           | A `.dSYM` bundle, or a directory holding them, such as an Xcode archive's `dSYMs`.                                                |

Every flag may be repeated, and a directory contributes only the files of its kind. Native files are matched to crashes by the identifier the binary carries, its ELF build id or Mach-O UUID, so libraries of every architecture can go in one upload.

## Running the upload

The uploader is an app of the same flake the host takes the NixOS module from:

```sh
nix run "$INSIGHTS_FLAKE#peculiar-insights-upload-symbols" -- \
  --server https://insights.example.org \
  --project shop \
  --build "$BUILD_NUMBER" \
  --key-file "$UPLOAD_KEY_FILE" \
  --dart-symbols build/symbols \
  --r8-mapping build/app/outputs/mapping/release/mapping.txt
```

`--build` is the build number the app reports, the one passed to `flutter build --build-number`, which the SDK sends with every crash. Symbols belong to a project, not an environment: the reports of every environment of the project with that build number use them.

The upload streams its files and ends with how many files of each kind the server kept. It fails, and stores nothing, when the key is unknown or belongs to another project, when a file is not of the kind it was given as, or when the files together pass the server's cap.

## The upload key

Each project has one upload key, apart from its ingest keys. The service generates it at `/var/lib/peculiar-insights/upload-keys/<slug>` unless `projects.<slug>.uploadKeyFile` names a file, and exports the path as `services.peculiar-insights.uploadKeyFiles."<slug>"`. A build on the same host loads it as a credential; a build elsewhere receives it through the secret channel the CI already uses. It is a secret everywhere: only builds hold it, never an app.

## Uploading again

Platforms often build in separate jobs, so a build can upload in several steps. Each upload adds the kinds it carries and replaces the kinds the build already had: an Android job uploading `--dart-symbols` and `--r8-mapping`, then an iOS job uploading `--dart-symbols` and `--dsyms`, leaves the iOS Dart symbols, the R8 mapping and the dSYMs. Upload every Dart symbols file of a build in one step when the platforms share a build number.

## Reports that arrive first

A crash that arrives before its build's symbols is stored as it came and grouped on its raw frames, and the new-issue alert fires for it then. When the symbols arrive, every stored report of that build is symbolicated and grouped again:

- a report whose symbolicated frames belong to an existing issue moves into it, and that issue keeps its state;
- an issue the regrouping creates takes the resolved or ignored state of the issues its reports left when they all share it, and starts open when they differ;
- an issue left with no reports is deleted;
- an issue the regrouping creates does not raise the new-issue alert, which already fired for its reports.

The raw frames stay beside the symbolicated ones, readable as `raw_frames` in `reporting.crash`; the issue detail dashboard shows the symbolicated frames.

## How long symbols are kept

A build's symbols are kept while any report of that build is retained, in any environment of the project. Once its last report is deleted by retention or erasure, they are deleted at the next hourly maintenance. Symbols of a build that never received a report are deleted once the longest retention among the project's environments has passed since their last upload; when any environment keeps everything, they are kept too.

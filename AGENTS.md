# AGENTS.md

> Guidance for AI agents (e.g. Copilot, Antigravity, Cursor, Claude) working in this repository.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Repository Layout](#2-repository-layout)
3. [Architecture](#3-architecture)
4. [Build System](#4-build-system)
5. [Coding Standards](#5-coding-standards)
6. [Common Tasks](#6-common-tasks)
7. [CI/CD Pipeline](#7-cicd-pipeline)
8. [Important Constraints](#8-important-constraints)

---

## 1. Project Overview

**HelloWorld** is a minimal Android application written entirely in **C** using the [raylib](https://github.com/raysan5/raylib) graphics library. It renders the text *"Hello, world!"* centered on a fullscreen window, with the font size calculated dynamically to fill 80 % of the available screen area.

This version uses a **CMake-only workflow** — there is no Gradle or AGP involved. All build steps (compiling native code, processing resources, packaging, signing, and installing) are driven directly by a root-level `CMakeLists.txt`.

| Property | Value |
|---|---|
| Language | C (standard: C23, extensions off) |
| Graphics library | raylib (git submodule, `master` branch) |
| Build system | CMake (root-level, no Gradle) |
| Android SDK | `compileSdk` 36, `minSdk` 21, `targetSdk` 36 |
| Android NDK | r28c or newer |
| Java toolchain | JDK 17 |
| Application ID | `com.oussamateyib.helloworld` |
| Default version | 1.0.0 / versionCode 1 |
| License | MIT |

---

## 2. Repository Layout

```
HelloWorld/
├── .github/
│   ├── ISSUE_TEMPLATE/           # Bug report & feature request templates
│   ├── workflows/
│   │   ├── build.yml             # CI: build, lint, and upload artifacts
│   │   └── release.yml           # CD: create GitHub releases (disabled on this version)
│   ├── CODEOWNERS
│   ├── CODE_OF_CONDUCT.md
│   ├── CONTRIBUTING.md
│   ├── pull_request_template.md
│   └── SECURITY.md
├── app/
│   └── src/
│       ├── debug/
│       │   └── AndroidManifest.xml   # Debug overlay manifest (adds debuggable flag)
│       └── main/
│           ├── AndroidManifest.xml   # Main application manifest (no version attrs — injected at build time)
│           ├── c/
│           │   ├── CMakeLists.txt    # Native library build definition
│           │   ├── main.c            # Application entry point (all logic lives here)
│           │   └── raylib/           # Git submodule — DO NOT edit
│           └── res/                  # Android resources (icons, strings, XML rules)
├── CMakeLists.txt                    # Root build orchestrator (646 lines) — the entire build pipeline
├── renovate.json                     # Dependency update automation
├── .gitmodules                       # Submodule declaration for raylib
├── .gitignore
├── .gitattributes
├── LICENSE
├── AGENTS.md
└── README.md
```

---

## 3. Architecture

The application is **fully native** — there is no Kotlin or Java runtime code (`android:hasCode="false"` in the manifest). Android's `NativeActivity` loads `libmain.so` directly.

```
Android NativeActivity
        │
        └── libmain.so   (compiled from app/src/main/c/)
                │
                ├── main.c          ← application logic
                └── libraylib.a     ← statically linked from the raylib submodule
```

The root `CMakeLists.txt` orchestrates the entire Android packaging pipeline as CMake custom targets. There are two parallel pipelines — **native libraries** and **resources** — that converge at APK and AAB creation.

> Targets marked **[ALL]** are built by the default `cmake --build` invocation. All others require an explicit `--target` flag.

#### Pipeline 1 — Native library (runs per ABI)

```
ExternalProject_Add [ALL]
    └── lib/<ABI>/libmain.unstripped.so
            ├── strip_debug_symbols_<ABI> [ALL]
            │       └── lib/<ABI>/libmain.so  ──────────────────────────────────► (converges at APK / AAB)
            │
            └── (release only) extract_debug_symbols_<ABI> [ALL]
                        │  FULL:         llvm-objcopy --only-keep-debug → libmain.so.dbg
                        │  SYMBOL_TABLE: llvm-objcopy --strip-debug     → libmain.so.sym
                        └── package_debug_symbols [ALL]
                                └── outputs/native-debug-symbols.zip
```

#### Pipeline 2 — Resources & manifest

```
AndroidManifest.xml (+ debug overlay in Debug builds)
    └── merge_manifest [ALL]
            └── intermediates/AndroidManifest.xml
                    └── link_res [ALL]  ← also consumes: res/, android.jar
                            └── *.binary-format.ap_
                                    └── optimize_res [ALL]
                                            └── *.binary-format.optimized.ap_  ──► (converges at APK / AAB)
```

#### Convergence — APK assembly (per ABI, default build)

```
libmain.so  ──────────────────────────────────────────┐
*.binary-format.optimized.ap_  ───────────────────────┤
                                                      ▼
                                            create_apk_<ABI> [ALL]
                                                └── *.unaligned.apk
                                                        └── align_apk_<ABI> [ALL]
                                                                └── *.aligned.apk
                                                                        └── sign_apk_<ABI> [ALL]
                                                                                └── outputs/*.apk ✓
```

#### Manual targets — AAB & APK sets

```
libmain.so (all ABIs)  ────────────────────────────────┐
*.binary-format.optimized.ap_  ────────────────────────┤
(release: also depends on package_debug_symbols)       ▼
                                                create_aab [manual]
                                                    └── outputs/*.aab
                                                            ├── create_apks_universal [manual]
                                                            │       └── outputs/*_universal.apks
                                                            │               └── install_apks_universal [manual]  ← needs export_spec
                                                            │
                                                            └── create_apks_connected_device [manual]
                                                                    └── intermediates/*_connected_device.apks
                                                                            └── install_apks_connected_device [manual]  ← needs export_spec

install_aab [manual]  ──delegates to──►  install_apks_connected_device
```

#### Utility targets (all manual)

| Target | What it does |
|---|---|
| `lint` | Lint the project for code quality issues |
| `export_spec` | Export the connected device specifications to a JSON file |
| `install_apk_<ABI>` | Install the connected device's APK set |
| `install_apk_universal` | Install the universal APK set on the connected device |
| `uninstall_app` | Uninstall the application from the connected device |
| `check_abis` | Display the ABIs supported by the connected device |

### Supported ABIs

Default: `armeabi-v7a`, `arm64-v8a`, `x86`, `x86_64`, `riscv64`

When more than one ABI is targeted, an additional **universal** APK is generated automatically from all shared libraries.

---

## 4. Build System

### Prerequisites

All tools must be available on the system `PATH`. For JAR-based tools (`manifest-merger`, `bundletool`), wrapper shell scripts must be configured.

| Tool | Version | Source / Notes |
|---|---|---|
| JDK | 17 | Provides `jarsigner` and `keytool` |
| CMake | ≥ 4.0.2 | |
| Android SDK | Platform 36, build-tools 36.0.0 | `ANDROID_HOME` must be set |
| Android NDK | r28c or newer | `ANDROID_NDK_HOME` must be set; NDK toolchain bin dir must be on `PATH` |
| Ninja | | Recommended generator for faster builds |
| manifest-merger | 31.9.0+ | [distriqt/android-manifest-merger](https://github.com/distriqt/android-manifest-merger/releases) |
| fd | | [sharkdp/fd](https://github.com/sharkdp/fd) |
| zip | ≥ 2.32 | |
| aapt2 | AAB-compatible | Downloaded separately from Maven (`com.android.tools.build:aapt2`); not the version bundled in SDK build-tools |
| unzip | ≥ 5.52 | Required for AAB / APK set targets only |
| bundletool | ≥ 1.18.1 | Required for AAB / APK set targets only |

### Required environment variables

| Variable | Description |
|---|---|
| `ANDROID_HOME` | Path to the Android SDK installation (CMake fails fatally if unset) |
| `ANDROID_NDK_HOME` | Path to the Android NDK installation (CMake fails fatally if unset) |

### Release signing environment variables

| Variable | Description |
|---|---|
| `STORE_FILE` | Absolute path to the `.jks` / `.p12` keystore |
| `STORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Key alias inside the keystore |
| `KEY_PASSWORD` | Key password (falls back to `STORE_PASSWORD` if unset) |

If none of these are set, the build falls back to the **debug keystore** (`~/.android/debug.keystore`), creating it automatically with `keytool` if it does not exist.

### Configuring the build

```bash
cmake -B <Build-Directory> \
      -G "Ninja" \
      [-DCMAKE_BUILD_TYPE=<Debug|Release|RelWithDebInfo|MinSizeRel>] \
      [-DABIS="<ABI;List>"] \
      [-DDEBUG_SYMBOLS_LEVEL=<FULL|SYMBOL_TABLE>] \
      [-DMIN_SDK=<int>] \
      [-DCOMPILE_SDK=<int>] \
      [-DTARGET_SDK=<int>] \
      [-DPACKAGE_NAME=<string>] \
      [-DVERSION_CODE=<int>] \
      [-DVERSION_NAME=<string>] \
      [-DOUTPUT_NAME=<string>] \
      [-DLIB_NAME=<string>] \
      [-DUSER=<current|all|uid>]
```

All `-D` options are optional; defaults are documented in `CMakeLists.txt`. `Build` is the recommended directory name. `Debug` is the default build type if `-DCMAKE_BUILD_TYPE` is omitted.

### Build type comparison

> The CI pipeline uses **`MinSizeRel`** for release builds (size-optimised flags), not plain `Release` (standard optimisation flags). Both behave identically for all custom targets below — the difference is only in the NDK toolchain compilation flags.

| Behaviour | Debug | Release | MinSizeRel | RelWithDebInfo |
|---|---|---|---|---|
| Debug symbols stripped | ❌ | ✅ | ✅ | ❌ |
| Debug symbols packaged | ❌ | ✅ | ✅ | ❌ |
| Debug manifest overlay | ✅ | ❌ | ❌ | ❌ |
| `HardcodedDebugMode` lint warning suppressed | ✅ |  ❌ | ❌ | ❌ |
| Resource optimisation | ❌ | ✅ | ✅ | ✅ |
| APK Zopfli recompression | ❌ | ✅ | ✅ | ✅ |
| Signing keystore | Debug | Production (or debug fallback) | Production (or debug fallback) | Production (or debug fallback) |

### CMake build targets

```bash
# Build all APKs (default target)
cmake --build <Build-Directory>

# Install an ABI-specific APK on the connected device
cmake --build <Build-Directory> --target install_apk_<ABI>

# Install the universal APK on the connected device
cmake --build <Build-Directory> --target install_apk_universal

# Generate an AAB
cmake --build <Build-Directory> --target create_aab

# Install the AAB on the connected device
cmake --build <Build-Directory> --target install_aab

# Generate a universal APK set
cmake --build <Build-Directory> --target create_apks_universal

# Install the universal APK set on the connected device
cmake --build <Build-Directory> --target export_spec
cmake --build <Build-Directory> --target install_apks_universal

# Generate an APK set specific to the connected device
cmake --build <Build-Directory> --target create_apks_connected_device

# Install the connected device's APK set
cmake --build <Build-Directory> --target export_spec
cmake --build <Build-Directory> --target install_apks_connected_device

# Uninstall the app from the connected device
cmake --build <Build-Directory> --target uninstall_app

# Run lint checks (reports → <Build-Directory>/reports/)
cmake --build <Build-Directory> --target lint

# Display the connected device's supported ABIs
cmake --build <Build-Directory> --target check_abis

# Export the connected device spec to a JSON file
cmake --build <Build-Directory> --target export_spec

# Clean build outputs
cmake --build <Build-Directory> --target clean
```

### Output locations

| Artifact | Path |
|---|---|
| APKs | `<Build-Directory>/outputs/*.apk` |
| AAB | `<Build-Directory>/outputs/*.aab` |
| APK sets | `<Build-Directory>/outputs/*.apks` |
| Native debug symbols | `<Build-Directory>/outputs/native-debug-symbols.zip` |
| Lint reports | `<Build-Directory>/reports/` |
| Intermediates | `<Build-Directory>/intermediates/` |

---

## 5. Coding Standards

### C code (`app/src/main/c/`)

- **Style**: Follow the existing style in `main.c`:
  - 4-space indentation (no tabs).
  - `const` whenever a variable is not reassigned.
  - Guard all public utility functions against invalid input (null pointers, non-positive dimensions, etc.).
  - Keep the render loop free of heap allocations.
- **Comments**: Use `//` line comments for inline explanations; keep them concise and accurate.

### CMake

#### `app/src/main/c/CMakeLists.txt` (native library)

- New C sources in `app/src/main/c/` are picked up automatically via `GLOB_RECURSE`.

#### `CMakeLists.txt` (root orchestrator)

- This file is the single source of truth for the entire build pipeline. Keep all packaging logic here.
- All configurable values (SDK versions, package name, version, ABIs, etc.) are exposed as CMake cache variables with sensible defaults — do not hardcode them.
- Follow the existing pattern when adding new custom targets: use `add_custom_command` + `add_custom_target`, declare proper `DEPENDS`, and add a descriptive `COMMENT`.

### XML / Resources

- All string resources belong in `app/src/main/res/values/strings.xml`.
- Follow Android resource naming conventions (`snake_case` for resource IDs).
- The main `AndroidManifest.xml` intentionally omits `package`, `versionCode`, and `versionName` — these are injected by `manifest-merger` at build time. Do not add them manually.

---

## 6. Common Tasks

### Adding a new C source file

1. Create `*.c` (and optionally `*.h`) files inside `app/src/main/c/`.
2. Add function declarations in a corresponding header if the symbol is used across files.

### Updating raylib

The `raylib` submodule tracks the `master` branch of <https://github.com/raysan5/raylib>.

```bash
git submodule update --remote app/src/main/c/raylib
```

Test the build immediately after updating, as raylib's master branch may contain breaking changes.

### Cloning the repository (including submodules)

```bash
git clone --recurse-submodules https://github.com/OussamaTeyib/HelloWorld.git
```

If already cloned without submodules:

```bash
git submodule update --init --recursive
```

---

## 7. CI/CD Pipeline

All workflows are defined in `.github/workflows/`.

### `build.yml` — triggered on

- Push of a `v*.*.*` tag
- Manual dispatch

**Steps summary:**
1. Check out code (with submodules)
2. Set up Java 17 (Temurin), Android SDK (Platform 36, build-tools 36.0.0), NDK r28c, CMake 4.0.2, `manifest-merger`, `fd`, `zip`/`unzip`, AAPT2, and `bundletool`
3. Configure and build both Debug and MinSizeRel (APKs, AABs, universal APK sets):
   ```
   cmake -B Build/Debug -G "Ninja"
   cmake -B Build/Release -G "Ninja" -DCMAKE_BUILD_TYPE=MinSizeRel
   cmake --build Build/{Debug,Release} [--target create_aab|create_apks_universal]
   ```
4. Run lint on both configurations
5. Upload artifacts: debug/release APKs, AABs, APK sets, native debug symbols, lint reports
6. Generate **build-provenance attestations** for all output artifacts

### `release.yml` — triggered on version tag push

> **Note:** The `release` job is disabled (`if: false`) on this version — releases are only created from the main branch. The workflow file exists for reference.

When enabled, it builds a signed `MinSizeRel` release, generates SHA256 checksums, signs them with GPG, and publishes a GitHub Release.

---

## 8. Important Constraints

| Rule | Reason |
|---|---|
| **Do not add Kotlin or Java source files.** | The app is fully native (`android:hasCode="false"`). |
| **Do not edit files under `app/src/main/c/raylib/`.** | This is a git submodule. Changes there will be lost on the next `submodule update` and are not tracked in this repo. |
| **Do not add `package`, `versionCode`, or `versionName` to `AndroidManifest.xml`.** | These are injected at build time by `manifest-merger`. Hardcoding them will cause a build conflict. |
| **Lint is treated as errors.** | `lint` is invoked with `-Wall -Werror --exitcode`. All warnings must be resolved before merging. |
| **All tools must be on `PATH` before running CMake.** | CMake resolves tool paths at configure time; missing tools cause silent or hard-to-diagnose failures at build time. |
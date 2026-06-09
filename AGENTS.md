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

**HelloWorld** is a minimal Android application written entirely in **C** using
the [raylib](https://github.com/raysan5/raylib) graphics library. It renders the text *"Hello,
world!"* centered on a fullscreen window, with the font size calculated dynamically to fill 80 % of
the available screen area.

| Property         | Value                                        |
|------------------|----------------------------------------------|
| Language         | C (standard: C23, extensions off)            |
| Graphics library | raylib (git submodule, `master` branch)      |
| Build system     | Gradle + CMake                               |
| Android SDK      | `compileSdk` 37, `minSdk` 21, `targetSdk` 37 |
| Application ID   | `com.oussamateyib.helloworld`                |
| Version          | 1.1.3 (versionCode 5)                        |
| License          | MIT                                          |

---

## 2. Repository Layout

```plaintext
HelloWorld/
├── .github/
│   ├── ISSUE_TEMPLATE/                   # Bug report & feature request templates
│   ├── workflows/
│   │   ├── build.yml                     # CI: build, lint, and upload artifacts
│   │   ├── release.yml                   # CD: create GitHub releases
|   |   ├── codeql.yml                    # CI: Run static analysis
│   │   └── dependency-submission.yml
│   ├── CODE_OF_CONDUCT.md
│   ├── CONTRIBUTING.md
│   ├── pull_request_template.md
│   └── SECURITY.md
├── app/
|   ├── build.gradle.kts                   # App-level Gradle build script
│   └── src/main/
│       ├── AndroidManifest.xml
│       ├── c/
│       │   ├── CMakeLists.txt             # Native build definition
│       │   ├── main.c                     # Application entry point (all logic lives here)
|       |   ├── libmain.map.txt            # Symbol map for the native library
│       │   └── raylib/                    # Git submodule — DO NOT edit
│       └── res/                           # Android resources (icons, strings, XML rules)
├── gradle/                                # Gradle wrapper and version catalog
├── build.gradle.kts                       # Root Gradle build script
├── settings.gradle.kts                    # Project name and module declarations
├── gradle.properties                      # JVM args, caching, and Android flags
├── renovate.json                          # Dependency update automation
├── .gitmodules                            # Submodule declaration for raylib
├── .gitignore
├── .gitattributes
├── gradlew / gradlew.bat                  # Gradle wrapper scripts
├── LICENSE
├── README.md
└── AGENTS.md
```

---

## 3. Architecture

The application is **fully native** — there is no Kotlin or Java runtime code (
`android:hasCode="false"` in the manifest). The Android framework loads the native shared library (
`libmain.so`) directly via `NativeActivity`.

```plaintext
Android NativeActivity
        │
        └── libmain.so   (compiled from app/src/main/c/)
                │
                ├── main.c          ← application logic
                └── libraylib.a     ← statically linked from the raylib submodule
```

### Supported ABIs

`x86`, `x86_64`, `armeabi-v7a`, `arm64-v8a`, `riscv64`

> ABI splits are enabled for APK builds and disabled automatically for AAB builds to avoid
> conflicts.

---

## 4. Build System

### Prerequisites

| Tool        | Version                             |
|-------------|-------------------------------------|
| JDK         | 21 (Managed automatically by Gradle |
| CMake       | ≥ 3.25.0                            |
| Android SDK | Managed automatically by AGP        |
| Android NDK | Managed automatically by AGP        |

### Gradle tasks

```bash
# Build debug and release APKs + AABs
./gradlew build
./gradlew bundle

# Install on a connected device or emulator
./gradlew installDebug
./gradlew installRelease

# Uninstall
./gradlew uninstallDebug
./gradlew uninstallRelease

# Run lint checks
./gradlew lint lintRelease

# Clean all build outputs
./gradlew clean
```

### CMake flags (set automatically by Gradle)

| Flag                 | Value     | Purpose                            |
|----------------------|-----------|------------------------------------|
| `CMAKE_C_STANDARD`   | `23`      | Enforce C23                        |
| `CMAKE_C_EXTENSIONS` | `OFF`     | Disable compiler extensions        |
| `PLATFORM`           | `Android` | Tell raylib to target Android      |
| `BUILD_EXAMPLES`     | `OFF`     | Skip raylib example builds         |
| `APP_LIB_NAME`       | `main`    | Output library name (`libmain.so`) |

### Release signing

Release builds read signing credentials from the following **environment variables**:

| Variable         | Description                                            |
|------------------|--------------------------------------------------------|
| `STORE_FILE`     | Absolute path to the `.jks` / `.p12` keystore          |
| `STORE_PASSWORD` | Keystore password                                      |
| `KEY_ALIAS`      | Key alias inside the keystore                          |
| `KEY_PASSWORD`   | Key password (falls back to `STORE_PASSWORD` if unset) |

If none of these are set, the release build falls back to the **debug keystore** automatically.

### Gradle performance settings (`gradle.properties`)

- Build cache and configuration cache are enabled, running in parallel.
- JVM heap is set to 2 GB.
- Non-transitive R classes are enabled (`android.nonTransitiveRClass=true`).

---

## 5. Coding Standards

### C code (`app/src/main/c/`)

- **Style**: Follow the existing style in `main.c`:
    - 4-space indentation (no tabs).
    - `const` whenever a variable is not reassigned.
    - Guard all public utility functions against invalid input (null pointers, non-positive
      dimensions, etc.).
    - Keep the render loop free of heap allocations.
- **Comments**: Use `//` line comments for inline explanations; keep comments concise and accurate.

### CMake (`CMakeLists.txt`)

- New C sources in `app/src/main/c/` are picked up automatically via `GLOB_RECURSE` — no manual
  `target_sources` additions needed.

### Gradle (`.gradle.kts` files)

- Use **Kotlin DSL** (`.kts`) — do not introduce Groovy build scripts.
- Add new dependencies through the **version catalog** (`gradle/libs.versions.toml`), not as inline
  strings.

### XML / Resources

- All string resources belong in `app/src/main/res/values/strings.xml`.
- Follow Android resource naming conventions (`snake_case` for resource IDs).

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

- Push to `main`
- Push of a `v*.*.*` tag
- Pull requests targeting `main`
- Manual dispatch

**Steps summary:**

1. Check out code (with submodules).
2. Set up Gradle.
3. Build APKs and AABs, signing with keystore secrets.
4. Run lint.
5. Rename artifacts to a consistent `HelloWorld_*` naming scheme.
6. Upload artifacts: debug/release APKs, debug/release AABs, native debug symbols, ProGuard mapping,
   build logs, lint reports.
7. Generate **build-provenance attestations** for all output artifacts.

### `release.yml` — triggered on version tag push

1. Build and sign release APKs and AABs.
2. Rename artifacts to `HelloWorld_<version>_*`, move ProGuard mapping and native debug symbols.
3. Generate `SHA256SUMS` and sign it with GPG.
4. Create a GitHub Release with auto-generated notes, attach APKs, AAB, mapping, native debug
   symbols, `SHA256SUMS`, and `SHA256SUMS.asc`. Also opens a discussion under **Announcements**.

### `dependency-submission.yml` — triggered on

- Push to `main`
- Manual dispatch

Submits the dependency graph to GitHub for security analysis.

### `codeql.yml` — triggered on

- Push to `main`
- Push of a `v*.*.*` tag
- Pull requests targeting `main`
- Manual dispatch

Runs GitHub's CodeQL static analysis on `c-cpp`.

---

## 8. Important Constraints

| Rule                                                  | Reason                                                                                                                   |
|-------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| **Do not add Kotlin or Java source files.**           | The app is fully native (`android:hasCode="false"`).                                                                     |
| **Do not edit files under `app/src/main/c/raylib/`.** | This is a git submodule. Changes there will be lost on the next `submodule update` and will not be tracked in this repo. |
| **Always use `./gradlew`, never `gradle`.**           | The wrapper pins the exact Gradle version required for reproducible builds.                                              |
| **Lint is treated as errors.**                        | `warningsAsErrors = true` in the lint configuration. All lint warnings must be resolved before merging.                  |

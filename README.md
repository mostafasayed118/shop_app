# e_commerce

A new Flutter project.

## ⚠️ Known issue — Android builds fail with "Could not close incremental caches"

**Symptom:** `flutter run` / `flutter build apk` fails with:

```
e: Daemon compilation failed
Caused by: java.lang.Exception: Could not close incremental caches in
    <project>\build\shared_preferences_android\kotlin\compileDebugKotlin\...
Suppressed: java.lang.IllegalStateException: Storage for
    [...class-fq-name-to-source.tab] is already registered
```

**Root cause:** Flutter's composite Gradle build compiles each plugin module
(e.g. `shared_preferences_android`) twice within one Kotlin-daemon session, and
the second pass collides in Kotlin's incremental-storage registry
(`FilePageCache`). It is **structural, not a version bug** — see the upstream
tracking below.

**Workaround (in place):** `kotlin.incremental=false` in
`android/gradle.properties` (kept with a detailed comment). Disabling
incremental compilation sidesteps the corrupted cache machinery entirely; the
only cost is a marginally slower Kotlin compile (~1s for this project).

**Empirically NOT fixed by toolchain bumps (verified 2026-08-02):** both
Kotlin 2.4.10 alone and the full Flutter-master combo (AGP 9.1.0 + Gradle
9.3.1 + Kotlin 2.4.0) fail identically on fresh daemons and clean caches.

**Upstream tracking:** JetBrains
[KT-84306](https://youtrack.jetbrains.com/issue/KT-84306) ("Kotlin compile
fails on Gradle composite builds with shared subprojects") — **open**. The
similarly-worded [KT-87217](https://youtrack.jetbrains.com/issue/KT-87217) is
resolved but covers only JS/Wasm incremental compilation. Re-test the
workaround removal after a Flutter upgrade that changes the plugin build, or
when KT-84306 closes.

**First-aid if you hit it after force-killing a build:** stop Gradle daemons
(`cd android && ./gradlew --stop`), kill any lingering `KotlinCompileDaemon`
java process, then `flutter clean` and rebuild.

## Development checks

- **Full health check** (analyze + tests + debug APK): `bash tool/health_check.sh`
- **Pre-commit hook** (one-time install): `bash tool/install_precommit_hook.sh`
  — after that, every `git commit` automatically runs `flutter analyze` and
  `flutter test` on Dart-relevant changes (docs-only commits are skipped; a
  failing check blocks the commit; escape hatch: `git commit --no-verify`).
  The hook source is versioned at `tool/pre-commit`; re-run the installer to
  pick up edits.
- `.gitattributes` pins `tool/*.sh` and `tool/pre-commit` to LF line endings
  so the hook survives Windows checkouts (`core.autocrlf`).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

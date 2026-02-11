# Fix Status (2026-02-11)

| Finding | Status | Fix |
|---------|--------|-----|
| iOS App Store build not feasible | DEFERRED | Launching Android first |
| External Stripe portal (policy risk) | DEFERRED | Policy review needed |
| Android INTERNET permission missing in main manifest | FIXED (previous session) | Added to main AndroidManifest.xml |
| Gradle user-home override (`/home/user/.gradle`) | FIXED | Removed from gradle.properties |
| Sensitive data in logs | PARTIALLY FIXED | `print()` → `debugPrint()` done earlier; PII in debugPrint deferred |
| Password reset deep link not wired | FIXED | Added `kviktime://` intent-filter to AndroidManifest.xml |
| API base placeholder risk | DEFERRED | Environment configuration |
| Auth header wrong for analytics API | FIXED | Uses `session?.accessToken` now |
| Release signing fallback to debug keystore | FIXED (previous session) | `key.properties`-based signing config |
| Pinned NDK version | DEFERRED | Low risk |
| CI produces APK not AAB | DEFERRED | CI config change |

---

**Plan (original audit)**
- Inventory Flutter targets + CI/deploy automation
- Review Android manifests/Gradle/signing/SDK levels + permission surface
- Review iOS project/Info.plist/entitlements/Pods + privacy-required artifacts
- Scan Dart for permission requests, external billing/account flows, third‑party data sharing, deep links, and sensitive logging
- Cross-check IDs/versions/names across pubspec + platform configs
- Summarize risks with severity + file/line evidence

**Scope (Key Artifacts Inspected)**
- Flutter/package: `apps/mobile_flutter/pubspec.yaml:19`
- Android: `apps/mobile_flutter/android/app/src/main/AndroidManifest.xml:2`, `apps/mobile_flutter/android/app/build.gradle.kts:16`, `apps/mobile_flutter/android/gradle.properties:4`, `apps/mobile_flutter/android/settings.gradle.kts:20`
- iOS: `apps/mobile_flutter/ios/Flutter/Generated.xcconfig:1`, `apps/mobile_flutter/ios/Flutter/flutter_export_environment.sh:2`
- CI: `.github/workflows/flutter-mobile.yml:17`
- App flows/services: `apps/mobile_flutter/lib/config/external_links.dart:10`, `apps/mobile_flutter/lib/screens/account_status_gate.dart:114`, `apps/mobile_flutter/lib/services/supabase_auth_service.dart:188`, `apps/mobile_flutter/lib/services/map_service.dart:15`

**High-Risk Findings (Likely to Block Store/Release)**
- **iOS App Store build is not feasible from this repo state**: the `ios/` tree appears to only include generated Flutter artifacts (no `Info.plist`, no `Runner.xcodeproj`, no `Podfile`, no entitlements, no privacy manifest found), so iOS compliance items can’t be validated and an App Store build would be blocked. Evidence that tracked iOS files are generated and include machine paths: `apps/mobile_flutter/ios/Flutter/Generated.xcconfig:1`, `apps/mobile_flutter/ios/Flutter/Generated.xcconfig:3`, `apps/mobile_flutter/ios/Flutter/flutter_export_environment.sh:2`.
- **External subscription management via Stripe portal (policy risk)**: the app gates access on subscription state and opens an external “Stripe customer portal via web app”; this can violate Apple/Google billing rules depending on whether the subscription unlocks digital services/features for general users. Evidence: `apps/mobile_flutter/lib/config/external_links.dart:10`, `apps/mobile_flutter/lib/config/external_links.dart:11`, `apps/mobile_flutter/lib/screens/account_status_gate.dart:114`.
- **Android release networking may be broken**: the only declared Android permission is `INTERNET` in debug/profile manifests, with no `<uses-permission>` present in the main manifest set; this can break Supabase/Mapbox/HTTP calls in release builds. Evidence of declared `INTERNET` only in debug/profile: `apps/mobile_flutter/android/app/src/debug/AndroidManifest.xml:6`, `apps/mobile_flutter/android/app/src/profile/AndroidManifest.xml:6`; evidence the app uses network services: `apps/mobile_flutter/lib/config/supabase_config.dart:6`, `apps/mobile_flutter/lib/services/map_service.dart:15`.
- **CI/build portability risk from Gradle user-home override**: `gradle.user.home=/home/user/.gradle` is nonstandard and likely incompatible with GitHub Actions runners (and many dev machines), risking build failures/permission errors. Evidence: `apps/mobile_flutter/android/gradle.properties:4`, CI runner: `.github/workflows/flutter-mobile.yml:17`.

**Medium-Risk Findings (Could Cause Rejection, Privacy Mismatch, or Production Breakage)**
- **Sensitive data in logs**: multiple `debugPrint` statements include user email, full entry JSON, and travel origin/destination strings; if logs are collected (device logs, crash reports, support dumps), this can conflict with privacy disclosures and increase exposure of personal data. Evidence: `apps/mobile_flutter/lib/services/supabase_auth_service.dart:67`, `apps/mobile_flutter/lib/providers/entry_provider.dart:128`, `apps/mobile_flutter/lib/services/map_service.dart:90`.
- **Password reset deep link metadata not wired in platform configs**: Supabase reset uses `kviktime://reset-password`, but Android manifest shows only a launcher intent filter and no app-link/custom-scheme handling; iOS URL scheme configuration can’t be checked because iOS project files are missing. Evidence: `apps/mobile_flutter/lib/services/supabase_auth_service.dart:188`, launcher-only intent filter: `apps/mobile_flutter/android/app/src/main/AndroidManifest.xml:25`.
- **API base configuration inconsistency/placeholder risk**: admin API defaults to a placeholder `https://your-project-id...` base URL while analytics API requires `KVIKTIME_API_BASE`; this can lead to environment-specific breakage if the build isn’t injecting the expected values. Evidence: `apps/mobile_flutter/lib/config/api_config.dart:6`, `apps/mobile_flutter/lib/services/admin_api_service.dart:114`, `apps/mobile_flutter/lib/config/app_config.dart:7`, `apps/mobile_flutter/lib/services/analytics_api.dart:20`.
- **Auth header likely wrong for analytics API**: analytics uses `user?.aud` as the Bearer token, which is not the access token in typical Supabase flows, risking authorization failures or unintended auth behavior. Evidence: `apps/mobile_flutter/lib/services/analytics_api.dart:28`.
- **Release signing behavior can derail Play deployment**: release signing falls back to the debug keystore when `key.properties` isn’t present, which will prevent uploading to Play (and can confuse release artifact provenance). Evidence: `apps/mobile_flutter/android/app/build.gradle.kts:50`, `apps/mobile_flutter/android/app/build.gradle.kts:53`.
- **Pinned NDK version can break builds**: explicit `ndkVersion` requires that exact NDK to be installed in the build environment. Evidence: `apps/mobile_flutter/android/app/build.gradle.kts:18`.
- **CI produces APK (deployment gap for Play)**: workflow builds an APK; Play Store production typically expects an AAB, so deployment readiness isn’t demonstrated here. Evidence: `.github/workflows/flutter-mobile.yml:44`.

**Low-Risk / Positive Findings**
- **No dangerous Android permissions declared in app manifests** (good for compliance posture): only `INTERNET` appears (and only in debug/profile). Evidence: `apps/mobile_flutter/android/app/src/debug/AndroidManifest.xml:6`.
- **Android identity consistency looks good**: manifest package/Gradle namespace/applicationId/MainActivity package align. Evidence: `apps/mobile_flutter/android/app/src/main/AndroidManifest.xml:2`, `apps/mobile_flutter/android/app/build.gradle.kts:16`, `apps/mobile_flutter/android/app/build.gradle.kts:30`, `apps/mobile_flutter/android/app/src/main/kotlin/se/kviktime/app/MainActivity.kt:1`.
- **iOS icon generation is explicitly disabled** (suggests iOS isn’t currently a supported shipping target). Evidence: `apps/mobile_flutter/pubspec.yaml:83`.

**Gaps / Not Verifiable From Repo**
- iOS compliance artifacts (usage descriptions, entitlements, background modes, ATS, privacy manifest/Required‑Reason APIs) can’t be assessed because core iOS project files aren’t present.
- Final Android permission set after manifest-merging (from plugins) isn’t confirmed without inspecting a merged manifest from a build.
- Store-console metadata (Privacy Nutrition Labels / Data Safety / billing declarations) isn’t in the codebase; only code-side indicators (Supabase + Mapbox + Stripe portal links) are visible.
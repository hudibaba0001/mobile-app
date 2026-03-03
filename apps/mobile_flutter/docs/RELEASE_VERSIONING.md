# Release Versioning (Google Play)

Single source of truth:
- `pubspec.yaml` `version: <build-name>+<build-number>`
- Android `versionCode` is taken from Flutter `build-number`.

Play Console rule:
- `versionCode` must be unique and strictly increasing for every upload.

## Standard workflow

1. Check current version:
```powershell
cd apps/mobile_flutter
dart run tool/bump_release_version.dart --show
```

2. Bump build number by 1:
```powershell
dart run tool/bump_release_version.dart --bump
```

3. Build upload artifact:
```powershell
flutter build appbundle --release
```

4. Upload:
- `build/app/outputs/bundle/release/app-release.aab`

## If Play says “version code already used”

Set an explicit higher build number:
```powershell
dart run tool/bump_release_version.dart --set-build 12
```

Then rebuild:
```powershell
flutter build appbundle --release
```

## Notes

- Do not manually edit Android `versionCode`; keep `pubspec.yaml` as the only source.
- Commit version bump before creating release tags.

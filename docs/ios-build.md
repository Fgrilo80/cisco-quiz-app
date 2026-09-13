# iOS build (macOS + Xcode)

Signed IPAs cannot be produced on Linux. Build on a Mac with Xcode and CocoaPods.

## Prerequisites

- macOS with Xcode (15+ recommended) and Command Line Tools
- [Flutter stable](https://docs.flutter.dev/get-started/install/macos) on `PATH`
- CocoaPods: `sudo gem install cocoapods` (or Homebrew)
- Apple Developer account for device/TestFlight/App Store signing

## Steps

```bash
cd cisco-quiz-app
flutter pub get
cd ios && pod install && cd ..
# Optional sanity check on Mac:
flutter build ios --release --no-codesign
```

Open the **workspace** (not the `.xcodeproj`):

```bash
open ios/Runner.xcworkspace
```

In Xcode:

1. Select target **Runner**.
2. **Signing & Capabilities**: choose your Team; enable Automatically manage signing.
3. Confirm Bundle Identifier `pt.fgrilo.ciscoquiz.ciscoQuiz` (or your own unique id).
4. Version/build come from `pubspec.yaml` (`version: 1.2.2+4` → CFBundleShortVersionString `1.2.2`, CFBundleVersion `4`).
5. Product → Destination → **Any iOS Device (arm64)**.
6. Product → **Archive**, then Distribute App (Ad Hoc / Development / App Store Connect).

## Notes

- `ios/Podfile` is the standard Flutter CocoaPods file; `pod install` creates `Pods/` and updates the workspace.
- `flutter build ios --no-codesign` on Linux usually fails (no iOS SDK); use a Mac.
- Do not commit `ios/Pods/` or `ios/.symlinks/`.

## Linux note

On this Linux Flutter install (`flutter build` has no `ios` subcommand), you cannot compile or archive for iPhone. `flutter build ios --no-codesign` is unavailable here. Always use a Mac as above.

# Windows desktop release

Version **1.2.9+11**, bundled bank **1230** questions in `assets/cricket.json` (Cricket `main` `02c0a868`, post length-bias). Do not edit the quiz bank to produce this binary.

When **DESKTOP-FGRILO** is away and cannot approve a local Shell build, use GitHub Actions. The local PowerShell script remains the path on that PC.

| Item | Value |
| --- | --- |
| Repo | https://github.com/Fgrilo80/cisco-quiz-app |
| Branch | `app` (or the open `cursor/**` branch before merge) |
| Version | `1.2.9+11` (`pubspec.yaml`) |
| Bundled bank | `assets/cricket.json`, **1230** questions |
| Release | https://github.com/Fgrilo80/cisco-quiz-app/releases/tag/v1.2.9 |

## CI (PC unavailable)

Workflow: [`.github/workflows/windows-release.yml`](../.github/workflows/windows-release.yml)

- Runner: `windows-latest`
- Flutter: stable **3.47.2** (project metadata revision `d3b14c876900e553bc736ca19295fc09e3853e8e`)
- Triggers: manual `workflow_dispatch`; push to `app` or `cursor/**` when `pubspec.yaml`, the bank, or the Windows project changes; push of tag `v1.2.9`. Pushes to `cursor/**` run so a pull request can publish the zip before it merges.
- Checkout uses the ref that started the run (including tag `v1.2.9`).
- Steps: Flutter 3.47.2, `flutter config --enable-windows-desktop`, `flutter pub get`, `flutter build windows --release`.
- The job refuses to publish unless `pubspec.yaml` is `1.2.9+11` and the bundled bank still has 1230 `"question"` entries.
- Zip: contents of `build/windows/x64/runner/Release` (so `cisco_quiz.exe`, DLLs, and `data\` sit at the root of the archive) as `CiscoQuiz-1.2.9-Windows.zip`.
- Artifact name: `CiscoQuiz-1.2.9-Windows` (workflow run → Artifacts).
- Release asset: https://github.com/Fgrilo80/cisco-quiz-app/releases/download/v1.2.9/CiscoQuiz-1.2.9-Windows.zip
- If release `v1.2.9` does not exist yet, the job creates it on the triggering commit and then uploads the zip. `--clobber` replaces only an asset of the same name.

Manual run after the workflow file is on the branch:

```bash
gh workflow run windows-release.yml --ref cursor/sync-bank-1.2.9-0b42
```

Use `--ref` with the branch that contains this workflow (for example the open pull request branch) before it is merged. After merge, `--ref app` is enough.

Unzip and keep `cisco_quiz.exe` next to `flutter_windows.dll` and the `data` folder.

## Local build (DESKTOP-FGRILO)

`flutter build windows --release` needs Windows and the Visual Studio C++ desktop toolchain. A Linux cloud VM cannot cross-compile it.

### Prerequisites

- Windows 10 or 11, 64-bit
- [Git for Windows](https://git-scm.com/download/win)
- [Flutter stable](https://docs.flutter.dev/get-started/install/windows) **3.47.2** on `PATH` (SDK constraint `^3.13.2`; project metadata tracks stable revision `d3b14c876900e553bc736ca19295fc09e3853e8e`)
- Visual Studio 2022 with the **Desktop development with C++** workload (MSVC, C++ CMake tools for Windows, Windows 10/11 SDK)
- `flutter doctor` shows a healthy Windows toolchain

### Build

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-windows-release.ps1
```

The script:

1. Clones `https://github.com/Fgrilo80/cisco-quiz-app.git` branch `app` into `%USERPROFILE%\src\cisco-quiz-app`, or `git pull --ff-only` when that clone already exists.
2. Checks version `1.2.9+11` and bank count 1230.
3. Runs `flutter pub get` and `flutter build windows --release`.
4. Copies `build\windows\x64\runner\Release` to `%USERPROFILE%\Desktop\CiscoQuiz`.
5. Writes `%USERPROFILE%\Desktop\CiscoQuiz-1.2.9-Windows.zip` (top-level folder `CiscoQuiz`, unlike the CI zip which has the Release files at the archive root).

Manual equivalent, from a checkout of branch `app`:

```powershell
git checkout app
git pull --ff-only origin app
flutter config --enable-windows-desktop
flutter pub get
flutter build windows --release
```

Release output: `build\windows\x64\runner\Release`.

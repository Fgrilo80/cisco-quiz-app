#Requires -Version 5.1
<#
.SYNOPSIS
  Windows release for Cisco Quiz 1.2.8+10 (bundled bank 1230).

.DESCRIPTION
  Run this on DESKTOP-FGRILO (Windows). The Linux cloud VM cannot run
  `flutter build windows --release`.

  Clones or fast-forwards branch app, checks pubspec 1.2.8+10 and that
  assets\cricket.json still has 1230 questions, then:
    flutter pub get
    flutter build windows --release
    copies build\windows\x64\runner\Release to Desktop\CiscoQuiz
    zips Desktop\CiscoQuiz-1.2.8-Windows.zip

  Does not edit the quiz bank.
#>
$ErrorActionPreference = 'Stop'

$RepoUrl = 'https://github.com/Fgrilo80/cisco-quiz-app.git'
$Branch = 'app'
$ExpectedVersion = '1.2.8+10'
$ExpectedQuestions = 1230
$Desktop = [Environment]::GetFolderPath('Desktop')
$RepoDir = Join-Path $env:USERPROFILE 'src\cisco-quiz-app'
$OutDir = Join-Path $Desktop 'CiscoQuiz'
$ZipPath = Join-Path $Desktop 'CiscoQuiz-1.2.8-Windows.zip'

function Assert-ExitCode([string]$Step) {
  if ($LASTEXITCODE -ne 0) {
    throw "$Step failed with exit code $LASTEXITCODE"
  }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw 'git is not on PATH.'
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'flutter is not on PATH. Install Flutter stable for Windows and reopen PowerShell.'
}

New-Item -ItemType Directory -Force -Path (Split-Path $RepoDir -Parent) | Out-Null

if (Test-Path (Join-Path $RepoDir '.git')) {
  Push-Location $RepoDir
  git fetch origin $Branch
  Assert-ExitCode 'git fetch'
  git checkout $Branch
  Assert-ExitCode 'git checkout'
  git pull --ff-only origin $Branch
  Assert-ExitCode 'git pull'
  Pop-Location
} else {
  if (Test-Path $RepoDir) {
    throw "Path exists but is not a git clone: $RepoDir"
  }
  git clone --branch $Branch --single-branch $RepoUrl $RepoDir
  Assert-ExitCode 'git clone'
}

$pubspecPath = Join-Path $RepoDir 'pubspec.yaml'
$versionLine = Select-String -Path $pubspecPath -Pattern '^version:\s*(.+)\s*$' | Select-Object -First 1
$version = if ($versionLine) { $versionLine.Matches[0].Groups[1].Value.Trim() } else { '' }
if ($version -ne $ExpectedVersion) {
  throw "Expected pubspec version $ExpectedVersion on branch $Branch (found '$version')."
}

$bankPath = Join-Path $RepoDir 'assets\cricket.json'
$bankText = Get-Content -Raw -Path $bankPath
$questionCount = ([regex]::Matches($bankText, '"question"\s*:')).Count
if ($questionCount -ne $ExpectedQuestions) {
  throw "Bundled bank has $questionCount questions; expected $ExpectedQuestions. Leave assets\cricket.json unchanged."
}

Push-Location $RepoDir
flutter pub get
Assert-ExitCode 'flutter pub get'
flutter build windows --release
Assert-ExitCode 'flutter build windows --release'
Pop-Location

$Release = Join-Path $RepoDir 'build\windows\x64\runner\Release'
$Exe = Join-Path $Release 'cisco_quiz.exe'
if (-not (Test-Path $Exe)) {
  throw "Expected executable not found: $Exe"
}

if (Test-Path $OutDir) {
  Remove-Item -Recurse -Force $OutDir
}
Copy-Item -Path $Release -Destination $OutDir -Recurse

if (Test-Path $ZipPath) {
  Remove-Item -Force $ZipPath
}
Compress-Archive -Path $OutDir -DestinationPath $ZipPath -CompressionLevel Optimal

Write-Host "Release folder: $OutDir"
Write-Host "Zip: $ZipPath"

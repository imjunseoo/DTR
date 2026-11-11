param([Parameter(ValueFromRemainingArguments=$true)][string[]]$FlutterArguments)
$ErrorActionPreference = 'Stop'

$projectPath = $PSScriptRoot
$flutterSdk = $env:FLUTTER_ROOT
$toolEnvironment = @{}

# Reuse this PC's shared tools if the checkout is under the marked workspace.
$workspace = Get-Item -LiteralPath $projectPath
while ($workspace) {
    if ((Test-Path -LiteralPath (Join-Path $workspace.FullName '.dontori-drive-id') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $workspace.FullName 'toolchains/flutter/bin/flutter.bat') -PathType Leaf)) {
        break
    }
    $workspace = $workspace.Parent
}
if ($workspace) {
    if (-not (Test-Path -LiteralPath 'Q:/')) {
        & subst.exe Q: $workspace.FullName
        if ($LASTEXITCODE -ne 0) { throw 'Could not map Q: to the local development workspace.' }
    }
    $localMarker = Join-Path $workspace.FullName '.dontori-drive-id'
    if (-not (Test-Path -LiteralPath 'Q:/.dontori-drive-id' -PathType Leaf) -or
        (Get-Content -LiteralPath 'Q:/.dontori-drive-id' -Raw) -cne (Get-Content -LiteralPath $localMarker -Raw)) {
        throw 'Q: is already used by another drive. The existing mapping was preserved.'
    }
    $relativePath = $projectPath.Substring($workspace.FullName.Length).TrimStart('\', '/')
    $projectPath = Join-Path 'Q:/' $relativePath
    if (-not $flutterSdk) { $flutterSdk = 'Q:/toolchains/flutter' }
    $toolEnvironment = @{
        PUB_CACHE = 'Q:/toolchains/pub-cache'
        TEMP = 'Q:/toolchains/temp'
        TMP = 'Q:/toolchains/temp'
        ANDROID_HOME = 'Q:/toolchains/android-sdk'
        ANDROID_SDK_ROOT = 'Q:/toolchains/android-sdk'
        GRADLE_USER_HOME = 'Q:/toolchains/gradle-cache'
    }
    New-Item -ItemType Directory -Force -Path $toolEnvironment.TEMP | Out-Null
    $localJdk = Get-ChildItem -LiteralPath 'Q:/toolchains/java' -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'bin/java.exe') } | Select-Object -First 1
    if ($localJdk) { $toolEnvironment.JAVA_HOME = $localJdk.FullName }
}

if ($flutterSdk) {
    $flutter = Join-Path $flutterSdk 'bin/flutter.bat'
    if (-not (Test-Path -LiteralPath $flutter -PathType Leaf)) { throw "Flutter SDK not found at $flutter" }
} else {
    $command = Get-Command flutter.bat -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $command) { throw 'Install Flutter and add its bin folder to PATH, or set FLUTTER_ROOT to the SDK directory.' }
    $flutter = $command.Source
    $flutterSdk = Split-Path -Parent (Split-Path -Parent $flutter)
}
$toolEnvironment.FLUTTER_ROOT = $flutterSdk

$savedEnvironment = @{}
Push-Location -LiteralPath $projectPath
try {
    foreach ($name in $toolEnvironment.Keys) {
        $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
        [Environment]::SetEnvironmentVariable($name, $toolEnvironment[$name], 'Process')
    }
    & $flutter @FlutterArguments
    $result = $LASTEXITCODE
} finally {
    foreach ($name in $savedEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], 'Process')
    }
    Pop-Location
}
exit $result

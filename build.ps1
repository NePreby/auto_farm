[CmdletBinding()]
param(
    [string] $OutputPath = (Join-Path $PSScriptRoot 'dist/main.lua'),
    [string] $CompilerPath = ''
)

$ErrorActionPreference = 'Stop'
$utf8 = [Text.UTF8Encoding]::new($false)
$lf = [string][char]10

$manifestPath = Join-Path $PSScriptRoot 'manifest.txt'
if (-not [IO.File]::Exists($manifestPath)) {
    throw 'Missing manifest.txt'
}

$modulePaths = [IO.File]::ReadAllLines($manifestPath) |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne '' -and -not $_.StartsWith('#') }

$payloadBuilder = [Text.StringBuilder]::new()
foreach ($relativePath in $modulePaths) {
    $modulePath = Join-Path $PSScriptRoot $relativePath
    if (-not [IO.File]::Exists($modulePath)) {
        throw "Missing module: $relativePath"
    }
    [void] $payloadBuilder.Append([IO.File]::ReadAllText($modulePath))
}
$payload = $payloadBuilder.ToString()

if (-not $payload.Contains('local RequestedScriptVersion = "2.3.4"')) {
    throw 'Payload is not V2.3.4'
}
if (-not $payload.Contains('buildMainInterface()')) {
    throw 'Payload is missing the UI entry point'
}

$fluentPath = Join-Path $PSScriptRoot 'vendor/fluent.lua'
$launcherPath = Join-Path $PSScriptRoot 'runtime/launcher.lua'
if (-not [IO.File]::Exists($fluentPath)) {
    throw 'Missing vendor/fluent.lua'
}
if (-not [IO.File]::Exists($launcherPath)) {
    throw 'Missing runtime/launcher.lua'
}

$fluent = [IO.File]::ReadAllText($fluentPath).Trim("`r", "`n")
$launcher = [IO.File]::ReadAllText($launcherPath).TrimStart("`r", "`n")
$bundle = 'local HAOTOOL_SOURCE = [========[' + $lf + $payload + $lf +
    ']========]' + $lf + $lf +
    'local HAOTOOL_FLUENT_SOURCE = [==========[' + $lf + $fluent + $lf +
    ']==========]' + $lf + $lf + $launcher

$outputDirectory = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($OutputPath))
[IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
[IO.File]::WriteAllText($OutputPath, $bundle, $utf8)

if ($CompilerPath -ne '') {
    if (-not [IO.File]::Exists($CompilerPath)) {
        throw "Luau compiler not found: $CompilerPath"
    }
    & $CompilerPath --null $OutputPath
    if ($LASTEXITCODE -ne 0) {
        throw 'Luau compiler reported an error'
    }
}

$hash = (Get-FileHash -LiteralPath $OutputPath -Algorithm SHA256).Hash
Write-Output "Built: $OutputPath"
Write-Output "Modules: $($modulePaths.Count)"
Write-Output "SHA256: $hash"

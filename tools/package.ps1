$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root=Split-Path $PSScriptRoot -Parent
$package=Join-Path $root 'build/package/Release/hud-fields'
$manifest=Get-Content -LiteralPath (Join-Path $package 'zml-package.json') -Raw | ConvertFrom-Json
$dist=Join-Path $root 'dist';New-Item -ItemType Directory -Force $dist | Out-Null
$zip=Join-Path $dist ('EndfieldHudFields-0.1.2-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.zip')
$files=@($manifest.files | ForEach-Object {Join-Path $package $_}) + @(Join-Path $package 'zml-package.json')
foreach($file in $files){if(-not(Test-Path -LiteralPath $file -PathType Leaf)){throw "Missing release file: $file"}}
$archive = [System.IO.Compression.ZipFile]::Open($zip, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in $files) {
        $name = Split-Path $file -Leaf
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file, $name) | Out-Null
    }
} finally {
    $archive.Dispose()
}
(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash+'  '+(Split-Path $zip -Leaf) | Set-Content -Encoding ascii ($zip+'.sha256')
Write-Output $zip

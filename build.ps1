param([string]$Output = (Join-Path $PSScriptRoot 'TuinRPG.pk3'))

$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot 'src'
if (-not (Test-Path -LiteralPath $source -PathType Container)) { throw "Missing PK3 source directory: $source" }
$resolvedOutput = [System.IO.Path]::GetFullPath($Output)
$parent = [System.IO.Path]::GetDirectoryName($resolvedOutput)
if (-not [System.IO.Directory]::Exists($parent)) { [System.IO.Directory]::CreateDirectory($parent) | Out-Null }
if ([System.IO.File]::Exists($resolvedOutput)) { [System.IO.File]::Delete($resolvedOutput) }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($source, $resolvedOutput, [System.IO.Compression.CompressionLevel]::Optimal, $false)
Write-Output "Built $resolvedOutput"

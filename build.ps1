#Requires -Version 5.1
[CmdletBinding()]
param(
	[string]$Mod,
	[string]$ModsDir,
	[switch]$Launch
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path $repoRoot 'build.config.json'

if (-not $ModsDir) {
	if (Test-Path -LiteralPath $configPath) {
		$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
		$ModsDir = $config.modsDir
	}
}

if (-not $ModsDir) {
	throw "ModsDir not specified. Pass -ModsDir <path> or create '$configPath' with:`n{`n  `"modsDir`": `"D:\\SteamLibrary\\steamapps\\common\\Road to Vostok\\mods`"`n}"
}

if (-not (Test-Path -LiteralPath $ModsDir -PathType Container)) {
	throw "ModsDir does not exist: $ModsDir"
}

function Get-ModFolders {
	if ($Mod) {
		$p = Join-Path $repoRoot $Mod
		if (-not (Test-Path -LiteralPath (Join-Path $p 'mod.txt'))) {
			throw "No mod.txt found in '$p'."
		}
		return ,(Get-Item -LiteralPath $p)
	}
	return Get-ChildItem -LiteralPath $repoRoot -Directory | Where-Object {
		Test-Path -LiteralPath (Join-Path $_.FullName 'mod.txt')
	}
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Update-ModVersion {
	param([string]$ModTxtPath)

	$content = [System.IO.File]::ReadAllText($ModTxtPath)
	$pattern = '(?m)^(version\s*=\s*")(\d+)\.(\d+)\.(\d+)(")'
	$m = [regex]::Match($content, $pattern)
	if (-not $m.Success) {
		Write-Warning "Skipping version bump: '$ModTxtPath' has no version=`"X.Y.Z`" line."
		return $null
	}

	$major = [int]$m.Groups[2].Value
	$minor = [int]$m.Groups[3].Value
	$patch = [int]$m.Groups[4].Value + 1
	$newVersion = "$major.$minor.$patch"
	$replacement = '${1}' + $newVersion + '${5}'
	$newContent = [regex]::Replace($content, $pattern, $replacement)

	$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
	[System.IO.File]::WriteAllText($ModTxtPath, $newContent, $utf8NoBom)
	return $newVersion
}

function New-ModZip {
	param([string]$SourceDir, [string]$ZipPath, [string]$ModId)

	if (Test-Path -LiteralPath $ZipPath) {
		Remove-Item -LiteralPath $ZipPath -Force
	}

	$sourceFull = (Resolve-Path -LiteralPath $SourceDir).Path.TrimEnd('\')
	$prefixLen = $sourceFull.Length + 1
	$level = [System.IO.Compression.CompressionLevel]::Optimal

	$zip = [System.IO.Compression.ZipFile]::Open($ZipPath, [System.IO.Compression.ZipArchiveMode]::Create)
	try {
		Get-ChildItem -LiteralPath $sourceFull -Recurse -File | ForEach-Object {
			$relative = $_.FullName.Substring($prefixLen).Replace('\', '/')
			if ($relative -eq 'mod.txt' -or $relative -eq 'README.md') {
				$entry = $relative
			} else {
				$entry = "mods/$ModId/$relative"
			}
			[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $entry, $level) | Out-Null
		}
	} finally {
		$zip.Dispose()
	}
}

function Test-GitAvailable {
	$result = & git -C $repoRoot rev-parse --is-inside-work-tree 2>$null
	return $LASTEXITCODE -eq 0
}

function Test-FolderDirty {
	param([string]$FolderPath, [string]$FolderName)

	$result = & git -C $repoRoot status --porcelain -- $FolderName 2>$null
	return -not [string]::IsNullOrEmpty($result)
}

function Get-CurrentModVersion {
	param([string]$ModTxtPath)

	$content = [System.IO.File]::ReadAllText($ModTxtPath)
	$pattern = '(?m)^(version\s*=\s*")(\d+)\.(\d+)\.(\d+)(")'
	$m = [regex]::Match($content, $pattern)
	if (-not $m.Success) {
		return $null
	}
	return "$($m.Groups[2].Value).$($m.Groups[3].Value).$($m.Groups[4].Value)"
}

$folders = @(Get-ModFolders)
if ($folders.Count -eq 0) {
	throw "No mod folders found (looked for directories containing mod.txt)."
}

$gitAvailable = Test-GitAvailable
$gitWarningShown = $false

foreach ($folder in $folders) {
	$modTxt = Join-Path $folder.FullName 'mod.txt'

	$shouldBump = $true
	if ($gitAvailable) {
		$folderDirty = Test-FolderDirty -FolderPath $folder.FullName -FolderName $folder.Name
		$shouldBump = $folderDirty
	} elseif (-not $gitWarningShown) {
		Write-Warning "Git not available; falling back to always-bumping version. Either git is not installed or this is not a git repository."
		$gitWarningShown = $true
	}

	$version = $null
	if ($shouldBump) {
		$version = Update-ModVersion -ModTxtPath $modTxt
	}

	if (-not $version) {
		$version = Get-CurrentModVersion -ModTxtPath $modTxt
	}

	$zipPath = Join-Path $ModsDir "$($folder.Name).vmz"
	New-ModZip -SourceDir $folder.FullName -ZipPath $zipPath -ModId $folder.Name

	if ($version) {
		Write-Host "built: $($folder.Name) v$version -> $zipPath"
	} else {
		Write-Host "built: $($folder.Name) -> $zipPath"
	}
}

if ($Launch) {
	$gameDir = Split-Path -Parent $ModsDir
	$exePath = Join-Path $gameDir 'RTV.exe'
	if (-not (Test-Path -LiteralPath $exePath)) {
		throw "Game executable not found: $exePath"
	}
	Write-Host "launching: $exePath"
	Start-Process -FilePath $exePath -WorkingDirectory $gameDir -RedirectStandardOutput 'NUL'
	#cmd.exe /c "start `"`" /D `"$gameDir`" `"$exePath`"" *>$null
}

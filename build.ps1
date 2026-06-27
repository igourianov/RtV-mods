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
		$ModsDir = Join-Path $config.game.dir 'mods'
	}
}

if (-not $ModsDir) {
	throw "ModsDir not specified. Pass -ModsDir <path> or create '$configPath' with:`n{`n  `"game`": { `"dir`": `"D:\\SteamLibrary\\steamapps\\common\\Road to Vostok`" }`n}"
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

function Get-AutoloadScripts {
	param([string]$ModTxtPath, [string]$ModId)

	$content = [System.IO.File]::ReadAllText($ModTxtPath)
	$section = [regex]::Match($content, '(?ms)^\[autoload\]\s*(.*?)(?=^\[|\Z)')
	if (-not $section.Success) {
		return @()
	}

	$paths = @()
	foreach ($entry in [regex]::Matches($section.Groups[1].Value, '=\s*"([^"]+)"')) {
		$resPath = $entry.Groups[1].Value
		$prefix = "res://mods/$ModId/"
		if ($resPath.StartsWith($prefix)) {
			$paths += $resPath.Substring($prefix.Length)
		}
	}
	return $paths
}

function Test-ModUsesLib {
	param([string]$SourceDir, [string]$ModId)

	$modTxt = Join-Path $SourceDir 'mod.txt'
	foreach ($rel in (Get-AutoloadScripts -ModTxtPath $modTxt -ModId $ModId)) {
		$scriptPath = Join-Path $SourceDir ($rel -replace '/', '\')
		if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
			continue
		}
		$scriptContent = [System.IO.File]::ReadAllText($scriptPath)
		$extends = [regex]::Match($scriptContent, '(?m)^\s*extends\s+"([^"]+)"')
		if ($extends.Success -and $extends.Groups[1].Value -match 'Lib/Main\.gd$') {
			return $true
		}
	}
	return $false
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

			# Add to archive root if mod.txt or .md file
			if ($relative -eq 'mod.txt' -or $relative -match '\.md$') {
				[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $relative, $level) | Out-Null
			}

			# Add to mods/<mod-id>/ if mod.txt or not a .md file
			if ($relative -eq 'mod.txt' -or $relative -notmatch '\.md$') {
				$entry = "mods/$ModId/$relative"
				[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $entry, $level) | Out-Null
			}
		}

		# Include mod-lib folder only if the mod's Main inherits from it
		$modLibPath = Join-Path $repoRoot 'mod-lib'
		$usesLib = Test-ModUsesLib -SourceDir $SourceDir -ModId $ModId
		if ($usesLib -and (Test-Path -LiteralPath $modLibPath -PathType Container)) {
			$modLibFull = (Resolve-Path -LiteralPath $modLibPath).Path.TrimEnd('\')
			$modLibPrefixLen = $modLibFull.Length + 1
			Get-ChildItem -LiteralPath $modLibFull -Recurse -File | ForEach-Object {
				$relative = $_.FullName.Substring($modLibPrefixLen).Replace('\', '/')
				$entry = "mods/$ModId/Lib/$relative"
				[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $entry, $level) | Out-Null
			}
		}
	} finally {
		$zip.Dispose()
	}

	return $usesLib
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
	$usedLib = New-ModZip -SourceDir $folder.FullName -ZipPath $zipPath -ModId $folder.Name

	$libNote = if ($usedLib) { '' } else { ' (no lib)' }
	if ($version) {
		Write-Host "built: $($folder.Name) v$version$libNote -> $zipPath"
	} else {
		Write-Host "built: $($folder.Name)$libNote -> $zipPath"
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

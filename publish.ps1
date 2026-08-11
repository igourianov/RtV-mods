#Requires -Version 5.1
[CmdletBinding()]
param(
	[string]$Mod,
	[string]$Vmz,
	[string]$ApiKey,
	[ValidateSet('main', 'optional', 'miscellaneous')]
	[string]$Category,
	[switch]$NoArchive,
	[switch]$NoBumpModVersion,
	[switch]$Force,
	[switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

trap {
	[Console]::Error.WriteLine($_.Exception.Message)
	exit 1
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$apiRoot = 'https://api.nexusmods.com/v3'
$maxSizeBytes = 100MB

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-ApiKey {
	if ($ApiKey) {
		return $ApiKey
	}

	$keyPath = Join-Path $repoRoot 'nexus-api.key'
	if (-not (Test-Path -LiteralPath $keyPath -PathType Leaf)) {
		throw "No API key. Create '$keyPath' containing your personal key from https://www.nexusmods.com/settings/api-keys, or pass -ApiKey."
	}

	$key = [System.IO.File]::ReadAllText($keyPath).Trim()
	if (-not $key) {
		throw "'$keyPath' is empty."
	}
	return $key
}

function Get-ArchiveEntryText {
	param([string]$ZipPath, [string]$EntryName)

	$zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
	try {
		$entry = $zip.GetEntry($EntryName)
		if (-not $entry) {
			return $null
		}
		$reader = New-Object System.IO.StreamReader($entry.Open())
		try {
			return $reader.ReadToEnd()
		} finally {
			$reader.Dispose()
		}
	} finally {
		$zip.Dispose()
	}
}

function Get-ModInfo {
	param([string]$ZipPath)

	$content = Get-ArchiveEntryText -ZipPath $ZipPath -EntryName 'mod.txt'
	if (-not $content) {
		throw "No mod.txt at the root of '$ZipPath'."
	}

	$info = @{}
	foreach ($key in @('id', 'version')) {
		$m = [regex]::Match($content, "(?m)^$key\s*=\s*`"([^`"]+)`"")
		if (-not $m.Success) {
			throw "mod.txt in '$ZipPath' has no $key entry."
		}
		$info[$key] = $m.Groups[1].Value
	}
	return $info
}

function New-VmzWrapper {
	param([string]$VmzPath, [string]$ZipPath, [string]$EntryName)

	if (Test-Path -LiteralPath $ZipPath) {
		Remove-Item -LiteralPath $ZipPath -Force
	}

	# The vmz is already deflated, so recompressing it only burns time.
	$zip = [System.IO.Compression.ZipFile]::Open($ZipPath, [System.IO.Compression.ZipArchiveMode]::Create)
	try {
		[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $VmzPath, $EntryName, [System.IO.Compression.CompressionLevel]::NoCompression) | Out-Null
	} finally {
		$zip.Dispose()
	}
}

function Get-ProblemDetail {
	param($ErrorRecord)

	$response = $ErrorRecord.Exception.Response
	if (-not $response) {
		return $ErrorRecord.Exception.Message
	}

	$reader = New-Object System.IO.StreamReader($response.GetResponseStream())
	try {
		$body = $reader.ReadToEnd()
	} finally {
		$reader.Dispose()
	}

	if (-not $body) {
		return $ErrorRecord.Exception.Message
	}
	return "$([int]$response.StatusCode) $body"
}

function Invoke-NexusApi {
	param([string]$Method, [string]$Path, $Body)

	$request = @{
		Method  = $Method
		Uri     = "$apiRoot$Path"
		Headers = @{ apikey = $script:apiKey }
	}
	if ($Body) {
		$request.Body = ($Body | ConvertTo-Json -Depth 4 -Compress)
		$request.ContentType = 'application/json'
	}

	try {
		$response = Invoke-RestMethod @request
	} catch {
		throw "$Method $Path failed: $(Get-ProblemDetail $_)"
	}
	return $response.data
}

function Assert-NewerVersion {
	param([string]$FileId, [string]$Version)

	$live = (Invoke-NexusApi -Method Get -Path "/mod-files/$FileId/versions").versions |
		Where-Object { $_.category -notin @('archived', 'old_version', 'removed') } |
		Select-Object -First 1
	if (-not $live) {
		return
	}

	if ($live.version -eq $Version) {
		throw "$Version is already published on mod file $FileId. Bump the version or pass -Force."
	}

	$published = New-Object Version
	$staged = New-Object Version
	if ([Version]::TryParse($live.version, [ref]$published) -and [Version]::TryParse($Version, [ref]$staged) -and $staged -lt $published) {
		throw "$Version is older than the published $($live.version). Pass -Force to publish it anyway."
	}

	Write-Host "replacing: $($live.version) -> $Version"
}

function Send-UploadData {
	param([string]$PresignedUrl, [string]$FilePath, [string]$Filename)

	# Both headers are part of the presigned signature and must match exactly.
	$headers = @{ 'Content-Disposition' = "attachment; filename=`"$Filename`"" }
	try {
		Invoke-WebRequest -Method Put -Uri $PresignedUrl -InFile $FilePath -Headers $headers -ContentType 'application/octet-stream' -UseBasicParsing | Out-Null
	} catch {
		throw "Upload of '$FilePath' failed: $(Get-ProblemDetail $_)"
	}
}

function Wait-UploadAvailable {
	param([string]$UploadId, [string]$State)

	$attempts = 0
	while ($State -ne 'available') {
		if ($attempts -ge 60) {
			throw "Upload $UploadId is still '$State' after 2 minutes."
		}
		Start-Sleep -Seconds 2
		$attempts++
		$State = (Invoke-NexusApi -Method Get -Path "/uploads/$UploadId").state
	}
}

if ($Vmz) {
	if (-not (Test-Path -LiteralPath $Vmz -PathType Leaf)) {
		throw "Archive not found: $Vmz"
	}
	$archivePath = (Resolve-Path -LiteralPath $Vmz).Path
} elseif ($Mod) {
	$buildConfigPath = Join-Path $repoRoot 'build.config.json'
	if (-not (Test-Path -LiteralPath $buildConfigPath)) {
		throw "Cannot resolve the built archive: '$buildConfigPath' is missing. Pass -Vmz <path> instead."
	}
	$buildConfig = Get-Content -LiteralPath $buildConfigPath -Raw | ConvertFrom-Json
	$archivePath = Join-Path (Join-Path $buildConfig.game.dir 'mods') "$Mod.vmz"
	if (-not (Test-Path -LiteralPath $archivePath -PathType Leaf)) {
		throw "Archive not found: $archivePath. Run build.ps1 -Mod $Mod first."
	}
} else {
	throw "Specify -Mod <mod-id> or -Vmz <path>."
}

$configPath = Join-Path $repoRoot 'publish.config.json'
if (-not (Test-Path -LiteralPath $configPath)) {
	throw "Missing '$configPath'."
}
$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json

$modInfo = Get-ModInfo -ZipPath $archivePath
$modId = $modInfo.id
$version = $modInfo.version

$entry = $config.mods.PSObject.Properties[$modId]
if (-not $entry) {
	throw "No entry for '$modId' in '$configPath'."
}
$settings = $entry.Value
$fileId = $settings.file_id
if (-not $fileId) {
	throw "No file_id for '$modId' in '$configPath'. Take it from the mod's file URL on Nexus."
}

$fileName = "$modId.vmz"
$fileCategory = if ($Category) { $Category } elseif ($settings.category) { $settings.category } else { 'main' }
$bumpModVersion = if ($NoBumpModVersion) { $false } elseif ($null -ne $settings.update_mod_version) { [bool]$settings.update_mod_version } else { $true }

if ($version -notmatch '^[a-zA-Z0-9.-]+\z' -or $version.Length -gt 50) {
	throw "Version '$version' is rejected by Nexus. Allowed: letters, digits and .- up to 50 chars."
}

if (-not $DryRun) {
	$script:apiKey = Get-ApiKey
	if (-not $Force) {
		Assert-NewerVersion -FileId $fileId -Version $version
	}
}

$uploadName = "$modId.zip"
$stagePath = Join-Path $env:TEMP $uploadName
New-VmzWrapper -VmzPath $archivePath -ZipPath $stagePath -EntryName "$modId.vmz"

$sizeBytes = (Get-Item -LiteralPath $stagePath).Length
if ($sizeBytes -gt $maxSizeBytes) {
	throw "'$uploadName' is $([math]::Round($sizeBytes / 1MB, 1)) MiB. Files over 100 MiB need a multipart upload, which this script does not implement."
}

$versionRequest = @{
	upload_id                    = $null
	name                         = $fileName
	version                      = $version
	file_category                = $fileCategory
	archive_existing_file        = (-not $NoArchive)
	update_mod_version           = $bumpModVersion
	primary_mod_manager_download = ($fileCategory -eq 'main')
}

Write-Host "publishing: $modId v$version -> mod file $fileId ($fileCategory, $uploadName, $([math]::Round($sizeBytes / 1MB, 2)) MiB)"

if ($DryRun) {
	Write-Host "dry run, POST /mod-files/$fileId/versions would send:"
	Write-Host ($versionRequest | ConvertTo-Json -Depth 4)
	return
}

$upload = Invoke-NexusApi -Method Post -Path '/uploads' -Body @{ size_bytes = $sizeBytes; filename = $uploadName }
Send-UploadData -PresignedUrl $upload.presigned_url -FilePath $stagePath -Filename $uploadName

$finalised = Invoke-NexusApi -Method Post -Path "/uploads/$($upload.id)/finalise"
Wait-UploadAvailable -UploadId $upload.id -State $finalised.state

$versionRequest.upload_id = $upload.id
$created = Invoke-NexusApi -Method Post -Path "/mod-files/$fileId/versions" -Body $versionRequest

Write-Host "published: version $($created.version.id)"
if ($settings.mod_id) {
	Write-Host "https://www.nexusmods.com/$($config.nexus.game)/mods/$($settings.mod_id)"
}

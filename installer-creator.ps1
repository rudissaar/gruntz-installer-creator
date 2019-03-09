<#
 .SYNOPSIS

  Runs tasks to generate Monolith's Gruntz (1999) installer for Windows 8+.

 .DESCRIPTION

  This scripts tries to convert Gruntz ISO file to installer that is compatible with Microsoft Windows 8, 8.1 and 10.

  Requirements:
  - Windows PowerShell 4.0 or higher.
  - Qt Installer Framework 3.0 or higher

 .PARAMETER Iso

  Path to Gruntz ISO file.
  Default, gruntz.iso
#>

[CmdletBinding()]
Param(
    $Media = 'gruntz.iso'
)

Set-StrictMode -Version 3

$CompressInstallerIfPossible = 1

$7zipFallback = ''
$BinaryCreatorFallback = ''
$UpxFallback = ''

$GruntzDataOutputDir = 'packages/eu.murda.gruntz/data'
$DdrawDataOutputDir = 'packages/eu.murda.gruntz.ddraw/data/GAME'
$PatchDataOutputDir = 'packages/eu.murda.gruntz.patch/data/GAME'
$EditorDataOutputDir = 'packages/eu.murda.gruntz.editor.editor/data'
$SamplesDataOutputDir = 'packages/eu.murda.gruntz.editor.samples/data/GAME/CUSTOM'

$CustomLevelForklandDataOutputDir = 'packages/eu.murda.gruntz.custom.multiplayer.forkland/data/GAME/CUSTOM'

$DdrawDownloadUrl = 'https://github.com/narzoul/DDrawCompat/releases/download/v0.2.1/ddraw.zip'
$DdrawArchiveName = 'tmp/' + (Split-Path $DdrawDownloadUrl -Leaf)

$PatchDownloadUrl = 'http://legacy.murda.eu/downloads/misc/gruntz-patch.zip'
$PatchArchiveName = 'tmp/' + (Split-Path $PatchDownloadUrl -Leaf)

$EditorDownloadUrl = 'http://legacy.murda.eu/downloads/tools/gruntz-editor.zip'
$EditorArchiveName = 'tmp/' + (Split-Path $EditorDownloadUrl -Leaf)

$SamplesDownloadUrl = 'http://legacy.murda.eu/downloads/misc/gruntz-sample-levels.zip'
$SamplesArchiveName = 'tmp/' + (Split-Path $SamplesDownloadUrl -Leaf)

$CustomLevelForklandDownloadUrl = 'http://legacy.murda.eu/downloads/misc/gruntz-battlez-forkland.zip'
$CustomLevelForklandArchiveName = 'tmp/' + (Split-Path $CustomLevelForklandDownloadUrl -Leaf)

function Main
{
    If ((Get-7zip) -Eq 1) {
        Write-Output "> Unable to find 7z.exe from your environment's PATH variable."
        Write-Output '> Aborting.'
        Exit(1)
    }

    Write-Output "> 7zip binary found at: '$(Get-7zip)'"

    If ((Get-BinaryCreator) -Eq 1) {
        Write-Output "> Unable to find binarycreator.exe from your environment's PATH variable."
        Write-Output '> Aborting.'
        Exit(1)
    }

    Write-Output "> BinaryCreator binary found at: '$(Get-BinaryCreator)'"

    If (-Not ((Test-Media $Media) -Eq 0)) {
        If ((Test-Media $Media) -Eq 1) {
            Write-Output "> Specified ISO file doesn't exist on your filesystem."
        }

        If ((Test-Media $Media) -Eq 2) {
            Write-Output "> Specified ISO file doesn't match with required fingerprint."
        }

        Write-Output '> Aborting.'
        Exit(1)
    }

    If ((Create-Directory $GruntzDataOutputDir) -Eq 0) {
        Write-Output "> Created directory: '$GruntzDataOutputDir'."
    }

    If ((Create-Directory $DdrawDataOutputDir) -Eq 0) {
        Write-Output "> Created directory: '$DdrawDataOutputDir'."
    }

    Expand-Media $Media
    Remove-UselessFiles
    Rename-Files
    Import-Ddraw
    Import-Patch
    Import-Editor
    Import-Samples

    Import-CustomLevelForkland

    Build-Installer
    Compress-Installer
}

Function Create-Directory ([string] $Directory)
{
    If (-Not (Test-Path -PathType Container $Directory)) {
        [void] (New-Item -Path $Directory -ItemType Directory)
        Return 0
    }

    Return 1
}

Function Get-7zip
{
    If (Get-Command '7z.exe' -ErrorAction SilentlyContinue) {
        Return (Get-Command '7z.exe' | Select -ExpandProperty Source)
    } Else {
        If (-Not ([string]::IsNullOrEmpty($7zipFallback))) {
            Return $7zipFallback
        }
    }

    Return 1
}

Function Get-BinaryCreator
{
    If (Get-Command 'binarycreator.exe' -ErrorAction SilentlyContinue) {
        Return (Get-Command 'binarycreator.exe' | Select -ExpandProperty Source)
    } Else {
        If (-Not ([string]::IsNullOrEmpty($BinaryCreatorFallback))) {
            Return $BinaryCreatorFallback
        }
    }

    Return 1
}

Function Get-Upx
{
    If (Get-Command 'upx.exe' -ErrorAction SilentlyContinue) {
        Return (Get-Command 'upx.exe' | Select -ExpandProperty Source)
    } Else {
        If (-Not ([string]::IsNullOrEmpty($UpxFallback))) {
            Return $UpxFallback
        }
    }

    Return 1
}

Function Test-Media ([string] $Path)
{
    $ValidHashes = @(
        '275547756A472DA85298F7B86FBAF197'
    )

    If (-Not (Test-Path -PathType Leaf $Path)) {
        Return 1
    }

    $Hash = Get-FileHash -Algorithm MD5 $Path | Select -ExpandProperty Hash

    If (-Not ($ValidHashes.Contains($Hash))) {
        Return 2
    }

    Return 0
}

Function Expand-Media ([string] $Media)
{
    & (Get-7zip) 'x' '-aoa' "-o$GruntzDataOutputDir" $Media
}

Function Remove-UselessFiles
{
    $UselessFiles = @(
        'AUTORUN.EXE',
        'AUTORUN.INF',
        'CDTEST.EXE',
        'PREVIEWS',
        'PREVIEW.EXE',
        '_SETUP.DLL',
        '_SETUP.LIB',
        'SETUP.EXE',
        'SETUP.INS',
        'SETUP.PKG',
        'UNINST.EXE'
    )

    Foreach ($UselessFile In $UselessFiles)
    {
        $UselessFilePath = "$GruntzDataOutputDir/$UselessFile"

        If (Test-Path -PathType Any $UselessFilePath) {
            Remove-Item -Recurse -Force $UselessFilePath
        }
    }
}

Function Rename-Files
{
    If (Test-Path -PathType Leaf "$GruntzDataOutputDir/AUTORUN.ICO") {
        Move-Item -Force -Path "$GruntzDataOutputDir/AUTORUN.ICO" -Destination "$GruntzDataOutputDir/GRUNTZ.ICO"
    }
}

Function Import-Ddraw
{
    If (-Not (Test-Path -PathType Leaf $DdrawArchiveName)) {
        Try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest $DdrawDownloadUrl -OutFile $DdrawArchiveName
        } Catch {
            $_
        }
    }

    If (Test-Path -PathType Leaf $DdrawArchiveName) {
        & (Get-7zip) 'x' '-aoa' "-o$DdrawDataOutputDir" $DdrawArchiveName
    }

    If (Test-Path -PathType Leaf "$DdrawDataOutputDir/license.txt") {
        Move-Item -Force -Path "$DdrawDataOutputDir/license.txt" -Destination "$DdrawDataOutputDir/ddraw-license.txt"
    }
}

Function Import-Patch
{
    If (-Not (Test-Path -PathType Leaf $PatchArchiveName)) {
        Try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest $PatchDownloadUrl -OutFile $PatchArchiveName
        } Catch {
            $_
        }
    }

    If (Test-Path -PathType Leaf $PatchArchiveName) {
        & (Get-7zip) 'x' '-aoa' "-o$PatchDataOutputDir" $PatchArchiveName
    }
}

Function Import-Editor
{
    If (-Not (Test-Path -PathType Leaf $EditorArchiveName)) {
        Try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest $EditorDownloadUrl -OutFile $EditorArchiveName
        } Catch {
            $_
        }
    }

    If (Test-Path -PathType Leaf $EditorArchiveName) {
        & (Get-7zip) 'x' '-aoa' "-o$EditorDataOutputDir" $EditorArchiveName
    }
}

Function Import-Samples
{
    If (-Not (Test-Path -PathType Leaf $SamplesArchiveName)) {
        Try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest $SamplesDownloadUrl -OutFile $SamplesArchiveName
        } Catch {
            $_
        }
    }

    If (Test-Path -PathType Leaf $SamplesArchiveName) {
        & (Get-7zip) 'x' '-aoa' "-o$SamplesDataOutputDir" $SamplesArchiveName
    }
}

Function Import-CustomLevelForkland
{
    If (-Not (Test-Path -PathType Leaf $CustomLevelForklandArchiveName)) {
        Try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest $CustomLevelForklandDownloadUrl -OutFile $CustomLevelForklandArchiveName
        } Catch {
            $_
        }
    }

    If (Test-Path -PathType Leaf $CustomLevelForklandArchiveName) {
        & (Get-7zip) 'x' '-aoa' "-o$CustomLevelForklandDataOutputDir" $CustomLevelForklandArchiveName
    }
}

Function Build-Installer
{
    & (Get-BinaryCreator) '-c' 'config/config.xml' '-p' 'packages' 'GruntzInstaller.exe'
}

Function Compress-Installer
{
    If ($CompressInstallerIfPossible -And (-Not ((Get-Upx) -Eq 1))) {
        If (Test-Path -PathType Leaf 'GruntzInstaller.exe') {
            Write-Output "> Compressing Installer to save disk space."
            & (Get-Upx) '-9' 'GruntzInstaller.exe'
        }
    }
}

. Main

<#
 .SYNOPSIS

  Runs tasks to generate Monolith's Gruntz (1999) installer for Windows 7+.

 .DESCRIPTION

  This scripts tries to convert Gruntz ISO file to installer that is compatible with Microsoft Windows 7, 8, 8.1 and 10.

  Requirements:
  - Windows PowerShell 4.0 or higher.
  - Qt Installer Framework 3.0 or higher
  - 7-Zip
  - UPX (Optional)

 .PARAMETER Iso

  Path to Gruntz ISO file.
  Default, gruntz.iso
#>

[CmdletBinding()]
Param(
    $Media = 'gruntz.iso'
)

Set-StrictMode -Version 3

$InstallerName = 'dist/gruntz-installer'
$InstallerExtension = '.exe'

$ExcludeMovies = 0

$CrackBinariesIfPossible = 1
$CompressInstallerIfPossible = 1

$7zipFallback = ''
$BinaryCreatorFallback = ''
$UpxFallback = ''

$GruntzDataOutputDir = 'packages/eu.murda.gruntz/data'
$GruntzDataMoviesOutputDir = 'packages/eu.murda.gruntz.movies/data'

$DdrawDataOutputDir = 'packages/eu.murda.gruntz.ddraw/data'
$PatchDataOutputDir = 'packages/eu.murda.gruntz.patch/data'
$EditorDataOutputDir = 'packages/eu.murda.gruntz.editor.editor/data'
$SamplesDataOutputDir = 'packages/eu.murda.gruntz.editor.samples/data/CUSTOM'

$CustomLevelForklandDataOutputDir = 'packages/eu.murda.gruntz.custom.battles.forkland/data/CUSTOM'
$CustomLevelDirtlandDataOutputDir = 'packages/eu.murda.gruntz.custom.battles.dirtland/data/CUSTOM'

$DdrawDownloadUrl = 'http://legacy.murda.eu/downloads/gruntz/gruntz-ddraw.zip'
$DdrawArchiveName = 'tmp/' + (Split-Path $DdrawDownloadUrl -Leaf)

$PatchDownloadUrl = 'http://legacy.murda.eu/downloads/gruntz/gruntz-patch.zip'
$PatchArchiveName = 'tmp/' + (Split-Path $PatchDownloadUrl -Leaf)

$EditorDownloadUrl = 'http://legacy.murda.eu/downloads/gruntz/gruntz-editor.zip'
$EditorArchiveName = 'tmp/' + (Split-Path $EditorDownloadUrl -Leaf)

$SamplesDownloadUrl = 'http://legacy.murda.eu/downloads/gruntz/gruntz-sample-levels.zip'
$SamplesArchiveName = 'tmp/' + (Split-Path $SamplesDownloadUrl -Leaf)

$CustomLevelForklandDownloadUrl = 'http://legacy.murda.eu/downloads/gruntz/gruntz-battlez-forkland.zip'
$CustomLevelForklandArchiveName = 'tmp/' + (Split-Path $CustomLevelForklandDownloadUrl -Leaf)

$CustomLevelDirtlandDownloadUrl = 'http://legacy.murda.eu/downloads/gruntz/gruntz-battlez-dirtland.zip'
$CustomLevelDirtlandArchiveName = 'tmp/' + (Split-Path $CustomLevelDirtlandDownloadUrl -Leaf)

$DirectoriesToMergeIntoRoot = @(
    'GAME',
    'DATA',
    'FONTS'
)

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

    Clear-DataOutputDirs

    If ((Create-Directory $GruntzDataMoviesOutputDir) -Eq 0) {
        Write-Output "> Created directory: '$GruntzDataOutputDir'."
    }

    If ((Create-Directory $GruntzDataMoviesOutputDir) -Eq 0) {
        Write-Output "> Created directory: '$GruntzDataMoviesOutputDir'."
    }

    Expand-Media $Media
    Remove-UselessFiles
    Rename-Files

    Import-Ddraw
    Import-Patch
    Import-Editor
    Import-Samples

    Import-CustomLevelForkland
    Import-CustomLevelDirtland

    Convert-Binaries
    Build-Installer
    Compress-Installer
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
        } Else {
            If ($CompressInstallerIfPossible) {
                Write-Output "> Unable to find upx.exe from your environment's PATH variable."
                echo '> Compressing installer will be skipped.'
            }
        }
    }

    Return 1
}

Function Create-Directory ([string] $Directory)
{
    If (-Not (Test-Path -PathType Container $Directory)) {
        [void] (New-Item -Path $Directory -ItemType Directory)
        Return 0
    }

    Return 1
}

Function Clear-DataOutputDirs
{
    $DataOutputDirs = (Get-ChildItem -Path 'packages' -Filter 'data' -Recurse -Directory).Fullname

    Foreach ($DataOutputDir In $DataOutputDirs) {
        If (Test-Path -PathType Any $DataOutputDir) {
            Remove-Item -Recurse -Force $DataOutputDir
        }
    }
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

    Copy-Item -Force 'compatibility.bat' -Destination $GruntzDataOutputDir

    If (Test-Path -PathType Container "$GruntzDataOutputDir/MOVIEZ") {
        Move-Item -Force -Path "$GruntzDataOutputDir/MOVIEZ" -Destination $GruntzDataMoviesOutputDir
    }

    Foreach ($DirectoryToMerge In $DirectoriesToMergeIntoRoot) {
        $DirectoryPath = "$GruntzDataOutputDir/$DirectoryToMerge"

        If (Test-Path -PathType Container $DirectoryPath) {
            Get-ChildItem -Path $DirectoryPath -Recurse | Move-Item -Force -Destination $GruntzDataOutputDir
        }
    }
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
        'UNINST.EXE',
        '_INST32I.EX_',
        '_ISDEL.EXE',
        '_ISRES.DLL',
        'GRUNTZ.HLP',
        'GRUNTZ.URL',
        'REGISTER.URL',
        'REDIST',
        'SYSTEM',
        'MOVIEZ'
    )

    $UselessFiles += $DirectoriesToMergeIntoRoot

    Foreach ($UselessFile In $UselessFiles) {
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

Function Import-CustomLevelDirtland
{
    If (-Not (Test-Path -PathType Leaf $CustomLevelDirtlandArchiveName)) {
        Try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest $CustomLevelDirtlandDownloadUrl -OutFile $CustomLevelDirtlandArchiveName
        } Catch {
            $_
        }
    }

    If (Test-Path -PathType Leaf $CustomLevelDirtlandArchiveName) {
        & (Get-7zip) 'x' '-aoa' "-o$CustomLevelDirtlandDataOutputDir" $CustomLevelDirtlandArchiveName
    }
}

Function Convert-Binaries
{
    If (-Not ($CrackBinariesIfPossible)) {
        Return
    }

    $ValidGruntzHashes = @(
        '81C7F648DB99501BED6E1EE71E66E4A0'
    )

    $GruntzHash = Get-FileHash -Algorithm MD5 "$GruntzDataOutputDir/GRUNTZ.EXE" | Select -ExpandProperty Hash

    If ($ValidGruntzHashes.Contains($GruntzHash)) {
        Write-Output "> Cracking $GruntzDataOutputDir/GRUNTZ.EXE"

        Try {
            [Byte[]] $Bytes = Get-Content "$GruntzDataOutputDir/GRUNTZ.EXE" -Encoding Byte

            $Bytes[0x0001F4CC] = 0x2E
            $Bytes[0x0001F4A1] = 0xEB
            $Bytes[0x0001F4F3] = 0x90
            $Bytes[0x0001F4F4] = 0x90
            $Bytes[0x0020AE86] = 0x5C
            $Bytes[0x0020AE9E] = 0x5C
            $Bytes[0x0020AEA1] = 0x52
            $Bytes[0x0020AEA2] = 0x55
            $Bytes[0x0020AEA3] = 0x4E
            $Bytes[0x0020AEA4] = 0x54
            $Bytes[0x0020AEA5] = 0x5A
            $Bytes[0x0020AEA6] = 0x2E
            $Bytes[0x0020AEA7] = 0x45
            $Bytes[0x0020AEA8] = 0x58
            $Bytes[0x0020AEA9] = 0x45
            $Bytes[0x0020AEAA] = 0x00
            $Bytes[0x0020AEAB] = 0x00
            $Bytes[0x0020AEAC] = 0x00
            $Bytes[0x0020AEAD] = 0x00
            $Bytes[0x0020AEAE] = 0x00
            $Bytes[0x0020F4BA] = 0x5C
            $Bytes[0x0020F826] = 0x5C
            $Bytes[0x0020F856] = 0x5C
            $Bytes[0x00212692] = 0x5C
            $Bytes[0x002126AE] = 0x5C

            $Bytes | Set-Content "$GruntzDataOutputDir/GRUNTZ.EXE" -Encoding Byte
        } Catch {
            $_
        }
    }

    $PatchValidHashes = @(
        '199D4613E4587E1D720623DC11569E4D'
    )

    $PatchHash = Get-FileHash -Algorithm MD5 "$PatchDataOutputDir/GRUNTZ.EXE" | Select -ExpandProperty Hash

    If ($PatchValidHashes.Contains($PatchHash)) {
        Write-Output "> Cracking $PatchDataOutputDir/GRUNTZ.EXE"

        Try {
            [Byte[]] $Bytes = Get-Content "$PatchDataOutputDir/GRUNTZ.EXE" -Encoding Byte

            $Bytes[0x0001F4DC] = 0x2E
            $Bytes[0x0001F4B1] = 0xEB
            $Bytes[0x0001F503] = 0x90
            $Bytes[0x0001F504] = 0x90
            $Bytes[0x0020B286] = 0x5C
            $Bytes[0x0020B29E] = 0x5C
            $Bytes[0x0020B2A1] = 0x52
            $Bytes[0x0020B2A2] = 0x55
            $Bytes[0x0020B2A3] = 0x4E
            $Bytes[0x0020B2A4] = 0x54
            $Bytes[0x0020B2A5] = 0x5A
            $Bytes[0x0020B2A6] = 0x2E
            $Bytes[0x0020B2A7] = 0x45
            $Bytes[0x0020B2A8] = 0x58
            $Bytes[0x0020B2A9] = 0x45
            $Bytes[0x0020B2AA] = 0x00
            $Bytes[0x0020B2AB] = 0x00
            $Bytes[0x0020B2AC] = 0x00
            $Bytes[0x0020B2AD] = 0x00
            $Bytes[0x0020B2AE] = 0x00
            $Bytes[0x0020F862] = 0x5C
            $Bytes[0x0020FBCE] = 0x5C
            $Bytes[0x0020FBFE] = 0x5C
            $Bytes[0x002129F2] = 0x5C
            $Bytes[0x00212A0E] = 0x5C

            $Bytes | Set-Content "$PatchDataOutputDir/GRUNTZ.EXE" -Encoding Byte
        } Catch {
            $_
        }
    }
}

Function Build-Installer
{
    Write-Output "> Creating installer."

    $Params = @(
        '--offline-only',
        '-c', 'config/config.xml',
        '-p', 'packages'
    )

    If ($ExcludeMovies) {
        $Params += '-e', 'eu.murda.gruntz.movies'
        $InstallerName = ("$InstallerName" +'-no-movie')
    }

    $InstallerName = ("$InstallerName" + $InstallerExtension)
    $Params += "$InstallerName"

    & (Get-BinaryCreator) $Params
}

Function Compress-Installer
{
    If ($CompressInstallerIfPossible -And (-Not ((Get-Upx) -Eq 1))) {
        If (Test-Path -PathType Leaf "$InstallerName") {
            Write-Output "> Compressing Installer to save disk space."
            & (Get-Upx) '-9' "$InstallerName"
        }
    }
}

. Main

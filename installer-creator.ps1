<#
 .SYNOPSIS

  Runs tasks to generate Monolith's Gruntz (1999) installer for Windows 7+.

 .DESCRIPTION

  This scripts tries to convert Gruntz ISO file to an installer that is compatible with Microsoft Windows 7, 8, 8.1 and 10.

 .REQUIREMENTS
  - Windows PowerShell 4.0 or higher
  - Qt Installer Framework 3.0 or higher
  - 7-Zip
  - UPX (Optional)

 .PARAMETER Iso

  Path to Gruntz ISO file.
  Default, gruntz.iso
#>

[CmdletBinding()]
Param(
    $Global:Media = "${PSScriptRoot}\gruntz.iso"
)

Set-StrictMode -Version 3

$Global:InstallerName = "${PSScriptRoot}\dist\gruntz-installer"
$Global:InstallerExtension = '.exe'

$Global:ExcludeMovies = $Null # Defaults to 0.
$Global:UseDgVoodooDdraw = $Null # Defaults to 0.

$Global:CrackBinariesIfPossible = $Null # Defaults to 1.
$Global:UseOriginalCrack = $Null # Defaults to 0.
$Global:CompressInstallerIfPossible = $Null  # Defaults to 1.

$Global:7zipFallback = ''
$Global:BinaryCreatorFallback = ''
$Global:UpxFallback = ''

$GruntzDataOutputDir = "${PSScriptRoot}\packages\eu.murda.gruntz\data"
$GruntzDataMoviesOutputDir = "${PSScriptRoot}\packages\eu.murda.gruntz.movies\data"

$DdrawDataOutputDir = "${PSScriptRoot}\packages\eu.murda.gruntz.ddraw\data"
$DgVoodooDdrawOutputDir = "${PSScriptRoot}\packages\eu.murda.gruntz.dgvoodoo.ddraw\data"
$PatchDataOutputDir = "${PSScriptRoot}\packages\eu.murda.gruntz.patch\data"
$EditorDataOutputDir = "${PSScriptRoot}\packages\eu.murda.gruntz.editor.editor\data"
$SamplesDataOutputDir = "${PSScriptRoot}\packages\eu.murda.gruntz.editor.samples\data\CUSTOM"

$CustomLevelForklandDataOutputDir = "${PSScriptRoot}\packages\eu.murda.gruntz.custom.battles.forkland\data\CUSTOM"
$CustomLevelDirtlandDataOutputDir = "${PSScriptRoot}\packages\eu.murda.gruntz.custom.battles.dirtland\data\CUSTOM"

$DdrawDownloadUrl = 'http://legacy.murda.eu/downloads/gruntz/gruntz-ddraw.zip'
$DdrawArchiveName = "${PSScriptRoot}\tmp\" + (Split-Path $DdrawDownloadUrl -Leaf)

$DgVoodooDdrawDownloadUrl = 'http://legacy.murda.eu/downloads/gruntz/gruntz-dgvoodoo-ddraw.zip'
$DgVoodooDdrawArchiveName = "${PSScriptRoot}\tmp\" + (Split-Path $DgVoodooDdrawDownloadUrl -Leaf)

$PatchDownloadUrl = 'http://legacy.murda.eu/downloads/gruntz/gruntz-patch.zip'
$PatchArchiveName = "${PSScriptRoot}\tmp\" + (Split-Path $PatchDownloadUrl -Leaf)

$EditorDownloadUrl = 'http://legacy.murda.eu/downloads/gruntz/gruntz-editor.zip'
$EditorArchiveName = "${PSScriptRoot}\tmp\" + (Split-Path $EditorDownloadUrl -Leaf)

$SamplesDownloadUrl = 'http://legacy.murda.eu/downloads/gruntz/gruntz-sample-levels.zip'
$SamplesArchiveName = "${PSScriptRoot}\tmp\" + (Split-Path $SamplesDownloadUrl -Leaf)

$CustomLevelForklandDownloadUrl = 'http://legacy.murda.eu/downloads/gruntz/gruntz-battlez-forkland.zip'
$CustomLevelForklandArchiveName = "${PSScriptRoot}\tmp\" + (Split-Path $CustomLevelForklandDownloadUrl -Leaf)

$CustomLevelDirtlandDownloadUrl = 'http://legacy.murda.eu/downloads/gruntz/gruntz-battlez-dirtland.zip'
$CustomLevelDirtlandArchiveName = "${PSScriptRoot}\tmp\" + (Split-Path $CustomLevelDirtlandDownloadUrl -Leaf)

$DirectoriesToMergeIntoRoot = @(
    'GAME',
    'DATA',
    'FONTS'
)

Function Main
{
    Get-MediaFromIniFile
    Get-FallbacksFromIniFile
    Get-SettingsFromIniFile

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

    If (-Not (Get-Upx) -Eq 1) {
        Write-Output "> UPX binary found at: '$(Get-Upx)'"
    }

    If (-Not ((Test-Media $Media) -Eq 0)) {
        If ((Test-Media $Media) -Eq 1) {
            Write-Output "> Specified ISO file doesn't exist on your filesystem."
        }

        If ((Test-Media $Media) -Eq 2) {
            Write-Output "> Specified ISO file doesn't match with the required fingerprint."
        }

        Write-Output '> Aborting.'
        Exit(1)
    }

    Clear-DataOutputDirs

    If ((New-Directory $GruntzDataMoviesOutputDir) -Eq 0) {
        Write-Output "> Created directory: '${GruntzDataOutputDir}'."
    }

    If ((New-Directory $GruntzDataMoviesOutputDir) -Eq 0) {
        Write-Output "> Created directory: '${GruntzDataMoviesOutputDir}'."
    }

    Expand-Media $Media
    Remove-UselessFiles
    Rename-Files

    Import-Ddraw
    Import-DgVoodooDdraw

    Import-Patch
    Import-Editor
    Import-Samples

    Import-CustomLevelForkland
    Import-CustomLevelDirtland

    Convert-Binaries
    Publish-Installer
    Compress-Installer

	Clear-DataOutputDirs
}

Function Get-ValueFromIniFile
{
    Param(
        [parameter(Mandatory = $True)] [string] $Key
    )

    $Ini = @{}

	Switch -Regex -File "${PSScriptRoot}\settings.ini" {
        "^\[(.+)\]$"
        {
            $Section = $Matches[1]
            $Ini[$Section] = @{}
            $CommentCount = 0
        }

        "^(;.*)$"
        {
            If (-Not ($Section)) {
                $Section = 'global'
                $Ini[$Section] = @{}
            }

            $Value = $Matches[1]
            $CommentCount = $CommentCount + 1
            $Name = 'Comment' + $CommentCount
            $Ini[$Section][$Name] = $Value
        }

        "(.+?)\s*=\s*(.*)"
        {
            If (-Not ($Section)) {
                $Section = 'global'
                $Ini[$Section] = @{}
            }

            $Name, $Value = $Matches[1..2]
            $Ini[$Section][$Name] = $Value
        }
    }

	Return $Ini.$Section.$Key
}

Function Get-MediaFromIniFile
{
    If (-Not (Test-Path -PathType Leaf "${PSScriptRoot}\settings.ini")) {
        Return
    }

    $IniMedia = Get-ValueFromIniFile 'media'

    If (-Not [string]::IsNullOrEmpty($IniMedia)) {
        $Global:Media = $IniMedia
    }
}

Function Get-FallbacksFromIniFile
{
    If (-Not (Test-Path -PathType Leaf "${PSScriptRoot}\settings.ini")) {
        Return
    }

    If ([string]::IsNullOrEmpty($7zipFallback)) {
        $Ini7zipFallback = Get-ValueFromIniFile 'windows_7zip_fallback'

        If (-Not [string]::IsNullOrEmpty($Ini7zipFallback)) {
            $7zipFallback = $Ini7zipFallback
        }
    }

    If ([string]::IsNullOrEmpty($BinaryCreatorFallback)) {
        $IniBinaryCreatorFallback = Get-ValueFromIniFile 'windows_binarycreator_fallback'

        If (-Not [string]::IsNullOrEmpty($IniBinaryCreatorFallback)) {
            $BinaryCreatorFallback = $IniBinaryCreatorFallback
        }
    }

    If ([string]::IsNullOrEmpty($UpxFallback)) {
        $IniUpxFallback = Get-ValueFromIniFile 'windows_upx_fallback'

        If (-Not [string]::IsNullOrEmpty($IniUpxFallback)) {
            $UpxFallback = $IniUpxFallback
        }
    }
}

Function Get-SettingsFromIniFile
{
    $IniFileExists = 0

    If (Test-Path -PathType Leaf "${PSScriptRoot}\settings.ini") {
        $IniFileExists = 1
    }

    If ($IniFileExists -And ($ExcludeMovies -Eq $Null)) {
        $IniExcludeMovies = Get-ValueFromIniFile 'windows_exclude_movies'

        If (-Not [string]::IsNullOrEmpty($IniExcludeMovies)) {
            $Global:ExcludeMovies = [int] $IniExcludeMovies
        } Else {
            $Global:ExcludeMovies = 0
        }
    } Else {
        $Global:ExcludeMovies = 0
    }

    If ($IniFileExists -And ($UseDgVoodooDdraw -Eq $Null)) {
        $IniUseDgVoodooDdraw = Get-ValueFromIniFile 'use_dgvoodoo_ddraw'

        If (-Not [string]::IsNullOrEmpty($IniUseDgVoodooDdraw)) {
            $Global:UseDgVoodooDdraw = [int] $IniUseDgVoodooDdraw
        } Else {
            $Global:UseDgVoodooDdraw = 0
        }
    } Else {
        $Global:UseDgVoodooDdraw = 0
    }

    If ($IniFileExists -And ($CrackBinariesIfPossible -Eq $Null)) {
        $IniCrackBinariesIfPossible = Get-ValueFromIniFile 'crack_binaries_if_possible'

        If (-Not [string]::IsNullOrEmpty($IniCrackBinariesIfPossible)) {
            $Global:CrackBinariesIfPossible = [int] $IniCrackBinariesIfPossible
        } Else {
            $Global:CrackBinariesIfPossible = 1
        }
    } Else {
        $Global:CrackBinariesIfPossible = 1
    }

    If ($IniFileExists -And ($UseOriginalCrack -Eq $Null)) {
        $IniUseOriginalCrack = Get-ValueFromIniFile 'use_original_crack'

        If (-Not [string]::IsNullOrEmpty($IniUseOriginalCrack)) {
            $Global:UseOriginalCrack = [int] $IniUseOriginalCrack
        } Else {
            $Global:UseOriginalCrack = 0
        }
    } Else {
        $Global:UseOriginalCrack = 0
    }

    If ($IniFileExists -And ($CompressInstallerIfPossible -Eq $Null)) {
        $IniCompressInstallerIfPossible = Get-ValueFromIniFile 'compress_installer_if_possible'

        If (-Not [string]::IsNullOrEmpty($IniCompressInstallerIfPossible)) {
            $Global:CompressInstallerIfPossible = [int] $IniCompressInstallerIfPossible
        } Else {
            $Global:CompressInstallerIfPossible = 1
        }
    } Else {
        $Global:CompressInstallerIfPossible = 1
    }
}

Function Get-7zip
{
    If (Get-Command '7z.exe' -ErrorAction SilentlyContinue) {
        Return (Get-Command '7z.exe' | Select-Object -ExpandProperty Source)
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
        Return (Get-Command 'binarycreator.exe' | Select-Object -ExpandProperty Source)
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
        Return (Get-Command 'upx.exe' | Select-Object -ExpandProperty Source)
    } Else {
        If (-Not ([string]::IsNullOrEmpty($UpxFallback))) {
            Return $UpxFallback
        } Else {
            If ($CompressInstallerIfPossible) {
                Write-Output "> Unable to find upx.exe from your environment's PATH variable."
                Write-Output '> Compressing the installer will be skipped.'
            }
        }
    }

    Return 1
}

Function New-Directory ([string] $Directory)
{
    If (-Not (Test-Path -PathType Container $Directory)) {
        [void] (New-Item -Path $Directory -ItemType Directory)
        Return 0
    }

    Return 1
}

Function Clear-DataOutputDirs
{
    $DataOutputDirs = (Get-ChildItem -Path "${PSScriptRoot}\packages" -Filter 'data' -Recurse -Directory).Fullname

    ForEach ($DataOutputDir In $DataOutputDirs) {
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

    $Hash = Get-FileHash -Algorithm MD5 $Path | Select-Object -ExpandProperty Hash

    If (-Not ($ValidHashes.Contains($Hash))) {
        Return 2
    }

    Return 0
}

Function Expand-Media ([string] $Media)
{
    & (Get-7zip) 'x' '-aoa' "-o${GruntzDataOutputDir}" $Media

    Copy-Item -Force 'compatibility.bat' -Destination $GruntzDataOutputDir

    If (Test-Path -PathType Container "${GruntzDataOutputDir}\MOVIEZ") {
        Move-Item -Force -Path "${GruntzDataOutputDir}\MOVIEZ" -Destination $GruntzDataMoviesOutputDir
    }

    ForEach ($DirectoryToMerge In $DirectoriesToMergeIntoRoot) {
        $DirectoryPath = "${GruntzDataOutputDir}\${DirectoryToMerge}"

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

    ForEach ($UselessFile In $UselessFiles) {
        $UselessFilePath = "${GruntzDataOutputDir}\${UselessFile}"

        If (Test-Path -PathType Any $UselessFilePath) {
            Remove-Item -Recurse -Force $UselessFilePath
        }
    }
}

Function Rename-Files
{
    If (Test-Path -PathType Leaf "${GruntzDataOutputDir}\AUTORUN.ICO") {
        Move-Item -Force -Path "${GruntzDataOutputDir}\AUTORUN.ICO" -Destination "${GruntzDataOutputDir}\GRUNTZ.ICO"
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
        & (Get-7zip) 'x' '-aoa' "-o${DdrawDataOutputDir}" $DdrawArchiveName
    }

    If (Test-Path -PathType Leaf "${DdrawDataOutputDir}\license.txt") {
        Move-Item -Force -Path "${DdrawDataOutputDir}\license.txt" -Destination "${DdrawDataOutputDir}\ddraw-license.txt"
    }
}

Function Import-DgVoodooDdraw
{
    If (-Not (Test-Path -PathType Leaf $DgVoodooDdrawArchiveName)) {
        Try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest $DgVoodooDdrawDownloadUrl -OutFile $DgVoodooDdrawArchiveName
        } Catch {
            $_
        }
    }

    If (Test-Path -PathType Leaf $DgVoodooDdrawArchiveName) {
        & (Get-7zip) 'x' '-aoa' "-o${DgVoodooDdrawOutputDir}" $DgVoodooDdrawArchiveName
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
        & (Get-7zip) 'x' '-aoa' "-o${PatchDataOutputDir}" $PatchArchiveName
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
        & (Get-7zip) 'x' '-aoa' "-o${EditorDataOutputDir}" $EditorArchiveName
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
        & (Get-7zip) 'x' '-aoa' "-o${SamplesDataOutputDir}" $SamplesArchiveName
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
        & (Get-7zip) 'x' '-aoa' "-o${CustomLevelForklandDataOutputDir}" $CustomLevelForklandArchiveName
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
        & (Get-7zip) 'x' '-aoa' "-o${CustomLevelDirtlandDataOutputDir}" $CustomLevelDirtlandArchiveName
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

    $GruntzHash = Get-FileHash -Algorithm MD5 "${GruntzDataOutputDir}\GRUNTZ.EXE" | Select-Object -ExpandProperty Hash

    If ($ValidGruntzHashes.Contains($GruntzHash)) {
        Write-Output "> Cracking ${GruntzDataOutputDir}\GRUNTZ.EXE"

        Try {
            [byte[]] $Bytes = Get-Content "${GruntzDataOutputDir}\GRUNTZ.EXE" -Encoding Byte

            If ($UseOriginalCrack) {
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
            } Else {
                $Bytes[0x0001F15A] = 0x93
            }

            $Bytes | Set-Content "${GruntzDataOutputDir}\GRUNTZ.EXE" -Encoding Byte
        } Catch {
            $_
        }
    }

    $PatchValidHashes = @(
        '199D4613E4587E1D720623DC11569E4D'
    )

    $PatchHash = Get-FileHash -Algorithm MD5 "${PatchDataOutputDir}\GRUNTZ.EXE" | Select-Object -ExpandProperty Hash

    If ($PatchValidHashes.Contains($PatchHash)) {
        Write-Output "> Cracking ${PatchDataOutputDir}\GRUNTZ.EXE"

        Try {
            [byte[]] $Bytes = Get-Content "${PatchDataOutputDir}\GRUNTZ.EXE" -Encoding Byte

            If ($UseOriginalCrack) {
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
            } Else {
                $Bytes[0x0001F16A] = 0x93
            }

            $Bytes | Set-Content "${PatchDataOutputDir}\GRUNTZ.EXE" -Encoding Byte
        } Catch {
            $_
        }
    }
}

Function Publish-Installer
{
    Write-Output "> Creating installer."

    $Params = @(
        '--offline-only',
        '-c', "${PSScriptRoot}\config\config.xml",
        '-p', "${PSScriptRoot}\packages"
    )

    $ExcludeString = ''

    If ($ExcludeMovies) {
        $ExcludeString += 'eu.murda.gruntz.movies'

        $Global:InstallerName = "${InstallerName}-no-movie"
    }

    If ($ExcludeString) {
        $ExcludeString += ','
    }

    If ($UseDgVoodooDdraw) {
        $ExcludeString += 'eu.murda.gruntz.ddraw'

        $Global:InstallerName = "${InstallerName}-dgvoodoo"
    } Else {
        $ExcludeString += 'eu.murda.gruntz.dgvoodoo.ddraw'
    }

    $Params += '-e', "${ExcludeString}"

    $Global:InstallerName = "${InstallerName}${InstallerExtension}"
    $Params += "${InstallerName}"

    & (Get-BinaryCreator) $Params
}

Function Compress-Installer
{
    If ($CompressInstallerIfPossible -And (-Not ((Get-Upx) -Eq 1))) {
        If (Test-Path -PathType Leaf "${InstallerName}") {
            Write-Output "> Compressing the installer to save disk space."
            & (Get-Upx) '-9' "${InstallerName}"
        }
    }
}

. Main


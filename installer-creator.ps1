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

$DataOutputDir = 'packages/eu.murda.gruntz/data'

function Main
{
    If ((Get-7zip) -Eq 1) {
        Write-Output "> Unable to find 7z.exe from your environment's PATH variable."
        Write-Output '> Aborting.'
        Exit(1)
    }

    Write-Output "> 7zip binary found at: '$(Get-7zip)'"

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

    If ((Create-Directory $DataOutputDir) -Eq 0) {
        Write-Output "> Created directory: '$DataOutputDir'."
    }

    Expand-Media $Media
    Remove-UselessFiles
    Rename-Files
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
    }

    Return 1
}

Function Get-BinaryCreator
{
    If (Get-Command 'binarycreator.exe' -ErrorAction SilentlyContinue) {
        Return (Get-Command 'binarycreator.exe' | Select -ExpandProperty Source)
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
    & (Get-7zip) 'x' "-o$DataOutputDir" $Media
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
        $UselessFilePath = "$DataOutputDir/$UselessFile"

        If (Test-Path -PathType Any $UselessFilePath) {
            Remove-Item -Recurse -Force $UselessFilePath
        }
    }
}

Function Rename-Files
{
    If (Test-Path -PathType Leaf "$DataOutputDir/AUTORUN.ICO") {
        Rename-Item -Path "$DataOutputDir/AUTORUN.ICO" -NewName 'GRUNTZ.ICO'
    }
}

. Main

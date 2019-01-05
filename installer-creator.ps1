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
    If ((Get-7zip) -eq 1) {
        Write-Output "> Unable to find 7z.exe from your environment's PATH variable."
        Write-Output '> Aborting.'
        Exit(1)
    }

    Write-Output "> 7zip binary found at: '$(Get-7zip)'"

    If (-Not ((Test-Media $Media) -Eq 0)) {
        If ((Test-Media $Media) -Eq 1) {
            Write-Output "> Specified ISO file doesn't exist on your filesystem."
        }

        if ((Test-Media $Media) -Eq 2) {
            Write-Output "> Specified ISO file doesn't match with required fingerprint."
        }

        Write-Output '> Aborting.'
        exit(1)
    }

    if ((Create-Directory $DataOutputDir) -eq 0) {
        Write-Output "> Created directory: '$DataOutputDir'."
    }

    Expand-Media $Media
    Remove-UselessFiles

}

function Create-Directory ([string] $Directory)
{
    if (-Not (Test-Path -PathType Container $Directory)) {
        [void] (New-Item -Path $Directory -ItemType Directory)
        return 0
    }

    return 1
}

Function Get-7zip
{
    if (Get-Command '7z.exe' -ErrorAction SilentlyContinue) {
        return (Get-Command '7z.exe' | Select -ExpandProperty Source)
    }

    return 1
}

Function Test-Media ([string] $Path)
{
    $ValidHashes = @(
        '275547756A472DA85298F7B86FBAF197'
    )

    if (-Not (Test-Path -PathType Leaf $Path)) {
        return 1
    }

    $Hash = Get-FileHash -Algorithm MD5 $Path | Select -ExpandProperty Hash

    if (-Not ($ValidHashes.Contains($Hash))) {
        return 2
    }

    return 0
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

    Foreach ($UselessFile in $UselessFiles)
    {
        $UselessFilePath = "$DataOutputDir/$UselessFile"

        If (Test-Path -PathType Any $UselessFilePath) {
            Remove-Item -Recurse -Force $UselessFilePath
        }
    }
}

. Main

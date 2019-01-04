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
param(
    $Media = 'gruntz.iso'
)

Set-StrictMode -Version 3

function Main
{
    if ((Get-7zip) -eq 1) {
        Write-Output "> Unable to find 7z.exe from your environment's PATH variable."
        Write-Output '> Aborting.'
        exit(1)
    }

    Write-Output "> 7zip binary found at: '$(Get-7zip)'"

    if (-Not ((Test-Media $Media) -eq 0)) {
        if ((Test-Media $Media) -eq 1) {
            Write-Output "> Specified ISO file doesn't exist on your filesystem."
        }

        if ((Test-Media $Media) -eq 2) {
            Write-Output "> Specified ISO file doesn't match with required fingerprint."
        }

        Write-Output '> Aborting.'
        exit(1)
    }

    if ((Create-Directory 'packages/eu.murda.gruntz/data') -eq 0) {
        Write-Output "> Created directory: 'packages/eu.murda.gruntz/data'."
    }
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

. Main

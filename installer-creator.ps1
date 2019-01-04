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
    Get-7zip
    Test-Media $Media
}

Function Get-7zip
{
    if (Get-Command '7z.exe' -ErrorAction SilentlyContinue) {
        return (Get-Command '7z.exe' | Select -ExpandProperty Source)
    } else {
        Write-Output "> Unable to find 7z.exe from your environment's PATH variable."
    }

    return 1
}

Function Test-Media ([string] $Path)
{
    $ValidHashes = @(
        '275547756A472DA85298F7B86FBAF197'
    )

    if (-Not (Test-Path -PathType Leaf $Path)) {
        Write-Output "> Specified file doesn't exist on your filesystem."
        return 1
    }

    $Hash = Get-FileHash -Algorithm MD5 $Path | Select -ExpandProperty Hash

    if (-Not ($ValidHashes.Contains($Hash))) {
        Write-Output "> Specified file doesn't match with required fingerprint."
        return 1
    }

    return 0
}

. Main

<#
 .SYNOPSIS

  Runs tasks to generate Monolith's Gruntz (1999) installer for Windows 8+.

 .DESCRIPTION

  This scripts tries to convert Gruntz ISO file to installer that is compatible with Microsoft Windows 8, 8.1 and 10.

  Requirements:
  - Windows PowerShell 4.0 or higher.
  - Qt Installer Framework 3.0 or higher

 .PARAMETER IsoFile

  Path to Gruntz ISO file.
  Default, gruntz.iso
#>

[CmdletBinding()]
param(
    $IsoFile = 'gruntz.iso'
)

Set-StrictMode -Version 3

function Main
{

}

.Main

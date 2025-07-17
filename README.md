# Copy-ItemDude
Copy exactly one file from the local machine to a remote target using PowerShell remoting.

```
.DESCRIPTION
  Copy exactly one file from the local machine to a remote target using PowerShell remoting.

.NOTES
    Script:  Copy-ItemDude.ps1
    Author:  MikeNizo808
    License: MIT 2025
    Profile: https://github.com/mikenizo808
    Status:  Functional

.EXAMPLE
    #paste into PowerShell
    $Error.Clear();Clear-Host
    Import-Module C:\Scripts\Copy-ItemDude.ps1 -Force
    Get-Command Copy-ItemDude -Syntax
    help Copy-ItemDude -Examples 

.EXAMPLE
    #paste into PowerShell
    Import-Module C:\Scripts\Copy-ItemDude.ps1 -Force
    Copy-ItemDude -ComputerName testnode01 -SourceFile "c:\temp\file.txt" -DestinationFolder "C:\Temp"

.EXAMPLE
    #paste into PowerShell
    Import-Module C:\Scripts\Copy-ItemDude.ps1 -Force
    $splatParams = @{
        ComputerName = "testnode01"
        SourceFile = "c:\temp\file.txt"
        DestinationFolder = "C:\Temp2"
    }
    Copy-ItemDude @splatParams

.EXAMPLE
#paste into PowerShell
$Error.Clear();Clear-Host
Import-Module C:\Scripts\Copy-ItemDude.ps1 -Force

if(-not $creds){
    $creds = Get-Credential -Message 'Enter the login for remote node'
}

$splatParams = @{
        ComputerName = "testnode01"
        Credential   = $creds
        Source       = "c:\temp\testfile.txt"
        Destination  = "C:\Temp2"
        Verbose      = $true
}
Copy-ItemDude @splatParams

This example used the parameter alias `Source` instead of `SourceFile` and also used the alias `Destination` instead of `DestinationFolder`.

```

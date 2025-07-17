Function Copy-ItemDude{

    <#
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

    #>

    [CmdletBinding()]
    Param(

        #String. The name of the target server
        [string]$ComputerName,

        #PSCredential. Optionally, provide login for the remote node. Not typically needed for domain-joined targets.
        [PSCredential]$Credential,

        #String. The path to the source file on the local machine.
        #Optionally uncomment the next line to get red error text immediately if the path does not exist.
        #[ValidateScript({Test-Path -Path $PSItem -PathType Leaf})]
        [Alias("Source")]
        [string]$SourceFile,

        #String. The path to the target folder to copy the file to such as "C:\Temp".
        #This path is from the perspective of the target and should not be a UNC path.
        #If the path does not exist on the target, it will be created for you.
        [Alias("Destination")]
        [string]$DestinationFolder
    )

    Process{

        ## Confirm local file exists
        $localFileExists = Test-Path -Path $SourceFile -ErrorAction Ignore
        if($localFileExists){
            Write-Verbose -Message ('Found local file to be copied {0}' -f $SourceFile)
        }
        Else{
            Write-Warning -Message ('Cannot find path to {0} on local machine {1}' -f $SourceFile, (Get-Content Env:ComputerName))
            return $null
        }

        ## Get the filename with extension
        ##
        ## Sometimes it is useful to have this for providing the full path for destination later.
        $strFileName = Get-Item -Path $SourceFile | Select-Object -ExpandProperty Name

        ## Handle destination, with support for remoting
        ##
        ## Not required, but often it is best to set your variable in the current scope
        ## to make it easier to ingest via remoting. So we take the inputted parameter,
        ## and simply set a variable in the current scope. If using with many functions
        ## in the future, you could make it script-scoped such as $Script:somevariable.
        
        if($DestinationFolder){
            $strDestinationFolder = $DestinationFolder
        }
        Else{
            Write-Warning -Message 'Please populate the DestinationFolder parameter and try again.'
            $strDestinationFolder = $null
            return $null
        }

        ## Handle session
        If($Credential){
            $session = New-PSSession -ComputerName $ComputerName -Credential $Credential
        }
        Else{
            $session = New-PSSession -ComputerName $ComputerName
        }

        ## Test remote folder path
        $existsRemoteFolder = Invoke-Command -Session $session -ScriptBlock{
            if(Test-Path -Path $Using:strDestinationFolder){
                return $true
            }
            Else{
                return $false
            }
        }

        ## Create remote folder, if needed
        if($existsRemoteFolder){
            Write-Verbose -Message ('The remote folder exists, and is ready to accept file copies')
        }
        Else{
            $created = Invoke-Command -Session $session -ScriptBlock{
                $null = New-Item -Path $Using:strDestinationFolder -ItemType Directory
                if(Test-Path $Using:strDestinationFolder){
                    return $true
                }
                Else{
                    return $false
                }
            }
            if($created){
                $existsRemoteFolder = $true
                Write-Verbose -Message ('Successfully created path {0} on target {1}.' -f $strDestinationFolder, $ComputerName)
            }
        }
        
        ## Prepare for the copy action
        If($existsRemoteFolder){
            
            ## Handle string path for destination including filename and extension
            try{
                ## Try to create the path using Join-Path
                $strDestination = Join-Path -Path $strDestinationFolder -ChildPath $strFileName -ErrorAction Stop
            }
            catch{
                ## If needed, just use a string representing the final full file path on the target
                $strDestination = ('{0}\{1}' -f $strDestinationFolder, $strFileName)
            }

            ## Do the copy action
            if($strDestination){
                try{
                    Copy-Item -ToSession $session -Path $SourceFile -Destination $strDestination -Force -ErrorAction Stop -Verbose
                }
                catch{
                    Write-Warning -Message 'Problem performing copy action. Check your inputs and try again.'
                    $null = Remove-PSSession -Session $session
                    throw $_
                }

                ## Verify and collect file details
                $copiedFileInfo = Invoke-Command -Session $session -ScriptBlock{
                    Get-Item -Path $Using:strDestination | Select-Object LastWriteTime, Length, Name #| Out-String
                }
            }
            Else{
                Write-Warning -Message ('Problem determining target path to copy to.')
                Write-Warning -Message ('Attempted using a target path of {0} on the remote target' -f $strDestination)
            }
        }
    }# End Process

    End{
        If($session){
            $null = Remove-PSSession -Session $session
        }

        if($copiedFileInfo){
            Write-Verbose -Message ('Copy succeeded!')
            return ($copiedFileInfo | Out-String)
        }
        Else{
            Write-Warning -Message 'Nothing copied. Check your inputs and try again.'
        }
    }
}# End Function
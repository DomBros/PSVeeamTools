Function Set-VTScheduleTests {
    
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.Void])]
    Param (
        # PSCredential
        [Parameter(Mandatory = $False)]
        [PSCredential]$Credential
    )
    
    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError
    
    Try {        
        $Msg = "START"
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
        Get-Info -Type i -Message $Msg | Out-File -FilePath $Log -Append
        Write-Verbose -Message $Msg
        
        If (-not $Credential) {
            $Credential = Get-CredentialValidate
        }
        
        Remove-VTvLabAllDependVM
        Set-VTvLabAllDependency
        Set-VTVbrSureBackupScheduledTask -Credential $Credential
        
        $Msg = "END"
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
Function Set-VTParameterPartFast {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([PSCustomObject])]
    Param (
        # PSCredential
        [Parameter()]
        [System.Management.Automation.PSCredential]$CredentialVeeam
    )

    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError

    Try {
        $Msg = 'Start'
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append

        if ($PSBoundParameters.ContainsKey('CredentialVeeam')) {
            Set-VTConnection -Credential $CredentialVeeam
        } else {
            Set-VTConnection
        }

        $Script:VTVirtualLab = Get-VTVirtualLab
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
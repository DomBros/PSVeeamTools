Function Set-VTParameterAll {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([PSCustomObject])]
    Param (
        # PSCredential
        [Parameter()]
        [System.Management.Automation.PSCredential]$CredentialHyperV
    )

    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError

    Try {
        $Msg = 'Start'
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append

        #Set-VTConnection
        $Script:VTVirtualLab = Get-VTVirtualLab

        if ($PSBoundParameters.ContainsKey('CredentialHyperV')) {
            $Script:VMsVLans = Get-VTVMvLan -CredentialHyperV $CredentialHyperV
        } else {
            $Script:VMsVLans = Get-VTVMvLan
        }
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
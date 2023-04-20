Function Set-VTScheduleTests {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.Void])]
    Param (
        # PSCredential
        [Parameter()]
        [System.Management.Automation.PSCredential]$CredentialScheduledTask,
        # PSCredential
        [Parameter()]
        [System.Management.Automation.PSCredential]$CredentialHyperV
    )

    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError

    Try {
        $Msg = "START"
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
        Set-VTInfo -m $Msg

        If (-not $CredentialScheduledTask) {
            $CredentialScheduledTask = Get-CredentialValidate
        }

        if ($PSBoundParameters.ContainsKey('CredentialHyperV')) {
            Remove-VTvLabAllDependVM -CredentialHyperV $CredentialHyperV
            Set-VTvLabAllDependency -CredentialHyperV $CredentialHyperV
        } else {
            Remove-VTvLabAllDependVM
            Set-VTvLabAllDependency
        }

        Set-VTVbrSureBackupScheduledTask -CredentialScheduledTask $CredentialScheduledTask

        $Msg = "END"
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
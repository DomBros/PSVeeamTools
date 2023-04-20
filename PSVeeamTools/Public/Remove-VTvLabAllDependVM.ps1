Function Remove-VTvLabAllDependVM {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.Void])]
    Param (
        # PSCredential
        [Parameter()]
        [System.Management.Automation.PSCredential]$CredentialHyperV
    )

    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError

    Try {
        Set-VTParameterPartFast

        $DependencyToRestore = $Script:VTConfig.DependencyToRestore | Where-Object -FilterScript { -not $PSItem.DuplicatedOnHost } | Sort-Object -Property vLabName -Descending

        ForEach ($dependencyObject In $DependencyToRestore) {
            $HyperVHost = (($Script:VTVirtualLab).Where({
                        $PSItem.Name -eq $dependencyObject.vLabName
                    })).Host

            $Msg = "$HyperVHost $($dependencyObject.vLabName) $($dependencyObject.ComputerName)"
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append

            # Remove-VTvLabDependVM
            $RemoveVTvLabDependVM = @{
                HyperVHost   = $HyperVHost
                ComputerName = $dependencyObject.ComputerName
                Verbose      = $true
            }
            if ($PSBoundParameters.ContainsKey('CredentialHyperV')) {
                $RemoveVTvLabDependVM += @{
                    CredentialHyperV = $CredentialHyperV
                }
            }
            Remove-VTvLabDependVM @RemoveVTvLabDependVM
        }
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
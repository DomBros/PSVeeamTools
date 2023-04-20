Function Set-VTVirtualLabEnvironmentFromScrach {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.Void])]
    Param (
        # PSCredential
        [Parameter()]
        [System.Management.Automation.PSCredential]$CredentialHyperV,
        # PSCredential
        [Parameter()]
        [System.Management.Automation.PSCredential]$CredentialVeeam
    )

    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError

    Try {
        if ($CredentialVeeam) {
            Set-VTParameterPartFast -CredentialVeeam $CredentialVeeam
        } else {
            Set-VTParameterPartFast
        }

        $DependencyToRestore = $Script:VTConfig.DependencyToRestore | Where-Object -FilterScript { -not $PSItem.DuplicatedOnHost } | Sort-Object -Property vLabName -Descending

        ForEach ($dependencyObject In $DependencyToRestore) {
            $HyperVHost = (($Script:VTVirtualLab).Where( {
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

        ForEach ($dependencyObject In $DependencyToRestore) {
            Start-RSJob -ScriptBlock {
                $dependencyObject = $USING:dependencyObject

                # Set-VTvLabDependency
                $SetVTvLabDependency = @{
                    ComputerName = $dependencyObject.ComputerName
                    vLabName     = $dependencyObject.vLabName
                    Verbose      = $true
                }
                if ($Using:CredentialHyperV) {
                    $SetVTvLabDependency += @{
                        CredentialHyperV = $Using:CredentialHyperV
                    }
                }
                Set-VTvLabDependency @SetVTvLabDependency
            }
            Start-Sleep -Seconds 10
        }

        Get-RSJob | Receive-RSJob

        Remove-VTSureBackupJobAndAppGroup -Verbose

        if ($PSBoundParameters.ContainsKey('CredentialHyperV')) {
            New-VTApplicationGroupSureBackupJob -CredentialHyperV $CredentialHyperV -Verbose
        } else {
            New-VTApplicationGroupSureBackupJob -Verbose
        }

        Get-RSJob | Wait-RSJob
        Get-RSJob | Receive-RSJob | Out-File -FilePath $Log -Append
        Get-RSJob | Remove-RSJob
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
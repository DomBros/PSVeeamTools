Function Set-VTvLabAllDependency {
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
            $Msg = "ComputerName: '$($dependencyObject.ComputerName)' vLabName: '$($dependencyObject.vLabName)'"
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
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
        Get-RSJob | Wait-RSJob
        Get-RSJob | Receive-RSJob
        Get-RSJob | Receive-RSJob | Out-File -FilePath $Log -Append
        #Get-RSJob | Remove-RSJob
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
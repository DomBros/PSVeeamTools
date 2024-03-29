﻿Function Set-VTvLabDependency {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([PSCustomObject])]
    Param
    (
        [Parameter(Mandatory)]
        [System.String]$ComputerName,
        [Parameter()]
        [System.String]$vLabName,
        [Parameter()]
        [System.String]$Reason = 'SureBackup Automate Tests',
        [Parameter()]
        [System.String[]]$VMRestoreSource = 'Backup',
        # PSCredential
        [Parameter()]
        [System.Management.Automation.PSCredential]$CredentialHyperV
    )

    <#DynamicParam {
    }#>

    Process {

        $ProcessName = $MyInvocation.MyCommand.Name
        $Log = $Script:VTConfig.LogFile
        $LogError = $Script:VTConfig.LogFileError

        Try {
            $Script:VTVirtualLab = Get-VTVirtualLab

            <#
            $vLabName = ($paramDictionary.Values).Where({
                    $_.Name -eq 'vLabName'
                }).Value
                #>

            $Msg = "Searching for vLab '$vLabName'"
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg

            $vLabHostName = ($Script:VTVirtualLab | Where-Object -FilterScript { $PSItem.Name -eq $vLabName }).Host

            If (-not $vLabHostName) {
                $Msg = "Uknown host for vLab:$vLabName"
                "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $LogError -Append
                Throw $Msg
            }

            $VBRBackup = (Get-VBRBackup).Where({
                    $_.JobType -in $VMRestoreSource
                })

            $Msg = "Searching for VM in backup: '$ComputerName'"
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg

            $Server = Get-VBRServer -Type HvServer -Name $vLabHostName

            $Restorepoint = $VBRBackup | Get-VBRRestorePoint -Name $ComputerName

            #$vLabHostNamePath = $vLabHostName.Split('.')[0]

            $InvokeCommand = @{
                ComputerName = $vLabHostName
            }
            if ($PSBoundParameters.ContainsKey('CredentialHyperV')) {
                $InvokeCommand += @{
                    Credential = $CredentialHyperV
                }
            }

            $Path = Invoke-Command @InvokeCommand -ScriptBlock {
                $vLab = $Using:vLabName
                (((Get-VM -Name $vLab).Path) -Split ($vLab))[0]
            }

            If ($Path) {
                #$Path = Join-Path -Path $Path -ChildPath $ComputerName
                $Path = $Path + $ComputerName
            } Else {
                $Msg = 'Unknown host VM file location.'
                Throw $Msg
            }

            $Msg = "Restoring VM '$ComputerName', on '$vLabHostName', connecting to vLab '$vLabName'"
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg

            Start-VBRHvRestoreVM -RestorePoint $Restorepoint[-1] -Server $Server -Path $Path -PowerUp:$false -RegisterAsClusterResource:$false -PreserveVmID:$false -VMName "vLab-$ComputerName" -Reason $Reason -NICsEnabled:$false -Force -Verbose

            # Set-VTVMSwichAndState -ComputerName $ComputerName -vLabHostName $vLabHostName -vLabName $vLabName
            $SetVTVMSwichAndState = @{
                ComputerName = $ComputerName
                vLabHostName = $vLabHostName
                vLabName     = $vLabName
            }
            if ($PSBoundParameters.ContainsKey('CredentialHyperV')) {
                $SetVTVMSwichAndState += @{
                    CredentialHyperV = $CredentialHyperV
                }
            }
            Set-VTVMSwichAndState @SetVTVMSwichAndState
        } Catch {
            Get-Date | Out-File -FilePath $LogError -Append
            $_ | Out-File -FilePath $LogError -Append
            Throw $_
        }
    }
}
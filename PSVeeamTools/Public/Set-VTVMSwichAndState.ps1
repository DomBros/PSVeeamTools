Function Set-VTVMSwichAndState {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([PSCustomObject])]
    Param (
        $ComputerName,
        $vLabHostName,
        $vLabName,
        $vLabvLan,
        # PSCredential
        [Parameter()]
        [System.Management.Automation.PSCredential]$CredentialHyperV
    )

    $ComputerNamevLab = "vLab-$ComputerName"
    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError

    Try {
        If (-not $vLabvLan) {
            if ($PSBoundParameters.ContainsKey('CredentialHyperV')) {
                $Script:VMsVLans = Get-VTVMvLan -CredentialHyperV $CredentialHyperV
            } else {
                $Script:VMsVLans = Get-VTVMvLan
            }

            $VMvLan = (($Script:VMsVLans | Where-Object -FilterScript {
                        $_.Name -eq $ComputerName
                    }).vLan | Where-Object -FilterScript {
                    $PSItem -ne '0'
                } | Select-Object -Unique)[0]
        }

        $SwitchName = 'Lab Isolated Network ({0}-{1})' -f $vLabName, $VMvLan

        $Msg = "SwitchName: '$SwitchName', ComputerName: '$ComputerName'"
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
        Set-VTInfo -m $Msg

        $InvokeCommand = @{
            ComputerName = $vLabHostName
        }
        if ($PSBoundParameters.ContainsKey('CredentialHyperV')) {
            $InvokeCommand += @{
                Credential = $CredentialHyperV
            }
        }

        Invoke-Command @InvokeCommand -ScriptBlock {

            $VMNetworkAdapter = Get-VMSwitch | Where-Object -FilterScript {
                $_.Name -eq $Using:SwitchName
            }

            If ($VMNetworkAdapter) {
                $Msg = "VM switch exist: $($VMNetworkAdapter.Name)"
                Write-Verbose -Message $Msg
                Write-Verbose -Message "$($VMNetworkAdapter.Name)"
                Connect-VMNetworkAdapter -VMName $Using:ComputerNamevLab -SwitchName $VMNetworkAdapter.Name
            } Else {
                $Msg = "VM switch does't exist: $($VMNetworkAdapter.Name)"
                Write-Verbose -Message $Msg
            }

            If ((Get-VM $Using:ComputerNamevLab).State -ne 'Running') {
                Start-VM -VMName $Using:ComputerNamevLab
            }
        }
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
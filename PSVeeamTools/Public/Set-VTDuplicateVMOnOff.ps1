Function Set-VTDuplicateVMOnOff {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([Void])]
    Param (
        #Sure Backup Job name
        [Parameter(Mandatory)]
        [System.String]$Name,
        #VM state
        [Parameter(Mandatory)]
        [ValidateSet('On', 'Off')]
        [System.String]$State,
        #Virtual lab name
        [Parameter(Mandatory)]
        [System.String]$vLabName,
        # PSCredential
        [Parameter()]
        [System.Management.Automation.PSCredential]$CredentialHyperV
    )

    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError

    Try {

        $VTComputerNames = $Script:VTConfig.DependencyToRestore.ComputerName

        $ComputerNames = $VTComputerNames | Where-Object -FilterScript {
            $Name -match $PSItem
        } | Select-Object -Unique

        If ($ComputerNames) {

            $ComputerNamevLabPrefix = $Script:VTConfig.ComputerNamevLabPrefix
            $ComputerNamevLabPrefixLike = "{0}*" -f $Script:VTConfig.ComputerNamevLabPrefix

            $ComputerName = "{0}{1}" -f $ComputerNamevLabPrefix, $ComputerNames

            $HyperVHost = (($Script:VTVirtualLab).Where({
                        $PSItem.Name -eq $vLabName
                    })).Host

            $Msg = "Proccesing power mgmt on '$ComputerName' on '$HyperVHost', vLab '$vLabName'"
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg

            $InvokeCommand = @{
                ComputerName = $HyperVHost
            }
            if ($PSBoundParameters.ContainsKey('CredentialHyperV')) {
                $InvokeCommand += @{
                    Credential = $CredentialHyperV
                }
            }

            If ($State -eq 'Off') {

                $Msg = "Turing off: '$ComputerName' on '$HyperVHost', vLab '$vLabName'"
                "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                Write-Verbose -Message $Msg

                Invoke-Command @InvokeCommand -ScriptBlock {

                    If ($VMToProcess = Get-VM -Name $USING:ComputerName -ErrorAction Ignore) {

                        If (($VMToProcess | Measure-Object).Count -gt 1) {
                            $Msg = "Check computer name, there is more than one VM to deletion."
                            Throw $Msg
                        }

                        If ($VMToProcess.VMName -notlike $Using:ComputerNamevLabPrefixLike) {
                            $Msg = "Check computer name, should starts with: '$Using:ComputerNamevLabPrefixLike'."
                            Throw $Msg
                        }

                        If ($VMToProcess.State -ne 'Off') {
                            Write-Verbose "Turning off VM '$($VMToProcess.VMName)' on host '$($USING:HypervHost)'"
                            $VMToProcess | Stop-VM -Force
                        }
                    }
                }
            } ElseIf ($State -eq 'ON') {

                $Msg = "Turing on: '$ComputerName' on '$HyperVHost', vLab '$vLabName'"
                "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                Write-Verbose -Message $Msg

                Invoke-Command @InvokeCommand -ScriptBlock {

                    If ($VMToProcess = Get-VM -Name $USING:ComputerName -ErrorAction Ignore) {

                        If (($VMToProcess | Measure-Object).Count -gt 1) {
                            $Msg = "Check computer name, there is more than one VM to deletion."
                            Throw $Msg
                        }

                        If ($VMToProcess.VMName -notlike $Using:ComputerNamevLabPrefixLike) {
                            $Msg = "Check computer name, should starts with: '$Using:ComputerNamevLabPrefixLike'."
                            Throw $Msg
                        }

                        If ($VMToProcess.State -ne 'On') {
                            Write-Verbose "Turning on VM '$($VMToProcess.VMName)' on host '$($USING:HypervHost)'"
                            $VMToProcess | Start-VM
                        }
                    }
                }
            } Else {
                $errMsg = "Unknown VM state needed '$ComputerName' on '$HyperVHost', vLab '$vLabName'"
                "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                Write-Verbose -Message $errMsg
            }
        }
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
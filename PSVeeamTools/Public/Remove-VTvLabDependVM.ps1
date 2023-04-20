Function Remove-VTvLabDependVM {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.Void])]
    Param (
        # Virtualization Server
        [Parameter()]
        [String]$HyperVHost,
        # VM Name
        [Parameter()]
        [String]$ComputerName,
        # PSCredential
        [Parameter()]
        [System.Management.Automation.PSCredential]$CredentialHyperV
    )

    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError

    Try {
        #Set-VTConnection

        $ComputerNamevLabPrefix = "{0}*" -f $Script:VTConfig.ComputerNamevLabPrefix
        $ComputerName = '{0}{1}' -f $Script:VTConfig.ComputerNamevLabPrefix, $ComputerName

        $Msg = "Removing VM $ComputerName from $HyperVHost"
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
        Write-Verbose -Message $Msg

        If ($ComputerName -notlike $ComputerNamevLabPrefix) {
            $Msg = "Check computer name, should starts with: '$ComputerNamevLabPrefix'."
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $LogError -Append
            Throw $Msg
        }

        $InvokeCommand = @{
            ComputerName = $HyperVHost
        }
        if ($PSBoundParameters.ContainsKey('CredentialHyperV')) {
            $InvokeCommand += @{
                Credential = $CredentialHyperV
            }
        }

        Invoke-Command @InvokeCommand -ScriptBlock {

            If ($VMToProcess = Get-VM -Name $USING:ComputerName -ErrorAction Ignore) {

                If (($VMToProcess | Measure-Object).Count -gt 1) {
                    $Msg = "Check computer name, there is more than one VM to deletion."
                    Throw $Msg
                }

                If ($VMToProcess.VMName -notlike $Using:ComputerNamevLabPrefix) {
                    $Msg = "Check computer name, should starts with: '$Using:ComputerNamevLabPrefix'."
                    Throw $Msg
                }

                If ($VMToProcess.State -ne 'Off') {
                    $Msg = "Turning off VM '$($VMToProcess.VMName)' on host '$($USING:HypervHost)'"
                    Write-Verbose $Msg
                    $VMToProcess | Stop-VM -Force
                }

                Do {
                    Start-Sleep -Seconds 1
                } While ((Get-VM -Name $USING:ComputerName).State -ne 'Off')

                $VMToProcess = Get-VM -Name $USING:ComputerName

                If ($VMToProcess.State -eq 'Off') {

                    $Msg = "Removing VM '$($VMToProcess.VMName)' from host '$($USING:HypervHost)'"
                    Write-Verbose $Msg
                    Remove-VM -Name $VMToProcess.VMName -Force

                    Do {
                        Start-Sleep -Seconds 1
                    } While (Get-VM -Name $USING:ComputerName -ErrorAction Ignore)

                    $Msg = "Removing VM files '$($VMToProcess.VMName)' from path '$($VMToProcess.Path)'"
                    Write-Verbose $Msg
                    Remove-Item -Path $VMToProcess.Path -Recurse
                }
            } Else {
                $Msg = "Check computer name: '$USING:ComputerName', no such on: '$USING:HypervHost'."
                "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg"
                Write-Verbose $Msg
            }
        }
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
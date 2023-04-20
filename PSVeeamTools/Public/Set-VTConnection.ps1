Function Set-VTConnection {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.Void])]
    Param (
        # PSCredential
        [Parameter()]
        [System.Management.Automation.PSCredential]$CredentialVeeam,
        # VbrServer
        [Parameter()]
        [String]$VbrServer = $Script:VTConfig.VBRServer
    )

    $needToConnect = $false
    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError

    Try {
        #region Connect
        If (-not (Get-Module -Name Veeam.Backup.PowerShell)) {
            # Load Veeam module
            $Msg = 'Module "Veeam.Backup.PowerShell" not loaded'
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg

            Import-Module -Name Veeam.Backup.PowerShell
        } Else {
            $Msg = 'Module "Veeam.Backup.PowerShell" loaded'
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg
        }

        $VBRServerSession = Get-VBRServerSession

        If (-not $VBRServerSession) {
            $Msg = 'Not connected to any VBR server'
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg
            $needToConnect = $true
        } Else {
            If ($VbrServer -eq $VBRServerSession.Server) {
                $Msg = 'Connected to right VBR server'
                "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                Write-Verbose -Message $Msg
            } Else {
                $Msg = 'Connected to diffrent VBR server'
                "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                Write-Verbose -Message $Msg
                Disconnect-VBRServer
                $needToConnect = $true
            }
        }

        If ($needToConnect) {
            Try {
                if ($PSBoundParameters.ContainsKey('CredentialVeeam')) {
                    Connect-VBRServer -Server $VbrServer -Credential $CredentialVeeam -ErrorAction Stop
                } else {
                    Connect-VBRServer -Server $VbrServer -ErrorAction Stop
                }
            } Catch {
                $Msg = "Unable to connect to VBR server - $VbrServer"
                "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $LogError -Append
                Write-Error -Message $Msg
            }
        }
        #endregion Connect
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
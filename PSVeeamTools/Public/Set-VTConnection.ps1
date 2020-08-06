Function Set-VTConnection {
    
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.Void])]
    Param (
        #VbrServer
        [Parameter()]
        [String]$VbrServer = $Script:VTConfig.VBRServer
    )
    
    $needToConnect = $false
    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError
    
    Try {
        #region Connect
        If (-not (Get-command Connect-VBRServer -ErrorAction Ignore)) {
            # Load Veeam Snapin
            $Msg = 'Cmdlet Connect-VBRServer not available'
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg
            If (-not (Get-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue)) {
                If (-not (Add-PSSnapin -PassThru -Name VeeamPSSnapIn)) {
                    Write-Error -Message 'Unable to load Veeam snapin'
                }
            }
            # Connect to VBR server
        } Else {
            $Msg = 'Cmdlet Connect-VBRServer available'
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
                Connect-VBRServer -Server $VbrServer -ErrorAction Stop
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
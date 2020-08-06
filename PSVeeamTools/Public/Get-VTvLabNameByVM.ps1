Function Get-VTvLabNameByVM {
    
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.String])]
    Param (
        # VM vLan
        [Parameter()]
        [System.String]$BackupJobName,
        # VM Name
        [Parameter()]
        [System.String]$VMName,
        # VM vLan
        [Parameter()]
        [System.String]$VMvLan,
        # VM type
        [Parameter()]
        [System.String]$VMType,
        # Hyper-V virtual lab name
        [Parameter()]
        [System.String]$vLabNameHyperVDefault = $Script:VTConfig.vLabNameHyperVDefault,
        # Vi virtual lab name
        [Parameter()]
        [System.String]$vLabNameVMwareDefault = $Script:VTConfig.vLabNameVMwareDefault
    )
    
    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError
    
    Try {
        
        $Msg = "VMvLan: $VMvLan"
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
        Write-Verbose -Message $Msg
        
        $VirtualLabNameByVM = $VirtualLabName = $VirtualLabNameBySureJobAll = $null
        
        If (-not $VirtualLabName) {
            If ($PSBoundParameters.ContainsKey('BackupJobName')) {
                $VirtualLabNameBySureJobAll = $Script:VTConfig.vLabParameters | Where-Object {
                    $PSItem.BackupJobName -contains $BackupJobName
                }
                If ($VirtualLabNameBySureJobAll) {
                    If ($PSBoundParameters.ContainsKey('VMvLan') -and $VirtualLabNameBySureJobAll.vLan) {
                        $VirtualLabNameBySureJob = $VirtualLabNameBySureJobAll | Where-Object {
                                $PSItem.vLan -contains $VMvLan
                            }
                        $VirtualLabName = $VirtualLabNameBySureJob.vLabName
                    } Else {
                        $VirtualLabName = $VirtualLabNameBySureJobAll.vLabName
                    }
                }
            }
        }
        
        If (-not $VirtualLabName) {
            If ($PSBoundParameters.ContainsKey('VMName')) {
                $VirtualLabNameByVM = $Script:VTConfig.vLabParameters | Where-Object {
                    $PSItem.VM -contains $VMName
                }
                If ($VirtualLabNameByVM) {
                    $VirtualLabName = $VirtualLabNameByVM.vLabName
                }
            }
        }
        
        If (-not $VirtualLabName) {
            If ($VMType -eq 'Hv' -and $PSBoundParameters.ContainsKey('VMvLan')) {
                If ($VirtualLabNameByVlan = $Script:VTConfig.vLabParameters | Where-Object {
                            $PSItem.vLan -contains $VMvLan -and -not $PSItem.BackupJobName
                        }) {
                    $VirtualLabName = $VirtualLabNameByVlan.vLabName
                } Else {
                    $VirtualLabName = $vLabNameHyperVDefault
                }
            } ElseIf ($VMType -eq 'Vi') {
                $VirtualLabName = $vLabNameVMwareDefault
            } Else {
                $errMsg = 'Unknow VM type'
                Throw $errMsg
            }
        }
        
        $VirtualLabName
        
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
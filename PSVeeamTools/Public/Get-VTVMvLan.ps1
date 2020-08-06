Function Get-VTVMvLan {
    
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([PSCustomObject])]
    Param (
    )
    
    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError
    
    Try {
        $Msg = 'Start'
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
        
        If (Get-Variable -Name VTVMsvLans -Scope Script -ErrorAction Ignore) {
            Return $Script:VTVMsvLans
        }
        
        # search for VM vLan
        $Nodes = (Get-VTHost).Name
        
        $NodesOnline = $Nodes | ForEach-Object {
            $ComputerName = $PSItem
            If (Test-WSMan -ComputerName $ComputerName -Authentication Negotiate -ErrorAction SilentlyContinue) {
                $ComputerName
            }
        }
        
        $VMsVlans = Invoke-Command -ComputerName $NodesOnline -ScriptBlock {
            $vLans = @{
                Name                                        = 'vLans'; Expression = {
                    $_.NetworkAdapters.VlanSetting.AccessVlanId
                }
            }
            Get-VM | Select-Object -Property Name, $vLans
        }
        
        $vLan = @{
            Name     = 'vLan'; Expression = {
                $_.vLans
            }
        }
        
        $VMsVlan = $VMsVLans | Select-Object Name, $vLan
        
        $VMsVlan | ForEach-Object -Process {
            [PSCustomObject]@{
                Name = $_.Name
                vLan = $_.vLan
            }
        }
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
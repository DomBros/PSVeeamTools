Function Get-VTHost {
    
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
        
        Set-VTConnection
        
        # Hyper-V hosts
        $VBRHvEntity = Find-VBRHvEntity -Hosts
        $VBRHvServers = $VBRHvEntity | Where-Object {
            ($PSItem.GetType()).Name -eq 'CHvHostItem'
        }
        $Nodes = $VBRHvServers | Where-Object {
            $_.Type -eq 'Host'
        } | Select-Object -Property ConnHostId, ID, Name, Path, Reference
        
        # vSphere hosts
        $VBRViEntity = Find-VBRViEntity -Servers
        $VBRViServers = $VBRViEntity | Where-Object {
            ($PSItem.GetType()).Name -eq 'CEsxItem'
        }
        $Nodes += $VBRViServers | Where-Object {
            $_.Type -eq 'Esx'
        } | Select-Object -Property ConnHostId, ID, Name, Path, Reference
        
        $Nodes | ForEach-Object -Process {
            [PSCustomObject]@{
                ConnHostId = $_.ConnHostId
                ID         = $_.ID
                Name       = $_.Name
                Path       = $_.Path
                Reference  = $_.Reference
            }
        }
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
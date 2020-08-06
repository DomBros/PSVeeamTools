Function Get-VTVirtualLab {
    
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
        
        If (Get-Variable -Name VTVirtualLab -Scope Script -ErrorAction Ignore) {
            Return $Script:VTVirtualLab
        }
        
        If (-not (Get-command Connect-VBRServer -ErrorAction Ignore)) {
            Set-VTConnection
        }
        
        $VSBVirtualLab = Get-VSBVirtualLab | ForEach-Object -Process {
            [PSCustomObject]@{
                Id = $_.Id
                Name = $_.Name
                Host = $_.GetHost() | Select-Object -ExpandProperty Name
                Type = 'Vi'
            }
        }
        $VSBHVVirtualLab = Get-VSBHVVirtualLab | ForEach-Object -Process {
            [PSCustomObject]@{
                Id = $_.Id
                Name = $_.Name
                Host = $_.GetHost() | Select-Object -ExpandProperty Name
                Type = 'Hv'
            }
        }
        
        If ($VSBVirtualLab) {
            ForEach ($item In $VSBVirtualLab) {
                [PSCustomObject]@{
                    Id = $item.Id
                    Name = $item.Name
                    Host = $item.Host
                    Type = $item.Type
                }
            }
        }
        
        If ($VSBHVVirtualLab) {
            ForEach ($item In $VSBHVVirtualLab) {
                [PSCustomObject]@{
                    Id = $item.Id
                    Name = $item.Name
                    Host = $item.Host
                    Type = $item.Type
                }
            }
        }
        
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
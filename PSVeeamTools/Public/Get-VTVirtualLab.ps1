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

        #Set-VTConnection

        Get-VBRVirtualLab | ForEach-Object -Process {
            [PSCustomObject]@{
                Id   = $_.Id
                Name = $_.Name
                Host = $_.Server.Name
                Type = $_.Platform
            }
        }
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
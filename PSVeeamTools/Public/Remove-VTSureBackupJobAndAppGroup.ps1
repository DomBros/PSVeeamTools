Function Remove-VTSureBackupJobAndAppGroup {
    
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.Void])]
    Param (
        #Aplication group, Sure backup Name to delete
        [Parameter()]
        [System.String]$Name = ('{0} (*' -f $Script:VTConfig.SureJobNamePrefix)
    )
    
    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError
    
    Try {
        Set-VTConnection
        
        $Msg = 'Cleaning up old jobs'
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
        Write-Verbose -Message $Msg
        
        Get-VSBJob | Where-Object -FilterScript {
            $_.Name -like $Name
        } | Remove-VSBJob -Confirm:$false
        
        Get-VSBApplicationGroup | Where-Object -FilterScript {
            $_.Name -like $Name
        } | Remove-VSBApplicationGroup -Confirm:$false
        
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
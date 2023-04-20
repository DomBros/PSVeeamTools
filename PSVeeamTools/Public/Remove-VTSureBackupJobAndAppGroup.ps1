Function Remove-VTSureBackupJobAndAppGroup {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
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
        #Set-VTConnection

        $Msg = 'Cleaning up old jobs'
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
        Write-Verbose -Message $Msg

        #$VsbJobsAll = [Veeam.Backup.Core.SureBackup.CSbJob]::GetAll()
        $VsbJobsAll = Get-VBRSureBackupJob

        $VsbJobsAll | Where-Object -FilterScript {
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
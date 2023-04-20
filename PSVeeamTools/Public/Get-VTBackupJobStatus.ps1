Function Get-VTBackupJobStatus {

    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.String])]
    Param (
        # Sure backup job name
        [Parameter(Mandatory)]
        [System.String]$Name
    )

    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError

    Try {
        $Msg = "Proccesing sure backup '$Name'"
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
        Write-Verbose -Message $Msg

        $nameSureJob = ($Name -Split 'p#')[-1]

        If ($VBRJob = Get-VBRJob -Name $nameSureJob) {
            $LastState = $VBRJob.GetLastState()

            $Msg = "Sure backup job name:'$Name', Backup name:'$nameSureJob', State:'$LastState'"
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg
        } Else {
            $LastState = 'Unknown'

            $Msg = "Sure backup job name:'$Name', Backup name:'$nameSureJob', State:'$LastState'"
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg

            $VBRJob | Out-File -FilePath $Log -Append
        }
        $LastState
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
Function Get-VTReport {

    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.Void])]
    Param (
    )

    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError

    Try {
        $Msg = 'Start'
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append

        Set-VTConnection

        #region report
        $VsbJobs = Get-VSBJob | Where-Object -FilterScript {
            $_.Name -like "$($Script:VTConfig.SureJobNamePrefix) (*"
        } | Sort-Object -Property Name

        $ReportObject = ForEach ($VsbJob In $VsbJobs) {
            [PSCustomObject]@{
                Name          = $VsbJob.Name
                Status        = $VsbJob.GetLastResult()
                StartTime     = ($VsbJob.ScheduleOptions.StartDateTimeLocal).ToString()
                EndTime       = ($VsbJob.ScheduleOptions.EndDateTimeLocal).ToString()
                LatestRun     = ($VsbJob.ScheduleOptions.LatestRunLocal).ToString()
                LatestRecheck = ($VsbJob.ScheduleOptions.LatestRecheckLocal).ToString()
            }
        }

        $ProcessName = $MyInvocation.MyCommand.Name
        $Report = $ReportObject | Sort-Object -Property Name
        $logInfo = ('{0} has finished successfully.' -f $ProcessName)
        $HtmlFragment = $Report | ConvertTo-Html -Fragment -PreContent ('<p>{0}</p><p>Report:</p>' -f $logInfo)


        #region
        #Add color to output depending on results
        #Green
        $HtmlFragment = $HtmlFragment.Replace('<td>Success<', '<td style="background-color: Green;color: White;">Success<')
        #Yellow
        $HtmlFragment = $HtmlFragment.Replace('<td>Warning<', '<td style="background-color: Yellow;">Warning<')
        #Magenta
        $HtmlFragment = $HtmlFragment.Replace('<td>Failed<', '<td style="background-color: Red;color: White;">Failed<')
        #Red
        $HtmlFragment = $HtmlFragment.Replace('<td>Error<', '<td style="background-color: Magenta;color: White;">Error<')
        #endregion

        If ($HtmlFragment -match 'Failed') {
            $Subject = "[$($Script:VTConfig.Tag)] [SureBackup] [Report] (withFailed) Sure backup status report ({0}h)" -f $TimeReportWindow
        } ElseIf ($HtmlFragment -match 'Warning') {
            $Subject = "[$($Script:VTConfig.Tag)] [SureBackup] [Report] (withWarning) Sure backup status report ({0}h)" -f $TimeReportWindow
        } Else {
            $Subject = "[$($Script:VTConfig.Tag)] [SureBackup] [Report] (allSuccess) Sure backup status report ({0}h)" -f $TimeReportWindow
        }

        $HtmlFoot = @"
<font face='Calibri' size='1'>
From: $env:COMPUTERNAME<br>
Path: $PSCommandPath<br>
RunBy: $env:USERNAME.<br>
</font>
"@
        $HtmlFragment = $HtmlFragment + $HtmlFoot

        $messageParameters = @{
            Subject    = $Subject
            From       = $From
            To         = $To
            SmtpServer = 'mailserver.test.co.uk'
            Body       = $HtmlFragment
            BodyAsHtml = $true
            Encoding   = 'UTF8'
        }

        Send-MailMessage @messageParameters
        #endregion report

    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
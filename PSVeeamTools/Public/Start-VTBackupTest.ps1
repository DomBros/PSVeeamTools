Function Start-VTBackupTest {

    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.String])]
    Param (
        $vLabHostName
    )

    $ProcessName = $MyInvocation.MyCommand.Name

    $Script:VTConfig.LogFile = $Script:VTConfig.LogFile -replace ('.log', "-$vLabHostName.log")
    $Script:VTConfig.LogFileError = $Script:VTConfig.LogFileError -replace ('.log', "-$vLabHostName.log")
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError

    $Tag = 'VeeamBackup'

    $To = "IT-Alert-$Tag@test.co.uk"
    $From = "$Tag@test.co.uk"

    $Subject = "[Auto] [$ProcessName] [$vLabHostName] [Info]"
    $SubjectError = "[Error] [$ProcessName] [$vLabHostName] [Auto]"

    $htmlFoot = @"
<font face='Calibri' size='1'>
From: $env:COMPUTERNAME<br>
Path: $PSCommandPath<br>
RunBy: $env:USERNAME.<br>
</font>
"@

    Try {
        $Msg = 'START'
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append

        Set-VTParameterPartFast

        $DependencyToRestore = $Script:VTConfig.DependencyToRestore

        $HostvLabs = $Script:VTVirtualLab | Where-Object -FilterScript {
            $PSItem.Host -eq $vLabHostName
        } | Select-Object -ExpandProperty Name -Unique | Sort-Object -Descending

        $Msg = "Starting RSJob for vLabs: '{0}' on '{1}'" -f ($HostvLabs -join ', '), $vLabHostName
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
        Write-Verbose -Message $Msg

        ForEach ($vLabName In $HostvLabs) {

            $ComputerToConnect = (($DependencyToRestore).Where( { $PSItem.vLabName -eq $vLabName })).ComputerName

            $HostObject = ($Script:VTVirtualLab | Where-Object -FilterScript {
                    $PSItem.Name -eq $vLabName
                })

            $Msg = "HostName: $($HostObject.Host) LabName: $vLabName"
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg

            If ($HostObject.Type -eq 'Hv') {
                ForEach ($ComputerName In $ComputerToConnect) {
                    $Msg = "Reconfiguring switch for: '$ComputerName', on: '$($HostObject.Host)', vLab: '$vLabName'."
                    "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                    Write-Verbose -Message $Msg
                    Set-VTVMSwichAndState -ComputerName $ComputerName -vLabHostName $HostObject.Host -vLabName $vLabName -Verbose
                }
            }
            $Msg = "Tests starts for vLab: '$vLabName'."
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg
            Test-VTSureBackupJob -VirtualLabName $vLabName -Tries 2 -Verbose
        }

        $Msg = "End"
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append

        $htmlFragments = $htmlFoot
        $Attachments = @($Log)
        Send-MailMessage -From $From -To $To -Subject $Subject -Body $htmlFragments -BodyAsHtml -Attachments $Attachments
    } Catch {
        $Attachments = @($Log, $LogError)
        $('#' * 80) | Out-File -FilePath $LogError -Append
        $Error | Out-File -FilePath $LogError -Append
        $htmlFragment = $_ | ConvertTo-Html -Fragment -As List
        $htmlFragments = $htmlFragment + $htmlFoot
        Send-ObjectivityEmail -From $From -To $To -Subject $SubjectError -Body $htmlFragments -BodyAsHtml -Attachments $Attachments
    }
}
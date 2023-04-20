Function New-VTApplicationGroupSureBackupJob {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([PSCustomObject])]
    Param (
        #BackupOlderThenHrs
        [Parameter()]
        [System.Int32]$BackupOlderThenHrs = $Script:VTConfig.SearchFormVMinBackupNotOlderThanHours,
        # PSCredential
        [Parameter()]
        [System.Management.Automation.PSCredential]$CredentialHyperV
    )

    $CurrentSureBackupJobs = $null
    $i = $CurrentSureBackupJobsCount = 0
    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError
    $SureJobNamePrefix = $Script:VTConfig.SureJobNamePrefix
    $BackupJobExcluded = $Script:VTConfig.ExcludeBackupJob
    $BackupOlderThen = (Get-Date).AddHours(-$BackupOlderThenHrs)

    Try {
        #Set-VTConnection

        $Msg = 'Getting VBR backup sessions'
        Write-Verbose -Message $Msg
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
        # Find backuped VMs

        $VBRJob = Get-VBRJob | Where-Object -FilterScript {
            $PSItem.JobType -eq 'Backup'
        }

        # TODO
        #Get-VBRComputerBackupJob

        $VBRJobName = $VBRJob.Name

        $VBRBackupSession = Get-VBRBackupSession | Where-Object -FilterScript {
            $PSItem.JobType -eq 'Backup' -and $PSItem.EndTime -ge $BackupOlderThen -and $PSItem.JobName -in $VBRJobName
        }

        $Msg = 'Getting VBR backup objects'
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
        Write-Verbose -Message $Msg
        $VbrBackupObjects = ($VBRBackupSession).GetTaskSessions() | Where-Object -FilterScript {
            $_.Status -eq 'Success' -or $_.Status -eq 'Warning'
        }

        # Get VMs list
        $VMsList = $VbrBackupObjects | Select-Object -Property Name, JobName -Unique

        $VMsList = $VMsList | Where-Object {
            $PSItem.Name -notin $Script:VTConfig.ExcludeVMFromSureJob
        } | Sort-Object -Property Name

        $VMsNumber = ($VMsList | Measure-Object).Count

        #Current Jobs list
        #Get-VSBJob = Get-VBRSureBackupJob = [Veeam.Backup.Core.SureBackup.CSbJob]::GetAll()
        If ($CurrentSureBackupJobsAll = Get-VBRSureBackupJob) {
            $CurrentSureBackupJobs = $CurrentSureBackupJobsAll | Where-Object -FilterScript {
                $PSItem.Name -like "$SureJobNamePrefix (*"
            }
            If ($CurrentSureBackupJobs) {
                $CurrentSureBackupJobsCount = ($CurrentSureBackupJobs | Measure-Object).Count
                $LastSureBackupJob = $CurrentSureBackupJobs | Sort-Object -Property Name | Select-Object -ExpandProperty Name -Last 1
                If ($LastSureBackupJob) {
                    [int]$i = $LastSureBackupJob.Substring($LastSureBackupJob.IndexOf('(') + 1, $LastSureBackupJob.IndexOf(')') - $LastSureBackupJob.IndexOf('(') - 1)
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('CredentialHyperV')) {
            $Script:VTVMsvLans = Get-VTVMvLan -CredentialHyperV $CredentialHyperV -Verbose
        } else {
            $Script:VTVMsvLans = Get-VTVMvLan -Verbose
        }

        #region check test surebackup present if not remove and recreate them
        If ($CurrentSureBackupJobsCount -lt $VMsNumber) {

            <#
            $Msg = 'Getting VBRHvEntity'
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg
            $VBRHvEntityAll = Find-VBRHvEntity

            $Msg = 'Getting VBRViEntity'
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg
            $VBRViEntityAll = Find-VBRViEntity
            #>

            $Msg = 'Getting VBRBackup'
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg
            $VBRBackupAll = (Get-VBRBackup).Where( {
                    $PSItem.JobType -eq 'Backup'
                })

            $Msg = 'Getting VBRRestorePoint'
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg

            $VBRRestorePointAll = ForEach ($VBRBackup In $VBRBackupAll) {
                @{
                    JobName            = $VBRBackup.JobName
                    BackupPlatform     = $VBRBackup.BackupPlatform
                    VBRRestorePointObj = $VBRBackup | Get-VBRRestorePoint
                }
            }

            $Msg = 'Start creating...'
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg

            ForEach ($TestVMObj In $VMsList) {

                $TestVM = $BackupJobName = $VMvLansObject = $null

                $TestVM = $TestVMObj.Name
                $BackupJobName = $TestVMObj.JobName

                $Msg = "TestVM: '$TestVM'"
                "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                Write-Verbose -Message $Msg

                If ($BackupJobName -in $BackupJobExcluded) {
                    Continue
                }
                If ($BackupJobName -like '*-Test') {
                    Continue
                }

                If ($CurrentSureBackupJobs) {
                    If ($CurrentSureBackupJobs.Name -match $TestVM -and $CurrentSureBackupJobs.Description -eq $BackupJobName) {
                        $Msg = "JobName: $($CurrentSureBackupJobs.Name) JobDescription: $($CurrentSureBackupJobs.Description)"
                        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                        Write-Verbose -Message $Msg
                        Continue
                    }
                }

                $i++
                $Proceed = $i / $VMsNumber
                $ProceedPercent = ($Proceed * 100)
                If ($ProceedPercent -gt 100) {
                    $ProceedPercent = 100
                }
                $is = $i.ToString('000')

                $VMvLansObject = ($Script:VTVMsvLans | Where-Object {
                        $_.Name -eq $TestVM
                    })

                If ($VMvLansObject) {
                    $VMvLans = $VMvLansObject.vLan
                    $VMvLan = $VMvLans[0]
                } Else {
                    $VMvLan = '3'
                }

                # Names and Descriptions
                [string]$AppGroupName = "$SureJobNamePrefix ($is) vm#$TestVM p#$BackupJobName vlan#$VMvLan"
                [string]$SureBackupJobName = "$SureJobNamePrefix ($is) vm#$TestVM p#$BackupJobName"
                [string]$SureBackupJobDescription = $BackupJobName

                $Msg = "Proceed $is / $VMsNumber, $SureBackupJobName"
                "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                Write-Verbose -Message $Msg
                Write-Progress -Activity 'Creating SureJob' -Id 1 -PercentComplete $ProceedPercent -Status $Msg -ErrorAction SilentlyContinue

                # Create Application Group, SureBackup Job
                $restorePointByJob = $VBRRestorePointAll | Where-Object {
                    $PSItem.JobName -eq $BackupJobName
                }

                If (-not $restorePointByJob) {
                    $Msg = "No restore point aviable for VM: '$TestVM' in backup job: '$BackupJobName'"
                    "[$ProcessName] [$((Get-Date).ToString())] [Error] $Msg" | Out-File -FilePath $Log -Append
                    Throw $Msg
                }

                $restorePoint = $restorePointByJob.VBRRestorePointObj | Where-Object {
                    $PSItem.Name -eq $TestVM
                } | Sort-Object -Property CreationTime -Descending | Select-Object -First 1

                If ($restorePointByJob.BackupPlatform.Platform -eq 'EHyperV') {

                    $Msg = "VMvLan:'$VMvLan', TestVM: '$TestVM', VMType:'Hv'"
                    "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                    Write-Verbose -Message $Msg
                    $VirtualLabName = Get-VTvLabNameByVM -BackupJobName $BackupJobName -VMName $TestVM -VMvLan $VMvLan -VMType 'Hv'

                    $VirtualLabHV = Get-VSBHvVirtualLab -Name $VirtualLabName
                    #ToDo: Add-VSBHvApplicationGroup error if $AppGroupName exists
                    #$AppGroup = Add-VSBHvApplicationGroup -Name $AppGroupName -VmFromBackup $VmFromBackup
                    $AppGroupHv = Add-VSBHvApplicationGroup -Name $AppGroupName -RestorePoint $restorePoint
                    $null = Add-VSBHvJob -Name $SureBackupJobName -VirtualLab $VirtualLabHV -AppGroup $AppGroupHv -Description $SureBackupJobDescription
                } ElseIf ($restorePointByJob.BackupPlatform.Platform -eq 'EVmware') {

                    $VirtualLabName = Get-VTvLabNameByVM -VMvLan $VMvLan -VMType 'Vi'

                    #$VmFromBackup = Find-VBRViEntity -Name $TestVM #, $VTConfig.VmNeededInApplicationGroup
                    $VirtualLabVi = Get-VBRVirtualLab -Name $VirtualLabName
                    #$AppGroup = Add-VSBViApplicationGroup -Name $AppGroupName -VmFromBackup $VmFromBackup
                    $startupoptions = New-VBRSureBackupStartupOptions -AllocatedMemory 50 -EnableVMHeartbeatCheck -MaximumBootTime 600 -ApplicationInitializationTimeout 120 -EnableVMPingCheck
                    $job = Get-VBRJob -Name $BackupJobName
                    $backupobject = Get-VBRJobObject -Job $job -Name $TestVM
                    $vm = New-VBRSureBackupVM -VM $backupobject -StartupOptions $startupoptions
                    $AppGroupVi = Add-VBRViApplicationGroup -Name $AppGroupName -VM $vm #-Description 'ESX'
                    $null = Add-VBRViSureBackupJob -Name $SureBackupJobName -VirtualLab $VirtualLabVi -ApplicationGroup $AppGroupVi -Description $SureBackupJobDescription
                } Else {
                    $errMsg = "Cannot find VM in backup: $TestVM ($BackupJobName)"
                    "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $LogError -Append
                    Throw $errMsg
                }

                $SureBackupOptionsObject = Get-VBRSureBackupJob -Name $SureBackupJobName
                $SureBackupOptions = New-VBRSureBackupJobVerificationOptions -EnableEmailNotification -Address $($Script:VTConfig.MailTo) -NotifyOnError -NotifyOnWarning -NotifyOnSuccess:$false
                $SureBackupOptionsObject | Set-VBRSureBackupJob -VerificationOptions $SureBackupOptions
            }
        }
        #endregion
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
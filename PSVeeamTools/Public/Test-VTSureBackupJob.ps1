Function Test-VTSureBackupJob {

    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.Void])]
    Param (
        #VbrServer
        [Parameter(Mandatory)]
        [System.String]$VirtualLabName,
        # PSCredential
        [Parameter()]
        [System.Management.Automation.PSCredential]$CredentialHyperV,
        #Loops
        [Parameter()]
        [System.Int32]$Tries = 2

    )

    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError
    $vsbOnHoldJobs = @()

    Try {
        $VirtualLabId = ($Script:VTVirtualLab | Where-Object -FilterScript {
                $PSItem.Name -eq $VirtualLabName
            }).Id

        $Msg = "vLab:$VirtualLabName vLabID:$VirtualLabId"
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
        Set-VTInfo -m $Msg

        #region present surebackup check
        $Msg = 'Listing jobs...'
        Write-Verbose -Message $Msg
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
        #$VsbJobsAll = [Veeam.Backup.Core.SureBackup.CSbJob]::GetAll()
        $VsbJobsAll = Get-VBRSureBackupJob
        $VsbJobs = $VsbJobsAll | Where-Object -FilterScript {
            $_.VirtualLabId -eq $VirtualLabId
        } | Sort-Object -Property Name

        $StateOff = @{
            State   = 'Off'
            Verbose = $true
        }
        $StateOn = @{
            State   = 'On'
            Verbose = $true
        }
        if ($PSBoundParameters.ContainsKey('CredentialHyperV')) {
            $StateOff += @{
                CredentialHyperV = $CredentialHyperV
            }
            $StateOn += @{
                CredentialHyperV = $CredentialHyperV
            }
        }

        If ($VsbJobs) {
            ForEach ($VsbJob In $VsbJobs) {
                If ($VsbJob.GetLastResult() -ne 'Success') {

                    $VsbJobName = $VsbJob.Name

                    $Msg = "Starting job -ne 'Success': $VsbJobName"
                    "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                    Write-Verbose -Message $Msg

                    If ('Stopped' -ne (Get-VTBackupJobStatus -Name $VsbJobName)) {
                        $Msg = "Adding to OnHold que: '$VsbJobName'"
                        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                        Write-Verbose -Message $Msg

                        $vsbOnHoldJobs += $VsbJob
                        Continue
                    }

                    Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName @StateOff
                    $VsbJob | Start-VSBJob -ErrorAction SilentlyContinue
                    Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName @StateOn
                }
            }

            #region check once again Warning and Failed SureBackup jobs
            If ($vsbOnHoldJobs) {
                $i = 0

                Do {
                    $i++
                    $Msg = "Start OnHold jobs -ne 'Success' loop, i=$i"
                    "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                    Write-Verbose -Message $Msg

                    $VsbJobs = $vsbOnHoldJobs
                    $vsbOnHoldJobs = @()

                    ForEach ($VsbJob In $VsbJobs) {
                        $VsbJobName = $VsbJob.Name

                        $Msg = "Starting job -ne 'Success': $VsbJobName"
                        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                        Write-Verbose -Message $Msg

                        If ('Stopped' -ne (Get-VTBackupJobStatus -Name $VsbJobName)) {
                            $Msg = "Adding to OnHold que: '$VsbJobName'"
                            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                            Write-Verbose -Message $Msg

                            $vsbOnHoldJobs += $VsbJob
                            Continue
                        }

                        Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName @StateOff
                        $VsbJob | Start-VSBJob -ErrorAction SilentlyContinue
                        Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName @StateOn
                    }
                } While ($vsbOnHoldJobs -and ($i -lt $Tries))
            }
            #endregion

            ForEach ($VsbJob In $VsbJobs) {
                If ($VsbJob.GetLastResult() -eq 'Success') {
                    $VsbJobName = $VsbJob.Name

                    If ('Stopped' -ne (Get-VTBackupJobStatus -Name $VsbJobName)) {
                        $Msg = "Adding to OnHold que: '$VsbJobName'"
                        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                        Write-Verbose -Message $Msg

                        $vsbOnHoldJobs += $VsbJob
                        Continue
                    }

                    $Msg = "Starting job -eq 'Success': $VsbJobName"
                    "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                    Write-Verbose -Message $Msg

                    Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName @StateOff
                    $VsbJob | Start-VSBJob -ErrorAction SilentlyContinue
                    Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName @StateOn
                }
            }
            #endregion

            #region check once again Warning and Failed SureBackup jobs
            If ($vsbOnHoldJobs) {
                $i = 0

                Do {
                    $i++
                    $Msg = "Start OnHold jobs -ne 'Success' loop, i=$i"
                    "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                    Write-Verbose -Message $Msg

                    $VsbJobs = $vsbOnHoldJobs
                    $vsbOnHoldJobs = @()

                    ForEach ($VsbJob In $VsbJobs) {
                        $VsbJobName = $VsbJob.Name

                        $Msg = "Starting job -ne 'Success': $VsbJobName"
                        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                        Write-Verbose -Message $Msg

                        If ('Stopped' -ne (Get-VTBackupJobStatus -Name $VsbJobName)) {
                            $Msg = "Adding to OnHold que: '$VsbJobName'"
                            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                            Write-Verbose -Message $Msg

                            $vsbOnHoldJobs += $VsbJob
                            Continue
                        }

                        Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName @StateOff
                        $VsbJob | Start-VSBJob -ErrorAction SilentlyContinue
                        Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName @StateOn
                    }
                } While ($vsbOnHoldJobs -and ($i -lt $Tries))
            }
            #endregion

            $i = 0
            #region check once again Warning and Failed SureBackup jobs
            Do {
                $i++
                $Msg = "Start jobs withWarning loop, i=$i"
                "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                Write-Verbose -Message $Msg
                #$VsbJobsAll = [Veeam.Backup.Core.SureBackup.CSbJob]::GetAll()
                $VsbJobsAll = Get-VBRSureBackupJob
                $VsbJobs = $VsbJobsAll | Where-Object -FilterScript {
                    $_.VirtualLabId -eq $VirtualLabId
                } | Sort-Object -Property Name

                ForEach ($VsbJob In $VsbJobs) {
                    If ($VsbJob.GetLastResult() -ne 'Success') {
                        $VsbJobName = $VsbJob.Name

                        $Msg = "Starting job -ne 'Success': $VsbJobName"
                        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                        Write-Verbose -Message $Msg

                        If ('Stopped' -ne (Get-VTBackupJobStatus -Name $VsbJobName)) {
                            $Msg = "Adding to OnHold que: '$VsbJobName'"
                            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                            Write-Verbose -Message $Msg

                            $vsbOnHoldJobs += $VsbJob
                            Continue
                        }

                        Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName @StateOff
                        $VsbJob | Start-VSBJob -ErrorAction SilentlyContinue
                        Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName @StateOn
                    }
                }
            } While (($VsbJobs.GetLastResult() -contains 'Warning' -or $VsbJobs.GetLastResult() -contains 'Failed') -and ($i -lt $Tries))
            #endregion

            #region check once again Warning and Failed SureBackup jobs
            If ($vsbOnHoldJobs) {
                Do {
                    $Msg = "Start OnHold jobs -ne 'Success' loop, i=$i"
                    "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                    Write-Verbose -Message $Msg

                    $VsbJobs = $vsbOnHoldJobs
                    $vsbOnHoldJobs = @()

                    ForEach ($VsbJob In $VsbJobs) {
                        $VsbJobName = $VsbJob.Name

                        $Msg = "Starting job -ne 'Success': $VsbJobName"
                        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                        Write-Verbose -Message $Msg

                        If ('Stopped' -ne (Get-VTBackupJobStatus -Name $VsbJobName)) {
                            $Msg = "Adding to OnHold que: '$VsbJobName'"
                            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                            Write-Verbose -Message $Msg

                            $vsbOnHoldJobs += $VsbJob
                            Continue
                        }

                        Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName @StateOff
                        $VsbJob | Start-VSBJob -ErrorAction SilentlyContinue
                        Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName @StateOn
                    }
                    If ($vsbOnHoldJobs) {
                        Start-Sleep -Seconds 600
                    }
                } While ($vsbOnHoldJobs)
            }
            #endregion
        } Else {
            $Msg = "No jobs for vLab:$VirtualLabName vLabID:$VirtualLabId"
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg
        }
        $Msg = "End"
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
Function Test-VTSureBackupJob {

    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.Void])]
    Param (
        #VbrServer
        [Parameter(Mandatory)]
        [System.String]$VirtualLabName,
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
        Get-Info -Type i -Message $Msg | Out-File -FilePath $Log -Append
        Write-Verbose -Message $Msg

        #region present surebackup check
        $Msg = 'Listing jobs...'
        Write-Verbose -Message $Msg
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
        $VsbJobs = Get-VSBJob | Where-Object -FilterScript {
            $_.VirtualLabId -eq $VirtualLabId
        } | Sort-Object -Property Name

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

                    Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName -State 'Off' -Verbose
                    $VsbJob | Start-VSBJob -ErrorAction SilentlyContinue
                    Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName -State 'On' -Verbose
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

                        Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName -State 'Off' -Verbose
                        $VsbJob | Start-VSBJob -ErrorAction SilentlyContinue
                        Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName -State 'On' -Verbose
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

                    Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName -State 'Off' -Verbose
                    $VsbJob | Start-VSBJob -ErrorAction SilentlyContinue
                    Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName -State 'On' -Verbose
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

                        Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName -State 'Off' -Verbose
                        $VsbJob | Start-VSBJob -ErrorAction SilentlyContinue
                        Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName -State 'On' -Verbose
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
                $VsbJobs = Get-VSBJob | Where-Object -FilterScript {
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

                        Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName -State 'Off' -Verbose
                        $VsbJob | Start-VSBJob -ErrorAction SilentlyContinue
                        Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName -State 'On' -Verbose
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

                        Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName -State 'Off' -Verbose
                        $VsbJob | Start-VSBJob -ErrorAction SilentlyContinue
                        Set-VTDuplicateVMOnOff -Name $VsbJobName -vLabName $VirtualLabName -State 'On' -Verbose
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
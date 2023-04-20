Function Start-VTBackupTest {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.String])]
    Param (
        $vLabHostName,
        # PSCredential
        [Parameter()]
        [System.Management.Automation.PSCredential]$CredentialVeeam,
        # PSCredential
        [Parameter()]
        [System.Management.Automation.PSCredential]$CredentialHyperV,
        [Parameter()]
        [Switch]$Auto
    )

    $ProcessName = $MyInvocation.MyCommand.Name

    $Script:VTConfig.LogFile = $Script:VTConfig.LogFile -replace ('.log', "-$vLabHostName.log")
    $Script:VTConfig.LogFileError = $Script:VTConfig.LogFileError -replace ('.log', "-$vLabHostName.log")
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError

    $Tag = 'VeeamBackup'

    $domain = $Script:VTConfig.Domain

    $To = "IT-Alert-$Tag@$domain"
    $From = "$Tag@$domain"

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

        if ($Auto) {
            # Get credentials
            $PathModule = (Get-Module -Name (Get-Command -Name $MyInvocation.MyCommand).ModuleName -ListAvailable | Select-Object ModuleBase -First 1).ModuleBase
            $CredentialImported = Import-Clixml -Path "$PathModule\Configuration\Data.dat"

            $CredentialVeeam = $CredentialImported | Where-Object -FilterScript {
                $PSItem.UserName -eq $Script:VTConfig.Credentials.VBR.UserName
            }
            $CredentialHyperV = $CredentialImported | Where-Object -FilterScript {
                $PSItem.UserName -eq $Script:VTConfig.Credentials.HyperV.UserName
            }

            if (-not $CredentialVeeam) {
                $CredentialVeeam = $CredentialImported[1]
            }
            if (-not $CredentialHyperV) {
                $CredentialHyperV = $CredentialImported[-1]
            }
        }

        if ($CredentialVeeam) {
            Set-VTParameterPartFast -CredentialVeeam $CredentialVeeam
        } else {
            Set-VTParameterPartFast
        }

        $DependencyToRestore = $Script:VTConfig.DependencyToRestore

        $HostvLabs = $Script:VTVirtualLab | Where-Object -FilterScript {
            $PSItem.Host -eq $vLabHostName
        } | Select-Object -ExpandProperty Name -Unique | Sort-Object -Descending

        $Msg = "Starting RSJob for vLabs: '{0}' on '{1}'" -f ($HostvLabs -join ', '), $vLabHostName
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
        Write-Verbose -Message $Msg

        ForEach ($vLabName In $HostvLabs) {
            $Msg = "LabName: $vLabName"
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg

            $ComputerToConnect = (($DependencyToRestore).Where( { $PSItem.vLabName -eq $vLabName })).ComputerName

            $HostObject = ($Script:VTVirtualLab | Where-Object -FilterScript {
                    $PSItem.Name -eq $vLabName
                })

            $Msg = "HostName: $($HostObject.Host) LabName: $vLabName"
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg

            If ($HostObject.Type -eq 'HyperV') {
                ForEach ($ComputerName In $ComputerToConnect) {
                    $Msg = "Reconfiguring switch for: '$ComputerName', on: '$($HostObject.Host)', vLab: '$vLabName'."
                    "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
                    Write-Verbose -Message $Msg

                    #Set-VTVMSwichAndState -ComputerName $ComputerName -vLabHostName $HostObject.Host -vLabName $vLabName -Verbose
                    $SetVTVMSwichAndState = @{
                        ComputerName = $ComputerName
                        vLabHostName = $HostObject.Host
                        vLabName     = $vLabName
                        Verbose      = $true
                    }
                    if ($CredentialHyperV) {
                        $SetVTVMSwichAndState += @{
                            CredentialHyperV = $CredentialHyperV
                        }
                    }
                    Set-VTVMSwichAndState @SetVTVMSwichAndState
                }
            }
            $Msg = "Tests starts for vLab: '$vLabName'."
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Write-Verbose -Message $Msg

            $testVTSureBackupJob = @{
                VirtualLabName = $vLabName
                Tries          = 2
                Verbose        = $true
            }
            if ($CredentialHyperV) {
                $testVTSureBackupJob += @{
                    CredentialHyperV = $CredentialHyperV
                }
            }
            Test-VTSureBackupJob @testVTSureBackupJob
        }
        $Msg = "End"
        "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append

        $htmlFragments = $htmlFoot
        $Attachments = @($Log)
        Send-ObjectivityEmail -From $From -To $To -Subject $Subject -HtmlFragments $htmlFragments -Attachments $Attachments
    } Catch {
        $Attachments = @($Log, $LogError)
        $('#' * 80) | Out-File -FilePath $LogError -Append
        $Error | Out-File -FilePath $LogError -Append
        $htmlFragment = $_ | ConvertTo-Html -Fragment -As List
        $htmlFragments = $htmlFragment + $htmlFoot
        Send-ObjectivityEmail -From $From -To $To -Subject $SubjectError -HtmlFragments $htmlFragments -Attachments $Attachments
    }
}
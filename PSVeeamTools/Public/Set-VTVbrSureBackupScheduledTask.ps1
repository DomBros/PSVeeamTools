Function Set-VTVbrSureBackupScheduledTask {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.Void])]
    Param (
        # Credentials for Scheduled Tasks creation and running
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$CredentialScheduledTask,
        # PSCredential
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$CredentialVeeam,
        # Credentials for HyperV
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$CredentialHyperV,
        [Parameter()]
        [Switch]$DependVmRebuild,
        [Parameter()]
        [Switch]$Auto
    )

    If (-not $CredentialScheduledTask) {
        $CredentialScheduledTask = (Get-Credential -Message 'Credentials for Scheduled Tasks creation and running' -UserName "$env:USERDOMAIN\$env:USERNAME")
    }

    if ($Auto) {
        $PathModule = (Get-Module -Name (Get-Command -Name $MyInvocation.MyCommand).ModuleName -ListAvailable | Select-Object ModuleBase -First 1).ModuleBase
        $DataFile = "$PathModule\Configuration\Data.dat"
        if (-not (Test-Path -Path $DataFile)) {
            $Credentials = $CredentialScheduledTask
            $Credentials += $CredentialVeeam
            $Credentials += $CredentialHyperV

            Invoke-Command -ComputerName localhost {
                $Using:Credentials | Export-Clixml -Path $Using:DataFile
            } -Credential $CredentialScheduledTask
        }
    }

    Set-VTParameterPartFast -CredentialVeeam $CredentialVeeam

    $VLabsHostNames = $Script:VTVirtualLab | Select-Object -ExpandProperty Host -Unique | Sort-Object

    # remove old Scheduled Tasks
    $taskName = 'PSVeeamTools VBR Sure Backup *'
    $tasks = Get-ScheduledTask | Where-Object {
        $_.TaskName -like $taskName
    }
    If ($null -ne $tasks) {
        ForEach ($task In $tasks) {
            $task | Unregister-ScheduledTask -Confirm:$false
            Write-Verbose "Task $($task.TaskName) was removed"
        }
    }

    If ($DependVmRebuild) {
        if ($PSBoundParameters.ContainsKey('CredentialHyperV')) {
            Remove-VTvLabAllDependVM -CredentialHyperV $CredentialHyperV -Verbose
            Set-VTvLabAllDependency -CredentialHyperV $CredentialHyperV -Verbose
        } else {
            Remove-VTvLabAllDependVM
            Set-VTvLabAllDependency
        }
    }

    $Password = $CredentialScheduledTask.GetNetworkCredential().Password
    $UserName = $CredentialScheduledTask.UserName

    $i = 1
    $VLabsHostNames | ForEach-Object -Process {
        $i++
        $Msg = "Procesing: $PSItem"
        Write-Verbose $Msg

        $RemoteCommand = @"
Import-Module -Name 'PSVeeamTools'
Import-Module -Name 'Veeam.Backup.PowerShell'
Start-VTBackupTest -vLabHostName $PSItem -Verbose
"@
        if ($Auto) {
            $RemoteCommand = @"
Import-Module -Name 'PSVeeamTools'
Import-Module -Name 'Veeam.Backup.PowerShell'
Start-VTBackupTest -vLabHostName $PSItem -Auto -Verbose
"@
        }


        $bytes = [System.Text.Encoding]::Unicode.GetBytes($RemoteCommand)
        $encodedCommand = [Convert]::ToBase64String($bytes)

        # register script as scheduled task
        $DateStart = Get-Date ((Get-Date).AddMinutes($i)) -Format 'HH:mm'
        $Trigger = New-ScheduledTaskTrigger -Once -At $DateStart
        #$User = "SYSTEM"
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ex bypass -encodedCommand $encodedCommand"
        $Settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit "48:00:00"
        Register-ScheduledTask -TaskName "PSVeeamTools VBR Sure Backup $PSItem" -Trigger $Trigger -User $UserName -Password $Password -Action $Action -Settings $Settings -RunLevel Highest -Force
    }
}
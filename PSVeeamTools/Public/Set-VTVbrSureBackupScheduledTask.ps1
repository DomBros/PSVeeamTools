Function Set-VTVbrSureBackupScheduledTask {
    
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.Void])]
    Param (
        # Credentials for Scheduled Tasks creation and running
        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential,
        [Parameter()]
        [Switch]$DependVmRebuild
    )
    
    If (-not $Credential) {
        $Credential = (Get-Credential -Message 'Credentials for Scheduled Tasks creation and running' -UserName "$env:USERDOMAIN\$env:USERNAME")
    }
    
    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError
    
    $Script:VTVirtualLab = Get-VTVirtualLab -Verbose
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
        Remove-VTvLabAllDependVM -Verbose
        Set-VTvLabAllDependency -Verbose
    }
        
    $Password = $Credential.GetNetworkCredential().Password
    $UserName = $Credential.UserName
    
    $i = 1
    $VLabsHostNames | ForEach-Object -Process {
        $i++
        $Msg = "Procesing: $PSItem"
        Write-Verbose $Msg
        
        $RemoteCommand = @"
Import-Module 'PSVeeamTools'
Start-VTBackupTest -vLabHostName $PSItem -Verbose
"@
        
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
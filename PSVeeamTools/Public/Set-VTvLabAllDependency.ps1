#Requires –Modules PoshRSJob
Function Set-VTvLabAllDependency {
    
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.Void])]
    Param ()
    
    $ProcessName = $MyInvocation.MyCommand.Name
    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError
    
    Try {
        Set-VTParameterPartFast
        
        $DependencyToRestore = $Script:VTConfig.DependencyToRestore | Sort-Object -Property vLabName -Descending
        
        ForEach ($dependencyObject In $DependencyToRestore) {
            $Msg = "ComputerName: '$($dependencyObject.ComputerName)' vLabName: '$($dependencyObject.vLabName)'"
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            Start-RSJob -ScriptBlock {
                $dependencyObject = $USING:dependencyObject
                Set-VTvLabDependency -ComputerName $dependencyObject.ComputerName -vLabName $dependencyObject.vLabName -Verbose
            }
            Start-Sleep -Seconds 10
        }
        Get-RSJob | Wait-RSJob
        Get-RSJob | Receive-RSJob
        Get-RSJob | Receive-RSJob | Out-File -FilePath $Log -Append
        Get-RSJob | Remove-RSJob
        
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
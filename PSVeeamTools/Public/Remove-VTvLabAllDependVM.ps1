Function Remove-VTvLabAllDependVM {
    
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
            $HyperVHost = (($Script:VTVirtualLab).Where({
                        $PSItem.Name -eq $dependencyObject.vLabName
                    })).Host
            
            $Msg = "$HyperVHost $($dependencyObject.vLabName) $($dependencyObject.ComputerName)"
            "[$ProcessName] [$((Get-Date).ToString())] [Info] $Msg" | Out-File -FilePath $Log -Append
            
            Remove-VTvLabDependVM -HyperVHost $HyperVHost -ComputerName $dependencyObject.ComputerName -Verbose
        }
    } Catch {
        Get-Date | Out-File -FilePath $LogError -Append
        $_ | Out-File -FilePath $LogError -Append
        Throw $_
    }
}
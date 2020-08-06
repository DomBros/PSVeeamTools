Param (
    # Computer Address you want to test.
    [Parameter(Mandatory = $true, HelpMessage = "Computer Address you want to test")]
    $ComputerAddress,
    
    # The name or names (not a display name) of the services to check. (For example: dhcp, gpsvc, SstpSvc)
    [Parameter(Mandatory = $true, HelpMessage = "The name or names (not a display name) of the services to check.'
        (For example: dhcp, gpsvc, SstpSvc)")]
    $Services
    
)

Invoke-Command -ComputerName $ComputerAddress -ScriptBlock {
    
    #Test for invoke command execution availability
    Try {
        Test-Path -Path "C:\Windows"
        $reachable = $true
    } Catch {
        $reachable = $false
        $ExitCode = 1
    }
    
    #IF invoke command test is OK Going to test services
    If ($reachable -eq $true) {        
        $ScriptTestResult += ForEach ($serviceName In $Using:Services) {
            $serviceObj = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            If ($serviceObj -ne $null -and $serviceObj.Status -eq "Running") {
                $ServiceTest = @{
                    "$serviceName" = "Running"
                }
            } ElseIf ($serviceObj -ne $null -and $serviceObj.Status -ne "Running") {
                $ServiceTest = @{
                    "$serviceName" = "NotRunning"
                }
            } ElseIf ($serviceObj -eq $null) {
                $ServiceTest = @{
                    "$serviceName" = "NotFound"
                }
            }
            $ServiceTest
        }
        
        If ($ScriptTestResult.Values -contains "NotFound" -or $ScriptTestResult.values -ccontains "NotRunning") {
            Write-Host -ForegroundColor Red "Some Tests Failed"
            $ExitCode = 1
        } Else {
            Write-Host -ForegroundColor Green "All Tests are OK"
            $ExitCode = 0
            
        }
        
    } Else {
        Write-Host -ForegroundColor Red "Can't invoke command on server. Skipping next tests"
        $ExitCode = 1
    }
    
    Exit $ExitCode
    
} -Authentication Negotiate
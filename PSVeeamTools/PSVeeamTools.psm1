Set-StrictMode -Version Latest

# we're setting 'Stop' globally to ensure that each exception stops the script from running
$Global:ErrorActionPreference = 'Stop'

#region include all needed files

. "$PSScriptRoot\Configuration\PSVeeamToolsConfig.Default.ps1"

#Get public and private function definition files.
$Public = @(Get-ChildItem -Recurse -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Recurse -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue | Where-Object {
        $_ -notmatch '\.Examples.ps1'
    })

#Dot source the files
ForEach ($import In @($Public + $Private)) {
    Try {
        . $import.fullname
    } Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

Export-ModuleMember -Function $Public.Basename
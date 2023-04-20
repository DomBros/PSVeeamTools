Function Start-VTVeeamZip {
    <#
    .SYNOPSIS
		Add VM to VeeamZip repo
	.DESCRIPTION
		Add VM to VeeamZip repo
    .EXAMPLE
        $vmNames = 'LABPLWAP1', 'LABPLADFS0'
        Start-VTVeeamZip -VMNames $vmNames
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([Void])]
    Param (
        [Parameter()]
        [System.String[]]$VMNames,
        [Parameter()]
        [System.String]$HostName = 'HV1',
        [Parameter()]
        [System.String]$ScaleOutName = 'Scale-out Repository',
        [Parameter()]
        [System.String]$EncryptionKey = 'VeeamZip master password',
        [Parameter()]
        [System.String]$AutoDelete = 'In6Months',
        # PSCredential
        [Parameter()]
        [System.Management.Automation.PSCredential]$CredentialVeeam
    )

    if ($PSBoundParameters.ContainsKey('CredentialVeeam')) {
        Set-VTConnection -Credential $CredentialVeeam
    } else {
        Set-VTConnection
    }

    foreach ($vmName in $vmNames) {
        $vmName
        Get-VM -ComputerName $HostName -Name $vmName | Stop-VM -Force

        $vm = Find-VBRHvEntity -Name $vmName
        $rep = Get-VBRBackupRepository -ScaleOut -Name $ScaleOutName
        $enc = Get-VBREncryptionKey -Description $EncryptionKey
        Start-VBRZip -BackupRepository $rep -Entity $vm -Compression 9 -DisableQuiesce -RunAsync -EncryptionKey $enc -AutoDelete $AutoDelete
    }
}
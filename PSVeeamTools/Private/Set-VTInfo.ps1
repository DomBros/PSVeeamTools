Function Set-VTInfo {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    Param (
        # Type can be: 'i' for Info, 'w' for Warn, 'e' for Error)]
        [Alias('t')]
        [Parameter()]
        [System.String]$Type = 'i',
        # Message
        [Alias('m')]
        [Parameter()]
        [System.String]$Message,
        # Message
        [Alias('s')]
        [Parameter()]
        [Switch]$FunctionStart,
        # Message
        [Alias('o')]
        [Parameter()]
        [Switch]$LogOverWrite,
        # ProcessName will mark in log which function is running now
        [Alias('p')]
        [Parameter()]
        [System.String]$ProcessName,
        # ProcessName will mark in log which function is running now
        [Parameter()]
        [System.String]$Tag
    )

    $Log = $Script:VTConfig.LogFile
    $LogError = $Script:VTConfig.LogFileError

    if ($LogOverWrite) {
        $Append = $false
    } else {
        $Append = $true
    }

    if ($Type -eq 'e') {
        $FilePath = $LogError
    } else {
        $FilePath = $Log
    }

    if ($Type -eq 'i') {
        $Type = 'Info'
    } elseif ($Type -eq 'w') {
        $Type = 'Warn'
    } elseif ($Type -eq 'e') {
        $Type = 'Error'
    } else {
        $Type = 'Info'
    }

    if ($FunctionStart -and -not $Message) {
        $Message = 'START function'
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    $callerFunction = (Get-PSCallStack)[1]
    if ($callerFunction.InvocationInfo -and $callerFunction.InvocationInfo.MyCommand -and $callerFunction.InvocationInfo.MyCommand.Name) {
        $callerNameCommand = $callerFunction.InvocationInfo.MyCommand.Name
    } else {
        $callerNameCommand = $null;
    }
    if ($callerFunction.ScriptName) {
        $callerNameScript = Split-Path -Leaf $callerFunction.ScriptName
    } else {
        $callerNameScript = '';
    }
    if ($callerFunction.ScriptLineNumber) {
        $callerLineNumber = $callerFunction.ScriptLineNumber
    } else {
        $callerLineNumber = ''
    }

    if (-not $callerNameCommand) {
        $callerNameCommand = $callerNameScript
    }

    $msg = "[$timestamp] [$callerNameCommand] [$callerLineNumber] [$Type] $Message"

    $msg | Out-File -FilePath $FilePath -Append:$Append

    Write-Verbose -Message $msg

    if ($Type -eq 'Error') {
        Throw $msg
    }
}
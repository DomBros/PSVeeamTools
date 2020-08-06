# Default configuration object. It is used through whole PSVeeamTools module.

$Script:VTConfig = [PSCustomObject]@{
    VBRServer                             = 'VBR1'
    LogFile                               = '{0}\PSVeeamTools-{1}.log' -f $env:TEMP, (Get-Date -Format 'yyyyMMddHHmmssfff')
    LogFileError                          = '{0}\PSVeeamToolsErrors-{1}.log' -f $env:TEMP, (Get-Date -Format 'yyyyMMddHHmmssfff')
    MailTo                                = 'IT-Alert-VeeamBackup@test.co.uk'

    ExcludeHostFromBackupSearch           = 'PLT*' # T stands for Test
    ExcludeBackupJob                      = 'Test'
    ExcludeVMFromSureJob                  = 'WROVC', 'WRONTC', 'wrc-wfv'

    DependencyToRestore                   = @(
        [PSCustomObject]@{
            ComputerName = 'PDC0'
            vLabName     = 'vLab-A'
        },
        [PSCustomObject]@{
            ComputerName = 'PDC0'
            vLabName     = 'vLab-B'
        },
        [PSCustomObject]@{
            ComputerName = 'PDC0'
            vLabName     = 'vLab-C'
        },
        [PSCustomObject]@{
            ComputerName = 'PDC0'
            vLabName     = 'vLab-E'
        },
        [PSCustomObject]@{
            ComputerName = 'PDC0'
            vLabName     = 'vLab-F'
        },
        [PSCustomObject]@{
            ComputerName = 'PDC0'
            vLabName     = 'vLab-G'
        },
        [PSCustomObject]@{
            ComputerName = 'TEST-AD'
            vLabName     = 'vLab-J'
        },
        [PSCustomObject]@{
            ComputerName = 'LAB'
            vLabName     = 'vLab-J'
        },
        [PSCustomObject]@{
            ComputerName = 'PDC0'
            vLabName     = 'vLab-S'
        }
    )
    vLabParameters                        = @(
        [PSCustomObject]@{
            vLabName      = 'vLab-A'
            vLan          = @('1', '1203')
            VM            = @()
            BackupJobName = @()
        },
        [PSCustomObject]@{
            vLabName      = 'vLab-B'
            vLan          = @('1204', '1205', '1206', '1207', '1208', '1209')
            VM            = @()
            BackupJobName = @()
        },
        [PSCustomObject]@{
            vLabName      = 'vLab-C'
            vLan          = @('1210', '1211', '1212', '1213', '1214', '1215')
            VM            = @()
            BackupJobName = @()
        },
        [PSCustomObject]@{
            vLabName      = 'vLab-E'
            vLan          = @('1301', '1302', '1303', '1304', '1305', '1306')
            VM            = @()
            BackupJobName = @()
        },
        [PSCustomObject]@{
            vLabName      = 'vLab-F'
            vLan          = @('1307', '1308', '1309', '1310', '1311', '1312')
            VM            = @()
            BackupJobName = @()
        },
        [PSCustomObject]@{
            vLabName      = 'vLab-G'
            vLan          = @('1313', '1314', '1315', '1316', '1317', '1318')
            VM            = @()
            BackupJobName = @()
        },
        [PSCustomObject]@{
            vLabName      = 'vLab-H'
            vLan          = @('1319')
            VM            = @()
            BackupJobName = @()
        },
        [PSCustomObject]@{
            vLabName      = 'vLab-J'
            vLan          = @('991', '12511', '12516', '12517')
            VM            = @('COVNPS1', 'COVFS1', 'COVSDC1')
            BackupJobName = @()
        },
        [PSCustomObject]@{
            vLabName      = 'vLab-S'
            vLan          = @()
            VM            = @('ERPAPP', 'ERPSQL')
            BackupJobName = @()
        },
        [PSCustomObject]@{
            vLabName      = 'vLab-T'
            vLan          = @()
            VM            = @()
            BackupJobName = @()
        }
    )
    Tag                                   = 'PSVeeamTools'
    SureJobNamePrefix                     = 'Test'
    ComputerNamevLabPrefix                = 'vLab-'

    vLabNameHyperVDefault                 = 'vLab-A'
    vLabNameVMwareDefault                 = 'vLab-X'
    SearchFormVMinBackupNotOlderThanHours = 72
    VmNeededInApplicationGroup            = 'PDC0'
    $DefaultVMvLan                        = '3'
}
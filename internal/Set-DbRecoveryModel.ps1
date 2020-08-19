
function Set-DbRecoveryModel {
    [CmdletBinding()]
    Param(
        # Target instance
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String] $SqlInstance,

        # Target Database
        [Parameter(Mandatory = $true, Position = 1)]
        [System.String] $Database,

        # Transfer path, default defined
        [Parameter(Mandatory = $false, Position = 2)]
        [System.String] $TransferPath = '\\MyServer\MyFolder\Transfer'
    )

    Begin {
        $ErrorActionPreference = 'Stop'
    }
    Process {

        if ((Get-DbaDbRecoveryModel -SqlInstance $SqlInstance -Database $Database).RecoveryModel -eq 'FULL') {

            # remove spids
            Invoke-KillDbConnections -SqlInstance $SqlInstance  -Database $Database

            # set db simple recovery
            Write-PSFMessage -Level Host -Message "Changing recovery model"
            Get-DbaDatabase -SqlInstance $SqlInstance -Database "$Database" | `
                Set-DbaDbRecoveryModel -RecoveryModel Simple -Confirm:$false | Out-Null

            Write-PSFMessage -Level Host -Message "Taking back up"
            $filename = "$Database`_RecoveryChange.bak"

            $backupParams = @{
                SqlInstance = $SqlInstance
                Database = $Database
                Path = $TransferPath
                FilePath = $filename
                CopyOnly = $true
                IgnoreFileChecks = $true
            }
            Backup-DbaDatabase @backupParams | Out-Null

            # remove backup artefact
            Write-PSFMessage -Level Host -Message "Removing artefact: $filename"
            Get-ChildItem -Path $TransferPath -Filter *$filename* | Remove-Item
        }
        else {
            Write-PSFMessage -Level Host -Message "$Database on $SqlInstance in simple recovery"
        }
    }
}
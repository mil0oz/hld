function Set-HldConfigName {

    Param (
        [CmdletBinding()]
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('INT','TEST','UAT','NONPROD','DEMO')]
        [System.String] $TargetEnvironment,
        [Parameter(Mandatory = $false, Position = 1)]
        [System.String] $Database = 'HighLevelDashBoard'
    )

    Begin
    {
        $ErrorActionPreference = 'Stop'

        ### Switch region starts
        $dbString = 'HLD_Config'
        switch ($TargetEnvironment) {

            'DEV' {
                $NewName = "$dbString`_DEV"
                $SqlInstance = ''
            }
            'INT' {
                $Database = "$Database`_INTEGRATION"
                $RemovalDb = 'HLD_Config_INTEGRATION'
                $NewName = "$dbString`_INTEGRATION"
                $SqlInstance = '<SERVERNAME>'
            }
            'DEMO' {
                $Database = "$Database`_DEMO"
                $RemovalDb = 'HLD_Config_DEMO'
                $NewName = "$dbString`_DEMO"
                $SqlInstance = '<SERVERNAME>'
            } 
            'TEST' {
                $Database = "$Database`_TESTING"
                $RemovalDb = 'HLD_Config_TESTING'
                $NewName = "$dbString`_TESTING"
                $SqlInstance = '<SERVERNAME>'
            }
            'UAT' {
                $Database = "$Database`_UAT"
                $RemovalDb = 'HLD_Config_UAT'
                $NewName = "$dbString`_UAT"
                $SqlInstance = '<SERVERNAME>'
            }
            'NONPROD' {
                $Database = "$Database`_NONPROD"
                $RemovalDb = 'HLD_Config_NONPROD'
                $NewName = "$dbString`_NONPROD"
                $SqlInstance = '<SERVERNAME>'
            }
            'PROD' {
                $NewName = "$dbString`_PROD"
                $SqlInstance = ''
            }
        }
        ### region ends

        $sql = "DROP DATABASE $RemovalDb"

        if (!(Get-DbaDatabase -SqlInstance $SqlInstance -Database $Database)) {
            Write-PSFMessage -Level Host -Message "$Database not present, nothing to process, exiting"
            Break
        }
    }

    Process
    {
        # if exists kill connections on target db and drop it
        if (Get-DbaDatabase -SqlInstance $SqlInstance -Database $RemovalDb) {

            Write-PSFMessage -Level Host -Message "Removing $RemovalDb"
            Invoke-KillDbConnections -SqlInstance $SqlInstance -Database $RemovalDb

            Invoke-DbaQuery -SqlInstance $SqlInstance -Database master -Query $sql -QueryTimeout 0 -ErrorAction Stop
            Write-PSFMessage -Level Host -Message "$RemovalDb removed"
        }

        # grab exclusive lock and rename db
        Invoke-KillDbConnections -SqlInstance $SqlInstance -Database $Database
        $params = @{
            SqlInstance  = $SqlInstance
            Database     = $Database
            DatabaseName = $NewName
            Filename     = "$NewName"
            LogicalName  = "$NewName"
            # With move ensures filenames are renamed
            Move         = $true
            ErrorAction  = 'Stop'
        }
        [void]::(Rename-DbaDatabase @params)
        Write-PSFMessage -Level Host -Message "Renamed $NewName"

        # Apply db permissions from SCM
        Set-DatabasePermissions -SqlInstance $SqlInstance -Database $NewName
    }
}
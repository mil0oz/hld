<#
.Synopsis
   Restores backups with replace
.DESCRIPTION
   Restores database from either live/preprod back to HLD MDF PREP server
.EXAMPLE
   Migrates from LIVEDB to UAT HLD server
   Invoke-TheGreatMigrator -SourceServer LIVEDB -TargetEnvironment UAT
.EXAMPLE
   Generates restore script to validate database operations
   Invoke-TheGreatMigrator -SourceServer LIVEDB -Script
.EXAMPLE
   Restores MDF from prod/preprod ontp server
   Invoke-TheGreatMigrator -SourceServer LIVEDB
#>

function Invoke-TheGreatMigrator
{
    [CmdletBinding()]
    Param
    (
        # Source connection server
        [Parameter(Mandatory = $true , Position = 0)]
        [ValidateNotNullOrEmpty()]
        [System.String] $SourceServer,

        # Source database to migrate
        [Parameter(Mandatory = $false , Position = 1)]
        [ValidatePattern("^(MyDrFoster|HLD|IdentityServer|Identity|HighLevelDashboard)")]
        [System.String] $Database,

        # Environment rule dictates target server
        [Parameter(Mandatory = $false , Position = 2)]
        [ValidateSet('DEMO','DEV','INT','TEST','UAT','NONPROD','PREPROD','PROD')]
        [System.String] $TargetEnvironment,

        # Target server for migration
        [Parameter(Mandatory = $false , Position = 3)]
        [ValidateNotNullOrEmpty()]
        [System.String] $TargetServer,

        # Network shared used for backup and restore
        [Parameter(Mandatory = $false , Position = 4)]
        [System.String] $TransferPath = '\\MyFileServer\Transfer',

        # Switch spits out a restore script
        [Parameter(Mandatory = $false , Position = 5)]
        [switch] $Script
    )

    Begin
    {
        $ErrorActionPreference = 'Stop'

        $sw = [Diagnostics.Stopwatch]::StartNew()

        ### Import AllFunctions so we can determine live and preprod servers
        try {
            Import-Module AllFunctions -DisableNameChecking
        }
        catch {
            Write-PSFMessage -Level Critical -message "Failed to import AllFunctions" -ErrorRecord Stop
            throw $_
            [Environment]::Exit()
        }
        ### Region ends

        ### strip environment from DB name if passed
        $CleanDatabase = $Database.Split("_")[0]
        Write-Host "Working database is: $CleanDatabase"

        ### switch region
        switch ($TargetEnvironment) {

            'Local' {
                $TargetServer = $env:localhost
                $DatabaseName = "$CleanDatabase`_Local"
                Write-PSFMessage -Level Host -Message "TargetEnvironment Local, migrating to $TargetServer"
                Write-PSFMessage -Level Host -Message "Database $Database tagged $DatabaseName based off switch input"
            }

            'DEV' {
                $TargetServer = '<SERVERNAME>'
                $DatabaseName = "$CleanDatabase`_DEV"
                $Suffix       = "`_DEV"
                Write-PSFMessage -Level Host -Message "TargetEnvironment DEV, migrating to $TargetServer"
                Write-PSFMessage -Level Host -Message "Database $Database tagged $DatabaseName based off switch input"
            }

            'INT' {
                $TargetServer = '<SERVERNAME>'
                $DatabaseName = "$CleanDatabase`_INTEGRATION"
                $Suffix       = "`_INTEGRATION"
                Write-PSFMessage -Level Host -Message "TargetEnvironment INT, migrating to $TargetServer"
                Write-PSFMessage -Level Host -Message "Database $Database tagged $DatabaseName based off switch input"
            }

            'DEMO' {
                $TargetServer = '<SERVERNAME>'
                $DatabaseName = "$CleanDatabase`_DEMO"
                $Suffix       = "`_DEMO"
                Write-PSFMessage -Level Host -Message "TargetEnvironment DEMO, migrating to $TargetServer"
                Write-PSFMessage -Level Host -Message "Database $Database tagged $DatabaseName based off switch input"
            }

            'TEST' {
                $TargetServer = '<SERVERNAME>'
                $DatabaseName = "$CleanDatabase`_TESTING"
                $Suffix       = "`_TESTING"
                Write-PSFMessage -Level Host -Message "TargetEnvironment TEST, migrating to $TargetServer"
                Write-PSFMessage -Level Host -Message "Database $Database tagged $DatabaseName based off switch input"
            }

            'UAT' {
                $TargetServer = '<SERVERNAME>'
                $DatabaseName = "$CleanDatabase`_UAT"
                $Suffix       = "`_UAT"
                Write-PSFMessage -Level Host -Message "TargetEnvironment UAT, migrating to $TargetServer"
                Write-PSFMessage -Level Host -Message "Database $Database tagged $DatabaseName based off switch input"
            }

            'NONPROD' {
                if ( $CleanDatabase.Contains("IDENTITY") ) { $TargetServer = 'LIVEDB' } else { $TargetServer = '<SERVERNAME>' }
                $DatabaseName = "$CleanDatabase`_NONPROD"
                $Suffix       = "`_NONPROD"
                Write-PSFMessage -Level Host -Message "TargetEnvironment NONPROD, migrating to $TargetServer"
                Write-PSFMessage -Level Host -Message "Database $Database tagged $DatabaseName based off switch input"
            }

            'PREPROD' {
                $TargetServer = '<SERVERNAME>'
                $DatabaseName = "$CleanDatabase`_PREPROD"
                $Suffix       = "`_PREPROD"
                Write-PSFMessage -Level Host -Message "TargetEnvironment PREPROD, migrating to $TargetServer"
                Write-PSFMessage -Level Host -Message "Database $Database tagged $DatabaseName based off switch input"
            }

            'PROD' {
                $TargetServer = '<SERVERNAME>'
                $DatabaseName = $CleanDatabase
                Write-PSFMessage -Level Host -Message "TargetEnvironment *** PROD ***, migrating to $TargetServer"
                Write-PSFMessage -Level Host -Message "Database $Database tagged $DatabaseName based off switch input"
            }
        }
        if (!($TargetEnvironment)) {
            $DatabaseName = $Database
        }
        ### Switch region ends

        ### Filename and debug output region
        Write-PSFMessage -Level Host -message "Source server is $SourceServer"
        Write-PSFMessage -Level Host -message "Source database is $Database"
        Write-PSFMessage -Level Host -message "Transfer filepath is $TransferPath"
        $TimeNow = Get-Date -Format yyyyMMddhhmmss
        $BackupFile = "$DatabaseName`_$TimeNow.bak"
        Write-PSFMessage -Level Host -message "Backup artefact will be $BackupFile"
        ### Region ends

        ### Validation region
        # test network share path
        $validateSplat = @{
            TransferPath = $TransferPath
            SourceServer = $SourceServer
            TargetServer = $TargetServer
            Database     = $Database
        }
        Validate-AllTheThings @validateSplat
        ### Validation Tests end

        ### Database backup region
        $BackupParams = @{
            SqlInstance      = $SourceServer
            Database         = $Database
            BackupDirectory  = $TransferPath
            BackupFileName   = $BackupFile
            IgnoreFileChecks = $true
            CopyOnly         = $true
            CompressBackup   = $true
            ErrorAction      = 'Stop' # can we use $DefaultErrorAction here?
        }
        ### region ends

        ### Database restore region
        $RestoreParams = @{
            SqlInstance                      = $TargetServer
            DatabaseName                     = $DatabaseName
            Path                             = "$TransferPath\$BackupFile"
            DestinationFileSuffix            = $suffix
            UseDestinationDefaultDirectories = $true
            WithReplace                      = $true
            ErrorAction                      = 'Stop'
        }
        ### region ends
    }
    Process
    {
        Write-PSFMessage -level Host -Message "Beginning $Database transfer"
        try
        {
            Write-PSFMessage -level Host -Message "Backing up $Database on $SourceServer"
            # Backup source db silently to network share
            [void]::(Backup-DbaDatabase @BackupParams)
        }
        catch {
            Write-PSFMessage -level Critical -Message "DB Backup failed" -ErrorRecord $_
            Break
        }

        ### Generate tsql restore script
        if ($Script)
        {
            Write-PSFMessage -level Host -Message "Generating restore script"
            try
            {
                Restore-DbaDatabase @RestoreParams -OutputScriptOnly
            }
            catch {
                Write-PSFMessage -level Critical -Message "Failed to generate script" -ErrorRecord $_
                [System.Environment]::Exit(1)
            }
        }
        ### region ends

        else
        {
            # Kill all connections on target databases
            Invoke-KillDbConnections -SqlInstance $TargetServer -Database $DatabaseName

            try
            {

                Write-PSFMessage -level Host -Message "Restoring $DatabaseName on $TargetServer from $TransferPath\$BackupFile"

                # Restore database on target
                [void]::(Restore-DbaDatabase @RestoreParams -EnableException)
                Write-PSFMessage -level Host -Message "Restored $DatabaseName"

                # Set db owner to sa
                [void]::(Set-DbaDbOwner -SqlInstance $TargetServer -Database $DatabaseName -TargetLogin 'sa')
                Write-PSFMessage -level Host -Message "Database owner set to sa"

            }
            catch {
                Write-PSFMessage -level Critical -Message "Restore for $DatabaseName on $TargetServer failed" -ErrorRecord $_
                [System.Environment]::Exit(1)
            }

            # Strip non-system users
            Remove-DbUsers -Server $TargetServer -Database $DatabaseName

            # Set permissions from git and set simple recovery model for all non Local migrations
            if ($TargetEnvironment -notmatch 'Local')
            {
                Set-DatabasePermissions -SqlInstance $TargetServer -Database $DatabaseName -ErrorAction SilentlyContinue

                Set-DBRecoveryModel -SqlInstance $TargetServer -Database $DatabaseName -ErrorAction SilentlyContinue
            }
            else {
                Write-PSFMessage -level Host -Message "Target is $TargetEnvironment so skipping permissions application"
            }
        }

        # Cleanup artefacts remaining
        Get-ArtefactsForCleanup -TransferPath $TransferPath
    }
    End
    {
        $sw.Stop()
        $time = $sw.Elapsed

        Write-PSFMessage -level Host -Message "Migrated $Database from $SourceServer to $TargetServer"
        Write-PSFMessage -Level Host -Message "Runtime : $time"
    }
}
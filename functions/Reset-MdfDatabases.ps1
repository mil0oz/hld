<#
.Synopsis
   Restores live db artefact onto targets depending on environment.
.DESCRIPTION
   Restores live db artefact onto targets depending on environment.
.EXAMPLE
   PS> Reset-MdfDatabases -TargetEnvironment DEV
   Restores latest production backup onto Dev HLD environment
#>
function Reset-MdfDatabases
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('DEMO','DEV','INT','TEST','UAT','NONPROD')]
        [System.String] $TargetEnvironment
    )

    begin {

        $ErrorActionPreference = 'Stop'

        Import-Module DbaTools,PSFramework -Scope Local -ErrorAction Stop

        $sw = [Diagnostics.Stopwatch]::StartNew() # start a timer

        [string] $Artefact = '\\MyServer\ArtefactStore\MyFolder\Databases\MyDbName.bak'

        [string] $GlobalDbName = 'MyDbName'

        [hashtable] $Constants = @{
            Path                                = $Artefact
            UseDestinationDefaultDirectories    = $true
            WithReplace                         = $true
        }

    }

    process {

        switch ($TargetEnvironment)
        {
            'DEV'
            {
                [System.String] $Suffix = 'DEV'
                [hashtable] $Restore = @{
                    SqlInstance                         = '<SERVERNAME>'
                    DatabaseName                        = "$GlobalDbName`_$Suffix"
                    DestinationFileSuffix               = "_$Suffix"
                }
            }
            'INT'
            {
                [System.String] $Suffix = 'INTEGRATION'
                [hashtable] $Restore = @{
                    SqlInstance                         = '<SERVERNAME>'
                    DatabaseName                        = "$GlobalDbName`_$Suffix"
                    DestinationFileSuffix               = "_$Suffix"
                }
            }
            'TEST'
            {
                [System.String] $Suffix = 'TESTING'
                [hashtable] $Restore = @{
                    SqlInstance                         = '<SERVERNAME>'
                    DatabaseName                        = "$GlobalDbName`_$Suffix"
                    DestinationFileSuffix               = "_$Suffix"
                }
            }
            'UAT'
            {
                [System.String] $Suffix = 'UAT'
                [hashtable] $Restore = @{
                    SqlInstance                         = '<SERVERNAME>'
                    DatabaseName                        = "$GlobalDbName`_$Suffix"
                    DestinationFileSuffix               = "_$Suffix"
                }
            }
            'NONPROD'
            {
                [System.String] $Suffix = 'NONPROD'
                [hashtable] $Restore = @{
                    SqlInstance                         = '<SERVERNAME>'
                    DatabaseName                        = "$GlobalDbName`_$Suffix"
                    DestinationFileSuffix               = "_$Suffix"
                }
            }
        }
    }

    end {

        # Database restore
        Write-PSFMessage -Level Host -Message "Restoring MDF onto $($Restore.SqlInstance) as $($Restore.DatabaseName)"
        [void]::(Restore-DbaDatabase @Constants @Restore)

        # Rename the logical filenames
        Write-PSFMessage -Level Host -Message "Changing logical filenames to $($Restore.DatabaseName)"
        [void]::(Rename-DbaDatabase -SqlInstance $($Restore.SqlInstance) -Database $($Restore.DatabaseName) -LogicalName $($Restore.DatabaseName))

        # Set db owner to sa
        Write-PSFMessage -level Host -Message "Setting database owner set to sa"
        [void]::(Set-DbaDbOwner -SqlInstance $($Restore.SqlInstance) -Database $($Restore.DatabaseName) -TargetLogin 'sa')

        # Strip restored and orphaned db users
        Write-PSFMessage -level Host -Message "Removing non-system database users"
        Remove-DbUsers -Server $($Restore.SqlInstance) -Database $($Restore.DatabaseName) -ErrorAction Continue

        # Set permissions from SCM
        Write-PSFMessage -level Host -Message "Setting database permissions"
        Set-DatabasePermissions -SqlInstance $($Restore.SqlInstance) -Database $($Restore.DatabaseName) -ErrorAction Continue

        # Handle setting recovery mode simple
        Write-PSFMessage -level Host -Message "Setting db recovery model"
        Set-DBRecoveryModel -SqlInstance $($Restore.SqlInstance) -Database $($Restore.DatabaseName) -ErrorAction Continue

        Write-PSFMessage -Level Host -Message "Execution complete"
        $sw.Stop()
        $time = $sw.Elapsed
        Write-PSFMessage -Level Host -Message "Runtime: $time"

    }
}
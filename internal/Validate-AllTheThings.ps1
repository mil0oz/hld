function Validate-AllTheThings
{
    [CmdletBinding()]
    param (
        # unc path for transient files
        [Parameter(Mandatory=$false)]
        [System.String] $TransferPath,

        # validate source sql server online
        [Parameter(Mandatory=$false)]
        [System.String] $SourceServer,

        # validate target sql server online
        [Parameter(Mandatory=$false)]
        [System.String] $TargetServer,

        # validate source database name
        [Parameter(Mandatory=$false)]
        [System.String] $Database
    )

    $ErrorActionPreference = 'Stop'

    Write-PSFMessage -Level Host -message "Validating source and target parameters"

    if (!(Test-Path $TransferPath))
    {
        Write-PSFMessage -level Warning -Message "Unable to connect to $TransferPath" -ErrorRecord $_
        [Environment]::Exit(1)
    }
    # test source db and instance
    if (!(Test-DbaConnection -SqlInstance $SourceServer))
    {
        Write-PSFMessage -level Critical -Message "Unable to connect to source instance $SourceServer" -ErrorRecord $_
        [Environment]::Exit(1)
    }
    # test destination db and instance
    if (!(Test-DbaConnection -SqlInstance $TargetServer))
    {
        Write-PSFMessage -level Warning -Message "Unable to connect to target instance $TargetServer" -ErrorRecord $_
        [Environment]::Exit(1)
    }
    # [Environment]::Exit(1) if source database does not exist
    if(!(Get-DbaDatabase -SqlInstance $SourceServer -Database $Database))
    {
        Write-PSFMessage -Level Critical -Message "Database $Database does not exit on $SourceServer"
        [Environment]::Exit(1)
    }

    Write-PSFMessage -Level Host -message "Validation complete."

}
function Invoke-KillDbConnections
{
    [CmdletBinding()]
    Param(
        # Target Sql Instance
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$SqlInstance,

        # Target Database
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Database
    )

    $ErrorActionPreference = 'Stop'

    Set-DbaDbState -SqlInstance $SqlInstance -Database $Database -Offline -Force -ErrorAction Stop | Out-Null

    Set-DbaDbState -SqlInstance $SqlInstance -Database $Database -Online -ErrorAction Stop | Out-Null

    Write-PSFMessage -Level Host -Message "All connections killed to $SqlInstance\$Database"
}


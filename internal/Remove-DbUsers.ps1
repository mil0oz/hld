function Remove-DbUsers {
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory = $false, Position = 0)]
        [System.String] $Server,

        # Param2 help description
        [Parameter(Mandatory = $true, Position = 1)]
        [System.String] $Database
    )

    Begin {

        $ErrorActionPreference = 'Stop'

        # get database users but exlude system accounts
        $Users = Get-DbaDbUser -SqlInstance $Server -Database $Database -ExcludeSystemUser

        if ($Users.Count -ge 1) {
            Write-PSFMessage -Level Host -Message "Detected users to remove"
        }
        else {
            Write-PSFMessage -Level Host -Message "No users to remove"
            Return
        }
    }

    Process {

        # remove each user
        foreach ($user in $users) {

            try {
                $user | Remove-DbaDbUser -Force | Out-Null
                Write-PSFMessage -Level Host -Message "Removed $user from $Server.$Database"
            }
            catch {
                Write-PSFMessage -Level Critical -Message "" -ErrorRecord $_
                Break
            }

        }
    }
}
function Set-DatabasePermissions {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string] $SqlInstance,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $Database
    )

    Begin {

        $filepath = "\\MyServer\MyPermissionsFolder\$SqlInstance"
        if (!(Test-Path -Path $filepath\$Database.sql)) {
            Write-PSFMessage -Level Host -Message "No sql script file on the end of $filepath\$Database.sql" #-ErrorRecord $_ -ErrorAction SilentlyContinue
            Return
        }
        else {
            $file = (Get-ChildItem -Path $filepath\$Database.sql).Name
        }

        Write-PSFMessage -Level Host -Message "Applying permissions against $SqlInstance.$Database"
    }

    Process {

        $PresentState = (Get-DbaDbState -SqlInstance $SqlInstance -Database $Database).RW
        Write-PSFMessage -Level Host -Message "$Database is $PresentState"

        if ($PresentState -eq 'READ_ONLY') {

            Write-PSFMessage -Level Host -Message "Setting $SqlInstance to read_write"
            Set-DbaDbState -SqlInstance $SqlInstance -Database $Database -ReadWrite -Force -ErrorAction Stop | Out-Null

            try {
                Invoke-DbaQuery -SqlInstance $SqlInstance -InputFile $filepath\$file -Database $Database
                Write-PSFMessage -Level Host -Message "Applied permissions to $Database on $SqlInstance from $filepath\$file"
            }
            catch {
                Write-PSFMessage -Level Warning -Message "Failed to apply permissions" -ErrorRecord $_ -ErrorAction Stop
            }

            Write-PSFMessage -Level Host -Message "Setting $SqlInstance back to READ_ONLY"
            Set-DbaDbState -SqlInstance $SqlInstance -Database $Database -ReadOnly -Force -ErrorAction Stop | Out-Null

        }

        if ($PresentState -eq 'READ_WRITE') {

            try {
                Invoke-DbaQuery -SqlInstance $SqlInstance -InputFile $filepath\$file -Database $Database
                Write-PSFMessage -Level Host -Message "Applied permissions to $Database on $SqlInstance from $filepath\$file"
            }
            catch {
                Write-PSFMessage -Level Warning -Message "Failed to apply permissions" -ErrorRecord $_ -ErrorAction Continue
            }

        }
    }
}
function Get-ArtefactsForCleanup
{
    [CmdletBinding()]
    Param(
        # Default path where artefacts are held
        [Parameter(Mandatory = $false , Position = 0)]
        [System.String] $TransferPath = '\\MyServer\MyFolder\Transfer'
    )

    Begin {
        $ErrorActionPreference = 'Stop'

        $files = Get-ChildItem -Path $TransferPath -File *.bak | Select-Object -First 5 | Sort-Object LastWriteTime
    }

    Process {

        try {

            Write-PSFMessage -level Host -Message "Removing backup files from $TransferPath"

            foreach ($file in $files) {

                $file | Remove-Item
                Write-PSFMessage -level Host -Message "Removed $transferpath\$file"

                }
        }
        catch {
            Write-PSFMessage -level Warning -Message "Failed to delete $BackupFile from $TransferPath" -ErrorRecord $_
        }
    }
}
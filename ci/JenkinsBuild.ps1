# Line break for readability in AppVeyor console
Write-Host -Object ''

try {
    Import-Module BuildHelpers
    Write-PSFMessage -Level Host -Message "Imported BuildHelpers"
}
catch {
    Write-PSFMessage -Level Critical -Message "Failed to import BuildHelpers" -ErrorRecord $_
    [Environment]::Exit(1)
}

$moduleName = Get-ProjectName
Write-PSFMessage -Level Host -Message "Building $moduleName"

$ErrorActionPreference = 'STOP'

# set environemt

Write-PSFMessage -Level Host "BHModulePath is ${env:workspace}"
Write-PSFMessage -Level Host "BHManifestPath is ${env:workspace}\$moduleName.psd1"
Write-PSFMessage -Level Host "Workspace is ${env:workspace}"
Write-PSFMessage -Level Host "Testing for manifest"

# check for manifest file
if (!(Test-Path ${env:workspace}\$moduleName.psd1)) {
    Write-PSFMessage -Level Host "No valid manifest to update, exiting"
    [Environment]::Exit()
}

# update functions to export
Update-ModuleManifest -Path "${env:workspace}\$moduleName.psd1" -FunctionsToExport * | Out-Null
Write-PSFMessage -Level Host "Updating functions to export"
$list = (Get-ChildItem -Path "${env:workspace}\functions\*.ps1" | `
            ForEach-Object -Process { [System.IO.Path]::GetFileNameWithoutExtension($_) })
$list | ForEach-Object { "'$_'" } | Out-Null
$list -join "','" | Out-Null
Update-ModuleManifest -Path "${env:workspace}\$moduleName.psd1" -FunctionsToExport $list | Out-Null
Write-PSFMessage -Level Host -Message "Exported functions: $(Get-Metadata -Path "${env:workspace}\$moduleName.psd1" -PropertyName FunctionsToExport)"

# Versioning
Write-PSFMessage -Level Host "Incrementing module build version"
#Step-ModuleVersion -Path $ENV:BHPSModuleManifest -By Build -Verbose
Update-ModuleManifest -Path "${env:workspace}\$moduleName.psd1" -ModuleVersion "0.2.${env:BUILD_NUMBER}"

# Test manifest validity
Write-PSFMessage -Level Host "Testing manifest"
Test-ModuleManifest -Path "${env:workspace}\$moduleName.psd1" -ErrorAction Stop | Out-Null
Write-PSFMessage -Level Host "Manifest test passed"

# write new version number to console
Write-PSFMessage -Level Host -Message "$moduleName module version: $(Get-Metadata -Path "${env:workspace}\$moduleName.psd1")"

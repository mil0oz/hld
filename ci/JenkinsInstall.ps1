# Line break for readability in AppVeyor console
Write-Host -Object ''

[string[]] $PowerShellModules = @("BuildHelpers", "PSFramework", "posh-git", "PSScriptAnalyzer", "Pester")
[string[]] $PackageProviders  = @("NuGet", "PowerShellGet")

# Install package providers for PowerShell Modules
ForEach ($Provider in $PackageProviders) {
  If (!(Get-PackageProvider $Provider -ErrorAction SilentlyContinue)) {
    Install-PackageProvider $Provider -Force -ForceBootstrap -Scope CurrentUser
    Write-Host "Installed provider $provider"
  }
}

# Install the PowerShell Modules
ForEach ($Module in $PowerShellModules) {
  If (!(Get-Module -ListAvailable $Module -ErrorAction SilentlyContinue)) {
    Install-Module $Module -Scope CurrentUser -Force -Repository PSGallery -AllowClobber
    Write-Host "Installed module $Module"
  }
  Import-Module $Module
  Write-Host "Imported $module"
}

Write-Host "Completed installing pre reqs"
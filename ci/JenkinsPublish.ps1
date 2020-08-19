# Line break for readability in AppVeyor console
Write-Host -Object ''

# Ensure pre reqs are loaded
if (!(Get-Module -Name BuildHelpers)) {
    Write-Host "Loading BuildHelpers module"
    Import-Module BuildHelpers
}

# Publish variables
$script:ModuleName = Get-ProjectName
$script:Gallery = 'MyGallery'

# ensure MyGallery registered
if (!((Get-PSRepository).Name -eq $script:Gallery)) {
  Write-PSFMessage -Level Critical -Message "$script:Gallery not configured or registered" -ErrorAction Stop
  [Environment]::Exit(1)
}

Write-PSFMessage -Level Host -Message "Starting publish region"

Write-PSFMessage -Level Host -Message "Module is $script:ModuleName"

# Set tls encryption
try {
  Write-PSFMessage -Level Host -Message "Changing security protocol to tls1.2"
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}
catch {
  Write-PSFMessage -Level Warning -Message "Failed to set security protocol"
  throw $_
  [Environment]::Exit(1)
}

if (${env:GIT_BRANCH} -eq 'master') {
    try {
        Write-PSFMessage -Level Host -Message "Changing location to ${env:WORKSPACE}"
        Set-Location ${env:WORKSPACE}
        Write-PSFMessage -Level Host -Message "Publishing to $script:Gallery"
        Publish-Module -Name ${env:workspace}\$moduleName.psd1 -Repository $script:Gallery
        Write-PSFMessage -Level Host -Message "Published"
    }
    catch {
        throw $_
        [Environment]::Exit(1)
    }
}
else {
    Write-PSFMessage -Level Host -Message "Branch is ${env:GIT_BRANCH} so not publishing"
}

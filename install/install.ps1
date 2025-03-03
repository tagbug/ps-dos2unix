<#
.SYNOPSIS
User-level one-click installation script
#>

$ErrorActionPreference = "Stop"
$documentsPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)
$modulePath = Join-Path $documentsPath "WindowsPowerShell\Modules\dos2unix"

try {
    # Create directory
    if (-not (Test-Path $modulePath)) {
        New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
    }

    # Download module files
    $baseUrl = "https://raw.githubusercontent.com/tagbug/ps-dos2unix/main/src/"
    Invoke-WebRequest "$baseUrl/dos2unix.psm1" -OutFile "$modulePath/dos2unix.psm1"
    Invoke-WebRequest "$baseUrl/dos2unix.psd1" -OutFile "$modulePath/dos2unix.psd1"

    # Add module path
    if ($env:PSModulePath -notmatch [regex]::Escape($modulePath)) {
        [Environment]::SetEnvironmentVariable(
            "PSModulePath", 
            "$([Environment]::GetEnvironmentVariable('PSModulePath', 'User'));$modulePath", 
            "User"
        )
    }

    Write-Host "✅ Installation successful! Type dos2unix -Help for help"
}
catch {
    Write-Error "Installation failed: $_"
    Remove-Item $modulePath -Recurse -Force -ErrorAction SilentlyContinue
}
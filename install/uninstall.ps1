<#
.SYNOPSIS
User-level one-click uninstallation script
#>

$documentsPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)
$modulePath = Join-Path $documentsPath "WindowsPowerShell\Modules\dos2unix"

try {
    # Remove module files
    if (Test-Path $modulePath) {
        Remove-Item $modulePath -Recurse -Force
    }

    # Clean up environment variables
    $newPath = ($env:PSModulePath -split ';' | 
        Where-Object { $_ -ne $modulePath }) -join ';'
    [Environment]::SetEnvironmentVariable("PSModulePath", $newPath, "User")

    Write-Host "✅ Uninstallation successful"
}
catch {
    Write-Warning "Error during uninstallation: $_"
}
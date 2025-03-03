function dos2unix {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Path = ".",
        [string[]]$Exclude = @("node_modules", "dist", ".git"),
        [bool]$SkipGitignore = $true,
        [string]$Encoding,
        [switch]$Help,
        [string[]]$WhiteList = @("txt","bat","cmd","ini","reg","sh","xml","md","html","css","js","ts","java","c","cpp","jsx","tsx","gradle","properties","yaml","json","ps1","config","log","py","php","rb","go","swift","kt"),
        [string[]]$BlackList = @("exe","dll","png","jpg","jpeg","gif","bmp","mp3","mp4","avi","mov","zip","rar","7z","gz","pdf","doc","docx","xls","xlsx","ppt","pptx","msi","iso","bin","jar","war","dat","pdb","lib","obj","so","dylib"),
        [string]$MaxFileSize = "1MB",
        [switch]$ConvertEncoding,
        [string]$TargetEncoding = "utf-8"
    )

    # Help information
    if ($Help) {
        Write-Host @"
Usage: dos2unix [-Path <string>] [-Exclude <string[]>] [-SkipGitignore <bool>] 
       [-Encoding <string>] [-WhiteList <string[]>] [-BlackList <string[]>]
       [-MaxFileSize <string>] [-ConvertEncoding] [-TargetEncoding <string>] [-Help]

Parameters:
  -Path            Target directory (default: current directory)
  -Exclude         Directories to exclude (default: node_modules, dist, .git)
  -SkipGitignore   Skip files matched by .gitignore (default: true)
  -Encoding        Force specific encoding
  -WhiteList       Allowed file extensions (default: common text formats)
  -BlackList       Blocked file extensions (default: common binary formats)
  -MaxFileSize     Maximum file size (default: 1MB)
  -ConvertEncoding Enable encoding conversion
  -TargetEncoding  Target encoding when conversion enabled (default: UTF8)
  -Help            Show this help message
"@
        return
    }

    # Parse file size limit
    $sizeUnit = $MaxFileSize -replace '\d',''
    $sizeValue = [double]($MaxFileSize -replace '[^\d.]','')
    $maxBytes = switch ($sizeUnit.ToUpper()) {
        "KB" { $sizeValue * 1KB }
        "MB" { $sizeValue * 1MB }
        "GB" { $sizeValue * 1GB }
        default { $sizeValue }
    }

    # Resolve path
    $resolvedPath = Resolve-Path $Path
    Write-Verbose "Processing path: $resolvedPath"

    # Get all files and exclude specified directories
    $allFiles = Get-ChildItem -Path $resolvedPath -File -Recurse
    $filteredFiles = $allFiles | Where-Object {
        $filePath = $_.FullName
        $excludeMatch = $Exclude | Where-Object { $filePath -match [regex]::Escape($_) }
        $excludeMatch.Count -eq 0
    }

    # Handle .gitignore exclusion
    if ($SkipGitignore) {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            $filteredFiles = $filteredFiles | Where-Object {
                $output = git check-ignore $_.FullName 2>&1
                $LASTEXITCODE -ne 0
            }
        } else {
            Write-Warning "Git not found, .gitignore processing skipped"
        }
    }

    # Process file filtering and conversion
    foreach ($file in $filteredFiles) {
        try {
            $ext = $file.Extension.TrimStart('.')
            $fullPath = $file.FullName

            # Check file size
            if ($file.Length -gt $maxBytes) {
                Write-Warning "Skipped large file: $fullPath ($([math]::Round($file.Length/1MB,2)) MB)"
                continue
            }

            # Check blacklist and whitelist
            if ($BlackList -contains $ext) {
                Write-Verbose "Skipped blacklisted: $fullPath"
                continue
            }
            if (-not ($WhiteList -contains $ext)) {
                # Binary file detection
                $isBinary = $false
                $buffer = [System.IO.File]::ReadAllBytes($fullPath) | Select-Object -First 1024
                $nonTextCount = $buffer | Where-Object { $_ -gt 127 -or ($_ -lt 32 -and $_ -notin 9,10,13) } | Measure-Object | Select-Object -Expand Count
                if ($nonTextCount -gt ($buffer.Count * 0.3)) {
                    Write-Warning "Skipped binary file: $fullPath"
                    continue
                }
            }

            # Detect encoding
            $fileEncoding = $null
            $hasBom = $false
            
            if ($Encoding) {
                $fileEncoding = [System.Text.Encoding]::GetEncoding($Encoding)
            } else {
                $bomBytes = [System.IO.File]::ReadAllBytes($fullPath) | Select-Object -First 4
                if ($bomBytes[0] -eq 0xEF -and $bomBytes[1] -eq 0xBB -and $bomBytes[2] -eq 0xBF) {
                    $fileEncoding = [System.Text.Encoding]::UTF8
                    $hasBom = $true
                } else {
                    $stream = New-Object System.IO.FileStream($fullPath, [System.IO.FileMode]::Open)
                    $reader = New-Object System.IO.StreamReader($stream, $true)
                    $null = $reader.ReadToEnd()
                    $fileEncoding = $reader.CurrentEncoding
                    $reader.Close()
                    $stream.Close()
                }
            }

            # Read content
            $content = if ($Encoding) {
                Get-Content -Path $fullPath -Raw -Encoding $fileEncoding
            } else {
                [System.IO.File]::ReadAllText($fullPath, $fileEncoding)
            }

            # Replace CRLF
            $newContent = $content -replace "`r`n", "`n"
            
            # Encoding conversion
            if ($ConvertEncoding) {
                try {
                    # Add alias conversion before GetEncoding call
                    $normalizedEncoding = switch -Wildcard ($TargetEncoding.ToLower()) {
                        "utf8"    { "utf-8" }
                        "unicode" { "utf-16" }
                        "ascii"   { "us-ascii" }
                        default   { $TargetEncoding }
                    }
                    $targetEnc = [System.Text.Encoding]::GetEncoding($normalizedEncoding)
                } catch {
                    Write-Warning "Unsupported encoding name '$TargetEncoding'. Supported encodings:"
                    Write-Warning ([System.Text.Encoding]::GetEncodings() | 
                        Select-Object -First 10 |  # Example shows the first 10
                        ForEach-Object { "$($_.Name) [code page $($_.CodePage)]" } | 
                        Join-String -Separator "`n")
                    return
                }
                
                if ($fileEncoding -ne $targetEnc) {
                    try {
                        $newContent = $targetEnc.GetString([System.Text.Encoding]::Convert($fileEncoding, $targetEnc, $fileEncoding.GetBytes($newContent)))
                        $fileEncoding = $targetEnc
                        $hasBom = $false
                    } catch {
                        Write-Warning "Encoding conversion failed: $_"
                        continue
                    }
                }
            }


            if ($newContent -eq $content) {
                Write-Verbose "No changes needed: $fullPath"
                continue
            }

            # Write file
            $bytes = $fileEncoding.GetBytes($newContent)
            if ($hasBom -and $fileEncoding -eq [System.Text.Encoding]::UTF8) {
                $bytes = $fileEncoding.GetPreamble() + $bytes
            }
            [System.IO.File]::WriteAllBytes($fullPath, $bytes)
            
            Write-Host "Converted: $fullPath"
        } catch {
            Write-Warning "Error processing $fullPath : $_"
        }
    }
}

Export-ModuleMember -Function dos2unix
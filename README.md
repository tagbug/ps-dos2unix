# DOS2Unix-PowerShell

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

> Smart cross-platform line ending converter with advanced encoding support

**English** | [中文文档](docs/README_ZH.md)

## Features ✨

- 🎯 Smart encoding detection (BOM-aware)
- 📁 Recursive directory processing
- ⚡ Automatic .gitignore integration (requires Git)
- 🛡️ Binary file protection mechanism
- 🔄 On-the-fly encoding conversion (UTF-8/16/32)
- 📏 Configurable file size limit (default 1MB)
- 📝 File type whitelist/blacklist system

## Installation 💻

### Quick Install

```powershell
irm https://raw.githubusercontent.com/tagbug/ps-dos2unix/main/install/install.ps1 | iex
```

### Manual Install

```powershell
# 1. Clone the repository
git clone https://github.com/tagbug/ps-dos2unix.git

# 2. Create user module directory
$documentsPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)
$userModulePath = Join-Path $documentsPath "WindowsPowerShell\Modules\dos2unix"
New-Item -Path $userModulePath -ItemType Directory -Force

# 3. Copy module files
Copy-Item ./ps-dos2unix/src/* $userModulePath -Recurse

# 4. Verify installation
Import-Module dos2unix -Force
dos2unix -Help
```

⚠ **Note:** If you encounter installation issues, try switching the line ending of the source code to CRLF.

### Uninstall

Uninstall for quick install:
```powershell
irm https://raw.githubusercontent.com/tagbug/ps-dos2unix/main/install/uninstall.ps1 | iex
```

Uninstall for manual install:
```powershell
# 1. Remove module directory
$documentsPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)
$userModulePath = Join-Path $documentsPath "WindowsPowerShell\Modules\dos2unix"
Remove-Item $userModulePath -Recurse -Force

# 2. Clean up environment variables
$newPath = ($env:PSModulePath -split ';' | 
    Where-Object { $_ -notmatch "dos2unix" }) -join ';'
[Environment]::SetEnvironmentVariable("PSModulePath", $newPath, "User")

# 3. Remove cloned repository (optional)
Remove-Item ./dos2unix -Recurse -Force
```

## Usage Example 🚀

Basic Conversion:
```powershell
# Convert current directory
dos2unix

# Specify path with verbose output
dos2unix -Path D:\Projects -Verbose
```

Advanced Usage:
```powershell
# Convert with encoding to UTF-8
dos2unix -Path ./src -ConvertEncoding -TargetEncoding utf-8

# Exclude directories
dos2unix -Exclude node_modules,bin

# Process large files
dos2unix -MaxFileSize 10MB

# Custom file filtering
dos2unix -WhiteList "cs,json" -BlackList "exe,dll"
```

## Configuration Options 🛠️

| Parameter        | Description                        | Default |
|------------------|------------------------------------|---------|
| -Path            | Target directory path              | Current directory |
| -Exclude         | Directories to exclude             | node_modules, dist, .git |
| -Encoding        | Force specific encoding            | Auto-detect |
| -WhiteList       | Allowed file extensions            | Common text formats |
| -BlackList       | Blocked file extensions            | Common binary formats |
| -MaxFileSize     | Max file size (supports KB/MB/GB)  | 1MB |
| -ConvertEncoding | Enable encoding conversion         | $false |
| -TargetEncoding  | Target encoding format             | utf-8 |

## FAQ 🤔

**Q: File encoding issues after conversion?**
→ **Backup files before processing!**
→ Try specifying encoding format: `-Encoding utf8` 
→ Check original file encoding: `Get-Content -Encoding Byte -TotalCount 3`

**Q: Slow processing speed?**
→ Add excluded directories: `-Exclude node_modules`  
→ Adjust file size limit: `-MaxFileSize 500KB`

## License 📄

This project is licensed under the [MIT License](./LICENSE)

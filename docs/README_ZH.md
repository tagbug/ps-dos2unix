# DOS2Unix-PowerShell

[![许可证: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

> 智能跨平台行尾符转换工具，支持高级编码处理

**中文** | [English Document](../README.md)

## 功能亮点 ✨

- 🎯 智能编码检测（自动识别BOM）
- 📁 递归处理目录结构
- ⚡ 自动集成.gitignore（需要Git环境）
- 🛡️ 二进制文件保护机制
- 🔄 实时编码转换（支持UTF-8/16/32）
- 📏 可配置文件大小限制（默认1MB）
- 📝 文件类型白名单/黑名单系统

## 安装方式 💻

### 快速安装

```powershell
irm https://raw.githubusercontent.com/tagbug/ps-dos2unix/main/install/install.ps1 | iex
```

### 手动安装

```powershell
# 1. 克隆仓库
git clone https://github.com/tagbug/ps-dos2unix.git

# 2. 创建用户模块目录
$documentsPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)
$userModulePath = Join-Path $documentsPath "WindowsPowerShell\Modules\dos2unix"
New-Item -Path $userModulePath -ItemType Directory -Force

# 3. 复制模块文件
Copy-Item ./ps-dos2unix/src/* $userModulePath -Recurse

# 4. 验证安装
Import-Module $userModulePath -Force
dos2unix -Help
```

⚠ **注意：** 如果遇到安装问题，请尝试将源代码的行尾符转换为CRLF。

### 卸载

快速安装对应的卸载方式：
```powershell
irm https://raw.githubusercontent.com/tagbug/ps-dos2unix/main/install/uninstall.ps1 | iex
```

手动安装对应的卸载方式：
```powershell
# 1. 删除模块目录
$documentsPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)
$userModulePath = Join-Path $documentsPath "WindowsPowerShell\Modules\dos2unix"
Remove-Item $userModulePath -Recurse -Force

# 2. 清理环境变量
$newPath = ($env:PSModulePath -split ';' | 
    Where-Object { $_ -notmatch "dos2unix" }) -join ';'
[Environment]::SetEnvironmentVariable("PSModulePath", $newPath, "User")

# 3. 删除克隆的仓库（可选）
Remove-Item ./dos2unix -Recurse -Force
```

## 使用示例 🚀

基础转换:
```powershell
# 转换当前目录
dos2unix

# 指定路径并显示详细信息
dos2unix -Path D:\Projects -Verbose
```

高级用法:
```powershell
# 转换并转码为UTF-8
dos2unix -Path ./src -ConvertEncoding -TargetEncoding utf-8

# 排除指定目录
dos2unix -Exclude node_modules,bin

# 处理大文件
dos2unix -MaxFileSize 10MB

# 自定义文件过滤
dos2unix -WhiteList "cs,json" -BlackList "exe,dll"
```

## 配置选项 🛠️

| 参数              | 描述                        | 默认值 |
|------------------|-----------------------------|---------|
| -Path            | 目标路径                     | 当前目录 |
| -Exclude         | 排除目录列表                  | node_modules, dist, .git |
| -Encoding        | 强制指定编码解析               | 自动 |
| -WhiteList       | 允许的文件扩展名               | 常见文本格式 |
| -BlackList       | 阻止的文件扩展名               | 常见二进制格式 |
| -MaxFileSize     | 最大处理文件大小 (支持KB/MB/GB) | 1MB |
| -ConvertEncoding | 启用编码转换                   | $false |
| -TargetEncoding  | 转换到目标编码格式              | utf-8 |

## 常见问题 🤔

**Q：转换后文件出现乱码？**  
→ **提前备份要处理的文件！**
→ 尝试指定编码格式：`-Encoding utf8`  
→ 检查原始文件编码：`Get-Content -Encoding Byte -TotalCount 3`

**Q：处理速度慢？**  
→ 添加排除目录：`-Exclude node_modules`  
→ 调整文件大小限制：`-MaxFileSize 500KB`

## 许可证 📄

本项目采用[MIT许可证](./LICENSE)

# encoding: UTF-8 with BOM
# non-ASCII (Japanese) user name
$UserName = "日本語ユーザー名"
$InstLang = "-lang=ja"
# Paths
$Root    = "C:\TestUsers"
$UserDir = Join-Path $Root $UserName
$TempDir = Join-Path $UserDir "Temp"
$DataDir = Join-Path $UserDir "AppData"

# Change CodePage to Japanese
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage" -Name "ACP" -Value "932"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage" -Name "OEMCP" -Value "932"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage" -Name "MACCP" -Value "10001"

# Recreate directory structure
Remove-Item $Root -Recurse -Force -ErrorAction SilentlyContinue
New-Item $UserDir -ItemType Directory -Force | Out-Null
New-Item $TempDir -ItemType Directory -Force | Out-Null
New-Item $DataDir -ItemType Directory -Force | Out-Null

# Stop inheriting from the parent directory.
icacls $UserDir /inheritance:d | Out-Null
# Root: prevent creation of new directories/files
# This will cause an error if the path contains garbled characters.
icacls $Root /inheritance:r | Out-Null
icacls $Root /grant "Everyone:(RX)" | Out-Null
icacls $Root /deny "Everyone:(WD,AD)" | Out-Null


Write-Host "::group::ACL state (icacls)"
icacls $Root /T
Write-Host "::endgroup::"

# Set environment variables
$env:TMP  = $TempDir
$env:TEMP = $TempDir
$env:HOME = $UserDir
$env:USERPROFILE = $UserDir
$env:APPDATA = $DataDir
$env:LOCALAPPDATA = $DataDir

# Install directory
$InstallDir = Join-Path $env:TEMP "install-tl"
New-Item $InstallDir -ItemType Directory -Force | Out-Null

# Copy installer from repository
Copy-Item "*" $InstallDir -Recurse

Write-Host "::group::install-tl dir"
Get-ChildItem $InstallDir
Write-Host "::endgroup::"

# Run installer from that directory
Write-Host "::group::Run TeX Live installer"
Push-Location $InstallDir
try {
    .\install-tl-windows.bat $InstLang -v -no-gui -profile=.github/workflows/windows.profile
}
finally {
    Pop-Location
}
Write-Host "::endgroup::"

Write-Host "::group::Check User Dir"
Get-ChildItem $UserDir
Write-Host "::endgroup::"

tlmgr.bat --version

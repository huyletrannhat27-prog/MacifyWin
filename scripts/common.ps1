# Ham dung chung cho MacifyWin

$script:RepoRoot  = Split-Path -Parent $PSScriptRoot
$script:DataDir   = Join-Path $env:LOCALAPPDATA "MacifyWin"
$script:BackupDir = Join-Path $script:DataDir "backup"

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [!]  $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "  [X]  $msg" -ForegroundColor Red }

function Get-WindowsInfo {
    $build = [Environment]::OSVersion.Version.Build
    return [PSCustomObject]@{
        Build   = $build
        IsWin11 = ($build -ge 22000)
    }
}

function Ensure-BackupDir {
    if (-not (Test-Path $script:BackupDir)) {
        New-Item -ItemType Directory -Force -Path $script:BackupDir | Out-Null
    }
}

function Backup-RegistryKey {
    param(
        [string]$RegPath,
        [string]$BackupName
    )
    Ensure-BackupDir
    $outFile = Join-Path $script:BackupDir $BackupName
    # Chi backup lan dau de giu nguyen trang thai goc cua Windows
    if (Test-Path $outFile) { return }

    & reg.exe export $RegPath $outFile /y 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Da sao luu $RegPath -> $BackupName"
    }
}

function New-MacifyRestorePoint {
    Write-Step "Tao diem khoi phuc he thong (System Restore Point)"
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "MacifyWin Pre-Install" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Ok "Da tao System Restore Point thanh cong."
    } catch {
        Write-Warn "Khong the tao Restore Point (co the do gioi han 24h cua Windows): $($_.Exception.Message)"
    }
}

function Install-WingetPackage {
    param([string]$Id, [string]$Name)
    Write-Host "  -> Dang cai $Name ($Id)..." -NoNewline
    & winget install --id $Id -e --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
        Write-Host " Xong" -ForegroundColor Green
    } else {
        Write-Host " Loi (ma $LASTEXITCODE)" -ForegroundColor Yellow
    }
}

function Restart-ExplorerSafe {
    Write-Step "Khoi dong lai Windows Explorer"
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Start-Process explorer.exe
    Write-Ok "Explorer da khoi dong lai."
}


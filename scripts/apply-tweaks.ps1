param([string]$Theme = "Dark")
. "$PSScriptRoot\common.ps1"

Write-Step "Ap dung tinh chinh Windows Registry (Theme: $Theme)"

# 1. Dong bo Dark / Light Mode
$useLight = if ($Theme -eq "Light") { 1 } else { 0 }
$persPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
Set-ItemProperty -Path $persPath -Name "AppsUseLightTheme"    -Value $useLight -Type DWord
Set-ItemProperty -Path $persPath -Name "SystemUsesLightTheme" -Value $useLight -Type DWord
Write-Ok "Da dat che do $Theme Mode."

# 2. Tu dong an Taskbar goc cua Windows de Dock cua Seelen UI hien thi sach se
$stuckPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"
if (Test-Path $stuckPath) {
    $sr = (Get-ItemProperty -Path $stuckPath -Name "Settings").Settings
    if ($sr -and $sr.Length -gt 8) {
        $sr[8] = 3
        Set-ItemProperty -Path $stuckPath -Name "Settings" -Value $sr -Type Binary
        Write-Ok "Da bat tu dong an Taskbar goc cua Windows (nhuong cho cho Mac Dock)."
    }
}

# 3. Hieu ung cua so muot, Scrollbar kieu overlay & Explorer thoang kieu Finder
$desktopPath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path "$desktopPath\WindowMetrics" -Name "MinAnimate" -Value "1" -Type String
$advPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path $advPath -Name "TaskbarAnimations" -Value 1 -Type DWord
Set-ItemProperty -Path $advPath -Name "HideFileExt" -Value 0 -Type DWord
Set-ItemProperty -Path $advPath -Name "UseCompactMode" -Value 0 -Type DWord
Set-ItemProperty -Path $advPath -Name "ShowSyncProviderNotifications" -Value 0 -Type DWord

if ((Get-WindowsInfo).IsWin11) {
    Set-ItemProperty -Path $advPath -Name "TaskbarAl" -Value 1 -Type DWord
    Set-ItemProperty -Path $advPath -Name "TaskbarDa" -Value 0 -Type DWord
    $accPath = "HKCU:\Control Panel\Accessibility"
    if (Test-Path $accPath) {
        Set-ItemProperty -Path $accPath -Name "DynamicScrollbars" -Value 1 -Type DWord
    }
}
Write-Ok "Da bat hieu ung dong/mo cua so muot, scrollbar overlay va Explorer thoang kieu Finder."

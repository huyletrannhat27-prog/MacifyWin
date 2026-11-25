param([string]$Theme = "Dark")
. "$PSScriptRoot\common.ps1"

Write-Step "Ap dung tinh chinh Windows Registry (Theme: $Theme)"

# 1. Dong bo Dark / Light Mode
$useLight = if ($Theme -eq "Light") { 1 } else { 0 }
$persPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
Set-ItemProperty -Path $persPath -Name "AppsUseLightTheme"    -Value $useLight -Type DWord
Set-ItemProperty -Path $persPath -Name "SystemUsesLightTheme" -Value $useLight -Type DWord
Write-Ok "Da dat che do $Theme Mode."

# 2. Hieu ung cua so muot & Scrollbar kieu overlay
$desktopPath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path "$desktopPath\WindowMetrics" -Name "MinAnimate" -Value "1" -Type String
$advPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path $advPath -Name "TaskbarAnimations" -Value 1 -Type DWord

if ((Get-WindowsInfo).IsWin11) {
    Set-ItemProperty -Path $advPath -Name "TaskbarAl" -Value 1 -Type DWord
    Set-ItemProperty -Path $advPath -Name "TaskbarDa" -Value 0 -Type DWord
    $accPath = "HKCU:\Control Panel\Accessibility"
    if (Test-Path $accPath) {
        Set-ItemProperty -Path $accPath -Name "DynamicScrollbars" -Value 1 -Type DWord
    }
}
Write-Ok "Da bat hieu ung muot va scrollbar overlay."


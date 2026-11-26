. "$PSScriptRoot\common.ps1"

Write-Step "Cai dat Font Inter, Con tro & Wallpaper"

# 1. Tu dong tai Font Inter (SIL OFL) neu thu muc dang trong
$fontDir = "$script:RepoRoot\assets\fonts\inter"
New-Item -ItemType Directory -Force -Path $fontDir | Out-Null
$fontFiles = Get-ChildItem -Path $fontDir -Include *.ttf,*.otf -Recurse -ErrorAction SilentlyContinue

if ($fontFiles.Count -eq 0) {
    Write-Host "  -> Dang tai font Inter ma nguon mo..." -NoNewline
    try {
        $zipPath = Join-Path $env:TEMP "inter-font.zip"
        $extractDir = Join-Path $env:TEMP "inter-font-extract"
        Invoke-WebRequest -Uri "https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip" -OutFile $zipPath -UseBasicParsing -TimeoutSec 30
        Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
        Get-ChildItem -Path $extractDir -Filter "Inter-*.ttf" -Recurse | Where-Object { $_.DirectoryName -match "extras\\ttf" } | ForEach-Object {
            Copy-Item $_.FullName $fontDir -Force
        }
        Remove-Item $zipPath, $extractDir -Recurse -Force -ErrorAction SilentlyContinue
        $fontFiles = Get-ChildItem -Path $fontDir -Include *.ttf,*.otf -Recurse -ErrorAction SilentlyContinue
        Write-Host " Xong" -ForegroundColor Green
    } catch {
        Write-Host " Bo qua (khong co mang)" -ForegroundColor Yellow
    }
}

$winFonts = "$env:WINDIR\Fonts"
$regFonts = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
if ($fontFiles.Count -gt 0) {
    foreach ($f in $fontFiles) {
        $dest = Join-Path $winFonts $f.Name
        if (-not (Test-Path $dest)) {
            Copy-Item $f.FullName $dest -Force
            Set-ItemProperty -Path $regFonts -Name "$($f.BaseName) (TrueType)" -Value $f.Name -Type String
        }
    }
    Write-Ok "Da cai $($fontFiles.Count) file font Inter."
}

# 2. Cai bo con tro Capitaine Cursors (neu co file .cur/.ani)
$curSrc = "$script:RepoRoot\assets\cursors\capitaine"
$curDst = Join-Path $script:DataDir "cursors"
$curFiles = Get-ChildItem -Path $curSrc -Include *.cur,*.ani -ErrorAction SilentlyContinue

if ($curFiles.Count -gt 0) {
    New-Item -ItemType Directory -Force -Path $curDst | Out-Null
    Copy-Item "$curSrc\*" $curDst -Force
    $curReg = "HKCU:\Control Panel\Cursors"
    $map = @{
        "Arrow"       = "default.cur"
        "Hand"        = "pointer.cur"
        "IBeam"       = "text.cur"
        "Wait"        = "wait.ani"
        "AppStarting" = "progress.ani"
        "SizeNS"      = "ns-resize.cur"
        "SizeWE"      = "ew-resize.cur"
        "SizeNWSE"    = "nwse-resize.cur"
        "SizeNESW"    = "nesw-resize.cur"
        "SizeAll"     = "all-scroll.cur"
        "No"          = "not-allowed.cur"
    }
    foreach ($k in $map.Keys) {
        $file = Join-Path $curDst $map[$k]
        if (Test-Path $file) {
            Set-ItemProperty -Path $curReg -Name $k -Value $file -Type ExpandString
        }
    }
    Add-Type -TypeDefinition @"
    using System.Runtime.InteropServices;
    public class Win32Cursor {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, System.IntPtr pvParam, uint fWinIni);
    }
"@ -ErrorAction SilentlyContinue
    [Win32Cursor]::SystemParametersInfo(0x0057, 0, [IntPtr]::Zero, 0x03) | Out-Null
    Write-Ok "Da ap dung bo con tro Capitaine Cursors."
}

# 3. Tao hinh nen gradient mesh hien dai (CC0) neu chua co, roi dat lam hinh nen
$wallDir = "$script:RepoRoot\assets\wallpapers"
New-Item -ItemType Directory -Force -Path $wallDir | Out-Null
$wall = Join-Path $wallDir "macify-gradient.png"

if (-not (Test-Path $wall)) {
    try {
        Add-Type -AssemblyName System.Drawing
        $bmp = New-Object System.Drawing.Bitmap(1920, 1080)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $rect = New-Object System.Drawing.Rectangle(0, 0, 1920, 1080)
        $baseBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            $rect,
            [System.Drawing.Color]::FromArgb(255, 13, 27, 62),
            [System.Drawing.Color]::FromArgb(255, 58, 28, 113),
            35
        )
        $g.FillRectangle($baseBrush, $rect)

        # Them 2 vung anh sang mem kieu macOS abstract wallpaper
        $p1 = New-Object System.Drawing.Drawing2D.GraphicsPath
        $p1.AddEllipse(-200, -200, 1400, 1200)
        $b1 = New-Object System.Drawing.Drawing2D.PathGradientBrush($p1)
        $b1.CenterColor = [System.Drawing.Color]::FromArgb(140, 0, 180, 216)
        $b1.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 0, 180, 216))
        $g.FillPath($b1, $p1)

        $p2 = New-Object System.Drawing.Drawing2D.GraphicsPath
        $p2.AddEllipse(700, 250, 1400, 1100)
        $b2 = New-Object System.Drawing.Drawing2D.PathGradientBrush($p2)
        $b2.CenterColor = [System.Drawing.Color]::FromArgb(130, 255, 117, 140)
        $b2.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 255, 117, 140))
        $g.FillPath($b2, $p2)

        $bmp.Save($wall, [System.Drawing.Imaging.ImageFormat]::Png)
        $b1.Dispose(); $p1.Dispose(); $b2.Dispose(); $p2.Dispose(); $baseBrush.Dispose(); $g.Dispose(); $bmp.Dispose()
        Write-Ok "Da tao hinh nen macify-gradient.png."
    } catch {
        Write-Warn "Khong the tao hinh nen tu dong."
    }
}

if (Test-Path $wall) {
    Add-Type -TypeDefinition @"
    using System.Runtime.InteropServices;
    public class Win32Wall {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    }
"@ -ErrorAction SilentlyContinue
    [Win32Wall]::SystemParametersInfo(0x0014, 0, $wall, 0x03) | Out-Null
    Write-Ok "Da dat hinh nen MacifyWin."
}

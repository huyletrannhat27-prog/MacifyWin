param([string]$Theme = "Dark")
. "$PSScriptRoot\common.ps1"

Write-Step "Cau hinh theme cho ung dung (VS Code & Trinh duyet)"

$vscodeUserDir = Join-Path $env:APPDATA "Code\User"
$vscodeSettings = Join-Path $vscodeUserDir "settings.json"
$patchFile = "$script:RepoRoot\configs\vscode\settings.patch.json"

if ((Test-Path $vscodeUserDir) -and (Test-Path $patchFile)) {
    Ensure-BackupDir
    $vscodeBak = Join-Path $script:BackupDir "vscode_settings.json"
    if ((Test-Path $vscodeSettings) -and (-not (Test-Path $vscodeBak))) {
        Copy-Item $vscodeSettings $vscodeBak -Force
    }

    $current = @{}
    if (Test-Path $vscodeSettings) {
        try {
            $raw = Get-Content $vscodeSettings -Raw | ConvertFrom-Json -AsHashtable
            if ($raw) { $current = $raw }
        } catch {
            Write-Warn "Khong doc duoc settings.json cua VS Code (co the co comment JSONC), bo qua merge."
            $current = $null
        }
    }

    if ($null -ne $current) {
        $patch = Get-Content $patchFile -Raw | ConvertFrom-Json -AsHashtable
        foreach ($key in $patch.Keys) { $current[$key] = $patch[$key] }
        $current | ConvertTo-Json -Depth 10 | Set-Content $vscodeSettings -Encoding UTF8
        Write-Ok "Da cap nhat VS Code settings.json (font Inter, titlebar custom)."
    }

    if (Get-Command code -ErrorAction SilentlyContinue) {
        & code --install-extension GitHub.github-vscode-theme --force 2>$null | Out-Null
        Write-Ok "Da cai GitHub Theme (ma nguon mo) cho VS Code."
    }
}

Write-Host "  [Tip] Voi Chrome/Edge: mo chrome://flags va bat 'Windows 11 Mica titlebar' de dong bo hieu ung mo." -ForegroundColor DarkGray


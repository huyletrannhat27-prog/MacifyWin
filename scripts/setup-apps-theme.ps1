param([string]$Theme = "Dark")
. "$PSScriptRoot\common.ps1"

Write-Step "Cau hinh giao dien ben trong ung dung (VS Code, Terminal, Files, Chrome/Edge)"

function Merge-JsonPatch {
    param([string]$TargetPath, [hashtable]$Patch, [string]$BackupName)
    if (-not (Test-Path (Split-Path -Parent $TargetPath))) { return $false }

    Ensure-BackupDir
    $bakPath = Join-Path $script:BackupDir $BackupName
    if ((Test-Path $TargetPath) -and (-not (Test-Path $bakPath))) {
        Copy-Item $TargetPath $bakPath -Force
    }

    $obj = New-Object PSObject
    if (Test-Path $TargetPath) {
        try {
            # Loai bo comment // de doc duoc JSONC trong PowerShell 5.1
            $lines = Get-Content $TargetPath -Encoding UTF8 | Where-Object { $_ -notmatch '^\s*//' }
            $raw = ($lines -join "`n").Trim()
            if ($raw) { $obj = $raw | ConvertFrom-Json }
        } catch {
            Write-Warn "Khong phan tich duoc $(Split-Path -Leaf $TargetPath), bo qua de an toan."
            return $false
        }
    }

    foreach ($k in $Patch.Keys) {
        if ($obj.PSObject.Properties[$k]) {
            $obj.$k = $Patch[$k]
        } else {
            $obj | Add-Member -NotePropertyName $k -NotePropertyValue $Patch[$k]
        }
    }
    $obj | ConvertTo-Json -Depth 15 | Set-Content $TargetPath -Encoding UTF8
    return $true
}

# 1. VS Code (su dung PS 5.1 tuong thich, khong dung -AsHashtable)
$vscodeSettings = Join-Path $env:APPDATA "Code\User\settings.json"
$patchFile = "$script:RepoRoot\configs\vscode\settings.patch.json"
if ((Test-Path (Split-Path -Parent $vscodeSettings)) -and (Test-Path $patchFile)) {
    $patchObj = Get-Content $patchFile -Raw | ConvertFrom-Json
    $patchMap = @{}
    foreach ($p in $patchObj.PSObject.Properties) { $patchMap[$p.Name] = $p.Value }

    if (Merge-JsonPatch -TargetPath $vscodeSettings -Patch $patchMap -BackupName "vscode_settings.json") {
        Write-Ok "Da cap nhat VS Code (font Inter, titlebar custom, GitHub theme, cuon muot)."
    }
    if (Get-Command code -ErrorAction SilentlyContinue) {
        & code --install-extension GitHub.github-vscode-theme --force 2>$null | Out-Null
        Write-Ok "Da cai GitHub Theme (Dark/Light tu dong) cho VS Code."
    }
}

# 2. Windows Terminal (hieu ung kinh mo Acrylic kieu iTerm2 / macOS Terminal)
$wtCandidates = @(
    (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"),
    (Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\settings.json")
)
foreach ($wtPath in $wtCandidates) {
    if (Test-Path $wtPath) {
        Ensure-BackupDir
        $wtBak = Join-Path $script:BackupDir "wt_settings.json"
        if (-not (Test-Path $wtBak)) { Copy-Item $wtPath $wtBak -Force }
        try {
            $wtObj = (Get-Content $wtPath -Raw -Encoding UTF8) | ConvertFrom-Json
            if ($wtObj.PSObject.Properties["useAcrylicInTabRow"]) { $wtObj.useAcrylicInTabRow = $true }
            else { $wtObj | Add-Member -NotePropertyName "useAcrylicInTabRow" -NotePropertyValue $true }
            if ($wtObj.PSObject.Properties["theme"]) { $wtObj.theme = "system" }
            else { $wtObj | Add-Member -NotePropertyName "theme" -NotePropertyValue "system" }

            if ($wtObj.profiles -and $wtObj.profiles.defaults) {
                $def = $wtObj.profiles.defaults
                $props = @{ "useAcrylic" = $true; "opacity" = 85; "padding" = "12"; "cursorShape" = "filledBox" }
                foreach ($pk in $props.Keys) {
                    if ($def.PSObject.Properties[$pk]) { $def.$pk = $props[$pk] }
                    else { $def | Add-Member -NotePropertyName $pk -NotePropertyValue $props[$pk] }
                }
            }
            $wtObj | ConvertTo-Json -Depth 20 | Set-Content $wtPath -Encoding UTF8
            Write-Ok "Da bat nen mo Acrylic & giao dien iTerm2 cho Windows Terminal."
        } catch {
            Write-Warn "Bo qua Windows Terminal settings.json."
        }
        break
    }
}

# 3. Files App (ho tro ca ban MSIX trong Packages lan ban thuong)
$filesCfgSrc = "$script:RepoRoot\configs\files-app\user_settings.json"
if (Test-Path $filesCfgSrc) {
    $filesTargets = New-Object System.Collections.ArrayList
    $null = $filesTargets.Add((Join-Path $env:LOCALAPPDATA "Files\Settings\user_settings.json"))
    Get-ChildItem (Join-Path $env:LOCALAPPDATA "Packages") -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "*Files*" } | ForEach-Object {
            $null = $filesTargets.Add((Join-Path $_.FullName "LocalState\settings\user_settings.json"))
        }
    foreach ($ft in $filesTargets) {
        $dir = Split-Path -Parent $ft
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Copy-Item $filesCfgSrc $ft -Force
    }
    Write-Ok "Da ap dung Column View & nen mo cho Files App (Finder)."
}

# 4. Chrome & Edge: Bat Fluent Overlay Scrollbars & Mica Titlebar trong Local State (neu trinh duyet dang dong)
$browsers = @(
    @{ Name = "Google Chrome"; Proc = "chrome"; LocalState = (Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data\Local State") },
    @{ Name = "Microsoft Edge"; Proc = "msedge"; LocalState = (Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data\Local State") }
)
foreach ($b in $browsers) {
    if (Test-Path $b.LocalState) {
        if (Get-Process -Name $b.Proc -ErrorAction SilentlyContinue) {
            Write-Warn "$($b.Name) dang mo — dong trinh duyet roi mo lai hoac bat 'Fluent scrollbars' trong chrome://flags."
        } else {
            try {
                Ensure-BackupDir
                $bak = Join-Path $script:BackupDir "$($b.Proc)_LocalState.json"
                if (-not (Test-Path $bak)) { Copy-Item $b.LocalState $bak -Force }
                $ls = Get-Content $b.LocalState -Raw -Encoding UTF8 | ConvertFrom-Json
                if (-not $ls.PSObject.Properties["browser"]) { $ls | Add-Member -NotePropertyName "browser" -NotePropertyValue (New-Object PSObject) }
                $exps = @()
                if ($ls.browser.PSObject.Properties["enabled_lab_experiments"]) {
                    $exps = @($ls.browser.enabled_lab_experiments)
                }
                foreach ($flag in @("fluent-overlay-scrollbars@1", "windows11-mica-titlebar@1")) {
                    if ($exps -notcontains $flag) { $exps += $flag }
                }
                if ($ls.browser.PSObject.Properties["enabled_lab_experiments"]) {
                    $ls.browser.enabled_lab_experiments = $exps
                } else {
                    $ls.browser | Add-Member -NotePropertyName "enabled_lab_experiments" -NotePropertyValue $exps
                }
                $ls | ConvertTo-Json -Depth 20 -Compress | Set-Content $b.LocalState -Encoding UTF8
                Write-Ok "Da bat Mica titlebar & Overlay Scrollbars cho $($b.Name)."
            } catch {
                Write-Warn "Khong cap nhat duoc Local State cua $($b.Name)."
            }
        }
    }
}

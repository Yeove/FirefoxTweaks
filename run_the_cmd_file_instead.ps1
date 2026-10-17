# ============================================================
#  Yeove's Firefox Sidebery CSS Tweaks - symlink setup
# ============================================================
#  Run this from the repo folder. It will:
#    1. Ask for administrator rights (needed to write into Program Files)
#    2. Find your Firefox install folder and profile
#    3. Symlink these repo items into Firefox:
#         chrome\             -> <profile>\chrome
#         autoconfig.js       -> <Firefox>\defaults\pref\autoconfig.js
#         yeovefirefox.cfg    -> <Firefox>\yeovefirefox.cfg
#    4. Clear Firefox's startup cache so the scripts load fresh
#
#  Anything already at those locations is renamed to *.bak-<timestamp>,
#  never deleted. Existing symlinks are simply replaced.
#  Safe to re-run (e.g. after reinstalling Firefox).
# ============================================================

param([switch]$Elevated)   # set internally when the script relaunches itself as admin

$ErrorActionPreference = "Stop"

# ---------- 0. Confirm ----------
# Asked once, in the first window. The elevated relaunch skips this.
if (-not $Elevated) {
    Write-Host ""
    Write-Host "Yeove's Firefox Sidebery CSS Tweaks - setup" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This will symlink the following from:"
    Write-Host "  $PSScriptRoot"
    Write-Host ""
    Write-Host "  chrome\             -> your Firefox profile's chrome folder"
    Write-Host "  autoconfig.js       -> <Firefox install>\defaults\pref\"
    Write-Host "  yeovefirefox.cfg    -> <Firefox install>\"
    Write-Host ""
    Write-Host "Existing files/folders at those spots are renamed to *.bak-<timestamp>, not deleted."
    Write-Host "Administrator rights are required to write into the Firefox install folder."
    Write-Host ""
    $answer = Read-Host "Type y and press Enter to start (anything else cancels)"
    if ($answer.Trim() -ne "y") {
        Write-Host ""
        Write-Host "Cancelled. Nothing was changed." -ForegroundColor Yellow
        Read-Host "Press Enter to close"
        exit
    }
}

# ---------- 1. Self-elevate ----------
$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting administrator rights..."
    $shell = (Get-Process -Id $PID).Path   # powershell.exe or pwsh.exe, whichever launched us
    try {
        Start-Process -FilePath $shell -Verb RunAs -ArgumentList @(
            "-NoExit", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"", "-Elevated"
        )
        Write-Host ""
        Write-Host "Continuing in the new administrator window."
    } catch {
        Write-Host ""
        Write-Host "Administrator rights were declined. Nothing was changed." -ForegroundColor Yellow
    }
    Read-Host "Press Enter to close this window"
    exit
}

# ---------- Helpers ----------
function Read-Ini([string]$Path) {
    $ini = [ordered]@{}
    $section = $null
    foreach ($line in Get-Content -LiteralPath $Path) {
        $line = $line.Trim()
        if ($line -match '^\[(.+)\]$') {
            $section = $Matches[1]
            $ini[$section] = @{}
        } elseif ($section -and $line -match '^([^=]+)=(.*)$') {
            $ini[$section][$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }
    return $ini
}

function Find-FirefoxDir {
    $appPathKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe"
    )
    foreach ($key in $appPathKeys) {
        $exe = (Get-ItemProperty -Path $key -ErrorAction SilentlyContinue).'(default)'
        if ($exe) {
            $exe = $exe.Trim('"')
            if (Test-Path -LiteralPath $exe) { return (Split-Path $exe -Parent) }
        }
    }
    foreach ($dir in @("$env:ProgramFiles\Mozilla Firefox", "${env:ProgramFiles(x86)}\Mozilla Firefox")) {
        if (Test-Path -LiteralPath "$dir\firefox.exe") { return $dir }
    }
    return $null
}

# Creates a symlink at $LinkPath pointing to $TargetPath.
# Existing links are replaced; existing real files/folders are renamed to a backup.
function Set-Link([string]$LinkPath, [string]$TargetPath) {
    if (-not (Test-Path -LiteralPath $TargetPath)) {
        throw "Missing from repo: $TargetPath"
    }
    $existing = Get-Item -LiteralPath $LinkPath -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.LinkType) {
            # Delete only the link itself, never the folder/file it points to
            if ($existing.PSIsContainer) { [System.IO.Directory]::Delete($LinkPath) }
            else                         { [System.IO.File]::Delete($LinkPath) }
        } else {
            $backupName = "$(Split-Path $LinkPath -Leaf).bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Rename-Item -LiteralPath $LinkPath -NewName $backupName
            Write-Host "  Backed up existing $(Split-Path $LinkPath -Leaf) to $backupName" -ForegroundColor Yellow
        }
    }
    New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath | Out-Null
    Write-Host "  Linked $LinkPath" -ForegroundColor Green
    Write-Host "      -> $TargetPath"
}

# ---------- Main ----------
$completed = New-Object System.Collections.Generic.List[string]
$succeeded = $false

try {
    $Repo = $PSScriptRoot
    Write-Host ""
    Write-Host "Repo folder: $Repo"

    # Firefox must be closed so it doesn't hold files open or rewrite the startup cache
    while (Get-Process -Name firefox -ErrorAction SilentlyContinue) {
        Read-Host "Firefox is running. Close it completely, then press Enter"
    }

    # ---------- 2a. Firefox install folder ----------
    $Firefox = Find-FirefoxDir
    if (-not $Firefox) {
        $Firefox = (Read-Host "Couldn't find Firefox. Paste the folder that contains firefox.exe").Trim('"')
    }
    if (-not (Test-Path -LiteralPath "$Firefox\firefox.exe")) {
        throw "firefox.exe not found in: $Firefox"
    }
    if ($Firefox -like "*\WindowsApps\*") {
        throw "This looks like the Microsoft Store version of Firefox, which can't be modified. Install Firefox from mozilla.org instead."
    }
    Write-Host "Firefox install: $Firefox"

    # ---------- 2b. Firefox profile ----------
    $ffAppData   = Join-Path $env:APPDATA "Mozilla\Firefox"
    $profilesIni = Join-Path $ffAppData "profiles.ini"
    if (-not (Test-Path -LiteralPath $profilesIni)) {
        throw "No profiles.ini found at $profilesIni. Run Firefox once first."
    }
    $ini = Read-Ini $profilesIni

    $profiles = @()
    foreach ($name in $ini.Keys) {
        if ($name -notlike "Profile*") { continue }
        $p = $ini[$name]
        if (-not $p.Path) { continue }
        $relPath = $p.Path -replace '/', '\'
        $full = if ($p.IsRelative -eq "1") { Join-Path $ffAppData $relPath } else { $relPath }
        $profiles += [pscustomobject]@{ Name = $p.Name; RawPath = $p.Path; FullPath = $full; IsRelative = ($p.IsRelative -eq "1") }
    }
    if ($profiles.Count -eq 0) { throw "No profiles listed in $profilesIni" }

    # The profile Firefox actually opens is listed under [Install...] -> Default
    $defaultRaw = $null
    foreach ($name in $ini.Keys) {
        if ($name -like "Install*" -and $ini[$name].Default) { $defaultRaw = $ini[$name].Default; break }
    }
    if (-not $defaultRaw) {
        foreach ($name in $ini.Keys) {
            if ($name -like "Profile*" -and $ini[$name].Default -eq "1") { $defaultRaw = $ini[$name].Path; break }
        }
    }
    $defaultIndex = 0
    for ($i = 0; $i -lt $profiles.Count; $i++) {
        if ($profiles[$i].RawPath -eq $defaultRaw) { $defaultIndex = $i; break }
    }

    if ($profiles.Count -eq 1) {
        $FxProfile = $profiles[0]
    } else {
        Write-Host ""
        Write-Host "Firefox profiles:"
        for ($i = 0; $i -lt $profiles.Count; $i++) {
            $marker = if ($i -eq $defaultIndex) { "  (default)" } else { "" }
            Write-Host ("  [{0}] {1}{2}" -f ($i + 1), $profiles[$i].Name, $marker)
            Write-Host ("      {0}" -f $profiles[$i].FullPath)
        }
        $choice = Read-Host "Pick a profile number [Enter = default]"
        if ([string]::IsNullOrWhiteSpace($choice)) {
            $FxProfile = $profiles[$defaultIndex]
        } elseif ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $profiles.Count) {
            $FxProfile = $profiles[[int]$choice - 1]
        } else {
            throw "Invalid choice: $choice"
        }
    }
    if (-not (Test-Path -LiteralPath $FxProfile.FullPath)) { throw "Profile folder not found: $($FxProfile.FullPath)" }
    Write-Host "Firefox profile: $($FxProfile.FullPath)"

    # ---------- 3. Links ----------
    Write-Host ""
    Write-Host "Creating symlinks..."

    Set-Link (Join-Path $FxProfile.FullPath "chrome") (Join-Path $Repo "chrome")
    $completed.Add("chrome folder linked")

    $prefDir = Join-Path $Firefox "defaults\pref"
    if (-not (Test-Path -LiteralPath $prefDir)) { New-Item -ItemType Directory -Path $prefDir | Out-Null }
    Set-Link (Join-Path $prefDir "autoconfig.js")    (Join-Path $Repo "autoconfig.js")
    $completed.Add("autoconfig.js linked")
    Set-Link (Join-Path $Firefox "yeovefirefox.cfg") (Join-Path $Repo "yeovefirefox.cfg")
    $completed.Add("yeovefirefox.cfg linked")

    # Clean up the link from before the rename to yeovefirefox.cfg
    $oldCfg = Get-Item -LiteralPath (Join-Path $Firefox "yeove.cfg") -Force -ErrorAction SilentlyContinue
    if ($oldCfg -and $oldCfg.LinkType) {
        [System.IO.File]::Delete($oldCfg.FullName)
        Write-Host "  Removed old yeove.cfg link"
    }

    # Warn about other AutoConfig loaders (e.g. fx-autoconfig) fighting over the same pref
    Get-ChildItem -LiteralPath $prefDir -Filter *.js -File |
        Where-Object { $_.Name -ne "autoconfig.js" } |
        Where-Object { Select-String -LiteralPath $_.FullName -Pattern "general.config.filename" -Quiet } |
        ForEach-Object {
            Write-Host "  WARNING: $($_.Name) also sets up an AutoConfig loader and may conflict." -ForegroundColor Yellow
        }

    # ---------- 4. Startup cache ----------
    if ($FxProfile.IsRelative) {
        $localProfile = Join-Path (Join-Path $env:LOCALAPPDATA "Mozilla\Firefox") ($FxProfile.RawPath -replace '/', '\')
        $startupCache = Join-Path $localProfile "startupCache"
        if (Test-Path -LiteralPath $startupCache) {
            Remove-Item -LiteralPath $startupCache -Recurse -Force
            Write-Host "Cleared startup cache."
            $completed.Add("startup cache cleared")
        }
    } else {
        Write-Host "Custom profile location: clear the startup cache from about:support if scripts don't load." -ForegroundColor Yellow
    }

    $succeeded = $true
} catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Write-Host ""
    Write-Host "============================================================"
    if ($succeeded) {
        Write-Host "  SETUP PASSED" -ForegroundColor Green
        Write-Host "============================================================"
        Write-Host ""
        Write-Host "Start Firefox to use the tweaks."
        Write-Host "Remember: paste sidebery_styles.css into Sidebery > Settings > Styles editor."
    } else {
        Write-Host "  SETUP FAILED" -ForegroundColor Red
        Write-Host "============================================================"
        Write-Host ""
        if ($completed.Count -gt 0) {
            Write-Host "These steps finished before the error:"
            $completed | ForEach-Object { Write-Host "  - $_" }
        } else {
            Write-Host "No changes were made."
        }
        Write-Host "Fix the error above and run the script again - it's safe to re-run."
    }
    Write-Host ""
    if ($Elevated) {
        Write-Host "You can close this window."
    } else {
        Read-Host "Press Enter to close"
    }
}

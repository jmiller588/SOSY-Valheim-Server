
$ErrorActionPreference = "Stop"

$profileFile = Join-Path $PSScriptRoot "SOSY-1.0.r2z"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "          SOSY 1.0 INSTALLER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $profileFile)) {
    Write-Host "ERROR: SOSY-1.0.r2z was not found." -ForegroundColor Red
    Write-Host "Keep the profile file in the same folder as this script."
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[1/3] Checking Steam..." -ForegroundColor Yellow

$steamPath = $null
$steamKey = Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue

if ($steamKey -and $steamKey.SteamPath) {
    $steamPath = $steamKey.SteamPath
}

$valheimPath = $null

if (-not $steamPath) {
    Write-Host "Steam was not detected." -ForegroundColor Red
    Write-Host "Opening the Steam download page..."
    Start-Process "https://store.steampowered.com/about/"
} else {
    Write-Host "Steam found: $steamPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "Checking Steam libraries..." -ForegroundColor Yellow

    $libraryPaths = @($steamPath)

    $libraryFile = Join-Path $steamPath "steamapps\libraryfolders.vdf"

    if (Test-Path $libraryFile) {
        try {
            $content = Get-Content $libraryFile -Raw -ErrorAction Stop
            $matches = [regex]::Matches($content, '"path"\s+"([^"]+)"')

            foreach ($match in $matches) {
                $path = $match.Groups[1].Value -replace '\\\\','\'

                if ($path -and $libraryPaths -notcontains $path) {
                    $libraryPaths += $path
                }
            }
        } catch {
            Write-Host "WARNING: Could not read Steam library configuration." -ForegroundColor Yellow
        }
    }

    foreach ($library in $libraryPaths) {
        Write-Host "  $library"

        $manifest = Join-Path $library "steamapps\appmanifest_892970.acf"

        if (Test-Path $manifest) {
            try {
                $manifestContent = Get-Content $manifest -Raw -ErrorAction Stop
                $installDirMatch = [regex]::Match(
                    $manifestContent,
                    '"installdir"\s+"([^"]+)"'
                )

                if ($installDirMatch.Success) {
                    $installDir = $installDirMatch.Groups[1].Value
                    $candidatePath = Join-Path $library "steamapps\common\$installDir"
                    $executable = Join-Path $candidatePath "valheim.exe"

                    if (Test-Path $executable) {
                        $valheimPath = $candidatePath
                        break
                    }
                }
            } catch {
                Write-Host "    WARNING: Could not verify this installation." -ForegroundColor Yellow
            }
        }
    }

    Write-Host ""

    if ($valheimPath) {
        Write-Host "Valheim found!" -ForegroundColor Green
        Write-Host "Game location: $valheimPath" -ForegroundColor Green
    } else {
        Write-Host "Valheim was not detected." -ForegroundColor Yellow
        Write-Host "Make sure Valheim is installed through Steam."
    }
}

Write-Host ""
Write-Host "[2/3] Checking r2modman..." -ForegroundColor Yellow

$r2Candidates = @(
    "$env:LOCALAPPDATA\Programs\r2modman\r2modman.exe",
    "$env:LOCALAPPDATA\r2modman\r2modman.exe",
    "$env:LOCALAPPDATA\Programs\Thunderstore Mod Manager\Thunderstore Mod Manager.exe"
)

$r2Exe = $r2Candidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($r2Exe) {
    Write-Host "Mod manager found: $r2Exe" -ForegroundColor Green
    Start-Process -FilePath $r2Exe
} else {
    Write-Host "r2modman was not found in its usual install locations." -ForegroundColor Yellow
    Write-Host "Opening the official r2modman releases page..."
    Start-Process "https://github.com/ebkr/r2modmanPlus/releases"
}

Write-Host ""
Write-Host "[3/3] Opening the SOSY 1.0 profile..." -ForegroundColor Yellow

Start-Process explorer.exe -ArgumentList "/select,`"$profileFile`""

Write-Host ""
Write-Host "NEXT STEPS" -ForegroundColor Cyan
Write-Host "1. In r2modman, select Valheim."
Write-Host "2. Open Settings and find the profile import option."
Write-Host "3. Choose Import local profile."
Write-Host "4. Select SOSY-1.0.r2z from this folder."
Write-Host "5. Select the imported SOSY 1.0 profile."
Write-Host "6. Click Start modded to launch the game."
Write-Host ""
Write-Host "The first launch may take a little longer while mods download."
Write-Host ""
Read-Host "Press Enter when you have finished"

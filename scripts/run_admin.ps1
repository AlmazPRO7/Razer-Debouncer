param(
    [switch]$Setup,
    [switch]$Build,
    [switch]$BuildNoAdmin,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args,
    [string]$ProjectRoot
)

# Надёжное определение корня проекта, даже если $MyInvocation пуст
if (-not $ProjectRoot -or $ProjectRoot.Trim() -eq '') {
    $scriptBase = if ($PSScriptRoot -and $PSScriptRoot.Trim() -ne '') {
        $PSScriptRoot
    } elseif ($MyInvocation -and $MyInvocation.MyCommand -and $MyInvocation.MyCommand.Path) {
        Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        (Get-Location).Path
    }
    $ProjectRoot = Split-Path -Parent $scriptBase
}

$venv = Join-Path $ProjectRoot '.venv'
$pythonExe = Join-Path $venv 'Scripts\python.exe'
$scriptPy = Join-Path $ProjectRoot 'bw3_debounce3.py'
$specFile = Join-Path $ProjectRoot 'bw3_debounce.spec'

if ($Setup) {
    & (Join-Path $ProjectRoot 'scripts\setup_windows.ps1')
    exit $LASTEXITCODE
}

if ($Build -or $BuildNoAdmin) {
    if (!(Test-Path $pythonExe)) { & (Join-Path $ProjectRoot 'scripts\setup_windows.ps1') }
    $argList = if (Test-Path $specFile) { $specFile } else { "$scriptPy --noconsole" }
    if ($BuildNoAdmin) {
        # Сборка без повышения прав
        & $pythonExe -m PyInstaller $argList
        exit $LASTEXITCODE
    } else {
        # Сборка с UAC (может открыть отдельное окно)
        $pyi = Join-Path $venv 'Scripts\pyinstaller.exe'
        if (!(Test-Path $pyi)) { & $pythonExe -m pip install pyinstaller }
        Start-Process -Verb RunAs -FilePath $pyi -ArgumentList $argList -Wait
        exit $LASTEXITCODE
    }
}

if (!(Test-Path $pythonExe)) { & (Join-Path $ProjectRoot 'scripts\setup_windows.ps1') }

$argLine = ($Args -join ' ')
Start-Process -Verb RunAs -FilePath $pythonExe -ArgumentList "`"$scriptPy`" $argLine" -Wait

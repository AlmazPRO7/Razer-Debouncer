param(
    [string]$PythonLauncher = 'py',
    [string]$ProjectRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent)
)

$venv = Join-Path $ProjectRoot '.venv'
$pythonExe = Join-Path $venv 'Scripts\python.exe'
$req = Join-Path $ProjectRoot 'requirements.txt'

Write-Host "[setup] Project: $ProjectRoot"
if (!(Test-Path $venv)) {
    Write-Host "[setup] Creating venv..."
    $launcher = $null
    if (Get-Command $PythonLauncher -ErrorAction SilentlyContinue) { $launcher = $PythonLauncher }
    elseif (Get-Command python -ErrorAction SilentlyContinue) { $launcher = 'python' }
    if ($null -eq $launcher) { throw "[setup] Python launcher not found (py/python)." }
    & $launcher -m venv $venv
}

Write-Host "[setup] Upgrading pip..."
if (Test-Path $pythonExe) {
    & $pythonExe -m pip install --upgrade pip
} else {
    & python -m pip install --upgrade pip
}

if (Test-Path $req) {
    Write-Host "[setup] Installing requirements..."
    if (Test-Path $pythonExe) {
        & $pythonExe -m pip install -r $req
    } else {
        & python -m pip install -r $req
    }
} else {
    Write-Host "[setup] requirements.txt not found, installing minimal..."
    if (Test-Path $pythonExe) {
        & $pythonExe -m pip install Pillow pystray pywin32 pyinstaller
    } else {
        & python -m pip install Pillow pystray pywin32 pyinstaller
    }
}

Write-Host "[setup] Done."

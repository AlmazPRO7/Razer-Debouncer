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
    & $PythonLauncher -3 -m venv $venv
}

Write-Host "[setup] Upgrading pip..."
& $pythonExe -m pip install --upgrade pip

if (Test-Path $req) {
    Write-Host "[setup] Installing requirements..."
    & $pythonExe -m pip install -r $req
} else {
    Write-Host "[setup] requirements.txt not found, installing minimal..."
    & $pythonExe -m pip install Pillow pystray pywin32 pyinstaller
}

Write-Host "[setup] Done."

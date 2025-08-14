param(
    [switch]$Setup,
    [switch]$Build,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args,
    [string]$ProjectRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent)
)

$venv = Join-Path $ProjectRoot '.venv'
$pythonExe = Join-Path $venv 'Scripts\python.exe'
$scriptPy = Join-Path $ProjectRoot 'bw3_debounce3.py'
$specFile = Join-Path $ProjectRoot 'bw3_debounce.spec'

if ($Setup) {
    & (Join-Path $ProjectRoot 'scripts\setup_windows.ps1')
    exit $LASTEXITCODE
}

if ($Build) {
    if (!(Test-Path $pythonExe)) { & (Join-Path $ProjectRoot 'scripts\setup_windows.ps1') }
    $pyi = Join-Path $venv 'Scripts\pyinstaller.exe'
    if (!(Test-Path $pyi)) { & $pythonExe -m pip install pyinstaller }
    $argList = if (Test-Path $specFile) { $specFile } else { "$scriptPy --noconsole" }
    Start-Process -Verb RunAs -FilePath $pyi -ArgumentList $argList -Wait
    exit $LASTEXITCODE
}

if (!(Test-Path $pythonExe)) { & (Join-Path $ProjectRoot 'scripts\setup_windows.ps1') }

$argLine = ($Args -join ' ')
Start-Process -Verb RunAs -FilePath $pythonExe -ArgumentList "`"$scriptPy`" $argLine" -Wait

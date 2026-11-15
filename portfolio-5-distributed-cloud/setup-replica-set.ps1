# =====================================================================
# Portfolio 5: start a 3-node MongoDB replica set on ONE Windows machine
# Run in PowerShell from this folder:
#   powershell -ExecutionPolicy Bypass -File .\setup-replica-set.ps1
# If mongod.exe is not found automatically, pass the path:
#   .\setup-replica-set.ps1 -MongoBin "C:\Program Files\MongoDB\Server\8.0\bin"
# Uses ports 27117-27119 so it does not clash with the normal MongoDB
# service on 27017 (used for Portfolio 4).
# =====================================================================
param(
    [string]$MongoBin = "",
    [string]$Root = "C:\mongo-rs"
)

if (-not $MongoBin) {
    $found = Get-ChildItem "C:\Program Files\MongoDB\Server" -Directory -ErrorAction SilentlyContinue |
             Sort-Object Name -Descending | Select-Object -First 1
    if ($found) { $MongoBin = Join-Path $found.FullName "bin" }
}

$mongod = Join-Path $MongoBin "mongod.exe"
if (-not (Test-Path $mongod)) {
    Write-Error "mongod.exe not found. Re-run with -MongoBin 'C:\Program Files\MongoDB\Server\<version>\bin'"
    exit 1
}

$ports = 27117, 27118, 27119
for ($i = 0; $i -lt 3; $i++) {
    $n    = $i + 1
    $port = $ports[$i]
    $data = Join-Path $Root "node$n\data"
    $log  = Join-Path $Root "node$n\mongod.log"
    New-Item -ItemType Directory -Force -Path $data | Out-Null

    Start-Process -FilePath $mongod -WindowStyle Hidden -ArgumentList @(
        "--replSet", "rs0",
        "--port", $port,
        "--dbpath", $data,
        "--logpath", $log,
        "--bind_ip", "localhost",
        "--oplogSize", "128"
    )
    Write-Host "Started node$n on port $port"
}

Write-Host "Waiting 6 seconds for the nodes to start..."
Start-Sleep -Seconds 6

Write-Host "Initiating the replica set..."
mongosh --port 27117 --quiet --file "$PSScriptRoot\init-replica-set.js"
Write-Host "Done. Next: mongosh --port 27117 --file .\status.js"

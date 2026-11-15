# Restarts a node that was stopped. Its data folder still exists, so it rejoins as SECONDARY.
# Usage:  .\start-node.ps1 -Node 1      (node 1 = port 27117, node 2 = 27118, node 3 = 27119)
param(
    [Parameter(Mandatory = $true)][ValidateSet(1, 2, 3)][int]$Node,
    [string]$MongoBin = "",
    [string]$Root = "C:\mongo-rs"
)
if (-not $MongoBin) {
    $found = Get-ChildItem "C:\Program Files\MongoDB\Server" -Directory -ErrorAction SilentlyContinue |
             Sort-Object Name -Descending | Select-Object -First 1
    if ($found) { $MongoBin = Join-Path $found.FullName "bin" }
}
$mongod = Join-Path $MongoBin "mongod.exe"
$port = 27116 + $Node
$data = Join-Path $Root "node$Node\data"
$log  = Join-Path $Root "node$Node\mongod.log"

Start-Process -FilePath $mongod -WindowStyle Hidden -ArgumentList @(
    "--replSet", "rs0", "--port", $port, "--dbpath", $data,
    "--logpath", $log, "--bind_ip", "localhost", "--oplogSize", "128"
)
Write-Host "Restarted node$Node on port $port"

# Stops the mongod process listening on a given port (simulates a crash).
# Usage:  .\stop-node.ps1 -Port 27117
param([Parameter(Mandatory = $true)][int]$Port)

$conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $conn) { Write-Error "Nothing is listening on port $Port"; exit 1 }
Stop-Process -Id $conn.OwningProcess -Force
Write-Host "Stopped the node on port $Port (process $($conn.OwningProcess))."

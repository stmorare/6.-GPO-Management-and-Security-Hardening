# Daily backup script
$backupPath = "C:\GPOBackups"
$date = Get-Date -Format "yyyyMMdd"
New-Item -ItemType Directory -Path "$backupPath\$date" -Force

Get-GPO -All | ForEach-Object {
    Backup-GPO -Guid $_.Id -Path "$backupPath\$date" -Comment "Daily Backup"
}
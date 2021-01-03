# Старт сервисов rx
Write-Host "Запускаем сервисы RX..."

# Старт iis
Start-Process -FilePath 'iisreset' -ArgumentList '/start' -NoNewWindow  -Wait

# Старть DrxServiceRunnerLocal
Start-Service -Name "DrxServiceRunnerLocal"
Start-Sleep -Seconds 2
$service = Get-Service -Name "DrxServiceRunnerLocal"
Write-Host "DrxServiceRunnerLocal is "$service.Status
Get-Process | where {$_.Name -match 'Sungero.'}

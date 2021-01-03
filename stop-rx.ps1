# остановка сервисов rx
Write-Host "Останавливаем сервисы RX..."

# остановить iis
Start-Process -FilePath 'iisreset' -ArgumentList '/stop' -NoNewWindow  -Wait

# остановить DrxServiceRunnerLocal
Stop-Service -Name "DrxServiceRunnerLocal"
Start-Sleep -Seconds 2
$service = Get-Service -Name "DrxServiceRunnerLocal"
Write-Host "DrxServiceRunnerLocal is "$service.Status
Get-Process | where {$_.Name -match 'Sungero.'}


# ����� �������� rx
Write-Host "��������� ������� RX..."

# ����� iis
Start-Process -FilePath 'iisreset' -ArgumentList '/start' -NoNewWindow  -Wait

# ������ DrxServiceRunnerLocal
Start-Service -Name "DrxServiceRunnerLocal"
Start-Sleep -Seconds 2
$service = Get-Service -Name "DrxServiceRunnerLocal"
Write-Host "DrxServiceRunnerLocal is "$service.Status
Get-Process | where {$_.Name -match 'Sungero.'}

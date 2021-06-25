$service = Get-Service -Name "DrxServiceRunnerLocal"
Write-Host "DrxServiceRunnerLocal is "$service.Status
Get-Process | where {$_.Name -match 'Sungero.' -Or $_.Name -match 'PreviewService.Host' -Or $_.Name -match 'PreviewStorage.Host' -Or  $_.Name -match 'centrifugo'}

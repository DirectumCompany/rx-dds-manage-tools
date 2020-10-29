# старт сервисов RX
Start-Process -FilePath 'iisreset' -ArgumentList '/start' -NoNewWindow  -Wait
Start-Process -FilePath 'net' -ArgumentList 'start DrxServiceRunnerLocal' -NoNewWindow  -Wait

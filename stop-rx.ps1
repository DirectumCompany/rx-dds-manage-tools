# остановка сервисов rx
Start-Process -FilePath 'iisreset' -ArgumentList '/stop' -NoNewWindow  -Wait
Start-Process -FilePath 'net' -ArgumentList 'stop DrxServiceRunnerLocal' -NoNewWindow -Wait

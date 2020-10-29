# удаление логов сервисов RX
Param ([string]$path_log, 
       [int]$limit_day,
       [switch] $help)

# ============================ ОБРАБОТКА ПАРАМЕТРОВ =====================================
if($help){
  Write-Host ""
  Write-Host "remove-old-logs.ps1 - удаление логов сервисов RX"
  Write-Host "Формат вызова:"
  Write-Host "   .\remove-old-logs.ps1 [-path_log <корневая папка с логами сервисов>] [-limit_day <за сколько дней оставить логи>] [-help]"
  Write-Host "Обходит все подкаталогив -path_log и удаляет логи, оставляя логи за -limit_day, начиная с текущего дня."
  Write-Host "Если параметр -path_log отсутствует, то берется значение по умолчанию - C:\inetpub\logs\"
  Write-Host "Если параметр -limit_day отсутствует, то берется значение по умолчанию - 5"
  Write-Host "Если запустить с параметром '-limit_day -1' - будут удалены все логи. В этом случае рекомендуется предварительно остановить службы."
  Write-Host "Предполагается, что именах файлов с логами последние 10 символов - это дата в формате YYYY-MM-DD"
  Write-Host ""
  Break
}


function doRecursiveThings ($path="C:\inetpub\logs\", $limit=5)
{
  $childs = Get-ChildItem $path
  
  foreach($child in $childs) {
    #Что-то делаем если надо делать для каждого элемента

    if( [System.IO.File]::GetAttributes($child.FullName) -eq [System.IO.FileAttributes]::Directory ) {
      #Или тут что-то делаем, если нужно сделать что-то в случае захода в каталог
      doRecursiveThings -path $child.FullName -limit $limit
    }
    if( [System.IO.File]::GetAttributes($child.FullName) -eq [System.IO.FileAttributes]::Archive ) {
      $name_as_array = $child.Name.split(".")
      if( ($child.Extension -eq ".log") -And ($name_as_array.Count -gt 2))
      {
         $cd = (Get-date).AddDays(-1*$limit).ToString("yyyy-MM-dd")
         $need_delete_file = $name_as_array[$name_as_array.Count-2] -lt $cd
         if ($need_delete_file)
         {
           $s = "removing " + $child.FullName + "  ..."
           Echo $s
           Remove-Item -Path $child.FullName
         }
      }
    }
  }
}

$path = $path_log
if ($path -eq "") {
  $path = "C:\inetpub\logs\"
}

$limit = $limit_day
if ($limit -eq 0) {
  $limit = 5
}

doRecursiveThings -path $path -limit $ld
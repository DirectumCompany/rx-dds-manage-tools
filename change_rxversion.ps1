# переключение на другую версию RX
Param ([string]$pathTargetVersion,
       [switch] $help)

# ============================ ОБРАБОТКА ПАРАМЕТРОВ =====================================
if($help){
  Write-Host " "
  Write-Host "change_rxversion.ps1 - переключение на другую версию RX"
  Write-Host "Формат вызова:"
  Write-Host "   .\change_rxversion.ps1 -pathTargetVersion <имя папки с каталогами wwwroot и 'Sungero Development Studio' [-help]"
  Write-Host "Предполагается, что в pathTargetVersion находятся два каталога: wwwroot и 'Sungero Development Studio'"
  Write-Host "Выполнять при отключенном IIS и DrxServiceRunnerLocal"
  Write-Host "Предполагается, что внутри папки, переданной в параметре pathTargetVersion находятся две папки: 'wwwroot' и 'Sungero Development Studio'."
  Write-Host "Суть переключения - создаются simlink-и на C:\inetpub\wwwroot\ и 'C:\Program Files\Directum Company\Sungero Development Studio'."
  Write-Host ""
  Break
}

if($pathTargetVersion -eq ""){
  Write-Host ""
  Write-Host "Не указан параметр -pathTargetVersion"
  Write-Host "Пример вызова:"
  Write-Host "   .\change_rxversion.ps1 -pathTargetVersion <имя папки с каталогами wwwroot и 'Sungero Development Studio' [-help]"
  Write-Host ""
  Break
}


$requiredWWWRoot = "C:\inetpub\wwwroot"
$requiredDDS = "C:\Program Files\Directum Company\Sungero Development Studio"

$realWWWRoot = $pathTargetVersion + "\wwwroot"
$realDDS =   $pathTargetVersion + "\Sungero Development Studio"

# ============================ ОСТАНОВКА СЛУЖБ =====================================
.\stop-rx.ps1


switch($PSVersionTable.PSVersion.Major)
{
  4 {
    #  Сделать симлинки для C:\inetpub\wwwroot\
    cmd /c rmdir $requiredWWWRoot /Q
    cmd /c mklink $requiredWWWRoot /d  $realWWWRoot
    #  Сделать симлинки для C:\Program Files\Directum Company\Sungero Development Studio
    cmd /c rmdir $requiredDDS /Q
    cmd /c mklink $requiredDDS /d  $realDDS
  }
  5 {
    #  Сделать симлинки для C:\inetpub\wwwroot\
    New-Item -ItemType SymbolicLink -Path $requiredWWWRoot -Target $realWWWRoot -Force
    #  Сделать симлинки для C:\Program Files\Directum Company\Sungero Development Studio
    New-Item -ItemType SymbolicLink -Path $requiredDDS -Target $realDDS -Force
  }
  default {
     Write-Host "Неизвестная верси Powershell " $PSVersionTable.PSVersion
  }
}

pause
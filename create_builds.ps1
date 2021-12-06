# подготовка инсталляционных комплектов при выпуске версии решения
Param ([string]$dds_path, 
       [string]$local_git_repo_path, 
       [string]$create_builds_config,
       [string]$solution_folder,
       [string]$version_number,
       [string]$mtd_for_version,
       [switch]$create_build,
       [switch]$create_zip,
       [switch]$help
)

function show_test_path($PathType, $Path) {
  $result = Test-Path -PathType $PathType -Path $Path
  Write-Host "      " $Path -NoNewLine
  if( -not $result) {
    Write-Host " не существует!" -ForegroundColor Red
  } else {
    Write-Host " существует!" -ForegroundColor Green
  }
  return $result
}


[Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding("utf-8")

# ============================ ОБРАБОТКА ПАРАМЕТРОВ =====================================
if($help){
  Write-Host ""
  Write-Host "create_builds.ps1 - подготовка инсталляционных комплектов при выпуске версии решения"
  Write-Host "Параметры:"
  Write-Host "  -dds_path - путь к DevelopmentStudio.exe. По умолчанию 'C:\Program Files\Directum Company\Sungero Development Studio\Bin\DevelopmentStudio.exe'"
  Write-Host "  -local_git_repo_path - путь к локальному репозиторию решения"
  Write-Host "  -create_builds_config - путь к конфигу, описывающему дистрибутивы, которые нужно собрать"
  Write-Host "  -solution_folder - путь к каталогу, в котором будет создан каталог с билдом"
  Write-Host "  -version_number - номер собираемой версии, может быть опущен, если указан параметр -mtd_for_version"
  Write-Host "  -mtd_for_version - путь к mtd-файлу, из которого возьмется номер собираемой версии. Рекомендуется указывать mtd-файл из shared-каталога solution"
  Write-Host "  -create_build - переключатель, указывающий, что нужно собрать билд. Если он не указан, то скрипт работает в режиме проверки параметров"
  Write-Host "  -create_zip - переключаетель, указывающий на необходимость создать архивы для дистрибутивов"
  Write-Host "  -help - вывод справки"
  Write-Host "Пример вызова:"
  Write-Host "   .\create_builds.ps1 -local_git_repo_path 'C:\RX\AppSol' -create_builds_config 'C:\RX\AppSol\build\builds_config.xml' -solution_folder 'D:\Install\AppSol' -version_number '1.1.3421.0' -create_build -create-zip"
  Write-Host ""
  Break
}


if($dds_path -eq ""){
  $dds_path = "C:\Program Files\Directum Company\Sungero Development Studio\Bin\DevelopmentStudio.exe"
}

if($local_git_repo_path -eq ""){
  Write-Host "Не указан параметр -local_git_repo_path"
  break
}

if($create_builds_config -eq ""){
  Write-Host "Не указан параметр -create_builds_config"
  break
}

if($solution_folder -eq ""){
  Write-Host "Не указан параметр -solution_folder"
  break
}

if(($version_number -eq "") -and ($mtd_for_version -eq "")){
  Write-Host "Необходимо указать один из параметров -version_number или -mtd_for_version"
  break
}

if($version_number -eq ""){
  if($mtd_for_version -eq ""){
    Write-Host "Необходимо указать один из параметров -version_number или -mtd_for_version"
    break
  } else {
    if ((Test-Path -PathType Leaf -Path $mtd_for_version)) {
      # найти версию билда из mtd-файла
      $mtd_file =  (Get-Content $mtd_for_version)
      foreach($s in $mtd_file) {
        if ($s.Contains('"Version":')) {
          $version_number = $s.Split(":")[1].Trim().Replace('"','').Replace(',','').ToString()
        }
      }
      if($version_number -eq "") {
        Write-Host "В "+$mtd_file+" не найден номер версии"
        break
      }
    }
  }
}


if(!$create_build) {
  #режим тестирования параметров
  $paths_is_ok = $true

  #протестировать параметры и конфиг
  Write-Host 'Тестирование переданных параметров'
  #Write-Host 'paths_is_ok: ' $paths_is_ok
  $paths_is_ok = $paths_is_ok -And (show_test_path -PathType Leaf -Path $mtd_for_version)
  $paths_is_ok = $paths_is_ok -And (show_test_path -PathType Container -Path $local_git_repo_path)
  #Write-Host 'paths_is_ok: ' $paths_is_ok
  $paths_is_ok = $paths_is_ok -And (show_test_path -PathType Leaf -Path $create_builds_config)
  $paths_is_ok = $paths_is_ok -And (show_test_path -PathType Leaf -Path $dds_path)

  $settings_xml = [xml](Get-Content $create_builds_config -Encoding UTF8)

  foreach($set_info in $settings_xml.DocumentElement.set_infos.SelectNodes("set_info")){
    foreach($pack_info in $set_info.SelectNodes("pack_info")){
      $config_full_path = Join-Path -Path $local_git_repo_path -ChildPath $pack_info.config_path
      $paths_is_ok = $paths_is_ok -And (show_test_path -PathType Leaf -Path $config_full_path)
    }
  
    foreach($file_info in $set_info.SelectNodes("file_info")){
      $copy_from = Join-Path -Path $local_git_repo_path -ChildPath $file_info.file_path
      $paths_is_ok = $paths_is_ok -And (show_test_path -PathType Any -Path $copy_from)
    }

    foreach($data in $settings_xml.DocumentElement.paths_for_copy_to_set.SelectNodes("path_for_copy_to_set")){
      $copy_from = Join-Path -Path $local_git_repo_path -ChildPath $data.path
      $paths_is_ok = $paths_is_ok -And (show_test_path -PathType Any -Path $copy_from)
    }
  }

  #Скопировать описание комплектов
  $sets_description = $settings_xml.DocumentElement.sets_description.path
  $sets_description_path = $local_git_repo_path + "\" + $sets_description
  $paths_is_ok = $paths_is_ok -And (show_test_path -PathType Leaf -Path $sets_description_path)

  if(-not $paths_is_ok) {
    Write-Host "Есть ошибки в параметрах" -ForegroundColor Red
    break
  } else {
    Write-Host "Параметры корректны" -ForegroundColor Green
  }
}

$version_folder = Join-Path -Path $solution_folder -ChildPath $version_number

if($create_build) {
  # ============================ ПРОВЕРКА НАЛИЧИЯ НЕЗАКОММИЧЕННЫХ ИЗМЕНЕНИЙ =====================================
  $git_status = git -C $local_git_repo_path status
  $git_status_str = [string]$git_status

  if(-Not $git_status_str.Contains("nothing to commit")){
    Write-Host "Невозможно выполнить операцию, имеются неотправленные локальные фиксации или изменения. Отправьте и повторите попытку."
    Break
  }

  # =========================== ПОДГОТОВКА КОМПЛЕКТОВ ===================================
  $settings_xml = [xml](Get-Content $create_builds_config -Encoding UTF8)

  foreach($set_info in $settings_xml.DocumentElement.set_infos.SelectNodes("set_info")){
  
    $d = Get-Date
    Write-Host 'Начало обработки комплекта ' $set_info.folder_name '  ' $d
  
    # папка комплекта
    $new_set_path = Join-Path -Path $version_folder -ChildPath $set_info.folder_name
  

    # признак необходимости увеличить номер верси
    if($set_info.HasAttribute("incrementversion")) {
      $increment_version = " --increment-version " + $set_info.incrementversion
      # если явно указано надо или менять номер версии
      # то откат изменений выполняется перед началом обработки всего комплекта, а не перед каждым дистрибутивом
      Write-Host '    Откат изменений в git-репозитории: ' $git_reset_result
      $git_reset_result = git -C $local_git_repo_path reset --hard
    } else {
      $increment_version = ""
    }


    foreach($pack_info in $set_info.SelectNodes("pack_info")){
   
      # выполнить откат изменений в репозитории только в том случае, если явно не указана надо или нет увеличивать номер билда
      # оставлено для совместимости
      if ($increment_version -eq "") {
        Write-Host '    Откат изменений в git-репозитории: ' $git_reset_result
        $git_reset_result = git -C $local_git_repo_path reset --hard
      }
	
      $config_full_path = Join-Path -Path $local_git_repo_path -ChildPath $pack_info.config_path
      Write-Host '    Конфиг пакета: ' $config_full_path
	
      $pack_name = $pack_info.pack_name + '.dat'
      $new_pack_name = Join-Path -Path $new_set_path -ChildPath $pack_name

      $pack_name_xml = $pack_info.pack_name + '.xml'
      $new_pack_name_xml = Join-Path -Path $new_set_path -ChildPath $pack_name_xml
    
      Write-Host "    Создание пакета " $new_pack_name
    
      # DDS запускается с ключами: -d <Имя пакета> -c <Путь к конфигу>
      $argumentList = '-d ' + $new_pack_name + ' -c ' + $config_full_path + $increment_version
      Write-Host $dds_path $argumentList 
      # старт DDS без ожидания завершения дочернего подпроцесса
      Start-Process -FilePath $dds_path -ArgumentList $argumentList -NoNewWindow -passthru | Wait-Process
      $s = show_test_path -PathType Leaf -Path $new_pack_name
      $s = show_test_path -PathType Leaf -Path $new_pack_name_xml
      Write-Host ""  
    }

    foreach($file_info in $set_info.SelectNodes("file_info")){
      $copy_from = Join-Path -Path $local_git_repo_path -ChildPath $file_info.file_path
      $copy_to = Join-Path -Path $new_set_path -ChildPath $file_info.file_name

      Write-Host '    Копирование ' $copy_from ' -->>  ' $copy_to
      $s = Copy-Item -Path $copy_from -Destination $copy_to -Recurse –Force
    }

  
    # Скопировать доп. данные в созданный комплект
    Write-Host "    Копирование доп.материалов в " $new_set_path
    foreach($data in $settings_xml.DocumentElement.paths_for_copy_to_set.SelectNodes("path_for_copy_to_set")){
      $copy_from = Join-Path -Path $local_git_repo_path -ChildPath $data.path
      if($data.HasAttribute("newpath")) {
        $copy_to = Join-Path -Path $new_set_path -ChildPath $data.newpath
      } else {
        $copy_to = Join-Path -Path $new_set_path -ChildPath $data.path
      }

      Write-Host "      " $copy_from "-->>" $copy_to
      $s = Copy-Item -Path $copy_from -Destination $copy_to -Recurse –Force
    }


    $d = Get-Date
    Write-Host 'Завершена обработка комплекта ' $set_info.folder_name '  ' $d
    Write-Host ""
  }

  #Скопировать описание комплектов
  $sets_description = $settings_xml.DocumentElement.sets_description.path
  $sets_description_path = $local_git_repo_path + "\" + $sets_description
  Write-Host 'Копирование описания комплектов ' $sets_description ' в ' $version_folder
  Copy-Item -Path $sets_description_path -Destination $version_folder -Recurse –Force
} 


if($create_zip) {
  Write-Host 'Создание архивов созданных комплектов в ' $solution_folder
  $settings_xml = [xml](Get-Content $create_builds_config -Encoding UTF8)

  foreach($set_info in $settings_xml.DocumentElement.set_infos.SelectNodes("set_info")){
    $new_set_path = Join-Path -Path $version_folder -ChildPath $set_info.folder_name
    $path_exist = Test-Path -PathType Container -Path $new_set_path
    if ($path_exist) {
      $arch_name = $set_info.zip_name + " v."+ $version_number + ".zip"
      $arch_path = Join-Path -Path $version_folder -ChildPath $arch_name
      Compress-Archive -Path $new_set_path -DestinationPath $arch_path -CompressionLevel Optimal
    }
  }

}

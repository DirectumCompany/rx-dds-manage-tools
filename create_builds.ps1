# подготовка инсталляционных комплектов при выпуске версии решения
Param ([string]$dds_path, 
       [string]$local_git_repo_path, 
       [string]$create_builds_config,
       [string]$solution_folder,
       [switch]$help,
       [switch]$test_mode)

function show_test_path($PathType, $Path) {
  $result = Test-Path -PathType $PathType -Path $Path
  Write-Host $Path -NoNewLine
  if( -not $result) {
    Write-Host " not exist!" -ForegroundColor Red
  } else {
    Write-Host " is ok!" -ForegroundColor Green
  }
}


[Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding("utf-8")

# ============================ ОБРАБОТКА ПАРАМЕТРОВ =====================================
if($help){
  Write-Host ""
  Write-Host "create_builds.ps1 - подготовка инсталляционных комплектов при выпуске версии решения"
  Write-Host "Формат вызова:"
  Write-Host "   .\create_builds.ps1 -dds_path <путь к DevelopmentStudio.exe> -local_git_repo_path <папка с репозиторием решения> -create_builds_config <конфиг с описанием комплектов> -solution_folder <папка, в которую выгружаются комплекты> [-help]"
  Write-Host "Пример вызова:"
  Write-Host "   .\create_builds.ps1 -local_git_repo_path 'C:\RX\AppSol' -create_builds_config 'C:\RX\AppSol\build\builds_config.xml' -solution_folder 'D:\Install\AppSol\1.1.3421.0'"
  Write-Host "Параметр dds_path может быть опущен. В этом случае используется значение по умолчанию - C:\Program Files\Directum Company\Sungero Development Studio\Bin\DevelopmentStudio.exe"
  Write-Host ""
  Break
}


if($dds_path -eq ""){
  $dds_path = "C:\Program Files\Directum Company\Sungero Development Studio\Bin\DevelopmentStudio.exe"
}

if($local_git_repo_path -eq ""){
  Write-Host "Не указан параметр -local_git_repo_path"
}

if($create_builds_config -eq ""){
  Write-Host "Не указан параметр -create_builds_config"
}

if($solution_folder -eq ""){
  Write-Host "Не указан параметр -solution_folder"
}

if($dds_path -eq "" -or $local_git_repo_path -eq "" -or $create_builds_config -eq "" -or $solution_folder -eq ""){
  Write-Host "Пример вызова:"
  Write-Host "   .\create_builds.ps1 -local_git_repo_path 'C:\RX\AppSol' -create_builds_config 'C:\RX\AppSol\build\builds_config.xml' -solution_folder 'D:\Install\AppSol\1.1.3421.0'"
  Break
}

# ============================ ПРОВЕРКА НАЛИЧИЯ НЕЗАКОММИЧЕННЫХ ИЗМЕНЕНИЙ =====================================
if(-not $test_mode) {
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
    $new_set_path = $solution_folder + "\" + $set_info.folder_name
  
    foreach($pack_info in $set_info.SelectNodes("pack_info")){
   
      # Откатить изменения номера билда
      Write-Host '    Откат изменений в git-репозитории: ' $git_reset_result
      $git_reset_result = git -C $local_git_repo_path reset --hard
	
      $config_full_path = $local_git_repo_path + "\" + $pack_info.config_path
      Write-Host '    Конфиг пакета: ' $config_full_path
	
      $new_pack_path = $solution_folder + "\" + $set_info.folder_name
      $new_pack_name = $new_pack_path + "\" + $pack_info.pack_name + '.dat'
    
      Write-Host "    Создание пакета " $new_pack_name
    
      # DDS запускается с ключами: -d <Имя пакета> -c <Путь к конфигу>
      $argumentList = '-d '+$new_pack_name+' -c '+$config_full_path
      Write-Host $dds_path $argumentList 
      # старт DDS без ожидания завершения дочернего подпроцесса
      Start-Process -FilePath $dds_path -ArgumentList $argumentList -NoNewWindow -passthru | Wait-Process
      Write-Host ""  
    }

    foreach($file_info in $set_info.SelectNodes("file_info")){
      $copy_from = $local_git_repo_path + "\" + $file_info.file_path
      $copy_to = $new_pack_path + "\" + $file_info.file_name
      Write-Host $copy_from ' -->>  ' $copy_to

      $current_data = Get-Item $copy_from 
      if ($current_data.PSIsContainer) {
        $s = New-Item -ItemType Directory -Force -Path $copy_to
        $copy_to = $new_pack_path
      }
      $s = Copy-Item -Path $copy_from -Destination $copy_to -Recurse –Force
    }

  
    # Скопировать доп. данные в созданный комплект
    Write-Host "    Копирование доп.материалов в " $new_pack_path
    foreach($data in $settings_xml.DocumentElement.paths_for_copy_to_set.SelectNodes("path_for_copy_to_set")){
      Write-Host "      " $data.path
      $copy_from = $local_git_repo_path + "\" + $data.path
      $copy_to = $new_pack_path + "\" + $data.path

      $current_data = Get-Item $copy_from 
      if ($current_data.PSIsContainer) {
        $s = New-Item -ItemType Directory -Force -Path $copy_to
        $copy_to = $new_pack_path
      }
      $s = Copy-Item -Path $copy_from -Destination $copy_to -Recurse –Force
    }


    $d = Get-Date
    Write-Host 'Завершена обработка комплекта ' $set_info.folder_name '  ' $d
    Write-Host ""
  }

  #Скопировать описание комплектов
  $sets_description = $settings_xml.DocumentElement.sets_description.path
  $sets_description_path = $local_git_repo_path + "\" + $sets_description
  Write-Host 'Копирование описания комплектов ' $sets_description ' в ' $solution_folder
  Copy-Item -Path $sets_description_path -Destination $solution_folder -Recurse –Force
} else {
  #протестировать параметры и конфиг
  show_test_path -PathType Container -Path $local_git_repo_path
  show_test_path -PathType Leaf -Path $create_builds_config
  show_test_path -PathType Leaf -Path $dds_path

  $settings_xml = [xml](Get-Content $create_builds_config -Encoding UTF8)

  foreach($set_info in $settings_xml.DocumentElement.set_infos.SelectNodes("set_info")){
    foreach($pack_info in $set_info.SelectNodes("pack_info")){
      $config_full_path = $local_git_repo_path + "\" + $pack_info.config_path
      show_test_path -PathType Leaf -Path $config_full_path
    }

    foreach($file_info in $set_info.SelectNodes("file_info")){
      $copy_from = $local_git_repo_path + "\" + $file_info.file_path
      show_test_path -PathType Any -Path $copy_from
    }

    foreach($data in $settings_xml.DocumentElement.paths_for_copy_to_set.SelectNodes("path_for_copy_to_set")){
      $copy_from = $local_git_repo_path + "\" + $data.path
      show_test_path -PathType Any -Path $copy_from
    }
  }

  #Скопировать описание комплектов
  $sets_description = $settings_xml.DocumentElement.sets_description.path
  $sets_description_path = $local_git_repo_path + "\" + $sets_description
  show_test_path -PathType Leaf -Path $sets_description_path

}


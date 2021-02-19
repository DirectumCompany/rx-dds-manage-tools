# переключение между разными прикладными проектами в рамках одной версии RX
Param ([string] $project_config,
       [switch] $test_mode,
       [switch] $help)

function new_file_name($file_name, $test_mode) {
  if(!$test_mode) {
    return $file_name  
  } else {
    return $file_name.Replace(".xml", ".xml_test")
  }
}

function replace_vars {
  Param ($file, $new_params, $new_repos=@())
  $xml = [xml](Get-Content $file -Encoding Ascii)
  $vars = $xml.SelectNodes("//var")
  $isChanged = $false
  foreach($new_param in $new_params) {
    foreach($var in $vars) {
      if($var.name -eq $new_param.Name) {
        $var.value = $new_param.Value
        $isChanged = $true
      }
    }
  }
  foreach($block in $xml.DocumentElement.block){
    if($block.name -eq "REPOSITORIES") {
      foreach($repo in $block.SelectNodes("repository")){
        $block.RemoveChild($repo)
      }
      foreach($nr in $new_repos){
        $repo = $xml.CreateElement("repository")
        $repo.SetAttribute("folderName", $nr["folderName"])
        $repo.SetAttribute("solutionType", $nr["solutionType"])
        $repo.SetAttribute("url", $nr["url"])
        $block.AppendChild($repo)
      }
    }
  }
  if($isChanged) {
    $nfn = new_file_name -file_name $file -test_mode $test_mode
    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    $sw = New-Object System.IO.StreamWriter($nfn, $false, $utf8WithoutBom)
    $xml.Save($sw) 
    $sw.Close()
  }
}

function show1 {
  Param ($title, $arr)
  Write-Host '============================='
  Write-Host $title
  foreach($a in $arr){
    Write-Host $a #"    " $a.Name " = " $a.Value
  }
  echo '.............................'
}              

function replace_macro_vars {
  Param($value, $macro_vars)
  foreach($v in $macro_vars){
    $value = $value.Replace($v.Keys[0], $v.Values[0])
  }
  return $value
}

# ============================ ОБРАБОТКА ПАРАМЕТРОВ =====================================
if($help){
  Write-Host ""
  Write-Host "change_project.ps1 - переключение между разными прикладными проектами в рамках одной версии RX"
  Write-Host "Проект - комплет *база данных* + *хранилище документов* + *исходники*."
  Write-Host "Формат вызова:"
  Write-Host "   .\change_project.ps1 -project_config <имя файла с конфигом проекта> [-test_mode] [-help]"
  Write-Host "Включение режима test_mode позволяет сымитировать корректировку конфигов - конфиги не правятся, но рядом с ними создаются файлы \*.xml_test с новыми данными."
  Write-Host ""
  Break
}


if($project_config -eq ""){
  Write-Host ""
  Write-Host "Не указан параметр -project_config"
  Write-Host "Формат вызова:"
  Write-Host "   .\change_project.ps1 -project_config <имя файла с конфигом проекта> [-test_mode] [-help]"
  Write-Host ""
  Break
}

$is_exist_project_config = Test-Path $project_config -PathType Leaf
if(!$is_exist_project_config){
  Write-Host ""
  Write-Host "Файл " $project_config " не существует."
  Write-Host ""
  Break
}


# ============================ ЧТЕНИЕ НОВЫХ ПАРАМЕТРОВ =====================================
Write-Host "Читаем новые параметры конфигов..."
$stand_xml =  [xml](Get-Content $project_config)

# Считать какие переменные надо менять под стенд
$macro_vars = @()
foreach($var in $stand_xml.DocumentElement.stand_vars.SelectNodes("var")){
  # подменить ранее считанные макропеременные
  $value = replace_macro_vars -value $var.value -macro_vars $macro_vars
  $macro_vars += @{$var.name=$value}
}


# Считать файл с описанием конфигов требуемой версии RX
foreach($var in $stand_xml.DocumentElement.rx_config_file.SelectNodes("var")){
  if($var.file -eq "rx_config") {
    $rx_config = $var.value
    break
  }
}
$settings_xml =  [xml](Get-Content $rx_config)
$wwwroot_dir = "C:\X\inetpub\wwwroot"
$ddsroot_dir = "C:\X\Program Files\Directum Company\Sungero Development Studio"
foreach($var in $settings_xml.DocumentElement.root_paths_rx.SelectNodes("var")){
  $macro_vars += @{$var.name=$var.value}
  if ($var.name -eq "!wwwroot!") {
    $wwwroot_dir = $var.value
  }
  if ($var.name -eq "!ddsroot!") {
    $ddsroot_dir = $var.value
  }
}

$dds_repos_params = @()
foreach($block in $stand_xml.DocumentElement.stand_vars.block){
  if($block.name -eq "REPOSITORIES") {
    foreach($repo in $block.SelectNodes("repository")){
      $dds_repos_params += @{'folderName'=$repo.folderName; 'solutionType'=$repo.solutionType; url=$repo.url}
    }
  }
}

$appliedmodules_paths = @()
foreach($var in $settings_xml.DocumentElement.appliedmodules.SelectNodes("var")){
  Write-Host $var
  $path = replace_macro_vars -value $var.path -macro_vars $macro_vars
  $appliedmodules_paths += @{'path'=$path}
}

Do {
  # Показать пользователю с какими параметрами будет произведена подмена
  Write-Host 'Будет выполнено переключение на стенд со следующими параметрами:'
  foreach($p in $macro_vars) {
     Write-Host '   ' $p.Keys[0] " = " -NoNewLine 
     if(($p.Keys[0] -eq "!DATABASE!") -or ($p.Keys[0] -eq "!DOC_ROOT_DIRECTORY!") -or ($p.Keys[0] -eq "!GIT_ROOT_DIRECTORY!")) {
       # значения критичных переменных вывести с выделением цветом
       Write-Host $p.Values[0] -ForegroundColor Green
     } else {
       Write-Host $p.Values[0]
     }
  }
  Write-Host  '    <block name="REPOSITORIES">'
  foreach($p in $dds_repos_params) {
    Write-Host '        <repository folderName="' -NoNewLine
    Write-Host $p.folderName -NoNewLine -ForegroundColor Green 
    Write-Host '" solutionType="' -NoNewLine
    Write-Host $p.solutionType -NoNewLine -ForegroundColor Green 
    Write-Host '" url="' -NoNewLine
    Write-Host $p.url -NoNewLine -ForegroundColor Green 
    Write-Host '" />'
     #$s = '        <repository folderName="' + $p.folderName + '" solutionType="' + $p.solutionType + '" url="' + $p.url + '" />'
     #echo $s
  }
  Write-Host  "    </block>"
  $answ = Read-Host "Продолжить (y/n)?"
} While ($answ -notin 'y', 'n', 'Y', 'N')

if($answ -in 'n', 'N') {
  break
}

if (!$test_mode) {
  ## ============================ ОСТАНОВКА СЛУЖБ =====================================
  .\stop-rx.ps1

  # ============================ ЧИСТКА AppliedModules =====================================
  Write-Host "Чистим AppliedModules..."
  foreach($p in $appliedmodules_paths) {
    $is_exist_path = Test-Path $p.path -PathType Container
    Write-Host "  " $p.path $is_exist_path
    if($is_exist_path) {
      Get-ChildItem $p.path -recurse | Remove-Item -Recurse -Confirm:$false -Force
    }
  }
}

#пройтись по каждому блоку переменных из settings
foreach($block in $settings_xml.DocumentElement.block){
  if($block.name -eq "config_files") {
    # Для каждого блока переменных
    #    - считать переменные
    #    - поменять в них макропеременные
    #    - пройтись по каждому файлу и подменить переменные
    foreach($config_file in $block.SelectNodes("config_file")){
      switch ($config_file.name) {
        "registry" {
          # подкорректировать реестр
          foreach($variable in $config_file.SelectNodes("var")) {
            $value = replace_macro_vars -value $variable.value -macro_vars $macro_vars
            Write-Host $config_file.file  " \ " $variable.name " \ " $value
            Set-ItemProperty -Path $config_file.file -Name $variable.name -Value $value
          }
        }
        "sungero_development_studio_readonly" {
          # пропустить описание конфигов DDS для запуска без возможности публикации
          continue
        }
        default {
          $file = $config_file.file.Replace('!wwwroot!', $wwwroot_dir).Replace('!ddsroot!', $ddsroot_dir)
          Write-Host "Корректируем конфиг: " $file
          $vars = @()
          foreach($variable in $config_file.SelectNodes("var")) {
            $value = replace_macro_vars -value $variable.value -macro_vars $macro_vars
            $vars += @{'Name'=$variable.name; 'Value'=$value}
          }
          if($config_file.name -eq "sungero_development_studio") {
            replace_vars -file $file -new_params $vars -new_repos $dds_repos_params
          } else {
            replace_vars -file $file -new_params $vars
          }
        }
      }
    }
  }
}

if (!$test_mode) {
  ## ============================ ЗАПУСК СЛУЖБ =====================================
  .\start-rx.ps1
}

pause
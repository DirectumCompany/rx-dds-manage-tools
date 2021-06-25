# запуск DDS для указанного проекта без возможности публикации
Param ([string]$project_config,
       [switch] $help)


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
    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    $sw = New-Object System.IO.StreamWriter($file, $false, $utf8WithoutBom)
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
  Write-Host "run_ro.ps1 - запуск DDS для указанного проекта без возможности публикации"
  Write-Host "Формат вызова:"
  Write-Host "   .\run_ro.ps1 -project_config <имя файла с конфигом проекта> [-help]"
  Write-Host "Логика работы:"
  Write-Host "	* создается копия файла _ConfigSettings.xml - _ConfigSettings_readonly.xml"
  Write-Host "	* в _ConfigSettings_readonly.xml:"
  Write-Host "		* меняются описания репозиториев"
  Write-Host "		* опустошаются параметры  LOCAL_SERVER_RELATIVE_PATH, LOCAL_WORKFLOW_PATH, LOCAL_WORKER_PATH, LOCAL_WEB_RELATIVE_PATH, QUEUE_CONNECTION_STRING"
  Write-Host "	* запускается DDS, которому передается _ConfigSettings_readonly.xml в качестве конфига. В запущенном DDS доступно редактирование исходников, но недоступна публикация."
  Write-Host "Может использоваться для быстрого просмотра исходников без фактического переключения стендов. При этом может быть запущено несколько экземпляров DDS."
  Write-Host ""
  Break
}

if($project_config -eq ""){
  Write-Host "Не указан параметр -project_config"
  Write-Host "Формат вызова:"
  Write-Host "   .\run_ro.ps1 -project_config <имя файла с конфигом проекта> [-help]"
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

foreach($var in $stand_xml.DocumentElement.rx_config_file.SelectNodes("var")){
  if($var.file -eq "rx_config") {
    $rx_config = $var.value
    break
  }
}

$settings_xml =  [xml](Get-Content $rx_config)
$ddsroot_dir = "C:\X\Program Files\Directum Company\Sungero Development Studio"
foreach($var in $settings_xml.DocumentElement.root_paths_rx.SelectNodes("var")){
  $macro_vars += @{$var.name=$var.value}
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

Do {
  # Показать пользователю с какими параметрами будет произведена подмена
  Write-Host 'Будет выполнено переключение на стенд со следующими параметрами:'
  foreach($p in $macro_vars) {
     Write-Host '   ' $p.Keys[0] " = " $p.Values[0]
  }
  Write-Host  '    <block name="REPOSITORIES">'
  foreach($p in $dds_repos_params) {
     $s = '        <repository folderName="' + $p.folderName + '" solutionType="' + $p.solutionType + '" url="' + $p.url + '" />'
     echo $s
  }
  Write-Host  "    </block>"
  $answ = Read-Host "Продолжить (y/n)?"
} While ($answ -notin 'y', 'n', 'Y', 'N')

if($answ -in 'n', 'N') {
  break
}

#пройтись по каждому блоку переменных из settings
foreach($block in $settings_xml.DocumentElement.block){
  if($block.name -eq "config_files") {
    # Для каждого блока переменных
    #    - считать переменные
    #    - поменять в них макропеременные
    #    - пройтись по каждому файлу и подменить переменные
    foreach($config_file in $block.SelectNodes("config_file")){
      if($config_file.name -eq "sungero_development_studio_readonly") {
        $file = $config_file.file.Replace('!ddsroot!', $ddsroot_dir)
        $file_readonly = $file.Replace("_ConfigSettings.xml", "_ConfigSettings_readonly.xml")
        Copy-Item -Path $file -Destination $file_readonly
        Write-Host "Корректируем конфиг: " $file_readonly
        $vars = @()
        foreach($variable in $config_file.SelectNodes("var")) {
          $value = replace_macro_vars -value $variable.value -macro_vars $macro_vars
          $vars += @{'Name'=$variable.name; 'Value'=$value}
        }
        replace_vars -file $file_readonly -new_params $vars -new_repos $dds_repos_params
      }
    }
  }
}

# Подготовить и запустить DDS
$dds_file = $ddsroot_dir + '\Bin\DevelopmentStudio.exe'
$dds_config = $file_readonly
$arg1 = '--multi-instance'
$arg2 = '--settings'
& $dds_file $arg1 $arg2 $dds_config


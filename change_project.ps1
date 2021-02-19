# ������������ ����� ������� ����������� ��������� � ������ ����� ������ RX
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

# ============================ ��������� ���������� =====================================
if($help){
  Write-Host ""
  Write-Host "change_project.ps1 - ������������ ����� ������� ����������� ��������� � ������ ����� ������ RX"
  Write-Host "������ - ������� *���� ������* + *��������� ����������* + *���������*."
  Write-Host "������ ������:"
  Write-Host "   .\change_project.ps1 -project_config <��� ����� � �������� �������> [-test_mode] [-help]"
  Write-Host "��������� ������ test_mode ��������� ������������ ������������� �������� - ������� �� ��������, �� ����� � ���� ��������� ����� \*.xml_test � ������ �������."
  Write-Host ""
  Break
}


if($project_config -eq ""){
  Write-Host ""
  Write-Host "�� ������ �������� -project_config"
  Write-Host "������ ������:"
  Write-Host "   .\change_project.ps1 -project_config <��� ����� � �������� �������> [-test_mode] [-help]"
  Write-Host ""
  Break
}

$is_exist_project_config = Test-Path $project_config -PathType Leaf
if(!$is_exist_project_config){
  Write-Host ""
  Write-Host "���� " $project_config " �� ����������."
  Write-Host ""
  Break
}


# ============================ ������ ����� ���������� =====================================
Write-Host "������ ����� ��������� ��������..."
$stand_xml =  [xml](Get-Content $project_config)

# ������� ����� ���������� ���� ������ ��� �����
$macro_vars = @()
foreach($var in $stand_xml.DocumentElement.stand_vars.SelectNodes("var")){
  # ��������� ����� ��������� ���������������
  $value = replace_macro_vars -value $var.value -macro_vars $macro_vars
  $macro_vars += @{$var.name=$value}
}


# ������� ���� � ��������� �������� ��������� ������ RX
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
  # �������� ������������ � ������ ����������� ����� ����������� �������
  Write-Host '����� ��������� ������������ �� ����� �� ���������� �����������:'
  foreach($p in $macro_vars) {
     Write-Host '   ' $p.Keys[0] " = " -NoNewLine 
     if(($p.Keys[0] -eq "!DATABASE!") -or ($p.Keys[0] -eq "!DOC_ROOT_DIRECTORY!") -or ($p.Keys[0] -eq "!GIT_ROOT_DIRECTORY!")) {
       # �������� ��������� ���������� ������� � ���������� ������
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
  $answ = Read-Host "���������� (y/n)?"
} While ($answ -notin 'y', 'n', 'Y', 'N')

if($answ -in 'n', 'N') {
  break
}

if (!$test_mode) {
  ## ============================ ��������� ����� =====================================
  .\stop-rx.ps1

  # ============================ ������ AppliedModules =====================================
  Write-Host "������ AppliedModules..."
  foreach($p in $appliedmodules_paths) {
    $is_exist_path = Test-Path $p.path -PathType Container
    Write-Host "  " $p.path $is_exist_path
    if($is_exist_path) {
      Get-ChildItem $p.path -recurse | Remove-Item -Recurse -Confirm:$false -Force
    }
  }
}

#�������� �� ������� ����� ���������� �� settings
foreach($block in $settings_xml.DocumentElement.block){
  if($block.name -eq "config_files") {
    # ��� ������� ����� ����������
    #    - ������� ����������
    #    - �������� � ��� ���������������
    #    - �������� �� ������� ����� � ��������� ����������
    foreach($config_file in $block.SelectNodes("config_file")){
      switch ($config_file.name) {
        "registry" {
          # ����������������� ������
          foreach($variable in $config_file.SelectNodes("var")) {
            $value = replace_macro_vars -value $variable.value -macro_vars $macro_vars
            Write-Host $config_file.file  " \ " $variable.name " \ " $value
            Set-ItemProperty -Path $config_file.file -Name $variable.name -Value $value
          }
        }
        "sungero_development_studio_readonly" {
          # ���������� �������� �������� DDS ��� ������� ��� ����������� ����������
          continue
        }
        default {
          $file = $config_file.file.Replace('!wwwroot!', $wwwroot_dir).Replace('!ddsroot!', $ddsroot_dir)
          Write-Host "������������ ������: " $file
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
  ## ============================ ������ ����� =====================================
  .\start-rx.ps1
}

pause
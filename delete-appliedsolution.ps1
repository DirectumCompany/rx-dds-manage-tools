# ������� ��������� AppliedSolution
Param ([string] $rx_config,
       [switch] $help)

# ============================ ��������� ���������� =====================================
if($help){
  Write-Host ""
  Write-Host "delete-appliedsolution.ps1 - ������� ��������� AppliedSolution"
  Write-Host "������ ������:"
  Write-Host "   .\delete-appliedsolution.ps1 -rx_config <��� ����� � �������� �������� � ������ RX> [-help]"
  Write-Host ""
  Break
}


if($rx_config -eq ""){
  Write-Host ""
  Write-Host "�� ������ �������� -project_config"
  Write-Host "������ ������:"
  Write-Host "   .\delete-appliedsolution.ps1 -rx_config <��� ����� � �������� �������� � ������ RX> [-help]"
  Write-Host ""
  Break
}

$is_exist_rx_config = Test-Path $rx_config -PathType Leaf
if(!$is_exist_rx_config){
  Write-Host ""
  Write-Host "���� " $rx_config " �� ����������."
  Write-Host ""
  Break
}

function replace_macro_vars {
  Param($value, $macro_vars)
  foreach($v in $macro_vars){
    $value = $value.Replace($v.Keys[0], $v.Values[0])
  }
  return $value
}

# ============================ ������� ������ ��������� =============================
$settings_xml =  [xml](Get-Content $rx_config)
$macro_vars = @()
foreach($var in $settings_xml.DocumentElement.root_paths_rx.SelectNodes("var")){
  $macro_vars += @{$var.name=$var.value}
}

$appliedmodules_paths = @()
foreach($var in $settings_xml.DocumentElement.appliedmodules.SelectNodes("var")){
  $path = replace_macro_vars -value $var.path -macro_vars $macro_vars
  $appliedmodules_paths += @{'path'=$path}
}

# ============================= ��������� ������� =========================================
Start-Process -FilePath 'iisreset' -ArgumentList '/stop' -NoNewWindow  -Wait
Start-Process -FilePath 'net' -ArgumentList 'stop DrxServiceRunnerLocal' -NoNewWindow -Wait

# ============================ ������ AppliedModules =====================================
Write-Host "������ AppliedModules..."
foreach($p in $appliedmodules_paths) {
  $is_exist_path = Test-Path $p.path -PathType Container
  Write-Host "  " $p.path $is_exist_path
  if($is_exist_path) {
    Get-ChildItem $p.path -recurse | Remove-Item -Recurse -Confirm:$false -Force
  }
}

# ============================= �������� ������� ������� =========================================
Start-Process -FilePath 'iisreset' -ArgumentList '/start' -NoNewWindow  -Wait
Start-Process -FilePath 'net' -ArgumentList 'start DrxServiceRunnerLocal' -NoNewWindow  -Wait

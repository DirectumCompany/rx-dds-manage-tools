# ���������� ��������������� ���������� ��� ������� ������ �������
Param ([string]$dds_path, 
       [string]$local_git_repo_path, 
       [string]$create_builds_config,
       [string]$solution_folder,
       [switch] $help)

[Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding("utf-8")

# ============================ ��������� ���������� =====================================
if($help){
  Write-Host ""
  Write-Host "create_builds.ps1 - ���������� ��������������� ���������� ��� ������� ������ �������"
  Write-Host "������ ������:"
  Write-Host "   .\create_builds.ps1 -dds_path <���� � DevelopmentStudio.exe> -local_git_repo_path <����� � ������������ �������> -create_builds_config <������ � ��������� ����������> -solution_folder <�����, � ������� ����������� ���������> [-help]"
  Write-Host "������ ������:"
  Write-Host "   .\create_builds.ps1 -local_git_repo_path 'C:\RX\AppSol' -create_builds_config 'C:\RX\AppSol\build\builds_config.xml' -solution_folder 'D:\Install\AppSol\1.1.3421.0'"
  Write-Host "�������� dds_path ����� ���� ������. � ���� ������ ������������ �������� �� ��������� - C:\Program Files\Directum Company\Sungero Development Studio\Bin\DevelopmentStudio.exe"
  Write-Host ""
  Break
}


if($dds_path -eq ""){
  $dds_path = "C:\Program Files\Directum Company\Sungero Development Studio\Bin\DevelopmentStudio.exe"
}

if($local_git_repo_path -eq ""){
  Write-Host "�� ������ �������� -local_git_repo_path"
}

if($create_builds_config -eq ""){
  Write-Host "�� ������ �������� -create_builds_config"
}

if($solution_folder -eq ""){
  Write-Host "�� ������ �������� -solution_folder"
}

if($dds_path -eq "" -or $local_git_repo_path -eq "" -or $create_builds_config -eq "" -or $solution_folder -eq ""){
  Write-Host "������ ������:"
  Write-Host "   .\create_builds.ps1 -local_git_repo_path 'C:\RX\AppSol' -create_builds_config 'C:\RX\AppSol\build\builds_config.xml' -solution_folder 'D:\Install\AppSol\1.1.3421.0'"
  Break
}

# ============================ �������� ������� ��������������� ��������� =====================================
$git_status = git -C $local_git_repo_path status
$git_status_str = [string]$git_status

if(-Not $git_status_str.Contains("nothing to commit")){
  Write-Host "���������� ��������� ��������, ������� �������������� ��������� �������� ��� ���������. ��������� � ��������� �������."
  Break
}

# =========================== ���������� ���������� ===================================
$settings_xml = [xml](Get-Content $create_builds_config -Encoding UTF8)

foreach($set_info in $settings_xml.DocumentElement.set_infos.SelectNodes("set_info")){
  
  Write-Host '��������� ��������� ' $set_info.folder_name
  
  # ����� ���������
  $new_set_path = $solution_folder + "\" + $set_info.folder_name
  
  foreach($pack_info in $set_info.SelectNodes("pack_info")){
   
   # �������� ��������� ������ �����
    Write-Host '    ����� ��������� � git-�����������: ' $git_reset_result
    $git_reset_result = git -C $local_git_repo_path reset --hard
	
    $config_full_path = $local_git_repo_path + "\" + $pack_info.config_path
    Write-Host '    ������ ������: ' $config_full_path
	
    $new_pack_path = $solution_folder + "\" + $set_info.folder_name
    $new_pack_name = $new_pack_path + "\" + $pack_info.pack_name + '.dat'
    
    Write-Host "    �������� ������ " $new_pack_name
    
    # DDS ����������� � �������: -d <��� ������> -c <���� � �������>
    $argumentList = '-d '+$new_pack_name+' -c '+$config_full_path
    Write-Host $dds_path $argumentList 
    Start-Process -FilePath $dds_path -ArgumentList $argumentList -Wait -NoNewWindow
    Write-Host ""  
  }
  
  # ����������� ���. ������ � ��������� ��������
  Write-Host "    ����������� ���.���������� � " $new_pack_path
  foreach($data in $settings_xml.DocumentElement.paths_for_copy_to_set.SelectNodes("path_for_copy_to_set")){
    Write-Host "      " $data.path
    $copy_from = $local_git_repo_path + "\" + $data.path
    $copy_to = $new_pack_path + "\" + $data.path

    $current_data = Get-Item $copy_from 
    if ($current_data.PSIsContainer) {
      $s = New-Item -ItemType Directory -Force -Path $copy_to
      $copy_to = $new_pack_path
    }
    $s = Copy-Item -Path $copy_from -Destination $copy_to -Recurse �Force
  }
  Write-Host ""
}

#����������� �������� ����������
$sets_description = $settings_xml.DocumentElement.sets_description.path
$sets_description_path = $local_git_repo_path + "\" + $sets_description
Write-Host '����������� �������� ���������� ' $sets_description ' � ' $solution_folder
Copy-Item -Path $sets_description_path -Destination $solution_folder -Recurse �Force
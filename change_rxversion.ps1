# ������������ �� ������ ������ RX
Param ([string]$pathTargetVersion,
       [switch] $help)

# ============================ ��������� ���������� =====================================
if($help){
  Write-Host ""
  Write-Host "change_rxversion.ps1 - ������������ �� ������ ������ RX"
  Write-Host "������ ������:"
  Write-Host "   .\change_rxversion.ps1 -pathTargetVersion <��� ����� � ���������� wwwroot � 'Sungero Development Studio' [-help]"
  Write-Host "��������������, ��� � pathTargetVersion ��������� ��� ��������: wwwroot � 'Sungero Development Studio'"
  Write-Host "��������� ��� ����������� IIS � DrxServiceRunnerLocal"
  Write-Host "��������������, ��� ������ �����, ���������� � ��������� pathTargetVersion ��������� ��� �����: 'wwwroot' � 'Sungero Development Studio'."
  Write-Host "���� ������������ - ��������� simlink-� �� C:\inetpub\wwwroot\ � 'C:\Program Files\Directum Company\Sungero Development Studio'."
  Write-Host ""
  Break
}

if($pathTargetVersion -eq ""){
  Write-Host ""
  Write-Host "�� ������ �������� -pathTargetVersion"
  Write-Host "������ ������:"
  Write-Host "   .\change_rxversion.ps1 -pathTargetVersion <��� ����� � ���������� wwwroot � 'Sungero Development Studio' [-help]"
  Write-Host ""
  Break
}


$requiredWWWRoot = "C:\inetpub\wwwroot"
$requiredDDS = "C:\Program Files\Directum Company\Sungero Development Studio"

$realWWWRoot = $pathTargetVersion + "\wwwroot"
$realDDS =   $pathTargetVersion + "\Sungero Development Studio"

# ============================ ��������� ����� =====================================
.\stop-rx.ps1


switch($PSVersionTable.PSVersion.Major)
{
  4 {
    #  ������� �������� ��� C:\inetpub\wwwroot\
    cmd /c rmdir $requiredWWWRoot /Q
    cmd /c mklink $requiredWWWRoot /d  $realWWWRoot
    #  ������� �������� ��� C:\Program Files\Directum Company\Sungero Development Studio
    cmd /c rmdir $requiredDDS /Q
    cmd /c mklink $requiredDDS /d  $realDDS
  }
  5 {
    #  ������� �������� ��� C:\inetpub\wwwroot\
    New-Item -ItemType SymbolicLink -Path $requiredWWWRoot -Target $realWWWRoot -Force
    #  ������� �������� ��� C:\Program Files\Directum Company\Sungero Development Studio
    New-Item -ItemType SymbolicLink -Path $requiredDDS -Target $realDDS -Force
  }
  default {
     Write-Host "����������� ����� Powershell " $PSVersionTable.PSVersion
  }
}

pause
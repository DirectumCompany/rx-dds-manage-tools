# �������� ����� �������� RX
Param ([string]$path_log, 
       [int]$limit_day,
       [switch] $help)

# ============================ ��������� ���������� =====================================
if($help){
  Write-Host ""
  Write-Host "remove-old-logs.ps1 - �������� ����� �������� RX"
  Write-Host "������ ������:"
  Write-Host "   .\remove-old-logs.ps1 [-path_log <�������� ����� � ������ ��������>] [-limit_day <�� ������� ���� �������� ����>] [-help]"
  Write-Host "������� ��� ������������ -path_log � ������� ����, �������� ���� �� -limit_day, ������� � �������� ���."
  Write-Host "���� �������� -path_log �����������, �� ������� �������� �� ��������� - C:\inetpub\logs\"
  Write-Host "���� �������� -limit_day �����������, �� ������� �������� �� ��������� - 5"
  Write-Host "���� ��������� � ���������� '-limit_day -1' - ����� ������� ��� ����. � ���� ������ ������������� �������������� ���������� ������."
  Write-Host "��������������, ��� ������ ������ � ������ ��������� 10 �������� - ��� ���� � ������� YYYY-MM-DD"
  Write-Host ""
  Break
}


function doRecursiveThings ($path="C:\inetpub\logs\", $limit=5)
{
  $childs = Get-ChildItem $path
  
  foreach($child in $childs) {
    #���-�� ������ ���� ���� ������ ��� ������� ��������

    if( [System.IO.File]::GetAttributes($child.FullName) -eq [System.IO.FileAttributes]::Directory ) {
      #��� ��� ���-�� ������, ���� ����� ������� ���-�� � ������ ������ � �������
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
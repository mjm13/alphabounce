$f='D:\Project\SELF\alphabounce\game\scenes\entities\Block.tscn'
$b=[System.IO.File]::ReadAllBytes($f)
Write-Host ('total='+$b.Length)
Write-Host ('first3='+($b[0].ToString('X2')+' '+$b[1].ToString('X2')+' '+$b[2].ToString('X2')))
if($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF){ Write-Host HAS_BOM } else { Write-Host NO_BOM }

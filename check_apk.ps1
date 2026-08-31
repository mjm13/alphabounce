$z='D:\Project\SELF\alphabounce\game\bin\AlphaBounce_debug.apk'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zf=[System.IO.Compression.ZipFile]::OpenRead($z)
$e=$zf.Entries | Where-Object { $_.FullName -like '*R08_enemy_debug.gd' }
if($e){ $s=$e.Open(); $r=New-Object System.IO.StreamReader($s); $t=$r.ReadToEnd(); $zf.Dispose(); if($t -like '*as EvEnemy*'){Write-Host APK_HAS_FIX} else {Write-Host APK_OLD_CODE}; Write-Host ('len='+$t.Length) } else { $zf.Dispose(); Write-Host NO_ENTRY }

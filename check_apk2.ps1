$z='D:\Project\SELF\alphabounce\game\bin\AlphaBounce_debug.apk'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zf=[System.IO.Compression.ZipFile]::OpenRead($z)
$all=$zf.Entries | ForEach-Object { $_.FullName }
$zf.Dispose()
$r08=$all | Where-Object { $_ -like '*R08*' }
Write-Host ('R08_MATCHES='+($r08.Count))
$r08 | ForEach-Object { Write-Host $_ }
$gd=$all | Where-Object { $_ -like '*.gd' } | Select-Object -First 5
Write-Host ('GD_SAMPLE=')
$gd | ForEach-Object { Write-Host $_ }
$gdc=$all | Where-Object { $_ -like '*.gdc' } | Select-Object -First 5
Write-Host ('GDC_SAMPLE=')
$gdc | ForEach-Object { Write-Host $_ }
$dbg=$all | Where-Object { $_ -like '*debug*' } | Select-Object -First 10
Write-Host ('DEBUG_SAMPLE=')
$dbg | ForEach-Object { Write-Host $_ }

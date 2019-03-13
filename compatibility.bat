reg.exe add^
 "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"^
 /v "%~dp0GRUNTZ.EXE"^
 /t REG_SZ^
 /d WINXPSP2^
 /f

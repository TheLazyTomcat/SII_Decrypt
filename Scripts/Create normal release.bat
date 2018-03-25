@echo off

if exist ..\Release rd ..\Release /s /q

mkdir ..\Release

copy ..\program_readme.txt ..\Release\readme.txt

copy ..\license.txt ..\Release\license.txt

copy ..\Program_Console\Delphi\Release\win_x86\SII_Decrypt.exe "..\Release\SII_Decrypt[D32].exe"

copy ..\Program_Console\Lazarus\Release\win_x86\SII_Decrypt.exe "..\Release\SII_Decrypt[L32].exe"

copy ..\Program_Console\Lazarus\Release\win_x64\SII_Decrypt.exe "..\Release\SII_Decrypt[L64].exe"
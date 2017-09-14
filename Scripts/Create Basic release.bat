@echo off

if exist ..\Release rd ..\Release /s /q

mkdir ..\Release

copy ..\program_readme.txt ..\Release\readme.txt

copy ..\license.txt ..\Release\license.txt

copy ..\Program\Delphi\Release\win_x86\SII_Decrypt.exe "..\Release\SII_Decrypt.exe"
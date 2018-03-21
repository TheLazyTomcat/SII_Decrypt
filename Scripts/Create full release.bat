@echo off

if exist ..\Release rd ..\Release /s /q

mkdir ..\Release

mkdir ..\Release\Library

copy ..\program_readme.txt ..\Release\readme.txt

copy ..\license.txt ..\Release\license.txt

copy ..\Program\Delphi\Release\win_x86\SII_Decrypt.exe  "..\Release\SII_Decrypt[D32].exe"
copy ..\Program\Lazarus\Release\win_x86\SII_Decrypt.exe "..\Release\SII_Decrypt[L32].exe"
copy ..\Program\Lazarus\Release\win_x64\SII_Decrypt.exe "..\Release\SII_Decrypt[L64].exe"

copy ..\Library\Delphi\Release\win_x86\SII_Decrypt.dll  "..\Release\Library\SII_Decrypt[D32].dll" 
copy ..\Library\Lazarus\Release\win_x86\SII_Decrypt.dll "..\Release\Library\SII_Decrypt[L32].dll"
copy ..\Library\Lazarus\Release\win_x64\SII_Decrypt.dll "..\Release\Library\SII_Decrypt[L64].dll"

copy ..\Headers\SII_Decrypt_Header.pas "..\Release\Library\SII_Decrypt_Header.pas"
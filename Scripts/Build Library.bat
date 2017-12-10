@echo off

pushd .

cd ..\Library\Delphi
dcc32.exe -Q -B SII_Decrypt.dpr

cd ..\Lazarus
lazbuild -B --no-write-project --bm=Release_win_x86 SII_Decrypt.lpi
lazbuild -B --no-write-project --bm=Release_win_x64 SII_Decrypt.lpi
lazbuild -B --no-write-project --bm=Debug_win_x86 SII_Decrypt.lpi
lazbuild -B --no-write-project --bm=Debug_win_x64 SII_Decrypt.lpi

popd
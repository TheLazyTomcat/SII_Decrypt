@echo off

pushd .

cd ..\Tester\Delphi
dcc32.exe -Q -B SII_Decrypt_Tester.dpr

cd ..\Lazarus
lazbuild -B --bm=Devel_win_x86 SII_Decrypt_Tester.lpi
lazbuild -B --bm=Devel_win_x64 SII_Decrypt_Tester.lpi

popd
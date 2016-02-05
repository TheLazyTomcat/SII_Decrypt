program SII_Decrypt_Tester;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  SII_DecryptLib in '..\..\Headers\SII_DecryptLib.pas';

begin
  Load_SII_Decrypt('..\..\Library\Delphi\Release\win_x86\SII_Decrypt.dll');
  try
    If ParamCount > 0 then
      WriteLn(Ord(DecryptFile(PAnsiChar(ParamStr(1)),PAnsiChar(ParamStr(1) + '.out'))));
    Write('Press enter to continue...'); ReadLn;
  finally
    Unload_SII_Decrypt;
  end;
end.

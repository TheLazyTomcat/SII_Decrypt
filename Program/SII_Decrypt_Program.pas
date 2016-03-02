{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decrypt_Program;

interface

procedure Main;

implementation

uses
  SysUtils, Decryptor
  {$IF Defined(FPC) and not Defined(Unicode) and (FPC_FULLVERSION < 20701)}
  , LazUTF8
  {$IFEND};

procedure Main;
begin
try
  WriteLn('*******************************');
  WriteLn('*     SII Decrypt Program     *');
  WriteLn('*   (c) 2016 Frantisek Milt   *');
  WriteLn('*******************************');
  WriteLn;
  If ParamCount <= 0 then
    begin
      WriteLn('usage:');
      WriteLn;
      WriteLn('  SII_Decrypt.exe InputFile [OutputFile]');
      WriteLn;
      WriteLn('    InputFile - file that has to be decrypted');
      WriteLn('    OutputFile (optional) - target file where to store the decrypted result');
      WriteLn;
      Write('Press enter to continue...'); ReadLn;
    end
  else
    begin
      with TSIIDecryptor.Create do
      try
        If ParamCount >= 2 then
      {$IF Defined(FPC) and not Defined(Unicode) and (FPC_FULLVERSION < 20701)}
          ExitCode := Ord(DecryptFile(WinCPToUTF8(ParamStr(1)),WinCPToUTF8(ParamStr(2))))
        else
          ExitCode := Ord(DecryptFile(WinCPToUTF8(ParamStr(1)),WinCPToUTF8(ParamStr(1))));
      {$ELSE}
          ExitCode := Ord(DecryptFile(ParamStr(1),ParamStr(2)))
        else
          ExitCode := Ord(DecryptFile(ParamStr(1),ParamStr(1)));
      {$IFEND}
      finally
        Free;
      end;
    end;
except
  on E: Exception do
    begin
      WriteLn(E.Message);
      ExitCode := -1;
    end;
end;
end;

end.

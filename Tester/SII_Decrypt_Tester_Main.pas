{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decrypt_Tester_Main;

interface

procedure Main;

implementation

uses
  SysUtils, Classes, AuxTypes, StrRect, SII_Decrypt_Header;

const
{$IFDEF FPC}
  PathPrefix = '..\..\..\';
{$ELSE}
  PathPrefix = '..\..\';
{$ENDIF}

procedure Main;
var
  MemStream:  TMemoryStream;
  OutBuff:    Pointer;
  OutSize:    TMemSize;
begin
{$IF SizeOf(Pointer) = 8}
Load_SII_Decrypt(PathPrefix + 'Library\Lazarus\Release\win_x64\SII_Decrypt.dll');
{$ELSE}
{$IFDEF FPC}
Load_SII_Decrypt(PathPrefix + 'Library\Lazarus\Release\win_x86\SII_Decrypt.dll');
{$ELSE}
Load_SII_Decrypt(PathPrefix + 'Library\Delphi\Release\win_x86\SII_Decrypt.dll');
{$ENDIF}
{$IFEND}
try
try
  If ParamCount > 0 then
    begin
      MemStream := TMemoryStream.Create;
      try
        WriteLn(DecryptFile(PUTF8Char(StrToUTF8(RTLToStr(ParamStr(1)))),PUTF8Char(StrToUTF8(RTLToStr(ParamStr(1)) + '.fout'))));
        WriteLn(DecodeFile(PUTF8Char(StrToUTF8(RTLToStr(ParamStr(1)))),PUTF8Char(StrToUTF8(RTLToStr(ParamStr(1)) + '.f2out'))));
        WriteLn(DecryptAndDecodeFile(PUTF8Char(StrToUTF8(RTLToStr(ParamStr(1)))),PUTF8Char(StrToUTF8(RTLToStr(ParamStr(1)) + '.fdout'))));

        MemStream.LoadFromFile(ParamStr(1));
        If DecryptAndDecodeMemory(MemStream.Memory,MemStream.Size,nil,@OutSize) = SIIDEC_RESULT_SUCCESS then
          begin
            GetMem(OutBuff,OutSize);
            try
              MemStream.Position := 0;
              WriteLn(DecryptAndDecodeMemory(MemStream.Memory,MemStream.Size,OutBuff,@OutSize));
              MemStream.Seek(0,soBeginning);
              MemStream.WriteBuffer(OutBuff^,OutSize);
              MemStream.Size := OutSize;
              MemStream.SaveToFile(ParamStr(1) + '.mout');
            finally
              FreeMem(OutBuff,OutSize);
            end;
          end;
      finally
        MemStream.Free;
      end;
    end;
  Write('Press enter to continue...'); ReadLn;
finally
  Unload_SII_Decrypt;
end;
except
  on E: Exception do
    begin
      Write('Error ',E.Message); ReadLn;
    end;
end;
end;

end.


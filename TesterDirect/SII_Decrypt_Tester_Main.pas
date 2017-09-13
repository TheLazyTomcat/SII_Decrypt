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
  SysUtils, Classes, AuxTypes, StrRect, SII_Decrypt_Library, SII_Decrypt_Header;

procedure Main;
var
  TestStream: TMemoryStream;
  Output:     Pointer;
  AllocSize:  TMemSize;
  OutSize:    TMemSize;
  Helper:     Pointer;
  Result:     Int32;

  Function StrPrep(Str: String): UTF8String;
  begin
    Result := StrToUTF8(RTLToStr(Str));
  end;

begin
try
  If ParamCount > 0 then
    begin
      TestStream := TMemoryStream.Create;
      try
        TestStream.LoadFromFile(ParamStr(1));
        WriteLn('Exp_GetMemoryFormat   ',Exp_GetMemoryFormat(TestStream.Memory,TestStream.Size));
        WriteLn('Exp_GetFileFormat     ',Exp_GetFileFormat(PUTF8Char(StrPrep(ParamStr(1)))));
        WriteLn('Exp_IsEncryptedMemory ',Exp_IsEncryptedMemory(TestStream.Memory,TestStream.Size));
        WriteLn('Exp_IsEncryptedFile   ',Exp_IsEncryptedFile(PUTF8Char(StrPrep(ParamStr(1)))));
        WriteLn('Exp_IsEncodedMemory   ',Exp_IsEncodedMemory(TestStream.Memory,TestStream.Size));
        WriteLn('Exp_IsEncodedFile     ',Exp_IsEncodedFile(PUTF8Char(StrPrep(ParamStr(1)))));
//--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
        WriteLn;
        Result := Exp_DecryptMemory(TestStream.Memory,TestStream.Size,nil,@AllocSize);
        WriteLn('Exp_DecryptMemory #1 ',Result);
        If Result = SIIDEC_RESULT_SUCCESS then
          begin
            GetMem(Output,AllocSize);
            try
              OutSize := AllocSize;
              WriteLn('Exp_DecryptMemory #2 ',Exp_DecryptMemory(TestStream.Memory,TestStream.Size,Output,@OutSize));
            finally
              FreeMem(Output,AllocSize);
            end;
          end;
        WriteLn('Exp_DecryptFile      ',Exp_DecryptFile(PUTF8Char(StrPrep(ParamStr(1))),PUTF8Char(StrPrep(ParamStr(1) + '.out'))));
//--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
        WriteLn;
        Result := Exp_DecodeMemory(TestStream.Memory,TestStream.Size,nil,@AllocSize);
        WriteLn('Exp_DecodeMemory #1       ',Result);
        If Result = SIIDEC_RESULT_SUCCESS then
          begin
            GetMem(Output,AllocSize);
            try
              OutSize := AllocSize;
              WriteLn('Exp_DecodeMemory #2       ',Exp_DecodeMemory(TestStream.Memory,TestStream.Size,Output,@OutSize));
            finally
              FreeMem(Output,AllocSize);
            end;
          end;
        Result := Exp_DecodeMemoryHelper(TestStream.Memory,TestStream.Size,nil,@AllocSize,@Helper);
        WriteLn('Exp_DecodeMemoryHelper #1 ',Result);
        If Result = SIIDEC_RESULT_SUCCESS then
          begin
            GetMem(Output,AllocSize);
            try
              OutSize := AllocSize;
              WriteLn('Exp_DecodeMemoryHelper #2 ',Exp_DecodeMemoryHelper(TestStream.Memory,TestStream.Size,Output,@OutSize,@Helper));
            finally
              FreeMem(Output,AllocSize);
            end;
          end
        else Exp_FreeHelper(@Helper);
        WriteLn('Exp_DecodeFile            ',Exp_DecodeFile(PUTF8Char(StrPrep(ParamStr(1))),PUTF8Char(StrPrep(ParamStr(1) + '.out'))));
//--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --
        WriteLn;
        Result := Exp_DecryptAndDecodeMemory(TestStream.Memory,TestStream.Size,nil,@AllocSize);
        WriteLn('Exp_DecryptAndDecodeMemory #1       ',Result);
        If Result = SIIDEC_RESULT_SUCCESS then
          begin
            GetMem(Output,AllocSize);
            try
              OutSize := AllocSize;
              WriteLn('Exp_DecryptAndDecodeMemory #2       ',Exp_DecryptAndDecodeMemory(TestStream.Memory,TestStream.Size,Output,@OutSize));
            finally
              FreeMem(Output,AllocSize);
            end;
          end;
        Result := Exp_DecryptAndDecodeMemoryHelper(TestStream.Memory,TestStream.Size,nil,@AllocSize,@Helper);
        WriteLn('Exp_DecryptAndDecodeMemoryHelper #1 ',Result);
        If Result = SIIDEC_RESULT_SUCCESS then
          begin
            GetMem(Output,AllocSize);
            try
              OutSize := AllocSize;
              WriteLn('Exp_DecryptAndDecodeMemoryHelper #2 ',Exp_DecryptAndDecodeMemoryHelper(TestStream.Memory,TestStream.Size,Output,@OutSize,@Helper));
            finally
              FreeMem(Output,AllocSize);
            end;
          end
        else Exp_FreeHelper(@Helper);
        WriteLn('Exp_DecryptAndDecodeFile            ',Exp_DecryptAndDecodeFile(PUTF8Char(StrPrep(ParamStr(1))),PUTF8Char(StrPrep(ParamStr(1) + '.out'))));
      finally
        TestStream.Free;
      end;
      WriteLn;
      Write('Press enter to continue...'); ReadLn;
    end;
except
  on E: Exception do
    begin
      Write('Error ',E.Message); ReadLn;
    end;
end;
end;

end.


{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decrypt_Tester_LibraryDirect;

interface

uses
  CRC32;

procedure TestOnFile(const FileName: String; FileFormat: Integer; BinCRC32, TextCRC32: TCRC32);

implementation

uses
  SysUtils, Classes,
  AuxTypes, StrRect,
  SII_Decrypt_Library_Header, SII_Decrypt_Library_Standalone;

procedure TestOnFile(const FileName: String; FileFormat: Integer; BinCRC32, TextCRC32: TCRC32);
var
  FileDataStream: TMemoryStream;
  OpResult:       Integer;
  Output:         Pointer;
  OutSize:        TMemSize;
  AllocSize:      TMemSize;
  Helper:         Pointer;
begin
WriteLn(StringOfChar('-',75));
WriteLn('  SII Decrypt Tester - Library direct');
WriteLn(StringOfChar('-',75));
WriteLn;
WriteLn('FileName:  ',FileName);
WriteLn('Format:    ',FileFormat);
WriteLn('BinCRC32:  ',CRC32ToStr(BinCRC32));
WriteLn('TextCRC32: ',CRC32ToStr(TextCRC32));
try
  WriteLn;
  WriteLn('  Exp_APIVersion: 0x',Format('%.8x',[Exp_APIVersion]));
  FileDataStream := TMemoryStream.Create;
  try
    FileDataStream.LoadFromFile(FileName);
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    WriteLn;
    WriteLn('  Exp_GetMemoryFormat:    ',Exp_GetMemoryFormat(FileDataStream.Memory,FileDataStream.Size));
    WriteLn('  Exp_GetFileFormat:      ',Exp_GetFileFormat(PUTF8Char(StrToUTF8(FileName))));
    WriteLn('  Exp_IsEncryptedMemory:  ',Exp_IsEncryptedMemory(FileDataStream.Memory,FileDataStream.Size));
    WriteLn('  Exp_IsEncryptedFile:    ',Exp_IsEncryptedFile(PUTF8Char(StrToUTF8(FileName))));
    WriteLn('  Exp_IsEncodedMemory:    ',Exp_IsEncodedMemory(FileDataStream.Memory,FileDataStream.Size));
    WriteLn('  Exp_IsEncodedFile:      ',Exp_IsEncodedFile(PUTF8Char(StrToUTF8(FileName))));
    WriteLn('  Exp_Is3nKEncodedMemory: ',Exp_Is3nKEncodedMemory(FileDataStream.Memory,FileDataStream.Size));
    WriteLn('  Exp_Is3nKEncodedFile:   ',Exp_Is3nKEncodedFile(PUTF8Char(StrToUTF8(FileName))));
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    WriteLn;
    OpResult := Exp_DecryptMemory(FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize);
    WriteLn('  Exp_DecryptMemory #1: ',OpResult);
    If OpResult = SIIDEC_RESULT_SUCCESS then
      begin
        GetMem(Output,AllocSize);
        try
          OutSize := AllocSize;
          Write('  Exp_DecryptMemory #2: ',Exp_DecryptMemory(FileDataStream.Memory,FileDataStream.Size,Output,@OutSize));
          WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),BinCRC32));
        finally
          FreeMem(Output,AllocSize);
        end;
      end;
    Write('  Exp_DecryptFile:      ',Exp_DecryptFile(PUTF8Char(StrToUTF8(FileName)),PUTF8Char(StrToUTF8(FileName + '.out'))));
    If FileExists(StrToRTL(FileName + '.out')) then
      begin
        WriteLn('  ',SameCRC32(FileCRC32(FileName + '.out'),BinCRC32));
        DeleteFile(StrToRTL(FileName + '.out'));
      end
    else WriteLn;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    WriteLn;
    OpResult := Exp_DecodeMemory(FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize);
    WriteLn('  Exp_DecodeMemory #1:       ',OpResult);
    If OpResult = SIIDEC_RESULT_SUCCESS then
      begin
        GetMem(Output,AllocSize);
        try
          OutSize := AllocSize;
          Write('  Exp_DecodeMemory #2:       ',Exp_DecodeMemory(FileDataStream.Memory,FileDataStream.Size,Output,@OutSize));
          WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TextCRC32));
        finally
          FreeMem(Output,AllocSize);
        end;
      end;
    OpResult := Exp_DecodeMemoryHelper(FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize,@Helper);
    WriteLn('  Exp_DecodeMemoryHelper #1: ',OpResult);
    If OpResult = SIIDEC_RESULT_SUCCESS then
      begin
        GetMem(Output,AllocSize);
        try
          OutSize := AllocSize;
          Write('  Exp_DecodeMemoryHelper #2: ',Exp_DecodeMemoryHelper(FileDataStream.Memory,FileDataStream.Size,Output,@OutSize,@Helper));
          WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TextCRC32));
        finally
          FreeMem(Output,AllocSize);
        end;
      end
    else Exp_FreeHelper(@Helper);
    Write('  Exp_DecodeFile:            ',Exp_DecodeFile(PUTF8Char(StrToUTF8(FileName)),PUTF8Char(StrToUTF8(FileName + '.out'))));
    If FileExists(StrToRTL(FileName + '.out')) then
      begin
        WriteLn('  ',SameCRC32(FileCRC32(FileName + '.out'),BinCRC32));
        DeleteFile(StrToRTL(FileName + '.out'));
      end
    else WriteLn;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    WriteLn;
    OpResult := Exp_DecryptAndDecodeMemory(FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize);
    WriteLn('  Exp_DecryptAndDecodeMemory #1:       ',OpResult);
    If OpResult = SIIDEC_RESULT_SUCCESS then
      begin
        GetMem(Output,AllocSize);
        try
          OutSize := AllocSize;
          Write('  Exp_DecryptAndDecodeMemory #2:       ',Exp_DecryptAndDecodeMemory(FileDataStream.Memory,FileDataStream.Size,Output,@OutSize));
          WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TextCRC32));
        finally
          FreeMem(Output,AllocSize);
        end;
      end;
    OpResult := Exp_DecryptAndDecodeMemoryHelper(FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize,@Helper);
    WriteLn('  Exp_DecryptAndDecodeMemoryHelper #1: ',OpResult);
    If OpResult = SIIDEC_RESULT_SUCCESS then
      begin
        GetMem(Output,AllocSize);
        try
          OutSize := AllocSize;
          Write('  Exp_DecryptAndDecodeMemoryHelper #2: ',Exp_DecryptAndDecodeMemoryHelper(FileDataStream.Memory,FileDataStream.Size,Output,@OutSize,@Helper));
          WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TextCRC32));
        finally
          FreeMem(Output,AllocSize);
        end;
      end
    else Exp_FreeHelper(@Helper);
    Write('  Exp_DecryptAndDecodeFile:            ',Exp_DecryptAndDecodeFile(PUTF8Char(StrToUTF8(FileName)),PUTF8Char(StrToUTF8(FileName + '.out'))));
    If FileExists(StrToRTL(FileName + '.out')) then
      begin
        WriteLn('  ',SameCRC32(FileCRC32(FileName + '.out'),TextCRC32));
        DeleteFile(StrToRTL(FileName + '.out'));
      end
    else WriteLn;

  finally
    FileDataStream.Free;
  end;
except
  on E: Exception do
    begin
      WriteLn;
      WriteLn(StrToCsl(Format('  error: %s: %s',[E.ClassName,E.Message])));
    end;
end;
end;


end.

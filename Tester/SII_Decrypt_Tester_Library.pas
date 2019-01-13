{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decrypt_Tester_Library;

interface

uses
  SII_Decrypt_Tester_Main;

procedure TestOnFile(TestFileEntry: TTestFileEntry);

implementation

uses
  SysUtils, Classes,
  AuxTypes, StrRect, CRC32, 
  SII_Decrypt_Library_Header;

procedure ProgressCallback(Context: Pointer; Progress: Double); stdcall;
begin
WriteLn(Format(' Progress(%p): %.3f',[Context,Progress]));
end;

//------------------------------------------------------------------------------

procedure TestOnFile(TestFileEntry: TTestFileEntry);
var
  FileDataStream: TMemoryStream;
  Result:         Integer;
  Output:         Pointer;
  OutSize:        TMemSize;
  AllocSize:      TMemSize;
  Helper:         Pointer;
  Context:        TSIIDecContext;
begin
WriteLn(StringOfChar('-',75));
WriteLn('  SII Decrypt Tester - Library');
WriteLn(StringOfChar('-',75));
WriteLn;
WriteLn('FileName:  ',TestFileEntry.FileName);
WriteLn('Format:    ',TestFileEntry.FileFormat);
WriteLn('BinCRC32:  ',CRC32ToStr(TestFileEntry.BinCRC32));
WriteLn('TextCRC32: ',CRC32ToStr(TestFileEntry.TextCRC32));
try
  WriteLn;
  WriteLn('  APIVersion: 0x',Format('%.8x',[APIVersion]));
  FileDataStream := TMemoryStream.Create;
  try
    FileDataStream.LoadFromFile(TestFileEntry.FileName);
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    WriteLn;
    WriteLn('  GetMemoryFormat:    ',GetMemoryFormat(FileDataStream.Memory,FileDataStream.Size));
    WriteLn('  GetFileFormat:      ',GetFileFormat(PUTF8Char(StrToUTF8(TestFileEntry.FileName))));
    WriteLn('  IsEncryptedMemory:  ',IsEncryptedMemory(FileDataStream.Memory,FileDataStream.Size));
    WriteLn('  IsEncryptedFile:    ',IsEncryptedFile(PUTF8Char(StrToUTF8(TestFileEntry.FileName))));
    WriteLn('  IsEncodedMemory:    ',IsEncodedMemory(FileDataStream.Memory,FileDataStream.Size));
    WriteLn('  IsEncodedFile:      ',IsEncodedFile(PUTF8Char(StrToUTF8(TestFileEntry.FileName))));
    WriteLn('  Is3nKEncodedMemory: ',Is3nKEncodedMemory(FileDataStream.Memory,FileDataStream.Size));
    WriteLn('  Is3nKEncodedFile:   ',Is3nKEncodedFile(PUTF8Char(StrToUTF8(TestFileEntry.FileName))));
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    WriteLn;
    Result := DecryptMemory(FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize);
    WriteLn('  DecryptMemory #1:    ',Result);
    If Result = SIIDEC_RESULT_SUCCESS then
      begin
        GetMem(Output,AllocSize);
        try
          OutSize := AllocSize;
          Write('  DecryptMemory #2:    ',
            DecryptMemory(FileDataStream.Memory,FileDataStream.Size,Output,@OutSize));
          WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TestFileEntry.BinCRC32));
        finally
          FreeMem(Output,AllocSize);
        end;
      end;
    Write('  DecryptFile:         ',
      DecryptFile(PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
    If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
      begin
        WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.BinCRC32));
        DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
      end
    else WriteLn;
    Write('  DecryptFileInMemory: ',
      DecryptFileInMemory(PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
    If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
      begin
        WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.BinCRC32));
        DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
      end
    else WriteLn;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    WriteLn;
    Result := DecodeMemory(FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize);
    WriteLn('  DecodeMemory #1:       ',Result);
    If Result = SIIDEC_RESULT_SUCCESS then
      begin
        GetMem(Output,AllocSize);
        try
          OutSize := AllocSize;
          Write('  DecodeMemory #2:       ',
            DecodeMemory(FileDataStream.Memory,FileDataStream.Size,Output,@OutSize));
          WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TestFileEntry.TextCRC32));
        finally
          FreeMem(Output,AllocSize);
        end;
      end;
    Result := DecodeMemoryHelper(FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize,@Helper);
    WriteLn('  DecodeMemoryHelper #1: ',Result);
    If Result = SIIDEC_RESULT_SUCCESS then
      begin
        GetMem(Output,AllocSize);
        try
          OutSize := AllocSize;
          Write('  DecodeMemoryHelper #2: ',
            DecodeMemoryHelper(FileDataStream.Memory,FileDataStream.Size,Output,@OutSize,@Helper));
          WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TestFileEntry.TextCRC32));
        finally
          FreeMem(Output,AllocSize);
        end;
      end
    else FreeHelper(@Helper);
    Write('  DecodeFile:            ',
      DecodeFile(PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
    If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
      begin
        WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.TextCRC32));
        DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
      end
    else WriteLn;
    Write('  DecodeFileInMemory:    ',
      DecodeFileInMemory(PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
    If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
      begin
        WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.TextCRC32));
        DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
      end
    else WriteLn;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    WriteLn;
    Result := DecryptAndDecodeMemory(FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize);
    WriteLn('  DecryptAndDecodeMemory #1:       ',Result);
    If Result = SIIDEC_RESULT_SUCCESS then
      begin
        GetMem(Output,AllocSize);
        try
          OutSize := AllocSize;
          Write('  DecryptAndDecodeMemory #2:       ',
            DecryptAndDecodeMemory(FileDataStream.Memory,FileDataStream.Size,Output,@OutSize));
          WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TestFileEntry.TextCRC32));
        finally
          FreeMem(Output,AllocSize);
        end;
      end;
    Result := DecryptAndDecodeMemoryHelper(FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize,@Helper);
    WriteLn('  DecryptAndDecodeMemoryHelper #1: ',Result);
    If Result = SIIDEC_RESULT_SUCCESS then
      begin
        GetMem(Output,AllocSize);
        try
          OutSize := AllocSize;
          Write('  DecryptAndDecodeMemoryHelper #2: ',
            DecryptAndDecodeMemoryHelper(FileDataStream.Memory,FileDataStream.Size,Output,@OutSize,@Helper));
          WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TestFileEntry.TextCRC32));
        finally
          FreeMem(Output,AllocSize);
        end;
      end
    else FreeHelper(@Helper);
    Write('  DecryptAndDecodeFile:            ',
      DecryptAndDecodeFile(PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
    If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
      begin
        WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.TextCRC32));
        DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
      end
    else WriteLn;
    Write('  DecryptAndDecodeFileInMemory:    ',
      DecryptAndDecodeFileInMemory(PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
    If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
      begin
        WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.TextCRC32));
        DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
      end
    else WriteLn;
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    WriteLn;
    WriteLn('Creating context...');
    Context := Decryptor_Create;
    try
      WriteLn;
      WriteLn('  Opt(SIIDEC_OPTIONID_ACCEL_AES):  ',Decryptor_GetOptionBool(Context,SIIDEC_OPTIONID_ACCEL_AES));
      WriteLn('  Opt(SIIDEC_OPTIONID_DEC_UNSUPP): ',Decryptor_GetOptionBool(Context,SIIDEC_OPTIONID_DEC_UNSUPP));
      //Decryptor_SetProgressCallback(Context,@ProgressCallback);
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      WriteLn;
      WriteLn('  Decryptor_GetMemoryFormat:    ',Decryptor_GetMemoryFormat(Context,FileDataStream.Memory,FileDataStream.Size));
      WriteLn('  Decryptor_GetFileFormat:      ',Decryptor_GetFileFormat(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName))));
      WriteLn('  Decryptor_IsEncryptedMemory:  ',Decryptor_IsEncryptedMemory(Context,FileDataStream.Memory,FileDataStream.Size));
      WriteLn('  Decryptor_IsEncryptedFile:    ',Decryptor_IsEncryptedFile(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName))));
      WriteLn('  Decryptor_IsEncodedMemory:    ',Decryptor_IsEncodedMemory(Context,FileDataStream.Memory,FileDataStream.Size));
      WriteLn('  Decryptor_IsEncodedFile:      ',Decryptor_IsEncodedFile(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName))));
      WriteLn('  Decryptor_Is3nKEncodedMemory: ',Decryptor_Is3nKEncodedMemory(Context,FileDataStream.Memory,FileDataStream.Size));
      WriteLn('  Decryptor_Is3nKEncodedFile:   ',Decryptor_Is3nKEncodedFile(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName))));
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      WriteLn;
      Result := Decryptor_DecryptMemory(Context,FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize);
      WriteLn('  Decryptor_DecryptMemory #1:    ',Result);
      If Result = SIIDEC_RESULT_SUCCESS then
        begin
          GetMem(Output,AllocSize);
          try
            OutSize := AllocSize;
            Write('  Decryptor_DecryptMemory #2:    ',
              Decryptor_DecryptMemory(Context,FileDataStream.Memory,FileDataStream.Size,Output,@OutSize));
            WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TestFileEntry.BinCRC32));
          finally
            FreeMem(Output,AllocSize);
          end;
        end;
      Write('  Decryptor_DecryptFile:         ',
        Decryptor_DecryptFile(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
      If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
        begin
          WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.BinCRC32));
          DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
        end
      else WriteLn;
      Write('  Decryptor_DecryptFileInMemory: ',
        Decryptor_DecryptFileInMemory(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
      If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
        begin
          WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.BinCRC32));
          DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
        end
      else WriteLn;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      WriteLn;
      Result := Decryptor_DecodeMemory(Context,FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize);
      WriteLn('  Decryptor_DecodeMemory #1:    ',Result);
      If Result = SIIDEC_RESULT_SUCCESS then
        begin
          GetMem(Output,AllocSize);
          try
            OutSize := AllocSize;
            Write('  Decryptor_DecodeMemory #2:    ',
              Decryptor_DecodeMemory(Context,FileDataStream.Memory,FileDataStream.Size,Output,@OutSize));
            WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TestFileEntry.TextCRC32));
          finally
            FreeMem(Output,AllocSize);
          end;
        end;
      Write('  Decryptor_DecodeFile:         ',
        Decryptor_DecodeFile(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
      If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
        begin
          WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.TextCRC32));
          DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
        end
      else WriteLn;
      Write('  Decryptor_DecodeFileInMemory: ',
        Decryptor_DecodeFileInMemory(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
      If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
        begin
          WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.TextCRC32));
          DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
        end
      else WriteLn;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      WriteLn;
      Result := Decryptor_DecryptAndDecodeMemory(Context,FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize);
      WriteLn('  Decryptor_DecryptAndDecodeMemory #1:    ',Result);
      If Result = SIIDEC_RESULT_SUCCESS then
        begin
          GetMem(Output,AllocSize);
          try
            OutSize := AllocSize;
            Write('  Decryptor_DecryptAndDecodeMemory #2:    ',
              Decryptor_DecryptAndDecodeMemory(Context,FileDataStream.Memory,FileDataStream.Size,Output,@OutSize));
            WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TestFileEntry.TextCRC32));
          finally
            FreeMem(Output,AllocSize);
          end;
        end;
      Write('  Decryptor_DecryptAndDecodeFile:         ',
        Decryptor_DecryptAndDecodeFile(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
      If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
        begin
          WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.TextCRC32));
          DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
        end
      else WriteLn;
      Write('  Decryptor_DecryptAndDecodeFileInMemory: ',
        Decryptor_DecryptAndDecodeFile(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
      If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
        begin
          WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.TextCRC32));
          DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
        end
      else WriteLn;
    finally
      Decryptor_Free(@Context);
    end;
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

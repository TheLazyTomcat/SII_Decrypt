{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decrypt_Tester_LibraryDirect;

interface

uses
  SII_Decrypt_Tester_Main;

procedure TestOnFile(TestFileEntry: TTestFileEntry);

implementation

uses
  SysUtils, Classes,
  AuxTypes, StrRect, CRC32,
  SII_Decrypt_Library_Header, SII_Decrypt_Library_Decryptor,
  SII_Decrypt_Library_Standalone;

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
WriteLn;
WriteLn(StringOfChar('-',75));
WriteLn('  SII Decrypt Tester - Library direct');
WriteLn(StringOfChar('-',75));
WriteLn;
WriteLn('FileName:  ',TestFileEntry.FileName);
WriteLn('Format:    ',TestFileEntry.FileFormat);
WriteLn('BinCRC32:  ',CRC32ToStr(TestFileEntry.BinCRC32));
WriteLn('TextCRC32: ',CRC32ToStr(TestFileEntry.TextCRC32));
try
  WriteLn;
  WriteLn('  Exp_APIVersion: 0x',Format('%.8x',[Exp_APIVersion()]));
  FileDataStream := TMemoryStream.Create;
  try
    FileDataStream.LoadFromFile(TestFileEntry.FileName);
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    WriteLn;
    WriteLn('  Exp_GetMemoryFormat:    ',Exp_GetMemoryFormat(FileDataStream.Memory,FileDataStream.Size));
    WriteLn('  Exp_GetFileFormat:      ',Exp_GetFileFormat(PUTF8Char(StrToUTF8(TestFileEntry.FileName))));
    WriteLn('  Exp_IsEncryptedMemory:  ',Exp_IsEncryptedMemory(FileDataStream.Memory,FileDataStream.Size));
    WriteLn('  Exp_IsEncryptedFile:    ',Exp_IsEncryptedFile(PUTF8Char(StrToUTF8(TestFileEntry.FileName))));
    WriteLn('  Exp_IsEncodedMemory:    ',Exp_IsEncodedMemory(FileDataStream.Memory,FileDataStream.Size));
    WriteLn('  Exp_IsEncodedFile:      ',Exp_IsEncodedFile(PUTF8Char(StrToUTF8(TestFileEntry.FileName))));
    WriteLn('  Exp_Is3nKEncodedMemory: ',Exp_Is3nKEncodedMemory(FileDataStream.Memory,FileDataStream.Size));
    WriteLn('  Exp_Is3nKEncodedFile:   ',Exp_Is3nKEncodedFile(PUTF8Char(StrToUTF8(TestFileEntry.FileName))));
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    WriteLn;
    Result := Exp_DecryptMemory(FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize);
    WriteLn('  Exp_DecryptMemory #1:    ',Result);
    If Result = SIIDEC_RESULT_SUCCESS then
      begin
        GetMem(Output,AllocSize);
        try
          OutSize := AllocSize;
          Write('  Exp_DecryptMemory #2:    ',
            Exp_DecryptMemory(FileDataStream.Memory,FileDataStream.Size,Output,@OutSize));
          WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TestFileEntry.BinCRC32));
        finally
          FreeMem(Output,AllocSize);
        end;
      end;
    Write('  Exp_DecryptFile:         ',
      Exp_DecryptFile(PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
    If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
      begin
        WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.BinCRC32));
        DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
      end
    else WriteLn;
    Write('  Exp_DecryptFileInMemory: ',
      Exp_DecryptFileInMemory(PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
    If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
      begin
        WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.BinCRC32));
        DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
      end
    else WriteLn;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    WriteLn;
    Result := Exp_DecodeMemory(FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize);
    WriteLn('  Exp_DecodeMemory #1:       ',Result);
    If Result = SIIDEC_RESULT_SUCCESS then
      begin
        GetMem(Output,AllocSize);
        try
          OutSize := AllocSize;
          Write('  Exp_DecodeMemory #2:       ',
            Exp_DecodeMemory(FileDataStream.Memory,FileDataStream.Size,Output,@OutSize));
          WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TestFileEntry.TextCRC32));
        finally
          FreeMem(Output,AllocSize);
        end;
      end;
    Result := Exp_DecodeMemoryHelper(FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize,@Helper);
    WriteLn('  Exp_DecodeMemoryHelper #1: ',Result);
    If Result = SIIDEC_RESULT_SUCCESS then
      begin
        GetMem(Output,AllocSize);
        try
          OutSize := AllocSize;
          Write('  Exp_DecodeMemoryHelper #2: ',
            Exp_DecodeMemoryHelper(FileDataStream.Memory,FileDataStream.Size,Output,@OutSize,@Helper));
          WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TestFileEntry.TextCRC32));
        finally
          FreeMem(Output,AllocSize);
        end;
      end
    else Exp_FreeHelper(@Helper);
    Write('  Exp_DecodeFile:            ',
      Exp_DecodeFile(PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
    If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
      begin
        WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.TextCRC32));
        DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
      end
    else WriteLn;
    Write('  Exp_DecodeFileInMemory:    ',
      Exp_DecodeFileInMemory(PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
    If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
      begin
        WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.TextCRC32));
        DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
      end
    else WriteLn;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    WriteLn;
    Result := Exp_DecryptAndDecodeMemory(FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize);
    WriteLn('  Exp_DecryptAndDecodeMemory #1:       ',Result);
    If Result = SIIDEC_RESULT_SUCCESS then
      begin
        GetMem(Output,AllocSize);
        try
          OutSize := AllocSize;
          Write('  Exp_DecryptAndDecodeMemory #2:       ',
            Exp_DecryptAndDecodeMemory(FileDataStream.Memory,FileDataStream.Size,Output,@OutSize));
          WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TestFileEntry.TextCRC32));
        finally
          FreeMem(Output,AllocSize);
        end;
      end;
    Result := Exp_DecryptAndDecodeMemoryHelper(FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize,@Helper);
    WriteLn('  Exp_DecryptAndDecodeMemoryHelper #1: ',Result);
    If Result = SIIDEC_RESULT_SUCCESS then
      begin
        GetMem(Output,AllocSize);
        try
          OutSize := AllocSize;
          Write('  Exp_DecryptAndDecodeMemoryHelper #2: ',
            Exp_DecryptAndDecodeMemoryHelper(FileDataStream.Memory,FileDataStream.Size,Output,@OutSize,@Helper));
          WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TestFileEntry.TextCRC32));
        finally
          FreeMem(Output,AllocSize);
        end;
      end
    else Exp_FreeHelper(@Helper);
    Write('  Exp_DecryptAndDecodeFile:            ',
      Exp_DecryptAndDecodeFile(PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
    If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
      begin
        WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.TextCRC32));
        DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
      end
    else WriteLn;
    Write('  Exp_DecryptAndDecodeFileInMemory:    ',
      Exp_DecryptAndDecodeFileInMemory(PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
    If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
      begin
        WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.TextCRC32));
        DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
      end
    else WriteLn;
// = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
    WriteLn;
    WriteLn('Creating context...');
    Context := Exp_Decryptor_Create();
    try
      WriteLn;
      WriteLn('  Opt(SIIDEC_OPTIONID_ACCEL_AES):  ',Exp_Decryptor_GetOptionBool(Context,SIIDEC_OPTIONID_ACCEL_AES));
      WriteLn('  Opt(SIIDEC_OPTIONID_DEC_UNSUPP): ',Exp_Decryptor_GetOptionBool(Context,SIIDEC_OPTIONID_DEC_UNSUPP));
      //Exp_Decryptor_SetProgressCallback(Context,@ProgressCallback);
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      WriteLn;
      WriteLn('  Exp_Decryptor_GetMemoryFormat:    ',Exp_Decryptor_GetMemoryFormat(Context,FileDataStream.Memory,FileDataStream.Size));
      WriteLn('  Exp_Decryptor_GetFileFormat:      ',Exp_Decryptor_GetFileFormat(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName))));
      WriteLn('  Exp_Decryptor_IsEncryptedMemory:  ',Exp_Decryptor_IsEncryptedMemory(Context,FileDataStream.Memory,FileDataStream.Size));
      WriteLn('  Exp_Decryptor_IsEncryptedFile:    ',Exp_Decryptor_IsEncryptedFile(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName))));
      WriteLn('  Exp_Decryptor_IsEncodedMemory:    ',Exp_Decryptor_IsEncodedMemory(Context,FileDataStream.Memory,FileDataStream.Size));
      WriteLn('  Exp_Decryptor_IsEncodedFile:      ',Exp_Decryptor_IsEncodedFile(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName))));
      WriteLn('  Exp_Decryptor_Is3nKEncodedMemory: ',Exp_Decryptor_Is3nKEncodedMemory(Context,FileDataStream.Memory,FileDataStream.Size));
      WriteLn('  Exp_Decryptor_Is3nKEncodedFile:   ',Exp_Decryptor_Is3nKEncodedFile(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName))));
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      WriteLn;
      Result := Exp_Decryptor_DecryptMemory(Context,FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize);
      WriteLn('  Exp_Decryptor_DecryptMemory #1:    ',Result);
      If Result = SIIDEC_RESULT_SUCCESS then
        begin
          GetMem(Output,AllocSize);
          try
            OutSize := AllocSize;
            Write('  Exp_Decryptor_DecryptMemory #2:    ',
              Exp_Decryptor_DecryptMemory(Context,FileDataStream.Memory,FileDataStream.Size,Output,@OutSize));
            WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TestFileEntry.BinCRC32));
          finally
            FreeMem(Output,AllocSize);
          end;
        end;
      Write('  Exp_Decryptor_DecryptFile:         ',
        Exp_Decryptor_DecryptFile(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
      If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
        begin
          WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.BinCRC32));
          DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
        end
      else WriteLn;
      Write('  Exp_Decryptor_DecryptFileInMemory: ',
        Exp_Decryptor_DecryptFileInMemory(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
      If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
        begin
          WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.BinCRC32));
          DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
        end
      else WriteLn;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      WriteLn;
      Result := Exp_Decryptor_DecodeMemory(Context,FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize);
      WriteLn('  Exp_Decryptor_DecodeMemory #1:    ',Result);
      If Result = SIIDEC_RESULT_SUCCESS then
        begin
          GetMem(Output,AllocSize);
          try
            OutSize := AllocSize;
            Write('  Exp_Decryptor_DecodeMemory #2:    ',
              Exp_Decryptor_DecodeMemory(Context,FileDataStream.Memory,FileDataStream.Size,Output,@OutSize));
            WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TestFileEntry.TextCRC32));
          finally
            FreeMem(Output,AllocSize);
          end;
        end;
      Write('  Exp_Decryptor_DecodeFile:         ',
        Exp_Decryptor_DecodeFile(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
      If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
        begin
          WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.TextCRC32));
          DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
        end
      else WriteLn;
      Write('  Exp_Decryptor_DecodeFileInMemory: ',
        Exp_Decryptor_DecodeFileInMemory(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
      If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
        begin
          WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.TextCRC32));
          DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
        end
      else WriteLn;
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      WriteLn;
      Result := Exp_Decryptor_DecryptAndDecodeMemory(Context,FileDataStream.Memory,FileDataStream.Size,nil,@AllocSize);
      WriteLn('  Exp_Decryptor_DecryptAndDecodeMemory #1:    ',Result);
      If Result = SIIDEC_RESULT_SUCCESS then
        begin
          GetMem(Output,AllocSize);
          try
            OutSize := AllocSize;
            Write('  Exp_Decryptor_DecryptAndDecodeMemory #2:    ',
              Exp_Decryptor_DecryptAndDecodeMemory(Context,FileDataStream.Memory,FileDataStream.Size,Output,@OutSize));
            WriteLn('  ',SameCRC32(BufferCRC32(Output^,OutSize),TestFileEntry.TextCRC32));
          finally
            FreeMem(Output,AllocSize);
          end;
        end;
      Write('  Exp_Decryptor_DecryptAndDecodeFile:         ',
        Exp_Decryptor_DecryptAndDecodeFile(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
      If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
        begin
          WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.TextCRC32));
          DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
        end
      else WriteLn;
      Write('  Exp_Decryptor_DecryptAndDecodeFileInMemory: ',
        Exp_Decryptor_DecryptAndDecodeFile(Context,PUTF8Char(StrToUTF8(TestFileEntry.FileName)),PUTF8Char(StrToUTF8(TestFileEntry.FileName + '.out'))));
      If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
        begin
          WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.TextCRC32));
          DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
        end
      else WriteLn;
    finally
      Exp_Decryptor_Free(@Context);
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

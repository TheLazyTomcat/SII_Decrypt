{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decrypt_Library_Standalone;

{$INCLUDE '..\Source\SII_Decrypt_defs.inc'}

interface

uses
  AuxTypes;

Function Exp_APIVersion: UInt32; stdcall;

Function Exp_GetMemoryFormat(Mem: Pointer; Size: TMemSize): Int32; stdcall;
Function Exp_GetFileFormat(FileName: PUTF8Char): Int32; stdcall;
Function Exp_IsEncryptedMemory(Mem: Pointer; Size: TMemSize): LongBool; stdcall;
Function Exp_IsEncryptedFile(FileName: PUTF8Char): LongBool; stdcall;
Function Exp_IsEncodedMemory(Mem: Pointer; Size: TMemSize): LongBool; stdcall;
Function Exp_IsEncodedFile(FileName: PUTF8Char): LongBool; stdcall;
Function Exp_Is3nKEncodedMemory(Mem: Pointer; Size: TMemSize): LongBool; stdcall;
Function Exp_Is3nKEncodedFile(FileName: PUTF8Char): LongBool; stdcall;

Function Exp_DecryptMemory(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;
Function Exp_DecryptFile(InputFile,OutputFile: PUTF8Char): Int32; stdcall;
Function Exp_DecryptFileInMemory(InputFile,OutputFile: PUTF8Char): Int32; stdcall;

Function Exp_DecodeMemoryHelper(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize; Helper: PPointer): Int32; stdcall;
Function Exp_DecodeMemory(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;
Function Exp_DecodeFile(InputFile,OutputFile: PUTF8Char): Int32; stdcall;
Function Exp_DecodeFileInMemory(InputFile,OutputFile: PUTF8Char): Int32; stdcall;

Function Exp_DecryptAndDecodeMemoryHelper(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize; Helper: PPointer): Int32; stdcall;
Function Exp_DecryptAndDecodeMemory(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;
Function Exp_DecryptAndDecodeFile(InputFile,OutputFile: PUTF8Char): Int32; stdcall;
Function Exp_DecryptAndDecodeFileInMemory(InputFile,OutputFile: PUTF8Char): Int32; stdcall;

procedure Exp_FreeHelper(Helper: PPointer); stdcall;

implementation

uses
  SysUtils, Classes,
  StaticMemoryStream,
  SII_Decrypt_Decryptor, SII_Decrypt_Header, SII_Decrypt_Library_Common;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W5057:={$WARN 5057 OFF}} // Local variable "$1" does not seem to be initialized
{$ENDIF}

Function Exp_APIVersion: UInt32; stdcall;
begin
Result := BuildAPIVersion(1,0);
end;

//==============================================================================

Function Exp_GetMemoryFormat(Mem: Pointer; Size: TMemSize): Int32; stdcall;
var
  MemStream:  TStaticMemoryStream;
begin
try
  with TSII_Decryptor.Create do
  try
    ReraiseExceptions := False;
    MemStream := TStaticMemoryStream.Create(Mem,Size);
    try
      Result := GetResultAsInt(GetStreamFormat(MemStream));
    finally
      MemStream.Free;
    end;
  finally
    Free;
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_GetFileFormat(FileName: PUTF8Char): Int32; stdcall;
begin
try
  with TSII_Decryptor.Create do
  try
    ReraiseExceptions := False;
    Result := GetResultAsInt(GetFileFormat(StrConv(FileName)));
  finally
    Free;
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_IsEncryptedMemory(Mem: Pointer; Size: TMemSize): LongBool; stdcall;
begin
try
  Result := Exp_GetMemoryFormat(Mem,Size) = SIIDEC_RESULT_FORMAT_ENCRYPTED;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function Exp_IsEncryptedFile(FileName: PUTF8Char): LongBool; stdcall;
begin
try
  Result := Exp_GetFileFormat(FileName) = SIIDEC_RESULT_FORMAT_ENCRYPTED;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function Exp_IsEncodedMemory(Mem: Pointer; Size: TMemSize): LongBool; stdcall;
begin
try
  Result := Exp_GetMemoryFormat(Mem,Size) = SIIDEC_RESULT_FORMAT_BINARY;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function Exp_IsEncodedFile(FileName: PUTF8Char): LongBool; stdcall;
begin
try
  Result := Exp_GetFileFormat(FileName) = SIIDEC_RESULT_FORMAT_BINARY;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function Exp_Is3nKEncodedMemory(Mem: Pointer; Size: TMemSize): LongBool;
begin
try
  Result := Exp_GetMemoryFormat(Mem,Size) = SIIDEC_RESULT_FORMAT_3NK;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function Exp_Is3nKEncodedFile(FileName: PUTF8Char): LongBool;
begin
try
  Result := Exp_GetFileFormat(FileName) = SIIDEC_RESULT_FORMAT_3NK;
except
  Result := False;
end;
end;
//==============================================================================

{$IFDEF FPCDWM}{$PUSH}W5057{$ENDIF}
Function Exp_DecryptMemory(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;
var
  InMemStream:  TStaticMemoryStream;
  Header:       TSIIHeader;
  OutMemStream: TWritableStaticMemoryStream;
begin
try
  If InSize >= SizeOf(TSIIHeader) then
    begin
      with TSII_Decryptor.Create do
      try
        ReraiseExceptions := False;
        InMemStream := TStaticMemoryStream.Create(Input,InSize);
        try
          Result := GetResultAsInt(GetStreamFormat(InMemStream));
          If Result = SIIDEC_RESULT_FORMAT_ENCRYPTED then
            begin
              InMemStream.ReadBuffer(Header,SizeOf(TSIIHeader));
              InMemStream.Seek(0,soBeginning);
              If Assigned(Output) then
                begin
                  If OutSize^ >= TMemSize(Header.DataSize) then
                    begin
                      OutMemStream := TWritableStaticMemoryStream.Create(Output,OutSize^);
                      try
                        Result := GetResultAsInt(DecryptStream(InMemStream,OutMemStream,True));
                        If Result = SIIDEC_RESULT_SUCCESS then
                          OutSize^ := TMemSize(OutMemStream.Position);
                      finally
                        OutMemStream.Free;
                      end;
                    end
                  else Result := SIIDEC_RESULT_BUFFER_TOO_SMALL;
                end
              else
                begin
                  OutSize^ := TMemSize(Header.DataSize);
                  Result := SIIDEC_RESULT_SUCCESS;
                end;
            end;
        finally
          InMemStream.Free;
        end;
      finally
        Free;
      end;
    end
  else Result := SIIDEC_RESULT_TOO_FEW_DATA;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

Function Exp_DecryptFile(InputFile,OutputFile: PUTF8Char): Int32; stdcall;
begin
try
  with TSII_Decryptor.Create do
  try
    ReraiseExceptions := False;
    Result := GetResultAsInt(GetFileFormat(StrConv(InputFile)));
    If Result = SIIDEC_RESULT_FORMAT_ENCRYPTED then
      Result := GetResultAsInt(DecryptFile(StrConv(InputFile),StrConv(OutputFile)));
  finally
    Free;
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_DecryptFileInMemory(InputFile,OutputFile: PUTF8Char): Int32; stdcall;
begin
try
  with TSII_Decryptor.Create do
  try
    ReraiseExceptions := False;
    Result := GetResultAsInt(GetFileFormat(StrConv(InputFile)));
    If Result = SIIDEC_RESULT_FORMAT_ENCRYPTED then
      Result := GetResultAsInt(DecryptFileInMemory(StrConv(InputFile),StrConv(OutputFile)));
  finally
    Free;
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//==============================================================================

Function Exp_DecodeMemoryHelper(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize; Helper: PPointer): Int32; stdcall;
var
  InMemStream:  TStaticMemoryStream;
  OutMemStream: TWritableStaticMemoryStream;
  HelperStream: TMemoryStream;
begin
try
  with TSII_Decryptor.Create do
  try
    ReraiseExceptions := False;
    InMemStream := TStaticMemoryStream.Create(Input,InSize);
    try
      Result := GetResultAsInt(GetStreamFormat(InMemStream));
      If Result in [SIIDEC_RESULT_FORMAT_BINARY,SIIDEC_RESULT_FORMAT_3NK] then
        begin
          If Assigned(Output) then
            begin
              If Assigned(Helper) then
                begin
                  HelperStream := TMemoryStream(Helper^);
                  try
                    If OutSize^ >= HelperStream.Size then
                      begin
                        Move(HelperStream.Memory^,Output^,HelperStream.Size);
                        OutSize^ := TMemSize(HelperStream.Size);
                        Result := SIIDEC_RESULT_SUCCESS;
                      end
                    else Result := SIIDEC_RESULT_BUFFER_TOO_SMALL;
                  finally
                    HelperStream.Free;
                    Helper^ := nil;
                  end;
                end
              else
                begin
                  OutMemStream := TWritableStaticMemoryStream.Create(Output,OutSize^);
                  try
                    Result := GetResultAsInt(DecodeStream(InMemStream,OutMemStream,True));
                    If Result = SIIDEC_RESULT_SUCCESS then
                      OutSize^ := TMemSize(OutMemStream.Position);
                  finally
                    OutMemStream.Free;
                  end;
                end;
            end
          else
            begin
              HelperStream := TMemoryStream.Create;
              try
                Result := GetResultAsInt(DecodeStream(InMemStream,HelperStream,False));
                If Result = SIIDEC_RESULT_SUCCESS then
                  OutSize^ := TMemSize(HelperStream.Size);
              finally
                If Assigned(Helper) then
                  Helper^ := Pointer(HelperStream)
                else
                  HelperStream.Free;
              end;
            end;
        end
    finally
      InMemStream.Free;
    end;
  finally
    Free;
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_DecodeMemory(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;
begin
try
  Result := Exp_DecodeMemoryHelper(Input,InSize,Output,OutSize,nil);
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_DecodeFile(InputFile,OutputFile: PUTF8Char): Int32; stdcall;
begin
try
  with TSII_Decryptor.Create do
  try
    ReraiseExceptions := False;
    Result := GetResultAsInt(GetFileFormat(StrConv(InputFile)));
    If Result in [SIIDEC_RESULT_FORMAT_BINARY,SIIDEC_RESULT_FORMAT_3NK] then
      Result := GetResultAsInt(DecodeFile(StrConv(InputFile),StrConv(OutputFile)));
  finally
    Free;
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_DecodeFileInMemory(InputFile,OutputFile: PUTF8Char): Int32; stdcall;
begin
try
  with TSII_Decryptor.Create do
  try
    ReraiseExceptions := False;
    Result := GetResultAsInt(GetFileFormat(StrConv(InputFile)));
    If Result in [SIIDEC_RESULT_FORMAT_BINARY,SIIDEC_RESULT_FORMAT_3NK] then
      Result := GetResultAsInt(DecodeFileInMemory(StrConv(InputFile),StrConv(OutputFile)));
  finally
    Free;
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//==============================================================================

Function Exp_DecryptAndDecodeMemoryHelper(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize; Helper: PPointer): Int32; stdcall;
var
  InMemStream:  TStaticMemoryStream;
  OutMemStream: TWritableStaticMemoryStream;
  HelperStream: TMemoryStream;
begin
try
  with TSII_Decryptor.Create do
  try
    ReraiseExceptions := False;
    InMemStream := TStaticMemoryStream.Create(Input,InSize);
    try
      Result := GetResultAsInt(GetStreamFormat(InMemStream));
      If Result in [SIIDEC_RESULT_FORMAT_ENCRYPTED,SIIDEC_RESULT_FORMAT_BINARY,SIIDEC_RESULT_FORMAT_3NK] then
        begin
          If Assigned(Output) then
            begin
              If Assigned(Helper) then
                begin
                  HelperStream := TMemoryStream(Helper^);
                  try
                    If OutSize^ >= HelperStream.Size then
                      begin
                        Move(HelperStream.Memory^,Output^,HelperStream.Size);
                        OutSize^ := TMemSize(HelperStream.Size);
                        Result := SIIDEC_RESULT_SUCCESS;
                      end
                    else Result := SIIDEC_RESULT_BUFFER_TOO_SMALL;
                  finally
                    HelperStream.Free;
                    Helper^ := nil;
                  end;
                end
              else
                begin
                  OutMemStream := TWritableStaticMemoryStream.Create(Output,OutSize^);
                  try
                    Result := GetResultAsInt(DecryptAndDecodeStream(InMemStream,OutMemStream,True));
                    If Result = SIIDEC_RESULT_SUCCESS then
                      OutSize^ := TMemSize(OutMemStream.Position);
                  finally
                    OutMemStream.Free;
                  end;
                end;
            end
          else
            begin
              HelperStream := TMemoryStream.Create;
              try
                Result := GetResultAsInt(DecryptAndDecodeStream(InMemStream,HelperStream,False));
                If Result = SIIDEC_RESULT_SUCCESS then
                  OutSize^ := TMemSize(HelperStream.Size);
              finally
                If Assigned(Helper) then
                  Helper^ := Pointer(HelperStream)
                else
                  HelperStream.Free;
              end;
            end;
        end;
    finally
      InMemStream.Free;
    end;
  finally
    Free;
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_DecryptAndDecodeMemory(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;
begin
try
  Result := Exp_DecryptAndDecodeMemoryHelper(Input,InSize,Output,OutSize,nil);
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_DecryptAndDecodeFile(InputFile,OutputFile: PUTF8Char): Int32; stdcall;
begin
try
  with TSII_Decryptor.Create do
  try
    ReraiseExceptions := False;
    Result := GetResultAsInt(GetFileFormat(StrConv(InputFile)));
    If Result in [SIIDEC_RESULT_FORMAT_ENCRYPTED,SIIDEC_RESULT_FORMAT_BINARY,SIIDEC_RESULT_FORMAT_3NK] then
      Result := GetResultAsInt(DecryptAndDecodeFile(StrConv(InputFile),StrConv(OutputFile)))
  finally
    Free;
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_DecryptAndDecodeFileInMemory(InputFile,OutputFile: PUTF8Char): Int32; stdcall;
begin
try
  with TSII_Decryptor.Create do
  try
    ReraiseExceptions := False;
    Result := GetResultAsInt(GetFileFormat(StrConv(InputFile)));
    If Result in [SIIDEC_RESULT_FORMAT_ENCRYPTED,SIIDEC_RESULT_FORMAT_BINARY,SIIDEC_RESULT_FORMAT_3NK] then
      Result := GetResultAsInt(DecryptAndDecodeFileInMemory(StrConv(InputFile),StrConv(OutputFile)))
  finally
    Free;
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//==============================================================================

procedure Exp_FreeHelper(Helper: PPointer); stdcall;
begin
try
  If Assigned(Helper) then
    FreeAndNil(TMemoryStream(Helper^));
except
  // do nothing
end;
end;

//==============================================================================

exports
  Exp_APIVersion                   name 'APIVersion',

  Exp_GetMemoryFormat              name 'GetMemoryFormat',
  Exp_GetFileFormat                name 'GetFileFormat',
  Exp_IsEncryptedMemory            name 'IsEncryptedMemory',
  Exp_IsEncryptedFile              name 'IsEncryptedFile',
  Exp_IsEncodedMemory              name 'IsEncodedMemory',
  Exp_IsEncodedFile                name 'IsEncodedFile',
  Exp_Is3nKEncodedMemory           name 'Is3nKEncodedMemory',
  Exp_Is3nKEncodedFile             name 'Is3nKEncodedFile',

  Exp_DecryptMemory                name 'DecryptMemory',
  Exp_DecryptFile                  name 'DecryptFile',
  Exp_DecryptFileInMemory          name 'DecryptFileInMemory',

  Exp_DecodeMemory                 name 'DecodeMemory',
  Exp_DecodeMemoryHelper           name 'DecodeMemoryHelper',
  Exp_DecodeFile                   name 'DecodeFile',
  Exp_DecodeFileInMemory           name 'DecodeFileInMemory',

  Exp_DecryptAndDecodeMemory       name 'DecryptAndDecodeMemory',
  Exp_DecryptAndDecodeMemoryHelper name 'DecryptAndDecodeMemoryHelper',
  Exp_DecryptAndDecodeFile         name 'DecryptAndDecodeFile',
  Exp_DecryptAndDecodeFileInMemory name 'DecryptAndDecodeFileInMemory',

  Exp_FreeHelper                   name 'FreeHelper';

end.

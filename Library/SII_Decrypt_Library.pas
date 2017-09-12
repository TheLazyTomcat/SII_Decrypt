{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decrypt_Library;

{$INCLUDE '..\Source\SII_Decrypt_defs.inc'}

interface

implementation

uses
  SysUtils, Classes, AuxTypes, StrRect, StaticMemoryStream,
  SII_Decrypt_Decryptor, SII_Decrypt_Header;

Function StrConv(Str: PUTF8Char): String;
begin
Result := UTF8ToStr(UTF8String(Str));
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
      Result := Ord(GetStreamFormat(MemStream));
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
    Result := Ord(GetFileFormat(StrConv(FileName)));
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
  Result := Exp_GetMemoryFormat(Mem,Size) = SIIDEC_RESULT_SUCCESS;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function Exp_IsEncryptedFile(FileName: PUTF8Char): LongBool; stdcall;
begin
try
  Result := Exp_GetFileFormat(FileName) = SIIDEC_RESULT_SUCCESS;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function Exp_IsEncodedMemory(Mem: Pointer; Size: TMemSize): LongBool; stdcall;
begin
try
  Result := Exp_GetMemoryFormat(Mem,Size) = SIIDEC_RESULT_BINARY_FORMAT;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function Exp_IsEncodedFile(FileName: PUTF8Char): LongBool; stdcall;
begin
try
  Result := Exp_GetFileFormat(FileName) = SIIDEC_RESULT_BINARY_FORMAT;
except
  Result := False;
end;
end;

//==============================================================================

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
          Result := Ord(GetStreamFormat(InMemStream));
          If Result = SIIDEC_RESULT_SUCCESS then
            begin
              InMemStream.ReadBuffer({%H-}Header,SizeOf(TSIIHeader));
              InMemStream.Seek(0,soBeginning);
              If Assigned(Output) then
                begin
                  If OutSize^ >= TMemSize(Header.DataSize) then
                    begin
                      OutMemStream := TWritableStaticMemoryStream.Create(Output,OutSize^);
                      try
                        Result := Ord(DecryptStream(InMemStream,OutMemStream,False));
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

//------------------------------------------------------------------------------

Function Exp_DecryptFile(InputFile,OutputFile: PUTF8Char): Int32; stdcall;
begin
try
  with TSII_Decryptor.Create do
  try
    ReraiseExceptions := False;
    Result := Ord(GetFileFormat(StrConv(InputFile)));
    If Result = SIIDEC_RESULT_SUCCESS then
      Result := Ord(DecryptFile(StrConv(InputFile),StrConv(OutputFile)));
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
      Result := Ord(GetStreamFormat(InMemStream));
      If Result = SIIDEC_RESULT_BINARY_FORMAT then
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
                    Result := Ord(DecodeStream(InMemStream,OutMemStream,False));
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
                Result := Ord(DecodeStream(InMemStream,HelperStream,True));
                OutSize^ := TMemSize(HelperStream.Size);
                Result := SIIDEC_RESULT_SUCCESS;
              finally
                If Assigned(Helper) then
                  Helper^ := Pointer(HelperStream)
                else
                  HelperStream.Free;
              end;
            end;
        end
      else If Result = SIIDEC_RESULT_SUCCESS then
        Result := SIIDEC_RESULT_UNKNOWN_FORMAT;
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
    Result := Ord(GetFileFormat(StrConv(InputFile)));
    If Result = SIIDEC_RESULT_BINARY_FORMAT then
      Result := Ord(DecodeFile(StrConv(InputFile),StrConv(OutputFile)))
    else If Result = SIIDEC_RESULT_SUCCESS then
      Result := SIIDEC_RESULT_UNKNOWN_FORMAT;
  finally
    Free;
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//==============================================================================

//==============================================================================

procedure FreeHelper(Helper: PPointer); stdcall;
begin
try
  If Assigned(Helper) then
    FreeAndNil(TMemoryStream(Helper^));
except
  // do nothing;
end;
end;
(*

//------------------------------------------------------------------------------

  DecryptAndDecodeMemoryHelper
  DecryptAndDecodeMemory
  DecryptAndDecodeFile

//==============================================================================

//exports
{
  GetMemoryFormat
  GetFileFormat
  IsEncryptedMemory
  IsEncryptedFile
  IsEncodedMemory
  IsEncodedFile
  DecryptMemory
  DecryptFile
  DecodeMemory
  DecodeMemoryHelper
  DecodeFile
  DecryptAndDecodeMemory
  DecryptAndDecodeMemoryHelper
  DecryptAndDecodeFile
  FreeHelper
}
(*
  Exp_IsEncryptedMemory       name 'IsEncryptedMemory',
  Exp_IsEncryptedFile         name 'IsEncryptedFile',
  Exp_DecryptMemory           name 'DecryptMemory',
  Exp_DecryptFile             name 'DecryptFile',
  Exp_DecryptFile2            name 'DecryptFile2',
  Exp_DecryptAndDecodeFile    name 'DecryptAndDecodeFile',
  Exp_DecryptAndDecodeFile2   name 'DecryptAndDecodeFile2';
*)
end.

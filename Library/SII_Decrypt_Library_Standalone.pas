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
  SII_Decrypt_Library_Header, SII_Decrypt_Library_Common,
  SII_Decrypt_Library_Decryptor;

Function Exp_APIVersion: UInt32; stdcall;
begin
Result := BuildAPIVersion(SIIDEC_LIBRARY_VERSION_MAJOR,SIIDEC_LIBRARY_VERSION_MINOR);
end;

//==============================================================================

Function Exp_GetMemoryFormat(Mem: Pointer; Size: TMemSize): Int32; stdcall;
var
  Context:  TSIIDecContext;
begin
try
  Context := Exp_Decryptor_Create();
  try
    Result := Exp_Decryptor_GetMemoryFormat(Context,Mem,Size);
  finally
    Exp_Decryptor_Free(@Context);
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_GetFileFormat(FileName: PUTF8Char): Int32; stdcall;
var
  Context:  TSIIDecContext;
begin
try
  Context := Exp_Decryptor_Create();
  try
    Result := Exp_Decryptor_GetFileFormat(Context,FileName);
  finally
    Exp_Decryptor_Free(@Context);
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

Function Exp_DecryptMemory(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;
var
  Context:  TSIIDecContext;
begin
try
  Context := Exp_Decryptor_Create();
  try
    Result := Exp_Decryptor_DecryptMemory(Context,Input,InSize,Output,OutSize);
  finally
    Exp_Decryptor_Free(@Context);
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_DecryptFile(InputFile,OutputFile: PUTF8Char): Int32; stdcall;
var
  Context:  TSIIDecContext;
begin
try
  Context := Exp_Decryptor_Create();
  try
    Result := Exp_Decryptor_DecryptFile(Context,InputFile,OutputFile);
  finally
    Exp_Decryptor_Free(@Context);
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_DecryptFileInMemory(InputFile,OutputFile: PUTF8Char): Int32; stdcall;
var
  Context:  TSIIDecContext;
begin
try
  Context := Exp_Decryptor_Create();
  try
    Result := Exp_Decryptor_DecryptFileInMemory(Context,InputFile,OutputFile);
  finally
    Exp_Decryptor_Free(@Context);
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//==============================================================================

Function Exp_DecodeMemoryHelper(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize; Helper: PPointer): Int32; stdcall;
var
  Context:  TSIIDecContext;
begin
try
  If Assigned(Output) then
    begin
      If Assigned(Helper) then
        begin
          Context := TSIIDecContext(Helper^);
          try
            Result := Exp_Decryptor_DecodeMemory(Context,Input,InSize,Output,OutSize);
          finally
            Exp_Decryptor_Free(PSIIDecContext(Helper));
          end;
        end
      else
        begin
          Context := Exp_Decryptor_Create();
          try
            Result := Exp_Decryptor_DecodeMemory(Context,Input,InSize,Output,OutSize);
          finally
            Exp_Decryptor_Free(@Context);
          end;
        end;
    end
  else
    begin
      Context := Exp_Decryptor_Create();
      try
        Result := Exp_Decryptor_DecodeMemory(Context,Input,InSize,Output,OutSize);
      finally
        If Assigned(Helper) then
          Helper^ := Pointer(Context)
        else
          Exp_Decryptor_Free(@Context);
      end;
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
var
  Context:  TSIIDecContext;
begin
try
  Context := Exp_Decryptor_Create();
  try
    Result := Exp_Decryptor_DecodeFile(Context,InputFile,OutputFile);
  finally
    Exp_Decryptor_Free(@Context);
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_DecodeFileInMemory(InputFile,OutputFile: PUTF8Char): Int32; stdcall;
var
  Context:  TSIIDecContext;
begin
try
  Context := Exp_Decryptor_Create();
  try
    Result := Exp_Decryptor_DecodeFileInMemory(Context,InputFile,OutputFile);
  finally
    Exp_Decryptor_Free(@Context);
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//==============================================================================

Function Exp_DecryptAndDecodeMemoryHelper(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize; Helper: PPointer): Int32; stdcall;
var
  Context:  TSIIDecContext;
begin
try
  If Assigned(Output) then
    begin
      If Assigned(Helper) then
        begin
          Context := TSIIDecContext(Helper^);
          try
            Result := Exp_Decryptor_DecryptAndDecodeMemory(Context,Input,InSize,Output,OutSize);
          finally
            Exp_Decryptor_Free(PSIIDecContext(Helper));
          end;
        end
      else
        begin
          Context := Exp_Decryptor_Create();
          try
            Result := Exp_Decryptor_DecryptAndDecodeMemory(Context,Input,InSize,Output,OutSize);
          finally
            Exp_Decryptor_Free(@Context);
          end;
        end;
    end
  else
    begin
      Context := Exp_Decryptor_Create();
      try
        Result := Exp_Decryptor_DecryptAndDecodeMemory(Context,Input,InSize,Output,OutSize);
      finally
        If Assigned(Helper) then
          Helper^ := Pointer(Context)
        else
          Exp_Decryptor_Free(@Context);
      end;
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
var
  Context:  TSIIDecContext;
begin
try
  Context := Exp_Decryptor_Create();
  try
    Result := Exp_Decryptor_DecryptAndDecodeFile(Context,InputFile,OutputFile);
  finally
    Exp_Decryptor_Free(@Context);
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_DecryptAndDecodeFileInMemory(InputFile,OutputFile: PUTF8Char): Int32; stdcall;
var
  Context:  TSIIDecContext;
begin
try
  Context := Exp_Decryptor_Create();
  try
    Result := Exp_Decryptor_DecryptAndDecodeFileInMemory(Context,InputFile,OutputFile);
  finally
    Exp_Decryptor_Free(@Context);
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
    Exp_Decryptor_Free(PSIIDecContext(Helper));
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

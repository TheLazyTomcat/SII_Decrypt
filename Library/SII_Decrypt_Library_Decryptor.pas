{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decrypt_Library_Decryptor;

{$INCLUDE '..\Source\SII_Decrypt_defs.inc'}

interface

uses
  AuxTypes,
  SII_Decrypt_Header;


Function Exp_Decryptor_Create: TSIIDecContext; stdcall;
procedure Exp_Decryptor_Free(Context: PSIIDecContext); stdcall;

Function Exp_Decryptor_GetOptionBool(Context: TSIIDecContext; OptionID: Int32): LongBool; stdcall;
procedure Exp_Decryptor_SetOptionBool(Context: TSIIDecContext; OptionID: Int32; NewValue: LongBool); stdcall;
procedure Exp_Decryptor_SetProgressCallback(Context: TSIIDecContext; CallbackFunc: Pointer); stdcall;

Function Exp_Decryptor_GetMemoryFormat(Context: TSIIDecContext; Mem: Pointer; Size: TMemSize): Int32; stdcall;
Function Exp_Decryptor_GetFileFormat(Context: TSIIDecContext; FileName: PUTF8Char): Int32; stdcall;
Function Exp_Decryptor_IsEncryptedMemory(Context: TSIIDecContext; Mem: Pointer; Size: TMemSize): LongBool; stdcall;
Function Exp_Decryptor_IsEncryptedFile(Context: TSIIDecContext; FileName: PUTF8Char): LongBool; stdcall;
Function Exp_Decryptor_IsEncodedMemory(Context: TSIIDecContext; Mem: Pointer; Size: TMemSize): LongBool; stdcall;
Function Exp_Decryptor_IsEncodedFile(Context: TSIIDecContext; FileName: PUTF8Char): LongBool; stdcall;
Function Exp_Decryptor_Is3nKEncodedMemory(Context: TSIIDecContext; Mem: Pointer; Size: TMemSize): LongBool; stdcall;
Function Exp_Decryptor_Is3nKEncodedFile(Context: TSIIDecContext; FileName: PUTF8Char): LongBool; stdcall;
(*
Function Exp_Decryptor_DecryptMemory(Context: TSIIDecContext; Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;
Function Exp_Decryptor_DecryptFile(Context: TSIIDecContext; InputFile,OutputFile: PUTF8Char): Int32; stdcall;
Function Exp_Decryptor_DecryptFileInMemory(Context: TSIIDecContext; InputFile,OutputFile: PUTF8Char): Int32; stdcall;

Function Exp_Decryptor_DecodeMemory(Context: TSIIDecContext; Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;
Function Exp_Decryptor_DecodeFile(Context: TSIIDecContext; InputFile,OutputFile: PUTF8Char): Int32; stdcall;
Function Exp_Decryptor_DecodeFileInMemory(Context: TSIIDecContext; InputFile,OutputFile: PUTF8Char): Int32; stdcall;

Function Exp_Decryptor_DecryptAndDecodeMemory(Context: TSIIDecContext; Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;
Function Exp_Decryptor_DecryptAndDecodeFile(Context: TSIIDecContext; InputFile,OutputFile: PUTF8Char): Int32; stdcall;
Function Exp_Decryptor_DecryptAndDecodeFileInMemory(Context: TSIIDecContext; InputFile,OutputFile: PUTF8Char): Int32; stdcall;
*)

implementation

uses
  StaticMemoryStream,
  SII_Decrypt_Decryptor, SII_Decrypt_Library_Common;


type
  TSIIDecContextInternal = record
    Decryptor:  TSII_Decryptor;
    Callback:   TSIIDecProgressCallback;
  end;
  PSIIDecContextInternal = ^TSIIDecContextInternal;

procedure ProgressCallbackFwd(Sender: TObject; Progress: Double);
begin
//PSIIDecContextInternal((Sender as TSII_Decryptor).UserPtrData)^.
  //Callback(TSIIDecContext((Sender as TSII_Decryptor).UserPtrData),Progress);
end;

//==============================================================================

Function Exp_Decryptor_Create: TSIIDecContext;
begin
try
  New(PSIIDecContextInternal(Result));
  PSIIDecContextInternal(Result)^.Decryptor := TSII_Decryptor.Create;
  PSIIDecContextInternal(Result)^.Decryptor.ReraiseExceptions := False;
  PSIIDecContextInternal(Result)^.Decryptor.UserPtrData := Result;
  PSIIDecContextInternal(Result)^.Callback := nil;
except
  Result := nil;
end;
end;

//------------------------------------------------------------------------------

procedure Exp_Decryptor_Free(Context: PSIIDecContext);
begin
try
  PSIIDecContextInternal(Context^)^.Decryptor.Free;
  PSIIDecContextInternal(Context^)^.Decryptor := nil;
  PSIIDecContextInternal(Context^)^.Callback := nil;
  Dispose(PSIIDecContextInternal(Context^));
  Context^ := nil;
except
  // do nothing
end;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_GetOptionBool(Context: TSIIDecContext; OptionID: Int32): LongBool;
begin
try
  case OptionID of
    SIIDEC_OPTIONID_ACCEL_AES:  Result := PSIIDecContextInternal(Context)^.Decryptor.AcceleratedAES;
    SIIDEC_OPTIONID_DEC_UNSUPP: Result := PSIIDecContextInternal(Context)^.Decryptor.DecodeUnsuported;
  else
    Result := False;
  end;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

procedure Exp_Decryptor_SetOptionBool(Context: TSIIDecContext; OptionID: Int32; NewValue: LongBool);
begin
try
  case OptionID of
    SIIDEC_OPTIONID_ACCEL_AES:  PSIIDecContextInternal(Context)^.Decryptor.AcceleratedAES := NewValue;
    SIIDEC_OPTIONID_DEC_UNSUPP: PSIIDecContextInternal(Context)^.Decryptor.DecodeUnsuported := NewValue;
  end;
except
  // do nothing
end;
end;

//------------------------------------------------------------------------------

procedure Exp_Decryptor_SetProgressCallback(Context: TSIIDecContext; CallbackFunc: Pointer);
begin
try
  PSIIDecContextInternal(Context)^.Callback := TSIIDecProgressCallback(CallbackFunc);
except
  // do nothing
end;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_GetMemoryFormat(Context: TSIIDecContext; Mem: Pointer; Size: TMemSize): Int32;
var
  MemStream:  TStaticMemoryStream;
begin
try
  MemStream := TStaticMemoryStream.Create(Mem,Size);
  try
    Result := GetResultAsInt(PSIIDecContextInternal(Context)^.Decryptor.GetStreamFormat(MemStream));
  finally
    MemStream.Free;
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_GetFileFormat(Context: TSIIDecContext; FileName: PUTF8Char): Int32;
begin
Result := GetResultAsInt(PSIIDecContextInternal(Context)^.Decryptor.GetFileFormat(StrConv(FileName)));
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_IsEncryptedMemory(Context: TSIIDecContext; Mem: Pointer; Size: TMemSize): LongBool;
begin
Result := Exp_Decryptor_GetMemoryFormat(Context,Mem,Size) = SIIDEC_RESULT_FORMAT_ENCRYPTED;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_IsEncryptedFile(Context: TSIIDecContext; FileName: PUTF8Char): LongBool;
begin
Result := Exp_Decryptor_GetFileFormat(Context,FileName) = SIIDEC_RESULT_FORMAT_ENCRYPTED;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_IsEncodedMemory(Context: TSIIDecContext; Mem: Pointer; Size: TMemSize): LongBool;
begin
Result := Exp_Decryptor_GetMemoryFormat(Context,Mem,Size) = SIIDEC_RESULT_FORMAT_BINARY;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_IsEncodedFile(Context: TSIIDecContext; FileName: PUTF8Char): LongBool;
begin
Result := Exp_Decryptor_GetFileFormat(Context,FileName) = SIIDEC_RESULT_FORMAT_BINARY;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_Is3nKEncodedMemory(Context: TSIIDecContext; Mem: Pointer; Size: TMemSize): LongBool;
begin
Result := Exp_Decryptor_GetMemoryFormat(Context,Mem,Size) = SIIDEC_RESULT_FORMAT_3NK;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_Is3nKEncodedFile(Context: TSIIDecContext; FileName: PUTF8Char): LongBool;
begin
Result := Exp_Decryptor_GetFileFormat(Context,FileName) = SIIDEC_RESULT_FORMAT_3NK;
end;

//------------------------------------------------------------------------------

//==============================================================================

exports
  Exp_Decryptor_Create              name 'Decryptor_Create',
  Exp_Decryptor_Free                name 'Decryptor_Free',

  Exp_Decryptor_GetOptionBool       name 'Decryptor_GetOptionBool',
  Exp_Decryptor_SetOptionBool       name 'Decryptor_SetOptionBool',
  Exp_Decryptor_SetProgressCallback name 'Decryptor_SetProgressCallback',

  Exp_Decryptor_GetMemoryFormat     name 'Decryptor_GetMemoryFormat',
  Exp_Decryptor_GetFileFormat       name 'Decryptor_GetFileFormat',
  Exp_Decryptor_IsEncryptedMemory   name 'Decryptor_IsEncryptedMemory',
  Exp_Decryptor_IsEncryptedFile     name 'Decryptor_IsEncryptedFile',
  Exp_Decryptor_IsEncodedMemory     name 'Decryptor_IsEncodedMemory',
  Exp_Decryptor_IsEncodedFile       name 'Decryptor_IsEncodedFile',
  Exp_Decryptor_Is3nKEncodedMemory  name 'Decryptor_Is3nKEncodedMemory',
  Exp_Decryptor_Is3nKEncodedFile    name 'Decryptor_Is3nKEncodedFile';

end.

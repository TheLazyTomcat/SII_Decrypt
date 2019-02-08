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
  SII_Decrypt_Library_Header;

Function Exp_Decryptor_Create: TSIIDecryptorObject; stdcall;
procedure Exp_Decryptor_Free(PDecryptor: PSIIDecryptorObject); stdcall;

Function Exp_Decryptor_GetOptionBool(Decryptor: TSIIDecryptorObject; OptionID: Int32): LongBool; stdcall;
procedure Exp_Decryptor_SetOptionBool(Decryptor: TSIIDecryptorObject; OptionID: Int32; NewValue: LongBool); stdcall;
procedure Exp_Decryptor_SetProgressCallback(Decryptor: TSIIDecryptorObject; CallbackFunc: TSIIDecryptorProgressCallback); stdcall;

Function Exp_Decryptor_GetMemoryFormat(Decryptor: TSIIDecryptorObject; Mem: Pointer; Size: TMemSize): Int32; stdcall;
Function Exp_Decryptor_GetFileFormat(Decryptor: TSIIDecryptorObject; FileName: PUTF8Char): Int32; stdcall;
Function Exp_Decryptor_IsEncryptedMemory(Decryptor: TSIIDecryptorObject; Mem: Pointer; Size: TMemSize): LongBool; stdcall;
Function Exp_Decryptor_IsEncryptedFile(Decryptor: TSIIDecryptorObject; FileName: PUTF8Char): LongBool; stdcall;
Function Exp_Decryptor_IsEncodedMemory(Decryptor: TSIIDecryptorObject; Mem: Pointer; Size: TMemSize): LongBool; stdcall;
Function Exp_Decryptor_IsEncodedFile(Decryptor: TSIIDecryptorObject; FileName: PUTF8Char): LongBool; stdcall;
Function Exp_Decryptor_Is3nKEncodedMemory(Decryptor: TSIIDecryptorObject; Mem: Pointer; Size: TMemSize): LongBool; stdcall;
Function Exp_Decryptor_Is3nKEncodedFile(Decryptor: TSIIDecryptorObject; FileName: PUTF8Char): LongBool; stdcall;

Function Exp_Decryptor_DecryptMemory(Decryptor: TSIIDecryptorObject; Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;
Function Exp_Decryptor_DecryptFile(Decryptor: TSIIDecryptorObject; InputFile,OutputFile: PUTF8Char): Int32; stdcall;
Function Exp_Decryptor_DecryptFileInMemory(Decryptor: TSIIDecryptorObject; InputFile,OutputFile: PUTF8Char): Int32; stdcall;

Function Exp_Decryptor_DecodeMemory(Decryptor: TSIIDecryptorObject; Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;
Function Exp_Decryptor_DecodeFile(Decryptor: TSIIDecryptorObject; InputFile,OutputFile: PUTF8Char): Int32; stdcall;
Function Exp_Decryptor_DecodeFileInMemory(Decryptor: TSIIDecryptorObject; InputFile,OutputFile: PUTF8Char): Int32; stdcall;

Function Exp_Decryptor_DecryptAndDecodeMemory(Decryptor: TSIIDecryptorObject; Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;
Function Exp_Decryptor_DecryptAndDecodeFile(Decryptor: TSIIDecryptorObject; InputFile,OutputFile: PUTF8Char): Int32; stdcall;
Function Exp_Decryptor_DecryptAndDecodeFileInMemory(Decryptor: TSIIDecryptorObject; InputFile,OutputFile: PUTF8Char): Int32; stdcall;

implementation

uses
  Classes,
  StaticMemoryStream,
  SII_Decrypt_Decryptor, SII_Decrypt_Library_Common;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W5057:={$WARN 5057 OFF}} // Local variable "$1" does not seem to be initialized
{$ENDIF}

type
  TSIIDecryptorObjectInternal = record
    Decryptor:  TSII_Decryptor;
    Callback:   TSIIDecryptorProgressCallback;
    Helper:     TMemoryStream;
  end;
  PSIIDecryptorObjectInternal = ^TSIIDecryptorObjectInternal;

//==============================================================================

Function DerefDecryptor(Decryptor: Pointer): TSII_Decryptor;
begin
Result := PSIIDecryptorObjectInternal(Decryptor)^.Decryptor;
end;

//------------------------------------------------------------------------------

Function DerefHelper(Helper: Pointer): TMemoryStream;
begin
Result := PSIIDecryptorObjectInternal(Helper)^.Helper;
end;

//------------------------------------------------------------------------------

procedure ProgressCallbackFwd(Sender: TObject; Progress: Double);
begin
PSIIDecryptorObjectInternal(TSII_Decryptor(Sender).UserPtrData)^.
  Callback(TSIIDecryptorObject(TSII_Decryptor(Sender).UserPtrData),Progress);
end;

//==============================================================================

Function Exp_Decryptor_Create: TSIIDecryptorObject;
begin
try
  New(PSIIDecryptorObjectInternal(Result));
  PSIIDecryptorObjectInternal(Result)^.Decryptor := TSII_Decryptor.Create;
  PSIIDecryptorObjectInternal(Result)^.Decryptor.ReraiseExceptions := False;
  PSIIDecryptorObjectInternal(Result)^.Decryptor.UserPtrData := Result;
  PSIIDecryptorObjectInternal(Result)^.Callback := nil;
  PSIIDecryptorObjectInternal(Result)^.Helper := nil;
except
  Result := nil;
end;
end;

//------------------------------------------------------------------------------

procedure Exp_Decryptor_Free(PDecryptor: PSIIDecryptorObject);
begin
try
  If Assigned(PDecryptor^) then
    begin
      PSIIDecryptorObjectInternal(PDecryptor^)^.Decryptor.Free;
      PSIIDecryptorObjectInternal(PDecryptor^)^.Decryptor := nil;
      PSIIDecryptorObjectInternal(PDecryptor^)^.Callback := nil;
      If Assigned(PSIIDecryptorObjectInternal(PDecryptor^)^.Helper) then
        PSIIDecryptorObjectInternal(PDecryptor^)^.Helper.Free;
      PSIIDecryptorObjectInternal(PDecryptor^)^.Helper := nil;
      Dispose(PSIIDecryptorObjectInternal(PDecryptor^));
      PDecryptor^ := nil;
    end;
except
  // do nothing
end;
end;

//==============================================================================

Function Exp_Decryptor_GetOptionBool(Decryptor: TSIIDecryptorObject; OptionID: Int32): LongBool;
begin
try
  case OptionID of
    SIIDEC_OPTIONID_ACCEL_AES:  Result := DerefDecryptor(Decryptor).AcceleratedAES;
    SIIDEC_OPTIONID_DEC_UNSUPP: Result := DerefDecryptor(Decryptor).DecodeUnsuported;
  else
    Result := False;
  end;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

procedure Exp_Decryptor_SetOptionBool(Decryptor: TSIIDecryptorObject; OptionID: Int32; NewValue: LongBool);
begin
try
  case OptionID of
    SIIDEC_OPTIONID_ACCEL_AES:  DerefDecryptor(Decryptor).AcceleratedAES := NewValue;
    SIIDEC_OPTIONID_DEC_UNSUPP: DerefDecryptor(Decryptor).DecodeUnsuported := NewValue;
  end;
except
  // do nothing
end;
end;

//------------------------------------------------------------------------------

procedure Exp_Decryptor_SetProgressCallback(Decryptor: TSIIDecryptorObject; CallbackFunc: TSIIDecryptorProgressCallback);
begin
try
  PSIIDecryptorObjectInternal(Decryptor)^.Callback := CallbackFunc;
  If Assigned(CallbackFunc) then
    DerefDecryptor(Decryptor).OnProgressCallback := ProgressCallbackFwd
  else
    DerefDecryptor(Decryptor).OnProgressCallback := nil;
except
  // do nothing
end;
end;

//==============================================================================

Function Exp_Decryptor_GetMemoryFormat(Decryptor: TSIIDecryptorObject; Mem: Pointer; Size: TMemSize): Int32;
var
  MemStream:  TStaticMemoryStream;
begin
try
  MemStream := TStaticMemoryStream.Create(Mem,Size);
  try
    Result := GetResultAsInt(DerefDecryptor(Decryptor).GetStreamFormat(MemStream));
  finally
    MemStream.Free;
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_GetFileFormat(Decryptor: TSIIDecryptorObject; FileName: PUTF8Char): Int32;
begin
Result := GetResultAsInt(DerefDecryptor(Decryptor).GetFileFormat(StrConv(FileName)));
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_IsEncryptedMemory(Decryptor: TSIIDecryptorObject; Mem: Pointer; Size: TMemSize): LongBool;
begin
Result := Exp_Decryptor_GetMemoryFormat(Decryptor,Mem,Size) = SIIDEC_RESULT_FORMAT_ENCRYPTED;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_IsEncryptedFile(Decryptor: TSIIDecryptorObject; FileName: PUTF8Char): LongBool;
begin
Result := Exp_Decryptor_GetFileFormat(Decryptor,FileName) = SIIDEC_RESULT_FORMAT_ENCRYPTED;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_IsEncodedMemory(Decryptor: TSIIDecryptorObject; Mem: Pointer; Size: TMemSize): LongBool;
begin
Result := Exp_Decryptor_GetMemoryFormat(Decryptor,Mem,Size) = SIIDEC_RESULT_FORMAT_BINARY;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_IsEncodedFile(Decryptor: TSIIDecryptorObject; FileName: PUTF8Char): LongBool;
begin
Result := Exp_Decryptor_GetFileFormat(Decryptor,FileName) = SIIDEC_RESULT_FORMAT_BINARY;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_Is3nKEncodedMemory(Decryptor: TSIIDecryptorObject; Mem: Pointer; Size: TMemSize): LongBool;
begin
Result := Exp_Decryptor_GetMemoryFormat(Decryptor,Mem,Size) = SIIDEC_RESULT_FORMAT_3NK;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_Is3nKEncodedFile(Decryptor: TSIIDecryptorObject; FileName: PUTF8Char): LongBool;
begin
Result := Exp_Decryptor_GetFileFormat(Decryptor,FileName) = SIIDEC_RESULT_FORMAT_3NK;
end;

//==============================================================================

{$IFDEF FPCDWM}{$PUSH}W5057{$ENDIF}
Function Exp_Decryptor_DecryptMemory(Decryptor: TSIIDecryptorObject; Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32;
var
  InMemStream:  TStaticMemoryStream;
  Header:       TSIIHeader;
  OutMemStream: TWritableStaticMemoryStream;
begin
try
  InMemStream := TStaticMemoryStream.Create(Input,InSize);
  try
    Result := GetResultAsInt(DerefDecryptor(Decryptor).GetStreamFormat(InMemStream));
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
                  Result := GetResultAsInt(DerefDecryptor(Decryptor).DecryptStream(InMemStream,OutMemStream,True));
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
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

Function Exp_Decryptor_DecryptFile(Decryptor: TSIIDecryptorObject; InputFile,OutputFile: PUTF8Char): Int32;
begin
try
  Result := GetResultAsInt(DerefDecryptor(Decryptor).GetFileFormat(StrConv(InputFile)));
  If Result = SIIDEC_RESULT_FORMAT_ENCRYPTED then
    Result := GetResultAsInt(DerefDecryptor(Decryptor).DecryptFile(StrConv(InputFile),StrConv(OutputFile)));
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_DecryptFileInMemory(Decryptor: TSIIDecryptorObject; InputFile,OutputFile: PUTF8Char): Int32;
begin
try
  Result := GetResultAsInt(DerefDecryptor(Decryptor).GetFileFormat(StrConv(InputFile)));
  If Result = SIIDEC_RESULT_FORMAT_ENCRYPTED then
    Result := GetResultAsInt(DerefDecryptor(Decryptor).DecryptFileInMemory(StrConv(InputFile),StrConv(OutputFile)));
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//==============================================================================

Function Exp_Decryptor_DecodeMemory(Decryptor: TSIIDecryptorObject; Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32;
var
  InMemStream:  TStaticMemoryStream;
  OutMemStream: TWritableStaticMemoryStream;
begin
try
  InMemStream := TStaticMemoryStream.Create(Input,InSize);
  try
    Result := GetResultAsInt(DerefDecryptor(Decryptor).GetStreamFormat(InMemStream));
    If Result in [SIIDEC_RESULT_FORMAT_BINARY,SIIDEC_RESULT_FORMAT_3NK] then
      begin
        If Assigned(Output) then
          begin
            If Assigned(DerefHelper(Decryptor)) then
              begin
                // helper stream is assigned, only copy its content
                try
                  If OutSize^ >= DerefHelper(Decryptor).Size then
                    begin
                      Move(DerefHelper(Decryptor).Memory^,Output^,DerefHelper(Decryptor).Size);
                      OutSize^ := TMemSize(DerefHelper(Decryptor).Size);
                      Result := SIIDEC_RESULT_SUCCESS;
                    end
                  else Result := SIIDEC_RESULT_BUFFER_TOO_SMALL;
                finally
                  DerefHelper(Decryptor).Free;
                  PSIIDecryptorObjectInternal(Decryptor)^.Helper := nil;
                end;
              end
            else  // helper stream not assigned, do complete decode...
              begin
                OutMemStream := TWritableStaticMemoryStream.Create(Output,OutSize^);
                try
                  Result := GetResultAsInt(DerefDecryptor(Decryptor).DecodeStream(InMemStream,OutMemStream,True));
                  If Result = SIIDEC_RESULT_SUCCESS then
                    OutSize^ := TMemSize(OutMemStream.Position);
                finally
                  OutMemStream.Free;
                end;
              end;
          end
        else  // output not assigned, only get size...
          begin
            PSIIDecryptorObjectInternal(Decryptor)^.Helper := TMemoryStream.Create;
            Result := GetResultAsInt(DerefDecryptor(Decryptor).DecodeStream(InMemStream,DerefHelper(Decryptor),False));
            If Result <> SIIDEC_RESULT_SUCCESS then
              begin
                DerefHelper(Decryptor).Free;
                PSIIDecryptorObjectInternal(Decryptor)^.Helper := nil;
              end
            else OutSize^ := TMemSize(DerefHelper(Decryptor).Size);
          end;
      end;
  finally
    InMemStream.Free;
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_DecodeFile(Decryptor: TSIIDecryptorObject; InputFile,OutputFile: PUTF8Char): Int32;
begin
try
  Result := GetResultAsInt(DerefDecryptor(Decryptor).GetFileFormat(StrConv(InputFile)));
  If Result in [SIIDEC_RESULT_FORMAT_BINARY,SIIDEC_RESULT_FORMAT_3NK] then
    Result := GetResultAsInt(DerefDecryptor(Decryptor).DecodeFile(StrConv(InputFile),StrConv(OutputFile)));
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_DecodeFileInMemory(Decryptor: TSIIDecryptorObject; InputFile,OutputFile: PUTF8Char): Int32;
begin
try
  Result := GetResultAsInt(DerefDecryptor(Decryptor).GetFileFormat(StrConv(InputFile)));
  If Result in [SIIDEC_RESULT_FORMAT_BINARY,SIIDEC_RESULT_FORMAT_3NK] then
    Result := GetResultAsInt(DerefDecryptor(Decryptor).DecodeFileInMemory(StrConv(InputFile),StrConv(OutputFile)));
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//==============================================================================

Function Exp_Decryptor_DecryptAndDecodeMemory(Decryptor: TSIIDecryptorObject; Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32;
var
  InMemStream:  TStaticMemoryStream;
  OutMemStream: TWritableStaticMemoryStream;
begin
try
  InMemStream := TStaticMemoryStream.Create(Input,InSize);
  try
    Result := GetResultAsInt(DerefDecryptor(Decryptor).GetStreamFormat(InMemStream));
    If Result in [SIIDEC_RESULT_FORMAT_ENCRYPTED,SIIDEC_RESULT_FORMAT_BINARY,SIIDEC_RESULT_FORMAT_3NK] then
      begin
        If Assigned(Output) then
          begin
            If Assigned(DerefHelper(Decryptor)) then
              begin
                // helper stream is assigned, only copy its content
                try
                  If OutSize^ >= DerefHelper(Decryptor).Size then
                    begin
                      Move(DerefHelper(Decryptor).Memory^,Output^,DerefHelper(Decryptor).Size);
                      OutSize^ := TMemSize(DerefHelper(Decryptor).Size);
                      Result := SIIDEC_RESULT_SUCCESS;
                    end
                  else Result := SIIDEC_RESULT_BUFFER_TOO_SMALL;
                finally
                  DerefHelper(Decryptor).Free;
                  PSIIDecryptorObjectInternal(Decryptor)^.Helper := nil;
                end;
              end
            else  // helper stream not assigned, do complete decrypt/decode...
              begin
                OutMemStream := TWritableStaticMemoryStream.Create(Output,OutSize^);
                try
                  Result := GetResultAsInt(DerefDecryptor(Decryptor).DecryptAndDecodeStream(InMemStream,OutMemStream,True));
                  If Result = SIIDEC_RESULT_SUCCESS then
                    OutSize^ := TMemSize(OutMemStream.Position);
                finally
                  OutMemStream.Free;
                end;
              end;
          end
        else  // output not assigned, only get size...
          begin
            PSIIDecryptorObjectInternal(Decryptor)^.Helper := TMemoryStream.Create;
            Result := GetResultAsInt(DerefDecryptor(Decryptor).DecryptAndDecodeStream(InMemStream,DerefHelper(Decryptor),False));
            If Result <> SIIDEC_RESULT_SUCCESS then
              begin
                DerefHelper(Decryptor).Free;
                PSIIDecryptorObjectInternal(Decryptor)^.Helper := nil;
              end
            else OutSize^ := TMemSize(DerefHelper(Decryptor).Size);
          end;
      end;
  finally
    InMemStream.Free;
  end;
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_DecryptAndDecodeFile(Decryptor: TSIIDecryptorObject; InputFile,OutputFile: PUTF8Char): Int32;
begin
try
  Result := GetResultAsInt(DerefDecryptor(Decryptor).GetFileFormat(StrConv(InputFile)));
  If Result in [SIIDEC_RESULT_FORMAT_ENCRYPTED,SIIDEC_RESULT_FORMAT_BINARY,SIIDEC_RESULT_FORMAT_3NK] then
    Result := GetResultAsInt(DerefDecryptor(Decryptor).DecryptAndDecodeFile(StrConv(InputFile),StrConv(OutputFile)))
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_DecryptAndDecodeFileInMemory(Decryptor: TSIIDecryptorObject; InputFile,OutputFile: PUTF8Char): Int32;
begin
try
  Result := GetResultAsInt(DerefDecryptor(Decryptor).GetFileFormat(StrConv(InputFile)));
  If Result in [SIIDEC_RESULT_FORMAT_ENCRYPTED,SIIDEC_RESULT_FORMAT_BINARY,SIIDEC_RESULT_FORMAT_3NK] then
    Result := GetResultAsInt(DerefDecryptor(Decryptor).DecryptAndDecodeFileInMemory(StrConv(InputFile),StrConv(OutputFile)))
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//==============================================================================

exports
  Exp_Decryptor_Create                       name 'Decryptor_Create',
  Exp_Decryptor_Free                         name 'Decryptor_Free',

  Exp_Decryptor_GetOptionBool                name 'Decryptor_GetOptionBool',
  Exp_Decryptor_SetOptionBool                name 'Decryptor_SetOptionBool',
  Exp_Decryptor_SetProgressCallback          name 'Decryptor_SetProgressCallback',

  Exp_Decryptor_GetMemoryFormat              name 'Decryptor_GetMemoryFormat',
  Exp_Decryptor_GetFileFormat                name 'Decryptor_GetFileFormat',
  Exp_Decryptor_IsEncryptedMemory            name 'Decryptor_IsEncryptedMemory',
  Exp_Decryptor_IsEncryptedFile              name 'Decryptor_IsEncryptedFile',
  Exp_Decryptor_IsEncodedMemory              name 'Decryptor_IsEncodedMemory',
  Exp_Decryptor_IsEncodedFile                name 'Decryptor_IsEncodedFile',
  Exp_Decryptor_Is3nKEncodedMemory           name 'Decryptor_Is3nKEncodedMemory',
  Exp_Decryptor_Is3nKEncodedFile             name 'Decryptor_Is3nKEncodedFile',

  Exp_Decryptor_DecryptMemory                name 'Decryptor_DecryptMemory',
  Exp_Decryptor_DecryptFile                  name 'Decryptor_DecryptFile',
  Exp_Decryptor_DecryptFileInMemory          name 'Decryptor_DecryptFileInMemory',

  Exp_Decryptor_DecodeMemory                 name 'Decryptor_DecodeMemory',
  Exp_Decryptor_DecodeFile                   name 'Decryptor_DecodeFile',
  Exp_Decryptor_DecodeFileInMemory           name 'Decryptor_DecodeFileInMemory',

  Exp_Decryptor_DecryptAndDecodeMemory       name 'Decryptor_DecryptAndDecodeMemory',
  Exp_Decryptor_DecryptAndDecodeFile         name 'Decryptor_DecryptAndDecodeFile',
  Exp_Decryptor_DecryptAndDecodeFileInMemory name 'Decryptor_DecryptAndDecodeFileInMemory';

end.

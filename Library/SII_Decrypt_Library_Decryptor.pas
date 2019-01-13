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

Function Exp_Decryptor_DecryptMemory(Context: TSIIDecContext; Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;
Function Exp_Decryptor_DecryptFile(Context: TSIIDecContext; InputFile,OutputFile: PUTF8Char): Int32; stdcall;
Function Exp_Decryptor_DecryptFileInMemory(Context: TSIIDecContext; InputFile,OutputFile: PUTF8Char): Int32; stdcall;

Function Exp_Decryptor_DecodeMemory(Context: TSIIDecContext; Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;
Function Exp_Decryptor_DecodeFile(Context: TSIIDecContext; InputFile,OutputFile: PUTF8Char): Int32; stdcall;
Function Exp_Decryptor_DecodeFileInMemory(Context: TSIIDecContext; InputFile,OutputFile: PUTF8Char): Int32; stdcall;

Function Exp_Decryptor_DecryptAndDecodeMemory(Context: TSIIDecContext; Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;
Function Exp_Decryptor_DecryptAndDecodeFile(Context: TSIIDecContext; InputFile,OutputFile: PUTF8Char): Int32; stdcall;
Function Exp_Decryptor_DecryptAndDecodeFileInMemory(Context: TSIIDecContext; InputFile,OutputFile: PUTF8Char): Int32; stdcall;

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
  TSIIDecContextInternal = record
    Decryptor:  TSII_Decryptor;
    Callback:   TSIIDecProgressCallback;
    Helper:     TMemoryStream;
  end;
  PSIIDecContextInternal = ^TSIIDecContextInternal;

//==============================================================================

Function CtxDecryptor(Context: Pointer): TSII_Decryptor;
begin
Result := PSIIDecContextInternal(Context)^.Decryptor;
end;

//------------------------------------------------------------------------------

Function CtxHelper(Context: Pointer): TMemoryStream;
begin
Result := PSIIDecContextInternal(Context)^.Helper;
end;

//------------------------------------------------------------------------------

procedure ProgressCallbackFwd(Sender: TObject; Progress: Double);
begin
PSIIDecContextInternal((Sender as TSII_Decryptor).UserPtrData)^.
  Callback(TSIIDecContext((Sender as TSII_Decryptor).UserPtrData),Progress);
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
  PSIIDecContextInternal(Result)^.Helper := nil;
except
  Result := nil;
end;
end;

//------------------------------------------------------------------------------

procedure Exp_Decryptor_Free(Context: PSIIDecContext);
begin
try
  If Assigned(Context^) then
    begin
      PSIIDecContextInternal(Context^)^.Decryptor.Free;
      PSIIDecContextInternal(Context^)^.Decryptor := nil;
      PSIIDecContextInternal(Context^)^.Callback := nil;
      If Assigned(PSIIDecContextInternal(Context^)^.Helper) then
        PSIIDecContextInternal(Context^)^.Helper.Free;
      PSIIDecContextInternal(Context^)^.Helper := nil;
      Dispose(PSIIDecContextInternal(Context^));
      Context^ := nil;
    end;
except
  // do nothing
end;
end;

//==============================================================================

Function Exp_Decryptor_GetOptionBool(Context: TSIIDecContext; OptionID: Int32): LongBool;
begin
try
  case OptionID of
    SIIDEC_OPTIONID_ACCEL_AES:  Result := CtxDecryptor(Context).AcceleratedAES;
    SIIDEC_OPTIONID_DEC_UNSUPP: Result := CtxDecryptor(Context).DecodeUnsuported;
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
    SIIDEC_OPTIONID_ACCEL_AES:  CtxDecryptor(Context).AcceleratedAES := NewValue;
    SIIDEC_OPTIONID_DEC_UNSUPP: CtxDecryptor(Context).DecodeUnsuported := NewValue;
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
  If Assigned(CallbackFunc) then
    CtxDecryptor(Context).OnProgressCallback := ProgressCallbackFwd
  else
    CtxDecryptor(Context).OnProgressCallback := nil;
except
  // do nothing
end;
end;

//==============================================================================

Function Exp_Decryptor_GetMemoryFormat(Context: TSIIDecContext; Mem: Pointer; Size: TMemSize): Int32;
var
  MemStream:  TStaticMemoryStream;
begin
try
  MemStream := TStaticMemoryStream.Create(Mem,Size);
  try
    Result := GetResultAsInt(CtxDecryptor(Context).GetStreamFormat(MemStream));
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
Result := GetResultAsInt(CtxDecryptor(Context).GetFileFormat(StrConv(FileName)));
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

//==============================================================================

{$IFDEF FPCDWM}{$PUSH}W5057{$ENDIF}
Function Exp_Decryptor_DecryptMemory(Context: TSIIDecContext; Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32;
var
  InMemStream:  TStaticMemoryStream;
  Header:       TSIIHeader;
  OutMemStream: TWritableStaticMemoryStream;
begin
try
  InMemStream := TStaticMemoryStream.Create(Input,InSize);
  try
    Result := GetResultAsInt(CtxDecryptor(Context).GetStreamFormat(InMemStream));
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
                  Result := GetResultAsInt(CtxDecryptor(Context).DecryptStream(InMemStream,OutMemStream,True));
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

Function Exp_Decryptor_DecryptFile(Context: TSIIDecContext; InputFile,OutputFile: PUTF8Char): Int32;
begin
try
  Result := GetResultAsInt(CtxDecryptor(Context).GetFileFormat(StrConv(InputFile)));
  If Result = SIIDEC_RESULT_FORMAT_ENCRYPTED then
    Result := GetResultAsInt(CtxDecryptor(Context).DecryptFile(StrConv(InputFile),StrConv(OutputFile)));
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_DecryptFileInMemory(Context: TSIIDecContext; InputFile,OutputFile: PUTF8Char): Int32;
begin
try
  Result := GetResultAsInt(CtxDecryptor(Context).GetFileFormat(StrConv(InputFile)));
  If Result = SIIDEC_RESULT_FORMAT_ENCRYPTED then
    Result := GetResultAsInt(CtxDecryptor(Context).DecryptFileInMemory(StrConv(InputFile),StrConv(OutputFile)));
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//==============================================================================

Function Exp_Decryptor_DecodeMemory(Context: TSIIDecContext; Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32;
var
  InMemStream:  TStaticMemoryStream;
  OutMemStream: TWritableStaticMemoryStream;
begin
try
  InMemStream := TStaticMemoryStream.Create(Input,InSize);
  try
    Result := GetResultAsInt(CtxDecryptor(Context).GetStreamFormat(InMemStream));
    If Result in [SIIDEC_RESULT_FORMAT_BINARY,SIIDEC_RESULT_FORMAT_3NK] then
      begin
        If Assigned(Output) then
          begin
            If Assigned(CtxHelper(Context)) then
              begin
                // helper stream is assigned, only copy its content
                try
                  If OutSize^ >= CtxHelper(Context).Size then
                    begin
                      Move(CtxHelper(Context).Memory^,Output^,CtxHelper(Context).Size);
                      OutSize^ := TMemSize(CtxHelper(Context).Size);
                      Result := SIIDEC_RESULT_SUCCESS;
                    end
                  else Result := SIIDEC_RESULT_BUFFER_TOO_SMALL;
                finally
                  CtxHelper(Context).Free;
                  PSIIDecContextInternal(Context)^.Helper := nil;
                end;
              end
            else  // helper stream not assigned, do complete decode...
              begin
                OutMemStream := TWritableStaticMemoryStream.Create(Output,OutSize^);
                try
                  Result := GetResultAsInt(CtxDecryptor(Context).DecodeStream(InMemStream,OutMemStream,True));
                  If Result = SIIDEC_RESULT_SUCCESS then
                    OutSize^ := TMemSize(OutMemStream.Position);
                finally
                  OutMemStream.Free;
                end;
              end;
          end
        else  // output not assigned, only get size...
          begin
            PSIIDecContextInternal(Context)^.Helper := TMemoryStream.Create;
            Result := GetResultAsInt(CtxDecryptor(Context).DecodeStream(InMemStream,CtxHelper(Context),False));
            If Result <> SIIDEC_RESULT_SUCCESS then
              begin
                CtxHelper(Context).Free;
                PSIIDecContextInternal(Context)^.Helper := nil;
              end
            else OutSize^ := TMemSize(CtxHelper(Context).Size);
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

Function Exp_Decryptor_DecodeFile(Context: TSIIDecContext; InputFile,OutputFile: PUTF8Char): Int32;
begin
try
  Result := GetResultAsInt(CtxDecryptor(Context).GetFileFormat(StrConv(InputFile)));
  If Result in [SIIDEC_RESULT_FORMAT_BINARY,SIIDEC_RESULT_FORMAT_3NK] then
    Result := GetResultAsInt(CtxDecryptor(Context).DecodeFile(StrConv(InputFile),StrConv(OutputFile)));
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_DecodeFileInMemory(Context: TSIIDecContext; InputFile,OutputFile: PUTF8Char): Int32;
begin
try
  Result := GetResultAsInt(CtxDecryptor(Context).GetFileFormat(StrConv(InputFile)));
  If Result in [SIIDEC_RESULT_FORMAT_BINARY,SIIDEC_RESULT_FORMAT_3NK] then
    Result := GetResultAsInt(CtxDecryptor(Context).DecodeFileInMemory(StrConv(InputFile),StrConv(OutputFile)));
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//==============================================================================

Function Exp_Decryptor_DecryptAndDecodeMemory(Context: TSIIDecContext; Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32;
var
  InMemStream:  TStaticMemoryStream;
  OutMemStream: TWritableStaticMemoryStream;
begin
try
  InMemStream := TStaticMemoryStream.Create(Input,InSize);
  try
    Result := GetResultAsInt(CtxDecryptor(Context).GetStreamFormat(InMemStream));
    If Result in [SIIDEC_RESULT_FORMAT_ENCRYPTED,SIIDEC_RESULT_FORMAT_BINARY,SIIDEC_RESULT_FORMAT_3NK] then
      begin
        If Assigned(Output) then
          begin
            If Assigned(CtxHelper(Context)) then
              begin
                // helper stream is assigned, only copy its content
                try
                  If OutSize^ >= CtxHelper(Context).Size then
                    begin
                      Move(CtxHelper(Context).Memory^,Output^,CtxHelper(Context).Size);
                      OutSize^ := TMemSize(CtxHelper(Context).Size);
                      Result := SIIDEC_RESULT_SUCCESS;
                    end
                  else Result := SIIDEC_RESULT_BUFFER_TOO_SMALL;
                finally
                  CtxHelper(Context).Free;
                  PSIIDecContextInternal(Context)^.Helper := nil;
                end;
              end
            else  // helper stream not assigned, do complete decrypt/decode...
              begin
                OutMemStream := TWritableStaticMemoryStream.Create(Output,OutSize^);
                try
                  Result := GetResultAsInt(CtxDecryptor(Context).DecryptAndDecodeStream(InMemStream,OutMemStream,True));
                  If Result = SIIDEC_RESULT_SUCCESS then
                    OutSize^ := TMemSize(OutMemStream.Position);
                finally
                  OutMemStream.Free;
                end;
              end;
          end
        else  // output not assigned, only get size...
          begin
            PSIIDecContextInternal(Context)^.Helper := TMemoryStream.Create;
            Result := GetResultAsInt(CtxDecryptor(Context).DecryptAndDecodeStream(InMemStream,CtxHelper(Context),False));
            If Result <> SIIDEC_RESULT_SUCCESS then
              begin
                CtxHelper(Context).Free;
                PSIIDecContextInternal(Context)^.Helper := nil;
              end
            else OutSize^ := TMemSize(CtxHelper(Context).Size);
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

Function Exp_Decryptor_DecryptAndDecodeFile(Context: TSIIDecContext; InputFile,OutputFile: PUTF8Char): Int32;
begin
try
  Result := GetResultAsInt(CtxDecryptor(Context).GetFileFormat(StrConv(InputFile)));
  If Result in [SIIDEC_RESULT_FORMAT_ENCRYPTED,SIIDEC_RESULT_FORMAT_BINARY,SIIDEC_RESULT_FORMAT_3NK] then
    Result := GetResultAsInt(CtxDecryptor(Context).DecryptAndDecodeFile(StrConv(InputFile),StrConv(OutputFile)))
except
  Result := SIIDEC_RESULT_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_Decryptor_DecryptAndDecodeFileInMemory(Context: TSIIDecContext; InputFile,OutputFile: PUTF8Char): Int32;
begin
try
  Result := GetResultAsInt(CtxDecryptor(Context).GetFileFormat(StrConv(InputFile)));
  If Result in [SIIDEC_RESULT_FORMAT_ENCRYPTED,SIIDEC_RESULT_FORMAT_BINARY,SIIDEC_RESULT_FORMAT_3NK] then
    Result := GetResultAsInt(CtxDecryptor(Context).DecryptAndDecodeFileInMemory(StrConv(InputFile),StrConv(OutputFile)))
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

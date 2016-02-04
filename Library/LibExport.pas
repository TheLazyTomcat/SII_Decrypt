{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit LibExport;

interface

implementation

uses
  AuxTypes, Decryptor, SII_DecryptLib;

//==============================================================================  

Function NumResultCode(SIIResult: TSIIResult): UInt32;
begin
case SIIResult of
  rSuccess:         Result := SIIDEC_SUCCESS;
  rNotEncrypted:    Result := SIIDEC_NOT_ENCRYPTED;
  rUnknownFormat:   Result := SIIDEC_UNKNOWN_FORMAT;
  rTooSmall:        Result := SIIDEC_TOO_SMALL;
  rBufferTooSmall:  Result := SIIDEC_BUFFER_TOO_SMALL;
else
 {rGenericError}
  Result := SIIDEC_GENERIC_ERROR;
end;
end;

//==============================================================================

Function Exp_IsEncryptedMemory(Mem: Pointer; Size: TMemSize): UInt32; stdcall;
begin
with TSIIDecryptor.Create do
  begin
    Result := NumResultCode(IsEncryptedMemory(Mem,Size));
    Free;
  end;
end;

//------------------------------------------------------------------------------

Function Exp_IsEncryptedFile(FileName: PAnsiChar): UInt32; stdcall;
begin
with TSIIDecryptor.Create do
  begin
    Result := NumResultCode(IsEncryptedFile(FileName));
    Free;
  end;
end;

//------------------------------------------------------------------------------

Function Exp_DecryptMemory(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): UInt32; stdcall;
begin
with TSIIDecryptor.Create do
  begin
    Result := NumResultCode(DecryptMemory(Input,InSize,Output,OutSize^));
    Free;
  end;
end;


//------------------------------------------------------------------------------

Function Exp_DecryptFile(InputFile: PAnsiChar; OutputFile: PAnsiChar): UInt32; stdcall;
begin
with TSIIDecryptor.Create do
  begin
    Result := NumResultCode(DecryptFile(InputFile,OutputFile));
    Free;
  end;
end;

//------------------------------------------------------------------------------

Function Exp_DecryptFile2(FileName: PAnsiChar): UInt32; stdcall;
begin
with TSIIDecryptor.Create do
  begin
    Result := NumResultCode(DecryptFile(FileName,FileName));
    Free;
  end;
end;

//==============================================================================

exports
  Exp_IsEncryptedMemory name 'IsEncryptedMemory',
  Exp_IsEncryptedFile   name 'IsEncryptedFile',
  Exp_DecryptMemory     name 'DecryptMemory',
  Exp_DecryptFile       name 'DecryptFile',
  Exp_DecryptFile2      name 'DecryptFile2';

end.

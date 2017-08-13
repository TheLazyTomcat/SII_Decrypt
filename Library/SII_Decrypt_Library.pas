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
  Classes, AuxTypes, StrRect, StaticMemoryStream,
  SII_Decrypt_Decryptor, SII_Decrypt_Header;

//==============================================================================

Function Exp_IsEncryptedMemory(Mem: Pointer; Size: TMemSize): Int32; stdcall;
var
  MemStream:  TStaticMemoryStream;
begin
try
  with TSII_Decryptor.Create(False) do
  try
    MemStream := TStaticMemoryStream.Create(Mem,Size);
    try
      Result := Ord(IsEncryptedSIIStream(MemStream));
    finally
      MemStream.Free;
    end;
  finally
    Free;
  end;
except
  Result := SIIDEC_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_IsEncryptedFile(FileName: PAnsiChar): Int32; stdcall;
begin
try
  with TSII_Decryptor.Create(False) do
  try
    Result := Ord(IsEncryptedSIIFile(UTF8ToStr(FileName)));
  finally
    Free;
  end;
except
  Result := SIIDEC_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_DecryptMemory(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): Int32; stdcall;
var
  MemStream:  TStaticMemoryStream;
  OutStream:  TMemoryStream;
  Header:     TSIIHeader;
begin
try
  with TSII_Decryptor.Create(False) do
  try
    MemStream := TStaticMemoryStream.Create(Input,InSize);
    try
      MemStream.ReadBuffer({%H-}Header,SizeOf(TSIIHeader));
      MemStream.Seek(0,soBeginning);
      If Assigned(Output) then
        begin
          OutStream := TMemoryStream.Create;
          try
            Result := Ord(DecryptStream(MemStream,OutStream));
            If Result = SIIDEC_SUCCESS then
              begin
                If OutSize^ >= TMemSize(OutStream.Size) then
                  begin
                    OutSize^ := TMemSize(OutStream.Size);
                    Move(OutStream.Memory^,Output^,OutSize^);
                  end
                else Result := SIIDEC_BUFFER_TOO_SMALL;
              end;
          finally
            OutStream.Free;
          end;
        end
      else
        begin
          OutSize^ := TMemSize(Header.DataSize);
          Result := SIIDEC_SUCCESS;
        end;
    finally
      MemStream.Free;
    end;
  finally
    Free;
  end;
except
  Result := SIIDEC_GENERIC_ERROR;
end;
end;


//------------------------------------------------------------------------------

Function Exp_DecryptFile(InputFile: PAnsiChar; OutputFile: PAnsiChar): Int32; stdcall;
begin
try
  with TSII_Decryptor.Create(False) do
  try
    Result := Ord(DecryptFile(UTF8ToStr(InputFile),UTF8ToStr(OutputFile)));
  finally
    Free;
  end;
except
  Result := SIIDEC_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_DecryptFile2(FileName: PAnsiChar): Int32; stdcall;
begin
try
  with TSII_Decryptor.Create(False) do
  try
    Result := Ord(DecryptFile(UTF8ToStr(FileName),UTF8ToStr(FileName)));
  finally
    Free;
  end;
except
  Result := SIIDEC_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_DecryptAndDecodeFile(InputFile: PAnsiChar; OutputFile: PAnsiChar): Int32; stdcall;
begin
try
  with TSII_Decryptor.Create(False) do
  try
    Result := Ord(DecryptAndDecodeFile(UTF8ToStr(InputFile),UTF8ToStr(OutputFile)));
  finally
    Free;
  end;
except
  Result := SIIDEC_GENERIC_ERROR;
end;
end;

//------------------------------------------------------------------------------

Function Exp_DecryptAndDecodeFile2(FileName: PAnsiChar): Int32; stdcall;
begin
try
  with TSII_Decryptor.Create(False) do
  try
    Result := Ord(DecryptAndDecodeFile(UTF8ToStr(FileName),UTF8ToStr(FileName)));
  finally
    Free;
  end;
except
  Result := SIIDEC_GENERIC_ERROR;
end;
end;

//==============================================================================

exports
  Exp_IsEncryptedMemory       name 'IsEncryptedMemory',
  Exp_IsEncryptedFile         name 'IsEncryptedFile',
  Exp_DecryptMemory           name 'DecryptMemory',
  Exp_DecryptFile             name 'DecryptFile',
  Exp_DecryptFile2            name 'DecryptFile2',
  Exp_DecryptAndDecodeFile    name 'DecryptAndDecodeFile',
  Exp_DecryptAndDecodeFile2   name 'DecryptAndDecodeFile2';

end.

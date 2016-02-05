{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_DecryptLib;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{.$DEFINE AutoLoad}

interface

{$IFNDEF IsLibrary}
uses
  AuxTypes;
{$ENDIF IsLibrary}

const
  SIIDEC_SUCCESS          = 0;
  SIIDEC_NOT_ENCRYPTED    = 1;
  SIIDEC_UNKNOWN_FORMAT   = 2;
  SIIDEC_TOO_SMALL        = 3;
  SIIDEC_BUFFER_TOO_SMALL = 4;
  SIIDEC_GENERIC_ERROR    = 5;

  SIIDecrypt_LibFileName = 'SII_Decrypt.dll';

//------------------------------------------------------------------------------
     
{$IFNDEF IsLibrary}
{$IFDEF AutoLoad}

Function IsEncryptedMemory(Mem: Pointer; Size: TMemSize): UInt32; stdcall; external SIIDecrypt_LibFileName;
Function IsEncryptedFile(FileName: PAnsiChar): UInt32; stdcall; external SIIDecrypt_LibFileName;

Function DecryptMemory(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): UInt32; stdcall; external SIIDecrypt_LibFileName;
Function DecryptFile(InputFile: PAnsiChar; OutputFile: PAnsiChar): UInt32; stdcall; external SIIDecrypt_LibFileName;
Function DecryptFile2(FileName: PAnsiChar): UInt32; stdcall; external SIIDecrypt_LibFileName;

{$ELSE AutoLoad}

var
  IsEncryptedMemory: Function(Mem: Pointer; Size: TMemSize): UInt32; stdcall;
  IsEncryptedFile:   Function (FileName: PAnsiChar): UInt32; stdcall;

  DecryptMemory: Function(Input: Pointer; InSize: TMemSize; Output: Pointer; OutSize: PMemSize): UInt32; stdcall;
  DecryptFile:   Function(InputFile: PAnsiChar; OutputFile: PAnsiChar): UInt32; stdcall;
  DecryptFile2:  Function(FileName: PAnsiChar): UInt32; stdcall;

//------------------------------------------------------------------------------

procedure Load_SII_Decrypt(const LibraryFile: String = 'SII_Decrypt.dll');
procedure Unload_SII_Decrypt;

{$ENDIF AutoLoad}
{$ENDIF IsLibrary}

implementation
      
{$IF not Defined(IsLibrary) and not Defined(AutoLoad)}

uses
  SysUtils, Windows;

var
  LibHandle:  HMODULE;

procedure Load_SII_Decrypt(const LibraryFile: String = 'SII_Decrypt.dll');
begin
If LibHandle = 0 then
  begin
    LibHandle := LoadLibrary(PChar(LibraryFile));
    If LibHandle <> 0 then
      begin
        IsEncryptedMemory := GetProcAddress(LibHandle,'IsEncryptedMemory');
        IsEncryptedFile   := GetProcAddress(LibHandle,'IsEncryptedFile');
        DecryptMemory     := GetProcAddress(LibHandle,'DecryptMemory');
        DecryptFile       := GetProcAddress(LibHandle,'DecryptFile');
        DecryptFile2      := GetProcAddress(LibHandle,'DecryptFile2');
      end
    else raise Exception.CreateFmt('Unable to load library %s.',[LibraryFile]);
  end;
end;

//------------------------------------------------------------------------------

procedure Unload_SII_Decrypt;
begin
If LibHandle <> 0 then
  FreeLibrary(LibHandle);
LibHandle := 0;
end;
{$IFEND}

end.

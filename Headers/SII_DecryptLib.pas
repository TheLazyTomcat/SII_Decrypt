{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_DecryptLib;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{
  When AutoLoad symbol is defined, all imports are resolved automatically at
  the program initialization.
  When not defined, you have to call procedure Load_SII_Decrypt before using
  any library function. You also have to call Unload_SII_Decrypt when you stop
  using the library.
}
{.$DEFINE AutoLoad}

interface

uses
  AuxTypes; // provides types that are not guaranteed to be present in all compilers

{
  Types used in this unit (in case anyone will be translating this unit to other
  languages):

    Pointer   - general, non-typed pointer
    TMemSize  - unsigned integer the size of pointer (8 bytes on 64bit system,
                4 bytes on 32bit system)
    UInt32    - unsigned 32bit integer
    PAnsiChar - pointer to first character of ansi-encoded, null-terminated
                string
    PMemSize  - Pointer to an unsigned pointer-sized integer
}

const
{
  Following are all possible values any imported function can return.
  For meaning of individual values, refer to description of functions that
  returns them.
  If any function returns value that is not listed here, you should take it as
  if it returned SIIDEC_GENERIC_ERROR.
}
  SIIDEC_SUCCESS          = 0;
  SIIDEC_NOT_ENCRYPTED    = 1;
  SIIDEC_UNKNOWN_FORMAT   = 2;
  SIIDEC_TOO_SMALL        = 3;
  SIIDEC_BUFFER_TOO_SMALL = 4;
  SIIDEC_GENERIC_ERROR    = 5;

{
  Default file name of the dynamically loaded library (DLL).
}
  SIIDecrypt_LibFileName = 'SII_Decrypt.dll';

//------------------------------------------------------------------------------

{
IsEncryptedMemory

  Checks whether passed memory contains encrypted SII file.
  The memory is not completely scanned, the library only checks if size is large
  enough to contain valid SII file header and first four bytes are equal to
  encrypted SII file signature.

  Parameters:

    Mem  - Pointer to a memory block that should be checked
    Size - Size of the memory block in bytes

  Returns:
    SIIDEC_SUCCESS          - passed memory contains encrypted SII file
                              (size >= size of encrypted SII header, first four
                              bytes are equal to 0x43736353)
    SIIDEC_NOT_ENCRYPTED    - passed memory contains not encrypted SII file
                              (size >= size of encrypted SII header, first four
                              bytes are equal to 0x4e696953)
    SIIDEC_UNKNOWN_FORMAT   - passed memory contains data of unknown format
                              (size >= size of encrypted SII header, first four
                              bytes are not equal to 0x43736353 or 0x4e696953)
    SIIDEC_TOO_SMALL        - passed memory block is too small to contain
                              encrypted SII file header
    SIIDEC_BUFFER_TOO_SMALL - not returned by this function
    SIIDEC_GENERIC_ERROR    - unhandled exception occured

 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

IsEncryptedFile

  Checks whether file given by the passed file name contains encrypted SII file.
  It is recommended that you pass full path, but it is possible to pass only
  relative path.
  The file is not completely scanned, the library only checks if size of the
  file is large enough to contain valid SII file header and first four bytes are
  equal to encrypted SII file signature.

  Parameters:

    FileName - path to the file that should be checked

  Returns:
    SIIDEC_SUCCESS          - file contains encrypted SII file
                              (size of the file >= size of encrypted SII header,
                              first four bytes are equal to 0x43736353)
    SIIDEC_NOT_ENCRYPTED    - file contains not encrypted SII file
                              (size of the file >= size of encrypted SII header,
                              first four bytes are equal to 0x4e696953)
    SIIDEC_UNKNOWN_FORMAT   - file contains data of unknown format
                              (size of the file >= size of encrypted SII header,
                              first four bytes are not equal to 0x43736353 or
                              0x4e696953)
    SIIDEC_TOO_SMALL        - file is too small to contain complete encrypted
                              SII file header
    SIIDEC_BUFFER_TOO_SMALL - not returned by this function
    SIIDEC_GENERIC_ERROR    - unhandled exception occured

 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DecryptMemory

  Decrypts memory block given by the Input parameter and stores decrypted data
  to a memory given by Output parameter.
  To properly use this function, do following:

    - call this function with parameter Output set to nil (null/0), variable
      pointed to by OutSize pointer can contain any value
    - if the function returns SIIDEC_SUCCESS, then minimal size of output buffer
      is stored in a variable pointed to by pointer passed in parameter OutSize,
      otherwise stop here and do not continue with next step
    - use returned min. size of output buffer to allocate buffer for the next
      step
    - call this function again, this time with Output set to a buffer allocated
      in previous step and value of variable pointed to by pointer passed in
      OutSize set to a size of the allocated output buffer
    - if the function returns SIIDEC_SUCCESS, then true size of decrypted data
      will be stored to a variable pointed to by pointer passed in parameter
      OutSize and decrypted data will be stored to buffer passed in Output
      parameter, otherwise nothing is stored in any output

  Parameters:

    Input   - pointer to a memory block containing input data (encrypted SII
              file)
    InSize  - size of the input data in bytes
    Output  - pointer to buffer that will receive decrypted data
    OutSize - pointer to a variable holding size of the output buffer, holds
              true size of the decryted data on return (in bytes)

    SIIDEC_SUCCESS          - input data were successfully decrypted and result
                              stored in output buffer
    SIIDEC_NOT_ENCRYPTED    - input data contains not encrypted SII file
    SIIDEC_UNKNOWN_FORMAT   - input data contains data of unknown format
    SIIDEC_TOO_SMALL        - input data are too small to contain complete
                              encrypted SII file header
    SIIDEC_BUFFER_TOO_SMALL - size of the output buffer given in OutSize is too
                              small to store decrypted data
    SIIDEC_GENERIC_ERROR    - unhandled exception occured

 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DecryptFile

  Decrypts file given by a path in Input parameter and stores decrypted result
  in a file give by a path in Output parameter.
  It is recommended to pass full file paths, but relative paths are acceptable.
  Folder, where the destination file will be stored, must exists prior of
  calling this function, otherwise it fails with SIIDEC_GENERIC_ERROR.

  Parameters:

    Input  - path to the source file (encrypted SII file)
    Output - path to the destination file (where decrypted result should be
             stored)

  Returns:
    SIIDEC_SUCCESS          - input file was successfully decrypted and result
                              stored in output file
    SIIDEC_NOT_ENCRYPTED    - input file contains not encrypted SII file
    SIIDEC_UNKNOWN_FORMAT   - input file contains data of unknown format
    SIIDEC_TOO_SMALL        - input file is too small to contain complete
                              encrypted SII file header
    SIIDEC_BUFFER_TOO_SMALL - not returned by this function
    SIIDEC_GENERIC_ERROR    - unhandled exception occured

 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DecryptFile2

  Decrypts file given by a path in FileName parameter and stores decrypted
  result back in the same file.
  It is recommended to pass full file path, but relative path is acceptable.

  Parameters:

    FileName  - path to a file to be processed (encrypted SII file)

  Returns:
    SIIDEC_SUCCESS          - file was successfully decrypted and result
                              stored
    SIIDEC_NOT_ENCRYPTED    - file contains not encrypted SII file
    SIIDEC_UNKNOWN_FORMAT   - file contains data of unknown format
    SIIDEC_TOO_SMALL        - file is too small to contain complete encrypted
                              SII file header
    SIIDEC_BUFFER_TOO_SMALL - not returned by this function
    SIIDEC_GENERIC_ERROR    - unhandled exception occured
}

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

// Call this routine to initialize (load) the dynamic library.
procedure Load_SII_Decrypt(const LibraryFile: String = 'SII_Decrypt.dll');

// Call this routine to free (unload) the dynamic library.
procedure Unload_SII_Decrypt;

{$ENDIF AutoLoad}

implementation
      
{$IFNDEF AutoLoad}

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

{$ENDIF AutoLoad}

end.

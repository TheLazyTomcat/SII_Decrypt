{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit Decryptor;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Classes,
  AuxTypes, AES;

{==============================================================================}
{------------------------------------------------------------------------------}
{                                TSIIDecryptor                                 }
{------------------------------------------------------------------------------}
{==============================================================================}
const
{
  This key was taken from a "Savegame Decrypter" utility made by user
  JohnnyGuitar. You can find more info here:
  http://forum.scssoft.com/viewtopic.php?f=34&t=164103#p280580
}
  SII_Key: array[0..31] of Byte = (
    $2a, $5f, $cb, $17, $91, $d2, $2f, $b6, $02, $45, $b3, $d8, $36, $9e, $d0, $b2,
    $c2, $73, $71, $56, $3f, $bf, $1f, $3c, $9e, $df, $6b, $11, $82, $5a, $5d, $0a);

  SII_Encrypted_Signature = $43736353; {ScsC}
  SII_Normal_Signature    = $4e696953; {SiiN}

type
  TSIIHeader = packed record
    Signature:  UInt32;
    HMAC:       array[0..31] of Byte;
    InitVector: array[0..15] of Byte;
    DataSize:   UInt32;
  end;
  PSIIHeader = ^TSIIHeader;

  TSIIResult = (rSuccess,rNotEncrypted,rUnknownFormat,rTooSmall,rBufferTooSmall,rGenericError);

{==============================================================================}
{------------------------------------------------------------------------------}
{                                TSIIDecryptor                                 }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TSIIDecryptor - declaration                                                }
{==============================================================================}
  TSIIDecryptor = class(TAESCipher)
  private
    fReraiseExceptions: Boolean;
  public
    constructor Create; override;
    Function IsEncryptedMemory(Mem: Pointer; Size: TMemSize): TSIIResult; virtual;
    Function IsEncryptedStream(Stream: TSTream): TSIIResult; virtual;
    Function IsEncryptedFile(const FileName: String): TSIIResult; virtual;
    Function DecryptMemory(Input: Pointer; InputSize: TMemSize; Output: Pointer; var OutputSize: TMemSize): TSIIResult; virtual;
    Function DecryptStream(Input, Output: TStream): TSIIResult; virtual;
    Function DecryptFile(const Input, Output: String): TSiiResult; virtual;
  published
    property ReraiseExceptions: Boolean read fReraiseExceptions write fReraiseExceptions; 
  end;

implementation

uses
  SysUtils,{$IFDEF FPC} PasZLib{$ELSE} ZLib{$ENDIF};

{==============================================================================}
{   TSIIDecryptor - initialization                                             }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TSIIDecryptor - public methods                                             }
{------------------------------------------------------------------------------}

constructor TSIIDecryptor.Create;
begin
inherited Create;
fReraiseExceptions := True;
end;

//------------------------------------------------------------------------------

Function TSIIDecryptor.IsEncryptedMemory(Mem: Pointer; Size: TMemSize): TSIIResult;
begin
try
  If Size >= SizeOf(TSIIHeader) then
    case PSIIHeader(Mem)^.Signature of
      SII_Encrypted_Signature:  Result := rSuccess;
      SII_Normal_Signature:     Result := rNotEncrypted;
    else
      Result := rUnknownFormat;
    end
  else Result := rTooSmall;
except
  Result := rGenericError;
  If fReraiseExceptions then raise;
end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TSIIDecryptor.IsEncryptedStream(Stream: TSTream): TSIIResult;
var
  Header: TSIIHeader;
begin
try
  If Stream.Size >= SizeOf(TSIIHeader) then
    begin
      Stream.Seek(0,soFromBeginning);
      Stream.ReadBuffer({%H-}Header,SizeOf(TSIIHeader));
      case Header.Signature of
        SII_Encrypted_Signature:  Result := rSuccess;
        SII_Normal_Signature:     Result := rNotEncrypted;
      else
        Result := rUnknownFormat;
      end;
    end
  else Result := rTooSmall;
except
  Result := rGenericError;
  If fReraiseExceptions then raise;
end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TSIIDecryptor.IsEncryptedFile(const FileName: String): TSIIResult;
var
  FileStream: TFileStream;
begin
try
  FileStream := TFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite);
  try
    Result := IsEncryptedStream(FileStream);
  finally
    FileStream.Free;
  end;
except
  Result := rGenericError;
  If fReraiseExceptions then raise;
end;
end;

//------------------------------------------------------------------------------

Function TSIIDecryptor.DecryptMemory(Input: Pointer; InputSize: TMemSize; Output: Pointer; var OutputSize: TMemSize): TSIIResult;
var
  Header:     TSIIHeader;
  Decrypted:  Pointer;
  OutData:    Pointer;
{$IFDEF FPC}
  OutSize:    LongWord;
{$ELSE}
  OutSize:    Integer;
{$ENDIF}
begin
try
  Result := IsEncryptedMemory(Input,InputSize);
  If Result = rSuccess then
    If Assigned(Output) then
      begin
        Header := PSIIHeader(Input)^;
        Init(SII_Key,Header.InitVector,r256bit,cmDecrypt);
        ModeOfOperation := moCBC;
        GetMem(Decrypted,InputSize - TMemSize(SizeOf(TSIIHeader)));
        try
          ProcessBytes({%H-}Pointer({%H-}PtrUInt(Input) + PtrUInt(SizeOf(TSIIHeader)))^,InputSize - TMemSize(SizeOf(TSIIHeader)),Decrypted^);
        {$IFDEF FPC}
          OutSize := LongWord(Header.DataSize);
          GetMem(OutData,Header.DataSize);
          try
            If Uncompress(OutData,OutSize,Decrypted,InputSize - TMemSize(SizeOf(TSIIHeader))) <> Z_OK then
              raise Exception.Create('Decompression error.');
        {$ELSE}
          DecompressBuf(Decrypted,InputSize - TMemSize(SizeOf(TSIIHeader)),PSIIHeader(Input)^.DataSize,OutData,OutSize);
          try
        {$ENDIF}
            If OutputSize >= TMemSize(OutSize) then
              begin
                Move(OutData^,Output^,OutSize);
                OutputSize := TMemSize(OutSize);
              end
            else Result := rBufferTooSmall;
          finally
            FreeMem(OutData,Header.DataSize);
          end;
        finally
          FreeMem(Decrypted,InputSize - TMemSize(SizeOf(TSIIHeader)));
        end;
      end
    else OutputSize := TMemSize(PSIIHeader(Input)^.DataSize);
except
  Result := rGenericError;
  If fReraiseExceptions then raise;
end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TSIIDecryptor.DecryptStream(Input, Output: TStream): TSIIResult;
var
  Header:     TSIIHeader;
  TempStream: TMemoryStream;

  procedure DecompressAndSave;
  var
    OutData:  Pointer;
  {$IFDEF FPC}
    OutSize:  LongWord;
  {$ELSE}
    OutSize:  Integer;
  {$ENDIF}
  begin
  {$IFDEF FPC}
    OutSize := LongWord(Header.DataSize);
    GetMem(OutData,Header.DataSize);
    try
      If Uncompress(OutData,OutSize,TempStream.Memory,TempStream.Size) <> Z_OK then
        raise Exception.Create('Decompression error.');
  {$ELSE}
    DecompressBuf(TempStream.Memory,TempStream.Size,Header.DataSize,OutData,OutSize);
    try
  {$ENDIF}
      Output.Position := 0;
      Output.WriteBuffer(OutData^,OutSize);
      Output.Size := Header.DataSize;
    finally
      FreeMem(OutData,Header.DataSize);
    end;
  end;

begin
try
  Result := IsEncryptedStream(Input);
  If Result = rSuccess then
    begin
      Input.Seek(0,soFromBeginning);
      Input.ReadBuffer({%H-}Header,SizeOf(TSIIHeader));
      Init(SII_Key,Header.InitVector,r256bit,cmDecrypt);
      ModeOfOperation := moCBC;
      TempStream := TMemoryStream.Create;
      try
        ProcessStream(Input,TempStream);
        DecompressAndSave;
      finally
        TempStream.Free;
      end;
      Result := rSuccess;
    end;
except
  Result := rGenericError;
  If fReraiseExceptions then raise;
end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TSIIDecryptor.DecryptFile(const Input, Output: String): TSIIResult;
var
  InputStream:  TFileStream;
  OutputStream: TFileStream;
begin
try
  If AnsiSameText(Input,Output) then
    begin
      InputStream := TFileStream.Create(Input,fmOpenReadWrite or fmShareExclusive);
      try
        Result := DecryptStream(InputStream,InputStream);
      finally
        InputStream.Free;
      end;
    end
  else
    begin
      InputStream := TFileStream.Create(Input,fmOpenRead or fmShareDenyWrite);
      try
        OutputStream := TFileStream.Create(Output,fmCreate or fmShareExclusive);
        try
          Result := DecryptStream(InputStream,OutputStream);
        finally
          OutputStream.Free;
        end;
      finally
        InputStream.Free;
      end;
    end;
except
  Result := rGenericError;
  If fReraiseExceptions then raise;
end;
end;

end.

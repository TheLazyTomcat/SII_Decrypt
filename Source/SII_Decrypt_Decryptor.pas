{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decrypt_Decryptor;

{$INCLUDE '.\SII_Decrypt_defs.inc'}

interface

uses
  Classes,
  AuxTypes, AES;

{==============================================================================}
{------------------------------------------------------------------------------}
{                                TSII_Decryptor                                }
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

  SII_Signature_Encrypted = UInt32($43736353);  {ScsC}
  SII_Signature_Normal    = UInt32($4e696953);  {SiiN}
  SII_Signature_Binary    = UInt32($49495342);  {BSII}

type
  TSIIHeader = packed record
    Signature:  UInt32;
    HMAC:       array[0..31] of Byte;
    InitVector: array[0..15] of Byte;
    DataSize:   UInt32;
  end;
  PSIIHeader = ^TSIIHeader;

  TSIIResult = (rGenericError = -1, rSuccess = 0, rNotEncrypted = 1,
                rBinaryFormat = 2, rUnknownFormat = 3,rTooFewData = 4,
                rBufferTooSmall = 5);

{==============================================================================}
{   TSII_Decryptor - declaration                                               }
{==============================================================================}
  TSII_Decryptor = class(TAESCipherAccelerated)
  private
    fReraiseExceptions: Boolean;
  public
    constructor Create(ReraiseException: Boolean);
    Function IsEncryptedSIIStream(Stream: TSTream): TSIIResult; virtual;
    Function IsEncryptedSIIFile(const FileName: String): TSIIResult; virtual;
    Function DecryptStream(Input, Output: TStream): TSIIResult; virtual;
    Function DecryptFile(const Input, Output: String): TSIIResult; virtual;
    Function DecryptAndDecodeStream(Input, Output: TStream): TSIIResult; virtual;
    Function DecryptAndDecodeFile(const Input, Output: String): TSIIResult; virtual;
  published
    property ReraiseExceptions: Boolean read fReraiseExceptions write fReraiseExceptions; 
  end;

implementation

uses
  SysUtils, StrRect, ZLibCommon, ZLibStatic, SII_Decode_Decoder
{$IFDEF FPC_NonUnicode_NoUTF8RTL}
  , LazFileUtils
{$ENDIF};

{==============================================================================}
{   TSII_Decryptor - implementation                                            }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TSII_Decryptor - public methods                                            }
{------------------------------------------------------------------------------}

constructor TSII_Decryptor.Create(ReraiseException: Boolean);
begin
inherited Create;
fReraiseExceptions := ReraiseException;
end;

//------------------------------------------------------------------------------

Function TSII_Decryptor.IsEncryptedSIIStream(Stream: TSTream): TSIIResult;
var
  OldPos: Int64;
  Header: TSIIHeader;
begin
try
  If (Stream.Size - Stream.Position) >= SizeOf(TSIIHeader) then
    begin
      OldPos := Stream.Position;
      try
        Stream.ReadBuffer({%H-}Header,SizeOf(TSIIHeader));
        case Header.Signature of
          SII_Signature_Encrypted:  Result := rSuccess;
          SII_Signature_Normal:     Result := rNotEncrypted;
          SII_Signature_Binary:     Result := rBinaryFormat;
        else
          Result := rUnknownFormat;
        end;
      finally
        Stream.Position := OldPos;
      end;
    end
  else Result := rTooFewData;
except
  Result := rGenericError;
  If fReraiseExceptions then raise;
end;
end;

//------------------------------------------------------------------------------

Function TSII_Decryptor.IsEncryptedSIIFile(const FileName: String): TSIIResult;
var
  FileStream: TFileStream;
begin
try
  FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
  try
    Result := IsEncryptedSIIStream(FileStream);
  finally
    FileStream.Free;
  end;
except
  Result := rGenericError;
  If fReraiseExceptions then raise;
end;
end;

//------------------------------------------------------------------------------

Function TSII_Decryptor.DecryptStream(Input, Output: TStream): TSIIResult;
var
  Header:     TSIIHeader;
  TempStream: TMemoryStream;
  DecompBuf:  Pointer;
  DecompSize: uLong;
begin
try
  Result := IsEncryptedSIIStream(Input);
  If Result = rSuccess then
    begin
      Input.ReadBuffer({%H-}Header,SizeOf(TSIIHeader));
      Init(SII_Key,Header.InitVector,r256bit,cmDecrypt);
      ModeOfOperation := moCBC;
      TempStream := TMemoryStream.Create;
      try
        ProcessStream(Input,TempStream);
        DecompSize := uLong(Header.DataSize);
        GetMem(DecompBuf,Header.DataSize);
        try
          If uncompress(DecompBuf,@DecompSize,TempStream.Memory,uLong(TempStream.Size)) <> Z_OK then
            raise Exception.Create('Decompression error.');
          Output.Seek(0,soBeginning);
          Output.WriteBuffer(DecompBuf^,DecompSize);
          Output.Size := Output.Position;
        finally
          FreeMem(DecompBuf,Header.DataSize)
        end;
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

//------------------------------------------------------------------------------

Function TSII_Decryptor.DecryptFile(const Input, Output: String): TSIIResult;
var
  InputStream:  TFileStream;
  OutputStream: TFileStream;
begin
try
{$IFDEF FPC_NonUnicode_NoUTF8RTL}
  If AnsiSameText(ExpandFileNameUTF8(Input),ExpandFileNameUTF8(Output)) then
{$ELSE}
  If AnsiSameText(ExpandFileName(Input),ExpandFileName(Output)) then
{$ENDIF}
    begin
      InputStream := TFileStream.Create(StrToRTL(Input),fmOpenReadWrite or fmShareExclusive);
      try
        Result := DecryptStream(InputStream,InputStream);
      finally
        InputStream.Free;
      end;
    end
  else
    begin
      InputStream := TFileStream.Create(StrToRTL(Input),fmOpenRead or fmShareDenyWrite);
      try
        OutputStream := TFileStream.Create(StrToRTL(Output),fmCreate or fmShareExclusive);
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

//------------------------------------------------------------------------------

Function TSII_Decryptor.DecryptAndDecodeStream(Input, Output: TStream): TSIIResult;
var
  TempStream: TMemoryStream;
  Decoder:    TSIIBin_Decoder;
  TextResult: TStringList;
begin
try
  TempStream := TMemoryStream.Create;
  try
    Result :=  IsEncryptedSIIStream(Input);
    case Result of
      rSuccess:       //  --  --  --  --  --  --  --  --  --  --  --  --  --  --
        begin
          Result := DecryptStream(Input,TempStream);
          If Result = rSuccess then
            begin
              TempStream.Seek(0,soBeginning);
              If TSIIBin_Decoder.IsBinarySIIStream(TempStream) then
                begin
                  Decoder := TSIIBin_Decoder.Create;
                  try
                    Decoder.LoadFromStream(TempStream);
                    TextResult := TStringList.Create;
                    try
                      Decoder.Convert(TextResult);
                      Output.Seek(0,soBeginning);
                      TextResult.SaveToStream(Output);
                      Output.Size := Output.Position;
                    finally
                      TextResult.Free;
                    end;
                  finally
                    Decoder.Free;
                  end;
                end
              else
                begin
                  Output.Seek(0,soBeginning);
                  Output.CopyFrom(TempStream,0);
                  Output.Size := TempStream.Size;
                end;
            end;
        end;
        
      rBinaryFormat:  //  --  --  --  --  --  --  --  --  --  --  --  --  --  --
        begin
          Decoder := TSIIBin_Decoder.Create;
          try
            Decoder.LoadFromStream(Input);
            TextResult := TStringList.Create;
            try
              WriteLn(Decoder.DataBlockCount);
              Decoder.Convert(TextResult);
              Output.Seek(0,soBeginning);
              TextResult.SaveToStream(Output);
              Output.Size := Output.Position;
            finally
              TextResult.Free;
            end;
          finally
            Decoder.Free;
          end;
        end;
    end;
  finally
    TempStream.Free;
  end;
except
  Result := rGenericError;
  If fReraiseExceptions then raise;
end;
end;

//------------------------------------------------------------------------------

Function TSII_Decryptor.DecryptAndDecodeFile(const Input, Output: String): TSIIResult;
var
  InputStream:  TFileStream;
  OutputStream: TFileStream;
begin
try
{$IFDEF FPC_NonUnicode_NoUTF8RTL}
  If AnsiSameText(ExpandFileNameUTF8(Input),ExpandFileNameUTF8(Output)) then
{$ELSE}
  If AnsiSameText(ExpandFileName(Input),ExpandFileName(Output)) then
{$ENDIF}
    begin
      InputStream := TFileStream.Create(StrToRTL(Input),fmOpenReadWrite or fmShareExclusive);
      try
        Result := DecryptAndDecodeStream(InputStream,InputStream);
      finally
        InputStream.Free;
      end;
    end
  else
    begin
      InputStream := TFileStream.Create(StrToRTL(Input),fmOpenRead or fmShareDenyWrite);
      try
        OutputStream := TFileStream.Create(StrToRTL(Output),fmCreate or fmShareExclusive);
        try
          Result := DecryptAndDecodeStream(InputStream,OutputStream);
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

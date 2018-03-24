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
  AuxTypes, AES, ProgressTracker;

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
  SII_Signature_3nK       = UInt32($014B6E33);  {3nK#01}

type
  TSIIHeader = packed record
    Signature:  UInt32;
    HMAC:       array[0..31] of Byte;
    InitVector: array[0..15] of Byte;
    DataSize:   UInt32;
  end;
  PSIIHeader = ^TSIIHeader;

  TSIIResult = (rGenericError   = -1,
                rSuccess        = 0,
                rNotEncrypted   = 1,
                rBinaryFormat   = 2,
                rUnknownFormat  = 3,
                rTooFewData     = 4,
                rBufferTooSmall = 5,
                r3nKFormat      = 6);

{==============================================================================}
{   TSII_Decryptor - declaration                                               }
{==============================================================================}
const
  SII_PRGS_STAGEID_DECRYPT = 0;
  SII_PRGS_STAGEID_DECODE  = 1;

  SII_PRGS_STAGELEN_DECRYPT = 10;
  SII_PRGS_STAGELEN_DECODE  = 90;

type
  TSII_ProgressEvent    = procedure(Sender: TObject; Progress: Single) of object;
  TSII_ProgressCallback = procedure(Sender: TObject; Progress: Single);

  TSII_Decryptor = class(TObject)
  private
    fReraiseExceptions:   Boolean;
    fAcceleratedAES:      Boolean;
    fProgressTracker:     TProgressTracker;
    fReportProgress:      Boolean;
    fOnProgressEvent:     TSII_ProgressEvent;
    fOnProgressCallback:  TSII_ProgressCallback;
  protected
    procedure DoProgress(Sender: TObject; Progress: Single); virtual;
    procedure DecryptProgressHandler(Sender: TObject; Progress: Single); virtual;
    procedure DecodeProgressHandler(Sender: TObject; Progress: Single); virtual;
    procedure DecryptStreamInternal(Input: TStream; Temp: TMemoryStream; const Header: TSIIHeader); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    Function GetStreamFormat(Stream: TSTream): TSIIResult; virtual;
    Function GetFileFormat(const FileName: String): TSIIResult; virtual;
    Function IsEncryptedSIIStream(Stream: TSTream): Boolean; virtual;
    Function IsEncryptedSIIFile(const FileName: String): Boolean; virtual;
    Function IsEncodedSIIStream(Stream: TSTream): Boolean; virtual;
    Function IsEncodedSIIFile(const FileName: String): Boolean; virtual;
    Function Is3nKSIIStream(Stream: TSTream): Boolean; virtual;
    Function Is3nKSIIFile(const FileName: String): Boolean; virtual;
    Function DecryptStream(Input, Output: TStream; InvariantOutput: Boolean = False): TSIIResult; virtual;
    Function DecryptFile(const Input, Output: String): TSIIResult; virtual;
    Function DecryptFileInMemory(const Input, Output: String): TSIIResult; virtual;
    Function DecodeStream(Input, Output: TStream; InvariantOutput: Boolean = False): TSIIResult; virtual;
    Function DecodeFile(const Input, Output: String): TSIIResult; virtual;
    Function DecodeFileInMemory(const Input, Output: String): TSIIResult; virtual;
    Function DecryptAndDecodeStream(Input, Output: TStream; InvariantOutput: Boolean = False): TSIIResult; virtual;
    Function DecryptAndDecodeFile(const Input, Output: String): TSIIResult; virtual;
    Function DecryptAndDecodeFileInMemory(const Input, Output: String): TSIIResult; virtual;
    property OnProgressCallback: TSII_ProgressCallback read fOnProgressCallback write fOnProgressCallback;    
  published
    property ReraiseExceptions: Boolean read fReraiseExceptions write fReraiseExceptions;
    property AcceleratedAES: Boolean read fAcceleratedAES write fAcceleratedAES;
    property OnProgressEvent: TSII_ProgressEvent read fOnProgressEvent write fOnProgressEvent;
    property OnProgress: TSII_ProgressEvent read fOnProgressEvent write fOnProgressEvent;
  end;
  
{==============================================================================}
{   Auxiliary functions                                                        }
{==============================================================================}

Function GetResultAsText(ResultCode: TSIIResult): String;  

implementation

uses
  SysUtils, StrRect, BinaryStreaming, ExplicitStringLists, SII_Decode_Decoder,
  SII_3nK_Transcoder, ZLibCommon, ZLibStatic
{$IFDEF FPC_NonUnicode_NoUTF8RTL}
  , LazFileUtils
{$ENDIF};

{==============================================================================}
{   Auxiliary functions                                                        }
{==============================================================================}

Function ExpandFileName(const Path: String): String;
begin
{$IFDEF FPC_NonUnicode_NoUTF8RTL}
  Result := LazFileUtils.ExpandFileNameUTF8(Path);
{$ELSE}
  Result := SysUtils.ExpandFileName(Path);
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function GetResultAsText(ResultCode: TSIIResult): String;
begin
case ResultCode of
  rSuccess:         Result := 'Success';
  rNotEncrypted:    Result := 'Data contain a plain-text SII';
  rBinaryFormat:    Result := 'Data contain a binary SII';
  rUnknownFormat:   Result := 'Data are in an unknown format';
  rTooFewData:      Result := 'Too few data to contain a valid format';
  rBufferTooSmall:  Result := 'Buffer is too small';
  r3nKFormat:       Result := 'Data contain a 3nK format';
else
  {rGenericError}
  Result := 'Generic error';
end;
end;

{==============================================================================}
{   TSII_Decryptor - implementation                                            }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TSII_Decryptor - protected methods                                         }
{------------------------------------------------------------------------------}

procedure TSII_Decryptor.DoProgress(Sender: TObject; Progress: Single);
begin
If fReportProgress then
  begin
    If Assigned(fOnProgressEvent) then
      fOnProgressEvent(Self,Progress);
    If Assigned(fOnProgressCallback) then
      fOnProgressCallback(Self,Progress);
  end;
end;

//------------------------------------------------------------------------------

procedure TSII_Decryptor.DecryptProgressHandler(Sender: TObject; Progress: Single);
begin
fProgressTracker.SetStageIDProgress(SII_PRGS_STAGEID_DECRYPT,Progress);
end;

//------------------------------------------------------------------------------

procedure TSII_Decryptor.DecodeProgressHandler(Sender: TObject; Progress: Single);
begin
fProgressTracker.SetStageIDProgress(SII_PRGS_STAGEID_DECODE,Progress);
end;

//------------------------------------------------------------------------------

procedure TSII_Decryptor.DecryptStreamInternal(Input: TStream; Temp: TMemoryStream; const Header: TSIIHeader);
var
  AESDec:     TAESCipher;
  DecompBuf:  Pointer;
  DecompSize: uLong;
begin
If fAcceleratedAES then
  AESDec := TAESCipherAccelerated.Create(SII_Key,Header.InitVector,r256bit,cmDecrypt)
else
  AESDec := TAESCipher.Create(SII_Key,Header.InitVector,r256bit,cmDecrypt);
try
  AESDec.OnProgress := DecryptProgressHandler;
  Temp.Seek(0,soBeginning);
  AESDec.ModeOfOperation := moCBC;
  AESDec.ProcessStream(Input,Temp);
  DecompSize := uLong(Header.DataSize);
  GetMem(DecompBuf,DecompSize);
  try
    If uncompress(DecompBuf,@DecompSize,Temp.Memory,uLong(Temp.Size)) <> Z_OK then
      raise Exception.Create('Decompression error.');
    Temp.Seek(0,soBeginning);
    Temp.WriteBuffer(DecompBuf^,DecompSize);
    Temp.Size := Temp.Position;
  finally
    FreeMem(DecompBuf,Header.DataSize)
  end;
finally
  AESDec.Free;
end;
end;

{------------------------------------------------------------------------------}
{   TSII_Decryptor - public methods                                            }
{------------------------------------------------------------------------------}

constructor TSII_Decryptor.Create;
begin
inherited Create;
fReraiseExceptions := True;
fAcceleratedAES := True;
fProgressTracker := TProgressTracker.Create;
fProgressTracker.OnProgress := DoProgress;
fReportProgress := True;
end;

//------------------------------------------------------------------------------

destructor TSII_Decryptor.Destroy;
begin
fProgressTracker.OnProgress := nil;
fProgressTracker.Free;
inherited;
end;

//------------------------------------------------------------------------------

Function TSII_Decryptor.GetStreamFormat(Stream: TStream): TSIIResult;
begin
try
  If (Stream.Size - Stream.Position) >= SizeOf(UInt32) then
    case Stream_ReadUInt32(Stream,False) of
      SII_Signature_Encrypted:  If (Stream.Size - Stream.Position) >= SizeOf(TSIIHeader) then
                                  Result := rSuccess
                                else
                                  Result := rTooFewData;
      SII_Signature_Normal:     Result := rNotEncrypted;
      SII_Signature_Binary:     If (Stream.Size - Stream.Position) >= SIIBIN_MIN_SIZE then
                                  Result := rBinaryFormat
                                else
                                  Result := rTooFewData;
      SII_Signature_3nK:        If (Stream.Size - Stream.Position) >= SII_3nK_MinSize then
                                  Result := r3nKFormat
                                else
                                  Result := rTooFewData;
    else
      Result := rUnknownFormat;
    end
  else Result := rTooFewData;
except
  Result := rGenericError;
  If fReraiseExceptions then raise;
end;
end;

//------------------------------------------------------------------------------

Function TSII_Decryptor.GetFileFormat(const FileName: String): TSIIResult;
var
  FileStream: TFileStream;
begin
try
  FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
  try
    Result := GetStreamFormat(FileStream);
  finally
    FileStream.Free;
  end;
except
  Result := rGenericError;
  If fReraiseExceptions then raise;
end;
end;

//------------------------------------------------------------------------------

Function TSII_Decryptor.IsEncryptedSIIStream(Stream: TSTream): Boolean;
begin
Result := GetStreamFormat(Stream) = rSuccess;
end;

//------------------------------------------------------------------------------

Function TSII_Decryptor.IsEncryptedSIIFile(const FileName: String): Boolean;
begin
Result := GetFileFormat(FileName) = rSuccess;
end;

//------------------------------------------------------------------------------

Function TSII_Decryptor.IsEncodedSIIStream(Stream: TSTream): Boolean;
begin
Result := GetStreamFormat(Stream) = rBinaryFormat;
end;

//------------------------------------------------------------------------------

Function TSII_Decryptor.IsEncodedSIIFile(const FileName: String): Boolean;
begin
Result := GetFileFormat(FileName) = rBinaryFormat;
end;

//------------------------------------------------------------------------------

Function TSII_Decryptor.Is3nKSIIStream(Stream: TSTream): Boolean;
begin
Result := GetStreamFormat(Stream) = r3nKFormat;
end;

//------------------------------------------------------------------------------

Function TSII_Decryptor.Is3nKSIIFile(const FileName: String): Boolean;
begin
Result := GetFileFormat(FileName) = r3nKFormat;
end;

//------------------------------------------------------------------------------

Function TSII_Decryptor.DecryptStream(Input, Output: TStream; InvariantOutput: Boolean = False): TSIIResult;
var
  InitOutPos: Int64;
  Header:     TSIIHeader;
  TempStream: TMemoryStream;
begin
If fProgressTracker.IndexOf(SII_PRGS_STAGEID_DECRYPT) < 0 then
  fProgressTracker.Add(SII_PRGS_STAGELEN_DECRYPT,SII_PRGS_STAGEID_DECRYPT);
try
  Result := GetStreamFormat(Input);
  If Result = rSuccess then
    begin
      InitOutPos := Output.Position;
      If (Input.Size - Input.Position) >= SizeOf(TSIIHeader) then
        begin
          Input.ReadBuffer({%H-}Header,SizeOf(TSIIHeader));
          TempStream := TMemoryStream.Create;
          try
            DecryptStreamInternal(Input,TempStream,Header);
            Output.Seek(InitOutPos,soBeginning);
            Output.WriteBuffer(TempStream.Memory^,TempStream.Size);
            If not InvariantOutput then
              Output.Size := Output.Position;
            Result := rSuccess;
          finally
            TempStream.Free;
          end;
        end
      else Result := rTooFewData;
    end;
except
  Result := rGenericError;
  If fReraiseExceptions then raise;
end;
fReportProgress := False;
try
  fProgressTracker.Clear;
finally
  fReportProgress := True;
end;
end;

//------------------------------------------------------------------------------

Function TSII_Decryptor.DecryptFile(const Input, Output: String): TSIIResult;
var
  InputStream:  TFileStream;
  OutputStream: TFileStream;
begin
try
  If AnsiSameText(ExpandFileName(Input),ExpandFileName(Output)) then
    begin
      InputStream := TFileStream.Create(StrToRTL(Input),fmOpenReadWrite or fmShareExclusive);
      try
        Result := DecryptStream(InputStream,InputStream,False);
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
          Result := DecryptStream(InputStream,OutputStream,False);
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

Function TSII_Decryptor.DecryptFileInMemory(const Input, Output: String): TSIIResult;
var
  MemoryStream: TMemoryStream;
begin
try
  MemoryStream := TMemoryStream.Create;
  try
    MemoryStream.LoadFromFile(StrToRTL(Input));
    Result := DecryptStream(MemoryStream,MemoryStream,False);
    If Result = rSuccess then
      MemoryStream.SaveToFile(StrToRTL(Output));
  finally
    MemoryStream.Free;
  end;
except
  Result := rGenericError;
  If fReraiseExceptions then raise;
end;
end;

//------------------------------------------------------------------------------

Function TSII_Decryptor.DecodeStream(Input, Output: TStream; InvariantOutput: Boolean = False): TSIIResult;
var
  DecoderBin: TSIIBin_Decoder;
  Decoder3nK: TSII_3nK_Transcoder;
  InitOutPos: Int64;
  TextResult: TAnsiStringList;
  TempStream: TMemoryStream;
begin
If fProgressTracker.IndexOf(SII_PRGS_STAGEID_DECODE) < 0 then
  fProgressTracker.Add(SII_PRGS_STAGELEN_DECODE,SII_PRGS_STAGEID_DECODE);
try
  Result := GetStreamFormat(Input);
  case Result of
    rBinaryFormat:   //- BSII file - - - - - - - - - - - - - - - - - - - - - - -
      begin
        DecoderBin := TSIIBin_Decoder.Create;
        try
          DecoderBin.OnProgress := DecodeProgressHandler;
          If Input = Output then
            begin
              InitOutPos := Output.Position;
              TextResult := TAnsiStringList.Create;
              try
                TextResult.TrailingLineBreak := False;
                DecoderBin.ConvertFromStream(Input,TextResult);
                Output.Seek(InitOutPos,soBeginning);
                TextResult.SaveToStream(Output);
                If not InvariantOutput then
                  Output.Size := Output.Position;
              finally
                TextResult.Free;
              end;
            end
          else DecoderBin.ConvertStream(Input,Output,InvariantOutput);
          Result := rSuccess;
        finally
          DecoderBin.Free;
        end;
      end;
    r3nKFormat:     //- 3nK file - - - - - - - - - - - - - - - - - - - - - - - -
      begin
        Decoder3nK := TSII_3nK_Transcoder.Create;
        try
          Decoder3nK.OnProgress := DecodeProgressHandler;
          If Input = Output then
            begin
              TempStream := TMemoryStream.Create;
              try
                InitOutPos := Output.Position;
                TempStream.Size := Input.Size - Input.Position;
                Decoder3nK.DecodeStream(Input,TempStream,False);
                Output.Seek(InitOutPos,soBeginning);
                Output.WriteBuffer(TempStream.Memory^,TempStream.Size);
                If not InvariantOutput then
                  Output.Size := Output.Position;
              finally
                TempStream.Free;
              end;
            end
          else Decoder3nK.DecodeStream(Input,Output,InvariantOutput);
          Result := rSuccess;
        finally
          Decoder3nK.Free;
        end;
      end;
  else
    Result := rUnknownFormat;
  end;
except
  Result := rGenericError;
  If fReraiseExceptions then raise;
end;
fReportProgress := False;
try
  fProgressTracker.Clear;
finally
  fReportProgress := True;
end;
end;

//------------------------------------------------------------------------------

Function TSII_Decryptor.DecodeFile(const Input, Output: String): TSIIResult;
var
  InputStream:  TFileStream;
  OutputStream: TFileStream;
begin
try
  If AnsiSameText(ExpandFileName(Input),ExpandFileName(Output)) then
    begin
      InputStream := TFileStream.Create(StrToRTL(Input),fmOpenReadWrite or fmShareExclusive);
      try
        Result := DecodeStream(InputStream,InputStream,False);
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
          Result := DecodeStream(InputStream,OutputStream,False);
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

Function TSII_Decryptor.DecodeFileInMemory(const Input, Output: String): TSIIResult;
var
  MemoryStream: TMemoryStream;
begin
try
  MemoryStream := TMemoryStream.Create;
  try
    MemoryStream.LoadFromFile(StrToRTL(Input));
    Result := DecodeStream(MemoryStream,MemoryStream,False);
    If Result = rSuccess then
      MemoryStream.SaveToFile(StrToRTL(Output));
  finally
    MemoryStream.Free;
  end;
except
  Result := rGenericError;
  If fReraiseExceptions then raise;
end;
end;

//------------------------------------------------------------------------------

Function TSII_Decryptor.DecryptAndDecodeStream(Input, Output: TStream; InvariantOutput: Boolean = False): TSIIResult;
var
  TempStream: TMemoryStream;
  InitOutPos: Int64;
  Header:     TSIIHeader;
begin
try
  Result := GetStreamFormat(Input);
  case Result of
    rSuccess:
      begin
        fProgressTracker.Add(SII_PRGS_STAGELEN_DECRYPT,SII_PRGS_STAGEID_DECRYPT);
        fProgressTracker.Add(SII_PRGS_STAGELEN_DECODE,SII_PRGS_STAGEID_DECODE);
        TempStream := TMemoryStream.Create;
        try
          InitOutPos := Input.Position;
          If (Input.Size - Input.Position >= SizeOf(TSIIHeader)) then
            begin
              Input.ReadBuffer({%H-}Header,SizeOf(TSIIHeader));
              DecryptStreamInternal(Input,TempStream,Header);
              TempStream.Seek(0,soBeginning);
              Result := GetStreamFormat(TempStream);
              case Result of
                rBinaryFormat,
                r3nKFormat:     begin
                                  Output.Seek(InitOutPos,soBeginning);
                                  Result := DecodeStream(TempStream,Output,InvariantOutput);
                                end;
                rNotEncrypted:  begin
                                  Output.Seek(InitOutPos,soBeginning);
                                  Output.WriteBuffer(TempStream.Memory^,TempStream.Size);
                                  If not InvariantOutput then
                                    Output.Size := Output.Position;
                                  Result := rSuccess;
                                end;
              end;
            end
          else Result := rTooFewData;
        finally
            TempStream.Free;
        end;
      end;
    rBinaryFormat,
    r3nKFormat:
      Result := DecodeStream(Input,Output,InvariantOutput);
  end;
except
  Result := rGenericError;
  If fReraiseExceptions then raise;
end;
fReportProgress := False;
try
  fProgressTracker.Clear;
finally
  fReportProgress := True;
end;
end;

//------------------------------------------------------------------------------

Function TSII_Decryptor.DecryptAndDecodeFile(const Input, Output: String): TSIIResult;
var
  InputStream:  TFileStream;
  OutputStream: TFileStream;
begin
try
  If AnsiSameText(ExpandFileName(Input),ExpandFileName(Output)) then
    begin
      InputStream := TFileStream.Create(StrToRTL(Input),fmOpenReadWrite or fmShareExclusive);
      try
        Result := DecryptAndDecodeStream(InputStream,InputStream,False);
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
          Result := DecryptAndDecodeStream(InputStream,OutputStream,False);
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

Function TSII_Decryptor.DecryptAndDecodeFileInMemory(const Input, Output: String): TSIIResult;
var
  MemoryStream: TMemoryStream;
begin
try
  MemoryStream := TMemoryStream.Create;
  try
    MemoryStream.LoadFromFile(StrToRTL(Input));
    Result := DecryptAndDecodeStream(MemoryStream,MemoryStream,False);
    If Result = rSuccess then
      MemoryStream.SaveToFile(StrToRTL(Output));
  finally
    MemoryStream.Free;
  end;
except
  Result := rGenericError;
  If fReraiseExceptions then raise;
end;
end;

end.

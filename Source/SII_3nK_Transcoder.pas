{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_3nK_Transcoder;

{$INCLUDE 'SII_3nK_defs.inc'}

interface

uses
  Classes,
  AuxTypes;

type
  SII_3nK_Header = packed record
    Signature:  UInt32;
    UnkByte:    UInt8;
    Seed:       UInt8;
  end;  

const
  SII_3nK_Signature = UInt32($014B6E33);      // 3nK#01
  SII_3nK_MinSize   = SizeOf(SII_3nK_Header); // 6 bytes

{
  Key table entries were calculated from this formula:

    Key[i] = (((i shl 2) xor not i) shl 3) xor i
}
  SII_3nK_KeyTable: array[Byte] of Byte = (
    $F8, $D1, $AA, $83, $5C, $75, $0E, $27, $B0, $99, $E2, $CB, $14, $3D, $46, $6F,
    $68, $41, $3A, $13, $CC, $E5, $9E, $B7, $20, $09, $72, $5B, $84, $AD, $D6, $FF,
    $D8, $F1, $8A, $A3, $7C, $55, $2E, $07, $90, $B9, $C2, $EB, $34, $1D, $66, $4F,
    $48, $61, $1A, $33, $EC, $C5, $BE, $97, $00, $29, $52, $7B, $A4, $8D, $F6, $DF,
    $B8, $91, $EA, $C3, $1C, $35, $4E, $67, $F0, $D9, $A2, $8B, $54, $7D, $06, $2F,
    $28, $01, $7A, $53, $8C, $A5, $DE, $F7, $60, $49, $32, $1B, $C4, $ED, $96, $BF,
    $98, $B1, $CA, $E3, $3C, $15, $6E, $47, $D0, $F9, $82, $AB, $74, $5D, $26, $0F,
    $08, $21, $5A, $73, $AC, $85, $FE, $D7, $40, $69, $12, $3B, $E4, $CD, $B6, $9F,
    $78, $51, $2A, $03, $DC, $F5, $8E, $A7, $30, $19, $62, $4B, $94, $BD, $C6, $EF,
    $E8, $C1, $BA, $93, $4C, $65, $1E, $37, $A0, $89, $F2, $DB, $04, $2D, $56, $7F,
    $58, $71, $0A, $23, $FC, $D5, $AE, $87, $10, $39, $42, $6B, $B4, $9D, $E6, $CF,
    $C8, $E1, $9A, $B3, $6C, $45, $3E, $17, $80, $A9, $D2, $FB, $24, $0D, $76, $5F,
    $38, $11, $6A, $43, $9C, $B5, $CE, $E7, $70, $59, $22, $0B, $D4, $FD, $86, $AF,
    $A8, $81, $FA, $D3, $0C, $25, $5E, $77, $E0, $C9, $B2, $9B, $44, $6D, $16, $3F,
    $18, $31, $4A, $63, $BC, $95, $EE, $C7, $50, $79, $02, $2B, $F4, $DD, $A6, $8F,
    $88, $A1, $DA, $F3, $2C, $05, $7E, $57, $C0, $E9, $92, $BB, $64, $4D, $36, $1F);

{===============================================================================
--------------------------------------------------------------------------------
                               TSII_3nK_Transcoder
--------------------------------------------------------------------------------
===============================================================================}
type
  TSII_3nK_ProcRoutine = procedure(Input, Output: TStream; RectifySize: Boolean = True) of object;

  TSII_3nK_ProgressEvent    = procedure(Sender: TObject; Progress: Double) of object;
  TSII_3nK_ProgressCallback = procedure(Sender: TObject; Progress: Double);

{===============================================================================
    TSII_3nK_Transcoder - declaration
===============================================================================}
  TSII_3nK_Transcoder = class(TObject)
  private
    fSeed:                UInt8;
    fOnProgressEvent:     TSII_3nK_ProgressEvent;
    fOnProgressCallback:  TSII_3nK_ProgressCallback;
    Function GetKey(Index: Integer): Byte;
  protected
    procedure DoProgress(Progress: Double); virtual;
    procedure TranscodeBuffer(var Buff; Size: TMemSize; Seed: Int64); virtual;
    procedure ProcessFile(const InFileName, OutFileName: String; Routine: TSII_3nK_ProcRoutine); virtual;
    procedure ProcessFileInMemory(const InFileName, OutFileName: String; Routine: TSII_3nK_ProcRoutine); virtual;
  public
    constructor Create;
    Function Is3nKStream(Stream: TStream): Boolean; virtual;
    Function Is3nKFile(const FileName: String): Boolean; virtual;    
    procedure EncodeStream(Input, Output: TStream; InvariantOutput: Boolean = False); virtual;
    procedure DecodeStream(Input, Output: TStream; InvariantOutput: Boolean = False); virtual;
    procedure TranscodeStream(Input, Output: TStream; InvariantOutput: Boolean = False); virtual;
    procedure DecodeFile(const InFileName, OutFileName: String); virtual;
    procedure EncodeFile(const InFileName, OutFileName: String); virtual;
    procedure TranscodeFile(const InFileName, OutFileName: String); virtual;
    procedure DecodeFileInMemory(const InFileName, OutFileName: String); virtual;
    procedure EncodeFileInMemory(const InFileName, OutFileName: String); virtual;
    procedure TranscodeFileInMemory(const InFileName, OutFileName: String); virtual;
    property Keys[Index: Integer]: Byte read GetKey;
    property Seed: UInt8 read fSeed;
    property OnProgress: TSII_3nK_ProgressEvent read fOnProgressEvent write fOnProgressEvent;
    property OnProgressEvent: TSII_3nK_ProgressEvent read fOnProgressEvent write fOnProgressEvent;
    property OnProgressCallback: TSII_3nK_ProgressCallback read fOnProgressCallback write fOnProgressCallback;
  end;

implementation

uses
  SysUtils,
  StrRect, BinaryStreaming, MemoryBuffer;

{$IFDEF FPC_DisableWarns}
  {$WARN 4055 OFF} // Conversion between ordinals and pointers is not portable
  {$WARN 5057 OFF} // Local variable "$1" does not seem to be initialized
{$ENDIF}

{===============================================================================
--------------------------------------------------------------------------------
                               TSII_3nK_Transcoder
--------------------------------------------------------------------------------
===============================================================================}

const
  SII_3nK_BufferSize = 16 * 1024; // 16KiB

{===============================================================================
    TSII_3nK_Transcoder - implementation
===============================================================================}

{-------------------------------------------------------------------------------
    TSII_3nK_Transcoder - private methods
-------------------------------------------------------------------------------}

Function TSII_3nK_Transcoder.GetKey(Index: Integer): Byte;
begin
Result := SII_3nK_KeyTable[Byte(Index)];
end;

{-------------------------------------------------------------------------------
    TSII_3nK_Transcoder - protected methods
-------------------------------------------------------------------------------}

procedure TSII_3nK_Transcoder.DoProgress(Progress: Double);
begin
If Assigned(fOnProgressEvent) then
  fOnProgressEvent(Self,Progress);
If Assigned(fOnProgressCallback) then
  fOnProgressCallback(Self,Progress);
end;

//------------------------------------------------------------------------------

procedure TSII_3nK_Transcoder.TranscodeBuffer(var Buff; Size: TMemSize; Seed: Int64);
var
  i:  TMemSize;
begin
If Size > 0 then
  For i := 0 to Pred(Size) do
    PByte(PtrUInt(@Buff) + PtrUInt(i))^ :=
      PByte(PtrUInt(@Buff) + PtrUInt(i))^ xor SII_3nK_KeyTable[Byte(Seed + i)];
end;

//------------------------------------------------------------------------------

procedure TSII_3nK_Transcoder.ProcessFile(const InFileName, OutFileName: String; Routine: TSII_3nK_ProcRoutine);
var
  InputStream:  TFileStream;
  OutputStream: TFileStream;
begin
InputStream := TFileStream.Create(StrToRTL(InFileName),fmOpenRead or fmShareDenyWrite);
try
  OutputStream := TFileStream.Create(StrToRTL(OutFileName),fmCreate or fmShareExclusive);
  try
    Routine(InputStream,OutputStream,False);
  finally
    OutputStream.Free;
  end;
finally
  InputStream.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TSII_3nK_Transcoder.ProcessFileInMemory(const InFileName, OutFileName: String; Routine: TSII_3nK_ProcRoutine);
var
  InputStream:  TMemoryStream;
  OutputStream: TMemoryStream;
begin
InputStream := TMemoryStream.Create;
try
  InputStream.LoadFromFile(StrToRTL(InFileName));
  OutputStream := TMemoryStream.Create;
  try
    Routine(InputStream,OutputStream,False);
    OutputStream.SaveToFile(StrToRTL(OutFileName));
  finally
    OutputStream.Free;
  end;
finally
  InputStream.Free;
end;
end;

{-------------------------------------------------------------------------------
    TSII_3nK_Transcoder - public methods
-------------------------------------------------------------------------------}

constructor TSII_3nK_Transcoder.Create;
begin
inherited;
fSeed := 0;
Randomize;
end;

//------------------------------------------------------------------------------

Function TSII_3nK_Transcoder.Is3nKStream(Stream: TStream): Boolean;
var
  Header: SII_3nK_Header;
begin
If (Stream.Size - Stream.Position) >= SII_3nK_MinSize then
  begin
    Stream_ReadBuffer(Stream,Header,SizeOf(Header),False);
    Result := Header.Signature = SII_3nK_Signature;
    If Result then
      fSeed := Header.Seed;
  end
else Result := False;
end;

//------------------------------------------------------------------------------

Function TSII_3nK_Transcoder.Is3nKFile(const FileName: String): Boolean;
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
try
  Result := Is3nKStream(FileStream);
finally
  FileStream.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TSII_3nK_Transcoder.EncodeStream(Input, Output: TStream; InvariantOutput: Boolean = False);
var
  Header:         SII_3nK_Header;
  Buff:           TMemoryBuffer;
  ActualReg:      Int64;
  ProgressStart:  Int64;
  TempPos:        Int64;
begin
If Input <> Output then
  begin
    DoProgress(0.0);
    Header.Signature := SII_3nK_Signature;
    Header.UnkByte := 0;
    Header.Seed := UInt8(Random(High(Byte) + 1));
    fSeed := Header.Seed;
    ActualReg := fSeed;
    // output preallocation
    If not InvariantOutput then
      begin
        TempPos := Output.Position;
        try
          If (Output.Size - Output.Position) < ((Input.Size - Input.Position) + SizeOf(Header)) then
            Output.Size := Output.Size + ((Input.Size - Input.Position) + SizeOf(Header));
        finally
          Output.Position := TempPos;
        end;
      end;
    // write header to output
    Output.WriteBuffer(Header,SizeOf(Header));
    // encode data
    If (Input.Size - Input.Position) > 0 then
      begin
        GetBuffer(Buff,SII_3nK_BufferSize);
        try
          ProgressStart := Input.Position;
          repeat
            Buff.Data := Input.Read(Buff.Memory^,Buff.Size);
            TranscodeBuffer(Buff.Memory^,Buff.Data,ActualReg);
            Output.WriteBuffer(Buff.Memory^,Buff.Data);
            ActualReg := ActualReg + Int64(Buff.Data);
            DoProgress((Input.Position - ProgressStart) / (Input.Size - ProgressStart));
          until Buff.Data < PtrInt(Buff.Size);
        finally
          FreeBuffer(Buff);
        end;
      end;
    If not InvariantOutput then
      Output.Size := Output.Position;
    DoProgress(1.0);  
  end
else raise Exception.Create('TSII_3nK_Transcoder.EncodeStream: Input and output streams are the same, data would be corrupted.');
end;

//------------------------------------------------------------------------------

procedure TSII_3nK_Transcoder.DecodeStream(Input, Output: TStream; InvariantOutput: Boolean = False);
var
  Header:         SII_3nK_Header;
  Buff:           TMemoryBuffer;
  ActualReg:      Int64;
  ProgressStart:  Int64;
  TempPos:        Int64;
begin
If Input <> Output then
  begin
    If Is3nKStream(Input) then
      begin
        DoProgress(0.0);
        // read header
        Input.ReadBuffer(Header,SizeOf(Header));
        ActualReg := Int64(Header.Seed);
        fSeed := Header.Seed;        
        // output preallocation
        If not InvariantOutput then
          begin
            TempPos := Output.Position;
            try
              If (Output.Size - Output.Position) < ((Input.Size - Input.Position)) then
                Output.Size := Output.Size + (Input.Size - Input.Position);
            finally
              Output.Position := TempPos;
            end;
          end;
        // decode data
        If (Input.Size - Input.Position) > 0 then
          begin
            GetBuffer(Buff,SII_3nK_BufferSize);
            try
              ProgressStart := Input.Position;
              repeat
                Buff.Data := Input.Read(Buff.Memory^,Buff.Size);
                TranscodeBuffer(Buff.Memory^,Buff.Data,ActualReg);
                Output.WriteBuffer(Buff.Memory^,Buff.Data);
                ActualReg := ActualReg + Int64(Buff.Data);
                DoProgress((Input.Position - ProgressStart) / (Input.Size - ProgressStart));
              until Buff.Data < PtrInt(Buff.Size);
            finally
              FreeBuffer(Buff);
            end;
          end;
        If not InvariantOutput then
          Output.Size := Output.Position;
        DoProgress(1.0);
      end
    else raise Exception.Create('TSII_3nK_Transcoder.DecodeStream: Input stream is not a valid 3nK stream.');
  end
else raise Exception.Create('TSII_3nK_Transcoder.DecodeStream: Input and output streams are the same, data would be corrupted.');
end;

//------------------------------------------------------------------------------

procedure TSII_3nK_Transcoder.TranscodeStream(Input, Output: TStream; InvariantOutput: Boolean = False);
begin
If Is3nKStream(Input) then
  DecodeStream(Input,Output,InvariantOutput)
else
  EncodeStream(Input,Output,InvariantOutput);
end;

//------------------------------------------------------------------------------

procedure TSII_3nK_Transcoder.DecodeFile(const InFileName, OutFileName: String);
begin
ProcessFile(InFileName,OutFileName,DecodeStream);
end;

//------------------------------------------------------------------------------

procedure TSII_3nK_Transcoder.EncodeFile(const InFileName, OutFileName: String);
begin
ProcessFile(InFileName,OutFileName,EncodeStream);
end;

//------------------------------------------------------------------------------

procedure TSII_3nK_Transcoder.TranscodeFile(const InFileName, OutFileName: String);
begin
ProcessFile(InFileName,OutFileName,TranscodeStream);
end;

//------------------------------------------------------------------------------

procedure TSII_3nK_Transcoder.DecodeFileInMemory(const InFileName, OutFileName: String);
begin
ProcessFileInMemory(InFileName,OutFileName,DecodeStream);
end;

//------------------------------------------------------------------------------

procedure TSII_3nK_Transcoder.EncodeFileInMemory(const InFileName, OutFileName: String);
begin
ProcessFileInMemory(InFileName,OutFileName,EncodeStream);
end;

//------------------------------------------------------------------------------

procedure TSII_3nK_Transcoder.TranscodeFileInMemory(const InFileName, OutFileName: String);
begin
ProcessFileInMemory(InFileName,OutFileName,TranscodeStream);
end;

end.

{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_Decoder;

{$INCLUDE '.\SII_Decode_defs.inc'}

interface

uses
  Classes, Contnrs, ExplicitStringLists,
  SII_Decode_Common, SII_Decode_DataBlock;

{===============================================================================
--------------------------------------------------------------------------------
                                TSIIBin_Decoder
--------------------------------------------------------------------------------
===============================================================================}
const
{
  Minimal size of valid BSII file. Obtained this way:

  8 bytes - header
    4 bytes - signature
    4 bytes - version (1 or 2)
  5 bytes - an invalid structure block
    4 bytes - block type (0)
    1 byte  - validity (0))
}
  SIIBIN_MIN_SIZE = 13;

{
  Expected size ratio between textual and binary sii formats.
  Used for preallocation.
}
  SIIBIN_BIN_TEXT_RATIO = 3.5;

type
  TSIIBin_ProgressType = (ptLoading,ptConverting,ptStreaming);

  TSIIBin_ProgressTypeEvent    = procedure(Sender: TObject; Progress: Double; ProgressType: TSIIBin_ProgressType) of object;
  TSIIBin_ProgressEvent        = procedure(Sender: TObject; Progress: Double) of object;
  TSIIBin_ProgressTypeCallback = procedure(Sender: TObject; Progress: Double; ProgressType: TSIIBin_ProgressType);
  TSIIBin_ProgressCallback     = procedure(Sender: TObject; Progress: Double);

{===============================================================================
    TSIIBin_Decoder - declaration
===============================================================================}
  TSIIBin_Decoder = class(TObject)
  private
    fFileInfo:                TSIIBin_FileInfo;
    fFileDataBlocks:          TObjectList;
    fProcessUnknowns:         Boolean;
    fOnProgressTypeEvent:     TSIIBin_ProgressTypeEvent;
    fOnProgressEvent:         TSIIBin_ProgressEvent;
    fOnProgressTypeCallback:  TSIIBin_ProgressTypeCallback;
    fOnProgressCallback:      TSIIBin_ProgressCallback;
    Function GetDataBlockCount: Integer;
    Function GetDataBlock(Index: Integer): TSIIBin_DataBlock;
  protected
    Function IndexOfStructureLocal(StructureID: TSIIBin_StructureID; const FileInfo: TSIIBin_FileInfo): Integer; virtual;
    Function LoadStructureBlockLocal(Stream: TStream; var FileInfo: TSIIBin_FileInfo): Boolean; virtual;
    procedure LoadDataBlockLocal(Stream: TStream; StructureID: TSIIBin_StructureID; const FileInfo: TSIIBin_FileInfo; out DataBlock: TSIIBin_DataBlock); virtual;
    Function IndexOfStructure(StructureID: TSIIBin_StructureID): Integer; virtual;
    Function LoadStructureBlock(Stream: TStream): Boolean; virtual;
    procedure LoadDataBlock(Stream: TStream; StructureID: TSIIBin_StructureID); virtual;
    procedure Initialize; virtual;
    procedure ClearStructures(var FileInfo: TSIIBin_FileInfo); virtual;
    procedure CheckFileHeader(const FileInfo: TSIIBin_FileInfo); virtual;
    procedure DoProgress(Progress: Double; ProgressType: TSIIBin_ProgressType); virtual;
  public
    class Function IsBinarySIIStream(Stream: TStream): Boolean; virtual;
    class Function IsBinarySIIFile(const FileName: String): Boolean; virtual;
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromStream(Stream: TStream); virtual;
    procedure LoadFromFile(const FileName: String); virtual;
    procedure Convert(Output: TStrings); overload; virtual;
    procedure Convert(Output: TAnsiStringList); overload; virtual;
    procedure ConvertFromStream(Stream: TStream; Output: TStrings); overload; virtual;
    procedure ConvertFromStream(Stream: TStream; Output: TAnsiStringList); overload; virtual;
    procedure ConvertFromFile(const FileName: String; Output: TStrings); overload; virtual;
    procedure ConvertFromFile(const FileName: String; Output: TAnsiStringList); overload; virtual;
    procedure ConvertStream(InStream, OutStream: TStream; InvariantOutput: Boolean = False); virtual;
    procedure ConvertFile(const InFileName, OutFileName: String); overload; virtual;
    property ProcessUnknowns: Boolean read fProcessUnknowns write fProcessUnknowns;
    property DataBlockCount: Integer read GetDataBlockCount;
    property DataBlocks[Index: Integer]: TSIIBin_DataBlock read GetDataBlock;
    property OnProgressTypeCallBack: TSIIBin_ProgressTypeCallback read fOnProgressTypeCallback write fOnProgressTypeCallback;
    property OnProgressCallBack: TSIIBin_ProgressCallback read fOnProgressCallback write fOnProgressCallback; 
    property OnProgressTypeEvent: TSIIBin_ProgressTypeEvent read fOnProgressTypeEvent write fOnProgressTypeEvent;
    property OnProgressEvent: TSIIBin_ProgressEvent read fOnProgressEvent write fOnProgressEvent;
    property OnProgress: TSIIBin_ProgressEvent read fOnProgressEvent write fOnProgressEvent;
  end;

implementation

uses
  SysUtils, BinaryStreaming, StrRect, AuxExceptions,
  SII_Decode_Utils, SII_Decode_FieldData;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$IF Defined(FPC) and (FPC_FULLVERSION >= 30000)}
    {$DEFINE W5057:=}
    {$DEFINE W5091:={$WARN 5091 OFF}} // Local variable "$1" of a managed type does not seem to be initialized
  {$ELSE}
    {$DEFINE W5057:={$WARN 5057 OFF}} // Local variable "$1" does not seem to be initialized
    {$DEFINE W5091:=}
  {$IFEND}
{$ENDIF}

{===============================================================================
--------------------------------------------------------------------------------
                                TSIIBin_Decoder
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_Decoder - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_Decoder - private methods
-------------------------------------------------------------------------------}

Function TSIIBin_Decoder.GetDataBlockCount: Integer;
begin
Result := fFileDataBlocks.Count;
end;

//------------------------------------------------------------------------------

Function TSIIBin_Decoder.GetDataBlock(Index: Integer): TSIIBin_DataBlock;
begin
If (Index >= 0) and (Index < fFileDataBlocks.Count) then
  Result := TSIIBin_DataBlock(fFileDataBlocks[Index])
else
  raise EIndexOutOfBounds.Create(Index,Self,'GetDataBlock');
end;

{-------------------------------------------------------------------------------
    TSIIBin_Decoder - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_Decoder.IndexOfStructureLocal(StructureID: TSIIBin_StructureID; const FileInfo: TSIIBin_FileInfo): Integer;
var
  i:  Integer;
begin
Result := -1;
For i := Low(FileInfo.Structures) to High(FileInfo.Structures) do
  If FileInfo.Structures[i].ID = StructureID then
    begin
      Result := i;
      Break;
    end;
end;

//------------------------------------------------------------------------------

Function TSIIBin_Decoder.LoadStructureBlockLocal(Stream: TStream; var FileInfo: TSIIBin_FileInfo): Boolean;
var
  Structure:  TSIIBin_Structure;
  ValueCount: Integer;
  ValueType:  TSIIBin_ValueType;
begin
Structure.Valid := Stream_ReadBool(Stream);
If Structure.Valid then
  begin
    Structure.ID := Stream_ReadUInt32(Stream);
    If (Structure.ID <> 0) and (IndexOfStructureLocal(Structure.ID,FileInfo) < 0) then
      begin
        SIIBin_LoadString(Stream,Structure.Name);
        ValueCount := 0;
        repeat
          ValueType := Stream_ReadUInt32(Stream);
          If ValueType <> 0 then
            begin
              If Length(Structure.Fields) <= ValueCount then
                SetLength(Structure.Fields,Length(Structure.Fields) + 16);
              If TSIIBin_DataBlock.ValueTypeSupported(ValueType) or
                (fProcessUnknowns and TSIIBin_DataBlockUnknowns.ValueTypeSupported(ValueType)) then
                Structure.Fields[ValueCount].ValueType := ValueType
              else
                raise EGeneralException.CreateFmt('Unsupported value type (0x%.8x).',[Ord(ValueType)],Self,'LoadStructureBlockLocal');
              SIIBin_LoadString(Stream,Structure.Fields[ValueCount].ValueName);
              case ValueType of
                $00000037:  Structure.Fields[ValueCount].ValueData := TSIIBIn_FieldData_OrdinalString.Create(Stream);
              else
                Structure.Fields[ValueCount].ValueData := nil;
              end;
              Inc(ValueCount);
            end;
        until ValueType = 0;
        SetLength(Structure.Fields,ValueCount);
        SetLength(FileInfo.Structures,Length(FileInfo.Structures) + 1);
        FileInfo.Structures[High(FileInfo.Structures)] := Structure;
        Result := True;
      end
    else raise EValueInvalidNameOnly.Create('structure ID',Self,'LoadStructureBlockLocal');
  end
else Result := False;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Decoder.LoadDataBlockLocal(Stream: TStream; StructureID: TSIIBin_StructureID; const FileInfo: TSIIBin_FileInfo; out DataBlock: TSIIBin_DataBlock);
var
  Index:  Integer;
begin
Index := IndexOfStructureLocal(StructureID,FileInfo);
If Index >= 0 then
  begin
    If fProcessUnknowns then
      DataBlock := TSIIBin_DataBlockUnknowns.Create(FileInfo.Header.Version,FileInfo.Structures[Index])
    else
      DataBlock := TSIIBin_DataBlock.Create(FileInfo.Header.Version,FileInfo.Structures[Index]);
    DataBlock.Load(Stream);
  end
else raise EGeneralException.CreateFmt('Unknown structure ID (%d).',[StructureID],Self,'LoadDataBlockLocal');
end;

//------------------------------------------------------------------------------

Function TSIIBin_Decoder.IndexOfStructure(StructureID: TSIIBin_StructureID): Integer;
begin
Result := IndexOfStructureLocal(StructureID,fFileInfo);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Decoder.LoadStructureBlock(Stream: TStream): Boolean;
begin
Result := LoadStructureBlockLocal(Stream,fFileInfo);
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Decoder.LoadDataBlock(Stream: TStream; StructureID: TSIIBin_StructureID);
var
  DataBlock:  TSIIBin_DataBlock;
begin
LoadDataBlockLocal(Stream,StructureID,fFileInfo,DataBlock);
fFileDataBlocks.Add(DataBlock);
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Decoder.Initialize;
begin
ClearStructures(fFileInfo);
FillChar(fFileInfo.Header,SizeOf(TSIIBin_FileHeader),0);
SetLength(fFileInfo.Structures,0);
fFileDataBlocks.Clear;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Decoder.ClearStructures(var FileInfo: TSIIBin_FileInfo);
var
  i,j:  Integer;
begin
For i := Low(FileInfo.Structures) to High(FileInfo.Structures) do
  For j := Low(FileInfo.Structures[i].Fields) to High(FileInfo.Structures[i].Fields) do
    If Assigned(FileInfo.Structures[i].Fields[j].ValueData) then
      FreeAndNil(FileInfo.Structures[i].Fields[j].ValueData);
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Decoder.CheckFileHeader(const FileInfo: TSIIBin_FileInfo);
begin
case FileInfo.Header.Signature of
  SIIBIN_SIGNARUTE_BIN:
    If not FileInfo.Header.Version in [1,2] then
      raise EGeneralException.CreateFmt('Unsupported version (0x%.8x).',[FileInfo.Header.Version],Self,'CheckFileHeader');
  SIIBin_SIGNATURE_CRYPT:
    raise EGeneralException.Create('Data are encrypted.',Self,'CheckFileHeader');
  SIIBin_SIGNATURE_TEXT:
    raise EGeneralException.Create('Data are already decoded.',Self,'CheckFileHeader');
else
  raise EGeneralException.CreateFmt('Unknown format (0x%.8x).',[FileInfo.Header.Signature],Self,'CheckFileHeader');
end;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Decoder.DoProgress(Progress: Double; ProgressType: TSIIBin_ProgressType);
begin
If Assigned(fOnProgressTypeEvent) then
  fOnProgressTypeEvent(Self,Progress,ProgressType);
If Assigned(fOnProgressEvent) then
  fOnProgressEvent(Self,Progress);
If Assigned(fOnProgressTypeCallback) then
  fOnProgressTypeCallback(Self,Progress,ProgressType);
If Assigned(fOnProgressCallback) then
  fOnProgressCallback(Self,Progress);
end;

{-------------------------------------------------------------------------------
    TSIIBin_Decoder - public methods
-------------------------------------------------------------------------------}

class Function TSIIBin_Decoder.IsBinarySIIStream(Stream: TStream): Boolean;
begin
If (Stream.Size - Stream.Position) >= SIIBIN_MIN_SIZE then
  Result := Stream_ReadUInt32(Stream,False) = SIIBIN_SIGNARUTE_BIN
else
  Result := False;
end;

//------------------------------------------------------------------------------

class Function TSIIBin_Decoder.IsBinarySIIFile(const FileName: String): Boolean;
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
try
  Result := IsBinarySIIStream(FileStream);
finally
  FileStream.Free;
end;
end;

//------------------------------------------------------------------------------

constructor TSIIBin_Decoder.Create;
begin
inherited Create;
fFileDataBlocks := TObjectList.Create(True);
end;

//------------------------------------------------------------------------------

destructor TSIIBin_Decoder.Destroy;
begin
fFileDataBlocks.Free;
ClearStructures(fFileInfo);
inherited;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Decoder.LoadFromStream(Stream: TStream);
var
  InitialPos: Int64;
  BlockType:  TSIIBin_BlockType;
  Continue:   Boolean;
begin
InitialPos := Stream.Position;
If (Stream.Size - InitialPos) >= SIIBIN_MIN_SIZE then
  begin
    DoProgress(0.0,ptLoading);
    Initialize;
    Stream_ReadBuffer(Stream,fFileInfo.Header,SizeOf(TSIIBin_FileHeader));
    CheckFileHeader(FFileInfo);
    Continue := True;
    repeat
      BlockType := Stream_ReadUInt32(Stream);
      If BlockType = 0 then
        Continue := LoadStructureBlock(Stream)
      else
        LoadDataBlock(Stream,TSIIBin_StructureID(BlockType));
      DoProgress((Stream.Position - InitialPos) / (Stream.Size - InitialPos),ptLoading);
    until not Continue;
    DoProgress(1.0,ptLoading);
  end
else raise EGeneralException.CreateFmt('Insufficient data (%d).',[Stream.Size - InitialPos],Self,'LoadFromStream');
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Decoder.LoadFromFile(const FileName: String);
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
try
  LoadFromStream(FileStream);
finally
  FileStream.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Decoder.Convert(Output: TStrings);
var
  i:  Integer;
begin
DoProgress(0.0,ptConverting);
Output.Add('SiiNunit');
Output.Add('{');
For i := 0 to Pred(fFileDataBlocks.Count) do
  begin
    Output.Add(AnsiToStr(TSIIBin_DataBlock(fFileDataBlocks[i]).AsString));
    DoProgress(i/fFileDataBlocks.Count,ptConverting);
  end;
Output.Add('}');
DoProgress(1.0,ptConverting);
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Decoder.Convert(Output: TAnsiStringList);
var
  i:  Integer;
begin
DoProgress(0.0,ptConverting);
Output.Add(AnsiString('SiiNunit'));
Output.Add(AnsiString('{'));
For i := 0 to Pred(fFileDataBlocks.Count) do
  begin
    Output.Add(TSIIBin_DataBlock(fFileDataBlocks[i]).AsString);
    DoProgress(i/fFileDataBlocks.Count,ptConverting);
  end;
Output.Add(AnsiString('}'));
DoProgress(1.0,ptConverting);
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5057 W5091{$ENDIF}
procedure TSIIBin_Decoder.ConvertFromStream(Stream: TStream; Output: TStrings);
var
  InitialPos: Int64;
  FileInfo:   TSIIBin_FileInfo;
  BlockType:  TSIIBin_BlockType;
  Continue:   Boolean;
  DataBlock:  TSIIBin_DataBlock;
begin
InitialPos := Stream.Position;
If (Stream.Size - InitialPos) >= SIIBIN_MIN_SIZE then
  begin
    DoProgress(0.0,ptStreaming);
    Stream_ReadBuffer(Stream,FileInfo.Header,SizeOf(TSIIBin_FileHeader));
    CheckFileHeader(FileInfo);
    Output.Add('SiiNunit');
    Output.Add('{');
    Continue := True;
    repeat
      BlockType := Stream_ReadUInt32(Stream);
      If BlockType <> 0 then
        begin
          LoadDataBlockLocal(Stream,TSIIBin_StructureID(BlockType),FileInfo,DataBlock);
          try
            Output.Add(AnsiToStr(DataBlock.AsString));
          finally
            DataBlock.Free;
          end;
        end
      else Continue := LoadStructureBlockLocal(Stream,FileInfo);
      DoProgress((Stream.Position - InitialPos) / (Stream.Size - InitialPos),ptStreaming);
    until not Continue;
    Output.Add('}');
    ClearStructures(FileInfo);
    DoProgress(1.0,ptStreaming);
  end
else raise EGeneralException.CreateFmt('Insufficient data (%d).',[Stream.Size - InitialPos],Self,'ConvertFromStream');
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5057 W5091{$ENDIF}
procedure TSIIBin_Decoder.ConvertFromStream(Stream: TStream; Output: TAnsiStringList);
var
  InitialPos: Int64;
  FileInfo:   TSIIBin_FileInfo;
  BlockType:  TSIIBin_BlockType;
  Continue:   Boolean;
  DataBlock:  TSIIBin_DataBlock;
begin
InitialPos := Stream.Position;
If (Stream.Size - InitialPos) >= SIIBIN_MIN_SIZE then
  begin
    DoProgress(0.0,ptStreaming);
    Stream_ReadBuffer(Stream,FileInfo.Header,SizeOf(TSIIBin_FileHeader));
    CheckFileHeader(FileInfo);
    Output.Add(AnsiString('SiiNunit'));
    Output.Add(AnsiString('{'));
    Continue := True;
    repeat
      BlockType := Stream_ReadUInt32(Stream);
      If BlockType <> 0 then
        begin
          LoadDataBlockLocal(Stream,TSIIBin_StructureID(BlockType),FileInfo,DataBlock);
          try
            Output.Add(DataBlock.AsString);
          finally
            DataBlock.Free;
          end;
        end
      else Continue := LoadStructureBlockLocal(Stream,FileInfo);
      DoProgress((Stream.Position - InitialPos) / (Stream.Size - InitialPos),ptStreaming);
    until not Continue;
    Output.Add(AnsiString('}'));
    ClearStructures(FileInfo);
    DoProgress(1.0,ptStreaming);
  end
else raise EGeneralException.CreateFmt('Insufficient data (%d).',[Stream.Size - InitialPos],Self,'ConvertFromStream');
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

procedure TSIIBin_Decoder.ConvertFromFile(const FileName: String; Output: TStrings);
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
try
  ConvertFromStream(FileStream,Output);
finally
  FileStream.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Decoder.ConvertFromFile(const FileName: String; Output: TAnsiStringList);
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
try
  ConvertFromStream(FileStream,Output);
finally
  FileStream.Free;
end;
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5057 W5091{$ENDIF}
procedure TSIIBin_Decoder.ConvertStream(InStream, OutStream: TStream; InvariantOutput: Boolean = False);
const
  asLineBreak: AnsiString = sLineBreak;
var
  InitialPos: Int64;
  FileInfo:   TSIIBin_FileInfo;
  BlockType:  TSIIBin_BlockType;
  Continue:   Boolean;
  DataBlock:  TSIIBin_DataBlock;
  TempPos:    Int64;

  procedure WriteToOutput(const Str: AnsiString; WriteLineBreak: Boolean = True);
  begin
    Stream_WriteBuffer(OutStream,PAnsiChar(Str)^,Length(Str) * SizeOf(AnsiChar));
    If WriteLineBreak then
      Stream_WriteBuffer(OutStream,PAnsiChar(asLineBreak)^,Length(asLineBreak) * SizeOf(AnsiChar));
  end;

begin
If InStream <> OutStream then
  begin
    InitialPos := InStream.Position;
    If (InStream.Size - InitialPos) >= SIIBIN_MIN_SIZE then
      begin
        DoProgress(0.0,ptStreaming);
        Stream_ReadBuffer(InStream,FileInfo.Header,SizeOf(TSIIBin_FileHeader));
        CheckFileHeader(FileInfo);
        // output preallocation
        If not InvariantOutput then
          begin
            TempPos := OutStream.Position;
            try
              If ((OutStream.Size - OutStream.Position) < Trunc((InStream.Size - InStream.Position) * SIIBIN_BIN_TEXT_RATIO)) and
                // prevent allocation of huge amount of memory in case of erroneous input              
                ((InStream.Size - InStream.Position) <= 26214400) {25MiB} then
                OutStream.Size := OutStream.Size + Trunc((InStream.Size - InStream.Position) * SIIBIN_BIN_TEXT_RATIO);
            finally
              OutStream.Position := TempPos;
            end;
          end;
        // conversion
        WriteToOutput(AnsiString('SiiNunit'));
        WriteToOutput(AnsiString('{'));
        Continue := True;
        repeat
          BlockType := Stream_ReadUInt32(InStream);
          If BlockType <> 0 then
            begin
              LoadDataBlockLocal(InStream,TSIIBin_StructureID(BlockType),FileInfo,DataBlock);
              try
                WriteToOutput(DataBlock.AsString);
              finally
                DataBlock.Free;
              end;
            end
          else Continue := LoadStructureBlockLocal(InStream,FileInfo);
          DoProgress((InStream.Position - InitialPos) / (InStream.Size - InitialPos),ptStreaming);
        until not Continue;
        WriteToOutput(AnsiString('}'),False);
        ClearStructures(FileInfo);
        // rectify size
        If not InvariantOutput and (OutStream.Position < OutStream.Size) then
          OutStream.Size := OutStream.Position;
        DoProgress(1.0,ptStreaming);
      end
    else raise EGeneralException.CreateFmt('Insufficient data (%d).',[InStream.Size - InitialPos],Self,'ConvertStream');
  end
else raise EGeneralException.Create('Input and output streams are the same.',Self,'ConvertStream');
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

procedure TSIIBin_Decoder.ConvertFile(const InFileName, OutFileName: String);
var
  InFileStream:   TFileStream;
  OutFileStream:  TFileStream;
begin
InFileStream := TFileStream.Create(StrToRTL(InFileName),fmOpenRead or fmShareDenyWrite);
try
  OutFileStream := TFileStream.Create(StrToRTL(OutFileName),fmCreate or fmShareExclusive);
  try
    ConvertStream(InFileStream,OutFileStream,False);
  finally
    OutFileStream.Free;
  end;
finally
  InFileStream.Free;
end;
end;

end.

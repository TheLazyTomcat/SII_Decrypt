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
  SII_Decode_Common, SII_Decode_Nodes;

{==============================================================================}
{------------------------------------------------------------------------------}
{                               TSIIBin_Decoder                                }
{------------------------------------------------------------------------------}
{==============================================================================}
const
{
  (8 bytes) header
    (4 bytes) signature
    (4 bytes) unknown (2)
  (5 bytes) an empty structure
    (4 bytes) structure index (0)
    (1 byte ) unknown (0))
}
  SIIBIN_MIN_SIZE = 13;

type
  TSIIBin_ProgressType = (ptLoading,ptConverting,ptStreaming);

  TSIIBin_ProgressEvent = procedure(Sender: TObject; Progress: Single; ProgressType: TSIIBin_ProgressType) of object;

{==============================================================================}
{   TSIIBin_Decoder - declaration                                              }
{==============================================================================}
  TSIIBin_Decoder = class(TObject)
  private
    fFileStructure:       TSIIBin_FileStructure;
    fFileDataBlocks:      TObjectList;
    fOnProgress:          TSIIBin_ProgressEvent;
    Function GetDataBlockCount: Integer;
    Function GetDataBlock(Index: Integer): TSIIBin_DataBlock;
  protected
    procedure Initialize; virtual;
    Function IndexOfStructure(StrucuteIndex: TSIIBin_StructureIndex): Integer; virtual;
    Function LoadStructureBlock(Stream: TStream): Boolean; virtual;
    procedure LoadDataBlock(Stream: TStream; StructureIndex: TSIIBin_StructureIndex); virtual;
    procedure DoProgress(Progress: Single; ProgressType: TSIIBin_ProgressType); virtual;
  public
    class Function IsBinarySIIStream(Stream: TStream): Boolean; virtual;
    class Function IsBinarySIIFile(const FileName: String): Boolean; virtual;
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromStream(Stream: TStream); virtual;
    procedure LoadFromFile(const FileName: String); virtual;
    procedure Convert(Output: TStrings); overload; virtual;
    procedure Convert(Output: TAnsiStringList); overload; virtual;
  (*
    todo: streaming conversion (reduced memory use)

    procedure ConvertFromStream(Input: TStream; Output: TStrings); virtual;
    procedure ConvertFromFile(const InputFileName, OutputFileName: String); virtual;
  *)
    property DataBlocks[Index: Integer]: TSIIBin_DataBlock read GetDataBlock;
  published
    property DataBlockCount: Integer read GetDataBlockCount;
    property OnProgress: TSIIBin_ProgressEvent read fOnProgress write fOnProgress;
  end;

implementation

uses
  SysUtils, BinaryStreaming, StrRect;

{==============================================================================}
{------------------------------------------------------------------------------}
{                               TSIIBin_Decoder                                }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Decoder - implementation                                           }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Decoder - private methods                                          }
{------------------------------------------------------------------------------}

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
  raise Exception.CreateFmt('TSIIBin_Decoder.GetDataBlock: Index (%d) out of bounds.',[Index]);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Decoder - protected methods                                        }
{------------------------------------------------------------------------------}

procedure TSIIBin_Decoder.Initialize;
begin
FillChar(fFileStructure.Header,SizeOf(TSIIBin_Header),0);
SetLength(fFileStructure.Structures,0);
fFileDataBlocks.Clear;
end;

//------------------------------------------------------------------------------

Function TSIIBin_Decoder.IndexOfStructure(StrucuteIndex: TSIIBin_StructureIndex): Integer;
var
  i:  Integer;
begin
Result := -1;
For i := Low(fFileStructure.Structures) to High(fFileStructure.Structures) do
  If fFileStructure.Structures[i].Index = StrucuteIndex then
    begin
      Result := i;
      Break;
    end;
end;

//------------------------------------------------------------------------------

Function TSIIBin_Decoder.LoadStructureBlock(Stream: TStream): Boolean;
var
  Structure:  TSIIBin_Structure;
  ValueCount: Integer;
  ValueType:  TSIIBin_ValueType;
begin
Structure.Unknown := Stream_ReadUInt8(Stream);
If Structure.Unknown <> 0 then
  begin
    Structure.Index := Stream_ReadUInt32(Stream);
    SIIBin_LoadString(Stream,Structure.Name);
    ValueCount := 0;
    repeat
      ValueType := Stream_ReadUInt32(Stream);
      If ValueType <> 0 then
        begin
          If Length(Structure.Fields) <= ValueCount then
            SetLength(Structure.Fields,Length(Structure.Fields) + 16);
          Structure.Fields[ValueCount].ValueType := ValueType;
          SIIBin_LoadString(Stream,Structure.Fields[ValueCount].ValueName);
          Inc(ValueCount);
        end;
    until ValueType = 0;
    SetLength(Structure.Fields,ValueCount);
    SetLength(fFileStructure.Structures,Length(fFileStructure.Structures) + 1);
    fFileStructure.Structures[High(fFileStructure.Structures)] := Structure;
    Result := True;
  end
else Result := False;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Decoder.LoadDataBlock(Stream: TStream; StructureIndex: TSIIBin_StructureIndex);
var
  Index:      Integer;
  DataBlock:  TSIIBin_DataBlock;
begin
Index := IndexOfStructure(StructureIndex);
If Index >= 0 then
  begin
    DataBlock := TSIIBin_DataBlock.Create(fFileStructure.Structures[Index]);
    DataBlock.Load(Stream);
    fFileDataBlocks.Add(DataBlock);
  end
else raise Exception.CreateFmt('TSIIBin_Decoder.LoadDataBlock: Unknown structure (%d).',[StructureIndex]);
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Decoder.DoProgress(Progress: Single; ProgressType: TSIIBin_ProgressType);
begin
If Assigned(fOnProgress) then
  fOnProgress(Self,Progress,ProgressType);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Decoder - public methods                                           }
{------------------------------------------------------------------------------}

class Function TSIIBin_Decoder.IsBinarySIIStream(Stream: TStream): Boolean;
begin
If (Stream.Size - Stream.Position) >= SIIBIN_MIN_SIZE then
  Result := Stream_ReadUInt32(Stream,False) = SIIBin_Signature_Bin
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
inherited;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Decoder.LoadFromStream(Stream: TStream);
var
  InitialPos:     Int64;
  StructureIndex: TSIIBin_StructureIndex;
  Continue:       Boolean;
begin
InitialPos := Stream.Position;
If (Stream.Size - InitialPos) >= SIIBIN_MIN_SIZE then
  begin
    DoProgress(0.0,ptLoading);
    Initialize;
    Stream_ReadBuffer(Stream,fFileStructure.Header,SizeOf(TSIIBin_Header));
    case fFileStructure.Header.Signature of
      SIIBin_Signature_Bin:
        If fFileStructure.Header.Unknown <> 2 then
          raise Exception.CreateFmt('TSIIBin_Decoder.LoadFromStream: Unknown format (0x%.8x).',[fFileStructure.Header.Signature]);
      SIIBin_Signature_Crypt:
        raise Exception.Create('TSIIBin_Decoder.LoadFromStream: Data are encrypted.');
      SIIBin_Signature_Text:
        raise Exception.Create('TSIIBin_Decoder.LoadFromStream: Data are already decoded.');
    else
      raise Exception.CreateFmt('TSIIBin_Decoder.LoadFromStream: Unknown format (0x%.8x).',[fFileStructure.Header.Signature]);
    end;
    Continue := True;
    repeat
      StructureIndex := Stream_ReadUInt32(Stream);
      If StructureIndex = 0 then
        Continue := LoadStructureBlock(Stream)
      else
        LoadDataBlock(Stream,StructureIndex);
      DoProgress((Stream.Position - InitialPos) / (Stream.Size - InitialPos),ptLoading);
    until not Continue;
    DoProgress(1.0,ptLoading);
  end
else raise Exception.CreateFmt('TSIIBin_Decoder.LoadFromStream: Insufficient data (%d).',[Stream.Size - InitialPos]);
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

end.

{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_DataBlock;

{$INCLUDE '.\SII_Decode_defs.inc'}

interface

uses
  Classes, Contnrs,
  AuxTypes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                               TSIIBin_DataBlock
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_DataBlock - declaration
===============================================================================}
type
  TSIIBin_DataBlock = class(TObject)
  private
    fFormatVersion: UInt32;
    fStructure:     TSIIBin_Structure;
    fName:          AnsiString;
    fBlockID:       TSIIBin_ID;
    fFields:        TObjectList;
    Function GetFieldCount: Integer;
    Function GetField(Index: Integer): TSIIBin_ValueNode;
  protected
    Function CreateValueNode(ValueType: TSIIBin_ValueType; FieldIndex: Integer; Stream: TStream): TSIIBin_ValueNode; virtual;
  public
    class Function ValueTypeSupported(ValueType: TSIIBin_ValueType): Boolean; virtual;
    constructor Create(FormatVersion: UInt32; Structure: TSIIBin_Structure);
    destructor Destroy; override;
    procedure Load(Stream: TStream); virtual;
    Function AsString: AnsiString; virtual;
    property Name: AnsiString read fName;
    property BlockID: TSIIBin_ID read fBlockID;
    property FieldCount: Integer read GetFieldCount;
    property Fields[Index: Integer]: TSIIBin_ValueNode read GetField; default;

  end;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_DataBlockUnknowns
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_DataBlockUnknowns - declaration
===============================================================================}

  TSIIBin_DataBlockUnknowns = class(TSIIBin_DataBlock)
  protected
    Function CreateValueNode(ValueType: TSIIBin_ValueType; FieldIndex: Integer; Stream: TStream): TSIIBin_ValueNode; override;
  public
    class Function ValueTypeSupported(ValueType: TSIIBin_ValueType): Boolean; override;
  end;

implementation

uses
  SysUtils,
  AuxExceptions, ExplicitStringLists,
  SII_Decode_Utils,
  SII_Decode_ValueNode_00000001,
  SII_Decode_ValueNode_00000002,
  SII_Decode_ValueNode_00000003,
  SII_Decode_ValueNode_00000004,
  SII_Decode_ValueNode_00000005,
  SII_Decode_ValueNode_00000006,
  SII_Decode_ValueNode_00000007,
  SII_Decode_ValueNode_00000008,
  SII_Decode_ValueNode_00000009,
  SII_Decode_ValueNode_0000000A,
  SII_Decode_ValueNode_00000011,
  SII_Decode_ValueNode_00000012,
  SII_Decode_ValueNode_00000017,
  SII_Decode_ValueNode_00000018,
  SII_Decode_ValueNode_00000019,
  SII_Decode_ValueNode_0000001A,
  SII_Decode_ValueNode_00000025,
  SII_Decode_ValueNode_00000026,
  SII_Decode_ValueNode_00000027,
  SII_Decode_ValueNode_00000028,
  SII_Decode_ValueNode_00000029,
  SII_Decode_ValueNode_0000002A,
  SII_Decode_ValueNode_0000002B,
  SII_Decode_ValueNode_0000002C,
  SII_Decode_ValueNode_0000002F,
  SII_Decode_ValueNode_00000031,
  SII_Decode_ValueNode_00000032,
  SII_Decode_ValueNode_00000033,
  SII_Decode_ValueNode_00000034,
  SII_Decode_ValueNode_00000035,
  SII_Decode_ValueNode_00000036,
  SII_Decode_ValueNode_00000037,
  SII_Decode_ValueNode_00000038,
  SII_Decode_ValueNode_00000039,
  SII_Decode_ValueNode_0000003A;

{===============================================================================
--------------------------------------------------------------------------------
                               TSIIBin_DataBlock
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_DataBlock - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_DataBlock - private methods
-------------------------------------------------------------------------------}

Function TSIIBin_DataBlock.GetFieldCount: Integer;
begin
Result := fFields.Count;
end;

//------------------------------------------------------------------------------

Function TSIIBin_DataBlock.GetField(Index: Integer): TSIIBin_ValueNode;
begin
If (Index >= 0) and (Index < fFields.Count) then
  Result := TSIIBin_ValueNode(fFields[Index])
else
  raise EIndexOutOfBounds.Create(Index,Self,'GetField');
end;

{-------------------------------------------------------------------------------
    TSIIBin_DataBlock - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_DataBlock.CreateValueNode(ValueType: TSIIBin_ValueType; FieldIndex: Integer; Stream: TStream): TSIIBin_ValueNode;
begin
case ValueType of
  $00000001:  Result := TSIIBin_ValueNode_00000001.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000002:  Result := TSIIBin_ValueNode_00000002.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000003:  Result := TSIIBin_ValueNode_00000003.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000004:  Result := TSIIBin_ValueNode_00000004.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000005:  Result := TSIIBin_ValueNode_00000005.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000006:  Result := TSIIBin_ValueNode_00000006.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000007:  Result := TSIIBin_ValueNode_00000007.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000009:  Result := TSIIBin_ValueNode_00000009.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $0000000A:  Result := TSIIBin_ValueNode_0000000A.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000011:  Result := TSIIBin_ValueNode_00000011.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000012:  Result := TSIIBin_ValueNode_00000012.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000017:  Result := TSIIBin_ValueNode_00000017.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000018:  Result := TSIIBin_ValueNode_00000018.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000019:  Result := TSIIBin_ValueNode_00000019.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $0000001A:  Result := TSIIBin_ValueNode_0000001A.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000025:  Result := TSIIBin_ValueNode_00000025.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000026:  Result := TSIIBin_ValueNode_00000026.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000027:  Result := TSIIBin_ValueNode_00000027.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000028:  Result := TSIIBin_ValueNode_00000028.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $0000002B:  Result := TSIIBin_ValueNode_0000002B.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $0000002C:  Result := TSIIBin_ValueNode_0000002C.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $0000002F:  Result := TSIIBin_ValueNode_0000002F.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000031:  Result := TSIIBin_ValueNode_00000031.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000032:  Result := TSIIBin_ValueNode_00000032.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000033:  Result := TSIIBin_ValueNode_00000033.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000034:  Result := TSIIBin_ValueNode_00000034.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000035:  Result := TSIIBin_ValueNode_00000035.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000036:  Result := TSIIBin_ValueNode_00000036.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000037:  Result := TSIIBin_ValueNode_00000037.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000039,
  $0000003B,
  $0000003D:  Result := TSIIBin_ValueNode_00000039.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $0000003A,
  $0000003C:  Result := TSIIBin_ValueNode_0000003A.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
else
  raise EGeneralException.CreateFmt('Unknown value type: %s(%d) at %d.',[fStructure.Fields[FieldIndex].ValueName,
    fStructure.Fields[FieldIndex].ValueType,Stream.Position],Self,'CreateValueNode');
end;
end;

{-------------------------------------------------------------------------------
    TSIIBin_DataBlock - public methods
-------------------------------------------------------------------------------}

class Function TSIIBin_DataBlock.ValueTypeSupported(ValueType: TSIIBin_ValueType): Boolean;
begin
Result := ValueType in [$01..$06,$07,$09,$0A,$11,$12,$17..$1A,$25..$28,$2B,$2C,$2F,$31..$37,$39..$3D];
end;

//------------------------------------------------------------------------------

constructor TSIIBin_DataBlock.Create(FormatVersion: UInt32; Structure: TSIIBin_Structure);
begin
inherited Create;
fFormatVersion := FormatVersion;
fStructure := Structure;
fName := fStructure.Name;
fFields := TObjectList.Create(True);
end;

//------------------------------------------------------------------------------

destructor TSIIBin_DataBlock.Destroy;
begin
fFields.Free;
inherited;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_DataBlock.Load(Stream: TStream);
var
  i:  Integer;
begin
SIIBin_LoadID(Stream,fBlockID);
SIIBin_DecodeID(fBlockID);
For i := Low(fStructure.Fields) to High(fStructure.Fields) do
  fFields.Add(CreateValueNode(fStructure.Fields[i].ValueType,i,Stream));
end;

//------------------------------------------------------------------------------

Function TSIIBin_DataBlock.AsString: AnsiString;
var
  i:  Integer;
begin
with TAnsiStringList.Create do
try
  AddDef(Format('%s : %s {',[fName,SIIBin_IDToStr(fBlockID,fFormatVersion < 2)]));
  For i := 0 to Pred(fFields.Count) do
    Add(TSIIBin_ValueNode(fFields[i]).AsLine(1));
  AddDef('}');
  Result := Text;
finally
  Free;
end;
end;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_DataBlockUnknowns
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_DataBlockUnknowns - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_DataBlockUnknowns - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_DataBlockUnknowns.CreateValueNode(ValueType: TSIIBin_ValueType; FieldIndex: Integer; Stream: TStream): TSIIBin_ValueNode;
begin
case ValueType of
  $00000008:  Result := TSIIBin_ValueNode_00000008.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000029:  Result := TSIIBin_ValueNode_00000029.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $0000002A:  Result := TSIIBin_ValueNode_0000002A.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $00000038:  Result := TSIIBin_ValueNode_00000038.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
  $0000003E:  Result := TSIIBin_ValueNode_0000003A.Create(fFormatVersion,fStructure.Fields[FieldIndex],Stream);
else
  Result := inherited CreateValueNode(ValueType,FieldIndex,Stream);
end;
end;

{-------------------------------------------------------------------------------
    TSIIBin_DataBlockUnknowns - public methods
-------------------------------------------------------------------------------}

class Function TSIIBin_DataBlockUnknowns.ValueTypeSupported(ValueType: TSIIBin_ValueType): Boolean;
begin
Result := inherited ValueTypeSupported(ValueType) or (ValueType in [$08,$29,$2A,$38,$3E]);
end;

end.

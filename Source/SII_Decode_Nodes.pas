{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_Nodes;

{$INCLUDE '.\SII_Decode_defs.inc'}

interface

uses
  Classes, Contnrs,
  AuxTypes, SII_Decode_Common;

{==============================================================================}
{------------------------------------------------------------------------------}
{                                TSIIBin_Value                                 }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value - declaration                                                }
{==============================================================================}
type
  TSIIBin_Value = class(TObject)
  private
    fName:  AnsiString;
  protected
    Function GetValueType: TSIIBin_ValueType; virtual;
    procedure Load(Stream: TStream); virtual; abstract;
    procedure Initialize; virtual;
    procedure Finalize; virtual;
  public
    constructor Create(const Name: AnsiString; Stream: TStream);
    destructor Destroy; override;
    Function AsString: String; virtual;
    Function AsLine(IndentCount: Integer = 0): String; virtual;
  published
    property ValueType: TSIIBin_ValueType read GetValueType;
    property Name: AnsiString read fName;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000001                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000001 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000001 = class(TSIIBin_Value)
  private
    fValue: AnsiString;
  protected
    procedure Initialize; override;
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000002                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000002 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000002 = class(TSIIBin_Value)
  private
    fValue: array of AnsiString;
  protected
    procedure Initialize; override;
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
    Function AsLine(IndentCount: Integer = 0): String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000003                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000003 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000003 = class(TSIIBin_Value)
  private
    fValue:     UInt64;
    fValueStr:  AnsiString;
  protected
    procedure Initialize; override;
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000004                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000004 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000004 = class(TSIIBin_Value)
  private
    fValue:     array of UInt64;
    fValueStr:  array of AnsiString;
  protected
    procedure Initialize; override;
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
    Function AsLine(IndentCount: Integer = 0): String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000005                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000005 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000005 = class(TSIIBin_Value)
  private
    fValue: Single;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000006                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000006 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000006 = class(TSIIBin_Value)
  private
    fValue: array of Single;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
    Function AsLine(IndentCount: Integer = 0): String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000009                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000009 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000009 = class(TSIIBin_Value)
  private
    fValue: TSIIBin_Value_Vec3s;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000011                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000011 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000011 = class(TSIIBin_Value)
  private
    fValue: TSIIBin_Value_Vec3i;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000012                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000012 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000012 = class(TSIIBin_Value)
  private
    fValue: array of TSIIBin_Value_Vec3i;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
    Function AsLine(IndentCount: Integer = 0): String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000018                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000018 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000018 = class(TSIIBin_Value)
  private
    fValue: array of TSIIBin_Value_Vec4s;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
    Function AsLine(IndentCount: Integer = 0): String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000019                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000019 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000019 = class(TSIIBin_Value)
  private
    fValue: TSIIBin_Value_Vec8s;
  protected
    procedure Initialize; override;
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
  end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_0000001A                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_0000001A - declaration                                       }
{==============================================================================}
  TSIIBin_Value_0000001A = class(TSIIBin_Value)
  private
    fValue: array of TSIIBin_Value_Vec8s;
  protected
    procedure Initialize; override;
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
    Function AsLine(IndentCount: Integer = 0): String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000025                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000025 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000025 = class(TSIIBin_Value)
  private
    fValue: Int32;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000026                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000026 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000026 = class(TSIIBin_Value)
  private
    fValue: array of Int32;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
    Function AsLine(IndentCount: Integer = 0): String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000027                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000027 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000027 = class(TSIIBin_Value)
  private
    fValue: UInt32;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000028                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000028 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000028 = class(TSIIBin_Value)
  private
    fValue: array of UInt32;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
    Function AsLine(IndentCount: Integer = 0): String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_0000002B                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_0000002B - declaration                                       }
{==============================================================================}
  TSIIBin_Value_0000002B = class(TSIIBin_Value)
  private
    fValue: UInt16;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_0000002C                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_0000002C - declaration                                       }
{==============================================================================}
  TSIIBin_Value_0000002C = class(TSIIBin_Value)
  private
    fValue: array of UInt16;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
    Function AsLine(IndentCount: Integer = 0): String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000031                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000031 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000031 = class(TSIIBin_Value)
  private
    fValue: Int64;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000033                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000033 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000033 = class(TSIIBin_Value)
  private
    fValue: UInt64;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000034                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000034 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000034 = class(TSIIBin_Value)
  private
    fValue: array of UInt64;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
    Function AsLine(IndentCount: Integer = 0): String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000035                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000035 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000035 = class(TSIIBin_Value)
  private
    fValue: ByteBool;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000036                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000036 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000036 = class(TSIIBin_Value)
  private
    fValue: array of ByteBool;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
    Function AsLine(IndentCount: Integer = 0): String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000039                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000039 - declaration                                       }
{==============================================================================}
  TSIIBin_Value_00000039 = class(TSIIBin_Value)
  private
    fValue: TSIIBin_Value_ID;
  protected
    procedure Initialize; override;
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_0000003A                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_0000003A - declaration                                       }
{==============================================================================}
  TSIIBin_Value_0000003A = class(TSIIBin_Value)
  private
    fValue: array of TSIIBin_Value_ID;
  protected
    procedure Initialize; override;
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: String; override;
    Function AsLine(IndentCount: Integer = 0): String; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                              TSIIBin_DataBlock                               }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_DataBlock - declaration                                            }
{==============================================================================}
  TSIIBin_DataBlock = class(TObject)
  private
    fStructure: TSIIBin_Structure;
    fName:      AnsiString;
    fBlockID:   TSIIBin_Value_ID;
    fFields:    TObjectList;
    Function GetFieldCount: Integer;
    Function GetField(Index: Integer): TSIIBin_Value;
  public
    constructor Create(Structure: TSIIBin_Structure);
    destructor Destroy; override;
    procedure Load(Stream: TStream); virtual;
    Function AsString: String; virtual;
    property BlockID: TSIIBin_Value_ID read fBlockID;
    property Fields[Index: Integer]: TSIIBin_Value read GetField;
  published
    property Name: AnsiString read fName;
    property FieldCount: Integer read GetFieldCount;
  end;

implementation

uses
  SysUtils,
  BinaryStreaming;

{==============================================================================}
{------------------------------------------------------------------------------}
{                                TSIIBin_Value                                 }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value - implementation                                             }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value - protected methods                                          }
{------------------------------------------------------------------------------}

Function TSIIBin_Value.GetValueType: TSIIBin_ValueType;
begin
Result := 0;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value.Initialize;
begin
Exit;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value.Finalize;
begin
Exit;
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value - public methods                                             }
{------------------------------------------------------------------------------}

constructor TSIIBin_Value.Create(const Name: AnsiString; Stream: TStream);
begin
inherited Create;
fName := Name;
Load(Stream);
Initialize;
end;

//------------------------------------------------------------------------------

destructor TSIIBin_Value.Destroy;
begin
Finalize;
inherited;
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value.AsString: String;
begin
Result := '';
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value.AsLine(IndentCount: Integer = 0): String;
begin
Result := StringOfChar(' ',IndentCount) + fName + ': ' + AsString;
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000001                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000001 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000001 - protected methods                                 }
{------------------------------------------------------------------------------}

procedure TSIIBin_Value_00000001.Initialize;
begin
SIIBin_RectifyString(fValue);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_00000001.GetValueType: TSIIBin_ValueType;
begin
Result := $00000001;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000001.Load(Stream: TStream);
begin
SIIBin_LoadString(Stream,fValue);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000001 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000001.AsString: String;
begin
If SIIBin_IsLimitedAlphabet(fValue) and (Length(fValue) > 0) then
  Result := Format('%s',[fValue])
else
  Result := Format('"%s"',[fValue])
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000002                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000002 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000002 - protected methods                                 }
{------------------------------------------------------------------------------}

procedure TSIIBin_Value_00000002.Initialize;
var
  i:  Integer;
begin
For i := Low(fValue) to High(fValue) do
  SIIBin_RectifyString(fValue[i]);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_00000002.GetValueType: TSIIBin_ValueType;
begin
Result := $00000002;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000002.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  SIIBin_LoadString(Stream,fValue[i]);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000002 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000002.AsString: String;
begin
Result := Format('%d',[Length(fValue)]);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_00000002.AsLine(IndentCount: Integer = 0): String;
var
  i:  Integer;
begin
Result := StringOfChar(' ',IndentCount) + Format('%s: %d',[fName,Length(fValue)]);
For i := Low(fValue) to High(fValue) do
  If SIIBin_IsLimitedAlphabet(fValue[i]) and (Length(fValue[i]) > 0) then
    Result := Result + sLineBreak + StringOfChar(' ',IndentCount) +
              Format('%s[%d]: %s',[fName,i,fValue[i]])
  else
    Result := Result + sLineBreak + StringOfChar(' ',IndentCount) +
              Format('%s[%d]: "%s"',[fName,i,fValue[i]]);
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000003                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000003 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000003 - protected methods                                 }
{------------------------------------------------------------------------------}

procedure TSIIBin_Value_00000003.Initialize;
begin
fValueStr := SIIBin_DecodeID(fValue);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_00000003.GetValueType: TSIIBin_ValueType;
begin
Result := $00000003;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000003.Load(Stream: TStream);
begin
fValue := Stream_ReadUInt64(Stream);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000003 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000003.AsString: String;
begin
If fValue <> 0 then
  Result := self.fValueStr
else
  Result := '""';
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000004                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000004 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000004 - protected methods                                 }
{------------------------------------------------------------------------------}

procedure TSIIBin_Value_00000004.Initialize;
var
  i:  Integer;
begin
For i := Low(fValue) to High(fValue) do
  fValueStr[i] := SIIBin_DecodeID(fValue[i]);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_00000004.GetValueType: TSIIBin_ValueType;
begin
Result := $00000004;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000004.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
SetLength(fValueStr,Length(fValue));
For i := Low(fValue) to High(fValue) do
  fValue[i] := Stream_ReadUInt64(Stream);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000004 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000004.AsString: String;
begin
Result := Format('%d',[Length(fValue)]);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_00000004.AsLine(IndentCount: Integer = 0): String;
var
  i:  Integer;
begin
Result := StringOfChar(' ',IndentCount) + Format('%s: %d',[fName,Length(fValue)]);
For i := Low(fValue) to High(fValue) do
  If fValue[i] <> 0 then
    Result := Result + sLineBreak + StringOfChar(' ',IndentCount) +
              Format('%s[%d]: %s',[fName,i,fValueStr[i]])
  else
    Result := Result + sLineBreak + StringOfChar(' ',IndentCount) +
              Format('%s[%d]: ""',[fName,i])
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000005                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000005 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000005 - protected methods                                 }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000005.GetValueType: TSIIBin_ValueType;
begin
Result := $00000005;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000005.Load(Stream: TStream);
begin
fValue := Stream_ReadFloat32(Stream);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000005 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000005.AsString: String;
begin
Result := SIIBin_SingleToStr(fValue);
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000006                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000006 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000006 - protected methods                                 }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000006.GetValueType: TSIIBin_ValueType;
begin
Result := $00000006;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000006.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  fValue[i] := Stream_ReadFloat32(Stream);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000006 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000006.AsString: String;
begin
Result := Format('%d',[Length(fValue)]);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_00000006.AsLine(IndentCount: Integer = 0): String;
var
  i:  Integer;
begin
Result := StringOfChar(' ',IndentCount) + Format('%s: %d',[fName,Length(fValue)]);
For i := Low(fValue) to High(fValue) do
  Result := Result + sLineBreak + StringOfChar(' ',IndentCount) +
            Format('%s[%d]: %s',[fName,i,SIIBin_SingleToStr(fValue[i])]);
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000009                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000009 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000009 - protected methods                                 }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000009.GetValueType: TSIIBin_ValueType;
begin
Result := $00000009;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000009.Load(Stream: TStream);
begin
Stream_ReadBuffer(Stream,fValue,SizeOf(TSIIBin_Value_Vec3s));
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000009 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000009.AsString: String;
begin
Result := Format('(%s, %s, %s)',[SIIBin_SingleToStr(fValue[0]),
                                 SIIBin_SingleToStr(fValue[1]),
                                 SIIBin_SingleToStr(fValue[2])]);
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000011                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000011 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000011 - protected methods                                 }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000011.GetValueType: TSIIBin_ValueType;
begin
Result := $00000011;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000011.Load(Stream: TStream);
begin
Stream_ReadBuffer(Stream,fValue,SizeOf(TSIIBin_Value_Vec3s));
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000011 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000011.AsString: String;
begin
Result := Format('(%d, %d, %d)',[fValue[0],fValue[1],fValue[2]]);
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000012                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000012 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000012 - protected methods                                 }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000012.GetValueType: TSIIBin_ValueType;
begin
Result := $00000012;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000012.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  Stream_ReadBuffer(Stream,fValue[i],SizeOf(TSIIBin_Value_Vec3i));
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000012 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000012.AsString: String;
begin
Result := Format('%d',[Length(fValue)]);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_00000012.AsLine(IndentCount: Integer = 0): String;
var
  i:  Integer;
begin
Result := StringOfChar(' ',IndentCount) + Format('%s: %d',[fName,Length(fValue)]);
For i := Low(fValue) to High(fValue) do
  Result := Result + sLineBreak + StringOfChar(' ',IndentCount) +
    Format('%s[%d]: (%d, %d, %d)',[fName,i,fValue[i][0],fValue[i][1],fValue[i][2]]);
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000018                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000018 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000018 - protected methods                                 }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000018.GetValueType: TSIIBin_ValueType;
begin
Result := $00000018;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000018.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  Stream_ReadBuffer(Stream,fValue[i],SizeOf(TSIIBin_Value_Vec4s));
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000018 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000018.AsString: String;
begin
Result := Format('%d',[Length(fValue)]);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_00000018.AsLine(IndentCount: Integer = 0): String;
var
  i:  Integer;
begin
Result := StringOfChar(' ',IndentCount) + Format('%s: %d',[fName,Length(fValue)]);
For i := Low(fValue) to High(fValue) do
  Result := Result + sLineBreak + StringOfChar(' ',IndentCount) +
    Format('%s[%d]: (%s; %s, %s, %s)',[fName,i,SIIBin_SingleToStr(fValue[i][0]),
                                               SIIBin_SingleToStr(fValue[i][1]),
                                               SIIBin_SingleToStr(fValue[i][2]),
                                               SIIBin_SingleToStr(fValue[i][3])]);
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000019                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000019 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000019 - protected methods                                 }
{------------------------------------------------------------------------------}

procedure TSIIBin_Value_00000019.Initialize;
var
  Coef: Integer;
begin
Coef := Trunc(fValue[3]);
fValue[0] := fValue[0] + Integer(((Coef and $FFF) - 2048) shl 9);
fValue[2] := fValue[2] + Integer((((Coef shr 12) and $FFF) - 2048) shl 9);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_00000019.GetValueType: TSIIBin_ValueType;
begin
Result := $00000019;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000019.Load(Stream: TStream);
begin
Stream_ReadBuffer(Stream,fValue,SizeOf(TSIIBin_Value_Vec8s));
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000019 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000019.AsString: String;
begin
Result := Format('(%s, %s, %s) (%s; %s, %s, %s)',
                 [SIIBin_SingleToStr(fValue[0]),SIIBin_SingleToStr(fValue[1]),
                  SIIBin_SingleToStr(fValue[2]),SIIBin_SingleToStr(fValue[4]),
                  SIIBin_SingleToStr(fValue[5]),SIIBin_SingleToStr(fValue[6]),
                  SIIBin_SingleToStr(fValue[7])]);
end;



{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_0000001A                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_0000001A - declaration                                       }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_0000001A - protected methods                                 }
{------------------------------------------------------------------------------}

procedure TSIIBin_Value_0000001A.Initialize;
var
  i,Coef: Integer;
begin
For i := Low(fValue) to High(fValue) do
  begin
    Coef := Trunc(fValue[i][3]);
    fValue[i][0] := fValue[i][0] + Integer(((Coef and $FFF) - 2048) shl 9);
    fValue[i][2] := fValue[i][2] + Integer((((Coef shr 12) and $FFF) - 2048) shl 9);
  end;
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_0000001A.GetValueType: TSIIBin_ValueType;
begin
Result := $0000001A;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_0000001A.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  Stream_ReadBuffer(Stream,fValue[i],SizeOf(TSIIBin_Value_Vec8s));
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_0000001A - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_0000001A.AsString: String;
begin
Result := Format('%d',[Length(fValue)]);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_0000001A.AsLine(IndentCount: Integer = 0): String;
var
  i:  Integer;
begin
Result := StringOfChar(' ',IndentCount) + Format('%s: %d',[fName,Length(fValue)]);
For i := Low(fValue) to High(fValue) do
  Result := Result + sLineBreak + StringOfChar(' ',IndentCount) + Format('%s[%d]: (%s, %s, %s) (%s; %s, %s, %s)',
              [fName,i,SIIBin_SingleToStr(fValue[i][0]),SIIBin_SingleToStr(fValue[i][1]),SIIBin_SingleToStr(fValue[i][2]),
               SIIBin_SingleToStr(fValue[i][4]),SIIBin_SingleToStr(fValue[i][5]),
               SIIBin_SingleToStr(fValue[i][6]),SIIBin_SingleToStr(fValue[i][7])]);
end;



{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000025                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000025 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000025 - protected methods                                 }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000025.GetValueType: TSIIBin_ValueType;
begin
Result := $00000025;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000025.Load(Stream: TStream);
begin
fValue := Stream_ReadInt32(Stream);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000025 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000025.AsString: String;
begin
Result := Format('%d',[fValue]);
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000026                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000026 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000026 - protected methods                                 }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000026.GetValueType: TSIIBin_ValueType;
begin
Result := $00000026;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000026.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  fValue[i] := Stream_ReadInt32(Stream);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000026 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000026.AsString: String;
begin
Result := Format('%d',[Length(fValue)]);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_00000026.AsLine(IndentCount: Integer = 0): String;
var
  i:  Integer;
begin
Result := StringOfChar(' ',IndentCount) + Format('%s: %d',[fName,Length(fValue)]);
For i := Low(fValue) to High(fValue) do
  Result := Result + sLineBreak + StringOfChar(' ',IndentCount) +
            Format('%s[%d]: %d',[fName,i,fValue[i]]);
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000027                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000027 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000027 - protected methods                                 }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000027.GetValueType: TSIIBin_ValueType;
begin
Result := $00000027;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000027.Load(Stream: TStream);
begin
fValue := Stream_ReadUInt32(Stream);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000027 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000027.AsString: String;
begin
If fValue <> $FFFFFFFF then
  Result := Format('%u',[fValue])
else
  Result := 'nil';
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000028                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000028 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000028 - protected methods                                 }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000028.GetValueType: TSIIBin_ValueType;
begin
Result := $00000028;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000028.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  fValue[i] := Stream_ReadUInt32(Stream);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000028 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000028.AsString: String;
begin
Result := Format('%d',[Length(fValue)]);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_00000028.AsLine(IndentCount: Integer = 0): String;
var
  i:  Integer;
begin
Result := StringOfChar(' ',IndentCount) + Format('%s: %d',[fName,Length(fValue)]);
For i := Low(fValue) to High(fValue) do
  begin
    Result := Result + sLineBreak + StringOfChar(' ',IndentCount);
    If fValue[i] <> $FFFFFFFF then
      Result := Result + Format('%s[%d]: %u',[fName,i,fValue[i]])
    else
      Result := Result + Format('%s[%d]: nil',[fName,i]);
  end;
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_0000002B                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_0000002B - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_0000002B - protected methods                                 }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_0000002B.GetValueType: TSIIBin_ValueType;
begin
Result := $0000002B;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_0000002B.Load(Stream: TStream);
begin
fValue := Stream_ReadUInt16(Stream);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_0000002B - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_0000002B.AsString: String;
begin
If fValue <> $FFFF then
  Result := Format('%u',[fValue])
else
  Result := 'nil';
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_0000002C                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_0000002C - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_0000002C - protected methods                                 }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_0000002C.GetValueType: TSIIBin_ValueType;
begin
Result := $0000002C;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_0000002C.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  fValue[i] := Stream_ReadUInt16(Stream);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_0000002C - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_0000002C.AsString: String;
begin
Result := Format('%d',[Length(fValue)]);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_0000002C.AsLine(IndentCount: Integer = 0): String;
var
  i:  Integer;
begin
Result := StringOfChar(' ',IndentCount) + Format('%s: %d',[fName,Length(fValue)]);
For i := Low(fValue) to High(fValue) do
  If fValue[i] <> $FFFF then
    Result := Result + sLineBreak + StringOfChar(' ',IndentCount) +
              Format('%s[%d]: %u',[fName,i,fValue[i]])
  else
    Result := Result + sLineBreak + StringOfChar(' ',IndentCount) +
              Format('%s[%d]: nil',[fName,i])
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000031                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000031 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000031 - protected methods                                 }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000031.GetValueType: TSIIBin_ValueType;
begin
Result := $00000031;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000031.Load(Stream: TStream);
begin
fValue := Stream_ReadInt64(Stream);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000031 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000031.AsString: String;
begin
Result := Format('%d',[fValue])
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000033                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000033 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000033 - protected methods                                 }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000033.GetValueType: TSIIBin_ValueType;
begin
Result := $00000033;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000033.Load(Stream: TStream);
begin
fValue := Stream_ReadUInt64(Stream);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000033 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000033.AsString: String;
begin
If (Int64Rec(fValue).Lo <> $FFFFFFFF) and (Int64Rec(fValue).Hi <> $FFFFFFFF) then
  Result := Format('%u',[fValue])
else
  Result := 'nil';
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000034                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000034 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000034 - protected methods                                 }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000034.GetValueType: TSIIBin_ValueType;
begin
Result := $00000034;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000034.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  fValue[i] := Stream_ReadUInt64(Stream);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000034 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000034.AsString: String;
begin
Result := Format('%d',[Length(fValue)]);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_00000034.AsLine(IndentCount: Integer = 0): String;
var
  i:  Integer;
begin
Result := StringOfChar(' ',IndentCount) + Format('%s: %d',[fName,Length(fValue)]);
For i := Low(fValue) to High(fValue) do
  If (Int64Rec(fValue[i]).Lo <> $FFFFFFFF) and (Int64Rec(fValue[i]).Hi <> $FFFFFFFF) then
    Result := Result + sLineBreak + StringOfChar(' ',IndentCount) +
              Format('%s[%d]: %u',[fName,i,fValue[i]])
  else
    Result := Result + sLineBreak + StringOfChar(' ',IndentCount) +
              Format('%s[%d]: nil',[fName,i])
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000035                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000035 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000035 - protected methods                                 }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000035.GetValueType: TSIIBin_ValueType;
begin
Result := $00000035;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000035.Load(Stream: TStream);
begin
fValue := Stream_ReadUInt8(Stream) <> 0;
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000035 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000035.AsString: String;
begin
Result := AnsiLowerCase(BoolToStr(fValue,True));
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000036                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000036 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000036 - protected methods                                 }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000036.GetValueType: TSIIBin_ValueType;
begin
Result := $00000036;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000036.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  fValue[i] := Stream_ReadUInt8(Stream) <> 0;
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000036 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000036.AsString: String;
begin
Result := Format('%d',[Length(fValue)]);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_00000036.AsLine(IndentCount: Integer = 0): String;
var
  i:  Integer;
begin
Result := StringOfChar(' ',IndentCount) + Format('%s: %d',[fName,Length(fValue)]);
For i := Low(fValue) to High(fValue) do
  Result := Result + sLineBreak + StringOfChar(' ',IndentCount) +
    Format('%s[%d]: ',[fName,i]) + AnsiLowerCase(BoolToStr(fValue[i],True));
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_00000039                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_00000039 - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000039 - protected methods                                 }
{------------------------------------------------------------------------------}

procedure TSIIBin_Value_00000039.Initialize;
begin
If not (fValue.Length in [0,$FF]) then
  SIIBin_DecodeID(fValue);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_00000039.GetValueType: TSIIBin_ValueType;
begin
Result := $00000039;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_00000039.Load(Stream: TStream);
begin
SIIBin_LoadID(Stream,fValue);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_00000039 - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_00000039.AsString: String;
begin
Result := SIIBin_IDToStr(fValue);
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                            TSIIBin_Value_0000003A                            }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_Value_0000003A - implementation                                    }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_Value_0000003A - protected methods                                 }
{------------------------------------------------------------------------------}

procedure TSIIBin_Value_0000003A.Initialize;
var
  i:  Integer;
begin
For i := Low(fValue) to High(fValue) do
  If not (fValue[i].Length in [0,$FF]) then
    SIIBin_DecodeID(fValue[i]);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_0000003A.GetValueType: TSIIBin_ValueType;
begin
Result := $0000003A;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_Value_0000003A.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  SIIBin_LoadID(Stream,fValue[i]);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_Value_0000003A - public methods                                    }
{------------------------------------------------------------------------------}

Function TSIIBin_Value_0000003A.AsString: String;
begin
Result := Format('%d',[Length(fValue)]);
end;

//------------------------------------------------------------------------------

Function TSIIBin_Value_0000003A.AsLine(IndentCount: Integer = 0): String;
var
  i:  Integer;
begin
Result := StringOfChar(' ',IndentCount) + Format('%s: %d',[fName,Length(fValue)]);
For i := Low(fValue) to High(fValue) do
  Result := Result + sLineBreak + StringOfChar(' ',IndentCount) +
            Format('%s[%d]: %s',[fName,i,SIIBin_IDToStr(fValue[i])]);
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                              TSIIBin_DataBlock                               }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBin_DataBlock - implementation                                         }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBin_DataBlock - private methods                                        }
{------------------------------------------------------------------------------}

Function TSIIBin_DataBlock.GetFieldCount: Integer;
begin
Result := fFields.Count;
end;

//------------------------------------------------------------------------------

Function TSIIBin_DataBlock.GetField(Index: Integer): TSIIBin_Value;
begin
If (Index >= 0) and (Index < fFields.Count) then
  Result := TSIIBin_Value(fFields[Index])
else
  raise Exception.CreateFmt('TSIIBin_DataBlock.GetField: Index (%d) out of bounds.',[Index]);
end;

{------------------------------------------------------------------------------}
{   TSIIBin_DataBlock - public methods                                         }
{------------------------------------------------------------------------------}

constructor TSIIBin_DataBlock.Create(Structure: TSIIBin_Structure);
begin
inherited Create;
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
  i:        Integer;
  FieldObj: TSIIBin_Value;
begin
SIIBin_LoadID(Stream,fBlockID);
SIIBin_DecodeID(fBlockID);
For i := Low(fStructure.Fields) to High(fStructure.Fields) do
  begin
    case fStructure.Fields[i].ValueType of
      $00000001:  FieldObj := TSIIBin_Value_00000001.Create(fStructure.Fields[i].ValueName,Stream);
      $00000002:  FieldObj := TSIIBin_Value_00000002.Create(fStructure.Fields[i].ValueName,Stream);
      $00000003:  FieldObj := TSIIBin_Value_00000003.Create(fStructure.Fields[i].ValueName,Stream);
      $00000004:  FieldObj := TSIIBin_Value_00000004.Create(fStructure.Fields[i].ValueName,Stream);
      $00000005:  FieldObj := TSIIBin_Value_00000005.Create(fStructure.Fields[i].ValueName,Stream);
      $00000006:  FieldObj := TSIIBin_Value_00000006.Create(fStructure.Fields[i].ValueName,Stream);
      $00000009:  FieldObj := TSIIBin_Value_00000009.Create(fStructure.Fields[i].ValueName,Stream);
      $00000011:  FieldObj := TSIIBin_Value_00000011.Create(fStructure.Fields[i].ValueName,Stream);
      $00000012:  FieldObj := TSIIBin_Value_00000012.Create(fStructure.Fields[i].ValueName,Stream);
      $00000018:  FieldObj := TSIIBin_Value_00000018.Create(fStructure.Fields[i].ValueName,Stream);
      $00000019:  FieldObj := TSIIBin_Value_00000019.Create(fStructure.Fields[i].ValueName,Stream);
      $0000001A:  FieldObj := TSIIBin_Value_0000001A.Create(fStructure.Fields[i].ValueName,Stream);
      $00000025:  FieldObj := TSIIBin_Value_00000025.Create(fStructure.Fields[i].ValueName,Stream);
      $00000026:  FieldObj := TSIIBin_Value_00000026.Create(fStructure.Fields[i].ValueName,Stream);
      $00000027:  FieldObj := TSIIBin_Value_00000027.Create(fStructure.Fields[i].ValueName,Stream);
      $00000028:  FieldObj := TSIIBin_Value_00000028.Create(fStructure.Fields[i].ValueName,Stream);
      $0000002B:  FieldObj := TSIIBin_Value_0000002B.Create(fStructure.Fields[i].ValueName,Stream);
      $0000002C:  FieldObj := TSIIBin_Value_0000002C.Create(fStructure.Fields[i].ValueName,Stream);
      $00000031:  FieldObj := TSIIBin_Value_00000031.Create(fStructure.Fields[i].ValueName,Stream);
      $00000033:  FieldObj := TSIIBin_Value_00000033.Create(fStructure.Fields[i].ValueName,Stream);
      $00000034:  FieldObj := TSIIBin_Value_00000034.Create(fStructure.Fields[i].ValueName,Stream);
      $00000035:  FieldObj := TSIIBin_Value_00000035.Create(fStructure.Fields[i].ValueName,Stream);
      $00000036:  FieldObj := TSIIBin_Value_00000036.Create(fStructure.Fields[i].ValueName,Stream);
      $00000039,
      $0000003B,
      $0000003D:  FieldObj := TSIIBin_Value_00000039.Create(fStructure.Fields[i].ValueName,Stream);
      $0000003A,
      $0000003C:  FieldObj := TSIIBin_Value_0000003A.Create(fStructure.Fields[i].ValueName,Stream);
    else
      raise Exception.CreateFmt('TSIIBin_DataBlock.Load: Unknown value type: %s(%d) at %d.',
            [fStructure.Fields[i].ValueName,fStructure.Fields[i].ValueType,Stream.Position]);
    end;
    fFields.Add(FieldObj);
  end;
end;

//------------------------------------------------------------------------------

Function TSIIBin_DataBlock.AsString: String;
var
  i:  Integer;
begin
with TStringList.Create do
try
  Add(Format('%s : %s {',[fName,SIIBin_IDToStr(fBlockID)]));
  For i := 0 to Pred(fFields.Count) do
    Add(TSIIBin_Value(fFields[i]).AsLine(1));
  Add('}');
  Result := Text;
finally
  Free;
end;
end;

end.


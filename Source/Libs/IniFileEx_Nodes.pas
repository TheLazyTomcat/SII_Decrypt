{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Extended INI file

    Internal ini file structure objects (nodes)

  ©František Milt 2018-10-21

  Version 1.0.3

  NOTE - library needs extensive testing

  Dependencies:
    AuxTypes            - github.com/ncs-sniper/Lib.AuxTypes
    AuxClasses          - github.com/ncs-sniper/Lib.AuxClasses
    CRC32               - github.com/ncs-sniper/Lib.CRC32
    StrRect             - github.com/ncs-sniper/Lib.StrRect
    BinTextEnc          - github.com/ncs-sniper/Lib.BinTextEnc
    FloatHex            - github.com/ncs-sniper/Lib.FloatHex
    ExplicitStringLists - github.com/ncs-sniper/Lib.ExplicitStringLists
    BinaryStreaming     - github.com/ncs-sniper/Lib.BinaryStreaming
    SimpleCompress      - github.com/ncs-sniper/Lib.SimpleCompress
    MemoryBuffer        - github.com/ncs-sniper/Lib.MemoryBuffer
    ZLib                - github.com/ncs-sniper/Bnd.ZLib
    ZLibUtils           - github.com/ncs-sniper/Lib.ZLibUtils
    AES                 - github.com/ncs-sniper/Lib.AES
  * SimpleCPUID         - github.com/ncs-sniper/Lib.SimpleCPUID
    ListSorters         - github.com/ncs-sniper/Lib.ListSorters

  SimpleCPUID is required only when PurePascal symbol is not defined.

===============================================================================}
unit IniFileEx_Nodes;

{$INCLUDE '.\IniFileEx_defs.inc'}

interface

uses
  AuxTypes, AuxClasses,
  IniFileEx_Common;

type
  // forward declarations
  TIFXKeyNode     = class;
  TIFXSectionNode = class;

  // internal events
  TIFXKeyNodeEvent = procedure(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode) of object;
  TIFXSectionNodeEvent = procedure(Sender: TObject; Section: TIFXSectionNode) of object;

{===============================================================================
--------------------------------------------------------------------------------
                                  TIFXKeyNode
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TIFXKeyNode - class declaration
===============================================================================}
  TIFXKeyNode = class(TCustomObject)
  private
    fSettingsPtr:   PIFXSettings;
    fName:          TIFXHashedString;
    fComment:       TIFXString;
    fInlineComment: TIFXString;
    fValueStr:      TIFXString;
    fValueEncoding: TIFXValueEncoding;
    fValueState:    TIFXValueState;
    fValueData:     TIFXValueData;
    procedure SetNameStr(const Value: TIFXString);
    Function GetValueStr: TIFXString;
    procedure SetValueStr(const Value: TIFXString);
    procedure SetValueEncoding(Value: TIFXValueEncoding);
    procedure SetValueType(Value: TIFXValueType);
    Function GetValueDataPtr: PIFXValueData;
  protected
    procedure FreeData; virtual;
    procedure SettingValue(ValueType: TIFXValueType); virtual;
    procedure EncodeValue; virtual;
    procedure EncodeBool; virtual;
    procedure EncodeInt8; virtual;
    procedure EncodeUInt8; virtual;
    procedure EncodeInt16; virtual;
    procedure EncodeUInt16; virtual;
    procedure EncodeInt32; virtual;
    procedure EncodeUInt32; virtual;
    procedure EncodeInt64; virtual;
    procedure EncodeUInt64; virtual;
    procedure EncodeFloat32; virtual;
    procedure EncodeFloat64; virtual;
    procedure EncodeDate; virtual;
    procedure EncodeTime; virtual;
    procedure EncodeDateTime; virtual;
    procedure EncodeString; virtual;
    procedure EncodeBinary; virtual; 
    Function GettingValue(ValueType: TIFXValueType): Boolean; virtual;
    procedure DecodeValue; virtual;
    procedure DecodeBool; virtual;
    procedure DecodeInt8; virtual;
    procedure DecodeUInt8; virtual;
    procedure DecodeInt16; virtual;
    procedure DecodeUInt16; virtual;
    procedure DecodeInt32; virtual;
    procedure DecodeUInt32; virtual;
    procedure DecodeInt64; virtual;
    procedure DecodeUInt64; virtual;
    procedure DecodeFloat32; virtual;
    procedure DecodeFloat64; virtual;
    procedure DecodeDate; virtual;
    procedure DecodeTime; virtual;
    procedure DecodeDateTime; virtual;
    procedure DecodeString; virtual;
    procedure DecodeBinary; virtual;
  public
    constructor Create(const KeyName: TIFXString; SettingsPtr: PIFXSettings); overload;
    constructor Create(SettingsPtr: PIFXSettings); overload;
    constructor CreateCopy(SourceNode: TIFXKeyNode); overload;
    destructor Destroy; override;
    procedure SetValueBool(Value: Boolean); virtual;
    procedure SetValueInt8(Value: Int8); virtual;
    procedure SetValueUInt8(Value: UInt8); virtual;
    procedure SetValueInt16(Value: Int16); virtual;
    procedure SetValueUInt16(Value: UInt16); virtual;
    procedure SetValueInt32(Value: Int32); virtual;
    procedure SetValueUInt32(Value: UInt32); virtual;
    procedure SetValueInt64(Value: Int64); virtual;
    procedure SetValueUInt64(Value: UInt64); virtual;
    procedure SetValueFloat32(Value: Float32); virtual;
    procedure SetValueFloat64(Value: Float64); virtual;
    procedure SetValueDate(Value: TDateTime); virtual;
    procedure SetValueTime(Value: TDateTime); virtual;
    procedure SetValueDateTime(Value: TDateTime); virtual;
    procedure SetValueString(const Value: TIFXString); virtual;
    procedure SetValueBinary(Value: Pointer; Size: TMemSize; MakeCopy: Boolean = False); virtual;
    Function GetValuePrepare(ValueType: TIFXValueType): Boolean; virtual;
    Function GetValueBool(out Value: Boolean): Boolean; virtual;
    Function GetValueInt8(out Value: Int8): Boolean; virtual;
    Function GetValueUInt8(out Value: UInt8): Boolean; virtual;
    Function GetValueInt16(out Value: Int16): Boolean; virtual;
    Function GetValueUInt16(out Value: UInt16): Boolean; virtual;
    Function GetValueInt32(out Value: Int32): Boolean; virtual;
    Function GetValueUInt32(out Value: UInt32): Boolean; virtual;
    Function GetValueInt64(out Value: Int64): Boolean; virtual;
    Function GetValueUInt64(out Value: UInt64): Boolean; virtual;
    Function GetValueFloat32(out Value: Float32): Boolean; virtual;
    Function GetValueFloat64(out Value: Float64): Boolean; virtual;
    Function GetValueDate(out Value: TDateTime): Boolean; virtual;
    Function GetValueTime(out Value: TDateTime): Boolean; virtual;
    Function GetValueDateTime(out Value: TDateTime): Boolean; virtual;
    Function GetValueString(out Value: TIFXString): Boolean; virtual;
    Function GetValueBinary(out Value: Pointer; out Size: TMemSize; MakeCopy: Boolean = False): Boolean; virtual;
    property SettingsPtr: PIFXSettings read fSettingsPtr write fSettingsPtr;
    property Name: TIFXHashedString read fName write fName;
    property NameStr: TIFXString read fName.Str write SetNameStr;
    property Comment: TIFXString read fComment write fComment;
    property InlineComment: TIFXString read fInlineComment write fInlineComment;
    property ValueStr: TIFXString read GetValueStr write SetValueStr;
    property ValueEncoding: TIFXValueEncoding read fValueEncoding write SetValueEncoding;
    property ValueState: TIFXValueState read fValueState;
    property ValueType: TIFXValueType read fValueData.ValueType write SetValueType;
    property ValueData: TIFXValueData read fValueData;
    property ValueDataPtr: PIFXValueData read GetValueDataPtr;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                                TIFXSectionNode
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TIFXSectionNode - class declaration
===============================================================================}
  TIFXSectionNode = class(TCustomListObject)
  private
    fKeys:          array of TIFXKeyNode;
    fCount:         Integer;
    fSettingsPtr:   PIFXSettings;
    fName:          TIFXHashedString;
    fComment:       TIFXString;
    fInlineComment: TIFXString;
    fOnKeyCreate:   TIFXKeyNodeEvent;
    fOnKeyDestroy:  TIFXKeyNodeEvent;
    Function GetKey(Index: Integer): TIFXKeyNode;
    procedure SetNameStr(const Value: TIFXString);
  protected
    Function GetCapacity: Integer; override;
    procedure SetCapacity(Value: Integer); override;
    Function GetCount: Integer; override;
    procedure SetCount(Value: Integer); override;
    Function CompareKeys(Idx1,Idx2: Integer): Integer; virtual;
  public
    constructor Create(const SectionName: TIFXString; SettingsPtr: PIFXSettings); overload;
    constructor Create(SettingsPtr: PIFXSettings); overload;
    constructor CreateCopy(SourceNode: TIFXSectionNode; OnKeyCreate: TIFXKeyNodeEvent); overload;
    destructor Destroy; override;
    Function LowIndex: Integer; override;
    Function HighIndex: Integer; override;
    Function IndexOfKey(const KeyName: TIFXString): Integer; virtual;
    Function FindKey(const KeyName: TIFXString; out KeyNode: TIFXKeyNode): Boolean; overload; virtual;
    Function FindKey(const KeyName: TIFXString): TIFXKeyNode; overload; virtual;
    Function AddKey(const KeyName: TIFXString): Integer; virtual;
    Function AddKeyNode(KeyNode: TIFXKeyNode): Integer; virtual;
    procedure ExchangeKeys(Idx1, Idx2: Integer); virtual;
    Function RemoveKey(const KeyName: TIFXString): Integer; virtual;
    procedure DeleteKey(Index: Integer); virtual;
    procedure ClearKeys; virtual;
    procedure SortKeys(Reversed: Boolean = False); virtual;
    property Keys[Index: Integer]: TIFXKeyNode read GetKey; default;
    property KeyCount: Integer read GetCount write SetCount;
    property SettingsPtr: PIFXSettings read fSettingsPtr write fSettingsPtr;
    property Name: TIFXHashedString read fName write fName;
    property NameStr: TIFXString read fName.Str write SetNameStr;
    property Comment: TIFXString read fComment write fComment;
    property InlineComment: TIFXString read fInlineComment write fInlineComment;
    property OnKeyCreate: TIFXKeyNodeEvent read fOnKeyCreate write fOnKeyCreate;
    property OnKeyDestroy: TIFXKeyNodeEvent read fOnKeyDestroy write fOnKeyDestroy;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                                  TIFXFileNode
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TIFXFileNode - class declaration
===============================================================================}
  TIFXFileNode = class(TCustomListObject)
  private
    fSections:          array of TIFXSectionNode;
    fCount:             Integer;
    fSettingsPtr:       PIFXSettings;
    fComment:           TIFXString;
    fOnKeyCreate:       TIFXKeyNodeEvent;
    fOnKeyDestroy:      TIFXKeyNodeEvent;
    fOnSectionCreate:   TIFXSectionNodeEvent;
    fOnSectionDestroy:  TIFXSectionNodeEvent;
    Function GetSection(Index: Integer): TIFXSectionNode;
  protected
    Function GetCapacity: Integer; override;
    procedure SetCapacity(Value: Integer); override;
    Function GetCount: Integer; override;
    procedure SetCount(Value: Integer); override;
    Function CompareSections(Idx1,Idx2: Integer): Integer; virtual;
    procedure KeyCreateHandler(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode); virtual;
    procedure KeyDestroyHandler(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode); virtual;
  public
    constructor Create(SettingsPtr: PIFXSettings); overload;
    constructor CreateCopy(SourceNode: TIFXFileNode; OnSectionCreate: TIFXSectionNodeEvent; OnKeyCreate: TIFXKeyNodeEvent); overload;
    destructor Destroy; override;
    Function LowIndex: Integer; override;
    Function HighIndex: Integer; override;
    Function IndexOfSection(const SectionName: TIFXString): Integer; virtual;
    Function FindSection(const SectionName: TIFXString; out SectionNode: TIFXSectionNode): Boolean; overload; virtual;
    Function FindSection(const SectionName: TIFXString): TIFXSectionNode; overload; virtual;
    Function AddSection(const SectionName: TIFXString): Integer; virtual;
    Function AddSectionNode(SectionNode: TIFXSectionNode): Integer; virtual;
    procedure ExchangeSections(Idx1, Idx2: Integer); virtual;
    Function RemoveSection(const SectionName: TIFXString): Integer; virtual;
    procedure DeleteSection(Index: Integer); virtual;
    procedure ClearSections; virtual;
    procedure SortSections(Reversed: Boolean = False); virtual;
    Function IndexOfKey(const SectionName, KeyName: TIFXString): TIFXNodeIndices; virtual;
    Function FindKey(const SectionName, KeyName: TIFXString; out KeyNode: TIFXKeyNode): Boolean; overload; virtual;
    Function FindKey(const SectionName, KeyName: TIFXString): TIFXKeyNode; overload; virtual;
    Function AddKey(const SectionName, KeyName: TIFXString): TIFXNodeIndices; virtual;
    procedure ExchangeKeys(const SectionName: TIFXString; KeyIdx1, KeyIdx2: Integer); virtual;
    Function RemoveKey(const SectionName, KeyName: TIFXString): TIFXNodeIndices; virtual;
    procedure DeleteKey(SectionIndex, KeyIndex: Integer); virtual;
    procedure ClearKeys(const SectionName: TIFXString); virtual;
    procedure SortKeys(const SectionName: TIFXString; Reversed: Boolean = False); virtual;
    property Sections[Index: Integer]: TIFXSectionNode read GetSection; default;
    property SectionCount: Integer read GetCount write SetCount;
    property SettingsPtr: PIFXSettings read fSettingsPtr write fSettingsPtr;
    property Comment: TIFXString read fComment write fComment;
    property OnKeyCreate: TIFXKeyNodeEvent read fOnKeyCreate write fOnKeyCreate;
    property OnKeyDestroy: TIFXKeyNodeEvent read fOnKeyDestroy write fOnKeyDestroy;
    property OnSectionCreate: TIFXSectionNodeEvent read fOnSectionCreate write fOnSectionCreate;
    property OnSectionDestroy: TIFXSectionNodeEvent read fOnSectionDestroy write fOnSectionDestroy;
  end;

implementation

uses
  SysUtils,
  BinTextEnc, FloatHex, ListSorters,
  //inline expansion...
{$IF not Defined(FPC) and Defined(CanInline)}CRC32, StrRect,{$IFEND}
  IniFileEx_Utils;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
{$ENDIF}

{===============================================================================
--------------------------------------------------------------------------------
                                  TIFXKeyNode
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TIFXKeyNode - class implementation
===============================================================================}

procedure TIFXKeyNode.SetNameStr(const Value: TIFXString);
begin
fName := IFXHashedString(Value);
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValueStr: TIFXString;
begin
If fValueState in [ivsNeedsEncode,ivsUndefined] then
  EncodeValue;
Result := fValueStr;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueStr(const Value: TIFXString);
begin
fValueStr := Value;
fValueEncoding := iveDefault;
fValueState := ivsNeedsDecode;
fValueData.ValueType := ivtUndecided;
FreeData;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueEncoding(Value: TIFXValueEncoding);
begin
If Value <> fValueEncoding then
  begin
    fValueEncoding := Value;      
    If fValueState = ivsReady then
      fValueState := ivsUndefined;
  end;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueType(Value: TIFXValueType);
begin
If Value <> fValueData.ValueType then
  begin
    fValueData.ValueType := Value;
    If fValueState = ivsReady then
      fValueState := ivsUndefined;
  end;
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValueDataPtr: PIFXValueData;
begin
Result := Addr(fValueData);
end;

//==============================================================================

procedure TIFXKeyNode.FreeData;
var
  OldValueType: TIFXValueType;
begin
fValueData.StringValue := '';
If Assigned(fValueData.BinaryValuePtr) then
  begin
    If fValueData.BinaryValueOwned then
      FreeMem(fValueData.BinaryValuePtr,fValueData.BinaryValueSize);
    fValueData.BinaryValuePtr := nil;
    fValueData.BinaryValueSize := 0;
  end;
OldValueType := fValueData.ValueType;
FillChar(fValueData,SizeOf(TIFXValueData),0);
fValueData.ValueType := OldValueType;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SettingValue(ValueType: TIFXValueType);
begin
If (fValueData.ValueType <> ValueType) or (fValueData.ValueType = ivtBinary) then
  FreeData;
fValueStr := '';
fValueState := ivsNeedsEncode;
fValueData.ValueType := ValueType;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.EncodeValue;
begin
case fValueData.ValueType of
  ivtBool:      EncodeBool;
  ivtInt8:      EncodeInt8;
  ivtUInt8:     EncodeUInt8;
  ivtInt16:     EncodeInt16;
  ivtUInt16:    EncodeUInt16;
  ivtInt32:     EncodeInt32;
  ivtUInt32:    EncodeUInt32;
  ivtInt64:     EncodeInt64;
  ivtUInt64:    EncodeUInt64;
  ivtFloat32:   EncodeFloat32;
  ivtFloat64:   EncodeFloat64;
  ivtDate:      EncodeDate;
  ivtTime:      EncodeTime;
  ivtDateTime:  EncodeDateTime;
  ivtString:    EncodeString;
  ivtBinary:    EncodeBinary;
else
  {ivtUndecided}
  raise Exception.Create('TIFXKeyNode.EncodeValue: Undecided value type.');
end;
If fValueState in [ivsNeedsEncode,ivsUndefined] then
  fValueState := ivsReady;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.EncodeBool;
begin
case fValueEncoding of
  iveHexadecimal: fValueStr := WideEncodingHexadecimal + StrToIFXStr(IntToHex(Byte(fValueData.BoolValue),2));
  iveNumber:      fValueStr := IFXBoolToStr(fValueData.BoolValue,False);
  iveDefault:     fValueStr := IFXBoolToStr(fValueData.BoolValue,True);
else
  fValueStr := WideEncode(IFXEncFromValueEnc(fValueEncoding),Addr(fValueData.BoolValue),SizeOf(Boolean),False,False);
end;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.EncodeInt8;
begin
case fValueEncoding of
  iveHexadecimal: fValueStr := WideEncodingHexadecimal + StrToIFXStr(IntToHex(fValueData.Int8Value,2));
  iveNumber,
  iveDefault:     fValueStr := StrToIFXStr(IntToStr(fValueData.Int8Value));
else
  fValueStr := WideEncode(IFXEncFromValueEnc(fValueEncoding),Addr(fValueData.Int8Value),SizeOf(Int8),False,False);
end;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.EncodeUInt8;
begin
case fValueEncoding of
  iveHexadecimal: fValueStr := WideEncodingHexadecimal + StrToIFXStr(IntToHex(fValueData.UInt8Value,2));
  iveNumber,
  iveDefault:     fValueStr := StrToIFXStr(IntToStr(fValueData.UInt8Value));
else
  fValueStr := WideEncode(IFXEncFromValueEnc(fValueEncoding),Addr(fValueData.UInt8Value),SizeOf(UInt8),False,False);
end;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.EncodeInt16;
begin
case fValueEncoding of
  iveHexadecimal: fValueStr := WideEncodingHexadecimal + StrToIFXStr(IntToHex(fValueData.Int16Value,4));
  iveNumber,
  iveDefault:     fValueStr := StrToIFXStr(IntToStr(fValueData.Int16Value));
else
  fValueStr := WideEncode(IFXEncFromValueEnc(fValueEncoding),Addr(fValueData.Int16Value),SizeOf(Int16),False,False);
end;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.EncodeUInt16;
begin
case fValueEncoding of
  iveHexadecimal: fValueStr := WideEncodingHexadecimal + StrToIFXStr(IntToHex(fValueData.UInt16Value,4));
  iveNumber,
  iveDefault:     fValueStr := StrToIFXStr(IntToStr(fValueData.UInt16Value));
else
  fValueStr := WideEncode(IFXEncFromValueEnc(fValueEncoding),Addr(fValueData.UInt16Value),SizeOf(UInt16),False,False);
end;
end;
 
//------------------------------------------------------------------------------

procedure TIFXKeyNode.EncodeInt32;
begin
case fValueEncoding of
  iveHexadecimal: fValueStr := WideEncodingHexadecimal + StrToIFXStr(IntToHex(fValueData.Int32Value,8));
  iveNumber,
  iveDefault:     fValueStr := StrToIFXStr(IntToStr(fValueData.Int32Value));
else
  fValueStr := WideEncode(IFXEncFromValueEnc(fValueEncoding),Addr(fValueData.Int32Value),SizeOf(Int32),False,False);
end;
end;
 
//------------------------------------------------------------------------------

procedure TIFXKeyNode.EncodeUInt32;  
begin
case fValueEncoding of
  iveHexadecimal: fValueStr := WideEncodingHexadecimal + StrToIFXStr(IntToHex(fValueData.UInt32Value,8));
  iveNumber,
  iveDefault:     fValueStr := StrToIFXStr(IntToStr(fValueData.UInt32Value));
else
  fValueStr := WideEncode(IFXEncFromValueEnc(fValueEncoding),Addr(fValueData.UInt32Value),SizeOf(UInt32),False,False);
end;
end;
 
//------------------------------------------------------------------------------

procedure TIFXKeyNode.EncodeInt64;
begin
case fValueEncoding of
  iveHexadecimal: fValueStr := WideEncodingHexadecimal + StrToIFXStr(IntToHex(fValueData.Int64Value,16));
  iveNumber,
  iveDefault:     fValueStr := StrToIFXStr(IntToStr(fValueData.Int64Value));
else
  fValueStr := WideEncode(IFXEncFromValueEnc(fValueEncoding),Addr(fValueData.Int64Value),SizeOf(Int64),False,False);
end;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.EncodeUInt64;
begin
case fValueEncoding of
  iveHexadecimal: fValueStr := WideEncodingHexadecimal + StrToIFXStr(IntToHex(fValueData.UInt64Value,16));
  iveNumber,
  iveDefault:     fValueStr := IFXUInt64ToStr(fValueData.UInt64Value);
else
  fValueStr := WideEncode(IFXEncFromValueEnc(fValueEncoding),Addr(fValueData.UInt64Value),SizeOf(UInt64),False,False);
end;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.EncodeFloat32;
begin
case fValueEncoding of
  iveHexadecimal: fValueStr := WideEncodingHexadecimal + StrToIFXStr(FloatToHex(fValueData.Float32Value));
  iveNumber,
  iveDefault:     fValueStr := StrToIFXStr(FloatToStr(fValueData.Float32Value,fSettingsPtr^.FormatSettings));
else
  fValueStr := WideEncode(IFXEncFromValueEnc(fValueEncoding),Addr(fValueData.Float32Value),SizeOf(Float32),False,False);
end;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.EncodeFloat64;
begin
case fValueEncoding of
  iveHexadecimal: fValueStr := WideEncodingHexadecimal + StrToIFXStr(FloatToHex(fValueData.Float64Value));
  iveNumber,
  iveDefault:     fValueStr := StrToIFXStr(FloatToStr(fValueData.Float64Value,fSettingsPtr^.FormatSettings));
else
  fValueStr := WideEncode(IFXEncFromValueEnc(fValueEncoding),Addr(fValueData.Float64Value),SizeOf(Float64),False,False);
end;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.EncodeDate;
begin
case fValueEncoding of
  iveHexadecimal: fValueStr := WideEncodingHexadecimal + StrToIFXStr(FloatToHex(fValueData.Float64Value));
  iveNumber,
  iveDefault:     fValueStr := StrToIFXStr(DateToStr(fValueData.DateValue,fSettingsPtr^.FormatSettings));
else
  fValueStr := WideEncode(IFXEncFromValueEnc(fValueEncoding),Addr(fValueData.Float64Value),SizeOf(Float64),False,False);
end;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.EncodeTime;
begin
case fValueEncoding of
  iveHexadecimal: fValueStr := WideEncodingHexadecimal + StrToIFXStr(FloatToHex(fValueData.Float64Value));
  iveNumber,
  iveDefault:     fValueStr := StrToIFXStr(TimeToStr(fValueData.DateValue,fSettingsPtr^.FormatSettings));
else
  fValueStr := WideEncode(IFXEncFromValueEnc(fValueEncoding),Addr(fValueData.Float64Value),SizeOf(Float64),False,False);
end;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.EncodeDateTime;
begin
case fValueEncoding of
  iveHexadecimal: fValueStr := WideEncodingHexadecimal + StrToIFXStr(FloatToHex(fValueData.Float64Value));
  iveNumber,
  iveDefault:     fValueStr := StrToIFXStr(DateTimeToStr(fValueData.DateValue,fSettingsPtr^.FormatSettings));
else
  fValueStr := WideEncode(IFXEncFromValueEnc(fValueEncoding),Addr(fValueData.Float64Value),SizeOf(Float64),False,False);
end;
end;
 
//------------------------------------------------------------------------------

procedure TIFXKeyNode.EncodeString;
begin
case fValueEncoding of
  iveHexadecimal,
  iveNumber:      fValueStr := WideEncode(bteHexadecimal,PIFXChar(fValueData.StringValue),
                                          Length(fValueData.StringValue) * SizeOf(TIFXChar),False,False);
  iveDefault:     fValueStr := IFXEncodeString(fValueData.StringValue,fSettingsPtr^.TextIniSettings);
else
  fValueStr := WideEncode(IFXEncFromValueEnc(fValueEncoding),PIFXChar(fValueData.StringValue),
                          Length(fValueData.StringValue) * SizeOf(TIFXChar),False,False);
end;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.EncodeBinary;
begin
case fValueEncoding of
  iveHexadecimal,
  iveNumber:      fValueStr := WideEncode(bteHexadecimal,fValueData.BinaryValuePtr,fValueData.BinaryValueSize,False,False);
  iveDefault:     fValueStr := WideEncode(bteBase64,fValueData.BinaryValuePtr,fValueData.BinaryValueSize,False,False);
else
  fValueStr := WideEncode(IFXEncFromValueEnc(fValueEncoding),fValueData.BinaryValuePtr,fValueData.BinaryValueSize,False,False);
end;
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GettingValue(ValueType: TIFXValueType): Boolean;
begin
If (fValueState = ivsNeedsEncode) and (ValueType <> fValueData.ValueType) then
  EncodeValue;
If (fValueState in [ivsNeedsDecode,ivsUndefined]) or (ValueType <> fValueData.ValueType) then
  begin
    If (fValueData.ValueType <> ValueType) or (fValueData.ValueType = ivtBinary) then
      FreeData;
    fValueData.ValueType := ValueType;
    DecodeValue;
  end;
Result := fValueState in [ivsNeedsEncode,ivsReady];
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.DecodeValue;
begin
case fValueData.ValueType of
  ivtBool:      DecodeBool;
  ivtInt8:      DecodeInt8;
  ivtUInt8:     DecodeUInt8;
  ivtInt16:     DecodeInt16;
  ivtUInt16:    DecodeUInt16;
  ivtInt32:     DecodeInt32;
  ivtUInt32:    DecodeUInt32;
  ivtInt64:     DecodeInt64;
  ivtUInt64:    DecodeUInt64;
  ivtFloat32:   DecodeFloat32;
  ivtFloat64:   DecodeFloat64;
  ivtDate:      DecodeDate;
  ivtTime:      DecodeTime;
  ivtDateTime:  DecodeDateTime;
  ivtString:    DecodeString;
  ivtBinary:    DecodeBinary;
else
  {ivtUndecided}
  raise Exception.Create('TIFXKeyNode.EncodeValue: Undecided value type.');
end;
fValueState := ivsReady;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.DecodeBool;
var
  TempInt:  Integer;
  TempByte: Byte;
  Encoding: TBinTextEncoding;
begin
If Length(fValueStr) > 0 then
  case fValueStr[1] of
    '$'{hexadecimal}:
      If TryStrToInt(IFXStrToStr(fValueStr),TempInt) then
        begin
          fValueData.BoolValue := TempInt <> 0;
          fValueEncoding := iveHexadecimal;
        end;
    WideEncodingHeaderStart:
      If WideDecode(fValueStr,@TempByte,SizeOf(Byte),Encoding) = SizeOf(Byte) then
        begin
          fValueData.BoolValue := TempByte <> 0;
          fValueEncoding := IFXValueEncFromEnc(Encoding);
        end;
    '0'..'9','-':
      If TryStrToInt(IFXStrToStr(fValueStr),TempInt) then
        begin
          fValueData.BoolValue := TempInt <> 0;
          fValueEncoding := iveNumber;
        end;
  else
    If IFXTryStrToBool(fValueStr,fValueData.Boolvalue) then
      fValueEncoding := iveDefault;
  end
else FreeData;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.DecodeInt8;
var
  TempInt:  Integer;
  Encoding: TBinTextEncoding;
begin
If Length(fValueStr) > 0 then
  case fValueStr[1] of
    '$'{hexadecimal}:
      If TryStrToInt(IFXStrToStr(fValueStr),TempInt) and ((TempInt >= Low(Int8)) and (TempInt <= High(Int8))) then
        begin
          fValueData.Int8Value := Int8(TempInt);
          fValueEncoding := iveHexadecimal;
        end;
    WideEncodingHeaderStart:
      If WideDecode(fValueStr,Addr(fValueData.Int8Value),SizeOf(Int8),Encoding) = SizeOf(Int8) then
        fValueEncoding := IFXValueEncFromEnc(Encoding);
  else
    If TryStrToInt(IFXStrToStr(fValueStr),TempInt) and ((TempInt >= Low(Int8)) and (TempInt <= High(Int8))) then
      begin
        fValueData.Int8Value := Int8(TempInt);
        fValueEncoding := iveDefault;
      end;
  end
else FreeData;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.DecodeUInt8;
var
  TempInt:  Integer;
  Encoding: TBinTextEncoding;
begin
If Length(fValueStr) > 0 then
  case fValueStr[1] of
    '$'{hexadecimal}:
      If TryStrToInt(IFXStrToStr(fValueStr),TempInt) and ((TempInt >= Low(UInt8)) and (TempInt <= High(UInt8))) then
        begin
          fValueData.UInt8Value := UInt8(TempInt);
          fValueEncoding := iveHexadecimal;
        end;
    WideEncodingHeaderStart:
      If WideDecode(fValueStr,Addr(fValueData.UInt8Value),SizeOf(UInt8),Encoding) = SizeOf(UInt8) then
        fValueEncoding := IFXValueEncFromEnc(Encoding);
  else
    If TryStrToInt(IFXStrToStr(fValueStr),TempInt) and ((TempInt >= Low(UInt8)) and (TempInt <= High(UInt8))) then
      begin
        fValueData.UInt8Value := UInt8(TempInt);
        fValueEncoding := iveDefault;
      end;
  end
else FreeData;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.DecodeInt16;
var
  TempInt:  Integer;
  Encoding: TBinTextEncoding;
begin
If Length(fValueStr) > 0 then
  case fValueStr[1] of
    '$'{hexadecimal}:
      If TryStrToInt(IFXStrToStr(fValueStr),TempInt) and ((TempInt >= Low(Int16)) and (TempInt <= High(Int16))) then
        begin
          fValueData.Int16Value := Int16(TempInt);
          fValueEncoding := iveHexadecimal;
        end;
    WideEncodingHeaderStart:
      If WideDecode(fValueStr,Addr(fValueData.Int16Value),SizeOf(Int16),Encoding) = SizeOf(Int16) then
        fValueEncoding := IFXValueEncFromEnc(Encoding);
  else
    If TryStrToInt(IFXStrToStr(fValueStr),TempInt) and ((TempInt >= Low(Int16)) and (TempInt <= High(Int16))) then
      begin
        fValueData.Int16Value := Int16(TempInt);
        fValueEncoding := iveDefault;
      end;
  end
else FreeData;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.DecodeUInt16;
var
  TempInt:  Integer;
  Encoding: TBinTextEncoding;
begin
If Length(fValueStr) > 0 then
  case fValueStr[1] of
    '$'{hexadecimal}:
      If TryStrToInt(IFXStrToStr(fValueStr),TempInt) and ((TempInt >= Low(UInt16)) and (TempInt <= High(UInt16))) then
        begin
          fValueData.UInt16Value := UInt16(TempInt);
          fValueEncoding := iveHexadecimal;
        end;
    WideEncodingHeaderStart:
      If WideDecode(fValueStr,Addr(fValueData.UInt16Value),SizeOf(UInt16),Encoding) = SizeOf(UInt16) then
        fValueEncoding := IFXValueEncFromEnc(Encoding);
  else
    If TryStrToInt(IFXStrToStr(fValueStr),TempInt) and ((TempInt >= Low(UInt16)) and (TempInt <= High(UInt16))) then
      begin
        fValueData.UInt16Value := UInt16(TempInt);
        fValueEncoding := iveDefault;
      end;
  end
else FreeData;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.DecodeInt32;
var
  TempInt:  Int64;
  Encoding: TBinTextEncoding;
begin
If Length(fValueStr) > 0 then
  case fValueStr[1] of
    '$'{hexadecimal}:
      If TryStrToInt64(IFXStrToStr(fValueStr),TempInt) and ((TempInt >= Low(Int32)) and (TempInt <= High(Int32))) then
        begin
          fValueData.Int32Value := Int32(TempInt);
          fValueEncoding := iveHexadecimal;
        end;
    WideEncodingHeaderStart:
      If WideDecode(fValueStr,Addr(fValueData.Int32Value),SizeOf(Int32),Encoding) = SizeOf(Int32) then
        fValueEncoding := IFXValueEncFromEnc(Encoding);
  else
    If TryStrToInt64(IFXStrToStr(fValueStr),TempInt) and ((TempInt >= Low(Int32)) and (TempInt <= High(Int32))) then
      begin
        fValueData.Int32Value := Int32(TempInt);
        fValueEncoding := iveDefault;
      end;
  end
else FreeData;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.DecodeUInt32;
var
  TempInt:  Int64;
  Encoding: TBinTextEncoding;
begin
If Length(fValueStr) > 0 then
  case fValueStr[1] of
    '$'{hexadecimal}:
      If TryStrToInt64(IFXStrToStr(fValueStr),TempInt) and ((TempInt >= Low(UInt32)) and (TempInt <= High(UInt32))) then
        begin
          fValueData.UInt32Value := UInt32(TempInt);
          fValueEncoding := iveHexadecimal;
        end;
    WideEncodingHeaderStart:
      If WideDecode(fValueStr,Addr(fValueData.UInt32Value),SizeOf(UInt32),Encoding) = SizeOf(UInt32) then
        fValueEncoding := IFXValueEncFromEnc(Encoding);
  else
    If TryStrToInt64(IFXStrToStr(fValueStr),TempInt) and ((TempInt >= Low(UInt32)) and (TempInt <= High(UInt32))) then
      begin
        fValueData.UInt32Value := UInt32(TempInt);
        fValueEncoding := iveDefault;
      end;
  end
else FreeData;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.DecodeInt64;
var
  TempInt:  Int64;
  Encoding: TBinTextEncoding;
begin
If Length(fValueStr) > 0 then
  case fValueStr[1] of
    '$'{hexadecimal}:
      If TryStrToInt64(IFXStrToStr(fValueStr),TempInt) then
        begin
          fValueData.Int64Value := TempInt;
          fValueEncoding := iveHexadecimal;
        end;
    WideEncodingHeaderStart:
      If WideDecode(fValueStr,Addr(fValueData.Int64Value),SizeOf(Int64),Encoding) = SizeOf(Int64) then
        fValueEncoding := IFXValueEncFromEnc(Encoding);
  else
    If TryStrToInt64(IFXStrToStr(fValueStr),TempInt) then
      begin
        fValueData.Int64Value := TempInt;
        fValueEncoding := iveDefault;
      end;
  end
else FreeData;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.DecodeUInt64;
var
  TempInt:  UInt64;
  Encoding: TBinTextEncoding;
begin
If Length(fValueStr) > 0 then
  case fValueStr[1] of
    '$'{hexadecimal}:
      If TryStrToInt64(IFXStrToStr(fValueStr),Int64(TempInt)) then
        begin
          fValueData.UInt64Value := TempInt;
          fValueEncoding := iveHexadecimal;
        end;
    WideEncodingHeaderStart:
      If WideDecode(fValueStr,Addr(fValueData.UInt64Value),SizeOf(UInt64),Encoding) = SizeOf(UInt64) then
        fValueEncoding := IFXValueEncFromEnc(Encoding);
  else
    If IFXTryStrToUInt64(fValueStr,TempInt) then
      begin
        fValueData.UInt64Value := TempInt;
        fValueEncoding := iveDefault;
      end;
  end
else FreeData;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.DecodeFloat32;
var
  TempFloat:  Float32;
  Encoding:   TBinTextEncoding;
begin
If Length(fValueStr) > 0 then
  case fValueStr[1] of
    '$'{hexadecimal}:
      If TryHexToSingle(IFXStrToStr(fValueStr),TempFloat) then
        begin
          fValueData.Float32Value := TempFloat;
          fValueEncoding := iveHexadecimal;
        end;
    WideEncodingHeaderStart:
      If WideDecode(fValueStr,Addr(fValueData.Float32Value),SizeOf(Float32),Encoding) = SizeOf(Float32) then
        fValueEncoding := IFXValueEncFromEnc(Encoding);
  else
    If TryStrToFloat(IFXStrToStr(fValueStr),TempFloat,fSettingsPtr^.FormatSettings) then
      begin
        fValueData.Float32Value := TempFloat;
        fValueEncoding := iveDefault;
      end;
  end
else FreeData;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.DecodeFloat64;
var
  TempFloat:  Float64;
  Encoding:   TBinTextEncoding;
begin
If Length(fValueStr) > 0 then
  case fValueStr[1] of
    '$'{hexadecimal}:
      If TryHexToDouble(IFXStrToStr(fValueStr),TempFloat) then
        begin
          fValueData.Float64Value := TempFloat;
          fValueEncoding := iveHexadecimal;
        end;
    WideEncodingHeaderStart:
      If WideDecode(fValueStr,Addr(fValueData.Float64Value),SizeOf(Float64),Encoding) = SizeOf(Float64) then
        fValueEncoding := IFXValueEncFromEnc(Encoding);
  else
    If TryStrToFloat(IFXStrToStr(fValueStr),TempFloat,fSettingsPtr^.FormatSettings) then
      begin
        fValueData.Float64Value := TempFloat;
        fValueEncoding := iveDefault;
      end;
  end
else FreeData;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.DecodeDate;
var
  TempFloat:  Float64;
  Encoding:   TBinTextEncoding;
begin
If Length(fValueStr) > 0 then
  case fValueStr[1] of
    '$'{hexadecimal}:
      If TryHexToDouble(IFXStrToStr(fValueStr),TempFloat) then
        begin
          fValueData.DateValue := TDateTime(TempFloat);
          fValueEncoding := iveHexadecimal;
        end;
    WideEncodingHeaderStart:
      If WideDecode(fValueStr,Addr(fValueData.DateValue),SizeOf(TDateTime),Encoding) = SizeOf(TDateTime) then
        fValueEncoding := IFXValueEncFromEnc(Encoding);
  else
    If TryStrToDate(IFXStrToStr(fValueStr),TDateTime(TempFloat),fSettingsPtr^.FormatSettings) then
      begin
        fValueData.DateValue := TDateTime(TempFloat);
        fValueEncoding := iveDefault;
      end;
  end
else FreeData;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.DecodeTime;
var
  TempFloat:  Float64;
  Encoding:   TBinTextEncoding;
begin
If Length(fValueStr) > 0 then
  case fValueStr[1] of
    '$'{hexadecimal}:
      If TryHexToDouble(IFXStrToStr(fValueStr),TempFloat) then
        begin
          fValueData.TimeValue := TDateTime(TempFloat);
          fValueEncoding := iveHexadecimal;
        end;
    WideEncodingHeaderStart:
      If WideDecode(fValueStr,Addr(fValueData.TimeValue),SizeOf(TDateTime),Encoding) = SizeOf(TDateTime) then
        fValueEncoding := IFXValueEncFromEnc(Encoding);
  else
    If TryStrToTime(IFXStrToStr(fValueStr),TDateTime(TempFloat),fSettingsPtr^.FormatSettings) then
      begin
        fValueData.TimeValue := TDateTime(TempFloat);
        fValueEncoding := iveDefault;
      end;
  end
else FreeData;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.DecodeDateTime;
var
  TempFloat:  Float64;
  Encoding:   TBinTextEncoding;
begin
If Length(fValueStr) > 0 then
  case fValueStr[1] of
    '$'{hexadecimal}:
      If TryHexToDouble(IFXStrToStr(fValueStr),TempFloat) then
        begin
          fValueData.DateTimeValue := TDateTime(TempFloat);
          fValueEncoding := iveHexadecimal;
        end;
    WideEncodingHeaderStart:
      If WideDecode(fValueStr,Addr(fValueData.DateTimeValue),SizeOf(TDateTime),Encoding) = SizeOf(TDateTime) then
        fValueEncoding := IFXValueEncFromEnc(Encoding);
  else
    If TryStrToDateTime(IFXStrToStr(fValueStr),TDateTime(TempFloat),fSettingsPtr^.FormatSettings) then
      begin
        fValueData.DateTimeValue := TDateTime(TempFloat);
        fValueEncoding := iveDefault;
      end;
  end
else FreeData;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.DecodeString;
var
  TempMem:  Pointer;
  TempSize: TMemSize;
  Encoding: TBinTextEncoding;
begin
If Length(fValueStr) > 0 then
  case fValueStr[1] of
    WideEncodingHexadecimal,
    WideEncodingHeaderStart:
      begin
        TempMem := WideDecode(fValueStr,TempSize,Encoding);
        try
          SetLength(fValueData.StringValue,TempSize div SizeOf(TIFXChar));
          If Length(fValueData.StringValue) > 0 then
            Move(TempMem^,PIFXChar(fValueData.StringValue)^,Length(fValueData.StringValue) * SizeOf(TIFXChar));
        finally
          FreeMem(TempMem,TempSize);
        end;
      end;
  else
    fValueData.StringValue := IFXDecodeString(fValueStr,fSettingsPtr^.TextIniSettings);
    fValueEncoding := iveDefault;
  end
else FreeData;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.DecodeBinary;
var
  Encoding: TBinTextEncoding;
begin
If Length(fValueStr) > 0 then
  begin
    fValueData.BinaryValuePtr := WideDecode(fValueStr,fValueData.BinaryValueSize,Encoding);
    fValueEncoding := IFXValueEncFromEnc(Encoding);
  end
else FreeData;
end;

//==============================================================================

constructor TIFXKeyNode.Create(const KeyName: TIFXString; SettingsPtr: PIFXSettings);
begin
inherited Create;
fSettingsPtr := SettingsPtr;
fName := IFXHashedString(KeyName);
fComment := '';
fValueStr := '';
fValueEncoding := iveDefault;
fValueState := ivsUndefined;
fValueData.ValueType := ivtUndecided;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TIFXKeyNode.Create(SettingsPtr: PIFXSettings);
begin
Create('',SettingsPtr);
end;

//------------------------------------------------------------------------------

constructor TIFXKeyNode.CreateCopy(SourceNode: TIFXKeyNode);
var
  TempPtr:  Pointer;
begin
Create(SourceNode.NameStr,SourceNode.SettingsPtr);
fComment := SourceNode.Comment;
fInlineComment := SourceNode.InlineComment;
fValueStr := SourceNode.ValueStr;
fValueEncoding := SourceNode.ValueEncoding;
fValueState := SourceNode.ValueState;
fValueData := SourceNode.ValueData;
If (fValueData.ValueType = ivtBinary) and fValueData.BinaryValueOwned then
  begin
    GetMem(TempPtr,fValueData.BinaryValueSize);
    Move(fValueData.BinaryValuePtr^,TempPtr^,fValueData.BinaryValueSize);
    fValueData.BinaryValuePtr := TempPtr;
  end;
// ensure thread safety
UniqueString(fName.Str);
UniqueString(fComment);
UniqueString(fInlineComment);
UniqueString(fValueStr);
UniqueString(fValueData.StringValue);
end;

//------------------------------------------------------------------------------

destructor TIFXKeyNode.Destroy;
begin
FreeData;
inherited;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueBool(Value: Boolean);
begin
SettingValue(ivtBool);
fValueData.BoolValue := Value;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueInt8(Value: Int8);
begin
SettingValue(ivtInt8);
fValueData.Int8Value := Value;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueUInt8(Value: UInt8);
begin
SettingValue(ivtUInt8);
fValueData.UInt8Value := Value;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueInt16(Value: Int16);
begin
SettingValue(ivtInt16);
fValueData.Int16Value := Value;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueUInt16(Value: UInt16);
begin
SettingValue(ivtUInt16);
fValueData.UInt16Value := Value;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueInt32(Value: Int32);
begin
SettingValue(ivtInt32);
fValueData.Int32Value := Value;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueUInt32(Value: UInt32);
begin
SettingValue(ivtUInt16);
fValueData.UInt16Value := Value;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueInt64(Value: Int64);
begin
SettingValue(ivtInt64);
fValueData.Int64Value := Value;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueUInt64(Value: UInt64);
begin
SettingValue(ivtUInt64);
fValueData.UInt64Value := Value;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueFloat32(Value: Float32);
begin
SettingValue(ivtFloat32);
fValueData.Float32Value := Value;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueFloat64(Value: Float64);
begin
SettingValue(ivtFloat64);
fValueData.Float64Value := Value;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueDate(Value: TDateTime);
begin
SettingValue(ivtDate);
fValueData.DateValue := Value;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueTime(Value: TDateTime);
begin
SettingValue(ivtTime);
fValueData.TimeValue := Value;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueDateTime(Value: TDateTime);
begin
SettingValue(ivtDateTime);
fValueData.DateTimeValue := Value;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueString(const Value: TIFXString);
begin
SettingValue(ivtString);
fValueData.StringValue := Value;
end;

//------------------------------------------------------------------------------

procedure TIFXKeyNode.SetValueBinary(Value: Pointer; Size: TMemSize; MakeCopy: Boolean = False);
begin
SettingValue(ivtBinary);
If MakeCopy then
  begin
    GetMem(fValueData.BinaryValuePtr,Size);
    Move(Value^,fValueData.BinaryValuePtr^,Size);
  end
else fValueData.BinaryValuePtr := Value;
fValueData.BinaryValueSize := Size;
fValueData.BinaryValueOwned := MakeCopy;
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValuePrepare(ValueType: TIFXValueType): Boolean;
begin
Result := GettingValue(ValueType);
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValueBool(out Value: Boolean): Boolean;
begin
Result := GettingValue(ivtBool);
Value := fValueData.BoolValue;
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValueInt8(out Value: Int8): Boolean;
begin
Result := GettingValue(ivtInt8);
Value := fValueData.Int8Value;
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValueUInt8(out Value: UInt8): Boolean;
begin
Result := GettingValue(ivtUInt8);
Value := fValueData.UInt8Value;
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValueInt16(out Value: Int16): Boolean;
begin
Result := GettingValue(ivtInt16);
Value := fValueData.Int16Value;
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValueUInt16(out Value: UInt16): Boolean;
begin
Result := GettingValue(ivtUInt16);
Value := fValueData.UInt16Value;
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValueInt32(out Value: Int32): Boolean;
begin
Result := GettingValue(ivtInt32);
Value := fValueData.Int32Value;
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValueUInt32(out Value: UInt32): Boolean;
begin
Result := GettingValue(ivtUInt32);
Value := fValueData.UInt32Value;
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValueInt64(out Value: Int64): Boolean;
begin
Result := GettingValue(ivtInt64);
Value := fValueData.Int64Value;
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValueUInt64(out Value: UInt64): Boolean;
begin
Result := GettingValue(ivtUInt64);
Value := fValueData.UInt64Value;
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValueFloat32(out Value: Float32): Boolean;
begin
Result := GettingValue(ivtFloat32);
Value := fValueData.Float32Value;
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValueFloat64(out Value: Float64): Boolean;
begin
Result := GettingValue(ivtFloat64);
Value := fValueData.Float64Value;
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValueDate(out Value: TDateTime): Boolean;
begin
Result := GettingValue(ivtDate);
Value := fValueData.DateValue;
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValueTime(out Value: TDateTime): Boolean;
begin
Result := GettingValue(ivtTime);
Value := fValueData.TimeValue;
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValueDateTime(out Value: TDateTime): Boolean;
begin
Result := GettingValue(ivtDateTime);
Value := fValueData.DateTimeValue;
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValueString(out Value: TIFXString): Boolean;
begin
Result := GettingValue(ivtString);
Value := fValueData.StringValue;
end;

//------------------------------------------------------------------------------

Function TIFXKeyNode.GetValueBinary(out Value: Pointer; out Size: TMemSize; MakeCopy: Boolean = False): Boolean;
begin
Result := GettingValue(ivtBinary);
If MakeCopy then
  begin
    GetMem(Value,fValueData.BinaryValueSize);
    Move(fValueData.BinaryValuePtr^,Value^,fValueData.BinaryValueSize);
  end
else Value := fValueData.BinaryValuePtr;
Size := fValueData.BinaryValueSize;
end;


{===============================================================================
--------------------------------------------------------------------------------
                                TIFXSectionNode
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TIFXSectionNode - class implementation
===============================================================================}

Function TIFXSectionNode.GetKey(Index: Integer): TIFXKeyNode;
begin
If CheckIndex(Index) then
  Result := fKeys[Index]
else
  raise Exception.CreateFmt('TIFXSectionNode.GetKey: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure TIFXSectionNode.SetNameStr(const Value: TIFXString);
begin
fName := IFXHashedString(Value);
end;

//==============================================================================

Function TIFXSectionNode.GetCapacity: Integer;
begin
Result := Length(fKeys);
end;

//------------------------------------------------------------------------------

procedure TIFXSectionNode.SetCapacity(Value: Integer);
var
  i:  Integer;
begin
If Value <> Length(fKeys) then
  begin
    If Value < fCount then
      begin
        For i := Value to Pred(fCount) do
          begin
            If Assigned(fOnKeyDestroy) then
              fOnKeyDestroy(Self,Self,fKeys[i]);
            fKeys[i].Free;
          end;
        fCount := Value;
      end;
    SetLength(fKeys,Value);
  end;
end;
 
//------------------------------------------------------------------------------

Function TIFXSectionNode.GetCount: Integer;
begin
Result := fCount;
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TIFXSectionNode.SetCount(Value: Integer);
begin
// nothing to do here
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

Function TIFXSectionNode.CompareKeys(Idx1,Idx2: Integer): Integer;
begin
Result := IFXCompareText(fKeys[Idx1].NameStr,fKeys[Idx2].NameStr);
end;

//==============================================================================

constructor TIFXSectionNode.Create(const SectionName: TIFXString; SettingsPtr: PIFXSettings);
begin
inherited Create;
SetLEngth(fKeys,0);
fCount := 0;
fSettingsPtr := SettingsPtr;
fName := IFXHashedString(SectionName);
fComment := '';
fOnKeyCreate := nil;
fOnKeyDestroy := nil;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TIFXSectionNode.Create(SettingsPtr: PIFXSettings);
begin
Create('',SettingsPtr);
end;

//------------------------------------------------------------------------------

constructor TIFXSectionNode.CreateCopy(SourceNode: TIFXSectionNode; OnKeyCreate: TIFXKeyNodeEvent);
var
  i:        Integer;
  TempKey:  TIFXKeyNode;
begin
Create(SourceNode.NameStr,SourceNode.fSettingsPtr);
fComment := SourceNode.Comment;
fInlineComment := SourceNode.InlineComment;
fOnKeyCreate := SourceNode.OnKeyCreate;
fOnKeyDestroy := SourceNode.OnKeyDestroy;
// copy all keys from source section
For i := SourceNode.LowIndex to SourceNode.HighIndex do
  begin
    TempKey := TIFXKeyNode.CreateCopy(SourceNode[i]);
    AddKeyNode(TempKey);
    If Assigned(OnKeyCreate) then
      OnKeyCreate(Self,Self,TempKey);
  end;
// ensure thread safety
UniqueString(fName.Str);
UniqueString(fComment);
UniqueString(fInlineComment);
end;

//------------------------------------------------------------------------------

destructor TIFXSectionNode.Destroy;
begin
ClearKeys;
inherited;
end;

//------------------------------------------------------------------------------

Function TIFXSectionNode.LowIndex: Integer;
begin
Result := Low(fKeys);
end;

//------------------------------------------------------------------------------

Function TIFXSectionNode.HighIndex: Integer;
begin
Result := Pred(fCount);
end;

//------------------------------------------------------------------------------

Function TIFXSectionNode.IndexOfKey(const KeyName: TIFXString): Integer;
var
  i:    Integer;
  Temp: TIFXHashedString;
begin
Result := -1;
Temp := IFXHashedString(KeyName);
For i := LowIndex to HighIndex do
  If IFXSameHashString(fKeys[i].Name,Temp,fSettingsPtr^.FullNameEval) then
    begin
      Result := i;
      Break{For i};
    end;
end;

//------------------------------------------------------------------------------

Function TIFXSectionNode.FindKey(const KeyName: TIFXString; out KeyNode: TIFXKeyNode): Boolean;
var
  Index:  Integer;
begin
Index := IndexOfKey(KeyName);
If Index >= 0 then
  begin
    KeyNode := fKeys[Index];
    Result := True;
  end
else Result := False;
end;

//------------------------------------------------------------------------------

Function TIFXSectionNode.FindKey(const KeyName: TIFXString): TIFXKeyNode;
begin
If not FindKey(KeyName,Result) then
  Result := nil;
end;

//------------------------------------------------------------------------------

Function TIFXSectionNode.AddKey(const KeyName: TIFXString): Integer;
begin
Result := IndexOfKey(KeyName);
If Result < 0 then
  begin
    Grow;
    Result := fCount;
    fKeys[Result] := TIFXKeyNode.Create(KeyName,fSettingsPtr);
    Inc(fCount);
    If Assigned(fOnKeyCreate) then
      fOnKeyCreate(Self,Self,fKeys[Result]);
  end;
end;

//------------------------------------------------------------------------------

Function TIFXSectionNode.AddKeyNode(KeyNode: TIFXKeyNode): Integer;
begin
Grow;
Result := fCount;
fKeys[Result] := KeyNode;
Inc(fCount);
end;

//------------------------------------------------------------------------------

procedure TIFXSectionNode.ExchangeKeys(Idx1, Idx2: Integer);
var
  Temp: TIFXKeyNode;
begin
If Idx1 <> Idx2 then
  begin
    If not CheckIndex(Idx1) then
      raise Exception.CreateFmt('TIFXSectionNode.ExchangeKeys: Idx1 (%d) out of bounds.',[Idx1]);
    If not CheckIndex(Idx2) then
      raise Exception.CreateFmt('TIFXSectionNode.ExchangeKeys: Idx2 (%d) out of bounds.',[Idx2]);
    Temp := fKeys[Idx1];
    fKeys[Idx1] := fKeys[Idx2];
    fKeys[Idx2] := Temp;
  end;
end;

//------------------------------------------------------------------------------

Function TIFXSectionNode.RemoveKey(const KeyName: TIFXString): Integer;
begin
Result := IndexOfKey(KeyName);
If Result >= 0 then
  DeleteKey(Result);
end;

//------------------------------------------------------------------------------

procedure TIFXSectionNode.DeleteKey(Index: Integer);
var
  i:  Integer;
begin
If CheckIndex(Index) then
  begin
    If Assigned(fOnKeyDestroy) then
      fOnKeyDestroy(Self,Self,fKeys[Index]);
    fKeys[Index].Free;
    For i := Index to (fCount - 2) do
      fKeys[i] := fKeys[i + 1];
    Dec(fCount);
    Shrink;
  end
else raise Exception.CreateFmt('TIFXSectionNode.DeleteKey: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure TIFXSectionNode.ClearKeys;
var
  i:  Integer;
begin
For i := HighIndex downto LowIndex do
  begin
    If Assigned(fOnKeyDestroy) then
      fOnKeyDestroy(Self,Self,fKeys[i]);
    fKeys[i].Free;
  end;
fCount := 0;
Shrink;
end;

//------------------------------------------------------------------------------

procedure TIFXSectionNode.SortKeys(Reversed: Boolean = False);
var
  Sorter: TListQuickSorter;
begin
If fCount > 1 then
  begin
    Sorter := TListQuickSorter.Create(CompareKeys,ExchangeKeys);
    try
      Sorter.ReversedCompare := True;
      Sorter.Reversed := Reversed;
      Sorter.Sort(LowIndex,HighIndex);
    finally
      Sorter.Free;
    end;
  end;
end;


{===============================================================================
--------------------------------------------------------------------------------
                                  TIFXFileNode
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TIFXFileNode - class implementation
===============================================================================}

Function TIFXFileNode.GetSection(Index: Integer): TIFXSectionNode;
begin
If CheckIndex(Index) then
  Result := fSections[Index]
else
  raise Exception.CreateFmt('TIFXFileNode.GetSection: Index (%d) out of bounds.',[Index]);
end;

//==============================================================================

Function TIFXFileNode.GetCapacity: Integer;
begin
Result := Length(fSections);
end;
 
//------------------------------------------------------------------------------

procedure TIFXFileNode.SetCapacity(Value: Integer);
var
  i:  Integer;
begin
If Value <> Length(fSections) then
  begin
    If Value < fCount then
      begin
        For i := Value to Pred(fCount) do
          begin
            If Assigned(fOnSectionDestroy) then
              fOnSectionDestroy(Self,fSections[i]);
            fSections[i].Free;
          end;
        fCount := Value;
      end;
    SetLength(fSections,Value);
  end;
end;
 
//------------------------------------------------------------------------------

Function TIFXFileNode.GetCount: Integer;
begin
Result := fCount;
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TIFXFileNode.SetCount(Value: Integer);
begin
// nothing to do here
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

Function TIFXFileNode.CompareSections(Idx1,Idx2: Integer): Integer;
begin
Result := IFXCompareText(fSections[Idx1].NameStr,fSections[Idx2].NameStr);
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TIFXFileNode.KeyCreateHandler(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode);
begin
If Assigned(fOnKeyCreate) then
  fOnKeyCreate(Self,Section,Key);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TIFXFileNode.KeyDestroyHandler(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode);
begin
If Assigned(fOnKeyDestroy) then
  fOnKeyDestroy(Self,Section,Key);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//==============================================================================

constructor TIFXFileNode.Create(SettingsPtr: PIFXSettings);
begin
inherited Create;
SetLength(fSections,0);
fCount := 0;
fSettingsPtr := SettingsPtr;
fComment := '';
fOnKeyCreate := nil;
fOnKeyDestroy := nil;
fOnSectionCreate := nil;
fOnSectionDestroy := nil;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TIFXFileNode.CreateCopy(SourceNode: TIFXFileNode; OnSectionCreate: TIFXSectionNodeEvent; OnKeyCreate: TIFXKeyNodeEvent);
var
  i:            Integer;
  TempSection:  TIFXSectionNode;
begin
Create(SourceNode.SettingsPtr);
fComment := SourceNode.Comment;
fOnKeyCreate := SourceNode.OnKeyCreate;
fOnKeyDestroy := SourceNode.OnKeyDestroy;
fOnSectionCreate := SourceNode.OnSectionCreate;
fOnSectionDestroy := SourceNode.OnSectionDestroy;
For i := SourceNode.LowIndex to SourceNode.HighIndex do
  begin
    TempSection := TIFXSectionNode.CreateCopy(SourceNode[i],OnKeyCreate);
    TempSection.OnKeyCreate := KeyCreateHandler;
    TempSection.OnKeyDestroy := KeyDestroyHandler;
    AddSectionNode(TempSection);
    If Assigned(OnSectionCreate) then
      OnSectionCreate(Self,TempSection);
  end;
// ensure thread safety
UniqueString(fComment);
end;

//------------------------------------------------------------------------------

destructor TIFXFileNode.Destroy;
begin
ClearSections;
inherited;
end;
 
//------------------------------------------------------------------------------

Function TIFXFileNode.LowIndex: Integer;
begin
Result := Low(fSections);
end;
 
//------------------------------------------------------------------------------

Function TIFXFileNode.HighIndex: Integer;
begin
Result := Pred(fCount);
end;
 
//------------------------------------------------------------------------------

Function TIFXFileNode.IndexOfSection(const SectionName: TIFXString): Integer;
var
  i:    Integer;
  Temp: TIFXHashedString;
begin
Result := -1;
Temp := IFXHashedString(SectionName);
For i := LowIndex to HighIndex do
  If IFXSameHashString(fSections[i].Name,Temp,fSettingsPtr^.FullNameEval) then
    begin
      Result := i;
      Break{For i};
    end;
end;
 
//------------------------------------------------------------------------------

Function TIFXFileNode.FindSection(const SectionName: TIFXString; out SectionNode: TIFXSectionNode): Boolean;
var
  Index:  Integer;
begin
Index := IndexOfSection(SectionName);
If Index >= 0 then
  begin
    SectionNode := fSections[Index];
    Result := True;
  end
else Result := False;
end;

//------------------------------------------------------------------------------

Function TIFXFileNode.FindSection(const SectionName: TIFXString): TIFXSectionNode;
begin
If not FindSection(SectionName,Result) then
  Result := nil;
end;

//------------------------------------------------------------------------------

Function TIFXFileNode.AddSection(const SectionName: TIFXString): Integer;
begin
Result := IndexOfSection(SectionName);
If Result < 0 then
  begin
    Grow;
    Result := fCount;
    fSections[Result] := TIFXSectionNode.Create(SectionName,fSettingsPtr);
    fSections[Result].OnKeyCreate := KeyCreateHandler;
    fSections[Result].OnKeyDestroy := KeyDestroyHandler;
    Inc(fCount);
    If Assigned(fOnSectionCreate) then
      fOnSectionCreate(Self,fSections[Result]);
  end;
end;

//------------------------------------------------------------------------------

Function TIFXFileNode.AddSectionNode(SectionNode: TIFXSectionNode): Integer;
begin
Grow;
Result := fCount;
fSections[Result] := SectionNode;
fSections[Result].OnKeyCreate := KeyCreateHandler;
fSections[Result].OnKeyDestroy := KeyDestroyHandler;
Inc(fCount);
end;

//------------------------------------------------------------------------------

procedure TIFXFileNode.ExchangeSections(Idx1, Idx2: Integer);
var
  Temp: TIFXSectionNode;
begin
If Idx1 <> Idx2 then
  begin
    If not CheckIndex(Idx1) then
      raise Exception.CreateFmt('TIFXFileNode.ExchangeSections: Idx1 (%d) out of bounds.',[Idx1]);
    If not CheckIndex(Idx2) then
      raise Exception.CreateFmt('TIFXFileNode.ExchangeSections: Idx2 (%d) out of bounds.',[Idx2]);
    Temp := fSections[Idx1];
    fSections[Idx1] := fSections[Idx2];
    fSections[Idx2] := Temp;
  end;
end;

//------------------------------------------------------------------------------

Function TIFXFileNode.RemoveSection(const SectionName: TIFXString): Integer;
begin
Result := IndexOfSection(SectionName);
If Result >= 0 then
  DeleteSection(Result);
end;

//------------------------------------------------------------------------------

procedure TIFXFileNode.DeleteSection(Index: Integer);
var
  i:  Integer;
begin
If CheckIndex(Index) then
  begin
    If Assigned(fOnSectionDestroy) then
      fOnSectionDestroy(Self,fSections[Index]);
    fSections[Index].Free;
    For i := Index to (fCount - 2) do
      fSections[i] := fSections[i + 1];
    Dec(fCount);
    Shrink;
  end
else raise Exception.CreateFmt('TIFXFileNode.DeleteSection: Index (%d) out of bounds.',[Index]);
end;
 
//------------------------------------------------------------------------------

procedure TIFXFileNode.ClearSections;
var
  i:  Integer;
begin
For i := HighIndex downto LowIndex do
  begin
    If Assigned(fOnSectionDestroy) then
      fOnSectionDestroy(Self,fSections[i]);
    fSections[i].Free;
  end;
fCount := 0;
Shrink;
end;

//------------------------------------------------------------------------------

procedure TIFXFileNode.SortSections(Reversed: Boolean = False);
var
  Sorter: TListQuickSorter;
begin
If fCount > 1 then
  begin
    Sorter := TListQuickSorter.Create(CompareSections,ExchangeSections);
    try
      Sorter.ReversedCompare := True;
      Sorter.Reversed := Reversed;
      Sorter.Sort(LowIndex,HighIndex);
    finally
      Sorter.Free;
    end;
  end;
end;

//------------------------------------------------------------------------------

Function TIFXFileNode.IndexOfKey(const SectionName, KeyName: TIFXString): TIFXNodeIndices;
begin
Result := IFX_INVALID_NODE_INDICES;
Result.SectionIndex := IndexOfSection(SectionName);
If Result.SectionIndex >= 0 then
  Result.KeyIndex := fSections[Result.SectionIndex].IndexOfKey(KeyName);
end;

//------------------------------------------------------------------------------

Function TIFXFileNode.FindKey(const SectionName, KeyName: TIFXString; out KeyNode: TIFXKeyNode): Boolean;
var
  Section:  TIFXSectionNode;
begin
KeyNode := nil;
If FindSection(SectionName,Section) then
  Result := Section.FindKey(KeyName,KeyNode)
else
  Result := False;
end;

//------------------------------------------------------------------------------

Function TIFXFileNode.FindKey(const SectionName, KeyName: TIFXString): TIFXKeyNode;
begin
If not FindKey(SectionName,KeyName,Result) then
  Result := nil;
end;

//------------------------------------------------------------------------------

Function TIFXFileNode.AddKey(const SectionName, KeyName: TIFXString): TIFXNodeIndices;
begin
Result := IFX_INVALID_NODE_INDICES;
Result.SectionIndex := IndexOfSection(SectionName);
If Result.SectionIndex <= 0 then
  Result.SectionIndex := AddSection(SectionName);
Result.KeyIndex := fSections[Result.SectionIndex].IndexOfKey(KeyName);
If Result.KeyIndex < 0 then
  Result.KeyIndex := fSections[Result.SectionIndex].AddKey(KeyName);
end;

//------------------------------------------------------------------------------

procedure TIFXFileNode.ExchangeKeys(const SectionName: TIFXString; KeyIdx1, KeyIdx2: Integer);
var
  Section:  TIFXSectionNode;
begin
If FindSection(SectionName,Section) then
  Section.ExchangeKeys(KeyIdx1,KeyIdx2);
end;

//------------------------------------------------------------------------------

Function TIFXFileNode.RemoveKey(const SectionName, KeyName: TIFXString): TIFXNodeIndices;
begin
Result := IFX_INVALID_NODE_INDICES;
Result.SectionIndex := IndexOfSection(SectionName);
If Result.SectionIndex >= 0 then
  Result.KeyIndex := fSections[Result.SectionIndex].RemoveKey(KeyName);
end;

//------------------------------------------------------------------------------

procedure TIFXFileNode.DeleteKey(SectionIndex, KeyIndex: Integer);
begin
If CheckIndex(SectionIndex) then
  fSections[SectionIndex].DeleteKey(KeyIndex)
else
  raise Exception.CreateFmt('TIFXFileNode.DeleteKey: Section index (%d) out of bounds.',[SectionIndex]);
end;

//------------------------------------------------------------------------------

procedure TIFXFileNode.ClearKeys(const SectionName: TIFXString);
var
  Section:  TIFXSectionNode;
begin
If FindSection(SectionName,Section) then
  Section.ClearKeys;
end;

//------------------------------------------------------------------------------

procedure TIFXFileNode.SortKeys(const SectionName: TIFXString; Reversed: Boolean = False);
var
  Section:  TIFXSectionNode;
begin
If FindSection(SectionName,Section) then
  Section.SortKeys(Reversed);
end;

end.

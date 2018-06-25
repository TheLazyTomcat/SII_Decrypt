{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Explicit string lists

  Base class for all explicit string lists.

  ©František Milt 2018-05-21

  Version 1.0.2

  Dependencies:
    AuxTypes        - github.com/ncs-sniper/Lib.AuxTypes
    AuxClasses      - github.com/ncs-sniper/Lib.AuxClasses
    StrRect         - github.com/ncs-sniper/Lib.StrRect
    BinaryStreaming - github.com/ncs-sniper/Lib.BinaryStreaming

===============================================================================}
unit ExplicitStringListsBase;

{$INCLUDE '.\ExplicitStringLists_defs.inc'}

interface

uses
  SysUtils, Classes, AuxTypes;

{===============================================================================
    Auxiliary functions - declaration
===============================================================================}

{$IF not Declared(UTF8ToString)}
Function UTF8ToString(const Str: UTF8String): UnicodeString;{$IFDEF CanInline} inline; {$ENDIF}
{$DEFINE UTF8ToString_Implement}
{$IFEND}

{===============================================================================
--------------------------------------------------------------------------------
                              TExplicitStringList
--------------------------------------------------------------------------------
===============================================================================}

const
  def_Delimiter = ',';
  def_LineBreak = sLineBreak;
  def_QuoteChar = '"';

type
  EExplicitStringListError = Exception;

  TGrowMode = (gmSlow, gmLinear, gmFast, gmFastAttenuated);
  TShrinkMode = (smKeepCap, smNormal, smToCount);

  TStringEndianness = (seSystem,seLittle,seBig);
  TLineBreakStyle = (lbsWIN,lbsUNIX,lbsMAC,lbsRISC,lbsCRLF,lbsLF,lbsCR,lbsLFCR);

{===============================================================================
    TExplicitStringList - declaration
===============================================================================}
  TExplicitStringList = class(TPersistent)
  private
    // grow/shrink settings
    fGrowMode:      TGrowMode;
    fGrowFactor:    Double;
    fGrowLimit:     Integer;
    fShrinkMode:    TShrinkMode;
    fShrinkFactor:  Double;
    fShrinkLimit:   Integer;
    // user data
    fUserIntData:   PtrInt;
    fUserPtrData:   Pointer;
    // change events
    fOnChanging:    TNotifyEvent;
    fOnChange:      TNotifyEvent;
  protected
    fCount:             Integer;
    fUpdateCount:       Integer;
    fChanged:           Boolean;
    fCaseSensitive:     Boolean;
    fStrictDelimiter:   Boolean;
    fTrailingLineBreak: Boolean;
    fDuplicates:        TDuplicates;
    fSorted:            Boolean;
    Function GetUpdating: Boolean;
    Function GetCapacity: Integer; virtual; abstract;
    procedure SetCapacity(Value: Integer); virtual; abstract;
    class procedure Error(const Msg: string; Data: array of const); virtual;
    class Function GetSystemEndianness: TStringEndianness; virtual;
    class procedure WideSwapEndian(Data: PWideChar; Count: TStrSize); virtual;
    procedure Grow(MinDelta: Integer = 1); virtual;
    procedure Shrink; virtual;
    Function CheckIndex(Index: Integer): Boolean; virtual;
    procedure SetUpdateState(Updating: Boolean); virtual;
    Function CompareItems(Index1,Index2: Integer): Integer; virtual; abstract;
    Function GetWriteSize: UInt64; virtual; abstract;
    procedure WriteItemToStream(Stream: TStream; Index: Integer; Endianness: TStringEndianness); virtual; abstract;
    procedure WriteLineBreakToStream(Stream: TStream; Endianness: TStringEndianness); virtual; abstract;
    procedure WriteBOMToStream(Stream: TStream; Endianness: TStringEndianness); virtual; abstract;
    procedure DoChange; virtual;
    procedure DoChanging; virtual;
  public
    constructor Create;
    Function BeginUpdate: Integer; virtual;
    Function EndUpdate: Integer; virtual;
    Function LowIndex: Integer; virtual; abstract;
    Function HighIndex: Integer; virtual; abstract;
    procedure Exchange(Idx1, Idx2: Integer); virtual; abstract;
    procedure Sort(Reversed: Boolean = False); virtual;
    procedure LoadFromStream(Stream: TStream; out Endianness: TStringEndianness); overload; virtual; abstract;
    procedure LoadFromStream(Stream: TStream); overload; virtual;
    procedure LoadFromFile(const FileName: String; out Endianness: TStringEndianness); overload; virtual;
    procedure LoadFromFile(const FileName: String); overload; virtual;
  {
    BOM is written only for UTF8-, Wide- and UnicodeStrings.
    Endiannes affects Wide- and UnicodeStrings, it has no meaning for single-byte
    strings.
  }
    procedure SaveToStream(Stream: TStream; WriteBOM: Boolean = True; Endianness: TStringEndianness = seSystem); virtual;
    procedure SaveToFile(const FileName: String; WriteBOM: Boolean = True; Endianness: TStringEndianness = seSystem); virtual;
    // grow/shrink settings
    property GrowMode: TGrowMode read fGrowMode write fGrowMode;
    property GrowFactor: Double read fGrowFactor write fGrowFactor;
    property GrowLimit: Integer read fGrowLimit write fGrowLimit;
    property ShrinkMode: TShrinkMode read fShrinkMode write fShrinkMode;
    property ShrinkFactor: Double read fShrinkFactor write fShrinkFactor;
    property ShrinkLimit: Integer read fShrinkLimit write fShrinkLimit;
    // user data
    property UserIntData: PtrInt read fUserIntData write fUserIntData;
    property UserPtrData: Pointer read fUserPtrData write fUserPtrData;
    property UserData: PtrInt read fUserIntData write fUserIntData;
  published
    property Capacity: Integer read GetCapacity write SetCapacity;
    property Count: Integer read fCount;
    property UpdateCount: Integer read fUpdateCount;
    property Updating: Boolean read GetUpdating;
    property Changed: Boolean read fChanged;
    property CaseSensitive: Boolean read fCaseSensitive write fCaseSensitive;
    property StrictDelimiter: Boolean read fStrictDelimiter write fStrictDelimiter;
    property TrailingLineBreak: Boolean read fTrailingLineBreak write fTrailingLineBreak;
    property Duplicates: TDuplicates read fDuplicates write fDuplicates;
    property Sorted: Boolean read fSorted;
    property OnChanging: TNotifyEvent read fOnChanging write fOnChanging;
    property OnChange: TNotifyEvent read fOnChange write fOnChange;    
  end;

implementation

uses
  StrRect;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
{$ENDIF}

{===============================================================================
    Auxiliary functions - implementation
===============================================================================}

{$IFDEF UTF8ToString_Implement}
Function UTF8ToString(const Str: UTF8String): UnicodeString;
begin
Result := UTF8Decode(Str);
end;
{$ENDIF}

{===============================================================================
--------------------------------------------------------------------------------
                              TExplicitStringList
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    TExplicitStringList - implementation
===============================================================================}

{-------------------------------------------------------------------------------
    TExplicitStringList - protected methods
-------------------------------------------------------------------------------}

Function TExplicitStringList.GetUpdating: Boolean;
begin
Result := fUpdateCount > 0;
end;

//------------------------------------------------------------------------------

class procedure TExplicitStringList.Error(const Msg: string; Data: array of const);
begin
raise EExplicitStringListError.CreateFmt(ClassName + '.' + Msg,Data);
end;

//------------------------------------------------------------------------------

class Function TExplicitStringList.GetSystemEndianness: TStringEndianness;
begin
Result := {$IFDEF ENDIAN_BIG}seBig{$ELSE}seLittle{$ENDIF};
end;

//------------------------------------------------------------------------------

class procedure TExplicitStringList.WideSwapEndian(Data: PWideChar; Count: TStrSize);
var
  i:  Integer;
begin
If Count > 0 then
  For i := 0 to Pred(Count) do
    begin
      PUInt16(Data)^ := UInt16(PUInt16(Data)^ shr 8) or UInt16(PUInt16(Data)^ shl 8);
      Inc(Data);
    end;
end;

//------------------------------------------------------------------------------

procedure TExplicitStringList.Grow(MinDelta: Integer = 1);
var
  Delta:  Integer;
begin
If Count >= Capacity then
  begin
    If Capacity = 0 then
      Delta := 16
    else
      case fGrowMode of
        gmLinear:
          Delta := Trunc(fGrowFactor);
        gmFast:
          Delta := Trunc(Capacity * fGrowFactor);
        gmFastAttenuated:
          If Capacity >= fGrowLimit then
            Delta := fGrowLimit shr 4
          else
            Delta := Trunc(Capacity * fGrowFactor);
      else
       {gmSlow}
       Delta := 1;
      end;
    If Delta < MinDelta then
      Delta := MinDelta
    else If Delta <= 0 then
      Delta := 1;
    Capacity := Capacity + Delta;;
  end;
end;

//------------------------------------------------------------------------------

procedure TExplicitStringList.Shrink;
begin
If Capacity > 0 then
  case fShrinkMode of
    smNormal:
      If (Capacity > fShrinkLimit) and (Count < Integer(Trunc((Capacity * fShrinkFactor) / 2))) then
        Capacity := Trunc(Capacity * fShrinkFactor);
    smToCount:
      Capacity := Count;
  else
    {smKeepCap}
    //do nothing
  end;
end;

//------------------------------------------------------------------------------

Function TExplicitStringList.CheckIndex(Index: Integer): Boolean;
begin
Result := (Index >= LowIndex) and (Index <= HighIndex);
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TExplicitStringList.SetUpdateState(Updating: Boolean);
begin
// nothing to do here
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

procedure TExplicitStringList.DoChanging;
begin
If fUpdateCount <= 0 then
  If Assigned(fOnChanging) then
    fOnChanging(Self);
end;

//------------------------------------------------------------------------------

procedure TExplicitStringList.DoChange;
begin
If fUpdateCount <= 0 then
  begin
    If Assigned(fOnChange) then
      fOnChange(Self);
  end
else fChanged := True;
end;

{-------------------------------------------------------------------------------
    TExplicitStringList - public methods
-------------------------------------------------------------------------------}

constructor TExplicitStringList.Create;
begin
inherited;
fGrowMode := gmFast;
fGrowFactor := 1.0;
fGrowLimit := 16 * 1024 * 1024;
fShrinkMode := smNormal;
fShrinkFactor := 0.5;
fShrinkLimit := 256;
fUserIntData := 0;
fUserPtrData := nil; 
fOnChanging := nil;
fOnChange := nil;
fCount := 0;
fUpdateCount := 0;
fChanged := False;
fCaseSensitive := False;
fStrictDelimiter := False;
fTrailingLineBreak := True;
fDuplicates := dupAccept;
fSorted := False;
end;

//------------------------------------------------------------------------------

Function TExplicitStringList.BeginUpdate: Integer;
begin
DoChanging;
If fUpdateCount = 0 then
  SetUpdateState(True);
fChanged := False;
Inc(fUpdateCount);
Result := fUpdateCount;
end;

//------------------------------------------------------------------------------

Function TExplicitStringList.EndUpdate: Integer;
begin
Dec(fUpdateCount);
If fUpdateCount = 0 then
  begin
    SetUpdateState(False);
    If fChanged then DoChange;
    fChanged := False;
  end;
Result := fUpdateCount;
end;

//------------------------------------------------------------------------------

procedure TExplicitStringList.Sort(Reversed: Boolean = False);

  procedure QuickSort(LeftIdx,RightIdx,Coef: Integer);
  var
    Idx,i:  Integer;
  begin
    If LeftIdx < RightIdx then
      begin
        Exchange((LeftIdx + RightIdx) shr 1,RightIdx);
        Idx := LeftIdx;
        For i := LeftIdx to Pred(RightIdx) do
          If (CompareItems(RightIdx,i) * Coef) > 0 then
            begin
              Exchange(i,idx);
              Inc(Idx);
            end;
        Exchange(Idx,RightIdx);
        QuickSort(LeftIdx,Idx - 1,Coef);
        QuickSort(Idx + 1,RightIdx,Coef);
      end;
  end;
  
begin
If fCount > 1 then
  begin
    BeginUpdate;
    try
      If Reversed then
        QuickSort(LowIndex,HighIndex,-1)
      else
        QuickSort(LowIndex,HighIndex,1);
      fSorted := not Reversed;
    finally
      EndUpdate;
    end;
  end
else fSorted := True;
end;

//------------------------------------------------------------------------------

procedure TExplicitStringList.LoadFromStream(Stream: TStream);
var
  Endianness: TStringEndianness;
begin
LoadFromStream(Stream,Endianness);
end;

//------------------------------------------------------------------------------

procedure TExplicitStringList.LoadFromFile(const FileName: String; out Endianness: TStringEndianness);
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
try
  LoadFromStream(FileStream,Endianness);
finally
  FileStream.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TExplicitStringList.LoadFromFile(const FileName: String);
var
  Endianness: TStringEndianness;
begin
LoadFromFile(FileName,Endianness);
end;

//------------------------------------------------------------------------------

procedure TExplicitStringList.SaveToStream(Stream: TStream; WriteBOM: Boolean = True; Endianness: TStringEndianness = seSystem);
var
  WriteSize:  UInt64;
  OldPos:     Int64;
  i:          Integer;
begin
If WriteBOM then
  WriteBOMToStream(Stream,Endianness);
WriteSize := GetWriteSize;
If Stream.Size < (Stream.Position + WriteSize) then
  begin
    OldPos := Stream.Position;
    try
      Stream.Size := Stream.Position + WriteSize;
    finally
      Stream.Position := OldPos;
    end;
  end;
For i := LowIndex to HighIndex do
  begin
    WriteItemToStream(Stream,i,Endianness);
    If (i < HighIndex) or fTrailingLineBreak then
      WriteLineBreakToStream(Stream,Endianness);
  end;
end;

//------------------------------------------------------------------------------

procedure TExplicitStringList.SaveToFile(const FileName: String; WriteBOM: Boolean = True; Endianness: TStringEndianness = seSystem);
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmCreate or fmShareDenyWrite);
try
  SaveToStream(FileStream,WriteBOM,Endianness);
finally
  FileStream.Free;
end;
end;

end.

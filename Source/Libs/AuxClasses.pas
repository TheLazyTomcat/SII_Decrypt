{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Auxiliary classes and classes-related material

  ©František Milt 2018-12-23

  Version 1.0.1

  Dependencies:
    AuxTypes - github.com/ncs-sniper/Lib.AuxTypes

===============================================================================}
unit AuxClasses;

{$IF defined(CPUX86_64) or defined(CPUX64)}
  {$DEFINE x64}
{$ELSEIF defined(CPU386)}
  {$DEFINE x86}
{$ELSE}
  {$DEFINE PurePascal}
{$IFEND}

{$IF Defined(WINDOWS) or Defined(MSWINDOWS)}
  {$DEFINE Windows}
{$IFEND}

{$IFDEF FPC}
  {$MODE ObjFPC}{$H+}
  {$ASMMODE Intel}
{$ENDIF}

interface

uses
  AuxTypes;

{===============================================================================
    Event and callback types
===============================================================================}

type
{
  TNotifyEvent is declared in classes, but if including entire classes unit
  into the project is not desirable, this declaration can be used instead.
}
  TNotifyEvent    = procedure(Sender: TObject) of object;
  TNotifyCallback = procedure(Sender: TObject);

  TIntegerEvent    = procedure(Sender: TObject; Value: Integer) of object;
  TIntegerCallback = procedure(Sender: TObject; Value: Integer);

  TFloatEvent    = procedure(Sender: TObject; Value: Double) of object;
  TFloatCallback = procedure(Sender: TObject; Value: Double);

  TStringEvent    = procedure(Sender: TObject; const Value: String) of object;
  TStringCallback = procedure(Sender: TObject; const Value: String);

  TMemoryEvent    = procedure(Sender: TObject; Addr: Pointer) of object;
  TMemoryCallback = procedure(Sender: TObject; Addr: Pointer);

  TBufferEvent    = procedure(Sender: TObject; const Buffer; Size: TMemSize) of object;
  TBufferCallback = procedure(Sender: TObject; const Buffer; Size: TMemSize);

  TObjectEvent    = procedure(Sender: TObject; Obj: TObject) of object;
  TObjectCallback = procedure(Sender: TObject; Obj: TObject);

{===============================================================================
--------------------------------------------------------------------------------
                                 TCustomObject
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TCustomObject - class declaration
===============================================================================}
{
  Normal object only with added fields/properties that can be used by user
  for any purpose.
}
  TCustomObject = class(TObject)
  private
    fUserIntData: PtrInt;
    fUserPtrData: Pointer;
  public
    constructor Create;
    property UserIntData: PtrInt read fUserIntData write fUserIntData;
    property UserPtrData: Pointer read fUserPtrData write fUserPtrData;
    property UserData: PtrInt read fUserIntData write fUserIntData;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                            TCustomRefCountedObject
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TCustomRefCountedObject - class declaration
===============================================================================}
{
  Reference counted object.
  Note that reference counting is not automatic, you have to call methods
  Acquire and Release for it to work.
  When FreeOnRelease is set to true (by default set to false), then the object
  is automatically freed inside of function Release when reference counter upon
  entry to this function is 1 (ie. it reaches 0 in this call).
}
  TCustomRefCountedObject = class(TCustomObject)
  private
    fRefCount:      Int32;
    fFreeOnRelease: Boolean;
    Function GetRefCount: Int32;
  public
    constructor Create;
    Function Acquire: Int32; virtual;
    Function Release: Int32; virtual;
    property RefCount: Int32 read GetRefCount;
    property FreeOnRelease: Boolean read fFreeOnRelease write fFreeOnRelease;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                               TCustomListObject
--------------------------------------------------------------------------------
===============================================================================}
{
  gmSlow            - grow by 1
  gmLinear          - grow by GrowFactor (integer part of the float)
  gmFast            - grow by capacity * GrowFactor
  gmFastAttenuated  - if capacity is below GrowLimit, grow by capacity * GrowFactor
                      if capacity is above or equal to GrowLimit, grow by 1/16 * GrowLimit
}
  TGrowMode = (gmSlow, gmLinear, gmFast, gmFastAttenuated);
{
  smKeepCap - list is not shrinked, capacity is preserved
  smNormal  - if capacity is above ShrinkLimit AND count is below (capacity * ShrinkFactor) / 2
              then capacity is set to capacity * ShrinkFactor, otherwise capacity is preserved
  smToCount - capacity is set to count
}
  TShrinkMode = (smKeepCap, smNormal, smToCount);

{===============================================================================
    TCustomListObject - class declaration
===============================================================================}
{
  Implements methods for advanced parametrized growing and shrinking of any
  list and a few more.
  Expects derived class to properly implement capacity and count properties and
  LowIndex and HighIndex functions.
}
  TCustomListObject = class(TCustomObject)
  private
    fGrowMode:      TGrowMode;
    fGrowFactor:    Double;
    fGrowLimit:     Integer;
    fShrinkMode:    TShrinkMode;
    fShrinkFactor:  Double;
    fShrinkLimit:   Integer;
  protected
    Function GetCapacity: Integer; virtual; abstract;
    procedure SetCapacity(Value: Integer); virtual; abstract;
    Function GetCount: Integer; virtual; abstract;
    procedure SetCount(Value: Integer); virtual; abstract;
    procedure Grow(MinDelta: Integer = 1); virtual;
    procedure Shrink; virtual;
  public
    constructor Create;
    Function LowIndex: Integer; virtual; abstract;
    Function HighIndex: Integer; virtual; abstract;
    Function CheckIndex(Index: Integer): Boolean; virtual;
    procedure CopyGrowSettings(Source: TCustomListObject); virtual;
    property GrowMode: TGrowMode read fGrowMode write fGrowMode;
    property GrowFactor: Double read fGrowFactor write fGrowFactor;
    property GrowLimit: Integer read fGrowLimit write fGrowLimit;
    property ShrinkMode: TShrinkMode read fShrinkMode write fShrinkMode;
    property ShrinkFactor: Double read fShrinkFactor write fShrinkFactor;
    property ShrinkLimit: Integer read fShrinkLimit write fShrinkLimit;
    property Capacity: Integer read GetCapacity write SetCapacity;
    property Count: Integer read GetCount write SetCount;
  end;

implementation

uses
  {$IF not Defined(FPC) and Defined(Windows) and Defined(PurePascal)}
    Windows,
  {$IFEND} SysUtils;

{===============================================================================
--------------------------------------------------------------------------------
                                 TCustomObject
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    TCustomObject - class implementation
===============================================================================}

{-------------------------------------------------------------------------------
    TCustomObject - public methods
-------------------------------------------------------------------------------}

constructor TCustomObject.Create;
begin
inherited;
fUserIntData := 0;
fUserPtrData := nil;
end;

{===============================================================================
--------------------------------------------------------------------------------
                            TCustomRefCountedObject
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    TCustomRefCountedObject - auxiliary functions
===============================================================================}

{$IFNDEF PurePascal}
Function InterlockedExchangeAdd(var A: Int32; B: Int32): Int32; register; assembler;
asm
{$IFDEF x64}
  {$IFDEF Windows}
        XCHG  RCX,  RDX
  LOCK  XADD  dword ptr [RDX], ECX
        MOV   EAX,  ECX
  {$ELSE}
        XCHG  RDI,  RSI
  LOCK  XADD  dword ptr [RSI], EDI
        MOV   EAX,  EDI
  {$ENDIF}
{$ELSE}
        XCHG  EAX,  EDX
  LOCK  XADD  dword ptr [EDX], EAX
{$ENDIF}
end;
{$ENDIF}

{===============================================================================
    TCustomRefCountedObject - class implementation
===============================================================================}

{-------------------------------------------------------------------------------
    TCustomRefCountedObject - private methods
-------------------------------------------------------------------------------}

Function TCustomRefCountedObject.GetRefCount: Int32;
begin
Result := InterlockedExchangeAdd(fRefCount,0);
end;

{-------------------------------------------------------------------------------
    TCustomRefCountedObject - public methods
-------------------------------------------------------------------------------}

constructor TCustomRefCountedObject.Create;
begin
inherited Create;
fRefCount := 0;
fFreeOnRelease := False;
end;

//------------------------------------------------------------------------------

Function TCustomRefCountedObject.Acquire: Int32;
begin
Result := InterlockedExchangeAdd(fRefCount,1) + 1;
end;

//------------------------------------------------------------------------------

Function TCustomRefCountedObject.Release: Int32;
begin
Result := InterlockedExchangeAdd(fRefCount,-1) - 1;
If fFreeOnRelease and (Result <= 0) then
  Self.Free;
end;

{===============================================================================
--------------------------------------------------------------------------------
                               TCustomListObject
--------------------------------------------------------------------------------
===============================================================================}

const
  CAPACITY_GROW_INIT = 32;

{===============================================================================
    TCustomListObject - class implementation
===============================================================================}

{-------------------------------------------------------------------------------
    TCustomListObject - protected methods
-------------------------------------------------------------------------------}

procedure TCustomListObject.Grow(MinDelta: Integer = 1);
var
  Delta:  Integer;
begin
If Count >= Capacity then
  begin
    If Capacity = 0 then
      Delta := CAPACITY_GROW_INIT
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
    Capacity := Capacity + Delta;
  end;
end;

//------------------------------------------------------------------------------

procedure TCustomListObject.Shrink;
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

{-------------------------------------------------------------------------------
    TCustomListObject - public methods
-------------------------------------------------------------------------------}

constructor TCustomListObject.Create;
begin
inherited;
fGrowMode := gmFast;
fGrowFactor := 1.0;
fGrowLimit := 128 * 1024 * 1024;
fShrinkMode := smNormal;
fShrinkFactor := 0.5;
fShrinkLimit := 256;
end;

//------------------------------------------------------------------------------

Function TCustomListObject.CheckIndex(Index: Integer): Boolean;
begin
Result := (Index >= LowIndex) and (Index <= HighIndex);
end;

//------------------------------------------------------------------------------

procedure TCustomListObject.CopyGrowSettings(Source: TCustomListObject);
begin
fGrowMode := Source.GrowMode;
fGrowFactor := Source.GrowFactor;
fGrowLimit := Source.GrowLimit;
fShrinkMode := Source.ShrinkMode;
fShrinkFactor := Source.ShrinkFactor;
fShrinkLimit := Source.ShrinkLimit;
end;

end.

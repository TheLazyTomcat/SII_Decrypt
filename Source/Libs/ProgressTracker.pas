{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Progress tracker

  ©František Milt 2018-03-21

  Version 1.1

===============================================================================}
unit ProgressTracker;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$TYPEINFO ON}

interface

{===============================================================================
--------------------------------------------------------------------------------
                                TProgressTracker
--------------------------------------------------------------------------------
===============================================================================}

type
  TProgressEvent    = procedure(Sender: TObject; Progress: Single) of object;
  TProgressCallback = procedure(Sender: TObject; Progress: Single);

  TProgressTracker = class; // forward declaration

  TProgressStage = record
    StageID:        Integer;
    AbsoluteLength: Single;
    RelativeLength: Single;
    RelativeStart:  Single;
    StageObject:    TProgressTracker;
  end;

  TProgressStages = record
    Arr:    array of TProgressStage;
    Count:  Integer;
  end;

{===============================================================================
    TProgressTracker - declaration
===============================================================================}

  TProgressTracker = class(TObject)
  private
    fUpdateCounter:       Integer;
    fConsecutiveStages:   Boolean;
    fGrowOnly:            Boolean;
    fProgress:            Single;
    fMaximum:             Int64;
    fPosition:            Int64;
    fStages:              TProgressStages;
    fOnStageProgress:     TProgressEvent;
    fOnTrackerProgress:   TProgressEvent;
    fOnTrackerProgressCB: TProgressCallback;
    fUserPtrData:         Pointer;
    fUserIntData:         Integer;
    Function GetUpdating: Boolean;
    procedure SetConsecutiveStages(Value: Boolean);
    procedure SetProgress(Value: Single);
    procedure SetMaximum(Value: Int64);
    procedure SetPosition(Value: Int64);
    Function GetStage(Index: Integer): TProgressStage;
    Function GetStageObject(Index: Integer): TProgressTracker;
  protected
    Function CheckIndex(Index: Integer): Boolean; virtual;
    procedure Grow; virtual;
    procedure DoStageProgress; virtual;
    procedure DoTrackerProgress; virtual;
    procedure DoProgressEvents; virtual;
    procedure StageProgressHandler(Sender: TObject; {%H-}Progress: Single); virtual;
    property StageEvent: TProgressEvent read fOnStageProgress write fOnStageProgress;
  public
    constructor Create;
    destructor Destroy; override;
    Function BeginUpdate: Integer; virtual;
    Function EndUpdate: Integer; virtual;
    Function LowIndex: Integer; virtual;
    Function HighIndex: Integer; virtual;
    Function First: TProgressStage; virtual;
    Function Last: TProgressStage; virtual;
    Function IndexOf(StageObject: TProgressTracker): Integer; overload; virtual;
    Function IndexOf(StageID: Integer): Integer; overload; virtual;
    Function Find(StageObject: TProgressTracker; out Index: Integer): Boolean; overload; virtual;
    Function Find(StageID: Integer; out Index: Integer): Boolean; overload; virtual;
    Function Find(StageObject: TProgressTracker; out Stage: TProgressStage): Boolean; overload; virtual;
    Function Find(StageID: Integer; out Stage: TProgressStage): Boolean; overload; virtual;
    Function Add(AbsoluteLength: Single; StageID: Integer = 0): Integer; virtual;
    procedure Insert(Index: Integer; AbsoluteLength: Single; StageID: Integer = 0); virtual;
    procedure Move(SrcIdx, DstIdx: Integer); virtual;
    procedure Exchange(Idx1, Idx2: Integer); virtual;
    Function Extract(StageObject: TProgressTracker): TProgressTracker; virtual;
    Function Remove(StageObject: TProgressTracker): Integer; overload; virtual;
    Function Remove(StageID: Integer): Integer; overload; virtual;
    procedure Delete(Index: Integer); virtual;
    procedure Clear; virtual;
    Function Recalculate(ProgressOnly: Boolean): Single; virtual;
    procedure RecalculateStages; virtual;
    procedure SetStageProgress(Index: Integer; NewValue: Single); virtual;
    procedure SetStageMaximum(Index: Integer; NewValue: Int64); virtual;
    procedure SetStagePosition(Index: Integer; NewValue: Int64); virtual;
    Function SetStageIDProgress(StageID: Integer; NewValue: Single): Boolean; virtual;
    Function SetStageIDMaximum(StageID: Integer; NewValue: Int64): Boolean; virtual;
    Function SetStageIDPosition(StageID: Integer; NewValue: Int64): Boolean; virtual;
    property Stages[Index: Integer]: TProgressStage read GetStage; default;
    property StageObjects[Index: Integer]: TProgressTracker read GetStageObject;
    property OnProgressCallBack: TProgressCallback read fOnTrackerProgressCB write fOnTrackerProgressCB;
    property UserPtrData: Pointer read fUserPtrData write fUserPtrData;
  published
    property Updating: Boolean read GetUpdating;
    property ConsecutiveStages: Boolean read fConsecutiveStages write SetConsecutiveStages;
    property GrowOnly: Boolean read fGrowOnly write fGrowOnly;
    property Progress: Single read fProgress write SetProgress;
    property Maximum: Int64 read fMaximum write SetMaximum;
    property Position: Int64 read fPosition write SetPosition;
    property Count: Integer read fStages.Count;
    property OnProgress: TProgressEvent read fOnTrackerProgress write fOnTrackerProgress;
    property UserIntData: Integer read fUserIntData write fUserIntData;
    property UserData: Integer read fUserIntData write fUserIntData;
  end;

implementation

uses
  SysUtils;

{===============================================================================
--------------------------------------------------------------------------------
                                TProgressTracker
--------------------------------------------------------------------------------
===============================================================================}

const
  PT_GROW_DELTA = 32;

{===============================================================================
    TProgressTracker - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TProgressTracker - private methods
-------------------------------------------------------------------------------}

Function TProgressTracker.GetUpdating: Boolean;
begin
Result := fUpdateCounter <> 0;
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.SetConsecutiveStages(Value: Boolean);
begin
If Value <> fConsecutiveStages then
  begin
    fConsecutiveStages := Value;
    Recalculate(True);
  end;
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.SetProgress(Value: Single);
begin
If (Value > fProgress) or not fGrowOnly then
  begin
    fProgress := Value;
    DoProgressEvents;
  end;
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.SetMaximum(Value: Int64);
begin
If fMaximum <> Value then
  begin
    fMaximum := Value;
    Recalculate(True);
  end;
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.SetPosition(Value: Int64);
begin
If fPosition <> Value then
  begin
    fPosition := Value;
    Recalculate(True);
  end;
end;

//------------------------------------------------------------------------------

Function TProgressTracker.GetStage(Index: Integer): TProgressStage;
begin
If CheckIndex(Index) then
  Result := fStages.Arr[Index]
else
  raise Exception.CreateFmt('TProgressTracker.GetStage: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

Function TProgressTracker.GetStageObject(Index: Integer): TProgressTracker;
begin
Result := GetStage(Index).StageObject;
end;


{-------------------------------------------------------------------------------
    TProgressTracker - protected methods
-------------------------------------------------------------------------------}

Function TProgressTracker.CheckIndex(Index: Integer): Boolean;
begin
Result := (Index >= Low(fStages.Arr)) and (Index < fStages.Count);
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.Grow;
begin
If fStages.Count >= Length(fStages.Arr) then
  SetLength(fStages.Arr,Length(fSTages.Arr) + PT_GROW_DELTA);
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.DoStageProgress;
begin
If Assigned(fOnStageProgress) and (fUpdateCounter <= 0) then
  fOnStageProgress(Self,fProgress);
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.DoTrackerProgress;
begin
If fUpdateCounter <= 0 then
  begin
    If Assigned(fOnTrackerProgress) then
      fOnTrackerProgress(Self,fProgress);
    If Assigned(fOnTrackerProgressCB) then
      fOnTrackerProgressCB(Self,fProgress);
  end;
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.DoProgressEvents;
begin
If (fUpdateCounter <= 0) then
  begin
    DoStageProgress;
    DoTrackerProgress;
  end;
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.StageProgressHandler(Sender: TObject; Progress: Single);
begin
Recalculate(True);
end;


{-------------------------------------------------------------------------------
    TProgressTracker - public methods
-------------------------------------------------------------------------------}

constructor TProgressTracker.Create;
begin
inherited;
fUpdateCounter := 0;
fConsecutiveStages := True;
fGrowOnly := False;
fProgress := 0.0;
fMaximum := 0;
fPosition := 0;
SetLength(fStages.Arr,0);
fStages.Count := 0;
fOnStageProgress := nil;
fOnTrackerProgress := nil;
fOnTrackerProgressCB := nil;
fUserPtrData := nil;
fUserIntData := 0;
end;

//------------------------------------------------------------------------------

destructor TProgressTracker.Destroy;
begin
// prevent calling of events from Clear method
fOnStageProgress := nil;
fOnTrackerProgress := nil;
fOnTrackerProgressCB := nil;
Clear;
inherited;
end;

//------------------------------------------------------------------------------

Function TProgressTracker.BeginUpdate: Integer;
begin
Inc(fUpdateCounter);
Result := fUpdateCounter;
end;

//------------------------------------------------------------------------------

Function TProgressTracker.EndUpdate: Integer;
begin
Dec(fUpdateCounter);
Result := fUpdateCounter;
If fUpdateCounter <= 0 then
  begin
    Recalculate(False);
    fUpdateCounter := 0;
  end;
end;

//------------------------------------------------------------------------------

Function TProgressTracker.LowIndex: Integer;
begin
Result := Low(fStages.Arr);
end;

//------------------------------------------------------------------------------

Function TProgressTracker.HighIndex: Integer;
begin
Result := Pred(fStages.Count);
end;

//------------------------------------------------------------------------------

Function TProgressTracker.First: TProgressStage;
begin
Result := GetStage(LowIndex);
end;

//------------------------------------------------------------------------------

Function TProgressTracker.Last: TProgressStage;
begin
Result := GetStage(HighIndex);
end;

//------------------------------------------------------------------------------

Function TProgressTracker.IndexOf(StageObject: TProgressTracker): Integer;
var
  i:  Integer;
begin
Result := -1;
For i := LowIndex to HighIndex do
  If fStages.Arr[i].StageObject = StageObject then
    begin
      Result := i;
      Break{For i};
    end;
end;

//------------------------------------------------------------------------------

Function TProgressTracker.IndexOf(StageID: Integer): Integer;
var
  i:  Integer;
begin
Result := -1;
For i := LowIndex to HighIndex do
  If fStages.Arr[i].StageID = StageID then
    begin
      Result := i;
      Break{For i};
    end;
end;

//------------------------------------------------------------------------------

Function TProgressTracker.Find(StageObject: TProgressTracker; out Index: Integer): Boolean;
begin
Index := IndexOf(StageObject);
Result := Index >= LowIndex;
end;

//------------------------------------------------------------------------------

Function TProgressTracker.Find(StageID: Integer; out Index: Integer): Boolean;
begin
Index := IndexOf(StageID);
Result := Index >= LowIndex;
end;

//------------------------------------------------------------------------------

Function TProgressTracker.Find(StageObject: TProgressTracker; out Stage: TProgressStage): Boolean;
var
  Index:  Integer;
begin
Index := IndexOf(StageObject);
If Index >= LowIndex then
  begin
    Stage := fStages.Arr[Index];
    Result := True;
  end
else Result := False;
end;

//------------------------------------------------------------------------------

Function TProgressTracker.Find(StageID: Integer; out Stage: TProgressStage): Boolean;
var
  Index:  Integer;
begin
Index := IndexOf(StageID);
If Index >= LowIndex then
  begin
    Stage := fStages.Arr[Index];
    Result := True;
  end
else Result := False;
end;

//------------------------------------------------------------------------------

Function TProgressTracker.Add(AbsoluteLength: Single; StageID: Integer = 0): Integer;
var
  NewItem:  TProgressStage;
begin
Grow;
NewItem.StageID := StageID;
NewItem.AbsoluteLength := AbsoluteLength;
NewItem.RelativeLength := 0.0;
NewItem.StageObject := TProgressTracker.Create;
NewItem.StageObject.StageEvent := StageProgressHandler;
Result := fStages.Count;
fStages.Arr[Result] := NewItem;
Inc(fStages.Count);
Recalculate(False);
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.Insert(Index: Integer; AbsoluteLength: Single; StageID: Integer = 0);
var
  i:        Integer;
  NewItem:  TProgressStage;
begin
If CheckIndex(Index) then
  begin
    Grow;
    For i := HighIndex downto Index do
      fStages.Arr[i + 1] := fStages.Arr[i];
    NewItem.StageID := StageID;
    NewItem.AbsoluteLength := AbsoluteLength;
    NewItem.RelativeLength := 0.0;
    NewItem.StageObject := TProgressTracker.Create;
    NewItem.StageObject.StageEvent := StageProgressHandler;
    fStages.Arr[Index] := NewItem;
    Inc(fStages.Count);
    Recalculate(False);
  end
else If Index = fStages.Count then
  Add(AbsoluteLength,StageID)
else
  raise Exception.CreateFmt('TProgressTracker.Insert: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.Move(SrcIdx, DstIdx: Integer);
var
  Temp: TProgressStage;
  i:    Integer;
begin
If SrcIdx <> DstIdx then
  begin
    If not CheckIndex(SrcIdx) then
      raise Exception.CreateFmt('TProgressTracker.Exchange: Source index (%d) out of bounds.',[SrcIdx]);
    If not CheckIndex(DstIdx) then
      raise Exception.CreateFmt('TProgressTracker.Exchange: Destination index (%d) out of bounds.',[DstIdx]);
    Temp := fStages.Arr[SrcIdx];
    If SrcIdx < DstIdx then
      For i := SrcIdx to Pred(DstIdx) do
        fStages.Arr[i] := fStages.Arr[i + 1]
    else
      For i := SrcIdx downto Succ(DstIdx) do
        fStages.Arr[i] := fStages.Arr[i - 1];
    fStages.Arr[DstIdx] := Temp;
    Recalculate(False);
  end;
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.Exchange(Idx1, Idx2: Integer);
var
  Temp: TProgressStage;
begin
If Idx1 <> Idx2 then
  begin
    If not CheckIndex(Idx1) then
      raise Exception.CreateFmt('TProgressTracker.Exchange: Index 1 (%d) out of bounds.',[Idx1]);
    If not CheckIndex(Idx2) then
      raise Exception.CreateFmt('TProgressTracker.Exchange: Index 2 (%d) out of bounds.',[Idx2]);
    Temp := fStages.Arr[Idx1];
    fStages.Arr[Idx1] := fStages.Arr[Idx2];
    fStages.Arr[Idx2] := Temp;
    Recalculate(False);
  end;
end;

//------------------------------------------------------------------------------

Function TProgressTracker.Extract(StageObject: TProgressTracker): TProgressTracker;
var
  Index:  Integer;
  i:      Integer;
begin
Index := IndexOf(StageObject);
If CheckIndex(Index) then
  begin
    Result := fStages.Arr[Index].StageObject;
    For i := Succ(Index) to Pred(fStages.Count) do
      fStages.Arr[i - 1] := fStages.Arr[i];
    Dec(fStages.Count);
    Recalculate(False);
  end
else Result := nil;
end;

//------------------------------------------------------------------------------

Function TProgressTracker.Remove(StageObject: TProgressTracker): Integer;
begin
Result := IndexOf(StageObject);
If CheckIndex(Result) then
  Delete(Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TProgressTracker.Remove(StageID: Integer): Integer;
begin
Result := IndexOf(StageID);
If CheckIndex(Result) then
  Delete(Result);
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.Delete(Index: Integer);
var
  i:  Integer;
begin
If CheckIndex(Index) then
  begin
    FreeAndNil(fStages.Arr[Index].StageObject);
    For i := Succ(Index) to Pred(fStages.Count) do
      fStages.Arr[i - 1] := fStages.Arr[i];
    Dec(fStages.Count);
    Recalculate(False);
  end
else raise Exception.CreateFmt('TProgressTracker.Delete: Index (%d) out of bounds..',[Index]);
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.Clear;
var
  i:  Integer;
begin
For i := LowIndex to HighIndex do
  FreeAndNil(fStages.Arr[i].StageObject);
fStages.Count := 0;
Recalculate(False);
end;

//------------------------------------------------------------------------------

Function TProgressTracker.Recalculate(ProgressOnly: Boolean): Single;
var
  i:    Integer;
  Temp: Single;
begin
If fStages.Count > 0 then
  begin
    If not ProgressOnly then
      begin
        Temp := 0.0;
        For i := LowIndex to HighIndex do
          Temp := Temp + fStages.Arr[i].AbsoluteLength;
        For i := LowIndex to HighIndex do
          begin
            If Temp <> 0.0 then
              fStages.Arr[i].RelativeLength := fStages.Arr[i].AbsoluteLength / Temp
            else
              fStages.Arr[i].RelativeLength := 0.0;
            If i > LowIndex then
              fStages.Arr[i].RelativeStart := fStages.Arr[i - 1].RelativeStart + fStages.Arr[i - 1].RelativeLength
            else
              fStages.Arr[i].RelativeStart := 0.0;
          end;
      end;
    fProgress := 0.0;
    If fConsecutiveStages then
      begin
        For i := HighIndex downto LowIndex  do
          If fStages.Arr[i].StageObject.Progress <> 0.0 then
            begin
              fProgress := fStages.Arr[i].RelativeStart + (fStages.Arr[i].StageObject.Progress * fStages.Arr[i].RelativeLength);
              Break{For i};
            end;
      end
    else
      begin
        For i := LowIndex to HighIndex do
          fProgress := fProgress + (fStages.Arr[i].StageObject.Progress * fStages.Arr[i].RelativeLength);
      end;
  end
else
  begin
    If fMaximum <> 0 then
      fProgress := fPosition / fMaximum
    else
      fProgress := 0.0;
  end;
DoProgressEvents;
Result := fProgress;
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.RecalculateStages;
var
  i:  Integer;
begin
BeginUpdate;
try
  For i := LowIndex to HighIndex do
    begin
      fStages.Arr[i].StageObject.RecalculateStages;
      fStages.Arr[i].StageObject.Recalculate(True);
    end;
finally
  EndUpdate;
end;
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.SetStageProgress(Index: Integer; NewValue: Single);
begin
If CheckIndex(Index) then
  fStages.Arr[Index].StageObject.Progress := NewValue
else
  raise Exception.CreateFmt('TProgressTracker.SetStageProgress: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.SetStageMaximum(Index: Integer; NewValue: Int64);
begin
If CheckIndex(Index) then
  fStages.Arr[Index].StageObject.Maximum := NewValue
else
  raise Exception.CreateFmt('TProgressTracker.SetStageMaximum: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.SetStagePosition(Index: Integer; NewValue: Int64);
begin
If CheckIndex(Index) then
  fStages.Arr[Index].StageObject.Position := NewValue
else
  raise Exception.CreateFmt('TProgressTracker.SetStagePosition: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

Function TProgressTracker.SetStageIDProgress(StageID: Integer; NewValue: Single): Boolean;
var
  Index:  Integer;
begin
If Find(StageID,Index) then
  begin
    fStages.Arr[Index].StageObject.Progress := NewValue;
    Result := True;
  end
else Result := False;
end;

//------------------------------------------------------------------------------

Function TProgressTracker.SetStageIDMaximum(StageID: Integer; NewValue: Int64): Boolean;
var
  Index:  Integer;
begin
If Find(StageID,Index) then
  begin
    fStages.Arr[Index].StageObject.Maximum := NewValue;
    Result := True;
  end
else Result := False;
end;

//------------------------------------------------------------------------------

Function TProgressTracker.SetStageIDPosition(StageID: Integer; NewValue: Int64): Boolean;
var
  Index:  Integer;
begin
If Find(StageID,Index) then
  begin
    fStages.Arr[Index].StageObject.Position := NewValue;
    Result := True;
  end
else Result := False;
end;

end.

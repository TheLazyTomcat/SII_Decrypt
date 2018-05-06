{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Progress tracker

  ©František Milt 2018-04-29

  Version 1.3.3

  Dependencies:
    AuxTypes   - github.com/ncs-sniper/Lib.AuxTypes
    AuxClasses - github.com/ncs-sniper/Lib.AuxClasses

===============================================================================}
unit ProgressTracker;

{$IFDEF FPC}
  {$MODE Delphi}
  {$DEFINE FPC_DisableWarns}
  {$MACRO ON}
{$ENDIF}

{$TYPEINFO ON}

interface

uses
  AuxClasses;

{===============================================================================
--------------------------------------------------------------------------------
                                TProgressTracker
--------------------------------------------------------------------------------
===============================================================================}

type
  TProgressTracker = class; // forward declaration

  TProgressStage = record
    StageID:          Integer;
    AbsoluteLength:   Double;
    RelativeLength:   Double;
    RelativeStart:    Double;
    StageObject:      TProgressTracker;
    RelativeProgress: Double;
  end;

  TProgressStages = record
    Arr:    array of TProgressStage;
    Count:  Integer;
  end;

{===============================================================================
    TProgressTracker - declaration
===============================================================================}

  TProgressTracker = class(TCustomListObject)
  private
    fUpdateCounter:       Integer;
    fConsecutiveStages:   Boolean;
    fConsStagesActiveIdx: Integer;
    fStrictlyGrowing:     Boolean;
    fLimitedRange:        Boolean;
    fMinProgressDelta:    Double;
    fPrevProgress:        Double;
    fProgress:            Double;
    fMaximum:             Int64;
    fPosition:            Int64;
    fStageIndex:          Integer;
    fStages:              TProgressStages;
    fOnStageProgress:     TFloatEvent;
    fOnTrackerProgress:   TFloatEvent;
    fOnTrackerProgressCB: TFloatCallback;
    Function GetUpdating: Boolean;
    procedure SetConsecutiveStages(Value: Boolean);
    procedure SetProgress(Value: Double);
    procedure SetMaximum(Value: Int64);
    procedure SetPosition(Value: Int64);
    Function GetStage(Index: Integer): TProgressStage;
    Function GetStageObject(Index: Integer): TProgressTracker;
  protected
    Function GetCapacity: Integer; override;
    procedure SetCapacity(Value: Integer); override;
    Function GetCount: Integer; override;
    procedure SetCount(Value: Integer); override;
    procedure DoStageProgress; virtual;
    procedure DoTrackerProgress; virtual;
    procedure DoProgress; virtual;
    procedure StageProgressHandler(Sender: TObject; Progress: Double); virtual;
    procedure ReindexStages; virtual;
    procedure PrepareNewStage(var NewStage: TProgressStage); virtual;
    property StageEvent: TFloatEvent read fOnStageProgress write fOnStageProgress;
    property StageIndex: Integer read fStageIndex write fStageIndex;
  public
    constructor Create;
    destructor Destroy; override;
    Function BeginUpdate: Integer; virtual;
    Function EndUpdate: Integer; virtual;
    Function LowIndex: Integer; override;
    Function HighIndex: Integer; override;
    Function First: TProgressStage; virtual;
    Function Last: TProgressStage; virtual;
    Function IndexOf(StageObject: TProgressTracker): Integer; overload; virtual;
    Function IndexOf(StageID: Integer): Integer; overload; virtual;
    Function Find(StageObject: TProgressTracker; out Index: Integer): Boolean; overload; virtual;
    Function Find(StageID: Integer; out Index: Integer): Boolean; overload; virtual;
    Function Find(StageObject: TProgressTracker; out Stage: TProgressStage): Boolean; overload; virtual;
    Function Find(StageID: Integer; out Stage: TProgressStage): Boolean; overload; virtual;
    Function Add(AbsoluteLength: Double; StageID: Integer = 0): Integer; virtual;
    procedure Insert(Index: Integer; AbsoluteLength: Double; StageID: Integer = 0); virtual;
    procedure Move(SrcIdx, DstIdx: Integer); virtual;
    procedure Exchange(Idx1, Idx2: Integer); virtual;
    Function Extract(StageObject: TProgressTracker): TProgressTracker; virtual;
    Function Remove(StageObject: TProgressTracker): Integer; overload; virtual;
    Function Remove(StageID: Integer): Integer; overload; virtual;
    procedure Delete(Index: Integer); virtual;
    procedure Clear; virtual;
    Function Recalculate(LocalProgressOnly: Boolean): Double; virtual;
    procedure RecalculateStages; virtual;
    procedure SetStageProgress(Index: Integer; NewValue: Double); virtual;
    procedure SetStageMaximum(Index: Integer; NewValue: Int64); virtual;
    procedure SetStagePosition(Index: Integer; NewValue: Int64); virtual;
    Function SetStageIDProgress(StageID: Integer; NewValue: Double): Boolean; virtual;
    Function SetStageIDMaximum(StageID: Integer; NewValue: Int64): Boolean; virtual;
    Function SetStageIDPosition(StageID: Integer; NewValue: Int64): Boolean; virtual;
    property Stages[Index: Integer]: TProgressStage read GetStage; default;
    property StageObjects[Index: Integer]: TProgressTracker read GetStageObject;
    property OnProgressCallBack: TFloatCallback read fOnTrackerProgressCB write fOnTrackerProgressCB;
  published
    property Updating: Boolean read GetUpdating;
    property ConsecutiveStages: Boolean read fConsecutiveStages write SetConsecutiveStages;
    property StrictlyGrowing: Boolean read fStrictlyGrowing write fStrictlyGrowing;
    property LimitedRange: Boolean read fLimitedRange write fLimitedRange;
    property MinProgressDelta: Double read fMinProgressDelta write fMinProgressDelta;
    property Progress: Double read fProgress write SetProgress;
    property Maximum: Int64 read fMaximum write SetMaximum;
    property Position: Int64 read fPosition write SetPosition;
    property OnProgressEvent: TFloatEvent read fOnTrackerProgress write fOnTrackerProgress;
    property OnProgress: TFloatEvent read fOnTrackerProgress write fOnTrackerProgress;
  end;

implementation

uses
  SysUtils;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
{$ENDIF}

{===============================================================================
--------------------------------------------------------------------------------
                                TProgressTracker
--------------------------------------------------------------------------------
===============================================================================}
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

procedure TProgressTracker.SetProgress(Value: Double);
begin
If ((Value > fProgress) or ((fProgress = 0.0) and (Value = 0.0))) or
  not fStrictlyGrowing then
  begin
    fProgress := Value;  
    If fLimitedRange then
      If fProgress < 0.0 then fProgress := 0.0
        else If fProgress > 1.0 then fProgress := 1.0;
    DoProgress;
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

Function TProgressTracker.GetCapacity: Integer;
begin
Result := Length(fStages.Arr);
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.SetCapacity(Value: Integer);
var
  i:  Integer;
begin
If Value < fStages.Count then
  begin
    For i := Value to Pred(fStages.Count) do
      FreeAndNil(fStages.Arr[i].StageObject);
    fStages.Count := Value;
    Recalculate(False);
  end;
SetLength(fStages.Arr,Value);
end;

//------------------------------------------------------------------------------

Function TProgressTracker.GetCount: Integer;
begin
Result := fStages.Count;
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TProgressTracker.SetCount(Value: Integer);
begin
// do nothing
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

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

procedure TProgressTracker.DoProgress;
begin
If (Abs(fProgress - fPrevProgress) >= fMinProgressDelta) or
   ((fProgress = 0.0) or (fProgress = 1.0)) then
  begin
    fPrevProgress := fProgress;
    If (fUpdateCounter <= 0) then
      begin
        DoStageProgress;
        DoTrackerProgress;
      end;
  end;
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.StageProgressHandler(Sender: TObject; Progress: Double);
var
  NewRelativeProgress:  Double;
begin
If CheckIndex((Sender as TProgressTracker).StageIndex) then
  with fStages.Arr[TProgressTracker(Sender).StageIndex] do
    begin
      NewRelativeProgress := (Progress * RelativeLength);
      If fConsecutiveStages then
        begin
          If TProgressTracker(Sender).StageIndex >= fConsStagesActiveIdx then
            begin
              If NewRelativeProgress <> 0.0 then
                begin
                  fConsStagesActiveIdx := TProgressTracker(Sender).StageIndex;
                  fProgress := RelativeStart + NewRelativeProgress
                end
              else If RelativeProgress <> 0.0 then Recalculate(True);
            end;
          RelativeProgress := NewRelativeProgress;
        end
      else
        begin
          If RelativeProgress <> NewRelativeProgress then
            begin
              fProgress := (fProgress - RelativeProgress) + NewRelativeProgress;
              RelativeProgress := NewRelativeProgress;
            end;
        end;
      If fLimitedRange then
        If fProgress < 0.0 then fProgress := 0.0
          else If fProgress > 1.0 then fProgress := 1.0;
      DoProgress;
    end;
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.ReindexStages;
var
  i:  Integer;
begin
If fUpdateCounter <= 0 then
  For i := LowIndex to HighIndex do
    fStages.Arr[i].StageObject.StageIndex := i;
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.PrepareNewStage(var NewStage: TProgressStage);
begin
NewStage.RelativeLength := 0.0;
NewStage.StageObject := TProgressTracker.Create;
NewStage.StageObject.StageEvent := StageProgressHandler;
NewStage.StageObject.ConsecutiveStages := fConsecutiveStages;
NewStage.StageObject.StrictlyGrowing := fStrictlyGrowing;
NewStage.StageObject.LimitedRange := fLimitedRange;
NewStage.StageObject.MinProgressDelta := fMinProgressDelta;
NewStage.StageObject.CopyGrowSettings(Self);
NewStage.RelativeProgress := 0.0;
end;

{-------------------------------------------------------------------------------
    TProgressTracker - public methods
-------------------------------------------------------------------------------}

constructor TProgressTracker.Create;
begin
inherited;
fUpdateCounter := 0;
fConsecutiveStages := True;
fConsStagesActiveIdx := -1;
fStrictlyGrowing := False;
fLimitedRange := True;
fMinProgressDelta := 0.0;
fPrevProgress := 0.0;
fProgress := 0.0;
fMaximum := 0;
fPosition := 0;
fStageIndex := -1;
SetLength(fStages.Arr,0);
fStages.Count := 0;
fOnStageProgress := nil;
fOnTrackerProgress := nil;
fOnTrackerProgressCB := nil;
// change grow limit (orginal is set to 128M, that is too high)
GrowLimit := 64 * 1024;
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
    fUpdateCounter := 0;  
    ReindexStages;
    Recalculate(False);
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

Function TProgressTracker.Add(AbsoluteLength: Double; StageID: Integer = 0): Integer;
var
  NewStage: TProgressStage;
begin
Grow;
NewStage.StageID := StageID;
NewStage.AbsoluteLength := AbsoluteLength;
PrepareNewStage(NewStage);
NewStage.StageObject.StageIndex := fStages.Count;
Result := fStages.Count;
fStages.Arr[Result] := NewStage;
Inc(fStages.Count);
Recalculate(False);
end;

//------------------------------------------------------------------------------

procedure TProgressTracker.Insert(Index: Integer; AbsoluteLength: Double; StageID: Integer = 0);
var
  i:        Integer;
  NewStage:  TProgressStage;
begin
If CheckIndex(Index) then
  begin
    Grow;
    For i := HighIndex downto Index do
      fStages.Arr[i + 1] := fStages.Arr[i];
    NewStage.StageID := StageID;
    NewStage.AbsoluteLength := AbsoluteLength;
    PrepareNewStage(NewStage);
    NewStage.StageObject.StageIndex := Index;    
    fStages.Arr[Index] := NewStage;
    Inc(fStages.Count);
    ReindexStages;
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
    ReindexStages;
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
    ReindexStages;
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
    ReindexStages;
    Recalculate(False);
    Shrink;
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
    ReindexStages;
    Recalculate(False);
    Shrink;
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
ReindexStages;
Recalculate(False);
Shrink;
end;

//------------------------------------------------------------------------------

Function TProgressTracker.Recalculate(LocalProgressOnly: Boolean): Double;
var
  i:    Integer;
  Temp: Double;
begin
If fUpdateCounter <= 0 then
  begin
    If fStages.Count > 0 then
      begin
        If not LocalProgressOnly then
          begin
            Temp := 0.0;
            For i := LowIndex to HighIndex do
              Temp := Temp + fStages.Arr[i].AbsoluteLength;
            For i := LowIndex to HighIndex do
              with fStages.Arr[i] do
                begin
                  If Temp <> 0.0 then
                    RelativeLength := AbsoluteLength / Temp
                  else
                    RelativeLength := 0.0;
                  If i > LowIndex then
                    RelativeStart := fStages.Arr[i - 1].RelativeStart + fStages.Arr[i - 1].RelativeLength
                  else
                    RelativeStart := 0.0;
                  RelativeProgress := RelativeLength * StageObject.Progress;
               end;
          end;
        fProgress := 0.0;
        If fConsecutiveStages then
          begin
            fConsStagesActiveIdx := -1;
            For i := HighIndex downto LowIndex  do
              If fStages.Arr[i].StageObject.Progress <> 0.0 then
                begin
                  fConsStagesActiveIdx := i;
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
    If fLimitedRange then
      If fProgress < 0.0 then fProgress := 0.0
        else If fProgress > 1.0 then fProgress := 1.0;
    DoProgress;
  end;
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

procedure TProgressTracker.SetStageProgress(Index: Integer; NewValue: Double);
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

Function TProgressTracker.SetStageIDProgress(StageID: Integer; NewValue: Double): Boolean;
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

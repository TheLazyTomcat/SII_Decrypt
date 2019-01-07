{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  AuxExceptions

    Set of exception classes designed to simplify exception creation in
    specific situations (eg. index out of bounds, invalid variable value,
    sytem error, ...).

  ©František Milt 2019-01-05

  Version 0.9 (under developent)

  Dependencies:
    AuxTypes - github.com/ncs-sniper/Lib.AuxTypes

===============================================================================}
unit AuxExceptions;

{$IF defined(CPU64) or defined(CPU64BITS)}
  {$DEFINE 64bit}
{$ELSEIF defined(CPU16)}
  {$DEFINE 16bit}
{$ELSE}
  {$DEFINE 32bit}
{$IFEND}

{$IF Defined(CPUX86_64) or Defined(CPUX64)}
  {$DEFINE x64}
{$ELSEIF Defined(CPU386)}
  {$DEFINE x86}
{$ELSE}
  {$DEFINE PurePascal}
{$IFEND}

{$IF Defined(WINDOWS) or Defined(MSWINDOWS)}
  {$DEFINE Windows}
{$ELSE}
  // for now unsupported, will try to add support for linux later
  {$MESSAGE FATAL 'Unsupported operating system.'}
  //{$IF not (Defined(UNIX) or Defined(POSIX))}
  //  {$MESSAGE FATAL 'Unsupported operating system.'}
  //{$IFEND}
{$IFEND}

{$IFDEF FPC}
  {$MODE ObjFPC}{$H+}
{$ENDIF}

{
  ExtendedException

  When defined, EGeneralException and all its subclasses provide extended
  error information (stack trace, CPU registers snapshot, ...).

  NOTE - currently not implemented.

  Enabled by default.
}
{$DEFINE EnableExtendedException}

// do not touch following...
{$IF not Defined(PurePascal) and Defined(EnableExtendedException)}
  {$DEFINE ExtendedException}
{$ELSE}
  {$UNDEF ExtendedException}
{$IFEND}

interface

uses
  Windows, SysUtils,
  AuxTypes;

{===============================================================================
--------------------------------------------------------------------------------
                             Base exception classes
--------------------------------------------------------------------------------
===============================================================================}

type
  TThreadID = DWORD;

{===============================================================================
    ECustomException - class declaration
===============================================================================}

  ECustomException = class(Exception)
  protected
    fTime:      TDateTime;
    fThreadID:  TThreadID;
  public
    constructor CreateFmt(const Msg: String; Args: array of const);
    property Time: TDateTime read fTime;
    property ThreadID: TThreadID read fThreadID;
  end;

{$IFDEF ExtendedException}
{===============================================================================
    EExtendedException - class declaration
===============================================================================}
  EExtendedException = class(ECustomException);  // later implement

{===============================================================================
    EGeneralException - class declaration
===============================================================================}
  EGeneralException = class(EExtendedException)
{$ELSE ExtendedException}
  EGeneralException = class(ECustomException)
{$ENDIF ExtendedException}
  private
    fFaultingObject:    String;
    fFaultingFunction:  String;
    fFullMessage:       String;
  public
    constructor CreateFmt(const Msg: String; Args: array of const; FaultObject: TObject; const FaultFunction: String); overload;
    constructor Create(const Msg: String; FaultObject: TObject; const FaultFunction: String); overload;
    property FaultingObject: String read fFaultingObject;
    property FaultingFunction: String read fFaultingFunction;
    property FullMessage: String read fFullMessage;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                                 System errors
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    ESystemError - class declaration
===============================================================================}

  ESystemError = class(EGeneralException)
  private
    fErrorCode: UInt32;
  public
    constructor Create(FullSysMsg: Boolean; FaultObject: TObject; const FaultFunction: String); overload;
    property ErrorCode: UInt32 read fErrorCode;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                                  Index errors
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    EIndexException - class declaration
===============================================================================}

  EIndexException = class(EGeneralException)
  protected
    fIndex: Integer;
    class Function GetDefaultMessage: String; virtual;
  public
    constructor Create(const Msg: String; Index: Integer; FaultObject: TObject; const FaultFunction: String); overload;
    constructor Create(Index: Integer; FaultObject: TObject; const FaultFunction: String); overload;
    property Index: Integer read fIndex;
  end;

{===============================================================================
    EIndexOutOfBounds - class declaration
===============================================================================}

  EIndexOutOfBounds = class(EIndexException)
  protected
    class Function GetDefaultMessage: String; override;
  end;

{===============================================================================
    EIndexTooLow - class declaration
===============================================================================}

  EIndexTooLow = class(EIndexException)
  protected
    class Function GetDefaultMessage: String; override;
  end;

{===============================================================================
    EIndexTooHigh - class declaration
===============================================================================}

  EIndexTooHigh = class(EIndexException)
  protected
    class Function GetDefaultMessage: String; override;
  end;

{===============================================================================
    EIndexInvalid - class declaration
===============================================================================}

  EIndexInvalid = class(EIndexException)
  protected
    class Function GetDefaultMessage: String; override;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                                  Value errors
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    EValueException - class declaration
===============================================================================}

  EValueException = class(EGeneralException)
  protected
    fValueName: String;
    fValue:     Variant;
    class Function VariantArrayToStr(Value: Variant): String; virtual;
    class Function GetDefaultMessage(ValueString: Boolean): String; virtual;
  public
    constructor Create(const Msg,ValueName: String; Value: Variant; FaultObject: TObject; const FaultFunction: String); overload;
    constructor Create(const Msg,ValueName: String; FaultObject: TObject; const FaultFunction: String); overload;
    constructor Create(const ValueName: String; Value: Variant; FaultObject: TObject; const FaultFunction: String); overload;
    constructor Create(const ValueName: String; FaultObject: TObject; const FaultFunction: String); overload;
    property ValueName: String read FValueName;
    property Value: Variant read fValue;
  end;

{===============================================================================
    EValueInvalid - class declaration
===============================================================================}

  EValueInvalid = class(EValueException)
  protected
    class Function GetDefaultMessage(ValueString: Boolean): String; override;
  end;

{===============================================================================
    EValueInvalidNameOnly - class declaration
===============================================================================}

  EValueInvalidNameOnly = class(EValueException)
  protected
    class Function GetDefaultMessage(ValueString: Boolean): String; override;
  end;

implementation

uses
  Variants;

{===============================================================================
--------------------------------------------------------------------------------
                             Base exception classes
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    ECustomException - class implementation
===============================================================================}

constructor ECustomException.CreateFmt(const Msg: String; Args: array of const);
begin
inherited CreateFmt(Msg,Args);
fTime := Now;
fThreadID := GetCurrentThreadID;
end;

{===============================================================================
    EGeneralException - class implementation
===============================================================================}

constructor EGeneralException.CreateFmt(const Msg: String; Args: array of const; FaultObject: TObject; const FaultFunction: String);

  Function InstanceString(Obj: TObject): String;
  begin
    Result := Format('%s(%p)',[Obj.ClassName,Pointer(Obj)]);
  end;
  
begin
inherited CreateFmt(Msg,Args);
If Assigned(FaultObject) then
  fFaultingObject := InstanceString(FaultObject)
else
  fFaultingObject := '';
fFaultingFunction := FaultFunction;
If Length(fFaultingObject) > 0 then
  begin
    If Length(fFaultingFunction) > 0 then
      fFullMessage := Format(Format('%s.%s: %s',[fFaultingObject,fFaultingFunction,Msg]),Args)
    else
      fFullMessage := Format(Format('%s: %s',[fFaultingObject,Msg]),Args);
  end
else
  begin
    If Length(fFaultingFunction) > 0 then
      fFullMessage := Format(Format('%s: %s',[fFaultingFunction,Msg]),Args)
    else
      fFullMessage := Format(Msg,Args);
  end;
end;

//------------------------------------------------------------------------------

constructor EGeneralException.Create(const Msg: String; FaultObject: TObject; const FaultFunction: String);
begin
CreateFmt(Msg,[],FaultObject,FaultFunction);
end;


{===============================================================================
--------------------------------------------------------------------------------
                                 System errors                                  
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    ESystemError - class implementation
===============================================================================}

constructor ESystemError.Create(FullSysMsg: Boolean; FaultObject: TObject; const FaultFunction: String);
var
  ErrCode:  UInt32;
begin
ErrCode := GetLastError;
If FullSysMsg then
  inherited CreateFmt('System error 0x%.8x: %s',[ErrCode,SysErrorMessage(ErrCode)],FaultObject,FaultFunction)
else
  inherited CreateFmt('System error occured (0x%.8x).',[ErrCode],FaultObject,FaultFunction);
fErrorCode := ErrCode;
end;


{===============================================================================
--------------------------------------------------------------------------------
                                  Index errors
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    EIndexException - class implementation
===============================================================================}

{-------------------------------------------------------------------------------
    EIndexException - protected methods
-------------------------------------------------------------------------------}

class Function EIndexException.GetDefaultMessage: String;
begin
Result := 'Index (%d) error.';
end;

{-------------------------------------------------------------------------------
    EIndexException - public methods
-------------------------------------------------------------------------------}

constructor EIndexException.Create(const Msg: String; Index: Integer; FaultObject: TObject; const FaultFunction: String);
begin
inherited CreateFmt(Msg,[Index],FaultObject,FaultFunction);
fIndex := Index;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor EIndexException.Create(Index: Integer; FaultObject: TObject; const FaultFunction: String);
begin
Create(GetDefaultMessage,Index,FaultObject,FaultFunction);
end;

{===============================================================================
    EIndexOutOfBounds - class implementation
===============================================================================}

class Function EIndexOutOfBounds.GetDefaultMessage: String;
begin
Result := 'Index (%d) out of bounds.';
end;

{===============================================================================
    EIndexTooLow - class implementation
===============================================================================}

class Function EIndexTooLow.GetDefaultMessage: String;
begin
Result := 'Index (%d) too low.';
end;

{===============================================================================
    EIndexTooHigh - class implementation
===============================================================================}

class Function EIndexTooHigh.GetDefaultMessage: String;
begin
Result := 'Index (%d) too high.';
end;

{===============================================================================
    EIndexInvalid - class implementation
===============================================================================}

class Function EIndexInvalid.GetDefaultMessage: String;
begin
Result := 'Index (%d) is invalid.';
end;


{===============================================================================
--------------------------------------------------------------------------------
                                  Value errors
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    EValueException - class implementation
===============================================================================}

{-------------------------------------------------------------------------------
    EValueException - protected methods
-------------------------------------------------------------------------------}

class Function EValueException.VariantArrayToStr(Value: Variant): String;
var
  Dimensions: Integer;
  Indices:    array of Integer;

  procedure ConvertVarArrayDimension(var Str: String; Dim: Integer);
  var
    Index:  Integer;
  begin
    Str := Str + '[';
    For Index := VarArrayLowBound(Value,Dim) to VarArrayHighBound(Value,Dim) do
      begin
        Indices[Pred(Dim)] := Index;
        If Dim >= Dimensions then
          begin
            If Index <> VarArrayHighBound(Value,Dim) then
              Str := Str + VarToStrDef(VarArrayGet(Value,Indices),'ERROR') + ','
            else
              Str := Str + VarToStrDef(VarArrayGet(Value,Indices),'ERROR');
          end
        else ConvertVarArrayDimension(Str,Dim + 1);
      end;
    Str := Str + ']';
  end;

begin
Result := '';
Dimensions := VarArrayDimCount(Value);
If Dimensions > 0 then
  begin
    SetLength(Indices,Dimensions);
    ConvertVarArrayDimension(Result,1);
  end;
end;

//------------------------------------------------------------------------------

class Function EValueException.GetDefaultMessage(ValueString: Boolean): String;
begin
If ValueString then
  Result := 'Value %s error (%s).'
else
  Result := 'Value %s error.';
end;

{-------------------------------------------------------------------------------
    EValueException - public methods
-------------------------------------------------------------------------------}

constructor EValueException.Create(const Msg,ValueName: String; Value: Variant; FaultObject: TObject; const FaultFunction: String);
begin
If (VarType(Value) and varArray) <> 0 then
  inherited CreateFmt(Msg,[ValueName,VariantArrayToStr(Value)],FaultObject,FaultFunction)
else
  inherited CreateFmt(Msg,[ValueName,VarToStrDef(Value,'ERROR')],FaultObject,FaultFunction);
fValue := Value;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor EValueException.Create(const Msg,ValueName: String; FaultObject: TObject; const FaultFunction: String);
begin
inherited CreateFmt(Msg,[ValueName],FaultObject,FaultFunction);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor EValueException.Create(const ValueName: String; Value: Variant; FaultObject: TObject; const FaultFunction: String);
begin
Create(GetDefaultMessage(True),ValueName,Value,FaultObject,FaultFunction);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor EValueException.Create(const ValueName: String; FaultObject: TObject; const FaultFunction: String);
begin
Create(GetDefaultMessage(False),ValueName,FaultObject,FaultFunction);
end;

{===============================================================================
    EValueInvalid - class implementation
===============================================================================}

class Function EValueInvalid.GetDefaultMessage(ValueString: Boolean): String;
begin
If ValueString then
  Result := 'Invalid %s value (%s).'
else
  Result := 'Invalid %s value.';
end;

{===============================================================================
    EValueInvalidNameOnly - class implementation
===============================================================================}

class Function EValueInvalidNameOnly.GetDefaultMessage(ValueString: Boolean): String;
begin
If ValueString then
  Result := 'Invalid %s (%s).'
else
  Result := 'Invalid %s.';
end;


end.

{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Explicit string lists

  Part A - lists working with ansichar-based strings.

  �Franti�ek Milt 2018-10-21

  Version 1.0.4

  Dependencies:
    AuxTypes        - github.com/ncs-sniper/Lib.AuxTypes
    AuxClasses      - github.com/ncs-sniper/Lib.AuxClasses
    StrRect         - github.com/ncs-sniper/Lib.StrRect
    BinaryStreaming - github.com/ncs-sniper/Lib.BinaryStreaming
    ListSorters     - github.com/ncs-sniper/Lib.ListSorters

===============================================================================}
unit ExplicitStringListsA;

{$INCLUDE '.\ExplicitStringLists_defs.inc'}

interface

uses
  Classes, AuxTypes, ExplicitStringListsBase;

{===============================================================================
--------------------------------------------------------------------------------
                                  T*StringList
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    T*StringList - declaration
===============================================================================}

{$DEFINE ESL_Declaration}

type
{$DEFINE ESL_Short}
  {$I 'ESL_inc\ESL_CompFuncType.inc'} = Function(const Str1,Str2: {$I 'ESL_inc\ESL_StringType.inc'}): Integer;

  {$I 'ESL_inc\ESL_ListType.inc'} = class(TExplicitStringList)
  protected
    Function GetAnsiText: AnsiString;
    procedure SetAnsiText(const Value: AnsiString);
    Function GetAnsiDelimitedText: AnsiString;
    procedure SetAnsiDelimitedText(const Value: AnsiString);
    Function GetAnsiCommaText: AnsiString;
    procedure SetAnsiCommaText(const Value: AnsiString);
    {$I ExplicitStringLists.inc}
    property AnsiText: AnsiString read GetAnsiText write SetAnsiText;
    property AnsiDelimitedText: AnsiString read GetAnsiDelimitedText write SetAnsiDelimitedText;
    property AnsiCommaText: AnsiString read GetAnsiCommaText write SetAnsiCommaText;
  end;
{$UNDEF ESL_Short}

{$DEFINE ESL_Ansi}
  {$I 'ESL_inc\ESL_CompFuncType.inc'} = Function(const Str1,Str2: {$I 'ESL_inc\ESL_StringType.inc'}): Integer;

  {$I 'ESL_inc\ESL_ListType.inc'} = class(TExplicitStringList)
    {$I ExplicitStringLists.inc}
  end;
{$UNDEF ESL_Ansi}

{$UNDEF ESL_Declaration}

implementation

uses
{$IF not Defined(FPC) and (CompilerVersion >= 20)}(* Delphi2009+ *)
  {$IFDEF Windows} Windows,{$ENDIF} AnsiStrings,
{$IFEND}
  SysUtils, StrRect, ListSorters, ExplicitStringListsParser;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W4055:={$WARN 4055 OFF}} // Conversion between ordinals and pointers is not portable
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
{$ENDIF}

{===============================================================================
--------------------------------------------------------------------------------
                               TAnsiParsingHelper
--------------------------------------------------------------------------------
===============================================================================}

type
  TAnsiParsingHelper = class(TObject)
  private
    fOnAddItem: TShortDelimitedTextParserEvent;
  public
    procedure Thunk(const Str: AnsiString); virtual;
    property OnAddItem: TShortDelimitedTextParserEvent read fOnAddItem write fOnAddItem;
  end;

//==============================================================================

procedure TAnsiParsingHelper.Thunk(const Str: AnsiString);
begin
If Assigned(fOnAddItem) then
  fOnAddItem(ShortString(Str));
end;

{===============================================================================
--------------------------------------------------------------------------------
                                  T*StringList
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    T*StringList - implementation
===============================================================================}

{$DEFINE ESL_Implementation}

{$DEFINE ESL_Short}
  {$I ExplicitStringLists.inc}
{$UNDEF ESL_Short}

{===============================================================================
    TShortStringList - implementation
===============================================================================}

{-------------------------------------------------------------------------------
    TShortStringList - protected methods
-------------------------------------------------------------------------------}

Function TShortStringList.GetAnsiText: AnsiString;
var
  i:    Integer;
  Len:  TStrSize;
begin
Len := 0;
// count size for preallocation
For i := LowIndex to HighIndex do
  Inc(Len,Length(fStrings[i]));
Inc(Len,fCount * Length(fLineBreak));
If not TrailingLineBreak then
  Dec(Len,Length(fLineBreak));
// preallocate
SetLength(Result,Len);
// store data
Len := 1;
For i := LowIndex to HighIndex do
  begin
    If Length(fStrings[i]) > 0 then
      System.Move(fStrings[i][1],Addr(Result[Len])^,Length(fStrings[i]) * SizeOf(AnsiChar));
    Inc(Len,Length(fStrings[i]));
    If (i < HighIndex) or TrailingLineBreak and (Length(fLineBreak) > 0) then
      begin
        If Length(fLineBreak) > 0 then
          System.Move(fLineBreak[1],Addr(Result[Len])^,Length(fLineBreak) * SizeOf(AnsiChar));
        Inc(Len,Length(fLineBreak));
      end;
  end;
end;

//------------------------------------------------------------------------------

procedure TShortStringList.SetAnsiText(const Value: AnsiString);
var
  C,S,E:  PAnsiChar;
  Buff:   AnsiString;
begin
{$IFDEF FPCDWM}{$PUSH}W4055{$ENDIF}
BeginUpdate;
try
  Clear;
  C := PAnsiChar(Value);
  E := PAnsiChar(PtrUInt(C) + PtrUInt(Length(Value) * SizeOf(AnsiChar)));
  If C <> nil then
    while PtrUInt(C) < PtrUInt(E) do
      begin
        S := C;
        while (PtrUInt(C) < PtrUInt(E)) do
          If IsBreak(C^) then Break{while (PtrUInt(C) < PtrUInt(E))}
            else Inc(C);

        If (PtrUInt(C) - PtrUInt(S)) > 0 then
          begin
            SetLength(Buff,(PtrUInt(C) - PtrUInt(S)) div SizeOf(AnsiChar));
            If Length(Buff) > 0 then
              System.Move(S^,PAnsiChar(Buff)^,Length(Buff) * SizeOf(AnsiChar));
            Add(ShortString(Buff));
          end
        else Add('');

        If PtrUInt(C) < PtrUInt(E) then
          If IsBreak(C^) then
            begin
              If (PtrUInt(C) + 1) < PtrUInt(E) then
                // more than 1 char left in string
                If (Ord(C^) <> Ord(PAnsiChar(PtrUInt(C) + SizeOf(AnsiChar))^)) and
                  IsBreak(PAnsiChar(PtrUInt(C) + SizeOf(AnsiChar))^,False) and
                  (Ord(C^) <> 0) then Inc(C);
              Inc(C);
            end;
      end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}
finally
  EndUpdate;
end;
end;

//------------------------------------------------------------------------------

Function TShortStringList.GetAnsiDelimitedText: AnsiString;
var
  i:    Integer;
  Len:  TStrSize;
  Temp: ShortString;

  Function GetRectifiedStringLength(Index: Integer): TStrSize;
  var
    ii:     TStrSize;
    Quoted: Boolean;
  begin
    Quoted := False;
    Result := Length(fStrings[Index]);
    For ii := 1 to Length(fStrings[Index]) do
      If (fStrings[Index][ii] = fQuoteChar) or
        (fStrings[Index][ii] = fDelimiter) or
        (Ord(fStrings[Index][ii]) in [0..32]) then
        begin
          If not Quoted then
            Inc(Result,2);
          If fStrings[Index][ii] = fQuoteChar then
            Inc(Result);
          Quoted := True;
        end;
    If Result >= High(ShortString) then
      Result := High(ShortString);
  end;

  Function GetRectifiedString(Index: Integer): ShortString;
  var
    ii:     TStrSize;
    ResPos: TStrSize;    
    Quoted: Boolean;
  begin
    SetLength(Result,High(ShortString));
    ResPos := 1;
    Quoted := False;    
    For ii := 1 to Length(fStrings[Index]) do
      If ResPos <= Length(Result) then
        begin
          If fStrings[Index][ii] = fQuoteChar then
            begin
              If ResPos < Length(Result) then
                begin
                  Result[ResPos] := fStrings[Index][ii];
                  Inc(ResPos);
                  Result[ResPos] := fStrings[Index][ii];
                  Quoted := True;
                end
              else Dec(ResPos);
            end
          else If (fStrings[Index][ii] = fDelimiter) or
            (Ord(fStrings[Index][ii]) in [0..32]) then
            begin
              Result[ResPos] := fStrings[Index][ii];
              Quoted := True;
            end
          else Result[ResPos] := fStrings[Index][ii];
          Inc(ResPos);
        end
      else Break{For ii};
    SetLength(Result,ResPos - 1);
    If Quoted then
      begin
        Result := fQuoteChar + Result;
        If Length(Result) < High(ShortString) then
          Result := Result + fQuoteChar
        else
          Result[Length(Result)] := fQuoteChar;
      end;
  end;

begin
Len := 0;
// count size for preallocation
For i := LowIndex to HighIndex do
  Inc(Len,GetRectifiedStringLength(i) + 1{delimiter});
If fCount > 0 then
  Dec(Len){last delimiter};
// preallocate
SetLength(Result,Len);
// store data
Len := 1;
For i := LowIndex to HighIndex do
  begin
    Temp := GetRectifiedString(i);
    If Length(Temp) > 0 then
      System.Move(Temp[1],Addr(Result[Len])^,Length(Temp) * SizeOf(AnsiChar));
    Inc(Len,Length(Temp));
    If i < HighIndex then
      begin
        Result[Len] := fDelimiter;
        Inc(Len);
      end;
  end;
If Len <= Length(Result) then
  SetLength(Result,Len - 1);
end;

//------------------------------------------------------------------------------

procedure TShortStringList.SetAnsiDelimitedText(const Value: AnsiString);
var
  Helper: TAnsiParsingHelper;
begin
BeginUpdate;
try
  Clear;
  Helper := TAnsiParsingHelper.Create;
  try
    Helper.OnAddItem := Self.Append;
    with TAnsiDelimitedTextParser.Create(fDelimiter,fQuoteChar,fStrictDelimiter) do
    try
      OnNewString := Helper.Thunk;
      Parse(Value);
    finally
      Free;
    end;
  finally
    Helper.Free;
  end;
finally
  EndUpdate;
end;
end;

//------------------------------------------------------------------------------

Function TShortStringList.GetAnsiCommaText: AnsiString;
var
  OldDelimiter: AnsiChar;
  OldQuoteChar: AnsiChar;
begin
OldDelimiter := fDelimiter;
OldQuoteChar := fQuoteChar;
try
  fDelimiter := def_Delimiter;
  fQuoteChar := def_QuoteChar;
  Result := GetAnsiDelimitedText;
finally
  fDelimiter := OldDelimiter;
  fQuoteChar := OldquoteChar;
end;
end;

//------------------------------------------------------------------------------

procedure TShortStringList.SetAnsiCommaText(const Value: AnsiString);
var
  OldDelimiter: AnsiChar;
  OldQuoteChar: AnsiChar;
begin
OldDelimiter := fDelimiter;
OldQuoteChar := fQuoteChar;
try
  fDelimiter := def_Delimiter;
  fQuoteChar := def_QuoteChar;
  SetAnsiDelimitedText(Value);
finally
  fDelimiter := OldDelimiter;
  fQuoteChar := OldquoteChar;
end;
end;

//==============================================================================

{$DEFINE ESL_Ansi}
  {$I ExplicitStringLists.inc}
{$UNDEF ESL_Ansi}

{$UNDEF ESL_Implementation}

end.

{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Explicit string lists

  Part A - lists working with ansichar-based strings.

  ©František Milt 2017-09-10

  Version 1.0

  Dependencies:
    AuxTypes        - github.com/ncs-sniper/Lib.AuxTypes
    StrRect         - github.com/ncs-sniper/Lib.StrRect
    BinaryStreaming - github.com/ncs-sniper/Lib.BinaryStreaming

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
  published
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
  SysUtils, StrRect, ExplicitStringListsParser;

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
    System.Move(fStrings[i][1],Addr(Result[Len])^,Length(fStrings[i]) * SizeOf(AnsiChar));
    Inc(Len,Length(fStrings[i]));
    If (i < HighIndex) or TrailingLineBreak and (Length(fLineBreak) > 0) then
      begin
        System.Move(fLineBreak[1],Addr(Result[Len])^,Length(fLineBreak) * SizeOf(AnsiChar));
        Inc(Len,Length(fLineBreak));
      end;
  end;
end;

//------------------------------------------------------------------------------

procedure TShortStringList.SetAnsiText(const Value: AnsiString);
var
  C,S:  PAnsiChar;
  Buff: AnsiString;
begin
BeginUpdate;
try
  Clear;
  C := PAnsiChar(Value);
  If C <> nil then
    while Ord(C^) <> 0 do
      begin
        S := C;
        while not IsBreak(C^) do Inc(C);
        If ({%H-}PtrUInt(C) - {%H-}PtrUInt(S)) > 0 then
          begin
            SetLength(Buff,({%H-}PtrUInt(C) - {%H-}PtrUInt(S)) div SizeOf(AnsiChar));
            System.Move(S^,PAnsiChar(Buff)^,Length(Buff) * SizeOf(AnsiChar));        
            Add(ShortString(Buff));
          end
        else Add('');
        If Ord(C^) = 13 then Inc(C);
        If Ord(C^) = 10 then Inc(C);
      end;
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
    Helper.OnAddItem := {$IFDEF FPC}@{$ENDIF}Self.Append;
    with TAnsiDelimitedTextParser.Create(fDelimiter,fQuoteChar,fStrictDelimiter) do
    try
      OnNewString := {$IFDEF FPC}@{$ENDIF}Helper.Thunk;
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

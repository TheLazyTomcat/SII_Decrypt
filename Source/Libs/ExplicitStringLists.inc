{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}

{===============================================================================
    T*StringList - declaration
===============================================================================}

{$IFDEF ESL_Declaration}
  protected
    fStrings:   array of {$I 'ESL_inc\ESL_StringType.inc'};
    fDelimiter: {$I 'ESL_inc\ESL_CharType.inc'};
    fLineBreak: {$I 'ESL_inc\ESL_StringType.inc'};
    fQuoteChar: {$I 'ESL_inc\ESL_CharType.inc'};
    // getters, setters
    Function GetItem(Index: Integer): {$I 'ESL_inc\ESL_StringType.inc'};
    procedure SetItem(Index: Integer; const Value: {$I 'ESL_inc\ESL_StringType.inc'});
    Function GetString(Index: Integer): String;
    procedure SetString(Index: Integer; const Value: String);
    procedure SetLineBreakStyle(Value: TLineBreakStyle);
    Function GetCapacity: Integer;
    procedure SetCapacity(Value: Integer);
    procedure SetSorted(Value: Boolean);
    Function GetText: {$I 'ESL_inc\ESL_StringType.inc'};
    procedure SetText(const Value: {$I 'ESL_inc\ESL_StringType.inc'});
    Function GetDelimitedText: {$I 'ESL_inc\ESL_StringType.inc'};
    procedure SetDelimitedText(const Value: {$I 'ESL_inc\ESL_StringType.inc'});
    Function GetCommaText: {$I 'ESL_inc\ESL_StringType.inc'};
    procedure SetCommaText(const Value: {$I 'ESL_inc\ESL_StringType.inc'});
    // protected class methods 
    class Function IsBreak(C: {$I 'ESL_inc\ESL_CharType.inc'}): Boolean; virtual;
    class Function ConvertStringTo(const Str: String): {$I 'ESL_inc\ESL_StringType.inc'}; virtual;
    class Function ConvertStringFrom(const Str: {$I 'ESL_inc\ESL_StringType.inc'}): String; virtual;
    // normal protected methods
    procedure Grow(Delta: Integer = 1); virtual;
    Function CheckIndex(Index: Integer): Boolean; virtual;
    Function CompareStrings(const Str1, Str2: {$I 'ESL_inc\ESL_StringType.inc'}): Integer; virtual;
    Function CompareItems(Index1,Index2: Integer): Integer; override;
    Function IndexForSortedAddition(const Str: {$I 'ESL_inc\ESL_StringType.inc'}): Integer; virtual;
    Function GetWriteSize: UInt64; override;
    procedure WriteItemToStream(Stream: TStream; Index: Integer; {%H-}Endianness: TStringEndianness); override;
    procedure WriteLineBreakToStream(Stream: TStream; {%H-}Endianness: TStringEndianness); override;
    procedure WriteBOMToStream({%H-}Stream: TStream; {%H-}Endianness: TStringEndianness); override;
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create;
    destructor Destroy; override;
    Function LowIndex: Integer; override;
    Function HighIndex: Integer; override;
    Function First: {$I 'ESL_inc\ESL_StringType.inc'}; virtual;
    Function Last: {$I 'ESL_inc\ESL_StringType.inc'}; virtual;
    Function IndexOf(const Str: {$I 'ESL_inc\ESL_StringType.inc'}): Integer; virtual;
    Function Find(const Str: {$I 'ESL_inc\ESL_StringType.inc'}; out Index: Integer): Boolean; virtual;
    Function Add(const Str: {$I 'ESL_inc\ESL_StringType.inc'}): Integer; virtual;
    Function AddDef(const Str: String): Integer; virtual;
    procedure AddStrings(Strings: {$I 'ESL_inc\ESL_ListType.inc'}); overload; virtual;
    procedure AddStrings(Strings: array of {$I 'ESL_inc\ESL_StringType.inc'}); overload; virtual;
    procedure AddStrings(Strings: TStrings); overload; virtual;
    procedure AddStringsDef(Strings: TStrings); overload; virtual;
    procedure AddStringsDef(Strings: array of String); overload; virtual;
    procedure Append(const Str: {$I 'ESL_inc\ESL_StringType.inc'}); virtual;
    procedure Insert(Index: Integer; const Str: {$I 'ESL_inc\ESL_StringType.inc'}); virtual;
    procedure Move(SrcIdx, DstIdx: Integer); virtual;
    procedure Exchange(Idx1, Idx2: Integer); override;
    Function Extract(const Str: {$I 'ESL_inc\ESL_StringType.inc'}): {$I 'ESL_inc\ESL_StringType.inc'}; virtual;
    Function Remove(const Str: {$I 'ESL_inc\ESL_StringType.inc'}): Integer; virtual;
    procedure Delete(Index: Integer); virtual;
    procedure Clear; virtual;
    procedure CustomSort(CompareFunction: {$I 'ESL_inc\ESL_CompFuncType.inc'}; Reversed: Boolean = False); virtual;
    procedure Reverse; virtual;
    Function Equals(Strings: {$I 'ESL_inc\ESL_ListType.inc'}): Boolean; reintroduce; virtual;
    procedure SetStrings(Strings: {$I 'ESL_inc\ESL_ListType.inc'}); overload; virtual;
    procedure SetStrings(Strings: array of {$I 'ESL_inc\ESL_StringType.inc'}); overload; virtual;
    procedure SetStrings(Strings: TStrings); overload; virtual;
    procedure SetStringsDef(Strings: TStrings); overload; virtual;
    procedure SetStringsDef(Strings: array of String); overload; virtual;
    procedure Assign(Source: TPersistent); override;
    procedure LoadFromStream(Stream: TStream; out {%H-}Endianness: TStringEndianness); override;
    property Items[Index: Integer]: {$I 'ESL_inc\ESL_StringType.inc'} read GetItem write SetItem; default;
    property Strings[Index: Integer]: String read GetString write SetString;
  published
    property Capacity: Integer read GetCapacity write SetCapacity;
    property Delimiter: {$I 'ESL_inc\ESL_CharType.inc'} read fDelimiter write fDelimiter;
    property LineBreak: {$I 'ESL_inc\ESL_StringType.inc'} read fLineBreak write fLineBreak;
    property LineBreakStyle: TLineBreakStyle write SetLineBreakStyle;
    property QuoteChar: {$I 'ESL_inc\ESL_CharType.inc'} read fQuoteChar write fQuoteChar;
    property Sorted: Boolean read fSorted write SetSorted;
    property Text: {$I 'ESL_inc\ESL_StringType.inc'} read GetText write SetText;
    property DelimitedText: {$I 'ESL_inc\ESL_StringType.inc'} read GetDelimitedText write SetDelimitedText;
    property CommaText: {$I 'ESL_inc\ESL_StringType.inc'} read GetCommaText write SetCommaText;
{$ENDIF ESL_Declaration}

{===============================================================================
    T*StringList - implementation
===============================================================================}

{$IFDEF ESL_Implementation}

{-------------------------------------------------------------------------------
    T*StringList - protected methods
-------------------------------------------------------------------------------}

Function {$I 'ESL_inc\ESL_ListType.inc'}.GetItem(Index: Integer): {$I 'ESL_inc\ESL_StringType.inc'};
begin
Result := '';
If CheckIndex(Index) then
  Result := fStrings[Index]
else
  Error('GetItem: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.SetItem(Index: Integer; const Value: {$I 'ESL_inc\ESL_StringType.inc'});
begin
If CheckIndex(Index) then
  begin
    DoChanging;
    fStrings[Index] := Value;
    DoChange;
  end
else Error('SetItem: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.GetString(Index: Integer): String;
begin
Result := '';
If CheckIndex(Index) then
  Result := ConvertStringFrom(fStrings[Index])
else
  Error('GetString: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.SetString(Index: Integer; const Value: String);
begin
If CheckIndex(Index) then
  begin
    DoChanging;
    fStrings[Index] := ConvertStringTo(Value);
    DoChange;
  end
else Error('SetString: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.SetLineBreakStyle(Value: TLineBreakStyle);
begin
case Value of
  lbsWIN,lbsCRLF: fLineBreak := {$I 'ESL_inc\ESL_StringType.inc'}(#13#10);
  lbsUNIX,lbsLF:  fLineBreak := {$I 'ESL_inc\ESL_StringType.inc'}(#10);
  lbsMAC,lbsCR:   fLineBreak := {$I 'ESL_inc\ESL_StringType.inc'}(#13);
else
  Error('SetLineBreakStyle: Invalid style (%d).',[Ord(Value)])
end;
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.GetCapacity: Integer;
begin
Result := Length(fStrings);
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.SetCapacity(Value: Integer);
begin
If Value < Length(fStrings) then
  begin
    DoChanging;
    SetLength(fStrings,Value);
    fCount := Length(fStrings);
    DoChange;
  end
else SetLength(fStrings,Value);
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.SetSorted(Value: Boolean);
begin
If fSorted <> Value then
  begin
    If Value then Sort(False);
    fSorted := Value;
  end;
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.GetText: {$I 'ESL_inc\ESL_StringType.inc'};
var
  i:    Integer;
  Len:  TStrSize;
begin
Len := 0;
// count size for preallocation
For i := LowIndex to HighIndex do
  Inc(Len,Length(fStrings[i]));
Inc(Len,fCount * Length(fLineBreak));
If not TrailingLineBreak and (fCount > 0) then
  Dec(Len,Length(fLineBreak));
// preallocate
{$IF Defined(ESL_Short) or Defined(ESL_ShortDefault)}
If Len > High(ShortString) then
  SetLength(Result,High(ShortString))
else
{$IFEND}
  SetLength(Result,Len);
// store data
Len := 1;
For i := LowIndex to HighIndex do
  begin
  {$IF Defined(ESL_Short) or Defined(ESL_ShortDefault)}
    If (Len + Length(fStrings[i]) - 1) > Length(Result) then
      begin
        System.Move(fStrings[i][1],Addr(Result[Len])^,(Length(Result) - Len + 1) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
        Break{For i};
      end
    else System.Move(fStrings[i][1],Addr(Result[Len])^,Length(fStrings[i]) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
  {$ELSE}
    System.Move({$I 'ESL_inc\ESL_PCharType.inc'}(fStrings[i])^,Addr(Result[Len])^,Length(fStrings[i]) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
  {$IFEND}
    Inc(Len,Length(fStrings[i]));
    If (i < HighIndex) or TrailingLineBreak and (Length(fLineBreak) > 0) then
      begin
      {$IF Defined(ESL_Short) or Defined(ESL_ShortDefault)}
        If (Len + Length(fLineBreak) - 1) > Length(Result) then
          begin
            System.Move(fLineBreak[1],Addr(Result[Len])^,(Length(Result) - Len + 1) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
            Break{For i};
          end
        else System.Move(fLineBreak[1],Addr(Result[Len])^,Length(fLineBreak) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
      {$ELSE}
        System.Move({$I 'ESL_inc\ESL_PCharType.inc'}(fLineBreak)^,Addr(Result[Len])^,Length(fLineBreak) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
      {$IFEND}
        Inc(Len,Length(fLineBreak));
      end;
  end;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.SetText(const Value: {$I 'ESL_inc\ESL_StringType.inc'});
var
  C,S,E:  {$I 'ESL_inc\ESL_PCharType.inc'};
  Buff:   {$I 'ESL_inc\ESL_StringType.inc'};
begin
BeginUpdate;
try
  Clear;
{$IF Defined(ESL_Short) or Defined(ESL_ShortDefault)}
  C := Addr(Value[1]);
{$ELSE}
  C := {$I 'ESL_inc\ESL_PCharType.inc'}(Value);
{$IFEND}
  E := {%H-}{$I 'ESL_inc\ESL_PCharType.inc'}({%H-}PtrUInt(C) + PtrUInt(Length(Value) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'})));
  If C <> nil then
    while {%H-}PtrUInt(C) < {%H-}PtrUInt(E) do
      begin
        S := C;
        while ({%H-}PtrUInt(C) < {%H-}PtrUInt(E)) do
          If IsBreak(C^) then Break{while (PtrUInt(C) < PtrUInt(E))}
            else Inc(C);
        If ({%H-}PtrUInt(C) - {%H-}PtrUInt(S)) > 0 then
          begin
          {
             for shortstrings, input itself cannot be longer than 255, so no
             need to check for limit when setting length of buffer
          }
            SetLength(Buff,({%H-}PtrUInt(C) - {%H-}PtrUInt(S)) div SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
          {$IF Defined(ESL_Short) or Defined(ESL_ShortDefault)}
            System.Move(S^,Buff[1],Length(Buff) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
          {$ELSE}
            System.Move(S^,{$I 'ESL_inc\ESL_PCharType.inc'}(Buff)^,Length(Buff) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
          {$IFEND}
            Add(Buff);
          end
        else Add('');
        If {%H-}PtrUInt(C) < {%H-}PtrUInt(E) then
          If Ord(C^) = 13 then Inc(C);
        If {%H-}PtrUInt(C) < {%H-}PtrUInt(E) then
          If Ord(C^) = 10 then Inc(C);
      end;
finally
  EndUpdate;
end;
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.GetDelimitedText: {$I 'ESL_inc\ESL_StringType.inc'};
var
  i:    Integer;
  Len:  TStrSize;
  Temp: {$I 'ESL_inc\ESL_StringType.inc'};

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
  end;

  Function GetRectifiedString(Index: Integer): {$I 'ESL_inc\ESL_StringType.inc'};
  var
    ii:     TStrSize;
    ResPos: TStrSize;    
    Quoted: Boolean;
  begin
    SetLength(Result,GetRectifiedStringLength(Index));
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
      Result := {$I 'ESL_inc\ESL_StringType.inc'}(fQuoteChar) + Result + {$I 'ESL_inc\ESL_StringType.inc'}(fQuoteChar);
  end;

begin
Len := 0;
// count size for preallocation
For i := LowIndex to HighIndex do
  Inc(Len,GetRectifiedStringLength(i) + 1{delimiter});
If fCount > 0 then
  Dec(Len){last delimiter};
// preallocate
{$IF Defined(ESL_Short) or Defined(ESL_ShortDefault)}
If Len > High(ShortString) then
  SetLength(Result,High(ShortString))
else
{$IFEND}
  SetLength(Result,Len);
// store data
Len := 1;
For i := LowIndex to HighIndex do
  begin
    Temp := GetRectifiedString(i);
  {$IF Defined(ESL_Short) or Defined(ESL_ShortDefault)}
    If (Len + Length(Temp) - 1) > Length(Result) then
      begin
        System.Move(Temp[1],Addr(Result[Len])^,(Length(Result) - Len + 1) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
        Break{For i};
      end
    else System.Move(Temp[1],Addr(Result[Len])^,Length(Temp) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
  {$ELSE}
    System.Move({$I 'ESL_inc\ESL_PCharType.inc'}(Temp)^,Addr(Result[Len])^,Length(Temp) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
  {$IFEND}
    Inc(Len,Length(Temp));
    If i < HighIndex then
      begin
        If Len <= Length(Result) then
          Result[Len] := fDelimiter
        else
          Break{For i};
        Inc(Len);
      end;
  end;
If Len <= Length(Result) then
  SetLength(Result,Len - 1);
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.SetDelimitedText(const Value: {$I 'ESL_inc\ESL_StringType.inc'});
begin
BeginUpdate;
try
  Clear;
  with {$I 'ESL_inc\ESL_DTParserType.inc'}.Create(fDelimiter,fQuoteChar,fStrictDelimiter) do
  try
    OnNewString := {$IFDEF FPC}@{$ENDIF}Self.Append;
    Parse(Value);
  finally
    Free;
  end;
finally
  EndUpdate;
end;
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.GetCommaText: {$I 'ESL_inc\ESL_StringType.inc'};
var
  OldDelimiter: {$I 'ESL_inc\ESL_CharType.inc'};
  OldQuoteChar: {$I 'ESL_inc\ESL_CharType.inc'};
begin
OldDelimiter := fDelimiter;
OldQuoteChar := fQuoteChar;
try
  fDelimiter := def_Delimiter;
  fQuoteChar := def_QuoteChar;
  Result := GetDelimitedText;
finally
  fDelimiter := OldDelimiter;
  fQuoteChar := OldquoteChar;
end;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.SetCommaText(const Value: {$I 'ESL_inc\ESL_StringType.inc'});
var
  OldDelimiter: {$I 'ESL_inc\ESL_CharType.inc'};
  OldQuoteChar: {$I 'ESL_inc\ESL_CharType.inc'};
begin
OldDelimiter := fDelimiter;
OldQuoteChar := fQuoteChar;
try
  fDelimiter := def_Delimiter;
  fQuoteChar := def_QuoteChar;
  SetDelimitedText(Value);
finally
  fDelimiter := OldDelimiter;
  fQuoteChar := OldquoteChar;
end;
end;

//==============================================================================

class Function {$I 'ESL_inc\ESL_ListType.inc'}.IsBreak(C: {$I 'ESL_inc\ESL_CharType.inc'}): Boolean;
begin
Result := Ord(C) in [0,10,13];
end;

//------------------------------------------------------------------------------

class Function {$I 'ESL_inc\ESL_ListType.inc'}.ConvertStringTo(const Str: String): {$I 'ESL_inc\ESL_StringType.inc'};
begin
{$IF Defined(ESL_Short)}
  Result := StrToShort(Str);
{$ELSEIF Defined(ESL_Ansi)}
  Result := StrToAnsi(Str);
{$ELSEIF Defined(ESL_UTF8)}
  Result := StrToUTF8(Str);
{$ELSEIF Defined(ESL_Wide)}
  Result := StrToWide(Str);
{$ELSEIF Defined(ESL_Unicode)}
  Result := StrToUnicode(Str);
{$ELSEIF Defined(ESL_Default)}
  Result := Str;
{$IFEND}
end;

//------------------------------------------------------------------------------

class Function {$I 'ESL_inc\ESL_ListType.inc'}.ConvertStringFrom(const Str: {$I 'ESL_inc\ESL_StringType.inc'}): String;
begin
{$IF Defined(ESL_Short)}
  Result := ShortToStr(Str);
{$ELSEIF Defined(ESL_Ansi)}
  Result := AnsiToStr(Str);
{$ELSEIF Defined(ESL_UTF8)}
  Result := UTF8ToStr(Str);
{$ELSEIF Defined(ESL_Wide)}
  Result := WideToStr(Str);
{$ELSEIF Defined(ESL_Unicode)}
  Result := UnicodeToStr(Str);
{$ELSEIF Defined(ESL_Default)}
  Result := Str;
{$IFEND}
end;

//==============================================================================

procedure {$I 'ESL_inc\ESL_ListType.inc'}.Grow(Delta: Integer = 1);
var
  NewLength:  Integer;
begin
If (Delta > 0) and ((fCount + Delta) > Length(fStrings)) then
  begin
    NewLength := Length(fStrings);
    while (fCount + Delta) > NewLength do
      begin
        If NewLength < 16 then
          NewLength := 16
        else
          NewLength := NewLength * 2;
      end;
    SetLength(fStrings,NewLength);
  end;
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.CheckIndex(Index: Integer): Boolean;
begin
Result := (Index >= Low(fStrings)) and (Index < fCount); 
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.CompareStrings(const Str1, Str2: {$I 'ESL_inc\ESL_StringType.inc'}): Integer;
begin
If fCaseSensitive then
{$IFDEF FPC}
  {$IF Defined(ESL_Short)}
      Result := SysUtils.CompareStr(ConvertStringFrom(Str1),ConvertStringFrom(Str2))
  {$ELSEIF Defined(ESL_Ansi)}
      Result := SysUtils.AnsiCompareStr(Str1,Str2)
  {$ELSEIF Defined(ESL_UTF8)}
      Result := SysUtils.UnicodeCompareStr(UTF8ToString(Str1),UTF8ToString(Str2))
  {$ELSEIF Defined(ESL_Wide)}
      Result := SysUtils.WideCompareStr(Str1,Str2)
  {$ELSEIF Defined(ESL_Unicode)}
      Result := SysUtils.UnicodeCompareStr(Str1,Str2)
  {$ELSEIF Defined(ESL_Default)}
      Result := SysUtils.AnsiCompareStr(Str1,Str2)
  {$IFEND}
{$ELSE}
  {$IF Defined(ESL_Short)}
      Result := SysUtils.CompareStr(ConvertStringFrom(Str1),ConvertStringFrom(Str2))
  {$ELSEIF Defined(ESL_Ansi)}
    {$IF Declared(AnsiStrings)}
      Result := AnsiStrings.AnsiCompareStr(Str1,Str2)
    {$ELSE}
      Result := SysUtils.AnsiCompareStr(Str1,Str2)
    {$IFEND}
  {$ELSEIF Defined(ESL_UTF8)}
    {$IFDEF Unicode}
      Result := SysUtils.AnsiCompareStr(UTF8ToString(Str1),UTF8ToString(Str2))
    {$ELSE}
      Result := SysUtils.WideCompareStr(UTF8ToString(Str1),UTF8ToString(Str2))
    {$ENDIF}
  {$ELSEIF Defined(ESL_Wide)}
      Result := SysUtils.WideCompareStr(Str1,Str2)
  {$ELSEIF Defined(ESL_Unicode)}
    {$IF Declared(AnsiStrings)}
      Result := SysUtils.AnsiCompareStr(Str1,Str2)
    {$ELSE}
      Result := SysUtils.WideCompareStr(Str1,Str2)
    {$IFEND}
  {$ELSEIF Defined(ESL_Default)}
      Result := SysUtils.AnsiCompareStr(Str1,Str2)
  {$IFEND}
{$ENDIF}
else
{$IFDEF FPC}
  {$IF Defined(ESL_Short)}
      Result := SysUtils.CompareText(ConvertStringFrom(Str1),ConvertStringFrom(Str2))
  {$ELSEIF Defined(ESL_Ansi)}
      Result := SysUtils.AnsiCompareText(Str1,Str2)
  {$ELSEIF Defined(ESL_UTF8)}
      Result := SysUtils.UnicodeCompareText(UTF8ToString(Str1),UTF8ToString(Str2))
  {$ELSEIF Defined(ESL_Wide)}
      Result := SysUtils.WideCompareText(Str1,Str2)
  {$ELSEIF Defined(ESL_Unicode)}
      Result := SysUtils.UnicodeCompareText(Str1,Str2)
  {$ELSEIF Defined(ESL_Default)}
      Result := SysUtils.AnsiCompareText(Str1,Str2)
  {$IFEND}
{$ELSE}
  {$IF Defined(ESL_Short)}
      Result := SysUtils.CompareText(ConvertStringFrom(Str1),ConvertStringFrom(Str2))
  {$ELSEIF Defined(ESL_Ansi)}
    {$IF Declared(AnsiStrings)}
      Result := AnsiStrings.AnsiCompareText(Str1,Str2)
    {$ELSE}
      Result := SysUtils.AnsiCompareText(Str1,Str2)
    {$IFEND}
  {$ELSEIF Defined(ESL_UTF8)}
    {$IFDEF Unicode}
      Result := SysUtils.AnsiCompareText(UTF8ToString(Str1),UTF8ToString(Str2))
    {$ELSE}
      Result := SysUtils.WideCompareText(UTF8ToString(Str1),UTF8ToString(Str2))
    {$ENDIF}
  {$ELSEIF Defined(ESL_Wide)}
      Result := SysUtils.WideCompareText(Str1,Str2)
  {$ELSEIF Defined(ESL_Unicode)}
    {$IF Declared(AnsiStrings)}
      Result := SysUtils.AnsiCompareText(Str1,Str2)
    {$ELSE}
      Result := SysUtils.WideCompareText(Str1,Str2)
    {$IFEND}
  {$ELSEIF Defined(ESL_Default)}
      Result := SysUtils.AnsiCompareText(Str1,Str2)
  {$IFEND}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.CompareItems(Index1,Index2: Integer): Integer;
begin
If not CheckIndex(Index1) then
  Error('CompareItems: Index (%d) out of bounds.',[Index1]);
If not CheckIndex(Index2) then
  Error('CompareItems: Index (%d) out of bounds.',[Index2]);
Result := CompareStrings(fStrings[Index1],fStrings[Index2]);
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.IndexForSortedAddition(const Str: {$I 'ESL_inc\ESL_StringType.inc'}): Integer;
var
  M,L,R,D:  Integer;
begin
If fSorted then
  begin
    If fCount > 0 then
      begin
        L := LowIndex;
        R := HighIndex;
        M := L;
        while L <= R do
          begin
            M := (L + R) shr 1;
            D := CompareStrings(Str,fStrings[M]);
            If D < 0 then
              begin
                R := M - 1;
                Dec(M);
              end
            else If D > 0 then
              L := M + 1
            else
              Break;
          end;
        Result := Succ(M);
      end
    else Result := 0;
  end
else Result := -1;
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.GetWriteSize: UInt64;
var
  i:  Integer;
begin
Result := 0;
For i := LowIndex to HighIndex do
  begin
    Inc(Result,Length(fStrings[i]));
    If (i < HighIndex) or fTrailingLineBreak then
      Inc(Result,Length(fLineBreak)); 
  end;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.WriteItemToStream(Stream: TStream; Index: Integer; Endianness: TStringEndianness);
{$IF Defined(ESL_Wide) or Defined(ESL_Unicode) or (Defined(ESL_Default) and Defined(Unicode))}
var
  Temp: UnicodeString;
{$IFEND}
begin
If CheckIndex(Index) then
  begin
    If Length(fStrings[Index]) > 0 then
      begin
      {$IF Defined(ESL_Short) or Defined(ESL_ShortDefault)}
        Stream.WriteBuffer(fStrings[Index][1],Length(fStrings[Index]) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
      {$ELSEIF Defined(ESL_Wide) or Defined(ESL_Unicode) or (Defined(ESL_Default) and Defined(Unicode))}
        If (Endianness <> seSystem) and (Endianness <> GetSystemEndianness) then
          begin
            Temp := fStrings[Index];
            WideSwapEndian(PWideChar(Temp),Length(Temp));
            Stream.WriteBuffer({$I 'ESL_inc\ESL_PCharType.inc'}(Temp)^,Length(Temp) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
          end
        else Stream.WriteBuffer({$I 'ESL_inc\ESL_PCharType.inc'}(fStrings[Index])^,Length(fStrings[Index]) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
      {$ELSE}
        Stream.WriteBuffer({$I 'ESL_inc\ESL_PCharType.inc'}(fStrings[Index])^,Length(fStrings[Index]) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
      {$IFEND}
      end;
  end
else Error('WriteItem: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.WriteLineBreakToStream(Stream: TStream; Endianness: TStringEndianness);
{$IF Defined(ESL_Wide) or Defined(ESL_Unicode) or (Defined(ESL_Default) and Defined(Unicode))}
var
  Temp: UnicodeString;
{$IFEND}
begin
If Length(fLineBreak) > 0 then
  begin
  {$IF Defined(ESL_Short) or Defined(ESL_ShortDefault)}
    Stream.WriteBuffer(fLineBreak[1],Length(fLineBreak) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
  {$ELSEIF Defined(ESL_Wide) or Defined(ESL_Unicode) or (Defined(ESL_Default) and Defined(Unicode))}
    If (Endianness <> seSystem) and (Endianness <> GetSystemEndianness) then
      begin
        Temp := fLineBreak;
        WideSwapEndian(PWideChar(Temp),Length(Temp));
        Stream.WriteBuffer({$I 'ESL_inc\ESL_PCharType.inc'}(Temp)^,Length(Temp) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
      end
    else Stream.WriteBuffer({$I 'ESL_inc\ESL_PCharType.inc'}(fLineBreak)^,Length(fLineBreak) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
  {$ELSE}
    Stream.WriteBuffer({$I 'ESL_inc\ESL_PCharType.inc'}(fLineBreak)^,Length(fLineBreak) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
  {$IFEND}
  end;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.WriteBOMToStream(Stream: TStream; Endianness: TStringEndianness);
begin
{$IF Defined(ESL_UTF8)}
  Stream_WriteUInt8(Stream,$EF);
  Stream_WriteUInt8(Stream,$BB);
  Stream_WriteUInt8(Stream,$BF);
{$ELSEIF Defined(ESL_Wide) or Defined(ESL_Unicode) or (Defined(ESL_Default) and Defined(Unicode))}
  If Endianness = seSystem then
    Endianness := GetSystemEndianness;
  case Endianness of
    seLittle: begin
                Stream_WriteUInt8(Stream,$FF);
                Stream_WriteUInt8(Stream,$FE);
              end;
    seBig:    begin
                Stream_WriteUInt8(Stream,$FE);
                Stream_WriteUInt8(Stream,$FF);
              end;
  else
    Error('WriteBOMToStream: Unknonw endianness (%d).',[Ord(Endianness)]);
  end;
{$IFEND}
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.AssignTo(Dest: TPersistent);
var
  i:  Integer;
begin
If Dest is TStrings then
  begin
    If Dest is TStringList then
      begin
        TStringList(Dest).Sorted := False;
        fCaseSensitive := TStringList(Dest).CaseSensitive;
        fDuplicates := TStringList(Dest).Duplicates;
      end;
    TStrings(Dest).Delimiter := Char(fDelimiter);
    TStrings(Dest).QuoteChar := Char(fQuoteChar);
    TStrings(Dest).Clear;
    For i := LowIndex to HighIndex do
      TStrings(Dest).Add(Strings[i]);
  {$IF Defined(FPC) or (CompilerVersion >= 31)}
    TStrings(Dest).StrictDelimiter := fStrictDelimiter;
    TStrings(Dest).LineBreak := ConvertStringFrom(fLineBreak);
  {$IFNDEF FPC}
    TStrings(Dest).TrailingLineBreak := fTrailingLineBreak;
  {$ENDIF}
  {$IFEND}
  end
else inherited;
end;


{-------------------------------------------------------------------------------
    T*StringList - public methods
-------------------------------------------------------------------------------}

constructor {$I 'ESL_inc\ESL_ListType.inc'}.Create;
begin
inherited;
SetLength(fStrings,0);
fDelimiter := def_Delimiter;
fLineBreak := {$I 'ESL_inc\ESL_StringType.inc'}(def_LineBreak);
fQuoteChar := def_QuoteChar;
end;

//------------------------------------------------------------------------------

destructor {$I 'ESL_inc\ESL_ListType.inc'}.Destroy;
begin
SetLength(fStrings,0);
inherited;
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.LowIndex: Integer;
begin
Result := Low(fStrings);
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.HighIndex: Integer;
begin
Result := Pred(fCount);
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.First: {$I 'ESL_inc\ESL_StringType.inc'};
begin
Result := GetItem(LowIndex);
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.Last: {$I 'ESL_inc\ESL_StringType.inc'};
begin
Result := GetItem(HighIndex);
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.IndexOf(const Str: {$I 'ESL_inc\ESL_StringType.inc'}): Integer;
var
  i,L,R,D:  Integer;
begin
Result := -1;
If fSorted and (fCount > 5) then
  begin
    L := LowIndex;
    R := HighIndex;
    while L <= R do
      begin
        i := (L + R) shr 1;
        D := CompareStrings(Str,fStrings[i]);
        If D > 0 then
          L := i + 1
        else If D < 0 then
          R := i - 1
        else
          begin
            Result := i;
            Break{L <= R};
          end;
      end;
  end
else
  begin
    For i := LowIndex to HighIndex do
      If CompareStrings(Str,fStrings[i]) = 0 then
        begin
          Result := i;
          Break{For i};
        end;
  end;
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.Find(const Str: {$I 'ESL_inc\ESL_StringType.inc'}; out Index: Integer): Boolean;
begin
Index := IndexOf(Str);
Result := Index >= LowIndex;
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.Add(const Str: {$I 'ESL_inc\ESL_StringType.inc'}): Integer;
var
  i:  Integer;
begin
If fDuplicates <> dupAccept then
  If Find(Str,Result) then
    case fDuplicates of
      dupIgnore:  begin
                    Result := -1;
                    Exit;
                  end;
      dupError:   Error('Add: Duplicit string (%d).',[Result]);
    end;
Grow;
DoChanging;
If fSorted then
  begin
    Result := IndexForSortedAddition(Str);
    For i := HighIndex downto Result do
      fStrings[i + 1] := fStrings[i];
  end
else Result := fCount;
fStrings[Result] := Str;
Inc(fCount);
DoChange;
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.AddDef(const Str: String): Integer;
begin
Result := Add(ConvertStringTo(Str));
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.AddStrings(Strings: {$I 'ESL_inc\ESL_ListType.inc'});
var
  i:  Integer;
begin
BeginUpdate;
try
  Grow(Strings.Count);
  For i := Strings.LowIndex to Strings.HighIndex do
    Add(Strings[i]);
finally
  EndUpdate;
end;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.AddStrings(Strings: array of {$I 'ESL_inc\ESL_StringType.inc'});
var
  i:  Integer;
begin
BeginUpdate;
try
  Grow(Length(Strings));
  For i := Low(Strings) to High(Strings) do
    Add(Strings[i]);
finally
  EndUpdate;
end;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.AddStrings(Strings: TStrings);
begin
AddStringsDef(Strings);
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.AddStringsDef(Strings: TStrings);
var
  i:  Integer;
begin
BeginUpdate;
try
  Grow(Strings.Count);
  For i := 0 to Pred(Strings.Count) do
    AddDef(Strings[i]);
finally
  EndUpdate;
end;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.AddStringsDef(Strings: array of String);
var
  i:  Integer;
begin
BeginUpdate;
try
  Grow(Length(Strings));
  For i := Low(Strings) to High(Strings) do
    AddDef(Strings[i]);
finally
  EndUpdate;
end;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.Append(const Str: {$I 'ESL_inc\ESL_StringType.inc'});
begin
Add(Str);
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.Insert(Index: Integer; const Str: {$I 'ESL_inc\ESL_StringType.inc'});
var
  i:  Integer;
begin
If CheckIndex(Index) then
  begin
    If fDuplicates <> dupAccept then
      If Find(Str,i) then
        case fDuplicates of
          dupIgnore:  Exit;
          dupError:   Error('Insert: Duplicit string (%d).',[i]);
        end;
    Grow;
    DoChanging;
    For i := HighIndex downto Index do
      fStrings[i + 1] := fStrings[i];
    fStrings[Index] := Str;
    Inc(fCount);
    fSorted := False;
    DoChange;
  end
else If Index = fCount then
  Add(Str)
else
  Error('Insert: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.Move(SrcIdx, DstIdx: Integer);
var
  i:    Integer;
  Temp: {$I 'ESL_inc\ESL_StringType.inc'};
begin
If SrcIdx <> DstIdx then
  begin
    If not CheckIndex(SrcIdx) then
      Error('Exchange: Source index (%d) out of bounds.',[SrcIdx]);
    If not CheckIndex(DstIdx) then
      Error('Exchange: Destination index (%d) out of bounds.',[DstIdx]);
    Grow;
    DoChanging;
    Temp := fStrings[SrcIdx];
    If SrcIdx > DstIdx then
      For i := SrcIdx downto Succ(DstIdx) do
        fStrings[i] := fStrings[i - 1]
    else
      For i := SrcIdx to Pred(DstIdx) do
        fStrings[i] := fStrings[i + 1];
    fStrings[DstIdx] := Temp;
    fSorted := False;
    DoChange;
  end;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.Exchange(Idx1, Idx2: Integer);
var
  Temp: {$I 'ESL_inc\ESL_StringType.inc'};
begin
If Idx1 <> Idx2 then
  begin
    If not CheckIndex(Idx1) then
      Error('Exchange: Index (%d) out of bounds.',[Idx1]);
    If not CheckIndex(Idx2) then
      Error('Exchange: Index (%d) out of bounds.',[Idx2]);
    DoChanging;
    Temp := fStrings[Idx1];
    fStrings[Idx1] := fStrings[Idx2];
    fStrings[Idx2] := Temp;
    fSorted := False;
    DoChange;
  end;
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.Extract(const Str: {$I 'ESL_inc\ESL_StringType.inc'}): {$I 'ESL_inc\ESL_StringType.inc'};
var
  Index:  Integer;
begin
If Find(Str,Index) then
  begin
    Result := fStrings[Index];
    Delete(Index);
  end
else Result := '';
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.Remove(const Str: {$I 'ESL_inc\ESL_StringType.inc'}): Integer;
begin
Result := IndexOf(Str);
If Result >= 0 then
  Delete(Result);
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.Delete(Index: Integer);
var
  i:  Integer;
begin
If CheckIndex(Index) then
  begin
    DoChanging;
    For i := Succ(Index) to Pred(fCount) do
      fStrings[i - 1] := fStrings[i];
    fStrings[fCount] := '';
    Dec(fCount);
    DoChange;
  end
else Error('Delete: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.Clear;
var
  i:  Integer;
begin
DoChanging;
For i := LowIndex to HighIndex do
  fStrings[i] := '';
fCount := 0;
DoChange;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.CustomSort(CompareFunction: {$I 'ESL_inc\ESL_CompFuncType.inc'}; Reversed: Boolean = False);

  procedure QuickSort(LeftIdx,RightIdx,Coef: Integer);
  var
    Idx,i:  Integer;
  begin
    If LeftIdx < RightIdx then
      begin
        Exchange((LeftIdx + RightIdx) shr 1,RightIdx);
        Idx := LeftIdx;
        For i := LeftIdx to Pred(RightIdx) do
          If (CompareFunction(fStrings[RightIdx],fStrings[i]) * Coef) > 0 then
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
      Sorted := False;
    finally
      EndUpdate;
    end;
  end;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.Reverse;
var
  i:  Integer;
begin
If fCount > 1 then
  begin
    BeginUpdate;
    try
      For i := LowIndex to Pred(fCount shr 1) do
        Exchange(i,HighIndex - i);
      fSorted := False;
    finally
      EndUpdate;
    end;
  end;
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_ListType.inc'}.Equals(Strings: {$I 'ESL_inc\ESL_ListType.inc'}): Boolean;
var
  i:  Integer;
begin
If fCount = Strings.Count then
  begin
    Result := True;
    For i := Strings.LowIndex to Strings.HighIndex do
      If CompareStrings(fStrings[i],Strings[i]) <> 0 then
        begin
          Result := False;
          Break{For i};
        end;
  end
else Result := False;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.SetStrings(Strings: {$I 'ESL_inc\ESL_ListType.inc'});
var
  i:  Integer;
begin
DoChanging;
SetCapacity(Strings.Count);
For i := LowIndex to HighIndex do
  fStrings[i] := Strings[i];
fCount := Strings.Count;
fSorted := False;
DoChange;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.SetStrings(Strings: array of {$I 'ESL_inc\ESL_StringType.inc'});
var
  i:  Integer;
begin
DoChanging;
SetCapacity(Length(Strings));
For i := Low(Strings) to high(Strings) do
  fStrings[i] := Strings[i];
fCount := Length(Strings);
fSorted := False;
DoChange;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.SetStrings(Strings: TStrings);
begin
SetStringsDef(Strings);
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.SetStringsDef(Strings: TStrings);
var
  i:  Integer;
begin
DoChanging;
SetCapacity(Strings.Count);
For i := LowIndex to HighIndex do
  fStrings[i] := ConvertStringTo(Strings[i]);
fCount := Strings.Count;
fSorted := False;
DoChange;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.SetStringsDef(Strings: array of String);
var
  i:  Integer;
begin
DoChanging;
SetCapacity(Length(Strings));
For i := LowIndex to HighIndex do
  fStrings[i] := ConvertStringTo(Strings[i]);
fCount := Length(Strings);
fSorted := False;
DoChange;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.Assign(Source: TPersistent);
begin
BeginUpdate;
try
  If Source is TStrings then
    begin
      SetStrings(TStrings(Source));
    {
      When were following added to TStrings in Delphi? I know they are all in
      10.1 (Berlin), but other than that...
    }
    {$IF Defined(FPC) or (CompilerVersion >= 31)}
      fStrictDelimiter := TStrings(Source).StrictDelimiter;
      fLineBreak := ConvertStringTo(TStrings(Source).LineBreak);
    {$IFNDEF FPC}
      fTrailingLineBreak := TStrings(Source).TrailingLineBreak;
    {$ENDIF}
    {$IFEND}
      fDelimiter := {$I 'ESL_inc\ESL_CharType.inc'}(TStrings(Source).Delimiter);
      fQuoteChar := {$I 'ESL_inc\ESL_CharType.inc'}(TStrings(Source).QuoteChar);
      fSorted := False;
      If Source is TStringList then
        begin
          fCaseSensitive := TStringList(Source).CaseSensitive;
          fDuplicates := TStringList(Source).Duplicates;
        end;
    end
  else If Source is {$I 'ESL_inc\ESL_ListType.inc'} then
    begin
      fCaseSensitive := TExplicitStringList(Source).CaseSensitive;
      fStrictDelimiter := TExplicitStringList(Source).StrictDelimiter;
      fTrailingLineBreak := TExplicitStringList(Source).TrailingLineBreak;
      fDuplicates := TExplicitStringList(Source).Duplicates;
      fSorted := TExplicitStringList(Source).Sorted; 
      SetStrings({$I 'ESL_inc\ESL_ListType.inc'}(Source));
      fDelimiter := {$I 'ESL_inc\ESL_ListType.inc'}(Source).Delimiter;
      fLineBreak := {$I 'ESL_inc\ESL_ListType.inc'}(Source).LineBreak;
      fQuoteChar := {$I 'ESL_inc\ESL_ListType.inc'}(Source).QuoteChar;
    end
  else inherited;
finally
  EndUpdate;
end;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_ListType.inc'}.LoadFromStream(Stream: TStream; out Endianness: TStringEndianness);
const
  BufferSize = $10000;  // 64KiB buffer
var
{$DEFINE ESL_ShortHelper}
  Buffer:     Pointer;
  TempStr:    {$I 'ESL_inc\ESL_StringType.inc'};
  TempStrLen: TStrSize;
  BytesRead:  Integer;
  CharsRead:  TStrSize;
  Position:   TStrSize;
  NewLine:    Boolean;
{$IF Defined(ESL_Wide) or Defined(ESL_Unicode) or (Defined(ESL_Default) and Defined(Unicode))}
  i:          Integer;
{$IFEND}

  Function BreakPos(const Str: {$I 'ESL_inc\ESL_StringType.inc'}; Start: Integer = 1): Integer;
  var
    ii: Integer;
  begin
    Result := 0;
    For ii := Start to Length(Str) do
      If IsBreak(Str[ii]) then
        begin
          Result := ii;
          Break{For ii};
        end;
  end;
{$UNDEF ESL_ShortHelper}
begin
Endianness := seSystem;
BeginUpdate;
try
  Clear;
  If Stream.Position < Stream.Size then // is there anything to read?
    begin
      GetMem(Buffer,BufferSize);
      try
      {$IF Defined(ESL_UTF8)}
        // read BOM if present
        If Stream.Size - Stream.Position >= 3{length of UTF8 BOM} then
          begin
            If Stream_ReadUInt8(Stream) <> $EF then
              Stream.Seek(-1,soCurrent)
            else If Stream_ReadUInt8(Stream) <> $BB then
              Stream.Seek(-2,soCurrent)
            else If Stream_ReadUInt8(Stream) <> $BF then
              Stream.Seek(-3,soCurrent);
          end;
      {$ELSEIF Defined(ESL_Wide) or Defined(ESL_Unicode) or (Defined(ESL_Default) and Defined(Unicode))}
        // read BOM and set endianness accordint to it
        If Stream.Size - Stream.Position >= 2{length of UTF16 BOM} then
          begin
            case Stream_ReadUInt16(Stream) of
              $FFFE:  If GetSystemEndianness = seLittle then Endianness := seBig
                        else Endianness := seLittle;
              $FEFF:  Endianness := GetSystemEndianness;
            else
              Stream.Seek(-2,soCurrent);
            end;
          end;
      {$IFEND}
        TempStr := '';
        TempStrLen := 0;
        NewLine := True;
        while Stream.Position < Stream.Size do
          begin
            BytesRead := Stream.Read(Buffer^,BufferSize);
            CharsRead := BytesRead div SizeOf({$I 'ESL_inc\ESL_CharType.inc'});
            Stream.Seek(-(BytesRead mod SizeOf({$I 'ESL_inc\ESL_CharType.inc'})),soCurrent);
            SetLength(TempStr,TempStrLen + CharsRead);
            System.Move(Buffer^,TempStr[TempStrLen + 1],(Length(TempStr) - TempStrLen) * SizeOf({$I 'ESL_inc\ESL_CharType.inc'}));
            TempStrLen := 0;
            repeat
              Position := BreakPos(TempStr,TempStrLen + 1) - 1;
              If Position >= 0 then
                begin
                  If NewLine then
                    begin
                      NewLine := False;
                      Add(Copy(TempStr,TempStrLen + 1,Position - TempStrLen));
                      TempStrLen := Position;
                    end;
                  If (Length(TempStr) - Position) >= 2 then
                    begin
                      If Ord(TempStr[TempStrLen + 1]) = 13 then
                        begin
                          Inc(TempStrLen);
                          NewLine := True;
                        end;
                      If Ord(TempStr[TempStrLen + 1]) = 10 then
                        begin
                          Inc(TempStrLen);
                          NewLine := True;
                        end;
                    end
                  else Position := -1;
                end;
            until Position < 0;
            System.Delete(TempStr,1,TempStrLen);
            TempStrLen := Length(TempStr);
          end;
        If (Length(TempStr) > 0) and not IsBreak(TempStr[1]) then
          Add(TempStr);
      {$IF Defined(ESL_Wide) or Defined(ESL_Unicode) or (Defined(ESL_Default) and Defined(Unicode))}
        // correct endianness for current system
        If (Endianness <> seSystem) and (Endianness <> GetSystemEndianness) then
          For i := LowIndex to HighIndex do
            WideSwapEndian(PWideChar(fStrings[i]),Length(fStrings[i]));
      {$IFEND}
        fSorted := False;
		  finally
        FreeMem(Buffer,BufferSize);
		  end;
		end;
finally
  EndUpdate;
end
end;

{$ENDIF ESL_Implementation}

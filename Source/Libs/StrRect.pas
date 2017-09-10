{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  StrRect - String rectification utility

  Main aim of this library is to simplify conversions in Lazarus when passing
  strings to RTL or WinAPI - mainly to ensure the same code can be used in all
  compilers (Delphi, FPC 2.x.x, FPC 3.x.x) without a need for symbol checks.

  Library was tested in these IDE/compilers:

    Delphi 7 Personal (non-unicode, windows)
    Delphi 10.1 Berlin Personal (unicode, windows)
    Lazarus 1.4.0 - FPC 2.6.4 (non-unicode, linux)
    Lazarus 1.4.4 - FPC 2.6.4 (non-unicode, windows)
    Lazarus 1.6.4 - FPC 3.0.2 (unicode and non-unicode, windows)

  ©František Milt 2017-08-26

  Version 1.1.0

===============================================================================}
unit StrRect;

{$IFDEF FPC}
  {
    Activate symbol BARE_FPC if you want to compile this unit outside of
    Lazarus.
    Non-unicode strings are assumed to be ANSI-encoded when defined, otherwise
    they are assumed to be UTF8-encoded.

    Not defined by default.
  }
  {.$DEFINE BARE_FPC}
  {$MODE ObjFPC}{$H+}
  {$INLINE ON}
  {$DEFINE CanInline}
{$ELSE}
  {$IF CompilerVersion >= 17 then}  // Delphi 2005+
    {$DEFINE CanInline}
  {$ELSE}
    {$UNDEF CanInline}
  {$IFEND}
{$ENDIF}

{$IF Defined(WINDOWS) or Defined(MSWINDOWS)}
  {$DEFINE Windows}
{$IFEND}

interface

type
{$IF not Declared(UnicodeString)}
  UnicodeString = WideString;
{$ELSE}
  // don't ask, it must be here (possible bug in FPC)
  UnicodeString = System.UnicodeString;
{$IFEND}

Function StrToShort(const Str: String): ShortString;{$IFDEF CanInline} inline; {$ENDIF}
Function ShortToStr(const Str: ShortString): String;{$IFDEF CanInline} inline; {$ENDIF}

Function StrToAnsi(const Str: String): AnsiString;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiToStr(const Str: AnsiString): String;{$IFDEF CanInline} inline; {$ENDIF}

Function StrToUTF8(const Str: String): UTF8String;{$IFDEF CanInline} inline; {$ENDIF}
Function UTF8ToStr(const Str: UTF8String): String;{$IFDEF CanInline} inline; {$ENDIF}

Function StrToWide(const Str: String): WideString;{$IFDEF CanInline} inline; {$ENDIF}
Function WideToStr(const Str: WideString): String;{$IFDEF CanInline} inline; {$ENDIF}

Function StrToUnicode(const Str: String): UnicodeString;{$IFDEF CanInline} inline; {$ENDIF}
Function UnicodeToStr(const Str: UnicodeString): String;{$IFDEF CanInline} inline; {$ENDIF}

Function StrToRTL(const Str: String): String;{$IFDEF CanInline} inline; {$ENDIF}
Function RTLToStr(const Str: String): String;{$IFDEF CanInline} inline; {$ENDIF}

Function StrToWinA(const Str: String): AnsiString;{$IFDEF CanInline} inline; {$ENDIF}
Function WinAToStr(const Str: AnsiString): String;{$IFDEF CanInline} inline; {$ENDIF}

Function StrToWinW(const Str: String): UnicodeString;{$IFDEF CanInline} inline; {$ENDIF}
Function WinWToStr(const Str: UnicodeString): String;{$IFDEF CanInline} inline; {$ENDIF}

Function StrToWin(const Str: String): String;{$IFDEF CanInline} inline; {$ENDIF}
Function WinToStr(const Str: String): String;{$IFDEF CanInline} inline; {$ENDIF}

Function StrToCsl(const Str: String): String;{$IFDEF CanInline} inline; {$ENDIF}
Function CslToStr(const Str: String): String;{$IFDEF CanInline} inline; {$ENDIF}

implementation

{$IF (not Defined(FPC) and Defined(Windows)) or (Defined(FPC) and not Defined(BARE_FPC))}
uses
{$IF not Defined(FPC) and Defined(Windows)}
  Windows 
{$IFEND}
{$IF Defined(FPC) and not Defined(BARE_FPC)}
  {$IF not Defined(FPC) and Defined(Windows)},{$IFEND}
(*
  If compiler raises and error that LazUTF8 unit cannot be found, you have to
  add LazUtils to required packages (Project > Project Inspector).
*)
  LazUTF8
{$IFEND};
{$IFEND}

//==============================================================================

{$IF not Declared(UTF8ToString)}
Function UTF8ToString(const Str: UTF8String): UnicodeString;{$IFDEF CanInline} inline; {$ENDIF}
begin
Result := UTF8Decode(Str);
end;
{$IFEND}

//------------------------------------------------------------------------------

{$IF not Declared(StringToUTF8)}
Function StringToUTF8(const Str: UnicodeString): UTF8String;{$IFDEF CanInline} inline; {$ENDIF}
begin                  
Result := UTF8Encode(Str);
end;
{$IFEND}

//==============================================================================

{$IF not Defined(FPC) and not Defined(Unicode)}

Function AnsiToConsole(const Str: String): String;
begin
{$IFDEF Windows}
  If Length (Str) > 0 then
    begin
      Result := StrToWinA(Str);
      UniqueString(Result);
      If not CharToOEMBuff(PAnsiChar(Result),PAnsiChar(Result),Length(Result)) then
        Result := '';
    end
  else Result := '';
{$ELSE}
  Result := Str;
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function ConsoleToAnsi(const Str: String): String;
begin
{$IFDEF Windows}
  If Length (Str) > 0 then
    begin
      Result := Str;
      UniqueString(Result);
      If OEMToCharBuff(PAnsiChar(Result),PAnsiChar(Result),Length(Result)) then
        Result := WinAToStr(Result)
      else
        Result := '';
    end
  else Result := '';
{$ELSE}
  Result := Str;
{$ENDIF}
end;

{$IFEND}

//==============================================================================

{$IF Defined(FPC) and not Defined(Unicode)}

Function _StrToAnsi(const Str: String): String;{$IFDEF CanInline} inline; {$ENDIF}
begin
{$IFDEF BARE_FPC}
  Result := Str;
{$ELSE}
  {$IFDEF Windows}
  Result := UTF8ToWinCP(Str);
  {$ELSE}
  Result := UTF8ToAnsi(Str);
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function _AnsiToStr(const Str: String): String;{$IFDEF CanInline} inline; {$ENDIF}
begin
{$IFDEF BARE_FPC}
  Result := Str;
{$ELSE}
  {$IFDEF Windows}
  Result := WinCPToUTF8(Str);
  {$ELSE}
  Result := AnsitoUTF8(Str);
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function _StrToUTF8(const Str: String): UTF8String;{$IFDEF CanInline} inline; {$ENDIF}
begin
{$IFDEF BARE_FPC}
  Result := AnsiToUTF8(Str);
{$ELSE}
  If Length(Str) > 0 then
    begin
      // prevent implicit conversion
      SetLength(Result,Length(Str));
      Move(Addr(Str[1])^,Addr(Result[1])^,Length(Str));
    end
  else Result := '';
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function _UTF8ToStr(const Str: UTF8String): String;{$IFDEF CanInline} inline; {$ENDIF}
begin
{$IFDEF BARE_FPC}
  Result := UTF8ToAnsi(Str);
{$ELSE}
  If Length(Str) > 0 then
    begin
      // prevent implicit conversion
      SetLength(Result,Length(Str));
      Move(Addr(Str[1])^,Addr(Result[1])^,Length(Str));
    end
  else Result := '';
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function _StrToWide(const Str: String): UnicodeString;{$IFDEF CanInline} inline; {$ENDIF}
begin
{$IFDEF BARE_FPC}
  Result := UnicodeString(Str);
{$ELSE}
  Result := UTF8Decode(Str);
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function _WideToStr(const Str: UnicodeString): String;{$IFDEF CanInline} inline; {$ENDIF}
begin
{$IFDEF BARE_FPC}
  Result := String(Str);
{$ELSE}
  Result := UTF8Encode(Str);
{$ENDIF}
end;

{$IFEND}

//==============================================================================

Function StrToShort(const Str: String): ShortString;
begin
{$IFOPT H+}
  // long strings
{$IFDEF Unicode}
  {$IFDEF FPC}
    // unicode FPC (String = UnicodeString)
    Result := ShortString({$IFNDEF BARE_FPC}UTF8ToWinCP{$ENDIF}(UTF8Encode(Str)));
  {$ELSE}
    // unicode Delphi (String = UnicodeString)
    Result := ShortString(Str);
  {$ENDIF}
{$ELSE}
  {$IFDEF FPC}
    // non-unicode FPC (String = AnsiString(UTF8))
    Result := ShortString(_StrToAnsi(Str));
  {$ELSE}
    // non-unicode delphi (String = AnsiString)
    Result := ShortString(Str);
  {$ENDIF}
{$ENDIF}
{$ELSE}
  // short strings
  Result := Str;
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function ShortToStr(const Str: ShortString): String;
begin
{$IFOPT H+}
{$IFDEF Unicode}
  {$IFDEF FPC}
    Result := UTF8Decode({$IFNDEF BARE_FPC}WinCPToUTF8{$ENDIF}(AnsiString(Str)));
  {$ELSE}
    Result := String(Str);
  {$ENDIF}
{$ELSE}
  {$IFDEF FPC}
    Result := _AnsiToStr(AnsiString(Str));
  {$ELSE}
    Result := String(Str);
  {$ENDIF}
{$ENDIF}
{$ELSE}
  Result := Str;
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function StrToAnsi(const Str: String): AnsiString;
begin
{$IFDEF Unicode}
  {$IFDEF FPC}
    Result := {$IFNDEF BARE_FPC}UTF8ToWinCP{$ENDIF}(UTF8Encode(Str));
  {$ELSE}
    Result := AnsiString(Str);
  {$ENDIF}
{$ELSE}
  {$IFDEF FPC}
    Result := _StrToAnsi(Str);
  {$ELSE}
    Result := Str;
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function AnsiToStr(const Str: AnsiString): String;
begin
{$IFDEF Unicode}
  {$IFDEF FPC}
    Result := UTF8Decode({$IFNDEF BARE_FPC}WinCPToUTF8{$ENDIF}(Str));
  {$ELSE}
    Result := String(Str);
  {$ENDIF}
{$ELSE}
  {$IFDEF FPC}
    Result := _AnsiToStr(Str);
  {$ELSE}
    Result := Str;
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function StrToUTF8(const Str: String): UTF8String;
begin
{$IFDEF Unicode}
  {$IFDEF FPC}
    Result := UTF8Encode(Str);
  {$ELSE}
    Result := StringToUTF8(Str);
  {$ENDIF}
{$ELSE}
  {$IFDEF FPC}
    Result := _StrToUTF8(Str);
  {$ELSE}
    Result := AnsiToUTF8(Str);
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function UTF8ToStr(const Str: UTF8String): String;
begin
{$IFDEF Unicode}
  {$IFDEF FPC}
    Result := UTF8Decode(Str);
  {$ELSE}
    Result := UTF8ToString(Str);
  {$ENDIF}
{$ELSE}
  {$IFDEF FPC}
    Result := _UTF8ToStr(Str);
  {$ELSE}
    Result := UTF8ToAnsi(Str);
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function StrToWide(const Str: String): WideString;
begin
{$IFDEF Unicode}
    Result := Str;
{$ELSE}
  {$IFDEF FPC}
    Result := _StrToWide(Str);
  {$ELSE}
    Result := WideString(Str);
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function WideToStr(const Str: WideString): String;
begin
{$IFDEF Unicode}
    Result := Str;
{$ELSE}
  {$IFDEF FPC}
    Result := _WideToStr(Str);
  {$ELSE}
    Result := String(Str);
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function StrToUnicode(const Str: String): UnicodeString;
begin
{$IFDEF Unicode}
    Result := Str;
{$ELSE}
  {$IFDEF FPC}
    Result := _StrToWide(Str);
  {$ELSE}
    Result := UnicodeString(Str);
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function UnicodeToStr(const Str: UnicodeString): String;
begin
{$IFDEF Unicode}
    Result := Str;
{$ELSE}
  {$IFDEF FPC}
    Result := _WideToStr(Str);
  {$ELSE}
    Result := String(Str);
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function StrToRTL(const Str: String): String;
begin
{$IFDEF Unicode}
    Result := Str;
{$ELSE}
  {$IFDEF FPC}
    Result := {$IFNDEF BARE_FPC}UTF8ToSys{$ENDIF}(Str);
  {$ELSE}
    Result := Str;
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function RTLToStr(const Str: String): String;
begin
{$IFDEF Unicode}
    Result := Str;
{$ELSE}
  {$IFDEF FPC}
    Result := {$IFNDEF BARE_FPC}SysToUTF8{$ENDIF}(Str);
  {$ELSE}
    Result := Str;
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function StrToWinA(const Str: String): AnsiString;
begin
Result := StrToAnsi(Str);
end;

//------------------------------------------------------------------------------

Function WinAToStr(const Str: AnsiString): String;
begin
Result := AnsitoStr(Str);
end;

//------------------------------------------------------------------------------

Function StrToWinW(const Str: String): UnicodeString;
begin
Result := StrToWide(Str);
end;

//------------------------------------------------------------------------------

Function WinWToStr(const Str: UnicodeString): String;
begin
Result := WideToStr(Str);
end;

//------------------------------------------------------------------------------

Function StrToWin(const Str: String): String;
begin
{$IFDEF Unicode}
Result := StrToWinW(Str);
{$ELSE}
Result := StrToWinA(Str);
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function WinToStr(const Str: String): String;
begin
{$IFDEF Unicode}
Result := WinWToStr(Str);
{$ELSE}
Result := WinAToStr(Str);
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function StrToCsl(const Str: String): String;
begin
{$IFDEF Unicode}
    Result := Str;
{$ELSE}
  {$IFDEF FPC}
    Result := {$IFNDEF BARE_FPC}UTF8ToConsole{$ENDIF}(Str);
  {$ELSE}
    Result := AnsiToConsole(Str);
  {$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function CslToStr(const Str: String): String;
begin
{$IFDEF Unicode}
    Result := Str;
{$ELSE}
  {$IFDEF FPC}
    Result := {$IFNDEF BARE_FPC}ConsoleToUTF8{$ENDIF}(Str);
  {$ELSE}
    Result := ConsoleToAnsi(Str);
  {$ENDIF}
{$ENDIF}
end;

end.

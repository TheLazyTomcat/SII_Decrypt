{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}

{===============================================================================
    T*DelimitedTextParser - declaration
===============================================================================}

{$IFDEF ESL_Declaration}
  private
    fDelimiter:       {$I 'ESL_inc\ESL_CharType.inc'};
    fQuoteChar:       {$I 'ESL_inc\ESL_CharType.inc'};
    fStrictDelimiter: Boolean;
    fOnNewString:     {$I 'ESL_inc\ESL_DTParserEventType.inc'};
    // parsing vars
    fParserState:     TDelimitedTextParserState;
    fParsedString:    {$I 'ESL_inc\ESL_StringType.inc'};
    fPosition:        TStrSize;
    fItemStart:       TStrSize;
    fItemLength:      TStrSize;
  protected
    Function RemoveDoubleQuotes(const Str: {$I 'ESL_inc\ESL_StringType.inc'}): {$I 'ESL_inc\ESL_StringType.inc'}; virtual;
    Function LookAhead(IsChar: {$I 'ESL_inc\ESL_CharType.inc'}): Boolean; virtual;
    Function CurrCharType: TDelimitedTextParserCharType; virtual;
    procedure Parse_Initial; virtual;
    procedure Parse_WhiteSpace; virtual;
    procedure Parse_Delimiter; virtual;
    procedure Parse_NormalText; virtual;
    procedure Parse_QuotedText; virtual;
    procedure DoNewString(const Str: {$I 'ESL_inc\ESL_StringType.inc'}); virtual;
  public
    constructor Create(Delimiter, QuoteChar: {$I 'ESL_inc\ESL_CharType.inc'}; StrictDelimiter: Boolean);
    procedure Parse(const Str: {$I 'ESL_inc\ESL_StringType.inc'}); virtual;
    property OnNewString: {$I 'ESL_inc\ESL_DTParserEventType.inc'} read fOnNewString write fOnNewString;
{$ENDIF ESL_Declaration}

{===============================================================================
    T*DelimitedTextParser - implementation
===============================================================================}

{$IFDEF ESL_Implementation}

{-------------------------------------------------------------------------------
    T*DelimitedTextParser - protected methods
-------------------------------------------------------------------------------}

Function {$I 'ESL_inc\ESL_DTParserType.inc'}.RemoveDoubleQuotes(const Str: {$I 'ESL_inc\ESL_StringType.inc'}): {$I 'ESL_inc\ESL_StringType.inc'};
var
  i,ResPos: TStrSize;
  LastChar: {$I 'ESL_inc\ESL_CharType.inc'};
begin
If Length(Str) > 0 then
  begin
    SetLength(Result,Length(Str));
    ResPos := 1;
    LastChar := {$I 'ESL_inc\ESL_CharType.inc'}(not Ord(fQuoteChar));
    For i := 1 to Length(Str) do
      If not((Str[i] = fQuoteChar) and (LastChar = fQuoteChar)) then
        begin
          Result[ResPos] := Str[i];
          Inc(ResPos);
          LastChar := Str[i];
        end
      else LastChar := {$I 'ESL_inc\ESL_CharType.inc'}(not Ord(fQuoteChar));
    SetLength(Result,ResPos - 1);
  end
else Result := '';
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_DTParserType.inc'}.LookAhead(IsChar: {$I 'ESL_inc\ESL_CharType.inc'}): Boolean;
begin
If (fPosition >= 1) and (fPosition < Length(fParsedString)) then
  Result := fParsedString[fPosition + 1] = IsChar
else
  Result := False;
end;

//------------------------------------------------------------------------------

Function {$I 'ESL_inc\ESL_DTParserType.inc'}.CurrCharType: TDelimitedTextParserCharType;
begin
If Ord(fParsedString[fPosition]) in [0..32] then
  Result := dtpcWhiteSpace
else If fParsedString[fPosition] = fDelimiter then
  Result := dtpcDelimiter
else If fParsedString[fPosition] = fQuoteChar then
  Result := dtpcQuoteChar
else
  Result := dtpcGeneral;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_DTParserType.inc'}.Parse_Initial;
begin
fParserState := dtpsDelimiter;
fPosition := 0;
fItemStart := 0;
fItemLength := 0;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_DTParserType.inc'}.Parse_WhiteSpace;
begin
case CurrCharType of
  dtpcWhiteSpace:;// ignore
  dtpcDelimiter:  fParserState := dtpsDelimiter;
  dtpcQuoteChar:  If not fStrictDelimiter then
                    begin
                      fItemStart := fPosition + 1;
                      fItemLength := 0;
                      fParserState := dtpsQuotedText;
                    end;
  dtpcGeneral:    If not fStrictDelimiter then
                    begin
                      fItemStart := fPosition;
                      fItemLength := 1;
                      fParserState := dtpsNormalText;
                    end;  
end;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_DTParserType.inc'}.Parse_Delimiter;
begin
case CurrCharType of
  dtpcWhiteSpace:;// ignore
  dtpcDelimiter:  DoNewString('');
  dtpcQuoteChar:  begin
                    fItemStart := fPosition + 1;
                    fItemLength := 0;
                    fParserState := dtpsQuotedText;
                  end;
  dtpcGeneral:    begin
                    fItemStart := fPosition;
                    fItemLength := 1;
                    fParserState := dtpsNormalText;
                  end;
end;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_DTParserType.inc'}.Parse_NormalText;
begin
case CurrCharType of
  dtpcWhiteSpace: If not fStrictDelimiter then
                    begin
                      DoNewString(Copy(fParsedString,fItemStart,fItemLength));
                      fParserState := dtpsWhiteSpace;
                    end
                  else Inc(fItemLength);
  dtpcDelimiter:  begin
                    DoNewString(Copy(fParsedString,fItemStart,fItemLength));
                    fParserState := dtpsDelimiter;
                  end;
  dtpcQuoteChar,
  dtpcGeneral:    Inc(fItemLength);
end;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_DTParserType.inc'}.Parse_QuotedText;
begin
If CurrCharType = dtpcQuoteChar then
  begin
    If LookAhead(fQuoteChar) then
      begin
        Inc(fPosition);
        Inc(fItemLength,2);
      end
    else
      begin
        DoNewString(RemoveDoubleQuotes(Copy(fParsedString,fItemStart,fItemLength)));
        fParserState := dtpsWhiteSpace;
      end;
  end
else Inc(fItemLength);
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_DTParserType.inc'}.DoNewString(const Str: {$I 'ESL_inc\ESL_StringType.inc'});
begin
If Assigned(fOnNewString) then
  fOnNewString(Str);
end;


{-------------------------------------------------------------------------------
    T*DelimitedTextParser - public methods
-------------------------------------------------------------------------------}

constructor {$I 'ESL_inc\ESL_DTParserType.inc'}.Create(Delimiter, QuoteChar: {$I 'ESL_inc\ESL_CharType.inc'}; StrictDelimiter: Boolean);
begin
inherited Create;
fDelimiter := Delimiter;
fQuoteChar := QuoteChar;
fStrictDelimiter := StrictDelimiter;
end;

//------------------------------------------------------------------------------

procedure {$I 'ESL_inc\ESL_DTParserType.inc'}.Parse(const Str: {$I 'ESL_inc\ESL_StringType.inc'});
begin
fParserState := dtpsInitial;
fParsedString := Str;
fPosition := 0;
while fPosition <= Length(fParsedString) do
  begin
    case fParserState of
      dtpsInitial:    Parse_Initial;
      dtpsWhiteSpace: Parse_WhiteSpace;
      dtpsDelimiter:  Parse_Delimiter;
      dtpsNormalText: Parse_NormalText;
      dtpsQuotedText: Parse_QuotedText;
    else
      raise Exception.CreateFmt('%s.Parse: Invalid parser state (%d).',[Self.ClassName,Ord(fParserState)]);
    end;
    Inc(fPosition);
  end;
case fParserState of
  dtpsDelimiter:  DoNewString('');
  dtpsNormalText: DoNewString(Copy(fParsedString,fItemStart,fItemLength));
  dtpsQuotedText: DoNewString(RemoveDoubleQuotes(Copy(fParsedString,fItemStart,fItemLength)));
end;
end;

{$ENDIF ESL_Implementation}

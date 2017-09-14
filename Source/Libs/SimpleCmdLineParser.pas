{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  SimpleCmdLineParser

  ©František Milt 2017-09-11

  Version 1.1.0

  Dependencies:
    StrRect - github.com/ncs-sniper/Lib.StrRect

===============================================================================}
{*******************************************************************************

  In current implementation, three basic objects are parsed from the command
  line - short command, long commad and general object.
  If first parsed object is a general text, it is assumed to be the image path.
  If you want to have general object after a command (normally it would be
  parsed as a command argument), add command termination char after the command.

-- Short command ---------------------------------------------------------------

  - starts with a single command intro character
  - exactly one character long
  - only lower and upper case letters (a..z, A..Z)
  - case sensitive (a is NOT the same as A)
  - cannot be enclosed in quote chars
  - can be compounded (several commands merged into one)
  - can have arguments, first is separated by a white space, subsequent are
    delimited by a delimiter character; in counpound commands, only the last
    command can have an argument

Examples:

  -v                                  // simple command
  -vbT                                // compound command (commands v, b and T)
  -f file1.txt, "file 2.txt"          // simple with two arguments
  -Tzf "file.dat"                     // compound, last command (f) with one argument

-- Long command ----------------------------------------------------------------

  - starts with two command intro characters
  - length is not explicitly limited
  - only lower and upper case letters (a..z, A..Z), numbers (0..9), underscore
    (_) and dash (-)
  - case insensitive
  - cannot start with a dash
  - cannot contain white-space characters
  - cannot be enclosed in quote chars
  - cannot be compounded
  - can have arguments, first argument is separated by a white space, subsequent
    are delimited by a delimiter character

Examples:

  --show_warnings                     // simple command
  --input_file "file1.txt"            // simple with one argument
  --files "file1.dat", "files2.dat"   // simple with two arguments

-- General ---------------------------------------------------------------------

  - any text that is not a command or delimiter
  - cannot contain whitespaces, delimiter, quotation or command intro character
  - ...unless it is enclosed in quote chars
  - to add one quote char, escape it with another one

Examples:

  this_is_simple_general_text
  "quoted text with ""whitespaces"" and quote chars"
  "special characters: - -- , """

*******************************************************************************}
unit SimpleCmdLineParser;

{$TYPEINFO ON}

interface

{===============================================================================
--------------------------------------------------------------------------------
                                   TCLPParser
--------------------------------------------------------------------------------
===============================================================================}

type
  TCLPParamType = (ptShortCommand,ptLongCommand,ptGeneral);

  TCLPParameter = record
    ParamType:  TCLPParamType;
    Str:        String;
    Arguments:  array of String;
  end;

  TCLPParameters = record
    Arr:    array of TCLPParameter;
    Count:  Integer;
  end;

  TCLPParserState = (psInitial,psCommand,psArgument,psGeneral);

{===============================================================================
    TCLPParser - class declaration
===============================================================================}

  TCLPParser = class(TObject)
  private
    fCommandIntroChar:  Char;
    fQuoteChar:         Char;
    fDelimiterChar:     Char;
    fCmdTerminateChar:  Char;
    fCommandLine:       String;
    fImagePath:         String;
    fParameters:        TCLPParameters;
    // parsing variables
    fLexer:             TObject;
    fState:             TCLPParserState;
    fTokenIndex:        Integer;
    fCurrentParam:      TCLPParameter;
    Function GetParameter(Index: Integer): TCLPParameter;
  protected
    procedure AddParam(Data: TCLPParameter); overload; virtual;
    procedure AddParam(ParamType: TCLPParamType; const Str: String); overload; virtual;
    // parsing
    procedure Process_Initial; virtual;
    procedure Process_Command; virtual;
    procedure Process_Argument; virtual;
    procedure Process_General; virtual;
  public
    constructor CreateEmpty;
    constructor Create(const CommandLine: String); overload;
    constructor Create; overload;
    destructor Destroy; override;
    Function LowIndex: Integer; virtual;
    Function HighIndex: Integer; virtual;
    Function First: TCLPParameter; virtual;
    Function Last: TCLPParameter; virtual;
    Function IndexOf(const Str: String; CaseSensitive: Boolean): Integer; virtual;
    Function CommandPresent(ShortForm: Char): Boolean; overload; virtual;
    Function CommandPresent(const LongForm: String): Boolean; overload; virtual;
    Function CommandPresent(ShortForm: Char; const LongForm: String): Boolean; overload; virtual;
    Function GetCommandData(ShortForm: Char; out CommandData: TCLPParameter): Boolean; overload; virtual;
    Function GetCommandData(const LongForm: String; out CommandData: TCLPParameter): Boolean; overload; virtual;
    Function GetCommandData(ShortForm: Char; const LongForm: String; out CommandData: TCLPParameter): Boolean; overload; virtual;
    Function GetCommandCount: Integer; virtual;
    procedure Clear; virtual;
    procedure Parse(const CommandLine: String); virtual;
    procedure ReParse; virtual;
    property Parameters[Index: Integer]: TCLPParameter read GetParameter; default;
  published
    property CommandIntroChar: Char read fCommandIntroChar write fCommandIntroChar;
    property QuoteChar: Char read fQuoteChar write fQuoteChar;
    property DelimiterChar: Char read fDelimiterChar write fDelimiterChar;
    property CommandTerminateChar: Char read fCmdTerminateChar write fCmdTerminateChar;
    property Count: Integer read fParameters.Count;
    property CommandLine: String read fCommandLine;
    property ImagePath: String read fImagePath;
  end;

implementation

uses
  SysUtils, StrRect;

{===============================================================================
    Auxiliary functions
===============================================================================}

{$If not Declared(CharInSet)}

Function CharInSet(C: AnsiChar; const CharSet: TSysCharSet): Boolean; overload;
begin
Result := C in CharSet;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function CharInSet(C: WideChar; const CharSet: TSysCharSet): Boolean; overload;
begin
If Ord(C) <= 255 then
  Result := AnsiChar(C) in CharSet
else
  Result := False;
end;

{$IFEND}

{===============================================================================
    Implementation constants
===============================================================================}

const
  def_CommandIntroChar = '-';
  def_QuoteChar        = '"';
  def_DelimiterChar    = ',';
  def_CmdTerminateChar = ';';

  CHARS_SHORTCOMMAND = ['a'..'z','A'..'Z'];
  CHARS_LONGCOMMAND  = ['a'..'z','A'..'Z','0'..'9','_','-'];
  CHARS_WHITESPACE   = [#0..#32];

{===============================================================================
--------------------------------------------------------------------------------
                                   TCLPLexer
--------------------------------------------------------------------------------
===============================================================================}

type
  TCLPLexerTokenType = (ttShortCommand,ttLongCommand,ttDelimiter,ttTerminator,ttGeneral);

  TCLPLexerToken = record
    TokenType:  TCLPLexerTokenType;
    Str:        String;
    Position:   Integer;
  end;

  TCLPLexerTokens = record
    Arr:    array of TCLPLexerToken;
    Count:  Integer;
  end;

  TCLPLexerCharType = (lctWhiteSpace,lctCommandIntro,lctQuote,lctDelimiter,lctTerminator,lctOther);
  TCLPLexerState    = (lsStart,lsTraverse,lsText,lsQuoted,lsShortCommand,lsLongCommand);

{===============================================================================
    TCLPLexer - class declaration
===============================================================================}

  TCLPLexer = class(TObject)
  private
    fCommandIntroChar:  Char;
    fQuoteChar:         Char;
    fDelimiterChar:     Char;
    fCmdTerminateChar:  Char;
    fCommandLine:       String;
    fTokens:            TCLPLexerTokens;
    // tokenization variables
    fState:             TCLPLexerState;
    fPosition:          Integer;
    fTokenStart:        Integer;
    fTokenLength:       Integer;
    Function GetToken(Index: Integer): TCLPLexerToken;
  protected
    procedure AddToken(TokenType: TCLPLexerTokenType; const Str: String; Position: Integer); virtual;
    // tokenization
    Function LookAhead(aChar: Char): Boolean; virtual;
    Function CurrCharType: TCLPLexerCharType; virtual;
    procedure Process_Common(TokenType: TCLPLexerTokenType); virtual;
    procedure Process_Start; virtual;
    procedure Process_Traverse; virtual;
    procedure Process_Text; virtual;
    procedure Process_Quoted; virtual;
    procedure Process_ShortCommand; virtual;
    procedure Process_LongCommand; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Analyze(const CommandLine: String); virtual;
    procedure Clear; virtual;
    property Tokens[Index: Integer]: TCLPLexerToken read GetToken; default;
  published
    property CommandIntroChar: Char read fCommandIntroChar write fCommandIntroChar;
    property QuoteChar: Char read fQuoteChar write fQuoteChar;
    property DelimiterChar: Char read fDelimiterChar write fDelimiterChar;
    property CommandTerminateChar: Char read fCmdTerminateChar write fCmdTerminateChar;
    property CommandLine: String read fCommandLine;
    property Count: Integer read fTokens.Count;
  end;

{===============================================================================
    TCLPLexer - class implementation
===============================================================================}

{-------------------------------------------------------------------------------
    TCLPLexer - private methods
-------------------------------------------------------------------------------}

Function TCLPLexer.GetToken(Index: Integer): TCLPLexerToken;
begin
If (Index >= Low(fTokens.Arr)) and (Index < fTokens.Count) then
  Result := fTokens.Arr[Index]
else
  raise Exception.CreateFmt('TCLPLexer.GetToken: Index (%d) out of bounds.',[Index]);
end;

{-------------------------------------------------------------------------------
    TCLPLexer - protected methods
-------------------------------------------------------------------------------}

procedure TCLPLexer.AddToken(TokenType: TCLPLexerTokenType; const Str: String; Position: Integer);
var
  TempStr:    String;
  i,TempPos:  Integer;
  LastChar:   Char;
begin
If fTokens.Count >= Length(fTokens.Arr) then
  SetLength(fTokens.Arr,Length(ftokens.Arr) + 16);
// split compund short commands
If (TokenType = ttShortCommand) and (Length(Str) > 1) then
  begin
    For i := 1 to Length(Str) do
      AddToken(ttShortCommand,Str[i],Position + Pred(i));
  end
else
  begin
    // remove any double quote chars
    If TokenType = ttGeneral then
      begin
        SetLength(TempStr,Length(Str));
        FillChar(PChar(TempStr)^,Length(TempStr) * SizeOf(Char),0);
        TempPos := 1;
        LastChar := #0;
        For i := 1 to Length(Str) do
          If not((Str[i] = fQuoteChar) and (LastChar = fQuoteChar)) then
            begin
              TempStr[TempPos] := Str[i];
              Inc(TempPos);
              LastChar := Str[i];
            end
          else LastChar := #0;
        SetLength(TempStr,Pred(TempPos));
      end
    else TempStr := Str;
    // store token data
    fTokens.Arr[fTokens.Count].TokenType := TokenType;
    fTokens.Arr[fTokens.Count].Str := TempStr;
    fTokens.Arr[fTokens.Count].Position := Position;
    Inc(ftokens.Count);
  end;
fTokenLength := 0;
end;

//------------------------------------------------------------------------------

Function TCLPLexer.LookAhead(aChar: Char): Boolean;
begin
If fPosition < Length(fCommandLine) then
  Result := fCommandLine[fPosition + 1] = aChar
else
  Result := False;
end;

//------------------------------------------------------------------------------

Function TCLPLexer.CurrCharType: TCLPLexerCharType;
begin
If CharInSet(fCommandLine[fPosition],CHARS_WHITESPACE) then
  Result := lctWhiteSpace
else If fCommandLine[fPosition] = fCommandIntroChar then
  Result := lctCommandIntro
else If fCommandLine[fPosition] = fQuoteChar then
  Result := lctQuote
else If fCommandLine[fPosition] = fDelimiterChar then
  Result := lctDelimiter
else If fCommandLine[fPosition] = fCmdTerminateChar then
  Result := lctTerminator
else
  Result := lctOther;
end;

//------------------------------------------------------------------------------

procedure TCLPLexer.Process_Common(TokenType: TCLPLexerTokenType);
begin
case CurrCharType of
  lctWhiteSpace:    begin
                      If fTokenLength > 0 then
                        AddToken(TokenType,Copy(fCommandLine,fTokenStart,fTokenLength),fTokenStart);
                      fState := lsTraverse;
                    end;
  lctCommandIntro:  begin
                      If fTokenLength > 0 then
                        AddToken(TokenType,Copy(fCommandLine,fTokenStart,fTokenLength),fTokenStart);
                      If LookAhead(fCommandIntroChar) then
                        begin
                          fState := lsLongCommand;
                          Inc(fPosition);
                        end
                      else fState := lsShortCommand;
                      fTokenStart := fPosition + 1;
                      fTokenLength := 0;                      
                    end;
  lctQuote:         begin
                      If fTokenLength > 0 then
                        AddToken(TokenType,Copy(fCommandLine,fTokenStart,fTokenLength),fTokenStart);
                      fState := lsQuoted;
                      fTokenStart := fPosition + 1;
                      fTokenLength := 0;
                    end;
  lctDelimiter:     begin
                      If fTokenLength > 0 then
                        AddToken(TokenType,Copy(fCommandLine,fTokenStart,fTokenLength),fTokenStart);
                      AddToken(ttDelimiter,fCommandLine[fPosition],fPosition);
                      fState := lsTraverse;
                    end;
  lctTerminator:    begin
                      If fTokenLength > 0 then
                        AddToken(TokenType,Copy(fCommandLine,fTokenStart,fTokenLength),fTokenStart);
                      AddToken(ttTerminator,fCommandLine[fPosition],fPosition);
                      fState := lsTraverse;
                    end;
end;
end;

//------------------------------------------------------------------------------

procedure TCLPLexer.Process_Start;
begin
fState := lsTraverse;
fPosition := 0;
fTokenStart := 0;
fTokenLength := 0;
end;

//------------------------------------------------------------------------------

procedure TCLPLexer.Process_Traverse;
begin
case CurrCharType of
  lctWhiteSpace:;
  lctCommandIntro:  begin
                      If LookAhead(fCommandIntroChar) then
                        begin
                          fState := lsLongCommand;
                          Inc(fPosition);
                        end
                      else fState := lsShortCommand;
                      fTokenStart := fPosition + 1;
                      fTokenLength := 0;
                    end;
  lctQuote:         begin
                      fState := lsQuoted;
                      fTokenStart := fPosition + 1;
                      fTokenLength := 0;
                    end;
  lctDelimiter:     AddToken(ttDelimiter,fCommandLine[fPosition],fPosition);
  lctTerminator:    AddToken(ttTerminator,fCommandLine[fPosition],fPosition);
  lctOther:         begin
                      fState := lsText;
                      fTokenStart := fPosition;
                      fTokenLength := 1;
                    end;
end;
end;

//------------------------------------------------------------------------------

procedure TCLPLexer.Process_Text;
begin
If CurrCharType = lctOther then
  Inc(fTokenLength)
else
  Process_Common(ttGeneral);
end;

//------------------------------------------------------------------------------

procedure TCLPLexer.Process_Quoted;
begin
If CurrCharType = lctQuote then
  begin
    If LookAhead(fQuoteChar) then
      begin
        Inc(fPosition);
        Inc(fTokenLength,2);
      end
    else
      begin
        If fTokenLength > 0 then
          AddToken(ttGeneral,Copy(fCommandLine,fTokenStart,fTokenLength),fTokenStart);
        fState := lsTraverse;
      end;
  end
else Inc(fTokenLength);
end;

//------------------------------------------------------------------------------

procedure TCLPLexer.Process_ShortCommand;
begin
If CurrcharType = lctOther then
  begin
    If not CharInSet(fCommandLine[fPosition],CHARS_SHORTCOMMAND) then
      begin
        If fTokenLength > 0 then
          AddToken(ttShortCommand,Copy(fCommandLine,fTokenStart,fTokenLength),fTokenStart);
        AddToken(ttGeneral,fCommandLine[fPosition],fPosition);
        fState := lsTraverse;
      end
    else Inc(fTokenLength);
  end
else Process_Common(ttShortCommand);
end;

//------------------------------------------------------------------------------

procedure TCLPLexer.Process_LongCommand;
begin
begin
If CurrcharType = lctOther then
  begin
    If not CharInSet(fCommandLine[fPosition],CHARS_LONGCOMMAND) then
      begin
        If fTokenLength > 0 then
          AddToken(ttLongCommand,Copy(fCommandLine,fTokenStart,fTokenLength),fTokenStart);
        AddToken(ttGeneral,fCommandLine[fPosition],fPosition);
        fState := lsTraverse;
      end
    else Inc(fTokenLength);
  end
else Process_Common(ttLongCommand);
end;
end;

{-------------------------------------------------------------------------------
    TCLPLexer - public methods
-------------------------------------------------------------------------------}

constructor TCLPLexer.Create;
begin
inherited;
fCommandIntroChar := def_CommandIntroChar;
fQuoteChar := def_QuoteChar;
fDelimiterChar := def_DelimiterChar;
fCmdTerminateChar := def_CmdTerminateChar;
SetLength(fTokens.Arr,0);
fTokens.Count := 0;
fCommandLine := '';
end;

//------------------------------------------------------------------------------

destructor TCLPLexer.Destroy;
begin
Clear;
inherited;
end;

//------------------------------------------------------------------------------

procedure TCLPLexer.Analyze(const CommandLine: String);
begin
fTokens.Count := 0;
fState := lsStart;
fCommandLine := CommandLine;
fPosition := 0;
while fPosition <= Length(fCommandLine) do
  begin
    case fState of
      lsStart:        Process_Start;
      lsTraverse:     Process_Traverse;
      lsText:         Process_Text;
      lsQuoted:       Process_Quoted;
      lsShortCommand: Process_ShortCommand;
      lsLongCommand:  Process_LongCommand;
    else
      raise Exception.CreateFmt('TCLPLexer.Analyze: Invalid lexer state (%d).',[Ord(fState)]);
    end;
    Inc(fPosition);
  end;
If fTokenLength > 0 then
  case fState of
    lsText,
    lsQuoted:       AddToken(ttGeneral,Copy(fCommandLine,fTokenStart,fTokenLength),fTokenStart);
    lsShortCommand: AddToken(ttShortCommand,Copy(fCommandLine,fTokenStart,fTokenLength),fTokenStart);
    lsLongCommand:  AddToken(ttLongCommand,Copy(fCommandLine,fTokenStart,fTokenLength),fTokenStart);
  end;
end;

//------------------------------------------------------------------------------

procedure TCLPLexer.Clear;
begin
fTokens.Count := 0;
SetLength(fTokens.Arr,0);
fCommandLine := '';
end;


{===============================================================================
--------------------------------------------------------------------------------
                                   TCLPParser
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    TCLPParser - class implementation
===============================================================================}

{-------------------------------------------------------------------------------
    TCLPParser - private methods
-------------------------------------------------------------------------------}

Function TCLPParser.GetParameter(Index: Integer): TCLPParameter;
begin
If (Index >= Low(fParameters.Arr)) and (Index < fParameters.Count) then
  Result := fParameters.Arr[Index]
else
  raise Exception.CreateFmt('TCLPParser.GetParameter: Index (%d) out of bounds.',[Index]);
end;

{-------------------------------------------------------------------------------
    TCLPParser - protected methods
-------------------------------------------------------------------------------}

procedure TCLPParser.AddParam(Data: TCLPParameter);
begin
If fParameters.Count >= Length(fParameters.Arr) then
  SetLength(fParameters.Arr,Length(fParameters.Arr) + 16);
fParameters.Arr[fParameters.Count] := Data;
Inc(fParameters.Count);
end;

//------------------------------------------------------------------------------

procedure TCLPParser.AddParam(ParamType: TCLPParamType; const Str: String);
var
  Temp: TCLPParameter;
begin
Temp.ParamType := ParamType;
Temp.Str := Str;
SetLength(Temp.Arguments,0);
AddParam(Temp);
end;

//------------------------------------------------------------------------------

procedure TCLPParser.Process_Initial;
begin
case TCLPLexer(fLexer)[fTokenIndex].TokenType of
  ttShortCommand: begin
                    fCurrentParam.ParamType := ptShortCommand;
                    fCurrentParam.Str := TCLPLexer(fLexer)[fTokenIndex].Str;
                    SetLength(fCurrentParam.Arguments,0);
                    fState := psCommand;
                  end;
  ttLongCommand:  begin
                    fCurrentParam.ParamType := ptLongCommand;
                    fCurrentParam.Str := TCLPLexer(fLexer)[fTokenIndex].Str;
                    SetLength(fCurrentParam.Arguments,0);
                    fState := psCommand;
                  end;
  ttDelimiter,
  ttTerminator:   fState := psGeneral;
  ttGeneral:      begin
                    fImagePath := TCLPLexer(fLexer)[fTokenIndex].Str;
                    AddParam(ptGeneral,TCLPLexer(fLexer)[fTokenIndex].Str);
                    fState := psGeneral;
                  end;
end;
end;

//------------------------------------------------------------------------------

procedure TCLPParser.Process_Command;
begin
case TCLPLexer(fLexer)[fTokenIndex].TokenType of
  ttShortCommand: begin
                    AddParam(fCurrentParam);
                    fCurrentParam.ParamType := ptShortCommand;
                    fCurrentParam.Str := TCLPLexer(fLexer)[fTokenIndex].Str;
                    SetLength(fCurrentParam.Arguments,0);
                    fState := psCommand;
                  end;
  ttLongCommand:  begin
                    AddParam(fCurrentParam);
                    fCurrentParam.ParamType := ptLongCommand;
                    fCurrentParam.Str := TCLPLexer(fLexer)[fTokenIndex].Str;
                    SetLength(fCurrentParam.Arguments,0);
                    fState := psCommand;
                  end;
  ttDelimiter:    fState := psGeneral;
  ttTerminator:   begin
                    AddParam(fCurrentParam);
                    fState := psGeneral;
                  end;
  ttGeneral:      begin
                    SetLength(fCurrentParam.Arguments,Length(fCurrentParam.Arguments) + 1);
                    fCurrentParam.Arguments[High(fCurrentParam.Arguments)] := TCLPLexer(fLexer)[fTokenIndex].Str;
                    fState := psArgument;
                  end;
end;
end;

//------------------------------------------------------------------------------

procedure TCLPParser.Process_Argument;
begin
case TCLPLexer(fLexer)[fTokenIndex].TokenType of
  ttShortCommand: begin
                    AddParam(fCurrentParam);
                    fCurrentParam.ParamType := ptShortCommand;
                    fCurrentParam.Str := TCLPLexer(fLexer)[fTokenIndex].Str;
                    SetLength(fCurrentParam.Arguments,0);
                    fState := psCommand;
                  end;
  ttLongCommand:  begin
                    AddParam(fCurrentParam);
                    fCurrentParam.ParamType := ptLongCommand;
                    fCurrentParam.Str := TCLPLexer(fLexer)[fTokenIndex].Str;
                    SetLength(fCurrentParam.Arguments,0);
                    fState := psCommand;
                  end;
  ttDelimiter:    fState := psCommand;
  ttTerminator:   begin
                    AddParam(fCurrentParam);
                    fState := psGeneral;
                  end;
  ttGeneral:      begin
                    AddParam(fCurrentParam);
                    AddParam(ptGeneral,TCLPLexer(fLexer)[fTokenIndex].Str);
                    fState := psGeneral;
                  end;
end;
end;

//------------------------------------------------------------------------------

procedure TCLPParser.Process_General;
begin
case TCLPLexer(fLexer)[fTokenIndex].TokenType of
  ttShortCommand: begin
                    fCurrentParam.ParamType := ptShortCommand;
                    fCurrentParam.Str := TCLPLexer(fLexer)[fTokenIndex].Str;
                    SetLength(fCurrentParam.Arguments,0);
                    fState := psCommand;
                  end;
  ttLongCommand:  begin
                    fCurrentParam.ParamType := ptLongCommand;
                    fCurrentParam.Str := TCLPLexer(fLexer)[fTokenIndex].Str;
                    SetLength(fCurrentParam.Arguments,0);
                    fState := psCommand;
                  end;
  ttDelimiter,
  ttTerminator:   fState := psGeneral;
  ttGeneral:      begin
                    AddParam(ptGeneral,TCLPLexer(fLexer)[fTokenIndex].Str);
                    fState := psGeneral;
                  end;
end;
end;

{-------------------------------------------------------------------------------
    TCLPParser - public methods
-------------------------------------------------------------------------------}

constructor TCLPParser.CreateEmpty;
begin
inherited;
fCommandIntroChar := def_CommandIntroChar;
fQuoteChar := def_QuoteChar;
fDelimiterChar := def_DelimiterChar;
fCmdTerminateChar := def_CmdTerminateChar;
fCommandLine := '';
fImagePath := '';
SetLength(fParameters.Arr,0);
fParameters.Count := 0;
fLexer := TCLPLexer.Create;
fState := psInitial;
fTokenIndex := -1;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TCLPParser.Create(const CommandLine: String);
begin
CreateEmpty;
Parse(CommandLine);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TCLPParser.Create;
begin
{$WARN SYMBOL_PLATFORM OFF}
Create(WinToStr(System.CmdLine));
{$WARN SYMBOL_PLATFORM ON}
end;

//------------------------------------------------------------------------------

destructor TCLPParser.Destroy;
begin
Clear;
fLexer.Free;
inherited;
end;

//------------------------------------------------------------------------------

Function TCLPParser.LowIndex: Integer;
begin
Result := Low(fParameters.Arr);
end;

//------------------------------------------------------------------------------

Function TCLPParser.HighIndex: Integer;
begin
Result := Pred(fParameters.Count);
end;

//------------------------------------------------------------------------------

Function TCLPParser.First: TCLPParameter;
begin
Result := GetParameter(LowIndex);
end;

//------------------------------------------------------------------------------

Function TCLPParser.Last: TCLPParameter;
begin
Result := GetParameter(HighIndex);
end;

//------------------------------------------------------------------------------

Function TCLPParser.IndexOf(const Str: String; CaseSensitive: Boolean): Integer;
var
  i:  Integer;
begin
Result := -1;
If CaseSensitive then
  begin
    For i := HighIndex downto LowIndex do
      If AnsiSameStr(Str,fParameters.Arr[i].Str) then
        begin
          Result := i;
          Break{For i};
        end;
  end
else
  begin
    For i := HighIndex downto LowIndex do
      If AnsiSameText(Str,fParameters.Arr[i].Str) then
        begin
          Result := i;
          Break{For i};
        end;
  end;
end;

//------------------------------------------------------------------------------

Function TCLPParser.CommandPresent(ShortForm: Char): Boolean;
begin
Result := IndexOf(ShortForm,True) >= LowIndex;
end;

//------------------------------------------------------------------------------

Function TCLPParser.CommandPresent(const LongForm: String): Boolean;
begin
Result := IndexOf(LongForm,False) >= LowIndex;
end;

//------------------------------------------------------------------------------

Function TCLPParser.CommandPresent(ShortForm: Char; const LongForm: String): Boolean;
begin
Result := CommandPresent(ShortForm) or CommandPresent(LongForm);
end;

//------------------------------------------------------------------------------

Function TCLPParser.GetCommandData(ShortForm: Char; out CommandData: TCLPParameter): Boolean;
var
  Index:  Integer;
begin
Index := IndexOf(ShortForm,True);
If Index >= LowIndex then
  begin
    CommandData := fParameters.Arr[Index];
    Result := True;
  end
else Result := False;
end;

//------------------------------------------------------------------------------

Function TCLPParser.GetCommandData(const LongForm: String; out CommandData: TCLPParameter): Boolean;
var
  Index:  Integer;
begin
Index := IndexOf(LongForm,False);
If Index >= LowIndex then
  begin
    CommandData := fParameters.Arr[Index];
    Result := True;
  end
else Result := False;
end;

//------------------------------------------------------------------------------

Function TCLPParser.GetCommandData(ShortForm: Char; const LongForm: String; out CommandData: TCLPParameter): Boolean;
var
  SIndex, LIndex: Integer;
begin
SIndex := IndexOf(ShortForm,True);
LIndex := IndexOf(LongForm,False);
If (SIndex >= LowIndex) or (LIndex >= LowIndex) then
  begin
    If SIndex > LIndex then
      CommandData := fParameters.Arr[SIndex]
    else
      CommandData := fParameters.Arr[LIndex];
    Result := True;
  end
else Result := False;
end;

//------------------------------------------------------------------------------

Function TCLPParser.GetCommandCount: Integer;
var
  i:  Integer;
begin
Result := 0;
For i := LowIndex to HighIndex do
  If fParameters.Arr[i].ParamType in [ptShortCommand,ptLongCommand] then
    Inc(Result);
end;

//------------------------------------------------------------------------------

procedure TCLPParser.Clear;
begin
fCommandLine := '';
fImagePath := '';
fParameters.Count := 0;
SetLength(fParameters.Arr,0);
TCLPLexer(fLexer).Clear;
end;

//------------------------------------------------------------------------------

procedure TCLPParser.Parse(const CommandLine: String);
begin
fCommandLine := CommandLine;
ReParse;
end;

//------------------------------------------------------------------------------

procedure TCLPParser.ReParse;
begin
fImagePath := '';
fParameters.Count := 0;
TCLPLexer(fLexer).CommandIntroChar := fCommandIntroChar;
TCLPLexer(fLexer).QuoteChar := fQuoteChar;
TCLPLexer(fLexer).DelimiterChar := fDelimiterChar;
TCLPLexer(fLexer).CommandTerminateChar := fCmdTerminateChar;
TCLPLexer(fLexer).Analyze(fCommandLine);
fTokenIndex := 0;
while fTokenIndex <= Pred(TCLPLexer(fLexer).Count) do
  begin
    case fState of
      psInitial:  Process_Initial;
      psCommand:  Process_Command;
      psArgument: Process_Argument;
      psGeneral:  Process_General;
    else
      raise Exception.CreateFmt('TCLPParser.ReParse: Invalid parser state (%d).',[Ord(fState)]);
    end;
    Inc(fTokenIndex);
  end;
If fState in [psCommand,psArgument] then
  AddParam(fCurrentParam);
end;

end.

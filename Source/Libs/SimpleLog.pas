{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  SimpleLog

  ©František Milt 2018-10-22

  Version 1.3.9

  Dependencies:
    StrRect - github.com/ncs-sniper/Lib.StrRect

===============================================================================}
{$IFNDEF SimpleLog_Include}
unit SimpleLog;
{$ENDIF}

{$IF not(defined(MSWINDOWS) or defined(WINDOWS))}
  {$MESSAGE FATAL 'Unsupported operating system.'}
{$IFEND}

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
  {$DEFINE FPC_DisableWarns}
  {$MACRO ON}
{$ENDIF}

{$IF Defined(FPC) and not Defined(Unicode) and not Defined(BARE_FPC) and (FPC_FULLVERSION < 20701)}
  {$DEFINE UTF8Wrappers}
{$ELSE}
  {$UNDEF UTF8Wrappers}
{$IFEND}

interface

uses
  SysUtils, Classes, Contnrs, SyncObjs;

type
  TLogEvent = procedure(Sender: TObject; LogText: String) of Object;

{==============================================================================}
{    TSimpleLog // Class declaration                                           }
{==============================================================================}
  TSimpleLog = class(TObject)
  private
    fFormatSettings:          TFormatSettings;
    fTimeFormat:              String;
    fTimeSeparator:           String;
    fTimeOfCreation:          TDateTime;
    fBreaker:                 String;
    fTimeStamp:               String;
    fStartStamp:              String;
    fEndStamp:                String;
    fAppendStamp:             String;
    fHeader:                  String;
    fIndentNewLines:          Boolean;
    fThreadLocked:            Boolean;
    fInternalLog:             Boolean;
    fWriteToConsole:          Boolean;
    fStreamToFile:            Boolean;
    fConsoleBinded:           Boolean;
    fStreamAppend:            Boolean;
    fStreamFileName:          String;
    fStreamFileAccessRights:  Cardinal;
    fForceTime:               Boolean;
    fForcedTime:              TDateTIme;
    fLogCounter:              Integer;
    fThreadLock:              TCriticalSection;
    fInternalLogObj:          TStringList;
    fExternalLogs:            TObjectList;
    fStreamFile:              TFileStream;
    fConsoleBindFlag:         Integer;
    fOnLog:                   TLogEvent;
    procedure SetWriteToConsole(Value: Boolean);    
    procedure SetStreamToFile(Value: Boolean);
    procedure SetStreamFileName(Value: String);
    Function GetInternalLogCount: Integer;
    Function GetExternalLogsCount: Integer;    
    Function GetExternalLog(Index: Integer): TStrings;
  protected
    Function ReserveConsoleBind: Boolean; virtual;
    Function GetCurrentTime: TDateTime; virtual;
    Function GetDefaultStreamFileName: String; virtual;
    Function GetTimeAsStr(Time: TDateTime; const Format: String = '$'): String; virtual;
    procedure DoIndentNewLines(var Str: String; IndentCount: Integer); virtual;    
    procedure ProtectedAddLog(LogText: String; IndentCount: Integer = 0; LineBreak: Boolean = True); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ThreadLock; virtual;
    procedure ThreadUnlock; virtual;
    procedure AddLogNoTime(const Text: String); virtual;
    procedure AddLogTime(const Text: String; Time: TDateTime); virtual;
    procedure AddLog(const Text: String); virtual;
    procedure AddEmpty; virtual;
    procedure AddBreaker; virtual;
    procedure AddTimeStamp; virtual;
    procedure AddStartStamp; virtual;
    procedure AddEndStamp; virtual;
    procedure AddAppendStamp; virtual;
    procedure AddHeader; virtual;
    procedure ForceTimeSet(Time: TDateTime); virtual;
    Function InternalLogGetLog(LogIndex: Integer): String; virtual;
    Function InternalLogGetAsText: String; virtual;
    procedure InternalLogClear; virtual;
    Function InternalLogSaveToFile(const FileName: String; Append: Boolean = False): Boolean; virtual;
    Function InternalLogLoadFromFile(const FileName: String; Append: Boolean = False): Boolean; virtual;
    Function BindConsole: Boolean; virtual;
    procedure UnbindConsole; virtual;
    Function ExternalLogAdd(ExternalLog: TStrings): Integer; virtual;
    Function ExternalLogIndexOf(ExternalLog: TStrings): Integer; virtual;
    Function ExternalLogRemove(ExternalLog: TStrings): Integer; virtual;
    procedure ExternalLogDelete(Index: Integer); virtual;
    property FormatSettings: TFormatSettings read fFormatSettings write fFormatSettings;
    property ExternalLogs[Index: Integer]: TStrings read GetExternalLog; default;
    property TimeFormat: String read fTimeFormat write fTimeFormat;
    property TimeSeparator: String read fTimeSeparator write fTimeSeparator;
    property TimeOfCreation: TDateTime read fTimeOfCreation;
    property Breaker: String read fBreaker write fBreaker;
    property TimeStamp: String read fTimeStamp write fTimeStamp;
    property StartStamp: String read fStartStamp write fStartStamp;
    property EndStamp: String read fEndStamp write fEndStamp;
    property AppendStamp: String read fAppendStamp write fAppendStamp;
    property Header: String read fHeader write fHeader;
    property IndentNewLines: Boolean read fIndentNewLines write fIndentNewLines;
    property ThreadLocked: Boolean read fThreadLocked write fThreadLocked;
    property InternalLog: Boolean read fInternalLog write fInternalLog;
    property WriteToConsole: Boolean read fWriteToConsole write SetWriteToConsole;
    property StreamToFile: Boolean read fStreamToFile write SetStreamToFile;
    property ConsoleBinded: Boolean read fConsoleBinded write fConsoleBinded;
    property StreamAppend: Boolean read fStreamAppend write fStreamAppend;
    property StreamFileName: String read fStreamFileName write SetStreamFileName;
    property StreamFileAccessRights: Cardinal read fStreamFileAccessRights write fStreamFileAccessRights;
    property ForceTime: Boolean read fForceTime write fForceTime;
    property ForcedTime: TDateTIme read fForcedTime write fForcedTime;
    property LogCounter: Integer read fLogCounter;
    property InternalLogCount: Integer read GetInternalLogCount;
    property ExternalLogsCount: Integer read GetExternalLogsCount;
    property OnLog: TLogEvent read fOnLog write fOnLog;
  end;


{$IFDEF SimpleLog_Include}
var
  LogActive:      Boolean = False;
  LogFileName:    String = '';
{$ENDIF}

implementation

uses
  Windows, StrUtils, StrRect {$IFDEF UTF8Wrappers}, LazFileUtils {$ENDIF};

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W5057:={$WARN 5057 OFF}} // Local variable "$1" does not seem to be initialized
  {$PUSH}{$WARN 2005 OFF} // Comment level $1 found
  {$IF Defined(FPC) and (FPC_FULLVERSION >= 30000)}
    {$DEFINE W5092:={$WARN 5092 OFF}} // Variable "$1" of a managed type does not seem to be initialized
  {$ELSE}
    {$DEFINE W5092:=}
  {$IFEND}
  {$POP}
{$ENDIF}

Function _FileExists(const FileName: String): Boolean;
begin
{$IFDEF UTF8Wrappers}
Result := FileExistsUTF8(FileName);
{$ELSE}
Result := FileExists(FileName);
{$ENDIF}
end;

{==============================================================================}
{    TSimpleLog // Console binding                                             }
{==============================================================================}

type
  IOFunc = Function(var F: TTextRec): Integer;

const
  ERR_SUCCESS                 = 0;
  ERR_UNSUPPORTED_MODE        = 10;
  ERR_WRITE_FAILED            = 11;
  ERR_READ_FAILED             = 12;
  ERR_FLUSH_FUNC_NOT_ASSIGNED = 13;

  UDI_OUTFILE = 1;

  CBF_LOCKED   = 1;
  CBF_UNLOCKED = 0;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5057{$ENDIF}
Function SLCB_Output(var F: TTextRec): Integer;
var
  CharsWritten: DWord;
  StrBuffer:    AnsiString;
{$IFDEF Unicode}
  Text:         String;
begin
SetLength(StrBuffer,F.BufPos);
Move(F.Buffer,PAnsiChar(StrBuffer)^,F.BufPos * SizeOf(AnsiChar));
Text := String(StrBuffer);
If WriteConsoleW(F.Handle,PChar(Text),Length(Text),CharsWritten,nil) then
{$ELSE}
begin
If WriteConsoleA(F.Handle,F.BufPtr,F.BufPos,CharsWritten,nil) then
{$ENDIF}
  begin
    SetLength(StrBuffer,F.BufPos);
    Move(F.Buffer,PAnsiChar(StrBuffer)^,F.BufPos * SizeOf(AnsiChar));
  {$IFDEF Unicode}
    TSimpleLog(Addr(F.UserData[UDI_OUTFILE])^).ProtectedAddLog(AnsiToStr(StrBuffer),0,False);
  {$ELSE}
    TSimpleLog(Addr(F.UserData[UDI_OUTFILE])^).ProtectedAddLog(CslToStr(StrBuffer),0,False);
  {$ENDIF}
    Result := ERR_SUCCESS;
  end
else Result := ERR_WRITE_FAILED;
F.BufPos := 0;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5057{$ENDIF}
Function SLCB_Input(var F: TTextRec): Integer;
var
  CharsRead:  DWord;
  StrBuffer:  AnsiString;
{$IFDEF Unicode}
  Text:       String;
begin
SetLength(Text,F.BufSize);
If ReadConsoleW(F.Handle,PChar(Text),Length(Text),CharsRead,nil) then
  begin
    SetLength(Text,CharsRead);
    StrBuffer := StrToAnsi(Text);
    Move(PAnsiChar(StrBuffer)^,F.Buffer,Length(StrBuffer) * SizeOf(AnsiChar));
    TSimpleLog(Addr(F.UserData[UDI_OUTFILE])^).ProtectedAddLog(Text,0,False);
    F.BufEnd := Length(StrBuffer);
    Result := ERR_SUCCESS;
  end
{$ELSE}
begin
If ReadConsoleA(F.Handle,F.BufPtr,F.BufSize,CharsRead,nil) then
  begin
    SetLength(StrBuffer,CharsRead);
    Move(F.Buffer,PAnsiChar(StrBuffer)^,CharsRead * SizeOf(AnsiChar));
  {$IFDEF Unicode}
    TSimpleLog(Addr(F.UserData[UDI_OUTFILE])^).ProtectedAddLog(AnsiToStr(StrBuffer),0,False);
  {$ELSE}
    TSimpleLog(Addr(F.UserData[UDI_OUTFILE])^).ProtectedAddLog(CslToStr(StrBuffer),0,False);
  {$ENDIF}
    F.BufEnd := CharsRead;
    Result := ERR_SUCCESS;
  end
{$ENDIF}
else Result := ERR_READ_FAILED;
F.BufPos := 0;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

Function SLCB_Flush(var F: TTextRec): Integer;
begin
case F.Mode of
  fmOutput: begin
              If Assigned(F.InOutFunc) then IOFunc(F.InOutFunc)(F);
              Result := ERR_SUCCESS;
            end;
  fmInput:  begin
              F.BufPos := 0;
              F.BufEnd := 0;
              Result := ERR_SUCCESS;
            end;
else
  Result := ERR_UNSUPPORTED_MODE;
end;
end;

//------------------------------------------------------------------------------

Function SLCB_Open(var F: TTextRec): Integer;
begin
case F.Mode of
  fmOutput: begin
              F.Handle := GetStdHandle(STD_OUTPUT_HANDLE);
              F.InOutFunc := @SLCB_Output;
              Result := ERR_SUCCESS;
            end;
  fmInput:  begin
              F.Handle := GetStdHandle(STD_INPUT_HANDLE);
              F.InOutFunc := @SLCB_Input;
              Result := ERR_SUCCESS;
            end;
else
  Result := ERR_UNSUPPORTED_MODE;
end;
end;

//------------------------------------------------------------------------------

Function SLCB_Close(var F: TTextRec): Integer;
begin
If Assigned(F.FlushFunc) then
  Result := IOFunc(F.FlushFunc)(F)
else
  Result := ERR_FLUSH_FUNC_NOT_ASSIGNED;
F.Mode := fmClosed;
end;

//------------------------------------------------------------------------------

procedure AssignSLCB(var T: Text; LogObject: TSimpleLog);
begin
with TTextRec(T) do
  begin
    Mode := fmClosed;
  {$IFDEF FPC}
    LineEnd := sLineBreak;
  {$ELSE}
    Flags := tfCRLF;
  {$ENDIF}
    BufSize := SizeOf(Buffer);
    BufPos := 0;
    BufEnd := 0;
    BufPtr := @Buffer;
    OpenFunc := @SLCB_Open;
    FlushFunc := @SLCB_Flush;
    CloseFunc := @SLCB_Close;
    TSimpleLog(Addr(UserData[UDI_OUTFILE])^) := LogObject;
    Name := '';
  end;
end;

{==============================================================================}
{    TSimpleLog // Class implementation                                        }
{==============================================================================}

{------------------------------------------------------------------------------}
{    TSimpleLog // Constants                                                   }
{------------------------------------------------------------------------------}

const
  HeaderLines = '================================================================================';

//--- default settings ---
  def_TimeFormat             = 'yyyy-mm-dd hh:nn:ss.zzz';
  def_TimeSeparator          = ' //: ';
  def_Breaker                = '--------------------------------------------------------------------------------';
  def_TimeStamp              = def_Breaker + sLineBreak +  'TimeStamp: %s' + sLineBreak + def_Breaker;
  def_StartStamp             = def_Breaker + sLineBreak +  '%s - Starting log' + sLineBreak + def_Breaker;
  def_EndStamp               = def_Breaker + sLineBreak +  '%s - Ending log' + sLineBreak + def_Breaker;
  def_AppendStamp            = def_Breaker + sLineBreak +  '%s - Appending log' + sLineBreak + def_Breaker;
  def_Header                 = HeaderLines + sLineBreak +
                               '              Created by SimpleLog 1.3, (c)2015-2017 Frantisek Milt' +
                               sLineBreak + HeaderLines;
  def_IndentNewLines         = False;
  def_ThreadLocked           = False;
  def_InternalLog            = True;
  def_WriteToConsole         = False;
  def_StreamToFile           = False;
  def_StreamAppend           = False;
  def_StreamFileAccessRights = fmShareDenyWrite;
  def_ForceTime              = False;


{------------------------------------------------------------------------------}
{    TSimpleLog // Private routines                                            }
{------------------------------------------------------------------------------}

procedure TSimpleLog.SetWriteToConsole(Value: Boolean);
begin
If not fConsoleBinded then fWriteToConsole := Value;
end;

//------------------------------------------------------------------------------

procedure TSimpleLog.SetStreamToFile(Value: Boolean);
begin
If fStreamToFile <> Value then
  If fStreamToFile then
    begin
      FreeAndNil(fStreamFile);
      fStreamToFile := Value;
    end
  else
    begin
      If _FileExists(fStreamFileName) then
        fStreamFile := TFileStream.Create(StrToRTL(fStreamFileName),fmOpenReadWrite or fStreamFileAccessRights)
      else
        fStreamFile := TFileStream.Create(StrToRTL(fStreamFileName),fmCreate or fStreamFileAccessRights);
      If fStreamAppend then fStreamFile.Seek(0,soEnd)
        else fStreamFile.Size := 0;
      fStreamToFile := Value;
    end;
end;

//------------------------------------------------------------------------------

procedure TSimpleLog.SetStreamFileName(Value: String);
begin
If Value = '' then Value := GetDefaultStreamFileName;
If not AnsiSameText(fStreamFileName,Value) then
  begin
    If fStreamToFile then
      begin
        fStreamFileName := Value;
        FreeAndNil(fStreamFile);
        If _FileExists(fStreamFileName) then
          fStreamFile := TFileStream.Create(StrToRTL(fStreamFileName),fmOpenReadWrite or fStreamFileAccessRights)
        else
          fStreamFile := TFileStream.Create(StrToRTL(fStreamFileName),fmCreate or fStreamFileAccessRights);
        If fStreamAppend then fStreamFile.Seek(0,soEnd)
          else fStreamFile.Size := 0;
      end
    else fStreamFileName := Value;
  end;
end;

//------------------------------------------------------------------------------

Function TSimpleLog.GetInternalLogCount: Integer;
begin
Result := fInternalLogObj.Count;
end;

//------------------------------------------------------------------------------

Function TSimpleLog.GetExternalLogsCount: Integer;
begin
Result := fExternalLogs.Count;
end;

//------------------------------------------------------------------------------

Function TSimpleLog.GetExternalLog(Index: Integer): TStrings;
begin
If (Index >= 0) and (Index < fExternalLogs.Count) then
  Result := TStrings(fExternalLogs[Index])
else
 raise exception.CreateFmt('TSimpleLog.GetExternalLog: Index (%d) out of bounds.',[Index]);
end;

{------------------------------------------------------------------------------}
{    TSimpleLog // Protected routines                                          }
{------------------------------------------------------------------------------}

Function TSimpleLog.ReserveConsoleBind: Boolean;
begin
Result := InterlockedExchange(fConsoleBindFlag,CBF_LOCKED) = CBF_UNLOCKED;
end;

//------------------------------------------------------------------------------

Function TSimpleLog.GetCurrentTime: TDateTime;
begin
If ForceTime then Result := ForcedTime
  else Result := Now;
end;

//------------------------------------------------------------------------------

Function TSimpleLog.GetDefaultStreamFileName: String;
begin
Result := RTLToStr(ParamStr(0)) + '[' + GetTimeAsStr(fTimeOfCreation,'YYYY-MM-DD-HH-NN-SS') + '].log';
end;

//------------------------------------------------------------------------------

Function TSimpleLog.GetTimeAsStr(Time: TDateTime; const Format: String = '$'): String;
begin
If Format <> '$' then DateTimeToString(Result,Format,Time,fFormatSettings)
  else DateTimeToString(Result,fTimeFormat,Time,fFormatSettings);
end;

//------------------------------------------------------------------------------

procedure TSimpleLog.DoIndentNewLines(var Str: String; IndentCount: Integer);
begin
If (IndentCount > 0) and AnsiContainsStr(Str,sLineBreak) then
  Str := AnsiReplaceStr(Str,sLineBreak,sLineBreak + StringOfChar(' ',IndentCount));
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5092{$ENDIF}
procedure TSimpleLog.ProtectedAddLog(LogText: String; IndentCount: Integer = 0; LineBreak: Boolean = True);
var
  i:    Integer;
  Temp: String;
begin
If fIndentNewLines then DoIndentNewLines(LogText,IndentCount);
If fWriteToConsole and System.IsConsole then WriteLn(StrToCsl(LogText));
If fInternalLog then fInternalLogObj.Add(LogText);
For i := 0 to Pred(fExternalLogs.Count) do TStrings(fExternalLogs[i]).Add(LogText);
If fStreamToFile then
  begin
    If LineBreak then
      begin
        Temp := LogText + sLineBreak;
        fStreamFile.WriteBuffer(PChar(Temp)^, Length(Temp) * SizeOf(Char));
      end
    else fStreamFile.WriteBuffer(PChar(LogText)^, Length(LogText) * SizeOf(Char));
  end;
Inc(fLogCounter);
If Assigned(fOnLog) then fOnLog(Self,LogText);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}
{    TSimpleLog // Public routines                                             }
{------------------------------------------------------------------------------}

constructor TSimpleLog.Create;
begin
inherited Create;
{$WARN SYMBOL_PLATFORM OFF}
{$IF not Defined(FPC) and (CompilerVersion >= 18)} // Delphi 2006 (not sure about that)
fFormatSettings := TFormatSettings.Create(LOCALE_USER_DEFAULT);
{$ELSE}
GetLocaleFormatSettings(LOCALE_USER_DEFAULT,fFormatSettings);
{$IFEND}
{$WARN SYMBOL_PLATFORM ON}
fTimeFormat := def_TimeFormat;
fTimeSeparator := def_TimeSeparator;
fTimeOfCreation := Now;
fBreaker := def_Breaker;
fTimeStamp := def_TimeStamp;
fStartStamp := def_StartStamp;
fEndStamp := def_EndStamp;
fAppendStamp := def_AppendStamp;
fHeader := def_Header;
fIndentNewLines := def_IndentNewLines;
fThreadLocked := def_ThreadLocked;
fInternalLog := def_InternalLog;
fWriteToConsole := def_WriteToConsole;
fStreamToFile := def_StreamToFile;
fConsoleBinded := False;
fStreamAppend := def_StreamAppend;
fStreamFileName := GetDefaultStreamFileName;
fStreamFileAccessRights := def_StreamFileAccessRights;
fForceTime := def_ForceTime;
fForcedTime := Now;
fLogCounter := 0;
fThreadLock := SyncObjs.TCriticalSection.Create;
fInternalLogObj := TStringList.Create;
fExternalLogs := TObjectList.Create(False);
fConsoleBindFlag := CBF_UNLOCKED;
fStreamFile := nil;
end;

//------------------------------------------------------------------------------

destructor TSimpleLog.Destroy;
begin
If Assigned(fStreamFile) then FreeAndNil(fStreamFile);
fExternalLogs.Free;
fInternalLogObj.Free;
fThreadLock.Free;
inherited;
end;

//------------------------------------------------------------------------------

procedure TSimpleLog.ThreadLock;
begin
fThreadLock.Enter;
end;

//------------------------------------------------------------------------------

procedure TSimpleLog.ThreadUnlock;
begin
fThreadLock.Leave;
end;

//------------------------------------------------------------------------------

procedure TSimpleLog.AddLogNoTime(const Text: String);
begin
If fThreadLocked then
  begin
    fThreadLock.Enter;
    try
      ProtectedAddLog(Text);
    finally
      fThreadLock.Leave;
    end;
  end
else ProtectedAddLog(Text);
end;

//------------------------------------------------------------------------------

procedure TSimpleLog.AddLogTime(const Text: String; Time: TDateTime);
var
  TimeStr:  String;
begin
TimeStr := GetTimeAsStr(Time) + fTimeSeparator;
If fThreadLocked then
  begin
    fThreadLock.Enter;
    try
      ProtectedAddLog(TimeStr + Text,Length(TimeStr));
    finally
      fThreadLock.Leave;
    end;
  end
else ProtectedAddLog(TimeStr + Text,Length(TimeStr));
end;

//------------------------------------------------------------------------------

procedure TSimpleLog.AddLog(const Text: String);
begin
AddLogTime(Text,GetCurrentTime);
end;

//------------------------------------------------------------------------------

procedure TSimpleLog.AddEmpty;
begin
AddLogNoTime('');
end;

//------------------------------------------------------------------------------

procedure TSimpleLog.AddBreaker;
begin
AddLogNoTime(fBreaker);
end;

//------------------------------------------------------------------------------

procedure TSimpleLog.AddTimeStamp;
begin
AddLogNoTime(Format(fTimeStamp,[GetTimeAsStr(GetCurrentTime)]));
end;

//------------------------------------------------------------------------------

procedure TSimpleLog.AddStartStamp;
begin
AddLogNoTime(Format(fStartStamp,[GetTimeAsStr(GetCurrentTime)]));
end;

//------------------------------------------------------------------------------

procedure TSimpleLog.AddEndStamp;
begin
AddLogNoTime(Format(fEndStamp,[GetTimeAsStr(GetCurrentTime)]));
end;

//------------------------------------------------------------------------------

procedure TSimpleLog.AddAppendStamp;
begin
AddLogNoTime(Format(fAppendStamp,[GetTimeAsStr(GetCurrentTime)]));
end;
 
//------------------------------------------------------------------------------

procedure TSimpleLog.AddHeader;
begin
AddLogNoTime(fHeader);
end;

//------------------------------------------------------------------------------

procedure TSimpleLog.ForceTimeSet(Time: TDateTime);
begin
fForcedTime := Time;
fForceTime := True;
end;

//------------------------------------------------------------------------------

Function TSimpleLog.InternalLogGetLog(LogIndex: Integer): String;
begin
If (LogIndex >= 0) and (LogIndex < fInternalLogObj.Count) then
  Result := fInternalLogObj[LogIndex]
else
  Result := '';
end;

//------------------------------------------------------------------------------

Function TSimpleLog.InternalLogGetAsText: String;
begin
Result := fInternalLogObj.Text;
end;
   
//------------------------------------------------------------------------------

procedure TSimpleLog.InternalLogClear;
begin
fInternalLogObj.Clear;
end;
  
//------------------------------------------------------------------------------

Function TSimpleLog.InternalLogSaveToFile(const FileName: String; Append: Boolean = False): Boolean;
var
  FileStream:   TFileStream;
  StringBuffer: String;
begin
try
  If _FileExists(FileName) then
    FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenReadWrite or fmShareDenyWrite)
  else
    FileStream := TFileStream.Create(StrToRTL(FileName),fmCreate or fmShareDenyWrite);
  try
    If Append then FileStream.Seek(0,soEnd)
      else FileStream.Size := 0;
    StringBuffer := fInternalLogObj.Text;
    FileStream.WriteBuffer(PChar(StringBuffer)^,Length(StringBuffer) * SizeOf(Char));
  finally
    FileStream.Free;
  end;
  Result := True;
except
  Result := False;
end;
end;
    
//------------------------------------------------------------------------------

Function TSimpleLog.InternalLogLoadFromFile(const FileName: String; Append: Boolean = False): Boolean;
var
  FileStream:   TFileStream;
  StringBuffer: String;
begin
try
  FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
  try
    If not Append then fInternalLogObj.Clear;
    FileStream.Position := 0;
    SetLength(StringBuffer,FileStream.Size div SizeOf(Char));
    FileStream.ReadBuffer(PChar(StringBuffer)^,Length(StringBuffer) * SizeOf(Char));
    fInternalLogObj.Text := fInternalLogObj.Text + StringBuffer;
  finally
    FileStream.Free;
  end;
  Result := True;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function TSimpleLog.BindConsole: Boolean;
begin
If not fConsoleBinded and System.IsConsole and ReserveConsoleBind then
  begin
    fWriteToConsole := False;
    AssignSLCB(ErrOutput,Self);
    Rewrite(ErrOutput);
    AssignSLCB(Output,Self);
    Rewrite(Output);
    AssignSLCB(Input,Self);
    Reset(Input);
    fConsoleBinded := True;
  end;
Result := fConsoleBinded;
end;

//------------------------------------------------------------------------------

procedure TSimpleLog.UnbindConsole;
begin
If fConsoleBinded then
  begin
    Close(Input);
    Close(Output);
    Close(ErrOutput);
    fConsoleBinded := False;
    InterlockedExchange(fConsoleBindFlag,CBF_UNLOCKED);
  end;
end;

//------------------------------------------------------------------------------

Function TSimpleLog.ExternalLogAdd(ExternalLog: TStrings): Integer;
begin
Result := fExternalLogs.Add(ExternalLog);
end;
     
//------------------------------------------------------------------------------

Function TSimpleLog.ExternalLogIndexOf(ExternalLog: TStrings): Integer;
begin
Result := fExternalLogs.IndexOf(ExternalLog);
end;
     
//------------------------------------------------------------------------------

Function TSimpleLog.ExternalLogRemove(ExternalLog: TStrings): Integer;
begin
Result := fExternalLogs.IndexOf(ExternalLog);
If Result >= 0 then ExternalLogDelete(Result);
end;
    
//------------------------------------------------------------------------------

procedure TSimpleLog.ExternalLogDelete(Index: Integer);
begin
If (Index >= 0) and (Index < fExternalLogs.Count) then
  fExternalLogs.Delete(Index)
else
 raise exception.CreateFmt('TSimpleLog.ExternalLogDelete: Index (%d) out of bounds.',[Index]);
end;

{$IFNDEF SimpleLog_Include}
{$WARNINGS OFF}
end.
{$ENDIF}

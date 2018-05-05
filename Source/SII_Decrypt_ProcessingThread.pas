{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decrypt_ProcessingThread;

{$INCLUDE '.\SII_Decrypt_defs.inc'}

interface

uses
  Classes, SII_Decrypt_Decryptor;

{===============================================================================
--------------------------------------------------------------------------------
                           TSII_DecryptProcessThread
--------------------------------------------------------------------------------
===============================================================================}

const
  SII_DPT_OPTID_INMEMPROC = 0;
  SII_DPT_OPTID_ACCELAES  = 1;
  SII_DPT_OPTID_NODECODE  = 2;

{===============================================================================
    TSII_DecryptProcessThread - declaration
===============================================================================}
type
  TSII_DecryptProcessThread = class(TTHread)
  private
    fInputFile:     String;
    fOutputFile:    String;
    fDecryptor:     TSII_Decryptor;
    fProgress_sync: Double;
    fErrorText:     String;
    fOnProgress:    TSII_ProgressEvent;
    fOpt_InMemProc: Boolean;
    fOpt_NoDecode:  Boolean;
    procedure SetOption(Option: Integer; Value: Boolean); virtual;
  protected
    procedure sync_DoProgress; virtual;
    procedure DecryptorProgressHandler(Sender: TObject; Progress: Double); virtual;
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Run; virtual;
    property InputFile: String read fInputFile write fInputFile;
    property OutputFile: String read fOutputFile write fOutputFile;
    property OnProgress: TSII_ProgressEvent read fOnProgress write fOnProgress;
    property ErrorText: String read fErrorText;
    property Opt_InMemoryProcess: Boolean index SII_DPT_OPTID_INMEMPROC write SetOption;
    property Opt_AcceleratedAES: Boolean index SII_DPT_OPTID_ACCELAES write SetOption;
    property Opt_NoDecode: Boolean index SII_DPT_OPTID_NODECODE write SetOption;
  end;

implementation

uses
  SysUtils, Math;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
{$ENDIF}

{===============================================================================
--------------------------------------------------------------------------------
                           TSII_DecryptProcessThread
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    TSII_DecryptProcessThread - implementation
===============================================================================}

{-------------------------------------------------------------------------------
    TSII_DecryptProcessThread - private methods
-------------------------------------------------------------------------------}

procedure TSII_DecryptProcessThread.SetOption(Option: Integer; Value: Boolean);
begin
case Option of
  SII_DPT_OPTID_INMEMPROC:  fOpt_InMemProc := Value;
  SII_DPT_OPTID_ACCELAES:   fDecryptor.AcceleratedAES := Value;
  SII_DPT_OPTID_NODECODE:   fOpt_NoDecode := Value;
end;
end;

{-------------------------------------------------------------------------------
    TSII_DecryptProcessThread - protected methods
-------------------------------------------------------------------------------}

procedure TSII_DecryptProcessThread.sync_DoProgress;
begin
If Assigned(fOnProgress) then
  fOnProgress(Self,fProgress_sync);
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TSII_DecryptProcessThread.DecryptorProgressHandler(Sender: TObject; Progress: Double);
begin
// limit number of synchronization to 1000
If not SameValue(Progress,fProgress_sync,1e-3) then
  begin
    fProgress_sync := Progress;
    Synchronize(sync_DoProgress);
  end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

procedure TSII_DecryptProcessThread.Execute;
var
  DecryptorResult:  TSIIResult;
begin
try
  If fOpt_NoDecode then
    begin
      If fOpt_InMemProc then
        DecryptorResult := fDecryptor.DecryptFileInMemory(fInputFile,fOutputFile)
      else
        DecryptorResult := fDecryptor.DecryptFile(fInputFile,fOutputFile);
    end
  else
    begin
      If fOpt_InMemProc then
        DecryptorResult := fDecryptor.DecryptAndDecodeFileInMemory(fInputFile,fOutputFile)
      else
        DecryptorResult := fDecryptor.DecryptAndDecodeFile(fInputFile,fOutputFile);
    end;
  If DecryptorResult = rSuccess then
    begin
      fErrorText := 'Success';
      DecryptorProgressHandler(Self,2.0);
    end
  else raise Exception.CreateFmt('Decryptor failed with message: %s',[GetResultAsText(DecryptorResult)]);
except
  on E: Exception do
    begin
      fErrorText := E.Message;
      DecryptorProgressHandler(Self,-1.0);
    end;
end;
end;

{-------------------------------------------------------------------------------
    TSII_DecryptProcessThread - public methods
-------------------------------------------------------------------------------}

constructor TSII_DecryptProcessThread.Create;
begin
inherited Create(True);
FreeOnTerminate := True;
fInputFile := '';
fOutputfile := '';
fDecryptor := TSII_Decryptor.Create;
fDecryptor.OnProgress := DecryptorProgressHandler;
fProgress_sync := 0.0;
fErrorText := '';
fOnProgress := nil;
fOpt_InMemProc := True;
fOpt_NoDecode := False;
end;

//------------------------------------------------------------------------------

destructor TSII_DecryptProcessThread.Destroy;
begin
fDecryptor.Free;
inherited;
end;

//------------------------------------------------------------------------------

procedure TSII_DecryptProcessThread.Run;
begin
UniqueString(fInputFile);
UniqueString(fOutputFile);
{$IF Defined(FPC) or (CompilerVersion >= 21)} // Delphi 2010+
Start;
{$ELSE}
Resume;
{$IFEND}
end;

end.

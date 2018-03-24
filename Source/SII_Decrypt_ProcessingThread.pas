unit SII_Decrypt_ProcessingThread;

interface

uses
  Classes, SII_Decrypt_Decryptor;

type
  TSII_DecryptProcessThread = class(TTHread)
  private
    fInputFile:     String;
    fOutputFile:    String;
    fDecryptor:     TSII_Decryptor;
    fProgress_sync: Single;
    fErrorText:     String;
    fOnProgress:    TSII_ProgressEvent;
  protected
    procedure sync_DoProgress; virtual;
    procedure DecryptorProgressHandler(Sender: TObject; Progress: Single); virtual;
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Run; virtual;
    property InputFile: String read fInputFile write fInputFile;
    property OutputFile: String read fOutputFile write fOutputFile;
    property OnProgress: TSII_ProgressEvent read fOnProgress write fOnProgress;
    property ErrorText: String read fErrorText;
  end;

implementation

uses
  SysUtils, Math;

procedure TSII_DecryptProcessThread.sync_DoProgress;
begin
If Assigned(fOnProgress) then
  fOnProgress(Self,fProgress_sync);
end;

//------------------------------------------------------------------------------

procedure TSII_DecryptProcessThread.DecryptorProgressHandler(Sender: TObject; Progress: Single);
begin
// limit number of synchronization to 1000
If not SameValue(Progress,fProgress_sync,1e-3) then
  begin
    fProgress_sync := Progress;
    Synchronize(sync_DoProgress);
  end;
end;

//------------------------------------------------------------------------------

procedure TSII_DecryptProcessThread.Execute;
var
  DecryptorResult:  TSIIResult;
begin
try
  DecryptorResult := fDecryptor.DecryptAndDecodeFile(fInputFile,fOutputFile);
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

//==============================================================================

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
{$IF Defined(FPC) or (CompilerVersion >= 21)} // Delphi 2010+
Start;
{$ELSE}
Resume;
{$IFEND}
end;

end.

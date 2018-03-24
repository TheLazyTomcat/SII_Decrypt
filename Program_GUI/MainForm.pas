unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, XPMan, ComCtrls,
  SII_Decrypt_ProcessingThread;

type
  TfMainForm = class(TForm)
    leInputFile: TLabeledEdit;
    btnBrowseInFile: TButton;
    oXPManifest: TXPManifest;
    leOutputFile: TLabeledEdit;
    btnBrowseOutFile: TButton;
    bvlHor_Progress: TBevel;
    lblProgress: TLabel;
    pbProgress: TProgressBar;
    sbStatusBar: TStatusBar;
    diaOpenInputFile: TOpenDialog;
    diaSaveOutputFile: TSaveDialog;
    btnStartProcessing: TButton;
    gbOptions: TGroupBox;
    cbNoDecode: TCheckBox;
    cbAccelAES: TCheckBox;
    cbInMemProc: TCheckBox;
    procedure FormCreate(Sender: TObject);    
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnBrowseInFileClick(Sender: TObject);
    procedure btnBrowseOutFileClick(Sender: TObject);
    procedure btnStartProcessingClick(Sender: TObject);
  private
    { Private declarations }
  protected
    ProcessingThread: TSII_DecryptProcessThread;
    procedure ProgressHandler(Sender: TObject; Progress: Single);
    procedure EnableOptions(Enable: Boolean);
  public
    { Public declarations }
  end;

var
  fMainForm: TfMainForm;

implementation

{$R *.dfm}

uses
  TaskbarProgress;

procedure TfMainForm.ProgressHandler(Sender: TObject; Progress: Single);
var
  TempStr:  String;
  NewPos:   Integer;
begin
If Progress > 1.0 then
  begin
    // process finished
    pbProgress.Position := pbProgress.Max;
    btnStartProcessing.Enabled := True;
    EnableOptions(True);
    SetTaskbarProgressState(tpsNoProgress);
    MessageDlg('File succesfully decrypted/decoded.',mtInformation,[mbOk],0);
    ProcessingThread := nil;
  end
else If Progress < 0.0 then
  begin
    // error in processing
    pbProgress.Position := pbProgress.Max;
    btnStartProcessing.Enabled := True;
    EnableOptions(True);
    SetTaskbarProgressState(tpsError);
    TempStr := ProcessingThread.ErrorText;
    UniqueString(TempStr);
    MessageDlg('An error has occured during processing:' +
               sLineBreak + sLineBreak + TempStr,mtError,[mbOk],0);
    ProcessingThread := nil;
  end
else
  begin
    // normal progress
    NewPos := Trunc(pbProgress.Max * Progress);
    If NewPos <> pbProgress.Position then
      begin
        pbProgress.Position := NewPos;
        SetTaskbarProgressValue(Progress);
      end;
  end;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.EnableOptions(Enable: Boolean);
begin
gbOptions.Enabled := Enable;
cbNoDecode.Enabled := Enable;
cbAccelAES.Enabled := Enable;
cbInMemProc.Enabled := Enable;
end;

//==============================================================================

procedure TfMainForm.FormCreate(Sender: TObject);
begin
sbStatusBar.DoubleBuffered := True;
SetTaskbarProgressState(tpsNoProgress);
end;

//------------------------------------------------------------------------------

procedure TfMainForm.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
If Assigned(ProcessingThread) then
  begin
    If MessageDlg('Processing thread is still running. ' +
                  'You can kill it now, bu you risk data corruption.' + sLineBreak +
                  'Kill the thread now?',mtWarning,[mbYes,mbNo],0) = mrYes then
      begin
        // kill the thread
        TerminateThread(ProcessingThread.Handle,0);
        CanClose := True;
      end
    else CanClose := False;
  end
else CanClose := True;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.btnBrowseInFileClick(Sender: TObject);
begin
If diaOpenInputFile.Execute then
  leInputFile.Text := diaOpenInputFile.FileName;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.btnBrowseOutFileClick(Sender: TObject);
begin
If diaSaveOutputFile.Execute then
  leOutputFile.Text := diaSaveOutputFile.FileName;
end;

//------------------------------------------------------------------------------

procedure TfMainForm.btnStartProcessingClick(Sender: TObject);
begin
If leInputFile.Text <> '' then
  begin
    btnStartProcessing.Enabled := False;
    EnableOptions(False);
    SetTaskbarProgressValue(0.0);
    SetTaskbarProgressState(tpsNormal);
    // create, set up and run processing thread
    ProcessingThread := TSII_DecryptProcessThread.Create;
    ProcessingThread.InputFile := leInputFile.Text;
    If leOutputFile.Text <> '' then
      ProcessingThread.OutputFile := leOutputFile.Text
    else
      ProcessingThread.OutputFile := leInputFile.Text;
    ProcessingThread.OnProgress := ProgressHandler;
    ProcessingThread.Opt_InMemoryProcess := cbInMemProc.Checked;
    ProcessingThread.Opt_AcceleratedAES := cbAccelAES.Checked;
    ProcessingThread.Opt_NoDecode := cbNoDecode.Checked;
    ProcessingThread.Run;
  end
else MessageDlg('No input file selected.',mtError,[mbOk],0);
end;

end.


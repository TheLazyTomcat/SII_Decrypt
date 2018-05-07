{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit MainForm;

{$INCLUDE '..\Source\SII_Decrypt_defs.inc'}

interface

uses
  Windows, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, {$IFNDEF FPC}XPMan,{$ENDIF} ComCtrls,
  SII_Decrypt_ProcessingThread;

type
  TfMainForm = class(TForm)
    leInputFile: TLabeledEdit;
    btnBrowseInFile: TButton;
  {$IFNDEF FPC}
    oXPManifest: TXPManifest;
  {$ENDIF}
    leOutputFile: TLabeledEdit;
    btnBrowseOutFile: TButton;
    bvlHor_Progress: TBevel;
    lblProgress: TLabel;
    pbProgress: TProgressBar;
    stbStatusBar: TStatusBar;
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
    procedure ProgressHandler(Sender: TObject; Progress: Double);
    procedure EnableOptions(Enable: Boolean);
  public
    { Public declarations }
  end;

var
  fMainForm: TfMainForm;

implementation

{$IFDEF FPC}
  {$R *.lfm}
{$ELSE}
  {$R *.dfm}
{$ENDIF}

uses
  WinTaskbarProgress, WinFileInfo, StrRect;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
{$ENDIF}

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TfMainForm.ProgressHandler(Sender: TObject; Progress: Double);
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
    MessageDlg('File successfully decrypted/decoded.',mtInformation,[mbOk],0);
    ProcessingThread.OnProgress := nil;
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
    MessageDlg('An error has occurred during processing:' +
               sLineBreak + sLineBreak + TempStr,mtError,[mbOk],0);
    ProcessingThread.OnProgress := nil;               
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
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

procedure TfMainForm.EnableOptions(Enable: Boolean);
begin
gbOptions.Enabled := Enable;
cbNoDecode.Enabled := Enable;
cbAccelAES.Enabled := Enable;
cbInMemProc.Enabled := Enable;
end;

//==============================================================================

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TfMainForm.FormCreate(Sender: TObject);
begin
stbStatusBar.DoubleBuffered := True;
SetTaskbarProgressState(tpsNoProgress);
// load copyright
with TWinFileInfo.Create(WFI_LS_LoadVersionInfo or WFI_LS_LoadFixedFileInfo or WFI_LS_DecodeFixedFileInfo) do
  begin
    stbStatusBar.Panels[0].Text :=
      VersionInfoValues[VersionInfoTranslations[0].LanguageStr,'LegalCopyright'] + ', version ' +
      VersionInfoValues[VersionInfoTranslations[0].LanguageStr,'ProductVersion'] + ' (' +
      {$IFDEF FPC}'L'{$ELSE}'D'{$ENDIF}{$IFDEF x64}+ '64'{$ELSE}+ '32'{$ENDIF} + 
      ' #' + IntToStr(VersionInfoFixedFileInfoDecoded.FileVersionMembers.Build)
      {$IFDEF Debug}+ ' debug'{$ENDIF} + ')';
    Free;
  end;
// set up initial folders for dialogs
diaOpenInputFile.InitialDir := ExtractFileDir(RTLToStr(ParamStr(0)));
diaSaveOutputFile.InitialDir := ExtractFileDir(RTLToStr(ParamStr(0)));
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
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
        If Assigned(ProcessingThread) then
          TerminateThread(ProcessingThread.Handle,0);
        CanClose := True;
      end
    else CanClose := False;
  end
else CanClose := True;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------
 
{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TfMainForm.btnBrowseInFileClick(Sender: TObject);
begin
If diaOpenInputFile.Execute then
  leInputFile.Text := diaOpenInputFile.FileName;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------
 
{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TfMainForm.btnBrowseOutFileClick(Sender: TObject);
begin
If diaSaveOutputFile.Execute then
  leOutputFile.Text := diaSaveOutputFile.FileName;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------
   
{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
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
{$IFDEF FPCDWM}{$POP}{$ENDIF}

end.


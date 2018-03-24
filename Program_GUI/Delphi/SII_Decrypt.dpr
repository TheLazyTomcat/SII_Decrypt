program SII_Decrypt;

uses
  Forms,
  MainForm in '..\MainForm.pas' {fMainForm},
  SII_Decrypt_ProcessingThread in '..\..\Source\SII_Decrypt_ProcessingThread.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfMainForm, fMainForm);
  Application.Run;
end.

{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decrypt_Tester_Program;

interface

uses
  SII_Decrypt_Tester_Main;

procedure TestOnFile(const CommnadLine: String; TestFileEntry: TTestFileEntry);

implementation

uses
  Windows, SysUtils,
  StrRect, CRC32;

procedure TestOnFile(const CommnadLine: String; TestFileEntry: TTestFileEntry);
const
  BELOW_NORMAL_PRIORITY_CLASS = $00004000;
var
  SecurityAttr: TSecurityAttributes;
  StartInfo:    TStartupInfo;
  ProcessInfo:  TProcessInformation;
  ExitCode:     DWORD;
begin
WriteLn(CommnadLine);

SecurityAttr.nLength := SizeOf(TSecurityAttributes);
SecurityAttr.lpSecurityDescriptor := nil;
SecurityAttr.bInheritHandle := True;
FillChar(StartInfo,SizeOf(TStartupInfo),0);
StartInfo.cb := SizeOf(TStartupInfo);
StartInfo.dwFlags := STARTF_USESHOWWINDOW;
StartInfo.wShowWindow := SW_HIDE;
WriteLn;
If CreateProcess(nil,PChar(CommnadLine),@SecurityAttr,@SecurityAttr,True,
                 BELOW_NORMAL_PRIORITY_CLASS,nil,nil,StartInfo,ProcessInfo) then
  begin
    WaitForSingleObject(ProcessInfo.hProcess,INFINITE);
    GetExitCodeProcess(ProcessInfo.hProcess,ExitCode);
    CloseHandle(ProcessInfo.hThread);
    CloseHandle(ProcessInfo.hProcess);
  end;
WriteLn;
Write('  ExitCode: ',ExitCode);
If FileExists(StrToRTL(TestFileEntry.FileName + '.out')) then
  begin
    WriteLn('  ',SameCRC32(FileCRC32(TestFileEntry.FileName + '.out'),TestFileEntry.TextCRC32));
    DeleteFile(StrToRTL(TestFileEntry.FileName + '.out'));
  end
else WriteLn;
end;

end.

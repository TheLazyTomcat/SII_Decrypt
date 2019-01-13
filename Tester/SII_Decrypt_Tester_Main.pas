{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decrypt_Tester_Main;

interface

uses
  CRC32;

type
  TTestFileEntry = record
    FileName:   String;
    FileFormat: Integer;
    BinCRC32:   TCRC32;
    TextCRC32:  TCRC32
  end;

procedure Main;

implementation

uses
  SysUtils, Classes,
  StrRect, IniFileEx, SimpleLog_LogConsole,
  SII_Decrypt_Library_Header, SII_Decrypt_Tester_LibraryDirect,
  SII_Decrypt_Tester_Library, SII_Decrypt_Tester_Program;

procedure Main;
const
{$IFDEF FPC}
  PathPrefix = '..\..\..\';
{$ELSE}
  PathPrefix = '..\..\';
{$ENDIF}
  TestFilesPrefix = PathPrefix + 'TestFiles\';
  TestFilesList = 'test_files_list.ini';
{$IFDEF FPC}
  {$IF SizeOf(Pointer) = 8}
  LibraryPath = PathPrefix + 'Library\Lazarus\Release\win_x64\SII_Decrypt.dll';
  ExecPath    = PathPrefix + 'Program_Console\Lazarus\Release\win_x64\SII_Decrypt.exe';
  {$ELSE}
  LibraryPath = PathPrefix + 'Library\Lazarus\Release\win_x86\SII_Decrypt.dll';
  ExecPath    = PathPrefix + 'Program_Console\Lazarus\Release\win_x86\SII_Decrypt.exe';
  {$IFEND}
{$ELSE}
  {$IF SizeOf(Pointer) = 8}
  LibraryPath = PathPrefix + 'Library\Delphi\Release\win_x64\SII_Decrypt.dll';
  ExecPath    = PathPrefix + 'Program_Console\Delphi\Release\win_x64\SII_Decrypt.exe';
  {$ELSE}
  LibraryPath = PathPrefix + 'Library\Delphi\Release\win_x86\SII_Decrypt.dll';
  ExecPath    = PathPrefix + 'Program_Console\Delphi\Release\win_x86\SII_Decrypt.exe';
  {$IFEND}
{$ENDIF}
var
  TestFilesPath:    String;
  TestFilesListIni: TIniFileEx;
  TestFiles:        array of TTestFileEntry;
  i:                Integer;
begin
try
  WriteLn(StringOfChar('=',75));
  WriteLn('    SII Decrypt Tester');
  WriteLn(StringOfChar('=',75));
  WriteLn;
  TestFilesPath := ExpandFileName(ExtractFilePath(RTLToStr(ParamStr(0))) + TestFilesPrefix);
  WriteLn('Test files path: ',TestFilesPath);

  WriteLn;
  WriteLn('Loading test files list...');
  TestFilesListIni := TIniFileEx.Create(TestFilesPath + TestFilesList,True);
  try
    SetLength(TestFiles,TestFilesListIni.ReadInteger('Files','Count',0));
    For i := Low(TestFiles) to High(TestFiles) do
      begin
        TestFiles[i].FileName := TestFilesPath + TestFilesListIni.ReadString(Format('File.%d',[i]),'FileName','');
        TestFiles[i].FileFormat := TestFilesListIni.ReadInteger(Format('File.%d',[i]),'FileFormat',0);
        TestFiles[i].BinCRC32 := TCRC32(TestFilesListIni.ReadUInt32(Format('File.%d',[i]),'BinCRC32',0));
        TestFiles[i].TextCRC32 := TCRC32(TestFilesListIni.ReadUInt32(Format('File.%d',[i]),'TextCRC32',0));
      end;
  finally
    TestFilesListIni.Free;
  end;
  WriteLn;
  WriteLn(Format('Loaded %d entries',[Length(TestFiles)]));

  Load_SII_Decrypt(LibraryPath);
  try
    For i := Low(TestFiles) to High(TestFiles) do
      begin
        WriteLn;
        WriteLn(StringOfChar('=',75));
        WriteLn('  Entry #',i);
        WriteLn(StringOfChar('=',75));

        SII_Decrypt_Tester_LibraryDirect.TestOnFile(TestFiles[i]);
        SII_Decrypt_Tester_Library.TestOnFile(TestFiles[i]);
        SII_Decrypt_Tester_Program.TestOnFile(
          Format('"%s" "%s" "%s"',[ExecPath,TestFiles[i].FileName,TestFiles[i].FileName + '.out']),
          Format('"%s" --no_decode -i "%s" -o "%s"',[ExecPath,TestFiles[i].FileName,TestFiles[i].FileName + '.out']),
          TestFiles[i]);
      end;
  finally
    Unload_SII_Decrypt;
  end;
except
  on E: Exception do
    begin
      WriteLn;
      WriteLn(StrToCsl(Format('  error: %s: %s',[E.ClassName,E.Message])));
    end;
end;
WriteLn;
WriteLn(StringOfChar('-',75));
Write('Press enter to continue...');ReadLn;
end;

end.


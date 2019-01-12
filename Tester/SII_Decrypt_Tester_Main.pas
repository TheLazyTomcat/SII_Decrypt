{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decrypt_Tester_Main;

interface

procedure Main;

implementation

uses
  SysUtils, Classes,
  AuxTypes, StrRect, IniFileEx, CRC32, //SimpleLog_LogConsole,
  SII_Decrypt_Library_Header, SII_Decrypt_Tester_LibraryDirect;

procedure Main;
type
  TTestFileEntry = record
    FileName: String;
    Format:   Integer;
    BCRC32:   TCRC32;
    TCRC32:   TCRC32
  end;
const
{$IFDEF FPC}
  PathPrefix = '..\..\..\TestFiles\';
{$ELSE}
  PathPrefix = '..\..\TestFiles\';
{$ENDIF}
  TestFilesList = 'test_files_list.ini';
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
  TestFilesPath := ExpandFileName(ExtractFilePath(RTLToStr(ParamStr(0))) + PathPrefix);
  WriteLn('Test files path: ',TestFilesPath);

  WriteLn;
  WriteLn('Loading test files list...');
  TestFilesListIni := TIniFileEx.Create(TestFilesPath + TestFilesList,True);
  try
    SetLength(TestFiles,TestFilesListIni.ReadInteger('Files','Count',0));
    For i := Low(TestFiles) to High(TestFiles) do
      begin
        TestFiles[i].FileName := TestFilesPath + TestFilesListIni.ReadString(Format('File.%d',[i]),'FileName','');
        TestFiles[i].Format := TestFilesListIni.ReadInteger(Format('File.%d',[i]),'Format',0);
        TestFiles[i].BCRC32 := TCRC32(TestFilesListIni.ReadUInt32(Format('File.%d',[i]),'BCRC32',0));
        TestFiles[i].TCRC32 := TCRC32(TestFilesListIni.ReadUInt32(Format('File.%d',[i]),'TCRC32',0));
      end;
  finally
    TestFilesListIni.Free;
  end;
  WriteLn;
  WriteLn(Format('Loaded %d entries',[Length(TestFiles)]));

  For i := Low(TestFiles) to High(TestFiles) do
    begin
      WriteLn;
      WriteLn(StringOfChar('=',75));
      WriteLn('  Entry #',i);
      WriteLn(StringOfChar('=',75));
      WriteLn;

      SII_Decrypt_Tester_LibraryDirect.TestOnFile(TestFiles[i].FileName,TestFiles[i].Format,TestFiles[i].BCRC32,TestFiles[i].TCRC32);
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
(*
const
{$IFDEF FPC}
  PathPrefix = '..\..\..\';
{$ELSE}
  PathPrefix = '..\..\';
{$ENDIF}

procedure Main;
var
  MemStream:  TMemoryStream;
  OutBuff:    Pointer;
  OutSize:    TMemSize;
begin
{$IF SizeOf(Pointer) = 8}
Load_SII_Decrypt(PathPrefix + 'Library\Lazarus\Release\win_x64\SII_Decrypt.dll');
{$ELSE}
{$IFDEF FPC}
Load_SII_Decrypt(PathPrefix + 'Library\Lazarus\Release\win_x86\SII_Decrypt.dll');
{$ELSE}
Load_SII_Decrypt(PathPrefix + 'Library\Delphi\Release\win_x86\SII_Decrypt.dll');
{$ENDIF}
{$IFEND}
try
try
  If ParamCount > 0 then
    begin
      MemStream := TMemoryStream.Create;
      try
        WriteLn(Format('API version: %.8x',[APIVersion()]));

        WriteLn;
        WriteLn('DecryptFile:          ',DecryptFile(PUTF8Char(StrToUTF8(RTLToStr(ParamStr(1)))),PUTF8Char(StrToUTF8(RTLToStr(ParamStr(1)) + '.fout'))));
        WriteLn('DecodeFile:           ',DecodeFile(PUTF8Char(StrToUTF8(RTLToStr(ParamStr(1)))),PUTF8Char(StrToUTF8(RTLToStr(ParamStr(1)) + '.f2out'))));
        WriteLn('DecryptAndDecodeFile: ',DecryptAndDecodeFile(PUTF8Char(StrToUTF8(RTLToStr(ParamStr(1)))),PUTF8Char(StrToUTF8(RTLToStr(ParamStr(1)) + '.fdout'))));

        WriteLn;
        WriteLn('DecryptFileInMemory:          ',DecryptFileInMemory(PUTF8Char(StrToUTF8(RTLToStr(ParamStr(1)))),PUTF8Char(StrToUTF8(RTLToStr(ParamStr(1)) + '.mfout'))));
        WriteLn('DecodeFileInMemory:           ',DecodeFileInMemory(PUTF8Char(StrToUTF8(RTLToStr(ParamStr(1)))),PUTF8Char(StrToUTF8(RTLToStr(ParamStr(1)) + '.mf2out'))));
        WriteLn('DecryptAndDecodeFileInMemory: ',DecryptAndDecodeFileInMemory(PUTF8Char(StrToUTF8(RTLToStr(ParamStr(1)))),PUTF8Char(StrToUTF8(RTLToStr(ParamStr(1)) + '.mfdout'))));

        MemStream.LoadFromFile(ParamStr(1));
        If DecryptAndDecodeMemory(MemStream.Memory,MemStream.Size,nil,@OutSize) = SIIDEC_RESULT_SUCCESS then
          begin
            GetMem(OutBuff,OutSize);
            try
              MemStream.Position := 0;
              WriteLn;
              WriteLn('DecryptAndDecodeMemory: ',DecryptAndDecodeMemory(MemStream.Memory,MemStream.Size,OutBuff,@OutSize));
              MemStream.Seek(0,soBeginning);
              MemStream.WriteBuffer(OutBuff^,OutSize);
              MemStream.Size := OutSize;
              MemStream.SaveToFile(ParamStr(1) + '.mout');
            finally
              FreeMem(OutBuff,OutSize);
            end;
          end;
      finally
        MemStream.Free;
      end;
    end;
  WriteLn;  
  Write('Press enter to continue...'); ReadLn;
finally
  Unload_SII_Decrypt;
end;
except
  on E: Exception do
    begin
      Write('Error ',E.Message); ReadLn;
    end;
end;
end;
*)
end.


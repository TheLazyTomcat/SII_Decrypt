{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decrypt_Program;

{$INCLUDE '..\Source\SII_Decrypt_defs.inc'}

interface

procedure Main;

implementation

uses
  SysUtils,
  SimpleCmdLineParser, StrRect,
  SII_Decrypt_Decryptor;

procedure Main;
type
  TParsingMode = (pmNone,pmSimple,pmExtended);
var
  ParsingMode:  TParsingMode;
  CMDParser:    TCLPParser;
  Decryptor:    TSII_Decryptor;
  ParamData:    TCLPParameter;
  InFileName:   String;
  OutFileName:  String;
  ProcResult:   TSIIResult;
begin
try
  CMDParser := TCLPParser.Create;
  try
    WriteLn('************************************');
    WriteLn('*    SII Decrypt program 1.4.2     *');
    WriteLn('*   (c) 2016-2018 Frantisek Milt   *');
    WriteLn('************************************');

    If CMDParser.GetCommandCount > 0 then
      ParsingMode := pmExtended
    else If CMDParser.Count > 1 then
      ParsingMode := pmSimple
    else
      ParsingMode := pmNone;
      
    case ParsingMode of
      pmNone:       //  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
        begin
          WriteLn;
          WriteLn('usage:');
          WriteLn;
          WriteLn('  SII_Decrypt.exe InputFile [OutputFile]');
          WriteLn('  SII_Decrypt.exe [commands] -i InputFile [-o OutputFile]');
          WriteLn;
          WriteLn('    commands (optional)   - set of commands affecting the decryption');
          WriteLn('    InputFile             - file that has to be decrypted');
          WriteLn('    OutputFile (optional) - target file where to store the decrypted result');
          WriteLn;
          WriteLn('    Commands:');
          WriteLn;
          WriteLn('      --no_decode  - decryption only, no decoding will be attempted');
          WriteLn('      --sw_aes     - AES decryption will be done only in software');
          WriteLn('      --on_file    - processing of files is done directly on them');
          WriteLn('      --wait       - program will wait for user input after processing');
        end;

      pmSimple:     //  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
        begin
          WriteLn;
          WriteLn('Please wait...');
          Decryptor := TSII_Decryptor.Create;
          try
            Decryptor.ReraiseExceptions := True;
            If CMDParser.Count > 2 then
              begin
                InFileName := CMDParser.Parameters[Pred(CMDParser.HighIndex)].Str;
                OutFileName := CMDParser.Last.Str;
              end
            else
              begin
                InFileName := CMDParser.Last.Str;
                OutFileName := InFileName
              end;
            ProcResult := Decryptor.DecryptAndDecodeFileInMemory(InFileName,OutFileName);
            ExitCode := GetResultAsInt(ProcResult);
            WriteLn;
            WriteLn(Format('Result: %s (%d)',[GetResultAsText(ProcResult),ExitCode]));
          finally
            Decryptor.Free;
          end;
        end;

      pmExtended:   //  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
        begin
          WriteLn;
          WriteLn('Please wait...');
          Decryptor := TSII_Decryptor.Create;
          try
            Decryptor.ReraiseExceptions := True;
            Decryptor.AcceleratedAES := not CMDParser.CommandPresent('sw_aes');
            If CMDParser.GetCommandData(Char('i'),ParamData) then
              begin
                If Length(ParamData.Arguments) > 0 then
                  InFileName := ParamData.Arguments[0]
                else
                  raise Exception.Create('Input file not set.');
              end
            else raise Exception.Create('Input file not set.');
            If CMDParser.GetCommandData(Char('o'),ParamData) then
              begin
                If Length(ParamData.Arguments) > 0 then
                  OutFileName := ParamData.Arguments[0]
                else
                  raise Exception.Create('Error setting output file.');
              end
            else OutFileName := InFileName;
            If CMDParser.CommandPresent('no_decode') then
              begin
                If CMDParser.CommandPresent('on_file') then
                  ProcResult := Decryptor.DecryptFile(InFileName,OutFileName)
                else
                  ProcResult := Decryptor.DecryptFileInMemory(InFileName,OutFileName);
              end
            else
              begin
                If CMDParser.CommandPresent('on_file') then
                  ProcResult := Decryptor.DecryptAndDecodeFile(InFileName,OutFileName)
                else
                  ProcResult := Decryptor.DecryptAndDecodeFileInMemory(InFileName,OutFileName);
              end;
            ExitCode := GetResultAsInt(ProcResult);
            WriteLn;
            WriteLn(Format('Result: %s (%d)',[GetResultAsText(ProcResult),ExitCode]));
          finally
            Decryptor.Free;
          end;
        end;
    end;

    If CMDParser.CommandPresent('wait') or (ParsingMode = pmNone) then
      begin
        WriteLn;
        Write('Press enter to continue...'); ReadLn;
      end;
  
  finally
    CMDParser.Free;
  end;
except
  on E: Exception do
    begin
      WriteLn('An error has occured. Error message:');
      WriteLn;
      WriteLn('  ',StrToCsl(E.Message));
      ExitCode := -1;
    end;
end;
end;

end.

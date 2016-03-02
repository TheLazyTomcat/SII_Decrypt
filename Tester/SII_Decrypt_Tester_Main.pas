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
  SII_DecryptLib
  {$IF Defined(FPC) and (FPC_FULLVERSION >= 20701)}
  ,LazUTF8
  {$IFEND};

const
{$IF not Declared(FPC_FULLVERSION)}
  {%H-}FPC_FULLVERSION = Integer(0);
{$IFEND}

{$IFDEF FPC}
  PathPrefix = '..\..\..\';
{$ELSE}
  PathPrefix = '..\..\';
{$ENDIF}

procedure Main;
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
  If ParamCount > 0 then
{$IFDEF Unicode}
  {$IFDEF FPC}
    WriteLn(Ord(DecryptFile(PAnsiChar(UTF8ToWinCP(AnsiString(ParamStr(1)))),PAnsiChar(UTF8ToWinCP(AnsiString(ParamStr(1)))))));
  {$ELSE}
    WriteLn(Ord(DecryptFile(PAnsiChar(AnsiString(ParamStr(1))),PAnsiChar(AnsiString(ParamStr(1))))));
  {$ENDIF}
{$ELSE}
  {$IF not Defined(FPC) or (FPC_FULLVERSION < 20701)}
    WriteLn(Ord(DecryptFile(PAnsiChar(ParamStr(1)),PAnsiChar(ParamStr(1) + '.out'))));
  {$ELSE}
    WriteLn(Ord(DecryptFile(PAnsiChar(UTF8ToWinCP(ParamStr(1))),PAnsiChar(UTF8ToWinCP(ParamStr(1) + '.out')))));
  {$IFEND}
{$ENDIF}
  Write('Press enter to continue...'); ReadLn;
finally
  Unload_SII_Decrypt;
end;
end;

end.


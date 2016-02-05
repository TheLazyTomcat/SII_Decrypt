{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
program SII_Decrypt_Tester;

{$mode objfpc}{$H+}

uses
  SII_DecryptLib;

begin
{$IF SizeOf(Pointer) = 8}
  Load_SII_Decrypt('..\..\..\Library\Lazarus\Release\win_x64\SII_Decrypt.dll');
{$ELSE}
  Load_SII_Decrypt('..\..\..\Library\Lazarus\Release\win_x86\SII_Decrypt.dll');
{$IFEND}
  try
    If ParamCount > 0 then
      WriteLn(Ord(DecryptFile(PAnsiChar(ParamStr(1)),PAnsiChar(ParamStr(1) + '.out'))));
    Write('Press enter to continue...'); ReadLn;
  finally
    Unload_SII_Decrypt;
  end;
end.


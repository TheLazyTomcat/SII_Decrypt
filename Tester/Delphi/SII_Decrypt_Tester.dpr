{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
program SII_Decrypt_Tester;

{$APPTYPE CONSOLE}

uses
  SII_Decrypt_Tester_Main in '..\SII_Decrypt_Tester_Main.pas',
  SII_Decrypt_Tester_LibraryDirect in '..\SII_Decrypt_Tester_LibraryDirect.pas',
  SII_Decrypt_Tester_Library in '..\SII_Decrypt_Tester_Library.pas',
  SII_Decrypt_Tester_Program in '..\SII_Decrypt_Tester_Program.pas';

begin
  SII_Decrypt_Tester_Main.Main;
end.

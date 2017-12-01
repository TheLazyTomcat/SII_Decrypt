{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
program SII_Decrypt_Tester;

{$APPTYPE CONSOLE}

uses
  SII_Decrypt_Tester_Main in '..\SII_Decrypt_Tester_Main.pas',
  
  SII_Decrypt_Header  in '..\..\Headers\SII_Decrypt_Header.pas',
  SII_Decrypt_Library in '..\..\Library\SII_Decrypt_Library.pas',

  SII_Decrypt_Decryptor in '..\..\Source\SII_Decrypt_Decryptor.pas',

  SII_Decode_Common  in '..\..\Source\SII_Decode_Common.pas',
  SII_Decode_Helpers in '..\..\Source\SII_Decode_Helpers.pas',
  SII_Decode_Nodes   in '..\..\Source\SII_Decode_Nodes.pas',
  SII_Decode_Decoder in '..\..\Source\SII_Decode_Decoder.pas';

begin
  SII_Decrypt_Tester_Main.Main;
end.

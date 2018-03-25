{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
program SII_Decrypt;

{$APPTYPE CONSOLE}

uses
  SII_Decrypt_Program   in '..\SII_Decrypt_Program.pas',
  
  SII_Decrypt_Decryptor in '..\..\Source\SII_Decrypt_Decryptor.pas',

  SII_Decode_Common  in '..\..\Source\SII_Decode_Common.pas',
  SII_Decode_Helpers in '..\..\Source\SII_Decode_Helpers.pas',  
  SII_Decode_Nodes   in '..\..\Source\SII_Decode_Nodes.pas',
  SII_Decode_Decoder in '..\..\Source\SII_Decode_Decoder.pas',

  SII_3nK_Transcoder in '..\..\Source\SII_3nK_Transcoder.pas';

begin
  SII_Decrypt_Program.Main;
end.

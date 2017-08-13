{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
program SII_Decrypt;

{$mode objfpc}{$H+}

uses
  SII_Decrypt_Program,

  SII_Decrypt_Decryptor,

  SII_Decode_Common,
  SII_Decode_Nodes,
	SII_Decode_Decoder;

begin
  SII_Decrypt_Program.Main;
end.


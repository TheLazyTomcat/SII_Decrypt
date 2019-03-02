{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
library SII_Decrypt;

{$INCLUDE '..\..\Source\SII_Decrypt_defs.inc'}

uses
  // following units must be here otherwise their exports would be ignored
  SII_Decrypt_Library_Decryptor,
  SII_Decrypt_Library_Standalone;

{$R *.res}

{$WARN 5023 OFF}  // must be here, otherwise does not work...

begin
end.


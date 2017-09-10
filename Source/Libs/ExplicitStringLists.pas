{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Explicit string lists

  ©František Milt 2017-09-10

  Version 1.0

  Dependencies:
    AuxTypes        - github.com/ncs-sniper/Lib.AuxTypes
    StrRect         - github.com/ncs-sniper/Lib.StrRect
    BinaryStreaming - github.com/ncs-sniper/Lib.BinaryStreaming

===============================================================================}
unit ExplicitStringLists;

{$INCLUDE '.\ExplicitStringLists_defs.inc'}

interface

uses
  ExplicitStringListsA, ExplicitStringListsW, ExplicitStringListsO;

{===============================================================================
    Forwarded classes
===============================================================================}
type
  TShortStringList = ExplicitStringListsA.TShortStringList;
  TAnsiStringList = ExplicitStringListsA.TAnsiStringList;

  TWideStringList = ExplicitStringListsW.TWideStringList;
  TUnicodeStringList = ExplicitStringListsW.TUnicodeStringList;

  TUTF8StringList = ExplicitStringListsO.TUTF8StringList;
  TDefaultStringList = ExplicitStringListsO.TDefaultStringList;

implementation

end.





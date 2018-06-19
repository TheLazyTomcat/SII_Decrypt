{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Explicit string lists

  Part W - lists working with widechar-based strings.

  ©František Milt 2018-05-21

  Version 1.0.2

  Dependencies:
    AuxTypes        - github.com/ncs-sniper/Lib.AuxTypes
    AuxClasses      - github.com/ncs-sniper/Lib.AuxClasses
    StrRect         - github.com/ncs-sniper/Lib.StrRect
    BinaryStreaming - github.com/ncs-sniper/Lib.BinaryStreaming

===============================================================================}
unit ExplicitStringListsW;

{$INCLUDE '.\ExplicitStringLists_defs.inc'}

interface

uses
  Classes, AuxTypes, ExplicitStringListsBase;

{===============================================================================
--------------------------------------------------------------------------------
                                  T*StringList
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    T*StringList - declaration
===============================================================================}

{$DEFINE ESL_Declaration}

type
{$DEFINE ESL_Wide}
  {$I 'ESL_inc\ESL_CompFuncType.inc'} = Function(const Str1,Str2: {$I 'ESL_inc\ESL_StringType.inc'}): Integer;

  {$I 'ESL_inc\ESL_ListType.inc'} = class(TExplicitStringList)
    {$I ExplicitStringLists.inc}
  end;
{$UNDEF ESL_Wide}

{$DEFINE ESL_Unicode}
  {$I 'ESL_inc\ESL_CompFuncType.inc'} = Function(const Str1,Str2: {$I 'ESL_inc\ESL_StringType.inc'}): Integer;

  {$I 'ESL_inc\ESL_ListType.inc'} = class(TExplicitStringList)
    {$I ExplicitStringLists.inc}
  end;
{$UNDEF ESL_Unicode}

{$UNDEF ESL_Declaration}

implementation

uses
  SysUtils, StrRect, BinaryStreaming, ExplicitStringListsParser;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W4055:={$WARN 4055 OFF}} // Conversion between ordinals and pointers is not portable
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
{$ENDIF}

{===============================================================================
--------------------------------------------------------------------------------
                                  T*StringList
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    T*StringList - implementation
===============================================================================}

{$DEFINE ESL_Implementation}

{$DEFINE ESL_Wide}
  {$I ExplicitStringLists.inc}
{$UNDEF ESL_Wide}

{$DEFINE ESL_Unicode}
  {$I ExplicitStringLists.inc}
{$UNDEF ESL_Unicode}

{$UNDEF ESL_Implementation}

end.

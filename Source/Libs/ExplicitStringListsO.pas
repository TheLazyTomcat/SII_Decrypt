{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Explicit string lists

  Part O - lists working with strings not explicitly based on ansi or widechars.

  ©František Milt 2018-04-30

  Version 1.0.1

  Dependencies:
    AuxTypes        - github.com/ncs-sniper/Lib.AuxTypes
    AuxClasses      - github.com/ncs-sniper/Lib.AuxClasses
    StrRect         - github.com/ncs-sniper/Lib.StrRect
    BinaryStreaming - github.com/ncs-sniper/Lib.BinaryStreaming

===============================================================================}
unit ExplicitStringListsO;

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
{$DEFINE ESL_UTF8}
  {$I 'ESL_inc\ESL_CompFuncType.inc'} = Function(const Str1,Str2: {$I 'ESL_inc\ESL_StringType.inc'}): Integer;

  {$I 'ESL_inc\ESL_ListType.inc'} = class(TExplicitStringList)
    {$I ExplicitStringLists.inc}
  end;
{$UNDEF ESL_UTF8}

{$DEFINE ESL_Default}
  {$I 'ESL_inc\ESL_CompFuncType.inc'} = Function(const Str1,Str2: {$I 'ESL_inc\ESL_StringType.inc'}): Integer;

  {$I 'ESL_inc\ESL_ListType.inc'} = class(TExplicitStringList)
    {$I ExplicitStringLists.inc}
  end;
{$UNDEF ESL_Default}

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
    T*StringList - declaration
===============================================================================}

{$DEFINE ESL_Implementation}

{$DEFINE ESL_UTF8}
  {$I ExplicitStringLists.inc}
{$UNDEF ESL_UTF8}

{$DEFINE ESL_Default}
  {$I ExplicitStringLists.inc}
{$UNDEF ESL_Default}

{$UNDEF ESL_Implementation}

end.

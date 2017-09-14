{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Explicit string lists

  Delimited text parsers.

  ©František Milt 2017-09-10

  Version 1.0

  Dependencies:
    AuxTypes        - github.com/ncs-sniper/Lib.AuxTypes
    StrRect         - github.com/ncs-sniper/Lib.StrRect
    BinaryStreaming - github.com/ncs-sniper/Lib.BinaryStreaming

===============================================================================}
unit ExplicitStringListsParser;

{$INCLUDE '.\ExplicitStringLists_defs.inc'}

interface

uses
  AuxTypes;

{===============================================================================
--------------------------------------------------------------------------------
                             T*DelimitedTextParser
--------------------------------------------------------------------------------
===============================================================================}

type
  TDelimitedTextParserState = (dtpsInitial,dtpsWhiteSpace,dtpsDelimiter,
                               dtpsNormalText,dtpsQuotedText);

  TDelimitedTextParserCharType = (dtpcWhiteSpace,dtpcDelimiter,dtpcQuoteChar,
                                  dtpcGeneral);

{===============================================================================
    T*DelimitedTextParser - declaration
===============================================================================}

{$DEFINE ESL_Declaration}

{$DEFINE ESL_Short}
  {$I 'ESL_inc\ESL_DTParserEventType.inc'} = procedure(const Str: {$I 'ESL_inc\ESL_StringType.inc'}) of object;

  {$I 'ESL_inc\ESL_DTParserType.inc'} = class(TObject)
    {$I ExplicitStringListsParser.inc}
  end;
{$UNDEF ESL_Short}

{$DEFINE ESL_Ansi}
  {$I 'ESL_inc\ESL_DTParserEventType.inc'} = procedure(const Str: {$I 'ESL_inc\ESL_StringType.inc'}) of object;

  {$I 'ESL_inc\ESL_DTParserType.inc'} = class(TObject)
    {$I ExplicitStringListsParser.inc}
  end;
{$UNDEF ESL_Ansi}

{$DEFINE ESL_UTF8}
  {$I 'ESL_inc\ESL_DTParserEventType.inc'} = procedure(const Str: {$I 'ESL_inc\ESL_StringType.inc'}) of object;

  {$I 'ESL_inc\ESL_DTParserType.inc'} = class(TObject)
    {$I ExplicitStringListsParser.inc}
  end;
{$UNDEF ESL_UTF8}

{$DEFINE ESL_Wide}
  {$I 'ESL_inc\ESL_DTParserEventType.inc'} = procedure(const Str: {$I 'ESL_inc\ESL_StringType.inc'}) of object;

  {$I 'ESL_inc\ESL_DTParserType.inc'} = class(TObject)
    {$I ExplicitStringListsParser.inc}
  end;
{$UNDEF ESL_Wide}

{$DEFINE ESL_Unicode}
  {$I 'ESL_inc\ESL_DTParserEventType.inc'} = procedure(const Str: {$I 'ESL_inc\ESL_StringType.inc'}) of object;
  
  {$I 'ESL_inc\ESL_DTParserType.inc'} = class(TObject)
    {$I ExplicitStringListsParser.inc}
  end;
{$UNDEF ESL_Unicode}

{$DEFINE ESL_Default}
  {$I 'ESL_inc\ESL_DTParserEventType.inc'} = procedure(const Str: {$I 'ESL_inc\ESL_StringType.inc'}) of object;
  {$I 'ESL_inc\ESL_DTParserType.inc'} = class(TObject)
    {$I ExplicitStringListsParser.inc}
  end;
{$UNDEF ESL_Default}

{$UNDEF ESL_Declaration}

implementation

uses
  SysUtils;

{===============================================================================
--------------------------------------------------------------------------------
                             T*DelimitedTextParser
--------------------------------------------------------------------------------
===============================================================================}

{===============================================================================
    T*DelimitedTextParser - implementation
===============================================================================}

{$DEFINE ESL_Implementation}

{$DEFINE ESL_Short}
  {$I ExplicitStringListsParser.inc}
{$UNDEF ESL_Short}

{$DEFINE ESL_Ansi}
  {$I ExplicitStringListsParser.inc}
{$UNDEF ESL_Ansi}

{$DEFINE ESL_UTF8}
  {$I ExplicitStringListsParser.inc}
{$UNDEF ESL_UTF8}

{$DEFINE ESL_Wide}
  {$I ExplicitStringListsParser.inc}
{$UNDEF ESL_Wide}

{$DEFINE ESL_Unicode}
  {$I ExplicitStringListsParser.inc}
{$UNDEF ESL_Unicode}

{$DEFINE ESL_Default}
  {$I ExplicitStringListsParser.inc}
{$UNDEF ESL_Default}

{$UNDEF ESL_Implementation}

end.

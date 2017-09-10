{$IF Defined(ESL_Short)}
  TShortDelimitedTextParserEvent
{$ELSEIF Defined(ESL_Ansi)}
  TAnsiDelimitedTextParserEvent
{$ELSEIF Defined(ESL_UTF8)}
  TUTF8DelimitedTextParserEvent
{$ELSEIF Defined(ESL_Wide)}
  TWideDelimitedTextParserEvent
{$ELSEIF Defined(ESL_Unicode)}
  TUnicodeDelimitedTextParserEvent
{$ELSEIF Defined(ESL_Default)}
  TDefaultDelimitedTextParserEvent
{$IFEND}
{$IF Defined(ESL_Short)}
  TShortDelimitedTextParser
{$ELSEIF Defined(ESL_Ansi)}
  TAnsiDelimitedTextParser
{$ELSEIF Defined(ESL_UTF8)}
  TUTF8DelimitedTextParser
{$ELSEIF Defined(ESL_Wide)}
  TWideDelimitedTextParser
{$ELSEIF Defined(ESL_Unicode)}
  TUnicodeDelimitedTextParser
{$ELSEIF Defined(ESL_Default)}
  TDefaultDelimitedTextParser
{$IFEND}
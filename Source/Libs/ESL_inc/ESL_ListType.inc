{$IF Defined(ESL_Short)}
  TShortStringList
{$ELSEIF Defined(ESL_Ansi)}
  TAnsiStringList
{$ELSEIF Defined(ESL_UTF8)}
  TUTF8StringList
{$ELSEIF Defined(ESL_Wide)}
  TWideStringList
{$ELSEIF Defined(ESL_Unicode)}
  TUnicodeStringList
{$ELSEIF Defined(ESL_Default)}
  TDefaultStringList
{$IFEND}
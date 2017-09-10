{$IF Defined(ESL_Short)}
  AnsiChar
{$ELSEIF Defined(ESL_Ansi)}
  AnsiChar
{$ELSEIF Defined(ESL_UTF8)}
  UTF8Char
{$ELSEIF Defined(ESL_Wide)}
  WideChar
{$ELSEIF Defined(ESL_Unicode)}
  WideChar
{$ELSEIF Defined(ESL_Default)}
  Char
{$IFEND}
{$IF Defined(ESL_Short)}
PAnsiChar
{$ELSEIF Defined(ESL_Ansi)}
PAnsiChar
{$ELSEIF Defined(ESL_UTF8)}
PUTF8Char
{$ELSEIF Defined(ESL_Wide)}
PWideChar
{$ELSEIF Defined(ESL_Unicode)}
PWideChar
{$ELSEIF Defined(ESL_Default)}
PChar
{$IFEND}

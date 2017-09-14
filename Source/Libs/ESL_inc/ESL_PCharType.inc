{$IF Defined(ESL_Short)}
{%H-}PAnsiChar
{$ELSEIF Defined(ESL_Ansi)}
{%H-}PAnsiChar
{$ELSEIF Defined(ESL_UTF8)}
{%H-}PUTF8Char
{$ELSEIF Defined(ESL_Wide)}
{%H-}PWideChar
{$ELSEIF Defined(ESL_Unicode)}
{%H-}PWideChar
{$ELSEIF Defined(ESL_Default)}
{%H-}PChar
{$IFEND}

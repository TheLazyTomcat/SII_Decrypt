{$IF Defined(ESL_Short)}
  {$IFDEF ESL_ShortHelper}AnsiString{$ELSE}ShortString{$ENDIF}
{$ELSEIF Defined(ESL_Ansi)}
  AnsiString
{$ELSEIF Defined(ESL_UTF8)}
  UTF8String
{$ELSEIF Defined(ESL_Wide)}
  WideString
{$ELSEIF Defined(ESL_Unicode)}
  UnicodeString
{$ELSEIF Defined(ESL_Default)}
  String
{$IFEND}

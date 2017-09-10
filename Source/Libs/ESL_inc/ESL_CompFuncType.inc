{$IF Defined(ESL_Short)}
  TShortCompareFunction
{$ELSEIF Defined(ESL_Ansi)}
  TAnsiCompareFunction
{$ELSEIF Defined(ESL_UTF8)}
  TUTF8CompareFunction
{$ELSEIF Defined(ESL_Wide)}
  TWideCompareFunction
{$ELSEIF Defined(ESL_Unicode)}
  TUnicodeCompareFunction
{$ELSEIF Defined(ESL_Default)}
  TDefaultCompareFunction
{$IFEND}
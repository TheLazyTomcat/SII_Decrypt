{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$IF Defined(FPC) and not Defined(Unicode)}
  {$DEFINE FPC_NonUnicode}
{$ELSE}
  {$UNDEF FPC_NonUnicode}
{$IFEND}

{$IF Defined(FPC) and not Defined(Unicode) and (FPC_FULLVERSION < 20701)}
  {$DEFINE FPC_NonUnicode_NoUTF8RTL}
{$ELSE}
  {$UNDEF FPC_NonUnicode_NoUTF8RTL}
{$IFEND}
{$IFDEF FPC}
  {$MODE Delphi}
  {$DEFINE FPC_DisableWarns}
  {$MACRO ON}
{$ENDIF}

{$IF Defined(FPC) and not Defined(Unicode) and (FPC_FULLVERSION < 20701)}
  {$DEFINE FPC_NonUnicode_NoUTF8RTL}
{$ELSE}
  {$UNDEF FPC_NonUnicode_NoUTF8RTL}
{$IFEND}

{$TYPEINFO ON}

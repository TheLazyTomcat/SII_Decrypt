{$IF defined(CPU64) or defined(CPU64BITS)}
  {$DEFINE 64bit}
{$ELSEIF defined(CPU16)}
  {$MESSAGE FATAL '16bit CPU not supported'}
{$ELSE}
  {$DEFINE 32bit}
{$IFEND}

{$IFDEF FPC}
  {$MODE ObjFPC}{$H+}
  {$MODESWITCH CLASSICPROCVARS+}
  {$INLINE ON}
  {$DEFINE CanInline}
  {$DEFINE FPC_DisableWarns}
  {$MACRO ON}
{$ELSE}
  {$IF CompilerVersion >= 17 then}  // Delphi 2005+
    {$DEFINE CanInline}
  {$ELSE}
    {$UNDEF CanInline}
  {$IFEND}
{$ENDIF}

{
  AllowLowLevelAccess

  When defined, TIniFileEx objects have public properties and methods that can
  be used to access low-level structures of the object (nodes), otherwise these
  methods and properties are not present.

  Not defined by default.
}
{.$DEFINE AllowLowLevelAccess}

{
  AllowDefaultStringOverloads

  When this symbol is defined and symbol Unicode is NOT defined, the TIniFileEx
  offers overloaded methods that accept normal string type in addition to
  methods accepting type TIFXString.

  Defined by default.
}
{$DEFINE AllowDefaultStringOverloads}

{$IF not Defined(Unicode) and Defined(AllowDefaultStringOverloads)}
  {$DEFINE DefStrOverloads}
{$IFEND}

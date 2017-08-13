{$IF defined(CPUX86_64) or defined(CPUX64)}
  {$DEFINE x64}
{$ELSEIF defined(CPU386)}
  {$DEFINE x86}
{$ELSE}
  {$MESSAGE FATAL 'Unsupported CPU.'}
{$IFEND}

{$IF not(Defined(WINDOWS) or Defined(MSWINDOWS))}
  {$MESSAGE FATAL 'Unsupported operating system.'}
{$IFEND}

{$IFDEF FPC}
  {$MODE Delphi}
  {$ASMMODE Intel}
  {$INLINE ON}
  {$DEFINE CanInline}
{$ELSE}
  {$IF CompilerVersion >= 17}  // Delphi 2005+
    {$DEFINE CanInline}
  {$ELSE}
    {$UNDEF CanInline}
  {$IFEND}
{$ENDIF}

{
  GZIP_Support

  When defined, the binding provides functions for GZIP file manipulation.
  Requires presence of msvcrt.dll in the system (should be integral part of
  Windos NT and newer) for statically linked version.

  Defined by default;
}
{$DEFINE GZIP_Support}

{
  CheckCompatibility

  Asserts compatibility of this binding and used zlib (be it DLL or statically
  linked code).
  For statically linked zlib, it is done at unit initialization. For dynamically
  linked zlib, it is done at binding initialization.

  Not defined by default.
}
{.$DEFINE CheckCompatibility}

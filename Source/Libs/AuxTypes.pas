{$IFNDEF Included}
{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Auxiliary types

  ©František Milt 2017-09-25

  Version 1.0.7

===============================================================================}
unit AuxTypes;

interface
{$ENDIF Included}

{$UNDEF UInt64_NotNative}
{$IF (Defined(DCC) or Declared(CompilerVersion)) and not Defined(FPC)}
  // assumes Delphi (DCC symbol is not defined in older Delphi than XE2)
  {$IF (CompilerVersion <= 17)}
    {$DEFINE UInt64_NotNative}
  {$IFEND}
{$IFEND}

const
  NativeUInt64 = {$IFDEF UInt64_NotNative}False{$ELSE}True{$ENDIF};

type
//== Integers ==================================================================

{$IF (SizeOf(ShortInt) <> 1) or (SizeOf(Byte) <> 1)}
  {$MESSAGE FATAL 'Wrong size of 8bit integers'}
{$IFEND}
  Int8  = ShortInt;       UInt8  = Byte;
  PInt8 = ^Int8;          PUInt8 = ^UInt8;

{$IF (SizeOf(SmallInt) <> 2) or (SizeOf(Word) <> 2)}
  {$MESSAGE FATAL 'Wrong size of 16bit integers'}
{$IFEND}
  Int16  = SmallInt;      UInt16  = Word;
  PInt16 = ^Int16;        PUInt16 = ^UInt16;

{$IF (SizeOf(LongInt) = 4) and (SizeOf(LongWord) = 4)}
  Int32  = LongInt;       UInt32  = LongWord;
{$ELSE}
  {$IF (SizeOf(Integer) <> 4) or (SizeOf(Cardinal) <> 4)}
    {$MESSAGE FATAL 'Wrong size of 32bit integers'}
  {$ELSE}
  Int32  = Integer;       UInt32  = Cardinal;
  {$IFEND}
{$IFEND}
  PInt32 = ^Int32;        PUInt32 = ^UInt32;

{$IFDEF UInt64_NotNative}
  UInt64 = Int64;
{$ENDIF}
{$IF (SizeOf(Int64) <> 8) or (SizeOf(UInt64) <> 8)}
  {$MESSAGE FATAL 'Wrong size of 64bit integers'}
{$IFEND}
  PUInt64 = ^UInt64;

  QuadWord  = UInt64;     PQuadWord = ^QuadWord;

//-- Half-byte -----------------------------------------------------------------

  TNibble = 0..15;        PNibble = ^TNibble;

  Nibble = TNibble;

//-- Pointer related -----------------------------------------------------------

{$IF SizeOf(Pointer) = 8}
  PtrInt  = Int64;
  PtrUInt = UInt64;
{$ELSEIF SizeOf(Pointer) = 4}
  PtrInt  = Int32;
  PtrUInt = UInt32;
{$ELSE}
  {$MESSAGE FATAL 'Unsupported size of pointer type'}
{$IFEND}
  PPtrInt  = ^PtrInt;
  PPtrUInt = ^PtrUInt;

  TStrSize = Int32;       PStrSize = ^TStrSize;
  TMemSize = PtrUInt;     PMemSize = ^TMemSize;

  NativeInt  = PtrInt;    PNativeInt  = ^NativeInt;
  NativeUInt = PtrUInt;   PNativeUInt = ^NativeUInt;

//== Floats ====================================================================

  // half precision floating point numbers
  // only for I/O operations, cannot be used in arithmetics
  Half  = packed array[0..1] of UInt8;        PHalf = ^Half;

{$IF (SizeOf(Half) <> 2)}
  {$MESSAGE FATAL 'Wrong size of 16bit float'}
{$IFEND}
  Float16 = Half;         PFloat16 = ^Float16;

{$IF (SizeOf(Single) <> 4)}
  {$MESSAGE FATAL 'Wrong size of 32bit float'}
{$IFEND}
  Float32 = Single;       PFloat32 = ^Float32;

{$IF (SizeOf(Double) <> 8)}
  {$MESSAGE FATAL 'Wrong size of 64bit float'}
{$IFEND}
  Float64 = Double;       PFloat64 = ^Float64;

{$IF SizeOf(Extended) = 10}
  Float80 = Extended;
{$ELSE}
  // only for I/O operations, cannot be used in arithmetics
  Float80 = packed array[0..9] of UInt8;
{$IFEND}
  PFloat80 = ^Float80;

//== Strings ===================================================================

{$IF not declared(UnicodeChar)}  
  UnicodeChar    = WideChar;
{$IFEND}
{$IF not declared(UnicodeString)}
  UnicodeString  = WideString;
{$IFEND}
  PUnicodeChar   = ^UnicodeChar; 
  PUnicodeString = ^UnicodeString;

{$IF not declared(UTF8Char)}
  UTF8Char = type AnsiChar;
{$IFEND}
  PUTF8Char = ^UTF8Char;

{$IFNDEF Included}
implementation

{$WARNINGS OFF}
end.
{$ENDIF Included}
{$WARNINGS ON}

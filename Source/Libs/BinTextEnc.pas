{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Binary to text encodings

  ©František Milt 2018-05-12

  Version 1.1.5

  Notes:
    - Do not call EncodedLength function with Base85 or Ascii85 encoding.
    - Hexadecimal encoding is always forward (ie. not reversed) when executed by
      a universal function, irrespective of selected setting.
    - Base16, Base32 nad Base64 encodings should be compliant with RFC 4648.
    - Base85 encoding is by-default using Z85 alphabet with undescore ("_", #95)
      as an all-zero compression letter.

  Dependencies:
    AuxTypes - github.com/ncs-sniper/Lib.AuxTypes

===============================================================================}
unit BinTextEnc;

{$IF not(defined(CPUX86_64) or defined(CPUX64) or defined(CPU386))}
  {$DEFINE PurePascal}
{$IFEND}

{$IFDEF FPC}
  {$MODE ObjFPC}{$H+}
  {$INLINE ON}
  {$DEFINE CanInline}
  {$ASMMODE Intel}
  {$DEFINE FPC_DisableWarns}
  {$MACRO ON}
{$ELSE}
  {$IF CompilerVersion >= 17 then}  // Delphi 2005+
    {$DEFINE CanInline}
  {$ELSE}
    {$UNDEF CanInline}
  {$IFEND}  
{$ENDIF}

interface

uses
  SysUtils, AuxTypes;

type
  TBinTextEncoding = (bteUnknown,bteBase2,bteBase8,bteBase10,bteBase16,
                      bteHexadecimal,bteBase32,bteBase32Hex,bteBase64,
                      bteBase85,bteAscii85);

  EBinTextEncError     = class(Exception);
  EUnknownEncoding     = class(EBinTextEncError);
  EUnsupportedEncoding = class(EBinTextEncError);
  EEncodingError       = class(EBinTextEncError);
  EDecodingError       = class(EBinTextEncError);
  EAllocationError     = class(EBinTextEncError);
  EInvalidCharacter    = class(EBinTextEncError);
  ETooMuchData         = class(EBinTextEncError);
  EHeaderWontFit       = class(EBinTextEncError);
  EEncodedTextTooShort = class(EBinTextEncError);

const
  AnsiEncodingHexadecimal = AnsiChar('$');
  AnsiEncodingHeaderStart = AnsiChar('#');
  AnsiEncodingHeaderEnd   = AnsiChar(':');

  WideEncodingHexadecimal = UnicodeChar('$');
  WideEncodingHeaderStart = UnicodeChar('#');
  WideEncodingHeaderEnd   = UnicodeChar(':');  


{===============================================================================
--------------------------------------------------------------------------------
                        Encoding alphabets and constants
--------------------------------------------------------------------------------
===============================================================================}
const
  AnsiPaddingChar_Base8     = AnsiChar('=');
  AnsiPaddingChar_Base32    = AnsiChar('=');
  AnsiPaddingChar_Base32Hex = AnsiChar('=');
  AnsiPaddingChar_Base64    = AnsiChar('=');

  WidePaddingChar_Base8     = UnicodeChar('=');
  WidePaddingChar_Base32    = UnicodeChar('=');
  WidePaddingChar_Base32Hex = UnicodeChar('=');
  WidePaddingChar_Base64    = UnicodeChar('=');

  AnsiCompressionChar_Base85 = AnsiChar('_');
  WideCompressionChar_Base85 = UnicodeChar('_');

  AnsiEncodingTable_Base2: array[0..1] of AnsiChar =
    ('0','1');
  WideEncodingTable_Base2: array[0..1] of UnicodeChar =
    ('0','1');

  AnsiEncodingTable_Base8: array[0..7] of AnsiChar =
    ('0','1','2','3','4','5','6','7');
  WideEncodingTable_Base8: array[0..7] of UnicodeChar =
    ('0','1','2','3','4','5','6','7');

  AnsiEncodingTable_Base10: array[0..9] of AnsiChar =
    ('0','1','2','3','4','5','6','7','8','9');
  WideEncodingTable_Base10: array[0..9] of UnicodeChar =
    ('0','1','2','3','4','5','6','7','8','9');

  AnsiEncodingTable_Base16: array[0..15] of AnsiChar =
    ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
  WideEncodingTable_Base16: array[0..15] of UnicodeChar =
    ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');

  AnsiEncodingTable_Hexadecimal: array[0..15] of AnsiChar =
    ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
  WideEncodingTable_Hexadecimal: array[0..15] of UnicodeChar =
    ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');

  AnsiEncodingTable_Base32: array[0..31] of AnsiChar =
    ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
     'Q','R','S','T','U','V','W','X','Y','Z','2','3','4','5','6','7');
  WideEncodingTable_Base32: array[0..31] of UnicodeChar =
    ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
     'Q','R','S','T','U','V','W','X','Y','Z','2','3','4','5','6','7');

  AnsiEncodingTable_Base32Hex: array[0..31] of AnsiChar =
    ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F',
     'G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V');
  WideEncodingTable_Base32Hex: array[0..31] of UnicodeChar =
    ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F',
     'G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V');

  AnsiEncodingTable_Base64: array[0..63] of AnsiChar =
    ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
     'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
     'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
     'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/');
  WideEncodingTable_Base64: array[0..63] of UnicodeChar =
    ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
     'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
     'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
     'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/');

  AnsiEncodingTable_Base85: array[0..84] of AnsiChar =
    ('0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
     'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
     'w','x','y','z','A','B','C','D','E','F','G','H','I','J','K','L',
     'M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','.','-',
     ':','+','=','^','!','/','*','?','&','<','>','(',')','[',']','{',
     '}','@','%','$','#');
  WideEncodingTable_Base85: array[0..84] of UnicodeChar =
    ('0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
     'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
     'w','x','y','z','A','B','C','D','E','F','G','H','I','J','K','L',
     'M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','.','-',
     ':','+','=','^','!','/','*','?','&','<','>','(',')','[',']','{',
     '}','@','%','$','#');

  AnsiCompressionChar_Ascii85 = AnsiChar('z');
  WideCompressionChar_Ascii85 = UnicodeChar('z');

  AnsiEncodingTable_Ascii85: array[0..84] of AnsiChar =
    ('!','"','#','$','%','&','''','(',')','*','+',',','-','.','/','0',
     '1','2','3','4','5','6','7','8','9',':',';','<','=','>','?','@',
     'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
     'Q','R','S','T','U','V','W','X','Y','Z','[','\',']','^','_','`',
     'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p',
     'q','r','s','t','u');
  WideEncodingTable_Ascii85: array[0..84] of UnicodeChar =
    ('!','"','#','$','%','&','''','(',')','*','+',',','-','.','/','0',
     '1','2','3','4','5','6','7','8','9',':',';','<','=','>','?','@',
     'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
     'Q','R','S','T','U','V','W','X','Y','Z','[','\',']','^','_','`',
     'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p',
     'q','r','s','t','u');

{===============================================================================
--------------------------------------------------------------------------------
                                Decoding tables
--------------------------------------------------------------------------------
===============================================================================}
type
  TDecodingTable = array[0..127] of Byte;

const
  DecodingTable_Base2: TDecodingTable =
    ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $00, $01, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);

  DecodingTable_Base8: TDecodingTable =
    ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $00, $01, $02, $03, $04, $05, $06, $07, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);

  DecodingTable_Base10: TDecodingTable =
    ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);

  DecodingTable_Base16: TDecodingTable =
    ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $0A, $0B, $0C, $0D, $0E, $0F, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);

  DecodingTable_Hexadecimal: TDecodingTable =
    ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $0A, $0B, $0C, $0D, $0E, $0F, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);

  DecodingTable_Base32: TDecodingTable =
    ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $1A, $1B, $1C, $1D, $1E, $1F, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E,
     $0F, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);

  DecodingTable_Base32Hex: TDecodingTable =
    ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $0A, $0B, $0C, $0D, $0E, $0F, $10, $11, $12, $13, $14, $15, $16, $17, $18,
     $19, $1A, $1B, $1C, $1D, $1E, $1F, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);

  DecodingTable_Base64: TDecodingTable =
    ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $3E, $FF, $FF, $FF, $3F,
     $34, $35, $36, $37, $38, $39, $3A, $3B, $3C, $3D, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E,
     $0F, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $FF, $FF, $FF, $FF, $FF,
     $FF, $1A, $1B, $1C, $1D, $1E, $1F, $20, $21, $22, $23, $24, $25, $26, $27, $28,
     $29, $2A, $2B, $2C, $2D, $2E, $2F, $30, $31, $32, $33, $FF, $FF, $FF, $FF, $FF);

  DecodingTable_Base85: TDecodingTable =
    ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $44, $FF, $54, $53, $52, $48, $FF, $4B, $4C, $46, $41, $FF, $3F, $3E, $45,
     $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $40, $FF, $49, $42, $4A, $47,
     $51, $24, $25, $26, $27, $28, $29, $2A, $2B, $2C, $2D, $2E, $2F, $30, $31, $32,
     $33, $34, $35, $36, $37, $38, $39, $3A, $3B, $3C, $3D, $4D, $FF, $4E, $43, $FF,
     $FF, $0A, $0B, $0C, $0D, $0E, $0F, $10, $11, $12, $13, $14, $15, $16, $17, $18,
     $19, $1A, $1B, $1C, $1D, $1E, $1F, $20, $21, $22, $23, $4F, $FF, $50, $FF, $FF);

  DecodingTable_Ascii85: TDecodingTable =
    ($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
     $FF, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E,
     $0F, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1A, $1B, $1C, $1D, $1E,
     $1F, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2A, $2B, $2C, $2D, $2E,
     $2F, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3A, $3B, $3C, $3D, $3E,
     $3F, $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4A, $4B, $4C, $4D, $4E,
     $4F, $50, $51, $52, $53, $54, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);

{===============================================================================
--------------------------------------------------------------------------------
                              Universal functions
--------------------------------------------------------------------------------
===============================================================================}

Function BuildDecodingTable(EncodingTable: array of Char): TDecodingTable;
Function AnsiBuildDecodingTable(EncodingTable: array of AnsiChar): TDecodingTable;
Function WideBuildDecodingTable(EncodingTable: array of UnicodeChar): TDecodingTable;

Function BuildHeader(Encoding: TBinTextEncoding; Reversed: Boolean): String;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiBuildHeader(Encoding: TBinTextEncoding; Reversed: Boolean): AnsiString;
Function WideBuildHeader(Encoding: TBinTextEncoding; Reversed: Boolean): UnicodeString;

Function GetEncoding(const Str: String; out Reversed: Boolean): TBinTextEncoding;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiGetEncoding(const Str: AnsiString; out Reversed: Boolean): TBinTextEncoding;
Function WideGetEncoding(const Str: UnicodeString; out Reversed: Boolean): TBinTextEncoding;

Function EncodedLength(Encoding: TBinTextEncoding; DataSize: TMemSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;

Function DecodedLength(Encoding: TBinTextEncoding; const Str: String; Header: Boolean = True): TMemSize;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecodedLength(Encoding: TBinTextEncoding; const Str: AnsiString; Header: Boolean = True): TMemSize;
Function WideDecodedLength(Encoding: TBinTextEncoding; const Str: UnicodeString; Header: Boolean = True): TMemSize;

Function Encode(Encoding: TBinTextEncoding; Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True): String;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiEncode(Encoding: TBinTextEncoding; Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True): AnsiString;
Function WideEncode(Encoding: TBinTextEncoding; Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True): UnicodeString;

Function Decode(const Str: String; out Size: TMemSize): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode(const Str: AnsiString; out Size: TMemSize): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode(const Str: UnicodeString; out Size: TMemSize): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode(const Str: String; out Size: TMemSize; out Encoding: TBinTextEncoding): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode(const Str: AnsiString; out Size: TMemSize; out Encoding: TBinTextEncoding): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode(const Str: UnicodeString; out Size: TMemSize; out Encoding: TBinTextEncoding): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode(const Str: String; out Size: TMemSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode(const Str: AnsiString; out Size: TMemSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): Pointer; overload;
Function WideDecode(const Str: UnicodeString; out Size: TMemSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): Pointer; overload;

Function Decode(const Str: String; Ptr: Pointer; Size: TMemSize): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode(const Str: AnsiString; Ptr: Pointer; Size: TMemSize): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode(const Str: String; Ptr: Pointer; Size: TMemSize; out Encoding: TBinTextEncoding): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; out Encoding: TBinTextEncoding): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; out Encoding: TBinTextEncoding): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode(const Str: String; Ptr: Pointer; Size: TMemSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): TMemSize; overload;
Function WideDecode(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): TMemSize; overload;

{===============================================================================
--------------------------------------------------------------------------------
                  Functions calculating length of encoded text
                    from size of data that has to be encoded
--------------------------------------------------------------------------------
===============================================================================}

Function EncodedLength_Base2(DataSize: TMemSize; Header: Boolean = False): TStrSize;
Function EncodedLength_Base8(DataSize: TMemSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;
Function EncodedLength_Base10(DataSize: TMemSize; Header: Boolean = False): TStrSize;
Function EncodedLength_Base16(DataSize: TMemSize; Header: Boolean = False): TStrSize;
Function EncodedLength_Hexadecimal(DataSize: TMemSize; Header: Boolean = False): TStrSize;
Function EncodedLength_Base32(DataSize: TMemSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;
Function EncodedLength_Base32Hex(DataSize: TMemSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;
Function EncodedLength_Base64(DataSize: TMemSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;
Function EncodedLength_Base85(Data: Pointer; DataSize: TMemSize; Reversed: Boolean; Header: Boolean = False; Compression: Boolean = True; Trim: Boolean = True): TStrSize;
Function EncodedLength_Ascii85(Data: Pointer; DataSize: TMemSize; Reversed: Boolean; Header: Boolean = False; Compression: Boolean = True; Trim: Boolean = True): TStrSize;

{===============================================================================
--------------------------------------------------------------------------------
                   Functions calculating size of encoded data
                          from length of encoded text
--------------------------------------------------------------------------------
===============================================================================}

Function DecodedLength_Base2(const Str: String; Header: Boolean = False): TMemSize;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecodedLength_Base2(const Str: AnsiString; Header: Boolean = False): TMemSize;
Function WideDecodedLength_Base2(const Str: UnicodeString; Header: Boolean = False): TMemSize;

Function DecodedLength_Base8(const Str: String; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecodedLength_Base8(const Str: AnsiString; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecodedLength_Base8(const Str: UnicodeString; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function DecodedLength_Base8(const Str: String; Header: Boolean; PaddingChar: Char): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecodedLength_Base8(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): TMemSize; overload;
Function WideDecodedLength_Base8(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): TMemSize; overload;

Function DecodedLength_Base10(const Str: String; Header: Boolean = False): TMemSize;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecodedLength_Base10(const Str: AnsiString; Header: Boolean = False): TMemSize;
Function WideDecodedLength_Base10(const Str: UnicodeString; Header: Boolean = False): TMemSize;

Function DecodedLength_Base16(const Str: String; Header: Boolean = False): TMemSize;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecodedLength_Base16(const Str: AnsiString; Header: Boolean = False): TMemSize;
Function WideDecodedLength_Base16(const Str: UnicodeString; Header: Boolean = False): TMemSize;

Function DecodedLength_Hexadecimal(const Str: String; Header: Boolean = False): TMemSize;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecodedLength_Hexadecimal(const Str: AnsiString; Header: Boolean = False): TMemSize;
Function WideDecodedLength_Hexadecimal(const Str: UnicodeString; Header: Boolean = False): TMemSize;

Function DecodedLength_Base32(const Str: String; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecodedLength_Base32(const Str: AnsiString; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecodedLength_Base32(const Str: UnicodeString; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function DecodedLength_Base32(const Str: String; Header: Boolean; PaddingChar: Char): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecodedLength_Base32(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): TMemSize; overload;
Function WideDecodedLength_Base32(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): TMemSize; overload;

Function DecodedLength_Base32Hex(const Str: String; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecodedLength_Base32Hex(const Str: AnsiString; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecodedLength_Base32Hex(const Str: UnicodeString; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function DecodedLength_Base32Hex(const Str: String; Header: Boolean; PaddingChar: Char): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecodedLength_Base32Hex(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecodedLength_Base32Hex(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function DecodedLength_Base64(const Str: String; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecodedLength_Base64(const Str: AnsiString; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecodedLength_Base64(const Str: UnicodeString; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function DecodedLength_Base64(const Str: String; Header: Boolean; PaddingChar: Char): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecodedLength_Base64(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): TMemSize; overload;
Function WideDecodedLength_Base64(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): TMemSize; overload;

Function DecodedLength_Base85(const Str: String; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecodedLength_Base85(const Str: AnsiString; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecodedLength_Base85(const Str: UnicodeString; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function DecodedLength_Base85(const Str: String; Header: Boolean; CompressionChar: Char): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecodedLength_Base85(const Str: AnsiString; Header: Boolean; CompressionChar: AnsiChar): TMemSize; overload;
Function WideDecodedLength_Base85(const Str: UnicodeString; Header: Boolean; CompressionChar: UnicodeChar): TMemSize; overload;

Function DecodedLength_Ascii85(const Str: String; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecodedLength_Ascii85(const Str: AnsiString; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecodedLength_Ascii85(const Str: UnicodeString; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}


{===============================================================================
--------------------------------------------------------------------------------
                               Encoding functions
--------------------------------------------------------------------------------
===============================================================================}

Function Encode_Base2(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: String = ''): String; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiEncode_Base2(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: AnsiString = ''): AnsiString; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideEncode_Base2(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: UnicodeString = ''): UnicodeString; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Encode_Base2(Data: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; Header: String = ''): String; overload;
Function AnsiEncode_Base2(Data: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; Header: AnsiString = ''): AnsiString; overload;
Function WideEncode_Base2(Data: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; Header: UnicodeString = ''): UnicodeString; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Encode_Base8(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: String = ''): String; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiEncode_Base8(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: AnsiString = ''): AnsiString; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideEncode_Base8(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: UnicodeString = ''): UnicodeString; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Encode_Base8(Data: Pointer; Size: TMemSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: array of Char; PaddingChar: Char; Header: String = ''): String; overload;
Function AnsiEncode_Base8(Data: Pointer; Size: TMemSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: array of AnsiChar; PaddingChar: AnsiChar; Header: AnsiString = ''): AnsiString; overload;
Function WideEncode_Base8(Data: Pointer; Size: TMemSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: array of UnicodeChar; PaddingChar: UnicodeChar; Header: UnicodeString = ''): UnicodeString; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Encode_Base10(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: String = ''): String; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiEncode_Base10(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: AnsiString = ''): AnsiString; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideEncode_Base10(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: UnicodeString = ''): UnicodeString; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Encode_Base10(Data: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; Header: String = ''): String; overload;
Function AnsiEncode_Base10(Data: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; Header: AnsiString = ''): AnsiString; overload;
Function WideEncode_Base10(Data: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; Header: UnicodeString = ''): UnicodeString; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Encode_Base16(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: String = ''): String; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiEncode_Base16(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: AnsiString = ''): AnsiString; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideEncode_Base16(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: UnicodeString = ''): UnicodeString; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Encode_Base16(Data: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; Header: String = ''): String; overload;
Function AnsiEncode_Base16(Data: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; Header: AnsiString = ''): AnsiString; overload;
Function WideEncode_Base16(Data: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; Header: UnicodeString = ''): UnicodeString; overload;

Function Encode_Hexadecimal(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: String = ''): String;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiEncode_Hexadecimal(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: AnsiString = ''): AnsiString;{$IFDEF CanInline} inline; {$ENDIF}
Function WideEncode_Hexadecimal(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: UnicodeString = ''): UnicodeString;{$IFDEF CanInline} inline; {$ENDIF}

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Encode_Base32(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: String = ''): String; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiEncode_Base32(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: AnsiString = ''): AnsiString; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideEncode_Base32(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: UnicodeString = ''): UnicodeString; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Encode_Base32(Data: Pointer; Size: TMemSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: array of Char; PaddingChar: Char; Header: String = ''): String; overload;
Function AnsiEncode_Base32(Data: Pointer; Size: TMemSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: array of AnsiChar; PaddingChar: AnsiChar; Header: AnsiString = ''): AnsiString; overload;
Function WideEncode_Base32(Data: Pointer; Size: TMemSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: array of UnicodeChar; PaddingChar: UnicodeChar; Header: UnicodeString = ''): UnicodeString; overload;

Function Encode_Base32Hex(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: String = ''): String; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiEncode_Base32Hex(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: AnsiString = ''): AnsiString; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideEncode_Base32Hex(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: UnicodeString = ''): UnicodeString; overload;{$IFDEF CanInline} inline; {$ENDIF}

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Encode_Base64(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: String = ''): String; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiEncode_Base64(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: AnsiString = ''): AnsiString; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideEncode_Base64(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: UnicodeString = ''): UnicodeString; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Encode_Base64(Data: Pointer; Size: TMemSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: array of Char; PaddingChar: Char; Header: String = ''): String; overload;
Function AnsiEncode_Base64(Data: Pointer; Size: TMemSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: array of AnsiChar; PaddingChar: AnsiChar; Header: AnsiString = ''): AnsiString; overload;
Function WideEncode_Base64(Data: Pointer; Size: TMemSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: array of UnicodeChar; PaddingChar: UnicodeChar; Header: UnicodeString = ''): UnicodeString; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Encode_Base85(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Compression: Boolean = True; Trim: Boolean = True; Header: String = ''): String; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiEncode_Base85(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Compression: Boolean = True; Trim: Boolean = True; Header: AnsiString = ''): AnsiString; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideEncode_Base85(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Compression: Boolean = True; Trim: Boolean = True; Header: UnicodeString = ''): UnicodeString; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Encode_Base85(Data: Pointer; Size: TMemSize; Reversed: Boolean; Compression: Boolean; Trim: Boolean; const EncodingTable: array of Char; CompressionChar: Char; Header: String = ''): String; overload;
Function AnsiEncode_Base85(Data: Pointer; Size: TMemSize; Reversed: Boolean; Compression: Boolean; Trim: Boolean; const EncodingTable: array of AnsiChar; CompressionChar: AnsiChar; Header: AnsiString = ''): AnsiString; overload;
Function WideEncode_Base85(Data: Pointer; Size: TMemSize; Reversed: Boolean; Compression: Boolean; Trim: Boolean; const EncodingTable: array of UnicodeChar; CompressionChar: UnicodeChar; Header: UnicodeString = ''): UnicodeString; overload;

Function Encode_Ascii85(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Compression: Boolean = True; Trim: Boolean = True; Header: String = ''): String; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiEncode_Ascii85(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Compression: Boolean = True; Trim: Boolean = True; Header: AnsiString = ''): AnsiString; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideEncode_Ascii85(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Compression: Boolean = True; Trim: Boolean = True; Header: UnicodeString = ''): UnicodeString; overload;{$IFDEF CanInline} inline; {$ENDIF}


{===============================================================================
--------------------------------------------------------------------------------
                               Decoding functions
--------------------------------------------------------------------------------
===============================================================================}

Function Decode_Base2(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base2(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Base2(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode_Base2(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base2(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Base2(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode_Base2(const Str: String; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; Header: Boolean = False): Pointer; overload;
Function AnsiDecode_Base2(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; Header: Boolean = False): Pointer; overload;
Function WideDecode_Base2(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; Header: Boolean = False): Pointer; overload;

Function Decode_Base2(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; Header: Boolean = False): TMemSize; overload;
Function AnsiDecode_Base2(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; Header: Boolean = False): TMemSize; overload;
Function WideDecode_Base2(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; Header: Boolean = False): TMemSize; overload;

Function Decode_Base2(const Str: String; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base2(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): Pointer; overload;
Function WideDecode_Base2(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): Pointer; overload;

Function Decode_Base2(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base2(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): TMemSize; overload;
Function WideDecode_Base2(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): TMemSize; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Decode_Base8(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base8(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Base8(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode_Base8(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base8(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Base8(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode_Base8(const Str: String; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; PaddingChar: Char; Header: Boolean = False): Pointer; overload;
Function AnsiDecode_Base8(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; PaddingChar: AnsiChar; Header: Boolean = False): Pointer; overload;
Function WideDecode_Base8(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; PaddingChar: UnicodeChar; Header: Boolean = False): Pointer; overload;

Function Decode_Base8(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; PaddingChar: Char; Header: Boolean = False): TMemSize; overload;
Function AnsiDecode_Base8(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; PaddingChar: AnsiChar; Header: Boolean = False): TMemSize; overload;
Function WideDecode_Base8(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; PaddingChar: UnicodeChar; Header: Boolean = False): TMemSize; overload;

Function Decode_Base8(const Str: String; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: Char; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base8(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: AnsiChar; Header: Boolean = False): Pointer; overload;
Function WideDecode_Base8(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: UnicodeChar; Header: Boolean = False): Pointer; overload;

Function Decode_Base8(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: Char; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base8(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: AnsiChar; Header: Boolean = False): TMemSize; overload;
Function WideDecode_Base8(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: UnicodeChar; Header: Boolean = False): TMemSize; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Decode_Base10(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base10(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Base10(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode_Base10(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base10(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Base10(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode_Base10(const Str: String; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; Header: Boolean = False): Pointer; overload;
Function AnsiDecode_Base10(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; Header: Boolean = False): Pointer; overload;
Function WideDecode_Base10(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; Header: Boolean = False): Pointer; overload;

Function Decode_Base10(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; Header: Boolean = False): TMemSize; overload;
Function AnsiDecode_Base10(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; Header: Boolean = False): TMemSize; overload;
Function WideDecode_Base10(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; Header: Boolean = False): TMemSize; overload;

Function Decode_Base10(const Str: String; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base10(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): Pointer; overload;
Function WideDecode_Base10(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): Pointer; overload;

Function Decode_Base10(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base10(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): TMemSize; overload;
Function WideDecode_Base10(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): TMemSize; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Decode_Base16(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base16(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Base16(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode_Base16(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base16(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Base16(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode_Base16(const Str: String; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; Header: Boolean = False): Pointer; overload;
Function AnsiDecode_Base16(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; Header: Boolean = False): Pointer; overload;
Function WideDecode_Base16(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; Header: Boolean = False): Pointer; overload;

Function Decode_Base16(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; Header: Boolean = False): TMemSize; overload;
Function AnsiDecode_Base16(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; Header: Boolean = False): TMemSize; overload;
Function WideDecode_Base16(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; Header: Boolean = False): TMemSize; overload;

Function Decode_Base16(const Str: String; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base16(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): Pointer; overload;
Function WideDecode_Base16(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): Pointer; overload;

Function Decode_Base16(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base16(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False; Hex: Boolean = False): TMemSize; overload;
Function WideDecode_Base16(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False; Hex: Boolean = False): TMemSize; overload;

Function Decode_Hexadecimal(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Hexadecimal(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;
Function WideDecode_Hexadecimal(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;

Function Decode_Hexadecimal(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Hexadecimal(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Hexadecimal(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Decode_Base32(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base32(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Base32(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode_Base32(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base32(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Base32(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode_Base32(const Str: String; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; PaddingChar: Char; Header: Boolean = False): Pointer; overload;
Function AnsiDecode_Base32(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; PaddingChar: AnsiChar; Header: Boolean = False): Pointer; overload;
Function WideDecode_Base32(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; PaddingChar: UnicodeChar; Header: Boolean = False): Pointer; overload;

Function Decode_Base32(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; PaddingChar: Char; Header: Boolean = False): TMemSize; overload;
Function AnsiDecode_Base32(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; PaddingChar: AnsiChar; Header: Boolean = False): TMemSize; overload;
Function WideDecode_Base32(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; PaddingChar: UnicodeChar; Header: Boolean = False): TMemSize; overload;

Function Decode_Base32(const Str: String; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: Char; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base32(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: AnsiChar; Header: Boolean = False): Pointer; overload;
Function WideDecode_Base32(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: UnicodeChar; Header: Boolean = False): Pointer; overload;

Function Decode_Base32(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: Char; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base32(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: AnsiChar; Header: Boolean = False): TMemSize; overload;
Function WideDecode_Base32(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: UnicodeChar; Header: Boolean = False): TMemSize; overload;

Function Decode_Base32Hex(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base32Hex(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Base32Hex(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode_Base32Hex(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base32Hex(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Base32Hex(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Decode_Base64(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base64(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Base64(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode_Base64(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base64(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Base64(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode_Base64(const Str: String; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; PaddingChar: Char; Header: Boolean = False): Pointer; overload;
Function AnsiDecode_Base64(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; PaddingChar: AnsiChar; Header: Boolean = False): Pointer; overload;
Function WideDecode_Base64(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; PaddingChar: UnicodeChar; Header: Boolean = False): Pointer; overload;

Function Decode_Base64(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; PaddingChar: Char; Header: Boolean = False): TMemSize; overload;
Function AnsiDecode_Base64(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; PaddingChar: AnsiChar; Header: Boolean = False): TMemSize; overload;
Function WideDecode_Base64(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; PaddingChar: UnicodeChar; Header: Boolean = False): TMemSize; overload;

Function Decode_Base64(const Str: String; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: Char; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base64(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: AnsiChar; Header: Boolean = False): Pointer; overload;
Function WideDecode_Base64(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: UnicodeChar; Header: Boolean = False): Pointer; overload;

Function Decode_Base64(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: Char; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base64(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: AnsiChar; Header: Boolean = False): TMemSize; overload;
Function WideDecode_Base64(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: UnicodeChar; Header: Boolean = False): TMemSize; overload;

{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}

Function Decode_Base85(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base85(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Base85(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode_Base85(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base85(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Base85(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode_Base85(const Str: String; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; CompressionChar: Char; Header: Boolean = False): Pointer; overload;
Function AnsiDecode_Base85(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; CompressionChar: AnsiChar; Header: Boolean = False): Pointer; overload;
Function WideDecode_Base85(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; CompressionChar: UnicodeChar; Header: Boolean = False): Pointer; overload;

Function Decode_Base85(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; CompressionChar: Char; Header: Boolean = False): TMemSize; overload;
Function AnsiDecode_Base85(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; CompressionChar: AnsiChar; Header: Boolean = False): TMemSize; overload;
Function WideDecode_Base85(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; CompressionChar: UnicodeChar; Header: Boolean = False): TMemSize; overload;

Function Decode_Base85(const Str: String; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; CompressionChar: Char; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base85(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; CompressionChar: AnsiChar; Header: Boolean = False): Pointer; overload;
Function WideDecode_Base85(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; CompressionChar: UnicodeChar; Header: Boolean = False): Pointer; overload;

Function Decode_Base85(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; CompressionChar: Char; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Base85(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; CompressionChar: AnsiChar; Header: Boolean = False): TMemSize; overload;
Function WideDecode_Base85(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; CompressionChar: UnicodeChar; Header: Boolean = False): TMemSize; overload;

Function Decode_Ascii85(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Ascii85(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Ascii85(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer; overload;{$IFDEF CanInline} inline; {$ENDIF}

Function Decode_Ascii85(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function AnsiDecode_Ascii85(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}
Function WideDecode_Ascii85(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize; overload;{$IFDEF CanInline} inline; {$ENDIF}


implementation

uses
  Math;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W4055:={$WARN 4055 OFF}} // Conversion between ordinals and pointers is not portable
  {$DEFINE W4056:={$WARN 4056 OFF}} // Conversion between ordinals and pointers is not portable
  {$DEFINE W5058:={$WARN 5058 OFF}} // Variable "$1" does not seem to be initialized
{$ENDIF}

const
  HeaderLength = Length(AnsiEncodingHeaderStart + '00' + AnsiEncodingHeaderEnd);

  HexadecimalHeaderLength = Length(AnsiEncodingHexadecimal);

  ENCNUM_BASE2     = 2;
  ENCNUM_BASE8     = 8;
  ENCNUM_BASE10    = 10;
  ENCNUM_BASE16    = 16;
  ENCNUM_BASE32    = 32;
  ENCNUM_BASE32HEX = 127;
  ENCNUM_BASE64    = 64;
  ENCNUM_BASE85    = 85;
  ENCNUM_ASCII85   = 126;

  Coefficients_Base10: array[1..3] of UInt16 = (100,10,1);
  Coefficients_Base85: array[1..5] of UInt32 = (52200625,614125,7225,85,1);

{===============================================================================
--------------------------------------------------------------------------------
                              Auxiliary functions
--------------------------------------------------------------------------------
===============================================================================}

Function GetEncodingNumber(Encoding: TBinTextEncoding): Byte;
begin
case Encoding of
  bteBase2:       Result := ENCNUM_BASE2;
  bteBase8:       Result := ENCNUM_BASE8;
  bteBase10:      Result := ENCNUM_BASE10;
  bteBase16:      Result := ENCNUM_BASE16;
  bteHexadecimal: raise EUnsupportedEncoding.Create('GetEncodingNumber: Hexadecimal encoding is not supported by this function.');
  bteBase32:      Result := ENCNUM_BASE32;
  bteBase32Hex:   Result := ENCNUM_BASE32HEX;
  bteBase64:      Result := ENCNUM_BASE64;
  bteBase85:      Result := ENCNUM_BASE85;
  bteAscii85:     Result := ENCNUM_ASCII85;
else
  raise EUnknownEncoding.CreateFmt('GetEncodingNumber: Unknown encoding (%d).',[Ord(Encoding)]);
end;
end;

{------------------------------------------------------------------------------}

procedure ResolveDataPointer(var Ptr: Pointer; Reversed: Boolean; Size: TMemSize; EndOffset: UInt32 = 1);{$IFDEF CanInline} inline; {$ENDIF}
begin
If Reversed and Assigned(Ptr) then
{$IFDEF FPCDWM}{$PUSH}W4055 W4056{$ENDIF}
  Ptr := Pointer(PtrUInt(Ptr) + (PtrUInt(Size) - PtrUInt(EndOffset)));
{$IFDEF FPCDWM}{$POP}{$ENDIF}
end;

{------------------------------------------------------------------------------}

procedure AdvanceDataPointer(var Ptr: Pointer; Reversed: Boolean; Step: Byte = 1);{$IFDEF CanInline} inline; {$ENDIF}
begin
{$IFDEF FPCDWM}{$PUSH}W4055 W4056{$ENDIF}
If Reversed then
  Ptr := Pointer(PtrUInt(Ptr) - Step)
else
  Ptr := Pointer(PtrUInt(Ptr) + Step);
{$IFDEF FPCDWM}{$POP}{$ENDIF}
end;

{------------------------------------------------------------------------------}

procedure DecodeCheckSize(Size, Required: TMemSize; Base: Integer; MaxError: UInt32 = 0);{$IFDEF CanInline} inline; {$ENDIF}
begin
If (Size + MaxError) < Required then
  raise EAllocationError.CreateFmt('DecodeCheckSize[base%d]: Output buffer too small (%d, required %d).',[Base,Size,Required]);
end;

{------------------------------------------------------------------------------}

Function AnsiDecodeFromTable(const aChar: AnsiChar; const Table: TDecodingTable; Base: Integer): Byte;
begin
If Byte(Ord(aChar)) < 128 then
  Result := Table[Ord(aChar) and $7F]
else
  Result := 255;
If Result >= 255 then
  raise EInvalidCharacter.CreateFmt('AnsiDecodeFromTable[base%d]: Invalid character "%s" (#%d).',[Base,aChar,Ord(aChar)]);
end;

{------------------------------------------------------------------------------}

Function WideDecodeFromTable(const aChar: WideChar; const Table: TDecodingTable; Base: Integer): Byte;
begin
If Word(Ord(aChar)) < 128 then
  Result := Table[Ord(aChar) and $7F]
else
  Result := 255;
If Result >= 255 then
  raise EInvalidCharacter.CreateFmt('WideDecodeFromTable[base%d]: Invalid character "%s" (#%d).',[Base,aChar,Ord(aChar)]);
end;

{------------------------------------------------------------------------------}

Function AnsiCountPadding(const Str: AnsiString; PaddingChar: AnsiChar): TStrSize;
var
  i:  TStrSize;
begin
Result := 0;
For i := Length(Str) downto 1 do
  If Str[i] = PaddingChar then
    Inc(Result)
  else
    Break{For i};
end;

{------------------------------------------------------------------------------}

Function WideCountPadding(const Str: UnicodeString; PaddingChar: UnicodeChar): TStrSize;
var
  i:  TStrSize;
begin
Result := 0;
For i := Length(Str) downto 1 do
  If Str[i] = PaddingChar then
    Inc(Result)
  else
    Break{For i};
end;

{------------------------------------------------------------------------------}

Function AnsiCorrectionForBase85(const Str: AnsiString; CompressionChar: AnsiChar): TStrSize;
var
  i:  Integer;
begin
Result := 0;
For i := 1 to Length(Str) do
  begin
    If Str[i] = CompressionChar then
      Inc(Result,4)
    else If (Ord(Str[i]) <= 32) or (Ord(Str[i]) >= 127) then
      Dec(Result);
  end;
end;

{------------------------------------------------------------------------------}

Function WideCorrectionForBase85(const Str: UnicodeString; CompressionChar: UnicodeChar): TStrSize;
var
  i:  Integer;
begin
Result := 0;
For i := 1 to Length(Str) do
  begin
    If Str[i] = CompressionChar then
      Inc(Result,4)
    else If (Ord(Str[i]) <= 32) or (Ord(Str[i]) >= 127) then
      Dec(Result);
  end;
end;

{------------------------------------------------------------------------------}

procedure SwapByteOrder(var Value: UInt32); register; {$IFNDEF PurePascal}assembler;
asm
  MOV     EDX, [Value]
  BSWAP   EDX
  MOV     [Value], EDX
end;
{$ELSE}
begin
Value := UInt32((Value and $000000FF shl 24) or (Value and $0000FF00 shl 8) or
                (Value and $00FF0000 shr 8) or (Value and $FF000000 shr 24));
end;
{$ENDIF}


{===============================================================================
--------------------------------------------------------------------------------
                              Universal functions
--------------------------------------------------------------------------------
===============================================================================}

Function BuildDecodingTable(EncodingTable: array of Char): TDecodingTable;
begin
{$IFDEF Unicode}
Result := WideBuildDecodingTable(EncodingTable);
{$ELSE}
Result := AnsiBuildDecodingTable(EncodingTable);
{$ENDIF}
end;


{------------------------------------------------------------------------------}

Function AnsiBuildDecodingTable(EncodingTable: array of AnsiChar): TDecodingTable;
var
  i:  Integer;
begin
FillChar(Addr(Result)^,SizeOf(Result),$FF);
For i := Low(EncodingTable) to High(EncodingTable) do
  Result[Ord(EncodingTable[i])] := i;
end;

{------------------------------------------------------------------------------}

Function WideBuildDecodingTable(EncodingTable: array of UnicodeChar): TDecodingTable;
var
  i:  Integer;
begin
FillChar(Addr(Result)^,SizeOf(Result),$FF);
For i := Low(EncodingTable) to High(EncodingTable) do
  Result[Ord(EncodingTable[i])] := i;
end;

{------------------------------------------------------------------------------}

Function BuildHeader(Encoding: TBinTextEncoding; Reversed: Boolean): String;
begin
{$IFDEF Unicode}
Result := WideBuildHeader(Encoding,Reversed);
{$ELSE}
Result := AnsiBuildHeader(Encoding,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiBuildHeader(Encoding: TBinTextEncoding; Reversed: Boolean): AnsiString;
var
  EncodingNum:  Byte;
begin
If Encoding = bteHexadecimal then
  Result := AnsiEncodingHexadecimal
else
  begin
    EncodingNum := GetEncodingNumber(Encoding);
    If Reversed then
      EncodingNum := EncodingNum or $80
    else
      EncodingNum := EncodingNum and $7F;
    Result := AnsiEncodingHeaderStart +
              AnsiEncode_Hexadecimal(@EncodingNum,SizeOf(EncodingNum),False) +
              AnsiEncodingHeaderEnd;
  end;
end;

{------------------------------------------------------------------------------}

Function WideBuildHeader(Encoding: TBinTextEncoding; Reversed: Boolean): UnicodeString;
var
  EncodingNum:  Byte;
begin
If Encoding = bteHexadecimal then
  Result := WideEncodingHexadecimal
else
  begin
    EncodingNum := GetEncodingNumber(Encoding);
    If Reversed then
      EncodingNum := EncodingNum or $80
    else
      EncodingNum := EncodingNum and $7F;
    Result := WideEncodingHeaderStart +
              WideEncode_Hexadecimal(@EncodingNum,SizeOf(EncodingNum),False) +
              WideEncodingHeaderEnd;
  end;
end;

{------------------------------------------------------------------------------}

Function GetEncoding(const Str: String; out Reversed: Boolean): TBinTextEncoding;
begin
{$IFDEF Unicode}
Result := WideGetEncoding(Str,Reversed);
{$ELSE}
Result := AnsiGetEncoding(Str,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiGetEncoding(const Str: AnsiString; out Reversed: Boolean): TBinTextEncoding;
var
  EncByte:  Byte;
begin
If Length(Str) > 0 then
  begin
    case Str[1] of
{---  ----    ----    ----    ----    ----    ----    ----    ----    ----  ---}
      AnsiEncodingHexadecimal:
        begin
          Reversed := False;
          Result := bteHexadecimal;
        end;
{---  ----    ----    ----    ----    ----    ----    ----    ----    ----  ---}
      AnsiEncodingHeaderStart:
        begin
          If Length(Str) >= HeaderLength then
            begin
              If Str[HeaderLength] = AnsiEncodingHeaderEnd then
                begin
                  AnsiDecode_Hexadecimal(Copy(Str,1 + Length(AnsiEncodingHeaderStart),2),@EncByte,SizeOf(EncByte),False);
                  Reversed := (EncByte and $80) <> 0;
                  case (EncByte and $7F) of
                    ENCNUM_BASE2:     Result := bteBase2;
                    ENCNUM_BASE8:     Result := bteBase8;
                    ENCNUM_BASE10:    Result := bteBase10;
                    ENCNUM_BASE16:    Result := bteBase16;
                    ENCNUM_BASE32:    Result := bteBase32;
                    ENCNUM_BASE32HEX: Result := bteBase32Hex;
                    ENCNUM_BASE64:    Result := bteBase64;
                    ENCNUM_BASE85:    Result := bteBase85;
                    ENCNUM_ASCII85:   Result := bteAscii85;
                  else
                    Result := bteUnknown;
                  end;
                end
              else Result := bteUnknown;
            end
          else Result := bteUnknown;
        end;
{---  ----    ----    ----    ----    ----    ----    ----    ----    ----  ---}
    else
      Result := bteUnknown;
    end;
  end
else Result := bteUnknown;
end;

{------------------------------------------------------------------------------}

Function WideGetEncoding(const Str: UnicodeString; out Reversed: Boolean): TBinTextEncoding;
var
  EncByte:  Byte;
begin
If Length(Str) > 0 then
  begin
    case Str[1] of
{---  ----    ----    ----    ----    ----    ----    ----    ----    ----  ---}
      WideEncodingHexadecimal:
        begin
          Reversed := False;
          Result := bteHexadecimal;
        end;
{---  ----    ----    ----    ----    ----    ----    ----    ----    ----  ---}
      WideEncodingHeaderStart:
        begin
          If Length(Str) >= HeaderLength then
            begin
              If Str[HeaderLength] = AnsiEncodingHeaderEnd then
                begin
                  WideDecode_Hexadecimal(Copy(Str,1 + Length(WideEncodingHeaderStart),2),@EncByte,SizeOf(EncByte),False);
                  Reversed := (EncByte and $80) <> 0;
                  case (EncByte and $7F) of
                    ENCNUM_BASE2:     Result := bteBase2;
                    ENCNUM_BASE8:     Result := bteBase8;
                    ENCNUM_BASE10:    Result := bteBase10;
                    ENCNUM_BASE16:    Result := bteBase16;
                    ENCNUM_BASE32:    Result := bteBase32;
                    ENCNUM_BASE32HEX: Result := bteBase32Hex;
                    ENCNUM_BASE64:    Result := bteBase64;
                    ENCNUM_BASE85:    Result := bteBase85;
                    ENCNUM_ASCII85:   Result := bteAscii85;
                  else
                    Result := bteUnknown;
                  end;
                end
              else Result := bteUnknown;
            end
          else Result := bteUnknown;
        end;
{---  ----    ----    ----    ----    ----    ----    ----    ----    ----  ---}
    else
      Result := bteUnknown;
    end;
  end
else Result := bteUnknown;
end;

{==============================================================================}

Function EncodedLength(Encoding: TBinTextEncoding; DataSize: TMemSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;
begin
case Encoding of
  bteBase2:       Result := EncodedLength_Base2(DataSize,Header);
  bteBase8:       Result := EncodedLength_Base8(DataSize,Header,Padding);
  bteBase10:      Result := EncodedLength_Base10(DataSize,Header);
  bteBase16:      Result := EncodedLength_Base16(DataSize,Header);
  bteHexadecimal: Result := EncodedLength_Hexadecimal(DataSize,Header);
  bteBase32:      Result := EncodedLength_Base32Hex(DataSize,Header,Padding);
  bteBase32Hex:   Result := EncodedLength_Base32(DataSize,Header,Padding);
  bteBase64:      Result := EncodedLength_Base64(DataSize,Header,Padding);
  bteBase85:      raise EUnsupportedEncoding.Create('EncodedLength: Base85 encoding is not supported by this function.');
  bteAscii85:     raise EUnsupportedEncoding.Create('EncodedLength: Ascii85 encoding is not supported by this function.');
else
  raise EUnknownEncoding.CreateFmt('EncodedLength: Unknown encoding (%d).',[Ord(Encoding)]);
end;
end;

{==============================================================================}

Function DecodedLength(Encoding: TBinTextEncoding; const Str: String; Header: Boolean = True): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength(Encoding,Str,Header);
{$ELSE}
Result := AnsiDecodedLength(Encoding,Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength(Encoding: TBinTextEncoding; const Str: AnsiString; Header: Boolean = True): TMemSize;
begin
case Encoding of
  bteBase2:       Result := AnsiDecodedLength_Base2(Str,Header);
  bteBase8:       Result := AnsiDecodedLength_Base8(Str,Header,AnsiPaddingChar_Base8);
  bteBase10:      Result := AnsiDecodedLength_Base10(Str,Header);
  bteBase16:      Result := AnsiDecodedLength_Base16(Str,Header);
  bteHexadecimal: Result := AnsiDecodedLength_Hexadecimal(Str,Header);
  bteBase32:      Result := AnsiDecodedLength_Base32(Str,Header,AnsiPaddingChar_Base32);
  bteBase32Hex:   Result := AnsiDecodedLength_Base32Hex(Str,Header,AnsiPaddingChar_Base32Hex);
  bteBase64:      Result := AnsiDecodedLength_Base64(Str,Header,AnsiPaddingChar_Base64);
  bteBase85:      Result := AnsiDecodedLength_Base85(Str,Header,AnsiCompressionChar_Base85);
  bteAscii85:     Result := AnsiDecodedLength_Ascii85(Str,Header);
else
  raise EUnknownEncoding.CreateFmt('AnsiDecodedLength: Unknown encoding (%d).',[Ord(Encoding)]);
end;
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength(Encoding: TBinTextEncoding; const Str: UnicodeString; Header: Boolean = True): TMemSize;
begin
case Encoding of
  bteBase2:       Result := WideDecodedLength_Base2(Str,Header);
  bteBase8:       Result := WideDecodedLength_Base8(Str,Header,WidePaddingChar_Base8);
  bteBase10:      Result := WideDecodedLength_Base10(Str,Header);
  bteBase16:      Result := WideDecodedLength_Base16(Str,Header);
  bteHexadecimal: Result := WideDecodedLength_Hexadecimal(Str,Header);
  bteBase32:      Result := WideDecodedLength_Base32(Str,Header,WidePaddingChar_Base32);
  bteBase32Hex:   Result := WideDecodedLength_Base32Hex(Str,Header,WidePaddingChar_Base32Hex);
  bteBase64:      Result := WideDecodedLength_Base64(Str,Header,WidePaddingChar_Base64);
  bteBase85:      Result := WideDecodedLength_Base85(Str,Header,WideCompressionChar_Base85);
  bteAscii85:     Result := WideDecodedLength_Ascii85(Str,Header);
else
  raise EUnknownEncoding.CreateFmt('WideDecodedLength: Unknown encoding (%d).',[Ord(Encoding)]);
end;
end;

{==============================================================================}

Function Encode(Encoding: TBinTextEncoding; Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True): String;
begin
{$IFDEF Unicode}
Result := WideEncode(Encoding,Data,Size,Reversed,Padding);
{$ELSE}
Result := AnsiEncode(Encoding,Data,Size,Reversed,Padding);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode(Encoding: TBinTextEncoding; Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True): AnsiString;
begin
case Encoding of
  bteBase2:       Result := AnsiEncode_Base2(Data,Size,Reversed,AnsiBuildHeader(Encoding,Reversed));
  bteBase8:       Result := AnsiEncode_Base8(Data,Size,Reversed,Padding,AnsiBuildHeader(Encoding,Reversed));
  bteBase10:      Result := AnsiEncode_Base10(Data,Size,Reversed,AnsiBuildHeader(Encoding,Reversed));
  bteBase16:      Result := AnsiEncode_Base16(Data,Size,Reversed,AnsiBuildHeader(Encoding,Reversed));
  bteHexadecimal: Result := AnsiEncode_Hexadecimal(Data,Size,False,AnsiBuildHeader(Encoding,Reversed));
  bteBase32:      Result := AnsiEncode_Base32(Data,Size,Reversed,Padding,AnsiBuildHeader(Encoding,Reversed));
  bteBase32Hex:   Result := AnsiEncode_Base32Hex(Data,Size,Reversed,Padding,AnsiBuildHeader(Encoding,Reversed));
  bteBase64:      Result := AnsiEncode_Base64(Data,Size,Reversed,Padding,AnsiBuildHeader(Encoding,Reversed));
  bteBase85:      Result := AnsiEncode_Base85(Data,Size,Reversed,True,not Padding,AnsiBuildHeader(Encoding,Reversed));
  bteAscii85:     Result := AnsiEncode_Ascii85(Data,Size,Reversed,True,not Padding,AnsiBuildHeader(Encoding,Reversed));
else
  raise EUnknownEncoding.CreateFmt('AnsiEncode: Unknown encoding (%d).',[Ord(Encoding)]);
end;
end;

{------------------------------------------------------------------------------}

Function WideEncode(Encoding: TBinTextEncoding; Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True): UnicodeString;
begin
case Encoding of
  bteBase2:       Result := WideEncode_Base2(Data,Size,Reversed,WideBuildHeader(Encoding,Reversed));
  bteBase8:       Result := WideEncode_Base8(Data,Size,Reversed,Padding,WideBuildHeader(Encoding,Reversed));
  bteBase10:      Result := WideEncode_Base10(Data,Size,Reversed,WideBuildHeader(Encoding,Reversed));
  bteBase16:      Result := WideEncode_Base16(Data,Size,Reversed,WideBuildHeader(Encoding,Reversed));
  bteHexadecimal: Result := WideEncode_Hexadecimal(Data,Size,False,WideBuildHeader(Encoding,Reversed));
  bteBase32:      Result := WideEncode_Base32(Data,Size,Reversed,Padding,WideBuildHeader(Encoding,Reversed));
  bteBase32Hex:   Result := WideEncode_Base32Hex(Data,Size,Reversed,Padding,WideBuildHeader(Encoding,Reversed));
  bteBase64:      Result := WideEncode_Base64(Data,Size,Reversed,Padding,WideBuildHeader(Encoding,Reversed));
  bteBase85:      Result := WideEncode_Base85(Data,Size,Reversed,True,not Padding,WideBuildHeader(Encoding,Reversed));
  bteAscii85:     Result := WideEncode_Ascii85(Data,Size,Reversed,True,not Padding,WideBuildHeader(Encoding,Reversed));
else
  raise EUnknownEncoding.CreateFmt('WideEncode: Unknown encoding (%d).',[Ord(Encoding)]);
end;
end;

{==============================================================================}

Function Decode(const Str: String; out Size: TMemSize): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode(Str,Size);
{$ELSE}
Result := AnsiDecode(Str,Size);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode(const Str: AnsiString; out Size: TMemSize): Pointer;
var
  Encoding: TBinTextEncoding;
begin
Result := AnsiDecode(Str,Size,Encoding);
end;

{------------------------------------------------------------------------------}

Function WideDecode(const Str: UnicodeString; out Size: TMemSize): Pointer;
var
  Encoding: TBinTextEncoding;
begin
Result := WideDecode(Str,Size,Encoding);
end;

{------------------------------------------------------------------------------}

Function Decode(const Str: String; out Size: TMemSize; out Encoding: TBinTextEncoding): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode(Str,Size,Encoding);
{$ELSE}
Result := AnsiDecode(Str,Size,Encoding);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode(const Str: AnsiString; out Size: TMemSize; out Encoding: TBinTextEncoding): Pointer;
var
  Reversed: Boolean;
begin
Result := AnsiDecode(Str,Size,Encoding,Reversed);
end;

{------------------------------------------------------------------------------}

Function WideDecode(const Str: UnicodeString; out Size: TMemSize; out Encoding: TBinTextEncoding): Pointer;
var
  Reversed: Boolean;
begin
Result := WideDecode(Str,Size,Encoding,Reversed);
end;

{------------------------------------------------------------------------------}

Function Decode(const Str: String; out Size: TMemSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode(Str,Size,Encoding,Reversed);
{$ELSE}
Result := AnsiDecode(Str,Size,Encoding,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode(const Str: AnsiString; out Size: TMemSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): Pointer;
begin
Encoding := AnsiGetEncoding(Str,Reversed);
case Encoding of
  bteBase2:       Result := AnsiDecode_Base2(Str,Size,Reversed,True);
  bteBase8:       Result := AnsiDecode_Base8(Str,Size,Reversed,True);
  bteBase10:      Result := AnsiDecode_Base10(Str,Size,Reversed,True);
  bteBase16:      Result := AnsiDecode_Base16(Str,Size,Reversed,True);
  bteHexadecimal: Result := AnsiDecode_Hexadecimal(Str,Size,Reversed,True);
  bteBase32:      Result := AnsiDecode_Base32(Str,Size,Reversed,True);
  bteBase32Hex:   Result := AnsiDecode_Base32Hex(Str,Size,Reversed,True);
  bteBase64:      Result := AnsiDecode_Base64(Str,Size,Reversed,True);
  bteBase85:      Result := AnsiDecode_Base85(Str,Size,Reversed,True);
  bteAscii85:     Result := AnsiDecode_Ascii85(Str,Size,Reversed,True);
else
  raise EUnknownEncoding.CreateFmt('AnsiDecode: Unknown encoding (%d).',[Ord(Encoding)]);
end;
end;

{------------------------------------------------------------------------------}

Function WideDecode(const Str: UnicodeString; out Size: TMemSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): Pointer;
begin
Encoding := WideGetEncoding(Str,Reversed);
case Encoding of
  bteBase2:       Result := WideDecode_Base2(Str,Size,Reversed,True);
  bteBase8:       Result := WideDecode_Base8(Str,Size,Reversed,True);
  bteBase10:      Result := WideDecode_Base10(Str,Size,Reversed,True);
  bteBase16:      Result := WideDecode_Base16(Str,Size,Reversed,True);
  bteHexadecimal: Result := WideDecode_Hexadecimal(Str,Size,Reversed,True);
  bteBase32:      Result := WideDecode_Base32(Str,Size,Reversed,True);
  bteBase32Hex:   Result := WideDecode_Base32Hex(Str,Size,Reversed,True);
  bteBase64:      Result := WideDecode_Base64(Str,Size,Reversed,True);
  bteBase85:      Result := WideDecode_Base85(Str,Size,Reversed,True);
  bteAscii85:     Result := WideDecode_Ascii85(Str,Size,Reversed,True);
else
  raise EUnknownEncoding.CreateFmt('WideDecode: Unknown encoding (%d).',[Ord(Encoding)]);
end;
end;

{------------------------------------------------------------------------------}

Function Decode(const Str: String; Ptr: Pointer; Size: TMemSize): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode(Str,Ptr,Size);
{$ELSE}
Result := AnsiDecode(Str,Ptr,Size);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode(const Str: AnsiString; Ptr: Pointer; Size: TMemSize): TMemSize;
var
  Encoding: TBinTextEncoding;
begin
Result := AnsiDecode(Str,Ptr,Size,Encoding);
end;

{------------------------------------------------------------------------------}

Function WideDecode(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize): TMemSize;
var
  Encoding: TBinTextEncoding;
begin
Result := WideDecode(Str,Ptr,Size,Encoding);
end;

{------------------------------------------------------------------------------}

Function Decode(const Str: String; Ptr: Pointer; Size: TMemSize; out Encoding: TBinTextEncoding): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode(Str,Ptr,Size,Encoding);
{$ELSE}
Result := AnsiDecode(Str,Ptr,Size,Encoding);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; out Encoding: TBinTextEncoding): TMemSize;
var
  Reversed: Boolean;
begin
Result := AnsiDecode(Str,Ptr,Size,Encoding,Reversed);
end;

{------------------------------------------------------------------------------}

Function WideDecode(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; out Encoding: TBinTextEncoding): TMemSize;
var
  Reversed: Boolean;
begin
Result := WideDecode(Str,Ptr,Size,Encoding,Reversed);
end;

{------------------------------------------------------------------------------}

Function Decode(const Str: String; Ptr: Pointer; Size: TMemSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode(Str,Ptr,Size,Encoding,Reversed);
{$ELSE}
Result := AnsiDecode(Str,Ptr,Size,Encoding,Reversed);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): TMemSize;
begin
Encoding := AnsiGetEncoding(Str,Reversed);
case Encoding of
  bteBase2:       Result := AnsiDecode_Base2(Str,Ptr,Size,Reversed,True);
  bteBase8:       Result := AnsiDecode_Base8(Str,Ptr,Size,Reversed,True);
  bteBase10:      Result := AnsiDecode_Base10(Str,Ptr,Size,Reversed,True);
  bteBase16:      Result := AnsiDecode_Base16(Str,Ptr,Size,Reversed,True);
  bteHexadecimal: Result := AnsiDecode_Hexadecimal(Str,Ptr,Size,Reversed,True);
  bteBase32:      Result := AnsiDecode_Base32(Str,Ptr,Size,Reversed,True);
  bteBase32Hex:   Result := AnsiDecode_Base32Hex(Str,Ptr,Size,Reversed,True);
  bteBase64:      Result := AnsiDecode_Base64(Str,Ptr,Size,Reversed,True);
  bteBase85:      Result := AnsiDecode_Base85(Str,Ptr,Size,Reversed,True);
  bteAscii85:     Result := AnsiDecode_Ascii85(Str,Ptr,Size,Reversed,True);
else
  raise EUnknownEncoding.CreateFmt('AnsiDecode: Unknown encoding (%d).',[Ord(Encoding)]);
end;
end;

{------------------------------------------------------------------------------}

Function WideDecode(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; out Encoding: TBinTextEncoding; out Reversed: Boolean): TMemSize;
begin
Encoding := WideGetEncoding(Str,Reversed);
case Encoding of
  bteBase2:       Result := WideDecode_Base2(Str,Ptr,Size,Reversed,True);
  bteBase8:       Result := WideDecode_Base8(Str,Ptr,Size,Reversed,True);
  bteBase10:      Result := WideDecode_Base10(Str,Ptr,Size,Reversed,True);
  bteBase16:      Result := WideDecode_Base16(Str,Ptr,Size,Reversed,True);
  bteHexadecimal: Result := WideDecode_Hexadecimal(Str,Ptr,Size,Reversed,True);
  bteBase32:      Result := WideDecode_Base32(Str,Ptr,Size,Reversed,True);
  bteBase32Hex:   Result := WideDecode_Base32Hex(Str,Ptr,Size,Reversed,True);
  bteBase64:      Result := WideDecode_Base64(Str,Ptr,Size,Reversed,True);
  bteBase85:      Result := WideDecode_Base85(Str,Ptr,Size,Reversed,True);
  bteAscii85:     Result := WideDecode_Ascii85(Str,Ptr,Size,Reversed,True);
else
  raise EUnknownEncoding.CreateFmt('WideDecode: Unknown encoding (%d).',[Ord(Encoding)]);
end;
end;


{===============================================================================
--------------------------------------------------------------------------------
                  Functions calculating length of encoded text
                    from size of data that has to be encoded
--------------------------------------------------------------------------------
===============================================================================}

Function EncodedLength_Base2(DataSize: TMemSize; Header: Boolean = False): TStrSize;
begin
If DataSize <= TMemSize(High(TStrSize) div 8) then
  begin
    Result := DataSize * 8;
    If Header then
      begin
        If (TMemSize(Result) + TMemSize(HeaderLength)) <= TMemSize(High(TStrSize)) then Result := Result + HeaderLength
          else raise EHeaderWontFit.Create('EncodedLength_Base2: Header won''t fit into resulting string.');
      end;
  end
else raise ETooMuchData.CreateFmt('EncodedLength_Base2: Too much data (%d).',[DataSize]);
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base8(DataSize: TMemSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;
var
  Temp: TMemSize;
begin
If Padding then Temp := Ceil(DataSize / 3) * 8
  else Temp := Ceil(DataSize * (8/3));
If Temp <= TMemSize(High(TStrSize)) then
  begin
    Result := Temp;
    If Header then
      begin
        If (TMemSize(Result) + TMemSize(HeaderLength)) <= TMemSize(High(TStrSize)) then Result := Result + HeaderLength
          else raise EHeaderWontFit.Create('EncodedLength_Base8: Header won''t fit into resulting string.');
      end;
  end
else raise ETooMuchData.CreateFmt('EncodedLength_Base8: Too much data (%d).',[DataSize]);
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base10(DataSize: TMemSize; Header: Boolean = False): TStrSize;
begin
If DataSize <= TMemSize(High(TStrSize) div 3) then
  begin
    Result := DataSize * 3;
    If Header then
      begin
        If (TMemSize(Result) + TMemSize(HeaderLength)) <= TMemSize(High(TStrSize)) then Result := Result + HeaderLength
          else raise EHeaderWontFit.Create('EncodedLength_Base10: Header won''t fit into resulting string.');
      end;
  end
else raise ETooMuchData.CreateFmt('EncodedLength_Base10: Too much data (%d).',[DataSize]);
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base16(DataSize: TMemSize; Header: Boolean = False): TStrSize;
begin
If DataSize <= TMemSize(High(TStrSize) div 2) then
  begin
    Result := DataSize * 2;
    If Header then
      begin
        If (TMemSize(Result) + TMemSize(HeaderLength)) <= TMemSize(High(TStrSize)) then Result := Result + HeaderLength
          else raise EHeaderWontFit.Create('EncodedLength_Base16: Header won''t fit into resulting string.');
      end;
  end
else raise ETooMuchData.CreateFmt('EncodedLength_Base16: Too much data (%d).',[DataSize]);
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Hexadecimal(DataSize: TMemSize; Header: Boolean = False): TStrSize;
begin
If DataSize <= TMemSize(High(TStrSize) div 2) then
  begin
    Result := DataSize * 2;
    If Header then
      begin
        If (TMemSize(Result) + TMemSize(HexadecimalHeaderLength)) <= TMemSize(High(TStrSize)) then Result := Result + HexadecimalHeaderLength
          else raise EHeaderWontFit.Create('EncodedLength_Hexadecimal: Header won''t fit into resulting string.');
      end;
  end
else raise ETooMuchData.CreateFmt('EncodedLength_Hexadecimal: Too much data (%d).',[DataSize]);
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base32(DataSize: TMemSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;
var
  Temp: TMemSize;
begin
If Padding then Temp := Ceil(DataSize / 5) * 8
  else Temp := Ceil(DataSize * (8/5));
If Temp <= TMemSize(High(TStrSize)) then
  begin
    Result := Temp;
    If Header then
      begin
        If (TMemSize(Result) + TMemSize(HeaderLength)) <= TMemSize(High(TStrSize)) then Result := Result + HeaderLength
          else raise EHeaderWontFit.Create('EncodedLength_Base32: Header won''t fit into resulting string.');
      end;
  end
else raise ETooMuchData.CreateFmt('EncodedLength_Base32: Too much data (%d).',[DataSize]);
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base32Hex(DataSize: TMemSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;
begin
Result := EncodedLength_Base32(DataSize,Header,Padding);
end;

{------------------------------------------------------------------------------}

Function EncodedLength_Base64(DataSize: TMemSize; Header: Boolean = False; Padding: Boolean = True): TStrSize;
var
  Temp: TMemSize;
begin
If Padding then Temp := Ceil(DataSize / 3) * 4
  else Temp := Ceil(DataSize * (4/3));
If Temp <= TMemSize(High(TStrSize)) then
  begin
    Result := Temp;
    If Header then
      begin
        If (TMemSize(Result) + TMemSize(HeaderLength)) <= TMemSize(High(TStrSize)) then Result := Result + HeaderLength
          else raise EHeaderWontFit.Create('EncodedLength_Base64: Header won''t fit into resulting string.');
      end;
  end
else raise ETooMuchData.CreateFmt('EncodedLength_Base64: Too much data (%d).',[DataSize]);
end;

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function EncodedLength_Base85(Data: Pointer; DataSize: TMemSize; Reversed: Boolean; Header: Boolean = False; Compression: Boolean = True; Trim: Boolean = True): TStrSize;
var
  Temp: TMemSize;

  Function CountCompressible(Ptr: PUInt32): TMemSize;
  var
    ii: TMemSize;
  begin
    Result := 0;
    ResolveDataPointer(Pointer(Ptr),Reversed,DataSize,4);
    For ii := 1 to (DataSize div 4) do
      begin
        If PUInt32(Ptr)^ = 0 then Inc(Result);
        AdvanceDataPointer(Pointer(Ptr),Reversed,4)
      end;
  end;

begin
If Trim then Temp := TMemSize(Ceil(DataSize / 4)) + DataSize
  else Temp := TMemSize(Ceil(DataSize / 4)) * 5;
If Compression then Temp := Temp - (CountCompressible(Data) * Int64(4));
If Temp <= TMemSize(High(TStrSize)) then
  begin
    Result := Temp;
    If Header then
      begin
        If (TMemSize(Result) + TMemSize(HeaderLength)) <= TMemSize(High(TStrSize)) then Result := Result + HeaderLength
          else raise EHeaderWontFit.Create('EncodedLength_Base85: Header won''t fit into resulting string.');
      end;
  end
else raise ETooMuchData.CreateFmt('EncodedLength_Base85: Too much data (%d).',[DataSize]);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

Function EncodedLength_Ascii85(Data: Pointer; DataSize: TMemSize; Reversed: Boolean; Header: Boolean = False; Compression: Boolean = True; Trim: Boolean = True): TStrSize;
begin
Result := EncodedLength_Base85(Data,DataSize,Reversed,Header,Compression,Trim);
end;


{===============================================================================
--------------------------------------------------------------------------------
                   Functions calculating size of encoded data
                          from length of encoded text
--------------------------------------------------------------------------------
===============================================================================}

Function DecodedLength_Base2(const Str: String; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base2(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base2(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base2(const Str: AnsiString; Header: Boolean = False): TMemSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := (Length(Str) - HeaderLength) div 8
    else
      raise EEncodedTextTooShort.Create('AnsiDecodedLength_Base2: Encoded text is too short to contain valid header.');
  end
else Result := Length(Str) div 8;
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base2(const Str: UnicodeString; Header: Boolean = False): TMemSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := (Length(Str) - HeaderLength) div 8
    else
      raise EEncodedTextTooShort.Create('WideDecodedLength_Base2: Encoded text is too short to contain valid header.');
  end
else Result := Length(Str) div 8;
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base8(const Str: String; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base8(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base8(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base8(const Str: AnsiString; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecodedLength_Base8(Str,Header,AnsiPaddingChar_Base8);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base8(const Str: UnicodeString; Header: Boolean = False): TMemSize;
begin
Result := WideDecodedLength_Base8(Str,Header,WidePaddingChar_Base8);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base8(const Str: String; Header: Boolean; PaddingChar: Char): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base8(Str,Header,PaddingChar);
{$ELSE}
Result := AnsiDecodedLength_Base8(Str,Header,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base8(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): TMemSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := Floor((((Length(Str) - HeaderLength) - AnsiCountPadding(Str,PaddingChar)) / 8) * 3)
    else
      raise EEncodedTextTooShort.Create('AnsiDecodedLength_Base8: Encoded text is too short to contain valid header.');
  end
else Result := Floor(((Length(Str) - AnsiCountPadding(Str,PaddingChar)) / 8) * 3);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base8(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): TMemSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := Floor((((Length(Str) - HeaderLength) - WideCountPadding(Str,PaddingChar)) / 8) * 3)
    else
      raise EEncodedTextTooShort.Create('WideDecodedLength_Base8: Encoded text is too short to contain valid header.');
  end
else Result := Floor(((Length(Str) - WideCountPadding(Str,PaddingChar)) / 8) * 3);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base10(const Str: String; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base10(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base10(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base10(const Str: AnsiString; Header: Boolean = False): TMemSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := (Length(Str) - HeaderLength) div 3
    else
      raise EEncodedTextTooShort.Create('AnsiDecodedLength_Base10: Encoded text is too short to contain valid header.');
  end
else Result := Length(Str) div 3;
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base10(const Str: UnicodeString; Header: Boolean = False): TMemSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := (Length(Str) - HeaderLength) div 3
    else
      raise EEncodedTextTooShort.Create('WideDecodedLength_Base10: Encoded text is too short to contain valid header.');
  end
else Result := Length(Str) div 3;
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base16(const Str: String; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base16(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base16(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base16(const Str: AnsiString; Header: Boolean = False): TMemSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := (Length(Str) - HeaderLength) div 2
    else
      raise EEncodedTextTooShort.Create('AnsiDecodedLength_Base16: Encoded text is too short to contain valid header.');
  end
else Result := Length(Str) div 2;
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base16(const Str: UnicodeString; Header: Boolean = False): TMemSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := (Length(Str) - HeaderLength) div 2
    else
      raise EEncodedTextTooShort.Create('WideDecodedLength_Base16: Encoded text is too short to contain valid header.');
  end
else Result := Length(Str) div 2;
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Hexadecimal(const Str: String; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Hexadecimal(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Hexadecimal(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Hexadecimal(const Str: AnsiString; Header: Boolean = False): TMemSize;
begin
If Header then
  begin
    If Length(Str) >= HexadecimalHeaderLength then
      Result := (Length(Str) - HexadecimalHeaderLength) div 2
    else
      raise EEncodedTextTooShort.Create('AnsiDecodedLength_Hexadecimal: Encoded text is too short to contain valid header.');
  end
else Result := Length(Str) div 2;
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Hexadecimal(const Str: UnicodeString; Header: Boolean = False): TMemSize;
begin
If Header then
  begin
    If Length(Str) >= HexadecimalHeaderLength then
      Result := (Length(Str) - HexadecimalHeaderLength) div 2
    else
      raise EEncodedTextTooShort.Create('WideDecodedLength_Hexadecimal: Encoded text is too short to contain valid header.');
  end
else Result := Length(Str) div 2;
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base32(const Str: String; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base32(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base32(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base32(const Str: AnsiString; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecodedLength_Base32(Str,Header,AnsiPaddingChar_Base32);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base32(const Str: UnicodeString; Header: Boolean = False): TMemSize;
begin
Result := WideDecodedLength_Base32(Str,Header,WidePaddingChar_Base32);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base32(const Str: String; Header: Boolean; PaddingChar: Char): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base32(Str,Header,PaddingChar);
{$ELSE}
Result := AnsiDecodedLength_Base32(Str,Header,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base32(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): TMemSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := Floor((((Length(Str) - HeaderLength) - AnsiCountPadding(Str,PaddingChar)) / 8) * 5)
    else
      raise EEncodedTextTooShort.Create('AnsiDecodedLength_Base32: Encoded text is too short to contain valid header.');
  end
else Result := Floor(((Length(Str) - AnsiCountPadding(Str,PaddingChar)) / 8) * 5);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base32(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): TMemSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := Floor((((Length(Str) - HeaderLength) - WideCountPadding(Str,PaddingChar)) / 8) * 5)
    else
      raise EEncodedTextTooShort.Create('WideDecodedLength_Base32: Encoded text is too short to contain valid header.');
  end
else Result := Floor(((Length(Str) - WideCountPadding(Str,PaddingChar)) / 8) * 5);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base32Hex(const Str: String; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base32Hex(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base32Hex(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base32Hex(const Str: AnsiString; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecodedLength_Base32Hex(Str,Header,AnsiPaddingChar_Base32Hex);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base32Hex(const Str: UnicodeString; Header: Boolean = False): TMemSize;
begin
Result := WideDecodedLength_Base32Hex(Str,Header,WidePaddingChar_Base32Hex);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base32Hex(const Str: String; Header: Boolean; PaddingChar: Char): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base32Hex(Str,Header,PaddingChar);
{$ELSE}
Result := AnsiDecodedLength_Base32Hex(Str,Header,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base32Hex(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): TMemSize;
begin
Result := AnsiDecodedLength_Base32(Str,Header,PaddingChar);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base32Hex(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): TMemSize;
begin
Result := WideDecodedLength_Base32(Str,Header,PaddingChar);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base64(const Str: String; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base64(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base64(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base64(const Str: AnsiString; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecodedLength_Base64(Str,Header,AnsiPaddingChar_Base64);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base64(const Str: UnicodeString; Header: Boolean = False): TMemSize;
begin
Result := WideDecodedLength_Base64(Str,Header,WidePaddingChar_Base64);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base64(const Str: String; Header: Boolean; PaddingChar: Char): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base64(Str,Header,PaddingChar);
{$ELSE}
Result := AnsiDecodedLength_Base64(Str,Header,PaddingChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base64(const Str: AnsiString; Header: Boolean; PaddingChar: AnsiChar): TMemSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := Floor((((Length(Str) - HeaderLength) - AnsiCountPadding(Str,PaddingChar)) / 4) * 3)
    else
      raise EEncodedTextTooShort.Create('AnsiDecodedLength_Base64: Encoded text is too short to contain valid header.');
  end
else Result := Floor(((Length(Str) - AnsiCountPadding(Str,PaddingChar)) / 4) * 3);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base64(const Str: UnicodeString; Header: Boolean; PaddingChar: UnicodeChar): TMemSize;
begin
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := Floor((((Length(Str) - HeaderLength) - WideCountPadding(Str,PaddingChar)) / 4) * 3)
    else
      raise EEncodedTextTooShort.Create('WideDecodedLength_Base64: Encoded text is too short to contain valid header.');
  end
else Result := Floor(((Length(Str) - WideCountPadding(Str,PaddingChar)) / 4) * 3);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base85(const Str: String; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base85(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Base85(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base85(const Str: AnsiString; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecodedLength_Base85(Str,Header,AnsiCompressionChar_Base85);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base85(const Str: UnicodeString; Header: Boolean = False): TMemSize;
begin
Result := WideDecodedLength_Base85(Str,Header,WideCompressionChar_Base85);
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Base85(const Str: String; Header: Boolean; CompressionChar: Char): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Base85(Str,Header,CompressionChar);
{$ELSE}
Result := AnsiDecodedLength_Base85(Str,Header,CompressionChar);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Base85(const Str: AnsiString; Header: Boolean; CompressionChar: AnsiChar): TMemSize;
begin
Result := Length(Str) + AnsiCorrectionForBase85(Str,CompressionChar);;
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := (Result - TMemSize(HeaderLength)) - TMemSize(Ceil((Result - TMemSize(HeaderLength)) / 5))
    else
      raise EEncodedTextTooShort.Create('AnsiDecodedLength_Base85: Encoded text is too short to contain valid header.');
  end
else Result := Result - TMemSize(Ceil(Result / 5));
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Base85(const Str: UnicodeString; Header: Boolean; CompressionChar: UnicodeChar): TMemSize;
begin
Result := Length(Str) + WideCorrectionForBase85(Str,CompressionChar);
If Header then
  begin
    If Length(Str) >= HeaderLength then
      Result := (Result - TMemSize(HeaderLength)) - TMemSize(Ceil((Result - TMemSize(HeaderLength)) / 5))
    else
      raise EEncodedTextTooShort.Create('WideDecodedLength_Base85: Encoded text is too short to contain valid header.');
  end
else Result := Result - TMemSize(Ceil(Result / 5));
end;

{------------------------------------------------------------------------------}

Function DecodedLength_Ascii85(const Str: String; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecodedLength_Ascii85(Str,Header);
{$ELSE}
Result := AnsiDecodedLength_Ascii85(Str,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecodedLength_Ascii85(const Str: AnsiString; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecodedLength_Base85(Str,Header,AnsiCompressionChar_Ascii85);
end;

{------------------------------------------------------------------------------}

Function WideDecodedLength_Ascii85(const Str: UnicodeString; Header: Boolean = False): TMemSize;
begin
Result := WideDecodedLength_Base85(Str,Header,WideCompressionChar_Ascii85);
end;


{===============================================================================
--------------------------------------------------------------------------------
                               Encoding functions
--------------------------------------------------------------------------------
===============================================================================}

Function Encode_Base2(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: String = ''): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base2(Data,Size,Reversed,Header);
{$ELSE}
Result := AnsiEncode_Base2(Data,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base2(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: AnsiString = ''): AnsiString;
begin
Result := AnsiEncode_Base2(Data,Size,Reversed,AnsiEncodingTable_Base2,Header);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base2(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: UnicodeString = ''): UnicodeString;
begin
Result := WideEncode_Base2(Data,Size,Reversed,WideEncodingTable_Base2,Header);
end;

{------------------------------------------------------------------------------}

Function Encode_Base2(Data: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; Header: String = ''): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base2(Data,Size,Reversed,EncodingTable,Header);
{$ELSE}
Result := AnsiEncode_Base2(Data,Size,Reversed,EncodingTable,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function AnsiEncode_Base2(Data: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; Header: AnsiString = ''): AnsiString;
var
  Buffer:     Byte;
  i,j:        TMemSize;
  StrOffset:  TStrSize;
begin
ResolveDataPointer(Data,Reversed,Size);
Result := Header;
SetLength(Result,Length(Header) + EncodedLength_Base2(Size));
StrOffset := Length(Header);
If Size > 0 then
  For i := 0 to Pred(Size) do
    begin
      Buffer := PByte(Data)^;
      For j := 8 downto 1 do
        begin
          Result[TMemSize(StrOffset) + (i * 8) + j] := EncodingTable[Buffer and 1];
          Buffer := Buffer shr 1;
        end;
      AdvanceDataPointer(Data,Reversed)
    end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function WideEncode_Base2(Data: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; Header: UnicodeString = ''): UnicodeString;
var
  Buffer:     Byte;
  i,j:        TMemSize;
  StrOffset:  TStrSize;
begin
ResolveDataPointer(Data,Reversed,Size);
Result := Header;
SetLength(Result,Length(Header) + EncodedLength_Base2(Size));
StrOffset := Length(Header);
If Size > 0 then
  For i := 0 to Pred(Size) do
    begin
      Buffer := PByte(Data)^;
      For j := 8 downto 1 do
        begin
          Result[TMemSize(StrOffset) + (i * 8) + j] := EncodingTable[Buffer and 1];
          Buffer := Buffer shr 1;
        end;
      AdvanceDataPointer(Data,Reversed);
    end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{==============================================================================}

Function Encode_Base8(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: String = ''): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base8(Data,Size,Reversed,Padding,Header);
{$ELSE}
Result := AnsiEncode_Base8(Data,Size,Reversed,Padding,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base8(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: AnsiString = ''): AnsiString;
begin
Result := AnsiEncode_Base8(Data,Size,Reversed,Padding,AnsiEncodingTable_Base8,AnsiPaddingChar_Base8,Header);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base8(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: UnicodeString = ''): UnicodeString;
begin
Result := WideEncode_Base8(Data,Size,Reversed,Padding,WideEncodingTable_Base8,WidePaddingChar_Base8,Header);
end;

{------------------------------------------------------------------------------}

Function Encode_Base8(Data: Pointer; Size: TMemSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: array of Char; PaddingChar: Char; Header: String = ''): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base8(Data,Size,Reversed,Padding,EncodingTable,PaddingChar,Header);
{$ELSE}
Result := AnsiEncode_Base8(Data,Size,Reversed,Padding,EncodingTable,PaddingChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function AnsiEncode_Base8(Data: Pointer; Size: TMemSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: array of AnsiChar; PaddingChar: AnsiChar; Header: AnsiString = ''): AnsiString;
var
  Buffer:         Byte;
  i:              TMemSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  ResultPosition: TStrSize;
  j:              TStrSize;
begin
ResolveDataPointer(Data,Reversed,Size);
Result := Header;
SetLength(Result,Length(Header) + EncodedLength_Base8(Size,False,Padding));
Remainder := 0;
RemainderBits := 0;
ResultPosition := 1 + Length(Header);
For i := 1 to Size do
  begin
    Buffer := PByte(Data)^;
    case RemainderBits of
      0:  begin
            Result[ResultPosition] := EncodingTable[(Buffer and $E0) shr 5];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $1C) shr 2];
            Inc(ResultPosition,2);
            Remainder := Buffer and $03;
            RemainderBits := 2;
          end;
      1:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 2) or ((Buffer and $C0) shr 6)];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $38) shr 3];
            Result[ResultPosition + 2] := EncodingTable[Buffer and $07];
            Inc(ResultPosition,3);
            Remainder := 0;
            RemainderBits := 0;
          end;
      2:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 1) or ((Buffer and $80) shr 7)];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $70) shr 4];
            Result[ResultPosition + 2] := EncodingTable[(Buffer and $0E) shr 1];
            Inc(ResultPosition,3);
            Remainder := Buffer and $01;
            RemainderBits := 1;
          end;
    else
      raise EEncodingError.CreateFmt('AnsiEncode_Base8: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    AdvanceDataPointer(Data,Reversed);
  end;
case RemainderBits of
  0:  ;
  1:  Result[ResultPosition] := EncodingTable[Remainder shl 2];
  2:  Result[ResultPosition] := EncodingTable[Remainder shl 1];
else
  raise EEncodingError.CreateFmt('AnsiEncode_Base8: Invalid RemainderBits value (%d).',[RemainderBits]);
end;
Inc(ResultPosition);
If Padding then
  For j := ResultPosition to Length(Result) do Result[j] := PaddingChar;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function WideEncode_Base8(Data: Pointer; Size: TMemSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: array of UnicodeChar; PaddingChar: UnicodeChar; Header: UnicodeString = ''): UnicodeString;
var
  Buffer:         Byte;
  i:              TMemSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  ResultPosition: TStrSize;
  j:              TStrSize;
begin
ResolveDataPointer(Data,Reversed,Size);
Result := Header;
SetLength(Result,Length(Header) + EncodedLength_Base8(Size,False,Padding));
Remainder := 0;
RemainderBits := 0;
ResultPosition := 1 + Length(Header);
For i := 1 to Size do
  begin
    Buffer := PByte(Data)^;
    case RemainderBits of
      0:  begin
            Result[ResultPosition] := EncodingTable[(Buffer and $E0) shr 5];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $1C) shr 2];
            Inc(ResultPosition,2);
            Remainder := Buffer and $03;
            RemainderBits := 2;
          end;
      1:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 2) or ((Buffer and $C0) shr 6)];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $38) shr 3];
            Result[ResultPosition + 2] := EncodingTable[Buffer and $07];
            Inc(ResultPosition,3);
            Remainder := 0;
            RemainderBits := 0;
          end;
      2:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 1) or ((Buffer and $80) shr 7)];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $70) shr 4];
            Result[ResultPosition + 2] := EncodingTable[(Buffer and $0E) shr 1];
            Inc(ResultPosition,3);
            Remainder := Buffer and $01;
            RemainderBits := 1;
          end;
    else
      raise EEncodingError.CreateFmt('WideEncode_Base8: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    AdvanceDataPointer(Data,Reversed);
  end;
case RemainderBits of
  0:  ;
  1:  Result[ResultPosition] := EncodingTable[Remainder shl 2];
  2:  Result[ResultPosition] := EncodingTable[Remainder shl 1];
else
  raise EEncodingError.CreateFmt('WideEncode_Base8: Invalid RemainderBits value (%d).',[RemainderBits]);
end;
Inc(ResultPosition);
If Padding then
  For j := ResultPosition to Length(Result) do Result[j] := PaddingChar;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{==============================================================================}

Function Encode_Base10(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: String = ''): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base10(Data,Size,Reversed,Header);
{$ELSE}
Result := AnsiEncode_Base10(Data,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base10(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: AnsiString = ''): AnsiString;
begin
Result := AnsiEncode_Base10(Data,Size,Reversed,AnsiEncodingTable_Base10,Header);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base10(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: UnicodeString = ''): UnicodeString;
begin
Result := WideEncode_Base10(Data,Size,Reversed,WideEncodingTable_Base10,Header);
end;

{------------------------------------------------------------------------------}

Function Encode_Base10(Data: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; Header: String = ''): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base10(Data,Size,Reversed,EncodingTable,Header);
{$ELSE}
Result := AnsiEncode_Base10(Data,Size,Reversed,EncodingTable,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function AnsiEncode_Base10(Data: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; Header: AnsiString = ''): AnsiString;
var
  Buffer:     Byte;
  i,j:        TMemSize;
  StrOffset:  TStrSize;
begin
ResolveDataPointer(Data,Reversed,Size);
Result := Header;
SetLength(Result,Length(Header) + EncodedLength_Base10(Size));
StrOffset := Length(Header);
If Size > 0 then
  For i := 0 to Pred(Size) do
    begin
      Buffer := PByte(Data)^;
      For j := 1 to 3 do
        begin
          Result[TMemSize(StrOffset) + (i * 3) + j] := EncodingTable[Buffer div Coefficients_Base10[j]];
          Buffer := Buffer mod Coefficients_Base10[j];
        end;
      AdvanceDataPointer(Data,Reversed);
    end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function WideEncode_Base10(Data: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; Header: UnicodeString = ''): UnicodeString;
var
  Buffer:     Byte;
  i,j:        TMemSize;
  StrOffset:  TStrSize;
begin
ResolveDataPointer(Data,Reversed,Size);
Result := Header;
SetLength(Result,Length(Header) + EncodedLength_Base10(Size));
StrOffset := Length(Header);
If Size > 0 then
  For i := 0 to Pred(Size) do
    begin
      Buffer := PByte(Data)^;
      For j := 1 to 3 do
        begin
          Result[TMemSize(StrOffset) + (i * 3) + j] := EncodingTable[Buffer div Coefficients_Base10[j]];
          Buffer := Buffer mod Coefficients_Base10[j];
        end;
      AdvanceDataPointer(Data,Reversed);
    end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{==============================================================================}

Function Encode_Base16(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: String = ''): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base16(Data,Size,Reversed,Header);
{$ELSE}
Result := AnsiEncode_Base16(Data,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base16(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: AnsiString = ''): AnsiString;
begin
Result := AnsiEncode_Base16(Data,Size,Reversed,AnsiEncodingTable_Base16,Header);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base16(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: UnicodeString = ''): UnicodeString;
begin
Result := WideEncode_Base16(Data,Size,Reversed,WideEncodingTable_Base16,Header);
end;

{------------------------------------------------------------------------------}

Function Encode_Base16(Data: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; Header: String = ''): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base16(Data,Size,Reversed,EncodingTable,Header);
{$ELSE}
Result := AnsiEncode_Base16(Data,Size,Reversed,EncodingTable,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function AnsiEncode_Base16(Data: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; Header: AnsiString = ''): AnsiString;
var
  i:          TMemSize;
  StrOffset:  TStrSize;
begin
ResolveDataPointer(Data,Reversed,Size);
Result := Header;
SetLength(Result,Length(Header) + EncodedLength_Base16(Size));
StrOffset := Length(Header);
If Size > 0 then
  For i := 0 to Pred(Size) do
    begin
      Result[TMemSize(StrOffset) + (i * 2) + 1] := EncodingTable[PByte(Data)^ shr 4];
      Result[TMemSize(StrOffset) + (i * 2) + 2] := EncodingTable[PByte(Data)^ and $0F];
      AdvanceDataPointer(Data,Reversed);
    end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function WideEncode_Base16(Data: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; Header: UnicodeString = ''): UnicodeString;
var
  i:          TMemSize;
  StrOffset:  TStrSize;
begin
ResolveDataPointer(Data,Reversed,Size);
Result := Header;
SetLength(Result,Length(Header) + EncodedLength_Base16(Size));
StrOffset := Length(Header);
If Size > 0 then
  For i := 0 to Pred(Size) do
    begin
      Result[TMemSize(StrOffset) + (i * 2) + 1] := EncodingTable[PByte(Data)^ shr 4];
      Result[TMemSize(StrOffset) + (i * 2) + 2] := EncodingTable[PByte(Data)^ and $0F];
      AdvanceDataPointer(Data,Reversed);
    end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

Function Encode_Hexadecimal(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: String = ''): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Hexadecimal(Data,Size,Reversed,Header);
{$ELSE}
Result := AnsiEncode_Hexadecimal(Data,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Hexadecimal(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: AnsiString = ''): AnsiString;
begin
Result := AnsiEncode_Base16(Data,Size,Reversed,AnsiEncodingTable_Hexadecimal,Header);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Hexadecimal(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: UnicodeString = ''): UnicodeString;
begin
Result := WideEncode_Base16(Data,Size,Reversed,WideEncodingTable_Hexadecimal,Header);
end;

{==============================================================================}

Function Encode_Base32(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: String = ''): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base32(Data,Size,Reversed,Padding,Header);
{$ELSE}
Result := AnsiEncode_Base32(Data,Size,Reversed,Padding,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base32(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: AnsiString = ''): AnsiString;
begin
Result := AnsiEncode_Base32(Data,Size,Reversed,Padding,AnsiEncodingTable_Base32,AnsiPaddingChar_Base32,Header);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base32(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: UnicodeString = ''): UnicodeString;
begin
Result := WideEncode_Base32(Data,Size,Reversed,Padding,WideEncodingTable_Base32,WidePaddingChar_Base32,Header);
end;

{------------------------------------------------------------------------------}

Function Encode_Base32(Data: Pointer; Size: TMemSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: array of Char; PaddingChar: Char; Header: String = ''): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base32(Data,Size,Reversed,Padding,EncodingTable,PaddingChar,Header);
{$ELSE}
Result := AnsiEncode_Base32(Data,Size,Reversed,Padding,EncodingTable,PaddingChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function AnsiEncode_Base32(Data: Pointer; Size: TMemSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: array of AnsiChar; PaddingChar: AnsiChar; Header: AnsiString = ''): AnsiString;
var
  Buffer:         Byte;
  i:              TMemSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  ResultPosition: TStrSize;
  j:              TStrSize;
begin
ResolveDataPointer(Data,Reversed,Size);
Result := Header;
SetLength(Result,Length(Header) + EncodedLength_Base32(Size,False,Padding));
Remainder := 0;
RemainderBits := 0;
ResultPosition := 1 + Length(Header);
For i := 1 to Size do
  begin
    Buffer := PByte(Data)^;
    case RemainderBits of
      0:  begin
            Result[ResultPosition] := EncodingTable[(Buffer and $F8) shr 3];
            Inc(ResultPosition,1);
            Remainder := Buffer and $07;
            RemainderBits := 3;
          end;
      1:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 4) or ((Buffer and $F0) shr 4)];
            Inc(ResultPosition,1);
            Remainder := Buffer and $0F;
            RemainderBits := 4;
          end;
      2:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 3) or ((Buffer and $E0) shr 5)];
            Result[ResultPosition + 1] := EncodingTable[Buffer and $1F];
            Inc(ResultPosition,2);
            Remainder := 0;
            RemainderBits := 0;
          end;
      3:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 2) or ((Buffer and $C0) shr 6)];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $3E) shr 1];
            Inc(ResultPosition,2);
            Remainder := Buffer and $01;
            RemainderBits := 1;
          end;
      4:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 1) or ((Buffer and $80) shr 7)];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $7C) shr 2];
            Inc(ResultPosition,2);
            Remainder := Buffer and $03;
            RemainderBits := 2;
          end;
    else
      raise EEncodingError.CreateFmt('AnsiEncode_Base32: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    AdvanceDataPointer(Data,Reversed);
  end;
case RemainderBits of
  0:  ;
  1:  Result[ResultPosition] := EncodingTable[Remainder shl 4];
  2:  Result[ResultPosition] := EncodingTable[Remainder shl 3];
  3:  Result[ResultPosition] := EncodingTable[Remainder shl 2];
  4:  Result[ResultPosition] := EncodingTable[Remainder shl 1];
else
  raise EEncodingError.CreateFmt('AnsiEncode_Base32: Invalid RemainderBits value (%d).',[RemainderBits]);
end;
Inc(ResultPosition);
If Padding then
  For j := ResultPosition to Length(Result) do Result[j] := PaddingChar;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function WideEncode_Base32(Data: Pointer; Size: TMemSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: array of UnicodeChar; PaddingChar: UnicodeChar; Header: UnicodeString = ''): UnicodeString;
var
  Buffer:         Byte;
  i:              TMemSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  ResultPosition: TStrSize;
  j:              TStrSize;
begin
ResolveDataPointer(Data,Reversed,Size);
Result := Header;
SetLength(Result,Length(Header) + EncodedLength_Base32(Size,False,Padding));
Remainder := 0;
RemainderBits := 0;
ResultPosition := 1 + Length(Header);
For i := 1 to Size do
  begin
    Buffer := PByte(Data)^;
    case RemainderBits of
      0:  begin
            Result[ResultPosition] := EncodingTable[(Buffer and $F8) shr 3];
            Inc(ResultPosition,1);
            Remainder := Buffer and $07;
            RemainderBits := 3;
          end;
      1:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 4) or ((Buffer and $F0) shr 4)];
            Inc(ResultPosition,1);
            Remainder := Buffer and $0F;
            RemainderBits := 4;
          end;
      2:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 3) or ((Buffer and $E0) shr 5)];
            Result[ResultPosition + 1] := EncodingTable[Buffer and $1F];
            Inc(ResultPosition,2);
            Remainder := 0;
            RemainderBits := 0;
          end;
      3:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 2) or ((Buffer and $C0) shr 6)];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $3E) shr 1];
            Inc(ResultPosition,2);
            Remainder := Buffer and $01;
            RemainderBits := 1;
          end;
      4:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 1) or ((Buffer and $80) shr 7)];
            Result[ResultPosition + 1] := EncodingTable[(Buffer and $7C) shr 2];
            Inc(ResultPosition,2);
            Remainder := Buffer and $03;
            RemainderBits := 2;
          end;
    else
      raise EEncodingError.CreateFmt('WideEncode_Base32: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    AdvanceDataPointer(Data,Reversed);
  end;
case RemainderBits of
  0:  ;
  1:  Result[ResultPosition] := EncodingTable[Remainder shl 4];
  2:  Result[ResultPosition] := EncodingTable[Remainder shl 3];
  3:  Result[ResultPosition] := EncodingTable[Remainder shl 2];
  4:  Result[ResultPosition] := EncodingTable[Remainder shl 1];
else
  raise EEncodingError.CreateFmt('WideEncode_Base32: Invalid RemainderBits value (%d).',[RemainderBits]);
end;
Inc(ResultPosition);
If Padding then
  For j := ResultPosition to Length(Result) do Result[j] := PaddingChar;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

Function Encode_Base32Hex(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: String = ''): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base32Hex(Data,Size,Reversed,Padding,Header);
{$ELSE}
Result := AnsiEncode_Base32Hex(Data,Size,Reversed,Padding,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base32Hex(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: AnsiString = ''): AnsiString;
begin
Result := AnsiEncode_Base32(Data,Size,Reversed,Padding,AnsiEncodingTable_Base32Hex,AnsiPaddingChar_Base32Hex,Header);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base32Hex(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: UnicodeString = ''): UnicodeString;
begin
Result := WideEncode_Base32(Data,Size,Reversed,Padding,WideEncodingTable_Base32Hex,WidePaddingChar_Base32Hex,Header);
end;

{==============================================================================}

Function Encode_Base64(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: String = ''): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base64(Data,Size,Reversed,Padding,Header);
{$ELSE}
Result := AnsiEncode_Base64(Data,Size,Reversed,Padding,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base64(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: AnsiString = ''): AnsiString;
begin
Result := AnsiEncode_Base64(Data,Size,Reversed,Padding,AnsiEncodingTable_Base64,AnsiPaddingChar_Base64,Header);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base64(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Padding: Boolean = True; Header: UnicodeString = ''): UnicodeString;
begin
Result := WideEncode_Base64(Data,Size,Reversed,Padding,WideEncodingTable_Base64,WidePaddingChar_Base64,Header);
end;

{------------------------------------------------------------------------------}

Function Encode_Base64(Data: Pointer; Size: TMemSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: array of Char; PaddingChar: Char; Header: String = ''): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base64(Data,Size,Reversed,Padding,EncodingTable,PaddingChar,Header);
{$ELSE}
Result := AnsiEncode_Base64(Data,Size,Reversed,Padding,EncodingTable,PaddingChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function AnsiEncode_Base64(Data: Pointer; Size: TMemSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: array of AnsiChar; PaddingChar: AnsiChar; Header: AnsiString = ''): AnsiString;
var
  Buffer:         Byte;
  i:              TMemSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  ResultPosition: TStrSize;
  j:              TStrSize;
begin
ResolveDataPointer(Data,Reversed,Size);
Result := Header;
SetLength(Result,Length(Header) + EncodedLength_Base64(Size,False,Padding));
Remainder := 0;
RemainderBits := 0;
ResultPosition := 1 + Length(Header);
For i := 1 to Size do
  begin
    Buffer := PByte(Data)^;
    case RemainderBits of
      0:  begin
            Result[ResultPosition] := EncodingTable[(Buffer and $FC) shr 2];
            Inc(ResultPosition,1);
            Remainder := Buffer and $03;
            RemainderBits := 2;
          end;
      2:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 4) or ((Buffer and $F0) shr 4)];
            Inc(ResultPosition,1);
            Remainder := Buffer and $0F;
            RemainderBits := 4;
          end;
      4:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 2) or ((Buffer and $C0) shr 6)];
            Result[ResultPosition + 1] := EncodingTable[Buffer and $3F];
            Inc(ResultPosition,2);
            Remainder := Buffer and $01;
            RemainderBits := 0;
          end;
    else
      raise EEncodingError.CreateFmt('AnsiEncode_Base64: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    AdvanceDataPointer(Data,Reversed);
  end;
case RemainderBits of
  0:  ;
  2:  Result[ResultPosition] := EncodingTable[Remainder shl 4];
  4:  Result[ResultPosition] := EncodingTable[Remainder shl 2];
else
  raise EEncodingError.CreateFmt('AnsiEncode_Base64: Invalid RemainderBits value (%d).',[RemainderBits]);
end;
Inc(ResultPosition);
If Padding then
  For j := ResultPosition to Length(Result) do Result[j] := PaddingChar;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function WideEncode_Base64(Data: Pointer; Size: TMemSize; Reversed: Boolean; Padding: Boolean; const EncodingTable: array of UnicodeChar; PaddingChar: UnicodeChar; Header: UnicodeString = ''): UnicodeString;
var
  Buffer:         Byte;
  i:              TMemSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  ResultPosition: TStrSize;
  j:              TStrSize;
begin
ResolveDataPointer(Data,Reversed,Size);
Result := Header;
SetLength(Result,Length(Header) + EncodedLength_Base64(Size,False,Padding));
Remainder := 0;
RemainderBits := 0;
ResultPosition := 1 + Length(Header);
For i := 1 to Size do
  begin
    Buffer := PByte(Data)^;
    case RemainderBits of
      0:  begin
            Result[ResultPosition] := EncodingTable[(Buffer and $FC) shr 2];
            Inc(ResultPosition,1);
            Remainder := Buffer and $03;
            RemainderBits := 2;
          end;
      2:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 4) or ((Buffer and $F0) shr 4)];
            Inc(ResultPosition,1);
            Remainder := Buffer and $0F;
            RemainderBits := 4;
          end;
      4:  begin
            Result[ResultPosition] := EncodingTable[(Remainder shl 2) or ((Buffer and $C0) shr 6)];
            Result[ResultPosition + 1] := EncodingTable[Buffer and $3F];
            Inc(ResultPosition,2);
            Remainder := Buffer and $01;
            RemainderBits := 0;
          end;
    else
      raise EEncodingError.CreateFmt('WideEncode_Base64: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    AdvanceDataPointer(Data,Reversed);
  end;
case RemainderBits of
  0:  ;
  2:  Result[ResultPosition] := EncodingTable[Remainder shl 4];
  4:  Result[ResultPosition] := EncodingTable[Remainder shl 2];
else
  raise EEncodingError.CreateFmt('WideEncode_Base64: Invalid RemainderBits value (%d).',[RemainderBits]);
end;
Inc(ResultPosition);
If Padding then
  For j := ResultPosition to Length(Result) do Result[j] := PaddingChar;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{==============================================================================}

Function Encode_Base85(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Compression: Boolean = True; Trim: Boolean = True; Header: String = ''): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base85(Data,Size,Reversed,Compression,Trim,Header);
{$ELSE}
Result := AnsiEncode_Base85(Data,Size,Reversed,Compression,Trim,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Base85(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Compression: Boolean = True; Trim: Boolean = True; Header: AnsiString = ''): AnsiString;
begin
Result := AnsiEncode_Base85(Data,Size,Reversed,Compression,Trim,AnsiEncodingTable_Base85,AnsiCompressionChar_Base85,Header);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Base85(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Compression: Boolean = True; Trim: Boolean = True; Header: UnicodeString = ''): UnicodeString;
begin
Result := WideEncode_Base85(Data,Size,Reversed,Compression,Trim,WideEncodingTable_Base85,WideCompressionChar_Base85,Header);
end;

{------------------------------------------------------------------------------}

Function Encode_Base85(Data: Pointer; Size: TMemSize; Reversed: Boolean; Compression: Boolean; Trim: Boolean; const EncodingTable: array of Char; CompressionChar: Char; Header: String = ''): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Base85(Data,Size,Reversed,Compression,Trim,EncodingTable,CompressionChar,Header);
{$ELSE}
Result := AnsiEncode_Base85(Data,Size,Reversed,Compression,Trim,EncodingTable,CompressionChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function AnsiEncode_Base85(Data: Pointer; Size: TMemSize; Reversed: Boolean; Compression: Boolean; Trim: Boolean; const EncodingTable: array of AnsiChar; CompressionChar: AnsiChar; Header: AnsiString = ''): AnsiString;
var
  Buffer:         UInt32;
  i:              TMemSize;
  j:              TStrSize;
  ResultPosition: TStrSize;
begin
Result := Header;
SetLength(Result,Length(Header) + EncodedLength_Base85(Data,Size,Reversed,False,Compression,Trim));
ResolveDataPointer(Data,Reversed,Size,4);
ResultPosition := 1 + Length(Header);
For i := 1 to Ceil(Size / 4) do
  begin
    If (i * 4) > Size then
      begin
        Buffer := 0;
        If Reversed then
        {$IFDEF FPCDWM}{$PUSH}W4055 W4056{$ENDIF}
          Move(Pointer(PtrUInt(Data) - PtrUInt(Size and 3) + 4)^,Pointer(PtrUInt(@Buffer) - PtrUInt(Size and 3) + 4)^,Size and 3)
        {$IFDEF FPCDWM}{$POP}{$ENDIF}
        else
          Move(Data^,Buffer,Size and 3);
      end
    else Buffer := PUInt32(Data)^;
  {$IFDEF ENDIAN_BIG}
    If Reversed then SwapByteOrder(Buffer);
  {$ELSE}
    If not Reversed then SwapByteOrder(Buffer);
  {$ENDIF}
    If (Buffer = 0) and Compression and ((i * 4) <= Size) then
      begin
        Result[ResultPosition] := CompressionChar;
        Inc(ResultPosition);
      end
    else
      begin
        For j := 1 to Min(5,Length(Result) - ResultPosition + 1) do
          begin
            Result[ResultPosition + j - 1] := EncodingTable[Buffer div Coefficients_Base85[j]];
            Buffer := Buffer mod Coefficients_Base85[j];
          end;
        Inc(ResultPosition,5);
      end;
    AdvanceDataPointer(Data,Reversed,4);
  end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function WideEncode_Base85(Data: Pointer; Size: TMemSize; Reversed: Boolean; Compression: Boolean; Trim: Boolean; const EncodingTable: array of UnicodeChar; CompressionChar: UnicodeChar; Header: UnicodeString = ''): UnicodeString;
var
  Buffer:         UInt32;
  i:              TMemSize;
  j:              TStrSize;
  ResultPosition: TStrSize;
begin
Result := Header;
SetLength(Result,Length(Header) + EncodedLength_Base85(Data,Size,Reversed,False,Compression,Trim));
ResolveDataPointer(Data,Reversed,Size,4);
ResultPosition := 1 + Length(Header);
For i := 1 to Ceil(Size / 4) do
  begin
    If (i * 4) > Size then
      begin
        Buffer := 0;
        If Reversed then
        {$IFDEF FPCDWM}{$PUSH}W4055 W4056{$ENDIF}
          Move(Pointer(PtrUInt(Data) - PtrUInt(Size and 3) + 4)^,Pointer(PtrUInt(@Buffer) - PtrUInt(Size and 3) + 4)^,Size and 3)
        {$IFDEF FPCDWM}{$POP}{$ENDIF}
        else
          Move(Data^,Buffer,Size and 3);
      end
    else Buffer := PUInt32(Data)^;
  {$IFDEF ENDIAN_BIG}
    If Reversed then SwapByteOrder(Buffer);
  {$ELSE}
    If not Reversed then SwapByteOrder(Buffer);
  {$ENDIF}
    If (Buffer = 0) and Compression and ((i * 4) <= Size) then
      begin
        Result[ResultPosition] := CompressionChar;
        Inc(ResultPosition);
      end
    else
      begin
        For j := 1 to Min(5,Length(Result) - ResultPosition + 1) do
          begin
            Result[ResultPosition + j - 1] := EncodingTable[Buffer div Coefficients_Base85[j]];
            Buffer := Buffer mod Coefficients_Base85[j];
          end;
        Inc(ResultPosition,5);
      end;
    AdvanceDataPointer(Data,Reversed,4);
  end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

Function Encode_Ascii85(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Compression: Boolean = True; Trim: Boolean = True; Header: String = ''): String;
begin
{$IFDEF Unicode}
Result := WideEncode_Ascii85(Data,Size,Reversed,Compression,Trim,Header);
{$ELSE}
Result := AnsiEncode_Ascii85(Data,Size,Reversed,Compression,Trim,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiEncode_Ascii85(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Compression: Boolean = True; Trim: Boolean = True; Header: AnsiString = ''): AnsiString;
begin
Result := AnsiEncode_Base85(Data,Size,Reversed,Compression,Trim,AnsiEncodingTable_Ascii85,AnsiCompressionChar_Ascii85,Header);
end;

{------------------------------------------------------------------------------}

Function WideEncode_Ascii85(Data: Pointer; Size: TMemSize; Reversed: Boolean = False; Compression: Boolean = True; Trim: Boolean = True; Header: UnicodeString = ''): UnicodeString;
begin
Result := WideEncode_Base85(Data,Size,Reversed,Compression,Trim,WideEncodingTable_Ascii85,WideCompressionChar_Ascii85,Header);
end;

{===============================================================================
--------------------------------------------------------------------------------
                               Decoding functions
--------------------------------------------------------------------------------
===============================================================================}

Function Decode_Base2(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base2(Str,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Base2(Str,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base2(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base2(Str,Size,Reversed,DecodingTable_Base2,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base2(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
Result := WideDecode_Base2(Str,Size,Reversed,DecodingTable_Base2,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base2(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base2(Str,Ptr,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Base2(Str,Ptr,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base2(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecode_Base2(Str,Ptr,Size,Reversed,DecodingTable_Base2,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base2(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := WideDecode_Base2(Str,Ptr,Size,Reversed,DecodingTable_Base2,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base2(const Str: String; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base2(Str,Size,Reversed,EncodingTable,Header);
{$ELSE}
Result := AnsiDecode_Base2(Str,Size,Reversed,EncodingTable,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base2(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; Header: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base2(Str,Size,Reversed,AnsiBuildDecodingTable(EncodingTable),Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base2(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; Header: Boolean = False): Pointer;
begin
Result := WideDecode_Base2(Str,Size,Reversed,WideBuildDecodingTable(EncodingTable),Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base2(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base2(Str,Ptr,Size,Reversed,EncodingTable,Header);
{$ELSE}
Result := AnsiDecode_Base2(Str,Ptr,Size,Reversed,EncodingTable,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base2(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecode_Base2(Str,Ptr,Size,Reversed,AnsiBuildDecodingTable(EncodingTable),Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base2(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; Header: Boolean = False): TMemSize;
begin
Result := WideDecode_Base2(Str,Ptr,Size,Reversed,WideBuildDecodingTable(EncodingTable),Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base2(const Str: String; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base2(Str,Size,Reversed,DecodingTable,Header);
{$ELSE}
Result := AnsiDecode_Base2(Str,Size,Reversed,DecodingTable,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base2(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): Pointer;
var
  ResultSize: TMemSize;
begin
Size := AnsiDecodedLength_Base2(Str,Header);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := AnsiDecode_Base2(Str,Result,Size,Reversed,DecodingTable,Header);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('AnsiDecode_Base2: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base2(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): Pointer;
var
  ResultSize: TMemSize;
begin
Size := WideDecodedLength_Base2(Str,Header);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := WideDecode_Base2(Str,Result,Size,Reversed,DecodingTable,Header);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('WideDecode_Base2: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function Decode_Base2(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base2(Str,Ptr,Size,Reversed,DecodingTable,Header);
{$ELSE}
Result := AnsiDecode_Base2(Str,Ptr,Size,Reversed,DecodingTable,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function AnsiDecode_Base2(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): TMemSize;
var
  Buffer:     Byte;
  i,j:        TMemSize;
  StrOffset:  TStrSize;
begin
If Header then StrOffset := HeaderLength
  else StrOffset := 0;
Result := AnsiDecodedLength_Base2(Str,Header);
DecodeCheckSize(Size,Result,2);
ResolveDataPointer(Ptr,Reversed,Size);
If Result > 0 then
  For i := 0 to Pred(Result) do
    begin
      Buffer := 0;
      For j := 1 to 8 do
        Buffer := (Buffer shl 1) or AnsiDecodeFromTable(Str[TMemSize(StrOffset) + (i * 8) + j],DecodingTable,2);
      PByte(Ptr)^ := Buffer;
      AdvanceDataPointer(Ptr,Reversed);
    end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function WideDecode_Base2(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): TMemSize;
var
  Buffer:     Byte;
  i,j:        TMemSize;
  StrOffset:  TStrSize;
begin
If Header then StrOffset := HeaderLength
  else StrOffset := 0;
Result := WideDecodedLength_Base2(Str,Header);
DecodeCheckSize(Size,Result,2);
ResolveDataPointer(Ptr,Reversed,Size);
If Result > 0 then
  For i := 0 to Pred(Result) do
    begin
      Buffer := 0;
      For j := 1 to 8 do
        Buffer := (Buffer shl 1) or WideDecodeFromTable(Str[TMemSize(StrOffset) + (i * 8) + j],DecodingTable,2);
      PByte(Ptr)^ := Buffer;
      AdvanceDataPointer(Ptr,Reversed);
    end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{==============================================================================}

Function Decode_Base8(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base8(Str,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Base8(Str,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base8(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base8(Str,Size,Reversed,DecodingTable_Base8,AnsiPaddingChar_Base8,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base8(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
Result := WideDecode_Base8(Str,Size,Reversed,DecodingTable_Base8,WidePaddingChar_Base8,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base8(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base8(Str,Ptr,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Base8(Str,Ptr,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base8(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecode_Base8(Str,Ptr,Size,Reversed,DecodingTable_Base8,AnsiPaddingChar_Base8,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base8(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := WideDecode_Base8(Str,Ptr,Size,Reversed,DecodingTable_Base8,WidePaddingChar_Base8,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base8(const Str: String; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; PaddingChar: Char; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base8(Str,Size,Reversed,EncodingTable,PaddingChar,Header);
{$ELSE}
Result := AnsiDecode_Base8(Str,Size,Reversed,EncodingTable,PaddingChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base8(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; PaddingChar: AnsiChar; Header: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base8(Str,Size,Reversed,AnsiBuildDecodingTable(EncodingTable),PaddingChar,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base8(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; PaddingChar: UnicodeChar; Header: Boolean = False): Pointer;
begin
Result := WideDecode_Base8(Str,Size,Reversed,WideBuildDecodingTable(EncodingTable),PaddingChar,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base8(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; PaddingChar: Char; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base8(Str,Ptr,Size,Reversed,EncodingTable,PaddingChar,Header);
{$ELSE}
Result := AnsiDecode_Base8(Str,Ptr,Size,Reversed,EncodingTable,PaddingChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base8(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; PaddingChar: AnsiChar; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecode_Base8(Str,Ptr,Size,Reversed,AnsiBuildDecodingTable(EncodingTable),PaddingChar,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base8(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; PaddingChar: UnicodeChar; Header: Boolean = False): TMemSize;
begin
Result := WideDecode_Base8(Str,Ptr,Size,Reversed,WideBuildDecodingTable(EncodingTable),PaddingChar,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base8(const Str: String; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: Char; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base8(Str,Size,Reversed,DecodingTable,PaddingChar,Header);
{$ELSE}
Result := AnsiDecode_Base8(Str,Size,Reversed,DecodingTable,PaddingChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base8(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: AnsiChar; Header: Boolean = False): Pointer;
var
  ResultSize: TMemSize;
begin
Size := AnsiDecodedLength_Base8(Str,Header,PaddingChar);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := AnsiDecode_Base8(Str,Result,Size,Reversed,DecodingTable,PaddingChar,Header);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('AnsiDecode_Base8: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base8(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: UnicodeChar; Header: Boolean = False): Pointer;
var
  ResultSize: TMemSize;
begin
Size := WideDecodedLength_Base8(Str,Header,PaddingChar);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := WideDecode_Base8(Str,Result,Size,Reversed,DecodingTable,PaddingChar,Header);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('WideDecode_Base8: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function Decode_Base8(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: Char; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base8(Str,Ptr,Size,Reversed,DecodingTable,PaddingChar,Header);
{$ELSE}
Result := AnsiDecode_Base8(Str,Ptr,Size,Reversed,DecodingTable,PaddingChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function AnsiDecode_Base8(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: AnsiChar; Header: Boolean = False): TMemSize;
var
  Buffer:         Byte;
  i:              TMemSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  StrPosition:    TStrSize;
begin
Result := AnsiDecodedLength_Base8(Str,Header,PaddingChar);
DecodeCheckSize(Size,Result,8);
ResolveDataPointer(Ptr,Reversed,Size);
Remainder := 0;
RemainderBits := 0;
If Header then StrPosition := 1 + HeaderLength
  else StrPosition := 1;
For i := 1 to Result do
  begin
    case RemainderBits of
      0:  begin
            Buffer := (AnsiDecodeFromTable(Str[StrPosition],DecodingTable,8) shl 5) or
                      (AnsiDecodeFromTable(Str[StrPosition + 1],DecodingTable,8) shl 2);
            Remainder := AnsiDecodeFromTable(Str[StrPosition + 2],DecodingTable,8);
            Buffer := Buffer or (Remainder shr 1);
            Inc(StrPosition,3);
            Remainder := Remainder and $01;
            RemainderBits := 1;
          end;
      1:  begin
            Buffer := (Remainder shl 7) or (AnsiDecodeFromTable(Str[StrPosition],DecodingTable,8) shl 4) or
                      (AnsiDecodeFromTable(Str[StrPosition + 1],DecodingTable,8) shl 1);
            Remainder := AnsiDecodeFromTable(Str[StrPosition + 2],DecodingTable,8);
            Buffer := Buffer or (Remainder shr 2);
            Inc(StrPosition,3);
            Remainder := Remainder and $03;
            RemainderBits := 2;
          end;
      2:  begin
            Buffer := (Remainder shl 6) or (AnsiDecodeFromTable(Str[StrPosition],DecodingTable,8) shl 3) or
                      AnsiDecodeFromTable(Str[StrPosition + 1],DecodingTable,8);
            Inc(StrPosition,2);
            Remainder := 0;
            RemainderBits := 0;
          end;
    else
      raise EDecodingError.CreateFmt('AnsiDecode_Base8: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    PByte(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed);
  end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function WideDecode_Base8(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: UnicodeChar; Header: Boolean = False): TMemSize;
var
  Buffer:         Byte;
  i:              TMemSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  StrPosition:    TStrSize;
begin
Result := WideDecodedLength_Base8(Str,Header,PaddingChar);
DecodeCheckSize(Size,Result,8);
ResolveDataPointer(Ptr,Reversed,Size);
Remainder := 0;
RemainderBits := 0;
If Header then StrPosition := 1 + HeaderLength
  else StrPosition := 1;
For i := 1 to Result do
  begin
    case RemainderBits of
      0:  begin
            Buffer := (WideDecodeFromTable(Str[StrPosition],DecodingTable,8) shl 5) or
                      (WideDecodeFromTable(Str[StrPosition + 1],DecodingTable,8) shl 2);
            Remainder := WideDecodeFromTable(Str[StrPosition + 2],DecodingTable,8);
            Buffer := Buffer or (Remainder shr 1);
            Inc(StrPosition,3);
            Remainder := Remainder and $01;
            RemainderBits := 1;
          end;
      1:  begin
            Buffer := (Remainder shl 7) or (WideDecodeFromTable(Str[StrPosition],DecodingTable,8) shl 4) or
                      (WideDecodeFromTable(Str[StrPosition + 1],DecodingTable,8) shl 1);
            Remainder := WideDecodeFromTable(Str[StrPosition + 2],DecodingTable,8);
            Buffer := Buffer or (Remainder shr 2);
            Inc(StrPosition,3);
            Remainder := Remainder and $03;
            RemainderBits := 2;
          end;
      2:  begin
            Buffer := (Remainder shl 6) or (WideDecodeFromTable(Str[StrPosition],DecodingTable,8) shl 3) or
                      WideDecodeFromTable(Str[StrPosition + 1],DecodingTable,8);
            Inc(StrPosition,2);
            Remainder := 0;
            RemainderBits := 0;
          end;
    else
      raise EDecodingError.CreateFmt('WideDecode_Base8: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    PByte(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed);
  end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{==============================================================================}

Function Decode_Base10(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base10(Str,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Base10(Str,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base10(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base10(Str,Size,Reversed,DecodingTable_Base10,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base10(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
Result := WideDecode_Base10(Str,Size,Reversed,DecodingTable_Base10,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base10(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base10(Str,Ptr,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Base10(Str,Ptr,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base10(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecode_Base10(Str,Ptr,Size,Reversed,DecodingTable_Base10,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base10(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := WideDecode_Base10(Str,Ptr,Size,Reversed,DecodingTable_Base10,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base10(const Str: String; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base10(Str,Size,Reversed,EncodingTable,Header);
{$ELSE}
Result := AnsiDecode_Base10(Str,Size,Reversed,EncodingTable,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base10(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; Header: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base10(Str,Size,Reversed,AnsiBuildDecodingTable(EncodingTable),Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base10(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; Header: Boolean = False): Pointer;
begin
Result := WideDecode_Base10(Str,Size,Reversed,WideBuildDecodingTable(EncodingTable),Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base10(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base10(Str,Ptr,Size,Reversed,EncodingTable,Header);
{$ELSE}
Result := AnsiDecode_Base10(Str,Ptr,Size,Reversed,EncodingTable,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base10(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecode_Base10(Str,Ptr,Size,Reversed,AnsiBuildDecodingTable(EncodingTable),Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base10(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; Header: Boolean = False): TMemSize;
begin
Result := WideDecode_Base10(Str,Ptr,Size,Reversed,WideBuildDecodingTable(EncodingTable),Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base10(const Str: String; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base10(Str,Size,Reversed,DecodingTable,Header);
{$ELSE}
Result := AnsiDecode_Base10(Str,Size,Reversed,DecodingTable,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base10(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): Pointer;
var
  ResultSize: TMemSize;
begin
Size := AnsiDecodedLength_Base10(Str,Header);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := AnsiDecode_Base10(Str,Result,Size,Reversed,DecodingTable,Header);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('AnsiDecode_Base10: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base10(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): Pointer;
var
  ResultSize: TMemSize;
begin
Size := WideDecodedLength_Base10(Str,Header);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := WideDecode_Base10(Str,Result,Size,Reversed,DecodingTable,Header);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('WideDecode_Base10: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function Decode_Base10(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base10(Str,Ptr,Size,Reversed,DecodingTable,Header);
{$ELSE}
Result := AnsiDecode_Base10(Str,Ptr,Size,Reversed,DecodingTable,Header);
{$ENDIF}
end;


{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function AnsiDecode_Base10(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): TMemSize;
var
  i:          TMemSize;
  StrOffset:  TStrSize;
begin
Result := AnsiDecodedLength_Base10(Str,Header);
DecodeCheckSize(Size,Result,10);
ResolveDataPointer(Ptr,Reversed,Size);
If Header then StrOffset := HeaderLength
  else StrOffset := 0;
If Result > 0 then
  For i := 0 to Pred(Result) do
    begin
      PByte(Ptr)^ := AnsiDecodeFromTable(Str[TMemSize(StrOffset) + (i * 3) + 1],DecodingTable,10) * Coefficients_Base10[1] +
                     AnsiDecodeFromTable(Str[TMemSize(StrOffset) + (i * 3) + 2],DecodingTable,10) * Coefficients_Base10[2] +
                     AnsiDecodeFromTable(Str[TMemSize(StrOffset) + (i * 3) + 3],DecodingTable,10) * Coefficients_Base10[3];
      AdvanceDataPointer(Ptr,Reversed)
    end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function WideDecode_Base10(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): TMemSize;
var
  i:          TMemSize;
  StrOffset:  TStrSize;
begin
Result := WideDecodedLength_Base10(Str,Header);
DecodeCheckSize(Size,Result,10);
ResolveDataPointer(Ptr,Reversed,Size);
If Header then StrOffset := HeaderLength
  else StrOffset := 0;
If Result > 0 then
  For i := 0 to Pred(Result) do
    begin
      PByte(Ptr)^ := WideDecodeFromTable(Str[TMemSize(StrOffset) + (i * 3) + 1],DecodingTable,10) * Coefficients_Base10[1] +
                     WideDecodeFromTable(Str[TMemSize(StrOffset) + (i * 3) + 2],DecodingTable,10) * Coefficients_Base10[2] +
                     WideDecodeFromTable(Str[TMemSize(StrOffset) + (i * 3) + 3],DecodingTable,10) * Coefficients_Base10[3];
      AdvanceDataPointer(Ptr,Reversed)
    end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{==============================================================================}

Function Decode_Base16(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base16(Str,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Base16(Str,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base16(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base16(Str,Size,Reversed,DecodingTable_Base16,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base16(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
Result := WideDecode_Base16(Str,Size,Reversed,DecodingTable_Base16,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base16(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base16(Str,Ptr,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Base16(Str,Ptr,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base16(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecode_Base16(Str,Ptr,Size,Reversed,DecodingTable_Base16,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base16(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := WideDecode_Base16(Str,Ptr,Size,Reversed,DecodingTable_Base16,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base16(const Str: String; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base16(Str,Size,Reversed,EncodingTable,Header);
{$ELSE}
Result := AnsiDecode_Base16(Str,Size,Reversed,EncodingTable,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base16(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; Header: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base16(Str,Size,Reversed,AnsiBuildDecodingTable(EncodingTable),Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base16(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; Header: Boolean = False): Pointer;
begin
Result := WideDecode_Base16(Str,Size,Reversed,WideBuildDecodingTable(EncodingTable),Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base16(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base16(Str,Ptr,Size,Reversed,EncodingTable,Header);
{$ELSE}
Result := AnsiDecode_Base16(Str,Ptr,Size,Reversed,EncodingTable,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base16(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecode_Base16(Str,Ptr,Size,Reversed,AnsiBuildDecodingTable(EncodingTable),Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base16(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; Header: Boolean = False): TMemSize;
begin
Result := WideDecode_Base16(Str,Ptr,Size,Reversed,WideBuildDecodingTable(EncodingTable),Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base16(const Str: String; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base16(Str,Size,Reversed,DecodingTable,Header);
{$ELSE}
Result := AnsiDecode_Base16(Str,Size,Reversed,DecodingTable,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base16(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): Pointer;
var
  ResultSize: TMemSize;
begin
Size := AnsiDecodedLength_Base16(Str,Header);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := AnsiDecode_Base16(Str,Result,Size,Reversed,DecodingTable,Header);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('AnsiDecode_Base16: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base16(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): Pointer;
var
  ResultSize: TMemSize;
begin
Size := WideDecodedLength_Base16(Str,Header);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := WideDecode_Base16(Str,Result,Size,Reversed,DecodingTable,Header);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('WideDecode_Base16: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function Decode_Base16(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base16(Str,Ptr,Size,Reversed,DecodingTable,Header);
{$ELSE}
Result := AnsiDecode_Base16(Str,Ptr,Size,Reversed,DecodingTable,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function AnsiDecode_Base16(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False; Hex: Boolean = False): TMemSize;
var
  i:          TMemSize;
  StrOffset:  TStrSize;
begin
If Hex then
  Result := AnsiDecodedLength_Hexadecimal(Str,Header)
else
  Result := AnsiDecodedLength_Base16(Str,Header);
DecodeCheckSize(Size,Result,16);
ResolveDataPointer(Ptr,Reversed,Size);
If Header then
  begin
    If Hex then StrOffset := HexadecimalHeaderLength
      else StrOffset := HeaderLength
  end
else StrOffset := 0;
If Result > 0 then
  For i := 0 to Pred(Result) do
    begin
      PByte(Ptr)^ := (AnsiDecodeFromTable(Str[TMemSize(StrOffset) + (i * 2) + 1],DecodingTable,16) shl 4) or
                     (AnsiDecodeFromTable(Str[TMemSize(StrOffset) + (i * 2) + 2],DecodingTable,16) and Byte($0F));
      AdvanceDataPointer(Ptr,Reversed);
    end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function WideDecode_Base16(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; Header: Boolean = False; Hex: Boolean = False): TMemSize;
var
  i:          TMemSize;
  StrOffset:  TStrSize;
begin
If Hex then
  Result := WideDecodedLength_Hexadecimal(Str,Header)
else
  Result := WideDecodedLength_Base16(Str,Header);
DecodeCheckSize(Size,Result,16);
ResolveDataPointer(Ptr,Reversed,Size);
If Header then
  begin
    If Hex then StrOffset := HexadecimalHeaderLength
      else StrOffset := HeaderLength
  end
else StrOffset := 0;
If Result > 0 then
  For i := 0 to Pred(Result) do
    begin
      PByte(Ptr)^ := (WideDecodeFromTable(Str[TMemSize(StrOffset) + (i * 2) + 1],DecodingTable,16) shl 4) or
                     (WideDecodeFromTable(Str[TMemSize(StrOffset) + (i * 2) + 2],DecodingTable,16) and Byte($0F));
      AdvanceDataPointer(Ptr,Reversed);
    end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

Function Decode_Hexadecimal(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Hexadecimal(Str,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Hexadecimal(Str,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Hexadecimal(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
var
  ResultSize: TMemSize;
begin
Size := AnsiDecodedLength_Hexadecimal(Str,Header);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := AnsiDecode_Hexadecimal(Str,Result,Size,Reversed,Header);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('AnsiDecode_Hexadecimal: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Hexadecimal(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
var
  ResultSize: TMemSize;
begin
Size := WideDecodedLength_Hexadecimal(Str,Header);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := WideDecode_Hexadecimal(Str,Result,Size,Reversed,Header);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('WideDecode_Hexadecimal: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function Decode_Hexadecimal(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Hexadecimal(Str,Ptr,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Hexadecimal(Str,Ptr,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Hexadecimal(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecode_Base16(Str,Ptr,Size,Reversed,DecodingTable_Hexadecimal,Header,True);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Hexadecimal(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := WideDecode_Base16(Str,Ptr,Size,Reversed,DecodingTable_Hexadecimal,Header,True);
end;

{==============================================================================}

Function Decode_Base32(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base32(Str,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Base32(Str,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base32(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base32(Str,Size,Reversed,DecodingTable_Base32,AnsiPaddingChar_Base32,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base32(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
Result := WideDecode_Base32(Str,Size,Reversed,DecodingTable_Base32,WidePaddingChar_Base32,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base32(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base32(Str,Ptr,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Base32(Str,Ptr,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base32(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecode_Base32(Str,Ptr,Size,Reversed,DecodingTable_Base32,AnsiPaddingChar_Base32,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base32(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := WideDecode_Base32(Str,Ptr,Size,Reversed,DecodingTable_Base32,WidePaddingChar_Base32,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base32(const Str: String; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; PaddingChar: Char; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base32(Str,Size,Reversed,EncodingTable,PaddingChar,Header);
{$ELSE}
Result := AnsiDecode_Base32(Str,Size,Reversed,EncodingTable,PaddingChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base32(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; PaddingChar: AnsiChar; Header: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base32(Str,Size,Reversed,AnsiBuildDecodingTable(EncodingTable),PaddingChar,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base32(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; PaddingChar: UnicodeChar; Header: Boolean = False): Pointer;
begin
Result := WideDecode_Base32(Str,Size,Reversed,WideBuildDecodingTable(EncodingTable),PaddingChar,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base32(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; PaddingChar: Char; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base32(Str,Ptr,Size,Reversed,EncodingTable,PaddingChar,Header);
{$ELSE}
Result := AnsiDecode_Base32(Str,Ptr,Size,Reversed,EncodingTable,PaddingChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base32(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; PaddingChar: AnsiChar; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecode_Base32(Str,Ptr,Size,Reversed,AnsiBuildDecodingTable(EncodingTable),PaddingChar,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base32(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; PaddingChar: UnicodeChar; Header: Boolean = False): TMemSize;
begin
Result := WideDecode_Base32(Str,Ptr,Size,Reversed,WideBuildDecodingTable(EncodingTable),PaddingChar,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base32(const Str: String; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: Char; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base32(Str,Size,Reversed,DecodingTable,PaddingChar,Header);
{$ELSE}
Result := AnsiDecode_Base32(Str,Size,Reversed,DecodingTable,PaddingChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base32(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: AnsiChar; Header: Boolean = False): Pointer;
var
  ResultSize: TMemSize;
begin
Size := AnsiDecodedLength_Base32(Str,Header,PaddingChar);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := AnsiDecode_Base32(Str,Result,Size,Reversed,DecodingTable,PaddingChar,Header);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('AnsiDecode_Base32: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base32(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: UnicodeChar; Header: Boolean = False): Pointer;
var
  ResultSize: TMemSize;
begin
Size := WideDecodedLength_Base32(Str,Header,PaddingChar);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := WideDecode_Base32(Str,Result,Size,Reversed,DecodingTable,PaddingChar,Header);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('WideDecode_Base32: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function Decode_Base32(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: Char; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base32(Str,Ptr,Size,Reversed,DecodingTable,PaddingChar,Header);
{$ELSE}
Result := AnsiDecode_Base32(Str,Ptr,Size,Reversed,DecodingTable,PaddingChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function AnsiDecode_Base32(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: AnsiChar; Header: Boolean = False): TMemSize;
var
  Buffer:         Byte;
  i:              TMemSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  StrPosition:    TStrSize;
begin
Result := AnsiDecodedLength_Base32(Str,Header,PaddingChar);
DecodeCheckSize(Size,Result,32);
ResolveDataPointer(Ptr,Reversed,Size);
Remainder := 0;
RemainderBits := 0;
If Header then StrPosition := 1 + HeaderLength
  else StrPosition := 1;
For i := 1 to Result do
  begin
    case RemainderBits of
      0:  begin
            Buffer := AnsiDecodeFromTable(Str[StrPosition],DecodingTable,32) shl 3;
            Remainder := AnsiDecodeFromTable(Str[StrPosition + 1],DecodingTable,32);
            Buffer := Buffer or (Remainder shr 2);
            Inc(StrPosition,2);
            Remainder := Remainder and $03;
            RemainderBits := 2;
          end;
      1:  begin
            Buffer := (Remainder shl 7) or (AnsiDecodeFromTable(Str[StrPosition],DecodingTable,32) shl 2);
            Remainder := AnsiDecodeFromTable(Str[StrPosition + 1],DecodingTable,32);
            Buffer := Buffer or (Remainder shr 3);
            Inc(StrPosition,2);
            Remainder := Remainder and $07;
            RemainderBits := 3;
          end;
      2:  begin
            Buffer := (Remainder shl 6) or (AnsiDecodeFromTable(Str[StrPosition],DecodingTable,32) shl 1);
            Remainder := AnsiDecodeFromTable(Str[StrPosition + 1],DecodingTable,32);
            Buffer := Buffer or (Remainder shr 4);
            Inc(StrPosition,2);
            Remainder := Remainder and $0F;
            RemainderBits := 4;
          end;
      3:  begin
            Buffer := (Remainder shl 5) or AnsiDecodeFromTable(Str[StrPosition],DecodingTable,32);
            Inc(StrPosition,1);
            Remainder := 0;
            RemainderBits := 0;
          end;
      4:  begin
            Buffer := (Remainder shl 4) or (AnsiDecodeFromTable(Str[StrPosition],DecodingTable,32) shr 1);
            Remainder := AnsiDecodeFromTable(Str[StrPosition],DecodingTable,32) and $01;
            Inc(StrPosition,1);
            RemainderBits := 1;
          end;
    else
      raise EDecodingError.CreateFmt('AnsiDecode_Base32: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    PByte(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed);
  end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function WideDecode_Base32(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: UnicodeChar; Header: Boolean = False): TMemSize;
var
  Buffer:         Byte;
  i:              TMemSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  StrPosition:    TStrSize;
begin
Result := WideDecodedLength_Base32(Str,Header,PaddingChar);
DecodeCheckSize(Size,Result,32);
ResolveDataPointer(Ptr,Reversed,Size);
Remainder := 0;
RemainderBits := 0;
If Header then StrPosition := 1 + HeaderLength
  else StrPosition := 1;
For i := 1 to Result do
  begin
    case RemainderBits of
      0:  begin
            Buffer := WideDecodeFromTable(Str[StrPosition],DecodingTable,32) shl 3;
            Remainder := WideDecodeFromTable(Str[StrPosition + 1],DecodingTable,32);
            Buffer := Buffer or (Remainder shr 2);
            Inc(StrPosition,2);
            Remainder := Remainder and $03;
            RemainderBits := 2;
          end;
      1:  begin
            Buffer := (Remainder shl 7) or (WideDecodeFromTable(Str[StrPosition],DecodingTable,32) shl 2);
            Remainder := WideDecodeFromTable(Str[StrPosition + 1],DecodingTable,32);
            Buffer := Buffer or (Remainder shr 3);
            Inc(StrPosition,2);
            Remainder := Remainder and $07;
            RemainderBits := 3;
          end;
      2:  begin
            Buffer := (Remainder shl 6) or (WideDecodeFromTable(Str[StrPosition],DecodingTable,32) shl 1);
            Remainder := WideDecodeFromTable(Str[StrPosition + 1],DecodingTable,32);
            Buffer := Buffer or (Remainder shr 4);
            Inc(StrPosition,2);
            Remainder := Remainder and $0F;
            RemainderBits := 4;
          end;
      3:  begin
            Buffer := (Remainder shl 5) or WideDecodeFromTable(Str[StrPosition],DecodingTable,32);
            Inc(StrPosition,1);
            Remainder := 0;
            RemainderBits := 0;
          end;
      4:  begin
            Buffer := (Remainder shl 4) or (WideDecodeFromTable(Str[StrPosition],DecodingTable,32) shr 1);
            Remainder := WideDecodeFromTable(Str[StrPosition],DecodingTable,32) and $01;
            Inc(StrPosition,1);
            RemainderBits := 1;
          end;
    else
      raise EDecodingError.CreateFmt('WideDecode_Base32: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    PByte(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed);
  end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

Function Decode_Base32Hex(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base32Hex(Str,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Base32Hex(Str,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base32Hex(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base32(Str,Size,Reversed,DecodingTable_Base32Hex,AnsiPaddingChar_Base32Hex,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base32Hex(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
Result := WideDecode_Base32(Str,Size,Reversed,DecodingTable_Base32Hex,WidePaddingChar_Base32Hex,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base32Hex(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base32Hex(Str,Ptr,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Base32Hex(Str,Ptr,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base32Hex(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecode_Base32(Str,Ptr,Size,Reversed,DecodingTable_Base32Hex,AnsiPaddingChar_Base32Hex,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base32Hex(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := WideDecode_Base32(Str,Ptr,Size,Reversed,DecodingTable_Base32Hex,WidePaddingChar_Base32Hex,Header);
end;

{==============================================================================}

Function Decode_Base64(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base64(Str,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Base64(Str,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base64(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base64(Str,Size,Reversed,DecodingTable_Base64,AnsiPaddingChar_Base64,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base64(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
Result := WideDecode_Base64(Str,Size,Reversed,DecodingTable_Base64,WidePaddingChar_Base64,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base64(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base64(Str,Ptr,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Base64(Str,Ptr,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base64(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecode_Base64(Str,Ptr,Size,Reversed,DecodingTable_Base64,AnsiPaddingChar_Base64,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base64(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := WideDecode_Base64(Str,Ptr,Size,Reversed,DecodingTable_Base64,WidePaddingChar_Base64,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base64(const Str: String; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; PaddingChar: Char; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base64(Str,Size,Reversed,EncodingTable,PaddingChar,Header);
{$ELSE}
Result := AnsiDecode_Base64(Str,Size,Reversed,EncodingTable,PaddingChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base64(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; PaddingChar: AnsiChar; Header: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base64(Str,Size,Reversed,AnsiBuildDecodingTable(EncodingTable),PaddingChar,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base64(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; PaddingChar: UnicodeChar; Header: Boolean = False): Pointer;
begin
Result := WideDecode_Base64(Str,Size,Reversed,WideBuildDecodingTable(EncodingTable),PaddingChar,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base64(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; PaddingChar: Char; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base64(Str,Ptr,Size,Reversed,EncodingTable,PaddingChar,Header);
{$ELSE}
Result := AnsiDecode_Base64(Str,Ptr,Size,Reversed,EncodingTable,PaddingChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base64(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; PaddingChar: AnsiChar; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecode_Base64(Str,Ptr,Size,Reversed,AnsiBuildDecodingTable(EncodingTable),PaddingChar,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base64(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; PaddingChar: UnicodeChar; Header: Boolean = False): TMemSize;
begin
Result := WideDecode_Base64(Str,Ptr,Size,Reversed,WideBuildDecodingTable(EncodingTable),PaddingChar,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base64(const Str: String; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: Char; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base64(Str,Size,Reversed,DecodingTable,PaddingChar,Header);
{$ELSE}
Result := AnsiDecode_Base64(Str,Size,Reversed,DecodingTable,PaddingChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base64(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: AnsiChar; Header: Boolean = False): Pointer;
var
  ResultSize: TMemSize;
begin
Size := AnsiDecodedLength_Base64(Str,Header,PaddingChar);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := AnsiDecode_Base64(Str,Result,Size,Reversed,DecodingTable,PaddingChar,Header);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('AnsiDecode_Base64: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base64(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: UnicodeChar; Header: Boolean = False): Pointer;
var
  ResultSize: TMemSize;
begin
Size := WideDecodedLength_Base64(Str,Header,PaddingChar);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := WideDecode_Base64(Str,Result,Size,Reversed,DecodingTable,PaddingChar,Header);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('WideDecode_Base64: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function Decode_Base64(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: Char; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base64(Str,Ptr,Size,Reversed,DecodingTable,PaddingChar,Header);
{$ELSE}
Result := AnsiDecode_Base64(Str,Ptr,Size,Reversed,DecodingTable,PaddingChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function AnsiDecode_Base64(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: AnsiChar; Header: Boolean = False): TMemSize;
var
  Buffer:         Byte;
  i:              TMemSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  StrPosition:    TStrSize;
begin
Result := AnsiDecodedLength_Base64(Str,Header,PaddingChar);
DecodeCheckSize(Size,Result,64);
ResolveDataPointer(Ptr,Reversed,Size);
Remainder := 0;
RemainderBits := 0;
If Header then StrPosition := 1 + HeaderLength
  else StrPosition := 1;
For i := 1 to Result do
  begin
    case RemainderBits of
      0:  begin
            Buffer := AnsiDecodeFromTable(Str[StrPosition],DecodingTable,64) shl 2;
            Remainder := AnsiDecodeFromTable(Str[StrPosition + 1],DecodingTable,64);
            Buffer := Buffer or (Remainder shr 4);
            Inc(StrPosition,2);
            Remainder := Remainder and $0F;
            RemainderBits := 4;
          end;
      2:  begin
            Buffer := (Remainder shl 6) or AnsiDecodeFromTable(Str[StrPosition],DecodingTable,64);
            Inc(StrPosition,1);
            Remainder := $00;
            RemainderBits := 0;
          end;
      4:  begin
            Buffer := (Remainder shl 4) or (AnsiDecodeFromTable(Str[StrPosition],DecodingTable,64) shr 2);
            Remainder := AnsiDecodeFromTable(Str[StrPosition],DecodingTable,64) and $03;
            Inc(StrPosition,1);
            RemainderBits := 2;
          end;
    else
      raise EDecodingError.CreateFmt('AnsiDecode_Base64: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    PByte(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed);
  end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function WideDecode_Base64(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; PaddingChar: UnicodeChar; Header: Boolean = False): TMemSize;
var
  Buffer:         Byte;
  i:              TMemSize;
  Remainder:      Byte;
  RemainderBits:  Integer;
  StrPosition:    TStrSize;
begin
Result := WideDecodedLength_Base64(Str,Header,PaddingChar);
DecodeCheckSize(Size,Result,64);
ResolveDataPointer(Ptr,Reversed,Size);
Remainder := 0;
RemainderBits := 0;
If Header then StrPosition := 1 + HeaderLength
  else StrPosition := 1;
For i := 1 to Result do
  begin
    case RemainderBits of
      0:  begin
            Buffer := WideDecodeFromTable(Str[StrPosition],DecodingTable,64) shl 2;
            Remainder := WideDecodeFromTable(Str[StrPosition + 1],DecodingTable,64);
            Buffer := Buffer or (Remainder shr 4);
            Inc(StrPosition,2);
            Remainder := Remainder and $0F;
            RemainderBits := 4;
          end;
      2:  begin
            Buffer := (Remainder shl 6) or WideDecodeFromTable(Str[StrPosition],DecodingTable,64);
            Inc(StrPosition,1);
            Remainder := $00;
            RemainderBits := 0;
          end;
      4:  begin
            Buffer := (Remainder shl 4) or (WideDecodeFromTable(Str[StrPosition],DecodingTable,64) shr 2);
            Remainder := WideDecodeFromTable(Str[StrPosition],DecodingTable,64) and $03;
            Inc(StrPosition,1);
            RemainderBits := 2;
          end;
    else
      raise EDecodingError.CreateFmt('WideDecode_Base64: Invalid RemainderBits value (%d).',[RemainderBits]);
    end;
    PByte(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed);
  end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{==============================================================================}

Function Decode_Base85(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base85(Str,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Base85(Str,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base85(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base85(Str,Size,Reversed,DecodingTable_Base85,AnsiCompressionChar_Base85,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base85(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
Result := WideDecode_Base85(Str,Size,Reversed,DecodingTable_Base85,WideCompressionChar_Base85,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base85(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base85(Str,Ptr,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Base85(Str,Ptr,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base85(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecode_Base85(Str,Ptr,Size,Reversed,DecodingTable_Base85,AnsiCompressionChar_Base85,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base85(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := WideDecode_Base85(Str,Ptr,Size,Reversed,DecodingTable_Base85,WideCompressionChar_Base85,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base85(const Str: String; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; CompressionChar: Char; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base85(Str,Size,Reversed,EncodingTable,CompressionChar,Header);
{$ELSE}
Result := AnsiDecode_Base85(Str,Size,Reversed,EncodingTable,CompressionChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base85(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; CompressionChar: AnsiChar; Header: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base85(Str,Size,Reversed,AnsiBuildDecodingTable(EncodingTable),CompressionChar,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base85(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; CompressionChar: UnicodeChar; Header: Boolean = False): Pointer;
begin
Result := WideDecode_Base85(Str,Size,Reversed,WideBuildDecodingTable(EncodingTable),CompressionChar,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base85(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of Char; CompressionChar: Char; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base85(Str,Ptr,Size,Reversed,EncodingTable,CompressionChar,Header);
{$ELSE}
Result := AnsiDecode_Base85(Str,Ptr,Size,Reversed,EncodingTable,CompressionChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base85(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of AnsiChar; CompressionChar: AnsiChar; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecode_Base85(Str,Ptr,Size,Reversed,AnsiBuildDecodingTable(EncodingTable),CompressionChar,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base85(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const EncodingTable: array of UnicodeChar; CompressionChar: UnicodeChar; Header: Boolean = False): TMemSize;
begin
Result := WideDecode_Base85(Str,Ptr,Size,Reversed,WideBuildDecodingTable(EncodingTable),CompressionChar,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Base85(const Str: String; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; CompressionChar: Char; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Base85(Str,Size,Reversed,DecodingTable,CompressionChar,Header);
{$ELSE}
Result := AnsiDecode_Base85(Str,Size,Reversed,DecodingTable,CompressionChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Base85(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; CompressionChar: AnsiChar; Header: Boolean = False): Pointer;
var
  ResultSize: TMemSize;
begin
Size := AnsiDecodedLength_Base85(Str,Header,CompressionChar);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := AnsiDecode_Base85(Str,Result,Size,Reversed,DecodingTable,CompressionChar,Header);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('AnsiDecode_Base85: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function WideDecode_Base85(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; CompressionChar: UnicodeChar; Header: Boolean = False): Pointer;
var
  ResultSize: TMemSize;
begin
Size := WideDecodedLength_Base85(Str,Header,CompressionChar);
If Size > 0 then
  begin
    Result := AllocMem(Size);
    try
      ResultSize := WideDecode_Base85(Str,Result,Size,Reversed,DecodingTable,CompressionChar,Header);
      If ResultSize <> Size then
        raise EAllocationError.CreateFmt('WideDecode_Base85: Wrong result size (%d, expected %d)',[ResultSize,Size]);
    except
      FreeMem(Result,Size);
      Size := 0;
      raise;
    end;
  end
else Result := nil;
end;

{------------------------------------------------------------------------------}

Function Decode_Base85(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; CompressionChar: Char; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Base85(Str,Ptr,Size,Reversed,DecodingTable,CompressionChar,Header);
{$ELSE}
Result := AnsiDecode_Base85(Str,Ptr,Size,Reversed,DecodingTable,CompressionChar,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function AnsiDecode_Base85(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; CompressionChar: AnsiChar; Header: Boolean = False): TMemSize;
var
  i:            TMemSize;
  j:            Integer;
  Buffer:       UInt32;
  Buffer64:     Int64;
  StrPosition:  TStrSize;
begin
Result := AnsiDecodedLength_Base85(Str,Header,CompressionChar);
DecodeCheckSize(Size,Result,85,3);
If Size < Result then Result := Size;
ResolveDataPointer(Ptr,Reversed,Size,4);
If Header then StrPosition := 1 + HeaderLength
  else StrPosition := 1;
For i := 1 to Ceil(Result / 4) do
  begin
    If Str[StrPosition] = CompressionChar then
      begin
        Buffer := $00000000;
        Inc(StrPosition);
      end
    else
      begin
        Buffer64 := 0;
        For j := 0 to 4 do
          begin
            while ((StrPosition + j) <= Length(Str)) and ((Ord(Str[StrPosition + j]) <= 32) or (Ord(Str[StrPosition + j]) >= 127)) do
              Inc(StrPosition);
            If (StrPosition + j) <= Length(Str) then
              Buffer64 := Buffer64 + (Int64(AnsiDecodeFromTable(Str[StrPosition + j],DecodingTable,85)) * Coefficients_Base85[j + 1])
            else
              Buffer64 := Buffer64 + (Int64(84) * Coefficients_Base85[j + 1]);
          end;
        If Buffer64 > High(UInt32) then
          raise EDecodingError.CreateFmt('AnsiDecode_Base85: Invalid value decoded (%d).',[Buffer64]);
        Buffer := UInt32(Buffer64);
        Inc(StrPosition,5);
      end;
  {$IFDEF ENDIAN_BIG}
    If Reversed then SwapByteOrder(Buffer);
  {$ELSE}
    If not Reversed then SwapByteOrder(Buffer);
  {$ENDIF}
    If (i * 4) > Result  then
      begin
        If Reversed then
        {$IFDEF FPCDWM}{$PUSH}W4055 W4056{$ENDIF}
          Move(Pointer(PtrUInt(@Buffer) - PtrUInt(Result and 3) + 4)^,Pointer(PtrUInt(Ptr) - PtrUInt(Result and 3) + 4)^,Result and 3)
        {$IFDEF FPCDWM}{$POP}{$ENDIF}
        else
          Move(Buffer,Ptr^,Result and 3);
      end
    else PUInt32(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed,4);
  end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W5058{$ENDIF}
Function WideDecode_Base85(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean; const DecodingTable: TDecodingTable; CompressionChar: UnicodeChar; Header: Boolean = False): TMemSize;
var
  i:            TMemSize;
  j:            Integer;
  Buffer:       UInt32;
  Buffer64:     Int64;
  StrPosition:  TStrSize;
begin
Result := WideDecodedLength_Base85(Str,Header,CompressionChar);
DecodeCheckSize(Size,Result,85,3);
If Size < Result then Result := Size;
ResolveDataPointer(Ptr,Reversed,Size,4);
If Header then StrPosition := 1 + HeaderLength
  else StrPosition := 1;
For i := 1 to Ceil(Result / 4) do
  begin
    If Str[StrPosition] = CompressionChar then
      begin
        Buffer := $00000000;
        Inc(StrPosition);
      end
    else
      begin
        Buffer64 := 0;
        For j := 0 to 4 do
          begin
            while ((StrPosition + j) <= Length(Str)) and ((Ord(Str[StrPosition + j]) <= 32) or (Ord(Str[StrPosition + j]) >= 127)) do
              Inc(StrPosition);
            If (StrPosition + j) <= Length(Str) then
              Buffer64 := Buffer64 + (Int64(WideDecodeFromTable(Str[StrPosition + j],DecodingTable,85)) * Coefficients_Base85[j + 1])
            else
              Buffer64 := Buffer64 + (Int64(84) * Coefficients_Base85[j + 1]);
          end;
        If Buffer64 > High(UInt32) then
          raise EDecodingError.CreateFmt('WideDecode_Base85: Invalid value decoded (%d).',[Buffer64]);
        Buffer := UInt32(Buffer64);
        Inc(StrPosition,5);
      end;
  {$IFDEF ENDIAN_BIG}
    If Reversed then SwapByteOrder(Buffer);
  {$ELSE}
    If not Reversed then SwapByteOrder(Buffer);
  {$ENDIF}
    If (i * 4) > Result  then
      begin
        If Reversed then
        {$IFDEF FPCDWM}{$PUSH}W4055 W4056{$ENDIF}
          Move(Pointer(PtrUInt(@Buffer) - PtrUInt(Result and 3) + 4)^,Pointer(PtrUInt(Ptr) - PtrUInt(Result and 3) + 4)^,Result and 3)
        {$IFDEF FPCDWM}{$POP}{$ENDIF}
        else
          Move(Buffer,Ptr^,Result and 3);
      end
    else PUInt32(Ptr)^ := Buffer;
    AdvanceDataPointer(Ptr,Reversed,4);
  end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}

Function Decode_Ascii85(const Str: String; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
{$IFDEF Unicode}
Result := WideDecode_Ascii85(Str,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Ascii85(Str,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Ascii85(const Str: AnsiString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
Result := AnsiDecode_Base85(Str,Size,Reversed,DecodingTable_Ascii85,AnsiCompressionChar_Ascii85,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Ascii85(const Str: UnicodeString; out Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): Pointer;
begin
Result := WideDecode_Base85(Str,Size,Reversed,DecodingTable_Ascii85,WideCompressionChar_Ascii85,Header);
end;

{------------------------------------------------------------------------------}

Function Decode_Ascii85(const Str: String; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
{$IFDEF Unicode}
Result := WideDecode_Ascii85(Str,Ptr,Size,Reversed,Header);
{$ELSE}
Result := AnsiDecode_Ascii85(Str,Ptr,Size,Reversed,Header);
{$ENDIF}
end;

{------------------------------------------------------------------------------}

Function AnsiDecode_Ascii85(const Str: AnsiString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := AnsiDecode_Base85(Str,Ptr,Size,Reversed,DecodingTable_Ascii85,AnsiCompressionChar_Ascii85,Header);
end;

{------------------------------------------------------------------------------}

Function WideDecode_Ascii85(const Str: UnicodeString; Ptr: Pointer; Size: TMemSize; Reversed: Boolean = False; Header: Boolean = False): TMemSize;
begin
Result := WideDecode_Base85(Str,Ptr,Size,Reversed,DecodingTable_Ascii85,WideCompressionChar_Ascii85,Header);
end;

end.

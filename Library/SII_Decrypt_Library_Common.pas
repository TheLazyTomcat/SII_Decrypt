{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decrypt_Library_Common;

{$INCLUDE '..\Source\SII_Decrypt_defs.inc'}

interface

uses
  AuxTypes;

Function StrConv(Str: PUTF8Char): String;

Function BuildAPIVersion(Major,Minor: UInt16): UInt32;

implementation

uses
  StrRect;

Function StrConv(Str: PUTF8Char): String;
begin
Result := UTF8ToStr(UTF8String(Str));
end;

//------------------------------------------------------------------------------

Function BuildAPIVersion(Major,Minor: UInt16): UInt32;
begin
Result := (UInt32(Major) shl 16) or UInt32(Minor);
end;

end.

{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_Common;

{$INCLUDE '.\SII_Decode_defs.inc'}

interface

uses
  AuxTypes;

const
  SIIBIN_SIGNARUTE_BIN   = UInt32($49495342);   // BSII
  SIIBin_SIGNATURE_CRYPT = UInt32($43736353);   // ScsC
  SIIBin_SIGNATURE_TEXT  = UInt32($4E696953);   // SiiN

//------------------------------------------------------------------------------

type
  TSIIBin_BlockType    = UInt32;
  TSIIBin_ValueType    = UInt32;

  TSIIBin_ArrayLength  = UInt32;
  TSIIBin_StringLength = UInt32;

  TSIIBin_StructureID  = UInt32;

  TSIIBin_Vec3s = packed array[0..2] of Single;
  TSIIBin_Vec4s = packed array[0..3] of Single;
  TSIIBin_Vec8s = packed array[0..7] of Single;

  TSIIBin_Vec3i = packed array[0..2] of Int32;

  TSIIBin_ID = record
    Length:   UInt8;
    Parts:    array of UInt64;
    PartsStr: array of AnsiString;  // for conversion only, not stored in the file
  end;

//------------------------------------------------------------------------------

  TSIIBin_NamedValue = record
    ValueType:  TSIIBin_ValueType;
    ValueName:  AnsiString;
    ValueData:  TObject;
  end;

  TSIIBin_Structure = record
    Valid:    ByteBool;
    ID:       TSIIBin_StructureID;
    Name:     AnsiString;
    Fields:   array of TSIIBin_NamedValue;
  end;

//------------------------------------------------------------------------------

  TSIIBin_FileHeader = packed record
    Signature:  UInt32;
    Version:    UInt32;
  end;  

  TSIIBin_FileInfo = record
    Header:     TSIIBin_FileHeader;
    Structures: array of TSIIBin_Structure;
  end;

//------------------------------------------------------------------------------

const
  SIIBIN_LARGE_ARRAY_THRESHOLD = 16;

implementation

end.

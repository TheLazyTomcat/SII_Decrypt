{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_Common;

{$INCLUDE '.\SII_Decode_defs.inc'}

interface

uses
  Classes,
  AuxTypes;

{==============================================================================}
{   Types and constants for the decoder                                        }
{==============================================================================}

const
  SIIBin_Signature_Bin   = UInt32($49495342);   // BSII
  SIIBin_Signature_Crypt = UInt32($43736353);   // ScsC
  SIIBin_Signature_Text  = UInt32($4E696953);   // SiiN

type
  TSIIBin_ValueType      = UInt32;
  TSIIBin_ArrayLength    = UInt32;
  TSIIBin_StringLength   = UInt32;
  TSIIBin_StructureIndex = UInt32;

  TSIIBin_Header = packed record
    Signature:  UInt32;
    Unknown:    UInt32;
  end;

  TSIIBin_NamedValue = record
    ValueType:  TSIIBin_ValueType;
    ValueName:  AnsiString;
  end;

  TSIIBin_Structure = record
    Unknown:  UInt8;
    Index:    TSIIBin_StructureIndex;
    Name:     AnsiString;
    Fields:   array of TSIIBin_NamedValue;
  end;

  TSIIBin_FileStructure = record
    Header:     TSIIBin_Header;
    Structures: array of TSIIBin_Structure;
  end;

  TSIIBin_Value_ID = record
    Length: UInt8;
    Parts:    array of UInt64;
    PartsStr: array of AnsiString;
  end;

  TSIIBin_Value_Vec3s = packed array[0..2] of Single;
  TSIIBin_Value_Vec4s = packed array[0..3] of Single;
  TSIIBin_Value_Vec8s = packed array[0..7] of Single;

  TSIIBin_Value_Vec3i = packed array[0..2] of Int32;

{==============================================================================}
{   Auxiliary functions - declaration                                          }
{==============================================================================}

procedure SIIBin_LoadString(Stream: TStream; var Str: AnsiString);
procedure SIIBin_LoadID(Stream: TStream; var ID: TSIIBin_Value_ID);

Function SIIBin_DecodeID(EncodedID: UInt64): AnsiString; overload;
procedure SIIBin_DecodeID(var ID: TSIIBin_Value_ID); overload;

Function SIIBin_SingleToStr(Value: Single): String;
Function SIIBin_IDToStr(ID: TSIIBin_Value_ID): String;

Function SIIBin_IsLimitedAlphabet(const Str: AnsiString): Boolean;
procedure SIIBin_RectifyString(var Str: AnsiString);


implementation

uses
  SysUtils,
  BinaryStreaming, FloatHex;

{==============================================================================}
{   Auxiliary functions - implementation                                       }
{==============================================================================}

procedure SIIBin_LoadString(Stream: TStream; var Str: AnsiString);
begin
SetLength(Str,Stream_ReadUInt32(Stream));
Stream_ReadBuffer(Stream,PAnsiChar(Str)^,Length(Str));
end;

//------------------------------------------------------------------------------

procedure SIIBin_LoadID(Stream: TStream; var ID: TSIIBin_Value_ID);
var
  i:  Integer;
begin
ID.Length := Stream_ReadUInt8(Stream);
If ID.Length = $FF then
  SetLength(ID.Parts,1)
else
  SetLength(ID.Parts,ID.Length);
For i := Low(ID.Parts) to High(ID.Parts) do
  ID.Parts[i] := Stream_ReadUInt64(Stream);
SetLength(ID.PartsStr,Length(ID.Parts));
end;

//------------------------------------------------------------------------------

Function SIIBin_DecodeID(EncodedID: UInt64): AnsiString;
const
  DecodeTable: array[1..37] of AnsiChar = (
    '0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f','g','h',
    'i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','_');
var
  CharIdx:  Byte;
begin
Result := '';
while EncodedID <> 0 do
  begin
    CharIdx := EncodedID mod 38;
    EncodedID := (EncodedID - UInt64(CharIdx)) div 38;
    If (CharIdx >= Low(DecodeTable)) and (CharIdx <= High(DecodeTable)) then
      Result := Result + DecodeTable[CharIdx]
    else
      raise Exception.CreateFmt('SIIBin_DecodeID: Character index (%d) out of bounds.',[CharIdx]);
  end;
end;

//------------------------------------------------------------------------------

procedure SIIBin_DecodeID(var ID: TSIIBin_Value_ID);
var
  i:  Integer;
begin
If not (ID.Length in [0,$FF]) then
  begin
    If Length(ID.PartsStr) <> Length(ID.Parts) then
      SetLength(ID.PartsStr,Length(ID.Parts));
    For i := Low(ID.Parts) to High(ID.Parts) do
      ID.PartsStr[i] := SIIBin_DecodeID(ID.Parts[i]);
  end;
end;

//------------------------------------------------------------------------------

Function SIIBin_SingleToStr(Value: Single): String;
begin
If (Frac(Value) <> 0) or (Value >= 1e7) then
  Result := '&' + AnsiLowerCase(SingleToHex(Value))
else
  Result := Format('%.0f',[Value]);
end;

//------------------------------------------------------------------------------

Function SIIBin_IDToStr(ID: TSIIBin_Value_ID): String;
var
  i:    Integer;
{$IFDEF NamelessID_NewHexStyle}
  Temp: UInt64;
{$ENDIF}
begin
case ID.Length of
  $00:  Result := 'null';
{$IFDEF NamelessID_NewHexStyle}
  $FF:  If ID.Parts[0] <> 0 then
          begin
            Temp := ID.Parts[0];
            Result := '';
            while Temp <> 0 do
              begin
                If (Temp and not UInt64($FFFF)) <> 0 then
                  Result := AnsiLowerCase(Format('.%.4x',[UInt16(Temp)])) + Result
                else
                  Result := AnsiLowerCase(Format('.%x',[UInt16(Temp)])) + Result;
                Temp := Temp shr 16;
              end;
            Result := '_nameless' + Result;
          end
        else Result := '_nameless.0';
{$ELSE}
  $FF:  Result := '_nameless' + AnsiUpperCase(Format('.%.4x.%.4x',
                                             [Int64Rec(ID.Parts[0]).Words[1],
                                              Int64Rec(ID.Parts[0]).Words[0]]));
{$ENDIF}
else
  Result := ID.PartsStr[0];
  For i := Succ(Low(ID.Parts)) to High(ID.Parts) do
    Result := Result + '.' + ID.PartsStr[i];
end;
end;

//------------------------------------------------------------------------------

Function SIIBin_IsLimitedAlphabet(const Str: AnsiString): Boolean;
var
  i:  Integer;
begin
Result := True;
For i := 1 to Length(Str) do
  If not (Str[i] in ['0'..'9','a'..'z','A'..'Z','_']) then
    begin
      Result := False;
      Break;
    end;
end;

//------------------------------------------------------------------------------

procedure SIIBin_RectifyString(var Str: AnsiString);
var
  i:    Integer;
  Temp: AnsiString;

  Function NonASCII: Boolean;
  var
    ii: Integer;
  begin
    Result := True;
    For ii := 1 to Length(Str) do
      If Ord(Str[ii]) >= 127 then Exit;
    Result := False;
  end;

begin
If NonASCII then
  begin
    Temp := '';
    For i := 1 to Length(Str) do
      begin
        If (Ord(Str[i]) < 127) and (Ord(Str[i]) > 31) then
          Temp := Temp + Str[i]
        else
          Temp := Temp + AnsiLowerCase(Format('\x%.2x',[Ord(Str[i])]));
      end;
    Str := Temp;
  end;
end;

end.

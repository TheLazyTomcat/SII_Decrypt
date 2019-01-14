{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_Utils;

{$INCLUDE '.\SII_Decode_defs.inc'}

interface

uses
  Classes,
  AuxTypes,
  SII_Decode_Common;

{===============================================================================
    Utility functions - declaration
===============================================================================}

Function SIIBin_SingleToStr(Value: Single): AnsiString;
Function SIIBin_DoubleToStr(Value: Double): AnsiString;

procedure SIIBin_LoadString(Stream: TStream; out Str: AnsiString);
procedure SIIBin_LoadID(Stream: TStream; out ID: TSIIBin_ID);

Function SIIBin_EncodeID(ID: AnsiString): UInt64;
Function SIIBin_DecodeID(EncodedID: UInt64): AnsiString; overload;
procedure SIIBin_DecodeID(var ID: TSIIBin_ID); overload;

Function SIIBin_IDToStr(ID: TSIIBin_ID; OldHexStyle: Boolean): AnsiString;

Function SIIBin_IsLimitedAlphabet(const Str: AnsiString): Boolean;
procedure SIIBin_RectifyString(var Str: AnsiString);

implementation

uses
  SysUtils, Math,
  BinaryStreaming, AuxExceptions, StrRect, FloatHex;

{===============================================================================
    Utility functions - implementation
===============================================================================}

Function SIIBin_SingleToStr(Value: Single): AnsiString;
begin
If not IsNaN(Value) then
  begin
    If (Frac(Value) <> 0) or (Value >= 1e7) then
      Result := StrToAnsi('&' + AnsiLowerCase(SingleToHex(Value)))
    else
      Result := StrToAnsi(Format('%.0f',[Value]));
  end
else Result := StrToAnsi('&' + AnsiLowerCase(SingleToHex(Value)));
end;

//------------------------------------------------------------------------------

Function SIIBin_DoubleToStr(Value: Double): AnsiString;
begin
If not IsNaN(Value) then
  begin
    If (Frac(Value) <> 0) or (Value >= 1e15) then
      Result := StrToAnsi('&' + AnsiLowerCase(DoubleToHex(Value)))
    else
      Result := StrToAnsi(Format('%.0f',[Value]));
  end
else Result := StrToAnsi('&' + AnsiLowerCase(DoubleToHex(Value)));
end;

//------------------------------------------------------------------------------

procedure SIIBin_LoadString(Stream: TStream; out Str: AnsiString);
begin
SetLength(Str,Stream_ReadUInt32(Stream));
Stream_ReadBuffer(Stream,PAnsiChar(Str)^,Length(Str));
end;

//------------------------------------------------------------------------------

procedure SIIBin_LoadID(Stream: TStream; out ID: TSIIBin_ID);
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

Function SIIBin_EncodeID(ID: AnsiString): UInt64;
const
  EncodeTable: array[AnsiChar] of Byte = (
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    01, 02, 03, 04, 05, 06, 07, 08, 09, 10,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0, 37,
     0, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25,
    26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
     0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0);
var
  i:  Integer;
begin
Result := 0;
If Length(ID) <= 12 then  // 12 is largest power of 38 smaller than High(UInt64)
  begin
    For i := Length(ID) downto 1 do
      If EncodeTable[ID[i]] > 0 then
        Result := UInt64((Result * 38) + EncodeTable[ID[i]])
      else
        raise EGeneralException.CreateFmt('Invalid character (#%d).',[Ord(ID[i])],nil,'SIIBin_EncodeID');
  end
else raise EGeneralException.CreateFmt('ID is too long (%d).',[Length(ID)],nil,'SIIBin_EncodeID');
end;

//------------------------------------------------------------------------------

Function SIIBin_DecodeID(EncodedID: UInt64): AnsiString;
const
  DecodeTable: array[1..37] of AnsiChar = (
    '0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f','g','h',
    'i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','_');
var
  CharIdx:  Integer;
  Len:      Integer;
begin
EncodedID := EncodedID and not(UInt64(1) shl 63); // mask out bit 63
SetLength(Result,12);
Len := 0;
while EncodedID <> 0 do
  begin
    CharIdx := Abs(Integer(EncodedID mod 38));
    EncodedID := UInt64(EncodedID div 38);
    If (CharIdx >= Low(DecodeTable)) and (CharIdx <= High(DecodeTable)) then
      begin
        Inc(Len);
        Result[Len] := DecodeTable[CharIdx]
      end
    else raise EGeneralException.CreateFmt('Character index (%d) out of bounds.',[CharIdx],nil,'SIIBin_DecodeID');
  end;
SetLength(Result,Len);
end;

//------------------------------------------------------------------------------

procedure SIIBin_DecodeID(var ID: TSIIBin_ID);
var
  i:  Integer;
begin
try
  If not (ID.Length in [0,$FF]) then
    begin
      If Length(ID.PartsStr) <> Length(ID.Parts) then
        SetLength(ID.PartsStr,Length(ID.Parts));
      For i := Low(ID.Parts) to High(ID.Parts) do
        ID.PartsStr[i] := SIIBin_DecodeID(ID.Parts[i]);
    end;
except
  ID.Length := 0;
end;
end;

//------------------------------------------------------------------------------

Function SIIBin_IDToStr(ID: TSIIBin_ID; OldHexStyle: Boolean): AnsiString;
var
  i:    Integer;
  Temp: UInt64;
begin
case ID.Length of
  $00:  Result := StrToAnsi('null');
  $FF:  If OldHexStyle and (Int64Rec(ID.Parts[0]).Hi = 0) then
          begin
            Result := StrToAnsi('_nameless' + AnsiUpperCase(Format('.%.4x.%.4x',
              [Int64Rec(ID.Parts[0]).Words[1],Int64Rec(ID.Parts[0]).Words[0]])));
          end
        else
          begin
            If ID.Parts[0] <> 0 then
              begin
                Temp := ID.Parts[0];
                Result := '';
                while Temp <> 0 do
                  begin
                    If (Temp and not UInt64($FFFF)) <> 0 then
                      Result := StrToAnsi(AnsiLowerCase(Format('.%.4x',[UInt16(Temp)]))) + Result
                    else
                      Result := StrToAnsi(AnsiLowerCase(Format('.%x',[UInt16(Temp)]))) + Result;
                    Temp := Temp shr 16;
                  end;
                Result := AnsiString('_nameless') + Result;
              end
            else Result := AnsiString('_nameless.0');
          end;
else
  Result := ID.PartsStr[0];
  For i := Succ(Low(ID.Parts)) to High(ID.Parts) do
    Result := Result + AnsiString('.') + ID.PartsStr[i];
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
      If Ord(Str[ii]) > 127 then Exit;
    Result := False;
  end;

begin
If NonASCII then
  begin
    Temp := '';
    For i := 1 to Length(Str) do
      begin
        If (Ord(Str[i]) <= 127) and (Ord(Str[i]) >= 32) then
          Temp := Temp + Str[i]
        else
          Temp := Temp + StrToAnsi(AnsiLowerCase(Format('\x%.2x',[Ord(Str[i])])));
      end;
    Str := Temp;
  end;
end;

end.

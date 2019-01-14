{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Extended INI file

    Utility functions

  ©František Milt 2018-10-21

  Version 1.0.3

  NOTE - library needs extensive testing

  Dependencies:
    AuxTypes            - github.com/ncs-sniper/Lib.AuxTypes
    AuxClasses          - github.com/ncs-sniper/Lib.AuxClasses
    CRC32               - github.com/ncs-sniper/Lib.CRC32
    StrRect             - github.com/ncs-sniper/Lib.StrRect
    BinTextEnc          - github.com/ncs-sniper/Lib.BinTextEnc
    FloatHex            - github.com/ncs-sniper/Lib.FloatHex
    ExplicitStringLists - github.com/ncs-sniper/Lib.ExplicitStringLists
    BinaryStreaming     - github.com/ncs-sniper/Lib.BinaryStreaming
    SimpleCompress      - github.com/ncs-sniper/Lib.SimpleCompress
    MemoryBuffer        - github.com/ncs-sniper/Lib.MemoryBuffer
    ZLib                - github.com/ncs-sniper/Bnd.ZLib
    ZLibUtils           - github.com/ncs-sniper/Lib.ZLibUtils
    AES                 - github.com/ncs-sniper/Lib.AES
  * SimpleCPUID         - github.com/ncs-sniper/Lib.SimpleCPUID
    ListSorters         - github.com/ncs-sniper/Lib.ListSorters

  SimpleCPUID is required only when PurePascal symbol is not defined.

===============================================================================}
unit IniFileEx_Utils;

{$INCLUDE '.\IniFileEx_defs.inc'}

interface

uses
  AuxTypes, BinTextEnc, StrRect{has to be here for inline expansion},
  IniFileEx_Common;

{===============================================================================
    UInt64 <-> IFXString conversions
===============================================================================}
  
Function IFXUInt64ToStr(Value: UInt64): TIFXString;
Function IFXStrToUInt64(const Str: TIFXString): UInt64;
Function IFXTryStrToUInt64(const Str: TIFXString; out Value: UInt64): Boolean;

{===============================================================================
    Boolean <-> IFXString conversions
===============================================================================}

Function IFXBoolToStr(Value: Boolean; AsString: Boolean): TIFXString;
Function IFXTryStrToBool(const Str: TIFXString; out Value: Boolean): Boolean;

{===============================================================================
    Conversion of IFXString to/from other string types
===============================================================================}

Function IFXStrToStr(const IFXStr: TIFXString): String;{$IFDEF CanInline} inline;{$ENDIF}
Function StrToIFXStr(const Str: String): TIFXString;{$IFDEF CanInline} inline;{$ENDIF}

Function IFXStrToUTF8(const IFXStr: TIFXString): UTF8String;{$IFDEF CanInline} inline;{$ENDIF}
Function UTF8ToIFXStr(const Str: UTF8String): TIFXString;{$IFDEF CanInline} inline;{$ENDIF}

{===============================================================================
    IFXString comparisons
===============================================================================}

Function IFXCompareStr(const S1,S2: TIFXString): Integer;{$IFDEF CanInline} inline;{$ENDIF}
Function IFXCompareText(const S1,S2: TIFXString): Integer;{$IFDEF CanInline} inline;{$ENDIF}

{===============================================================================
    Other IFXString functions
===============================================================================}

Function IFXTrimStr(const Str: TIFXString; WhiteSpaceChar: TIFXChar): TIFXString; overload;
Function IFXTrimStr(const Str: TIFXString): TIFXString; overload;

{===============================================================================
    IFXString encoding/decoding for use in textual INI
===============================================================================}

Function IFXEncodeString(const Str: TIFXString; Settings: TIFXTextIniSettings): TIFXString;
Function IFXDecodeString(const Str: TIFXString; Settings: TIFXTextIniSettings): TIFXString;

{===============================================================================
    Hashed string function
===============================================================================}

procedure IFXHashString(var HashStr: TIFXHashedString);{$IFDEF CanInline} inline;{$ENDIF}
Function IFXHashedString(const Str: TIFXString): TIFXHashedString;{$IFDEF CanInline} inline;{$ENDIF}

Function IFXSameHashString(const S1,S2: TIFXHashedString; FullEval: Boolean = True): Boolean;{$IFDEF CanInline} inline;{$ENDIF}

{===============================================================================
    Value-bound types functions
===============================================================================}

Function IFXValueEncodingToByte(ValueEncoding: TIFXValueEncoding): Byte;
Function IFXByteToValueEncoding(ByteValue: Byte): TIFXValueEncoding;

Function IFXEncFromValueEnc(ValueEncoding: TIFXValueEncoding): TBinTextEncoding;
Function IFXValueEncFromEnc(Encoding: TBinTextEncoding): TIFXValueEncoding;

Function IFXValueTypeToByte(ValueType: TIFXValueType): Byte;
Function IFXByteToValueType(ByteValue: Byte): TIFXValueType;

{===============================================================================
    INI settings functions
===============================================================================}

procedure IFXInitSettings(var Sett: TIFXSettings);

{===============================================================================
    Other functions
===============================================================================}

Function IFXNodeIndicesValid(Indices: TIFXNodeIndices): Boolean;
Function IFXTrimUTF8(const Str: UTF8String): UTF8String;

implementation

uses
  SysUtils,
  CRC32;

{===============================================================================
    UInt64 <-> IFXString conversions
===============================================================================}

const
  IFX_UInt64BitTable: array[0..63] of TIFXString = (
    '00000000000000000001','00000000000000000002','00000000000000000004','00000000000000000008',
    '00000000000000000016','00000000000000000032','00000000000000000064','00000000000000000128',
    '00000000000000000256','00000000000000000512','00000000000000001024','00000000000000002048',
    '00000000000000004096','00000000000000008192','00000000000000016384','00000000000000032768',
    '00000000000000065536','00000000000000131072','00000000000000262144','00000000000000524288',
    '00000000000001048576','00000000000002097152','00000000000004194304','00000000000008388608',
    '00000000000016777216','00000000000033554432','00000000000067108864','00000000000134217728',
    '00000000000268435456','00000000000536870912','00000000001073741824','00000000002147483648',
    '00000000004294967296','00000000008589934592','00000000017179869184','00000000034359738368',
    '00000000068719476736','00000000137438953472','00000000274877906944','00000000549755813888',
    '00000001099511627776','00000002199023255552','00000004398046511104','00000008796093022208',
    '00000017592186044416','00000035184372088832','00000070368744177664','00000140737488355328',
    '00000281474976710656','00000562949953421312','00001125899906842624','00002251799813685248',
    '00004503599627370496','00009007199254740992','00018014398509481984','00036028797018963968',
    '00072057594037927936','00144115188075855872','00288230376151711744','00576460752303423488',
    '01152921504606846976','02305843009213693952','04611686018427387904','09223372036854775808');

//------------------------------------------------------------------------------

Function IFXUInt64ToStr(Value: UInt64): TIFXString;
var
  i,j:      Integer;
  CharOrd:  Integer;
  Carry:    Integer;
begin
Result := StrToIFXStr(StringOfChar('0',Length(IFX_UInt64BitTable[0])));
Carry := 0;
For i := 0 to 63 do
  If ((Value shr i) and 1) <> 0 then
    For j := Length(Result) downto 1 do
      begin
        CharOrd := (Ord(Result[j]) - Ord('0')) + (Ord(IFX_UInt64BitTable[i][j]) - Ord('0')) + Carry;
        Carry := CharOrd div 10;
        Result[j] := TIFXChar(Ord('0') + CharOrd mod 10);
      end;
// remove leading zeroes
i := 0;
repeat
  Inc(i);
until (Result[i] <> '0') or (i >= Length(Result));
Result := Copy(Result,i,Length(Result));
end;

//------------------------------------------------------------------------------

Function IFXStrToUInt64(const Str: TIFXString): UInt64;
var
  TempStr:  TIFXString;
  ResStr:   TIFXString;
  i:        Integer;

  Function CompareValStr(const S1,S2: TIFXString): Integer;
  var
    ii: Integer;
  begin
    Result := 0;
    For ii := 1 to Length(S1) do
      If Ord(S1[ii]) < Ord(S2[ii]) then
        begin
          Result := 1;
          Break{For ii};
        end
      else If Ord(S1[ii]) > Ord(S2[ii]) then
        begin
          Result := -1;
          Break{For ii};
        end      
  end;

  Function SubtractValStr(const S1,S2: TIFXString; out Res: TIFXString): Integer;
  var
    ii:       Integer;
    CharVal:  Integer;
  begin
    SetLength(Res,Length(S1));
    Result := 0;
    For ii := Length(S1) downto 1 do
      begin
        CharVal := Ord(S1[ii]) - Ord(S2[ii]) + Result;
        If CharVal < 0 then
          begin
            CharVal := CharVal + 10;
            Result := -1;
          end
        else Result := 0;
        Res[ii] := TIFXChar(Abs(CharVal) + Ord('0'));
      end;
    If Result < 0 then
      Res := S1;  
  end;

begin
Result := 0;
// rectify string
If Length(Str) < Length(IFX_UInt64BitTable[0]) then
  TempStr := StrToIFXStr(StringOfChar('0',Length(IFX_UInt64BitTable[0]) - Length(Str))) + Str
else If Length(Str) > Length(IFX_UInt64BitTable[0]) then
  raise EConvertError.CreateFmt('IFXStrToUInt64: "%s" is not a valid integer string.',[Str])
else
  TempStr := Str;
// check if string contains only numbers  
For i := 1 to Length(TempStr) do
  If not(Ord(TempStr[i]) in [Ord('0')..Ord('9')]) then
    raise EConvertError.CreateFmt('IFXStrToUInt64: "%s" is not a valid integer string.',[Str]);
For i := 63 downto 0 do
  If SubtractValStr(TempStr,IFX_UInt64BitTable[i],ResStr) >= 0 then
    If CompareValStr(ResStr,IFX_UInt64BitTable[i]) > 0 then
      begin
        Result := Result or (UInt64(1) shl i);
        TempStr := ResStr;
      end
    else raise EConvertError.CreateFmt('IFXStrToUInt64: "%s" is not a valid integer string.',[Str]);
end;

//------------------------------------------------------------------------------

Function IFXTryStrToUInt64(const Str: TIFXString; out Value: UInt64): Boolean;
begin
try
  Value := IFXStrToUInt64(Str);
  Result := True;
except
  Result := False;
end;
end;

{===============================================================================
    Boolean <-> IFXString conversions
===============================================================================}

Function IFXBoolToStr(Value: Boolean; AsString: Boolean): TIFXString;
begin
If AsString then
  begin
    If Value then Result := 'True'
      else Result := 'False';
  end
else
  begin
    If Value then Result := '1'
      else Result := '0';
  end;
end;

//------------------------------------------------------------------------------

Function IFXTryStrToBool(const Str: TIFXString; out Value: Boolean): Boolean;
begin
Result := True;
If IFXCompareText(Str,'true') = 0 then
  Value := True
else If IFXCompareText(Str,'false') = 0 then
  Value := False
else
  Result := False;
end;

{===============================================================================
    Conversion of IFXString to/from other string types
===============================================================================}

Function IFXStrToStr(const IFXStr: TIFXString): String;
begin
Result := UnicodeToStr(IFXStr);
end;

//------------------------------------------------------------------------------

Function StrToIFXStr(const Str: String): TIFXString;
begin
Result := StrToUnicode(Str);
end;

//------------------------------------------------------------------------------

Function IFXStrToUTF8(const IFXStr: TIFXString): UTF8String;
begin
{$IF Declared(StringToUTF8)}
Result := StringToUTF8(IFXStr);
{$ELSE}
Result := UTF8Encode(IFXStr);
{$IFEND}
end;

//------------------------------------------------------------------------------

Function UTF8ToIFXStr(const Str: UTF8String): TIFXString;
begin
{$IF Declared(UTF8ToString)}
Result := UTF8ToString(Str);
{$ELSE}
Result := UTF8Decode(Str);
{$IFEND}
end;

{===============================================================================
    IFXString comparisons
===============================================================================}

Function IFXCompareStr(const S1,S2: TIFXString): Integer;
begin
{$IFDEF Unicode}
Result := AnsiCompareStr(S1,S2);
{$ELSE}
{$IFDEF FPC}
Result := UnicodeCompareStr(S1,S2);
{$ELSE}
Result := WideCompareStr(S1,S2);
{$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function IFXCompareText(const S1,S2: TIFXString): Integer;
begin
{$IFDEF Unicode}
Result := AnsiCompareText(S1,S2);
{$ELSE}
{$IFDEF FPC}
Result := UnicodeCompareText(S1,S2);
{$ELSE}
Result := WideCompareText(S1,S2);
{$ENDIF}
{$ENDIF}
end;

{===============================================================================
    Other IFXString functions
===============================================================================}

Function IFXTrimStr(const Str: TIFXString; WhiteSpaceChar: TIFXChar): TIFXString;
var
  StartIdx,EndIdx:  TStrSize;
  i:                TStrSize;
begin
If Length(Str) > 0 then
  begin
    StartIdx := -1;
    For i := 1 to Length(Str) do
      If (Ord(Str[i]) > 32) and (Str[i] <> WhiteSpaceChar) then
        begin
          StartIdx := i;
          Break{for i};
        end;
    If StartIdx > 0 then
      begin
        EndIdx := Length(Str);
        For i := Length(Str) downto 1 do
          If (Ord(Str[i]) > 32) and (Str[i] <> WhiteSpaceChar) then
            begin
              EndIdx := i;
              Break{for i};
            end;
        Result := Copy(Str,StartIdx,EndIdx - StartIdx + 1);
      end
    else Result := '';
  end
else Result := '';
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

Function IFXTrimStr(const Str: TIFXString): TIFXString;
begin
Result := IFXTrimStr(Str,TIFXChar(0));
end;
 
{===============================================================================
    IFXString encoding/decoding for use in textual INI
===============================================================================}

Function IFXEncodeString(const Str: TIFXString; Settings: TIFXTextIniSettings): TIFXString;
var
  i:        TStrSize;
  Temp:     TStrSize;
  Quoted:   Boolean;
  StrTemp:  TIFXString;
begin
// scan string
Temp := 0; 
Quoted := Settings.ForceQuote or (Length(Str) <= 0);
For i := 1 to Length(Str) do
  case Str[i] of
    #32:        // space
      begin
        Inc(Temp);
        Quoted := True;
      end;
    #1..#6,#14..#31:
      begin     // chars replaced by \#xxxx
        Inc(Temp,6);
        Quoted := True;
      end;
    #0,#7..#13:
      begin     // replaced by \C
        Inc(Temp,2);
        Quoted := True;
     end;
  else
    If (Str[i] = Settings.EscapeChar) or (Str[i] = Settings.QuoteChar) then
      begin
        Inc(Temp,2);
        Quoted := True;
      end
    else If Str[i] = Settings.CommentChar then
      begin
        // comment char does not need to be escaped,
        // but string containing it must be quoted
        Inc(Temp);
        Quoted := True;
      end
    else Inc(Temp);
  end;
If Quoted then
  begin
    SetLength(Result,Temp + 2);
    Result[1] := Settings.QuoteChar;
    Result[Length(result)] := Settings.QuoteChar;
  end
else SetLength(Result,Temp);
// encode string
If Quoted then
  Temp := 2
else
  Temp := 1;
For i := 1 to Length(Str) do
  case Str[i] of
    #1..#6,#14..#26,#28..#31:
      begin
        Result[Temp] := Settings.EscapeChar;
        Result[Temp + 1] := Settings.NumericChar;
        StrTemp := StrToIFXStr(IntToHex(Ord(Str[i]),4));
        Result[Temp + 2] := StrTemp[1];
        Result[Temp + 3] := StrTemp[2];
        Result[Temp + 4] := StrTemp[3];
        Result[Temp + 5] := StrTemp[4];
        Inc(Temp,6);
      end;
    #0,#7..#13,#27:
      begin
        Result[Temp] := Settings.EscapeChar;
        case Str[i] of
          #0:   Result[Temp + 1] := '0';  // null
          #7:   Result[Temp + 1] := 'a';  // bell
          #8:   Result[Temp + 1] := 'b';  // backspace
          #9:   Result[Temp + 1] := 't';  // horizontal tab
          #10:  Result[Temp + 1] := 'n';  // line feed
          #11:  Result[Temp + 1] := 'v';  // vertical tab
          #12:  Result[Temp + 1] := 'f';  // form feed
          #13:  Result[Temp + 1] := 'r';  // carriage return
          #27:  Result[Temp + 1] := 'e';  // escape
        end;
        Inc(Temp,2);
      end;
  else
    If (Str[i] = Settings.EscapeChar) or (Str[i] = Settings.QuoteChar) then
      begin
        Result[Temp] := Settings.EscapeChar;
        Result[Temp + 1] := Str[i];
        Inc(Temp,2);
      end
    else
      begin
        Result[Temp] := Str[i];
        Inc(Temp);
      end;
  end;
end;
 
//------------------------------------------------------------------------------

Function IFXDecodeString(const Str: TIFXString; Settings: TIFXTextIniSettings): TIFXString;
var
  Quoted:   Boolean;
  i,ResPos: TStrSize;
  Temp:     Integer;

  procedure SetAndAdvance(NewChar: TIFXChar; SrcShift, ResShift: Integer);
  begin
    Result[ResPos] := NewChar;
    Inc(i,SrcShift);
    Inc(ResPos,resShift);
  end;

begin
If Length(Str) > 0 then
  begin
    SetLength(Result,Length(Str));
    Quoted := Str[1] = Settings.QuoteChar;
    If Quoted then i := 2
      else i := 1;
    ResPos := 1;
    while i <= Length(Str) do
      begin
        If Str[i] = Settings.EscapeChar then
          begin
            If i < Length(Str) then
              case Str[i + 1] of
                '0':  SetAndAdvance(#0,2,1);
                'a':  SetAndAdvance(#7,2,1);
                'b':  SetAndAdvance(#8,2,1);
                't':  SetAndAdvance(#9,2,1);
                'n':  SetAndAdvance(#10,2,1);
                'v':  SetAndAdvance(#11,2,1);
                'f':  SetAndAdvance(#12,2,1);
                'r':  SetAndAdvance(#13,2,1);
                'e':  SetAndAdvance(#27,2,1);
              else
                If Str[i + 1] = Settings.NumericChar then
                  begin
                    If (i + 4) < Length(Str) then
                      begin
                        If TryStrToInt(IFXStrToStr('$' + Copy(Str,i + 2,4)),Temp) then
                          SetAndAdvance(TIFXChar(Temp),6,1)
                        else
                          Break{while...};
                      end
                    else Break{while...};
                  end
                else If (Str[i + 1] = Settings.EscapeChar) or (Str[i + 1] = Settings.QuoteChar) then
                  SetAndAdvance(Str[i + 1],2,1)
                else
                  Break{while...};
              end
            else Break{while...};
          end
        else If Str[i] = Settings.QuoteChar then
          begin
            If Quoted then
              Break{while...};
            SetAndAdvance(Str[i],1,1);
          end
        else SetAndAdvance(Str[i],1,1);
      end;
    SetLength(Result,ResPos - 1);
  end
else Result := '';
end;

{===============================================================================
    Hashed string function
===============================================================================}

procedure IFXHashString(var HashStr: TIFXHashedString);
begin
{$IFDEF Unicode}
HashStr.Hash := WideStringCRC32(AnsiLowerCase(HashStr.Str));
{$ELSE}
{$IFDEF FPC}
HashStr.Hash := WideStringCRC32(UnicodeLowerCase(HashStr.Str));
{$ELSE}
HashStr.Hash := WideStringCRC32(WideLowerCase(HashStr.Str));
{$ENDIF}
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function IFXHashedString(const Str: TIFXString): TIFXHashedString;
begin
Result.Str := Str;
IFXHashString(Result);
end;

//------------------------------------------------------------------------------


Function IFXSameHashString(const S1, S2: TIFXHashedString; FullEval: Boolean = True): Boolean;
begin
Result := SameCRC32(S1.Hash,S2.Hash) and (not FullEval or (IFXCompareText(S1.Str,S2.Str) = 0));
end;

{===============================================================================
    Value-bound types functions
===============================================================================}

Function IFXValueEncodingToByte(ValueEncoding: TIFXValueEncoding): Byte;
begin
case ValueEncoding of
  iveBase2:       Result := IFX_VALENC_BASE2;
  iveBase64:      Result := IFX_VALENC_BASE64;
  iveBase85:      Result := IFX_VALENC_BASE85;
  iveHexadecimal: Result := IFX_VALENC_HEXADEC;
  iveNumber:      Result := IFX_VALENC_NUMBER;
  iveDefault:     Result := IFX_VALENC_DEFAULT;
else
  raise Exception.CreateFmt('ValueEncodingToByte: Unknown value encoding (%d).',[Ord(ValueEncoding)]);
end;
end;

//------------------------------------------------------------------------------

Function IFXByteToValueEncoding(ByteValue: Byte): TIFXValueEncoding;
begin
case ByteValue of
  IFX_VALENC_BASE2:   Result := iveBase2;
  IFX_VALENC_BASE64:  Result := iveBase64;
  IFX_VALENC_BASE85:  Result := iveBase85;
  IFX_VALENC_HEXADEC: Result := iveHexadecimal;
  IFX_VALENC_NUMBER:  Result := iveNumber;
  IFX_VALENC_DEFAULT: Result := iveDefault;
else
  raise Exception.CreateFmt('ByteToValueEncoding: Unknown value encoding (%d).',[ByteValue]);
end;
end;

//------------------------------------------------------------------------------

Function IFXEncFromValueEnc(ValueEncoding: TIFXValueEncoding): TBinTextEncoding;
begin
case ValueEncoding of
  iveBase2:       Result := bteBase2;
  iveBase64:      Result := bteBase64;
  iveBase85:      Result := bteBase85;
  iveHexadecimal: Result := bteHexadecimal;
else
  raise Exception.CreateFmt('EncFromValueEnc: Unsupported value encoding (%d).',[Ord(ValueEncoding)]);
end;
end;

//------------------------------------------------------------------------------

Function IFXValueEncFromEnc(Encoding: TBinTextEncoding): TIFXValueEncoding;
begin
case Encoding of
  bteBase2:       Result := iveBase2;
  bteBase64:      Result := iveBase64;
  bteBase85:      Result := iveBase85;
  bteHexadecimal: Result := iveHexadecimal;
else
  raise Exception.CreateFmt('ValueEncFromEnc: Unsupported encoding (%d).',[Ord(Encoding)]);
end;
end;

//------------------------------------------------------------------------------

Function IFXValueTypeToByte(ValueType: TIFXValueType): Byte;
begin
case ValueType of
  ivtUndecided: REsult := IFX_VALTYPE_UNDECIDED;
  ivtBool:      Result := IFX_VALTYPE_BOOL;
  ivtInt8:      Result := IFX_VALTYPE_INT8;
  ivtUInt8:     Result := IFX_VALTYPE_UINT8;
  ivtInt16:     Result := IFX_VALTYPE_INT16;
  ivtUInt16:    Result := IFX_VALTYPE_UINT16;
  ivtInt32:     Result := IFX_VALTYPE_INT32;
  ivtUInt32:    Result := IFX_VALTYPE_UINT32;
  ivtInt64:     Result := IFX_VALTYPE_INT64;
  ivtUInt64:    Result := IFX_VALTYPE_UINT64;
  ivtFloat32:   Result := IFX_VALTYPE_FLOAT32;
  ivtFloat64:   Result := IFX_VALTYPE_FLOAT64;
  ivtDate:      Result := IFX_VALTYPE_DATE;
  ivtTime:      Result := IFX_VALTYPE_TIME;
  ivtDateTime:  Result := IFX_VALTYPE_DATETIME;
  ivtString:    Result := IFX_VALTYPE_STRING;
  ivtBinary:    Result := IFX_VALTYPE_BINARY;
else
  raise Exception.CreateFmt('ValueTypeToByte: Unknown value type (%d).',[Ord(ValueType)]);
end;
end;

//------------------------------------------------------------------------------

Function IFXByteToValueType(ByteValue: Byte): TIFXValueType;
begin
case ByteValue of
  IFX_VALTYPE_UNDECIDED:  Result := ivtUndecided;
  IFX_VALTYPE_BOOL:       Result := ivtBool;
  IFX_VALTYPE_INT8:       Result := ivtInt8;
  IFX_VALTYPE_UINT8:      Result := ivtUInt8;
  IFX_VALTYPE_INT16:      Result := ivtInt16;
  IFX_VALTYPE_UINT16:     Result := ivtUInt16;
  IFX_VALTYPE_INT32:      Result := ivtInt32;
  IFX_VALTYPE_UINT32:     Result := ivtUInt32;
  IFX_VALTYPE_INT64:      Result := ivtInt32;
  IFX_VALTYPE_UINT64:     Result := ivtUInt32;
  IFX_VALTYPE_FLOAT32:    Result := ivtFloat32;
  IFX_VALTYPE_FLOAT64:    Result := ivtFloat64;
  IFX_VALTYPE_DATE:       Result := ivtDate;
  IFX_VALTYPE_TIME:       Result := ivtTime;
  IFX_VALTYPE_DATETIME:   Result := ivtDateTime;
  IFX_VALTYPE_STRING:     Result := ivtString;
  IFX_VALTYPE_BINARY:     Result := ivtBinary;
else
  raise Exception.CreateFmt('ByteToValueType: Unknown value type (%d).',[ByteValue]);
end;
end;

{===============================================================================
    INI settings functions
===============================================================================}

procedure IFXInitSettings(var Sett: TIFXSettings);
const
  def_ShortMonthNames: array[1..12] of String =
    ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
  def_LongMonthNames: array[1..12] of String =
    ('January','February','March','April','May','June','July','August','September','October','November','December');
  def_ShortDayNames: array[1..7] of String =
    ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
  def_LongDayNames: array[1..7] of String =
    ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
var
  i:  Integer;
begin
{
  Delphi changed order of fields in TFormatSettings somewhere along the line,
  so I cannot use constant and assign everything in one step, yay!
}
Sett.FormatSettings.ThousandSeparator := #0;
Sett.FormatSettings.DecimalSeparator  := '.';
Sett.FormatSettings.DateSeparator     := '-';
Sett.FormatSettings.TimeSeparator     := ':';
Sett.FormatSettings.ShortDateFormat   := 'yyyy"-"mm"-"dd';
Sett.FormatSettings.LongDateFormat    := 'yyyy"-"mm"-"dd';
Sett.FormatSettings.ShortTimeFormat   := 'hh":"nn":"ss';
Sett.FormatSettings.LongTimeFormat    := 'hh":"nn":"ss';
Sett.FormatSettings.TwoDigitYearCenturyWindow := 50;
For i := Low(def_ShortMonthNames) to High(def_ShortMonthNames) do
  Sett.FormatSettings.ShortMonthNames[i] := def_ShortMonthNames[i];
For i := Low(def_LongMonthNames) to High(def_LongMonthNames) do
  Sett.FormatSettings.LongMonthNames[i] := def_LongMonthNames[i];
For i := Low(def_ShortDayNames) to High(def_ShortDayNames) do
  Sett.FormatSettings.ShortDayNames[i] := def_ShortDayNames[i];
For i := Low(def_LongDayNames) to High(def_LongDayNames) do
  Sett.FormatSettings.LongDayNames[i] := def_LongDayNames[i];
// textual ini file options
with Sett.TextIniSettings do
  begin
    EscapeChar         := TIFXChar('\');
    QuoteChar          := TIFXChar('"');
    NumericChar        := TIFXChar('#');
    ForceQuote         := False;
    CommentChar        := TIFXChar(';');
    SectionStartChar   := TIFXChar('[');
    SectionEndChar     := TIFXChar(']');
    ValueDelimChar     := TIFXChar('=');
    WhiteSpaceChar     := TIFXChar(' ');
    KeyWhiteSpace      := True;
    ValueWhiteSpace    := True;
    ValueWrapLength    := 0;   // < min line length = unlimited
    LineBreak          := StrToIFXStr(sLineBreak);
    WriteByteOrderMask := False;
  end;
// binary ini file settings
with Sett.BinaryIniSettings do
  begin
    CompressData   := True;
    DataEncryption := ideNone;
    FillChar(AESEncryptionKey,SizeOf(TIFXAESEncVector),0);
    FillChar(AESEncryptionVector,SizeOf(TIFXAESEncVector),0);
  end;
// other fields
Sett.FullNameEval          := True;
Sett.ReadOnly              := False;
Sett.DuplicityBehavior     := idbDrop;
Sett.DuplicityRenameOldStr := TIFXString('_old');
Sett.DuplicityRenameNewStr := TIFXString('_new');
Sett.WorkingStyle          := iwsStandalone;
Sett.WorkingStream         := nil;
Sett.WorkingFile           := '';
end;

{===============================================================================
    Other functions
===============================================================================}

Function IFXNodeIndicesValid(Indices: TIFXNodeIndices): Boolean;
begin
Result := (Indices.SectionIndex >= 0) and (Indices.KeyIndex >= 0);
end;

//------------------------------------------------------------------------------

Function IFXTrimUTF8(const Str: UTF8String): UTF8String;
var
  StartIdx,EndIdx:  TStrSize;
  i:                TStrSize;
begin
If Length(Str) > 0 then
  begin
    StartIdx := -1;
    For i := 1 to Length(Str) do
      If Ord(Str[i]) > 32 then
        begin
          StartIdx := i;
          Break{for i};
        end;
    If StartIdx > 0 then
      begin
        EndIdx := Length(Str);
        For i := Length(Str) downto 1 do
          If Ord(Str[i]) > 32 then
            begin
              EndIdx := i;
              Break{for i};
            end;
        Result := Copy(Str,StartIdx,EndIdx - StartIdx + 1);
      end
    else Result := '';
  end
else Result := '';
end;
 
end.

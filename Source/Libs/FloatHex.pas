{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Floating point numbers <-> HexString conversion routines

  ©František Milt 2017-06-09

  Version 1.5.3

  Dependencies:
    AuxTypes - github.com/ncs-sniper/Lib.AuxTypes

===============================================================================}
unit FloatHex;

{$IF defined(CPUX86_64) or defined(CPUX64)}
  {$DEFINE x64}
{$ELSEIF defined(CPU386)}
  {$DEFINE x86}
{$ELSE}
  {$DEFINE PurePascal}
{$IFEND}

{$IFDEF FPC}
  {$MODE ObjFPC}{$H+}
  {$IFNDEF PurePascal}
    {$ASMMODE Intel}
  {$ENDIF}
{$ENDIF}

{$IFDEF ENDIAN_BIG}
  {$MESSAGE FATAL 'Big-endian system not supported'}
{$ENDIF}

interface

uses
  AuxTypes;

Function HalfToHex(Value: Half): String;
Function HexToHalf(HexString: String): Half;
Function TryHexToHalf(const HexString: String; out Value: Half): Boolean;
Function HexToHalfDef(const HexString: String; const DefaultValue: Half): Half;

//------------------------------------------------------------------------------

Function SingleToHex(Value: Single): String;
Function HexToSingle(HexString: String): Single;
Function TryHexToSingle(const HexString: String; out Value: Single): Boolean;
Function HexToSingleDef(const HexString: String; const DefaultValue: Single): Single;

//------------------------------------------------------------------------------

Function DoubleToHex(Value: Double): String;
Function HexToDouble(HexString: String): Double;
Function TryHexToDouble(const HexString: String; out Value: Double): Boolean;
Function HexToDoubleDef(const HexString: String; const DefaultValue: Double): Double;

//------------------------------------------------------------------------------

Function ExtendedToHex(Value: Extended): String;
Function HexToExtended(HexString: String): Extended;
Function TryHexToExtended(const HexString: String; out Value: Extended): Boolean;
Function HexToExtendedDef(const HexString: String; const DefaultValue: Extended): Extended;

//------------------------------------------------------------------------------

Function FloatToHex(Value: Double): String;
Function HexToFloat(const HexString: String): Double;
Function TryHexToFloat(const HexString: String; out Value: Double): Boolean;
Function HexToFloatDef(const HexString: String; const DefaultValue: Double): Double; 

implementation

{$IF SizeOf(Extended) = 8}
  {$DEFINE Extended64}
{$ELSEIF SizeOf(Extended) = 10}
  {$UNDEF Extended64}
{$ELSE}
  {$MESSAGE FATAL 'Unsupported platform, type extended must be 8 or 10 bytes.'}
{$IFEND}

uses
  SysUtils;

{$IFDEF PurePascal}
const
  CW_EInvalidOP = UInt16($0001);  // invalid operation exception mask
  CW_EOverflow  = UInt16($0008);  // overflow exception mask
  CW_EUnderflow = UInt16($0010);  // underflow exception mask
{$IF not Declared(Get8087CW)}
  CW_Default    = UInt16($1372);  // default FPU control word
{$IFEND}
{$ENDIF}

type
  // overlay used when working with 10-byte extended precision float
  TExtendedOverlay = packed record
    Part_64:  UInt64;
    Part_16:  UInt16;
  end;

//= Auxiliary functions ========================================================

procedure RectifyHexString(var Str: String; RequiredLength: Integer);

  Function StartsWithHexMark(const Str: String): Boolean;
  begin
  If Length(Str) > 0 then
    Result := Str[1] = '$'
  else
    Result := False;
  end;

begin
If Length(Str) <> RequiredLength then
  begin
    If Length(Str) < RequiredLength then
      Str := Str + StringOfChar('0',RequiredLength - Length(Str))
    else
      Str := Copy(Str,1,RequiredLength);
  end;
If not StartsWithHexMark(Str) then Str := '$' + Str;
end;

//------------------------------------------------------------------------------

procedure ConvertFloat64ToFloat80(DoublePtr, ExtendedPtr: Pointer); register; {$IFNDEF PurePascal}assembler;
asm
  FLD   qword ptr [DoublePtr]
  FSTP  tbyte ptr [ExtendedPtr]
  FWAIT
end;
{$ELSE PurePascal}
var
  ControlWord:  UInt16;
  Sign:         UInt64;
  Exponent:     Int32;
  Mantissa:     UInt64;
  MantissaTZC:  Integer;

  procedure BuildExtendedResult(Upper: UInt16; Lower: UInt64);
  begin
    {%H-}PUInt16({%H-}PtrUInt(ExtendedPtr) + 8)^ := Upper;
    UInt64(ExtendedPtr^) := Lower;
  end;

  Function HighZeroCount(Value: UInt64): Integer;
  begin
    If Value <> 0 then
      begin
        Result := 0;
        while (Value and UInt64($8000000000000000)) = 0  do
          begin
            Value := UInt64(Value shl 1);
            Inc(Result);
          end;
      end
    else Result := 64;
  end;

begin
{$IF Declared(Get8087CW)}
ControlWord := Get8087CW;
{$ELSE}
ControlWord := CW_Default;
{$IFEND}
Sign := UInt64(DoublePtr^) and UInt64($8000000000000000);
Exponent := Int32(UInt64(DoublePtr^) shr 52) and $7FF;
Mantissa := UInt64(DoublePtr^) and UInt64($000FFFFFFFFFFFFF);
case Exponent of
        // zero or subnormal
  0:    If Mantissa <> 0 then
          begin
            // subnormals, normalizing
            MantissaTZC := HighZeroCount(Mantissa);
            BuildExtendedResult(UInt16(Sign shr 48) or UInt16(Exponent - MantissaTZC + 15372),
                                UInt64(Mantissa shl MantissaTZC));
          end
        // return signed zero
        else BuildExtendedResult(UInt16(Sign shr 48),0);

        // infinity or NaN
  $7FF: If Mantissa <> 0 then
          begin
            If (Mantissa and UInt64($0008000000000000)) = 0 then
              begin
                // signaled NaN
                If (ControlWord and CW_EInvalidOP) <> 0 then
                  // quiet signed NaN with mantissa
                  BuildExtendedResult(UInt16(Sign shr 48) or $7FFF,
                    UInt64(Mantissa shl 11) or UInt64($C000000000000000))
                else
                  // signaling NaN
                  raise EInvalidOp.Create('Invalid floating point operation')
              end
            // quiet signed NaN with mantissa
            else BuildExtendedResult(UInt16(Sign shr 48) or $7FFF,
                   UInt64(Mantissa shl 11) or UInt64($8000000000000000));
          end  
        // signed infinity
        else BuildExtendedResult(UInt16(Sign shr 48) or $7FFF,UInt64($8000000000000000));

else
  // normal number
  BuildExtendedResult(UInt16(Sign shr 48) or UInt16(Exponent + 15360),
    UInt64(Mantissa shl 11) or UInt64($8000000000000000));
end;
end;
{$ENDIF PurePascal}

//------------------------------------------------------------------------------

procedure ConvertFloat80ToFloat64(ExtendedPtr, DoublePtr: Pointer); register; {$IFNDEF PurePascal}assembler;
asm
  FLD   tbyte ptr [ExtendedPtr]
  FSTP  qword ptr [DoublePtr]
  FWAIT
end;
{$ELSE PurePascal}
const
  Infinity = UInt64($7FF0000000000000);
  NaN      = UInt64($7FF8000000000000);
var
  ControlWord:  UInt16;
  RoundMode:    Integer;
  Sign:         UInt64;
  Exponent:     Int32;
  Mantissa:     UInt64;

  Function ShiftMantissa(Value: UInt64; Shift: Byte): UInt64;
  var
    ShiftedOut: UInt64;
    Distance:   UInt64;

    Function FirstIsSmaller(A,B: UInt64): Boolean;
    begin
      If Int64Rec(A).Hi = Int64Rec(B).Hi then
        Result := Int64Rec(A).Lo < Int64Rec(B).Lo
      else
        Result := Int64Rec(A).Hi < Int64Rec(B).Hi;
    end;

  begin
    If (Shift > 0) and (Shift <= 64) then
      begin
        If Shift = 64 then Result := 0
          else Result := Value shr Shift;
        ShiftedOut := Value and (UInt64($FFFFFFFFFFFFFFFF) shr (64 - Shift));
        case RoundMode of
              // nearest
          0:  If ShiftedOut <> 0 then
                begin
                  If Shift >= 64 then Distance := UInt64(-Int64(ShiftedOut))
                    else Distance := UInt64((UInt64(1) shl Shift) - ShiftedOut);
                  If FirstIsSmaller(Distance,ShiftedOut) or
                     ((Distance = ShiftedOut) and ((Result and 1) <> 0)) then
                    Inc(Result);
                end;
              // down
          1:  If (Sign <> 0) and (ShiftedOut <> 0) then
                Inc(Result);
              // up
          2:  If (Sign = 0) and (ShiftedOut <> 0) then
                Inc(Result);
        else
          {truncate}  // nothing to do
        end;
      end
    else Result := Value;
  end;

begin
{$IF Declared(Get8087CW)}
ControlWord := Get8087CW;
{$ELSE}
ControlWord := CW_Default;
{$IFEND}
RoundMode := (ControlWord shr 10) and 3;
Sign := UInt64({%H-}PUInt8({%H-}PtrUInt(ExtendedPtr) + 9)^ and $80) shl 56;
Exponent := Int32({%H-}PUInt16({%H-}PtrUInt(ExtendedPtr) + 8)^) and $7FFF;
Mantissa := (UInt64(ExtendedPtr^) and UInt64($7FFFFFFFFFFFFFFF));
If ((UInt64(ExtendedPtr^) and UInt64($8000000000000000)) = 0) and ((Exponent > 0) and (Exponent < $7FFF)) then
  begin
    // unnormal number
    If (ControlWord and CW_EInvalidOP) <> 0 then
      // return negative SNaN (don't ask me, ask Intel)
      UInt64(DoublePtr^) := UInt64(NaN or UInt64($8000000000000000))
    else
      // invalid operand
      raise EInvalidOp.Create('Invalid floating point operation');
  end
else
  case Exponent of
            // zero or denormal (denormal cannot be represented as double)
    0:      If Mantissa <> 0 then
              begin
                // denormal
                If (ControlWord and CW_EUnderflow) <> 0 then
                  begin
                    If ((RoundMode = 1{down}) and (Sign <> 0)) or
                       ((RoundMode = 2{up}) and (Sign = 0)) then
                      // convert to smallest representable number
                      UInt64(DoublePtr^) := Sign or 1
                    else
                      // convert to signed zero
                      UInt64(DoublePtr^) := Sign;
                  end
                // signal underflow
                else raise EUnderflow.Create('Floating point underflow');
              end
            // return signed zero
            else UInt64(DoublePtr^) := Sign;

            // exponent is too small to be represented in double even as subnormal
    1..
    $3BCB:  If (ControlWord and CW_EUnderflow) <> 0 then
              begin
                If ((RoundMode = 1{down}) and (Sign <> 0)) or
                   ((RoundMode = 2{up}) and (Sign = 0)) then
                  // convert to smallest representable number
                  UInt64(DoublePtr^) := Sign or 1
                else
                  // convert to signed zero
                  UInt64(DoublePtr^) := Sign;
              end
            // signal underflow
            else raise EUnderflow.Create('Floating point underflow');

            // subnormal values (resulting exponent in double is 0)
    $3BCC..
    $3C00:  If (ControlWord and CW_EUnderflow) <> 0 then
              UInt64(DoublePtr^) := Sign or ShiftMantissa((Mantissa or
                UInt64($8000000000000000)),$3C0C - Exponent)
            else
              // signal underflow
              raise EUnderflow.Create('Floating point underflow');

            // exponent is too large to be represented in double (resulting
            // exponent would be larger than $7FE)
    $43FF..
    $7FFE:  If (ControlWord and CW_EOverflow) <> 0 then
              begin
                If (RoundMode = 3{trunc}) or
                   ((RoundMode = 1{down}) and (Sign = 0)) or
                   ((RoundMode = 2{up}) and (Sign <> 0)) then
                  // convert to largest representable number
                  UInt64(DoublePtr^) := Sign or UInt64($7FEFFFFFFFFFFFFF)
                else
                  // convert to signed infinity
                  UInt64(DoublePtr^) := Sign or Infinity
              end
            // signal overflow
            else raise EOverflow.Create('Floating point overflow');

            // special cases (INF, NaN, ...)
    $7FFF:  case UInt64(ExtendedPtr^) shr 62 of
                  // pseudo INF, pseudo NaN (treated as invalid operand)
              0,
              1:  If (ControlWord and CW_EInvalidOP) <> 0 then
                    // return negative SNaN
                    UInt64(DoublePtr^) := UInt64(NaN or UInt64($8000000000000000))
                  else
                     // invalid operand
                    raise EInvalidOp.Create('Invalid floating point operation');

                  // infinity or SNaN
              2:  If (UInt64(ExtendedPtr^) and UInt64($3FFFFFFFFFFFFFFF)) <> 0 then
                      begin
                        // signaled NaN
                        If (ControlWord and CW_EInvalidOP) <> 0 then
                          // return quiet signed NaN with truncated mantissa
                          UInt64(DoublePtr^) := Sign or NaN or (Mantissa shr 11)
                        else
                          // signaling NaN
                          raise EInvalidOp.Create('Invalid floating point operation');
                      end
                  // signed infinity
                  else UInt64(DoublePtr^) := Sign or Infinity;

                  // quiet signed NaN with truncated mantissa
              3:  UInt64(DoublePtr^) := Sign or NaN or (Mantissa shr 11);
            else
              // unknown case, return positive NaN
              UInt64(DoublePtr^) := NaN;
            end;
  else
    // representable numbers, normalized value
    Exponent := Exponent - 15360; // 15360 = $3FFF - $3FF
    // mantissa shift correction
    Mantissa := ShiftMantissa(Mantissa,11);
    If (Mantissa and UInt64($0010000000000000)) <> 0 then
      Inc(Exponent);
    UInt64(DoublePtr^) := Sign or (UInt64(Exponent and $7FF) shl 52) or
                          (Mantissa and UInt64($000FFFFFFFFFFFFF));
  end;
end;
{$ENDIF PurePascal}

//==============================================================================

Function HalfToHex(Value: Half): String;
var
  Overlay:  UInt16 absolute Value;
begin
Result := IntToHex(Overlay,4);
end;

//------------------------------------------------------------------------------

Function HexToHalf(HexString: String): Half;
var
  Overlay:  UInt16 absolute Result;
begin
RectifyHexString(HexString,4);
Overlay := UInt16(StrToInt(HexString));
end;

//------------------------------------------------------------------------------

Function TryHexToHalf(const HexString: String; out Value: Half): Boolean;
begin
try
  Value := HexToHalf(HexString);
  Result := True;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function HexToHalfDef(const HexString: String; const DefaultValue: Half): Half;
begin
If not TryHexToHalf(HexString,Result) then
  Result := DefaultValue;
end;

//==============================================================================

Function SingleToHex(Value: Single): String;
var
  Overlay:  UInt32 absolute Value;
begin
Result := IntToHex(Overlay,8);
end;

//------------------------------------------------------------------------------

Function HexToSingle(HexString: String): Single;
var
  Overlay:  UInt32 absolute Result;
begin
RectifyHexString(HexString,8);
Overlay := UInt32(StrToInt(HexString));
end;

//------------------------------------------------------------------------------

Function TryHexToSingle(const HexString: String; out Value: Single): Boolean;
begin
try
  Value := HexToSingle(HexString);
  Result := True;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function HexToSingleDef(const HexString: String; const DefaultValue: Single): Single;
begin
If not TryHexToSingle(HexString,Result) then
  Result := DefaultValue;
end;

//==============================================================================

Function DoubleToHex(Value: Double): String;
var
  Overlay:  UInt64 absolute Value;
begin
Result := IntToHex(Overlay,16);
end;

//------------------------------------------------------------------------------

Function HexToDouble(HexString: String): Double;
var
  Overlay:  UInt64 absolute Result;
begin
RectifyHexString(HexString,16);
Overlay := UInt64(StrToInt64(HexString));
end;

//------------------------------------------------------------------------------

Function TryHexToDouble(const HexString: String; out Value: Double): Boolean;
begin
try
  Value := HexToDouble(HexString);
  Result := True;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function HexToDoubleDef(const HexString: String; const DefaultValue: Double): Double;
begin
If not TryHexToDouble(HexString,Result) then
  Result := DefaultValue;
end;

//==============================================================================

Function ExtendedToHex(Value: Extended): String;
var
  Overlay:  TExtendedOverlay {$IFNDEF Extended64}absolute Value{$ENDIF};
begin
{$IFDEF Extended64}
ConvertFloat64ToFloat80(@Value,@Overlay);
{$ENDIF}
Result := IntToHex(Overlay.Part_16,4) + IntToHex(Overlay.Part_64,16);
end;

//------------------------------------------------------------------------------

Function HexToExtended(HexString: String): Extended;
var
  Overlay:  TExtendedOverlay {$IFNDEF Extended64}absolute Result{$ENDIF};
begin
RectifyHexString(HexString,20);
Overlay.Part_16 := UInt16(StrToInt(Copy(HexString,1,5)));
Overlay.Part_64 := UInt64(StrToInt64('$' + Copy(HexString,6,16)));
{$IFDEF Extended64}
ConvertFloat80ToFloat64(@Overlay,@Result);
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function TryHexToExtended(const HexString: String; out Value: Extended): Boolean;
begin
try
  Value := HexToExtended(HexString);
  Result := True;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function HexToExtendedDef(const HexString: String; const DefaultValue: Extended): Extended;
begin
If not TryHexToExtended(HexString,Result) then
  Result := DefaultValue;
end;

//==============================================================================

Function FloatToHex(Value: Double): String;
begin
Result := DoubleToHex(Value);
end;

//------------------------------------------------------------------------------

Function HexToFloat(const HexString: String): Double;
begin
Result := HexToDouble(HexString);
end;

//------------------------------------------------------------------------------

Function TryHexToFloat(const HexString: String; out Value: Double): Boolean;
begin
Result := TryHexToDouble(HexString,Value);
end;

//------------------------------------------------------------------------------

Function HexToFloatDef(const HexString: String; const DefaultValue: Double): Double;
begin
Result := HexToDoubleDef(HexString,DefaultValue);
end;

end.

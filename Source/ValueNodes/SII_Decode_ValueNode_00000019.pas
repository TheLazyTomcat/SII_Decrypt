{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000019;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000019
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000019 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000019 = class(TSIIBin_ValueNode)
  private
    fValue: TSIIBin_Vec8s;
  protected
    procedure Initialize; override;
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: AnsiString; override;
  end;

implementation

uses
  SysUtils,
  BinaryStreaming, StrRect,
  SII_Decode_Utils;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000019
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000019 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000019 - protected methods
-------------------------------------------------------------------------------}

procedure TSIIBin_ValueNode_00000019.Initialize;
var
  Coef: Integer;
begin
If FormatVersion = 2 then
  begin
    Coef := Trunc(fValue[3]);
    fValue[0] := fValue[0] + Integer(((Coef and $FFF) - 2048) shl 9);
    fValue[2] := fValue[2] + Integer((((Coef shr 12) and $FFF) - 2048) shl 9);
  end;
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode_00000019.GetValueType: TSIIBin_ValueType;
begin
Result := $00000019;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000019.Load(Stream: TStream);
begin
case FormatVersion of
  1:  begin
        Stream_ReadFloat32(Stream,fValue[0]);
        Stream_ReadFloat32(Stream,fValue[1]);
        Stream_ReadFloat32(Stream,fValue[2]);
        fValue[3] := 0.0;
        Stream_ReadFloat32(Stream,fValue[4]);
        Stream_ReadFloat32(Stream,fValue[5]);
        Stream_ReadFloat32(Stream,fValue[6]);
        Stream_ReadFloat32(Stream,fValue[7]);
      end;
  2:  Stream_ReadBuffer(Stream,fValue,SizeOf(TSIIBin_Vec8s));
end;
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000019 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000019.AsString: AnsiString;
begin
Result := StrToAnsi(Format('(%s, %s, %s) (%s; %s, %s, %s)',
                    [SIIBin_SingleToStr(fValue[0]),SIIBin_SingleToStr(fValue[1]),
                     SIIBin_SingleToStr(fValue[2]),SIIBin_SingleToStr(fValue[4]),
                     SIIBin_SingleToStr(fValue[5]),SIIBin_SingleToStr(fValue[6]),
                     SIIBin_SingleToStr(fValue[7])]));
end;

end.

{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_0000001A;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_0000001A
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_0000001A - declaration
===============================================================================}
type
  TSIIBin_ValueNode_0000001A = class(TSIIBin_ValueNode)
  private
    fValue: array of TSIIBin_Vec8s;
  protected
    procedure Initialize; override;
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: AnsiString; override;
    Function AsLine(IndentCount: Integer = 0): AnsiString; override;
  end;

implementation

uses
  SysUtils,
  BinaryStreaming, StrRect, ExplicitStringLists,
  SII_Decode_Utils;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_0000001A
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_0000001A - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_0000001A - protected methods
-------------------------------------------------------------------------------}

procedure TSIIBin_ValueNode_0000001A.Initialize;
var
  i:    Integer;
  Coef: Int64;
begin
If FormatVersion in [2,3] then
  For i := Low(fValue) to High(fValue) do
    begin
      Coef := Trunc(fValue[i][3]);
      fValue[i][0] := fValue[i][0] + Integer(((Coef and $FFF) - 2048) shl 9);
      fValue[i][2] := fValue[i][2] + Integer((((Coef shr 12) and $FFF) - 2048) shl 9);
    end;
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode_0000001A.GetValueType: TSIIBin_ValueType;
begin
Result := $0000001A;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_0000001A.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  case FormatVersion of
    1:    begin
            Stream_ReadFloat32(Stream,fValue[i][0]);
            Stream_ReadFloat32(Stream,fValue[i][1]);
            Stream_ReadFloat32(Stream,fValue[i][2]);
            fValue[i][3] := 0.0;
            Stream_ReadFloat32(Stream,fValue[i][4]);
            Stream_ReadFloat32(Stream,fValue[i][5]);
            Stream_ReadFloat32(Stream,fValue[i][6]);
            Stream_ReadFloat32(Stream,fValue[i][7]);
          end;
    2,3:  Stream_ReadBuffer(Stream,fValue[i],SizeOf(TSIIBin_Vec8s));
  end;
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_0000001A - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_0000001A.AsString: AnsiString;
begin
Result := StrToAnsi(Format('%d',[Length(fValue)]));
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode_0000001A.AsLine(IndentCount: Integer = 0): AnsiString;
var
  i:  Integer;
begin
If Length(fValue) >= SIIBIN_LARGE_ARRAY_THRESHOLD then
  begin
    with TAnsiStringList.Create do
    try
      TrailingLineBreak := False;
      AddDef(StringOfChar(' ',IndentCount) + Format('%s: %d',[Name,Length(fValue)]));
      For i := Low(fValue) to High(fValue) do
        AddDef(StringOfChar(' ',IndentCount) + Format('%s[%d]: (%s, %s, %s) (%s; %s, %s, %s)',
                  [Name,i,SIIBin_SingleToStr(fValue[i][0]),SIIBin_SingleToStr(fValue[i][1]),SIIBin_SingleToStr(fValue[i][2]),
                   SIIBin_SingleToStr(fValue[i][4]),SIIBin_SingleToStr(fValue[i][5]),
                   SIIBin_SingleToStr(fValue[i][6]),SIIBin_SingleToStr(fValue[i][7])]));
      Result := Text;
    finally
      Free;
    end;
  end
else
  begin
    Result := StrToAnsi(StringOfChar(' ',IndentCount) + Format('%s: %d',[Name,Length(fValue)]));
    For i := Low(fValue) to High(fValue) do
      Result := Result + StrToAnsi(sLineBreak + StringOfChar(' ',IndentCount) + Format('%s[%d]: (%s, %s, %s) (%s; %s, %s, %s)',
                  [Name,i,SIIBin_SingleToStr(fValue[i][0]),SIIBin_SingleToStr(fValue[i][1]),SIIBin_SingleToStr(fValue[i][2]),
                   SIIBin_SingleToStr(fValue[i][4]),SIIBin_SingleToStr(fValue[i][5]),
                   SIIBin_SingleToStr(fValue[i][6]),SIIBin_SingleToStr(fValue[i][7])]));
  end;
end;

end.

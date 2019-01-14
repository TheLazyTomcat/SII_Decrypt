{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_0000000A;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_0000000A
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_0000000A - declaration
===============================================================================}
type
  TSIIBin_ValueNode_0000000A = class(TSIIBin_ValueNode)
  private
    fValue: array of TSIIBin_Vec3s;
  protected
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
                           TSIIBin_ValueNode_0000000A
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_0000000A - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_0000000A - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_0000000A.GetValueType: TSIIBin_ValueType;
begin
Result := $0000000A;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_0000000A.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  Stream_ReadBuffer(Stream,fValue[i],SizeOf(TSIIBin_Vec3s));
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_0000000A - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_0000000A.AsString: AnsiString;
begin
Result := StrToAnsi(Format('%d',[Length(fValue)]));
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode_0000000A.AsLine(IndentCount: Integer = 0): AnsiString;
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
        AddDef(StringOfChar(' ',IndentCount) + Format('%s[%d]: %s',[Name,i,
          Format('(%s, %s, %s)',[SIIBin_SingleToStr(fValue[i][0]),
                                 SIIBin_SingleToStr(fValue[i][1]),
                                 SIIBin_SingleToStr(fValue[i][2])])]));
      Result := Text;
    finally
      Free;
    end;
  end
else
  begin
    Result := StrToAnsi(StringOfChar(' ',IndentCount) + Format('%s: %d',[Name,Length(fValue)]));
    For i := Low(fValue) to High(fValue) do
      Result := Result + StrToAnsi(sLineBreak + StringOfChar(' ',IndentCount) + Format('%s[%d]: %s',[Name,i,
                  Format('(%s, %s, %s)',[SIIBin_SingleToStr(fValue[i][0]),
                                         SIIBin_SingleToStr(fValue[i][1]),
                                         SIIBin_SingleToStr(fValue[i][2])])]));
  end;
end;

end.

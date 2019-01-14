{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000018;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000018
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000018 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000018 = class(TSIIBin_ValueNode)
  private
    fValue: array of TSIIBin_Vec4s;
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
                           TSIIBin_ValueNode_000000018
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000019 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000018 - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000018.GetValueType: TSIIBin_ValueType;
begin
Result := $00000018;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000018.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  Stream_ReadBuffer(Stream,fValue[i],SizeOf(TSIIBin_Vec4s));
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000018 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000018.AsString: AnsiString;
begin
Result := StrToAnsi(Format('%d',[Length(fValue)]));
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode_00000018.AsLine(IndentCount: Integer = 0): AnsiString;
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
        AddDef(StringOfChar(' ',IndentCount) +
               Format('%s[%d]: (%s; %s, %s, %s)',[Name,i,SIIBin_SingleToStr(fValue[i][0]),
                                                          SIIBin_SingleToStr(fValue[i][1]),
                                                          SIIBin_SingleToStr(fValue[i][2]),
                                                          SIIBin_SingleToStr(fValue[i][3])]));
      Result := Text;
    finally
      Free;
    end;
  end
else
  begin
    Result := StrToAnsi(StringOfChar(' ',IndentCount) + Format('%s: %d',[Name,Length(fValue)]));
    For i := Low(fValue) to High(fValue) do
      Result := Result + StrToAnsi(sLineBreak + StringOfChar(' ',IndentCount) +
        Format('%s[%d]: (%s; %s, %s, %s)',[Name,i,SIIBin_SingleToStr(fValue[i][0]),
                                                   SIIBin_SingleToStr(fValue[i][1]),
                                                   SIIBin_SingleToStr(fValue[i][2]),
                                                   SIIBin_SingleToStr(fValue[i][3])]));
  end;
end;

end.

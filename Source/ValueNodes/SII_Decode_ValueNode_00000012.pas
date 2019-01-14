{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000012;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000012
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000012 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000012 = class(TSIIBin_ValueNode)
  private
    fValue: array of TSIIBin_Vec3i;
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
  BinaryStreaming, StrRect, ExplicitStringLists;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000012
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000012 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000012 - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000012.GetValueType: TSIIBin_ValueType;
begin
Result := $00000012;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000012.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  Stream_ReadBuffer(Stream,fValue[i],SizeOf(TSIIBin_Vec3i));
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000012 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000012.AsString: AnsiString;
begin
Result := StrToAnsi(Format('%d',[Length(fValue)]));
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode_00000012.AsLine(IndentCount: Integer = 0): AnsiString;
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
        AddDef(StringOfChar(' ',IndentCount) + Format('%s[%d]: (%d, %d, %d)',[Name,i,fValue[i][0],fValue[i][1],fValue[i][2]]));
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
        Format('%s[%d]: (%d, %d, %d)',[Name,i,fValue[i][0],fValue[i][1],fValue[i][2]]));
  end;
end;

end.

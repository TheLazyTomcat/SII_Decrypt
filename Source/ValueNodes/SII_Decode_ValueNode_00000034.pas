{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000034;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
{$IFNDEF FPC}
  AuxTypes,
{$ENDIF}
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000034
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000034 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000034 = class(TSIIBin_ValueNode)
  private
    fValue: array of UInt64;
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
                           TSIIBin_ValueNode_00000034
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000034 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000034 - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000034.GetValueType: TSIIBin_ValueType;
begin
Result := $00000034;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000034.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  fValue[i] := Stream_ReadUInt64(Stream);
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000034 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000034.AsString: AnsiString;
begin
Result := StrToAnsi(Format('%d',[Length(fValue)]));
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode_00000034.AsLine(IndentCount: Integer = 0): AnsiString;
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
        If (Int64Rec(fValue[i]).Lo <> $FFFFFFFF) and (Int64Rec(fValue[i]).Hi <> $FFFFFFFF) then
          AddDef(StringOfChar(' ',IndentCount) + Format('%s[%d]: %u',[Name,i,fValue[i]]))
        else
          AddDef(StringOfChar(' ',IndentCount) + Format('%s[%d]: nil',[Name,i]));
      Result := Text;
    finally
      Free;
    end;
  end
else
  begin
    Result := StrToAnsi(StringOfChar(' ',IndentCount) + Format('%s: %d',[Name,Length(fValue)]));
    For i := Low(fValue) to High(fValue) do
      If (Int64Rec(fValue[i]).Lo <> $FFFFFFFF) and (Int64Rec(fValue[i]).Hi <> $FFFFFFFF) then
        Result := Result + StrToAnsi(sLineBreak + StringOfChar(' ',IndentCount) +
                  Format('%s[%d]: %u',[Name,i,fValue[i]]))
      else
        Result := Result + StrToAnsi(sLineBreak + StringOfChar(' ',IndentCount) +
                  Format('%s[%d]: nil',[Name,i]));
  end;
end;

end.

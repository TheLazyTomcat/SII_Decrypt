{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000028;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  AuxTypes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000028
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000028 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000028 = class(TSIIBin_ValueNode)
  private
    fValue: array of UInt32;
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
                           TSIIBin_ValueNode_00000028
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000028 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000028 - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000028.GetValueType: TSIIBin_ValueType;
begin
Result := $00000028;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000028.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  fValue[i] := Stream_ReadUInt32(Stream);
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000028 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000028.AsString: AnsiString;
begin
Result := StrToAnsi(Format('%d',[Length(fValue)]));
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode_00000028.AsLine(IndentCount: Integer = 0): AnsiString;
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
        If fValue[i] <> $FFFFFFFF then
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
      begin
        If fValue[i] <> $FFFFFFFF then
          Result := Result + StrToAnsi(sLineBreak + StringOfChar(' ',IndentCount) +
                             Format('%s[%d]: %u',[Name,i,fValue[i]]))
        else
          Result := Result + StrToAnsi(sLineBreak + StringOfChar(' ',IndentCount) +
                             Format('%s[%d]: nil',[Name,i]));
      end;
  end;
end;

end.

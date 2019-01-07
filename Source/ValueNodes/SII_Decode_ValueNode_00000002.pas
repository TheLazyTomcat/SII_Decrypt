{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000002;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000002
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000002 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000002 = class(TSIIBin_ValueNode)
  private
    fValue: array of AnsiString;
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
                           TSIIBin_ValueNode_00000002
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000002 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000002 - protected methods
-------------------------------------------------------------------------------}

procedure TSIIBin_ValueNode_00000002.Initialize;
var
  i:  Integer;
begin
For i := Low(fValue) to High(fValue) do
  SIIBin_RectifyString(fValue[i]);
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode_00000002.GetValueType: TSIIBin_ValueType;
begin
Result := $00000002;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000002.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  SIIBin_LoadString(Stream,fValue[i]);
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000002 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000002.AsString: AnsiString;
begin
Result := StrToAnsi(Format('%d',[Length(fValue)]));
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode_00000002.AsLine(IndentCount: Integer = 0): AnsiString;
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
        If SIIBin_IsLimitedAlphabet(fValue[i]) and (Length(fValue[i]) > 0) then
          AddDef(StringOfChar(' ',IndentCount) + Format('%s[%d]: %s',[Name,i,fValue[i]]))
        else
          AddDef(StringOfChar(' ',IndentCount) + Format('%s[%d]: "%s"',[Name,i,fValue[i]]));
      Result := Text;
    finally
      Free;
    end;
  end
else
  begin
    Result := StrToAnsi(StringOfChar(' ',IndentCount) + Format('%s: %d',[Name,Length(fValue)]));
    For i := Low(fValue) to High(fValue) do
      If SIIBin_IsLimitedAlphabet(fValue[i]) and (Length(fValue[i]) > 0) then
        Result := Result + StrToAnsi(sLineBreak + StringOfChar(' ',IndentCount) +
                                     Format('%s[%d]: %s',[Name,i,fValue[i]]))
      else
        Result := Result + StrToAnsi(sLineBreak + StringOfChar(' ',IndentCount) +
                                     Format('%s[%d]: "%s"',[Name,i,fValue[i]]));
  end;
end;

end.

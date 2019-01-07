{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_0000003A;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  SII_Decode_Common, SII_Decode_ValueNode;

{!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

                                    WARNING

                 Actual type is not known, it was only guessed.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!}

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_0000003A
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_0000003A - declaration
===============================================================================}
type
  TSIIBin_ValueNode_0000003A = class(TSIIBin_ValueNode)
  private
    fValue: array of TSIIBin_ID;
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
                           TSIIBin_ValueNode_0000003A
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_0000003A - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_0000003A - protected methods
-------------------------------------------------------------------------------}

procedure TSIIBin_ValueNode_0000003A.Initialize;
var
  i:  Integer;
begin
For i := Low(fValue) to High(fValue) do
  If not (fValue[i].Length in [0,$FF]) then
    SIIBin_DecodeID(fValue[i]);
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode_0000003A.GetValueType: TSIIBin_ValueType;
begin
Result := $0000003A;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_0000003A.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  SIIBin_LoadID(Stream,fValue[i]);
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_0000003A - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_0000003A.AsString: AnsiString;
begin
Result := StrToAnsi(Format('%d',[Length(fValue)]));
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode_0000003A.AsLine(IndentCount: Integer = 0): AnsiString;
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
        AddDef(StringOfChar(' ',IndentCount) + Format('%s[%d]: %s',[Name,i,SIIBin_IDToStr(fValue[i],FormatVersion < 2)]));
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
                Format('%s[%d]: %s',[Name,i,SIIBin_IDToStr(fValue[i],FormatVersion < 2)]));
  end;
end;

end.

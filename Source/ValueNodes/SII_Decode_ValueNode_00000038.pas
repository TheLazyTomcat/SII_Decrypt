{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000038;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  SII_Decode_Common, SII_Decode_FieldData, SII_Decode_ValueNode;

{!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

                                    WARNING

                 Actual type is not known, it was only guessed.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!}

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000038
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000038 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000038 = class(TSIIBin_ValueNode)
  private
    fValue: array of TSIIBIn_FieldData_OrdinalStringItem;
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
  BinaryStreaming, StrRect, ExplicitStringLists, AuxExceptions,
  SII_Decode_Utils;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000038
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000038 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000038 - protected methods
-------------------------------------------------------------------------------}

procedure TSIIBin_ValueNode_00000038.Initialize;
var
  i:  Integer;
begin
If ValueInfo.ValueData is TSIIBIn_FieldData_OrdinalString then
  begin
    For i := Low(fValue) to High(fValue) do
      fValue[i].StringValue := TSIIBIn_FieldData_OrdinalString(ValueInfo.ValueData).GetStringValue(fValue[i].OrdinalValue)
  end
else raise EGeneralException.CreateFmt('Unsupported helper object (%s).',[ValueInfo.ValueData.ClassName],Self,'Initialize');
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode_00000038.GetValueType: TSIIBin_ValueType;
begin
Result := $00000038;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000038.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fValue,Stream_ReadUInt32(Stream));
For i := Low(fValue) to High(fValue) do
  fValue[i].OrdinalValue := Stream_ReadUInt32(Stream);
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000038 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000038.AsString: AnsiString;
begin
Result := StrToAnsi(Format('%d',[Length(fValue)]));
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode_00000038.AsLine(IndentCount: Integer = 0): AnsiString;
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

        If SIIBin_IsLimitedAlphabet(fValue[i].StringValue) and (Length(fValue[i].StringValue) > 0) then
          AddDef(StringOfChar(' ',IndentCount) + Format('%s[%d]: %s',[fValue[i].StringValue]))
        else
          AddDef(StringOfChar(' ',IndentCount) + Format('%s[%d]: "%s"',[fValue[i].StringValue]));

      Result := Text;
    finally
      Free;
    end;
  end
else
  begin
    Result := StrToAnsi(StringOfChar(' ',IndentCount) + Format('%s: %d',[Name,Length(fValue)]));
    For i := Low(fValue) to High(fValue) do
      If SIIBin_IsLimitedAlphabet(fValue[i].StringValue) and (Length(fValue[i].StringValue) > 0) then
        Result := Result + StrToAnsi(sLineBreak + StringOfChar(' ',IndentCount) +
                                     Format('%s[%d]: %s',[Name,i,fValue[i].StringValue]))
      else
        Result := Result + StrToAnsi(sLineBreak + StringOfChar(' ',IndentCount) +
                                     Format('%s[%d]: "%s"',[Name,i,fValue[i].StringValue]));
  end;
end;

end.

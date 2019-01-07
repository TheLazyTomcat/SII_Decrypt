{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000037;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  SII_Decode_Common, SII_Decode_FieldData, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000037
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000037 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000037 = class(TSIIBin_ValueNode)
  private
    fValue: TSIIBIn_FieldData_OrdinalStringItem;
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
  BinaryStreaming, StrRect, AuxExceptions,
  SII_Decode_Utils;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000037
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000037 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000037 - protected methods
-------------------------------------------------------------------------------}

procedure TSIIBin_ValueNode_00000037.Initialize;
begin
If ValueInfo.ValueData is TSIIBIn_FieldData_OrdinalString then
  fValue.StringValue := TSIIBIn_FieldData_OrdinalString(ValueInfo.ValueData).GetStringValue(fValue.OrdinalValue)
else
  raise EGeneralException.CreateFmt('Unsupported helper object (%s).',[ValueInfo.ValueData.ClassName],Self,'Initialize');
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode_00000037.GetValueType: TSIIBin_ValueType;
begin
Result := $00000037;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000037.Load(Stream: TStream);
begin
fValue.OrdinalValue := Stream_ReadUInt32(Stream);
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000037 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000037.AsString: AnsiString;
begin
If SIIBin_IsLimitedAlphabet(fValue.StringValue) and (Length(fValue.StringValue) > 0) then
  Result := StrToAnsi(Format('%s',[fValue.StringValue]))
else
  Result := StrToAnsi(Format('"%s"',[fValue.StringValue]));
end;

end.

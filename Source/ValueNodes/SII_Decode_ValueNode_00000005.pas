{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000005;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000005
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000005 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000005 = class(TSIIBin_ValueNode)
  private
    fValue: Single;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: AnsiString; override;
  end;

implementation

uses
  BinaryStreaming,
  SII_Decode_Utils;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000005
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000005 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000005 - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000005.GetValueType: TSIIBin_ValueType;
begin
Result := $00000005;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000005.Load(Stream: TStream);
begin
fValue := Stream_ReadFloat32(Stream);
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000005 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000005.AsString: AnsiString;
begin
Result := SIIBin_SingleToStr(fValue);
end;

end.

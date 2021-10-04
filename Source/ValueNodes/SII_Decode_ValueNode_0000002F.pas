{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_0000002F;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  AuxTypes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_0000002F
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_0000002F - declaration
===============================================================================}
type
  TSIIBin_ValueNode_0000002F = class(TSIIBin_ValueNode)
  private
    fValue: UInt32;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: AnsiString; override;
  end;

implementation

uses
  SysUtils,
  BinaryStreaming;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_0000002F
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_0000002F - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_0000002F - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_0000002F.GetValueType: TSIIBin_ValueType;
begin
Result := $0000002F;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_0000002F.Load(Stream: TStream);
begin
fValue := Stream_ReadUInt32(Stream);
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_0000002F - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_0000002F.AsString: AnsiString;
begin
Result := IntToStr(fValue);
end;

end.

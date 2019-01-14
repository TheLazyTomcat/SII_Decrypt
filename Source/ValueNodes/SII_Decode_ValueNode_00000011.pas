{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000011;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000011
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000011 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000011 = class(TSIIBin_ValueNode)
  private
    fValue: TSIIBin_Vec3i;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: AnsiString; override;
  end;


implementation

uses
  SysUtils,
  BinaryStreaming, StrRect;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_000000011
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000011 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000011 - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000011.GetValueType: TSIIBin_ValueType;
begin
Result := $00000011;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000011.Load(Stream: TStream);
begin
Stream_ReadBuffer(Stream,fValue,SizeOf(TSIIBin_Vec3i));
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000011 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000011.AsString: AnsiString;
begin
Result := StrToAnsi(Format('(%d, %d, %d)',[fValue[0],fValue[1],fValue[2]]));
end;

end.

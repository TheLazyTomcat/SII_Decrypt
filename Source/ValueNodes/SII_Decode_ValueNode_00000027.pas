{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000027;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  AuxTypes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000027
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000027 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000027 = class(TSIIBin_ValueNode)
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
  BinaryStreaming, StrRect;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000027
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000027 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000027 - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000027.GetValueType: TSIIBin_ValueType;
begin
Result := $00000027;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000027.Load(Stream: TStream);
begin
fValue := Stream_ReadUInt32(Stream);
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000027 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000027.AsString: AnsiString;
begin
If fValue <> $FFFFFFFF then
  Result := StrToAnsi(Format('%u',[fValue]))
else
  Result := AnsiString('nil');
end;

end.

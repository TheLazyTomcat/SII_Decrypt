{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_0000002B;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  AuxTypes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_0000002B
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_0000002B - declaration
===============================================================================}
type
  TSIIBin_ValueNode_0000002B = class(TSIIBin_ValueNode)
  private
    fValue: UInt16;
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
                           TSIIBin_ValueNode_0000002B
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_0000002B - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_0000002B - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_0000002B.GetValueType: TSIIBin_ValueType;
begin
Result := $0000002B;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_0000002B.Load(Stream: TStream);
begin
fValue := Stream_ReadUInt16(Stream);
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_0000002B - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_0000002B.AsString: AnsiString;
begin
If fValue <> $FFFF then
  Result := StrToAnsi(Format('%u',[fValue]))
else
  Result := AnsiString('nil');
end;

end.

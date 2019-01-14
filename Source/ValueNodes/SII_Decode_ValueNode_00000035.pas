{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000035;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000035
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000035 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000035 = class(TSIIBin_ValueNode)
  private
    fValue: ByteBool;
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
                           TSIIBin_ValueNode_00000035
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000035 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000035 - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000035.GetValueType: TSIIBin_ValueType;
begin
Result := $00000035;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000035.Load(Stream: TStream);
begin
fValue := Stream_ReadUInt8(Stream) <> 0;
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000035 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000035.AsString: AnsiString;
begin
Result := StrToAnsi(AnsiLowerCase(BoolToStr(fValue,True)));
end;

end.

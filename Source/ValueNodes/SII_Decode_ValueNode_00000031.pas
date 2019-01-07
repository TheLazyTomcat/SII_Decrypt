{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000031;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000031
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000031 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000031 = class(TSIIBin_ValueNode)
  private
    fValue: Int64;
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
                           TSIIBin_ValueNode_00000031
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000031 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000031 - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000031.GetValueType: TSIIBin_ValueType;
begin
Result := $00000031;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000031.Load(Stream: TStream);
begin
fValue := Stream_ReadInt64(Stream);
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000031 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000031.AsString: AnsiString;
begin
Result := StrToAnsi(Format('%d',[fValue]));
end;

end.

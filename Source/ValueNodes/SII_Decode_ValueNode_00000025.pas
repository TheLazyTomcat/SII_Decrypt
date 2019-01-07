{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000025;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  AuxTypes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000025
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000025 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000025 = class(TSIIBin_ValueNode)
  private
    fValue: Int32;
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
                           TSIIBin_ValueNode_00000025
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000025 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000025 - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000025.GetValueType: TSIIBin_ValueType;
begin
Result := $00000025;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000025.Load(Stream: TStream);
begin
fValue := Stream_ReadInt32(Stream);
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000025 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000025.AsString: AnsiString;
begin
Result := StrToAnsi(Format('%d',[fValue]));
end;


end.

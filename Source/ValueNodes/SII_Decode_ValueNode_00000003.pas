{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000003;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000003
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000003 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000003 = class(TSIIBin_ValueNode)
  private
    fValue:     UInt64;
    fValueStr:  AnsiString;
  protected
    procedure Initialize; override;
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
                           TSIIBin_ValueNode_00000003
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000003 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000003 - protected methods
-------------------------------------------------------------------------------}

procedure TSIIBin_ValueNode_00000003.Initialize;
begin
fValueStr := SIIBin_DecodeID(fValue);
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode_00000003.GetValueType: TSIIBin_ValueType;
begin
Result := $00000003;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000003.Load(Stream: TStream);
begin
fValue := Stream_ReadUInt64(Stream);
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000003 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000003.AsString: AnsiString;
begin
If fValue <> 0 then
  Result := fValueStr
else
  Result := '""';
end;

end.

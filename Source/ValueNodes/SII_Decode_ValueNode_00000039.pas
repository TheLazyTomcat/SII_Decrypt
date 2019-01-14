{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000039;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000039
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000039 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000039 = class(TSIIBin_ValueNode)
  private
    fValue: TSIIBin_ID;
  protected
    procedure Initialize; override;
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: AnsiString; override;
  end;

implementation

uses
  SII_Decode_Utils;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000039
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000039 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000039 - protected methods
-------------------------------------------------------------------------------}

procedure TSIIBin_ValueNode_00000039.Initialize;
begin
If not (fValue.Length in [0,$FF]) then
  SIIBin_DecodeID(fValue);
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode_00000039.GetValueType: TSIIBin_ValueType;
begin
Result := $00000039;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000039.Load(Stream: TStream);
begin
SIIBin_LoadID(Stream,fValue);
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000039 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000039.AsString: AnsiString;
begin
Result := SIIBin_IDToStr(fValue,FormatVersion < 2);
end;

end.

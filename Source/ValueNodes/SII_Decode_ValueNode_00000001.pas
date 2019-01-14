{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000001;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000001
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000001 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000001 = class(TSIIBin_ValueNode)
  private
    fValue: AnsiString;
  protected
    procedure Initialize; override;
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: AnsiString; override;
  end;

implementation

uses
  SysUtils,
  StrRect,
  SII_Decode_Utils;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000001
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000001 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000001 - protected methods
-------------------------------------------------------------------------------}

procedure TSIIBin_ValueNode_00000001.Initialize;
begin
SIIBin_RectifyString(fValue);
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode_00000001.GetValueType: TSIIBin_ValueType;
begin
Result := $00000001;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000001.Load(Stream: TStream);
begin
SIIBin_LoadString(Stream,fValue);
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000001 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000001.AsString: AnsiString;
begin
If SIIBin_IsLimitedAlphabet(fValue) and (Length(fValue) > 0) then
  Result := StrToAnsi(Format('%s',[fValue]))
else
  Result := StrToAnsi(Format('"%s"',[fValue]));
end;

end.

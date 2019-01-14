{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000033;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
{$IFNDEF FPC}
  AuxTypes,
{$ENDIF}
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000033
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000033 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000033 = class(TSIIBin_ValueNode)
  private
    fValue: UInt64;
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
                           TSIIBin_ValueNode_00000033
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000033 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000033 - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000033.GetValueType: TSIIBin_ValueType;
begin
Result := $00000033;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000033.Load(Stream: TStream);
begin
fValue := Stream_ReadUInt64(Stream);
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000033 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000033.AsString: AnsiString;
begin
If (Int64Rec(fValue).Lo <> $FFFFFFFF) and (Int64Rec(fValue).Hi <> $FFFFFFFF) then
  Result := StrToAnsi(Format('%u',[fValue]))
else
  Result := AnsiString('nil');
end;

end.

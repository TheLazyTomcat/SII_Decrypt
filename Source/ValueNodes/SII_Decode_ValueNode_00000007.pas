{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode_00000007;

{$INCLUDE '..\SII_Decode_defs.inc'}

interface

uses
  Classes,
  SII_Decode_Common, SII_Decode_ValueNode;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000007
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000007 - declaration
===============================================================================}
type
  TSIIBin_ValueNode_00000007 = class(TSIIBin_ValueNode)
  private
    fValue: TSIIBin_Vec2s;
  protected
    Function GetValueType: TSIIBin_ValueType; override;
    procedure Load(Stream: TStream); override;
  public
    Function AsString: AnsiString; override;
  end;

implementation

uses
  SysUtils,
  BinaryStreaming, StrRect,
  SII_Decode_Utils;

{===============================================================================
--------------------------------------------------------------------------------
                           TSIIBin_ValueNode_00000007
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode_00000007 - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000007 - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000007.GetValueType: TSIIBin_ValueType;
begin
Result := $00000007;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode_00000007.Load(Stream: TStream);
begin
Stream_ReadBuffer(Stream,fValue,SizeOf(TSIIBin_Vec2s));
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode_00000007 - public methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode_00000007.AsString: AnsiString;
begin
Result := StrToAnsi(Format('(%s, %s)',[SIIBin_SingleToStr(fValue[0]),SIIBin_SingleToStr(fValue[1])]));
end;

end.

{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_ValueNode;

{$INCLUDE '.\SII_Decode_defs.inc'}

interface

uses
  Classes,
  AuxTypes, AuxClasses,
  SII_Decode_Common;

{===============================================================================
--------------------------------------------------------------------------------
                               TSIIBin_ValueNode
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode - declaration
===============================================================================}
type
  TSIIBin_ValueNode = class(TCustomObject)
  private
    fFormatVersion: UInt32;
    fValueInfo:     TSIIBin_NamedValue;
    fName:          AnsiString;
  protected
    Function GetValueType: TSIIBin_ValueType; virtual;
    procedure Load(Stream: TStream); virtual; abstract;
    procedure Initialize; virtual;
    procedure Finalize; virtual;
  public
    constructor Create(FormatVersion: UInt32; const ValueInfo: TSIIBin_NamedValue; Stream: TStream);
    destructor Destroy; override;
    Function AsString: AnsiString; virtual;
    Function AsLine(IndentCount: Integer = 0): AnsiString; virtual;
    property ValueType: TSIIBin_ValueType read GetValueType;
    property ValueInfo: TSIIBin_NamedValue read fValueInfo;
    property FormatVersion: UInt32 read fFormatVersion;
    property Name: AnsiString read fName;
  end;

implementation

uses
  StrRect;

{===============================================================================
--------------------------------------------------------------------------------
                               TSIIBin_ValueNode
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBin_ValueNode - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBin_ValueNode - protected methods
-------------------------------------------------------------------------------}

Function TSIIBin_ValueNode.GetValueType: TSIIBin_ValueType;
begin
Result := 0;
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode.Initialize;
begin
// nothing to do
end;

//------------------------------------------------------------------------------

procedure TSIIBin_ValueNode.Finalize;
begin
// nothing to do
end;

{-------------------------------------------------------------------------------
    TSIIBin_ValueNode - public methods
-------------------------------------------------------------------------------}

constructor TSIIBin_ValueNode.Create(FormatVersion: UInt32; const ValueInfo: TSIIBin_NamedValue; Stream: TStream);
begin
inherited Create;
fFormatVersion := FormatVersion;
fValueInfo := ValueInfo;
fName := fValueInfo.ValueName;
Load(Stream);
Initialize;
end;

//------------------------------------------------------------------------------

destructor TSIIBin_ValueNode.Destroy;
begin
Finalize;
inherited;
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode.AsString: AnsiString;
begin
Result := '';
end;

//------------------------------------------------------------------------------

Function TSIIBin_ValueNode.AsLine(IndentCount: Integer = 0): AnsiString;
begin
Result := StrToAnsi(StringOfChar(' ',IndentCount)) + fName + AnsiString(': ') + AsString;
end;

end.

{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_FieldData;

{$INCLUDE '.\SII_Decode_defs.inc'}

interface

uses
  Classes,
  AuxTypes;

{===============================================================================
--------------------------------------------------------------------------------
                                TSIIBIn_FieldData
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBIn_FieldData - declaration
===============================================================================}

type
  TSIIBIn_FieldData = class(TObject)
  protected
    procedure Initialize; virtual;
    procedure Finalize; virtual;
    procedure Load(Stream: TStream); virtual; abstract;
  public
    constructor Create(Stream: TStream);
    destructor Destroy; override;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                         TSIIBIn_FieldData_OrdinalString
--------------------------------------------------------------------------------
===============================================================================}

  TSIIBIn_FieldData_OrdinalStringItem = record
    OrdinalValue: UInt32;
    StringValue:  AnsiString;
  end;

  TSIIBIn_FieldData_OrdinalStrings = array of TSIIBIn_FieldData_OrdinalStringItem;

{===============================================================================
    TSIIBIn_FieldData_OrdinalString - declaration
===============================================================================}

  TSIIBIn_FieldData_OrdinalString = class(TSIIBIn_FieldData)
  private
    fList:  TSIIBIn_FieldData_OrdinalStrings;
  protected
    procedure Load(Stream: TStream); override;
  public
    Function GetStringValue(OrdinalValue: UInt32): AnsiString; virtual;
  end;


implementation

uses
  AuxExceptions, BinaryStreaming,
  SII_Decode_Utils;

{===============================================================================
--------------------------------------------------------------------------------
                                TSIIBIn_FieldData
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBIn_FieldData - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBIn_FieldData - protected methods
-------------------------------------------------------------------------------}

procedure TSIIBIn_FieldData.Initialize;
begin
// nothing to do
end;

//------------------------------------------------------------------------------

procedure TSIIBIn_FieldData.Finalize;
begin
// nothing to do
end;

{-------------------------------------------------------------------------------
    TSIIBIn_FieldData - public methods
-------------------------------------------------------------------------------}

constructor TSIIBIn_FieldData.Create(Stream: TStream);
begin
inherited Create;
Load(Stream);
Initialize;
end;

//------------------------------------------------------------------------------

destructor TSIIBIn_FieldData.Destroy;
begin
Finalize;
inherited;
end;   


{===============================================================================
--------------------------------------------------------------------------------
                         TSIIBIn_FieldData_OrdinalString
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TSIIBIn_FieldData_OrdinalString - implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TSIIBIn_FieldData_OrdinalString - protected methods
-------------------------------------------------------------------------------}

procedure TSIIBIn_FieldData_OrdinalString.Load(Stream: TStream);
var
  i:  Integer;
begin
SetLength(fList,Stream_ReadUInt32(Stream));
For i := Low(fList) to High(fList) do
  begin
    fList[i].OrdinalValue := Stream_ReadUInt32(Stream);
    SIIBin_LoadString(Stream,fList[i].StringValue); 
  end;
end;

{-------------------------------------------------------------------------------
    TSIIBIn_FieldData_OrdinalString - public methods
-------------------------------------------------------------------------------}

Function TSIIBIn_FieldData_OrdinalString.GetStringValue(OrdinalValue: UInt32): AnsiString;
var
  i:  Integer;
begin
Result := '';
For i := Low(fList) to High(fList) do
  If fList[i].OrdinalValue = Ordinalvalue then
    begin
      Result := fList[i].StringValue;
      Exit;
    end;
// if the execution gets here, no match for given ordinal value was found
raise EGeneralException.CreateFmt('No match found for ordinal value %d.',[OrdinalValue],Self,'GetStringValue');
end;

end.

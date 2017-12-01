{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit SII_Decode_Helpers;

{$INCLUDE '.\SII_Decode_defs.inc'}

interface

uses
  Classes,
  AuxTypes;

{==============================================================================}
{------------------------------------------------------------------------------}
{                           TSIIBIn_ValueData_Helper                           }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TSIIBIn_ValueData_Helper - declaration                                     }
{==============================================================================}

type
  TSIIBIn_ValueData_Helper = class(TObject)
  protected
    procedure Initialize; virtual;
    procedure Finalize; virtual;
    procedure Load(Stream: TStream); virtual; abstract;
  public
    constructor Create(Stream: TStream);
    destructor Destroy; override;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                   TSIIBIn_ValueData_Helper_OrdinalStrings                    }
{------------------------------------------------------------------------------}
{==============================================================================}

  TSIIBIn_ValueData_OrdinalString = record
    OrdinalValue: UInt32;
    StringValue:  AnsiString;
  end;

  TSIIBIn_ValueData_OrdinalStrings = array of TSIIBIn_ValueData_OrdinalString;

{==============================================================================}
{   TSIIBIn_ValueData_Helper_OrdinalStrings - declaration                      }
{==============================================================================}

  TSIIBIn_ValueData_Helper_OrdinalStrings = class(TSIIBIn_ValueData_Helper)
  private
    fList:  TSIIBIn_ValueData_OrdinalStrings;
  protected
    procedure Load(Stream: TStream); override;
  public
    Function GetStringValue(OrdinalValue: UInt32): AnsiString; virtual;
  end;


implementation

uses
  SysUtils,
  BinaryStreaming,
  SII_Decode_Common;

{==============================================================================}
{------------------------------------------------------------------------------}
{                           TSIIBIn_ValueData_Helper                           }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBIn_ValueData_Helper - implementation                                  }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBIn_ValueData_Helper - protected methods                               }
{------------------------------------------------------------------------------}

procedure TSIIBIn_ValueData_Helper.Initialize;
begin
end;

//------------------------------------------------------------------------------

procedure TSIIBIn_ValueData_Helper.Finalize;
begin
end;

{------------------------------------------------------------------------------}
{   TSIIBIn_ValueData_Helper - public methods                                  }
{------------------------------------------------------------------------------}

constructor TSIIBIn_ValueData_Helper.Create(Stream: TStream);
begin
inherited Create;
Initialize;
Load(Stream);
end;

//------------------------------------------------------------------------------

destructor TSIIBIn_ValueData_Helper.Destroy;
begin
Finalize;
inherited;
end;



{==============================================================================}
{------------------------------------------------------------------------------}
{                   TSIIBIn_ValueData_Helper_OrdinalStrings                    }
{------------------------------------------------------------------------------}
{==============================================================================}
{==============================================================================}
{   TSIIBIn_ValueData_Helper_OrdinalStrings - implementation                   }
{==============================================================================}
{------------------------------------------------------------------------------}
{   TSIIBIn_ValueData_Helper_OrdinalStrings - protected methods                }
{------------------------------------------------------------------------------}

procedure TSIIBIn_ValueData_Helper_OrdinalStrings.Load(Stream: TStream);
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

{------------------------------------------------------------------------------}
{   TSIIBIn_ValueData_Helper_OrdinalStrings - public methods                   }
{------------------------------------------------------------------------------}

Function TSIIBIn_ValueData_Helper_OrdinalStrings.GetStringValue(OrdinalValue: UInt32): AnsiString;
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
raise Exception.CreateFmt('TSIIBIn_ValueData_Helper_OrdinalStrings.GetStringValue: No match found for ordinal value %d.',[OrdinalValue]);
end;

end.

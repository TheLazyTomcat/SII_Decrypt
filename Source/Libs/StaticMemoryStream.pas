{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  StaticMemoryStream

  ©František Milt 2017-08-01

  Version 1.0

  Very simple class intended to provide a way of accessing general memory
  location using usual streams.
  Unlike TMemoryStream, this implementation cannot realocate the memory, so it
  is safe to use it on pointers from external sources (libraries, OS, ...).

  Dependencies:
    AuxTypes  - github.com/ncs-sniper/Lib.AuxTypes

===============================================================================}
unit StaticMemoryStream;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Classes, AuxTypes;

{==============================================================================}
{------------------------------------------------------------------------------}
{                             TStaticMemoryStream                              }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TStaticMemoryStream - declaration                                          }
{==============================================================================}

type
  TStaticMemoryStream = class(TStream)
  private
    fMemory:    Pointer;
    fSize:      TMemSize;
    fPosition:  Int64;
  protected
    Function GetSize: Int64; override;
    procedure SetSize(const {%H-}NewValue: Int64); override;
  public
    constructor Create(Memory: Pointer; Size: TMemSize); overload;
    Function Read(var Buffer; Count: LongInt): LongInt; override;
    Function Write(const {%H-}Buffer; {%H-}Count: LongInt): LongInt; override;
    Function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    property Memory: Pointer read fMemory;
    property Size: TMemSize read fSize;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                         TWritableStaticMemoryStream                          }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TWritableStaticMemoryStream - declaration                                  }
{==============================================================================}

  TWritableStaticMemoryStream = class(TStaticMemoryStream)
  public
    Function Write(const Buffer; Count: LongInt): LongInt; override;
  end;

implementation

uses
  SysUtils;

{==============================================================================}
{------------------------------------------------------------------------------}
{                             TStaticMemoryStream                              }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TStaticMemoryStream - implementation                                       }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TStaticMemoryStream - protected methods                                    }
{------------------------------------------------------------------------------}

Function TStaticMemoryStream.GetSize: Int64;
begin
Result := Int64(fSize);
end;

//------------------------------------------------------------------------------

procedure TStaticMemoryStream.SetSize(const NewValue: Int64);
begin
raise Exception.Create('TStaticMemoryStream.SetSize: Cannot change size of static memory.');
end;

{------------------------------------------------------------------------------}
{   TStaticMemoryStream - public methods                                       }
{------------------------------------------------------------------------------}

constructor TStaticMemoryStream.Create(Memory: Pointer; Size: TMemSize);
begin
inherited Create;
fMemory := Memory;
fSize := Size;
fPosition := 0;
end;

//------------------------------------------------------------------------------

Function TStaticMemoryStream.Read(var Buffer; Count: LongInt): LongInt;
begin
If (Count > 0) and (fPosition >= 0) then
  begin
    Result := Int64(fSize) - fPosition;
    If Result > 0 then
      begin
        If Result > Count then
          Result := Count;
        Move({%H-}Pointer({%H-}PtrUInt(fMemory) + PtrUInt(fPosition))^,Buffer,Result);
        Inc(fPosition,Result);
      end
    else Result := 0;
  end
else Result := 0;
end;

//------------------------------------------------------------------------------

Function TStaticMemoryStream.{%H-}Write(const Buffer; Count: LongInt): LongInt;
begin
raise EWriteError.Create('TStaticMemoryStream.Write: Write operation not allowed on static memory.');
end;

//------------------------------------------------------------------------------

Function TStaticMemoryStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
case Origin of
  soBeginning:  fPosition := Offset;
  soCurrent:    fPosition := fPosition + Offset;
  soEnd:        fPosition := Int64(fSize) + Offset;
end;
Result := fPosition;
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                         TWritableStaticMemoryStream                          }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TWritableStaticMemoryStream - implementation                               }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TWritableStaticMemoryStream - public methods                               }
{------------------------------------------------------------------------------}

Function TWritableStaticMemoryStream.Write(const Buffer; Count: LongInt): LongInt;
begin
If (Count > 0) and (fPosition >= 0) then
  begin
    Result := Int64(fSize) - fPosition;
    If Result > 0 then
      begin
        If Result > Count then
          Result := Count;
        Move(Buffer,{%H-}Pointer({%H-}PtrUInt(fMemory) + PtrUInt(fPosition))^,Result);
        Inc(fPosition,Result);
      end
    else Result := 0;
  end
else Result := 0;
end;

end.

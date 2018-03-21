{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Memory buffer

  ©František Milt 2018-01-22

  Version 1.0.1

  Dependencies:
    AuxTypes - github.com/ncs-sniper/Lib.AuxTypes

===============================================================================}
unit MemoryBuffer;

{$IFDEF FPC}
  {$MODE ObjFPC}{$H+}
{$ENDIF}

interface

uses
  AuxTypes;

type
  TMemoryBuffer = record
    Memory: Pointer;
    Size:   TMemSize;
    Data:   PtrInt;
  end;
  PMemoryBuffer = ^TMemoryBuffer;

procedure GetBuffer(var Buff: TMemoryBuffer); overload;
procedure GetBuffer(out Buff: TMemoryBuffer; Size: TMemSize); overload;
Function GetBuffer(Size: TMemSize): TMemoryBuffer; overload;

procedure AllocBuffer(var Buff: TMemoryBuffer); overload;
procedure AllocBuffer(out Buff: TMemoryBuffer; Size: TMemSize); overload;
Function AllocBuffer(Size: TMemSize): TMemoryBuffer; overload;

procedure FreeBuffer(var Buff: TMemoryBuffer);

procedure ReallocBuffer(var Buff: TMemoryBuffer; NewSize: TMemSize);
procedure ReallocBufferKeep(var Buff: TMemoryBuffer; NewSize: TMemSize; AllowShrink: Boolean = False);

procedure CopyBuffer(const Src: TMemoryBuffer; out Copy: TMemoryBuffer);

Function BuildBuffer(Memory: Pointer; Size: TMemSize; Data: PtrInt = 0): TMemoryBuffer;

implementation

procedure GetBuffer(var Buff: TMemoryBuffer);
begin
If Buff.Size > 0 then
  GetMem(Buff.Memory,Buff.Size)
else
  Buff.Memory := nil;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure GetBuffer(out Buff: TMemoryBuffer; Size: TMemSize);
begin
Buff.Size := Size;
GetBuffer(Buff);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function GetBuffer(Size: TMemSize): TMemoryBuffer;
begin
Result.Size := Size;
GetBuffer(Result);
end;

//------------------------------------------------------------------------------

procedure AllocBuffer(var Buff: TMemoryBuffer);
begin
GetBuffer(Buff);
FillChar(Buff.Memory^,Buff.Size,0);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure AllocBuffer(out Buff: TMemoryBuffer; Size: TMemSize);
begin
GetBuffer(Buff,Size);
FillChar(Buff.Memory^,Buff.Size,0);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function AllocBuffer(Size: TMemSize): TMemoryBuffer;
begin
Result := GetBuffer(Size);
FillChar(Result.Memory^,Result.Size,0);
end;

//------------------------------------------------------------------------------

procedure FreeBuffer(var Buff: TMemoryBuffer);
begin
FreeMem(Buff.Memory,Buff.Size);
Buff.Memory := nil;
Buff.Size := 0;
end;

//------------------------------------------------------------------------------

procedure ReallocBuffer(var Buff: TMemoryBuffer; NewSize: TMemSize);
begin
If Assigned(Buff.Memory) then
  begin
    If NewSize <> 0 then
      begin
        If NewSize <> Buff.Size then
          begin
            ReallocMem(Buff.Memory,NewSize);
            Buff.Size := NewSize;
          end;
      end
    else FreeBuffer(Buff);
  end
else GetBuffer(Buff,NewSize);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure ReallocBufferKeep(var Buff: TMemoryBuffer; NewSize: TMemSize; AllowShrink: Boolean = False);
begin
If (NewSize > Buff.Size) or AllowShrink then
  ReallocBuffer(Buff,NewSize);
end;

//------------------------------------------------------------------------------

procedure CopyBuffer(const Src: TMemoryBuffer; out Copy: TMemoryBuffer);
begin
Copy := GetBuffer(Src.Size);
Move(Src.Memory^,Copy.Memory^,Src.Size);
Copy.Data := Src.Data;
end;

//------------------------------------------------------------------------------

Function BuildBuffer(Memory: Pointer; Size: TMemSize; Data: PtrInt = 0): TMemoryBuffer;
begin
Result.Memory := Memory;
Result.Size := Size;
Result.Data := Data;
end;

end.

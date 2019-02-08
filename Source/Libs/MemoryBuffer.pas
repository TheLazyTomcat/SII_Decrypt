{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Memory buffer

  ©František Milt 2019-01-26

  Version 1.0.3

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
    SigA:   UInt32;
    Data:   PtrInt;
    SigB:   UInt32;
  end;
  PMemoryBuffer = ^TMemoryBuffer;

Function ValidBuffer(const Buff: TMemoryBuffer): Boolean;
procedure InitBuffer(out Buff: TMemoryBuffer);

procedure GetBuffer(out Buff: TMemoryBuffer; Size: TMemSize); overload;
procedure GetBuffer(var Buff: TMemoryBuffer); overload;
Function GetBuffer(Size: TMemSize): TMemoryBuffer; overload;

procedure AllocBuffer(out Buff: TMemoryBuffer; Size: TMemSize); overload;
procedure AllocBuffer(var Buff: TMemoryBuffer); overload;
Function AllocBuffer(Size: TMemSize): TMemoryBuffer; overload;

procedure FreeBuffer(var Buff: TMemoryBuffer);

procedure ReallocBuffer(var Buff: TMemoryBuffer; NewSize: TMemSize);
procedure ReallocBufferKeep(var Buff: TMemoryBuffer; NewSize: TMemSize; AllowShrink: Boolean = False);

procedure CopyBuffer(const Src: TMemoryBuffer; out Copy: TMemoryBuffer);
procedure CopyBufferInto(const Src: TMemoryBuffer; var Dest: TMemoryBuffer);

Function BuildBuffer(Memory: Pointer; Size: TMemSize; Data: PtrInt = 0): TMemoryBuffer;

implementation

const
  // just some random numbers
  MEMBUFFER_SIGA = UInt32($035577FA);
  MEMBUFFER_SIGB = UInt32($45A297BC);

Function ValidBuffer(const Buff: TMemoryBuffer): Boolean;
begin
Result := (Buff.SigA = MEMBUFFER_SIGA) and (Buff.SigB = MEMBUFFER_SIGB);
end;

//------------------------------------------------------------------------------

procedure InitBuffer(out Buff: TMemoryBuffer);
begin
Buff.Memory := nil;
Buff.Size := 0;
Buff.SigA := MEMBUFFER_SIGA;
Buff.Data := 0;
Buff.SigB := MEMBUFFER_SIGB;
end;

//------------------------------------------------------------------------------

procedure GetBuffer(out Buff: TMemoryBuffer; Size: TMemSize);
begin
InitBuffer(Buff);
If Size > 0 then
  begin
    GetMem(Buff.Memory,Size);
    Buff.Size := Size;
  end
else Buff.Memory := nil;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure GetBuffer(var Buff: TMemoryBuffer);
begin
GetBuffer(Buff,Buff.Size);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function GetBuffer(Size: TMemSize): TMemoryBuffer;
begin
GetBuffer(Result,Size);
end;

//------------------------------------------------------------------------------

procedure AllocBuffer(out Buff: TMemoryBuffer; Size: TMemSize);
begin
GetBuffer(Buff,Size);
FillChar(Buff.Memory^,Buff.Size,0);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure AllocBuffer(var Buff: TMemoryBuffer);
begin
AllocBuffer(Buff,Buff.Size);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function AllocBuffer(Size: TMemSize): TMemoryBuffer;
begin
AllocBuffer(Result,Size);
end;

//------------------------------------------------------------------------------

procedure FreeBuffer(var Buff: TMemoryBuffer);
begin
If ValidBuffer(Buff) then
  begin
    FreeMem(Buff.Memory,Buff.Size);
    Buff.Memory := nil;
    Buff.Size := 0;
  end
else Initbuffer(Buff);
end;

//------------------------------------------------------------------------------

procedure ReallocBuffer(var Buff: TMemoryBuffer; NewSize: TMemSize);
begin
If ValidBuffer(Buff) then
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
If ValidBuffer(Buff) then
  begin
    If (NewSize > Buff.Size) or AllowShrink then
      ReallocBuffer(Buff,NewSize);
  end
else GetBuffer(Buff,NewSize);
end;

//------------------------------------------------------------------------------

procedure CopyBuffer(const Src: TMemoryBuffer; out Copy: TMemoryBuffer);
begin
If ValidBuffer(Src) then
  begin
    Copy := GetBuffer(Src.Size);  // this will also init the copy buffer
    Move(Src.Memory^,Copy.Memory^,Src.Size);
    Copy.Data := Src.Data;
  end
else InitBuffer(Copy);
end;

//------------------------------------------------------------------------------

procedure CopyBufferInto(const Src: TMemoryBuffer; var Dest: TMemoryBuffer);
begin
If ValidBuffer(Src) then
  begin
    ReallocBuffer(Dest,Src.Size); // this also checks validity
    Move(Src.Memory^,Dest.Memory^,Dest.Size);
    Dest.Data := Src.Data;
  end;
end;

//------------------------------------------------------------------------------

Function BuildBuffer(Memory: Pointer; Size: TMemSize; Data: PtrInt = 0): TMemoryBuffer;
begin
InitBuffer(Result);
Result.Memory := Memory;
Result.Size := Size;
Result.Data := Data;
end;

end.

{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  CRC32 Calculation

  ©František Milt 2018-10-21

  Version 1.4.11

  Polynomial 0x04c11db7

  Dependencies:
    AuxTypes - github.com/ncs-sniper/Lib.AuxTypes
    StrRect  - github.com/ncs-sniper/Lib.StrRect

===============================================================================}
unit CRC32;

{$IF defined(CPUX86_64) or defined(CPUX64)}
  {$DEFINE x64}
  {$IF defined(WINDOWS) or defined(MSWINDOWS)}
    {$DEFINE ASM_x64}
  {$ELSE}
    {$DEFINE PurePascal}
  {$IFEND}
{$ELSEIF defined(CPU386)}
  {$DEFINE x86}
{$ELSE}
  {$DEFINE PurePascal}
{$IFEND}

{$IFDEF FPC}
  {$MODE ObjFPC}{$H+}
  {$INLINE ON}
  {$DEFINE CanInline}
  {$IFNDEF PurePascal}
    {$ASMMODE Intel}
  {$ENDIF}
{$ELSE}
  {$IF CompilerVersion >= 17 then}  // Delphi 2005+
    {$DEFINE CanInline}
  {$ELSE}
    {$UNDEF CanInline}
  {$IFEND}
{$ENDIF}

{$DEFINE LargeBuffer}

{$IFDEF PurePascal}
  {$UNDEF ASM_x64}
{$ENDIF}

interface

uses
  Classes, AuxTypes;

type
  TCRC32 = UInt32;
  PCRC32 = ^TCRC32;

const
  InitialCRC32 = TCRC32($00000000);  

Function CRC32ToStr(CRC32: TCRC32): String;{$IFDEF CanInline} inline; {$ENDIF}
Function StrToCRC32(const Str: String): TCRC32;
Function TryStrToCRC32(const Str: String; out CRC32: TCRC32): Boolean;
Function StrToCRC32Def(const Str: String; Default: TCRC32): TCRC32;

Function CompareCRC32(A,B: TCRC32): Integer;
Function SameCRC32(A,B: TCRC32): Boolean;{$IFDEF CanInline} inline; {$ENDIF}

Function BufferCRC32(CRC32: TCRC32; const Buffer; Size: TMemSize): TCRC32; overload;

Function BufferCRC32(const Buffer; Size: TMemSize): TCRC32; overload;

Function AnsiStringCRC32(const Str: AnsiString): TCRC32;{$IFDEF CanInline} inline; {$ENDIF}
Function WideStringCRC32(const Str: WideString): TCRC32;{$IFDEF CanInline} inline; {$ENDIF}
Function StringCRC32(const Str: String): TCRC32;{$IFDEF CanInline} inline; {$ENDIF}

Function StreamCRC32(Stream: TStream; Count: Int64 = -1): TCRC32;
Function FileCRC32(const FileName: String): TCRC32;

//------------------------------------------------------------------------------

type
  TCRC32Context = type Pointer;

Function CRC32_Init: TCRC32Context;
procedure CRC32_Update(Context: TCRC32Context; const Buffer; Size: TMemSize);
Function CRC32_Final(var Context: TCRC32Context; const Buffer; Size: TMemSize): TCRC32; overload;
Function CRC32_Final(var Context: TCRC32Context): TCRC32; overload;
Function CRC32_Hash(const Buffer; Size: TMemSize): TCRC32;

implementation

uses
  SysUtils, StrRect;

const
{$IFDEF LargeBuffer}
  BufferSize = $100000; // 1MiB buffer
{$ELSE}
  BufferSize = 4096;    // 4KiB buffer
{$ENDIF}

  CRCTable: Array[Byte] of TCRC32 = (
  $00000000, $77073096, $EE0E612C, $990951BA, $076DC419, $706AF48F, $E963A535, $9E6495A3,
  $0EDB8832, $79DCB8A4, $E0D5E91E, $97D2D988, $09B64C2B, $7EB17CBD, $E7B82D07, $90BF1D91,
  $1DB71064, $6AB020F2, $F3B97148, $84BE41DE, $1ADAD47D, $6DDDE4EB, $F4D4B551, $83D385C7,
  $136C9856, $646BA8C0, $FD62F97A, $8A65C9EC, $14015C4F, $63066CD9, $FA0F3D63, $8D080DF5,
  $3B6E20C8, $4C69105E, $D56041E4, $A2677172, $3C03E4D1, $4B04D447, $D20D85FD, $A50AB56B,
  $35B5A8FA, $42B2986C, $DBBBC9D6, $ACBCF940, $32D86CE3, $45DF5C75, $DCD60DCF, $ABD13D59,
  $26D930AC, $51DE003A, $C8D75180, $BFD06116, $21B4F4B5, $56B3C423, $CFBA9599, $B8BDA50F,
  $2802B89E, $5F058808, $C60CD9B2, $B10BE924, $2F6F7C87, $58684C11, $C1611DAB, $B6662D3D,
  $76DC4190, $01DB7106, $98D220BC, $EFD5102A, $71B18589, $06B6B51F, $9FBFE4A5, $E8B8D433,
  $7807C9A2, $0F00F934, $9609A88E, $E10E9818, $7F6A0DBB, $086D3D2D, $91646C97, $E6635C01,
  $6B6B51F4, $1C6C6162, $856530D8, $F262004E, $6C0695ED, $1B01A57B, $8208F4C1, $F50FC457,
  $65B0D9C6, $12B7E950, $8BBEB8EA, $FCB9887C, $62DD1DDF, $15DA2D49, $8CD37CF3, $FBD44C65,
  $4DB26158, $3AB551CE, $A3BC0074, $D4BB30E2, $4ADFA541, $3DD895D7, $A4D1C46D, $D3D6F4FB,
  $4369E96A, $346ED9FC, $AD678846, $DA60B8D0, $44042D73, $33031DE5, $AA0A4C5F, $DD0D7CC9,
  $5005713C, $270241AA, $BE0B1010, $C90C2086, $5768B525, $206F85B3, $B966D409, $CE61E49F,
  $5EDEF90E, $29D9C998, $B0D09822, $C7D7A8B4, $59B33D17, $2EB40D81, $B7BD5C3B, $C0BA6CAD,
  $EDB88320, $9ABFB3B6, $03B6E20C, $74B1D29A, $EAD54739, $9DD277AF, $04DB2615, $73DC1683,
  $E3630B12, $94643B84, $0D6D6A3E, $7A6A5AA8, $E40ECF0B, $9309FF9D, $0A00AE27, $7D079EB1,
  $F00F9344, $8708A3D2, $1E01F268, $6906C2FE, $F762575D, $806567CB, $196C3671, $6E6B06E7,
  $FED41B76, $89D32BE0, $10DA7A5A, $67DD4ACC, $F9B9DF6F, $8EBEEFF9, $17B7BE43, $60B08ED5,
  $D6D6A3E8, $A1D1937E, $38D8C2C4, $4FDFF252, $D1BB67F1, $A6BC5767, $3FB506DD, $48B2364B,
  $D80D2BDA, $AF0A1B4C, $36034AF6, $41047A60, $DF60EFC3, $A867DF55, $316E8EEF, $4669BE79,
  $CB61B38C, $BC66831A, $256FD2A0, $5268E236, $CC0C7795, $BB0B4703, $220216B9, $5505262F,
  $C5BA3BBE, $B2BD0B28, $2BB45A92, $5CB36A04, $C2D7FFA7, $B5D0CF31, $2CD99E8B, $5BDEAE1D,
  $9B64C2B0, $EC63F226, $756AA39C, $026D930A, $9C0906A9, $EB0E363F, $72076785, $05005713,
  $95BF4A82, $E2B87A14, $7BB12BAE, $0CB61B38, $92D28E9B, $E5D5BE0D, $7CDCEFB7, $0BDBDF21,
  $86D3D2D4, $F1D4E242, $68DDB3F8, $1FDA836E, $81BE16CD, $F6B9265B, $6FB077E1, $18B74777,
  $88085AE6, $FF0F6A70, $66063BCA, $11010B5C, $8F659EFF, $F862AE69, $616BFFD3, $166CCF45,
  $A00AE278, $D70DD2EE, $4E048354, $3903B3C2, $A7672661, $D06016F7, $4969474D, $3E6E77DB,
  $AED16A4A, $D9D65ADC, $40DF0B66, $37D83BF0, $A9BCAE53, $DEBB9EC5, $47B2CF7F, $30B5FFE9,
  $BDBDF21C, $CABAC28A, $53B39330, $24B4A3A6, $BAD03605, $CDD70693, $54DE5729, $23D967BF,
  $B3667A2E, $C4614AB8, $5D681B02, $2A6F2B94, $B40BBE37, $C30C8EA1, $5A05DF1B, $2D02EF8D);
  
type
  TCRC32Context_Internal = record
    CRC32: TCRC32;
  end;
  PCRC32Context_Internal = ^TCRC32Context_Internal;  

//==============================================================================

Function CRC32ToStr(CRC32: TCRC32): String;
begin
Result := IntToHex(CRC32,8);
end;

//------------------------------------------------------------------------------

Function StrToCRC32(const Str: String): TCRC32;
begin
If Length(Str) > 0 then
  begin
    If Str[1] = '$' then
      Result := TCRC32(StrToInt(Str))
    else
      Result := TCRC32(StrToInt('$' + Str));
  end
else Result := InitialCRC32;
end;

//------------------------------------------------------------------------------

Function TryStrToCRC32(const Str: String; out CRC32: TCRC32): Boolean;
begin
try
  CRC32 := StrToCRC32(Str);
  Result := True;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function StrToCRC32Def(const Str: String; Default: TCRC32): TCRC32;
begin
If not TryStrToCRC32(Str,Result) then
  Result := Default;
end;

//------------------------------------------------------------------------------

Function CompareCRC32(A,B: TCRC32): Integer;
begin
If UInt32(A) > UInt32(B) then
  Result := -1
else If UInt32(A) < UInt32(B) then
  Result := 1
else
  Result := 0;
end;

//------------------------------------------------------------------------------

Function SameCRC32(A,B: TCRC32): Boolean;
begin
Result := UInt32(A) = UInt32(B);
end;

//==============================================================================

Function _BufferCRC32(CRC32: TCRC32; const Buffer; Size: TMemSize{$IFDEF ASM_x64}; CRCTablePtr: Pointer{$ENDIF}): TCRC32; register;{$IFNDEF PurePascal}assembler;
asm
{$IFDEF x64}
{******************************************************************************}
{     Register    Content                                                      }
{     RCX         old CRC32 value                                              }
{     RDX         pointer to Buffer                                            }
{     R8          Size value                                                   }
{     R9          Pointer to CRC table                                         }
{                                                                              }
{     Registers used in routine:                                               }
{     RAX (contains result), RCX, RDX, R8, R9                                  }
{******************************************************************************}

                MOV   EAX, ECX
                CMP   R8,  0        // check whether size is zero...
                JZ    @RoutineEnd   // ...end calculation when it is

                XCHG  R8, RCX       // RCX now contains size, R8 old CRC32 value
                NOT   R8D

{*** Main calculation loop, executed ECX times ********************************}
  @MainLoop:    MOV   AL,  byte ptr [RDX]
                XOR   AL,  R8B
                AND   RAX, $00000000000000FF
                MOV   EAX, dword ptr [RAX * 4 + R9]
                SHR   R8D, 8
                XOR   R8D, EAX
                INC   RDX

                DEC   RCX
                JNZ   @MainLoop

                NOT   R8D
                MOV   EAX, R8D

  @RoutineEnd:  MOV   Result, EAX
{$ELSE}
{******************************************************************************}
{     Register    Content                                                      }
{     EAX         old CRC32 value, Result                                      }
{     EDX         pointer to Buffer                                            }
{     ECX         Size value                                                   }
{                                                                              }
{     Registers used in routine:                                               }
{     EAX (contains result), EBX (value preserved), ECX, EDX                   }
{******************************************************************************}

                CMP   ECX, 0        // check whether size is zero...
                JZ    @RoutineEnd   // ...end calculation when it is

                PUSH  EBX           // EBX register value must be preserved
                MOV   EBX, EDX      // EBX now contains pointer to Buffer
                NOT   EAX

{*** Main calculation loop, executed ECX times ********************************}
  @MainLoop:    MOV   DL,  byte ptr [EBX]
                XOR   DL,  AL
                AND   EDX, $000000FF
                MOV   EDX, dword ptr [EDX * 4 + CRCTable]
                SHR   EAX, 8
                XOR   EAX, EDX
                INC   EBX

                DEC   ECX
                JNZ   @MainLoop

                NOT   EAX
                POP   EBX           // restore EBX register

  @RoutineEnd:  MOV   Result, EAX
{$ENDIF}
end;
{$ELSE PurePascal}
var
  i:    TMemSize;
  Buff: PByte;
begin
Result := not CRC32;
Buff := @Buffer;
For i := 1 to Size do
  begin
    Result := CRCTable[Byte(Result xor TCRC32(Buff^))] xor (Result shr 8);
    Inc(Buff);
  end;
Result := not Result;
end;
{$ENDIF PurePascal}

//------------------------------------------------------------------------------

Function BufferCRC32(CRC32: TCRC32; const Buffer; Size: TMemSize): TCRC32;
begin
Result := _BufferCRC32(CRC32,Buffer,Size{$IFDEF ASM_x64},@CRCTable{$ENDIF});
end;

//==============================================================================

Function BufferCRC32(const Buffer; Size: TMemSize): TCRC32;
begin
Result := BufferCRC32(InitialCRC32,Buffer,Size);
end;

//==============================================================================

Function AnsiStringCRC32(const Str: AnsiString): TCRC32;
begin
Result := BufferCRC32(PAnsiChar(Str)^,Length(Str) * SizeOf(AnsiChar));
end;

//------------------------------------------------------------------------------

Function WideStringCRC32(const Str: WideString): TCRC32;
begin
Result := BufferCRC32(PWideChar(Str)^,Length(Str) * SizeOf(WideChar));
end;

//------------------------------------------------------------------------------

Function StringCRC32(const Str: String): TCRC32;
begin
Result := BufferCRC32(PChar(Str)^,Length(Str) * SizeOf(Char));
end;

//==============================================================================

Function StreamCRC32(Stream: TStream; Count: Int64 = -1): TCRC32;
var
  Buffer:     Pointer;
  BytesRead:  Integer;

  Function Min(A,B: Int64): Int64;
  begin
    If A < B then Result := A
      else Result := B;
  end;

begin
If Assigned(Stream) then
  begin
    If Count = 0 then
      Count := Stream.Size - Stream.Position;
    If Count < 0 then
      begin
        Stream.Position := 0;
        Count := Stream.Size;
      end;
    GetMem(Buffer,BufferSize);
    try
      Result := InitialCRC32;
      repeat
        BytesRead := Stream.Read(Buffer^,Min(BufferSize,Count));
        Result := BufferCRC32(Result,Buffer^,BytesRead);
        Dec(Count,BytesRead);
      until BytesRead < BufferSize;
    finally
      FreeMem(Buffer,BufferSize);
    end;
  end
else raise Exception.Create('StreamCRC32: Stream is not assigned.');
end;

//------------------------------------------------------------------------------

Function FileCRC32(const FileName: String): TCRC32;
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName), fmOpenRead or fmShareDenyWrite);
try
  Result := StreamCRC32(FileStream);
finally
  FileStream.Free;
end;
end;

//==============================================================================

Function CRC32_Init: TCRC32Context;
begin
Result := AllocMem(SizeOf(TCRC32Context_Internal));
PCRC32Context_Internal(Result)^.CRC32 := InitialCRC32;
end;

//------------------------------------------------------------------------------

procedure CRC32_Update(Context: TCRC32Context; const Buffer; Size: TMemSize);
begin
PCRC32Context_Internal(Context)^.CRC32 := BufferCRC32(PCRC32Context_Internal(Context)^.CRC32,Buffer,Size);
end;

//------------------------------------------------------------------------------

Function CRC32_Final(var Context: TCRC32Context; const Buffer; Size: TMemSize): TCRC32;
begin
CRC32_Update(Context,Buffer,Size);
Result := CRC32_Final(Context);
end;

//------------------------------------------------------------------------------

Function CRC32_Final(var Context: TCRC32Context): TCRC32;
begin
Result := PCRC32Context_Internal(Context)^.CRC32;
FreeMem(Context,SizeOf(TCRC32Context_Internal));
Context := nil;
end;

//------------------------------------------------------------------------------

Function CRC32_Hash(const Buffer; Size: TMemSize): TCRC32;
begin
Result := BufferCRC32(Buffer,Size);
end;

end.

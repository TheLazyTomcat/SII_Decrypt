{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Rijndael/AES cipher

  ©František Milt 2017-07-26

  Version 1.1

  All combinations of allowed key and block sizes are implemented and should be
  compatible with reference Rijndael cipher.

  Dependencies:
    AuxTypes    - github.com/ncs-sniper/Lib.AuxTypes
    StrRect     - github.com/ncs-sniper/Lib.StrRect
  * SimpleCPUID - github.com/ncs-sniper/Lib.SimpleCPUID

  SimpleCPUID is required only when PurePascal symbol is not defined.

===============================================================================}
unit AES;

{$IF defined(CPUX86_64) or defined(CPUX64)}
  {$DEFINE x64}
{$ELSEIF defined(CPU386)}
  {$DEFINE x86}
{$ELSE}
  {$DEFINE PurePascal}
{$IFEND}

{$IF defined(CPU64) or defined(CPU64BITS)}
  {$DEFINE 64bit}
{$ELSEIF defined(CPU16)}
  {$MESSAGE FATAL '16bit CPU not supported'}
{$ELSE}
  {$DEFINE 32bit}
{$IFEND}

{$IF Defined(WINDOWS) or Defined(MSWINDOWS)}
  {$DEFINE Windows}
{$IFEND}

{$IFDEF ENDIAN_BIG}
  {$MESSAGE FATAL 'Big-endian system not supported'}
{$ENDIF}

{$IFOPT Q+}
  {$DEFINE OverflowChecks}
{$ENDIF}

{$IFDEF FPC}
  {$MODE Delphi}
  {$IFNDEF PurePascal}
    {$ASMMODE Intel}
    {$DEFINE ASMSuppressSizeWarnings}
  {$ENDIF}
{$ENDIF}

{$IF not Defined(FPC) and not Defined(x64)}
  {$DEFINE ASM_MachineCode}
{$ELSE}
  {$UNDEF ASM_MachineCode}
{$IFEND}

{$TYPEINFO ON}

interface

uses
  Classes,
  AuxTypes;

{==============================================================================}
{------------------------------------------------------------------------------}
{                                 TBlockCipher                                 }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TBlockCipher - declaration                                                 }
{==============================================================================}
{
  TBlockCipher serves as a base class for all block ciphers - it will be moved
  to a separate unit in the future.
}

const
  BlocksPerStreamBuffer = 1024;

type
  TBCMode            = (cmUndefined,cmEncrypt,cmDecrypt);
  TBCModeOfOperation = (moECB,moCBC,moPCBC,moCFB,moOFB,moCTR);
  TBCPadding         = (padZeroes,padPKCS7,padANSIX923,padISO10126,padISOIEC7816_4);

  TBCUpdateProc = procedure(const Input; out Output) of object;
  TBCProgressEvent = procedure(Sender: TObject; Progress: Single) of object;

  TBlockCipher = class(TObject)
  private
    fMode:            TBCMode;
    fModeOfOperation: TBCModeOfOperation;
    fPadding:         TBCPadding;
    fInitVector:      Pointer;
    fInitVectorBytes: TMemSize;
    fKey:             Pointer;
    fKeyBytes:        TMemSize;
    fTempBlock:       Pointer;
    fBlockBytes:      TMemSize;
    fUpdateProc:      TBCUpdateProc;
    fOnProgress:      TBCProgressEvent;
    Function GetInitVectorBits: TMemSize;
    Function GetKeyBits: TMemSize;
    Function GetBlockBits: TMemSize;  
  protected
    procedure SetKeyBytes(Value: TMemSize); virtual;
    procedure SetBlockBytes(Value: TMemSize); virtual;
    procedure SetModeOfOperation(Value: TBCModeOfOperation); virtual;
    procedure BlocksXOR(const Src1,Src2; out Dest); virtual;
    procedure BlocksCopy(const Src; out Dest); virtual;
    procedure Update_ECB(const Input; out Output); virtual;
    procedure Update_CBC(const Input; out Output); virtual;
    procedure Update_PCBC(const Input; out Output); virtual;
    procedure Update_CFB(const Input; out Output); virtual;
    procedure Update_OFB(const Input; out Output); virtual;
    procedure Update_CTR(const Input; out Output); virtual;
    procedure ProcessBuffer(Buffer: Pointer; Size: TMemSize); virtual;
    procedure PrepareUpdateProc; virtual;
    procedure DoProgress(Progress: Single); virtual;
    procedure CipherInit; virtual; abstract;
    procedure CipherFinal; virtual; abstract;
    procedure CipherEncrypt(const Input; out Output); virtual; abstract;
    procedure CipherDecrypt(const Input; out Output); virtual; abstract;
    procedure Initialize(const Key; const InitVector; KeyBytes, BlockBytes: TMemSize; Mode: TBCMode); overload; virtual;
    procedure Initialize(const Key; KeyBytes, BlockBytes: TMemSize; Mode: TBCMode); overload; virtual;
  public
    constructor Create; overload; virtual;
    destructor Destroy; override;
    procedure Update(const Input; out Output); virtual;
    procedure Final(const Input; InputSize: TMemSize; out Output); virtual;
    Function OutputSize(InputSize: TMemSize): TMemSize; virtual;
    procedure ProcessBytes(const Input; InputSize: TMemSize; out Output); overload; virtual;
    procedure ProcessBytes(var Buff; Size: TMemSize); overload; virtual;
    procedure ProcessStream(Input, Output: TStream); overload; virtual;
    procedure ProcessStream(Stream: TStream); overload; virtual;
    procedure ProcessFile(const InputFileName, OutputFileName: String); overload; virtual;
    procedure ProcessFile(const FileName: String); overload; virtual;
    procedure ProcessAnsiString(const InputStr: AnsiString; var OutputStr: AnsiString); overload; virtual;
    procedure ProcessAnsiString(var Str: AnsiString); overload; virtual;
    procedure ProcessWideString(const InputStr: UnicodeString; var OutputStr: UnicodeString); overload; virtual;
    procedure ProcessWideString(var Str: UnicodeString); overload; virtual;
    procedure ProcessString(const InputStr: String; var OutputStr: String); overload; virtual;
    procedure ProcessString(var Str: String); overload; virtual;
    property InitVector: Pointer read fInitVector;
    property Key: Pointer read fKey;
  published
    property Mode: TBCMode read fMode;
    property ModeOfOperation: TBCModeOfOperation read fModeOfOperation write SetModeOfOperation;
    property Padding: TBCPadding read fPadding write fPadding;
    property InitVectorBytes: TMemSize read fInitVectorBytes;
    property InitVectorBits: TMemSize read GetInitVectorBits;
    property KeyBytes: TMemSize read fKeyBytes;
    property KeyBits: TMemSize read GetKeyBits;
    property BlockBytes: TMemSize read fBlockBytes;
    property BlockBits: TMemSize read GetBlockBits;
    property OnProgress: TBCProgressEvent read fOnProgress write fOnProgress;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                               TRijndaelCipher                                }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TRijndaelCipher - declaration                                              }
{==============================================================================}

type
  TRijLength  = (r128bit,r160bit,r192bit,r224bit,r256bit);

  TRijWord = UInt32;
  PRijWord = ^TRijWord;

  TRijKeySchedule  = array[0..119] of TRijWord;
  TRijState        = array[0..7] of TRijWord;   {256 bits}
  TRijRowShiftOffs = array[0..3] of Integer;

  TRijndaelCipher = class(TBlockCipher)
  private
    fKeyLength:   TRijLength;
    fBlockLength: TRijLength;
    fNk:          Integer;    // length of the key in words
    fNb:          Integer;    // length of the block in words (also number of columns in state)
    fNr:          Integer;    // number of rounds (function of Nk an Nb)
    fKeySchedule: TRijKeySchedule;
    fRowShiftOff: TRijRowShiftOffs;
  protected
    procedure SetModeOfOperation(Value: TBCModeOfOperation); override;
    procedure SetKeyLength(Value: TRijLength); virtual;
    procedure SetBlockLength(Value: TRijLength); virtual;
    procedure CipherInit; override;
    procedure CipherFinal; override;
    procedure CipherEncrypt(const Input; out Output); override;
    procedure CipherDecrypt(const Input; out Output); override;
  public
    constructor Create(const Key; const InitVector; KeyLength, BlockLength: TRijLength; Mode: TBCMode); overload; virtual;
    constructor Create(const Key; KeyLength, BlockLength: TRijLength; Mode: TBCMode); overload; virtual;
    procedure Init(const Key; const InitVector; KeyLength, BlockLength: TRijLength; Mode: TBCMode); overload; virtual;
    procedure Init(const Key; KeyLength, BlockLength: TRijLength; Mode: TBCMode); overload; virtual;
  published
    property KeyLength: TRijLength read fKeyLength;
    property BlockLength: TRijLength read fBlockLength;
    property Nk: Integer read fNk;
    property Nb: Integer read fNb;
    property Nr: Integer read fNr;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                                  TAESCipher                                  }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TAESCipher - declaration                                                   }
{==============================================================================}

  TAESCipher = class(TRijndaelCipher)
  protected
    procedure SetKeyLength(Value: TRijLength); override;
    procedure SetBlockLength(Value: TRijLength); override;
  public
    class Function AccelerationSupported: Boolean; virtual;
    constructor Create(const Key; const InitVector; KeyLength, {%H-}BlockLength: TRijLength; Mode: TBCMode); overload; override;
    constructor Create(const Key; KeyLength, {%H-}BlockLength: TRijLength; Mode: TBCMode); overload; override;
    constructor Create(const Key; const InitVector; KeyLength: TRijLength; Mode: TBCMode); overload; virtual;
    constructor Create(const Key; KeyLength: TRijLength; Mode: TBCMode); overload; virtual;
    procedure Init(const Key; const InitVector; KeyLength, {%H-}BlockLength: TRijLength; Mode: TBCMode); overload; override;
    procedure Init(const Key; KeyLength, {%H-}BlockLength: TRijLength; Mode: TBCMode); overload; override;    
    procedure Init(const Key; const InitVector; KeyLength: TRijLength; Mode: TBCMode); overload; virtual;
    procedure Init(const Key; KeyLength: TRijLength; Mode: TBCMode); overload; virtual;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TAESCipherAccelerated                             }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TAESCipherAccelerated - declaration                                        }
{==============================================================================}

{$IFDEF PurePascal}
  TAESCipherAccelerated = TAESCipher;
{$ELSE}
  TAESCipherAccelerated = class(TAESCipher)
  private
    fAccelerated:     Boolean;
    fKeySchedulePtr:  Pointer;
  protected
    procedure CipherInit; override;
    procedure CipherEncrypt(const Input; out Output); override;
    procedure CipherDecrypt(const Input; out Output); override;
  public
    class Function AccelerationSupported: Boolean; override;
  end;
{$ENDIF}

implementation

uses
  SysUtils, Math, StrRect{$IFNDEF PurePascal}, SimpleCPUID{$ENDIF};

{==============================================================================}
{------------------------------------------------------------------------------}
{                                 TBlockCipher                                 }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TBlockCipher - implementation                                              }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TBlokcCipher - private methods                                             }
{------------------------------------------------------------------------------}

Function TBlockCipher.GetInitVectorBits: TMemSize;
begin
Result := TMemSize(fInitVectorBytes shl 3);
end;

//------------------------------------------------------------------------------

Function TBlockCipher.GetKeyBits: TMemSize;
begin
Result := TMemSize(fKeyBytes shl 3);
end;

//------------------------------------------------------------------------------

Function TBlockCipher.GetBlockBits: TMemSize;
begin
Result := TMemSize(fBlockBytes shl 3);
end;

{------------------------------------------------------------------------------}
{   TBlokcCipher - protected methods                                           }
{------------------------------------------------------------------------------}

procedure TBlockCipher.SetKeyBytes(Value: TMemSize);
begin
fKeyBytes := Value;
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.SetBlockBytes(Value: TMemSize);
begin
fBlockBytes := Value;
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.SetModeOfOperation(Value: TBCModeOfOperation);
begin
fModeOfOperation := Value;
PrepareUpdateProc;
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.BlocksXOR(const Src1,Src2; out Dest);
var
  i:  PtrUInt;
begin
If fBlockBytes > 0 then
  begin
  {$IFDEF 64bit}
    If fBlockBytes and 7 = 0 then
      begin
        For i := 0 to Pred(fBlockBytes shr 3) do
          {%H-}PUInt64({%H-}PtrUInt(@Dest) + (i shl 3))^ :=
            {%H-}PUInt64({%H-}PtrUInt(@Src1) + (i shl 3))^ xor
            {%H-}PUInt64({%H-}PtrUInt(@Src2) + (i shl 3))^
      end
    else{$ENDIF} If fBlockBytes and 3 = 0 then
      begin
        For i := 0 to Pred(fBlockBytes shr 2) do
          {%H-}PUInt32({%H-}PtrUInt(@Dest) + (i shl 2))^ :=
            {%H-}PUInt32({%H-}PtrUInt(@Src1) + (i shl 2))^ xor
            {%H-}PUInt32({%H-}PtrUInt(@Src2) + (i shl 2))^
      end
    else
      begin
        For i := 0 to Pred(fBlockBytes) do
          {%H-}PByte({%H-}PtrUInt(@Dest) + i)^ :=
            {%H-}PByte({%H-}PtrUInt(@Src1) + i)^ xor
            {%H-}PByte({%H-}PtrUInt(@Src2) + i)^;
      end;
  end;
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.BlocksCopy(const Src; out Dest);
begin
Move(Src,{%H-}Dest,fBlockBytes);
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.Update_ECB(const Input; out Output);
begin
case fMode of
  cmEncrypt:  CipherEncrypt(Input,Output);
  cmDecrypt:  CipherDecrypt(Input,Output);
else
  raise Exception.CreateFmt('TBlockCipher.Update_ECB: Invalid mode (%d).',[Ord(fMode)]);
end;
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.Update_CBC(const Input; out Output);
begin
case fMode of
  cmEncrypt:
    begin
      BlocksXOR(Input,fInitVector^,fTempBlock^);
      CipherEncrypt(fTempBlock^,Output);
      BlocksCopy(Output,fInitVector^);
    end;
  cmDecrypt:
    begin
      BlocksCopy(Input,fTempBlock^);
      CipherDecrypt(Input,Output);
      BlocksXOR(Output,fInitVector^,Output);
      BlocksCopy(fTempBlock^,fInitVector^);
    end;
else
  raise Exception.CreateFmt('TBlockCipher.Update_CBC: Invalid mode (%d).',[Ord(fMode)]);
end;
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.Update_PCBC(const Input; out Output);
begin
case fMode of
  cmEncrypt:
    begin
      BlocksXOR(Input,fInitVector^,fTempBlock^);
      BlocksCopy(Input,fInitVector^);
      CipherEncrypt(fTempBlock^,Output);
      BlocksXOR(Output,fInitVector^,fInitVector^);
    end;
  cmDecrypt:
    begin
      CipherDecrypt(Input,fTempBlock^);
      BlocksXOR(fTempBlock^,fInitVector^,fTempBlock^);
      BlocksXOR(Input,fTempBlock^,fInitVector^);
      BlocksCopy(fTempBlock^,Output);
    end;
else
  raise Exception.CreateFmt('TBlockCipher.Update_PCBC: Invalid mode (%d).',[Ord(fMode)]);
end;
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.Update_CFB(const Input; out Output);
begin
case fMode of
  cmEncrypt:
    begin
      CipherEncrypt(fInitVector^,fTempBlock^);
      BlocksXOR(fTempBlock^,Input,Output);
      BlocksCopy(Output,fInitVector^);
    end;
  cmDecrypt:
    begin
      CipherEncrypt(fInitVector^,fTempBlock^);
      BlocksCopy(Input,fInitVector^);
      BlocksXOR(fTempBlock^,Input,Output);
    end;
else
  raise Exception.CreateFmt('TBlockCipher.Update_CFB: Invalid mode (%d).',[Ord(fMode)]);
end;
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.Update_OFB(const Input; out Output);
begin
CipherEncrypt(fInitVector^,fInitVector^);
BlocksXOR(Input,fInitVector^,Output);
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.Update_CTR(const Input; out Output);
begin
If BlockBytes >= 8 then
  begin
    CipherEncrypt(fInitVector^,fTempBlock^);
    BlocksXOR(Input,fTempBlock^,Output);
  {$IFDEF OverflowChecks}{$Q-}{$ENDIF}
    Int64(fInitVector^) := Int64(fInitVector^) + 1;
  {$IFDEF OverflowChecks}{$Q+}{$ENDIF}
  end
else raise Exception.CreateFmt('TBlockCipher.Update_CTR: Too small block (%d), cannot use CTR.',[fBlockBytes]);
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.ProcessBuffer(Buffer: Pointer; Size: TMemSize);
var
  i:        Integer;
  WorkPtr:  Pointer;
begin
If Size >= fBlockBytes then
  For i := 0 to Pred(Size div fBlockBytes) do
    begin
      WorkPtr := {%H-}Pointer({%H-}PtrUInt(Buffer) + PtrUInt(TMemSize(i) * fBlockBytes));
      Update(WorkPtr^,WorkPtr^);
    end;
If (Size mod fBlockBytes) <> 0 then
  begin
    WorkPtr := {%H-}Pointer({%H-}PtrUInt(Buffer) + PtrUInt((Size div fBlockBytes) * fBlockBytes));
    Final(WorkPtr^,Size mod fBlockBytes,WorkPtr^);
  end;
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.PrepareUpdateProc;
begin
case fModeOfOperation of
  moECB:  fUpdateProc := Update_ECB;
  moCBC:  fUpdateProc := Update_CBC;
  moPCBC: fUpdateProc := Update_PCBC;
  moCFB:  fUpdateProc := Update_CFB;
  moOFB:  fUpdateProc := Update_OFB;
  moCTR:  fUpdateProc := Update_CTR;
else
  raise Exception.CreateFmt('TBlockCipher.PrepareUpdateProc: Unknown mode of operation (%d).',[Ord(fModeOfOperation)]);
end;
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.DoProgress(Progress: Single);
begin
If Assigned(fOnProgress) then fOnProgress(Self,Progress);
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.Initialize(const Key; const InitVector; KeyBytes, BlockBytes: TMemSize; Mode: TBCMode);
begin
If (KeyBytes > 0) and (BlockBytes > 0) then
  begin
    fMode := Mode;
    ReallocMem(fKey,KeyBytes);
    Move(Key,fKey^,KeyBytes);
    fKeyBytes := KeyBytes;
    ReallocMem(fInitVector,BlockBytes);
    ReallocMem(fTempBlock,BlockBytes);
    Move(InitVector,fInitVector^,BlockBytes);
    fBlockBytes := BlockBytes;
    PrepareUpdateProc;
    CipherInit;
  end
else raise Exception.CreateFmt('TBlockCipher.Init: Size of key (%d) and blocks (%d) must be larger than zero.',[KeyBytes, BlockBytes]);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TBlockCipher.Initialize(const Key; KeyBytes, BlockBytes: TMemSize; Mode: TBCMode);
begin
If (KeyBytes > 0) and (BlockBytes > 0) then
  begin
    fMode := Mode;
    ReallocMem(fKey,KeyBytes);
    Move(Key,fKey^,KeyBytes);
    fKeyBytes := KeyBytes;
    ReallocMem(fInitVector,BlockBytes);
    FillChar(fInitVector^,BlockBytes,0);
    ReallocMem(fTempBlock,BlockBytes);
    fBlockBytes := BlockBytes;
    PrepareUpdateProc;
    CipherInit;
  end
else raise Exception.CreateFmt('TBlockCipher.Init: Size of key (%d) and blocks (%d) must be larger than zero.',[KeyBytes, BlockBytes]);
end;

{------------------------------------------------------------------------------}
{   TBlokcCipher - public methods                                              }
{------------------------------------------------------------------------------}

constructor TBlockCipher.Create;
begin
inherited Create;
fMode := cmUndefined;
fModeOfOperation := moECB;
fPadding := padZeroes;
fInitVector := nil;
fInitVectorBytes := 0;
fKey := nil;
fKeyBytes := 0;
fTempBlock := nil;
fBlockBytes := 0;
end;

//------------------------------------------------------------------------------


destructor TBlockCipher.Destroy;
begin
CipherFinal;
If fBlockBytes > 0 then
  begin
    If Assigned(fInitVector) then
      FreeMem(fInitVector,fBlockBytes);
    If Assigned(fTempBlock) then
      FreeMem(fTempBlock,fBlockBytes);
  end;
If Assigned(fKey) and (fKeyBytes > 0) then
  FreeMem(fKey,fKeyBytes);
inherited;
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.Update(const Input; out Output);
begin
If fMode in [cmEncrypt,cmDecrypt] then
  fUpdateProc(Input,Output)
else
  raise Exception.CreateFmt('TBlockCipher.Update: Undefined or unknown mode (%d).',[Ord(fMode)]);
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.Final(const Input; InputSize: TMemSize; out Output);
var
  i:          Integer;
  TempBlock:  Pointer;
begin
If InputSize <= fBlockBytes then
  begin
    If InputSize < fBlockBytes then
      begin
        GetMem(TempBlock,fBlockBytes);
        try
          case fPadding of
            padPKCS7:     {PKCS#7}
              FillChar(TempBlock^,fBlockBytes,Byte(fBlockBytes - InputSize));
            padANSIX923:  {ANSI X.923}
              begin
                FillChar(TempBlock^,fBlockBytes,0);
                {%H-}PByte({%H-}PtrUInt(TempBlock) + Pred(fBlockBytes))^ := Byte(fBlockBytes - InputSize);
              end;
            padISO10126:  {ISO 10126}
              begin
              Randomize;
                For i := InputSize to Pred(fBlockBytes) do
                  {%H-}PByte({%H-}PtrUInt(TempBlock) + PtrUInt(i))^ := Byte(Random(256));
              end;
            padISOIEC7816_4:  {ISO/IEC 7816-4}
              begin
                FillChar(TempBlock^,fBlockBytes,0);
                {%H-}PByte({%H-}PtrUInt(TempBlock) + PtrUInt(InputSize))^ := $80;
              end;
          else
            {padZeroes}
            FillChar(TempBlock^,fBlockBytes,0);
          end;
          Move(Input,TempBlock^,InputSize);
          Update(TempBlock^,Output);
        finally
          FreeMem(TempBlock,fBlockBytes);
        end;
      end
    else Update(Input,Output);
  end
else raise Exception.CreateFmt('TBlockCipher.Final: Input buffer is too large (%d/%d).',[InputSize,fBlockBytes]);
end;

//------------------------------------------------------------------------------

Function TBlockCipher.OutputSize(InputSize: TMemSize): TMemSize;
begin
Result := TMemSize(Ceil(InputSize / fBlockBytes)) * fBlockBytes;
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.ProcessBytes(const Input; InputSize: TMemSize; out Output);
var
  Offset:     TMemSize;
  BytesLeft:  TMemSize;
begin
If InputSize > 0 then
  begin
    Offset := 0;
    BytesLeft := InputSize;
    DoProgress(0.0);
    while BytesLeft >= fBlockBytes do
      begin
        Update({%H-}Pointer({%H-}PtrUInt(@Input) + Offset)^,{%H-}Pointer({%H-}PtrUInt(@Output) + Offset)^);
        Dec(BytesLeft,fBlockBytes);
        Inc(Offset,fBlockBytes);
        DoProgress(Offset / InputSize);
      end;
    If BytesLeft > 0 then
      Final({%H-}Pointer({%H-}PtrUInt(@Input) + Offset)^,BytesLeft,{%H-}Pointer({%H-}PtrUInt(@Output) + Offset)^);
    DoProgress(1.0);
  end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TBlockCipher.ProcessBytes(var Buff; Size: TMemSize);
begin
ProcessBytes(Buff,Size,Buff);
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.ProcessStream(Input, Output: TStream);
var
  BuffSize:       TMemSize;
  Buffer:         Pointer;
  BytesRead:      TMemSize;
  ProgressStart:  Int64;
begin
If Input = Output then
  ProcessStream(Input)
else
  begin
    If (Input.Size - Input.Position) > 0 then
      begin
        BuffSize := fBlockBytes * BlocksPerStreamBuffer;
        GetMem(Buffer,BuffSize);
        try
          DoProgress(0.0);
          ProgressStart := Input.Position;
          repeat
            BytesRead := Input.Read(Buffer^,BuffSize);
            If BytesRead > 0 then
              begin
                ProcessBuffer(Buffer,BytesRead);
                Output.WriteBuffer(Buffer^,TMemSize(Ceil(BytesRead / fBlockBytes)) * fBlockBytes);
              end;
            DoProgress((Input.Position - ProgressStart) / (Input.Size - ProgressStart));
          until BytesRead < BuffSize;
          DoProgress(1.0);
        finally
          FreeMem(Buffer,BuffSize);
        end;
      end;
  end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TBlockCipher.ProcessStream(Stream: TStream);
var
  BuffSize:       TMemSize;
  Buffer:         Pointer;
  BytesRead:      TMemSize;
  ProgressStart:  Int64;
begin
If (Stream.Size - Stream.Position) > 0 then
  begin
    BuffSize := fBlockBytes * BlocksPerStreamBuffer;
    GetMem(Buffer,BuffSize);
    try
      DoProgress(0.0);
      ProgressStart := Stream.Position;
      repeat
        BytesRead := Stream.Read(Buffer^,BuffSize);
        If BytesRead > 0 then
          begin
            ProcessBuffer(Buffer,BytesRead);
            Stream.Seek(-Int64(BytesRead),soCurrent);
            Stream.WriteBuffer(Buffer^,TMemSize(Ceil(BytesRead / fBlockBytes)) * fBlockBytes);
          end;
        DoProgress((Stream.Position - ProgressStart) / (Stream.Size - ProgressStart));
      until BytesRead < BuffSize;
      DoProgress(1.0);
    finally
      FreeMem(Buffer,BuffSize);
    end;
  end;
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.ProcessFile(const InputFileName, OutputFileName: String);
var
  InputStream:  TFileStream;
  OutputStream: TFileStream;
begin
If AnsiSameText(InputFileName,OutputFileName) then
  ProcessFile(InputFileName)
else
  begin
    InputStream := TFileStream.Create(StrToRTL(InputFileName),fmOpenRead or fmShareDenyWrite);
    try
      OutputStream := TFileStream.Create(StrToRTL(OutputFileName),fmCreate or fmShareExclusive);
      try
        ProcessStream(InputStream,OutputStream);
      finally
        OutputStream.Free;
      end;
    finally
      InputStream.Free;
    end;
  end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TBlockCipher.ProcessFile(const FileName: String);
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenReadWrite or fmShareExclusive);
try
  ProcessStream(FileStream);
finally
  FileStream.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.ProcessAnsiString(const InputStr: AnsiString; var OutputStr: AnsiString);
begin
If PAnsiChar(InputStr) = PAnsiChar(OutputStr) then
  ProcessAnsiString(OutputStr)
else
  begin
    SetLength(OutputStr,Ceil(OutputSize(Length(InputStr) * SizeOf(AnsiChar)) / SizeOf(AnsiChar)));
    ProcessBytes(PAnsiChar(InputStr)^,Length(InputStr) * SizeOf(AnsiChar),PAnsiChar(OutputStr)^);
  end;
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.ProcessAnsiString(var Str: AnsiString);
var
  InLength: TStrSize;
begin
InLength := Length(Str);
SetLength(Str,Ceil(OutputSize(InLength * SizeOf(AnsiChar)) / SizeOf(AnsiChar)));
ProcessBytes(PAnsiChar(Str)^,InLength * SizeOf(AnsiChar));
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.ProcessWideString(const InputStr: UnicodeString; var OutputStr: UnicodeString);
begin
If PWideChar(InputStr) = PWideChar(OutputStr) then
  ProcessWideString(OutputStr)
else
  begin
    SetLength(OutputStr,Ceil(OutputSize(Length(InputStr) * SizeOf(WideChar)) / SizeOf(WideChar)));
    ProcessBytes(PWideChar(InputStr)^,Length(InputStr) * SizeOf(WideChar),PWideChar(OutputStr)^);
  end;
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.ProcessWideString(var Str: UnicodeString);
var
  InLength: TStrSize;
begin
InLength := Length(Str);
SetLength(Str,Ceil(OutputSize(InLength * SizeOf(WideChar)) / SizeOf(WideChar)));
ProcessBytes(PWideChar(Str)^,InLength * SizeOf(WideChar));
end;

//------------------------------------------------------------------------------

procedure TBlockCipher.ProcessString(const InputStr: String; var OutputStr: String);
begin
If PChar(InputStr) = PChar(OutputStr) then
  ProcessString(OutputStr)
else
  begin
    SetLength(OutputStr,Ceil(OutputSize(Length(InputStr) * SizeOf(Char)) / SizeOf(Char)));
    ProcessBytes(PChar(InputStr)^,Length(InputStr) * SizeOf(Char),PChar(OutputStr)^);
  end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TBlockCipher.ProcessString(var Str: String);
var
  InLength: TStrSize;
begin
InLength := Length(Str);
SetLength(Str,Ceil(OutputSize(InLength * SizeOf(Char)) / SizeOf(Char)));
ProcessBytes(PChar(Str)^,InLength * SizeOf(Char));
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                               TRijndaelCipher                                }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TRijndaelCipher - implementation                                           }
{==============================================================================}

{------------------------------------------------------------------------------}
{   Rijndael cipher lookup tables                                              }
{------------------------------------------------------------------------------}
{
  Majority of calculations is replaced by following lookup tables.
  Also note that current imlementation is optimized for little endian systems,
  and would not work on big endian system.

--- Original data --------------------------------------------------------------

  Rijndael substitution table:

       | 0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
    ---|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
    00 |63 7c 77 7b f2 6b 6f c5 30 01 67 2b fe d7 ab 76
    10 |ca 82 c9 7d fa 59 47 f0 ad d4 a2 af 9c a4 72 c0
    20 |b7 fd 93 26 36 3f f7 cc 34 a5 e5 f1 71 d8 31 15
    30 |04 c7 23 c3 18 96 05 9a 07 12 80 e2 eb 27 b2 75
    40 |09 83 2c 1a 1b 6e 5a a0 52 3b d6 b3 29 e3 2f 84
    50 |53 d1 00 ed 20 fc b1 5b 6a cb be 39 4a 4c 58 cf
    60 |d0 ef aa fb 43 4d 33 85 45 f9 02 7f 50 3c 9f a8
    70 |51 a3 40 8f 92 9d 38 f5 bc b6 da 21 10 ff f3 d2
    80 |cd 0c 13 ec 5f 97 44 17 c4 a7 7e 3d 64 5d 19 73
    90 |60 81 4f dc 22 2a 90 88 46 ee b8 14 de 5e 0b db
    a0 |e0 32 3a 0a 49 06 24 5c c2 d3 ac 62 91 95 e4 79
    b0 |e7 c8 37 6d 8d d5 4e a9 6c 56 f4 ea 65 7a ae 08
    c0 |ba 78 25 2e 1c a6 b4 c6 e8 dd 74 1f 4b bd 8b 8a
    d0 |70 3e b5 66 48 03 f6 0e 61 35 57 b9 86 c1 1d 9e
    e0 |e1 f8 98 11 69 d9 8e 94 9b 1e 87 e9 ce 55 28 df
    f0 |8c a1 89 0d bf e6 42 68 41 99 2d 0f b0 54 bb 16

  Rijndael inverse substitution table:

       | 0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
    ---|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
    00 |52 09 6a d5 30 36 a5 38 bf 40 a3 9e 81 f3 d7 fb
    10 |7c e3 39 82 9b 2f ff 87 34 8e 43 44 c4 de e9 cb
    20 |54 7b 94 32 a6 c2 23 3d ee 4c 95 0b 42 fa c3 4e
    30 |08 2e a1 66 28 d9 24 b2 76 5b a2 49 6d 8b d1 25
    40 |72 f8 f6 64 86 68 98 16 d4 a4 5c cc 5d 65 b6 92
    50 |6c 70 48 50 fd ed b9 da 5e 15 46 57 a7 8d 9d 84
    60 |90 d8 ab 00 8c bc d3 0a f7 e4 58 05 b8 b3 45 06
    70 |d0 2c 1e 8f ca 3f 0f 02 c1 af bd 03 01 13 8a 6b
    80 |3a 91 11 41 4f 67 dc ea 97 f2 cf ce f0 b4 e6 73
    90 |96 ac 74 22 e7 ad 35 85 e2 f9 37 e8 1c 75 df 6e
    a0 |47 f1 1a 71 1d 29 c5 89 6f b7 62 0e aa 18 be 1b
    b0 |fc 56 3e 4b c6 d2 79 20 9a db c0 fe 78 cd 5a f4
    c0 |1f dd a8 33 88 07 c7 31 b1 12 10 59 27 80 ec 5f
    d0 |60 51 7f a9 19 b5 4a 0d 2d e5 7a 9f 93 c9 9c ef
    e0 |a0 e0 3b 4d ae 2a f5 b0 c8 eb bb 3c 83 53 99 61
    f0 |17 2b 04 7e ba 77 d6 26 e1 69 14 63 55 21 0c 7d

  Rijndael Galois Multiplication lookup tables:

    (*2)
       | 0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
    ---|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
    00 |00 02 04 06 08 0a 0c 0e 10 12 14 16 18 1a 1c 1e
    10 |20 22 24 26 28 2a 2c 2e 30 32 34 36 38 3a 3c 3e
    20 |40 42 44 46 48 4a 4c 4e 50 52 54 56 58 5a 5c 5e
    30 |60 62 64 66 68 6a 6c 6e 70 72 74 76 78 7a 7c 7e
    40 |80 82 84 86 88 8a 8c 8e 90 92 94 96 98 9a 9c 9e
    50 |a0 a2 a4 a6 a8 aa ac ae b0 b2 b4 b6 b8 ba bc be
    60 |c0 c2 c4 c6 c8 ca cc ce d0 d2 d4 d6 d8 da dc de
    70 |e0 e2 e4 e6 e8 ea ec ee f0 f2 f4 f6 f8 fa fc fe
    80 |1b 19 1f 1d 13 11 17 15 0b 09 0f 0d 03 01 07 05
    90 |3b 39 3f 3d 33 31 37 35 2b 29 2f 2d 23 21 27 25
    a0 |5b 59 5f 5d 53 51 57 55 4b 49 4f 4d 43 41 47 45
    b0 |7b 79 7f 7d 73 71 77 75 6b 69 6f 6d 63 61 67 65
    c0 |9b 99 9f 9d 93 91 97 95 8b 89 8f 8d 83 81 87 85
    d0 |bb b9 bf bd b3 b1 b7 b5 ab a9 af ad a3 a1 a7 a5
    e0 |db d9 df dd d3 d1 d7 d5 cb c9 cf cd c3 c1 c7 c5
    f0 |fb f9 ff fd f3 f1 f7 f5 eb e9 ef ed e3 e1 e7 e5

    (*3)
       | 0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
    ---|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
    00 |00 03 06 05 0c 0f 0a 09 18 1b 1e 1d 14 17 12 11
    10 |30 33 36 35 3c 3f 3a 39 28 2b 2e 2d 24 27 22 21
    20 |60 63 66 65 6c 6f 6a 69 78 7b 7e 7d 74 77 72 71
    30 |50 53 56 55 5c 5f 5a 59 48 4b 4e 4d 44 47 42 41
    40 |c0 c3 c6 c5 cc cf ca c9 d8 db de dd d4 d7 d2 d1
    50 |f0 f3 f6 f5 fc ff fa f9 e8 eb ee ed e4 e7 e2 e1
    60 |a0 a3 a6 a5 ac af aa a9 b8 bb be bd b4 b7 b2 b1
    70 |90 93 96 95 9c 9f 9a 99 88 8b 8e 8d 84 87 82 81
    80 |9b 98 9d 9e 97 94 91 92 83 80 85 86 8f 8c 89 8a
    90 |ab a8 ad ae a7 a4 a1 a2 b3 b0 b5 b6 bf bc b9 ba
    a0 |fb f8 fd fe f7 f4 f1 f2 e3 e0 e5 e6 ef ec e9 ea
    b0 |cb c8 cd ce c7 c4 c1 c2 d3 d0 d5 d6 df dc d9 da
    c0 |5b 58 5d 5e 57 54 51 52 43 40 45 46 4f 4c 49 4a
    d0 |6b 68 6d 6e 67 64 61 62 73 70 75 76 7f 7c 79 7a
    e0 |3b 38 3d 3e 37 34 31 32 23 20 25 26 2f 2c 29 2a
    f0 |0b 08 0d 0e 07 04 01 02 13 10 15 16 1f 1c 19 1a

    (*9)
       | 0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
    ---|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
    00 |00 09 12 1b 24 2d 36 3f 48 41 5a 53 6c 65 7e 77
    10 |90 99 82 8b b4 bd a6 af d8 d1 ca c3 fc f5 ee e7
    20 |3b 32 29 20 1f 16 0d 04 73 7a 61 68 57 5e 45 4c
    30 |ab a2 b9 b0 8f 86 9d 94 e3 ea f1 f8 c7 ce d5 dc
    40 |76 7f 64 6d 52 5b 40 49 3e 37 2c 25 1a 13 08 01
    50 |e6 ef f4 fd c2 cb d0 d9 ae a7 bc b5 8a 83 98 91
    60 |4d 44 5f 56 69 60 7b 72 05 0c 17 1e 21 28 33 3a
    70 |dd d4 cf c6 f9 f0 eb e2 95 9c 87 8e b1 b8 a3 aa
    80 |ec e5 fe f7 c8 c1 da d3 a4 ad b6 bf 80 89 92 9b
    90 |7c 75 6e 67 58 51 4a 43 34 3d 26 2f 10 19 02 0b
    a0 |d7 de c5 cc f3 fa e1 e8 9f 96 8d 84 bb b2 a9 a0
    b0 |47 4e 55 5c 63 6a 71 78 0f 06 1d 14 2b 22 39 30
    c0 |9a 93 88 81 be b7 ac a5 d2 db c0 c9 f6 ff e4 ed
    d0 |0a 03 18 11 2e 27 3c 35 42 4b 50 59 66 6f 74 7d
    e0 |a1 a8 b3 ba 85 8c 97 9e e9 e0 fb f2 cd c4 df d6
    f0 |31 38 23 2a 15 1c 07 0e 79 70 6b 62 5d 54 4f 46

    (*11)
       | 0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
    ---|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
    00 |00 0b 16 1d 2c 27 3a 31 58 53 4e 45 74 7f 62 69
    10 |b0 bb a6 ad 9c 97 8a 81 e8 e3 fe f5 c4 cf d2 d9
    20 |7b 70 6d 66 57 5c 41 4a 23 28 35 3e 0f 04 19 12
    30 |cb c0 dd d6 e7 ec f1 fa 93 98 85 8e bf b4 a9 a2
    40 |f6 fd e0 eb da d1 cc c7 ae a5 b8 b3 82 89 94 9f
    50 |46 4d 50 5b 6a 61 7c 77 1e 15 08 03 32 39 24 2f
    60 |8d 86 9b 90 a1 aa b7 bc d5 de c3 c8 f9 f2 ef e4
    70 |3d 36 2b 20 11 1a 07 0c 65 6e 73 78 49 42 5f 54
    80 |f7 fc e1 ea db d0 cd c6 af a4 b9 b2 83 88 95 9e
    90 |47 4c 51 5a 6b 60 7d 76 1f 14 09 02 33 38 25 2e
    a0 |8c 87 9a 91 a0 ab b6 bd d4 df c2 c9 f8 f3 ee e5
    b0 |3c 37 2a 21 10 1b 06 0d 64 6f 72 79 48 43 5e 55
    c0 |01 0a 17 1c 2d 26 3b 30 59 52 4f 44 75 7e 63 68
    d0 |b1 ba a7 ac 9d 96 8b 80 e9 e2 ff f4 c5 ce d3 d8
    e0 |7a 71 6c 67 56 5d 40 4b 22 29 34 3f 0e 05 18 13
    f0 |ca c1 dc d7 e6 ed f0 fb 92 99 84 8f be b5 a8 a3

    (*13)
       | 0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
    ---|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
    00 |00 0d 1a 17 34 39 2e 23 68 65 72 7f 5c 51 46 4b
    10 |d0 dd ca c7 e4 e9 fe f3 b8 b5 a2 af 8c 81 96 9b
    20 |bb b6 a1 ac 8f 82 95 98 d3 de c9 c4 e7 ea fd f0
    30 |6b 66 71 7c 5f 52 45 48 03 0e 19 14 37 3a 2d 20
    40 |6d 60 77 7a 59 54 43 4e 05 08 1f 12 31 3c 2b 26
    50 |bd b0 a7 aa 89 84 93 9e d5 d8 cf c2 e1 ec fb f6
    60 |d6 db cc c1 e2 ef f8 f5 be b3 a4 a9 8a 87 90 9d
    70 |06 0b 1c 11 32 3f 28 25 6e 63 74 79 5a 57 40 4d
    80 |da d7 c0 cd ee e3 f4 f9 b2 bf a8 a5 86 8b 9c 91
    90 |0a 07 10 1d 3e 33 24 29 62 6f 78 75 56 5b 4c 41
    a0 |61 6c 7b 76 55 58 4f 42 09 04 13 1e 3d 30 27 2a
    b0 |b1 bc ab a6 85 88 9f 92 d9 d4 c3 ce ed e0 f7 fa
    c0 |b7 ba ad a0 83 8e 99 94 df d2 c5 c8 eb e6 f1 fc
    d0 |67 6a 7d 70 53 5e 49 44 0f 02 15 18 3b 36 21 2c
    e0 |0c 01 16 1b 38 35 22 2f 64 69 7e 73 50 5d 4a 47
    f0 |dc d1 c6 cb e8 e5 f2 ff b4 b9 ae a3 80 8d 9a 97

    (*14)
       | 0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
    ---|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
    00 |00 0e 1c 12 38 36 24 2a 70 7e 6c 62 48 46 54 5a
    10 |e0 ee fc f2 d8 d6 c4 ca 90 9e 8c 82 a8 a6 b4 ba
    20 |db d5 c7 c9 e3 ed ff f1 ab a5 b7 b9 93 9d 8f 81
    30 |3b 35 27 29 03 0d 1f 11 4b 45 57 59 73 7d 6f 61
    40 |ad a3 b1 bf 95 9b 89 87 dd d3 c1 cf e5 eb f9 f7
    50 |4d 43 51 5f 75 7b 69 67 3d 33 21 2f 05 0b 19 17
    60 |76 78 6a 64 4e 40 52 5c 06 08 1a 14 3e 30 22 2c
    70 |96 98 8a 84 ae a0 b2 bc e6 e8 fa f4 de d0 c2 cc
    80 |41 4f 5d 53 79 77 65 6b 31 3f 2d 23 09 07 15 1b
    90 |a1 af bd b3 99 97 85 8b d1 df cd c3 e9 e7 f5 fb
    a0 |9a 94 86 88 a2 ac be b0 ea e4 f6 f8 d2 dc ce c0
    b0 |7a 74 66 68 42 4c 5e 50 0a 04 16 18 32 3c 2e 20
    c0 |ec e2 f0 fe d4 da c8 c6 9c 92 80 8e a4 aa b8 b6
    d0 |0c 02 10 1e 34 3a 28 26 7c 72 60 6e 44 4a 58 56
    e0 |37 39 2b 25 0f 01 13 1d 47 49 5b 55 7f 71 63 6d
    f0 |d7 d9 cb c5 ef e1 f3 fd a7 a9 bb b5 9f 91 83 8d

--- Constructing decryption tables ---------------------------------------------

  See methods Encrypt and Decrypt for detailed description of why and how the
  following tables are created.
}
const
{-- Encryption lookup tables --------------------------------------------------}

  EncTab1: array[Byte] of TRijWord = (
    $A56363C6, $847C7CF8, $997777EE, $8D7B7BF6, $0DF2F2FF, $BD6B6BD6, $B16F6FDE, $54C5C591,
    $50303060, $03010102, $A96767CE, $7D2B2B56, $19FEFEE7, $62D7D7B5, $E6ABAB4D, $9A7676EC,
    $45CACA8F, $9D82821F, $40C9C989, $877D7DFA, $15FAFAEF, $EB5959B2, $C947478E, $0BF0F0FB,
    $ECADAD41, $67D4D4B3, $FDA2A25F, $EAAFAF45, $BF9C9C23, $F7A4A453, $967272E4, $5BC0C09B,
    $C2B7B775, $1CFDFDE1, $AE93933D, $6A26264C, $5A36366C, $413F3F7E, $02F7F7F5, $4FCCCC83,
    $5C343468, $F4A5A551, $34E5E5D1, $08F1F1F9, $937171E2, $73D8D8AB, $53313162, $3F15152A,
    $0C040408, $52C7C795, $65232346, $5EC3C39D, $28181830, $A1969637, $0F05050A, $B59A9A2F,
    $0907070E, $36121224, $9B80801B, $3DE2E2DF, $26EBEBCD, $6927274E, $CDB2B27F, $9F7575EA,
    $1B090912, $9E83831D, $742C2C58, $2E1A1A34, $2D1B1B36, $B26E6EDC, $EE5A5AB4, $FBA0A05B,
    $F65252A4, $4D3B3B76, $61D6D6B7, $CEB3B37D, $7B292952, $3EE3E3DD, $712F2F5E, $97848413,
    $F55353A6, $68D1D1B9, $00000000, $2CEDEDC1, $60202040, $1FFCFCE3, $C8B1B179, $ED5B5BB6,
    $BE6A6AD4, $46CBCB8D, $D9BEBE67, $4B393972, $DE4A4A94, $D44C4C98, $E85858B0, $4ACFCF85,
    $6BD0D0BB, $2AEFEFC5, $E5AAAA4F, $16FBFBED, $C5434386, $D74D4D9A, $55333366, $94858511,
    $CF45458A, $10F9F9E9, $06020204, $817F7FFE, $F05050A0, $443C3C78, $BA9F9F25, $E3A8A84B,
    $F35151A2, $FEA3A35D, $C0404080, $8A8F8F05, $AD92923F, $BC9D9D21, $48383870, $04F5F5F1,
    $DFBCBC63, $C1B6B677, $75DADAAF, $63212142, $30101020, $1AFFFFE5, $0EF3F3FD, $6DD2D2BF,
    $4CCDCD81, $140C0C18, $35131326, $2FECECC3, $E15F5FBE, $A2979735, $CC444488, $3917172E,
    $57C4C493, $F2A7A755, $827E7EFC, $473D3D7A, $AC6464C8, $E75D5DBA, $2B191932, $957373E6,
    $A06060C0, $98818119, $D14F4F9E, $7FDCDCA3, $66222244, $7E2A2A54, $AB90903B, $8388880B,
    $CA46468C, $29EEEEC7, $D3B8B86B, $3C141428, $79DEDEA7, $E25E5EBC, $1D0B0B16, $76DBDBAD,
    $3BE0E0DB, $56323264, $4E3A3A74, $1E0A0A14, $DB494992, $0A06060C, $6C242448, $E45C5CB8,
    $5DC2C29F, $6ED3D3BD, $EFACAC43, $A66262C4, $A8919139, $A4959531, $37E4E4D3, $8B7979F2,
    $32E7E7D5, $43C8C88B, $5937376E, $B76D6DDA, $8C8D8D01, $64D5D5B1, $D24E4E9C, $E0A9A949,
    $B46C6CD8, $FA5656AC, $07F4F4F3, $25EAEACF, $AF6565CA, $8E7A7AF4, $E9AEAE47, $18080810,
    $D5BABA6F, $887878F0, $6F25254A, $722E2E5C, $241C1C38, $F1A6A657, $C7B4B473, $51C6C697,
    $23E8E8CB, $7CDDDDA1, $9C7474E8, $211F1F3E, $DD4B4B96, $DCBDBD61, $868B8B0D, $858A8A0F,
    $907070E0, $423E3E7C, $C4B5B571, $AA6666CC, $D8484890, $05030306, $01F6F6F7, $120E0E1C,
    $A36161C2, $5F35356A, $F95757AE, $D0B9B969, $91868617, $58C1C199, $271D1D3A, $B99E9E27,
    $38E1E1D9, $13F8F8EB, $B398982B, $33111122, $BB6969D2, $70D9D9A9, $898E8E07, $A7949433,
    $B69B9B2D, $221E1E3C, $92878715, $20E9E9C9, $49CECE87, $FF5555AA, $78282850, $7ADFDFA5,
    $8F8C8C03, $F8A1A159, $80898909, $170D0D1A, $DABFBF65, $31E6E6D7, $C6424284, $B86868D0,
    $C3414182, $B0999929, $772D2D5A, $110F0F1E, $CBB0B07B, $FC5454A8, $D6BBBB6D, $3A16162C);

  EncTab2: array[Byte] of TRijWord = (
    $6363C6A5, $7C7CF884, $7777EE99, $7B7BF68D, $F2F2FF0D, $6B6BD6BD, $6F6FDEB1, $C5C59154,
    $30306050, $01010203, $6767CEA9, $2B2B567D, $FEFEE719, $D7D7B562, $ABAB4DE6, $7676EC9A,
    $CACA8F45, $82821F9D, $C9C98940, $7D7DFA87, $FAFAEF15, $5959B2EB, $47478EC9, $F0F0FB0B,
    $ADAD41EC, $D4D4B367, $A2A25FFD, $AFAF45EA, $9C9C23BF, $A4A453F7, $7272E496, $C0C09B5B,
    $B7B775C2, $FDFDE11C, $93933DAE, $26264C6A, $36366C5A, $3F3F7E41, $F7F7F502, $CCCC834F,
    $3434685C, $A5A551F4, $E5E5D134, $F1F1F908, $7171E293, $D8D8AB73, $31316253, $15152A3F,
    $0404080C, $C7C79552, $23234665, $C3C39D5E, $18183028, $969637A1, $05050A0F, $9A9A2FB5,
    $07070E09, $12122436, $80801B9B, $E2E2DF3D, $EBEBCD26, $27274E69, $B2B27FCD, $7575EA9F,
    $0909121B, $83831D9E, $2C2C5874, $1A1A342E, $1B1B362D, $6E6EDCB2, $5A5AB4EE, $A0A05BFB,
    $5252A4F6, $3B3B764D, $D6D6B761, $B3B37DCE, $2929527B, $E3E3DD3E, $2F2F5E71, $84841397,
    $5353A6F5, $D1D1B968, $00000000, $EDEDC12C, $20204060, $FCFCE31F, $B1B179C8, $5B5BB6ED,
    $6A6AD4BE, $CBCB8D46, $BEBE67D9, $3939724B, $4A4A94DE, $4C4C98D4, $5858B0E8, $CFCF854A,
    $D0D0BB6B, $EFEFC52A, $AAAA4FE5, $FBFBED16, $434386C5, $4D4D9AD7, $33336655, $85851194,
    $45458ACF, $F9F9E910, $02020406, $7F7FFE81, $5050A0F0, $3C3C7844, $9F9F25BA, $A8A84BE3,
    $5151A2F3, $A3A35DFE, $404080C0, $8F8F058A, $92923FAD, $9D9D21BC, $38387048, $F5F5F104,
    $BCBC63DF, $B6B677C1, $DADAAF75, $21214263, $10102030, $FFFFE51A, $F3F3FD0E, $D2D2BF6D,
    $CDCD814C, $0C0C1814, $13132635, $ECECC32F, $5F5FBEE1, $979735A2, $444488CC, $17172E39,
    $C4C49357, $A7A755F2, $7E7EFC82, $3D3D7A47, $6464C8AC, $5D5DBAE7, $1919322B, $7373E695,
    $6060C0A0, $81811998, $4F4F9ED1, $DCDCA37F, $22224466, $2A2A547E, $90903BAB, $88880B83,
    $46468CCA, $EEEEC729, $B8B86BD3, $1414283C, $DEDEA779, $5E5EBCE2, $0B0B161D, $DBDBAD76,
    $E0E0DB3B, $32326456, $3A3A744E, $0A0A141E, $494992DB, $06060C0A, $2424486C, $5C5CB8E4,
    $C2C29F5D, $D3D3BD6E, $ACAC43EF, $6262C4A6, $919139A8, $959531A4, $E4E4D337, $7979F28B,
    $E7E7D532, $C8C88B43, $37376E59, $6D6DDAB7, $8D8D018C, $D5D5B164, $4E4E9CD2, $A9A949E0,
    $6C6CD8B4, $5656ACFA, $F4F4F307, $EAEACF25, $6565CAAF, $7A7AF48E, $AEAE47E9, $08081018,
    $BABA6FD5, $7878F088, $25254A6F, $2E2E5C72, $1C1C3824, $A6A657F1, $B4B473C7, $C6C69751,
    $E8E8CB23, $DDDDA17C, $7474E89C, $1F1F3E21, $4B4B96DD, $BDBD61DC, $8B8B0D86, $8A8A0F85,
    $7070E090, $3E3E7C42, $B5B571C4, $6666CCAA, $484890D8, $03030605, $F6F6F701, $0E0E1C12,
    $6161C2A3, $35356A5F, $5757AEF9, $B9B969D0, $86861791, $C1C19958, $1D1D3A27, $9E9E27B9,
    $E1E1D938, $F8F8EB13, $98982BB3, $11112233, $6969D2BB, $D9D9A970, $8E8E0789, $949433A7,
    $9B9B2DB6, $1E1E3C22, $87871592, $E9E9C920, $CECE8749, $5555AAFF, $28285078, $DFDFA57A,
    $8C8C038F, $A1A159F8, $89890980, $0D0D1A17, $BFBF65DA, $E6E6D731, $424284C6, $6868D0B8,
    $414182C3, $999929B0, $2D2D5A77, $0F0F1E11, $B0B07BCB, $5454A8FC, $BBBB6DD6, $16162C3A);

  EncTab3: array[Byte] of TRijWord = (
    $63C6A563, $7CF8847C, $77EE9977, $7BF68D7B, $F2FF0DF2, $6BD6BD6B, $6FDEB16F, $C59154C5,
    $30605030, $01020301, $67CEA967, $2B567D2B, $FEE719FE, $D7B562D7, $AB4DE6AB, $76EC9A76,
    $CA8F45CA, $821F9D82, $C98940C9, $7DFA877D, $FAEF15FA, $59B2EB59, $478EC947, $F0FB0BF0,
    $AD41ECAD, $D4B367D4, $A25FFDA2, $AF45EAAF, $9C23BF9C, $A453F7A4, $72E49672, $C09B5BC0,
    $B775C2B7, $FDE11CFD, $933DAE93, $264C6A26, $366C5A36, $3F7E413F, $F7F502F7, $CC834FCC,
    $34685C34, $A551F4A5, $E5D134E5, $F1F908F1, $71E29371, $D8AB73D8, $31625331, $152A3F15,
    $04080C04, $C79552C7, $23466523, $C39D5EC3, $18302818, $9637A196, $050A0F05, $9A2FB59A,
    $070E0907, $12243612, $801B9B80, $E2DF3DE2, $EBCD26EB, $274E6927, $B27FCDB2, $75EA9F75,
    $09121B09, $831D9E83, $2C58742C, $1A342E1A, $1B362D1B, $6EDCB26E, $5AB4EE5A, $A05BFBA0,
    $52A4F652, $3B764D3B, $D6B761D6, $B37DCEB3, $29527B29, $E3DD3EE3, $2F5E712F, $84139784,
    $53A6F553, $D1B968D1, $00000000, $EDC12CED, $20406020, $FCE31FFC, $B179C8B1, $5BB6ED5B,
    $6AD4BE6A, $CB8D46CB, $BE67D9BE, $39724B39, $4A94DE4A, $4C98D44C, $58B0E858, $CF854ACF,
    $D0BB6BD0, $EFC52AEF, $AA4FE5AA, $FBED16FB, $4386C543, $4D9AD74D, $33665533, $85119485,
    $458ACF45, $F9E910F9, $02040602, $7FFE817F, $50A0F050, $3C78443C, $9F25BA9F, $A84BE3A8,
    $51A2F351, $A35DFEA3, $4080C040, $8F058A8F, $923FAD92, $9D21BC9D, $38704838, $F5F104F5,
    $BC63DFBC, $B677C1B6, $DAAF75DA, $21426321, $10203010, $FFE51AFF, $F3FD0EF3, $D2BF6DD2,
    $CD814CCD, $0C18140C, $13263513, $ECC32FEC, $5FBEE15F, $9735A297, $4488CC44, $172E3917,
    $C49357C4, $A755F2A7, $7EFC827E, $3D7A473D, $64C8AC64, $5DBAE75D, $19322B19, $73E69573,
    $60C0A060, $81199881, $4F9ED14F, $DCA37FDC, $22446622, $2A547E2A, $903BAB90, $880B8388,
    $468CCA46, $EEC729EE, $B86BD3B8, $14283C14, $DEA779DE, $5EBCE25E, $0B161D0B, $DBAD76DB,
    $E0DB3BE0, $32645632, $3A744E3A, $0A141E0A, $4992DB49, $060C0A06, $24486C24, $5CB8E45C,
    $C29F5DC2, $D3BD6ED3, $AC43EFAC, $62C4A662, $9139A891, $9531A495, $E4D337E4, $79F28B79,
    $E7D532E7, $C88B43C8, $376E5937, $6DDAB76D, $8D018C8D, $D5B164D5, $4E9CD24E, $A949E0A9,
    $6CD8B46C, $56ACFA56, $F4F307F4, $EACF25EA, $65CAAF65, $7AF48E7A, $AE47E9AE, $08101808,
    $BA6FD5BA, $78F08878, $254A6F25, $2E5C722E, $1C38241C, $A657F1A6, $B473C7B4, $C69751C6,
    $E8CB23E8, $DDA17CDD, $74E89C74, $1F3E211F, $4B96DD4B, $BD61DCBD, $8B0D868B, $8A0F858A,
    $70E09070, $3E7C423E, $B571C4B5, $66CCAA66, $4890D848, $03060503, $F6F701F6, $0E1C120E,
    $61C2A361, $356A5F35, $57AEF957, $B969D0B9, $86179186, $C19958C1, $1D3A271D, $9E27B99E,
    $E1D938E1, $F8EB13F8, $982BB398, $11223311, $69D2BB69, $D9A970D9, $8E07898E, $9433A794,
    $9B2DB69B, $1E3C221E, $87159287, $E9C920E9, $CE8749CE, $55AAFF55, $28507828, $DFA57ADF,
    $8C038F8C, $A159F8A1, $89098089, $0D1A170D, $BF65DABF, $E6D731E6, $4284C642, $68D0B868,
    $4182C341, $9929B099, $2D5A772D, $0F1E110F, $B07BCBB0, $54A8FC54, $BB6DD6BB, $162C3A16);

  EncTab4: array[Byte] of TRijWord = (
    $C6A56363, $F8847C7C, $EE997777, $F68D7B7B, $FF0DF2F2, $D6BD6B6B, $DEB16F6F, $9154C5C5,
    $60503030, $02030101, $CEA96767, $567D2B2B, $E719FEFE, $B562D7D7, $4DE6ABAB, $EC9A7676,
    $8F45CACA, $1F9D8282, $8940C9C9, $FA877D7D, $EF15FAFA, $B2EB5959, $8EC94747, $FB0BF0F0,
    $41ECADAD, $B367D4D4, $5FFDA2A2, $45EAAFAF, $23BF9C9C, $53F7A4A4, $E4967272, $9B5BC0C0,
    $75C2B7B7, $E11CFDFD, $3DAE9393, $4C6A2626, $6C5A3636, $7E413F3F, $F502F7F7, $834FCCCC,
    $685C3434, $51F4A5A5, $D134E5E5, $F908F1F1, $E2937171, $AB73D8D8, $62533131, $2A3F1515,
    $080C0404, $9552C7C7, $46652323, $9D5EC3C3, $30281818, $37A19696, $0A0F0505, $2FB59A9A,
    $0E090707, $24361212, $1B9B8080, $DF3DE2E2, $CD26EBEB, $4E692727, $7FCDB2B2, $EA9F7575,
    $121B0909, $1D9E8383, $58742C2C, $342E1A1A, $362D1B1B, $DCB26E6E, $B4EE5A5A, $5BFBA0A0,
    $A4F65252, $764D3B3B, $B761D6D6, $7DCEB3B3, $527B2929, $DD3EE3E3, $5E712F2F, $13978484,
    $A6F55353, $B968D1D1, $00000000, $C12CEDED, $40602020, $E31FFCFC, $79C8B1B1, $B6ED5B5B,
    $D4BE6A6A, $8D46CBCB, $67D9BEBE, $724B3939, $94DE4A4A, $98D44C4C, $B0E85858, $854ACFCF,
    $BB6BD0D0, $C52AEFEF, $4FE5AAAA, $ED16FBFB, $86C54343, $9AD74D4D, $66553333, $11948585,
    $8ACF4545, $E910F9F9, $04060202, $FE817F7F, $A0F05050, $78443C3C, $25BA9F9F, $4BE3A8A8,
    $A2F35151, $5DFEA3A3, $80C04040, $058A8F8F, $3FAD9292, $21BC9D9D, $70483838, $F104F5F5,
    $63DFBCBC, $77C1B6B6, $AF75DADA, $42632121, $20301010, $E51AFFFF, $FD0EF3F3, $BF6DD2D2,
    $814CCDCD, $18140C0C, $26351313, $C32FECEC, $BEE15F5F, $35A29797, $88CC4444, $2E391717,
    $9357C4C4, $55F2A7A7, $FC827E7E, $7A473D3D, $C8AC6464, $BAE75D5D, $322B1919, $E6957373,
    $C0A06060, $19988181, $9ED14F4F, $A37FDCDC, $44662222, $547E2A2A, $3BAB9090, $0B838888,
    $8CCA4646, $C729EEEE, $6BD3B8B8, $283C1414, $A779DEDE, $BCE25E5E, $161D0B0B, $AD76DBDB,
    $DB3BE0E0, $64563232, $744E3A3A, $141E0A0A, $92DB4949, $0C0A0606, $486C2424, $B8E45C5C,
    $9F5DC2C2, $BD6ED3D3, $43EFACAC, $C4A66262, $39A89191, $31A49595, $D337E4E4, $F28B7979,
    $D532E7E7, $8B43C8C8, $6E593737, $DAB76D6D, $018C8D8D, $B164D5D5, $9CD24E4E, $49E0A9A9,
    $D8B46C6C, $ACFA5656, $F307F4F4, $CF25EAEA, $CAAF6565, $F48E7A7A, $47E9AEAE, $10180808,
    $6FD5BABA, $F0887878, $4A6F2525, $5C722E2E, $38241C1C, $57F1A6A6, $73C7B4B4, $9751C6C6,
    $CB23E8E8, $A17CDDDD, $E89C7474, $3E211F1F, $96DD4B4B, $61DCBDBD, $0D868B8B, $0F858A8A,
    $E0907070, $7C423E3E, $71C4B5B5, $CCAA6666, $90D84848, $06050303, $F701F6F6, $1C120E0E,
    $C2A36161, $6A5F3535, $AEF95757, $69D0B9B9, $17918686, $9958C1C1, $3A271D1D, $27B99E9E,
    $D938E1E1, $EB13F8F8, $2BB39898, $22331111, $D2BB6969, $A970D9D9, $07898E8E, $33A79494,
    $2DB69B9B, $3C221E1E, $15928787, $C920E9E9, $8749CECE, $AAFF5555, $50782828, $A57ADFDF,
    $038F8C8C, $59F8A1A1, $09808989, $1A170D0D, $65DABFBF, $D731E6E6, $84C64242, $D0B86868,
    $82C34141, $29B09999, $5A772D2D, $1E110F0F, $7BCBB0B0, $A8FC5454, $6DD6BBBB, $2C3A1616);

{-- Decryption lookup tables --------------------------------------------------}

  DecTab1: array[Byte] of TRijWord = (
    $50A7F451, $5365417E, $C3A4171A, $965E273A, $CB6BAB3B, $F1459D1F, $AB58FAAC, $9303E34B,
    $55FA3020, $F66D76AD, $9176CC88, $254C02F5, $FCD7E54F, $D7CB2AC5, $80443526, $8FA362B5,
    $495AB1DE, $671BBA25, $980EEA45, $E1C0FE5D, $02752FC3, $12F04C81, $A397468D, $C6F9D36B,
    $E75F8F03, $959C9215, $EB7A6DBF, $DA595295, $2D83BED4, $D3217458, $2969E049, $44C8C98E,
    $6A89C275, $78798EF4, $6B3E5899, $DD71B927, $B64FE1BE, $17AD88F0, $66AC20C9, $B43ACE7D,
    $184ADF63, $82311AE5, $60335197, $457F5362, $E07764B1, $84AE6BBB, $1CA081FE, $942B08F9,
    $58684870, $19FD458F, $876CDE94, $B7F87B52, $23D373AB, $E2024B72, $578F1FE3, $2AAB5566,
    $0728EBB2, $03C2B52F, $9A7BC586, $A50837D3, $F2872830, $B2A5BF23, $BA6A0302, $5C8216ED,
    $2B1CCF8A, $92B479A7, $F0F207F3, $A1E2694E, $CDF4DA65, $D5BE0506, $1F6234D1, $8AFEA6C4,
    $9D532E34, $A055F3A2, $32E18A05, $75EBF6A4, $39EC830B, $AAEF6040, $069F715E, $51106EBD,
    $F98A213E, $3D06DD96, $AE053EDD, $46BDE64D, $B58D5491, $055DC471, $6FD40604, $FF155060,
    $24FB9819, $97E9BDD6, $CC434089, $779ED967, $BD42E8B0, $888B8907, $385B19E7, $DBEEC879,
    $470A7CA1, $E90F427C, $C91E84F8, $00000000, $83868009, $48ED2B32, $AC70111E, $4E725A6C,
    $FBFF0EFD, $5638850F, $1ED5AE3D, $27392D36, $64D90F0A, $21A65C68, $D1545B9B, $3A2E3624,
    $B1670A0C, $0FE75793, $D296EEB4, $9E919B1B, $4FC5C080, $A220DC61, $694B775A, $161A121C,
    $0ABA93E2, $E52AA0C0, $43E0223C, $1D171B12, $0B0D090E, $ADC78BF2, $B9A8B62D, $C8A91E14,
    $8519F157, $4C0775AF, $BBDD99EE, $FD607FA3, $9F2601F7, $BCF5725C, $C53B6644, $347EFB5B,
    $7629438B, $DCC623CB, $68FCEDB6, $63F1E4B8, $CADC31D7, $10856342, $40229713, $2011C684,
    $7D244A85, $F83DBBD2, $1132F9AE, $6DA129C7, $4B2F9E1D, $F330B2DC, $EC52860D, $D0E3C177,
    $6C16B32B, $99B970A9, $FA489411, $2264E947, $C48CFCA8, $1A3FF0A0, $D82C7D56, $EF903322,
    $C74E4987, $C1D138D9, $FEA2CA8C, $360BD498, $CF81F5A6, $28DE7AA5, $268EB7DA, $A4BFAD3F,
    $E49D3A2C, $0D927850, $9BCC5F6A, $62467E54, $C2138DF6, $E8B8D890, $5EF7392E, $F5AFC382,
    $BE805D9F, $7C93D069, $A92DD56F, $B31225CF, $3B99ACC8, $A77D1810, $6E639CE8, $7BBB3BDB,
    $097826CD, $F418596E, $01B79AEC, $A89A4F83, $656E95E6, $7EE6FFAA, $08CFBC21, $E6E815EF,
    $D99BE7BA, $CE366F4A, $D4099FEA, $D67CB029, $AFB2A431, $31233F2A, $3094A5C6, $C066A235,
    $37BC4E74, $A6CA82FC, $B0D090E0, $15D8A733, $4A9804F1, $F7DAEC41, $0E50CD7F, $2FF69117,
    $8DD64D76, $4DB0EF43, $544DAACC, $DF0496E4, $E3B5D19E, $1B886A4C, $B81F2CC1, $7F516546,
    $04EA5E9D, $5D358C01, $737487FA, $2E410BFB, $5A1D67B3, $52D2DB92, $335610E9, $1347D66D,
    $8C61D79A, $7A0CA137, $8E14F859, $893C13EB, $EE27A9CE, $35C961B7, $EDE51CE1, $3CB1477A,
    $59DFD29C, $3F73F255, $79CE1418, $BF37C773, $EACDF753, $5BAAFD5F, $146F3DDF, $86DB4478,
    $81F3AFCA, $3EC468B9, $2C342438, $5F40A3C2, $72C31D16, $0C25E2BC, $8B493C28, $41950DFF,
    $7101A839, $DEB30C08, $9CE4B4D8, $90C15664, $6184CB7B, $70B632D5, $745C6C48, $4257B8D0);

  DecTab2: array[Byte] of TRijWord = (
    $A7F45150, $65417E53, $A4171AC3, $5E273A96, $6BAB3BCB, $459D1FF1, $58FAACAB, $03E34B93,
    $FA302055, $6D76ADF6, $76CC8891, $4C02F525, $D7E54FFC, $CB2AC5D7, $44352680, $A362B58F,
    $5AB1DE49, $1BBA2567, $0EEA4598, $C0FE5DE1, $752FC302, $F04C8112, $97468DA3, $F9D36BC6,
    $5F8F03E7, $9C921595, $7A6DBFEB, $595295DA, $83BED42D, $217458D3, $69E04929, $C8C98E44,
    $89C2756A, $798EF478, $3E58996B, $71B927DD, $4FE1BEB6, $AD88F017, $AC20C966, $3ACE7DB4,
    $4ADF6318, $311AE582, $33519760, $7F536245, $7764B1E0, $AE6BBB84, $A081FE1C, $2B08F994,
    $68487058, $FD458F19, $6CDE9487, $F87B52B7, $D373AB23, $024B72E2, $8F1FE357, $AB55662A,
    $28EBB207, $C2B52F03, $7BC5869A, $0837D3A5, $872830F2, $A5BF23B2, $6A0302BA, $8216ED5C,
    $1CCF8A2B, $B479A792, $F207F3F0, $E2694EA1, $F4DA65CD, $BE0506D5, $6234D11F, $FEA6C48A,
    $532E349D, $55F3A2A0, $E18A0532, $EBF6A475, $EC830B39, $EF6040AA, $9F715E06, $106EBD51,
    $8A213EF9, $06DD963D, $053EDDAE, $BDE64D46, $8D5491B5, $5DC47105, $D406046F, $155060FF,
    $FB981924, $E9BDD697, $434089CC, $9ED96777, $42E8B0BD, $8B890788, $5B19E738, $EEC879DB,
    $0A7CA147, $0F427CE9, $1E84F8C9, $00000000, $86800983, $ED2B3248, $70111EAC, $725A6C4E,
    $FF0EFDFB, $38850F56, $D5AE3D1E, $392D3627, $D90F0A64, $A65C6821, $545B9BD1, $2E36243A,
    $670A0CB1, $E757930F, $96EEB4D2, $919B1B9E, $C5C0804F, $20DC61A2, $4B775A69, $1A121C16,
    $BA93E20A, $2AA0C0E5, $E0223C43, $171B121D, $0D090E0B, $C78BF2AD, $A8B62DB9, $A91E14C8,
    $19F15785, $0775AF4C, $DD99EEBB, $607FA3FD, $2601F79F, $F5725CBC, $3B6644C5, $7EFB5B34,
    $29438B76, $C623CBDC, $FCEDB668, $F1E4B863, $DC31D7CA, $85634210, $22971340, $11C68420,
    $244A857D, $3DBBD2F8, $32F9AE11, $A129C76D, $2F9E1D4B, $30B2DCF3, $52860DEC, $E3C177D0,
    $16B32B6C, $B970A999, $489411FA, $64E94722, $8CFCA8C4, $3FF0A01A, $2C7D56D8, $903322EF,
    $4E4987C7, $D138D9C1, $A2CA8CFE, $0BD49836, $81F5A6CF, $DE7AA528, $8EB7DA26, $BFAD3FA4,
    $9D3A2CE4, $9278500D, $CC5F6A9B, $467E5462, $138DF6C2, $B8D890E8, $F7392E5E, $AFC382F5,
    $805D9FBE, $93D0697C, $2DD56FA9, $1225CFB3, $99ACC83B, $7D1810A7, $639CE86E, $BB3BDB7B,
    $7826CD09, $18596EF4, $B79AEC01, $9A4F83A8, $6E95E665, $E6FFAA7E, $CFBC2108, $E815EFE6,
    $9BE7BAD9, $366F4ACE, $099FEAD4, $7CB029D6, $B2A431AF, $233F2A31, $94A5C630, $66A235C0,
    $BC4E7437, $CA82FCA6, $D090E0B0, $D8A73315, $9804F14A, $DAEC41F7, $50CD7F0E, $F691172F,
    $D64D768D, $B0EF434D, $4DAACC54, $0496E4DF, $B5D19EE3, $886A4C1B, $1F2CC1B8, $5165467F,
    $EA5E9D04, $358C015D, $7487FA73, $410BFB2E, $1D67B35A, $D2DB9252, $5610E933, $47D66D13,
    $61D79A8C, $0CA1377A, $14F8598E, $3C13EB89, $27A9CEEE, $C961B735, $E51CE1ED, $B1477A3C,
    $DFD29C59, $73F2553F, $CE141879, $37C773BF, $CDF753EA, $AAFD5F5B, $6F3DDF14, $DB447886,
    $F3AFCA81, $C468B93E, $3424382C, $40A3C25F, $C31D1672, $25E2BC0C, $493C288B, $950DFF41,
    $01A83971, $B30C08DE, $E4B4D89C, $C1566490, $84CB7B61, $B632D570, $5C6C4874, $57B8D042);

  DecTab3: array[Byte] of TRijWord = (
    $F45150A7, $417E5365, $171AC3A4, $273A965E, $AB3BCB6B, $9D1FF145, $FAACAB58, $E34B9303,
    $302055FA, $76ADF66D, $CC889176, $02F5254C, $E54FFCD7, $2AC5D7CB, $35268044, $62B58FA3,
    $B1DE495A, $BA25671B, $EA45980E, $FE5DE1C0, $2FC30275, $4C8112F0, $468DA397, $D36BC6F9,
    $8F03E75F, $9215959C, $6DBFEB7A, $5295DA59, $BED42D83, $7458D321, $E0492969, $C98E44C8,
    $C2756A89, $8EF47879, $58996B3E, $B927DD71, $E1BEB64F, $88F017AD, $20C966AC, $CE7DB43A,
    $DF63184A, $1AE58231, $51976033, $5362457F, $64B1E077, $6BBB84AE, $81FE1CA0, $08F9942B,
    $48705868, $458F19FD, $DE94876C, $7B52B7F8, $73AB23D3, $4B72E202, $1FE3578F, $55662AAB,
    $EBB20728, $B52F03C2, $C5869A7B, $37D3A508, $2830F287, $BF23B2A5, $0302BA6A, $16ED5C82,
    $CF8A2B1C, $79A792B4, $07F3F0F2, $694EA1E2, $DA65CDF4, $0506D5BE, $34D11F62, $A6C48AFE,
    $2E349D53, $F3A2A055, $8A0532E1, $F6A475EB, $830B39EC, $6040AAEF, $715E069F, $6EBD5110,
    $213EF98A, $DD963D06, $3EDDAE05, $E64D46BD, $5491B58D, $C471055D, $06046FD4, $5060FF15,
    $981924FB, $BDD697E9, $4089CC43, $D967779E, $E8B0BD42, $8907888B, $19E7385B, $C879DBEE,
    $7CA1470A, $427CE90F, $84F8C91E, $00000000, $80098386, $2B3248ED, $111EAC70, $5A6C4E72,
    $0EFDFBFF, $850F5638, $AE3D1ED5, $2D362739, $0F0A64D9, $5C6821A6, $5B9BD154, $36243A2E,
    $0A0CB167, $57930FE7, $EEB4D296, $9B1B9E91, $C0804FC5, $DC61A220, $775A694B, $121C161A,
    $93E20ABA, $A0C0E52A, $223C43E0, $1B121D17, $090E0B0D, $8BF2ADC7, $B62DB9A8, $1E14C8A9,
    $F1578519, $75AF4C07, $99EEBBDD, $7FA3FD60, $01F79F26, $725CBCF5, $6644C53B, $FB5B347E,
    $438B7629, $23CBDCC6, $EDB668FC, $E4B863F1, $31D7CADC, $63421085, $97134022, $C6842011,
    $4A857D24, $BBD2F83D, $F9AE1132, $29C76DA1, $9E1D4B2F, $B2DCF330, $860DEC52, $C177D0E3,
    $B32B6C16, $70A999B9, $9411FA48, $E9472264, $FCA8C48C, $F0A01A3F, $7D56D82C, $3322EF90,
    $4987C74E, $38D9C1D1, $CA8CFEA2, $D498360B, $F5A6CF81, $7AA528DE, $B7DA268E, $AD3FA4BF,
    $3A2CE49D, $78500D92, $5F6A9BCC, $7E546246, $8DF6C213, $D890E8B8, $392E5EF7, $C382F5AF,
    $5D9FBE80, $D0697C93, $D56FA92D, $25CFB312, $ACC83B99, $1810A77D, $9CE86E63, $3BDB7BBB,
    $26CD0978, $596EF418, $9AEC01B7, $4F83A89A, $95E6656E, $FFAA7EE6, $BC2108CF, $15EFE6E8,
    $E7BAD99B, $6F4ACE36, $9FEAD409, $B029D67C, $A431AFB2, $3F2A3123, $A5C63094, $A235C066,
    $4E7437BC, $82FCA6CA, $90E0B0D0, $A73315D8, $04F14A98, $EC41F7DA, $CD7F0E50, $91172FF6,
    $4D768DD6, $EF434DB0, $AACC544D, $96E4DF04, $D19EE3B5, $6A4C1B88, $2CC1B81F, $65467F51,
    $5E9D04EA, $8C015D35, $87FA7374, $0BFB2E41, $67B35A1D, $DB9252D2, $10E93356, $D66D1347,
    $D79A8C61, $A1377A0C, $F8598E14, $13EB893C, $A9CEEE27, $61B735C9, $1CE1EDE5, $477A3CB1,
    $D29C59DF, $F2553F73, $141879CE, $C773BF37, $F753EACD, $FD5F5BAA, $3DDF146F, $447886DB,
    $AFCA81F3, $68B93EC4, $24382C34, $A3C25F40, $1D1672C3, $E2BC0C25, $3C288B49, $0DFF4195,
    $A8397101, $0C08DEB3, $B4D89CE4, $566490C1, $CB7B6184, $32D570B6, $6C48745C, $B8D04257);

  DecTab4: array[Byte] of TRijWord = (                                                    
    $5150A7F4, $7E536541, $1AC3A417, $3A965E27, $3BCB6BAB, $1FF1459D, $ACAB58FA, $4B9303E3,
    $2055FA30, $ADF66D76, $889176CC, $F5254C02, $4FFCD7E5, $C5D7CB2A, $26804435, $B58FA362,
    $DE495AB1, $25671BBA, $45980EEA, $5DE1C0FE, $C302752F, $8112F04C, $8DA39746, $6BC6F9D3,
    $03E75F8F, $15959C92, $BFEB7A6D, $95DA5952, $D42D83BE, $58D32174, $492969E0, $8E44C8C9,
    $756A89C2, $F478798E, $996B3E58, $27DD71B9, $BEB64FE1, $F017AD88, $C966AC20, $7DB43ACE,
    $63184ADF, $E582311A, $97603351, $62457F53, $B1E07764, $BB84AE6B, $FE1CA081, $F9942B08,
    $70586848, $8F19FD45, $94876CDE, $52B7F87B, $AB23D373, $72E2024B, $E3578F1F, $662AAB55,
    $B20728EB, $2F03C2B5, $869A7BC5, $D3A50837, $30F28728, $23B2A5BF, $02BA6A03, $ED5C8216,
    $8A2B1CCF, $A792B479, $F3F0F207, $4EA1E269, $65CDF4DA, $06D5BE05, $D11F6234, $C48AFEA6,
    $349D532E, $A2A055F3, $0532E18A, $A475EBF6, $0B39EC83, $40AAEF60, $5E069F71, $BD51106E,
    $3EF98A21, $963D06DD, $DDAE053E, $4D46BDE6, $91B58D54, $71055DC4, $046FD406, $60FF1550,
    $1924FB98, $D697E9BD, $89CC4340, $67779ED9, $B0BD42E8, $07888B89, $E7385B19, $79DBEEC8,
    $A1470A7C, $7CE90F42, $F8C91E84, $00000000, $09838680, $3248ED2B, $1EAC7011, $6C4E725A,
    $FDFBFF0E, $0F563885, $3D1ED5AE, $3627392D, $0A64D90F, $6821A65C, $9BD1545B, $243A2E36,
    $0CB1670A, $930FE757, $B4D296EE, $1B9E919B, $804FC5C0, $61A220DC, $5A694B77, $1C161A12,
    $E20ABA93, $C0E52AA0, $3C43E022, $121D171B, $0E0B0D09, $F2ADC78B, $2DB9A8B6, $14C8A91E,
    $578519F1, $AF4C0775, $EEBBDD99, $A3FD607F, $F79F2601, $5CBCF572, $44C53B66, $5B347EFB,
    $8B762943, $CBDCC623, $B668FCED, $B863F1E4, $D7CADC31, $42108563, $13402297, $842011C6,
    $857D244A, $D2F83DBB, $AE1132F9, $C76DA129, $1D4B2F9E, $DCF330B2, $0DEC5286, $77D0E3C1,
    $2B6C16B3, $A999B970, $11FA4894, $472264E9, $A8C48CFC, $A01A3FF0, $56D82C7D, $22EF9033,
    $87C74E49, $D9C1D138, $8CFEA2CA, $98360BD4, $A6CF81F5, $A528DE7A, $DA268EB7, $3FA4BFAD,
    $2CE49D3A, $500D9278, $6A9BCC5F, $5462467E, $F6C2138D, $90E8B8D8, $2E5EF739, $82F5AFC3,
    $9FBE805D, $697C93D0, $6FA92DD5, $CFB31225, $C83B99AC, $10A77D18, $E86E639C, $DB7BBB3B,
    $CD097826, $6EF41859, $EC01B79A, $83A89A4F, $E6656E95, $AA7EE6FF, $2108CFBC, $EFE6E815,
    $BAD99BE7, $4ACE366F, $EAD4099F, $29D67CB0, $31AFB2A4, $2A31233F, $C63094A5, $35C066A2,
    $7437BC4E, $FCA6CA82, $E0B0D090, $3315D8A7, $F14A9804, $41F7DAEC, $7F0E50CD, $172FF691,
    $768DD64D, $434DB0EF, $CC544DAA, $E4DF0496, $9EE3B5D1, $4C1B886A, $C1B81F2C, $467F5165,
    $9D04EA5E, $015D358C, $FA737487, $FB2E410B, $B35A1D67, $9252D2DB, $E9335610, $6D1347D6,
    $9A8C61D7, $377A0CA1, $598E14F8, $EB893C13, $CEEE27A9, $B735C961, $E1EDE51C, $7A3CB147,
    $9C59DFD2, $553F73F2, $1879CE14, $73BF37C7, $53EACDF7, $5F5BAAFD, $DF146F3D, $7886DB44,
    $CA81F3AF, $B93EC468, $382C3424, $C25F40A3, $1672C31D, $BC0C25E2, $288B493C, $FF41950D,
    $397101A8, $08DEB30C, $D89CE4B4, $6490C156, $7B6184CB, $D570B632, $48745C6C, $D04257B8);

  // Round constants
  RCon: array[1..29] of Byte = (
    $01, $02, $04, $08, $10, $20, $40, $80, $1B, $36, $6c, $d8, $ab, $4d, $9a, $2f,
    $5e, $bc, $63, $c6, $97, $35, $6a, $d4, $b3, $7d, $fa, $ef, $c5);

  // Inverse substitution table
  InvSub: array[Byte] of Byte = (
    $52, $09, $6A, $D5, $30, $36, $A5, $38, $BF, $40, $A3, $9E, $81, $F3, $D7, $FB,
    $7C, $E3, $39, $82, $9B, $2F, $FF, $87, $34, $8E, $43, $44, $C4, $DE, $E9, $CB,
    $54, $7B, $94, $32, $A6, $C2, $23, $3D, $EE, $4C, $95, $0B, $42, $FA, $C3, $4E,
    $08, $2E, $A1, $66, $28, $D9, $24, $B2, $76, $5B, $A2, $49, $6D, $8B, $D1, $25,
    $72, $F8, $F6, $64, $86, $68, $98, $16, $D4, $A4, $5C, $CC, $5D, $65, $B6, $92,
    $6C, $70, $48, $50, $FD, $ED, $B9, $DA, $5E, $15, $46, $57, $A7, $8D, $9D, $84,
    $90, $D8, $AB, $00, $8C, $BC, $D3, $0A, $F7, $E4, $58, $05, $B8, $B3, $45, $06,
    $D0, $2C, $1E, $8F, $CA, $3F, $0F, $02, $C1, $AF, $BD, $03, $01, $13, $8A, $6B,
    $3A, $91, $11, $41, $4F, $67, $DC, $EA, $97, $F2, $CF, $CE, $F0, $B4, $E6, $73,
    $96, $AC, $74, $22, $E7, $AD, $35, $85, $E2, $F9, $37, $E8, $1C, $75, $DF, $6E,
    $47, $F1, $1A, $71, $1D, $29, $C5, $89, $6F, $B7, $62, $0E, $AA, $18, $BE, $1B,
    $FC, $56, $3E, $4B, $C6, $D2, $79, $20, $9A, $DB, $C0, $FE, $78, $CD, $5A, $F4,
    $1F, $DD, $A8, $33, $88, $07, $C7, $31, $B1, $12, $10, $59, $27, $80, $EC, $5F,
    $60, $51, $7F, $A9, $19, $B5, $4A, $0D, $2D, $E5, $7A, $9F, $93, $C9, $9C, $EF,
    $A0, $E0, $3B, $4D, $AE, $2A, $F5, $B0, $C8, $EB, $BB, $3C, $83, $53, $99, $61,
    $17, $2B, $04, $7E, $BA, $77, $D6, $26, $E1, $69, $14, $63, $55, $21, $0C, $7D);

  RowShiftOffsets: array[4..8] of TRijRowShiftOffs = (
    (0,1,2,3),(0,1,2,3),(0,1,2,3),(0,1,2,4),(0,1,3,4));

{------------------------------------------------------------------------------}
{   TRijndaelCipher - protected methods                                        }
{------------------------------------------------------------------------------}

procedure TRijndaelCipher.SetModeOfOperation(Value: TBCModeOfOperation);
var
  OldValue: TBCModeOfOperation;
begin
OldValue := ModeOfOperation;
inherited SetModeOfOperation(Value);
If (OldValue <> Value) and (Value in [moCFB,moOFB,moCTR]) and (Mode = cmDecrypt) then
  CipherInit;
end;

//------------------------------------------------------------------------------

procedure TRijndaelCipher.SetKeyLength(Value: TRijLength);
begin
fKeyLength := Value;
case fKeyLength of
  r128bit: fNk := 4;
  r160bit: fNk := 5;
  r192bit: fNk := 6;
  r224bit: fNk := 7;
  r256bit: fNk := 8;
else
  raise Exception.CreateFmt('TRijndaelCipher.SetKeyLength: Unsupported key length (%d).',[Ord(Value)]);
end;
fNr := Max(fNk,fNb) + 6;
SetKeyBytes(fNk * SizeOf(TRijWord));
end;

//------------------------------------------------------------------------------

procedure TRijndaelCipher.SetBlockLength(Value: TRijLength);
begin
fBlockLength := Value;
case fBlockLength of
  r128bit: fNb := 4;
  r160bit: fNb := 5;
  r192bit: fNb := 6;
  r224bit: fNb := 7;
  r256bit: fNb := 8;
else
  raise Exception.CreateFmt('TRijndaelCipher.SetBlockLength: Unsupported block length (%d).',[Ord(Value)]);
end;
fNr := Max(fNk,fNb) + 6;
SetBlockBytes(fNb * SizeOf(TRijWord));
fRowShiftOff := RowShiftOffsets[fNb];
end;

//------------------------------------------------------------------------------

(*
  Complete pseudocode of key expansion (Equivalent Inverse Cipher is used).
  Source: FIPS 197.

 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  KeyExpansion(byte key[4*Nk], word w[Nb*(Nr+1)], Nk)
  begin
    word temp
    i = 0

    while (i < Nk)
      w[i] = word(key[4*i], key[4*i+1], key[4*i+2], key[4*i+3])
      i = i+1
    end while

    i = Nk
    while (i < Nb * (Nr+1)]
      temp = w[i-1]
      if (i mod Nk = 0)
        temp = SubWord(RotWord(temp)) xor Rcon[i/Nk]
      else if (Nk > 6 and i mod Nk = 4)
        temp = SubWord(temp)
      end if
      w[i] = w[i-Nk] xor temp
      i = i + 1
    end while

    // Equivalent Inverse Cipher code follows (used only when expanding key for decryption)

    for i = 0 step 1 to (Nr+1)*Nb-1
      dw[i] = w[i]
    end for

    for round = 1 step 1 to Nr-1
      InvMixColumns(dw[round*Nb, (round+1)*Nb-1]) // note change of type
    end for
  end

 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
*)
procedure TRijndaelCipher.CipherInit;
var
  i:    Integer;
  Temp: TRijWord;
begin
(*
  Key words are simply copied into lower Nk words of key shedule.

  Note that all words in KeyShedule will have reversed byte order in comparisson
  with test cases. This is normal and desired behavior and is accounted for in
  further computations.
*)
For i := 0 to Pred(fNk) do
  fKeySchedule[i] := {%H-}PRijWord({%H-}PtrUInt(Key) + PtrUInt(4 * i))^;
(*
  RotWord rotates bytes in input 32bit word one place up as this:

     RotWord(w{a0,a1,a2,a3}) = w{a1,a2,a3,a0}

  Instead of implementing this as a function, it is done by selecting
  appropriate byte from input word as an index for substitution table.

  SubWord is done by indexing encryption table 4. Lowest byte of all words in
  encoding table 4 (EncTab4) contains plain substitution values (see method
  Encrypt for description how the words in this table are constructed), so we
  use it as a substitution lookup table instead of declaring one separately.

  Other than that, this part does not differ from pseudocode.
*)
For i := fNk to Pred(fNb * (fNr + 1)) do
  begin
    Temp := fKeySchedule[i - 1];
    If (i mod fNk = 0) then
      Temp := (EncTab4[Byte(Temp shr 8)] and $FF) or
             ((EncTab4[Byte(Temp shr 16)] and $FF) shl 8) or
             ((EncTab4[Byte(Temp shr 24)] and $FF) shl 16) or
              (EncTab4[Byte(Temp)] shl 24) xor TRijWord(RCon[i div fNk])
    else If (fNk > 6) and (i mod fNk = 4) then
      Temp := (EncTab4[Byte(Temp)] and $FF) or
             ((EncTab4[Byte(Temp shr 8)] and $FF) shl 8) or
             ((EncTab4[Byte(Temp shr 16)] and $FF) shl 16) or
             ((EncTab4[Byte(Temp shr 24)] and $FF) shl 24);
    fKeySchedule[i] := fKeySchedule[i - fNk] xor Temp;
  end;
(*
  Modified decryption shedule (dw) is not created, modified values are instead
  stored in normal shedule which in turn cannot be used for encryption (not a
  problem, TBlockCipher can be initialized either for decryption or encryption
  mode, but not both).

  Modified value is computed this way:

    mKSw = InvMixColumns(KSw)

  This can be rewritten for individual bytes as follows:

    mKSw0 = glt14[KSw0] xor glt11[KSw1] xor glt13[KSw2] xor glt9[KSw3]
    mKSw1 = glt9[KSw0] xor glt14[KSw1] xor glt11[KSw2] xor glt13[KSw3]
    mKSw2 = glt13[KSw0] xor glt9[KSw1] xor glt14[KSw2] xor glt11[KSw3]
    mKSw3 = glt11[KSw0] xor glt13[KSw1] xor glt9[KSw2] xor glt14[KSw3]

  ...and since decoding tables are constructed this way:

    Table 1:  W1[i] = {glt14(invsub(i)),glt9(invsub(i)),glt13(invsub(i)),glt11(invsub(i))}
    Table 2:  W2[i] = {glt11(invsub(i)),glt14(invsub(i)),glt9(invsub(i)),glt13(invsub(i))}
    Table 3:  W3[i] = {glt13(invsub(i)),glt11(invsub(i)),glt14(invsub(i)),glt9(invsub(i))}
    Table 4:  W4[i] = {glt9(invsub(i)),glt13(invsub(i)),glt11(invsub(i)),glt14(invsub(i))}

  ...we can use them in here for lookup. Only problem is, that every decoding
  table already incorporates inverse substitution, so every byte used to index
  word in decoding table must be first rectified to a state in which applying
  invsub() on it returns its original value, which will result in this:

    W1[rectified(i)] = {glt14[i],glt9[i],glt13[i],glt11[i]}

  This is easily done if we consider this fact:

    invsub(sub(B)) = B

  What we need is therefore simple substitution. Encoding table 4 can be used
  for substitution since lowest byte of each its word contains plain
  substitution value for a given index (byte).
  Finally, modified shedule word is constructed this way:

    mKSw = W1[sub(KSw0)] xor W2[sub(KSw1)] xor W3[sub(KSw2)] xor W4[sub(KSw3)]
*)
If (Mode = cmDecrypt) and not (ModeOfOperation in [moCFB,moOFB,moCTR]) then
  For i := fNb to Pred(fNr * fNb) do
      fKeySchedule[i] := DecTab1[Byte(EncTab4[Byte(fKeySchedule[i])])] xor
                         DecTab2[Byte(EncTab4[Byte(fKeySchedule[i] shr 8)])] xor
                         DecTab3[Byte(EncTab4[Byte(fKeySchedule[i] shr 16)])] xor
                         DecTab4[Byte(EncTab4[Byte(fKeySchedule[i] shr 24)])];
end;

//------------------------------------------------------------------------------

procedure TRijndaelCipher.CipherFinal;
begin
// nothing to do here
end;

//------------------------------------------------------------------------------

(*
  Complete pseudocode of block encryption.
  Source: FIPS 197.

 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  Cipher(byte in[4*Nb], byte out[4*Nb], word w[Nb*(Nr+1)])
  begin
    byte state[4,Nb]

    state = in

    AddRoundKey(state, w[0, Nb-1])

    for round = 1 step 1 to Nr–1
      SubBytes(state)
      ShiftRows(state)
      MixColumns(state)
      AddRoundKey(state, w[round*Nb, (round+1)*Nb-1])
    end for

    SubBytes(state)
    ShiftRows(state)
    AddRoundKey(state, w[Nr*Nb, (Nr+1)*Nb-1])

    out = state
  end

 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
*)
procedure TRijndaelCipher.CipherEncrypt(const Input; out Output);
var
  i,j:        Integer;
  State:      TRijState;
  TempState:  TRijState;

  Function RoundIdx(Start,Off: Integer): Integer;
  begin
    Result := Start + Off;
    while Result >= fNb do
      Dec(Result,fNb);
  end;

begin
(*
  AddRoundKey at this point is simple XOR of words from inpuf block with key
  shedule.
*)
For i := 0 to Pred(fNb) do
  State[i] := TRijState(Input)[i] xor fKeySchedule[i];
(*
  SubBytes and ShiftRows are switched - they are commutable, so result is not
  affected by this. ShiftRows is therefore done first and SubBytes and
  MixColumns are merged into one operation and done using encryption lookup
  tables.

--- ShiftRows ------------------------------------------------------------------

  ShiftRows is doing byte rotation on state rows (that is, between individual
  words) by a predefined number of places (this number depends on a row that
  is being shifted and size of a cipher block - see table ShiftRowsOffset for
  actual data). It rotates the bytes to a lower places (down).
  For example, shift by a one place will look like this:

    ShiftRows(w{a0,a1,a2,a3}) = w{a1,a2,a3,a0}

  If we assume 6-word state, shifting third row by two places will do this:

    w0 | w1 | w2 | w3 | w4 | w5                 w0 | w1 | w2 | w3 | w4 | w5
   -----------------------------               -----------------------------
    a0 | b0 | c0 | d0 | e0 | f0                 a0 | b0 | c0 | d0 | e0 | f0
    a1 | b1 | c1 | d1 | e1 | f1                 a1 | b1 | c1 | d1 | e1 | f1
    a2 | b2 | c2 | d2 | e2 | f2 - rotate by 2 - c2 | d2 | e2 | f2 | a2 | b2
    a3 | b3 | c3 | d3 | e3 | f3                 a3 | b3 | c3 | d3 | e3 | f3

  In this implementation, however, it is done diferently.
  For a further computation after ShiftRows, we need to extract four bytes as an
  indices for a lookup table. It would be normally done by selecting a word
  in a shifted state and then using its constituting bytes. Instead of this, we
  carefully select from which state word we extract each byte.
  Byte, that is N, where N is shift offset, number of places higher in unshifted
  state than the word we would select in a shifted state, is selected - indices
  that fall out of boundary are wrapped.

  For example, if we want to select third word (w2) in a 6-word state above,
  we do it this way:

    W = {byte #0 of w[2 + first row offset], byte #1 of w[2 + second row offset],
         byte #2 of w[2 + third row offset], byte #3 of w[2 + fourth row offset]}

           first row offset = 0  second row offset = 0
           third row offset = 2  fourth row offset = 0

    W = {byte #0 of w2, byte #1 of w2, byte #2 of w4, byte #3 of w2}

    W = {c0, c1, e2, c3} <<<


  Second example - let's say we have this state:

    w0 | w1 | w2 | w3
   -------------------
    a0 | b0 | c0 | d0  - should be rotated by 0
    a1 | b1 | c1 | d1  - should be rotated by 1
    a2 | b2 | c2 | d2  - should be rotated by 2
    a3 | b3 | c3 | d3  - should be rotated by 4

  ... and we want second word (w1) as it would be in a shifted state.

    W = {byte 0 of w[1 + first row offset], byte 1 of w[1 + second row offset],
         byte 2 of w[1 + third row offset], byte 3 of w[1 + fourth row offset]}

           first row offset = 0  second row offset = 1
           third row offset = 2  fourth row offset = 4

    W = {byte 0 of w1, byte 1 of w2, byte 2 of w3, byte 3 of w1}

    W = {b0, c1, d2, b3} <<<


--- SubBytes + MixColumns ------------------------------------------------------

  As was already said, SubBytes and MixColumns are merged and done using
  encryption lookup tables.

  SubBytes is simple substitution - a byte in a word is replaced by a different
  byte according to some rule. This itself is usually done by a lookup table.

  MixColumns is very complex operation, but can be simplified for individual
  bytes in a processed word to a following formula:

    b0 = glt2[a0] xor glt3[a1] xor glt1[a2] xor glt1[a3]
    b1 = glt1[a0] xor glt2[a1] xor glt3[a2] xor glt1[a3]
    b2 = glt1[a0] xor glt1[a1] xor glt2[a2] xor glt3[a3]
    b3 = glt3[a0] xor glt1[a1] xor glt1[a2] xor glt2[a3]

  ...where a0..a3 are individual bytes of the input 32bit word, b0..b3 are
  corresponding bytes in the resulting 32bit word. gltX is Galois Multiplication
  lookup table for a X multiplier (note that glt1 does not change the value).

  It should be apparent form this formula, that we can actually create four
  tables of precomputed 32bit words for each byte that vould be passed to
  MixColumns function. To merge it with SubBytes, we just use substituted bytes
  to index gltX tables instead of original bytes.
  The tables are therefore constructed this way (i is index in the table):

    Table 1:  W1[i] = {glt2[sub(i)],glt1[sub(i)],glt1[sub(i)],glt3[sub(i)]}
    Table 2:  W2[i] = {glt3[sub(i)],glt2[sub(i)],glt1[sub(i)],glt1[sub(i)]}
    Table 3:  W3[i] = {glt1[sub(i)],glt3[sub(i)],glt2[sub(i)],glt1[sub(i)]}
    Table 4:  W4[i] = {glt1[sub(i)],glt1[sub(i)],glt3[sub(i)],glt2[sub(i)]}

  To get the resulting word, we just XOR all four words from the tables that we
  obtain by indexing them with corresponding bytes from the input word (returned
  from ShiftRows function):

    Rw = W1[a0] xor W2[a1] xor W3[a2] xor W4[a3]


  Examples of lookup table word construction:

    Example 1 - Table 1, input byte 0x01

      Substitution:       0x01 -> 0x7c

      Creating mix word:  W = {glt2[0x7c], 0x7c, 0x7c, glt3[0x7c]}
                          W = {0xf8, 0x7c, 0x7c, 0x84}
                          W = 0x847c7cf8 <<<

    Example 2 - Table 3, input byte 0xc9

      Substitution:       0xc9 -> 0xdd

      Creating mix word:  W = {0xdd, glt3[0xdd], glt2[0xdd], 0xdd}
                          W = {0xdd, 0x7c, 0xa1, 0xdd}
                          W = 0xdda17cdd <<<


  Note, that since Galois Multiplication by 1 is used, there are plain (no mix)
  substitution values contained in all encryption tables - this fact is used in
  last encryption round.

--- AddRoundKey ----------------------------------------------------------------

  We XOR resulting word from previous operations with a key shedule and store
  it back in the state.
*)
For j := 1 to (fNr - 1) do
  begin
    TempState := {%H-}State;
    For i := 0 to Pred(fNb) do
      State[i] := EncTab1[Byte(TempState[RoundIdx(i,fRowShiftOff[0])])] xor
                  EncTab2[Byte(TempState[RoundIdx(i,fRowShiftOff[1])] shr 8)] xor
                  EncTab3[Byte(TempState[RoundIdx(i,fRowShiftOff[2])] shr 16)] xor
                  EncTab4[Byte(TempState[RoundIdx(i,fRowShiftOff[3])] shr 24)] xor
                  fKeySchedule[j * fNb + i];
  end;
(*
  We again switch order of SubByte and ShiftRows (ShiftRows is done first,
  SubBytes second).

  ShiftRows is implemented the same way as in main round - instead of actual
  shifting, we carefully select from which state word to take indexing byte for
  a table lookup.

  SubBytes is primitive table lookup operation, table index is byte selected in
  ShiftRows.
  As mentioned earlier, some tables used in main round contain plain
  substitution values - so instead of declaring separate substitution table, we
  can use this fact (EncTab4 is used since its words contain subtitution values
  in their lowest byte).
  The resulting 32bit word is then cunstructed by concatenation of substitued
  bytes.

  AddRoundKey is again a simple XOR operation.
*)
For i := 0 to Pred(fNb) do
  TempState[i] := (EncTab4[Byte(State[RoundIdx(i,fRowShiftOff[0])])] and $FF) or
                 ((EncTab4[Byte(State[RoundIdx(i,fRowShiftOff[1])] shr 8)] and $FF) shl 8) or
                 ((EncTab4[Byte(State[RoundIdx(i,fRowShiftOff[2])] shr 16)] and $FF) shl 16) or
                 ((EncTab4[Byte(State[RoundIdx(i,fRowShiftOff[3])] shr 24)] and $FF) shl 24) xor
                  fKeySchedule[fNr * fNb + i];
Move({%H-}TempState,{%H-}Output,BlockBytes);
end;

//------------------------------------------------------------------------------

(*
  Complete pseudocode of block decryption (equivalent inverse cipher).
  Source: FIPS 197.

 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  EqInvCipher(byte in[4*Nb], byte out[4*Nb], word dw[Nb*(Nr+1)])
  begin
    byte state[4,Nb]

    state = in

    AddRoundKey(state, dw[Nr*Nb, (Nr+1)*Nb-1])

    for round = Nr-1 step -1 downto 1
      InvSubBytes(state)
      InvShiftRows(state)
      InvMixColumns(state)
      AddRoundKey(state, dw[round*Nb, (round+1)*Nb-1])
    end for

    InvSubBytes(state)
    InvShiftRows(state)
    AddRoundKey(state, dw[0, Nb-1])

    out = state
  end

 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
*)
procedure TRijndaelCipher.CipherDecrypt(const Input; out Output);
var
  i,j:        Integer;
  State:      TRijState;
  TempState:  TRijState;

  Function RoundIdx(Start,Off: Integer): Integer;
  begin
    Result := Start - Off;
    while Result < 0 do
      Inc(Result,fNb);
  end;

begin
(*
  AddRoundKey is simple XOR of words from inpuf block with key shedule words.
*)
For i := 0 to Pred(fNb) do
  State[i] := TRijState(Input)[i] xor fKeySchedule[fNr * fNb + i];
(*
  InvSubBytes and InvShiftRows are again switched so InvShiftRows is done first.
  InvSubBytes and InvMixColumns are then merged into one operation and done
  using decryption lookup tables.

--- InvShiftRows ---------------------------------------------------------------

  InvShiftRows is implemented the same way as in the case of encryption -
  instead of actual shifting, we select proper word from which to extract
  indexing byte for further processing.
  Only difference is, that inverse shifting moves bytes to a higher places (up):

    InvShiftRows(w{a0,a1,a2,a3}) = w{a3,a0,a1,a2}

  So when selecting the word, instead of adding row shift offset, we subtract
  it.

  For example, let's say we have this state:

      w0 | w1 | w2 | w3 | w4 | w5
     -----------------------------
      a0 | b0 | c0 | d0 | e0 | f0
      a1 | b1 | c1 | d1 | e1 | f1 - rotate by 1
      a2 | b2 | c2 | d2 | e2 | f2 - rotate by 2
      a3 | b3 | c3 | d3 | e3 | f3

  We want to select fourth word (w3) in a 6-word state above, we do it this way:

    W = {byte #0 of w[3 - first row offset], byte #1 of w[3 - second row offset],
         byte #2 of w[3 - third row offset], byte #3 of w[3 - fourth row offset]}

           first row offset = 0  second row offset = 1
           third row offset = 2  fourth row offset = 0

    W = {byte #0 of w3, byte #1 of w2, byte #2 of w1, byte #3 of w3}

    W = {d0, c1, b2, d3} <<<

--- InvSubBytes + InvMixColumns ------------------------------------------------

  These two operations are again meged together and done using lookup tables the
  same way as encryption.

  InvSubBytes is simple substitution.

  InvMixColumns is very complex operation, but can be written for individual
  bytes this way:

    b0 = glt14[a0] xor glt11[a1] xor glt13[a2] xor glt9[a3]
    b1 = glt9[a0] xor glt14[a1] xor glt11[a2] xor glt13[a3]
    b2 = glt13[a0] xor glt9[a1] xor glt14[a2] xor glt11[a3]
    b3 = glt11[a0] xor glt13[a1] xor glt9[a2] xor glt14[a3]

  a0..a3 are individual bytes of the input 32bit word, b0..b3 are corresponding
  bytes in the resulting 32bit word. gltX is Galois Multiplication lookup table
  for a X multiplier.

  We can again create set of lookup tables of precalculated words.
  These decryption tables are constructed this way (i is index in the table):

    Table 1:  W1[i] = {glt14[invsub(i)],glt9[invsub(i)],glt13[invsub(i)],glt11[invsub(i)]}
    Table 2:  W2[i] = {glt11[invsub(i)],glt14[invsub(i)],glt9[invsub(i)],glt13[invsub(i)]}
    Table 3:  W3[i] = {glt13[invsub(i)],glt11[invsub(i)],glt14[invsub(i)],glt9[invsub(i)]}
    Table 4:  W4[i] = {glt9[invsub(i)],glt13[invsub(i)],glt11[invsub(i)],glt14[invsub(i)]}

  And the resulting word is obtained by XORing all four words from the tables
  that we obtain by indexing them with corresponding bytes word returned by
  InvShiftRows function:

    Rw = W1[a0] xor W2[a1] xor W3[a2] xor W4[a3]


  Examples of lookup table word construction:

    Example 1 - Table 2, input byte 0x07

      Substitution:       0x07 -> 0x38

      Creating mix word:  W = [glt11(0x38), glt14(0x38), glt9(0x38), glt13(0x38)]
                          W = [0x93, 0x4b, 0xe3, 0x03]
                          W = 0x03e34b93 <<<

    Example 2 - Table 4, input byte 0x5a

      Substitution:       0x5a -> 0x46

      Creating mix word:  W = [glt9(0x46), glt13(0x46), glt11(0x46), glt14(0x46)]
                          W = [0x40, 0x43, 0xcc, 0x89]
                          W = 0x89cc4340 <<<


  Note that since Galois Multiplication by 1 is NOT used this time, there are no
  plain substitution values in any table.

--- AddRoundKey ----------------------------------------------------------------

  We XOR resulting word from previous operations with a key shedule and store
  it back in the state.  
*)
For j := (fNr - 1) downto 1 do
  begin
    TempState := {%H-}State;
    For i := 0 to Pred(fNb) do
      State[i] := DecTab1[Byte(TempState[RoundIdx(i,fRowShiftOff[0])])] xor
                  DecTab2[Byte(TempState[RoundIdx(i,fRowShiftOff[1])] shr 8)] xor
                  DecTab3[Byte(TempState[RoundIdx(i,fRowShiftOff[2])] shr 16)] xor
                  DecTab4[Byte(TempState[RoundIdx(i,fRowShiftOff[3])] shr 24)] xor
                  fKeySchedule[j * fNb + i];
  end;
(*
  Order of InvSubByte and InvShiftRows is swithed (InvShiftRows is done first,
  InvSubBytes second).

  InvShiftRows is implemented the same way as in main round - refer there for
  details.

  SubBytes is lookup operation, table index is byte selected in ShiftRows.
  Unlike in ecryption, decryption tables do not contain plain substitution
  values, so we must declare separate inverse substitution table (InvSub).
  The resulting 32bit word is then cunstructed by concatenation of substitued
  bytes.

  AddRoundKey is simple XOR operation.
*)
For i := 0 to Pred(fNb) do
  TempState[i] := TRijWord(InvSub[Byte(State[RoundIdx(i,fRowShiftOff[0])])]) or
                 (TRijWord(InvSub[Byte(State[RoundIdx(i,fRowShiftOff[1])] shr 8)]) shl 8) or
                 (TRijWord(InvSub[Byte(State[RoundIdx(i,fRowShiftOff[2])] shr 16)]) shl 16) or
                 (TRijWord(InvSub[Byte(State[RoundIdx(i,fRowShiftOff[3])] shr 24)]) shl 24) xor
                  fKeySchedule[i];
Move({%H-}TempState,{%H-}Output,BlockBytes);
end;

{------------------------------------------------------------------------------}
{   TRijndaelCipher - public methods                                           }
{------------------------------------------------------------------------------}

constructor TRijndaelCipher.Create(const Key; const InitVector; KeyLength, BlockLength: TRijLength; Mode: TBCMode);
begin
Create;
Init(Key,InitVector,KeyLength,BlockLength,Mode);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

constructor TRijndaelCipher.Create(const Key; KeyLength, BlockLength: TRijLength; Mode: TBCMode);
begin
Create;
Init(Key,KeyLength,BlockLength,Mode);
end;

//------------------------------------------------------------------------------

procedure TRijndaelCipher.Init(const Key; const InitVector; KeyLength, BlockLength: TRijLength; Mode: TBCMode);
begin
SetKeyLength(KeyLength);
SetBlockLength(BlockLength);
inherited Initialize(Key,InitVector,KeyBytes,BlockBytes,Mode);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TRijndaelCipher.Init(const Key; KeyLength, BlockLength: TRijLength; Mode: TBCMode);
begin
SetKeyLength(KeyLength);
SetBlockLength(BlockLength);
inherited Initialize(Key,KeyBytes,BlockBytes,Mode);
end;


{==============================================================================}
{------------------------------------------------------------------------------}
{                                  TAESCipher                                  }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TAESCipher - implementation                                                }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TAESCipher - protected methods                                             }
{------------------------------------------------------------------------------}

procedure TAESCipher.SetKeyLength(Value: TRijLength);
begin
If Value in [r128bit,r192bit,r256bit] then
  inherited SetKeyLength(Value)
else
  raise Exception.CreateFmt('TAESCipher.SetKeyLength: Unsupported key length (%d).',[Ord(Value)]);
end;

//------------------------------------------------------------------------------

procedure TAESCipher.SetBlockLength(Value: TRijLength);
begin
If Value = r128bit then
  inherited SetBlockLength(Value)
else
  raise Exception.CreateFmt('TAESCipher.SetBlockLength: Unsupported block length (%d).',[Ord(Value)]);
end;

{------------------------------------------------------------------------------}
{   TAESCipher - public methods                                                }
{------------------------------------------------------------------------------}

class Function TAESCipher.AccelerationSupported: Boolean;
begin
Result := False;
end;

//------------------------------------------------------------------------------

constructor TAESCipher.Create(const Key; const InitVector; KeyLength, BlockLength: TRijLength; Mode: TBCMode);
begin
inherited Create(Key,InitVector,KeyLength,r128bit,Mode);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

constructor TAESCipher.Create(const Key; KeyLength, BlockLength: TRijLength; Mode: TBCMode);
begin
inherited Create(Key,KeyLength,r128bit,Mode);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

constructor TAESCipher.Create(const Key; const InitVector; KeyLength: TRijLength; Mode: TBCMode);
begin
inherited Create(Key,InitVector,KeyLength,r128bit,Mode);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

constructor TAESCipher.Create(const Key; KeyLength: TRijLength; Mode: TBCMode);
begin
inherited Create(Key,KeyLength,r128bit,Mode);
end;

//------------------------------------------------------------------------------

procedure TAESCipher.Init(const Key; const InitVector; KeyLength, BlockLength: TRijLength; Mode: TBCMode);
begin
inherited Init(Key,InitVector,KeyLength,r128bit,Mode);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TAESCipher.Init(const Key; KeyLength, BlockLength: TRijLength; Mode: TBCMode);
begin
inherited Init(Key,KeyLength,r128bit,Mode);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TAESCipher.Init(const Key; const InitVector; KeyLength: TRijLength; Mode: TBCMode);
begin
inherited Init(Key,InitVector,KeyLength,r128bit,Mode);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TAESCipher.Init(const Key; KeyLength: TRijLength; Mode: TBCMode);
begin
inherited Init(Key,KeyLength,r128bit,Mode);
end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                            TAESCipherAccelerated                             }
{------------------------------------------------------------------------------}
{==============================================================================}

{==============================================================================}
{   TAESCipherAccelerated - implementation                                     }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TAESCipherAccelerated - assembly implementation                            }
{------------------------------------------------------------------------------}

{$IFNDEF PurePascal}

{$IFDEF ASMSuppressSizeWarnings}
  {$WARN 2087 OFF}  //  Supresses warnings on following $WARN
  {$WARN 7122 OFF}  //  Warning: Check size of memory operand "op: memory-operand-size is X bits, but expected [Y bits + Z byte offset]"
{$ENDIF}

procedure AESNI_KeyExpand_128(Key, KeySchedule: Pointer); register; assembler;
asm
    MOVUPS    XMM0, dqword ptr [Key]
    MOVAPS    dqword ptr [KeySchedule], XMM0
    MOVAPS    XMM1, XMM0

{$DEFINE KeyExpand_128_RoundCommon}
  {$IFDEF ASM_MachineCode}
    DB  $66, $0F, $3A, $DF, $C9, $01    //  AESKEYGENASSIST   XMM1, XMM1, $01
    {$INCLUDE '.\AES_Assembly.inc'}
    DB  $66, $0F, $3A, $DF, $C9, $02
    {$INCLUDE '.\AES_Assembly.inc'}
    DB  $66, $0F, $3A, $DF, $C9, $04
    {$INCLUDE '.\AES_Assembly.inc'}
    DB  $66, $0F, $3A, $DF, $C9, $08
    {$INCLUDE '.\AES_Assembly.inc'}
    DB  $66, $0F, $3A, $DF, $C9, $10
    {$INCLUDE '.\AES_Assembly.inc'}
    DB  $66, $0F, $3A, $DF, $C9, $20
    {$INCLUDE '.\AES_Assembly.inc'}
    DB  $66, $0F, $3A, $DF, $C9, $40
    {$INCLUDE '.\AES_Assembly.inc'}
    DB  $66, $0F, $3A, $DF, $C9, $80
    {$INCLUDE '.\AES_Assembly.inc'}
    DB  $66, $0F, $3A, $DF, $C9, $1B
    {$INCLUDE '.\AES_Assembly.inc'}
    DB  $66, $0F, $3A, $DF, $C9, $36
    {$INCLUDE '.\AES_Assembly.inc'}
  {$ELSE}
    AESKEYGENASSIST   XMM1, XMM1, $01
    {$INCLUDE '.\AES_Assembly.inc'}
    AESKEYGENASSIST   XMM1, XMM1, $02
    {$INCLUDE '.\AES_Assembly.inc'}
    AESKEYGENASSIST   XMM1, XMM1, $04
    {$INCLUDE '.\AES_Assembly.inc'}
    AESKEYGENASSIST   XMM1, XMM1, $08
    {$INCLUDE '.\AES_Assembly.inc'}
    AESKEYGENASSIST   XMM1, XMM1, $10
    {$INCLUDE '.\AES_Assembly.inc'}
    AESKEYGENASSIST   XMM1, XMM1, $20
    {$INCLUDE '.\AES_Assembly.inc'}
    AESKEYGENASSIST   XMM1, XMM1, $40
    {$INCLUDE '.\AES_Assembly.inc'}
    AESKEYGENASSIST   XMM1, XMM1, $80
    {$INCLUDE '.\AES_Assembly.inc'}
    AESKEYGENASSIST   XMM1, XMM1, $1B
    {$INCLUDE '.\AES_Assembly.inc'}
    AESKEYGENASSIST   XMM1, XMM1, $36
    {$INCLUDE '.\AES_Assembly.inc'}
  {$ENDIF}
{$UNDEF KeyExpand_128_RoundCommon}
end;

//------------------------------------------------------------------------------

procedure AESNI_KeyExpand_192(Key, KeySchedule: Pointer); register; assembler;
asm
    MOVUPS    XMM0, dqword ptr [Key]
    MOVAPS    dqword ptr [KeySchedule], XMM0
    ADD       KeySchedule,  16

    MOVLPS    XMM2, qword ptr [Key + 16]
    MOVAPS    XMM1, XMM0
    MOVAPS    XMM3, XMM2

{$IFDEF ASM_MachineCode}
    DB  $66, $0F, $3A, $DF, $DB, $01
  {$DEFINE KeyExpand_192_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_192_RoundCommon_2}
    DB  $66, $0F, $3A, $DF, $DB, $02
  {$DEFINE KeyExpand_192_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_192_RoundCommon_1}
    DB  $66, $0F, $3A, $DF, $DB, $04
  {$DEFINE KeyExpand_192_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_192_RoundCommon_2}
    DB  $66, $0F, $3A, $DF, $DB, $08
  {$DEFINE KeyExpand_192_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_192_RoundCommon_1}
    DB  $66, $0F, $3A, $DF, $DB, $10
  {$DEFINE KeyExpand_192_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_192_RoundCommon_2}
    DB  $66, $0F, $3A, $DF, $DB, $20
  {$DEFINE KeyExpand_192_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_192_RoundCommon_1}
    DB  $66, $0F, $3A, $DF, $DB, $40
  {$DEFINE KeyExpand_192_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_192_RoundCommon_2}
    DB  $66, $0F, $3A, $DF, $DB, $80
  {$DEFINE KeyExpand_192_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_192_RoundCommon_1}
{$ELSE}
    AESKEYGENASSIST   XMM3, XMM3, $01
  {$DEFINE KeyExpand_192_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_192_RoundCommon_2}
    AESKEYGENASSIST   XMM3, XMM3, $02
  {$DEFINE KeyExpand_192_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_192_RoundCommon_1}
    AESKEYGENASSIST   XMM3, XMM3, $04
  {$DEFINE KeyExpand_192_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_192_RoundCommon_2}
    AESKEYGENASSIST   XMM3, XMM3, $08
  {$DEFINE KeyExpand_192_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_192_RoundCommon_1}
    AESKEYGENASSIST   XMM3, XMM3, $10
  {$DEFINE KeyExpand_192_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_192_RoundCommon_2}
    AESKEYGENASSIST   XMM3, XMM3, $20
  {$DEFINE KeyExpand_192_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_192_RoundCommon_1}
    AESKEYGENASSIST   XMM3, XMM3, $40
  {$DEFINE KeyExpand_192_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_192_RoundCommon_2}
    AESKEYGENASSIST   XMM3, XMM3, $80
  {$DEFINE KeyExpand_192_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_192_RoundCommon_1}
{$ENDIF}
end;

//------------------------------------------------------------------------------

procedure AESNI_KeyExpand_256(Key, KeySchedule: Pointer); register; assembler;
asm
    MOVUPS    XMM0, dqword ptr [Key]
    MOVUPS    XMM1, dqword ptr [Key + 16]
    MOVAPS    dqword ptr [KeySchedule], XMM0
    MOVAPS    dqword ptr [KeySchedule + 16], XMM1

    MOVAPS    XMM2, XMM1
    ADD       KeySchedule,  32

{$IFDEF ASM_MachineCode}
    DB  $66, $0F, $3A, $DF, $D2, $01
  {$DEFINE KeyExpand_256_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_1}
    DB  $66, $0F, $3A, $DF, $D2, $00
  {$DEFINE KeyExpand_256_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_2}
    DB  $66, $0F, $3A, $DF, $D2, $02
  {$DEFINE KeyExpand_256_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_1}
    DB  $66, $0F, $3A, $DF, $D2, $00
  {$DEFINE KeyExpand_256_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_2}
    DB  $66, $0F, $3A, $DF, $D2, $04
  {$DEFINE KeyExpand_256_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_1}
    DB  $66, $0F, $3A, $DF, $D2, $00
  {$DEFINE KeyExpand_256_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_2}
    DB  $66, $0F, $3A, $DF, $D2, $08
  {$DEFINE KeyExpand_256_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_1}
    DB  $66, $0F, $3A, $DF, $D2, $00
  {$DEFINE KeyExpand_256_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_2}
    DB  $66, $0F, $3A, $DF, $D2, $10
  {$DEFINE KeyExpand_256_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_1}
    DB  $66, $0F, $3A, $DF, $D2, $00
  {$DEFINE KeyExpand_256_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_2}
    DB  $66, $0F, $3A, $DF, $D2, $20
  {$DEFINE KeyExpand_256_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_1}
    DB  $66, $0F, $3A, $DF, $D2, $00
  {$DEFINE KeyExpand_256_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_2}
    DB  $66, $0F, $3A, $DF, $D2, $40
  {$DEFINE KeyExpand_256_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_1}
{$ELSE}
    AESKEYGENASSIST   XMM2, XMM2, $01
  {$DEFINE KeyExpand_256_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_1}
    AESKEYGENASSIST   XMM2, XMM2, $00
  {$DEFINE KeyExpand_256_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_2}
    AESKEYGENASSIST   XMM2, XMM2, $02
  {$DEFINE KeyExpand_256_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_1}
    AESKEYGENASSIST   XMM2, XMM2, $00
  {$DEFINE KeyExpand_256_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_2}
    AESKEYGENASSIST   XMM2, XMM2, $04
  {$DEFINE KeyExpand_256_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_1}
    AESKEYGENASSIST   XMM2, XMM2, $00
  {$DEFINE KeyExpand_256_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_2}
    AESKEYGENASSIST   XMM2, XMM2, $08
  {$DEFINE KeyExpand_256_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_1}
    AESKEYGENASSIST   XMM2, XMM2, $00
  {$DEFINE KeyExpand_256_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_2}
    AESKEYGENASSIST   XMM2, XMM2, $10
  {$DEFINE KeyExpand_256_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_1}
    AESKEYGENASSIST   XMM2, XMM2, $00
  {$DEFINE KeyExpand_256_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_2}
    AESKEYGENASSIST   XMM2, XMM2, $20
  {$DEFINE KeyExpand_256_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_1}
    AESKEYGENASSIST   XMM2, XMM2, $00
  {$DEFINE KeyExpand_256_RoundCommon_2}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_2}
    AESKEYGENASSIST   XMM2, XMM2, $40
  {$DEFINE KeyExpand_256_RoundCommon_1}{$INCLUDE '.\AES_Assembly.inc'}{$UNDEF KeyExpand_256_RoundCommon_1}
{$ENDIF}
end;

//==============================================================================

procedure AESNI_KeyExpand_Dec(KeySchedule: Pointer; Repeats: UInt32); register; assembler;
asm
@Cycle:
    ADD     KeySchedule,  16
  {$IFDEF ASM_MachineCode}
    DB  $66, $0F, $38, $DB, $00   //  AESIMC  XMM0, dqword ptr [EAX]
  {$ELSE}
    AESIMC  XMM0, dqword ptr [KeySchedule]
  {$ENDIF}
    MOVAPS  dqword ptr [KeySchedule], XMM0

    DEC     Repeats
    JNZ     @Cycle
end;

//==============================================================================

procedure AESNI_Encrypt(Input, Output, KeySchedule: Pointer; Rounds: UInt8); register; assembler;
asm
    // load input
    MOVUPS      XMM0, dqword ptr [Input]
    PXOR        XMM0, dqword ptr [KeySchedule]
    ADD         KeySchedule,  16

    // first 9 rounds
  {$IFDEF ASM_MachineCode}
    DB  $66, $0F, $38, $DC, $01                     //  AESENC  XMM0, dqword ptr [ECX]
    DB  $66, $0F, $38, $DC, $41, $10                //  AESENC  XMM0, dqword ptr [ECX + 16]
    DB  $66, $0F, $38, $DC, $41, $20                //  AESENC  XMM0, dqword ptr [ECX + 32]
    DB  $66, $0F, $38, $DC, $41, $30                //  AESENC  XMM0, dqword ptr [ECX + 48]
    DB  $66, $0F, $38, $DC, $41, $40                //  AESENC  XMM0, dqword ptr [ECX + 64]
    DB  $66, $0F, $38, $DC, $41, $50                //  AESENC  XMM0, dqword ptr [ECX + 80]
    DB  $66, $0F, $38, $DC, $41, $60                //  AESENC  XMM0, dqword ptr [ECX + 96]
    DB  $66, $0F, $38, $DC, $41, $70                //  AESENC  XMM0, dqword ptr [ECX + 112]
    DB  $66, $0F, $38, $DC, $81, $80, $00, $00, $00 //  AESENC  XMM0, dqword ptr [ECX + 128]
  {$ELSE}
    AESENC      XMM0, dqword ptr [KeySchedule]
    AESENC      XMM0, dqword ptr [KeySchedule + 16]
    AESENC      XMM0, dqword ptr [KeySchedule + 32]
    AESENC      XMM0, dqword ptr [KeySchedule + 48]
    AESENC      XMM0, dqword ptr [KeySchedule + 64]
    AESENC      XMM0, dqword ptr [KeySchedule + 80]
    AESENC      XMM0, dqword ptr [KeySchedule + 96]
    AESENC      XMM0, dqword ptr [KeySchedule + 112]
    AESENC      XMM0, dqword ptr [KeySchedule + 128]
  {$ENDIF}
    ADD         KeySchedule,  144
    CMP         Rounds,       10
    JNA         @LastRound

    // 12 rounds (192bit key)
  {$IFDEF ASM_MachineCode}
    DB  $66, $0F, $38, $DC, $01       //  AESENC  XMM0, dqword ptr [ECX]
    DB  $66, $0F, $38, $DC, $41, $10  //  AESENC  XMM0, dqword ptr [ECX + 16]
  {$ELSE}
    AESENC      XMM0, dqword ptr [KeySchedule]
    AESENC      XMM0, dqword ptr [KeySchedule + 16]
  {$ENDIF}
    ADD         KeySchedule,  32
    CMP         Rounds,       12
    JNA         @LastRound

    // 14 rounds (256bit key)
  {$IFDEF ASM_MachineCode}
    DB  $66, $0F, $38, $DC, $01       //  AESENC  XMM0, dqword ptr [ECX]
    DB  $66, $0F, $38, $DC, $41, $10  //  AESENC  XMM0, dqword ptr [ECX + 16]
  {$ELSE}
    AESENC      XMM0, dqword ptr [KeySchedule]
    AESENC      XMM0, dqword ptr [KeySchedule + 16]
  {$ENDIF}
    ADD         KeySchedule,  32

@LastRound:
  {$IFDEF ASM_MachineCode}
    DB  $66, $0F, $38, $DD, $01       // AESENCLAST  XMM0, dqword ptr [ECX]
  {$ELSE}
    AESENCLAST  XMM0, dqword ptr [KeySchedule]
  {$ENDIF}

    // store output
    MOVUPS      dqword ptr [Output],  XMM0
end;

//------------------------------------------------------------------------------

procedure AESNI_Decrypt(Input, Output, KeySchedule: Pointer; Rounds: UInt8); register; assembler;
asm
    // load input
    MOVUPS      XMM0, dqword ptr [Input]
    PXOR        XMM0, dqword ptr [KeySchedule]

    // first 9 rounds
    SUB         KeySchedule,  144
  {$IFDEF ASM_MachineCode}
    DB  $66, $0F, $38, $DE, $81, $80, $00, $00, $00 //  AESDEC  XMM0, dqword ptr [ECX + 128]
    DB  $66, $0F, $38, $DE, $41, $70                //  AESDEC  XMM0, dqword ptr [ECX + 112]
    DB  $66, $0F, $38, $DE, $41, $60                //  AESDEC  XMM0, dqword ptr [ECX + 96]
    DB  $66, $0F, $38, $DE, $41, $50                //  AESDEC  XMM0, dqword ptr [ECX + 80]
    DB  $66, $0F, $38, $DE, $41, $40                //  AESDEC  XMM0, dqword ptr [ECX + 64]
    DB  $66, $0F, $38, $DE, $41, $30                //  AESDEC  XMM0, dqword ptr [ECX + 48]
    DB  $66, $0F, $38, $DE, $41, $20                //  AESDEC  XMM0, dqword ptr [ECX + 32]
    DB  $66, $0F, $38, $DE, $41, $10                //  AESDEC  XMM0, dqword ptr [ECX + 16]
    DB  $66, $0F, $38, $DE, $01                     //  AESDEC  XMM0, dqword ptr [ECX]
  {$ELSE}
    AESDEC      XMM0, dqword ptr [KeySchedule + 128]
    AESDEC      XMM0, dqword ptr [KeySchedule + 112]
    AESDEC      XMM0, dqword ptr [KeySchedule + 96]
    AESDEC      XMM0, dqword ptr [KeySchedule + 80]
    AESDEC      XMM0, dqword ptr [KeySchedule + 64]
    AESDEC      XMM0, dqword ptr [KeySchedule + 48]
    AESDEC      XMM0, dqword ptr [KeySchedule + 32]
    AESDEC      XMM0, dqword ptr [KeySchedule + 16]
    AESDEC      XMM0, dqword ptr [KeySchedule]
  {$ENDIF}
    CMP         Rounds,       10
    JNA         @LastRound

    // 12 rounds (192bit key)
    SUB         KeySchedule,  32
  {$IFDEF ASM_MachineCode}
    DB  $66, $0F, $38, $DE, $41, $10  //  AESDEC  XMM0, dqword ptr [ECX + 16]
    DB  $66, $0F, $38, $DE, $01       //  AESDEC  XMM0, dqword ptr [ECX]
  {$ELSE}
    AESDEC      XMM0, dqword ptr [KeySchedule + 16]
    AESDEC      XMM0, dqword ptr [KeySchedule]
  {$ENDIF}
    CMP         Rounds,       12
    JNA         @LastRound

    // 14 rounds (256bit key)
    SUB         KeySchedule,  32
  {$IFDEF ASM_MachineCode}
    DB  $66, $0F, $38, $DE, $41, $10  //  AESDEC  XMM0, dqword ptr [ECX + 16]
    DB  $66, $0F, $38, $DE, $01       //  AESDEC  XMM0, dqword ptr [ECX]
  {$ELSE}
    AESDEC      XMM0, dqword ptr [KeySchedule + 16]
    AESDEC      XMM0, dqword ptr [KeySchedule]
  {$ENDIF}

@LastRound:
    SUB         KeySchedule,  16
  {$IFDEF ASM_MachineCode}
    DB  $66, $0F, $38, $DF, $01       // AESDECLAST  XMM0, dqword ptr [ECX]
  {$ELSE}
    AESDECLAST  XMM0, dqword ptr [KeySchedule]
  {$ENDIF}

    // store output
    MOVUPS      dqword ptr [Output],  XMM0
end;

{$IFDEF ASMSuppressSizeWarnings}
  {$WARN 7122 ON}
  {$WARN 2087 ON}
{$ENDIF}

{------------------------------------------------------------------------------}
{   TAESCipherAccelerated - protected methods                                  }
{------------------------------------------------------------------------------}

procedure TAESCipherAccelerated.CipherInit;
begin
fAccelerated := AccelerationSupported;
fKeySchedulePtr := {%H-}Pointer(({%H-}PtrUInt(Addr(fKeySchedule)) + $F) and not PtrUInt($F));
If fAccelerated then
  begin
    case fKeyLength of
      r128bit:  AESNI_KeyExpand_128(fKey,fKeySchedulePtr);
      r192bit:  AESNI_KeyExpand_192(fKey,fKeySchedulePtr);
      r256bit:  AESNI_KeyExpand_256(fKey,fKeySchedulePtr);
    else
      raise Exception.CreateFmt('TAESCipherAccelerated.CipherInit: Unsupported key length (%d).',[Ord(fKeyLength)]);
    end;
    If (Mode = cmDecrypt) and not (ModeOfOperation in [moCFB,moOFB,moCTR]) then
      AESNI_KeyExpand_Dec(fKeySchedulePtr,UInt32(fNr - 1));
  end
else inherited CipherInit;
{
  for decryption, change schedule pointer so it points to the last four words,
  not at the beginning
}
If (Mode = cmDecrypt) and not (ModeOfOperation in [moCFB,moOFB,moCTR]) then
  fKeySchedulePtr := {%H-}Pointer({%H-}PtrUInt(fKeySchedulePtr) + PtrUInt(fNr * fNb * SizeOf(TRijWord)));
end;

//------------------------------------------------------------------------------

procedure TAESCipherAccelerated.CipherEncrypt(const Input; out Output);
begin
If fAccelerated then
  AESNI_Encrypt(@Input,@Output,fKeySchedulePtr,UInt8(fNr))
else
  inherited CipherEncrypt(Input,Output);
end;

//------------------------------------------------------------------------------

procedure TAESCipherAccelerated.CipherDecrypt(const Input; out Output);
begin
If fAccelerated then
  AESNI_Decrypt(@Input,@Output,fKeySchedulePtr,UInt8(fNr))
else
  inherited CipherDecrypt(Input,Output);
end;

{------------------------------------------------------------------------------}
{   TAESCipherAccelerated - public methods                                     }
{------------------------------------------------------------------------------}

class Function TAESCipherAccelerated.AccelerationSupported: Boolean;
begin
with TSimpleCPUID.Create do
try
  Result := Info.SupportedExtensions.AES;
finally
  Free;
end;
end;

{$ENDIF PurePascal}

end.

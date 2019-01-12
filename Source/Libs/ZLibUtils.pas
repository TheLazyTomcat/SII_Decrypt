{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  ZLibUtils

    Utility classes for data (de)compression build on zlib library.

  ©František Milt 2018-05-03

  Version 1.0.3

  Dependencies:
    AuxTypes     - github.com/ncs-sniper/Lib.AuxTypes
    AuxClasses   - github.com/ncs-sniper/Lib.AuxClasses
    MemoryBuffer - github.com/ncs-sniper/Lib.MemoryBuffer
  * StrRect      - github.com/ncs-sniper/Lib.StrRect    
    ZLib         - github.com/ncs-sniper/Bnd.ZLib

  StrRect is required only when dynamically linked zlib is used (see symbol
  ZLib_Static for details).

===============================================================================}
unit ZLibUtils;

{$IFDEF FPC}
  {$MODE Delphi}
  {$DEFINE FPC_DisableWarns}
  {$MACRO ON}
{$ENDIF}

{
  ZLib_Static

  When defined, a statically linked zlib is used (unit ZLibStatic). When not,
  a dynamically linked zlib (a DLL) is used (unit ZLibDynamic) - note that zlib
  library initialization and finalization is done automatically.
  Defined by default.
}
{$DEFINE ZLib_Static}

interface

uses
  SysUtils, Classes,
  AuxTypes, AuxClasses, MemoryBuffer,
  ZLibCommon;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W3031:={$WARN 3031 OFF}} // Values in enumeration types have to be ascending
{$ENDIF}

{===============================================================================
    Types, constants and auxiliary classes
===============================================================================}
type
  TZCompressionLevel = (
    zclNoCompression   = Z_NO_COMPRESSION,
    zclBestSpeed       = Z_BEST_SPEED,
    zclBestCompression = Z_BEST_COMPRESSION,
  {$IFDEF FPCDWM}{$PUSH}W3031{$ENDIF}
    zclDefault         = Z_DEFAULT_COMPRESSION,
  {$IFDEF FPCDWM}{$POP}{$ENDIF}
    zclLevel0          = 0,
    zclLevel1          = 1,
    zclLevel2          = 2,
    zclLevel3          = 3,
    zclLevel4          = 4,
    zclLevel5          = 5,
    zclLevel6          = 6,
    zclLevel7          = 7,
    zclLevel8          = 8,
    zclLevel9          = 9);

  TZMemLevel = (
    zmlDefault = DEF_MEM_LEVEL,
  {$IFDEF FPCDWM}{$PUSH}W3031{$ENDIF}
    zmlLevel1  = 1,
  {$IFDEF FPCDWM}{$POP}{$ENDIF}
    zmlLevel2  = 2,
    zmlLevel3  = 3,
    zmlLevel4  = 4,
    zmlLevel5  = 5,
    zmlLevel6  = 6,
    zmlLevel7  = 7,
    zmlLevel8  = 8,
    zmlLevel9  = 9);

  TZStrategy = (
    zsFiltered = Z_FILTERED,
    zsHuffman  = Z_HUFFMAN_ONLY,
    zsRLE      = Z_RLE,
    zsFixed    = Z_FIXED,
  {$IFDEF FPCDWM}{$PUSH}W3031{$ENDIF}
    zsDefault  = Z_DEFAULT_STRATEGY);
  {$IFDEF FPCDWM}{$POP}{$ENDIF}

{$IFDEF FPCDWM}{$PUSH}W3031{$ENDIF}
  TZStreamType = (zstZLib,zstGZip,zstRaw,zstDefault = zstZLib);
{$IFDEF FPCDWM}{$POP}{$ENDIF}

  EZError = class(Exception)
  public
    constructor ZCreate(ErrCode: int; ZStream: z_stream);
  end;

  EZCompressionError   = class(EZError);
  EZDecompressionError = class(EZError);

const
  ZInvalidOp = 'Invalid operation';

  PROC_BUFFSIZE = 1024 * 1024;  {1MiB}
  STRM_BUFFSIZE = 1024 * 1024;  {1MiB}
  BUFF_BUFFSIZE = 1024 * 1024;  {1MiB}
  INTR_BUFFSIZE = 1024 * 1024;  {1MiB}

{-------------------------------------------------------------------------------
================================================================================
                                  TZProcessor
================================================================================
-------------------------------------------------------------------------------}

type
  TZProcessorOutEvent = procedure(Sender: TObject; Data: Pointer; Size: TMemSize) of object;
  TZProcessorOutCallback = procedure(Sender: TObject; Data: Pointer; Size: TMemSize);

{===============================================================================
    TZProcessor - class declaration
===============================================================================}
  TZProcessor = class(TCustomObject)
  protected
    fZLibState:         z_stream;
    fOutBuffer:         TMemoryBuffer;
    fTotalCompressed:   UInt64;
    fTotalUncompressed: UInt64;
    fOnOutputEvent:     TZProcessorOutEvent;
    fOnOutputCallback:  TZProcessorOutCallback;
    fUserData:          PtrInt;
    Function GetCompressionRatio: Double;
    procedure DoOutput(OutSize: TMemSize); virtual;
  public
    procedure Init; virtual;
    Function Update(const Data; Size: uInt): uInt; virtual; abstract;
    procedure Final; virtual;
    property TotalCompressed: UInt64 read fTotalCompressed;
    property TotalUncompressed: UInt64 read fTotalUncompressed;
    property CompressionRatio: Double read GetCompressionRatio;
    property OnOutputEvent: TZProcessorOutEvent read fOnOutputEvent write fOnOutputEvent;
    property OnOutputCallback: TZProcessorOutCallback read fOnOutputCallback write fOnOutputCallback;
    property UserData: PtrInt read fUserData write fUserData;
  end;

{-------------------------------------------------------------------------------
================================================================================
                                  TZCompressor
================================================================================
-------------------------------------------------------------------------------}
{===============================================================================
    TZCompressor - class declaration
===============================================================================}
  TZCompressor = class(TZProcessor)
  protected
    fCompressionLevel:  TZCompressionLevel;
    fMemLevel:          TZMemLevel;
    fStrategy:          TZStrategy;
    fWindowBits:        int;
  public
    constructor Create(CompressionLevel: TZCompressionLevel; MemLevel: TZMemLevel; Strategy: TZStrategy; WindowBits: int); overload;
    constructor Create(CompressionLevel: TZCompressionLevel; MemLevel: TZMemLevel; Strategy: TZStrategy; StreamType: TZStreamType); overload;
    constructor Create(CompressionLevel: TZCompressionLevel; WindowBits: int); overload;
    constructor Create(CompressionLevel: TZCompressionLevel; StreamType: TZStreamType); overload;
    constructor Create(CompressionLevel: TZCompressionLevel = zclDefault); overload;
    procedure Init; override;
    Function Update(const Data; Size: uInt): uInt; override;
    procedure Final; override;
    property CompressionLevel: TZCompressionLevel read fCompressionLevel;
    property MemLevel: TZMemLevel read fMemLevel;
    property Strategy: TZStrategy read fStrategy;
    property WindowBits: int read fWindowBits;
  end;

{-------------------------------------------------------------------------------
================================================================================
                                 TZDecompressor
================================================================================
-------------------------------------------------------------------------------}
{===============================================================================
    TZDecompressor - class declaration
===============================================================================}
  TZDecompressor = class(TZProcessor)
  protected
    fWindowBits:  int;
  public
    constructor Create(WindowBits: int); overload;
    constructor Create(StreamType: TZStreamType = zstDefault); overload;
    procedure Init; override;
    Function Update(const Data; Size: uInt): uInt; override;
    procedure Final; override;
    property WindowBits: int read fWindowBits write fWindowBits;
  end;

{-------------------------------------------------------------------------------
================================================================================
                                 TZCustomStream
================================================================================
-------------------------------------------------------------------------------}
{===============================================================================
    TZCustomStream - class declaration
===============================================================================}
  TZCustomStream = class(TStream)
  protected
    fZLibState:         z_stream;
    fBuffer:            TMemoryBuffer;
    fTotalCompressed:   UInt64;
    fTotalUncompressed: UInt64;
    fOnProgress:        TNotifyEvent;
    Function GetCompressionRatio: Double;
    procedure DoProgress; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Final; virtual; abstract;
    property TotalCompressed: UInt64 read fTotalCompressed;
    property TotalUncompressed: UInt64 read fTotalUncompressed;
    property CompressionRatio: Double read GetCompressionRatio;
    property OnProgress: TNotifyEvent read fOnProgress write fOnProgress;
  end;

{-------------------------------------------------------------------------------
================================================================================
                              TZCompressionStream
================================================================================
-------------------------------------------------------------------------------}
{===============================================================================
    TZCompressionStream - class declaration
===============================================================================}
  TZCompressionStream = class(TZCustomStream)
  protected
    fCompressionLevel:  TZCompressionLevel;
    fMemLevel:          TZMemLevel;
    fStrategy:          TZStrategy;
    fWindowBits:        int;
    fDestination:       TStream;    
  public
    constructor Create(Dest: TStream; CompressionLevel: TZCompressionLevel; MemLevel: TZMemLevel; Strategy: TZStrategy; WindowBits: int); overload;
    constructor Create(Dest: TStream; CompressionLevel: TZCompressionLevel; MemLevel: TZMemLevel; Strategy: TZStrategy; StreamType: TZStreamType); overload;
    constructor Create(Dest: TStream; CompressionLevel: TZCompressionLevel; WindowBits: int); overload;
    constructor Create(Dest: TStream; CompressionLevel: TZCompressionLevel; StreamType: TZStreamType); overload;
    constructor Create(Dest: TStream; CompressionLevel: TZCompressionLevel = zclDefault); overload;
    destructor Destroy; override;
    Function Read(var Buffer; Count: LongInt): LongInt; override;
    Function Write(const Buffer; Count: LongInt): LongInt; override;
    Function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    Function CompressFrom(Source: TStream): Int64; virtual;
    procedure Final; override;
    property CompressionLevel: TZCompressionLevel read fCompressionLevel;
    property MemLevel: TZMemLevel read fMemLevel;
    property Strategy: TZStrategy read fStrategy;
    property WindowBits: int read fWindowBits;
  end;

{-------------------------------------------------------------------------------
================================================================================
                             TZDecompressionStream
================================================================================
-------------------------------------------------------------------------------}
{===============================================================================
    TZDecompressionStream - class declaration
===============================================================================}
  TZDecompressionStream = class(TZCustomStream)
  protected
    fWindowBits:    int;
    fSource:        TStream;
    fTransferOff:   PtrUInt;
  public
    constructor Create(Src: TStream; WindowBits: int); overload;
    constructor Create(Src: TStream; StreamType: TZStreamType = zstDefault); overload;
    destructor Destroy; override;
    Function Read(var Buffer; Count: LongInt): LongInt; override;
    Function Write(const Buffer; Count: LongInt): LongInt; override;
    Function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    Function ExtractTo(Destination: TStream): Int64; virtual;
    procedure Final; override;
    property WindowBits: int read fWindowBits;
  end;

{-------------------------------------------------------------------------------
================================================================================
                                 TZCustomBuffer
================================================================================
-------------------------------------------------------------------------------}

  TZBufferProgressEvent = procedure(Sender: TObject; Progress: Double) of Object;

{===============================================================================
    TZCustomBuffer - class declaration
===============================================================================}
  TZCustomBuffer = class(TCustomObject)
  protected
    fFreeResult:        Boolean;
    fSource:            TMemoryBuffer;
    fBuffer:            TMemoryBuffer;
    fResult:            TMemoryBuffer;
    fTotalCompressed:   UInt64;
    fTotalUncompressed: UInt64;
    fExpctdResultSize:  TMemSize;
    fOnProgress:        TZBufferProgressEvent;
    Function GetCompressionRatio: Double;
    procedure ProcessorHandler(Sender: TObject; Data: Pointer; Size: TMemSize); virtual; abstract;
    procedure DoProgress; virtual; abstract;
    procedure ZInit; virtual; abstract;
    Function ZUpdate: Boolean; virtual; abstract;    
    procedure ZFinal; virtual; abstract;
  public
    constructor Create(Src: TMemoryBuffer);
    destructor Destroy; override;
    procedure Process; virtual;
    property Source: TMemoryBuffer read fSource;
    property FreeResult: Boolean read fFreeResult write fFreeResult;
    property Result: TMemoryBuffer read fResult;
    property ResultMemory: Pointer read fResult.Memory;
    property ResultSize: TMemSize read fResult.Size;
    property TotalCompressed: UInt64 read fTotalCompressed;
    property TotalUncompressed: UInt64 read fTotalUncompressed;
    property CompressionRatio: Double read GetCompressionRatio;
    property ExpectedResultSize: TMemSize read fExpctdResultSize write fExpctdResultSize;
    property OnProgress: TZBufferProgressEvent read fOnProgress write fOnProgress;
  end;

{-------------------------------------------------------------------------------
================================================================================
                              TZCompressionBuffer
================================================================================
-------------------------------------------------------------------------------}
{===============================================================================
    TZCompressionBuffer - class declaration
===============================================================================}
  TZCompressionBuffer = class(TZCustomBuffer)
  protected
    fCompressor:        TZCompressor;
    fCompressionLevel:  TZCompressionLevel;
    fMemLevel:          TZMemLevel;
    fStrategy:          TZStrategy;
    fWindowBits:        int;
    procedure ProcessorHandler(Sender: TObject; Data: Pointer; Size: TMemSize); override;
    procedure DoProgress; override;
    procedure ZInit; override;
    Function ZUpdate: Boolean; override;
    procedure ZFinal; override;
  public
    constructor Create(Src: TMemoryBuffer; CompressionLevel: TZCompressionLevel; MemLevel: TZMemLevel; Strategy: TZStrategy; WindowBits: int); overload;
    constructor Create(Src: TMemoryBuffer; CompressionLevel: TZCompressionLevel; MemLevel: TZMemLevel; Strategy: TZStrategy; StreamType: TZStreamType); overload;
    constructor Create(Src: TMemoryBuffer; CompressionLevel: TZCompressionLevel; WindowBits: int); overload;
    constructor Create(Src: TMemoryBuffer; CompressionLevel: TZCompressionLevel; StreamType: TZStreamType); overload;
    constructor Create(Src: TMemoryBuffer; CompressionLevel: TZCompressionLevel = zclDefault); overload;
    constructor Create(Src: Pointer; SrcSize: TMemSize; CompressionLevel: TZCompressionLevel; MemLevel: TZMemLevel; Strategy: TZStrategy; WindowBits: int); overload;
    constructor Create(Src: Pointer; SrcSize: TMemSize; CompressionLevel: TZCompressionLevel; MemLevel: TZMemLevel; Strategy: TZStrategy; StreamType: TZStreamType); overload;
    constructor Create(Src: Pointer; SrcSize: TMemSize; CompressionLevel: TZCompressionLevel; WindowBits: int); overload;
    constructor Create(Src: Pointer; SrcSize: TMemSize; CompressionLevel: TZCompressionLevel; StreamType: TZStreamType); overload;
    constructor Create(Src: Pointer; SrcSize: TMemSize; CompressionLevel: TZCompressionLevel = zclDefault); overload;
    property CompressionLevel: TZCompressionLevel read fCompressionLevel;
    property MemLevel: TZMemLevel read fMemLevel;
    property Strategy: TZStrategy read fStrategy;
    property WindowBits: int read fWindowBits;
  end;

{-------------------------------------------------------------------------------
================================================================================
                             TZDecompressionBuffer
================================================================================
-------------------------------------------------------------------------------}
{===============================================================================
    TZDecompressionBuffer - class declaration
===============================================================================}
  TZDecompressionBuffer = class(TZCustomBuffer)
  protected
    fDecompressor:  TZDecompressor;
    fWindowBits:    int;
    procedure ProcessorHandler(Sender: TObject; Data: Pointer; Size: TMemSize); override;
    procedure DoProgress; override;
    procedure ZInit; override;
    Function ZUpdate: Boolean; override;
    procedure ZFinal; override;    
  public
    constructor Create(Src: TMemoryBuffer; WindowBits: int); overload;
    constructor Create(Src: TMemoryBuffer; StreamType: TZStreamType = zstDefault); overload;
    constructor Create(Src: Pointer; SrcSize: TMemSize; WindowBits: int); overload;
    constructor Create(Src: Pointer; SrcSize: TMemSize; StreamType: TZStreamType = zstDefault); overload;
    property WindowBits: int read fWindowBits;    
  end;

implementation

uses
{$IFDEF ZLib_Static}
  ZLibStatic;
{$ELSE}
  ZLibDynamic;
{$ENDIF}

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W4055:={$WARN 4055 OFF}} // Conversion between ordinals and pointers is not portable
  {$DEFINE W4056:={$WARN 4056 OFF}} // Conversion between ordinals and pointers is not portable
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
{$ENDIF}

{===============================================================================
    Auxiliary functions
===============================================================================}

Function CompressionErrCheck(ErrCode: int; State: z_stream; RaiseDictionaryError: Boolean = True): int;
begin
Result := ErrCode;
If (ErrCode < 0) or ((ErrCode = Z_NEED_DICT) and RaiseDictionaryError) then
  raise EZCompressionError.ZCreate(ErrCode,State)
end;

//------------------------------------------------------------------------------

Function DecompressionErrCheck(ErrCode: int; State: z_stream; RaiseDictionaryError: Boolean = True): int;
begin
Result := ErrCode;
If (ErrCode < 0) or ((ErrCode = Z_NEED_DICT) and RaiseDictionaryError) then
  raise EZDecompressionError.ZCreate(ErrCode,State);
end;

//------------------------------------------------------------------------------

Function GetStreamTypeWBits(StreamType: TZStreamType): int;
begin
case StreamType of
  zstZLib:  Result := WBITS_ZLIB;
  zstGZip:  Result := WBITS_GZIP;
  zstRaw:   Result := WBITS_RAW;
else
  raise EZError.CreateFmt('GetStreamTypeWBits: Unknown stream type (%d).',[Ord(StreamType)]);
end;
end;

{===============================================================================
    Auxiliary classes - implementation
===============================================================================}

constructor EZError.ZCreate(ErrCode: int; ZStream: z_stream);
begin
If Assigned(ZStream.msg) then
  CreateFmt('%s (%s)',[zError(ErrCode),ZStream.msg])
else
  CreateFmt('%s',[zError(ErrCode)])
end;

{-------------------------------------------------------------------------------
================================================================================
                                  TZProcessor
================================================================================
-------------------------------------------------------------------------------}
{===============================================================================
    TZProcessor - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TZProcessor - protected methods
-------------------------------------------------------------------------------}

Function TZProcessor.GetCompressionRatio: Double;
begin
If fTotalCompressed <> 0 then
  Result := fTotalUncompressed / fTotalCompressed
else
  Result := 0.0;
end;

//------------------------------------------------------------------------------

procedure TZProcessor.DoOutput(OutSize: TMemSize);
begin
If OutSize > 0 then
  begin
    If Assigned(fOnOutputEvent) then
      fOnOutputEvent(Self,fOutBuffer.Memory,OutSize);
    If Assigned(fOnOutputCallback) then
      fOnOutputCallback(Self,fOutBuffer.Memory,OutSize);
  end;
end;

{-------------------------------------------------------------------------------
    TZProcessor - public methods
-------------------------------------------------------------------------------}

procedure TZProcessor.Init;
begin
FillChar(fZLibState,SizeOf(fZLibState),0);
GetBuffer(fOutBuffer,PROC_BUFFSIZE);
fTotalCompressed := 0;
fTotalUncompressed := 0;
end;

//------------------------------------------------------------------------------

procedure TZProcessor.Final;
begin
FreeBuffer(fOutBuffer);
end;


{-------------------------------------------------------------------------------
================================================================================
                                  TZCompressor
================================================================================
-------------------------------------------------------------------------------}
{===============================================================================
    TZCompressor - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TZCompressor - public methods
-------------------------------------------------------------------------------}

constructor TZCompressor.Create(CompressionLevel: TZCompressionLevel; MemLevel: TZMemLevel; Strategy: TZStrategy; WindowBits: int);
begin
inherited Create;
fCompressionLevel := CompressionLevel;
fMemLevel := MemLevel;
fStrategy := Strategy;
fWindowBits := WindowBits;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZCompressor.Create(CompressionLevel: TZCompressionLevel; MemLevel: TZMemLevel; Strategy: TZStrategy; StreamType: TZStreamType);
begin
Create(CompressionLevel,MemLevel,Strategy,GetStreamTypeWBits(StreamType));
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZCompressor.Create(CompressionLevel: TZCompressionLevel; WindowBits: int);
begin
Create(CompressionLevel,zmlDefault,zsDefault,WindowBits);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZCompressor.Create(CompressionLevel: TZCompressionLevel; StreamType: TZStreamType);
begin
Create(CompressionLevel,zmlDefault,zsDefault,GetStreamTypeWBits(StreamType));
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZCompressor.Create(CompressionLevel: TZCompressionLevel = zclDefault);
begin
Create(CompressionLevel,zmlDefault,zsDefault,zstDefault);
end;

//------------------------------------------------------------------------------

procedure TZCompressor.Init;
begin
inherited;
CompressionErrCheck(deflateInit2(@fZLibState,Ord(fCompressionLevel),Z_DEFLATED,fWindowBits,Ord(fMemLevel),Ord(fStrategy)),fZLibState);
end;

//------------------------------------------------------------------------------

Function TZCompressor.Update(const Data; Size: uInt): uInt;
var
  OutSize:  TMemSize;
begin
If Size > 0 then
  begin
    Inc(fTotalUncompressed,Size);
    fZLibState.next_in := @Data;
    fZLibState.avail_in := Size;
    repeat
      fZLibState.next_out := fOutBuffer.Memory;
      fZLibState.avail_out := uInt(fOutBuffer.Size);
      CompressionErrCheck(deflate(@fZLibState,Z_NO_FLUSH),fZLibState);
      OutSize := TMemSize(fOutBuffer.Size - TMemSize(fZLibState.avail_out));
      Inc(fTotalCompressed,OutSize);
      DoOutput(OutSize);
    until fZLibState.avail_in <= 0;
    Result := Size - fZLibState.avail_in;
  end
else Result := 0;
end;

//------------------------------------------------------------------------------

procedure TZCompressor.Final;
var
  ResultCode: int;
  OutSize:    TMemSize;
begin
try
  // flush what is left in zlib internal state
  fZLibState.next_in := nil;
  fZLibState.avail_in := 0;
  repeat
    fZLibState.next_out := fOutBuffer.Memory;
    fZLibState.avail_out := uInt(fOutBuffer.Size);
    ResultCode := CompressionErrCheck(deflate(@fZLibState,Z_FINISH),fZLibState);
    OutSize := TMemSize(fOutBuffer.Size - TMemSize(fZLibState.avail_out));
    Inc(fTotalCompressed,OutSize);
    DoOutput(OutSize);
  until ResultCode = Z_STREAM_END;
finally
  CompressionErrCheck(deflateEnd(@fZLibState),fZLibState);
end;
inherited;
end;


{-------------------------------------------------------------------------------
================================================================================
                                 TZDecompressor
================================================================================
-------------------------------------------------------------------------------}
{===============================================================================
    TZDecompressor - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TZDecompressor - public methods
-------------------------------------------------------------------------------}

constructor TZDecompressor.Create(WindowBits: int);
begin
inherited Create;
fWindowBits := WindowBits;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZDecompressor.Create(StreamType: TZStreamType = zstDefault);
begin
Create(GetStreamTypeWBits(StreamType));
end;

//------------------------------------------------------------------------------

procedure TZDecompressor.Init;
begin
inherited;
DecompressionErrCheck(inflateInit2(@fZLibState,fWindowbits),fZLibState,True);
end;

//------------------------------------------------------------------------------

Function TZDecompressor.Update(const Data; Size: uInt): uInt;
var
  ResultCode: int;
  OutSize:    TMemSize;
begin
If Size > 0 then
  begin
    fZLibState.next_in := @Data;
    fZLibState.avail_in := Size;
    repeat
      fZLibState.next_out := fOutBuffer.Memory;
      fZLibState.avail_out := uInt(fOutBuffer.Size);
      ResultCode := DecompressionErrCheck(inflate(@fZLibState,Z_NO_FLUSH),fZLibState,True);
      OutSize := TMemSize(fOutBuffer.Size - TMemSize(fZLibState.avail_out));
      Inc(fTotalUncompressed,OutSize);
      DoOutput(OutSize);
    until (ResultCode = Z_STREAM_END) or (fZLibState.avail_in <= 0);
    Inc(fTotalCompressed,Size - fZLibState.avail_in);
    Result := Size - fZLibState.avail_in;
  end
else Result := 0;
end;

//------------------------------------------------------------------------------

procedure TZDecompressor.Final;
begin
DecompressionErrCheck(inflateEnd(@fZLibState),fZLibState,True);
inherited;
end;


{-------------------------------------------------------------------------------
================================================================================
                                 TZCustomStream
================================================================================
-------------------------------------------------------------------------------}
{===============================================================================
    TZCustomStream - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TZCustomStream - protected methods
-------------------------------------------------------------------------------}

Function TZCustomStream.GetCompressionRatio: Double;
begin
If fTotalCompressed <> 0 then
  Result := fTotalUncompressed / fTotalCompressed
else
  Result := 0.0;
end;

//------------------------------------------------------------------------------

procedure TZCustomStream.DoProgress;
begin
If Assigned(fOnProgress) then
  fOnProgress(Self);
end;

{-------------------------------------------------------------------------------
    TZCustomStream - public methods
-------------------------------------------------------------------------------}

constructor TZCustomStream.Create;
begin
inherited;
FillChar(fZLibState,SizeOf(fZLibState),0);
GetBuffer(fBuffer,STRM_BUFFSIZE);
fTotalCompressed := 0;
fTotalUncompressed := 0;
end;

//------------------------------------------------------------------------------

destructor TZCustomStream.Destroy;
begin
FreeBuffer(fBuffer);
inherited;
end;


{-------------------------------------------------------------------------------
================================================================================
                              TZCompressionStream
================================================================================
-------------------------------------------------------------------------------}
{===============================================================================
    TZCompressionStream - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TZCompressionStream - public methods
-------------------------------------------------------------------------------}

constructor TZCompressionStream.Create(Dest: TStream; CompressionLevel: TZCompressionLevel; MemLevel: TZMemLevel; Strategy: TZStrategy; WindowBits: int);
begin
inherited Create;
fCompressionLevel := CompressionLevel;
fMemLevel := MemLevel;
fStrategy := Strategy;
fWindowBits := WindowBits;
fDestination := Dest;
CompressionErrCheck(deflateInit2(@fZLibState,Ord(fCompressionLevel),Z_DEFLATED,fWindowBits,Ord(fMemLevel),Ord(fStrategy)),fZLibState);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZCompressionStream.Create(Dest: TStream; CompressionLevel: TZCompressionLevel; MemLevel: TZMemLevel; Strategy: TZStrategy; StreamType: TZStreamType);
begin
Create(Dest,CompressionLevel,MemLevel,Strategy,GetStreamTypeWBits(StreamType));
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZCompressionStream.Create(Dest: TStream; CompressionLevel: TZCompressionLevel; WindowBits: int);
begin
Create(Dest,CompressionLevel,zmlDefault,zsDefault,WindowBits);
end;
 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZCompressionStream.Create(Dest: TStream; CompressionLevel: TZCompressionLevel; StreamType: TZStreamType);
begin
Create(Dest,CompressionLevel,zmlDefault,zsDefault,GetStreamTypeWBits(StreamType));
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZCompressionStream.Create(Dest: TStream; CompressionLevel: TZCompressionLevel = zclDefault);
begin
Create(Dest,CompressionLevel,zmlDefault,zsDefault,zstDefault);
end;

//------------------------------------------------------------------------------

destructor TZCompressionStream.Destroy;
begin
try
  Final;
finally
  CompressionErrCheck(deflateEnd(@fZLibState),fZLibState);
end;
inherited;
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
Function TZCompressionStream.Read(var Buffer; Count: LongInt): LongInt;
begin
{$IFDEF FPC}
Result := 0;
{$ENDIf}
raise EZCompressionError.Create('TZCompressionStream.Read: ' + ZInvalidOp);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

Function TZCompressionStream.Write(const Buffer; Count: LongInt): LongInt;
var
  OutSize:  TMemSize;
begin
If Count > 0 then
  begin
    Inc(fTotalUncompressed,Count);
    fZLibState.next_in := @Buffer;
    fZLibState.avail_in := Count;
    repeat
      fZLibState.next_out := fBuffer.Memory;
      fZLibState.avail_out := uInt(fBuffer.Size);
      CompressionErrCheck(deflate(@fZLibState,Z_NO_FLUSH),fZLibState);
      OutSize := TMemSize(fBuffer.Size - TMemSize(fZLibState.avail_out));
      Inc(fTotalCompressed,OutSize);
      fDestination.WriteBuffer(fBuffer.Memory^,OutSize);
    until fZLibState.avail_in <= 0;
    Result := Count;
  end
else Result := 0;
DoProgress;
end;

//------------------------------------------------------------------------------

Function TZCompressionStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
If (Origin = soCurrent) and (Offset = 0) then
  Result := fTotalUncompressed
else
  raise EZCompressionError.Create('TZCompressionStream.Seek: ' + ZInvalidOp);
end;

//------------------------------------------------------------------------------

Function TZCompressionStream.CompressFrom(Source: TStream): Int64;
var
  Buffer: TMemoryBuffer;
begin
Result := 0;
GetBuffer(Buffer,INTR_BUFFSIZE);
try
  repeat
    Buffer.Data := Source.Read(Buffer.Memory^,INTR_BUFFSIZE);
    WriteBuffer(Buffer.Memory^,Buffer.Data);
    Inc(Result,Buffer.Data);
  until Buffer.Data < INTR_BUFFSIZE;
finally
  FreeBuffer(Buffer);
end;
end;

//------------------------------------------------------------------------------

procedure TZCompressionStream.Final;
var
  ResultCode: int;
  OutSize:    TMemSize;
begin
fZLibState.next_in := nil;
fZLibState.avail_in := 0;
repeat
  fZLibState.next_out := fBuffer.Memory;
  fZLibState.avail_out := uInt(fBuffer.Size);
  ResultCode := CompressionErrCheck(deflate(@fZLibState,Z_FINISH),fZLibState);
  OutSize := TMemSize(fBuffer.Size - TMemSize(fZLibState.avail_out));
  Inc(fTotalCompressed,OutSize);
  fDestination.WriteBuffer(fBuffer.Memory^,OutSize);
until ResultCode = Z_STREAM_END;
end;


{-------------------------------------------------------------------------------
================================================================================
                             TZDecompressionStream
================================================================================
-------------------------------------------------------------------------------}
{===============================================================================
    TZDecompressionStream - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TZDecompressionStream - public methods
-------------------------------------------------------------------------------}

constructor TZDecompressionStream.Create(Src: TStream; WindowBits: int);
begin
inherited Create;
fBuffer.Data := 0;
fWindowBits := WindowBits;
fSource := Src;
fTransferOff := 0;
DecompressionErrCheck(inflateInit2(@fZLibState,fWindowBits),fZLibState);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZDecompressionStream.Create(Src: TStream; StreamType: TZStreamType = zstDefault);
begin
Create(Src,GetStreamTypeWBits(StreamType));
end;

//------------------------------------------------------------------------------

destructor TZDecompressionStream.Destroy;
begin
try
  Final;
finally
  DecompressionErrCheck(inflateEnd(@fZLibState),fZLibState);
end;
inherited;
end;

//------------------------------------------------------------------------------

Function TZDecompressionStream.Read(var Buffer; Count: LongInt): LongInt;
var
  ResultCode: int;
begin
If Count > 0 then
  begin
    fZLibState.next_out := @Buffer;
    fZLibState.avail_out := uInt(Count);
    repeat
      If (fBuffer.Data > 0) and (fTransferOff > 0) then
        begin
        {$IFDEF FPCDWM}{$PUSH}W4055{$ENDIF}
          fZLibState.next_in := Pointer(PtrUInt(fBuffer.Memory) + fTransferOff);
        {$IFDEF FPCDWM}{$POP}{$ENDIF}
          fZLibState.avail_in := uInt(PtrUInt(fBuffer.Data) - fTransferOff);
        end
      else
        begin
          fBuffer.Data := fSource.Read(fBuffer.Memory^,fBuffer.Size);
          fZLibState.next_in := fBuffer.Memory;
          fZLibState.avail_in := uInt(fBuffer.Data);
          fTransferOff := 0;
        end;
      ResultCode := DecompressionErrCheck(inflate(@fZLibState,Z_NO_FLUSH),fZLibState,True);
      Inc(fTotalCompressed,PtrUInt(fBuffer.Data) - fTransferOff - PtrUInt(fZLibState.avail_in));
      If fZLibState.avail_in > 0 then
        fTransferOff := PtrUInt(fBuffer.Data) - PtrUInt(fZLibState.avail_in)
      else
        fTransferOff := 0;
    until (ResultCode = Z_STREAM_END) or (fZLibState.avail_out <= 0);
    Result := Count - LongInt(fZLibState.avail_out);
    Inc(fTotalUncompressed,Result);
  end
else Result := 0;
DoProgress;
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
Function TZDecompressionStream.Write(const Buffer; Count: LongInt): LongInt;
begin
{$IFDEF FPC}
Result := 0;
{$ENDIf}
raise EZCompressionError.Create('TZDecompressionStream.Write: ' + ZInvalidOp);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

Function TZDecompressionStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
If (Origin = soCurrent) and (Offset = 0) then
  Result := fSource.Position
else If (Origin = soBeginning) and (Offset = 0) and (fSource.Position = 0) then
  Result := 0
else
  raise EZCompressionError.Create('TZDecompressionStream.Seek: ' + ZInvalidOp);
end;

//------------------------------------------------------------------------------

Function TZDecompressionStream.ExtractTo(Destination: TStream): Int64;
var
  Buffer: TMemoryBuffer;
begin
Result := 0;
GetBuffer(Buffer,INTR_BUFFSIZE);
try
  repeat
    Buffer.Data := Read(Buffer.Memory^,INTR_BUFFSIZE);
    Destination.WriteBuffer(Buffer.Memory^,Buffer.Data);
    Inc(Result,Buffer.Data);
  until Buffer.Data < INTR_BUFFSIZE;
finally
  FreeBuffer(Buffer);
end;
end;

//------------------------------------------------------------------------------

procedure TZDecompressionStream.Final;
begin
// nothing to do here
end;


{-------------------------------------------------------------------------------
================================================================================
                                 TZCustomBuffer
================================================================================
-------------------------------------------------------------------------------}
{===============================================================================
    TZCustomBuffer - class declaration
===============================================================================}
{-------------------------------------------------------------------------------
    TZCustomBuffer - protected methods
-------------------------------------------------------------------------------}

Function TZCustomBuffer.GetCompressionRatio: Double;
begin
If fTotalCompressed <> 0 then
  Result := fTotalUncompressed / fTotalCompressed
else
  Result := 0.0;
end;

{-------------------------------------------------------------------------------
    TZCustomBuffer - public methods
-------------------------------------------------------------------------------}

constructor TZCustomBuffer.Create(Src: TMemoryBuffer);
begin
inherited Create;
fTotalCompressed := 0;
fTotalUncompressed := 0;
fFreeResult := True;
fSource := Src;
GetBuffer(fBuffer,BUFF_BUFFSIZE);
fExpctdResultSize := Src.Size;
end;

//------------------------------------------------------------------------------

destructor TZCustomBuffer.Destroy;
begin
FreeBuffer(fBuffer);
If fFreeResult then
  FreeBuffer(fResult);
inherited;
end;

//------------------------------------------------------------------------------

procedure TZCustomBuffer.Process;
begin
If fSource.Size > 0 then
  begin
    DoProgress;
    ZInit;
    try
      while ZUpdate do
        DoProgress;
    finally
      ZFinal;
    end;
    DoProgress;
  end;
end;


{-------------------------------------------------------------------------------
================================================================================
                              TZCompressionBuffer
================================================================================
-------------------------------------------------------------------------------}
{===============================================================================
    TZCompressionBuffer - class declaration
===============================================================================}
{-------------------------------------------------------------------------------
    TZCompressionBuffer - protected methods
-------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W4055 W4056 W5024{$ENDIF}
procedure TZCompressionBuffer.ProcessorHandler(Sender: TObject; Data: Pointer; Size: TMemSize);
begin
while (fTotalCompressed + Size) > fResult.Size do
  ReallocBuffer(fResult,((fResult.Size + (fResult.Size shr 1)) + 255) and not TMemSize(255));
Move(Data^,Pointer(PtrUInt(fResult.Memory) + fTotalCompressed)^,Size);
Inc(fTotalCompressed,Size);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

procedure TZCompressionBuffer.DoProgress;
begin
If Assigned(fOnProgress) then
  begin
    If fSource.Size <> 0 then
      fOnProgress(Self,fTotalUncompressed / fSource.Size)
    else
      fOnProgress(Self,0.0);
  end;
end;

//------------------------------------------------------------------------------

procedure TZCompressionBuffer.ZInit;
begin
GetBuffer(fResult,fExpctdResultSize);
fCompressor := TZCompressor.Create(fCompressionLevel,fMemLevel,fStrategy,fWindowBits);
fCompressor.OnOutputEvent := ProcessorHandler;
fCompressor.Init;
end;

//------------------------------------------------------------------------------

Function TZCompressionBuffer.ZUpdate: Boolean;
var
  Size:       TMemSize;
  Processed:  TMemSize;
begin
If (fTotalUncompressed + BUFF_BUFFSIZE) > fSource.Size then
  Size := fSource.Size - TMemSize(fTotalUncompressed)
else
  Size := BUFF_BUFFSIZE;
{$IFDEF FPCDWM}{$PUSH}W4055 W4056{$ENDIF}
Processed := fCompressor.Update(Pointer(PtrUInt(fSource.Memory) + fTotalUncompressed)^,Size);
{$IFDEF FPCDWM}{$POP}{$ENDIF}
Inc(fTotalUncompressed,Processed);
Result := (Processed >= Size) and (TMemSize(fTotalUncompressed) < fSource.Size);
end;

//------------------------------------------------------------------------------

procedure TZCompressionBuffer.ZFinal;
begin
fCompressor.Final;
fCompressor.Free;
ReallocBuffer(fResult,fTotalCompressed);
end;

{-------------------------------------------------------------------------------
    TZCompressionBuffer - public methods
-------------------------------------------------------------------------------}

constructor TZCompressionBuffer.Create(Src: TMemoryBuffer; CompressionLevel: TZCompressionLevel; MemLevel: TZMemLevel; Strategy: TZStrategy; WindowBits: int);
begin
inherited Create(Src);
fCompressionLevel := CompressionLevel;
fMemLevel := MemLevel;
fStrategy := Strategy;
fWindowBits := WindowBits;
fExpctdResultSize := Trunc(fSource.Size * 1.1);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZCompressionBuffer.Create(Src: TMemoryBuffer; CompressionLevel: TZCompressionLevel; MemLevel: TZMemLevel; Strategy: TZStrategy; StreamType: TZStreamType);
begin
Create(Src,CompressionLevel,MemLevel,Strategy,GetStreamTypeWBits(StreamType));
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZCompressionBuffer.Create(Src: TMemoryBuffer; CompressionLevel: TZCompressionLevel; WindowBits: int);
begin
Create(Src,CompressionLevel,zmlDefault,zsDefault,WindowBits);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZCompressionBuffer.Create(Src: TMemoryBuffer; CompressionLevel: TZCompressionLevel; StreamType: TZStreamType);
begin
Create(Src,CompressionLevel,zmlDefault,zsDefault,GetStreamTypeWBits(StreamType));
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZCompressionBuffer.Create(Src: TMemoryBuffer; CompressionLevel: TZCompressionLevel = zclDefault);
begin
Create(Src,CompressionLevel,zmlDefault,zsDefault,zstDefault);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZCompressionBuffer.Create(Src: Pointer; SrcSize: TMemSize; CompressionLevel: TZCompressionLevel; MemLevel: TZMemLevel; Strategy: TZStrategy; WindowBits: int);
begin
Create(BuildBuffer(Src,SrcSize),CompressionLevel,MemLevel,Strategy,WindowBits);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZCompressionBuffer.Create(Src: Pointer; SrcSize: TMemSize; CompressionLevel: TZCompressionLevel; MemLevel: TZMemLevel; Strategy: TZStrategy; StreamType: TZStreamType);
begin
Create(BuildBuffer(Src,SrcSize),CompressionLevel,MemLevel,Strategy,GetStreamTypeWBits(StreamType));
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZCompressionBuffer.Create(Src: Pointer; SrcSize: TMemSize; CompressionLevel: TZCompressionLevel; WindowBits: int);
begin
Create(BuildBuffer(Src,SrcSize),CompressionLevel,zmlDefault,zsDefault,WindowBits);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZCompressionBuffer.Create(Src: Pointer; SrcSize: TMemSize; CompressionLevel: TZCompressionLevel; StreamType: TZStreamType);
begin
Create(BuildBuffer(Src,SrcSize),CompressionLevel,zmlDefault,zsDefault,GetStreamTypeWBits(StreamType));
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZCompressionBuffer.Create(Src: Pointer; SrcSize: TMemSize; CompressionLevel: TZCompressionLevel = zclDefault);
begin
Create(BuildBuffer(Src,SrcSize),CompressionLevel,zmlDefault,zsDefault,zstDefault);
end;


{-------------------------------------------------------------------------------
================================================================================
                             TZDecompressionBuffer
================================================================================
-------------------------------------------------------------------------------}
{===============================================================================
    TZDecompressionBuffer - class declaration
===============================================================================}
{-------------------------------------------------------------------------------
    TZDecompressionBuffer - protected methods
-------------------------------------------------------------------------------}

{$IFDEF FPCDWM}{$PUSH}W4055 W4056 W5024{$ENDIF}
procedure TZDecompressionBuffer.ProcessorHandler(Sender: TObject; Data: Pointer; Size: TMemSize);
begin
while (fTotalUncompressed + Size) > fResult.Size do
  ReallocBuffer(fResult,((fResult.Size * 2) + 255) and not TMemSize(255));
Move(Data^,Pointer(PtrUInt(fResult.Memory) + fTotalUncompressed)^,Size);
Inc(fTotalUncompressed,Size);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

procedure TZDecompressionBuffer.DoProgress;
begin
If Assigned(fOnProgress) then
  begin
    If fSource.Size <> 0 then
      fOnProgress(Self,fTotalCompressed / fSource.Size)
    else
      fOnProgress(Self,0.0);
  end;
end;

//------------------------------------------------------------------------------

procedure TZDecompressionBuffer.ZInit;
begin
GetBuffer(fResult,fExpctdResultSize);
fDecompressor := TZDecompressor.Create(fWindowBits);
fDecompressor.OnOutputEvent := ProcessorHandler;
fDecompressor.Init;
end;

//------------------------------------------------------------------------------

Function TZDecompressionBuffer.ZUpdate: Boolean;
var
  Size:       TMemSize;
  Processed:  TMemSize;
begin
If (fTotalCompressed + BUFF_BUFFSIZE) > fSource.Size then
  Size := fSource.Size - TMemSize(fTotalCompressed)
else
  Size := BUFF_BUFFSIZE;
{$IFDEF FPCDWM}{$PUSH}W4055 W4056{$ENDIF}
Processed := fDecompressor.Update(Pointer(PtrUInt(fSource.Memory) + fTotalCompressed)^,Size);
{$IFDEF FPCDWM}{$POP}{$ENDIF}
Inc(fTotalCompressed,Processed);
Result := (Processed >= Size) and (TMemSize(fTotalCompressed) < fSource.Size);
end;

//------------------------------------------------------------------------------

procedure TZDecompressionBuffer.ZFinal;
begin
fDecompressor.Final;
fDecompressor.Free;
ReallocBuffer(fResult,fTotalUncompressed);
end;

{-------------------------------------------------------------------------------
    TZDecompressionBuffer - public methods
-------------------------------------------------------------------------------}

constructor TZDecompressionBuffer.Create(Src: TMemoryBuffer; WindowBits: int);
begin
inherited Create(Src);
fWindowBits := WindowBits;
fExpctdResultSize := fSource.Size * 2;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZDecompressionBuffer.Create(Src: TMemoryBuffer; StreamType: TZStreamType = zstDefault);
begin
Create(Src,GetStreamTypeWBits(StreamType));
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZDecompressionBuffer.Create(Src: Pointer; SrcSize: TMemSize; WindowBits: int);
begin
Create(BuildBuffer(Src,SrcSize),WindowBits);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TZDecompressionBuffer.Create(Src: Pointer; SrcSize: TMemSize; StreamType: TZStreamType = zstDefault);
begin
Create(BuildBuffer(Src,SrcSize),GetStreamTypeWBits(StreamType));
end;

{$IFNDEF ZLib_Static}
initialization
  ZLibDynamic.ZLib_Initialize;

finalization
  ZLibDynamic.ZLib_Finalize;
{$ENDIF}

end.

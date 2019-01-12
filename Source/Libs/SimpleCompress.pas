{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Simple (De)Compression routines (powered by ZLib)

  ©František Milt 2018-01-26

  Version 1.3

  Dependencies:
    AuxTypes     - github.com/ncs-sniper/Lib.AuxTypes
    AuxClasses   - github.com/ncs-sniper/Lib.AuxClasses
    StrRect      - github.com/ncs-sniper/Lib.StrRect
    MemoryBuffer - github.com/ncs-sniper/Lib.MemoryBuffer
    ZLib         - github.com/ncs-sniper/Bnd.ZLib
    ZLibUtils    - github.com/ncs-sniper/Lib.ZLibUtils

===============================================================================}
unit SimpleCompress;

{$IFDEF FPC}
  {$MODE ObjFPC}{$H+}
{$ENDIF}

interface

uses
  Classes, AuxTypes, ZLibUtils;

Function ZCompressBuffer(InBuff: Pointer; InSize: TMemSize; out OutBuff: Pointer; out OutSize: TMemSize; StreamType: TZStreamType = zstDefault): Boolean;
Function ZCompressStream(Stream: TStream; StreamType: TZStreamType = zstDefault): Boolean; overload;
Function ZCompressStream(InStream, OutStream: TStream; StreamType: TZStreamType = zstDefault): Boolean; overload;
Function ZCompressFile(const FileName: String; StreamType: TZStreamType = zstDefault): Boolean; overload;
Function ZCompressFile(const InFileName, OutFileName: String; StreamType: TZStreamType = zstDefault): Boolean; overload;

Function ZDecompressBuffer(InBuff: Pointer; InSize: TMemSize; out OutBuff: Pointer; out OutSize: TMemSize; StreamType: TZStreamType = zstDefault): Boolean;
Function ZDecompressStream(Stream: TStream; StreamType: TZStreamType = zstDefault): Boolean; overload;
Function ZDecompressStream(InStream, OutStream: TStream; StreamType: TZStreamType = zstDefault): Boolean; overload;
Function ZDecompressFile(const FileName: String; StreamType: TZStreamType = zstDefault): Boolean; overload;
Function ZDecompressFile(const InFileName, OutFileName: String; StreamType: TZStreamType = zstDefault): Boolean; overload;

implementation

uses
  SysUtils, MemoryBuffer, StrRect;

const
  COPY_BUFFER_SIZE = 1024 * 1024 {1MiB};

procedure CopyStream(Src,Dest: TStream);
var
  Buffer:     TMemoryBuffer;
  BytesRead:  Integer;
begin
GetBuffer(Buffer,COPY_BUFFER_SIZE);
try
  repeat
    BytesRead := Src.Read(Buffer.Memory^,Buffer.Size);
    Dest.WriteBuffer(Buffer.Memory^,BytesRead);
  until TMemSize(BytesRead) < Buffer.Size;
finally
  FreeBuffer(Buffer);
end;
end;

//==============================================================================

Function ZCompressBuffer(InBuff: Pointer; InSize: TMemSize; out OutBuff: Pointer; out OutSize: TMemSize; StreamType: TZStreamType = zstDefault): Boolean;
var
  Compressor: TZCompressionBuffer;
begin
try
  Compressor := TZCompressionBuffer.Create(InBuff,InSize,zclDefault,StreamType);
  try
    Compressor.Process;
    Compressor.FreeResult := False;
    OutBuff := Compressor.ResultMemory;
    OutSize := Compressor.ResultSize;
    Result := True;
  finally
    Compressor.Free;
  end;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function ZCompressStream(Stream: TStream; StreamType: TZStreamType = zstDefault): Boolean;
var
  TempStream: TMemoryStream;
begin
TempStream := TMemoryStream.Create;
try
  TempStream.Size := Stream.Size;
  Result := ZCompressStream(Stream,TempStream,StreamType);
  If Result then
    begin
      TempStream.Position := 0;
      Stream.Position := 0;
      CopyStream(TempStream,Stream);
      Stream.Size := Stream.Position;
    end;
finally
  TempStream.Free;
end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function ZCompressStream(InStream, OutStream: TStream; StreamType: TZStreamType = zstDefault): Boolean;
var
  Compressor: TZCompressionStream;
begin
try
  If InStream = OutStream then
    Result := ZCompressStream(InStream)
  else
    begin
      Compressor := TZCompressionStream.Create(OutStream,zclDefault,StreamType);
      try
        InStream.Position := 0;
        OutStream.Position := 0;
        CopyStream(InStream,Compressor);
        OutStream.Size := OutStream.Position;
        Result := True;
      finally
        Compressor.Free;
      end;
    end;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function ZCompressFile(const FileName: String; StreamType: TZStreamType = zstDefault): Boolean;
var
  FileStream: TFileStream;
begin
try
  FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenReadWrite or fmShareExclusive);
  try
    Result := ZCompressStream(FileStream,StreamType);
  finally
    FileStream.Free;
  end;
except
  Result := False;
end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function ZCompressFile(const InFileName, OutFileName: String; StreamType: TZStreamType = zstDefault): Boolean;
var
  InFileStream:   TFileStream;
  OutFileStream:  TFileStream;
begin
If AnsiSameText(InFileName,OutFileName) then
  Result := ZCompressFile(InFileName)
else
  begin
    InFileStream := TFileStream.Create(StrToRTL(InFileName),fmOpenRead or fmShareDenyWrite);
    try
      OutFileStream := TFileStream.Create(StrToRTL(OutFileName),fmCreate or fmShareExclusive);
      try
        Result := ZCompressStream(InFileStream,OutFileStream,StreamType);
      finally
        OutFileStream.Free;
      end;
    finally
      InFileStream.Free;
    end;
  end;
end;

//==============================================================================

Function ZDecompressBuffer(InBuff: Pointer; InSize: TMemSize; out OutBuff: Pointer; out OutSize: TMemSize; StreamType: TZStreamType = zstDefault): Boolean;
var
  Decompressor: TZDecompressionBuffer;
begin
try
  Decompressor := TZDecompressionBuffer.Create(InBuff,InSize,StreamType);
  try
    Decompressor.Process;
    Decompressor.FreeResult := False;
    OutBuff := Decompressor.ResultMemory;
    OutSize := Decompressor.ResultSize;
    Result := True;
  finally
    Decompressor.Free;
  end;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function ZDecompressStream(Stream: TStream; StreamType: TZStreamType = zstDefault): Boolean;
var
  TempStream: TMemoryStream;
begin
TempStream := TMemoryStream.Create;
try
  TempStream.Size := Stream.Size * 2;
  Result := ZDecompressStream(Stream,TempStream,StreamType);
  If Result then
    begin
      TempStream.Position := 0;
      Stream.Position := 0;
      CopyStream(TempStream,Stream);
      Stream.Size := Stream.Position;
    end;
finally
  TempStream.Free;
end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function ZDecompressStream(InStream, OutStream: TStream; StreamType: TZStreamType = zstDefault): Boolean;
var
  Decompressor: TZDecompressionStream;
begin
try
  If InStream = OutStream then
    Result := ZDecompressStream(InStream)
  else
    begin
      Decompressor := TZDecompressionStream.Create(InStream,StreamType);
      try
        InStream.Position := 0;
        OutStream.Position := 0;
        CopyStream(Decompressor,OutStream);
        OutStream.Size := OutStream.Position;
        Result := True;
      finally
        Decompressor.Free;
      end;
    end;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function ZDecompressFile(const FileName: String; StreamType: TZStreamType = zstDefault): Boolean;
var
  FileStream: TFileStream;
begin
try
  FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenReadWrite or fmShareExclusive);
  try
    Result := ZDecompressStream(FileStream,StreamType);
  finally
    FileStream.Free;
  end;
except
  Result := False;
end;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function ZDecompressFile(const InFileName, OutFileName: String; StreamType: TZStreamType = zstDefault): Boolean;
var
  InFileStream:   TFileStream;
  OutFileStream:  TFileStream;
begin
If AnsiSameText(InFileName,OutFileName) then
  Result := ZCompressFile(InFileName)
else
  begin
    InFileStream := TFileStream.Create(StrToRTL(InFileName),fmOpenRead or fmShareDenyWrite);
    try
      OutFileStream := TFileStream.Create(StrToRTL(OutFileName),fmCreate or fmShareExclusive);
      try
        Result := ZDecompressStream(InFileStream,OutFileStream,StreamType);
      finally
        OutFileStream.Free;
      end;
    finally
      InFileStream.Free;
    end;
  end;
end;

end.

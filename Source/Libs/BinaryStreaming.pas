{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Binary streaming

  ©František Milt 2017-09-14

  Version 1.4

  Dependencies:
    AuxTypes - github.com/ncs-sniper/Lib.AuxTypes
    StrRect  - github.com/ncs-sniper/Lib.StrRect

===============================================================================}
unit BinaryStreaming;

{$IFDEF FPC}
  {$MODE ObjFPC}{$H+}
{$ENDIF}

interface

uses
  Classes, AuxTypes;

{------------------------------------------------------------------------------}
{==============================================================================}
{                                Memory writing                                }
{==============================================================================}
{------------------------------------------------------------------------------}

Function Ptr_WriteBool(var Dest: Pointer; Value: ByteBool; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteBool(Dest: Pointer; Value: ByteBool): TMemSize; overload;

Function Ptr_WriteBoolean(var Dest: Pointer; Value: Boolean; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteBoolean(Dest: Pointer; Value: Boolean): TMemSize; overload;

//------------------------------------------------------------------------------

Function Ptr_WriteInt8(var Dest: Pointer; Value: Int8; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteInt8(Dest: Pointer; Value: Int8): TMemSize; overload;

Function Ptr_WriteUInt8(var Dest: Pointer; Value: UInt8; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteUInt8(Dest: Pointer; Value: UInt8): TMemSize; overload;

Function Ptr_WriteInt16(var Dest: Pointer; Value: Int16; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteInt16(Dest: Pointer; Value: Int16): TMemSize; overload;

Function Ptr_WriteUInt16(var Dest: Pointer; Value: UInt16; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteUInt16(Dest: Pointer; Value: UInt16): TMemSize; overload;

Function Ptr_WriteInt32(var Dest: Pointer; Value: Int32; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteInt32(Dest: Pointer; Value: Int32): TMemSize; overload;

Function Ptr_WriteUInt32(var Dest: Pointer; Value: UInt32; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteUInt32(Dest: Pointer; Value: UInt32): TMemSize; overload;

Function Ptr_WriteInt64(var Dest: Pointer; Value: Int64; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteInt64(Dest: Pointer; Value: Int64): TMemSize; overload;

Function Ptr_WriteUInt64(var Dest: Pointer; Value: UInt64; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteUInt64(Dest: Pointer; Value: UInt64): TMemSize; overload;

//------------------------------------------------------------------------------

Function Ptr_WriteFloat32(var Dest: Pointer; Value: Float32; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteFloat32(Dest: Pointer; Value: Float32): TMemSize; overload;

Function Ptr_WriteFloat64(var Dest: Pointer; Value: Float64; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteFloat64(Dest: Pointer; Value: Float64): TMemSize; overload;

//------------------------------------------------------------------------------

Function Ptr_WriteAnsiChar(var Dest: Pointer; Value: AnsiChar; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteAnsiChar(Dest: Pointer; Value: AnsiChar): TMemSize; overload;

Function Ptr_WriteUTF8Char(var Dest: Pointer; Value: UTF8Char; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteUTF8Char(Dest: Pointer; Value: UTF8Char): TMemSize; overload;

Function Ptr_WriteWideChar(var Dest: Pointer; Value: WideChar; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteWideChar(Dest: Pointer; Value: WideChar): TMemSize; overload;

Function Ptr_WriteChar(var Dest: Pointer; Value: Char; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteChar(Dest: Pointer; Value: Char): TMemSize; overload;

//------------------------------------------------------------------------------

Function Ptr_WriteShortString(var Dest: Pointer; const Str: ShortString; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteShortString(Dest: Pointer; const Str: ShortString): TMemSize; overload;

Function Ptr_WriteAnsiString(var Dest: Pointer; const Str: AnsiString; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteAnsiString(Dest: Pointer; const Str: AnsiString): TMemSize; overload;

Function Ptr_WriteUnicodeString(var Dest: Pointer; const Str: UnicodeString; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteUnicodeString(Dest: Pointer; const Str: UnicodeString): TMemSize; overload;

Function Ptr_WriteWideString(var Dest: Pointer; const Str: WideString; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteWideString(Dest: Pointer; const Str: WideString): TMemSize; overload;

Function Ptr_WriteUTF8String(var Dest: Pointer; const Str: UTF8String; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteUTF8String(Dest: Pointer; const Str: UTF8String): TMemSize; overload;

Function Ptr_WriteString(var Dest: Pointer; const Str: String; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteString(Dest: Pointer; const Str: String): TMemSize; overload;

//------------------------------------------------------------------------------

Function Ptr_WriteBuffer(var Dest: Pointer; const Buffer; Size: TMemSize; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteBuffer(Dest: Pointer; const Buffer; Size: TMemSize): TMemSize; overload;

//------------------------------------------------------------------------------

Function Ptr_WriteBytes(var Dest: Pointer; const Value: array of UInt8; Advance: Boolean): TMemSize; overload;
Function Ptr_WriteBytes(Dest: Pointer; const Value: array of UInt8): TMemSize; overload;

//------------------------------------------------------------------------------

Function Ptr_FillBytes(var Dest: Pointer; Count: TMemSize; Value: UInt8; Advance: Boolean): TMemSize; overload;
Function Ptr_FillBytes(Dest: Pointer; Count: TMemSize; Value: UInt8): TMemSize; overload;

{------------------------------------------------------------------------------}
{==============================================================================}
{                                Memory reading                                }
{==============================================================================}
{------------------------------------------------------------------------------}

Function Ptr_ReadBool(var Src: Pointer; out Value: ByteBool; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadBool(Src: Pointer; out Value: ByteBool): TMemSize; overload;
Function Ptr_ReadBool(var Src: Pointer; Advance: Boolean): ByteBool; overload;
Function Ptr_ReadBool(Src: Pointer): ByteBool; overload;

Function Ptr_ReadBoolean(var Src: Pointer; out Value: Boolean; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadBoolean(Src: Pointer; out Value: Boolean): TMemSize; overload;

//------------------------------------------------------------------------------

Function Ptr_ReadInt8(var Src: Pointer; out Value: Int8; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadInt8(Src: Pointer; out Value: Int8): TMemSize; overload;
Function Ptr_ReadInt8(var Src: Pointer; Advance: Boolean): Int8; overload;
Function Ptr_ReadInt8(Src: Pointer): Int8; overload;

Function Ptr_ReadUInt8(var Src: Pointer; out Value: UInt8; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadUInt8(Src: Pointer; out Value: UInt8): TMemSize; overload;
Function Ptr_ReadUInt8(var Src: Pointer; Advance: Boolean): UInt8; overload;
Function Ptr_ReadUInt8(Src: Pointer): UInt8; overload;

Function Ptr_ReadInt16(var Src: Pointer; out Value: Int16; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadInt16(Src: Pointer; out Value: Int16): TMemSize; overload;
Function Ptr_ReadInt16(var Src: Pointer; Advance: Boolean): Int16; overload;
Function Ptr_ReadInt16(Src: Pointer): Int16; overload;

Function Ptr_ReadUInt16(var Src: Pointer; out Value: UInt16; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadUInt16(Src: Pointer; out Value: UInt16): TMemSize; overload;
Function Ptr_ReadUInt16(var Src: Pointer; Advance: Boolean): UInt16; overload;
Function Ptr_ReadUInt16(Src: Pointer): UInt16; overload;

Function Ptr_ReadInt32(var Src: Pointer; out Value: Int32; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadInt32(Src: Pointer; out Value: Int32): TMemSize; overload;
Function Ptr_ReadInt32(var Src: Pointer; Advance: Boolean): Int32; overload;
Function Ptr_ReadInt32(Src: Pointer): Int32; overload;

Function Ptr_ReadUInt32(var Src: Pointer; out Value: UInt32; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadUInt32(Src: Pointer; out Value: UInt32): TMemSize; overload;
Function Ptr_ReadUInt32(var Src: Pointer; Advance: Boolean): UInt32; overload;
Function Ptr_ReadUInt32(Src: Pointer): UInt32; overload;

Function Ptr_ReadInt64(var Src: Pointer; out Value: Int64; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadInt64(Src: Pointer; out Value: Int64): TMemSize; overload;
Function Ptr_ReadInt64(var Src: Pointer; Advance: Boolean): Int64; overload;
Function Ptr_ReadInt64(Src: Pointer): Int64; overload;

Function Ptr_ReadUInt64(var Src: Pointer; out Value: UInt64; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadUInt64(Src: Pointer; out Value: UInt64): TMemSize; overload;
Function Ptr_ReadUInt64(var Src: Pointer; Advance: Boolean): UInt64; overload;
Function Ptr_ReadUInt64(Src: Pointer): UInt64; overload;

//------------------------------------------------------------------------------

Function Ptr_ReadFloat32(var Src: Pointer; out Value: Float32; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadFloat32(Src: Pointer; out Value: Float32): TMemSize; overload;
Function Ptr_ReadFloat32(var Src: Pointer; Advance: Boolean): Float32; overload;
Function Ptr_ReadFloat32(Src: Pointer): Float32; overload;

Function Ptr_ReadFloat64(var Src: Pointer; out Value: Float64; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadFloat64(Src: Pointer; out Value: Float64): TMemSize; overload;
Function Ptr_ReadFloat64(var Src: Pointer; Advance: Boolean): Float64; overload;
Function Ptr_ReadFloat64(Src: Pointer): Float64; overload;

//------------------------------------------------------------------------------

Function Ptr_ReadAnsiChar(var Src: Pointer; out Value: AnsiChar; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadAnsiChar(Src: Pointer; out Value: AnsiChar): TMemSize; overload;
Function Ptr_ReadAnsiChar(var Src: Pointer; Advance: Boolean): AnsiChar; overload;
Function Ptr_ReadAnsiChar(Src: Pointer): AnsiChar; overload;

Function Ptr_ReadUTF8Char(var Src: Pointer; out Value: UTF8Char; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadUTF8Char(Src: Pointer; out Value: UTF8Char): TMemSize; overload;
Function Ptr_ReadUTF8Char(var Src: Pointer; Advance: Boolean): UTF8Char; overload;
Function Ptr_ReadUTF8Char(Src: Pointer): UTF8Char; overload;

Function Ptr_ReadWideChar(var Src: Pointer; out Value: WideChar; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadWideChar(Src: Pointer; out Value: WideChar): TMemSize; overload;
Function Ptr_ReadWideChar(var Src: Pointer; Advance: Boolean): WideChar; overload;
Function Ptr_ReadWideChar(Src: Pointer): WideChar; overload;

Function Ptr_ReadChar(var Src: Pointer; out Value: Char; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadChar(Src: Pointer; out Value: Char): TMemSize; overload;
Function Ptr_ReadChar(var Src: Pointer; Advance: Boolean): Char; overload;
Function Ptr_ReadChar(Src: Pointer): Char; overload;

//------------------------------------------------------------------------------

Function Ptr_ReadShortString(var Src: Pointer; out Str: ShortString; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadShortString(Src: Pointer; out Str: ShortString): TMemSize; overload;
Function Ptr_ReadShortString(var Src: Pointer; Advance: Boolean): ShortString; overload;
Function Ptr_ReadShortString(Src: Pointer): ShortString; overload;

Function Ptr_ReadAnsiString(var Src: Pointer; out Str: AnsiString; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadAnsiString(Src: Pointer; out Str: AnsiString): TMemSize; overload;
Function Ptr_ReadAnsiString(var Src: Pointer; Advance: Boolean): AnsiString; overload;
Function Ptr_ReadAnsiString(Src: Pointer): AnsiString; overload;

Function Ptr_ReadUnicodeString(var Src: Pointer; out Str: UnicodeString; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadUnicodeString(Src: Pointer; out Str: UnicodeString): TMemSize; overload;
Function Ptr_ReadUnicodeString(var Src: Pointer; Advance: Boolean): UnicodeString; overload;
Function Ptr_ReadUnicodeString(Src: Pointer): UnicodeString; overload;

Function Ptr_ReadWideString(var Src: Pointer; out Str: WideString; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadWideString(Src: Pointer; out Str: WideString): TMemSize; overload;
Function Ptr_ReadWideString(var Src: Pointer; Advance: Boolean): WideString; overload;
Function Ptr_ReadWideString(Src: Pointer): WideString; overload;

Function Ptr_ReadUTF8String(var Src: Pointer; out Str: UTF8String; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadUTF8String(Src: Pointer; out Str: UTF8String): TMemSize; overload;
Function Ptr_ReadUTF8String(var Src: Pointer; Advance: Boolean): UTF8String; overload;
Function Ptr_ReadUTF8String(Src: Pointer): UTF8String; overload;

Function Ptr_ReadString(var Src: Pointer; out Str: String; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadString(Src: Pointer; out Str: String): TMemSize; overload;
Function Ptr_ReadString(var Src: Pointer; Advance: Boolean): String; overload;
Function Ptr_ReadString(Src: Pointer): String; overload;

//------------------------------------------------------------------------------

Function Ptr_ReadBuffer(var Src: Pointer; var Buffer; Size: TMemSize; Advance: Boolean): TMemSize; overload;
Function Ptr_ReadBuffer(Src: Pointer; var Buffer; Size: TMemSize): TMemSize; overload;

{------------------------------------------------------------------------------}
{==============================================================================}
{                                Stream writing                                }
{==============================================================================}
{------------------------------------------------------------------------------}

Function Stream_WriteBool(Stream: TStream; Value: ByteBool; Advance: Boolean = True): TMemSize;

Function Stream_WriteBoolean(Stream: TStream; Value: Boolean; Advance: Boolean = True): TMemSize;

//------------------------------------------------------------------------------

Function Stream_WriteInt8(Stream: TStream; Value: Int8; Advance: Boolean = True): TMemSize;

Function Stream_WriteUInt8(Stream: TStream; Value: UInt8; Advance: Boolean = True): TMemSize;

Function Stream_WriteInt16(Stream: TStream; Value: Int16; Advance: Boolean = True): TMemSize;

Function Stream_WriteUInt16(Stream: TStream; Value: UInt16; Advance: Boolean = True): TMemSize;

Function Stream_WriteInt32(Stream: TStream; Value: Int32; Advance: Boolean = True): TMemSize;

Function Stream_WriteUInt32(Stream: TStream; Value: UInt32; Advance: Boolean = True): TMemSize;

Function Stream_WriteInt64(Stream: TStream; Value: Int64; Advance: Boolean = True): TMemSize;

Function Stream_WriteUInt64(Stream: TStream; Value: UInt64; Advance: Boolean = True): TMemSize;

//------------------------------------------------------------------------------

Function Stream_WriteFloat32(Stream: TStream; Value: Float32; Advance: Boolean = True): TMemSize;

Function Stream_WriteFloat64(Stream: TStream; Value: Float64; Advance: Boolean = True): TMemSize;

//------------------------------------------------------------------------------

Function Stream_WriteAnsiChar(Stream: TStream; Value: AnsiChar; Advance: Boolean = True): TMemSize;

Function Stream_WriteUTF8Char(Stream: TStream; Value: UTF8Char; Advance: Boolean = True): TMemSize;

Function Stream_WriteWideChar(Stream: TStream; Value: WideChar; Advance: Boolean = True): TMemSize;

Function Stream_WriteChar(Stream: TStream; Value: Char; Advance: Boolean = True): TMemSize;

//------------------------------------------------------------------------------

Function Stream_WriteShortString(Stream: TStream; const Str: ShortString; Advance: Boolean = True): TMemSize;

Function Stream_WriteAnsiString(Stream: TStream; const Str: AnsiString; Advance: Boolean = True): TMemSize;

Function Stream_WriteUnicodeString(Stream: TStream; const Str: UnicodeString; Advance: Boolean = True): TMemSize;

Function Stream_WriteWideString(Stream: TStream; const Str: WideString; Advance: Boolean = True): TMemSize;

Function Stream_WriteUTF8String(Stream: TStream; const Str: UTF8String; Advance: Boolean = True): TMemSize;

Function Stream_WriteString(Stream: TStream; const Str: String; Advance: Boolean = True): TMemSize;

//------------------------------------------------------------------------------

Function Stream_WriteBuffer(Stream: TStream; const Buffer; Size: TMemSize; Advance: Boolean = True): TMemSize;

//------------------------------------------------------------------------------

Function Stream_WriteBytes(Stream: TStream; const Value: array of UInt8; Advance: Boolean = True): TMemSize;

//------------------------------------------------------------------------------

Function Stream_FillBytes(Stream: TStream; Count: TMemSize; Value: UInt8; Advance: Boolean = True): TMemSize;

{------------------------------------------------------------------------------}
{==============================================================================}
{                                Stream reading                                }
{==============================================================================}
{------------------------------------------------------------------------------}

Function Stream_ReadBool(Stream: TStream; out Value: ByteBool; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadBool(Stream: TStream; Advance: Boolean = True): ByteBool; overload;

Function Stream_ReadBoolean(Stream: TStream; out Value: Boolean; Advance: Boolean = True): TMemSize;

//------------------------------------------------------------------------------

Function Stream_ReadInt8(Stream: TStream; out Value: Int8; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadInt8(Stream: TStream; Advance: Boolean = True): Int8; overload;

Function Stream_ReadUInt8(Stream: TStream; out Value: UInt8; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadUInt8(Stream: TStream; Advance: Boolean = True): UInt8; overload;

Function Stream_ReadInt16(Stream: TStream; out Value: Int16; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadInt16(Stream: TStream; Advance: Boolean = True): Int16; overload;

Function Stream_ReadUInt16(Stream: TStream; out Value: UInt16; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadUInt16(Stream: TStream; Advance: Boolean = True): UInt16; overload;

Function Stream_ReadInt32(Stream: TStream; out Value: Int32; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadInt32(Stream: TStream; Advance: Boolean = True): Int32; overload;

Function Stream_ReadUInt32(Stream: TStream; out Value: UInt32; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadUInt32(Stream: TStream; Advance: Boolean = True): UInt32; overload;

Function Stream_ReadInt64(Stream: TStream; out Value: Int64; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadInt64(Stream: TStream; Advance: Boolean = True): Int64; overload;

Function Stream_ReadUInt64(Stream: TStream; out Value: UInt64; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadUInt64(Stream: TStream; Advance: Boolean = True): UInt64; overload;

//------------------------------------------------------------------------------

Function Stream_ReadFloat32(Stream: TStream; out Value: Float32; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadFloat32(Stream: TStream; Advance: Boolean = True): Float32; overload;

Function Stream_ReadFloat64(Stream: TStream; out Value: Float64; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadFloat64(Stream: TStream; Advance: Boolean = True): Float64; overload;

//------------------------------------------------------------------------------

Function Stream_ReadAnsiChar(Stream: TStream; out Value: AnsiChar; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadAnsiChar(Stream: TStream; Advance: Boolean = True): AnsiChar; overload;

Function Stream_ReadUTF8Char(Stream: TStream; out Value: UTF8Char; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadUTF8Char(Stream: TStream; Advance: Boolean = True): UTF8Char; overload;

Function Stream_ReadWideChar(Stream: TStream; out Value: WideChar; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadWideChar(Stream: TStream; Advance: Boolean = True): WideChar; overload;

Function Stream_ReadChar(Stream: TStream; out Value: Char; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadChar(Stream: TStream; Advance: Boolean = True): Char; overload;

//------------------------------------------------------------------------------

Function Stream_ReadShortString(Stream: TStream; out Str: ShortString; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadShortString(Stream: TStream; Advance: Boolean = True): ShortString; overload;

Function Stream_ReadAnsiString(Stream: TStream; out Str: AnsiString; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadAnsiString(Stream: TStream; Advance: Boolean = True): AnsiString; overload;

Function Stream_ReadUnicodeString(Stream: TStream; out Str: UnicodeString; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadUnicodeString(Stream: TStream; Advance: Boolean = True): UnicodeString; overload;

Function Stream_ReadWideString(Stream: TStream; out Str: WideString; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadWideString(Stream: TStream; Advance: Boolean = True): WideString; overload;

Function Stream_ReadUTF8String(Stream: TStream; out Str: UTF8String; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadUTF8String(Stream: TStream; Advance: Boolean = True): UTF8String; overload;

Function Stream_ReadString(Stream: TStream; out Str: String; Advance: Boolean = True): TMemSize; overload;
Function Stream_ReadString(Stream: TStream; Advance: Boolean = True): String; overload;

//------------------------------------------------------------------------------

Function Stream_ReadBuffer(Stream: TStream; var Buffer; Size: TMemSize; Advance: Boolean = True): TMemSize; overload;

{------------------------------------------------------------------------------}
{==============================================================================}
{                               Streaming objects                              }
{==============================================================================}
{------------------------------------------------------------------------------}

{==============================================================================}
{                                TCustomStreamer                               }
{==============================================================================}

type
  TCustomStreamer = class(TObject)
  protected
    fBookmarks:       array of UInt64;
    fStartPosition:   UInt64;
    fUserData:        PtrUInt;
    Function GetBookmarkCount: Integer; virtual;
    Function GetBookmark(Index: Integer): UInt64; virtual;
    procedure SetBookmark(Index: Integer; Value: UInt64); virtual;
    Function GetCurrentPosition: UInt64; virtual; abstract;
    procedure SetCurrentPosition(NewPosition: UInt64); virtual; abstract;
    Function GetDistance: Int64; virtual;
    Function WriteValue(Value: Pointer; Advance: Boolean; Size: TMemSize; Param: Integer = 0): TMemSize; virtual; abstract;
    Function ReadValue(Value: Pointer; Advance: Boolean; Size: TMemSize; Param: Integer = 0): TMemSize; virtual; abstract;
  public
    procedure Initialize; virtual;
    procedure MoveToStart; virtual;
    procedure MoveToBookmark(Index: Integer); virtual;
    procedure MoveBy(Offset: Int64); virtual;
    Function IndexOfBookmark(Position: UInt64): Integer; virtual;
    Function AddBookmark: Integer; overload; virtual;
    Function AddBookmark(Position: UInt64): Integer; overload; virtual;
    Function RemoveBookmark(Position: UInt64; RemoveAll: Boolean = True): Integer; virtual;
    procedure DeleteBookmark(Index: Integer); virtual;
    Function WriteBool(Value: ByteBool; Advance: Boolean = True): TMemSize; virtual;
    Function WriteBoolean(Value: Boolean; Advance: Boolean = True): TMemSize; virtual;
    Function WriteInt8(Value: Int8; Advance: Boolean = True): TMemSize; virtual;
    Function WriteUInt8(Value: UInt8; Advance: Boolean = True): TMemSize; virtual;
    Function WriteInt16(Value: Int16; Advance: Boolean = True): TMemSize; virtual;
    Function WriteUInt16(Value: UInt16; Advance: Boolean = True): TMemSize; virtual;
    Function WriteInt32(Value: Int32; Advance: Boolean = True): TMemSize; virtual;
    Function WriteUInt32(Value: UInt32; Advance: Boolean = True): TMemSize; virtual;
    Function WriteInt64(Value: Int64; Advance: Boolean = True): TMemSize; virtual;
    Function WriteUInt64(Value: UInt64; Advance: Boolean = True): TMemSize; virtual;
    Function WriteFloat32(Value: Float32; Advance: Boolean = True): TMemSize; virtual;
    Function WriteFloat64(Value: Float64; Advance: Boolean = True): TMemSize; virtual;
    Function WriteAnsiChar(Value: AnsiChar; Advance: Boolean = True): TMemSize; virtual;
    Function WriteUTF8Char(Value: UTF8Char; Advance: Boolean = True): TMemSize; virtual;
    Function WriteWideChar(Value: WideChar; Advance: Boolean = True): TMemSize; virtual;
    Function WriteChar(Value: Char; Advance: Boolean = True): TMemSize; virtual;
    Function WriteShortString(const Value: ShortString; Advance: Boolean = True): TMemSize; virtual;
    Function WriteAnsiString(const Value: AnsiString; Advance: Boolean = True): TMemSize; virtual;
    Function WriteUnicodeString(const Value: UnicodeString; Advance: Boolean = True): TMemSize; virtual;
    Function WriteWideString(const Value: WideString; Advance: Boolean = True): TMemSize; virtual;
    Function WriteUTF8String(const Value: UTF8String; Advance: Boolean = True): TMemSize; virtual;
    Function WriteString(const Value: String; Advance: Boolean = True): TMemSize; virtual;
    Function WriteBuffer(const Buffer; Size: TMemSize; Advance: Boolean = True): TMemSize; virtual;
    Function WriteBytes(const Value: array of UInt8; Advance: Boolean = True): TMemSize; virtual;
    Function FillBytes(Count: TMemSize; Value: UInt8; Advance: Boolean = True): TMemSize; virtual;
    Function ReadBool(out Value: ByteBool; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadBool(Advance: Boolean = True): ByteBool; overload; virtual;
    Function ReadBoolean(out Value: Boolean; Advance: Boolean = True): TMemSize; virtual;
    Function ReadInt8(out Value: Int8; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadInt8(Advance: Boolean = True): Int8; overload; virtual;
    Function ReadUInt8(out Value: UInt8; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadUInt8(Advance: Boolean = True): UInt8; overload; virtual;
    Function ReadInt16(out Value: Int16; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadInt16(Advance: Boolean = True): Int16; overload; virtual;
    Function ReadUInt16(out Value: UInt16; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadUInt16(Advance: Boolean = True): UInt16; overload; virtual;
    Function ReadInt32(out Value: Int32; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadInt32(Advance: Boolean = True): Int32; overload; virtual;
    Function ReadUInt32(out Value: UInt32; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadUInt32(Advance: Boolean = True): UInt32; overload; virtual;
    Function ReadInt64(out Value: Int64; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadInt64(Advance: Boolean = True): Int64; overload; virtual;
    Function ReadUInt64(out Value: UInt64; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadUInt64(Advance: Boolean = True): UInt64; overload; virtual;
    Function ReadFloat32(out Value: Float32; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadFloat32(Advance: Boolean = True): Float32; overload; virtual;
    Function ReadFloat64(out Value: Float64; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadFloat64(Advance: Boolean = True): Float64; overload; virtual;
    Function ReadAnsiChar(out Value: AnsiChar; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadAnsiChar(Advance: Boolean = True): AnsiChar; overload; virtual;
    Function ReadUTF8Char(out Value: UTF8Char; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadUTF8Char(Advance: Boolean = True): UTF8Char; overload; virtual;
    Function ReadWideChar(out Value: WideChar; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadWideChar(Advance: Boolean = True): WideChar; overload; virtual;
    Function ReadChar(out Value: Char; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadChar(Advance: Boolean = True): Char; overload; virtual;
    Function ReadShortString(out Value: ShortString; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadShortString(Advance: Boolean = True): ShortString; overload; virtual;
    Function ReadAnsiString(out Value: AnsiString; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadAnsiString(Advance: Boolean = True): AnsiString; overload; virtual;
    Function ReadUnicodeString(out Value: UnicodeString; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadUnicodeString(Advance: Boolean = True): UnicodeString; overload; virtual;
    Function ReadWideString(out Value: WideString; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadWideString(Advance: Boolean = True): WideString; overload; virtual;
    Function ReadUTF8String(out Value: UTF8String; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadUTF8String(Advance: Boolean = True): UTF8String; overload; virtual;
    Function ReadString(out Value: String; Advance: Boolean = True): TMemSize; overload; virtual;
    Function ReadString(Advance: Boolean = True): String; overload; virtual;    
    Function ReadBuffer(var Buffer; Size: TMemSize; Advance: Boolean = True): TMemSize; overload; virtual;
    property Bookmarks[Index: Integer]: UInt64 read GetBookmark write SetBookmark;
    property BookmarkCount: Integer read GetBookmarkCount;
    property CurrentPosition: UInt64 read GetCurrentPosition write SetCurrentPosition;
    property StartPosition: UInt64 read fStartPosition;
    property Distance: Int64 read GetDistance;
    property UserData: PtrUInt read fUserData write fUserData;
  end;

{==============================================================================}
{                                TMemoryStreamer                               }
{==============================================================================}

  TMemoryStreamer = class(TCustomStreamer)
  private
    fCurrentPtr:  Pointer;
    fOwnsPointer: Boolean;
    fPtrSize:     PtrUInt;
    Function GetStartPtr: Pointer;
  protected
    procedure SetBookmark(Index: Integer; Value: UInt64); override;
    Function GetCurrentPosition: UInt64; override;
    procedure SetCurrentPosition(NewPosition: UInt64); override;
    Function WriteValue(Value: Pointer; Advance: Boolean; Size: TMemSize; Param: Integer = 0): TMemSize; override;
    Function ReadValue(Value: Pointer; Advance: Boolean; Size: TMemSize; Param: Integer = 0): TMemSize; override;
  public
    constructor Create(Memory: Pointer); overload;
    constructor Create(Size: PtrUInt); overload;
    destructor Destroy; override;
    procedure Initialize(Memory: Pointer); reintroduce; overload; virtual;
    procedure Initialize(Size: PtrUInt); reintroduce; overload; virtual;
    Function IndexOfBookmark(Position: UInt64): Integer; override;
    Function AddBookmark(Position: UInt64): Integer; override;
    Function RemoveBookmark(Position: UInt64; RemoveAll: Boolean = True): Integer; override;
    property OwnsPointer: Boolean read fOwnsPointer;
    property PtrSize: PtrUInt read fPtrSize;
    property CurrentPtr: Pointer read fCurrentPtr write fCurrentPtr;
    property StartPtr: Pointer read GetStartPtr;
  end;

{==============================================================================}
{                                TStreamStreamer                               }
{==============================================================================}

  TStreamStreamer = class(TCustomStreamer)
  private
    fTarget:  TStream;
  protected
    Function GetCurrentPosition: UInt64; override;
    procedure SetCurrentPosition(NewPosition: UInt64); override;
    Function WriteValue(Value: Pointer; Advance: Boolean; Size: TMemSize; Param: Integer = 0): TMemSize; override;
    Function ReadValue(Value: Pointer; Advance: Boolean; Size: TMemSize; Param: Integer = 0): TMemSize; override;
  public
    constructor Create(Target: TStream);
    procedure Initialize(Target: TStream); reintroduce; virtual;
    property Target: TStream read fTarget;
  end;


implementation

uses
  SysUtils, StrRect;

const
  PARAM_ANSISTRING    = -1;
  PARAM_UNICODESTRING = -2;
  PARAM_WIDESTRING    = -3;
  PARAM_UTF8STRING    = -4;
  PARAM_STRING        = -5;
  PARAM_FILLBYTES     = -6;
  PARAM_SHORTSTRING   = -7;

{------------------------------------------------------------------------------}
{==============================================================================}
{                              Auxiliary routines                              }
{==============================================================================}
{------------------------------------------------------------------------------}

{$IFDEF ENDIAN_BIG}
type
  Int32Rec = packed record
    LoWord: UInt16;
    HiWord: UInt16;
  end;

//------------------------------------------------------------------------------

Function SwapEndian(Value: UInt16): UInt16; overload;
begin
Result := UInt16(Value shl 8) or UInt16(Value shr 8);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function SwapEndian(Value: UInt32): UInt32; overload;
begin
Int32Rec(Result).HiWord := SwapEndian(Int32Rec(Value).LoWord);
Int32Rec(Result).LoWord := SwapEndian(Int32Rec(Value).HiWord);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function SwapEndian(Value: UInt64): UInt64; overload;
begin
Int64Rec(Result).Hi := SwapEndian(Int64Rec(Value).Lo);
Int64Rec(Result).Lo := SwapEndian(Int64Rec(Value).Hi);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function SwapEndian(Value: Float32): Float32; overload;
begin
Int32Rec(Result).HiWord := SwapEndian(Int32Rec(Value).LoWord);
Int32Rec(Result).LoWord := SwapEndian(Int32Rec(Value).HiWord);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function SwapEndian(Value: Float64): Float64; overload; 
begin
Int64Rec(Result).Hi := SwapEndian(Int64Rec(Value).Lo);
Int64Rec(Result).Lo := SwapEndian(Int64Rec(Value).Hi);
end;

//------------------------------------------------------------------------------

Function Ptr_WriteUTF16LE(var Dest: PUInt16; Data: PUInt16; Length: TStrSize): TMemSize;
var
  i:  TStrSize;
begin
Result := 0;
For i := 1 to Length do
  begin
    Dest^ := SwapEndian(Data^);
    Inc(Dest);
    Inc(Data);
    Inc(Result,SizeOf(UInt16));
  end;
end;

//------------------------------------------------------------------------------

Function Ptr_ReadUTF16LE(var Src: PUInt16; Data: PUInt16; Length: TStrSize): TMemSize;
var
  i:  TStrSize;
begin
Result := 0;
For i := 1 to Length do
  begin
    Data^ := SwapEndian(Src^);
    Inc(Src);
    Inc(Data);
    Inc(Result,SizeOf(UInt16)); 
  end;
end;

//------------------------------------------------------------------------------

Function Stream_WriteUTF16LE(Stream: TStream; Data: PUInt16; Length: TStrSize): TMemSize;
var
  i:    TStrSize;
  Buff: UInt16;
begin
Result := 0;
For i := 1 to Length do
  begin
    Buff := SwapEndian(Data^);
    Inc(Result,TMemSize(Stream.Write(Buff,SizeOf(UInt16))));
    Inc(Data);
  end;
end;

//------------------------------------------------------------------------------

Function Stream_ReadUTF16LE(Stream: TStream; Data: PUInt16; Length: TStrSize): TMemSize;
var
  i:    TStrSize;
  Buff: UInt16;
begin
Result := 0;
For i := 1 to Length do
  begin
    Inc(Result,TMemSize(Stream.Read({%H-}Buff,SizeOf(UInt16))));
    Data^ := SwapEndian(Buff);
    Inc(Data);
  end;
end;


{$ENDIF ENDIAN_BIG}

{------------------------------------------------------------------------------}
{==============================================================================}
{                                Memory writing                                }
{==============================================================================}
{------------------------------------------------------------------------------}

Function Ptr_WriteBool(var Dest: Pointer; Value: ByteBool; Advance: Boolean): TMemSize;
begin
ByteBool(Dest^) := Value;
Result := SizeOf(Value);
If Advance then Dest := {%H-}Pointer({%H-}PtrUInt(Dest) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteBool(Dest: Pointer; Value: ByteBool): TMemSize;
begin
Result := Ptr_WriteBool({%H-}Dest,Value,False);
end;

//------------------------------------------------------------------------------

Function Ptr_WriteBoolean(var Dest: Pointer; Value: Boolean; Advance: Boolean): TMemSize;
begin
Result := Ptr_WriteBool(Dest,Value,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteBoolean(Dest: Pointer; Value: Boolean): TMemSize;
begin
Result := Ptr_WriteBool(Dest,Value);
end;

//==============================================================================

Function Ptr_WriteInt8(var Dest: Pointer; Value: Int8; Advance: Boolean): TMemSize;
begin
Int8(Dest^) := Value;
Result := SizeOf(Value);
If Advance then Dest := {%H-}Pointer({%H-}PtrUInt(Dest) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteInt8(Dest: Pointer; Value: Int8): TMemSize;
begin
Result := Ptr_WriteInt8({%H-}Dest,Value,False);
end;

//------------------------------------------------------------------------------

Function Ptr_WriteUInt8(var Dest: Pointer; Value: UInt8; Advance: Boolean): TMemSize;
begin
UInt8(Dest^) := Value;
Result := SizeOf(Value);
If Advance then Dest := {%H-}Pointer({%H-}PtrUInt(Dest) + Result);
end;
 
//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteUInt8(Dest: Pointer; Value: UInt8): TMemSize;   
begin
Result := Ptr_WriteUInt8({%H-}Dest,Value,False);
end;

//------------------------------------------------------------------------------

Function Ptr_WriteInt16(var Dest: Pointer; Value: Int16; Advance: Boolean): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Int16(Dest^) := Int16(SwapEndian(UInt16(Value)));
{$ELSE}
Int16(Dest^) := Value;
{$ENDIF}
Result := SizeOf(Value);
If Advance then Dest := {%H-}Pointer({%H-}PtrUInt(Dest) + Result);
end;
  
//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteInt16(Dest: Pointer; Value: Int16): TMemSize;  
begin
Result := Ptr_WriteInt16({%H-}Dest,Value,False);
end;
 
//------------------------------------------------------------------------------

Function Ptr_WriteUInt16(var Dest: Pointer; Value: UInt16; Advance: Boolean): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
UInt16(Dest^) := SwapEndian(Value);
{$ELSE}
UInt16(Dest^) := Value;
{$ENDIF}
Result := SizeOf(Value);
If Advance then Dest := {%H-}Pointer({%H-}PtrUInt(Dest) + Result);
end;
  
//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteUInt16(Dest: Pointer; Value: UInt16): TMemSize;       
begin
Result := Ptr_WriteUInt16({%H-}Dest,Value,False);
end;
 
//------------------------------------------------------------------------------

Function Ptr_WriteInt32(var Dest: Pointer; Value: Int32; Advance: Boolean): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Int32(Dest^) := Int32(SwapEndian(UInt32(Value)));
{$ELSE}
Int32(Dest^) := Value;
{$ENDIF}
Result := SizeOf(Value);
If Advance then Dest := {%H-}Pointer({%H-}PtrUInt(Dest) + Result);
end;
 
//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteInt32(Dest: Pointer; Value: Int32): TMemSize;    
begin
Result := Ptr_WriteInt32({%H-}Dest,Value,False);
end;

//------------------------------------------------------------------------------

Function Ptr_WriteUInt32(var Dest: Pointer; Value: UInt32; Advance: Boolean): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
UInt32(Dest^) := SwapEndian(Value);
{$ELSE}
UInt32(Dest^) := Value;
{$ENDIF}
Result := SizeOf(Value);
If Advance then Dest := {%H-}Pointer({%H-}PtrUInt(Dest) + Result);
end;
 
//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteUInt32(Dest: Pointer; Value: UInt32): TMemSize;
begin
Result := Ptr_WriteUInt32({%H-}Dest,Value,False);
end;
  
//------------------------------------------------------------------------------

Function Ptr_WriteInt64(var Dest: Pointer; Value: Int64; Advance: Boolean): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Int64(Dest^) := Int64(SwapEndian(UInt64(Value)));
{$ELSE}
Int64(Dest^) := Value;
{$ENDIF}
Result := SizeOf(Value);
If Advance then Dest := {%H-}Pointer({%H-}PtrUInt(Dest) + Result);
end;
  
//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteInt64(Dest: Pointer; Value: Int64): TMemSize; 
begin
Result := Ptr_WriteInt64({%H-}Dest,Value,False);
end;

//------------------------------------------------------------------------------

Function Ptr_WriteUInt64(var Dest: Pointer; Value: UInt64; Advance: Boolean): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
UInt64(Dest^) := SwapEndian(Value);
{$ELSE}
UInt64(Dest^) := Value;
{$ENDIF}
Result := SizeOf(Value);
If Advance then Dest := {%H-}Pointer({%H-}PtrUInt(Dest) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteUInt64(Dest: Pointer; Value: UInt64): TMemSize;
begin
Result := Ptr_WriteUInt64({%H-}Dest,Value,False);
end;

//==============================================================================

Function Ptr_WriteFloat32(var Dest: Pointer; Value: Float32; Advance: Boolean): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Float32(Dest^) := SwapEndian(Value);
{$ELSE}
Float32(Dest^) := Value;
{$ENDIF}
Result := SizeOf(Value);
If Advance then Dest := {%H-}Pointer({%H-}PtrUInt(Dest) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteFloat32(Dest: Pointer; Value: Float32): TMemSize;
begin
Result := Ptr_WriteFloat32({%H-}Dest,Value,False);
end;

//------------------------------------------------------------------------------

Function Ptr_WriteFloat64(var Dest: Pointer; Value: Float64; Advance: Boolean): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Float64(Dest^) := SwapEndian(Value);
{$ELSE}
Float64(Dest^) := Value;
{$ENDIF}
Result := SizeOf(Value);
If Advance then Dest := {%H-}Pointer({%H-}PtrUInt(Dest) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteFloat64(Dest: Pointer; Value: Float64): TMemSize;
begin
Result := Ptr_WriteFloat32({%H-}Dest,Value,False);
end;

//==============================================================================

Function Ptr_WriteAnsiChar(var Dest: Pointer; Value: AnsiChar; Advance: Boolean): TMemSize;
begin
AnsiChar(Dest^) := Value;
Result := SizeOf(Value);
If Advance then Dest := {%H-}Pointer({%H-}PtrUInt(Dest) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteAnsiChar(Dest: Pointer; Value: AnsiChar): TMemSize;
begin
Result := Ptr_WriteAnsiChar({%H-}Dest,Value,False);
end;

//------------------------------------------------------------------------------

Function Ptr_WriteUTF8Char(var Dest: Pointer; Value: UTF8Char; Advance: Boolean): TMemSize;
begin
UTF8Char(Dest^) := Value;
Result := SizeOf(Value);
If Advance then Dest := {%H-}Pointer({%H-}PtrUInt(Dest) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteUTF8Char(Dest: Pointer; Value: UTF8Char): TMemSize;
begin
Result := Ptr_WriteUTF8Char({%H-}Dest,Value,False);
end;

//------------------------------------------------------------------------------

Function Ptr_WriteWideChar(var Dest: Pointer; Value: WideChar; Advance: Boolean): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
WideChar(Dest^) := WideChar(SwapEndian(UInt16(Value)));
{$ELSE}
WideChar(Dest^) := Value;
{$ENDIF}
Result := SizeOf(Value);
If Advance then Dest := {%H-}Pointer({%H-}PtrUInt(Dest) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteWideChar(Dest: Pointer; Value: WideChar): TMemSize;
begin
Result := Ptr_WriteWideChar({%H-}Dest,Value,False);
end;

//------------------------------------------------------------------------------

Function Ptr_WriteChar(var Dest: Pointer; Value: Char; Advance: Boolean): TMemSize;
begin
{$IFDEF Unicode}
Result := Ptr_WriteWideChar(Dest,Value,Advance);
{$ELSE}
Result := Ptr_WriteAnsiChar(Dest,Value,Advance);
{$ENDIF}
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteChar(Dest: Pointer; Value: Char): TMemSize;
begin
Result := Ptr_WriteChar({%H-}Dest,Value,False);
end;

//==============================================================================

Function Ptr_WriteShortString(var Dest: Pointer; const Str: ShortString; Advance: Boolean): TMemSize;
begin
If Assigned(Dest) then
  begin
    Result := Ptr_WriteBuffer(Dest,{%H-}Pointer({%H-}PtrUInt(Addr(Str[1])) - 1)^,Length(Str) + 1, Advance);
    If Advance then Dest := {%H-}Pointer({%H-}PtrUInt(Dest) + Result);
  end
else
  Result := Length(Str) + 1;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteShortString(Dest: Pointer; const Str: ShortString): TMemSize;
begin
Result := Ptr_WriteShortString({%H-}Dest,Str,False);
end;

//------------------------------------------------------------------------------

Function Ptr_WriteAnsiString(var Dest: Pointer; const Str: AnsiString; Advance: Boolean): TMemSize;
var
  WorkPtr:  Pointer;
begin
If Assigned(Dest) then
  begin
    WorkPtr := Dest;
    Result := Ptr_WriteInt32(WorkPtr,Length(Str),True);
    Inc(Result,Ptr_WriteBuffer(WorkPtr,PAnsiChar(Str)^,Length(Str) * SizeOf(AnsiChar),True));
    If Advance then Dest := WorkPtr;
  end
else Result := SizeOf(Int32) + (Length(Str) * SizeOf(AnsiChar));
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteAnsiString(Dest: Pointer; const Str: AnsiString): TMemSize;
begin
Result := Ptr_WriteAnsiString({%H-}Dest,Str,False);
end;

//------------------------------------------------------------------------------

Function Ptr_WriteUnicodeString(var Dest: Pointer; const Str: UnicodeString; Advance: Boolean): TMemSize;
var
  WorkPtr:  Pointer;
begin
If Assigned(Dest) then
  begin
    WorkPtr := Dest;
    Result := Ptr_WriteInt32(WorkPtr,Length(Str),True);
  {$IFDEF ENDIAN_BIG}
    Inc(Result,Ptr_WriteUTF16LE(PUInt16(WorkPtr),PUInt16(PUnicodeChar(Str)),Length(Str)));
  {$ELSE}
    Inc(Result,Ptr_WriteBuffer(WorkPtr,PUnicodeChar(Str)^,Length(Str) * SizeOf(UnicodeChar),True));
  {$ENDIF}
    If Advance then Dest := WorkPtr;
  end
else Result := SizeOf(Int32) + (Length(Str) * SizeOf(UnicodeChar));
end;


//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteUnicodeString(Dest: Pointer; const Str: UnicodeString): TMemSize;
begin
Result := Ptr_WriteUnicodeString({%H-}Dest,Str,False);
end;

//------------------------------------------------------------------------------

Function Ptr_WriteWideString(var Dest: Pointer; const Str: WideString; Advance: Boolean): TMemSize;
var
  WorkPtr:  Pointer;
begin
If Assigned(Dest) then
  begin
    WorkPtr := Dest;
    Result := Ptr_WriteInt32(WorkPtr,Length(Str),True);
  {$IFDEF ENDIAN_BIG}
    Inc(Result,Ptr_WriteUTF16LE(PUInt16(WorkPtr),PUInt16(PWideChar(Str)),Length(Str)));
  {$ELSE}
    Inc(Result,Ptr_WriteBuffer(WorkPtr,PWideChar(Str)^,Length(Str) * SizeOf(WideChar),True));
  {$ENDIF}
    If Advance then Dest := WorkPtr;
  end
else Result := SizeOf(Int32) + (Length(Str) * SizeOf(WideChar));
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteWideString(Dest: Pointer; const Str: WideString): TMemSize;
begin
Result := Ptr_WriteWideString({%H-}Dest,Str,False);
end;

//------------------------------------------------------------------------------

Function Ptr_WriteUTF8String(var Dest: Pointer; const Str: UTF8String; Advance: Boolean): TMemSize;
var
  WorkPtr:  Pointer;
begin
If Assigned(Dest) then
  begin
    WorkPtr := Dest;
    Result := Ptr_WriteInt32(WorkPtr,Length(Str),True);
    Inc(Result,Ptr_WriteBuffer(WorkPtr,PUTF8Char(Str)^,Length(Str) * SizeOf(UTF8Char),True));
    If Advance then Dest := WorkPtr;
  end
else Result := SizeOf(Int32) + (Length(Str) * SizeOf(UTF8Char));
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteUTF8String(Dest: Pointer; const Str: UTF8String): TMemSize;
begin
Result := Ptr_WriteUTF8String({%H-}Dest,Str,False);
end;

//------------------------------------------------------------------------------

Function Ptr_WriteString(var Dest: Pointer; const Str: String; Advance: Boolean): TMemSize;
begin
Result := Ptr_WriteUTF8String(Dest,StrToUTF8(Str),Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteString(Dest: Pointer; const Str: String): TMemSize;
begin
Result := Ptr_WriteString({%H-}Dest,Str,False);
end;

//==============================================================================

Function Ptr_WriteBuffer(var Dest: Pointer; const Buffer; Size: TMemSize; Advance: Boolean): TMemSize;
begin
Move(Buffer,Dest^,Size);
Result := Size;
If Advance then Dest := {%H-}Pointer({%H-}PtrUInt(Dest) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteBuffer(Dest: Pointer; const Buffer; Size: TMemSize): TMemSize;
begin
Result := Ptr_WriteBuffer({%H-}Dest,Buffer,Size,False);
end;

//==============================================================================

Function Ptr_WriteBytes(var Dest: Pointer; const Value: array of UInt8; Advance: Boolean): TMemSize;
var
  i:  Integer;
begin
Result := 0;
For i := Low(Value) to High(Value) do
  Inc(Result,Ptr_WriteUInt8(Dest,Value[i],True));
If not Advance then Dest := {%H-}Pointer({%H-}PtrUInt(Dest) - Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_WriteBytes(Dest: Pointer; const Value: array of UInt8): TMemSize;
begin
Result := Ptr_WriteBytes({%H-}Dest,Value,False);
end;

//==============================================================================

Function Ptr_FillBytes(var Dest: Pointer; Count: TMemSize; Value: UInt8; Advance: Boolean): TMemSize;
begin
FillChar(Dest^,Count,Value);
Result := Count;
If Advance then Dest := {%H-}Pointer({%H-}PtrUInt(Dest) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_FillBytes(Dest: Pointer; Count: TMemSize; Value: UInt8): TMemSize;
begin
Result := Ptr_FillBytes({%H-}Dest,Count,Value,False);
end;

{------------------------------------------------------------------------------}
{==============================================================================}
{                                Memory reading                                }
{==============================================================================}
{------------------------------------------------------------------------------}

Function Ptr_ReadBool(var Src: Pointer; out Value: ByteBool; Advance: Boolean): TMemSize;
begin
Value := ByteBool(Src^);
Result := SizeOf(Value);
If Advance then Src := {%H-}Pointer({%H-}PtrUInt(Src) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadBool(Src: Pointer; out Value: ByteBool): TMemSize;
begin
Result := Ptr_ReadBool({%H-}Src,Value,False);
end;
 
//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadBool(var Src: Pointer; Advance: Boolean): ByteBool;
begin
Ptr_ReadBool(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadBool(Src: Pointer): ByteBool;
begin
Ptr_ReadBool({%H-}Src,Result,False);
end;

//------------------------------------------------------------------------------

Function Ptr_ReadBoolean(var Src: Pointer; out Value: Boolean; Advance: Boolean): TMemSize;
var
  TempBool: ByteBool;
begin
Result := Ptr_ReadBool(Src,TempBool,Advance);
Value := TempBool;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadBoolean(Src: Pointer; out Value: Boolean): TMemSize;
begin
Result := Ptr_ReadBoolean({%H-}Src,Value,False);
end;

//==============================================================================

Function Ptr_ReadInt8(var Src: Pointer; out Value: Int8; Advance: Boolean): TMemSize; 
begin
Value := Int8(Src^);
Result := SizeOf(Value);
If Advance then Src := {%H-}Pointer({%H-}PtrUInt(Src) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadInt8(Src: Pointer; out Value: Int8): TMemSize;
begin
Result := Ptr_ReadInt8({%H-}Src,Value,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadInt8(var Src: Pointer; Advance: Boolean): Int8;
begin
Ptr_ReadInt8(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadInt8(Src: Pointer): Int8;
begin
Ptr_ReadInt8({%H-}Src,Result,False);
end;

//------------------------------------------------------------------------------

Function Ptr_ReadUInt8(var Src: Pointer; out Value: UInt8; Advance: Boolean): TMemSize;
begin
Value := UInt8(Src^);
Result := SizeOf(Value);
If Advance then Src := {%H-}Pointer({%H-}PtrUInt(Src) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUInt8(Src: Pointer; out Value: UInt8): TMemSize;
begin
Result := Ptr_ReadUInt8({%H-}Src,Value,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUInt8(var Src: Pointer; Advance: Boolean): UInt8;
begin
Ptr_ReadUInt8(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUInt8(Src: Pointer): UInt8;
begin
Ptr_ReadUInt8({%H-}Src,Result,False);
end;

//------------------------------------------------------------------------------

Function Ptr_ReadInt16(var Src: Pointer; out Value: Int16; Advance: Boolean): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Value := Int16(SwapEndian(UInt16(Src^)));
{$ELSE}
Value := Int16(Src^);
{$ENDIF}
Result := SizeOf(Value);
If Advance then Src := {%H-}Pointer({%H-}PtrUInt(Src) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadInt16(Src: Pointer; out Value: Int16): TMemSize;
begin
Result := Ptr_ReadInt16({%H-}Src,Value,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadInt16(var Src: Pointer; Advance: Boolean): Int16;
begin
Ptr_ReadInt16(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadInt16(Src: Pointer): Int16;
begin
Ptr_ReadInt16({%H-}Src,Result,False);
end;

//------------------------------------------------------------------------------

Function Ptr_ReadUInt16(var Src: Pointer; out Value: UInt16; Advance: Boolean): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Value := SwapEndian(UInt16(Src^));
{$ELSE}
Value := UInt16(Src^);
{$ENDIF}
Result := SizeOf(Value);
If Advance then Src := {%H-}Pointer({%H-}PtrUInt(Src) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUInt16(Src: Pointer; out Value: UInt16): TMemSize;
begin
Result := Ptr_ReadUInt16({%H-}Src,Value,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUInt16(var Src: Pointer; Advance: Boolean): UInt16;
begin
Ptr_ReadUInt16(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUInt16(Src: Pointer): UInt16;
begin
Ptr_ReadUInt16({%H-}Src,Result,False);
end;

//------------------------------------------------------------------------------

Function Ptr_ReadInt32(var Src: Pointer; out Value: Int32; Advance: Boolean): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Value := Int32(SwapEndian(UInt32(Src^)));
{$ELSE}
Value := Int32(Src^);
{$ENDIF}
Result := SizeOf(Value);
If Advance then Src := {%H-}Pointer({%H-}PtrUInt(Src) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadInt32(Src: Pointer; out Value: Int32): TMemSize;
begin
Result := Ptr_ReadInt32({%H-}Src,Value,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadInt32(var Src: Pointer; Advance: Boolean): Int32;
begin
Ptr_ReadInt32(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadInt32(Src: Pointer): Int32;
begin
Ptr_ReadInt32({%H-}Src,Result,False);
end;

//------------------------------------------------------------------------------

Function Ptr_ReadUInt32(var Src: Pointer; out Value: UInt32; Advance: Boolean): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Value := SwapEndian(UInt32(Src^));
{$ELSE}
Value := UInt32(Src^);
{$ENDIF}
Result := SizeOf(Value);
If Advance then Src := {%H-}Pointer({%H-}PtrUInt(Src) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUInt32(Src: Pointer; out Value: UInt32): TMemSize;
begin
Result := Ptr_ReadUInt32({%H-}Src,Value,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUInt32(var Src: Pointer; Advance: Boolean): UInt32;
begin
Ptr_ReadUInt32(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUInt32(Src: Pointer): UInt32;
begin
Ptr_ReadUInt32({%H-}Src,Result,False);
end;
 
//------------------------------------------------------------------------------

Function Ptr_ReadInt64(var Src: Pointer; out Value: Int64; Advance: Boolean): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Value := Int64(SwapEndian(UInt64(Src^)));
{$ELSE}
Value := Int64(Src^);
{$ENDIF}
Result := SizeOf(Value);
If Advance then Src := {%H-}Pointer({%H-}PtrUInt(Src) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadInt64(Src: Pointer; out Value: Int64): TMemSize;
begin
Result := Ptr_ReadInt64({%H-}Src,Value,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadInt64(var Src: Pointer; Advance: Boolean): Int64;
begin
Ptr_ReadInt64(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadInt64(Src: Pointer): Int64;
begin
Ptr_ReadInt64({%H-}Src,Result,False);
end;

//------------------------------------------------------------------------------

Function Ptr_ReadUInt64(var Src: Pointer; out Value: UInt64; Advance: Boolean): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Value := SwapEndian(UInt64(Src^));
{$ELSE}
Value := UInt64(Src^);
{$ENDIF}
Result := SizeOf(Value);
If Advance then Src := {%H-}Pointer({%H-}PtrUInt(Src) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUInt64(Src: Pointer; out Value: UInt64): TMemSize;
begin
Result := Ptr_ReadUInt64({%H-}Src,Value,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUInt64(var Src: Pointer; Advance: Boolean): UInt64;
begin
Ptr_ReadUInt64(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUInt64(Src: Pointer): UInt64;
begin
Ptr_ReadUInt64({%H-}Src,Result,False);
end;

//==============================================================================

Function Ptr_ReadFloat32(var Src: Pointer; out Value: Float32; Advance: Boolean): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Value := SwapEndian(Float32(Src^));
{$ELSE}
Value := Float32(Src^);
{$ENDIF}
Result := SizeOf(Value);
If Advance then Src := {%H-}Pointer({%H-}PtrUInt(Src) + Result);
end;
 
//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadFloat32(Src: Pointer; out Value: Float32): TMemSize;
begin
Result := Ptr_ReadFloat32({%H-}Src,Value,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadFloat32(var Src: Pointer; Advance: Boolean): Float32;
begin
Ptr_ReadFloat32(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadFloat32(Src: Pointer): Float32;
begin
Ptr_ReadFloat32({%H-}Src,Result,False);
end;

//------------------------------------------------------------------------------

Function Ptr_ReadFloat64(var Src: Pointer; out Value: Float64; Advance: Boolean): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Value := SwapEndian(Float64(Src^));
{$ELSE}
Value := Float64(Src^);
{$ENDIF}
Result := SizeOf(Value);
If Advance then Src := {%H-}Pointer({%H-}PtrUInt(Src) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadFloat64(Src: Pointer; out Value: Float64): TMemSize;
begin
Result := Ptr_ReadFloat64({%H-}Src,Value,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadFloat64(var Src: Pointer; Advance: Boolean): Float64;
begin
Ptr_ReadFloat64(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadFloat64(Src: Pointer): Float64;
begin
Ptr_ReadFloat64({%H-}Src,Result,False);
end;

//==============================================================================

Function Ptr_ReadAnsiChar(var Src: Pointer; out Value: AnsiChar; Advance: Boolean): TMemSize;
begin
Value := AnsiChar(Src^);
Result := SizeOf(Value);
If Advance then Src := {%H-}Pointer({%H-}PtrUInt(Src) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadAnsiChar(Src: Pointer; out Value: AnsiChar): TMemSize;
begin
Result := Ptr_ReadAnsiChar({%H-}Src,Value,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadAnsiChar(var Src: Pointer; Advance: Boolean): AnsiChar;
begin
Ptr_ReadAnsiChar(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadAnsiChar(Src: Pointer): AnsiChar;
begin
Ptr_ReadAnsiChar({%H-}Src,Result,False);
end;

//------------------------------------------------------------------------------

Function Ptr_ReadUTF8Char(var Src: Pointer; out Value: UTF8Char; Advance: Boolean): TMemSize;
begin
Value := UTF8Char(Src^);
Result := SizeOf(Value);
If Advance then Src := {%H-}Pointer({%H-}PtrUInt(Src) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUTF8Char(Src: Pointer; out Value: UTF8Char): TMemSize;
begin
Result := Ptr_ReadUTF8Char({%H-}Src,Value,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUTF8Char(var Src: Pointer; Advance: Boolean): UTF8Char;
begin
Ptr_ReadUTF8Char(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUTF8Char(Src: Pointer): UTF8Char;
begin
Ptr_ReadUTF8Char({%H-}Src,Result,False);
end;

//------------------------------------------------------------------------------

Function Ptr_ReadWideChar(var Src: Pointer; out Value: WideChar; Advance: Boolean): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Value := WideChar(SwapEndian(UInt16(Src^)));
{$ELSE}
Value := WideChar(Src^);
{$ENDIF}
Result := SizeOf(Value);
If Advance then Src := {%H-}Pointer({%H-}PtrUInt(Src) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadWideChar(Src: Pointer; out Value: WideChar): TMemSize;
begin
Result := Ptr_ReadWideChar({%H-}Src,Value,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadWideChar(var Src: Pointer; Advance: Boolean): WideChar;
begin
Ptr_ReadWideChar(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadWideChar(Src: Pointer): WideChar;
begin
Ptr_ReadWideChar({%H-}Src,Result,False);
end;

//------------------------------------------------------------------------------

Function Ptr_ReadChar(var Src: Pointer; out Value: Char; Advance: Boolean): TMemSize;
begin
{$IFDEF Unicode}
Result := Ptr_ReadWideChar(Src,Value,Advance);
{$ELSE}
Result := Ptr_ReadAnsiChar(Src,Value,Advance);
{$ENDIF}
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadChar(Src: Pointer; out Value: Char): TMemSize;
begin
Result := Ptr_ReadChar({%H-}Src,Value,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadChar(var Src: Pointer; Advance: Boolean): Char;
begin
Ptr_ReadChar(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadChar(Src: Pointer): Char;
begin
Ptr_ReadChar({%H-}Src,Result,False);
end;

//==============================================================================

Function Ptr_ReadShortString(var Src: Pointer; out Str: ShortString; Advance: Boolean): TMemSize;
var
  StrLength:  UInt8;
  WorkPtr:    Pointer;
begin
WorkPtr := Src;
Result := Ptr_ReadUInt8(WorkPtr,StrLength,True);
SetLength(Str,StrLength);
Inc(Result,Ptr_ReadBuffer(WorkPtr,Addr(Str[1])^,StrLength,True));
If Advance then Src := WorkPtr;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadShortString(Src: Pointer; out Str: ShortString): TMemSize;
begin
Result := Ptr_ReadShortString({%H-}Src,Str,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadShortString(var Src: Pointer; Advance: Boolean): ShortString;
begin
Ptr_ReadShortString(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadShortString(Src: Pointer): ShortString;
begin
Ptr_ReadShortString({%H-}Src,Result,False);
end;

//------------------------------------------------------------------------------

Function Ptr_ReadAnsiString(var Src: Pointer; out Str: AnsiString; Advance: Boolean): TMemSize;
var
  StrLength:  Int32;
  WorkPtr:    Pointer;
begin
WorkPtr := Src;
Result := Ptr_ReadInt32(WorkPtr,StrLength,True);
SetLength(Str,StrLength);
Inc(Result,Ptr_ReadBuffer(WorkPtr,PAnsiChar(Str)^,StrLength * SizeOf(AnsiChar),True));
If Advance then Src := WorkPtr;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadAnsiString(Src: Pointer; out Str: AnsiString): TMemSize;
begin
Result := Ptr_ReadAnsiString({%H-}Src,Str,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadAnsiString(var Src: Pointer; Advance: Boolean): AnsiString;
begin
Ptr_ReadAnsiString(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadAnsiString(Src: Pointer): AnsiString;
begin
Ptr_ReadAnsiString({%H-}Src,Result,False);
end;

//------------------------------------------------------------------------------

Function Ptr_ReadUnicodeString(var Src: Pointer; out Str: UnicodeString; Advance: Boolean): TMemSize;
var
  StrLength:  Int32;
  WorkPtr:    Pointer;
begin
WorkPtr := Src;
Result := Ptr_ReadInt32(WorkPtr,StrLength,True);
SetLength(Str,StrLength);
{$IFDEF ENDIAN_BIG}
Inc(Result,Ptr_ReadUTF16LE(PUInt16(WorkPtr),PUInt16(PUnicodeChar(Str)),StrLength));
{$ELSE}
Inc(Result,Ptr_ReadBuffer(WorkPtr,PUnicodeChar(Str)^,StrLength * SizeOf(UnicodeChar),True));
{$ENDIF}
If Advance then Src := WorkPtr;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUnicodeString(Src: Pointer; out Str: UnicodeString): TMemSize;
begin
Result := Ptr_ReadUnicodeString({%H-}Src,Str,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUnicodeString(var Src: Pointer; Advance: Boolean): UnicodeString;
begin
Ptr_ReadUnicodeString(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUnicodeString(Src: Pointer): UnicodeString;
begin
Ptr_ReadUnicodeString({%H-}Src,Result,False);
end;

//------------------------------------------------------------------------------

Function Ptr_ReadWideString(var Src: Pointer; out Str: WideString; Advance: Boolean): TMemSize;
var
  StrLength:  Int32;
  WorkPtr:    Pointer;
begin
WorkPtr := Src;
Result := Ptr_ReadInt32(WorkPtr,StrLength,True);
SetLength(Str,StrLength);
{$IFDEF ENDIAN_BIG}
Inc(Result,Ptr_ReadUTF16LE(PUInt16(WorkPtr),PUInt16(PWideChar(Str)),StrLength));
{$ELSE}
Inc(Result,Ptr_ReadBuffer(WorkPtr,PWideChar(Str)^,StrLength * SizeOf(WideChar),True));
{$ENDIF}
If Advance then Src := WorkPtr;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadWideString(Src: Pointer; out Str: WideString): TMemSize;
begin
Result := Ptr_ReadWideString({%H-}Src,Str,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadWideString(var Src: Pointer; Advance: Boolean): WideString;
begin
Ptr_ReadWideString(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadWideString(Src: Pointer): WideString;
begin
Ptr_ReadWideString({%H-}Src,Result,False);
end;

//------------------------------------------------------------------------------

Function Ptr_ReadUTF8String(var Src: Pointer; out Str: UTF8String; Advance: Boolean): TMemSize;
var
  StrLength:  Int32;
  WorkPtr:    Pointer;
begin
WorkPtr := Src;
Result := Ptr_ReadInt32(WorkPtr,StrLength,True);
SetLength(Str,StrLength);
Inc(Result,Ptr_ReadBuffer(WorkPtr,PUTF8Char(Str)^,StrLength * SizeOf(UTF8Char),True));
If Advance then Src := WorkPtr;
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUTF8String(Src: Pointer; out Str: UTF8String): TMemSize;
begin
Result := Ptr_ReadUTF8String({%H-}Src,Str,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUTF8String(var Src: Pointer; Advance: Boolean): UTF8String;
begin
Ptr_ReadUTF8String(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadUTF8String(Src: Pointer): UTF8String;
begin
Ptr_ReadUTF8String({%H-}Src,Result,False);
end;

//------------------------------------------------------------------------------

Function Ptr_ReadString(var Src: Pointer; out Str: String; Advance: Boolean): TMemSize;
var
  TempStr:  UTF8String;
begin
Result := Ptr_ReadUTF8String(Src,TempStr,Advance);
Str := UTF8ToStr(TempStr);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadString(Src: Pointer; out Str: String): TMemSize;
begin
Result := Ptr_ReadString({%H-}Src,Str,False);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadString(var Src: Pointer; Advance: Boolean): String;
begin
Ptr_ReadString(Src,Result,Advance);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadString(Src: Pointer): String;
begin
Ptr_ReadString({%H-}Src,Result,False);
end;

//==============================================================================

Function Ptr_ReadBuffer(var Src: Pointer; var Buffer; Size: TMemSize; Advance: Boolean): TMemSize; 
begin
Move(Src^,Buffer,Size);
Result := Size;
If Advance then Src := {%H-}Pointer({%H-}PtrUInt(Src) + Result);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Ptr_ReadBuffer(Src: Pointer; var Buffer; Size: TMemSize): TMemSize;
begin
Result := Ptr_ReadBuffer({%H-}Src,Buffer,Size,False);
end;

{------------------------------------------------------------------------------}
{==============================================================================}
{                                Stream writing                                }
{==============================================================================}
{------------------------------------------------------------------------------}

Function Stream_WriteBool(Stream: TStream; Value: ByteBool; Advance: Boolean = True): TMemSize;
begin
Result := Stream.Write(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//------------------------------------------------------------------------------

Function Stream_WriteBoolean(Stream: TStream; Value: Boolean; Advance: Boolean = True): TMemSize;
begin
Result := Stream_WriteBool(Stream,Value,Advance);
end;

//==============================================================================

Function Stream_WriteInt8(Stream: TStream; Value: Int8; Advance: Boolean = True): TMemSize;
begin
Result := Stream.Write(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//------------------------------------------------------------------------------

Function Stream_WriteUInt8(Stream: TStream; Value: UInt8; Advance: Boolean = True): TMemSize;
begin
Result := Stream.Write(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//------------------------------------------------------------------------------

Function Stream_WriteInt16(Stream: TStream; Value: Int16; Advance: Boolean = True): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Value := Int16(SwapEndian(UInt16(Value)));
{$ENDIF}
Result := Stream.Write(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;
 
//------------------------------------------------------------------------------

Function Stream_WriteUInt16(Stream: TStream; Value: UInt16; Advance: Boolean = True): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Value := SwapEndian(Value);
{$ENDIF}
Result := Stream.Write(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//------------------------------------------------------------------------------

Function Stream_WriteInt32(Stream: TStream; Value: Int32; Advance: Boolean = True): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Value := Int32(SwapEndian(UInt32(Value)));
{$ENDIF}
Result := Stream.Write(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//------------------------------------------------------------------------------

Function Stream_WriteUInt32(Stream: TStream; Value: UInt32; Advance: Boolean = True): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Value := SwapEndian(Value);
{$ENDIF}
Result := Stream.Write(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;
 
//------------------------------------------------------------------------------

Function Stream_WriteInt64(Stream: TStream; Value: Int64; Advance: Boolean = True): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Value := Int64(SwapEndian(UInt64(Value)));
{$ENDIF}
Result := Stream.Write(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//------------------------------------------------------------------------------

Function Stream_WriteUInt64(Stream: TStream; Value: UInt64; Advance: Boolean = True): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Value := SwapEndian(Value);
{$ENDIF}
Result := Stream.Write(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//==============================================================================

Function Stream_WriteFloat32(Stream: TStream; Value: Float32; Advance: Boolean = True): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Value := SwapEndian(Value);
{$ENDIF}
Result := Stream.Write(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//------------------------------------------------------------------------------

Function Stream_WriteFloat64(Stream: TStream; Value: Float64; Advance: Boolean = True): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Value := SwapEndian(Value);
{$ENDIF}
Result := Stream.Write(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//==============================================================================

Function Stream_WriteAnsiChar(Stream: TStream; Value: AnsiChar; Advance: Boolean = True): TMemSize;
begin
Result := Stream.Write(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//------------------------------------------------------------------------------

Function Stream_WriteUTF8Char(Stream: TStream; Value: UTF8Char; Advance: Boolean = True): TMemSize;
begin
Result := Stream.Write(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//------------------------------------------------------------------------------

Function Stream_WriteWideChar(Stream: TStream; Value: WideChar; Advance: Boolean = True): TMemSize;
begin
{$IFDEF ENDIAN_BIG}
Value := WideChar(SwapEndian(UInt16(Value)));
{$ENDIF}
Result := Stream.Write(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//------------------------------------------------------------------------------

Function Stream_WriteChar(Stream: TStream; Value: Char; Advance: Boolean = True): TMemSize;
begin
{$IFDEF Unicode}
Result := Stream_WriteWideChar(Stream,Value,Advance);
{$ELSE}
Result := Stream_WriteAnsiChar(Stream,Value,Advance);
{$ENDIF}
end;

//==============================================================================

Function Stream_WriteShortString(Stream: TStream; const Str: ShortString; Advance: Boolean = True): TMemSize;
begin
Result := Stream_WriteBuffer(Stream,{%H-}Pointer({%H-}PtrUInt(Addr(Str[1])) - 1)^,Length(Str) + 1, Advance);
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//------------------------------------------------------------------------------

Function Stream_WriteAnsiString(Stream: TStream; const Str: AnsiString; Advance: Boolean = True): TMemSize;
begin
Result := Stream_WriteInt32(Stream,Length(Str),True);
Inc(Result,Stream_WriteBuffer(Stream,PAnsiChar(Str)^,Length(Str) * SizeOf(AnsiChar),True));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//------------------------------------------------------------------------------

Function Stream_WriteUnicodeString(Stream: TStream; const Str: UnicodeString; Advance: Boolean = True): TMemSize;
begin
Result := Stream_WriteInt32(Stream,Length(Str),True);
{$IFDEF ENDIAN_BIG}
Inc(Result,Stream_WriteUTF16LE(Stream,PUInt16(PUnicodeChar(Str)),Length(Str)));
{$ELSE}
Inc(Result,Stream_WriteBuffer(Stream,PUnicodeChar(Str)^,Length(Str) * SizeOf(UnicodeChar),True));
{$ENDIF}
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//------------------------------------------------------------------------------

Function Stream_WriteWideString(Stream: TStream; const Str: WideString; Advance: Boolean = True): TMemSize;
begin
Result := Stream_WriteInt32(Stream,Length(Str),True);
{$IFDEF ENDIAN_BIG}
Inc(Result,Stream_WriteUTF16LE(Stream,PUInt16(PWideChar(Str)),Length(Str)));
{$ELSE}
Inc(Result,Stream_WriteBuffer(Stream,PWideChar(Str)^,Length(Str) * SizeOf(WideChar),True));
{$ENDIF}
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//------------------------------------------------------------------------------

Function Stream_WriteUTF8String(Stream: TStream; const Str: UTF8String; Advance: Boolean = True): TMemSize;
begin
Result := Stream_WriteInt32(Stream,Length(Str),True);
Inc(Result,Stream_WriteBuffer(Stream,PUTF8Char(Str)^,Length(Str) * SizeOf(UTF8Char),True));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//------------------------------------------------------------------------------

Function Stream_WriteString(Stream: TStream; const Str: String; Advance: Boolean = True): TMemSize;
begin
Result := Stream_WriteUTF8String(Stream,StrToUTF8(Str),Advance);
end;

//==============================================================================

Function Stream_WriteBuffer(Stream: TStream; const Buffer; Size: TMemSize; Advance: Boolean = True): TMemSize;
begin
Result := Stream.Write(Buffer,Size);
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//==============================================================================

Function Stream_WriteBytes(Stream: TStream; const Value: array of UInt8; Advance: Boolean = True): TMemSize;
var
  i:  Integer;
begin
Result := 0;
For i := Low(Value) to High(Value) do
  Inc(Result,Stream_WriteUInt8(Stream,Value[i],True));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//==============================================================================

Function Stream_FillBytes(Stream: TStream; Count: TMemSize; Value: UInt8; Advance: Boolean = True): TMemSize;
var
  i:  TMemSize;
begin
Result := 0;
For i := 1 to Count do
  begin
    Stream.Write(Value,SizeOf(Value));
    Inc(Result);
  end;
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

{------------------------------------------------------------------------------}
{==============================================================================}
{                                Stream reading                                }
{==============================================================================}
{------------------------------------------------------------------------------}

Function Stream_ReadBool(Stream: TStream; out Value: ByteBool; Advance: Boolean = True): TMemSize;
begin
Value := False;
Result := Stream.Read(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadBool(Stream: TStream; Advance: Boolean = True): ByteBool;
begin
Stream_ReadBool(Stream,Result,Advance);
end;

//------------------------------------------------------------------------------

Function Stream_ReadBoolean(Stream: TStream; out Value: Boolean; Advance: Boolean = True): TMemSize;
var
  TempBool: ByteBool;
begin
Result := Stream_ReadBool(Stream,TempBool,Advance);
Value := TempBool;
end;

//==============================================================================

Function Stream_ReadInt8(Stream: TStream; out Value: Int8; Advance: Boolean = True): TMemSize;
begin
Value := 0;
Result := Stream.Read(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadInt8(Stream: TStream; Advance: Boolean = True): Int8;
begin
Stream_ReadInt8(Stream,Result,Advance);
end;

//------------------------------------------------------------------------------

Function Stream_ReadUInt8(Stream: TStream; out Value: UInt8; Advance: Boolean = True): TMemSize;
begin
Value := 0;
Result := Stream.Read(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadUInt8(Stream: TStream; Advance: Boolean = True): UInt8;
begin
Stream_ReadUInt8(Stream,Result,Advance);
end;

//------------------------------------------------------------------------------

Function Stream_ReadInt16(Stream: TStream; out Value: Int16; Advance: Boolean = True): TMemSize;
begin
Value := 0;
Result := Stream.Read(Value,SizeOf(Value));
{$IFDEF ENDIAN_BIG}
Value := Int16(SwapEndian(UInt16(Value)));
{$ENDIF}
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadInt16(Stream: TStream; Advance: Boolean = True): Int16;
begin
Stream_ReadInt16(Stream,Result,Advance);
end;

//------------------------------------------------------------------------------

Function Stream_ReadUInt16(Stream: TStream; out Value: UInt16; Advance: Boolean = True): TMemSize;
begin
Value := 0;
Result := Stream.Read(Value,SizeOf(Value));
{$IFDEF ENDIAN_BIG}
Value := SwapEndian(Value);
{$ENDIF}
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadUInt16(Stream: TStream; Advance: Boolean = True): UInt16;
begin
Stream_ReadUInt16(Stream,Result,Advance);
end;

//------------------------------------------------------------------------------

Function Stream_ReadInt32(Stream: TStream; out Value: Int32; Advance: Boolean = True): TMemSize;
begin
Value := 0;
Result := Stream.Read(Value,SizeOf(Value));
{$IFDEF ENDIAN_BIG}
Value := Int32(SwapEndian(UInt32(Value)));
{$ENDIF}
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadInt32(Stream: TStream; Advance: Boolean = True): Int32;
begin
Stream_ReadInt32(Stream,Result,Advance);
end;

//------------------------------------------------------------------------------

Function Stream_ReadUInt32(Stream: TStream; out Value: UInt32; Advance: Boolean = True): TMemSize;
begin
Value := 0;
Result := Stream.Read(Value,SizeOf(Value));
{$IFDEF ENDIAN_BIG}
Value := SwapEndian(Value);
{$ENDIF}
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadUInt32(Stream: TStream; Advance: Boolean = True): UInt32;
begin
Stream_ReadUInt32(Stream,Result,Advance);
end;

//------------------------------------------------------------------------------

Function Stream_ReadInt64(Stream: TStream; out Value: Int64; Advance: Boolean = True): TMemSize;
begin
Value := 0;
Result := Stream.Read(Value,SizeOf(Value));
{$IFDEF ENDIAN_BIG}
Value := Int64(SwapEndian(UInt64(Value)));
{$ENDIF}
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadInt64(Stream: TStream; Advance: Boolean = True): Int64;
begin
Stream_ReadInt64(Stream,Result,Advance);
end;

//------------------------------------------------------------------------------

Function Stream_ReadUInt64(Stream: TStream; out Value: UInt64; Advance: Boolean = True): TMemSize;
begin
Value := 0;
Result := Stream.Read(Value,SizeOf(Value));
{$IFDEF ENDIAN_BIG}
Value := SwapEndian(Value);
{$ENDIF}
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadUInt64(Stream: TStream; Advance: Boolean = True): UInt64;
begin
Stream_ReadUInt64(Stream,Result,Advance);
end;

//==============================================================================

Function Stream_ReadFloat32(Stream: TStream; out Value: Float32; Advance: Boolean = True): TMemSize;
begin
Value := 0.0;
Result := Stream.Read(Value,SizeOf(Value));
{$IFDEF ENDIAN_BIG}
Value := SwapEndian(Value);
{$ENDIF}
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadFloat32(Stream: TStream; Advance: Boolean = True): Float32;
begin
Stream_ReadFloat32(Stream,Result,Advance);
end;

//------------------------------------------------------------------------------

Function Stream_ReadFloat64(Stream: TStream; out Value: Float64; Advance: Boolean = True): TMemSize;
begin
Value := 0.0;
Result := Stream.Read(Value,SizeOf(Value));
{$IFDEF ENDIAN_BIG}
Value := SwapEndian(Value);
{$ENDIF}
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadFloat64(Stream: TStream; Advance: Boolean = True): Float64;
begin
Stream_ReadFloat64(Stream,Result,Advance);
end;

//==============================================================================

Function Stream_ReadAnsiChar(Stream: TStream; out Value: AnsiChar; Advance: Boolean = True): TMemSize;
begin
Value := AnsiChar(0);
Result := Stream.Read(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadAnsiChar(Stream: TStream; Advance: Boolean = True): AnsiChar;
begin
Stream_ReadAnsiChar(Stream,Result,Advance);
end;

//------------------------------------------------------------------------------

Function Stream_ReadUTF8Char(Stream: TStream; out Value: UTF8Char; Advance: Boolean = True): TMemSize;
begin
Value := UTF8Char(0);
Result := Stream.Read(Value,SizeOf(Value));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;
 
//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadUTF8Char(Stream: TStream; Advance: Boolean = True): UTF8Char;
begin
Stream_ReadUTF8Char(Stream,Result,Advance);
end;
 
//------------------------------------------------------------------------------

Function Stream_ReadWideChar(Stream: TStream; out Value: WideChar; Advance: Boolean = True): TMemSize;
begin
Value := WideChar(0);
Result := Stream.Read(Value,SizeOf(Value));
{$IFDEF ENDIAN_BIG}
Value := WideChar(SwapEndian(UInt16(Value)));
{$ENDIF}
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;
 
//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadWideChar(Stream: TStream; Advance: Boolean = True): WideChar;
begin
Stream_ReadWideChar(Stream,Result,Advance);
end;
 
//------------------------------------------------------------------------------

Function Stream_ReadChar(Stream: TStream; out Value: Char; Advance: Boolean = True): TMemSize;
begin
{$IFDEF Unicode}
Result := Stream_ReadWideChar(Stream,Value,Advance);
{$ELSE}
Result := Stream_ReadAnsiChar(Stream,Value,Advance);
{$ENDIF}
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadChar(Stream: TStream; Advance: Boolean = True): Char;
begin
Stream_ReadChar(Stream,Result,Advance);
end;

//==============================================================================

Function Stream_ReadShortString(Stream: TStream; out Str: ShortString; Advance: Boolean = True): TMemSize;
var
  StrLength:  UInt8;
begin
Result := Stream_ReadUInt8(Stream,StrLength,True);
SetLength(Str,StrLength);
Inc(Result,Stream_ReadBuffer(Stream,Addr(Str[1])^,StrLength,True));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadShortString(Stream: TStream; Advance: Boolean = True): ShortString;
begin
Stream_ReadShortString(Stream,Result,Advance);
end;

//------------------------------------------------------------------------------

Function Stream_ReadAnsiString(Stream: TStream; out Str: AnsiString; Advance: Boolean = True): TMemSize;
var
  StrLength:  Int32;
begin
Result := Stream_ReadInt32(Stream,StrLength,True);
SetLength(Str,StrLength);
Inc(Result,Stream_ReadBuffer(Stream,PAnsiChar(Str)^,StrLength * SizeOf(AnsiChar),True));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadAnsiString(Stream: TStream; Advance: Boolean = True): AnsiString;
begin
Stream_ReadAnsiString(Stream,Result,Advance);
end;

//------------------------------------------------------------------------------

Function Stream_ReadUnicodeString(Stream: TStream; out Str: UnicodeString; Advance: Boolean = True): TMemSize;
var
  StrLength:  Int32;
begin
Result := Stream_ReadInt32(Stream,StrLength,True);
SetLength(Str,StrLength);
{$IFDEF ENDIAN_BIG}
Inc(Result,Stream_ReadUTF16LE(Stream,PUInt16(PUnicodeChar(Str)),StrLength));
{$ELSE}
Inc(Result,Stream_ReadBuffer(Stream,PUnicodeChar(Str)^,StrLength * SizeOf(UnicodeChar),True));
{$ENDIF}
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadUnicodeString(Stream: TStream; Advance: Boolean = True): UnicodeString;
begin
Stream_ReadUnicodeString(Stream,Result,Advance);
end;

//------------------------------------------------------------------------------

Function Stream_ReadWideString(Stream: TStream; out Str: WideString; Advance: Boolean = True): TMemSize;
var
  StrLength:  Int32;
begin
Result := Stream_ReadInt32(Stream,StrLength,True);
SetLength(Str,StrLength);
{$IFDEF ENDIAN_BIG}
Inc(Result,Stream_ReadUTF16LE(Stream,PUInt16(PWideChar(Str)),StrLength));
{$ELSE}
Inc(Result,Stream_ReadBuffer(Stream,PWideChar(Str)^,StrLength * SizeOf(WideChar),True));
{$ENDIF}
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadWideString(Stream: TStream; Advance: Boolean = True): WideString;
begin
Stream_ReadWideString(Stream,Result,Advance);
end;

//------------------------------------------------------------------------------

Function Stream_ReadUTF8String(Stream: TStream; out Str: UTF8String; Advance: Boolean = True): TMemSize;
var
  StrLength:  Int32;
begin
Result := Stream_ReadInt32(Stream,StrLength,True);
SetLength(Str,StrLength);
Inc(Result,Stream_ReadBuffer(Stream,PUTF8Char(Str)^,StrLength * SizeOf(UTF8Char),True));
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadUTF8String(Stream: TStream; Advance: Boolean = True): UTF8String;
begin
Stream_ReadUTF8String(Stream,Result,Advance);
end;

//------------------------------------------------------------------------------

Function Stream_ReadString(Stream: TStream; out Str: String; Advance: Boolean = True): TMemSize;
var
  TempStr:  UTF8String;
begin
Result := Stream_ReadUTF8String(Stream,TempStr,Advance);
Str := UTF8ToStr(TempStr);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function Stream_ReadString(Stream: TStream; Advance: Boolean = True): String;
begin
Stream_ReadString(Stream,Result,Advance);
end;

//==============================================================================

Function Stream_ReadBuffer(Stream: TStream; var Buffer; Size: TMemSize; Advance: Boolean = True): TMemSize;
begin
Result := Stream.Read(Buffer,Size);
If not Advance then Stream.Seek(-Int64(Result),soCurrent);
end;

{------------------------------------------------------------------------------}
{==============================================================================}
{                               Streaming objects                              }
{==============================================================================}
{------------------------------------------------------------------------------}

{==============================================================================}
{                                TCustomStreamer                               }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TCustomStreamer - protected methods                                        }
{------------------------------------------------------------------------------}

Function TCustomStreamer.GetBookmarkCount: Integer;
begin
Result := Length(fBookmarks);
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.GetBookmark(Index: Integer): UInt64;
begin
If (Index >= Low(fBookmarks)) and (Index <= High(fBookmarks)) then
  Result := fBookmarks[Index]
else
  raise Exception.CreateFmt('TCustomStreamer.GetBookmark: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure TCustomStreamer.SetBookmark(Index: Integer; Value: UInt64);
begin
If (Index >= Low(fBookmarks)) and (Index <= High(fBookmarks)) then
  fBookmarks[Index] := Value
else
  raise Exception.CreateFmt('TCustomStreamer.SetBookmark: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.GetDistance: Int64;
begin
Result := CurrentPosition - StartPosition;
end;

{------------------------------------------------------------------------------}
{   TCustomStreamer - public methods                                           }
{------------------------------------------------------------------------------}

procedure TCustomStreamer.Initialize;
begin
SetLength(fBookmarks,0);
fStartPosition := 0;
end;

//------------------------------------------------------------------------------

procedure TCustomStreamer.MoveToStart;
begin
CurrentPosition := StartPosition;
end;

//------------------------------------------------------------------------------

procedure TCustomStreamer.MoveToBookmark(Index: Integer);
begin
If (Index >= Low(fBookmarks)) and (Index <= High(fBookmarks)) then
  CurrentPosition := fBookmarks[Index]
else
  raise Exception.CreateFmt('TCustomStreamer.MoveToBookmark: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure TCustomStreamer.MoveBy(Offset: Int64);
begin
CurrentPosition := CurrentPosition + Offset;
end;

//------------------------------------------------------------------------------
 
Function TCustomStreamer.IndexOfBookmark(Position: UInt64): Integer;
var
  i:  Integer;
begin
Result := -1;
For i := Low(fBookMarks) to High(fBookmarks) do
  If fBookmarks[i] = Position then
    begin
      Result := i;
      Break;
    end;
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.AddBookmark: Integer;
begin
Result := AddBookmark(CurrentPosition);
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.AddBookmark(Position: UInt64): Integer;
begin
SetLength(fBookmarks,Length(fBookmarks) + 1);
Result := High(fBookmarks);
fBookmarks[Result] := Position;
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.RemoveBookmark(Position: UInt64; RemoveAll: Boolean = True): Integer;
begin
repeat
  Result := IndexOfBookmark(Position);
  If Result >= 0 then
    DeleteBookMark(Result);
until (Result < 0) or not RemoveAll;
end;

//------------------------------------------------------------------------------

procedure TCustomStreamer.DeleteBookmark(Index: Integer);
var
  i:  Integer;
begin
If (Index >= Low(fBookmarks)) and (Index <= High(fBookmarks)) then
  begin
    For i := Index to Pred(High(fBookmarks)) do
      fBookmarks[i] := fBookMarks[i + 1];
    SetLength(fBookmarks,Length(fBookmarks) - 1);
  end
else raise Exception.CreateFmt('TCustomStreamer.DeleteBookmark: Index (%d) out of bounds.',[Index]);
end;

//==============================================================================

Function TCustomStreamer.WriteBool(Value: ByteBool; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,SizeOf(Value));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.WriteBoolean(Value: Boolean; Advance: Boolean = True): TMemSize;
begin
Result := WriteBool(Value,Advance);
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.WriteInt8(Value: Int8; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,SizeOf(Value));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.WriteUInt8(Value: UInt8; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,SizeOf(Value));
end;
 
//------------------------------------------------------------------------------

Function TCustomStreamer.WriteInt16(Value: Int16; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,SizeOf(Value));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.WriteUInt16(Value: UInt16; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,SizeOf(Value));
end;

Function TCustomStreamer.WriteInt32(Value: Int32; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,SizeOf(Value));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.WriteUInt32(Value: UInt32; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,SizeOf(Value));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.WriteInt64(Value: Int64; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,SizeOf(Value));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.WriteUInt64(Value: UInt64; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,SizeOf(Value));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.WriteFloat32(Value: Float32; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,SizeOf(Value));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.WriteFloat64(Value: Float64; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,SizeOf(Value));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.WriteAnsiChar(Value: AnsiChar; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,SizeOf(Value));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.WriteUTF8Char(Value: UTF8Char; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,SizeOf(Value));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.WriteWideChar(Value: WideChar; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,SizeOf(Value));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.WriteChar(Value: Char; Advance: Boolean = True): TMemSize;
begin
{$IFDEF Unicode}
Result := WriteWideChar(Value,Advance);
{$ELSE}
Result := WriteAnsiChar(Value,Advance);
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.WriteShortString(const Value: ShortString; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,0,PARAM_SHORTSTRING);
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.WriteAnsiString(const Value: AnsiString; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,0,PARAM_ANSISTRING);
end;
 
//------------------------------------------------------------------------------

Function TCustomStreamer.WriteUnicodeString(const Value: UnicodeString; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,0,PARAM_UNICODESTRING);
end;
  
//------------------------------------------------------------------------------

Function TCustomStreamer.WriteWideString(const Value: WideString; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,0,PARAM_WIDESTRING);
end;
  
//------------------------------------------------------------------------------

Function TCustomStreamer.WriteUTF8String(const Value: UTF8String; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,0,PARAM_UTF8STRING);
end;
  
//------------------------------------------------------------------------------

Function TCustomStreamer.WriteString(const Value: String; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,0,PARAM_STRING);
end;
  
//------------------------------------------------------------------------------

Function TCustomStreamer.WriteBuffer(const Buffer; Size: TMemSize; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Buffer,Advance,Size);
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.WriteBytes(const Value: array of UInt8; Advance: Boolean = True): TMemSize;
var
  i:      Integer;
  OldPos: UInt64;
begin
OldPos := CurrentPosition;
Result := 0;
For i := Low(Value) to High(Value) do
  WriteUInt8(Value[i],True);
If not Advance then CurrentPosition := OldPos;
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.FillBytes(Count: TMemSize; Value: UInt8; Advance: Boolean = True): TMemSize;
begin
Result := WriteValue(@Value,Advance,Count,PARAM_FILLBYTES);
end;

//==============================================================================

Function TCustomStreamer.ReadBool(out Value: ByteBool; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,SizeOf(Value));
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadBool(Advance: Boolean = True): ByteBool;
begin
ReadValue(@Result,Advance,SizeOf(Result));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadBoolean(out Value: Boolean; Advance: Boolean = True): TMemSize;
var
  TempBool: ByteBool;
begin
Result := ReadBool(TempBool,Advance);
Value := TempBool;
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadInt8(out Value: Int8; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,SizeOf(Value));
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadInt8(Advance: Boolean = True): Int8;
begin
ReadValue(@Result,Advance,SizeOf(Result));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadUInt8(out Value: UInt8; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,SizeOf(Value));
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadUInt8(Advance: Boolean = True): UInt8;
begin
ReadValue(@Result,Advance,SizeOf(Result));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadInt16(out Value: Int16; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,SizeOf(Value));
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadInt16(Advance: Boolean = True): Int16;
begin
ReadValue(@Result,Advance,SizeOf(Result));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadUInt16(out Value: UInt16; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,SizeOf(Value));
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadUInt16(Advance: Boolean = True): UInt16;
begin
ReadValue(@Result,Advance,SizeOf(Result));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadInt32(out Value: Int32; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,SizeOf(Value));
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadInt32(Advance: Boolean = True): Int32;
begin
ReadValue(@Result,Advance,SizeOf(Result));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadUInt32(out Value: UInt32; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,SizeOf(Value));
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadUInt32(Advance: Boolean = True): UInt32;
begin
ReadValue(@Result,Advance,SizeOf(Result));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadInt64(out Value: Int64; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,SizeOf(Value));
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadInt64(Advance: Boolean = True): Int64;
begin
ReadValue(@Result,Advance,SizeOf(Result));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadUInt64(out Value: UInt64; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,SizeOf(Value));
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadUInt64(Advance: Boolean = True): UInt64;
begin
ReadValue(@Result,Advance,SizeOf(Result));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadFloat32(out Value: Float32; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,SizeOf(Value));
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadFloat32(Advance: Boolean = True): Float32;
begin
ReadValue(@Result,Advance,SizeOf(Result));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadFloat64(out Value: Float64; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,SizeOf(Value));
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadFloat64(Advance: Boolean = True): Float64;
begin
ReadValue(@Result,Advance,SizeOf(Result));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadAnsiChar(out Value: AnsiChar; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,SizeOf(Value));
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadAnsiChar(Advance: Boolean = True): AnsiChar;
begin
ReadValue(@Result,Advance,SizeOf(Result));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadUTF8Char(out Value: UTF8Char; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,SizeOf(Value));
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadUTF8Char(Advance: Boolean = True): UTF8Char;
begin
ReadValue(@Result,Advance,SizeOf(Result));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadWideChar(out Value: WideChar; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,SizeOf(Value));
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadWideChar(Advance: Boolean = True): WideChar;
begin
ReadValue(@Result,Advance,SizeOf(Result));
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadChar(out Value: Char; Advance: Boolean = True): TMemSize;
begin
{$IFDEF Unicode}
Result := ReadWideChar(Value,Advance);
{$ELSE}
Result := ReadAnsiChar(Value,Advance);
{$ENDIF}
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadChar(Advance: Boolean = True): Char;
begin
{$IFDEF Unicode}
Result := ReadWideChar(Advance);
{$ELSE}
Result := ReadAnsiChar(Advance);
{$ENDIF}
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadShortString(out Value: ShortString; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,0,PARAM_SHORTSTRING);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadShortString(Advance: Boolean = True): ShortString;
begin
ReadValue(@Result,Advance,0,PARAM_SHORTSTRING);
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadAnsiString(out Value: AnsiString; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,0,PARAM_ANSISTRING);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadAnsiString(Advance: Boolean = True): AnsiString;
begin
ReadValue(@Result,Advance,0,PARAM_ANSISTRING);
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadUnicodeString(out Value: UnicodeString; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,0,PARAM_UNICODESTRING);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadUnicodeString(Advance: Boolean = True): UnicodeString;
begin
ReadValue(@Result,Advance,0,PARAM_UNICODESTRING);
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadWideString(out Value: WideString; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,0,PARAM_WIDESTRING);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadWideString(Advance: Boolean = True): WideString;
begin
ReadValue(@Result,Advance,0,PARAM_WIDESTRING);
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadUTF8String(out Value: UTF8String; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,0,PARAM_UTF8STRING);
end;
 
//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadUTF8String(Advance: Boolean = True): UTF8String;
begin
ReadValue(@Result,Advance,0,PARAM_UTF8STRING);
end;
 
//------------------------------------------------------------------------------

Function TCustomStreamer.ReadString(out Value: String; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Value,Advance,0,PARAM_STRING);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

Function TCustomStreamer.ReadString(Advance: Boolean = True): String;
begin
ReadValue(@Result,Advance,0,PARAM_STRING);
end;

//------------------------------------------------------------------------------

Function TCustomStreamer.ReadBuffer(var Buffer; Size: TMemSize; Advance: Boolean = True): TMemSize;
begin
Result := ReadValue(@Buffer,Advance,Size);
end;

{==============================================================================}
{                                TMemoryStreamer                               }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TMemoryStreamer - private methods                                          }
{------------------------------------------------------------------------------}

Function TMemoryStreamer.GetStartPtr: Pointer;
begin
Result := {%H-}Pointer(fStartPosition);
end;

{------------------------------------------------------------------------------}
{   TMemoryStreamer - protected methods                                        }
{------------------------------------------------------------------------------}

procedure TMemoryStreamer.SetBookmark(Index: Integer; Value: UInt64);
begin
inherited SetBookmark(Index,UInt64(PtrUInt(Value)));
end;

//------------------------------------------------------------------------------

Function TMemoryStreamer.GetCurrentPosition: UInt64;
begin
Result := {%H-}UInt64(fCurrentPtr);
end;

//------------------------------------------------------------------------------

procedure TMemoryStreamer.SetCurrentPosition(NewPosition: UInt64);
begin
fCurrentPtr := {%H-}Pointer(PtrUInt(NewPosition));
end;

//------------------------------------------------------------------------------

Function TMemoryStreamer.WriteValue(Value: Pointer; Advance: Boolean; Size: TMemSize; Param: Integer = 0): TMemSize;
begin
case Param of
  PARAM_SHORTSTRING:    Result := Ptr_WriteShortString(fCurrentPtr,ShortString(Value^),Advance);
  PARAM_ANSISTRING:     Result := Ptr_WriteAnsiString(fCurrentPtr,AnsiString(Value^),Advance);
  PARAM_UNICODESTRING:  Result := Ptr_WriteUnicodeString(fCurrentPtr,UnicodeString(Value^),Advance);
  PARAM_WIDESTRING:     Result := Ptr_WriteWideString(fCurrentPtr,WideString(Value^),Advance);
  PARAM_UTF8STRING:     Result := Ptr_WriteUTF8String(fCurrentPtr,UTF8String(Value^),Advance);
  PARAM_STRING:         Result := Ptr_WriteString(fCurrentPtr,String(Value^),Advance);
  PARAM_FILLBYTES:      Result := Ptr_FillBytes(fCurrentPtr,Size,UInt8(Value^),Advance);
else
  case Size of
    1:  Result := Ptr_WriteUInt8(fCurrentPtr,UInt8(Value^),Advance);
    2:  Result := Ptr_WriteUInt16(fCurrentPtr,UInt16(Value^),Advance);
    4:  Result := Ptr_WriteUInt32(fCurrentPtr,UInt32(Value^),Advance);
    8:  Result := Ptr_WriteUInt64(fCurrentPtr,UInt64(Value^),Advance);
  else
    Result := Ptr_WriteBuffer(fCurrentPtr,Value^,Size,Advance);
  end;
end;
end;

//------------------------------------------------------------------------------

Function TMemoryStreamer.ReadValue(Value: Pointer; Advance: Boolean; Size: TMemSize; Param: Integer = 0): TMemSize;
begin
case Param of
  PARAM_SHORTSTRING:    Result := Ptr_ReadShortString(fCurrentPtr,ShortString(Value^),Advance);
  PARAM_ANSISTRING:     Result := Ptr_ReadAnsiString(fCurrentPtr,AnsiString(Value^),Advance);
  PARAM_UNICODESTRING:  Result := Ptr_ReadUnicodeString(fCurrentPtr,UnicodeString(Value^),Advance);
  PARAM_WIDESTRING:     Result := Ptr_ReadWideString(fCurrentPtr,WideString(Value^),Advance);
  PARAM_UTF8STRING:     Result := Ptr_ReadUTF8String(fCurrentPtr,UTF8String(Value^),Advance);
  PARAM_STRING:         Result := Ptr_ReadString(fCurrentPtr,String(Value^),Advance);
else
  case Size of
    1:  Result := Ptr_ReadUInt8(fCurrentPtr,UInt8(Value^),Advance);
    2:  Result := Ptr_ReadUInt16(fCurrentPtr,UInt16(Value^),Advance);
    4:  Result := Ptr_ReadUInt32(fCurrentPtr,UInt32(Value^),Advance);
    8:  Result := Ptr_ReadUInt64(fCurrentPtr,UInt64(Value^),Advance);
  else
    Result := Ptr_ReadBuffer(fCurrentPtr,Value^,Size,Advance);
  end;
end;
end;

{------------------------------------------------------------------------------}
{   TMemoryStreamer - public methods                                           }
{------------------------------------------------------------------------------}

constructor TMemoryStreamer.Create(Memory: Pointer);
begin
inherited Create;
fOwnsPointer := False;
Initialize(Memory);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

constructor TMemoryStreamer.Create(Size: PtrUInt);
begin
inherited Create;
fOwnsPointer := False;
Initialize(Size);
end;

//------------------------------------------------------------------------------

destructor TMemoryStreamer.Destroy;
begin
If fOwnsPointer then
  FreeMem(StartPtr,PtrSize);
inherited;
end;

//------------------------------------------------------------------------------

procedure TMemoryStreamer.Initialize(Memory: Pointer);
begin
inherited Initialize;
fOwnsPointer := False;
fPtrSize := 0;
fCurrentPtr := Memory;
fStartPosition := {%H-}UInt64(Memory);
end;

//   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---   ---

procedure TMemoryStreamer.Initialize(Size: PtrUInt);
var
  TempPtr:  Pointer;
begin
inherited Initialize;
If fOwnsPointer then
  begin
    TempPtr := StartPtr;
    ReallocMem(TempPtr,Size);
  end
else TempPtr := AllocMem(Size);
fOwnsPointer := True;
fPtrSize := Size;
fCurrentPtr := TempPtr;
fStartPosition := {%H-}UInt64(TempPtr);
end;

//------------------------------------------------------------------------------

Function TMemoryStreamer.IndexOfBookmark(Position: UInt64): Integer;
begin
Result := inherited IndexOfBookmark(PtrUInt(Position));
end;

//------------------------------------------------------------------------------

Function TMemoryStreamer.AddBookmark(Position: UInt64): Integer;
begin
Result := inherited AddBookmark(PtrUInt(Position));
end;

//------------------------------------------------------------------------------

Function TMemoryStreamer.RemoveBookmark(Position: UInt64; RemoveAll: Boolean = True): Integer;
begin
Result := inherited RemoveBookmark(PtrUInt(Position),RemoveAll);
end;


{==============================================================================}
{                                TStreamStreamer                               }
{==============================================================================}

{------------------------------------------------------------------------------}
{   TStreamStreamer - protected methods                                        }
{------------------------------------------------------------------------------}

Function TStreamStreamer.GetCurrentPosition: UInt64;
begin
Result := UInt64(fTarget.Position);
end;

//------------------------------------------------------------------------------

procedure TStreamStreamer.SetCurrentPosition(NewPosition: UInt64);
begin
fTarget.Position := Int64(NewPosition);
end;

//------------------------------------------------------------------------------

Function TStreamStreamer.WriteValue(Value: Pointer; Advance: Boolean; Size: TMemSize; Param: Integer = 0): TMemSize;
begin
case Param of
  PARAM_SHORTSTRING:    Result := Stream_WriteShortString(fTarget,ShortString(Value^),Advance);
  PARAM_ANSISTRING:     Result := Stream_WriteAnsiString(fTarget,AnsiString(Value^),Advance);
  PARAM_UNICODESTRING:  Result := Stream_WriteUnicodeString(fTarget,UnicodeString(Value^),Advance);
  PARAM_WIDESTRING:     Result := Stream_WriteWideString(fTarget,WideString(Value^),Advance);
  PARAM_UTF8STRING:     Result := Stream_WriteUTF8String(fTarget,UTF8String(Value^),Advance);
  PARAM_STRING:         Result := Stream_WriteString(fTarget,String(Value^),Advance);
  PARAM_FILLBYTES:      Result := Stream_FillBytes(fTarget,Size,UInt8(Value^),Advance);
else
  case Size of
    1:  Result := Stream_WriteUInt8(fTarget,UInt8(Value^),Advance);
    2:  Result := Stream_WriteUInt16(fTarget,UInt16(Value^),Advance);
    4:  Result := Stream_WriteUInt32(fTarget,UInt32(Value^),Advance);
    8:  Result := Stream_WriteUInt64(fTarget,UInt64(Value^),Advance);
  else
    Result := Stream_WriteBuffer(fTarget,Value^,Size,Advance);
  end;
end;
end;

//------------------------------------------------------------------------------

Function TStreamStreamer.ReadValue(Value: Pointer; Advance: Boolean; Size: TMemSize; Param: Integer = 0): TMemSize;
begin
case Param of
  PARAM_SHORTSTRING:    Result := Stream_ReadShortString(fTarget,ShortString(Value^),Advance);
  PARAM_ANSISTRING:     Result := Stream_ReadAnsiString(fTarget,AnsiString(Value^),Advance);
  PARAM_UNICODESTRING:  Result := Stream_ReadUnicodeString(fTarget,UnicodeString(Value^),Advance);
  PARAM_WIDESTRING:     Result := Stream_ReadWideString(fTarget,WideString(Value^),Advance);
  PARAM_UTF8STRING:     Result := Stream_ReadUTF8String(fTarget,UTF8String(Value^),Advance);
  PARAM_STRING:         Result := Stream_ReadString(fTarget,String(Value^),Advance);
else
  case Size of
    1:  Result := Stream_ReadUInt8(fTarget,UInt8(Value^),Advance);
    2:  Result := Stream_ReadUInt16(fTarget,UInt16(Value^),Advance);
    4:  Result := Stream_ReadUInt32(fTarget,UInt32(Value^),Advance);
    8:  Result := Stream_ReadUInt64(fTarget,UInt64(Value^),Advance);
  else
    Result := Stream_ReadBuffer(fTarget,Value^,Size,Advance);
  end;
end;
end;

{------------------------------------------------------------------------------}
{   TStreamStreamer - public methods                                           }
{------------------------------------------------------------------------------}

constructor TStreamStreamer.Create(Target: TStream);
begin
inherited Create;
Initialize(Target);
end;

//------------------------------------------------------------------------------

procedure TStreamStreamer.Initialize(Target: TStream);
begin
inherited Initialize;
fTarget := Target;
fStartPosition := Target.Position;
end;

end.


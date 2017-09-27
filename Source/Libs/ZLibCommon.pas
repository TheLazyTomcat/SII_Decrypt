{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  zlib bindings (expected zlib version: 1.2.11)

  Common types, constants and functions

  These units provides plain (no wrappers or helpers) bindings for zlib library.
  Most comments were copied directly from zlib.h header without any change.

  This binding is distributed with all necessary binaries (object files, DLLs)
  precompiled. For details please refer to file bin_readme.txt.

  ©František Milt 2017-08-07

  Version 1.0

  Dependencies:
    AuxTypes  - github.com/ncs-sniper/Lib.AuxTypes
  * StrRect   - github.com/ncs-sniper/Lib.StrRect

  StrRect is required only for dynamically linked part of the binding (unit
  ZLibDynamic).

===============================================================================}
unit ZLibCommon;

{$INCLUDE '.\ZLib_defs.inc'}

interface

uses
  AuxTypes;

{===============================================================================
    Basic constants and types
===============================================================================}

const
  LibName = 'zlib1.dll';

type
  int      = Int32;         pint      = ^int;
  off_t    = Int32;
  off64_t  = Int64;
  size_t   = PtrUInt;
  uInt     = UInt32;        puInt     = ^uInt;
  uLong    = UInt32;        puLong    = ^uLong;
  unsigned = UInt32;        punsigned = ^unsigned;
  long     = Int32;
  PPByte   = ^PByte;

{===============================================================================
    Zlib constants and types
===============================================================================}

const
  z_errmsg: array[0..9] of PAnsiChar = (
    'need dictionary',      // Z_NEED_DICT       2
    'stream end',           // Z_STREAM_END      1
    '',                     // Z_OK              0
    'file error',           // Z_ERRNO         (-1)
    'stream error',         // Z_STREAM_ERROR  (-2)
    'data error',           // Z_DATA_ERROR    (-3)
    'insufficient memory',  // Z_MEM_ERROR     (-4)
    'buffer error',         // Z_BUF_ERROR     (-5)
    'incompatible version', // Z_VERSION_ERROR (-6)
    '');

type
  z_size_t  = size_t;
  z_off_t   = off_t;
  z_off64_t = off64_t;
  z_crc_t   = UInt32;     pz_crc_t = ^z_crc_t;

const
  MAX_MEM_LEVEL = 9;
  MAX_WBITS     = 15;

  DEF_MEM_LEVEL = 8;
  DEF_WBITS     = MAX_WBITS;

  SEEK_SET = 0;   (* Seek from beginning of file.  *)
  SEEK_CUR = 1;   (* Seek from current position.  *)
  SEEK_END = 2;   (* Set file pointer to EOF plus "offset" *)

  WBITS_RAW  = -15;
  WBITS_ZLIB = 15;
  WBITS_GZIP = 31;

const
  ZLIB_VERSION         = AnsiString('1.2.11');
  ZLIB_VERNUM          = $12b0;
  ZLIB_VER_MAJOR       = 1;
  ZLIB_VER_MINOR       = 2;
  ZLIB_VER_REVISION    = 11;
  ZLIB_VER_SUBREVISION = 0;

(*
    The 'zlib' compression library provides in-memory compression and
  decompression functions, including integrity checks of the uncompressed data.
  This version of the library supports only one compression method (deflation)
  but other algorithms will be added later and will have the same stream
  interface.

    Compression can be done in a single step if the buffers are large enough,
  or can be done by repeated calls of the compression function.  In the latter
  case, the application must provide more input and/or consume the output
  (providing more output space) before each call.

    The compressed data format used by default by the in-memory functions is
  the zlib format, which is a zlib wrapper documented in RFC 1950, wrapped
  around a deflate stream, which is itself documented in RFC 1951.

    The library also supports reading and writing files in gzip (.gz) format
  with an interface similar to that of stdio using the functions that start
  with "gz".  The gzip format is different from the zlib format.  gzip is a
  gzip wrapper, documented in RFC 1952, wrapped around a deflate stream.

    This library can optionally read and write gzip and raw deflate streams in
  memory as well.

    The zlib format was designed to be compact and fast for use in memory
  and on communications channels.  The gzip format was designed for single-
  file compression on file systems, has a larger header than zlib to maintain
  directory information, and uses a different, slower check method than zlib.

    The library does not install any signal handler.  The decoder checks
  the consistency of the compressed data, so the library should never crash
  even in the case of corrupted input.
*)

type
  alloc_func = Function(opaque: Pointer; items, size: uInt): Pointer; cdecl;
  free_func = procedure(opaque, address: Pointer); cdecl;

  internal_state = record end;

  z_stream_s = record
    next_in:    PByte;      (* next input byte *)
    avail_in:   uInt;       (* number of bytes available at next_in *)
    total_in:   uLong;      (* total number of input bytes read so far *)

    next_out:   PByte;      (* next output byte will go here *)
    avail_out:  uInt;       (* remaining free space at next_out *)
    total_out:  uLong;      (* total number of bytes output so far *)

    msg:        PAnsiChar;        (* last error message, NULL if no error *)
    state:      ^internal_state;  (* not visible by applications *)

    zalloc:     alloc_func; (* used to allocate the internal state *)
    zfree:      free_func;  (* used to free the internal state *)
    opaque:     Pointer;    (* private data object passed to zalloc and zfree *)

    data_type:  int;        (* best guess about the data type: binary or text
                             for deflate, or the decoding state for inflate *)
    adler:      uLong;      (* Adler-32 or CRC-32 value of the uncompressed data *)
    reserved:   uLong;      (* reserved for future use *)
  end;
  z_stream  = z_stream_s;
  z_streamp = ^z_stream_s;

(*
     gzip header information passed to and from zlib routines.  See RFC 1952
  for more details on the meanings of these fields.
*)
  gz_header_s = record
    text:       int;        (* true if compressed data believed to be text *)
    time:       uLong;      (* modification time *)
    xflags:     int;        (* extra flags (not used when writing a gzip file) *)
    os:         int;        (* operating system *)
    extra:      PByte;      (* pointer to extra field or Z_NULL if none *)
    extra_len:  uInt;       (* extra field length (valid if extra != Z_NULL) *)
    extra_max:  uInt;       (* space at extra (only when reading header) *)
    name:       PByte;      (* pointer to zero-terminated file name or Z_NULL *)
    name_max:   uInt;       (* space at name (only when reading header) *)
    comment:    PByte;      (* pointer to zero-terminated comment or Z_NULL *)
    comm_max:   uInt;       (* space at comment (only when reading header) *)
    hcrc:       int;        (* true if there was or will be a header crc *)
    done:       int;        (* true when done reading gzip header (not used
                               when writing a gzip file) *)
  end;
  gz_header  = gz_header_s;
  gz_headerp = ^gz_header;

(*
     The application must update next_in and avail_in when avail_in has dropped
   to zero.  It must update next_out and avail_out when avail_out has dropped
   to zero.  The application must initialize zalloc, zfree and opaque before
   calling the init function.  All other fields are set by the compression
   library and must not be updated by the application.

     The opaque value provided by the application will be passed as the first
   parameter for calls of zalloc and zfree.  This can be useful for custom
   memory management.  The compression library attaches no meaning to the
   opaque value.

     zalloc must return Z_NULL if there is not enough memory for the object.
   If zlib is used in a multi-threaded application, zalloc and zfree must be
   thread safe.  In that case, zlib is thread-safe.  When zalloc and zfree are
   Z_NULL on entry to the initialization function, they are set to internal
   routines that use the standard library functions malloc() and free().

     On 16-bit systems, the functions zalloc and zfree must be able to allocate
   exactly 65536 bytes, but will not be required to allocate more than this if
   the symbol MAXSEG_64K is defined (see zconf.h).  WARNING: On MSDOS, pointers
   returned by zalloc for objects of exactly 65536 bytes *must* have their
   offset normalized to zero.  The default allocation function provided by this
   library ensures this (see zutil.c).  To reduce memory requirements and avoid
   any allocation of 64K objects, at the expense of compression ratio, compile
   the library with -DMAX_WBITS=14 (see zconf.h).

     The fields total_in and total_out can be used for statistics or progress
   reports.  After compression, total_in holds the total size of the
   uncompressed data and may be saved for use by the decompressor (particularly
   if the decompressor wants to decompress everything in a single step).
*)

(* constants *)
const
  Z_NO_FLUSH      = 0;
  Z_PARTIAL_FLUSH = 1;
  Z_SYNC_FLUSH    = 2;
  Z_FULL_FLUSH    = 3;
  Z_FINISH        = 4;
  Z_BLOCK         = 5;
  Z_TREES         = 6;
(* Allowed flush values; see deflate() and inflate() below for details *)

  Z_OK            = 0;
  Z_STREAM_END    = 1;
  Z_NEED_DICT     = 2;
  Z_ERRNO         = -1;
  Z_STREAM_ERROR  = -2;
  Z_DATA_ERROR    = -3;
  Z_MEM_ERROR     = -4;
  Z_BUF_ERROR     = -5;
  Z_VERSION_ERROR = -6;
(* Return codes for the compression/decompression functions. Negative values
* are errors, positive values are used for special but normal events.
*)

  Z_NO_COMPRESSION      = 0;
  Z_BEST_SPEED          = 1;
  Z_BEST_COMPRESSION    = 9;
  Z_DEFAULT_COMPRESSION = -1;
(* compression levels *)

  Z_FILTERED         = 1;
  Z_HUFFMAN_ONLY     = 2;
  Z_RLE              = 3;
  Z_FIXED            = 4;
  Z_DEFAULT_STRATEGY = 0;
(* compression strategy; see deflateInit2() below for details *)

  Z_BINARY  = 0;
  Z_TEXT    = 1;
  Z_ASCII   = Z_TEXT;  (* for compatibility with 1.2.2 and earlier *)
  Z_UNKNOWN = 2;
(* Possible values of the data_type field for deflate() *)

  Z_DEFLATED = 8;
(* The deflate compression method (the only one supported in this version) *)

	Z_NULL = nil;   (* for initializing zalloc, zfree, opaque *)

type
  in_func = Function(Ptr: Pointer; Buff: PPByte): unsigned; cdecl;
  out_func = Function(Ptr: Pointer; Buff: PByte; Len: unsigned): int; cdecl;

  gzFile_s = record
    have: unsigned;
    next: PByte;
    pos:  z_off64_t;
  end;

  gzFile = ^gzFile_s;   (* semi-opaque gzip file descriptor *)

{===============================================================================
    Auxiliary functions
===============================================================================}

procedure CheckCompatibility(Flags: uLong);

implementation

procedure CheckCompatibility(Flags: uLong);
begin
// check sizes of integer types
Assert((Flags and 3) = 1,'uInt is not 32bit in size');
Assert(((Flags shr 2) and 3) = 1,'uLong is not 32bit in size');
{$IFDEF x64}
Assert(((Flags shr 4) and 3) = 2,'voidpf is not 64bit in size');
{$ELSE}
Assert(((Flags shr 4) and 3) = 1,'voidpf is not 32bit in size');
{$ENDIF}
Assert(((Flags shr 6) and 3) = 1,'z_off_t is not 32bit in size');
// check whether calling convention is *not* STDCALL (ie. it is CDECL))
Assert(((Flags shr 10) and 1) = 0,'incomatible calling convention');
// check if all funcionality is available
Assert(((Flags shr 16) and 1) = 0,'gz* functions cannot compress');
Assert(((Flags shr 17) and 1) = 0,'unable to write gzip stream');
end;

end.


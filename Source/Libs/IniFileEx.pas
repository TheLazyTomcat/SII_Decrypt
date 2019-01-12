{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Extended INI file

    Main class

  ©František Milt 2018-10-21

  Version 1.0.3

  NOTE - library needs extensive testing

  Dependencies:
    AuxTypes            - github.com/ncs-sniper/Lib.AuxTypes
    AuxClasses          - github.com/ncs-sniper/Lib.AuxClasses
    CRC32               - github.com/ncs-sniper/Lib.CRC32
    StrRect             - github.com/ncs-sniper/Lib.StrRect
    BinTextEnc          - github.com/ncs-sniper/Lib.BinTextEnc
    FloatHex            - github.com/ncs-sniper/Lib.FloatHex
    ExplicitStringLists - github.com/ncs-sniper/Lib.ExplicitStringLists
    BinaryStreaming     - github.com/ncs-sniper/Lib.BinaryStreaming
    SimpleCompress      - github.com/ncs-sniper/Lib.SimpleCompress
    MemoryBuffer        - github.com/ncs-sniper/Lib.MemoryBuffer
    ZLib                - github.com/ncs-sniper/Bnd.ZLib
    ZLibUtils           - github.com/ncs-sniper/Lib.ZLibUtils
    AES                 - github.com/ncs-sniper/Lib.AES
  * SimpleCPUID         - github.com/ncs-sniper/Lib.SimpleCPUID
    ListSorters         - github.com/ncs-sniper/Lib.ListSorters

  SimpleCPUID is required only when PurePascal symbol is not defined.

===============================================================================}
unit IniFileEx;

{$INCLUDE '.\IniFileEx_defs.inc'}

interface

uses
  SysUtils, Classes, IniFiles,
  AuxTypes, AuxClasses,
  IniFileEx_Common, IniFileEx_Nodes, IniFileEx_Parser;

{===============================================================================
--------------------------------------------------------------------------------
                                   TIniFileEx
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TIniFileEx - class declaration
===============================================================================}
type
  TIniFileEx = class(TCustomObject)
  private
    fSettings:          TIFXSettings;
    fFileNode:          TIFXFileNode;
    fParser:            TIFXParser;
    fOnSectionCreate:   TIFXSectionNodeEvent;
    fOnSectionDestroy:  TIFXSectionNodeEvent;
    fOnKeyCreate:       TIFXKeyNodeEvent;
    fOnKeyDestroy:      TIFXKeyNodeEvent;
    Function GetSettingsPtr: PIFXSettings;
    Function GetSectionCount: Integer;
    Function GetSectionKeyCount(Index: Integer): Integer;
    Function GetKeyCount: Integer;
  {$IFDEF AllowLowLevelAccess}
    Function GetSectionNodeIdx(SectionIndex: Integer): TIFXSectionNode;
    Function GetKeyNodeIdx(SectionIndex, KeyIndex: Integer): TIFXKeyNode;
  {$ENDIF}
  protected
  {$IFNDEF AllowLowLevelAccess}
    property FileNode: TIFXFileNode read fFileNode; // required for assigning
  {$ENDIF}
    procedure Initialize; virtual;
    procedure Finalize; virtual;
    procedure SectionCreateHandler(Sender: TObject; Section: TIFXSectionNode); virtual;
    procedure SectionDestroyHandler(Sender: TObject; Section: TIFXSectionNode); virtual;
    procedure KeyCreateHandler(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode); virtual;
    procedure KeyDestroyHandler(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode); virtual;
    Function WritingValue(const Section, Key: TIFXString): TIFXKeyNode; virtual;
  public
    constructor Create; overload;
    constructor Create(Stream: TStream; ReadOnly: Boolean = False); overload;
    constructor Create(const FileName: String; ReadOnly: Boolean = False); overload;
    constructor CreateCopy(Src: TIniFileEx); overload;
    destructor Destroy; override;
    // file/stream manipulation
    procedure SaveToTextualStream(Stream: TStream); virtual;
    procedure SaveToBinaryStream(Stream: TStream); virtual;
    procedure SaveToStream(Stream: TStream); virtual;    
    procedure SaveToTextualFile(const FileName: String); virtual;
    procedure SaveToBinaryFile(const FileName: String); virtual;
    procedure SaveToFile(const FileName: String); virtual;
    procedure LoadFromTextualStream(Stream: TStream); virtual;
    procedure LoadFromBinaryStream(Stream: TStream); virtual;
    procedure LoadFromStream(Stream: TStream); virtual;
    procedure LoadFromTextualFile(const FileName: String); virtual;
    procedure LoadFromBinaryFile(const FileName: String); virtual;
    procedure LoadFromFile(const FileName: String); virtual;
    procedure AppendToTextualStream(Stream: TStream); virtual;
    procedure AppendToBinaryStream(Stream: TStream); virtual;
    procedure AppendToStream(Stream: TStream); virtual;
    procedure AppendToTextualFile(const FileName: String); virtual;
    procedure AppendToBinaryFile(const FileName: String); virtual;
    procedure AppendToFile(const FileName: String); virtual;
    procedure AppendFromTextualStream(Stream: TStream); virtual;
    procedure AppendFromBinaryStream(Stream: TStream); virtual;
    procedure AppendFromStream(Stream: TStream); virtual;
    procedure AppendFromTextualFile(const FileName: String); virtual;
    procedure AppendFromBinaryFile(const FileName: String); virtual;
    procedure AppendFromFile(const FileName: String); virtual;
    procedure Flush; virtual;
    procedure Update(Clear: Boolean = False); virtual;
    // assigning from objects
    procedure Assign(Ini: TIniFile); overload; virtual;
    procedure Assign(Ini: TIniFileEx); overload; virtual;
    procedure Append(Ini: TIniFileEx); virtual;
    // structure access
    Function IndexOfSection(const Section: TIFXString): Integer;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function IndexOfKey(const Section, Key: TIFXString): TIFXNodeIndices; overload; virtual;
    Function IndexOfKey(SectionIndex: Integer; const Key: TIFXString): Integer; overload; virtual;
    Function SectionExists(const Section: TIFXString): Boolean;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function KeyExists(const Section, Key: TIFXString): Boolean; overload; virtual;
    Function KeyExists(SectionIndex: Integer; const Key: TIFXString): Boolean; overload; virtual;
    procedure AddSection(const Section: TIFXString);{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    procedure AddKey(const Section, Key: TIFXString); overload; virtual;
    procedure AddKey(SectionIndex: Integer; const Key: TIFXString); overload; virtual;
    procedure DeleteSection(const Section: TIFXString);{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    procedure DeleteKey(const Section, Key: TIFXString); overload; virtual;
    procedure DeleteKey(SectionIndex: Integer; const Key: TIFXString); overload; virtual;
    procedure ExchangeSections(const Section1, Section2: TIFXString);{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    procedure ExchangeKeys(const Section, Key1, Key2: TIFXString); overload; virtual;
    procedure ExchangeKeys(SectionIndex: Integer; const Key1, Key2: TIFXString); overload; virtual;
    Function CopySection(const SourceSection, DestinationSection: TIFXString): Boolean;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function CopyKey(const SourceSection, DestinationSection, SourceKey, DestinationKey: TIFXString): Boolean;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    procedure Clear; virtual;
    procedure SortSections; virtual;
    procedure SortSection(const Section: TIFXString);{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    procedure SortKeys(const Section: TIFXString); overload; virtual;
    procedure SortKeys; overload; virtual;
    procedure Sort; virtual;
    // comments access
    Function GetFileComment: TIFXString; virtual;
    Function GetFileCommentStr: String; virtual;
    Function GetSectionComment(const Section: TIFXString): TIFXString;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function GetSectionInlineComment(const Section: TIFXString): TIFXString;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function GetKeyComment(const Section, Key: TIFXString): TIFXString;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function GetKeyInlineComment(const Section, Key: TIFXString): TIFXString;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    procedure SetFileComment(const Text: TIFXString);{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    procedure SetSectionComment(const Section: TIFXString; const Text: TIFXString);{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    procedure SetSectionInlineComment(const Section: TIFXString; const Text: TIFXString);{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    procedure SetKeyComment(const Section, Key: TIFXString; const Text: TIFXString);{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    procedure SetKeyInlineComment(const Section, Key: TIFXString; const Text: TIFXString);{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    procedure RemoveFileComment; virtual;
    procedure RemoveSectionComment(const Section: TIFXString; RemoveKeysComments: Boolean = False);{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    procedure RemoveKeyComment(const Section, Key: TIFXString);{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    procedure RemoveAllComment; virtual;
    // mid-level properties access
    Function GetValueState(const Section, Key: TIFXString): TIFXValueState;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function GetValueEncoding(const Section, Key: TIFXString): TIFXValueEncoding;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    procedure SetValueEncoding(const Section, Key: TIFXString; Encoding: TIFXValueEncoding);{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function GetValueType(const Section, Key: TIFXString): TIFXValueType;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    procedure ReadSections(Strings: TStrings); virtual;
    procedure ReadSection(const Section: TIFXString; Strings: TStrings);{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    procedure ReadSectionValues(const Section: TIFXString; Strings: TStrings);{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    // values writing
    procedure WriteBool(const Section, Key: TIFXString; Value: Boolean); overload; virtual;
    procedure WriteBool(const Section, Key: TIFXString; Value: Boolean; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteInt8(const Section, Key: TIFXString; Value: Int8); overload; virtual;
    procedure WriteInt8(const Section, Key: TIFXString; Value: Int8; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteUInt8(const Section, Key: TIFXString; Value: UInt8); overload; virtual;
    procedure WriteUInt8(const Section, Key: TIFXString; Value: UInt8; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteInt16(const Section, Key: TIFXString; Value: Int16); overload; virtual;
    procedure WriteInt16(const Section, Key: TIFXString; Value: Int16; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteUInt16(const Section, Key: TIFXString; Value: UInt16); overload; virtual;
    procedure WriteUInt16(const Section, Key: TIFXString; Value: UInt16; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteInt32(const Section, Key: TIFXString; Value: Int32); overload; virtual;
    procedure WriteInt32(const Section, Key: TIFXString; Value: Int32; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteUInt32(const Section, Key: TIFXString; Value: UInt32); overload; virtual;
    procedure WriteUInt32(const Section, Key: TIFXString; Value: UInt32; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteInt64(const Section, Key: TIFXString; Value: Int64); overload; virtual;
    procedure WriteInt64(const Section, Key: TIFXString; Value: Int64; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteUInt64(const Section, Key: TIFXString; Value: UInt64); overload; virtual;
    procedure WriteUInt64(const Section, Key: TIFXString; Value: UInt64; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteInteger(const Section, Key: TIFXString; Value: Integer); overload; virtual;
    procedure WriteInteger(const Section, Key: TIFXString; Value: Integer; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteFloat32(const Section, Key: TIFXString; Value: Float32); overload; virtual;
    procedure WriteFloat32(const Section, Key: TIFXString; Value: Float32; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteFloat64(const Section, Key: TIFXString; Value: Float64); overload; virtual;
    procedure WriteFloat64(const Section, Key: TIFXString; Value: Float64; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteFloat(const Section, Key: TIFXString; Value: Double); overload; virtual;
    procedure WriteFloat(const Section, Key: TIFXString; Value: Double; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteTime(const Section, Key: TIFXString; Value: TDateTime); overload; virtual;
    procedure WriteTime(const Section, Key: TIFXString; Value: TDateTime; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteDate(const Section, Key: TIFXString; Value: TDateTime); overload; virtual;
    procedure WriteDate(const Section, Key: TIFXString; Value: TDateTime; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteDateTime(const Section, Key: TIFXString; Value: TDateTime); overload; virtual;
    procedure WriteDateTime(const Section, Key: TIFXString; Value: TDateTime; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteString(const Section, Key: TIFXString; const Value: String); overload; virtual;
    procedure WriteString(const Section, Key: TIFXString; const Value: String; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteBinaryBuffer(const Section, Key: TIFXString; const Buffer; Size: TMemSize; MakeCopy: Boolean = False); overload; virtual;
    procedure WriteBinaryBuffer(const Section, Key: TIFXString; const Buffer; Size: TMemSize; Encoding: TIFXValueEncoding; MakeCopy: Boolean = False); overload; virtual;
    procedure WriteBinaryMemory(const Section, Key: TIFXString; Value: Pointer; Size: TMemSize; MakeCopy: Boolean = False); overload; virtual;
    procedure WriteBinaryMemory(const Section, Key: TIFXString; Value: Pointer; Size: TMemSize; Encoding: TIFXValueEncoding; MakeCopy: Boolean = False); overload; virtual;
    procedure WriteBinaryStream(const Section, Key: TIFXString; Stream: TStream; Position, Count: Int64); overload; virtual;
    procedure WriteBinaryStream(const Section, Key: TIFXString; Stream: TStream; Position, Count: Int64; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteBinaryStream(const Section, Key: TIFXString; Stream: TStream); overload; virtual;
    procedure WriteBinaryStream(const Section, Key: TIFXString; Stream: TStream; Encoding: TIFXValueEncoding); overload; virtual;
    // values reading
    procedure PrepareReading(const Section, Key: TIFXString; ValueType: TIFXValueType);{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadBool(const Section, Key: TIFXString; Default: Boolean = False): Boolean;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadInt8(const Section, Key: TIFXString; Default: Int8 = 0): Int8;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadUInt8(const Section, Key: TIFXString; Default: UInt8 = 0): UInt8;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadInt16(const Section, Key: TIFXString; Default: Int16 = 0): Int16;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadUInt16(const Section, Key: TIFXString; Default: UInt16 = 0): UInt16;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadInt32(const Section, Key: TIFXString; Default: Int32 = 0): Int32;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadUInt32(const Section, Key: TIFXString; Default: UInt32 = 0): UInt32;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadInt64(const Section, Key: TIFXString; Default: Int64 = 0): Int64;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadUInt64(const Section, Key: TIFXString; Default: UInt64 = 0): UInt64;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadInteger(const Section, Key: TIFXString; Default: Integer = 0): Integer;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadFloat32(const Section, Key: TIFXString; Default: Float32 = 0.0): Float32;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadFloat64(const Section, Key: TIFXString; Default: Float64 = 0.0): Float64;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadFloat(const Section, Key: TIFXString; Default: Double = 0.0): Double;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadTime(const Section, Key: TIFXString; Default: TDateTime = 0.0): TDateTime;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadDate(const Section, Key: TIFXString; Default: TDateTime = 0.0): TDateTime;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadDateTime(const Section, Key: TIFXString; Default: TDateTime = 0.0): TDateTime;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadString(const Section, Key: TIFXString; Default: String = ''): String;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadBinarySize(const Section, Key: TIFXString): TMemSize;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadBinaryBuffer(const Section, Key: TIFXString; var Buffer; Size: TMemSize): TMemSize;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
    Function ReadBinaryMemory(const Section, Key: TIFXString; out Ptr: Pointer; MakeCopy: Boolean = False): TMemSize; overload; virtual;
    Function ReadBinaryMemory(const Section, Key: TIFXString; Ptr: Pointer; Size: TMemSize): TMemSize; overload; virtual;
    Function ReadBinaryStream(const Section, Key: TIFXString; Stream: TStream; ClearStream: Boolean = False): Int64;{$IFDEF DefStrOverloads} overload;{$ENDIF} virtual;
  {$IFDEF DefStrOverloads}
    // default string overloads
    // structure access
    Function IndexOfSection(const Section: String): Integer; overload; virtual;
    Function IndexOfKey(const Section, Key: String): TIFXNodeIndices; overload; virtual;
    Function IndexOfKey(SectionIndex: Integer; const Key: String): Integer; overload; virtual;
    Function SectionExists(const Section: String): Boolean; overload; virtual;
    Function KeyExists(const Section, Key: String): Boolean; overload; virtual;
    Function KeyExists(SectionIndex: Integer; const Key: String): Boolean; overload; virtual;
    procedure AddSection(const Section: String); overload; virtual;
    procedure AddKey(const Section, Key: String); overload; virtual;
    procedure AddKey(SectionIndex: Integer; const Key: String); overload; virtual;
    procedure DeleteSection(const Section: String); overload; virtual;
    procedure DeleteKey(const Section, Key: String); overload; virtual;
    procedure DeleteKey(SectionIndex: Integer; const Key: String); overload; virtual;
    procedure ExchangeSections(const Section1, Section2: String); overload; virtual;
    procedure ExchangeKeys(const Section, Key1, Key2: String); overload; virtual;
    procedure ExchangeKeys(SectionIndex: Integer; const Key1, Key2: String); overload; virtual;
    Function CopySection(const SourceSection, DestinationSection: String): Boolean; overload; virtual;
    Function CopyKey(const SourceSection, DestinationSection, SourceKey, DestinationKey: String): Boolean; overload; virtual;
    procedure SortSection(const Section: String); overload; virtual;
    procedure SortKeys(const Section: String); overload; virtual;
    // comments access
    Function GetSectionComment(const Section: String): String; overload; virtual;
    Function GetSectionInlineComment(const Section: String): String; overload; virtual;
    Function GetKeyComment(const Section, Key: String): String; overload; virtual;
    Function GetKeyInlineComment(const Section, Key: String): String; overload; virtual;
    procedure SetFileComment(const Text: String); overload; virtual;
    procedure SetSectionComment(const Section: String; const Text: String); overload; virtual;
    procedure SetSectionInlineComment(const Section: String; const Text: String); overload; virtual;
    procedure SetKeyComment(const Section, Key: String; const Text: String); overload; virtual;
    procedure SetKeyInlineComment(const Section, Key: String; const Text: String); overload; virtual;
    procedure RemoveSectionComment(const Section: String; RemoveKeysComments: Boolean = False); overload; virtual;
    procedure RemoveKeyComment(const Section, Key: String); overload; virtual;
    // mid-level properties access
    Function GetValueState(const Section, Key: String): TIFXValueState; overload; virtual;
    Function GetValueEncoding(const Section, Key: String): TIFXValueEncoding; overload; virtual;
    procedure SetValueEncoding(const Section, Key: String; Encoding: TIFXValueEncoding); overload; virtual;
    Function GetValueType(const Section, Key: String): TIFXValueType; overload; virtual;
    procedure ReadSection(const Section: String; Strings: TStrings); overload; virtual;
    procedure ReadSectionValues(const Section: String; Strings: TStrings); overload; virtual;
    // values writing
    procedure WriteBool(const Section, Key: String; Value: Boolean); overload; virtual;
    procedure WriteBool(const Section, Key: String; Value: Boolean; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteInt8(const Section, Key: String; Value: Int8); overload; virtual;
    procedure WriteInt8(const Section, Key: String; Value: Int8; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteUInt8(const Section, Key: String; Value: UInt8); overload; virtual;
    procedure WriteUInt8(const Section, Key: String; Value: UInt8; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteInt16(const Section, Key: String; Value: Int16); overload; virtual;
    procedure WriteInt16(const Section, Key: String; Value: Int16; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteUInt16(const Section, Key: String; Value: UInt16); overload; virtual;
    procedure WriteUInt16(const Section, Key: String; Value: UInt16; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteInt32(const Section, Key: String; Value: Int32); overload; virtual;
    procedure WriteInt32(const Section, Key: String; Value: Int32; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteUInt32(const Section, Key: String; Value: UInt32); overload; virtual;
    procedure WriteUInt32(const Section, Key: String; Value: UInt32; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteInt64(const Section, Key: String; Value: Int64); overload; virtual;
    procedure WriteInt64(const Section, Key: String; Value: Int64; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteUInt64(const Section, Key: String; Value: UInt64); overload; virtual;
    procedure WriteUInt64(const Section, Key: String; Value: UInt64; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteInteger(const Section, Key: String; Value: Integer); overload; virtual;
    procedure WriteInteger(const Section, Key: String; Value: Integer; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteFloat32(const Section, Key: String; Value: Float32); overload; virtual;
    procedure WriteFloat32(const Section, Key: String; Value: Float32; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteFloat64(const Section, Key: String; Value: Float64); overload; virtual;
    procedure WriteFloat64(const Section, Key: String; Value: Float64; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteFloat(const Section, Key: String; Value: Double); overload; virtual;
    procedure WriteFloat(const Section, Key: String; Value: Double; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteTime(const Section, Key: String; Value: TDateTime); overload; virtual;
    procedure WriteTime(const Section, Key: String; Value: TDateTime; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteDate(const Section, Key: String; Value: TDateTime); overload; virtual;
    procedure WriteDate(const Section, Key: String; Value: TDateTime; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteDateTime(const Section, Key: String; Value: TDateTime); overload; virtual;
    procedure WriteDateTime(const Section, Key: String; Value: TDateTime; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteString(const Section, Key: String; const Value: String); overload; virtual;
    procedure WriteString(const Section, Key: String; const Value: String; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteBinaryBuffer(const Section, Key: String; const Buffer; Size: TMemSize; MakeCopy: Boolean = False); overload; virtual;
    procedure WriteBinaryBuffer(const Section, Key: String; const Buffer; Size: TMemSize; Encoding: TIFXValueEncoding; MakeCopy: Boolean = False); overload; virtual;
    procedure WriteBinaryMemory(const Section, Key: String; Value: Pointer; Size: TMemSize; MakeCopy: Boolean = False); overload; virtual;
    procedure WriteBinaryMemory(const Section, Key: String; Value: Pointer; Size: TMemSize; Encoding: TIFXValueEncoding; MakeCopy: Boolean = False); overload; virtual;
    procedure WriteBinaryStream(const Section, Key: String; Stream: TStream; Position, Count: Int64); overload; virtual;
    procedure WriteBinaryStream(const Section, Key: String; Stream: TStream; Position, Count: Int64; Encoding: TIFXValueEncoding); overload; virtual;
    procedure WriteBinaryStream(const Section, Key: String; Stream: TStream); overload; virtual;
    procedure WriteBinaryStream(const Section, Key: String; Stream: TStream; Encoding: TIFXValueEncoding); overload; virtual;
    // values reading
    procedure PrepareReading(const Section, Key: String; ValueType: TIFXValueType); overload; virtual;
    Function ReadBool(const Section, Key: String; Default: Boolean = False): Boolean; overload; virtual;
    Function ReadInt8(const Section, Key: String; Default: Int8 = 0): Int8; overload; virtual;
    Function ReadUInt8(const Section, Key: String; Default: UInt8 = 0): UInt8; overload; virtual;
    Function ReadInt16(const Section, Key: String; Default: Int16 = 0): Int16; overload; virtual;
    Function ReadUInt16(const Section, Key: String; Default: UInt16 = 0): UInt16; overload; virtual;
    Function ReadInt32(const Section, Key: String; Default: Int32 = 0): Int32; overload; virtual;
    Function ReadUInt32(const Section, Key: String; Default: UInt32 = 0): UInt32; overload; virtual;
    Function ReadInt64(const Section, Key: String; Default: Int64 = 0): Int64; overload; virtual;
    Function ReadUInt64(const Section, Key: String; Default: UInt64 = 0): UInt64; overload; virtual;
    Function ReadInteger(const Section, Key: String; Default: Integer = 0): Integer; overload; virtual;
    Function ReadFloat32(const Section, Key: String; Default: Float32 = 0.0): Float32; overload; virtual;
    Function ReadFloat64(const Section, Key: String; Default: Float64 = 0.0): Float64; overload; virtual;
    Function ReadFloat(const Section, Key: String; Default: Double = 0.0): Double; overload; virtual;
    Function ReadTime(const Section, Key: String; Default: TDateTime = 0.0): TDateTime; overload; virtual;
    Function ReadDate(const Section, Key: String; Default: TDateTime = 0.0): TDateTime; overload; virtual;
    Function ReadDateTime(const Section, Key: String; Default: TDateTime = 0.0): TDateTime; overload; virtual;
    Function ReadString(const Section, Key: String; Default: String = ''): String; overload; virtual;
    Function ReadBinarySize(const Section, Key: String): TMemSize; overload; virtual;
    Function ReadBinaryBuffer(const Section, Key: String; var Buffer; Size: TMemSize): TMemSize; overload; virtual;
    Function ReadBinaryMemory(const Section, Key: String; out Ptr: Pointer; MakeCopy: Boolean = False): TMemSize; overload; virtual;
    Function ReadBinaryMemory(const Section, Key: String; Ptr: Pointer; Size: TMemSize): TMemSize; overload; virtual;
    Function ReadBinaryStream(const Section, Key: String; Stream: TStream; ClearStream: Boolean = False): Int64; overload; virtual;
  {$ENDIF}
  {$IFDEF AllowLowLevelAccess}
    // low level stuff
    Function GetSectionNode(const Section: TIFXString): TIFXSectionNode; virtual;
    Function GetKeyNode(const Section, Key: TIFXString): TIFXKeyNode; virtual;
    Function GetValueString(const Section, Key: TIFXString): TIFXString; virtual;
    procedure SetValueString(const Section, Key, ValueStr: TIFXString); virtual;
    property FileNode: TIFXFileNode read fFileNode;
    property Parser: TIFXParser read fParser; 
    property SectionNodes[SectionIndex: Integer]: TIFXSectionNode read GetSectionNodeIdx;
    property KeyNodes[SectionIndex, KeyIndex: Integer]: TIFXKeyNode read GetKeyNodeIdx; default;
    property OnSectionCreate: TIFXSectionNodeEvent read fOnSectionCreate write fOnSectionCreate;
    property OnSectionDestroy: TIFXSectionNodeEvent read fOnSectionDestroy write fOnSectionDestroy;
    property OnKeyCreate: TIFXKeyNodeEvent read fOnKeyCreate write fOnKeyCreate;
    property OnKeyDestroy: TIFXKeyNodeEvent read fOnKeyDestroy write fOnKeyDestroy;
  {$ENDIF}
    property Settings: TIFXSettings read fSettings write fSettings;
    property SettingsPtr: PIFXSettings read GetSettingsPtr;
    // individual settings options
    property FormatSettings: TFormatSettings read fSettings.FormatSettings write fSettings.FormatSettings;
    property TextIniSettings: TIFXTextIniSettings read fSettings.TextIniSettings write fSettings.TextIniSettings;
    property BinaryIniSettings: TIFXBinaryIniSettings read fSettings.BinaryIniSettings write fSettings.BinaryIniSettings;
    property FullNameEval: Boolean read fSettings.FullNameEval write fSettings.FullNameEval;
    property ReadOnly: Boolean read fSettings.ReadOnly write fSettings.ReadOnly;
    property DuplicityBehavior: TIFXDuplicityBehavior read fSettings.DuplicityBehavior write fSettings.DuplicityBehavior;
    property DuplicityRenameOldStr: TIFXString read fSettings.DuplicityRenameOldStr write fSettings.DuplicityRenameOldStr;
    property DuplicityRenameNewStr: TIFXString read fSettings.DuplicityRenameNewStr write fSettings.DuplicityRenameNewStr;
    property WorkingStyle: TIFXWorkingStyle read fSettings.WorkingStyle;
    property WorkingStream: TStream read fSettings.WorkingStream;
    property WorkingFile: String read fSettings.WorkingFile;
    // individual Settings.TextIniSettings options
    property EscapeChar: TIFXChar read fSettings.TextIniSettings.EscapeChar write fSettings.TextIniSettings.EscapeChar;
    property QuoteChar: TIFXChar read fSettings.TextIniSettings.QuoteChar write fSettings.TextIniSettings.QuoteChar;
    property NumericChar: TIFXChar read fSettings.TextIniSettings.NumericChar write fSettings.TextIniSettings.NumericChar;
    property ForceQuote: Boolean read fSettings.TextIniSettings.ForceQuote write fSettings.TextIniSettings.ForceQuote;
    property CommentChar: TIFXChar read fSettings.TextIniSettings.CommentChar write fSettings.TextIniSettings.CommentChar;
    property SectionStartChar: TIFXChar read fSettings.TextIniSettings.SectionStartChar write fSettings.TextIniSettings.SectionStartChar;
    property SectionEndChar: TIFXChar read fSettings.TextIniSettings.SectionEndChar write fSettings.TextIniSettings.SectionEndChar;
    property ValueDelimChar: TIFXChar read fSettings.TextIniSettings.ValueDelimChar write fSettings.TextIniSettings.ValueDelimChar;
    property WhiteSpaceChar: TIFXChar read fSettings.TextIniSettings.WhiteSpaceChar write fSettings.TextIniSettings.WhiteSpaceChar;
    property KeyWhiteSpace: Boolean read fSettings.TextIniSettings.KeyWhiteSpace write fSettings.TextIniSettings.KeyWhiteSpace;
    property ValueWhiteSpace: Boolean read fSettings.TextIniSettings.ValueWhiteSpace write fSettings.TextIniSettings.ValueWhiteSpace;
    property ValueWrapLength: Integer read fSettings.TextIniSettings.ValueWrapLength write fSettings.TextIniSettings.ValueWrapLength;
    property LineBreak: TIFXString read fSettings.TextIniSettings.LineBreak write fSettings.TextIniSettings.LineBreak;
    property WriteByteOrderMask: Boolean read fSettings.TextIniSettings.WriteByteOrderMask write fSettings.TextIniSettings.WriteByteOrderMask;
    // individual Settings.BinaryIniSettings
    property CompressData: Boolean read fSettings.BinaryIniSettings.CompressData write fSettings.BinaryIniSettings.CompressData;
    property DataEncryption: TIFXDataEncryption read fSettings.BinaryIniSettings.DataEncryption write fSettings.BinaryIniSettings.DataEncryption;
    property AESEncryptionKey: TIFXAESEncVector read fSettings.BinaryIniSettings.AESEncryptionKey write fSettings.BinaryIniSettings.AESEncryptionKey;
    property AESEncryptionVector: TIFXAESEncVector read fSettings.BinaryIniSettings.AESEncryptionVector write fSettings.BinaryIniSettings.AESEncryptionVector;
    property SectionCount: Integer read GetSectionCount;
    property SectionKeyCount[Index: Integer]: Integer read GetSectionKeyCount;
    property KeyCount: Integer read GetKeyCount;
  end;

implementation

uses
  StrRect,
  IniFileEx_Utils;

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
{$ENDIF}

{===============================================================================
--------------------------------------------------------------------------------
                                   TIniFileEx
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TIniFileEx - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TIniFileEx - private methods
-------------------------------------------------------------------------------}

Function TIniFileEx.GetSettingsPtr: PIFXSettings;
begin
Result := Addr(fSettings);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetSectionCount: Integer;
begin
Result := fFileNode.SectionCount;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetSectionKeyCount(Index: Integer): Integer;
begin
If fFileNode.CheckIndex(Index) then
  Result := fFileNode[Index].KeyCount
else
  raise Exception.CreateFmt('TIniFileEx.GetSectionKeyCount: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetKeyCount: Integer;
var
  i:  Integer;
begin
Result := 0;
For i := fFileNode.LowIndex to fFileNode.HighIndex do
  Inc(Result,fFileNode[i].KeyCount);
end;

{$IFDEF AllowLowLevelAccess}
//------------------------------------------------------------------------------

Function TIniFileEx.GetSectionNodeIdx(SectionIndex: Integer): TIFXSectionNode;
begin
If fFileNode.CheckIndex(SectionIndex) then
  Result := fFileNode[SectionIndex]
else
  raise Exception.CreateFmt('TIniFileEx.GetSectionNodeIdx: Section index (%d) out of bounds.',[SectionIndex]);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetKeyNodeIdx(SectionIndex, KeyIndex: Integer): TIFXKeyNode;
begin
If fFileNode.CheckIndex(SectionIndex) then
  begin
    If fFileNode[SectionIndex].CheckIndex(KeyIndex) then
      Result := fFileNode[SectionIndex][KeyIndex]
    else
      raise Exception.CreateFmt('TIniFileEx.GetSectionNodeIdx: Key index (%d) out of bounds.',[KeyIndex]);
  end
else raise Exception.CreateFmt('TIniFileEx.GetSectionNodeIdx: Section index (%d) out of bounds.',[SectionIndex]);
end;

{$ENDIF}

{-------------------------------------------------------------------------------
    TIniFileEx - protected methods
-------------------------------------------------------------------------------}

procedure TIniFileEx.Initialize;
begin
IFXInitSettings(fSettings);
fFileNode := TIFXFileNode.Create(Addr(fSettings));
fFileNode.OnSectionCreate := SectionCreateHandler;
fFileNode.OnSectionDestroy := SectionDestroyHandler;
fFileNode.OnKeyCreate := KeyCreateHandler;
fFileNode.OnKeyDestroy := KeyDestroyHandler;
fParser := TIFXParser.Create(@fSettings,fFileNode);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.Finalize;
begin
fParser.Free;
fFileNode.Free;
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TIniFileEx.SectionCreateHandler(Sender: TObject; Section: TIFXSectionNode);
begin
If Assigned(fOnSectionCreate) then
  fOnSectionCreate(Self,Section);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TIniFileEx.SectionDestroyHandler(Sender: TObject; Section: TIFXSectionNode);
begin
If Assigned(fOnSectionDestroy) then
  fOnSectionDestroy(Self,Section);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TIniFileEx.KeyCreateHandler(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode);
begin
If Assigned(fOnKeyCreate) then
  fOnKeyCreate(Self,Section,Key);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TIniFileEx.KeyDestroyHandler(Sender: TObject; Section: TIFXSectionNode; Key: TIFXKeyNode);
begin
If Assigned(fOnKeyDestroy) then
  fOnKeyDestroy(Self,Section,Key);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

Function TIniFileEx.WritingValue(const Section, Key: TIFXString): TIFXKeyNode;
var
  SectionIndex: Integer;
  KeyIndex:     Integer;
begin
SectionIndex := fFileNode.AddSection(Section);
KeyIndex := fFileNode[SectionIndex].AddKey(Key);
Result := fFileNode[SectionIndex][KeyIndex];
end;

{-------------------------------------------------------------------------------
    TIniFileEx - public methods
-------------------------------------------------------------------------------}

constructor TIniFileEx.Create;
begin
inherited Create;
Initialize;
fSettings.WorkingStyle := iwsStandalone;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TIniFileEx.Create(Stream: TStream; ReadOnly: Boolean = False);
begin
inherited Create;
Initialize;
fSettings.ReadOnly := ReadOnly;
fSettings.WorkingStyle := iwsOnStream;
fSettings.WorkingStream := Stream;
LoadFromStream(Stream);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor TIniFileEx.Create(const FileName: String; ReadOnly: Boolean = False);
begin
inherited Create;
Initialize;
fSettings.ReadOnly := ReadOnly;
fSettings.WorkingStyle := iwsOnFile;
fSettings.WorkingFile := FileName;
If FileExists(StrToRTL(FileName)) then
  LoadFromFile(FileName);
end;

//------------------------------------------------------------------------------

constructor TIniFileEx.CreateCopy(Src: TIniFileEx);
var
  i:  Integer;
begin
inherited Create;
fSettings := Src.Settings;
// thread safety...
with fSettings.FormatSettings do
  begin
    UniqueString(CurrencyString);
    UniqueString(ShortDateFormat);
    UniqueString(LongDateFormat);
    UniqueString(TimeAMString);
    UniqueString(TimePMString);
    UniqueString(ShortTimeFormat);
    UniqueString(LongTimeFormat);
    For i := Low(ShortMonthNames) to High(ShortMonthNames) do
      UniqueString(ShortMonthNames[i]);
    For i := Low(LongMonthNames) to High(LongMonthNames) do
      UniqueString(LongMonthNames[i]);
    For i := Low(ShortDayNames) to High(ShortDayNames) do
      UniqueString(ShortDayNames[i]);
    For i := Low(LongDayNames) to High(LongDayNames) do
      UniqueString(LongDayNames[i]);
  end;
UniqueString(fSettings.TextIniSettings.LineBreak);
UniqueString(fSettings.DuplicityRenameOldStr);
UniqueString(fSettings.DuplicityRenameNewStr);
UniqueString(fSettings.WorkingFile);
fFileNode := TIFXFileNode.CreateCopy(Src.FileNode,SectionCreateHandler,KeyCreateHandler);
fFileNode.OnSectionCreate := SectionCreateHandler;
fFileNode.OnSectionDestroy := SectionDestroyHandler;
fFileNode.OnKeyCreate := KeyCreateHandler;
fFileNode.OnKeyDestroy := KeyDestroyHandler;
fParser := TIFXParser.Create(Addr(fSettings),fFileNode);
end;

//------------------------------------------------------------------------------

destructor TIniFileEx.Destroy;
begin
If not fSettings.ReadOnly then
  Flush;
Finalize;
inherited;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SaveToTextualStream(Stream: TStream);
begin
If not fSettings.ReadOnly then
  fParser.WriteTextual(Stream);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SaveToBinaryStream(Stream: TStream);
begin
If not fSettings.ReadOnly then
  fParser.WriteBinary(Stream);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SaveToStream(Stream: TStream);
begin
If not fSettings.ReadOnly then
  SaveToTextualStream(Stream);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SaveToTextualFile(const FileName: String);
var
  FileStream: TFileStream;
begin
If not fSettings.ReadOnly then
  begin
    FileStream := TFileStream.Create(StrToRTL(FileName),fmCreate or fmShareDenyWrite);
    try
      SaveToTextualStream(FileStream);
      FileStream.Size := FileStream.Position;
    finally
      FileStream.Free;
    end;
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SaveToBinaryFile(const FileName: String);
var
  FileStream: TFileStream;
begin
If not fSettings.ReadOnly then
  begin
    FileStream := TFileStream.Create(StrToRTL(FileName),fmCreate or fmShareDenyWrite);
    try
      SaveToBinaryStream(FileStream);
      FileStream.Size := FileStream.Position;
    finally
      FileStream.Free;
    end;
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SaveToFile(const FileName: String);
begin
If not fSettings.ReadOnly then
  SaveToTextualFile(FileName);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.LoadFromTextualStream(Stream: TStream);
begin
fFileNode.ClearSections;
fFileNode.Comment := '';
fParser.ReadTextual(Stream);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.LoadFromBinaryStream(Stream: TStream);
begin
fFileNode.ClearSections;
fFileNode.Comment := '';
fParser.ReadBinary(Stream);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.LoadFromStream(Stream: TStream);
begin
If fParser.IsBinaryIniStream(Stream) then
  LoadFromBinaryStream(Stream)
else
  LoadFromTextualStream(Stream);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.LoadFromTextualFile(const FileName: String);
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
try
  LoadFromTextualStream(FileStream);
finally
  FileStream.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.LoadFromBinaryFile(const FileName: String);
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
try
  LoadFromBinaryStream(FileStream);
finally
  FileStream.Free;
end;
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.LoadFromFile(const FileName: String);
begin
If fParser.IsBinaryIniFile(FileName) then
  LoadFromBinaryFile(FileName)
else
  LoadFromTextualFile(FileName);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.AppendToTextualStream(Stream: TStream);
var
  ExtIniFile: TIniFileEx;
  StreamPos:  Int64;
begin
If not fSettings.ReadOnly then
  begin
    ExtIniFile := TIniFileEx.Create;
    try
      ExtIniFile.Settings := fSettings;
      ExtIniFile.ReadOnly := False;
      ExtIniFile.SettingsPtr^.WorkingStyle := iwsStandalone;
      StreamPos := Stream.Position;
      try
        ExtIniFile.LoadFromTextualStream(Stream);
        ExtIniFile.Append(Self);
      finally
        Stream.Position := StreamPos;
      end;
      ExtIniFile.SaveToTextualStream(Stream);
      Stream.Size := Stream.Position;
    finally
      ExtIniFile.Free;
    end;
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.AppendToBinaryStream(Stream: TStream);
var
  ExtIniFile: TIniFileEx;
  StreamPos:  Int64;
begin
If not fSettings.ReadOnly then
  begin
    ExtIniFile := TIniFileEx.Create;
    try
      ExtIniFile.Settings := fSettings;
      ExtIniFile.ReadOnly := False;
      ExtIniFile.SettingsPtr^.WorkingStyle := iwsStandalone;
      StreamPos := Stream.Position;
      try
        ExtIniFile.LoadFromBinaryStream(Stream);
        ExtIniFile.Append(Self);
      finally
        Stream.Position := StreamPos;
      end;
      ExtIniFile.SaveToBinaryStream(Stream);
      Stream.Size := Stream.Position;
    finally
      ExtIniFile.Free;
    end;
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.AppendToStream(Stream: TStream);
begin
If not fSettings.ReadOnly then
  begin
    If fParser.IsBinaryIniStream(Stream) then
      AppendToBinaryStream(Stream)
    else
      AppendToTextualStream(Stream);
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.AppendToTextualFile(const FileName: String);
var
  FileStream: TFileStream;
begin
If not fSettings.ReadOnly then
  begin
    FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenReadWrite or fmShareDenyWrite);
    try
      AppendToTextualStream(FileStream);
    finally
      FileStream.Free;
    end;
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.AppendToBinaryFile(const FileName: String);
var
  FileStream: TFileStream;
begin
If not fSettings.ReadOnly then
  begin
    FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenReadWrite or fmShareDenyWrite);
    try
      AppendToBinaryStream(FileStream);
    finally
      FileStream.Free;
    end;
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.AppendToFile(const FileName: String);
begin
If not fSettings.ReadOnly then
  begin
    If fParser.IsBinaryIniFile(FileName) then
      AppendToBinaryFile(FileName)
    else
      AppendToTextualFile(FileName);
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.AppendFromTextualStream(Stream: TStream);
begin
fParser.ReadTextual(Stream);
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.AppendFromBinaryStream(Stream: TStream);
begin
fParser.ReadBinary(Stream);
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.AppendFromStream(Stream: TStream);
begin
If fParser.IsBinaryIniStream(Stream) then
  AppendFromBinaryStream(Stream)
else
  AppendFromTextualStream(Stream);
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.AppendFromTextualFile(const FileName: String);
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
try
  AppendFromTextualStream(FileStream);
finally
  FileStream.Free;
end;
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.AppendFromBinaryFile(const FileName: String);
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
try
  AppendFromBinaryStream(FileStream);
finally
  FileStream.Free;
end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.AppendFromFile(const FileName: String);
begin
If fParser.IsBinaryIniFile(FileName) then
  AppendFromBinaryFile(FileName)
else
  AppendFromTextualFile(FileName);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.Flush;
var
  OldDupBehavior: TIFXDuplicityBehavior;
begin
If (fSettings.WorkingStyle <> iwsStandalone) and not fSettings.ReadOnly then
  begin
    OldDupBehavior := fSettings.DuplicityBehavior;
    try
      fSettings.DuplicityBehavior := idbReplace;
      case fSettings.WorkingStyle of
        iwsOnStream:  AppendToStream(fSettings.WorkingStream);
        iwsOnFile:    If FileExists(StrToRTL(fSettings.WorkingFile)) then
                        AppendToFile(fSettings.WorkingFile)
                      else
                        If fFileNode.Count > 0 then
                          SaveToFile(fSettings.WorkingFile);
      end;
    finally
      fSettings.DuplicityBehavior := OldDupBehavior;
    end;
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.Update(Clear: Boolean = False);
var
  OldDupBehavior: TIFXDuplicityBehavior;
begin
If fSettings.WorkingStyle <> iwsStandalone then
  begin
    OldDupBehavior := fSettings.DuplicityBehavior;
    try
      fSettings.DuplicityBehavior := idbReplace;
      If Clear then
        case fSettings.WorkingStyle of
          iwsOnStream:  LoadFromStream(fSettings.WorkingStream);
          iwsOnFile:    If FileExists(StrToRTL(fSettings.WorkingFile)) then
                          LoadFromFile(fSettings.WorkingFile);
        end
      else
        case fSettings.WorkingStyle of
          iwsOnStream:  AppendFromStream(fSettings.WorkingStream);
          iwsOnFile:    If FileExists(StrToRTL(fSettings.WorkingFile)) then
                          AppendFromFile(fSettings.WorkingFile);
        end;
    finally
      fSettings.DuplicityBehavior := OldDupBehavior;
    end;
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.Assign(Ini: TIniFile);
var
  Sections: TStringList;
  Keys:     TStringList;
  i,j:      Integer;
begin
If not fSettings.ReadOnly then
  begin
    Sections := TStringList.Create;
    try
      Keys := TStringList.Create;
      try
        Clear;      
        Ini.ReadSections(Sections);
        For i := 0 to Pred(Sections.Count) do
          begin
            Keys.Clear;
            AddSection(Sections[i]);
            Ini.ReadSection(Sections[i],Keys);
            For j := 0 to Pred(Keys.Count) do
              WriteString(Sections[i],Keys[j],Ini.ReadString(Sections[i],Keys[j],''));
          end;
      finally
        Keys.Free;
      end;
    finally
      Sections.Free;
    end;
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.Assign(Ini: TIniFileEx);
begin
If not fSettings.ReadOnly then
  begin
    FreeAndNil(fParser);
    FreeAndNil(fFileNode);
    // create new objects
    fSettings := Ini.Settings;
    fFileNode := TIFXFileNode.CreateCopy(Ini.FileNode,SectionCreateHandler,KeyCreateHandler);
    fFileNode.SettingsPtr := Addr(fSettings);
    fFileNode.OnSectionCreate := SectionCreateHandler;
    fFileNode.OnSectionDestroy := SectionDestroyHandler;
    fFileNode.OnKeyCreate := KeyCreateHandler;
    fFileNode.OnKeyDestroy := KeyDestroyHandler;
    fParser := TIFXParser.Create(@fSettings,fFileNode);
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.Append(Ini: TIniFileEx);
var
  i,j:          Integer;
  SIdx,KIdx:    Integer;
  ExtFileNode:  TIFXFileNode;
  NewSectNode:  TIFXSectionNode;
  NewKeyNode:   TIFXKeyNode;
  Counter:      Integer;
begin
If not fSettings.ReadOnly and (Ini.SectionCount > 0) then
  begin
    ExtFileNode := Ini.FileNode;
    For i := ExtFileNode.LowIndex to ExtFileNode.HighIndex do
      begin
        // sections...
        SIdx := fFileNode.IndexOfSection(ExtFileNode[i].NameStr);
        If SIdx >= 0 then
          begin
            // section of this name is already present, append comment...
            If Length(fFileNode[SIdx].Comment) > 0 then
              case fSettings.DuplicityBehavior of
                idbReplace:
                  fFileNode[SIdx].Comment := ExtFileNode[i].Comment;
                idbRenameOld:
                  If Length(ExtFileNode[i].Comment) > 0 then
                    fFileNode[SIdx].Comment := ExtFileNode[i].Comment + fSettings.TextIniSettings.LineBreak +
                      fSettings.TextIniSettings.LineBreak + TIFXString('Old comment:') +
                      fSettings.TextIniSettings.LineBreak + fFileNode[SIdx].Comment;
                idbRenameNew:
                  If Length(ExtFileNode[i].Comment) > 0 then
                    fFileNode[SIdx].Comment := fFileNode[SIdx].Comment + fSettings.TextIniSettings.LineBreak +
                      fSettings.TextIniSettings.LineBreak + TIFXString('New comment:') +
                      fSettings.TextIniSettings.LineBreak + ExtFileNode[i].Comment;
              else
                {idbDrop} // do nothing
              end
            else fFileNode[SIdx].Comment := ExtFileNode[i].Comment;
            // ... and copy only keys
            For j := ExtFileNode[i].LowIndex to ExtFileNode[i].HighIndex do
              begin
                KIdx := fFileNode[SIdx].IndexOfKey(ExtFileNode[i][j].NameStr);
                If KIdx >= 0 then
                  // key of this name is already present, decide what to do...
                  case fSettings.DuplicityBehavior of
                    idbReplace:
                      begin
                        fFileNode[SIdx].DeleteKey(KIdx);
                        NewKeyNode := TIFXKeyNode.CreateCopy(ExtFileNode[i][j]);
                        fFileNode[SIdx].AddKeyNode(NewKeyNode);
                        KeyCreateHandler(Self,fFileNode[SIdx],NewKeyNode);
                      end;
                    idbRenameOld:
                      begin
                        If fFileNode[SIdx].IndexOfKey(fFileNode[SIdx][KIdx].NameStr + fSettings.DuplicityRenameOldStr) >= 0 then
                          begin
                            Counter := 0;
                            while fFileNode[SIdx].IndexOfKey(fFileNode[SIdx][KIdx].NameStr +
                              fSettings.DuplicityRenameOldStr + StrToIFXStr(IntToStr(Counter))) >= 0 do
                              Inc(Counter);
                            fFileNode[SIdx][KIdx].NameStr := fFileNode[SIdx][KIdx].NameStr +
                              fSettings.DuplicityRenameOldStr + StrToIFXStr(IntToStr(Counter));
                          end
                        else fFileNode[SIdx][KIdx].NameStr := fFileNode[SIdx][KIdx].NameStr + fSettings.DuplicityRenameOldStr;
                        NewKeyNode := TIFXKeyNode.CreateCopy(ExtFileNode[i][j]);
                        fFileNode[SIdx].AddKeyNode(NewKeyNode);
                        KeyCreateHandler(Self,fFileNode[SIdx],NewKeyNode);
                      end;
                    idbRenameNew:
                      begin
                        NewKeyNode := TIFXKeyNode.CreateCopy(ExtFileNode[i][j]);
                        If fFileNode[SIdx].IndexOfKey(NewKeyNode.NameStr + fSettings.DuplicityRenameNewStr) >= 0 then
                          begin
                            Counter := 0;
                            while fFileNode[SIdx].IndexOfKey(NewKeyNode.NameStr + fSettings.DuplicityRenameNewStr +
                              StrToIFXStr(IntToStr(Counter))) >= 0 do
                              Inc(Counter);
                            NewKeyNode.NameStr := NewKeyNode.NameStr + fSettings.DuplicityRenameNewStr + StrToIFXStr(IntToStr(Counter));
                          end
                        else NewKeyNode.NameStr := NewKeyNode.NameStr + fSettings.DuplicityRenameNewStr;
                        fFileNode[SIdx].AddKeyNode(NewKeyNode);
                        KeyCreateHandler(Self,fFileNode[SIdx],NewKeyNode);
                      end;
                  else
                    {idbDrop}
                    // do nothing
                  end
                else
                  begin
                    // key of this name is not yet in this section, add copy
                    NewKeyNode := TIFXKeyNode.CreateCopy(ExtFileNode[i][j]);
                    fFileNode[SIdx].AddKeyNode(NewKeyNode);
                    KeyCreateHandler(Self,fFileNode[SIdx],NewKeyNode);
                  end;
              end;
          end
        else
          begin
            // section of this name is not yet present, create and add copy
            NewSectNode := TIFXSectionNode.CreateCopy(ExtFileNode[i],KeyCreateHandler);
            fFileNode.AddSectionNode(NewSectNode);
            SectionCreateHandler(Self,NewSectNode);
          end;
      end;
  end;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.IndexOfSection(const Section: TIFXString): Integer;
begin
Result := fFileNode.IndexOfSection(Section);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.IndexOfKey(const Section, Key: TIFXString): TIFXNodeIndices;
begin
Result := fFileNode.IndexOfKey(Section,Key);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.IndexOfKey(SectionIndex: Integer; const Key: TIFXString): Integer;
begin
If fFileNode.CheckIndex(SectionIndex) then
  Result := fFileNode[SectionIndex].IndexOfKey(Key)
else
  raise Exception.CreateFmt('TIniFileEx.IndexOfKey: Section index (%d) out of bounds.',[SectionIndex]);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.SectionExists(const Section: TIFXString): Boolean;
begin
Result := IndexOfSection(Section) >= 0;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.KeyExists(const Section, Key: TIFXString): Boolean;
begin
Result := IFXNodeIndicesValid(IndexOfKey(Section,Key));
end;

//------------------------------------------------------------------------------

Function TIniFileEx.KeyExists(SectionIndex: Integer; const Key: TIFXString): Boolean;
begin
Result := IndexOfKey(SectionIndex,Key) >= 0;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.AddSection(const Section: TIFXString);
begin
If not fSettings.ReadOnly then
  fFileNode.AddSection(Section);
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.AddKey(const Section, Key: TIFXString);
var
  SectionIndex: Integer;
  KeyIndex:     Integer;
begin
If not fSettings.ReadOnly then
  begin
    SectionIndex := fFileNode.AddSection(Section);
    KeyIndex := fFileNode[SectionIndex].IndexOfKey(Key);
    If KeyIndex < 0 then
      begin
        KeyIndex := fFileNode[SectionIndex].AddKey(Key);
        // set some arbitrary value so the value type is not left as undecided
        fFileNode[SectionIndex][KeyIndex].SetValueString('');
      end;
  end;
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.AddKey(SectionIndex: Integer; const Key: TIFXString);
begin
If not fSettings.ReadOnly then
  begin
    If fFileNode.CheckIndex(SectionIndex) then
      fFileNode[SectionIndex].AddKey(Key)
    else
      raise Exception.CreateFmt('TIniFileEx.AddKey: Section index (%d) out of bounds.',[SectionIndex]);
  end;
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.DeleteSection(const Section: TIFXString);
begin
If not fSettings.ReadOnly then
  fFileNode.RemoveSection(Section);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.DeleteKey(const Section, Key: TIFXString);
begin
If not fSettings.ReadOnly then
  fFileNode.RemoveKey(Section,Key);
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.DeleteKey(SectionIndex: Integer; const Key: TIFXString);
begin
If not fSettings.ReadOnly then
  begin
    If fFileNode.CheckIndex(SectionIndex) then
      fFileNode[SectionIndex].RemoveKey(Key)
    else
      raise Exception.CreateFmt('TIniFileEx.DeleteKey: Section index (%d) out of bounds.',[SectionIndex]);
  end;
end;
  
//------------------------------------------------------------------------------

procedure TIniFileEx.ExchangeSections(const Section1, Section2: TIFXString);
var
  SectIdx1,SectIdx2:  Integer;
begin
If not fSettings.ReadOnly then
  begin
    SectIdx1 := fFileNode.IndexOfSection(Section1);
    SectIdx2 := fFileNode.IndexOfSection(Section2);
    If (SectIdx1 <> SectIdx2) and fFileNode.CheckIndex(SectIdx1) and fFileNode.CheckIndex(SectIdx2) then
      fFileNode.ExchangeSections(SectIdx1,SectIdx2);
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.ExchangeKeys(const Section, Key1, Key2: TIFXString);
var
  SectionNode:      TIFXSectionNode;
  KeyIdx1,KeyIdx2:  Integer;
begin
If not fSettings.ReadOnly then
  If fFileNode.FindSection(Section,SectionNode) then
    begin
      KeyIdx1 := SectionNode.IndexOfKey(Key1);
      KeyIdx2 := SectionNode.IndexOfKey(Key2);
      If (KeyIdx1 <> KeyIdx2) and SectionNode.CheckIndex(KeyIdx1) and SectionNode.CheckIndex(KeyIdx2) then
        SectionNode.ExchangeKeys(KeyIdx1,KeyIdx2);
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.ExchangeKeys(SectionIndex: Integer; const Key1, Key2: TIFXString);
var
  KeyIdx1,KeyIdx2:  Integer;
begin
If not fSettings.ReadOnly then
  begin
    If fFileNode.CheckIndex(SectionIndex) then
      begin
        KeyIdx1 := fFileNode[SectionIndex].IndexOfKey(Key1);
        KeyIdx2 := fFileNode[SectionIndex].IndexOfKey(Key2);
        If (KeyIdx1 <> KeyIdx2) and fFileNode[SectionIndex].CheckIndex(KeyIdx1) and fFileNode[SectionIndex].CheckIndex(KeyIdx2) then
          fFileNode[SectionIndex].ExchangeKeys(KeyIdx1,KeyIdx2);
      end
    else raise Exception.CreateFmt('TIniFileEx.ExchangeKeys: Section index (%d) out of bounds.',[SectionIndex]);
  end;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.CopySection(const SourceSection, DestinationSection: TIFXString): Boolean;
var
  SrcSectionNode: TIFXSectionNode;
  Index:          Integer;
  Counter:        Integer;

  procedure AddNewSection(const NewSectionName: TIFXString);
  var
    NewSectionNode: TIFXSectionNode;
  begin
    NewSectionNode := TIFXSectionNode.CreateCopy(SrcSectionNode,KeyCreateHandler);
    NewSectionNode.NameStr := NewSectionName;
    fFileNode.AddSectionNode(NewSectionNode);
    SectionCreateHandler(Self,NewSectionNode);
    CopySection{Result} := True;
  end;

begin
Result := False;
If not fSettings.ReadOnly and (IFXCompareText(SourceSection,DestinationSection) <> 0) then
  If fFileNode.FindSection(SourceSection,SrcSectionNode) then
    begin
      Index := fFileNode.IndexOfSection(DestinationSection);
      If Index >= 0 then
        // section with the same name already exists, decide what to do
        case fSettings.DuplicityBehavior of
          idbReplace:
            begin
              fFileNode.DeleteSection(Index);
              AddNewSection(DestinationSection);
            end;
          idbRenameOld:
            begin
              If fFileNode.IndexOfSection(DestinationSection + fSettings.DuplicityRenameOldStr) >= 0 then
                begin
                  Counter := 0;
                  // this can go to infinite loop, but only theoretically, look elsewhere
                  while fFileNode.IndexOfSection(DestinationSection +
                    fSettings.DuplicityRenameOldStr + StrToIFXStr(IntToStr(Counter))) >= 0 do
                    Inc(Counter);
                  fFileNode[Index].NameStr := DestinationSection + fSettings.DuplicityRenameOldStr + StrToIFXStr(IntToStr(Counter));
                end
              else fFileNode[Index].NameStr := DestinationSection + fSettings.DuplicityRenameOldStr;
              AddNewSection(DestinationSection);
            end;
          idbRenameNew:
            If fFileNode.IndexOfSection(DestinationSection + fSettings.DuplicityRenameNewStr) >= 0 then
              begin
                Counter := 0;
                while fFileNode.IndexOfSection(DestinationSection +
                  fSettings.DuplicityRenameNewStr + StrToIFXStr(IntToStr(Counter))) >= 0 do
                  Inc(Counter);
                AddNewSection(DestinationSection + fSettings.DuplicityRenameNewStr + StrToIFXStr(IntToStr(Counter)));
              end
            else AddNewSection(DestinationSection + fSettings.DuplicityRenameNewStr);
        else
          {idbDrop}
        end
      else AddNewSection(DestinationSection);
    end;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.CopyKey(const SourceSection, DestinationSection, SourceKey, DestinationKey: TIFXString): Boolean;
var
  SrcSectionIndex:  Integer;
  DstSectionIndex:  Integer;
  SrcKeyNode:       TIFXKeyNode;
  Index:            Integer;
  Counter:          Integer;

  procedure AddNewKey(const NewKeyName: TIFXString);
  var
    NewKeyNode: TIFXKeyNode;
  begin
    NewKeyNode := TIFXKeyNode.CreateCopy(SrcKeyNode);
    NewKeyNode.NameStr := NewKeyName;
    fFileNode[DstSectionIndex].AddKeyNode(NewKeyNode);
    KeyCreateHandler(Self,fFileNode[DstSectionIndex],NewKeyNode);
    CopyKey{Result} := True;
  end;

begin
Result := False;
If not fSettings.ReadOnly and ((IFXCompareText(SourceSection,DestinationSection) <> 0) or
  (IFXCompareText(SourceKey,DestinationKey) <> 0)) then
  begin
    SrcSectionIndex := fFileNode.IndexOfSection(SourceSection);
    If SrcSectionIndex >= 0 then
      begin
        DstSectionIndex := fFileNode.AddSection(DestinationSection);
        If fFileNode[SrcSectionIndex].FindKey(SourceKey,SrcKeyNode) then
          begin
            Index := fFileNode[DstSectionIndex].IndexOfKey(DestinationKey);
            If Index >= 0 then
              // key with the same name already exists in the destination section
              case fSettings.DuplicityBehavior of
                idbReplace:
                  begin
                    fFileNode[DstSectionIndex].DeleteKey(Index);
                    AddNewKey(DestinationKey);
                  end;
                idbRenameOld:
                  begin
                    If fFileNode[DstSectionIndex].IndexOfKey(DestinationKey + fSettings.DuplicityRenameOldStr) >= 0 then
                      begin
                        Counter := 0;
                        while fFileNode[DstSectionIndex].IndexOfKey(DestinationKey +
                          fSettings.DuplicityRenameOldStr + StrToIFXStr(IntToStr(Counter))) >= 0 do
                          Inc(Counter);
                        fFileNode[DstSectionIndex][Index].NameStr := DestinationKey + fSettings.DuplicityRenameOldStr + StrToIFXStr(IntToStr(Counter));
                      end
                    else fFileNode[DstSectionIndex][Index].NameStr := DestinationKey + fSettings.DuplicityRenameOldStr;
                    AddNewKey(DestinationKey);
                  end;
                idbRenameNew:
                  If fFileNode[DstSectionIndex].IndexOfKey(DestinationKey + fSettings.DuplicityRenameNewStr) >= 0 then
                    begin
                      Counter := 0;
                      while fFileNode[DstSectionIndex].IndexOfKey(DestinationKey +
                        fSettings.DuplicityRenameNewStr + StrToIFXStr(IntToStr(Counter))) >= 0 do
                        Inc(Counter);
                      AddNewKey(DestinationKey + fSettings.DuplicityRenameNewStr + StrToIFXStr(IntToStr(Counter)));
                    end
                  else AddNewKey(DestinationKey + fSettings.DuplicityRenameNewStr);
              else
                {idbDrop}
              end
            else AddNewKey(DestinationKey);
          end;
      end;
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.Clear;
begin
If not fSettings.ReadOnly then
  begin
    fFileNode.ClearSections;
    fFileNode.Comment := '';
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SortSections;
begin
If not fSettings.ReadOnly then
  fFileNode.SortSections;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SortSection(const Section: TIFXString);
var
  SectionNode:  TIFXSectionNode;
begin
If not fSettings.ReadOnly then
  If fFileNode.FindSection(Section,SectionNode) then
    SectionNode.SortKeys;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SortKeys(const Section: TIFXString);
begin
If not fSettings.ReadOnly then
  SortSection(Section);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SortKeys;
var
  i:  Integer;
begin
If not fSettings.ReadOnly then
  For i := fFileNode.LowIndex to fFileNode.HighIndex do
    fFileNode[i].SortKeys;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.Sort;
begin
If not fSettings.ReadOnly then
  begin
    SortKeys;
    SortSections;
  end;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetFileComment: TIFXString;
begin
Result := fFileNode.Comment;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetFileCommentStr: String;
begin
Result := IFXStrToStr(fFileNode.Comment);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetSectionComment(const Section: TIFXString): TIFXString;
var
  SectionNode:  TIFXSectionNode;
begin
If fFileNode.FindSection(Section,SectionNode) then
  Result := SectionNode.Comment
else
  Result := '';
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetSectionInlineComment(const Section: TIFXString): TIFXString;
var
  SectionNode:  TIFXSectionNode;
begin
If fFileNode.FindSection(Section,SectionNode) then
  Result := SectionNode.InlineComment
else
  Result := '';
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetKeyComment(const Section, Key: TIFXString): TIFXString;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  Result := KeyNode.Comment
else
  Result := '';
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetKeyInlineComment(const Section, Key: TIFXString): TIFXString;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  Result := KeyNode.InlineComment
else
  Result := '';
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SetFileComment(const Text: TIFXString);
begin
If not fSettings.ReadOnly then
  fFileNode.Comment := Text;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SetSectionComment(const Section: TIFXString; const Text: TIFXString);
var
  SectionNode:  TIFXSectionNode;
begin
If not fSettings.ReadOnly then
  If fFileNode.FindSection(Section,SectionNode) then
    SectionNode.Comment := Text;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SetSectionInlineComment(const Section: TIFXString; const Text: TIFXString);
var
  SectionNode:  TIFXSectionNode;
begin
If not fSettings.ReadOnly then
  If fFileNode.FindSection(Section,SectionNode) then
    SectionNode.InlineComment := Text;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SetKeyComment(const Section, Key: TIFXString; const Text: TIFXString);
var
  KeyNode:  TIFXKeyNode;
begin
If not fSettings.ReadOnly then
  If fFileNode.FindKey(Section,Key,KeyNode) then
    KeyNode.Comment := Text;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SetKeyInlineComment(const Section, Key: TIFXString; const Text: TIFXString);
var
  KeyNode:  TIFXKeyNode;
begin
If not fSettings.ReadOnly then
  If fFileNode.FindKey(Section,Key,KeyNode) then
    KeyNode.InlineComment := Text;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.RemoveFileComment;
begin
If not fSettings.ReadOnly then
  fFileNode.Comment := '';
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.RemoveSectionComment(const Section: TIFXString; RemoveKeysComments: Boolean = False);
var
  SectionNode:  TIFXSectionNode;
  i:            Integer;
begin
If not fSettings.ReadOnly then
  If fFileNode.FindSection(Section,SectionNode) then
    begin
      SectionNode.Comment := '';
      SectionNode.InlineComment := '';
      If RemoveKeysComments then
        For i := SectionNode.LowIndex to SectionNode.HighIndex do
          begin
            SectionNode[i].Comment := '';
            SectionNode[i].InlineComment := '';
          end;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.RemoveKeyComment(const Section, Key: TIFXString);
var
  KeyNode:  TIFXKeyNode;
begin
If not fSettings.ReadOnly then
  If fFileNode.FindKey(Section,Key,KeyNode) then
    begin
      KeyNode.Comment := '';
      KeyNode.InlineComment := '';
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.RemoveAllComment;
var
  i,j:  Integer;
begin
If not fSettings.ReadOnly then
  begin
    RemoveFileComment;
    For i := fFileNode.LowIndex to fFileNode.HighIndex do
      begin
        fFileNode[i].Comment := '';
        For j := fFileNode[i].LowIndex to fFileNode[i].HighIndex do
          fFileNode[i][j].Comment := '';
      end;
  end;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetValueState(const Section, Key: TIFXString): TIFXValueState;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  Result := KeyNode.ValueState
else
  raise Exception.CreateFmt('TIniFileEx.GetValueState: Key (%s:%s) not found.',[Section,Key]);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetValueEncoding(const Section, Key: TIFXString): TIFXValueEncoding;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  Result := KeyNode.ValueEncoding
else
  raise Exception.CreateFmt('TIniFileEx.GetValueEncoding: Key (%s:%s) not found.',[Section,Key]);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SetValueEncoding(const Section, Key: TIFXString; Encoding: TIFXValueEncoding);
var
  KeyNode:  TIFXKeyNode;
begin
If not fSettings.ReadOnly then
  If fFileNode.FindKey(Section,Key,KeyNode) then
    KeyNode.ValueEncoding := Encoding;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetValueType(const Section, Key: TIFXString): TIFXValueType;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  Result := KeyNode.ValueType
else
  raise Exception.CreateFmt('TIniFileEx.GetValueType: Key (%s:%s) not found.',[Section,Key]);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.ReadSections(Strings: TStrings);
var
  i:  Integer;
begin
Strings.Clear;
For i := fFileNode.LowIndex to fFileNode.HighIndex do
  Strings.Add(IFXStrToStr(fFileNode[i].NameStr));
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.ReadSection(const Section: TIFXString; Strings: TStrings);
var
  SectionNode:  TIFXSectionNode;
  i:            Integer;
begin
If fFileNode.FindSection(Section,SectionNode) then
  begin
    Strings.Clear;
    For i := SectionNode.LowIndex to SectionNode.HighIndex do
      Strings.Add(IFXStrToStr(SectionNode[i].NameStr));
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.ReadSectionValues(const Section: TIFXString; Strings: TStrings);
var
  SectionNode:  TIFXSectionNode;
  i:            Integer;
  Dummy:        TStrSize;
begin
If fFileNode.FindSection(Section,SectionNode) then
  begin
    Strings.Clear;
    For i := SectionNode.LowIndex to SectionNode.HighIndex do
      Strings.Add(IFXStrToStr(fParser.ConstructKeyValueLine(SectionNode[i],Dummy)));
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBool(const Section, Key: TIFXString; Value: Boolean);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueBool(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteBool(const Section, Key: TIFXString; Value: Boolean; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueBool(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInt8(const Section, Key: TIFXString; Value: Int8);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueInt8(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteInt8(const Section, Key: TIFXString; Value: Int8; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueInt8(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteUInt8(const Section, Key: TIFXString; Value: UInt8);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueUInt8(Value);
end;
 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteUInt8(const Section, Key: TIFXString; Value: UInt8; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueUInt8(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInt16(const Section, Key: TIFXString; Value: Int16);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueInt16(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteInt16(const Section, Key: TIFXString; Value: Int16; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueInt16(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteUInt16(const Section, Key: TIFXString; Value: UInt16);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueUInt16(Value);
end;
  
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteUInt16(const Section, Key: TIFXString; Value: UInt16; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueUInt16(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInt32(const Section, Key: TIFXString; Value: Int32);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueInt32(Value);
end;
 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteInt32(const Section, Key: TIFXString; Value: Int32; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueInt32(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteUInt32(const Section, Key: TIFXString; Value: UInt32);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueUInt32(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteUInt32(const Section, Key: TIFXString; Value: UInt32; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueUInt32(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInt64(const Section, Key: TIFXString; Value: Int64);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueInt64(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteInt64(const Section, Key: TIFXString; Value: Int64; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueInt64(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteUInt64(const Section, Key: TIFXString; Value: UInt64);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueUInt64(Value);
end;
 
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteUInt64(const Section, Key: TIFXString; Value: UInt64; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueUInt64(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInteger(const Section, Key: TIFXString; Value: Integer);
begin
If not fSettings.ReadOnly then
{$IF SizeOf(Integer) = 2}
  WritingValue(Section,Key).SetValueInt16(Value);
{$ELSEIF SizeOf(Integer) = 4}
  WritingValue(Section,Key).SetValueInt32(Value);
{$ELSEIF SizeOf(Integer) = 8}
  WritingValue(Section,Key).SetValueInt64(Value);
{$ELSE}
  {$MESSAGE FATAL 'Unsupported integer size'}
{$IFEND}
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteInteger(const Section, Key: TIFXString; Value: Integer; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueInt32(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteFloat32(const Section, Key: TIFXString; Value: Float32);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueFloat32(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteFloat32(const Section, Key: TIFXString; Value: Float32; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueFloat32(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteFloat64(const Section, Key: TIFXString; Value: Float64);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueFloat64(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteFloat64(const Section, Key: TIFXString; Value: Float64; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueFloat64(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteFloat(const Section, Key: TIFXString; Value: Double);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueFloat64(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteFloat(const Section, Key: TIFXString; Value: Double; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueFloat64(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteTime(const Section, Key: TIFXString; Value: TDateTime);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueTime(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteTime(const Section, Key: TIFXString; Value: TDateTime; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueTime(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteDate(const Section, Key: TIFXString; Value: TDateTime);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueDate(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteDate(const Section, Key: TIFXString; Value: TDateTime; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueDate(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteDateTime(const Section, Key: TIFXString; Value: TDateTime);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueDateTime(Value);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteDateTime(const Section, Key: TIFXString; Value: TDateTime; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueDateTime(Value);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteString(const Section, Key: TIFXString; const Value: String);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueString(StrToIFXStr(Value));
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteString(const Section, Key: TIFXString; const Value: String; Encoding: TIFXValueEncoding);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueString(StrToIFXStr(Value));
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBinaryBuffer(const Section, Key: TIFXString; const Buffer; Size: TMemSize; MakeCopy: Boolean = False);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueBinary(@Buffer,Size,MakeCopy);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteBinaryBuffer(const Section, Key: TIFXString; const Buffer; Size: TMemSize; Encoding: TIFXValueEncoding; MakeCopy: Boolean = False);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueBinary(@Buffer,Size,MakeCopy);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBinaryMemory(const Section, Key: TIFXString; Value: Pointer; Size: TMemSize; MakeCopy: Boolean = False);
begin
If not fSettings.ReadOnly then
  WritingValue(Section,Key).SetValueBinary(Value,Size,MakeCopy);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteBinaryMemory(const Section, Key: TIFXString; Value: Pointer; Size: TMemSize; Encoding: TIFXValueEncoding; MakeCopy: Boolean = False);
begin
If not fSettings.ReadOnly then
  with WritingValue(Section,Key) do
    begin
      SetValueBinary(Value,Size,MakeCopy);
      ValueEncoding := Encoding;
    end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBinaryStream(const Section, Key: TIFXString; Stream: TStream; Position, Count: Int64);
var
  TempMem:  Pointer;
begin
If not fSettings.ReadOnly then
  begin
    GetMem(TempMem,Count);
    try
      Stream.Seek(Position,soBeginning);
      Stream.ReadBuffer(TempMem^,Count);
      with WritingValue(Section,Key) do
        begin
          SetValueBinary(TempMem,TMemSize(Count),False);
          ValueDataPtr^.BinaryValueOwned := True;
        end;
    except
      FreeMem(TempMem,Stream.Size);
      raise;
    end;
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteBinaryStream(const Section, Key: TIFXString; Stream: TStream; Position, Count: Int64; Encoding: TIFXValueEncoding);
var
  TempMem:  Pointer;
begin
If not fSettings.ReadOnly then
  begin
    GetMem(TempMem,Count);
    try
      Stream.Seek(Position,soBeginning);
      Stream.ReadBuffer(TempMem^,Count);
      with WritingValue(Section,Key) do
        begin
          SetValueBinary(TempMem,TMemSize(Count),False);
          ValueDataPtr^.BinaryValueOwned := True;
          ValueEncoding := Encoding;
        end;
    except
      FreeMem(TempMem,Stream.Size);
      raise;
    end;
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBinaryStream(const Section, Key: TIFXString; Stream: TStream);
var
  TempMem:  Pointer;
begin
If not fSettings.ReadOnly then
  begin
    GetMem(TempMem,Stream.Size);
    try
      Stream.Seek(0,soBeginning);
      Stream.ReadBuffer(TempMem^,Stream.Size);
      with WritingValue(Section,Key) do
        begin
          SetValueBinary(TempMem,Stream.Size,False);
          ValueDataPtr^.BinaryValueOwned := True;
        end;
    except
      FreeMem(TempMem,Stream.Size);
      raise;
    end;
  end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure TIniFileEx.WriteBinaryStream(const Section, Key: TIFXString; Stream: TStream; Encoding: TIFXValueEncoding);
var
  TempMem:  Pointer;
begin
If not fSettings.ReadOnly then
  begin
    GetMem(TempMem,Stream.Size);
    try
      Stream.Seek(0,soBeginning);
      Stream.ReadBuffer(TempMem^,Stream.Size);
      with WritingValue(Section,Key) do
        begin
          SetValueBinary(TempMem,Stream.Size,False);
          ValueDataPtr^.BinaryValueOwned := True;
          ValueEncoding := Encoding;
        end;
    except
      FreeMem(TempMem,Stream.Size);
      raise
    end;
  end;
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.PrepareReading(const Section, Key: TIFXString; ValueType: TIFXValueType);
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.GetValuePrepare(ValueType)
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadBool(const Section, Key: TIFXString; Default: Boolean = False): Boolean;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If not KeyNode.GetValueBool(Result) then
      Result := Default
  end
else Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadInt8(const Section, Key: TIFXString; Default: Int8 = 0): Int8;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If not KeyNode.GetValueInt8(Result) then
      Result := Default;
  end
else Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadUInt8(const Section, Key: TIFXString; Default: UInt8 = 0): UInt8;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If not KeyNode.GetValueUInt8(Result) then
      Result := Default;
  end
else Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadInt16(const Section, Key: TIFXString; Default: Int16 = 0): Int16;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If not KeyNode.GetValueInt16(Result) then
      Result := Default;
  end
else Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadUInt16(const Section, Key: TIFXString; Default: UInt16 = 0): UInt16;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If not KeyNode.GetValueUInt16(Result) then
      Result := Default;
  end
else Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadInt32(const Section, Key: TIFXString; Default: Int32 = 0): Int32;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If not KeyNode.GetValueInt32(Result) then
      Result := Default;
  end
else Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadUInt32(const Section, Key: TIFXString; Default: UInt32 = 0): UInt32;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If not KeyNode.GetValueUInt32(Result) then
      Result := Default;
  end
else Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadInt64(const Section, Key: TIFXString; Default: Int64 = 0): Int64;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If not KeyNode.GetValueInt64(Result) then
      Result := Default;
  end
else Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadUInt64(const Section, Key: TIFXString; Default: UInt64 = 0): UInt64;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If not KeyNode.GetValueUInt64(Result) then
      Result := Default;
  end
else Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadInteger(const Section, Key: TIFXString; Default: Integer = 0): Integer;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If not KeyNode.GetValueInt32(Result) then
      Result := Default;
  end
else Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadFloat32(const Section, Key: TIFXString; Default: Float32 = 0.0): Float32;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If not KeyNode.GetValueFloat32(Result) then
      Result := Default;
  end
else Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadFloat64(const Section, Key: TIFXString; Default: Float64 = 0.0): Float64;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If not KeyNode.GetValueFloat64(Result) then
      Result := Default;
  end
else Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadFloat(const Section, Key: TIFXString; Default: Double = 0.0): Double;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If not KeyNode.GetValueFloat64(Result) then
      Result := Default;
  end
else Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadTime(const Section, Key: TIFXString; Default: TDateTime = 0.0): TDateTime;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If not KeyNode.GetValueDate(Result) then
      Result := Default;
  end
else Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadDate(const Section, Key: TIFXString; Default: TDateTime = 0.0): TDateTime;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If not KeyNode.GetValueTime(Result) then
      Result := Default;
  end
else Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadDateTime(const Section, Key: TIFXString; Default: TDateTime = 0.0): TDateTime;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If not KeyNode.GetValueDateTime(Result) then
      Result := Default;
  end
else Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadString(const Section, Key: TIFXString; Default: String = ''): String;
var
  KeyNode:  TIFXKeyNode;
  OutTemp:  TIFXString;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If KeyNode.GetValueString(OutTemp) then
      Result := IFXStrToStr(OutTemp)
    else
      Result := Default;
  end
else Result := Default;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadBinarySize(const Section, Key: TIFXString): TMemSize;
var
  KeyNode:  TIFXKeyNode;
  Dummy:    Pointer;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If not KeyNode.GetValueBinary(Dummy,Result,False) then
      Result := 0;
  end
else Result := 0;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadBinaryBuffer(const Section, Key: TIFXString; var Buffer; Size: TMemSize): TMemSize;
var
  KeyNode:    TIFXKeyNode;
  ValuePtr:   Pointer;
  ValueSize:  TMemSize;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If KeyNode.GetValueBinary(ValuePtr,ValueSize,False) then
      begin
        If Size < ValueSize then Result := Size
          else Result := ValueSize;
        Move(ValuePtr^,Buffer,Result);
      end
    else Result := 0;
  end
else Result := 0;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadBinaryMemory(const Section, Key: TIFXString; out Ptr: Pointer; MakeCopy: Boolean = False): TMemSize;
var
  KeyNode:  TIFXKeyNode;
begin
If not fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    Ptr := nil;
    Result := 0;
  end
else If not KeyNode.GetValueBinary(Ptr,Result,MakeCopy) then
  Result := 0;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadBinaryMemory(const Section, Key: TIFXString; Ptr: Pointer; Size: TMemSize): TMemSize;
begin
Result := ReadBinaryBuffer(Section,Key,Ptr^,Size);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadBinaryStream(const Section, Key: TIFXString; Stream: TStream; ClearStream: Boolean = False): Int64;
var
  KeyNode:    TIFXKeyNode;
  ValuePtr:   Pointer;
  ValueSize:  TMemSize;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  begin
    If KeyNode.GetValueBinary(ValuePtr,ValueSize,False) then
      begin
        If ClearStream then
          Stream.Size := 0;
        Stream.WriteBuffer(ValuePtr^,ValueSize);
        Result := Int64(ValueSize);
      end
    else Result := 0;
  end
else Result := 0;
end;

//------------------------------------------------------------------------------

{$IFDEF DefStrOverloads}

Function TIniFileEx.IndexOfSection(const Section: String): Integer;
begin
Result := IndexOfSection(StrToIFXStr(Section));
end;

//------------------------------------------------------------------------------

Function TIniFileEx.IndexOfKey(const Section, Key: String): TIFXNodeIndices;
begin
Result := IndexOfKey(StrToIFXStr(Section),StrToIFXStr(Key));
end;

//------------------------------------------------------------------------------

Function TIniFileEx.IndexOfKey(SectionIndex: Integer; const Key: String): Integer;
begin
Result := IndexOfKey(SectionIndex,StrToIFXStr(Key));
end;

//------------------------------------------------------------------------------

Function TIniFileEx.SectionExists(const Section: String): Boolean;
begin
Result := SectionExists(StrToIFXStr(Section));
end;

//------------------------------------------------------------------------------

Function TIniFileEx.KeyExists(const Section, Key: String): Boolean;
begin
Result := KeyExists(StrToIFXStr(Section),StrToIFXStr(Key));
end;

//------------------------------------------------------------------------------

Function TIniFileEx.KeyExists(SectionIndex: Integer; const Key: String): Boolean;
begin
Result := KeyExists(SectionIndex,StrToIFXStr(Key));
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.AddSection(const Section: String);
begin
AddSection(StrToIFXStr(Section));
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.AddKey(const Section, Key: String);
begin
AddKey(StrToIFXStr(Section),StrToIFXStr(Key));
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.AddKey(SectionIndex: Integer; const Key: String);
begin
AddKey(SectionIndex,StrToIFXStr(Key));
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.DeleteSection(const Section: String);
begin
DeleteSection(StrToIFXStr(Section));
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.DeleteKey(const Section, Key: String);
begin
DeleteKey(StrToIFXStr(Section),StrToIFXStr(Key));
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.DeleteKey(SectionIndex: Integer; const Key: String);
begin
DeleteKey(SectionIndex,StrToIFXStr(Key));
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.ExchangeSections(const Section1, Section2: String);
begin
ExchangeSections(StrToIFXStr(Section1),StrToIFXStr(Section2));
end;
   
//------------------------------------------------------------------------------

procedure TIniFileEx.ExchangeKeys(const Section, Key1, Key2: String);
begin
ExchangeKeys(StrToIFXStr(Section),StrToIFXStr(Key1),StrToIFXStr(Key2));
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.ExchangeKeys(SectionIndex: Integer; const Key1, Key2: String);
begin
ExchangeKeys(SectionIndex,StrToIFXStr(Key1),StrToIFXStr(Key2));
end;
 
//------------------------------------------------------------------------------

Function TIniFileEx.CopySection(const SourceSection, DestinationSection: String): Boolean;
begin
Result := CopySection(StrToIFXStr(SourceSection),StrToIFXStr(DestinationSection));
end;
 
//------------------------------------------------------------------------------

Function TIniFileEx.CopyKey(const SourceSection, DestinationSection, SourceKey, DestinationKey: String): Boolean;
begin
Result := CopyKey(StrToIFXStr(SourceSection),StrToIFXStr(DestinationSection),StrToIFXStr(SourceKey),StrToIFXStr(DestinationKey));
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.SortSection(const Section: String);
begin
SortSection(StrToIFXStr(Section));
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SortKeys(const Section: String);
begin
SortKeys(StrToIFXStr(Section));
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetSectionComment(const Section: String): String;
begin
Result := IFXStrToStr(GetSectionComment(StrToIFXStr(Section)));
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetSectionInlineComment(const Section: String): String;
begin
Result := IFXStrToStr(GetSectionInlineComment(StrToIFXStr(Section)));
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetKeyComment(const Section, Key: String): String;
begin
Result := IFXStrToStr(GetKeyComment(StrToIFXStr(Section),StrToIFXStr(Key)));
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetKeyInlineComment(const Section, Key: String): String;
begin
Result := IFXStrToStr(GetKeyInlineComment(StrToIFXStr(Section),StrToIFXStr(Key)));
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SetFileComment(const Text: String);
begin
SetFileComment(StrToIFXStr(Text));
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.SetSectionComment(const Section: String; const Text: String);
begin
SetSectionComment(StrToIFXStr(Section),StrToIFXStr(Text));
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SetSectionInlineComment(const Section: String; const Text: String);
begin
SetSectionInlineComment(StrToIFXStr(Section),StrToIFXStr(Text));
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.SetKeyComment(const Section, Key: String; const Text: String);
begin
SetKeyComment(StrToIFXStr(Section),StrToIFXStr(Key),StrToIFXStr(Text));
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SetKeyInlineComment(const Section, Key: String; const Text: String);
begin
SetKeyInlineComment(StrToIFXStr(Section),StrToIFXStr(Key),StrToIFXStr(Text));
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.RemoveSectionComment(const Section: String; RemoveKeysComments: Boolean = False);
begin
RemoveSectionComment(StrToIFXStr(Section),RemoveKeysComments);
end;
 
//------------------------------------------------------------------------------

procedure TIniFileEx.RemoveKeyComment(const Section, Key: String);
begin
RemoveKeyComment(StrToIFXStr(Section),StrToIFXStr(Key));
end;
 
//------------------------------------------------------------------------------

Function TIniFileEx.GetValueState(const Section, Key: String): TIFXValueState;
begin
Result := GetValueState(StrToIFXStr(Section),StrToIFXStr(Key));
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetValueEncoding(const Section, Key: String): TIFXValueEncoding;
begin
Result := GetValueEncoding(StrToIFXStr(Section),StrToIFXStr(Key));
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SetValueEncoding(const Section, Key: String; Encoding: TIFXValueEncoding);
begin
SetValueEncoding(StrToIFXStr(Section),StrToIFXStr(Key),Encoding);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetValueType(const Section, Key: String): TIFXValueType;
begin
Result := GetValueType(StrToIFXStr(Section),StrToIFXStr(Key));
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.ReadSection(const Section: String; Strings: TStrings);
begin
ReadSection(StrToIFXStr(Section),Strings);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.ReadSectionValues(const Section: String; Strings: TStrings);
begin
ReadSectionValues(StrToIFXStr(Section),Strings);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBool(const Section, Key: String; Value: Boolean);
begin
WriteBool(StrToIFXStr(Section),StrToIFXStr(Key),Value);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBool(const Section, Key: String; Value: Boolean; Encoding: TIFXValueEncoding);
begin
WriteBool(StrToIFXStr(Section),StrToIFXStr(Key),Value,Encoding);
end; 

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInt8(const Section, Key: String; Value: Int8);
begin
WriteInt8(StrToIFXStr(Section),StrToIFXStr(Key),Value);
end; 

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInt8(const Section, Key: String; Value: Int8; Encoding: TIFXValueEncoding);
begin
WriteInt8(StrToIFXStr(Section),StrToIFXStr(Key),Value,Encoding);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteUInt8(const Section, Key: String; Value: UInt8);
begin
WriteUInt8(StrToIFXStr(Section),StrToIFXStr(Key),Value);
end; 

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteUInt8(const Section, Key: String; Value: UInt8; Encoding: TIFXValueEncoding);
begin
WriteUInt8(StrToIFXStr(Section),StrToIFXStr(Key),Value,Encoding);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInt16(const Section, Key: String; Value: Int16);
begin
WriteInt16(StrToIFXStr(Section),StrToIFXStr(Key),Value);
end; 

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInt16(const Section, Key: String; Value: Int16; Encoding: TIFXValueEncoding); 
begin
WriteInt16(StrToIFXStr(Section),StrToIFXStr(Key),Value,Encoding);
end; 

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteUInt16(const Section, Key: String; Value: UInt16);
begin
WriteUInt16(StrToIFXStr(Section),StrToIFXStr(Key),Value);
end; 

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteUInt16(const Section, Key: String; Value: UInt16; Encoding: TIFXValueEncoding);
begin
WriteUInt16(StrToIFXStr(Section),StrToIFXStr(Key),Value,Encoding);
end;   

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInt32(const Section, Key: String; Value: Int32);
begin
WriteInt32(StrToIFXStr(Section),StrToIFXStr(Key),Value);
end;  

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInt32(const Section, Key: String; Value: Int32; Encoding: TIFXValueEncoding); 
begin
WriteInt32(StrToIFXStr(Section),StrToIFXStr(Key),Value,Encoding);
end;  

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteUInt32(const Section, Key: String; Value: UInt32);
begin
WriteUInt32(StrToIFXStr(Section),StrToIFXStr(Key),Value);
end;  

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteUInt32(const Section, Key: String; Value: UInt32; Encoding: TIFXValueEncoding); 
begin
WriteUInt32(StrToIFXStr(Section),StrToIFXStr(Key),Value,Encoding);
end;  

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInt64(const Section, Key: String; Value: Int64);
begin
WriteInt64(StrToIFXStr(Section),StrToIFXStr(Key),Value);
end;  

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInt64(const Section, Key: String; Value: Int64; Encoding: TIFXValueEncoding);  
begin
WriteInt64(StrToIFXStr(Section),StrToIFXStr(Key),Value,Encoding);
end;  

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteUInt64(const Section, Key: String; Value: UInt64);
begin
WriteUInt64(StrToIFXStr(Section),StrToIFXStr(Key),Value);
end;    

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteUInt64(const Section, Key: String; Value: UInt64; Encoding: TIFXValueEncoding); 
begin
WriteUInt64(StrToIFXStr(Section),StrToIFXStr(Key),Value,Encoding);
end;   

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInteger(const Section, Key: String; Value: Integer);
begin
WriteInteger(StrToIFXStr(Section),StrToIFXStr(Key),Value);
end;   

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteInteger(const Section, Key: String; Value: Integer; Encoding: TIFXValueEncoding); 
begin
WriteInteger(StrToIFXStr(Section),StrToIFXStr(Key),Value,Encoding);
end;    

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteFloat32(const Section, Key: String; Value: Float32);
begin
WriteFloat32(StrToIFXStr(Section),StrToIFXStr(Key),Value);
end;   

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteFloat32(const Section, Key: String; Value: Float32; Encoding: TIFXValueEncoding);  
begin
WriteFloat32(StrToIFXStr(Section),StrToIFXStr(Key),Value,Encoding);
end;   

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteFloat64(const Section, Key: String; Value: Float64);
begin
WriteFloat64(StrToIFXStr(Section),StrToIFXStr(Key),Value);
end;      

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteFloat64(const Section, Key: String; Value: Float64; Encoding: TIFXValueEncoding); 
begin
WriteFloat64(StrToIFXStr(Section),StrToIFXStr(Key),Value,Encoding);
end;   

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteFloat(const Section, Key: String; Value: Double);
begin
WriteFloat(StrToIFXStr(Section),StrToIFXStr(Key),Value);
end;    

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteFloat(const Section, Key: String; Value: Double; Encoding: TIFXValueEncoding); 
begin
WriteFloat(StrToIFXStr(Section),StrToIFXStr(Key),Value,Encoding);
end;   

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteTime(const Section, Key: String; Value: TDateTime);
begin
WriteTime(StrToIFXStr(Section),StrToIFXStr(Key),Value);
end;    

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteTime(const Section, Key: String; Value: TDateTime; Encoding: TIFXValueEncoding); 
begin
WriteTime(StrToIFXStr(Section),StrToIFXStr(Key),Value,Encoding);
end;     

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteDate(const Section, Key: String; Value: TDateTime);
begin
WriteDate(StrToIFXStr(Section),StrToIFXStr(Key),Value);
end;    

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteDate(const Section, Key: String; Value: TDateTime; Encoding: TIFXValueEncoding);  
begin
WriteDate(StrToIFXStr(Section),StrToIFXStr(Key),Value,Encoding);
end;    

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteDateTime(const Section, Key: String; Value: TDateTime);
begin
WriteDateTime(StrToIFXStr(Section),StrToIFXStr(Key),Value);
end; 

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteDateTime(const Section, Key: String; Value: TDateTime; Encoding: TIFXValueEncoding);  
begin
WriteDateTime(StrToIFXStr(Section),StrToIFXStr(Key),Value,Encoding);
end;   

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteString(const Section, Key: String; const Value: String);
begin
WriteString(StrToIFXStr(Section),StrToIFXStr(Key),Value);
end;   

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteString(const Section, Key: String; const Value: String; Encoding: TIFXValueEncoding);
begin
WriteString(StrToIFXStr(Section),StrToIFXStr(Key),Value,Encoding);
end;  

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBinaryBuffer(const Section, Key: String; const Buffer; Size: TMemSize; MakeCopy: Boolean = False);
begin
WriteBinaryBuffer(StrToIFXStr(Section),StrToIFXStr(Key),Buffer,Size,MakeCopy);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBinaryBuffer(const Section, Key: String; const Buffer; Size: TMemSize; Encoding: TIFXValueEncoding; MakeCopy: Boolean = False);
begin
WriteBinaryBuffer(StrToIFXStr(Section),StrToIFXStr(Key),Buffer,Size,Encoding,MakeCopy);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBinaryMemory(const Section, Key: String; Value: Pointer; Size: TMemSize; MakeCopy: Boolean = False);
begin
WriteBinaryMemory(StrToIFXStr(Section),StrToIFXStr(Key),Value,Size,MakeCopy);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBinaryMemory(const Section, Key: String; Value: Pointer; Size: TMemSize; Encoding: TIFXValueEncoding; MakeCopy: Boolean = False);
begin
WriteBinaryMemory(StrToIFXStr(Section),StrToIFXStr(Key),Value,Size,Encoding,MakeCopy);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBinaryStream(const Section, Key: String; Stream: TStream; Position, Count: Int64);
begin
WriteBinaryStream(StrToIFXStr(Section),StrToIFXStr(Key),Stream,Position,Count);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBinaryStream(const Section, Key: String; Stream: TStream; Position, Count: Int64; Encoding: TIFXValueEncoding);
begin
WriteBinaryStream(StrToIFXStr(Section),StrToIFXStr(Key),Stream,Position,Count,Encoding);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBinaryStream(const Section, Key: String; Stream: TStream);
begin
WriteBinaryStream(StrToIFXStr(Section),StrToIFXStr(Key),Stream);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.WriteBinaryStream(const Section, Key: String; Stream: TStream; Encoding: TIFXValueEncoding);
begin
WriteBinaryStream(StrToIFXStr(Section),StrToIFXStr(Key),Stream,Encoding);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.PrepareReading(const Section, Key: String; ValueType: TIFXValueType);
begin
PrepareReading(StrToIFXStr(Section),StrToIFXStr(Key),ValueType);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadBool(const Section, Key: String; Default: Boolean = False): Boolean;
begin
Result := ReadBool(StrToIFXStr(Section),StrToIFXStr(Key),Default);
end; 

//------------------------------------------------------------------------------

Function TIniFileEx.ReadInt8(const Section, Key: String; Default: Int8 = 0): Int8;
begin
Result := ReadInt8(StrToIFXStr(Section),StrToIFXStr(Key),Default);
end; 

//------------------------------------------------------------------------------

Function TIniFileEx.ReadUInt8(const Section, Key: String; Default: UInt8 = 0): UInt8;
begin
Result := ReadUInt8(StrToIFXStr(Section),StrToIFXStr(Key),Default);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadInt16(const Section, Key: String; Default: Int16 = 0): Int16;
begin
Result := ReadInt16(StrToIFXStr(Section),StrToIFXStr(Key),Default);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadUInt16(const Section, Key: String; Default: UInt16 = 0): UInt16;
begin
Result := ReadUInt16(StrToIFXStr(Section),StrToIFXStr(Key),Default);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadInt32(const Section, Key: String; Default: Int32 = 0): Int32;
begin
Result := ReadInt32(StrToIFXStr(Section),StrToIFXStr(Key),Default);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadUInt32(const Section, Key: String; Default: UInt32 = 0): UInt32;
begin
Result := ReadUInt32(StrToIFXStr(Section),StrToIFXStr(Key),Default);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadInt64(const Section, Key: String; Default: Int64 = 0): Int64;
begin
Result := ReadInt64(StrToIFXStr(Section),StrToIFXStr(Key),Default);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadUInt64(const Section, Key: String; Default: UInt64 = 0): UInt64;
begin
Result := ReadUInt64(StrToIFXStr(Section),StrToIFXStr(Key),Default);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadInteger(const Section, Key: String; Default: Integer = 0): Integer;
begin
Result := ReadInteger(StrToIFXStr(Section),StrToIFXStr(Key),Default);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadFloat32(const Section, Key: String; Default: Float32 = 0.0): Float32;
begin
Result := ReadFloat32(StrToIFXStr(Section),StrToIFXStr(Key),Default);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadFloat64(const Section, Key: String; Default: Float64 = 0.0): Float64;
begin
Result := ReadFloat64(StrToIFXStr(Section),StrToIFXStr(Key),Default);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadFloat(const Section, Key: String; Default: Double = 0.0): Double;
begin
Result := ReadFloat(StrToIFXStr(Section),StrToIFXStr(Key),Default);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadTime(const Section, Key: String; Default: TDateTime = 0.0): TDateTime;
begin
Result := ReadTime(StrToIFXStr(Section),StrToIFXStr(Key),Default);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadDate(const Section, Key: String; Default: TDateTime = 0.0): TDateTime;
begin
Result := ReadDate(StrToIFXStr(Section),StrToIFXStr(Key),Default);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadDateTime(const Section, Key: String; Default: TDateTime = 0.0): TDateTime;
begin
Result := ReadDateTime(StrToIFXStr(Section),StrToIFXStr(Key),Default);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadString(const Section, Key: String; Default: String = ''): String;
begin
Result := ReadString(StrToIFXStr(Section),StrToIFXStr(Key),Default);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadBinarySize(const Section, Key: String): TMemSize;
begin
Result := ReadBinarySize(StrToIFXStr(Section),StrToIFXStr(Key));
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadBinaryBuffer(const Section, Key: String; var Buffer; Size: TMemSize): TMemSize;
begin
Result := ReadBinaryBuffer(StrToIFXStr(Section),StrToIFXStr(Key),Buffer,Size);
end;
 
//------------------------------------------------------------------------------

Function TIniFileEx.ReadBinaryMemory(const Section, Key: String; out Ptr: Pointer; MakeCopy: Boolean = False): TMemSize;
begin
Result := ReadBinaryMemory(StrToIFXStr(Section),StrToIFXStr(Key),Ptr,MakeCopy);
end;
 
//------------------------------------------------------------------------------

Function TIniFileEx.ReadBinaryMemory(const Section, Key: String; Ptr: Pointer; Size: TMemSize): TMemSize;
begin
Result := ReadBinaryMemory(StrToIFXStr(Section),StrToIFXStr(Key),Ptr,Size);
end;

//------------------------------------------------------------------------------

Function TIniFileEx.ReadBinaryStream(const Section, Key: String; Stream: TStream; ClearStream: Boolean = False): Int64;
begin
Result := ReadBinaryStream(StrToIFXStr(Section),StrToIFXStr(Key),Stream,ClearStream);
end;

{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF AllowLowLevelAccess}

Function TIniFileEx.GetSectionNode(const Section: TIFXString): TIFXSectionNode;
begin
If not fFileNode.FindSection(Section,Result) then
  Result := nil;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetKeyNode(const Section, Key: TIFXString): TIFXKeyNode;
begin
If not fFileNode.FindKey(Section,Key,Result) then
  Result := nil;
end;

//------------------------------------------------------------------------------

Function TIniFileEx.GetValueString(const Section, Key: TIFXString): TIFXString;
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  Result := KeyNode.ValueStr
else
  raise Exception.CreateFmt('TIniFileEx.GetValueString: Key (%s:%s) not found',[Section,Key]);
end;

//------------------------------------------------------------------------------

procedure TIniFileEx.SetValueString(const Section, Key, ValueStr: TIFXString);
var
  KeyNode:  TIFXKeyNode;
begin
If fFileNode.FindKey(Section,Key,KeyNode) then
  KeyNode.ValueStr := ValueStr
else
  raise Exception.CreateFmt('TIniFileEx.SetValueString: Key (%s:%s) not found',[Section,Key]);
end;

{$ENDIF}
end.

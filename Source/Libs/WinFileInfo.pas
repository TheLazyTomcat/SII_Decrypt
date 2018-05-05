{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  WinFileInfo

  ©František Milt 2017-07-17

  Version 1.0.6

  Dependencies:
    AuxTypes - github.com/ncs-sniper/Lib.AuxTypes
    StrRect  - github.com/ncs-sniper/Lib.StrRect

===============================================================================}
unit WinFileInfo;

{$IF not(defined(MSWINDOWS) or defined(WINDOWS))}
  {$MESSAGE FATAL 'Unsupported operating system.'}
{$IFEND}

{$IFDEF FPC}
  {
    Activate symbol BARE_FPC if you want to compile this unit outside of
    Lazarus.
    Non-unicode strings are assumed to be ANSI-encoded when defined, otherwise
    they are assumed to be UTF8-encoded.

    Not defined by default.
  }
  {.$DEFINE BARE_FPC}
  {$MODE ObjFPC}{$H+}
  {$DEFINE FPC_DisableWarns}
  {$MACRO ON}
{$ENDIF}

{$IF Defined(FPC) and not Defined(Unicode) and (FPC_FULLVERSION < 20701) and not Defined(BARE_FPC)}
  {$DEFINE UTF8Wrappers}
{$ELSE}
  {$UNDEF UTF8Wrappers}
{$IFEND}

interface

uses
  Windows, SysUtils, AuxTypes;

const
  // Loading strategy flags.
  // Loading strategy affects what file information will be loaded and
  // decoded/parsed.
  WFI_LS_LoadSize                   = $00000001;
  WFI_LS_LoadTime                   = $00000002;
  WFI_LS_LoadAttributes             = $00000004;
  WFI_LS_DecodeAttributes           = $00000008;
  WFI_LS_LoadVersionInfo            = $00000010;
  WFI_LS_ParseVersionInfo           = $00000020;
  WFI_LS_LoadFixedFileInfo          = $00000040;
  WFI_LS_DecodeFixedFileInfo        = $00000080;
  WFI_LS_VerInfoDefaultKeys         = $00000100;
  WFI_LS_VerInfoExtractTranslations = $00000200;

  // Combined loading strategy flags.
  WFI_LS_LoadNone            = $00000000;
  WFI_LS_BasicInfo           = $0000000F;
  WFI_LS_FullInfo            = $000000FF;
  WFI_LS_All                 = $FFFFFFFF;
  WFI_LS_VersionInfo         = WFI_LS_LoadVersionInfo or
                               WFI_LS_ParseVersionInfo or
                               WFI_LS_VerInfoExtractTranslations;
  WFI_LS_VersionInfoAndFFI   = WFI_LS_VersionInfo or
                               WFI_LS_LoadFixedFileInfo or
                               WFI_LS_DecodeFixedFileInfo;  

  // File attributes flags
  INVALID_FILE_ATTRIBUTES = DWORD(-1); 

  FILE_ATTRIBUTE_ARCHIVE             = $20;
  FILE_ATTRIBUTE_COMPRESSED          = $800;
  FILE_ATTRIBUTE_DEVICE              = $40;
  FILE_ATTRIBUTE_DIRECTORY           = $10;
  FILE_ATTRIBUTE_ENCRYPTED           = $4000;
  FILE_ATTRIBUTE_HIDDEN              = $2;
  FILE_ATTRIBUTE_INTEGRITY_STREAM    = $8000;
  FILE_ATTRIBUTE_NORMAL              = $80;
  FILE_ATTRIBUTE_NOT_CONTENT_INDEXED = $2000;
  FILE_ATTRIBUTE_NO_SCRUB_DATA       = $20000;
  FILE_ATTRIBUTE_OFFLINE             = $1000;
  FILE_ATTRIBUTE_READONLY            = $1;
  FILE_ATTRIBUTE_REPARSE_POINT       = $400;
  FILE_ATTRIBUTE_SPARSE_FILE         = $200;
  FILE_ATTRIBUTE_SYSTEM              = $4;
  FILE_ATTRIBUTE_TEMPORARY           = $100;
  FILE_ATTRIBUTE_VIRTUAL             = $10000;

  // Flags for field TVSFixedFileInfo.dwFileFlags
  VS_FF_DEBUG        = $00000001;
  VS_FF_INFOINFERRED = $00000010;
  VS_FF_PATCHED      = $00000004;
  VS_FF_PRERELEASE   = $00000002;
  VS_FF_PRIVATEBUILD = $00000008;
  VS_FF_SPECIALBUILD = $00000020;

  // Flags for field TVSFixedFileInfo.dwFileOS
  VOS_DOS           = $00010000;
  VOS_NT            = $00040000;
  VOS__WINDOWS16    = $00000001;
  VOS__WINDOWS32    = $00000004;
  VOS_OS216         = $00020000;
  VOS_OS232         = $00030000;
  VOS__PM16         = $00000002;
  VOS__PM32         = $00000003;
  VOS_UNKNOWN       = $00000000;
  VOS_DOS_WINDOWS16 = $00010001;
  VOS_DOS_WINDOWS32 = $00010004;
  VOS_NT_WINDOWS32  = $00040004;
  VOS_OS216_PM16    = $00020002;
  VOS_OS232_PM32    = $00030003;

  // Flags for field TVSFixedFileInfo.dwFileType
  VFT_APP        = $00000001;
  VFT_DLL        = $00000002;
  VFT_DRV        = $00000003;
  VFT_FONT       = $00000004;
  VFT_STATIC_LIB = $00000007;
  VFT_UNKNOWN    = $00000000;
  VFT_VXD        = $00000005;

  // Flags for field TVSFixedFileInfo.dwFileSubtype when
  // TVSFixedFileInfo.dwFileType is set to VFT_DRV
  VFT2_DRV_COMM              = $0000000A;
  VFT2_DRV_DISPLAY           = $00000004;
  VFT2_DRV_INSTALLABLE       = $00000008;
  VFT2_DRV_KEYBOARD          = $00000002;
  VFT2_DRV_LANGUAGE          = $00000003;
  VFT2_DRV_MOUSE             = $00000005;
  VFT2_DRV_NETWORK           = $00000006;
  VFT2_DRV_PRINTER           = $00000001;
  VFT2_DRV_SOUND             = $00000009;
  VFT2_DRV_SYSTEM            = $00000007;
  VFT2_DRV_VERSIONED_PRINTER = $0000000C;
  VFT2_UNKNOWN               = $00000000;

  // Flags for field TVSFixedFileInfo.dwFileSubtype when
  // TVSFixedFileInfo.dwFileType is set to VFT_FONT
  VFT2_FONT_RASTER   = $00000001;
  VFT2_FONT_TRUETYPE = $00000003;
  VFT2_FONT_VECTOR   = $00000002;


{==============================================================================}
{   Auxiliary structures                                                       }
{--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --}
{ Following structures are used to store information about requested file in   }
{ a more user-friendly and better accessible way.                              }
{==============================================================================}

type
  TFileAttributesDecoded = record
    Archive:            Boolean;
    Compressed:         Boolean;
    Device:             Boolean;
    Directory:          Boolean;
    Encrypted:          Boolean;
    Hidden:             Boolean;
    IntegrityStream:    Boolean;
    Normal:             Boolean;
    NotContentIndexed:  Boolean;
    NoScrubData:        Boolean;
    Offline:            Boolean;
    ReadOnly:           Boolean;
    ReparsePoint:       Boolean;
    SparseFile:         Boolean;
    System:             Boolean;
    Temporary:          Boolean;
    Virtual:            Boolean;
  end;

//------------------------------------------------------------------------------
// Group of structures used to store decoded information from fixed file info
// part of version information resource.

  TFixedFileInfo_VersionMembers = record
    Major:    UInt16;
    Minor:    UInt16;
    Release:  UInt16;
    Build:    UInt16;
  end;  

  TFixedFileInfo_FileFlags = record
    Debug:        Boolean;
    InfoInferred: Boolean;
    Patched:      Boolean;
    Prerelease:   Boolean;
    PrivateBuild: Boolean;
    SpecialBuild: Boolean;
  end;

  TFixedFileInfoDecoded = record
    FileVersionFull:        Int64;
    FileVersionMembers:     TFixedFileInfo_VersionMembers;
    FileVersionStr:         String;
    ProductVersionFull:     Int64;
    ProductVersionMembers:  TFixedFileInfo_VersionMembers;
    ProductVersionStr:      String;
    FileFlags:              TFixedFileInfo_FileFlags;
    FileOSStr:              String;
    FileTypeStr:            String;
    FileSubTypeStr:         String;
    FileDateFull:           Int64;
  end;

//------------------------------------------------------------------------------
// Following structures are used to store fully parsed information from
// version information structure.

  TTranslationItem = record
    LanguageName: String;
    LanguageStr:  String;
    case Integer of
      0: (Language:     UInt16;
          CodePage:     UInt16);
      1: (Translation:  UInt32);
  end;

  TStringTableItem = record
    Key:    String;
    Value:  String;
  end;

  TStringTable = record
    Translation:  TTranslationItem;
    Strings:      array of TStringTableItem;
  end;

//------------------------------------------------------------------------------
// Following structures are used to hold partially parsed information from
// version information structure.

  TVersionInfoStruct_String = record
    Address:    Pointer;
    Size:       TMemSize;
    Key:        WideString;
    ValueSize:  TMemSize;
    Value:      Pointer;
  end;

  TVersionInfoStruct_StringTable = record
    Address:  Pointer;
    Size:     TMemSize;
    Key:      WideString;
    Strings:  array of TVersionInfoStruct_String;
  end;

  TVersionInfoStruct_StringFileInfo = record
    Address:      Pointer;
    Size:         TMemSize;
    Key:          WideString;
    StringTables: array of TVersionInfoStruct_StringTable;
  end;

  TVersionInfoStruct_Var = record
    Address:    Pointer;
    Size:       TMemSize;
    Key:        WideString;
    ValueSize:  TMemSize;
    Value:      Pointer;
  end;

  TVersionInfoStruct_VarFileInfo = record
    Address:  Pointer;
    Size:     TMemSize;
    Key:      WideString;
    Vars:     array of TVersionInfoStruct_Var;
  end;

  TVersionInfoStruct = record
    Address:            Pointer;
    Size:               TMemSize;
    Key:                WideString;
    FixedFileInfo:      Pointer;
    FixedFileInfoSize:  TMemSize;
    StringFileInfos:    array of TVersionInfoStruct_StringFileInfo;
    VarFileInfos:       array of TVersionInfoStruct_VarFileInfo;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                        TWinFileInfo class declaration                        }
{------------------------------------------------------------------------------}
{==============================================================================}
  TWinFileInfo = class(TObject)
  private
    fLoadingStrategy:         UInt32;
    fFormatSettings:          TFormatSettings;
    fFileHandle:              THandle;
    fExists:                  Boolean;
    fLongName:                String;
    fShortName:               String;
    fSize:                    UInt64;
    fSizeStr:                 String;
    fCreationTime:            TDateTime;
    fLastAccessTime:          TDateTime;
    fLastWriteTime:           TDateTime;
    fAttributesFlags:         DWord;
    fAttributesStr:           String;
    fAttributesText:          String;
    fAttributesDecoded:       TFileAttributesDecoded;
    fVerInfoSize:             TMemSize;
    fVerInfoData:             Pointer;
    fVersionInfoPresent:      Boolean;
    fVersionInfoFFIPresent:   Boolean;
    fVersionInfoFFI:          TVSFixedFileInfo;
    fVersionInfoFFIDecoded:   TFixedFileInfoDecoded;
    fVersionInfoStringTables: array of TStringTable;
    fVersionInfoParsed:       Boolean;
    fVersionInfoStruct:       TVersionInfoStruct;
    Function GetVersionInfoTranslation(Index: Integer): TTranslationItem;
    Function GetVersionInfoStringTableCount: Integer;
    Function GetVersionInfoStringTable(Index: Integer): TStringTable;
    Function GetVersionInfoKeyCount(Table: Integer): Integer;
    Function GetVersionInfoKey(Table,Index: Integer): String;
    Function GetVersionInfoStringCount(Table: Integer): Integer;
    Function GetVersionInfoString(Table,Index: Integer): TStringTableItem;
    Function GetVersionInfoValue(const Language,Key: String): String;
  protected
    Function LoadingStrategyFlag(Flag: UInt32): Boolean; virtual;
    procedure VersionInfo_LoadStrings; virtual;
    procedure VersionInfo_EnumerateKeys; virtual;
    procedure VersionInfo_ExtractTranslations; virtual;
    procedure VersionInfo_Parse; virtual;
    procedure VersionInfo_LoadTranslations; virtual;
    procedure VersionInfo_LoadFixedFileInfo; virtual;
    procedure LoadVersionInfo; virtual;
    procedure LoadAttributes; virtual;
    procedure LoadTime; virtual;
    procedure LoadSize; virtual;
    Function CheckFileExists: Boolean; virtual;
    procedure Clear; virtual;    
    procedure Initialize(const FileName: String); virtual;
    procedure Finalize; virtual;
  public
    constructor Create(LoadingStrategy: UInt32 = WFI_LS_All); overload;
    constructor Create(const FileName: String; LoadingStrategy: UInt32 = WFI_LS_All); overload;
    destructor Destroy; override;
    procedure Refresh; virtual;
    Function IndexOfVersionInfoStringTable(Translation: DWord): Integer; virtual;
    Function IndexOfVersionInfoString(Table: Integer; const Key: String): Integer; virtual;
    Function CreateReport(DoRefresh: Boolean = False): String; virtual;
    property LoadingStrategy: UInt32 read fLoadingStrategy write fLoadingStrategy;
    property FormatSettings: TFormatSettings read fFormatSettings write fFormatSettings;
    property FileHandle: THandle read fFileHandle;
    property Exists: Boolean read fExists;
    property Name: String read fLongName;
    property LongName: String read fLongName;
    property ShortName: String read fShortName;
    property Size: UInt64 read fSize;
    property SizeStr: String read fSizeStr;
    property CreationTime: TDateTime read fCreationTime;
    property LastAccessTime: TDateTime read fLastAccessTime;
    property LastWriteTime: TDateTime read fLastWriteTime;
    property AttributesFlags: DWord read fAttributesFlags;
    property AttributesStr: String read fAttributesStr;
    property AttributesText: String read fAttributesText;
    property AttributesDecoded: TFileAttributesDecoded read fAttributesDecoded;
    property VerInfoSize: PtrUInt read fVerInfoSize;
    property VerInfoData: Pointer read fVerInfoData;
    property VersionInfoPresent: Boolean read fVersionInfoPresent;
    property VersionInfoFixedFileInfoPresent: Boolean read fVersionInfoFFIPresent;
    property VersionInfoFixedFileInfo: TVSFixedFileInfo read fVersionInfoFFI;
    property VersionInfoFixedFileInfoDecoded: TFixedFileInfoDecoded read fVersionInfoFFIDecoded;
    property VersionInfoTranslationCount: Integer read GetVersionInfoStringTableCount;
    property VersionInfoTranslations[Index: Integer]: TTranslationItem read GetVersionInfoTranslation;
    property VersionInfoStringTableCount: Integer read GetVersionInfoStringTableCount;
    property VersionInfoStringTables[Index: Integer]: TStringTable read GetVersionInfoStringTable;
    property VersionInfoKeyCount[Table: Integer]: Integer read GetVersionInfoKeyCount;
    property VersionInfoKeys[Table,Index: Integer]: String read GetVersionInfoKey;
    property VersionInfoStringCount[Table: Integer]: Integer read GetVersionInfoStringCount;
    property VersionInfoString[Table,Index: Integer]: TStringTableItem read GetVersionInfoString;
    property VersionInfoValues[const Language,Key: String]: String read GetVersionInfoValue; default;
    property VersionInfoParsed: Boolean read fVersionInfoParsed;
    property VersionInfoStruct: TVersionInfoStruct read fVersionInfoStruct;
  end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                         Public functions declaration                         }
{------------------------------------------------------------------------------}
{==============================================================================}

Function SizeToStr(Size: UInt64): String;

implementation

uses
  Classes, StrRect{$IFDEF UTF8Wrappers}, LazFileUtils{$ENDIF};

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W4055:={$WARN 4055 OFF}} // Conversion between ordinals and pointers is not portable
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
  {$DEFINE W5057:={$WARN 5057 OFF}} // Local variable "$1" does not seem to be initialized
{$ENDIF}

{$IF not Declared(GetFileSizeEx)}
Function GetFileSizeEx(hFile: THandle; lpFileSize: PInt64): BOOL; stdcall; external 'kernel32.dll';
{$IFEND}

type
  TAttributeString = record
    Flag: DWord;
    Text: String;
    Str:  String;
  end;

  TFlagText = record
    Flag: DWord;
    Text: String;
  end;

// Tables used to convert some binary information (mainly flags) to a textual
// representation.
const
  AttributesStrings: array[0..16] of TAttributeString = (
    (Flag: FILE_ATTRIBUTE_ARCHIVE;             Text: 'Archive';             Str: 'A'),
    (Flag: FILE_ATTRIBUTE_COMPRESSED;          Text: 'Compressed';          Str: 'C'),
    (Flag: FILE_ATTRIBUTE_DEVICE;              Text: 'Device';              Str: ''),
    (Flag: FILE_ATTRIBUTE_DIRECTORY;           Text: 'Directory';           Str: 'D'),
    (Flag: FILE_ATTRIBUTE_ENCRYPTED;           Text: 'Encrypted';           Str: 'E'),
    (Flag: FILE_ATTRIBUTE_HIDDEN;              Text: 'Hidden';              Str: 'H'),
    (Flag: FILE_ATTRIBUTE_INTEGRITY_STREAM;    Text: 'Integrity stream';    Str: ''),
    (Flag: FILE_ATTRIBUTE_NORMAL;              Text: 'Normal';              Str: 'N'),
    (Flag: FILE_ATTRIBUTE_NOT_CONTENT_INDEXED; Text: 'Not content indexed'; Str: 'I'),
    (Flag: FILE_ATTRIBUTE_NO_SCRUB_DATA;       Text: 'No scrub data';       Str: ''),
    (Flag: FILE_ATTRIBUTE_OFFLINE;             Text: 'Offline';             Str: 'O'),
    (Flag: FILE_ATTRIBUTE_READONLY;            Text: 'Read only';           Str: 'R'),
    (Flag: FILE_ATTRIBUTE_REPARSE_POINT;       Text: 'Reparse point';       Str: 'L'),
    (Flag: FILE_ATTRIBUTE_SPARSE_FILE;         Text: 'Sparse file';         Str: 'P'),
    (Flag: FILE_ATTRIBUTE_SYSTEM;              Text: 'System';              Str: 'S'),
    (Flag: FILE_ATTRIBUTE_TEMPORARY;           Text: 'Temporary';           Str: 'T'),
    (Flag: FILE_ATTRIBUTE_VIRTUAL;             Text: 'Virtual';             Str: ''));

  FFI_FileOSStrings: array[0..13] of TFlagText = (
    (Flag: VOS_DOS;           Text: 'MS-DOS'),
    (Flag: VOS_NT;            Text: 'Windows NT'),
    (Flag: VOS__WINDOWS16;    Text: '16-bit Windows'),
    (Flag: VOS__WINDOWS32;    Text: '32-bit Windows'),
    (Flag: VOS_OS216;         Text: '16-bit OS/2'),
    (Flag: VOS_OS232;         Text: '32-bit OS/2'),
    (Flag: VOS__PM16;         Text: '16-bit Presentation Manager'),
    (Flag: VOS__PM32;         Text: '32-bit Presentation Manager'),
    (Flag: VOS_UNKNOWN;       Text: 'Unknown'),
    (Flag: VOS_DOS_WINDOWS16; Text: '16-bit Windows running on MS-DOS'),
    (Flag: VOS_DOS_WINDOWS32; Text: '32-bit Windows running on MS-DOS'),
    (Flag: VOS_NT_WINDOWS32;  Text: 'Windows NT'),
    (Flag: VOS_OS216_PM16;    Text: '16-bit Presentation Manager running on 16-bit OS/2'),
    (Flag: VOS_OS232_PM32;    Text: '32-bit Presentation Manager running on 32-bit OS/2'));

  FFI_FileTypeStrings: array[0..6] of TFlagText = (
    (Flag: VFT_APP;        Text: 'Application'),
    (Flag: VFT_DLL;        Text: 'DLL'),
    (Flag: VFT_DRV;        Text: 'Device driver'),
    (Flag: VFT_FONT;       Text: 'Font'),
    (Flag: VFT_STATIC_LIB; Text: 'Static-link library'),
    (Flag: VFT_UNKNOWN;    Text: 'Unknown'),
    (Flag: VFT_VXD;        Text: 'Virtual device'));

  FFI_FileSubtypeStrings_DRV: array[0..11] of TFlagText = (
    (Flag: VFT2_DRV_COMM;              Text: 'Communications driver'),
    (Flag: VFT2_DRV_DISPLAY;           Text: 'Display driver'),
    (Flag: VFT2_DRV_INSTALLABLE;       Text: 'Installable driver'),
    (Flag: VFT2_DRV_KEYBOARD;          Text: 'Keyboard driver'),
    (Flag: VFT2_DRV_LANGUAGE;          Text: 'Language driver'),
    (Flag: VFT2_DRV_MOUSE;             Text: 'Mouse driver'),
    (Flag: VFT2_DRV_NETWORK;           Text: 'Network driver'),
    (Flag: VFT2_DRV_PRINTER;           Text: 'Printer driver'),
    (Flag: VFT2_DRV_SOUND;             Text: 'Sound driver'),
    (Flag: VFT2_DRV_SYSTEM;            Text: 'System driver'),
    (Flag: VFT2_DRV_VERSIONED_PRINTER; Text: 'Versioned printer driver'),
    (Flag: VFT2_UNKNOWN;               Text: 'Unknown'));

  FFI_FileSubtypeStrings_FONT: array[0..3] of TFlagText = (
    (Flag: VFT2_FONT_RASTER;   Text: 'Raster font'),
    (Flag: VFT2_FONT_TRUETYPE; Text: 'TrueType font'),
    (Flag: VFT2_FONT_VECTOR;   Text: 'Vector font'),
    (Flag: VFT2_UNKNOWN;       Text: 'Unknown'));

  VerInfo_DefaultKeys: array[0..11] of String = (
    'Comments','CompanyName','FileDescription','FileVersion','InternalName',
    'LegalCopyright','LegalTrademarks','OriginalFilename','ProductName',
    'ProductVersion','PrivateBuild','SpecialBuild');

{==============================================================================}
{------------------------------------------------------------------------------}
{                              Auxiliary functions                             }
{------------------------------------------------------------------------------}
{==============================================================================}

{$IF not Declared(CP_THREAD_ACP)}
const
  CP_THREAD_ACP = 3;
{$IFEND}

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
Function WideToString(const WStr: WideString; AnsiCodePage: UINT = CP_THREAD_ACP): String;
begin
{$IFDEF Unicode}
Result := WStr;
{$ELSE}
{$IFDEF FPC}
Result := UTF8Encode(WStr);
{$ELSE}
SetLength(Result,WideCharToMultiByte(AnsiCodePage,0,PWideChar(WStr),Length(WStr),nil,0,nil,nil));
WideCharToMultiByte(AnsiCodePage,0,PWideChar(WStr),Length(WStr),PAnsiChar(Result),Length(Result) * SizeOf(AnsiChar),nil,nil);
// A wrong codepage might be stored, try translation with default cp
If (AnsiCodePage <> CP_THREAD_ACP) and (Length(Result) <= 0) and (Length(WStr) > 0) then
  Result := WideToString(WStr);
{$ENDIF}
{$ENDIF}
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{==============================================================================}
{------------------------------------------------------------------------------}
{                        Public functions implementation                       }
{------------------------------------------------------------------------------}
{==============================================================================}

Function SizeToStr(Size: UInt64): String;
const
  BinaryPrefix: array[0..8] of String = ('','Ki','Mi','Gi','Ti','Pi','Ei','Zi','Yi');
  PrefixShift = 10;
var
  Offset: Integer;
  Deci:   Integer;
  Num:    Double;
begin
Offset := -1;
repeat
  Inc(Offset);
until ((Size shr (PrefixShift * Succ(Offset))) = 0) or (Offset >= 8);
case Size shr (PrefixShift * Offset) of
   1..9:  Deci := 2;
  10..99: Deci := 1;
else
  Deci := 0;
end;
Num := (Size shr (PrefixShift * Offset));
If Offset > 0 then
  Num := Num + ((Size shr (PrefixShift * Pred(Offset))) and 1023) / 1024
else
  Deci := 0;
Result := Format('%.*f %sB',[Deci,Num,BinaryPrefix[Offset]])
end;

{==============================================================================}
{------------------------------------------------------------------------------}
{                       TWinFileInfo class implementation                      }
{------------------------------------------------------------------------------}
{==============================================================================}

{------------------------------------------------------------------------------}
{   TWinFileInfo - private methods                                             }
{------------------------------------------------------------------------------}

Function TWinFileInfo.GetVersionInfoTranslation(Index: Integer): TTranslationItem;
begin
Result := GetVersionInfoStringTable(Index).Translation;
end;

//------------------------------------------------------------------------------

Function TWinFileInfo.GetVersionInfoStringTableCount: Integer;
begin
Result := Length(fVersionInfoStringTables);
end;

//------------------------------------------------------------------------------

Function TWinFileInfo.GetVersionInfoStringTable(Index: Integer): TStringTable;
begin
If (Index >= Low(fVersionInfoStringTables)) and (Index <= High(fVersionInfoStringTables)) then
  Result := fVersionInfoStringTables[Index]
else
  raise Exception.CreateFmt('TWinFileInfo.GetVersionInfoStringTables: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

Function TWinFileInfo.GetVersionInfoKeyCount(Table: Integer): Integer;
begin
Result := Length(GetVersionInfoStringTable(Table).Strings);
end;

//------------------------------------------------------------------------------

Function TWinFileInfo.GetVersionInfoKey(Table,Index: Integer): String;
begin
with GetVersionInfoStringTable(Table) do
  begin
    If (Index >= Low(Strings)) and (Index <= High(Strings)) then
      Result := Strings[Index].Key
    else
      raise Exception.CreateFmt('TWinFileInfo.GetVersionInfoKeys: Index (%d) out of bounds.',[Index]);
  end;
end;

//------------------------------------------------------------------------------

Function TWinFileInfo.GetVersionInfoStringCount(Table: Integer): Integer;
begin
Result := Length(GetVersionInfoStringTable(Table).Strings);
end;

//------------------------------------------------------------------------------

Function TWinFileInfo.GetVersionInfoString(Table,Index: Integer): TStringTableItem;
begin
with GetVersionInfoStringTable(Table) do
  begin
    If (Index >= Low(Strings)) and (Index <= High(Strings)) then
      Result := Strings[Index]
    else
      raise Exception.CreateFmt('TWinFileInfo.GetVersionInfoStrings: Index (%d) out of bounds.',[Index]);
  end;
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5057{$ENDIF}
Function TWinFileInfo.GetVersionInfoValue(const Language,Key: String): String;
var
  StrPtr:   Pointer;
  StrSize:  UInt32;
begin
Result := '';
If fVersionInfoPresent and (Language <> '') and (Key <> '') then
  If VerQueryValue(fVerInfoData,PChar(Format('\StringFileInfo\%s\%s',[Language,Key])),StrPtr,StrSize) then
    Result := WinToStr(PChar(StrPtr));
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{------------------------------------------------------------------------------}
{   TWinFileInfo - protected methods                                           }
{------------------------------------------------------------------------------}

Function TWinFileInfo.LoadingStrategyFlag(Flag: UInt32): Boolean;
begin
Result := (fLoadingStrategy and Flag) <> 0;
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5057{$ENDIF}
procedure TWinFileInfo.VersionInfo_LoadStrings;
var
  Table:    Integer;
  i,j:      Integer;
  StrPtr:   Pointer;
  StrSize:  UInt32;
begin
For Table := Low(fVersionInfoStringTables) to High(fVersionInfoStringTables) do
  with fVersionInfoStringTables[Table] do
    begin
      For i := High(Strings) downto Low(Strings) do
        begin
          If VerQueryValue(fVerInfoData,PChar(Format('\StringFileInfo\%s\%s',[Translation.LanguageStr,StrToWin(Strings[i].Key)])),StrPtr,StrSize) then
            Strings[i].Value := WinToStr(PChar(StrPtr))
          else
            begin
              For j := i to Pred(High(Strings)) do
                Strings[j] := Strings[j + 1];
              SetLength(Strings,Length(Strings) - 1);
            end;
        end;
    end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

procedure TWinFileInfo.VersionInfo_EnumerateKeys;
var
  Table:  Integer;
  i,j,k:  Integer;
begin
For i := Low(fVersionInfoStruct.StringFileInfos) to High(fVersionInfoStruct.StringFileInfos) do
  If AnsiSameText(WideToString(fVersionInfoStruct.StringFileInfos[i].Key),'StringFileInfo') then
    For Table := Low(fVersionInfoStringTables) to High(fVersionInfoStringTables) do
      with fVersionInfoStruct.StringFileInfos[i] do
        begin
          For j := Low(StringTables) to High(StringTables) do
            If AnsiSameText(WideToString(StringTables[j].Key),fVersionInfoStringTables[Table].Translation.LanguageStr) then
              begin
                SetLength(fVersionInfoStringTables[Table].Strings,Length(StringTables[j].Strings));
                For k := Low(StringTables[j].Strings) to High(StringTables[j].Strings) do
                  fVersionInfoStringTables[Table].Strings[k].Key := WideToString(StringTables[j].Strings[k].Key,fVersionInfoStringTables[Table].Translation.CodePage);
              end;
          If (Length(fVersionInfoStringTables[Table].Strings) <= 0) and LoadingStrategyFlag(WFI_LS_VerInfoDefaultKeys) then
            begin
              SetLength(fVersionInfoStringTables[Table].Strings,Length(VerInfo_DefaultKeys));
              For j := Low(VerInfo_DefaultKeys) to High(VerInfo_DefaultKeys) do
                fVersionInfoStringTables[Table].Strings[j].Key := VerInfo_DefaultKeys[j];
            end;
        end;
end;

//------------------------------------------------------------------------------

procedure TWinFileInfo.VersionInfo_ExtractTranslations;
var
  i,Table:  Integer;

  Function TranslationIsListed(const LanguageStr: String): Boolean;
  var
    ii: Integer;
  begin
    Result := False;
    For ii := Low(fVersionInfoStringTables) to High(fVersionInfoStringTables) do
      If AnsiSameText(fVersionInfoStringTables[ii].Translation.LanguageStr,LanguageStr) then
        begin
          Result := True;
          Break;
        end;
  end;

begin
For i := Low(fVersionInfoStruct.StringFileInfos) to High(fVersionInfoStruct.StringFileInfos) do
  If AnsiSameText(WideToString(fVersionInfoStruct.StringFileInfos[i].Key),'StringFileInfo') then
    For Table := Low(fVersionInfoStruct.StringFileInfos[i].StringTables) to High(fVersionInfoStruct.StringFileInfos[i].StringTables) do
      If not TranslationIsListed(WideToString(fVersionInfoStruct.StringFileInfos[i].StringTables[Table].Key)) then
        begin
          SetLength(fVersionInfoStringTables,Length(fVersionInfoStringTables) + 1);
          with fVersionInfoStringTables[High(fVersionInfoStringTables)].Translation do
            begin
              LanguageStr := WideToString(fVersionInfoStruct.StringFileInfos[i].StringTables[Table].Key);
              Language := StrToIntDef('$' + Copy(LanguageStr,1,4),0);
              CodePage := StrToIntDef('$' + Copy(LanguageStr,5,4),0);
              SetLength(LanguageName,256);
              SetLength(LanguageName,VerLanguageName(Translation,PChar(LanguageName),Length(LanguageName)));
              LanguageName := WinToStr(LanguageName);
            end;
        end;
end;

//------------------------------------------------------------------------------

procedure TWinFileInfo.VersionInfo_Parse;
type
  PVIS_Base = ^TVIS_Base;
  TVIS_Base = record
    Address:  Pointer;
    Size:     TMemSize;
    Key:      WideString;
  end;
var
  CurrentAddress: Pointer;
  TempBlock:      TVIS_Base;

//--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

  Function Align32bit(Ptr: Pointer): Pointer;
  begin
  {$IFDEF FPCDWM}{$PUSH}W4055{$ENDIF}
    If ((PtrUInt(Ptr) and $3) <> 0) then
      Result := Pointer((PtrUInt(Ptr) and not PtrUInt($3)) + 4)
    else
      Result := Ptr;
  {$IFDEF FPCDWM}{$POP}{$ENDIF}
  end;

//--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

  procedure ParseBlock(var Ptr: Pointer; BlockBase: Pointer);
  begin
    PVIS_Base(BlockBase)^.Address := Ptr;
    PVIS_Base(BlockBase)^.Size := PUInt16(PVIS_Base(BlockBase)^.Address)^;
  {$IFDEF FPCDWM}{$PUSH}W4055{$ENDIF}
    PVIS_Base(BlockBase)^.Key := PWideChar(PtrUInt(PVIS_Base(BlockBase)^.Address) + 6);
    Ptr := Align32bit(Pointer(PtrUInt(PVIS_Base(BlockBase)^.Address) + 6 + PtrUInt((Length(PVIS_Base(BlockBase)^.Key) + 1) * 2)));
  {$IFDEF FPCDWM}{$POP}{$ENDIF}
  end;

//--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

  Function CheckPointer(var Ptr: Pointer; BlockBase: Pointer): Boolean;
  begin
  {$IFDEF FPCDWM}{$PUSH}W4055{$ENDIF}
    Result := (PtrUInt(Ptr) >= PtrUInt(PVIS_Base(BlockBase)^.Address)) and
              (PtrUInt(Ptr) < (PtrUInt(PVIS_Base(BlockBase)^.Address) + PVIS_Base(BlockBase)^.Size));
  {$IFDEF FPCDWM}{$POP}{$ENDIF}
  end;

//--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

begin
If (fVerInfoSize >= 6) and (fVerInfoSize >= PUInt16(fVerInfoData)^) then
  try
    CurrentAddress := fVerInfoData;
    ParseBlock(CurrentAddress,@fVersionInfoStruct);
  {$IFDEF FPCDWM}{$PUSH}W4055{$ENDIF}
    fVersionInfoStruct.FixedFileInfoSize := PUInt16(PtrUInt(fVersionInfoStruct.Address) + 2)^;
    fVersionInfoStruct.FixedFileInfo := CurrentAddress;
    CurrentAddress := Align32bit(Pointer(PtrUInt(CurrentAddress) + fVersionInfoStruct.FixedFileInfoSize));
  {$IFDEF FPCDWM}{$POP}{$ENDIF}
    while CheckPointer(CurrentAddress,@fVersionInfoStruct) do
      begin
        ParseBlock(CurrentAddress,@TempBlock);
        If AnsiSameText(WideToString(TempBlock.Key),'StringFileInfo') then
          begin
            SetLength(fVersionInfoStruct.StringFileInfos,Length(fVersionInfoStruct.StringFileInfos) + 1);
            with fVersionInfoStruct.StringFileInfos[High(fVersionInfoStruct.StringFileInfos)] do
              begin
                Address := TempBlock.Address;
                Size := TempBlock.Size;
                Key := TempBlock.Key;
                while CheckPointer(CurrentAddress,@fVersionInfoStruct.StringFileInfos[High(fVersionInfoStruct.StringFileInfos)]) do
                  begin
                    SetLength(StringTables,Length(StringTables) + 1);
                    ParseBlock(CurrentAddress,@StringTables[High(StringTables)]);
                    while CheckPointer(CurrentAddress,@StringTables[High(StringTables)]) do
                      with StringTables[High(StringTables)] do
                        begin
                          SetLength(Strings,Length(Strings) + 1);
                          ParseBlock(CurrentAddress,@Strings[High(Strings)]);
                        {$IFDEF FPCDWM}{$PUSH}W4055{$ENDIF}
                          Strings[High(Strings)].ValueSize := PUInt16(PtrUInt(Strings[High(Strings)].Address) + 2)^;
                          Strings[High(Strings)].Value := CurrentAddress;
                          CurrentAddress := Align32bit(Pointer(PtrUInt(Strings[High(Strings)].Address) + Strings[High(Strings)].Size));
                        {$IFDEF FPCDWM}{$POP}{$ENDIF}
                        end;
                  end;
              end
          end
        else If AnsiSameText(WideToString(TempBlock.Key),'VarFileInfo') then
          begin
            SetLength(fVersionInfoStruct.VarFileInfos,Length(fVersionInfoStruct.VarFileInfos) + 1);
            with fVersionInfoStruct.VarFileInfos[High(fVersionInfoStruct.VarFileInfos)] do
              begin
                Address := TempBlock.Address;
                Size := TempBlock.Size;
                Key := TempBlock.Key;
                while CheckPointer(CurrentAddress,@fVersionInfoStruct.VarFileInfos[High(fVersionInfoStruct.VarFileInfos)]) do
                  begin
                    SetLength(Vars,Length(Vars) + 1);
                    ParseBlock(CurrentAddress,@Vars[High(Vars)]);
                  {$IFDEF FPCDWM}{$PUSH}W4055{$ENDIF}
                    Vars[High(Vars)].ValueSize := PUInt16(PtrUInt(Vars[High(Vars)].Address) + 2)^;
                    Vars[High(Vars)].Value := CurrentAddress;
                    CurrentAddress := Align32bit(Pointer(PtrUInt(Vars[High(Vars)].Address) + Vars[High(Vars)].Size));
                  {$IFDEF FPCDWM}{$POP}{$ENDIF}
                  end;
              end;
          end
        else raise Exception.CreateFmt('TWinFileInfo.VersionInfo_Parse: Unknown block (%s).',[TempBlock.Key]);
      end;
    fVersionInfoParsed := True;
  except
    fVersionInfoParsed := False;
    SetLength(fVersionInfoStruct.StringFileInfos,0);
    SetLength(fVersionInfoStruct.VarFileInfos,0);
    fVersionInfoStruct.Key := '';
    FillChar(fVersionInfoStruct,SizeOf(fVersionInfoStruct),0);
  end
else fVersionInfoParsed := False;
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5057{$ENDIF}
procedure TWinFileInfo.VersionInfo_LoadTranslations;
var
  TrsPtr:   Pointer;
  TrsSize:  UInt32;
  i:        Integer;
begin
If VerQueryValue(fVerInfoData,'\VarFileInfo\Translation',TrsPtr,TrsSize) then
  begin
    SetLength(fVersionInfoStringTables,TrsSize div SizeOf(UInt32));
    For i := Low(fVersionInfoStringTables) to High(fVersionInfoStringTables) do
      with fVersionInfoStringTables[i].Translation do
        begin
        {$IFDEF FPCDWM}{$PUSH}W4055{$ENDIF}
          Translation := PUInt32(PtrUInt(TrsPtr) + (UInt32(i) * SizeOf(UInt32)))^;
        {$IFDEF FPCDWM}{$POP}{$ENDIF}
          SetLength(LanguageName,256);
          SetLength(LanguageName,VerLanguageName(Translation,PChar(LanguageName),Length(LanguageName)));
          LanguageName := WinToStr(LanguageName);
          LanguageStr := IntToHex(Language,4) + IntToHex(CodePage,4);
        end;
  end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5057{$ENDIF}
procedure TWinFileInfo.VersionInfo_LoadFixedFileInfo;
var
  FFIPtr:           Pointer;
  FFISize:          UInt32;
  FFIWorkFileFlags: DWord;

//--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

  Function VersionToStr(Low, High: DWord): String;
  begin
    Result := Format('%d.%d.%d.%d',[High shr 16,High and $FFFF,Low shr 16,Low and $FFFF]);
  end;

//--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

  Function GetFlagText(Flag: DWord; Data: array of TFlagText; NotFound: String): String;
  var
    i:  Integer;
  begin
    Result := NotFound;
    For i := Low(Data) to High(Data) do
      If Data[i].Flag = Flag then
        begin
          Result := Data[i].Text;
          Break;
        end;
  end;

//--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

begin
fVersionInfoFFIPresent := VerQueryValue(fVerInfoData,'\',FFIPtr,FFISize);
If fVersionInfoFFIPresent then
  begin
    If FFISize = SizeOf(TVSFixedFileInfo) then
      begin
        fVersionInfoFFI := PVSFixedFileInfo(FFIPtr)^;
        If LoadingStrategyFlag(WFI_LS_DecodeFixedFileInfo) then
          begin
            fVersionInfoFFIDecoded.FileVersionFull := (Int64(fVersionInfoFFI.dwFileVersionMS) shl 32) or fVersionInfoFFI.dwFileVersionLS;
            fVersionInfoFFIDecoded.FileVersionMembers.Major := fVersionInfoFFI.dwFileVersionMS shr 16;
            fVersionInfoFFIDecoded.FileVersionMembers.Minor := fVersionInfoFFI.dwFileVersionMS and $FFFF;
            fVersionInfoFFIDecoded.FileVersionMembers.Release := fVersionInfoFFI.dwFileVersionLS shr 16;
            fVersionInfoFFIDecoded.FileVersionMembers.Build := fVersionInfoFFI.dwFileVersionLS and $FFFF;
            fVersionInfoFFIDecoded.FileVersionStr := VersionToStr(fVersionInfoFFI.dwFileVersionLS,fVersionInfoFFI.dwFileVersionMS);
            fVersionInfoFFIDecoded.ProductVersionFull := (Int64(fVersionInfoFFI.dwProductVersionMS) shl 32) or fVersionInfoFFI.dwProductVersionLS;
            fVersionInfoFFIDecoded.ProductVersionMembers.Major := fVersionInfoFFI.dwProductVersionMS shr 16;
            fVersionInfoFFIDecoded.ProductVersionMembers.Minor := fVersionInfoFFI.dwProductVersionMS and $FFFF;
            fVersionInfoFFIDecoded.ProductVersionMembers.Release := fVersionInfoFFI.dwProductVersionLS shr 16;
            fVersionInfoFFIDecoded.ProductVersionMembers.Build := fVersionInfoFFI.dwProductVersionLS and $FFFF;
            fVersionInfoFFIDecoded.ProductVersionStr := VersionToStr(fVersionInfoFFI.dwProductVersionLS,fVersionInfoFFI.dwProductVersionMS);
            FFIWorkFileFlags := fVersionInfoFFI.dwFileFlags and fVersionInfoFFI.dwFileFlagsMask;
            fVersionInfoFFIDecoded.FileFlags.Debug        := ((FFIWorkFileFlags) and VS_FF_DEBUG) <> 0;
            fVersionInfoFFIDecoded.FileFlags.InfoInferred := ((FFIWorkFileFlags) and VS_FF_INFOINFERRED) <> 0;
            fVersionInfoFFIDecoded.FileFlags.Patched      := ((FFIWorkFileFlags) and VS_FF_PATCHED) <> 0;
            fVersionInfoFFIDecoded.FileFlags.Prerelease   := ((FFIWorkFileFlags) and VS_FF_PRERELEASE) <> 0;
            fVersionInfoFFIDecoded.FileFlags.PrivateBuild := ((FFIWorkFileFlags) and VS_FF_PRIVATEBUILD) <> 0;
            fVersionInfoFFIDecoded.FileFlags.SpecialBuild := ((FFIWorkFileFlags) and VS_FF_SPECIALBUILD) <> 0;
            fVersionInfoFFIDecoded.FileOSStr := GetFlagText(fVersionInfoFFI.dwFileOS,FFI_FileOSStrings,'Unknown');
            fVersionInfoFFIDecoded.FileTypeStr := GetFlagText(fVersionInfoFFI.dwFileType,FFI_FileTypeStrings,'Unknown');
            case fVersionInfoFFI.dwFileType of
              VFT_DRV:  fVersionInfoFFIDecoded.FileSubTypeStr := GetFlagText(fVersionInfoFFI.dwFileType,FFI_FIleSubtypeStrings_DRV,'Unknown');
              VFT_FONT: fVersionInfoFFIDecoded.FileSubTypeStr := GetFlagText(fVersionInfoFFI.dwFileType,FFI_FIleSubtypeStrings_FONT,'Unknown');
              VFT_VXD:  fVersionInfoFFIDecoded.FileSubTypeStr := IntToHex(fVersionInfoFFI.dwFileSubtype,8);
            else
              fVersionInfoFFIDecoded.FileSubTypeStr := '';
            end;
            fVersionInfoFFIDecoded.FileDateFull := (Int64(fVersionInfoFFI.dwFileDateMS) shl 32) or fVersionInfoFFI.dwFileDateLS;
          end;
      end
    else raise Exception.CreateFmt('TWinFileInfo.VersionInfo_LoadFixedFileInfo: Wrong size of fixed file information (got %d, expected %d).',[FFISize,SizeOf(TVSFixedFileInfo)]);
  end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5057{$ENDIF}
procedure TWinFileInfo.LoadVersionInfo;
var
  Dummy:  DWord;
begin
fVerInfoSize := GetFileVersionInfoSize(PChar(StrToWin(fLongName)),Dummy);
fVersionInfoPresent := fVerInfoSize > 0;
If fVersionInfoPresent then
  begin
    fVerInfoData := AllocMem(fVerInfoSize);
    If GetFileVersionInfo(PChar(StrToWin(fLongName)),0,fVerInfoSize,fVerInfoData) then
      begin
        If LoadingStrategyFlag(WFI_LS_LoadFixedFileInfo) then
          VersionInfo_LoadFixedFileInfo;
        VersionInfo_LoadTranslations;        
        If LoadingStrategyFlag(WFI_LS_ParseVersionInfo) then
          begin
            VersionInfo_Parse;
            If LoadingStrategyFlag(WFI_LS_VerInfoExtractTranslations) then
              VersionInfo_ExtractTranslations;
            VersionInfo_EnumerateKeys;  
          end;
        VersionInfo_LoadStrings;
      end
    else
      begin
        FreeMem(fVerInfoData,fVerInfoSize);
        fVerInfoData := nil;
        fVerInfoSize := 0;
        fVersionInfoPresent := False;
      end;
  end;
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

procedure TWinFileInfo.LoadAttributes;

  // This function also fills AttributesStr and AttributesText strings
  Function CheckAttribute(AttributeFlag: DWord): Boolean;
  var
    i:  Integer;
  begin
    Result := (fAttributesFlags and AttributeFlag) <> 0;
    If Result then
      For i := Low(AttributesStrings) to High(AttributesStrings) do
        If AttributesStrings[i].Flag = AttributeFlag then
          begin
            fAttributesStr := fAttributesStr + AttributesStrings[i].Str;
            If fAttributesText = '' then fAttributesText := AttributesStrings[i].Text
              else fAttributesText := fAttributesText + ', ' + AttributesStrings[i].Text;
            Break;
          end;
  end;

begin
If LoadingStrategyFlag(WFI_LS_DecodeAttributes) then
  begin
    fAttributesDecoded.Archive           := CheckAttribute(FILE_ATTRIBUTE_ARCHIVE);
    fAttributesDecoded.Compressed        := CheckAttribute(FILE_ATTRIBUTE_COMPRESSED);
    fAttributesDecoded.Device            := CheckAttribute(FILE_ATTRIBUTE_DEVICE);
    fAttributesDecoded.Directory         := CheckAttribute(FILE_ATTRIBUTE_DIRECTORY);
    fAttributesDecoded.Encrypted         := CheckAttribute(FILE_ATTRIBUTE_ENCRYPTED);
    fAttributesDecoded.Hidden            := CheckAttribute(FILE_ATTRIBUTE_HIDDEN);
    fAttributesDecoded.IntegrityStream   := CheckAttribute(FILE_ATTRIBUTE_INTEGRITY_STREAM);
    fAttributesDecoded.Normal            := CheckAttribute(FILE_ATTRIBUTE_NORMAL);
    fAttributesDecoded.NotContentIndexed := CheckAttribute(FILE_ATTRIBUTE_NOT_CONTENT_INDEXED);
    fAttributesDecoded.NoScrubData       := CheckAttribute(FILE_ATTRIBUTE_NO_SCRUB_DATA);
    fAttributesDecoded.Offline           := CheckAttribute(FILE_ATTRIBUTE_OFFLINE);
    fAttributesDecoded.ReadOnly          := CheckAttribute(FILE_ATTRIBUTE_READONLY);
    fAttributesDecoded.ReparsePoint      := CheckAttribute(FILE_ATTRIBUTE_REPARSE_POINT);
    fAttributesDecoded.SparseFile        := CheckAttribute(FILE_ATTRIBUTE_SPARSE_FILE);
    fAttributesDecoded.System            := CheckAttribute(FILE_ATTRIBUTE_SYSTEM);
    fAttributesDecoded.Temporary         := CheckAttribute(FILE_ATTRIBUTE_TEMPORARY);
    fAttributesDecoded.Virtual           := CheckAttribute(FILE_ATTRIBUTE_VIRTUAL);
  end;
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5057{$ENDIF}
procedure TWinFileInfo.LoadTime;
var
  Creation:   TFileTime;
  LastAccess: TFileTime;
  LastWrite:  TFileTime;

  Function FileTimeToDateTime(FileTime: TFileTime): TDateTime;
  var
    LocalTime:  TFileTime;
    SystemTime: TSystemTime;
  begin
    If FileTimeToLocalFileTime(FileTime,LocalTime) then
      begin
        If FileTimeToSystemTime(LocalTime,SystemTime) then
          Result := SystemTimeToDateTime(SystemTime)
        else raise Exception.CreateFmt('TWinFileInfo.LoadTime.FileTimeToDateTime: Unable to convert to system time ("%s", 0x%.8x).',[fLongName,GetLastError]);
      end
    else raise Exception.CreateFmt('TWinFileInfo.LoadTime.FileTimeToDateTime: Unable to convert to local time ("%s", 0x%.8x).',[fLongName,GetLastError]);
  end;

begin
If GetFileTime(fFileHandle,@Creation,@LastAccess,@LastWrite) then
  begin
    fCreationTime := FileTimeToDateTime(Creation);
    fLastAccessTime := FileTimeToDateTime(LastAccess);
    fLastWriteTime := FileTimeToDateTime(LastWrite);
  end
else raise Exception.CreateFmt('TWinFileInfo.LoadTime: Unable to obtain file time ("%s", 0x%.8x).',[fLongName,GetLastError]);
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

//------------------------------------------------------------------------------

procedure TWinFileInfo.LoadSize;
begin
If GetFileSizeEx(fFileHandle,@fSize) then
  fSizeStr := SizeToStr(fSize)
else
  raise Exception.CreateFmt('TWinFileInfo.GetFileSize: Unable to obtain file size ("%s", 0x%.8x).',[fLongName,GetLastError]);
end;

//------------------------------------------------------------------------------

Function TWinFileInfo.CheckFileExists: Boolean;
begin
fAttributesFlags := GetFileAttributes(PChar(StrToWin(fLongName)));
fExists := (fAttributesFlags <> INVALID_FILE_ATTRIBUTES) and
           (fAttributesFlags and FILE_ATTRIBUTE_DIRECTORY = 0);
Result := fExists;
end;

//------------------------------------------------------------------------------

procedure TWinFileInfo.Clear;
begin
fSize := 0;
fSizeStr := '';
fCreationTime := 0;
fLastAccessTime := 0;
fLastWriteTime := 0;
fAttributesFlags := 0;
fAttributesStr := '';
fAttributesText := '';
FillChar(fAttributesDecoded,SizeOf(fAttributesDecoded),0);
fVersionInfoPresent := False;
fVersionInfoFFIPresent := False;
FillChar(fVersionInfoFFI,SizeOf(fVersionInfoFFI),0);
fVersionInfoFFIDecoded.FileVersionStr := '';
fVersionInfoFFIDecoded.ProductVersionStr := '';
fVersionInfoFFIDecoded.FileOSStr := '';
fVersionInfoFFIDecoded.FileTypeStr := '';
fVersionInfoFFIDecoded.FileSubTypeStr := '';
FillChar(fVersionInfoFFIDecoded,SizeOf(fVersionInfoFFIDecoded),0);
SetLength(fVersionInfoStringTables,0);
fVersionInfoParsed := False;
SetLength(fVersionInfoStruct.StringFileInfos,0);
SetLength(fVersionInfoStruct.VarFileInfos,0);
fVersionInfoStruct.Key := '';
FillChar(fVersionInfoStruct,SizeOf(fVersionInfoStruct),0);
end;

//------------------------------------------------------------------------------

procedure TWinFileInfo.Initialize(const FileName: String);
begin
{$IFDEF UTF8Wrappers}
fLongName := ExpandFileNameUTF8(FileName);
{$ELSE}
fLongName := ExpandFileName(FileName);
{$ENDIF}
SetLength(fShortName,MAX_PATH);
SetLength(fShortName,GetShortPathName(PChar(StrToWin(fLongName)),PChar(fShortName),Length(fShortName)));
fShortName := WinToStr(fShortName);
If CheckFileExists then
  begin
    fFileHandle := CreateFile(PChar(StrToWin(fLongName)),0,FILE_SHARE_READ or FILE_SHARE_WRITE,nil,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
    If fFileHandle <> INVALID_HANDLE_VALUE then
      begin
        If LoadingStrategyFlag(WFI_LS_LoadSize) then LoadSize;
        If LoadingStrategyFlag(WFI_LS_LoadTime) then LoadTime;
        If LoadingStrategyFlag(WFI_LS_LoadAttributes) then LoadAttributes
          else fAttributesFlags := 0;
        If LoadingStrategyFlag(WFI_LS_LoadVersionInfo) then LoadVersionInfo;
      end
    else raise Exception.CreateFmt('TWinFileInfo.Initialize: Failed to open requested file ("%s", 0x%.8x).',[fLongName,GetLastError]);
  end;
end;

//------------------------------------------------------------------------------

procedure TWinFileInfo.Finalize;
begin
If Assigned(fVerInfoData) and (fVerInfoSize <> 0) then
  FreeMem(fVerInfoData,fVerInfoSize);
fVerInfoData := nil;
fVerInfoSize := 0;
CloseHandle(fFileHandle);
fFileHandle := INVALID_HANDLE_VALUE;
end;

{------------------------------------------------------------------------------}
{   TWinFileInfo - public methods                                              }
{------------------------------------------------------------------------------}

constructor TWinFileInfo.Create(LoadingStrategy: UInt32 = WFI_LS_All);
var
  ModuleFileName: String;
begin
SetLength(ModuleFileName,MAX_PATH);
SetLength(ModuleFileName,GetModuleFileName(hInstance,PChar(ModuleFileName),Length(ModuleFileName)));
ModuleFileName := WinToStr(ModuleFileName);
Create(ModuleFileName,LoadingStrategy);
end;

//--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

constructor TWinFileInfo.Create(const FileName: String; LoadingStrategy: UInt32 = WFI_LS_All);
begin
inherited Create;
fLoadingStrategy := LoadingStrategy;
{$WARN SYMBOL_PLATFORM OFF}
{$IF not Defined(FPC) and (CompilerVersion >= 18)} // Delphi 2006+
fFormatSettings := TFormatSettings.Create(LOCALE_USER_DEFAULT);
{$ELSE}
GetLocaleFormatSettings(LOCALE_USER_DEFAULT,fFormatSettings);
{$IFEND}
{$WARN SYMBOL_PLATFORM ON}
Initialize(FileName);
end;

//------------------------------------------------------------------------------

destructor TWinFileInfo.Destroy;
begin
Finalize;
inherited;
end;

//------------------------------------------------------------------------------

procedure TWinFileInfo.Refresh;
begin
Clear;
Finalize;
Initialize(fLongName);
end;
 
//------------------------------------------------------------------------------

Function TWinFileInfo.IndexOfVersionInfoStringTable(Translation: DWord): Integer;
var
  i:  Integer;
begin
Result := -1;
For i := Low(fVersionInfoStringTables) to High(fVersionInfoStringTables) do
  If fVersionInfoStringTables[i].Translation.Translation = Translation then
    begin
      Result := i;
      Exit;
    end;
end;

//------------------------------------------------------------------------------

Function TWinFileInfo.IndexOfVersionInfoString(Table: Integer; const Key: String): Integer;
var
  i:  Integer;
begin
Result := -1;
with GetVersionInfoStringTable(Table) do
  For i := Low(Strings) to High(Strings) do
    If AnsiSameText(Strings[i].Key,Key) then
      begin
        Result := i;
        Exit;
      end;
end;

//------------------------------------------------------------------------------

Function TWinFileInfo.CreateReport(DoRefresh: Boolean = False): String;
var
  i,j:  Integer;
  Len:  Integer;
begin
If DoRefresh then
  begin
    fLoadingStrategy := WFI_LS_All;
    Refresh;
  end;
with TStringList.Create do
  begin
    Add('=== TWinInfoFile report, created on ' + DateTimeToStr(Now,fFormatSettings) + ' ===');
    Add(sLineBreak + '--- General info ---' + sLineBreak);
    Add('  Exists:     ' + BoolToStr(fExists,True));
    Add('  Long name:  ' + LongName);
    Add('  Short name: ' + ShortName);
    Add(sLineBreak + 'Size:' + sLineBreak);
    Add('  Size:    ' + IntToStr(fSize));
    Add('  SizeStr: ' + SizeStr);
    Add(sLineBreak + 'Time:' + sLineBreak);
    Add('  Created:     ' + DateTimeToStr(fCreationTime));
    Add('  Last access: ' + DateTimeToStr(fLastAccessTime));
    Add('  Last write:  ' + DateTimeToStr(fLastWriteTime));
    Add(sLineBreak + 'Attributes:' + sLineBreak);
    Add('  Attributes flags:  ' + IntToHex(fAttributesFlags,8));
    Add('  Attributes string: ' + fAttributesStr);
    Add('  Attributes text:   ' + fAttributesText);
    Add(sLineBreak + '  Attributes decoded:');
    Add('    Archive:             ' + BoolToStr(fAttributesDecoded.Archive,True));
    Add('    Compressed:          ' + BoolToStr(fAttributesDecoded.Compressed,True));
    Add('    Device:              ' + BoolToStr(fAttributesDecoded.Device,True));
    Add('    Directory:           ' + BoolToStr(fAttributesDecoded.Directory,True));
    Add('    Encrypted:           ' + BoolToStr(fAttributesDecoded.Encrypted,True));
    Add('    Hidden:              ' + BoolToStr(fAttributesDecoded.Hidden,True));
    Add('    Integrity stream:    ' + BoolToStr(fAttributesDecoded.IntegrityStream,True));
    Add('    Normal:              ' + BoolToStr(fAttributesDecoded.Normal,True));
    Add('    Not content indexed: ' + BoolToStr(fAttributesDecoded.NotContentIndexed,True));
    Add('    No scrub data:       ' + BoolToStr(fAttributesDecoded.NoScrubData,True));
    Add('    Offline:             ' + BoolToStr(fAttributesDecoded.Offline,True));
    Add('    Read only:           ' + BoolToStr(fAttributesDecoded.ReadOnly,True));
    Add('    Reparse point:       ' + BoolToStr(fAttributesDecoded.ReparsePoint,True));
    Add('    Sparse file:         ' + BoolToStr(fAttributesDecoded.SparseFile,True));
    Add('    System:              ' + BoolToStr(fAttributesDecoded.System,True));
    Add('    Temporary:           ' + BoolToStr(fAttributesDecoded.Temporary,True));
    Add('    Vitual:              ' + BoolToStr(fAttributesDecoded.Virtual,True));
    If fVersionInfoPresent then
      begin
        Add(sLineBreak + '--- File version info ---');
        If fVersionInfoFFIPresent then
          begin
            Add(sLineBreak + 'Fixed file info:' + sLineBreak);
            Add('  Signature:         ' + IntToHex(fVersionInfoFFI.dwSignature,8));
            Add('  Struct version:    ' + IntToHex(fVersionInfoFFI.dwStrucVersion,8));
            Add('  File version H:    ' + IntToHex(fVersionInfoFFI.dwFileVersionMS,8));
            Add('  File version L:    ' + IntToHex(fVersionInfoFFI.dwFileVersionLS,8));
            Add('  Product version H: ' + IntToHex(fVersionInfoFFI.dwProductVersionMS,8));
            Add('  Product version L: ' + IntToHex(fVersionInfoFFI.dwProductVersionLS,8));
            Add('  File flags mask :  ' + IntToHex(fVersionInfoFFI.dwFileFlagsMask,8));
            Add('  File flags:        ' + IntToHex(fVersionInfoFFI.dwFileFlags,8));
            Add('  File OS:           ' + IntToHex(fVersionInfoFFI.dwFileOS,8));
            Add('  File type:         ' + IntToHex(fVersionInfoFFI.dwFileType,8));
            Add('  File subtype:      ' + IntToHex(fVersionInfoFFI.dwFileSubtype,8));
            Add('  File date H:       ' + IntToHex(fVersionInfoFFI.dwFileDateMS,8));
            Add('  File date L:       ' + IntToHex(fVersionInfoFFI.dwFileDateLS,8));
            Add(sLineBreak + '  Fixed file info decoded:');
            Add('    File version full:      ' + IntToHex(fVersionInfoFFIDecoded.FileVersionFull,16));
            Add('    File version members:');
            Add('      Major:   ' + IntToStr(fVersionInfoFFIDecoded.FileVersionMembers.Major));
            Add('      Minor:   ' + IntToStr(fVersionInfoFFIDecoded.FileVersionMembers.Minor));
            Add('      Release: ' + IntToStr(fVersionInfoFFIDecoded.FileVersionMembers.Release));
            Add('      Build:   ' + IntToStr(fVersionInfoFFIDecoded.FileVersionMembers.Build));
            Add('    File version string:    ' + fVersionInfoFFIDecoded.FileVersionStr);
            Add('    Product version full:   ' + IntToHex(fVersionInfoFFIDecoded.ProductVersionFull,16));
            Add('    Product version members:');
            Add('      Major:   ' + IntToStr(fVersionInfoFFIDecoded.ProductVersionMembers.Major));
            Add('      Minor:   ' + IntToStr(fVersionInfoFFIDecoded.ProductVersionMembers.Minor));
            Add('      Release: ' + IntToStr(fVersionInfoFFIDecoded.ProductVersionMembers.Release));
            Add('      Build:   ' + IntToStr(fVersionInfoFFIDecoded.ProductVersionMembers.Build));
            Add('    Product version string: ' + fVersionInfoFFIDecoded.ProductVersionStr);
            Add('    File flags:');
            Add('      Debug:         ' + BoolToStr(fVersionInfoFFIDecoded.FileFlags.Debug,True));
            Add('      Info inferred: ' + BoolToStr(fVersionInfoFFIDecoded.FileFlags.InfoInferred,True));
            Add('      Patched:       ' + BoolToStr(fVersionInfoFFIDecoded.FileFlags.Patched,True));
            Add('      Prerelease:    ' + BoolToStr(fVersionInfoFFIDecoded.FileFlags.Prerelease,True));
            Add('      Private build: ' + BoolToStr(fVersionInfoFFIDecoded.FileFlags.PrivateBuild,True));
            Add('      Special build: ' + BoolToStr(fVersionInfoFFIDecoded.FileFlags.SpecialBuild,True));
            Add('    File OS string:         ' + fVersionInfoFFIDecoded.FileOSStr);
            Add('    File type string:       ' + fVersionInfoFFIDecoded.FileTypeStr);
            Add('    File subtype string:    ' + fVersionInfoFFIDecoded.FileSubTypeStr);
            Add('    File date full:         ' + IntToHex(fVersionInfoFFIDecoded.FileDateFull,16));
          end
        else Add(sLineBreak + 'Fixed file info not present.');
        If VersionInfoTranslationCount > 0 then
          begin
            Add(sLineBreak + 'Version info translations:' + sLineBreak);
            Add('  Translation count: ' + IntToStr(VersionInfoTranslationCount));
              For i := 0 to Pred(VersionInfoTranslationCount) do
                begin
                Add(sLineBreak + Format('  Translation %d:',[i]));
                Add('    Language:        ' + IntToStr(VersionInfoTranslations[i].Language));
                Add('    Code page:       ' + IntToStr(VersionInfoTranslations[i].CodePage));
                Add('    Translation:     ' + IntToHex(VersionInfoTranslations[i].Translation,8));
                Add('    Language string: ' + VersionInfoTranslations[i].LanguageStr);
                Add('    Language name:   ' + VersionInfoTranslations[i].LanguageName);
                end;
            end
          else Add(sLineBreak + 'No translation found.');
        If VersionInfoStringTableCount > 0 then
          begin
            Add(sLineBreak + 'Version info string tables:' + sLineBreak);
            Add('  String table count: ' + IntToStr(VersionInfoStringTableCount));
              For i := 0 to Pred(VersionInfoStringTableCount) do
                begin
                Add(sLineBreak + Format('  String table %d (%s):',[i,fVersionInfoStringTables[i].Translation.LanguageName]));
                  Len := 0;
                  For j := 0 to Pred(VersionInfoKeyCount[i]) do
                    If Length(VersionInfoKeys[i,j]) > Len then Len := Length(VersionInfoKeys[i,j]);
                  For j := 0 to Pred(VersionInfoStringCount[i]) do
                    Add(Format('    %s: %s%s',[VersionInfoString[i,j].Key,StringOfChar(' ',Len - Length(VersionInfoString[i,j].Key)),VersionInfoString[i,j].Value]));
                end;
            end
          else Add(sLineBreak + 'No string table found.');
      end
    else Add(sLineBreak + 'File version information not present.');
    Result := Text;
    Free;
  end;
end;

end.

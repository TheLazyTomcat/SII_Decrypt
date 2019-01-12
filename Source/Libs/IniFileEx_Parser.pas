{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Extended INI file

    Parser class used for writing and reading of actual INI files

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
{-------------------------------------------------------------------------------

  Structure of binary INI (BINI) files

  All primitives are stored with little endianess.
  Strings are UTF8-encoded and are stored with explicit length the
  following way:

    begin
      UInt32      - string length (number of characters, NOT code points)
      UTF8Char[]  - array of UTF8 characters
    end;

  BINI files have following structure:

    begin
      UInt32    - signature (0x494E4942)    --
      UInt16    - data structure number      |- Header
      UInt16    - flags                      |
      UInt64    - data size                 --
      []        - data
    end;

  Header is common to all BINI files, but data can have different structure,
  depending on data structure number (format).

  Following flags are implemented:

    (0x0001) IFX_BINI_FLAGS_ZLIB_COMPRESS   - data will be compressed into
                                              zlib stream
    (0x0002) IFX_BINI_FLAGS_AES_ENCRYPT     - data will be encrypted using AES
                                              cipher and key and init vector
                                              from ini settings

  If both compression and encryption are selected, the data are first compressed
  and then encrypted.

  As for data format, only one is currently implemented - format 0 of following
  structure:

  format_0:
    begin
      String[]  - file comment
      UInt32    - section count
      Section[] - array of sections
    end;

  Section:
    begin
      UInt32    - signature (0x54434553)
      String[]  - section name
      String[]  - section comment
      String[]  - section inline comment
      UInt32    - key count
      Key[]     - array of keys
    end;

  Key:
    begin
      UInt32    - signature (0x5659454B)
      String[]  - key name
      String[]  - key comment
      String[]  - key inline comment
      UInt8     - value encoding (obtained by calling IFXValueEncodingToByte)
      UInt8     - value type (obtained by calling IFXValueTypeToByte)
      []        - data (size and actual type depends on the value type; if value
                  type is undecided, it contains ValueStr)
    end;
    
-------------------------------------------------------------------------------}
unit IniFileEx_Parser;

{$INCLUDE '.\IniFileEx_defs.inc'}

interface

uses
  Classes,
  AuxTypes, ExplicitStringLists,
  IniFileEx_Common, IniFileEx_Nodes;

{===============================================================================
--------------------------------------------------------------------------------
                                   TIFXParser
--------------------------------------------------------------------------------
===============================================================================}
type
  TIFXBiniFileHeader = packed record
    Signature:  UInt32;
    Structure:  UInt16;
    Flags:      UInt16;
    DataSize:   UInt64;
  end;

  TIFXTextLineType = (itltEmpty,itltComment,itltSection,itltKey);

const
  IFX_UTF8BOM: packed array[0..2] of Byte = ($EF,$BB,$BF);

  IFX_INI_MINLINELENGTH = 16; // minimum length of a line before it can be wrapped

  IFX_BINI_SIGNATURE_FILE    = UInt32($494E4942); // BINI
  IFX_BINI_SIGNATURE_SECTION = UInt32($54434553); // SECT
  IFX_BINI_SIGNATURE_KEY     = UInt32($5659454B); // KEYV

  IFX_BINI_MINFILESIZE = SizeOf(TIFXBiniFileHeader);

  IFX_BINI_DATASTRUCT_0 = UInt16(0);  // more may be added in the future

  IFX_BINI_FLAGS_ZLIB_COMPRESS = UInt16($0001);
  IFX_BINI_FLAGS_AES_ENCRYPT   = UInt16($0002);

{===============================================================================
    TIFXParser - class declaration
===============================================================================}
type
  TIFXParser = class(TObject)
  private
    fSettingsPtr:         PIFXSettings;
    fFileNode:            TIFXFileNode;
    fStream:              TStream;
    // for textual processing...
    fEmptyLinePos:        Int64;
    fIniStrings:          TUTF8StringList;
    fProcessedLine:       TIFXString;
    fLastComment:         TIFXString;
    fFileCommentSet:      Boolean;
    fLastTextLineType:    TIFXTextLineType;
    fCurrentSectionNode:  TIFXSectionNode;
    // for binary processing...
    fBinFileHeader:       TIFXBiniFileHeader;
  protected
    // writing textual ini
    Function Text_WriteEmptyLine: TMemSize; virtual;
    Function Text_WriteString(const Str: TIFXString; LineBreak: Boolean = True): TMemSize; virtual;
    Function Text_WriteSection(SectionNode: TIFXSectionNode): TMemSize; virtual;
    Function Text_WriteKey(KeyNode: TIFXKeyNode): TMemSize; virtual;
    // reading textual ini
    procedure Text_AddToLastComment(const Comment: TIFXString); virtual;
    Function Text_ConsumeLastComment: TIFXString; virtual;
    procedure Text_CreateEmptyNameSection; virtual;
    procedure Text_ReadLine; virtual;
    procedure Text_ReadCommentLine; virtual;
    procedure Text_ReadSectionLine; virtual;
    procedure Text_ReadKeyLine; virtual;
    // writing binary ini of structure 0x0000
    Function Binary_0000_WriteString(const Str: TIFXString): TMemSize; virtual;
    Function Binary_0000_WriteSection(SectionNode: TIFXSectionNode): TMemSize; virtual;
    Function Binary_0000_WriteKey(KeyNode: TIFXKeyNode): TMemSize; virtual;
    // reading binary ini of structure 0x0000
    Function Binary_0000_ReadString: TIFXString; virtual;
    procedure Binary_0000_ReadData; virtual;
    Function Binary_0000_ReadSection(out SectionNode: TIFXSectionNode): Boolean; virtual;
    Function Binary_0000_ReadKey(SectionNode: TIFXSectionNode; out KeyNode: TIFXKeyNode): Boolean; virtual;
  public
    class Function IsBinaryIniStream(Stream: TStream): Boolean; virtual;
    class Function IsBinaryIniFile(const FileName: String): Boolean; virtual;
    constructor Create(SettingsPtr: PIFXSettings; FileNode: TIFXFileNode);
    // auxiliary methods
    Function ConstructCommentBlock(const CommentStr: TIFXString): TIFXString; virtual;
    Function ConstructSectionName(SectionNode: TIFXSectionNode): TIFXString; virtual;
    Function ConstructKeyValueLine(KeyNode: TIFXKeyNode; out ValueStart: TStrSize): TIFXString; virtual;
    Function PrepareInlineComment(const CommentStr: TIFXString): TIFXString; virtual;
    // writing to stream
    procedure WriteTextual(Stream: TStream); virtual;
    procedure ReadTextual(Stream: TStream); virtual;
    procedure WriteBinary(Stream: TStream); virtual;
    procedure ReadBinary(Stream: TStream); virtual;
  end;

implementation

uses
  SysUtils, Math,
  BinaryStreaming, StrRect, SimpleCompress, AES,
  IniFileEx_Utils;

{===============================================================================
--------------------------------------------------------------------------------
                                   TIFXParser                                                                         
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TIFXParser - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TIFXParser - protected methods
-------------------------------------------------------------------------------}

Function TIFXParser.Text_WriteEmptyLine: TMemSize;
var
  TempStr:  UTF8String;
begin
If fStream.Position <> fEmptyLinePos then
  begin
    TempStr := IFXStrToUTF8(fSettingsPtr^.TextIniSettings.LineBreak);
    Result := TMemSize(Stream_WriteBuffer(fStream,PUTF8Char(TempStr)^,Length(TempStr) * SizeOf(UTF8Char)));
    fEmptyLinePos := fStream.Position;
  end
else Result := 0;
end;

//------------------------------------------------------------------------------

Function TIFXParser.Text_WriteString(const Str: TIFXString; LineBreak: Boolean = True): TMemSize;
var
  TempStr:  UTF8String;
begin
If Length(Str) > 0 then
  begin
    If LineBreak then
      TempStr := IFXStrToUTF8(Str + fSettingsPtr^.TextIniSettings.LineBreak)
    else
      TempStr := IFXStrToUTF8(Str);
    If Length(TempStr) > 0 then
      Result := TMemSize(Stream_WriteBuffer(fStream,PUTF8Char(TempStr)^,Length(TempStr) * SizeOf(UTF8Char)))
    else
      Result := 0;
  end
else Result := 0;
end;

//------------------------------------------------------------------------------

Function TIFXParser.Text_WriteSection(SectionNode: TIFXSectionNode): TMemSize;
var
  i:  Integer;
begin
Result := Text_WriteEmptyLine;
Inc(Result,Text_WriteString(ConstructCommentBlock(SectionNode.Comment)));
Inc(Result,Text_WriteString(ConstructSectionName(SectionNode),Length(SectionNode.InlineComment) <= 0));
Inc(Result,Text_WriteString(PrepareInlineComment(SectionNode.InlineComment)));
For i := SectionNode.LowIndex to SectionNode.HighIndex do
  Inc(Result,Text_WriteKey(SectionNode[i]));
end;

//------------------------------------------------------------------------------

Function TIFXParser.Text_WriteKey(KeyNode: TIFXKeyNode): TMemSize;
var
  LineStr:  TIFXString;
  ValStart: TStrSize;
  Cntr,i:   Integer;
begin
Result := Text_WriteString(ConstructCommentBlock(KeyNode.Comment));
LineStr := ConstructKeyValueLine(KeyNode,ValStart);
If (fSettingsPtr^.TextIniSettings.ValueWrapLength > IFX_INI_MINLINELENGTH) and
  ((Length(LineStr) - ValStart) >= fSettingsPtr^.TextIniSettings.ValueWrapLength) and
  (KeyNode.ValueType in [ivtUndecided,ivtString,ivtBinary]) then
  begin
    // write key and delimiter
    Inc(Result,Text_WriteString(Copy(LineStr,1,ValStart - 1),False));
    // compute how much breaks there has to be
    Cntr := Ceil((Length(LineStr) - ValStart) / (fSettingsPtr^.TextIniSettings.ValueWrapLength - 1)) - 1;
    // write blocks
    For i := 0 to Pred(Cntr) do
      begin
        Inc(Result,Text_WriteString(
          Copy(LineStr,i * (fSettingsPtr^.TextIniSettings.ValueWrapLength - 1) + ValStart,
            (fSettingsPtr^.TextIniSettings.ValueWrapLength - 1)),False));
        Inc(Result,Text_WriteString(fSettingsPtr^.TextIniSettings.EscapeChar + fSettingsPtr^.TextIniSettings.LineBreak,False));
      end;
    // write last block  
    Inc(Result,Text_WriteString(
      Copy(LineStr,Cntr * (fSettingsPtr^.TextIniSettings.ValueWrapLength - 1) + ValStart,
        Length(LineStr) - ((Cntr * (fSettingsPtr^.TextIniSettings.ValueWrapLength - 1)) + ValStart) + 1),
      Length(KeyNode.InlineComment) <= 0));
  end
else Inc(Result,Text_WriteString(ConstructKeyValueLine(KeyNode,ValStart),Length(KeyNode.InlineComment) <= 0));
Inc(Result,Text_WriteString(PrepareInlineComment(KeyNode.InlineComment)));
end;

//------------------------------------------------------------------------------

procedure TIFXParser.Text_AddToLastComment(const Comment: TIFXString);
begin
If Length(fLastComment) > 0 then
  fLastComment := fLastComment + fSettingsPtr^.TextIniSettings.LineBreak + Comment
else
  fLastComment := Comment;
end;
//------------------------------------------------------------------------------

Function TIFXParser.Text_ConsumeLastComment: TIFXString;
begin
Result := fLastComment;
fLastComment := '';
end;

//------------------------------------------------------------------------------

procedure TIFXParser.Text_CreateEmptyNameSection;
var
  Index:  Integer;
begin
Index := fFileNode.IndexOfSection('');
If Index < 0 then
  begin
    fCurrentSectionNode := TIFXSectionNode.Create('',fFileNode.SettingsPtr);
    fFileNode.AddSectionNode(fCurrentSectionNode);
  end
else fCurrentSectionNode := fFileNode[Index];
end;

//------------------------------------------------------------------------------

procedure TIFXParser.Text_ReadLine;
begin
// select how to parse the line according to first character
If Length(fProcessedLine) > 0 then
  begin
    If fProcessedLine[1] = fSettingsPtr^.TextIniSettings.CommentChar then
      Text_ReadCommentLine
    else If fProcessedLine[1] = fSettingsPtr^.TextIniSettings.SectionStartChar then
      Text_ReadSectionLine
    else
      // invalid lines will fall to key parser
      Text_ReadKeyLine;
    fProcessedLine := '';
  end
else fLastTextLineType := itltEmpty;
end;

//------------------------------------------------------------------------------

procedure TIFXParser.Text_ReadCommentLine;
begin
If (fLastTextLineType <> itltComment) and (Length(fLastComment) > 0) then
  begin
    If not fFileCommentSet then
      begin
        fFileNode.Comment := fLastComment;
        fFileCommentSet := True;
      end
    else
      begin
        If not Assigned(fCurrentSectionNode) then
          begin
            Text_CreateEmptyNameSection;
            fCurrentSectionNode.Comment := fLastComment;
          end;
      end;
    fLastComment := '';
  end;
Text_AddToLastComment(Copy(fProcessedLine,2,Length(fProcessedLine) - 1));
fLastTextLineType := itltComment;
end;

//------------------------------------------------------------------------------

procedure TIFXParser.Text_ReadSectionLine;
var
  SectName: TIFXString;
  i,p:      TStrSize;
  Cntr:     Integer;
  ICmnt:    TIFXString;
begin
// find closing character; if not present, discard line
p := -1;
For i := 1 to Length(fProcessedLine) do
  If fProcessedLine[i] = fSettingsPtr^.TextIniSettings.SectionEndChar then
    begin
      p := i;
      Break{For i};
    end;
If p > 0 then
  begin
    // extract section name from the line
    SectName := Copy(fProcessedLine,2,p - 2);
    // search for an inline comment
    ICmnt := '';
    For i := (p + 1) to Length(fProcessedLine) do
      If fProcessedLine[i] = fSettingsPtr^.TextIniSettings.CommentChar then
        begin
          // everything after comment mark is assumed to be an inline comment
          ICmnt := Copy(fProcessedLine,i + 1,Length(fProcessedLine) - i);
          Break{For i};
        end;
    i := fFileNode.IndexOfSection(SectName);
    If i >= 0 then
      // section of this name is already present
      case fSettingsPtr^.DuplicityBehavior of
        idbReplace:
          begin
            fCurrentSectionNode := fFileNode[i];
            fCurrentSectionNode.Comment := Text_ConsumeLastComment;
            fCurrentSectionNode.InlineComment := ICmnt;
          end;
        idbRenameOld:
          begin
            If fFileNode.IndexOfSection(SectName + fSettingsPtr^.DuplicityRenameOldStr) >= 0 then
              begin
                Cntr := 0;
                while fFileNode.IndexOfSection(SectName + fSettingsPtr^.DuplicityRenameOldStr +
                  StrToIFXStr(IntToStr(Cntr))) >= 0 do Inc(Cntr);
                fFileNode[i].NameStr := SectName + fSettingsPtr^.DuplicityRenameOldStr +
                  StrToIFXStr(IntToStr(Cntr));
              end
            else fFileNode[i].NameStr := SectName + fSettingsPtr^.DuplicityRenameOldStr;
            fCurrentSectionNode := TIFXSectionNode.Create(SectName,fFileNode.SettingsPtr);
            fCurrentSectionNode.Comment := Text_ConsumeLastComment;
            fCurrentSectionNode.InlineComment := ICmnt;
            fFileNode.AddSectionNode(fCurrentSectionNode);
          end;
        idbRenameNew:
          begin
            If fFileNode.IndexOfSection(SectName + fSettingsPtr^.DuplicityRenameNewStr) >= 0 then
              begin
                Cntr := 0;
                while fFileNode.IndexOfSection(SectName + fSettingsPtr^.DuplicityRenameNewStr +
                  StrToIFXStr(IntToStr(Cntr))) >= 0 do Inc(Cntr);
                SectName := SectName + fSettingsPtr^.DuplicityRenameNewStr + StrToIFXStr(IntToStr(Cntr));
              end
            else SectName := SectName + fSettingsPtr^.DuplicityRenameNewStr;
            fCurrentSectionNode := TIFXSectionNode.Create(SectName,fFileNode.SettingsPtr);
            fCurrentSectionNode.Comment := Text_ConsumeLastComment;
            fCurrentSectionNode.InlineComment := ICmnt;
            fFileNode.AddSectionNode(fCurrentSectionNode);
          end;
      else
        {idbDrop}
        fCurrentSectionNode := fFileNode[i];
        Text_ConsumeLastComment;
      end
    else
      begin
        // section of this name does not yet exist, create node and add it
        fCurrentSectionNode := TIFXSectionNode.Create(SectName,fFileNode.SettingsPtr);
        fCurrentSectionNode.Comment := Text_ConsumeLastComment;
        fCurrentSectionNode.InlineComment := ICmnt;
        fFileNode.AddSectionNode(fCurrentSectionNode);
      end;
    fLastTextLineType := itltSection;
  end
else fLastTextLineType := itltEmpty;
end;

//------------------------------------------------------------------------------

procedure TIFXParser.Text_ReadKeyLine;
var
  i,p:      TSTrSize;
  KeyName:  TIFXString;
  KeyCmnt:  TIFXString;
  KeyNode:  TIFXKeyNode;
  Cntr:     Integer;
  ICmnt:    TIFXString;

  Function ExtractInlineComment(var FromStr: TIFXString): TIFXSTring;
  var
    ii:       TStrSize;
    Quoted:   Boolean;
    Escaped:  Boolean;
    AfterVal: Boolean;
  begin
    Result := '';
    If Length(FromStr) > 0 then
      begin
        Quoted := False;
        Escaped := False;
        AfterVal := False;
        For ii := 1 to Length(FromStr) do
          begin
            If (FromStr[ii] = fSettingsPtr^.TextIniSettings.EscapeChar) and not Escaped then
              Escaped := True
            else If (FromStr[ii] = fSettingsPtr^.TextIniSettings.QuoteChar) and not Escaped and not AfterVal then
              begin
                If Quoted then
                  AfterVal := True;
                Quoted := not Quoted;
                Escaped := False;
              end
            else If (FromStr[ii] = fSettingsPtr^.TextIniSettings.CommentChar) and not Quoted then
              begin
                // everything after comment mark is assumed to be an inline comment
                Result := Copy(FromStr,ii + 1,Length(FromStr) - ii);
                SetLength(FromStr,ii - 1);
                FromStr := IFXTrimStr(FromStr);
                Break{For ii};
              end
            else
              Escaped := False;
          end;
      end;
  end;

begin
// get position of value delimiter
p := -1;
For i := 1 to Length(fProcessedLine) do
  If fProcessedLine[i] = fSettingsPtr^.TextIniSettings.ValueDelimChar then
    begin
      p := i;
      Break{For i};
    end;
If p > 0 then
  begin
    // everything in front of delimiter is key, everything behind is a value and potentially inline comment
    KeyName := IFXTrimStr(Copy(fProcessedLine,1,p - 1),fSettingsPtr^.TextIniSettings.WhiteSpaceChar);
    fProcessedLine := IFXTrimStr(Copy(fProcessedLine,p + 1,Length(fProcessedLine) - p),fSettingsPtr^.TextIniSettings.WhiteSpaceChar);
    KeyCmnt := Text_ConsumeLastComment;
    // extract inline comment
    ICmnt := ExtractInlineComment(fProcessedLine);
    If not Assigned(fCurrentSectionNode) then
      Text_CreateEmptyNameSection;
    i := fCurrentSectionNode.IndexOfKey(KeyName);
    If i >= 0 then
      // key of this name is already present
      case fSettingsPtr^.DuplicityBehavior of
        idbReplace:
          begin
            fCurrentSectionNode[i].Comment := KeyCmnt;
            fCurrentSectionNode[i].InlineComment := ICmnt;
            fCurrentSectionNode[i].ValueStr := fProcessedLine;
          end;
        idbRenameOld:
          begin
            If fCurrentSectionNode.IndexOfKey(KeyName + fSettingsPtr^.DuplicityRenameOldStr) >= 0 then
              begin
                Cntr := 0;
                while fCurrentSectionNode.IndexOfKey(KeyName + fSettingsPtr^.DuplicityRenameOldStr +
                  StrToIFXStr(IntToStr(Cntr))) >= 0 do Inc(Cntr);
                fCurrentSectionNode[i].NameStr := KeyName + fSettingsPtr^.DuplicityRenameOldStr +
                  StrToIFXStr(IntToStr(Cntr));
              end
            else fCurrentSectionNode[i].NameStr := KeyName + fSettingsPtr^.DuplicityRenameOldStr;
            KeyNode := TIFXKeyNode.Create(KeyName,fCurrentSectionNode.SettingsPtr);
            KeyNode.Comment := KeyCmnt;
            KeyNode.InlineComment := ICmnt;
            KeyNode.ValueStr := fProcessedLine;
            fCurrentSectionNode.AddKeyNode(KeyNode);
          end;
        idbRenameNew:
          begin
            If fCurrentSectionNode.IndexOfKey(KeyName + fSettingsPtr^.DuplicityRenameNewStr) >= 0 then
              begin
                Cntr := 0;
                while fCurrentSectionNode.IndexOfKey(KeyName + fSettingsPtr^.DuplicityRenameNewStr +
                  StrToIFXStr(IntToStr(Cntr))) >= 0 do Inc(Cntr);
                KeyName := KeyName + fSettingsPtr^.DuplicityRenameNewStr + StrToIFXStr(IntToStr(Cntr));
              end
            else KeyName := KeyName + fSettingsPtr^.DuplicityRenameNewStr;
            KeyNode := TIFXKeyNode.Create(KeyName,fCurrentSectionNode.SettingsPtr);
            KeyNode.Comment := KeyCmnt;
            KeyNode.InlineComment := ICmnt;
            KeyNode.ValueStr := fProcessedLine;
            fCurrentSectionNode.AddKeyNode(KeyNode);
          end;
      else
        {idbDrop}
        // do nothing, discard everything
      end
    else
      begin
        KeyNode := TIFXKeyNode.Create(KeyName,fCurrentSectionNode.SettingsPtr);
        KeyNode.Comment := KeyCmnt;
        KeyNode.InlineComment := ICmnt;
        KeyNode.ValueStr := fProcessedLine;
        fCurrentSectionNode.AddKeyNode(KeyNode);
      end;
    fLastTextLineType := itltKey;
  end
else fLastTextLineType := itltEmpty;
end;

//------------------------------------------------------------------------------

Function TIFXParser.Binary_0000_WriteString(const Str: TIFXString): TMemSize;
var
  TempStr:  UTF8String;
begin
If Length(Str) > 0 then
  begin
    TempStr := IFXStrToUTF8(Str);
    Result := Stream_WriteUInt32(fStream,Length(TempStr));
    Inc(Result,Stream_WriteBuffer(fStream,PUTF8Char(TempStr)^,Length(TempStr) * SizeOf(UTF8Char)));
  end
else Result := Stream_WriteUInt32(fStream,0);
end;

//------------------------------------------------------------------------------

Function TIFXParser.Binary_0000_WriteSection(SectionNode: TIFXSectionNode): TMemSize;
var
  i:  Integer;
begin
Result := Stream_WriteUInt32(fStream,IFX_BINI_SIGNATURE_SECTION);
Inc(Result,Binary_0000_WriteString(SectionNode.NameStr));
Inc(Result,Binary_0000_WriteString(SectionNode.Comment));
Inc(Result,Binary_0000_WriteString(SectionNode.InlineComment));
Inc(Result,Stream_WriteUInt32(fStream,SectionNode.KeyCount));
For i := SectionNode.LowIndex to SectionNode.HighIndex do
  Inc(Result,Binary_0000_WriteKey(SectionNode[i]));
end;

//------------------------------------------------------------------------------

Function TIFXParser.Binary_0000_WriteKey(KeyNode: TIFXKeyNode): TMemSize;
begin
Result := Stream_WriteUInt32(fStream,IFX_BINI_SIGNATURE_KEY);
Inc(Result,Binary_0000_WriteString(KeyNode.NameStr));
Inc(Result,Binary_0000_WriteString(KeyNode.Comment));
Inc(Result,Binary_0000_WriteString(KeyNode.InlineComment));
Inc(Result,Stream_WriteUInt8(fStream,UInt8(IFXValueEncodingToByte(KeyNode.ValueEncoding))));
Inc(Result,Stream_WriteUInt8(fStream,UInt8(IFXValueTypeToByte(KeyNode.ValueType))));
case KeyNode.ValueType of
  ivtBool:      Inc(Result,Stream_WriteBoolean(fStream,KeyNode.ValueData.BoolValue));
  ivtInt8:      Inc(Result,Stream_WriteInt8(fStream,KeyNode.ValueData.Int8Value));
  ivtUInt8:     Inc(Result,Stream_WriteUInt8(fStream,KeyNode.ValueData.UInt8Value));
  ivtInt16:     Inc(Result,Stream_WriteInt16(fStream,KeyNode.ValueData.Int16Value));
  ivtUInt16:    Inc(Result,Stream_WriteUInt16(fStream,KeyNode.ValueData.UInt16Value));
  ivtInt32:     Inc(Result,Stream_WriteInt32(fStream,KeyNode.ValueData.Int32Value));
  ivtUInt32:    Inc(Result,Stream_WriteUInt32(fStream,KeyNode.ValueData.UInt32Value));
  ivtInt64:     Inc(Result,Stream_WriteInt64(fStream,KeyNode.ValueData.Int64Value));
  ivtUInt64:    Inc(Result,Stream_WriteUInt64(fStream,KeyNode.ValueData.UInt64Value));
  ivtFloat32:   Inc(Result,Stream_WriteFloat32(fStream,KeyNode.ValueData.Float32Value));
  ivtFloat64:   Inc(Result,Stream_WriteFloat64(fStream,KeyNode.ValueData.Float64Value));
  ivtDate:      Inc(Result,Stream_WriteBuffer(fStream,KeyNode.ValueData.DateValue,SizeOf(TDateTime)));
  ivtTime:      Inc(Result,Stream_WriteBuffer(fStream,KeyNode.ValueData.TimeValue,SizeOf(TDateTime)));
  ivtDateTime:  Inc(Result,Stream_WriteBuffer(fStream,KeyNode.ValueData.DateTimeValue,SizeOf(TDateTime)));
  ivtBinary:    begin
                  Inc(Result,Stream_WriteUInt64(fStream,UInt64(KeyNode.ValueData.BinaryValueSize)));
                  Inc(Result,Stream_WriteBuffer(fStream,KeyNode.ValueData.BinaryValuePtr^,KeyNode.ValueData.BinaryValueSize));
                end;
  ivtString:    Inc(Result,Binary_0000_WriteString(KeyNode.ValueData.StringValue));
else
  {ivtUndecided}
  Inc(Result,Binary_0000_WriteString(KeyNode.ValueStr));
end;
end;

//------------------------------------------------------------------------------

Function TIFXParser.Binary_0000_ReadString: TIFXString;
var
  StrLen:   UInt32;
  TempStr:  UTF8String;
begin
If Stream_ReadUInt32(fStream,StrLen) = SizeOf(UInt32) then
  begin
    SetLength(TempStr,StrLen);
    If Stream_ReadBuffer(fStream,PUTF8Char(TempStr)^,StrLen * SizeOf(UTF8Char)) = (StrLen * SizeOf(UTF8Char)) then
      Result := UTF8ToIFXStr(TempStr)
    else
      raise Exception.Create('TIFXParser.Binary_0000_ReadString: Error reading string.');
  end
else raise Exception.Create('TIFXParser.Binary_0000_ReadString: Error reading string length.');
end;

//------------------------------------------------------------------------------

procedure TIFXParser.Binary_0000_ReadData;
var
  i:            Integer;
  SectionNode:  TIFXSectionNode;
begin
fFileNode.Comment := Binary_0000_ReadString;
If (fStream.Size - fStream.Position) >= SizeOf(UInt32) then
  begin
    For i := 0 to Pred(Integer(Stream_ReadUInt32(fStream))) do
      If Binary_0000_ReadSection(SectionNode) then
        fFileNode.AddSectionNode(SectionNode);
  end
else raise Exception.Create('TIFXParser.Binary_0000_ReadData: Not enough data for section count.');
end;

//------------------------------------------------------------------------------

Function TIFXParser.Binary_0000_ReadSection(out SectionNode: TIFXSectionNode): Boolean;
var
  SectName: TIFXString;
  i,Cntr:   Integer;
  KeyNode:  TIFXKeyNode;
begin
Result := True;
SectionNode := TIFXSectionNode.Create(fFileNode.SettingsPtr);
try
  If (fStream.Size - fStream.Position) >= (SizeOf(UInt32) * 4) then
    begin
      If Stream_ReadUInt32(fStream) = IFX_BINI_SIGNATURE_SECTION then
        begin
          SectName := Binary_0000_ReadString;
          i := fFileNode.IndexOfSection(SectName);
          If i >= 0 then
            // section with the same name is already present, decide what to
            // do next according to duplicity behavior
            case fSettingsPtr^.DuplicityBehavior of
              idbReplace:
                begin
                  // discard created node, use the one present, replace comment
                  SectionNode.Free;
                  SectionNode := fFileNode[i];
                  SectionNode.Comment := Binary_0000_ReadString;
                  SectionNode.InlineComment := Binary_0000_ReadString;
                  Result := False;
                end;
              idbRenameOld:
                begin
                  // use the new node, rename the old one
                  SectionNode.NameStr := SectName;
                  SectionNode.Comment := Binary_0000_ReadString;
                  SectionNode.InlineComment := Binary_0000_ReadString;
                  If fFileNode.IndexOfSection(SectName + fSettingsPtr^.DuplicityRenameOldStr) >= 0 then
                    begin
                      Cntr := 0;
                      while fFileNode.IndexOfSection(SectName + fSettingsPtr^.DuplicityRenameOldStr +
                        StrToIFXStr(IntToStr(Cntr))) >= 0 do Inc(Cntr);
                      fFileNode[i].NameStr := SectName + fSettingsPtr^.DuplicityRenameOldStr +
                        StrToIFXStr(IntToStr(Cntr));
                    end
                  else fFileNode[i].NameStr := SectName + fSettingsPtr^.DuplicityRenameOldStr;
                end;
              idbRenameNew:
                begin
                  // rename the new node, don't touch the old one
                  If fFileNode.IndexOfSection(SectName + fSettingsPtr^.DuplicityRenameNewStr) >= 0 then
                    begin
                      Cntr := 0;
                      while fFileNode.IndexOfSection(SectName + fSettingsPtr^.DuplicityRenameNewStr +
                        StrToIFXStr(IntToStr(Cntr))) >= 0 do Inc(Cntr);
                      SectionNode.NameStr := SectName + fSettingsPtr^.DuplicityRenameNewStr +
                        StrToIFXStr(IntToStr(Cntr));
                    end
                  else SectionNode.NameStr := SectName + fSettingsPtr^.DuplicityRenameNewStr;
                  SectionNode.Comment := Binary_0000_ReadString;
                  SectionNode.InlineComment := Binary_0000_ReadString;
                end;
            else
              {idbDrop}
              // discard created node, use the one already present, discard comments
              SectionNode.Free;
              SectionNode := fFileNode[i];
              Binary_0000_ReadString; // comment
              Binary_0000_ReadString; // inline comment
              Result := False;
            end
          else
            begin
              // section is not yet in the file
              SectionNode.NameStr := SectName;
              SectionNode.Comment := Binary_0000_ReadString;
              SectionNode.InlineComment := Binary_0000_ReadString;
            end;
          If (fStream.Size - fStream.Position) >= SizeOf(UInt32) then
            begin
              For i := 0 to Pred(Integer(Stream_ReadUInt32(fStream))) do
                If Binary_0000_ReadKey(SectionNode,KeyNode) then
                  SectionNode.AddKeyNode(KeyNode);
            end
          else raise Exception.Create('TIFXParser.Binary_0000_ReadSection: Not enough data for key count.');
        end
      else raise Exception.Create('TIFXParser.Binary_0000_ReadSection: Wrong section signature.');
    end
  else raise Exception.Create('TIFXParser.Binary_0000_ReadSection: Not enough data for section.');
except
  FreeAndNil(SectionNode);
  raise;
end;
end;

//------------------------------------------------------------------------------

Function TIFXParser.Binary_0000_ReadKey(SectionNode: TIFXSectionNode; out KeyNode: TIFXKeyNode): Boolean;
var
  KeyName:    TIFXString;
  BinSize:    UInt64;
  Index:      Integer;
  Cntr:       Integer;
  FreeNode:   Boolean;
  ValueType:  TIFXValueType;
  TempValue:  TIFXValueData;

  procedure ValReadCheckAndRaise(Val,Exp: TMemSize);
  begin
    If Val <> Exp then
      raise Exception.Create('TIFXParser.Binary_0000_ReadKey: Not enough data for key value.');
  end;

begin
FreeNode := False;
Result := True;
KeyNode := TIFXKeyNode.Create(fFileNode.SettingsPtr);
try
  If (fStream.Size - fStream.Position) >= ((SizeOf(UInt32) * 3) + 2{value enc. and type}) then
    begin
      If Stream_ReadUInt32(fStream) = IFX_BINI_SIGNATURE_KEY then
        begin
          KeyName := Binary_0000_ReadString;
          Index := SectionNode.IndexOfKey(KeyName);
          If Index >= 0 then
            // key with the same name is already present, decide what to do next
            // according to duplicity behavior
            case fSettingsPtr^.DuplicityBehavior of
              idbReplace:
                begin
                  // discard created node, use the one present, replace content
                  KeyNode.Free;
                  KeyNode := SectionNode[Index];
                  KeyNode.NameStr := KeyName;
                  Result := False;
                end;
              idbRenameOld:
                begin
                  // use the new node, rename the old one
                  KeyNode.NameStr := KeyName;
                  If SectionNode.IndexOfKey(KeyName + fSettingsPtr^.DuplicityRenameOldStr) >= 0 then
                    begin
                      Cntr := 0;
                      while SectionNode.IndexOfKey(KeyName + fSettingsPtr^.DuplicityRenameOldStr +
                        StrToIFXStr(IntToStr(Cntr))) >= 0 do Inc(Cntr);
                      SectionNode[Index].NameStr := KeyName + fSettingsPtr^.DuplicityRenameOldStr +
                        StrToIFXStr(IntToStr(Cntr));
                    end
                  else SectionNode[Index].NameStr := KeyName + fSettingsPtr^.DuplicityRenameOldStr;
                end;
              idbRenameNew:
                begin
                  // rename the new node, don't touch the old one
                  If SectionNode.IndexOfKey(KeyName + fSettingsPtr^.DuplicityRenameNewStr) >= 0 then
                    begin
                      Cntr := 0;
                      while SectionNode.IndexOfKey(KeyName + fSettingsPtr^.DuplicityRenameNewStr +
                        StrToIFXStr(IntToStr(Cntr))) >= 0 do Inc(Cntr);
                      KeyNode.NameStr := KeyName + fSettingsPtr^.DuplicityRenameNewStr +
                        StrToIFXStr(IntToStr(Cntr));
                    end
                  else KeyNode.NameStr := KeyName + fSettingsPtr^.DuplicityRenameNewStr;
                end;
            else
              {idbDrop}
              // discard created node (will be freed at the end of this funtion
              // since the actual reading must be performed)
              Result := False;
              FreeNode := True;
            end
          else
            begin
              // key is not yet in the section
              KeyNode.NameStr := KeyName;
            end;
          KeyNode.Comment := Binary_0000_ReadString;
          KeyNode.InlineComment := Binary_0000_ReadString;
          KeyNode.ValueEncoding := IFXByteToValueEncoding(Stream_ReadUInt8(fStream));
          ValueType := IFXByteToValueType(Stream_ReadUInt8(fStream));
          TempValue.StringValue := '';
          // read value data to temporary storage
          case ValueType of
            ivtBool:      ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.BoolValue,SizeOf(Boolean)),SizeOf(Boolean));
            ivtInt8:      ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.Int8Value,SizeOf(Int8)),SizeOf(Int8));
            ivtUInt8:     ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.UInt8Value,SizeOf(UInt8)),SizeOf(UInt8));
            ivtInt16:     ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.Int16Value,SizeOf(Int16)),SizeOf(Int16));
            ivtUInt16:    ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.UInt16Value,SizeOf(UInt16)),SizeOf(UInt16));
            ivtInt32:     ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.Int32Value,SizeOf(Int32)),SizeOf(Int32));
            ivtUInt32:    ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.UInt32Value,SizeOf(UInt32)),SizeOf(UInt32));
            ivtInt64:     ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.Int64Value,SizeOf(Int64)),SizeOf(Int64));
            ivtUInt64:    ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.UInt64Value,SizeOf(UInt64)),SizeOf(UInt64));
            ivtFloat32:   ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.Float32Value,SizeOf(Float32)),SizeOf(Float32));
            ivtFloat64:   ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.Float64Value,SizeOf(Float64)),SizeOf(Float64));
            ivtDate:      ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.DateValue,SizeOf(TDateTime)),SizeOf(TDateTime));
            ivtTime:      ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.TimeValue,SizeOf(TDateTime)),SizeOf(TDateTime));
            ivtDateTime:  ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.DateTimeValue,SizeOf(TDateTime)),SizeOf(TDateTime));
            ivtBinary:    begin
                            ValReadCheckAndRaise(Stream_ReadUInt64(fStream,BinSize),SizeOf(UInt64));
                          {$IFNDEF 64bit}
                            If BinSize > UInt64(High(TMemSize)) then
                              raise Exception.Create('TIFXParser.Binary_0000_ReadKey: Too much raw data.');
                          {$ENDIF}
                            TempValue.BinaryValueSize := TMemSize(BinSize);
                            GetMem(TempValue.BinaryValuePtr,TempValue.BinaryValueSize);
                            try
                              ValReadCheckAndRaise(Stream_ReadBuffer(fStream,TempValue.BinaryValuePtr^,TempValue.BinaryValueSize),
                                                   TempValue.BinaryValueSize);
                              TempValue.BinaryValueOwned := True;
                            except
                              FreeMem(TempValue.BinaryValuePtr,TempValue.BinaryValueSize);
                              TempValue.BinaryValuePtr := nil;
                              raise;
                            end;
                          end;
            ivtString:    TempValue.StringValue := Binary_0000_ReadString;
          else
            {ivtUndecided}
            KeyNode.ValueStr := Binary_0000_ReadString;
          end;
          // assign values to key
          case ValueType of
            ivtBool:      KeyNode.SetValueBool(TempValue.BoolValue);
            ivtInt8:      KeyNode.SetValueInt8(TempValue.UInt8Value);
            ivtUInt8:     KeyNode.SetValueUInt8(TempValue.UInt8Value);
            ivtInt16:     KeyNode.SetValueInt16(TempValue.Int16Value);
            ivtUInt16:    KeyNode.SetValueUInt16(TempValue.UInt16Value);
            ivtInt32:     KeyNode.SetValueInt32(TempValue.Int32Value);
            ivtUInt32:    KeyNode.SetValueUInt32(TempValue.UInt32Value);
            ivtInt64:     KeyNode.SetValueInt64(TempValue.Int64Value);
            ivtUInt64:    KeyNode.SetValueUInt64(TempValue.UInt64Value);
            ivtFloat32:   KeyNode.SetValueFloat32(TempValue.Float32Value);
            ivtFloat64:   KeyNode.SetValueFloat64(TempValue.Float64Value);
            ivtDate:      KeyNode.SetValueDate(TempValue.DateValue);
            ivtTime:      KeyNode.SetValueTime(TempValue.TimeValue);
            ivtDateTime:  KeyNode.SetValueDateTime(TempValue.DateTimeValue);
            ivtBinary:    begin
                            KeyNode.SetValueBinary(TempValue.BinaryValuePtr,TempValue.BinaryValueSize,False);
                            KeyNode.ValueDataPtr^.BinaryValueOwned := True;
                          end;
            ivtString:    KeyNode.SetValueString(TempValue.StringValue);
          else
            {ivtUndecided}
            // do nothing, already assigned to key
          end;
        end
      else raise Exception.Create('TIFXParser.Binary_0000_ReadKey: Wrong key signature.');
    end
  else raise Exception.Create('TIFXParser.Binary_0000_ReadKey: Not enough data for key.');
except
  FreeAndNil(KeyNode);
  raise;
end;
If FreeNode then FreeAndNil(KeyNode); 
end;

{-------------------------------------------------------------------------------
    TIFXParser - public methods
-------------------------------------------------------------------------------}

class Function TIFXParser.IsBinaryIniStream(Stream: TStream): Boolean;
begin
If (Stream.Size - Stream.Position) >= IFX_BINI_MINFILESIZE then
  Result := Stream_ReadUInt32(Stream,False) = IFX_BINI_SIGNATURE_FILE
else
  Result := False;
end;

//------------------------------------------------------------------------------

class Function TIFXParser.IsBinaryIniFile(const FileName: String): Boolean;
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
try
  Result := IsBinaryIniStream(FileStream);
finally
  FileStream.Free;
end;
end;

//------------------------------------------------------------------------------

constructor TIFXParser.Create(SettingsPtr: PIFXSettings; FileNode: TIFXFileNode);
begin
inherited Create;
fSettingsPtr := SettingsPtr;
fFileNode := FileNode;
end;

//------------------------------------------------------------------------------

Function TIFXParser.ConstructCommentBlock(const CommentStr: TIFXString): TIFXString;
var
  i,j:  TStrSize;
  Temp: TStrSize;
begin
If Length(CommentStr) > 0 then
  begin
    // first pass - count how many characters the result should have
    Temp := 1{first comment mark};
    i := 1;
    while i <= Length(CommentStr) do
      begin
        If Ord(CommentStr[i]) in [10,13] then
          begin
            Inc(Temp,1{comment mark} + Length(fSettingsPtr^.TextIniSettings.LineBreak));
            If i < Length(CommentStr) then
              If (Ord(CommentStr[i + 1]) in [10,13]) and
                (CommentStr[i] <> CommentStr[i + 1]) then
                Inc(i);
          end
        else Inc(Temp);
        Inc(i);
      end;
    // second pass - build result, replace current linebreaks with the one
    // specified in settings
    SetLength(Result,Temp);
    i := 1;
    Temp := 2;  // will be used to index result string
    Result[1] := fSettingsPtr^.TextIniSettings.CommentChar;
    while i <= Length(CommentStr) do
      begin
        If Ord(CommentStr[i]) in [10,13] then
          begin
            If i < Length(CommentStr) then
              If (Ord(CommentStr[i + 1]) in [10,13]) and
                (CommentStr[i] <> CommentStr[i + 1]) then
                Inc(i);
            For j := 0 to Pred(Length(fSettingsPtr^.TextIniSettings.LineBreak)) do
              Result[Temp + j] := fSettingsPtr^.TextIniSettings.LineBreak[j + 1];
            Inc(Temp,Length(fSettingsPtr^.TextIniSettings.LineBreak));
            Result[Temp] := fSettingsPtr^.TextIniSettings.CommentChar;
          end
        else Result[Temp] := CommentStr[i];
        Inc(i);
        Inc(Temp);
      end;
  end
else Result := '';
end;

//------------------------------------------------------------------------------

Function TIFXParser.ConstructSectionName(SectionNode: TIFXSectionNode): TIFXString;
begin
SetLength(Result,Length(SectionNode.NameStr) + 2{section name start and end char});
Result[1] := fSettingsPtr^.TextIniSettings.SectionStartChar;
Result[Length(Result)] := fSettingsPtr^.TextIniSettings.SectionEndChar;
If Length(SectionNode.NameStr) > 0 then
  Move(PIFXChar(SectionNode.NameStr)^,Result[2],Length(SectionNode.NameStr) * SizeOf(TIFXChar));
end;

//------------------------------------------------------------------------------

Function TIFXParser.ConstructKeyValueLine(KeyNode: TIFXKeyNode; out ValueStart: TStrSize): TIFXString;
var
  Temp: TStrSize;
begin
// get length of the resulting string
Temp := Length(KeyNode.NameStr) + Length(KeyNode.ValueStr) + 1{ValueDelimChar};
If fSettingsPtr^.TextIniSettings.KeyWhiteSpace then
  Inc(Temp{WhiteSpaceChar});
If fSettingsPtr^.TextIniSettings.ValueWhiteSpace then
  Inc(Temp{WhiteSpaceChar});
SetLength(Result,Temp);
// build resulting string
Temp := 1;
If Length(KeyNode.NameStr) > 0 then
  Move(KeyNode.NameStr[1],Result[Temp],Length(KeyNode.NameStr) * SizeOf(TIFXChar));
Inc(Temp,Length(KeyNode.NameStr));
If fSettingsPtr^.TextIniSettings.KeyWhiteSpace then
  begin
    Result[Temp] := fSettingsPtr^.TextIniSettings.WhiteSpaceChar;
    Inc(Temp{WhiteSpaceChar});
  end;
Result[Temp] := fSettingsPtr^.TextIniSettings.ValueDelimChar;
Inc(Temp{ValueDelimChar});
If fSettingsPtr^.TextIniSettings.KeyWhiteSpace then
  begin
    Result[Temp] := fSettingsPtr^.TextIniSettings.WhiteSpaceChar;
    Inc(Temp{WhiteSpaceChar});
  end;
ValueStart := Temp;
If Length(KeyNode.ValueStr) > 0 then
  Move(KeyNode.ValueStr[1],Result[Temp],Length(KeyNode.ValueStr) * SizeOf(TIFXChar));
end;

//------------------------------------------------------------------------------

Function TIFXParser.PrepareInlineComment(const CommentStr: TIFXString): TIFXString;
var
  i,ResPos:  TStrSize;
begin
If Length(CommentStr) > 0 then
  begin
    SetLength(Result,Length(CommentStr) + 2);
    Result[1] := fSettingsPtr^.TextIniSettings.WhiteSpaceChar;
    Result[2] := fSettingsPtr^.TextIniSettings.CommentChar;
    ResPos := 3;
    For i := 1 to Length(CommentStr) do
      If (Ord(CommentStr[i]) >= 32) and (CommentStr[i] <> fSettingsPtr^.TextIniSettings.CommentChar) and
        (CommentStr[i] <> fSettingsPtr^.TextIniSettings.EscapeChar) then
        begin
          Result[ResPos] := CommentStr[i];
          Inc(ResPos);
        end;
    SetLength(Result,ResPos - 1);
  end
else Result := '';
end;

//------------------------------------------------------------------------------

procedure TIFXParser.WriteTextual(Stream: TStream);
var
  SectionNode:  TIFXSectionNode;
  i:            Integer;
begin
fStream := Stream;
// write BOM if requested
If fSettingsPtr^.TextIniSettings.WriteByteOrderMask then
  Stream_WriteBuffer(fStream,IFX_UTF8BOM,SizeOf(IFX_UTF8BOM));
fEmptyLinePos := fStream.Position;
// write file comment
Text_WriteString(ConstructCommentBlock(fFileNode.Comment));
If fFileNode.Count > 0 then
  begin
    // write section-less values if any present
    If fFileNode.FindSection('',SectionNode) then
      begin
        Text_WriteEmptyLine;
        Text_WriteString(ConstructCommentBlock(SectionNode.Comment));
        If SectionNode.Count > 0 then
          Text_WriteEmptyLine;
        // write values
        For i := SectionNode.LowIndex to SectionNode.HighIndex do
          Text_WriteKey(SectionNode[i]);
      end;
    // write other sections
    For i := fFileNode.LowIndex to fFileNode.HighIndex do
      If IFXCompareText('',fFileNode[i].NameStr) <> 0 then
        Text_WriteSection(fFileNode[i]);
  end;
end;

//------------------------------------------------------------------------------

procedure TIFXParser.ReadTextual(Stream: TStream);
var
  i:        Integer;
  TempStr:  TIFXString;
begin
// prepare stringlist for parsing of lines
fIniStrings := TUTF8StringList.Create;
try
  fLastComment := '';
  fFileCommentSet := False;
  fIniStrings.LoadFromStream(Stream);
  If fIniStrings.Count > 0 then
    begin
      // traverse and parse lines  
      fLastTextLineType := itltEmpty;
      fCurrentSectionNode := nil;
      TempStr := '';
      For i := fIniStrings.LowIndex to fIniStrings.HighIndex do
        begin
          // remove any leading or trailing whitespaces
          TempStr := IFXTrimStr(UTF8ToIFXStr(fIniStrings[i]));
          If Length(TempStr) > 0 then
            begin
              If Length(fProcessedLine) > 0 then
                begin
                  // continuation of previous line
                  If TempStr[Length(TempStr)] <> fSettingsPtr^.TextIniSettings.EscapeChar then
                    begin
                      // line terminates, process it
                      fProcessedLine := fProcessedLine + TempStr;
                      Text_ReadLine;
                    end
                  // line will continue
                  else fProcessedLine := fProcessedLine + Copy(TempStr,1,Length(TempStr) - 1);
                end
              else
                begin
                  // new line
                  If TempStr[Length(TempStr)] <> fSettingsPtr^.TextIniSettings.EscapeChar then
                    begin
                      // line will not continue
                      fProcessedLine := TempStr;
                      Text_ReadLine;
                    end
                  // line will continue
                  else fProcessedLine := Copy(TempStr,1,Length(TempStr) - 1);;
                end;
            end
          else
            begin
              // empty line, must be processed
              fProcessedLine := '';
              Text_ReadLine;
            end;
        end;
      If Length(fProcessedLine) > 0 then
        Text_ReadLine;
    end;
finally
  FreeAndNil(fIniStrings);
end;
fCurrentSectionNode := nil;
end;

//------------------------------------------------------------------------------

procedure TIFXParser.WriteBinary(Stream: TStream);
var
  i:  Integer;
begin
// prepare file header, size will be filled later
fBinFileHeader.Signature := IFX_BINI_SIGNATURE_FILE;
fBinFileHeader.Structure := IFX_BINI_DATASTRUCT_0;  // later implement selectable
// set data flags
fBinFileHeader.Flags := 0;
If fSettingsPtr^.BinaryIniSettings.CompressData then
  fBinFileHeader.Flags := fBinFileHeader.Flags or IFX_BINI_FLAGS_ZLIB_COMPRESS;
If fSettingsPtr^.BinaryIniSettings.DataEncryption = ideAES then
  fBinFileHeader.Flags := fBinFileHeader.Flags or IFX_BINI_FLAGS_AES_ENCRYPT;
// prepare stream for data
fStream := TMemoryStream.Create;
try
  case fBinFileHeader.Structure of
    IFX_BINI_DATASTRUCT_0:
      begin
        // write data to temp stream
        Binary_0000_WriteString(fFileNode.Comment);
        Stream_WriteUInt32(fStream,UInt32(fFileNode.SectionCount));
        For i := fFileNode.LowIndex to fFileNode.HighIndex do
          Binary_0000_WriteSection(fFileNode[i]);
        // data compression
        If fSettingsPtr^.BinaryIniSettings.CompressData then
          begin
            fStream.Seek(0,soBeginning);
            ZCompressStream(fStream);
          end;
        // AES data encryption
        with fSettingsPtr^.BinaryIniSettings do
          If DataEncryption = ideAES then
            with AES.TAESCipherAccelerated.Create(AESEncryptionKey,AESEncryptionVector,r128bit,cmEncrypt) do
            try
              fStream.Seek(0,soBeginning);
              ProcessStream(fStream);
            finally
              Free;
            end;
        fBinFileHeader.DataSize := UInt64(fStream.Size);
        // save header and complete data to output stream
        Stream_WriteBuffer(Stream,fBinFileHeader,SizeOf(TIFXBiniFileHeader));                
        Stream_WriteBuffer(Stream,TMemoryStream(fStream).Memory^,fStream.Size);
      end;
  else
    raise Exception.CreateFmt('TIFXParser.WriteBinary: Unknown binary format (%d).',[fBinFileHeader.Structure]);
  end;
finally
  FreeAndNil(fStream);
end
end;

//------------------------------------------------------------------------------

procedure TIFXParser.ReadBinary(Stream: TStream);
begin
If (Stream.Size - Stream.Position) >= SizeOf(TIFXBiniFileHeader) then
  begin
    Stream_ReadBuffer(Stream,fBinFileHeader,SizeOf(TIFXBiniFileHeader));
    // check signature
    If fBinFileHeader.Signature = IFX_BINI_SIGNATURE_FILE then
      begin
        If (Stream.Size - Stream.Position) >= fBinFileHeader.DataSize then
          begin
            fStream := TMemoryStream.Create;
            try
              fStream.CopyFrom(Stream,fBinFileHeader.DataSize);
              // AES data decryption
              If (fBinFileHeader.Flags and IFX_BINI_FLAGS_AES_ENCRYPT) <> 0 then
                with fSettingsPtr^.BinaryIniSettings do
                  with AES.TAESCipherAccelerated.Create(AESEncryptionKey,AESEncryptionVector,r128bit,cmDecrypt) do
                  try
                    fStream.Seek(0,soBeginning);
                    ProcessStream(fStream);
                  finally
                    Free;
                  end;
              // data decompression
              If (fBinFileHeader.Flags and IFX_BINI_FLAGS_ZLIB_COMPRESS) <> 0 then
                begin
                  fStream.Seek(0,soBeginning);
                  ZDecompressStream(fStream);
                end;
              fStream.Seek(0,soBeginning);
              case fBinFileHeader.Structure of
                IFX_BINI_DATASTRUCT_0:  Binary_0000_ReadData;
              else
                raise Exception.CreateFmt('TIFXParser.ReadBinary: Unknown binary format (%d).',[fBinFileHeader.Structure]);
              end;
            finally
              fStream.Free;
            end;
          end
        else raise Exception.Create('TIFXParser.ReadBinary: Stream is too small for declared data.');
      end
    else raise Exception.CreateFmt('TIFXParser.ReadBinary: Wrong file signature (0x%.8x).',[fBinFileHeader.Signature]);
  end
else raise Exception.CreateFmt('TIFXParser.ReadBinary: Not enough data (%d) for file header.',[Stream.Size - Stream.Position]);
end;

end.

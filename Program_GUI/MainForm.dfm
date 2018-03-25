object fMainForm: TfMainForm
  Left = 787
  Top = 116
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'SII Decrypt'
  ClientHeight = 307
  ClientWidth = 464
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object bvlHor_Progress: TBevel
    Left = 8
    Top = 208
    Width = 449
    Height = 9
    Shape = bsTopLine
  end
  object lblProgress: TLabel
    Left = 8
    Top = 248
    Width = 46
    Height = 13
    Caption = 'Progress:'
  end
  object leInputFile: TLabeledEdit
    Left = 8
    Top = 24
    Width = 424
    Height = 21
    EditLabel.Width = 47
    EditLabel.Height = 13
    EditLabel.Caption = 'Input file:'
    TabOrder = 0
  end
  object btnBrowseInFile: TButton
    Left = 432
    Top = 24
    Width = 25
    Height = 21
    Caption = '...'
    TabOrder = 1
    OnClick = btnBrowseInFileClick
  end
  object leOutputFile: TLabeledEdit
    Left = 8
    Top = 72
    Width = 424
    Height = 21
    EditLabel.Width = 104
    EditLabel.Height = 13
    EditLabel.Caption = 'Output file (optional):'
    TabOrder = 2
  end
  object btnBrowseOutFile: TButton
    Left = 432
    Top = 72
    Width = 25
    Height = 21
    Caption = '...'
    TabOrder = 3
    OnClick = btnBrowseOutFileClick
  end
  object pbProgress: TProgressBar
    Left = 8
    Top = 264
    Width = 449
    Height = 17
    Max = 1000
    TabOrder = 6
  end
  object stbStatusBar: TStatusBar
    Left = 0
    Top = 288
    Width = 464
    Height = 19
    Panels = <
      item
        Alignment = taRightJustify
        Text = '-copyright-'
        Width = 50
      end>
  end
  object btnStartProcessing: TButton
    Left = 8
    Top = 216
    Width = 449
    Height = 25
    Caption = 'Start processing'
    TabOrder = 5
    OnClick = btnStartProcessingClick
  end
  object gbOptions: TGroupBox
    Left = 8
    Top = 104
    Width = 449
    Height = 97
    Caption = 'Options'
    TabOrder = 4
    object cbNoDecode: TCheckBox
      Left = 8
      Top = 24
      Width = 209
      Height = 17
      Caption = 'Do not attempt decoding, only decrypt'
      TabOrder = 0
    end
    object cbAccelAES: TCheckBox
      Left = 8
      Top = 48
      Width = 401
      Height = 17
      Caption = 
        'Allow hardware-accelerated AES decryption (AES-NI instruction se' +
        't extension)'
      Checked = True
      State = cbChecked
      TabOrder = 1
    end
    object cbInMemProc: TCheckBox
      Left = 8
      Top = 72
      Width = 193
      Height = 17
      Caption = 'Do entire file processing in memory'
      Checked = True
      State = cbChecked
      TabOrder = 2
    end
  end
  object oXPManifest: TXPManifest
    Left = 80
  end
  object diaOpenInputFile: TOpenDialog
    Filter = 'SII save files (*.sii)|*.sii|All files (*.*)|*.*'
    Left = 112
  end
  object diaSaveOutputFile: TSaveDialog
    DefaultExt = '.sii'
    Filter = 'SII save files (*.sii)|*.sii|All files (*.*)|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 144
  end
end

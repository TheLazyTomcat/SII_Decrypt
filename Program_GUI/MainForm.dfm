object fMainForm: TfMainForm
  Left = 787
  Top = 116
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'SII Decrypt GUI'
  ClientHeight = 204
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
    Top = 104
    Width = 449
    Height = 9
    Shape = bsTopLine
  end
  object lblProgress: TLabel
    Left = 8
    Top = 144
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
    EditLabel.Width = 55
    EditLabel.Height = 13
    EditLabel.Caption = 'Output file:'
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
    Top = 160
    Width = 449
    Height = 17
    Max = 1000
    TabOrder = 5
  end
  object sbStatusBar: TStatusBar
    Left = 0
    Top = 185
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
    Top = 112
    Width = 449
    Height = 25
    Caption = 'Start processing'
    TabOrder = 4
    OnClick = btnStartProcessingClick
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
    Left = 144
  end
end

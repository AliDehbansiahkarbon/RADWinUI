object OrdersForm: TOrdersForm
  Left = 0
  Top = 0
  Caption = 'Ember Orders (VCL and WinUI)'
  ClientHeight = 560
  ClientWidth = 1020
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object Splitter: TSplitter
    Left = 560
    Top = 41
    Height = 500
  end
  object ToolbarPanel: TPanel
    Left = 0
    Top = 0
    Width = 1020
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object Navigator: TDBNavigator
      Left = 8
      Top = 8
      Width = 240
      Height = 25
      DataSource = RoasteryData.OrdersSource
      TabOrder = 0
    end
  end
  object OrdersGrid: TDBGrid
    Left = 0
    Top = 41
    Width = 560
    Height = 500
    Align = alLeft
    DataSource = RoasteryData.OrdersSource
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
    ReadOnly = True
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
    Columns = <
      item
        Expanded = False
        FieldName = 'OrderNo'
        Width = 50
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'OrderDate'
        Width = 76
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Customer'
        Width = 140
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Coffee'
        Width = 90
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Kg'
        Width = 44
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'Status'
        Width = 70
        Visible = True
      end>
  end
  object OrderHost: TWinUIHost
    Left = 563
    Top = 41
    Width = 457
    Height = 500
    XamlFile = 'Panels\OrderCard.xaml'
    Align = alClient
    Color = clBtnFace
    ParentColor = False
    TabOrder = 2
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 541
    Width = 1020
    Height = 19
    Panels = <>
    SimplePanel = True
  end
end

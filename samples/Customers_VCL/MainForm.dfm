object CustomersForm: TCustomersForm
  Left = 0
  Top = 0
  Caption = 'Customers'
  ClientHeight = 480
  ClientWidth = 760
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
    Left = 220
    Top = 41
    Height = 420
  end
  object ToolbarPanel: TPanel
    Left = 0
    Top = 0
    Width = 760
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object NewButton: TButton
      Left = 8
      Top = 8
      Width = 75
      Height = 25
      Caption = '&New'
      TabOrder = 0
      OnClick = NewButtonClick
    end
    object DeleteButton: TButton
      Left = 89
      Top = 8
      Width = 75
      Height = 25
      Caption = '&Delete'
      TabOrder = 1
      OnClick = DeleteButtonClick
    end
  end
  object CustomerList: TListBox
    Left = 0
    Top = 41
    Width = 220
    Height = 420
    Align = alLeft
    ItemHeight = 15
    TabOrder = 1
    OnClick = CustomerListClick
  end
  object DetailsHost: TWinUIHost
    Left = 223
    Top = 41
    Width = 537
    Height = 420
    Xaml.Strings = (
      '<ScrollViewer>'
      
        '  <StackPanel Padding="24" Spacing="12" Width="440" HorizontalAl' +
        'ignment="Left">'
      
        '    <TextBlock Text="Customer details" Style="{StaticResource Su' +
        'btitleTextBlockStyle}"/>'
      
        '    <TextBox x:Name="NameBox" Header="Name" Text="{Binding Name,' +
        ' Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}"/>'
      
        '    <TextBox x:Name="EmailBox" Header="Email" Text="{Binding Ema' +
        'il, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}"/>'
      
        '    <NumberBox x:Name="CreditBox" Header="Credit limit" SpinButt' +
        'onPlacementMode="Inline" SmallChange="500" Value="{Binding Credi' +
        'tLimit, Mode=TwoWay}"/>'
      
        '    <ToggleSwitch x:Name="NewsletterSwitch" Header="Newsletter" ' +
        'IsOn="{Binding Newsletter, Mode=TwoWay}"/>'
      '    <StackPanel Orientation="Horizontal" Spacing="8">'
      
        '      <Button x:Name="SaveButton" Content="Save" Style="{Static' +
        'Resource AccentButtonStyle}"/>'
      
        '      <Button x:Name="RevertButton" Content="Revert" Click="Reve' +
        'rtClick"/>'
      '    </StackPanel>'
      
        '    <InfoBar x:Name="SavedBar" Title="Saved" Message="The custom' +
        'er list is up to date." Severity="Success"/>'
      '  </StackPanel>'
      '</ScrollViewer>')
    Align = alClient
    Color = clBtnFace
    ParentColor = False
    TabOrder = 2
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 461
    Width = 760
    Height = 19
    Panels = <>
    SimplePanel = True
  end
end

object RoasteryData: TRoasteryData
  OnCreate = DataModuleCreate
  Height = 260
  Width = 420
  object Coffees: TFDMemTable
    FieldDefs = <
      item
        Name = 'ID'
        DataType = ftInteger
      end
      item
        Name = 'Name'
        DataType = ftString
        Size = 40
      end
      item
        Name = 'Origin'
        DataType = ftString
        Size = 40
      end
      item
        Name = 'Process'
        DataType = ftString
        Size = 20
      end
      item
        Name = 'Roast'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'Notes'
        DataType = ftString
        Size = 80
      end
      item
        Name = 'StockKg'
        DataType = ftFloat
      end
      item
        Name = 'PricePerKg'
        DataType = ftCurrency
      end>
    IndexFieldNames = 'Name'
    IndexDefs = <>
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    StoreDefs = True
    Left = 48
    Top = 32
  end
  object CoffeesSource: TDataSource
    DataSet = Coffees
    Left = 48
    Top = 112
  end
  object Customers: TFDMemTable
    FieldDefs = <
      item
        Name = 'ID'
        DataType = ftInteger
      end
      item
        Name = 'Name'
        DataType = ftString
        Size = 60
      end
      item
        Name = 'City'
        DataType = ftString
        Size = 40
      end
      item
        Name = 'Contact'
        DataType = ftString
        Size = 40
      end
      item
        Name = 'Email'
        DataType = ftString
        Size = 60
      end
      item
        Name = 'Tier'
        DataType = ftString
        Size = 10
      end>
    IndexFieldNames = 'Name'
    IndexDefs = <>
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    StoreDefs = True
    Left = 168
    Top = 32
  end
  object CustomersSource: TDataSource
    DataSet = Customers
    Left = 168
    Top = 112
  end
  object Orders: TFDMemTable
    BeforePost = OrdersBeforePost
    OnNewRecord = OrdersNewRecord
    FieldDefs = <
      item
        Name = 'OrderNo'
        DataType = ftInteger
      end
      item
        Name = 'OrderDate'
        DataType = ftDate
      end
      item
        Name = 'CustomerID'
        DataType = ftInteger
      end
      item
        Name = 'Customer'
        DataType = ftString
        Size = 60
      end
      item
        Name = 'CoffeeID'
        DataType = ftInteger
      end
      item
        Name = 'Coffee'
        DataType = ftString
        Size = 40
      end
      item
        Name = 'Kg'
        DataType = ftFloat
      end
      item
        Name = 'Total'
        DataType = ftCurrency
      end
      item
        Name = 'Status'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'Note'
        DataType = ftMemo
      end>
    IndexFieldNames = 'OrderNo:D'
    IndexDefs = <>
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    StoreDefs = True
    Left = 288
    Top = 32
  end
  object OrdersSource: TDataSource
    DataSet = Orders
    Left = 288
    Top = 112
  end
end

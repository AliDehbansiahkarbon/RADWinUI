object CustomerData: TCustomerData
  OnCreate = DataModuleCreate
  Height = 260
  Width = 420
  object Countries: TFDMemTable
    FieldDefs = <
      item
        Name = 'ID'
        DataType = ftInteger
      end
      item
        Name = 'CountryName'
        DataType = ftString
        Size = 40
      end>
    IndexFieldNames = 'CountryName'
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
  object CountriesSource: TDataSource
    DataSet = Countries
    Left = 48
    Top = 112
  end
  object Customers: TFDMemTable
    OnNewRecord = CustomersNewRecord
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
        Name = 'CountryID'
        DataType = ftInteger
      end
      item
        Name = 'Tier'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'Balance'
        DataType = ftCurrency
      end
      item
        Name = 'Joined'
        DataType = ftDate
      end
      item
        Name = 'Active'
        DataType = ftBoolean
      end
      item
        Name = 'Newsletter'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'Notes'
        DataType = ftMemo
      end
      item
        Name = 'Logo'
        DataType = ftBlob
      end>
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
    OnNewRecord = OrdersNewRecord
    FieldDefs = <
      item
        Name = 'OrderNo'
        DataType = ftInteger
      end
      item
        Name = 'CustomerID'
        DataType = ftInteger
      end
      item
        Name = 'OrderDate'
        DataType = ftDate
      end
      item
        Name = 'Product'
        DataType = ftString
        Size = 60
      end
      item
        Name = 'Quantity'
        DataType = ftInteger
      end
      item
        Name = 'Total'
        DataType = ftCurrency
      end
      item
        Name = 'Shipped'
        DataType = ftBoolean
      end>
    IndexFieldNames = 'CustomerID;OrderNo'
    MasterSource = CustomersSource
    MasterFields = 'ID'
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

unit RADWinUI.Designer.VclHost;

{
  Object Inspector support for TWinUIHost on VCL forms: XamlFile gets a "..."
  button that picks a .xaml file. The path is stored relative to the project
  folder when the file is in it, and picking a file clears Xaml (the file takes
  over). Registered by RADWinUI.Wizard.Registration.
}

interface

uses
  DesignIntf,
  DesignEditors;

type
  TWinUIXamlFileProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

/// <summary>AFileName relative to AFolder when it is inside it, unchanged otherwise.</summary>
function ProjectRelativePath(const AFileName, AFolder: string): string;

implementation

uses
  System.SysUtils,
  Vcl.Dialogs,
  ToolsAPI;

function ProjectRelativePath(const AFileName, AFolder: string): string;
var
  Folder: string;
begin
  Result := AFileName;
  if AFolder = '' then
    Exit;
  Folder := IncludeTrailingPathDelimiter(AFolder);
  if SameText(Copy(AFileName, 1, Length(Folder)), Folder) then
    Result := Copy(AFileName, Length(Folder) + 1, MaxInt);
end;

function ProjectFolder: string;
var
  Project: IOTAProject;
begin
  Project := GetActiveProject;
  if Project <> nil then
    Result := ExtractFileDir(Project.FileName)
  else
    Result := '';
end;

{ TWinUIXamlFileProperty }

function TWinUIXamlFileProperty.GetAttributes: TPropertyAttributes;
begin
  Result := [paDialog, paMultiSelect, paRevertable];
end;

procedure TWinUIXamlFileProperty.Edit;
var
  Dialog: TFileOpenDialog;
  FileType: TFileTypeItem;
  Folder, Current: string;
begin
  Folder := ProjectFolder;
  Dialog := TFileOpenDialog.Create(nil);
  try
    Dialog.Title := 'XAML file of ' + GetComponent(0).GetNamePath;
    FileType := Dialog.FileTypes.Add;
    FileType.DisplayName := 'XAML files (*.xaml)';
    FileType.FileMask := '*.xaml';
    FileType := Dialog.FileTypes.Add;
    FileType.DisplayName := 'All files (*.*)';
    FileType.FileMask := '*.*';
    Dialog.DefaultExtension := 'xaml';
    Dialog.Options := Dialog.Options + [fdoFileMustExist];
    Current := GetStrValue;
    if (Current <> '') and (Folder <> '') and not IsPathDelimiter(Current, 1) and (ExtractFileDrive(Current) = '') then
      Current := IncludeTrailingPathDelimiter(Folder) + Current;
    if (Current <> '') and FileExists(Current) then
    begin
      Dialog.DefaultFolder := ExtractFileDir(Current);
      Dialog.FileName := ExtractFileName(Current);
    end
    else
      Dialog.DefaultFolder := Folder;
    if Dialog.Execute then
      // Through the property, so every selected host takes it and clears its Xaml
      SetStrValue(ProjectRelativePath(Dialog.FileName, Folder));
  finally
    Dialog.Free;
  end;
end;

end.

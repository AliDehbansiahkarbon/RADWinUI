program PreviewMenuTest;

{
  Checks where Tools > RADWinUI Preview goes, on a VCL menu shaped like the
  IDE's. Build-Wizard.ps1 runs it.
}

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Vcl.Menus,
  RADWinUI.Preview.Menu in '..\..\src\IDE\Preview\RADWinUI.Preview.Menu.pas';

var
  Failures: Integer;

procedure Check(ACondition: Boolean; const AWhat: string);
begin
  if ACondition then
    Writeln('  [ok] ', AWhat)
  else
  begin
    Writeln('  [failed] ', AWhat);
    Inc(Failures);
  end;
end;

function Item(AParent: TMenuItem; const AName, ACaption: string): TMenuItem;
begin
  Result := TMenuItem.Create(AParent.Owner);
  Result.Name := AName;
  Result.Caption := ACaption;
  AParent.Add(Result);
end;

var
  Menu: TMainMenu;
  Tools, Preview: TMenuItem;
begin
  Writeln('Preview menu item');
  Menu := TMainMenu.Create(nil);
  try
    Item(Menu.Items, 'FileMenu', '&File');
    Tools := Item(Menu.Items, 'ToolsMenu', '&Tools');
    Item(Tools, 'ToolsOptionsItem', '&Options...');
    Item(Tools, 'ToolsGetItItem', '&GetIt Package Manager...');
    Item(Tools, 'ToolsToolsItem', 'Configure &Tools...');
    Item(Menu.Items, 'HelpMenu', '&Help');
    Preview := TMenuItem.Create(nil);
    Preview.Caption := 'RADWinUI Preview';
    Check(InsertIntoToolsMenu(Menu, Preview), 'finds the Tools menu by name');
    Check((Preview.Parent = Tools) and (Tools.IndexOf(Preview) = 1), 'goes right after Options, not at the end');
    Check(InsertIntoToolsMenu(Menu, Preview) and (Tools.Count = 4), 'inserting again moves it, no duplicate');
    Tools.Name := '';
    Check(FindToolsMenu(Menu) = Tools, 'finds Tools by caption when the item has no name');
    Tools.Remove(Preview);
    Preview.Free;
    Menu.Items.Remove(Tools);
    Tools.Free;
    Preview := TMenuItem.Create(nil);
    Check(not InsertIntoToolsMenu(Menu, Preview), 'no Tools menu yet: False (the command retries)');
    Preview.Free;
  finally
    Menu.Free;
  end;
  if Failures > 0 then
  begin
    Writeln('Preview menu test FAILED (', Failures, ')');
    Halt(1);
  end;
  Writeln('Preview menu test PASSED');
end.

unit RADWinUI.Preview.Menu;

{
  Puts the Tools > RADWinUI Preview item into the IDE main menu. Without
  ToolsAPI, so tests\Preview\PreviewMenuTest checks it on a VCL menu shaped
  like the IDE's.

  The item goes right after the first item of Tools (Options), not at the
  end: the IDE rebuilds the end of Tools from Configure Tools, and an item
  appended there with INTAServices.AddActionMenu did not show.
}

interface

uses
  Vcl.Menus;

/// <summary>The Tools menu: the item named ToolsMenu, else the one captioned Tools, nil when missing.</summary>
function FindToolsMenu(AMenu: TMainMenu): TMenuItem;
/// <summary>Inserts AItem after the first item of Tools, False when there is no Tools menu yet.</summary>
function InsertIntoToolsMenu(AMenu: TMainMenu; AItem: TMenuItem): Boolean;

implementation

uses
  System.SysUtils;

function FindToolsMenu(AMenu: TMainMenu): TMenuItem;
var
  I: Integer;
begin
  Result := nil;
  if AMenu = nil then
    Exit;
  for I := 0 to AMenu.Items.Count - 1 do
    if SameText(AMenu.Items[I].Name, 'ToolsMenu') then
      Exit(AMenu.Items[I]);
  for I := 0 to AMenu.Items.Count - 1 do
    if SameText(StripHotkey(AMenu.Items[I].Caption), 'Tools') then
      Exit(AMenu.Items[I]);
end;

function InsertIntoToolsMenu(AMenu: TMainMenu; AItem: TMenuItem): Boolean;
var
  Tools: TMenuItem;
begin
  Tools := FindToolsMenu(AMenu);
  Result := Tools <> nil;
  if not Result then
    Exit;
  if AItem.Parent <> nil then
    AItem.Parent.Remove(AItem);
  if Tools.Count = 0 then
    Tools.Add(AItem)
  else
    Tools.Insert(1, AItem);
end;

end.

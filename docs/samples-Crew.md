# Crew

A team directory made with Delphi and WinUI 3, built from pages: a NavigationView with Home, People and Settings, each page a `.xaml` file with its `.pas` unit, and a profile page the others navigate to. It shows how a RADWinUI app is put together from pages, a frame and a user control of its own.

Open `samples\Crew\Crew.dproj` in RAD Studio 13 and run Win64. Or, from the repository root:

```powershell
.\scripts\Build.ps1 -Project samples\Crew\Crew.dpr -Config Release
.\samples\Crew\Win64\Release\Crew.exe
```

## What to try

- **Home.** Three person cards: one user control, `PersonCard.xaml` with `PersonCard.pas`, used three times with different `PersonName` and `Role` attributes. Click one: the profile page opens with that person.
- **Profile.** The person arrives as the navigation parameter. Change a field: Save becomes available and the status says Edited. Now click Back, People or Home: Crew asks "Save changes to ...?". Cancel stays on the profile, No drops the edits and goes on, Yes saves and goes on.
- **People.** Type in the search box, open a profile, come back: the search and the list are as you left them, because the page sets `KeepAlive`. A name saved on a profile shows in the list.
- **Back.** The back button of the NavigationView goes back through every page you saw, and the selected menu item follows. It is disabled when there is nothing to go back to.
- **Settings.** The settings item of the NavigationView shows the history: the pages behind the current one. Clear history empties it, and the back button turns off.

## How it is made

- `MainWindow.xaml` is a NavigationView whose content is `<Frame x:Name="ContentFrame"/>`. XamlCodeGen makes that field a `TWinUIPageFrame`. The menu items name their page class in `Tag`, and `ContentFrame.AttachNavigationView(Nav, [THomePage, TPeoplePage], TSettingsPage)` connects menu, settings item, back button and frame.
- Each page is `<Page x:Class="T...">` with a unit whose class inherits the generated base. Pages navigate with `Frame.Navigate(TProfilePage, Person)` and receive the parameter in `NavigatedTo`.
- `TProfilePage.NavigatingFrom` sets `Cancel` when there are unsaved edits, asks with `MessageDlg`, and calls `Proceed` after Yes or No to finish the navigation that was asked for.
- `TPeoplePage` sets `KeepAlive := True` in its constructor, so the frame shows the same instance every time.
- `TPersonCard` declares `PersonName`, `Role` and the `Opened` event in `DefineType`. The Home page uses it as `<local:PersonCard ... Opened="CardOpened"/>` with `xmlns:local="using:Crew"`, and XamlCodeGen checks those attributes when it builds.

## Automated check

`scripts\Test-Samples.ps1` runs Crew offscreen: it opens a card, edits the profile, cancels and then confirms leaving it, uses the menu, and checks that the People page keeps its search.

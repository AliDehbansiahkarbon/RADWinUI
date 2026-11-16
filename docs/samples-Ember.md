# Ember

A coffee roastery's app made with Delphi and WinUI 3. It brings most of RADWinUI together in one real-looking program: a dashboard, orders from FireDAC in the data controls, a live roast curve, a compact overlay mini window, Windows notifications, three languages with right to left. [Ember_VCL](#ember_vcl) shows the same data on a VCL form with a WinUI card.

Open `samples\Ember\Ember.dproj` in RAD Studio 13 and run Win64. Or, from the repository root:

```powershell
.\scripts\Build.ps1 -Project samples\Ember\Ember.dpr -Config Release
.\samples\Ember\Win64\Release\Ember.exe
```

## What to try

- **Dashboard.** Today's revenue, the open orders, the green coffee in stock and the roaster's state, the sales of the last seven days as bars that grow in, the best sellers and the newest orders. All of it comes from the FireDAC tables.
- **Next roast.** Pick a coffee and a batch size on the orange card, then drag **Slide to start the roast** to the end. Ember opens the Roastery page with the batch running.
- **Roastery.** The bean temperature curve draws itself as the roast goes: the turning point, the Maillard phase from 150 °C, first crack at 196 °C, and the drop at 11:00. Twelve minutes of roasting take about forty seconds. **Hold to drop** ends the batch early.
- **Mini roaster.** Opens a small window that stays above every other window, with the temperature, the time and the phase. Minimize Ember: the mini roaster stays.
- **Notifications.** When a batch is done, Windows shows a notification. **Show the roast** brings Ember to the Roastery page, **Start the next batch** starts another one with the same coffee.
- **Pane footer.** The roast of the moment shows at the bottom of the navigation pane on every page. A click opens the Roastery.
- **Orders.** A grid with a navigator and a form for the current order, all bound with `DataSource` and `DataField`. The tab bar filters by status.
- **Search.** Type in the title bar's search box: it suggests cafes and coffees, and the Orders page filters while you type, in any case. Enter or a suggestion opens Orders from another page.
- **New order.** The **New order** button on the dashboard opens Orders with a new record.
- **Settings.** The theme (Windows, light or dark), the language (English, German or Persian, right to left) and a test notification.

`-light` and `-dark` on the command line pick a theme without changing the saved one, `--lang=de-DE` or `--lang=fa-IR` a language.

## How it is made

- `EmberData.pas` is a data module with three `TFDMemTable`s (coffees, cafes, orders) and their `TDataSource`s. The orders are dated back from today, so the dashboard always shows this week. Code that walks a table uses `Snapshot`, a cloned cursor: the data controls keep their own cursor, and a lookup control never moves it back during the loop.
- `MainWindow.xaml` has WinUI's `TitleBar` with a search box and a `NavigationView` whose frame shows the pages (`AttachNavigationView`). Its `Root` grid gives the app an ember orange accent for selection, sliders and accent buttons.
- `HomePage`, `OrdersPage`, `RoastPage` and `SettingsPage` are pages: a `.xaml` file with its `.pas` unit each. The cards enter with `TWinUIMotion.Enter`, the bars grow with `TWinUIMotion.Grow`.
- `RoastSession.pas` simulates the roaster with a `TWinUITimer`. The Roastery page, the mini window and the main window listen to it. `RoastPage.pas` draws the curve into a `Polyline` on a `Canvas`.
- `MiniRoastWindow.xaml` sets `WindowState="CompactOverlay"`.
- The batch-ready notification is a `TWinUINotification` with two buttons. `TWinUIApp.SingleInstance` and `OnActivated` bring a click back to the running Ember.
- `Strings\en-US`, `de-DE` and `fa-IR` hold the texts, `x:Uid` applies them in XAML and `TWinUIResources.GetString` in code. A new language starts Ember again, as in [Quill](samples-Quill.md).
- The Slide, Hold and Shine buttons and the sliding pill tab bar are RADWinUI's own controls from the Tool Palette.

## Ember_VCL

`samples\Ember_VCL` shows that WinUI and the VCL work together on one form, on the same `EmberData.pas`: a VCL `TDBGrid` and `TDBNavigator` list the orders, and a `TWinUIHost` shows the current order as a WinUI card (`Panels\OrderCard.xaml`), bound to a `TOrderCard` that the form fills when the cursor moves. **Start roasting** and **Mark as shipped** are published methods of the form, and give the focus back to the grid.

The card's XAML is in a subfolder because XamlCodeGen turns every `.xaml` next to the project into a unit. Edit it while the app runs in Debug: the card updates at once ([Hot reload](HOT-RELOAD.md)).

## Automated check

`scripts\Test-Samples.ps1` runs Ember in English: it opens Orders and checks the count, starts a batch on the Roastery page, waits for its clock and drops it. For Ember_VCL it checks the WinUI card shows the first order and ships it with the WinUI button.

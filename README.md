# One Click ToDo List

> A single-key show/hide ToDo list for Windows — built with nothing but standard PowerShell.

A minimal checkbox ToDo app for Windows that you can **show or hide with a single keystroke**.
Runs on the PowerShell that ships with Windows. No installer, no external libraries, no network calls.

## Features

- **One-key toggle**: press `Insert` to show or hide the window (key is configurable)
- **Checkbox-style items**: click to mark done / undone
- **Auto-save**: every edit, check, and delete is written immediately
- **Lives in the system tray**: stays out of the way
- **Zero install**: uses only built-in Windows PowerShell 5.1
- **Fully readable source**: no binaries, just a few hundred lines of script

## Requirements

- Windows 10 or 11
- Windows PowerShell 5.1 (preinstalled)

## Setup

1. Put `todo.ps1` and `todo.vbs` in the same folder (e.g. `C:\Users\<name>\todo\`).
2. Double-click `todo.vbs` to launch.
3. A ToDo icon should appear in the system tray.

## Usage

| Action | Result |
| --- | --- |
| Press **Insert** | Toggle window visibility |
| Type in the top box, press **Enter** | Add a new item |
| Click a checkbox | Toggle done / undone |
| Select an item, press **Delete** | Remove that item |
| Click **Remove checked items** | Remove all completed items at once |
| Right-click tray icon → Exit | Quit the app |
| Double-click tray icon | Toggle window visibility |

## Run on startup

1. Press `Win` + `R`, type `shell:startup`, press Enter.
2. Drop a shortcut to `todo.vbs` into the folder that opens.

## Changing the hotkey

Edit the `$VK_TOGGLE_KEY` value at the top of `todo.ps1`:

| Value | Key |
| --- | --- |
| `0x2D` | Insert (default) |
| `0x91` | ScrollLock |
| `0x13` | Pause/Break |
| `0x70` – `0x7B` | F1 – F12 |

See [Microsoft — Virtual-Key Codes](https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes) for other keys.

> A single key is captured globally across all apps, so avoid keys you actually use (e.g. F1 = Help).

## Data format

Items are stored as plain text in `%USERPROFILE%\todo.txt`:

```
[ ] buy milk
[x] take out trash
[ ] book dentist
```

You can edit the file directly with any text editor (restart the app to reload).

## How it works

- Registers a global hotkey via Win32 `RegisterHotKey`
- Catches `WM_HOTKEY` through an `IMessageFilter` to toggle the window
- Uses `System.Windows.Forms.CheckedListBox` for the list UI
- Uses `NotifyIcon` for the system tray
- `todo.vbs` is just a wrapper that launches PowerShell with the console hidden

## Troubleshooting

### Nothing happens when I launch it

Run it directly to see the error:

```powershell
powershell -ExecutionPolicy Bypass -NoExit -File .\todo.ps1
```

### Parser errors mentioning unterminated strings

Make sure `todo.ps1` is saved as **UTF-8 with BOM**.
Windows PowerShell 5.1 reads BOM-less UTF-8 as the system code page, which corrupts non-ASCII characters.

### The hotkey does nothing

- Another app may have already registered that key globally — quit it or change the key.
- Change `$VK_TOGGLE_KEY` to a different value (see table above).

### Execution policy blocks the script

`todo.vbs` launches with `-ExecutionPolicy Bypass`, which works on most setups.
On machines locked down by Group Policy, ask your admin.

## License

MIT

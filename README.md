# Mouse & Keyboard Controller

**A lightweight, portable keyboard-to-mouse utility for Windows.**

Use your keyboard to move the system pointer, click, right-click, and drag. The project uses built-in Windows components and does not require a third-party installer.

[![Platform](https://img.shields.io/badge/platform-Windows-0078D4?logo=windows)](https://www.microsoft.com/windows)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Dependencies](https://img.shields.io/badge/third--party%20dependencies-none-brightgreen)](#requirements)

> **Current repository version: 1.0.0.** This documentation describes the source currently published on the `main` branch. Custom bindings, sensitivity sliders, and profile management are not part of this version.

## Features

- **Keyboard pointer control** — move the system mouse pointer with the arrow keys.
- **Fast movement** — hold Shift while moving for larger steps.
- **Mouse clicks** — use the keyboard for left- and right-click actions.
- **Drag support** — hold and release the left mouse button from the keyboard.
- **Application launcher** — choose a local Windows executable and launch it from the interface.
- **Quick toggle** — enable or disable controller input with F7.
- **Portable and offline** — no installer, account, telemetry service, or network connection is required for normal use.
- **Inspectable source** — the PowerShell script is included in the repository.

## Download and run

1. Open the [latest repository source](https://github.com/siddop422/Mouse-Keyboard-Controller/archive/refs/heads/main.zip) and download the ZIP.
2. Extract the archive to a normal folder.
3. Open the extracted folder and run `MouseKeyboardController/START_CONTROLLER.cmd`.
4. Select **Choose .EXE...** and choose the application you want to launch.
5. Click **Launch selected app**.
6. Keep the controller window open while using the application.

No setup wizard is needed. The launcher starts Windows PowerShell in STA mode, which the Windows Forms interface requires.

## Default controls

| Key | Action |
| --- | --- |
| `Arrow keys` | Move the pointer |
| `Shift + Arrow keys` | Move the pointer faster |
| `Enter` | Left-click |
| `Space` | Left-click |
| `Backspace` | Right-click |
| `Numpad 0` | Hold the left mouse button |
| `Numpad Decimal` | Release the held left mouse button |
| `F6` | Show the controls help |
| `F7` | Toggle controller input on or off |

**Laptop keyboards:** Drag controls use numeric-keypad key codes. They may not be available on compact keyboards or may depend on NumLock and the keyboard layout.

## Requirements

- Windows with Windows PowerShell, .NET Windows Forms, and standard Win32 input APIs.
- A local Windows `.exe` if you want to launch an application through the controller.

The project is designed not to require third-party packages. Compatibility depends on the Windows configuration and the target application's input handling.

## Project files

```text
Mouse-Keyboard-Controller/
├── README.md
├── CHANGELOG.md
├── LICENSE
└── MouseKeyboardController/
    ├── START_CONTROLLER.cmd
    ├── MouseKeyboardController.ps1
    └── README.txt
```

- `START_CONTROLLER.cmd` — launches the script using Windows PowerShell.
- `MouseKeyboardController.ps1` — contains the GUI and keyboard/mouse handling.
- `README.txt` — quick-start instructions for the extracted application folder.
- `CHANGELOG.md` — records notable project changes.
- `LICENSE` — MIT license.

## Troubleshooting

### The controller window closes immediately
Extract the ZIP first, then run `START_CONTROLLER.cmd` again. If it still closes, open Command Prompt in the application folder and run the CMD file there to view any error message.

### Keys affect the target application
Press **F7** to disable controller input. Press it again to re-enable it. The controller polls keys globally while enabled, so avoid bindings that conflict with important application controls.

### Mouse input is ignored
Some full-screen games, applications using raw input, anti-cheat systems, or elevated processes may ignore synthetic mouse input. If the target is running with elevated privileges, Windows may require the controller to run at the same privilege level. Only elevate software you trust.

### The pointer will not move across all monitors
This version constrains pointer movement to the primary display. Full multi-monitor support is not currently implemented.

### A drag remains held
Press **Numpad Decimal** to release the left mouse button. Closing the controller also attempts to release an active drag.

## Important limitations

This is a **keyboard-to-mouse helper**, not a driver or a game patch. It sends system-level pointer and mouse-button input; it does not add native keyboard bindings to the selected application. Some games and protected applications may not accept this type of input.

The current source uses fixed keyboard controls and movement steps. Customizable mappings, sensitivity controls, saved profiles, and game-specific compatibility have not been verified in the published version.

## Privacy and safety

- Normal operation does not require internet access.
- The app can launch the executable you select. Only choose files you trust.
- The PowerShell source is available for inspection.
- The project is provided as-is. Test it with a non-critical application before relying on it.

## Contributing and feedback

Bug reports, compatibility notes, and focused improvement suggestions are welcome through [GitHub Issues](https://github.com/siddop422/Mouse-Keyboard-Controller/issues). When reporting a problem, include your Windows version, the steps to reproduce it, and any error message. Do not include private files or sensitive information.

## License

Released under the [MIT License](LICENSE).

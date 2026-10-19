# Mouse & Keyboard Controller

<p align="center">
  <strong>A portable keyboard-to-mouse controller for Windows</strong><br>
  Use keyboard keys to move the pointer, click, right-click, and drag — without installing third-party software.
</p>

![Platform](https://img.shields.io/badge/platform-Windows-0078D4)
![Version](https://img.shields.io/badge/version-1.0.0-2ea44f)
![License](https://img.shields.io/badge/license-MIT-blue)
![Dependencies](https://img.shields.io/badge/third--party%20dependencies-none-brightgreen)

Mouse & Keyboard Controller is a small Windows utility for people who need keyboard-only mouse input. Select a Windows `.exe`, launch it from the controller, and use your keyboard to move the system pointer and trigger basic mouse actions.

It can help with games or desktop applications that are difficult to operate without a mouse, accessibility workflows, and situations where a mouse is unavailable.

> **Release status:** v1.0.0 — initial public release. Community testing and compatibility feedback are welcome.

## Highlights

- **Simple graphical interface** — choose an executable using a standard file picker.
- **Launch and stop** — start the selected app and request that the launched process be stopped.
- **Pointer movement** — move the mouse with the arrow keys.
- **Fast movement** — hold Shift while moving for larger pointer steps.
- **Mouse actions** — trigger left-click and right-click from the keyboard.
- **Drag support** — hold the left mouse button, move the pointer, then release.
- **Quick enable/disable** — toggle keyboard control when the target app needs those keys.
- **Portable** — no installer, package manager, account, or third-party runtime download.
- **Offline by design** — after downloading the files, it does not need an internet connection.
- **Readable source** — the PowerShell implementation is included for inspection and modification.

## Download and run

1. Open the repository's **Code** menu and choose **Download ZIP**.
2. Extract the ZIP to a regular folder. Do not run the script from inside the compressed archive.
3. Double-click `MouseKeyboardController/START_CONTROLLER.cmd`.
4. Select **Choose .EXE...** and browse to the application's executable.
5. Select **Launch selected app**.
6. Keep the controller window open while using the selected app.

No setup wizard or installer is included. Windows PowerShell, .NET Windows Forms, and Win32 input APIs are used as built-in Windows components.

## Default keyboard controls

| Key | Action |
| --- | --- |
| `← ↑ → ↓` | Move the mouse pointer |
| `Shift` + arrow | Move the pointer faster |
| `Enter` | Left-click |
| `Space` | Left-click |
| `Backspace` | Right-click |
| `Numpad 0` | Hold the left mouse button for dragging |
| `Numpad Decimal` | Release the held left mouse button |
| `F6` | Open the controls help |
| `F7` | Toggle keyboard control on/off |

**Laptop note:** Some keyboards do not have a dedicated numeric keypad. The drag controls may depend on the keyboard layout, NumLock, or an embedded numeric keypad.

## Requirements

- Windows with Windows PowerShell and .NET Windows Forms available.
- A local Windows executable (`.exe`) for the target application.
- Permission to send input to the target application.

The project is designed to work without third-party libraries or network access. Compatibility can vary by Windows configuration and by the way a target app handles input.

## How it works

The graphical interface is built with Windows Forms from PowerShell. A short timer polls the relevant keys and uses Windows input APIs to move the system pointer or send mouse-button events. The selected application is launched as a separate process.

This is a **keyboard-to-mouse helper**, not a game patch or a native keyboard-remapping driver. It does not modify the selected application's files or add genuine keyboard bindings inside that application.

## Troubleshooting

### The controller does not start
- Extract the ZIP completely before launching it.
- Confirm that Windows PowerShell is available.
- If the window closes immediately, launch `START_CONTROLLER.cmd` from Command Prompt to inspect any error message.

### The keys affect the game instead
- Press **F7** to turn controller input off, then press **F7** again to turn it back on.
- Some games reserve keys for gameplay, so choose controls that do not conflict with the target app.

### Mouse input does not work in a game
- Some full-screen games, anti-cheat systems, elevated applications, or custom input systems may reject synthetic input.
- If the target app is running as administrator, Windows may require the controller to run at the same privilege level. Only elevate software you trust.
- Test with a normal desktop application before relying on it in a game.

### Dragging does not release
- Press **Numpad Decimal** to release the held left button.
- Closing the controller also attempts to release an active drag.

### Multi-monitor pointer movement
The current version clamps movement to the primary display. Multi-monitor pointer movement is not fully supported yet.

## Project structure

```text
Mouse-Keyboard-Controller/
├── README.md
├── LICENSE
├── CHANGELOG.md
└── MouseKeyboardController/
    ├── START_CONTROLLER.cmd
    ├── MouseKeyboardController.ps1
    └── README.txt
```

- `START_CONTROLLER.cmd` — starts the controller in a single-threaded PowerShell apartment.
- `MouseKeyboardController.ps1` — Windows Forms interface and keyboard/mouse handling.
- `README.txt` — compact instructions included beside the launcher.
- `CHANGELOG.md` — release history.
- `LICENSE` — MIT license terms.

## Privacy and safety

- The app is intended to run locally and does not need an account, analytics, or network access.
- It can launch the executable you select. Only select applications you trust.
- Review the included PowerShell script before running it if you want to inspect its behavior.
- The project is provided as-is. Test it in a non-critical application first.

## Roadmap ideas

Potential improvements for future releases include:
- Customizable keyboard-to-mouse bindings.
- Adjustable pointer sensitivity and movement speed in the GUI.
- Per-application control profiles.
- Better multi-monitor support.
- More accessible drag controls for compact laptop keyboards.
- Automated compatibility checks and clearer error reporting.

These are ideas, not features promised by v1.0.0.

## Contributing and feedback

Bug reports and feature requests are welcome. When opening an issue, include:
- Your Windows version.
- The target application and whether it is windowed or full-screen.
- Which key or action failed.
- Steps to reproduce the problem and any visible error message.

Do not attach private files, credentials, or personal information.

## License

Released under the [MIT License](LICENSE).

---

**Mouse & Keyboard Controller v1.0.0** — a small, portable helper for keyboard-driven mouse input on Windows.

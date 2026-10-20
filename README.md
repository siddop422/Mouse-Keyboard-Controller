# Mouse & Keyboard Controller

**A portable Windows utility that turns keyboard keys into mouse movement, clicks, scrolling, and drag controls — with customizable bindings and per-app profiles.**

[![Platform](https://img.shields.io/badge/platform-Windows-0078D4?logo=windows)](https://www.microsoft.com/windows)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Dependencies](https://img.shields.io/badge/third--party%20dependencies-none-brightgreen)](#requirements)
[![Portable](https://img.shields.io/badge/portable-no%20installer-success)](#quick-start)

Use the keyboard to control the system mouse pointer in games and desktop apps. Configure the keys and movement sensitivity to suit your setup, save profiles for different applications, and launch a selected executable from the controller window.

## Quick start

1. **[Download the repository ZIP](https://github.com/siddop422/Mouse-Keyboard-Controller/archive/refs/heads/main.zip).**
2. Extract the ZIP to a regular folder.
3. Open the `MouseKeyboardController` folder.
4. Double-click `START_CONTROLLER.cmd`.
5. Choose the target application's `.exe`, then select **Launch selected app**.
6. Keep the controller running while you use the application.

No installer or third-party package is required. Windows PowerShell and Windows components included with the operating system are used.

## Features

- **Custom keyboard bindings** — choose a key from a list or use the key-capture control to assign one.
- **Pointer movement** — configure up, down, left, and right movement.
- **Adjustable sensitivity** — tune horizontal and vertical movement separately, link the sliders if desired, and configure fast movement and fine aim.
- **Mouse actions** — configure left/right/middle click, additional mouse buttons, scrolling, and drag hold/release actions.
- **Game mode** — try relative mouse movement for applications that do not respond well to ordinary pointer movement.
- **Profiles** — save and load per-application controls, sensitivity, and options. Profiles are stored as JSON files in the local `Profiles` folder.
- **Live settings summary** — review current bindings and settings and spot duplicate key assignments.
- **Quick toggle** — turn controller input on or off without closing the app.
- **Portable and offline** — normal operation does not need an internet connection, account, or installer.
- **Readable source** — the PowerShell implementation is included.

## Default controls

These are the default bindings; they can be changed in the app.

| Key | Action |
| --- | --- |
| Arrow keys | Move pointer |
| Shift + arrows | Move faster |
| Ctrl + arrows | Fine aim |
| Enter / Space | Left-click |
| Backspace | Right-click |
| Numpad 0 | Hold left mouse button |
| Numpad Decimal | Release held left mouse button |
| F6 | Show controls |
| F7 | Toggle controller on or off |

Some compact laptop keyboards do not provide dedicated numpad keys. You can reassign the relevant actions in **Key bindings**.

## Project structure

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

- `MouseKeyboardController/START_CONTROLLER.cmd` — starts the controller in Windows PowerShell STA mode.
- `MouseKeyboardController/MouseKeyboardController.ps1` — the application interface and input-handling logic.
- `MouseKeyboardController/README.txt` — quick-start instructions for users who have extracted the application folder.
- `CHANGELOG.md` — notable release changes.
- `LICENSE` — MIT license.

## Requirements

- Windows with Windows PowerShell, .NET Windows Forms, and standard Win32 input APIs.
- A local `.exe` file if you want to launch an application from the controller.

No third-party dependencies are required. Compatibility depends on the target application and Windows configuration.

## Troubleshooting

### The controller does not start
Extract the ZIP before launching it. If the window closes immediately, open Command Prompt in the `MouseKeyboardController` folder and run `START_CONTROLLER.cmd` there to see any error output.

### The target application ignores mouse input
Some full-screen games, raw-input applications, protected games, or anti-cheat systems may ignore synthetic mouse input. If the target application runs as administrator, Windows may require the controller to run at the same privilege level. Only run elevated software you trust.

### Keys interfere with typing
Bindings are read globally while controller input is enabled, so a key can affect other applications too. Use the configured toggle key (F7 by default) to disable controller input when you need to type normally.

### A drag remains held
Use the configured drag-release binding. Closing the controller also attempts to release an active drag.

## Important limitations

This is a **keyboard-to-mouse helper**, not a driver or a patch to the target game. It sends system pointer and mouse-button input; it does not add native keyboard support to an application. Some games may not accept this type of input, and the helper must remain open while in use.

## Privacy and safety

- Normal operation does not require internet access.
- The controller can launch the executable you select. Choose only files you trust.
- The PowerShell source is available for inspection.
- Test the tool with a non-critical application before relying on it.

## Feedback and contributions

Found a bug or have a compatibility tip? [Open an issue](https://github.com/siddop422/Mouse-Keyboard-Controller/issues) with your Windows version, steps to reproduce the issue, and any relevant error message. Do not attach private files or sensitive information.

## License

Released under the [MIT License](LICENSE).

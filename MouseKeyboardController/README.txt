MOUSE & KEYBOARD CONTROLLER
Portable keyboard-to-mouse utility for Windows
Current published version: 1.0.0

QUICK START
1. Extract the downloaded ZIP to a normal folder.
2. Run START_CONTROLLER.cmd.
3. Click Choose .EXE... and select a Windows application.
4. Click Launch selected app.
5. Keep the controller window open while using the application.

DEFAULT CONTROLS
Arrow keys          Move pointer
Shift + arrows      Move pointer faster
Enter / Space       Left-click
Backspace           Right-click
Numpad 0            Hold left mouse button
Numpad Decimal      Release left mouse button
F6                  Show controls help
F7                  Toggle controller input on/off

REQUIREMENTS
Windows PowerShell, .NET Windows Forms, and standard Win32 input APIs.
No third-party package installation is intended.

LIMITATIONS
This helper sends system mouse input; it does not add native key bindings
inside the selected application. Some games, full-screen apps, anti-cheat
systems, and elevated processes may reject synthetic input. Pointer movement
is limited to the primary display in this version.

SAFETY
Only launch applications you trust. Review the included PowerShell script
if you want to inspect its behavior. Test with a non-critical application.

Project and issue tracker:
https://github.com/siddop422/Mouse-Keyboard-Controller

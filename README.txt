MOUSE + KEYBOARD CONTROLLER - NO INSTALLER

1. Extract this ZIP to a normal folder (do not run it from inside the ZIP).
2. Double-click START_CONTROLLER.cmd.
3. Click Choose .EXE... and select your game's/app's .exe.
4. Click Launch selected app.
5. Keep the controller open while using the selected app.

FEATURES
Key bindings     Pick any key for every action from a dropdown, or click
                 "Press a key..." and press the key you want (Esc cancels).
                 Actions: move up/down/left/right, left click (two keys),
                 right click, middle click, Mouse 4 / Mouse 5, scroll wheel
                 up/down, hold/release drag, fast move, fine aim,
                 toggle controller, show controls.
Sensitivity      Separate horizontal and vertical sliders (optionally linked),
                 a fast-move multiplier, and a separate fine-aim slider
                 (percent of normal speed) used while the Fine-aim key is held.
Options          - Hold mouse button while its key is held (good for games)
                 - Game mode: relative mouse movement (try this if a game
                   ignores the pointer)
Profiles         Save the whole setup (keys, sensitivity, options and the
                 selected .exe) under a name, e.g. one per game. Load or
                 delete them from the Profiles tab. They are stored as .json
                 files in the Profiles folder next to the script. The last
                 profile you saved/loaded is loaded automatically at startup.
Reset            "Reset to defaults" restores the original controls and
                 sensitivity.
Live summary     The panel on the right always shows the current keys,
                 sensitivity and options, and warns if one key is assigned
                 to more than one action.

DEFAULT CONTROLS
Arrow keys          Move mouse pointer
Shift + arrows      Move faster
Ctrl + arrows       Fine aim (slow, precise movement)
Enter / Space       Left-click
Backspace           Right-click
Numpad 0            Hold left mouse button (drag)
Numpad Decimal      Release left mouse button
F6                  Show controls (when the controller window is focused)
F7                  Toggle controller on/off (works from any window)
Middle click, Mouse 4/5 and scroll wheel start unassigned - bind them in
the Key bindings tab.

NOTES
Uses Windows PowerShell and .NET included with Windows. No downloads or
third-party installs. This is a keyboard-to-mouse helper, not a native patch
to the selected game, so the helper must remain open. Some apps running as
administrator may require running START_CONTROLLER.cmd as administrator too.
Keys you bind are read globally, so they also act while you type in other
programs; press the toggle key (F7 by default) to turn the controller off.

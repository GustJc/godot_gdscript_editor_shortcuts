# Gdscript Space Block Jumper

Very simple plugin that let's you move around your code really fast with extra code shortcuts.

![](example_jumper.gif)

Use *page-up* or *page-down* to jump to the next empty line.

You can also *hold shift* to to jump to func definitions.

Initially inspired by PICO-8 script editor where you use the 'page up/down' keys to move acress functions.

Shortcuts:
- Page Down : Go to next empty line
- Page Up : Go to previous empty line
- Shift + Page Down : Go to next 'func'
- Shift + Page Up : Go to previous 'func'

- Ctrl + Enter : Add (:) colon at end and create new line below (if needed)

_Tip: You can turn `safe_colon` off inside the code to always add (:) colon instead of guessing.
_Tip: If you do so, change the editor shortcut of `ui_text_newline_blank` to something else like `alt + enter` to create the newline without the colon._

_Tip: This addon also fixes the autocomplete hint not disappearing when creating a new blank line._

- Ctrl + Page Up : Go to the begining of current Block
- Ctrl + Page Down : Go to end begining of current the Block

_Tip: Using goto block if already at the begining/end goes to the next valid line outside it._

- Alt + Page Up : Go to the begining of the Block (no matter the indent)
- Alt + Page Down : Go to the begining of the Block (no matter the indent)

Summary:

- *No modifier* for empty line movement
- *Shift* for FUNC movement
- *Control* for indented block movement
- *Alt* for unindented block movement

_Tip: Can switch the shift/no modifier actions with Project Settings (see below)_

# Configuration

You can set the `Shift to Move Space Behavior` configuration in the ProjectSettings/Plugins/Gdscript Block Jumper.

If you enable this, the scroll commands will be switched.

PageUp/Down will scroll to func and shift+PageUp/Down will jump to empty lines

## Todo

- Add ability to select lines while jumping around
- Add configurable hotkeys (note: careful because of Godot bug in project setting resources)
- Use some option+arrow combination to move, if configurable hotkeys doesn't work for that.

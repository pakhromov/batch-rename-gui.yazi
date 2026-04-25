# batch-rename-gui.yazi

Yazi's built-in bulk rename only works with terminal editors, this plugin adds possibility ro use batch rename in a GUI text editor like VS Code or Sublime Text. Single file or no selection uses Yazi's built-in inline rename. When multiple files are selected, a configured GUI editor is opened with one filename per line and renaming happens the moment you save the opened file.


https://github.com/user-attachments/assets/b721d8fe-1443-4eb6-91a7-dc284cb325ef

## Dependencies

- `inotify-tools` - for detecting when the file is saved (`sudo pacman -S inotify-tools`)

## Installation

**Via ya pkg:**
```bash
ya pkg add pakhromov/batch-rename-gui
```

**Manual:**
```bash
git clone https://github.com/pakhromov/batch-rename-gui.yazi ~/.config/yazi/plugins/batch-rename-gui.yazi
```

Add to `~/.config/yazi/keymap.toml`:
```toml
[[mgr.prepend_keymap]]
on = "r"
run = "plugin batch-rename-gui"
desc = "Rename file or batch rename selection in GUI editor"
```

## Configuration

The editor is resolved in this order:

1. **Keymap argument** - takes precedence over everything else:
```toml
run = "plugin batch-rename-gui -- subl"
run = "plugin batch-rename-gui -- code"
run = "plugin batch-rename-gui -- kate"
```

2. **`$VISUAL` environment variable** - used if no argument is passed

3. **`$EDITOR` environment variable** - fallback if `$VISUAL` is not set

## Usage

- **No selection or single file selected** - opens Yazi's built-in inline rename with the cursor positioned before the extension
- **Multiple files selected** - opens a temp file in the configured editor with one filename per line; edit the names and save the file

Lines are matched to files in selection order, do not add or remove lines, only edit the names.

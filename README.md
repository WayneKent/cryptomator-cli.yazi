[中文](README.zh-CN.md) | [English](README.md)

# cryptomator-cli.yazi

Yazi file manager plugin for mounting/unmounting Cryptomator vaults

## Features

- 🔍 Auto-detects Cryptomator vaults (`.cryptomator` files) in current or previewed directory
- ⌨️ Interactive password input for mounting encrypted vaults
- 🔓 Secure vault unmounting functionality
- ⚙️ Configurable mount point location
- 💬 Operation status notifications

## Installation

### Method 1: Using ya package manager

```bash
ya pkg add WayneKent/cryptomator-cli
```

### Method 2: Manual installation

1. Clone repository:
    ```bash
    git clone https://github.com/WayneKent/cryptomator-cli.yazi.git
    ```
2. Copy plugin to Yazi plugins directory:
    ```bash
    cp -r cryptomator-cli.yazi ~/.config/yazi/plugins/
    ```
3. Ensure `cryptomator-cli` command is installed on your system

## Usage

### Mount vault

1. Navigate to directory containing `.cryptomator` file, or
2. Select target directory in parent directory view
3. Press `mc` shortcut
4. Enter vault password

### Unmount vault

1. Navigate to mounted vault directory, or
2. Select target directory in parent directory view
3. Press `uc` shortcut

## Keybind Configuration

Add to `~/.config/yazi/keymap.toml`:

```toml
[mgr]
prepend_keymap = [
{ on = ["m", "c"], run = "plugin cryptomator-cli -- --mount", desc = "Mount Cryptomator vault" },
{ on = ["u", "c"], run = "plugin cryptomator-cli -- --umount", desc = "Unmount Cryptomator vault"},
]
```

or

```toml
[[mgr.prepend_keymap]]
on = ["m", "c"]
run = "plugin cryptomator-cli -- --mount"
desc = "Mount Cryptomator vault"

[[mgr.prepend_keymap]]
on = ["u", "c"]
run = "plugin cryptomator-cli -- --umount"
desc = "Unmount Cryptomator vault"
```

## Configuration

### Mount directory

Add to `~/.config/yazi/init.lua`:

```lua
require('cryptomator-cli'):setup({
    mount_parent = '~/mnt' --default
})
```

## Dependencies

- [Cryptomator CLI](https://github.com/cryptomator/cli)
- FUSE filesystem support

## FAQ

**Q: Mounting fails?**  
✅ Check:

1. cryptomator-cli is installed
2. FUSE support exists
3. Correct password

**Q: Change default mount location?**  
⚙️ Modify `mount_parent` in init.lua config

## License

This project is licensed under the [MIT License](LICENSE).

## Credits

- 🦆 [Yazi](https://github.com/sxyazi/yazi) - Powerful terminal file manager
- 🔐 [Cryptomator CLI](https://github.com/cryptomator/cli) - Encrypted storage tool

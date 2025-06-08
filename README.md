# yaml-breadcrumb.nvim

A Neovim plugin that provides YAML breadcrumb navigation, showing the hierarchical path to your current position in YAML files.

## Features

- 🍞 **Visual breadcrumb display** - Shows the current YAML path as virtual text
- 📍 **Auto-update on cursor movement** - Breadcrumb updates as you navigate through the file  
- 🔢 **Array index tracking** - Handles YAML arrays with proper indexing (`[0]`, `[1]`, etc.)
- 🎯 **Line number integration** - Optional display of line numbers in breadcrumb
- ⌨️ **Customizable keymaps** - Default keybindings with full customization support
- 🎨 **Configurable appearance** - Custom separators, highlight groups, and formatting
- 🔧 **Statusline integration** - Export breadcrumb to your statusline
- 🩺 **Health check support** - Built-in health check command

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "your-username/yaml-breadcrumb.nvim",
  ft = { "yaml", "yml" },
  config = function()
    require("yaml-breadcrumb").setup({
      -- your configuration here
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "your-username/yaml-breadcrumb.nvim",
  ft = { "yaml", "yml" },
  config = function()
    require("yaml-breadcrumb").setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'your-username/yaml-breadcrumb.nvim'
```

## Configuration

### Default Configuration

```lua
require("yaml-breadcrumb").setup({
  enabled = true,                    -- Enable/disable the plugin
  show_on_cursor_move = true,        -- Auto-update breadcrumb on cursor movement
  virtual_text = true,               -- Show breadcrumb as virtual text
  separator = " -> ",                 -- Separator between breadcrumb items
  show_line_numbers = false,         -- Show line numbers in breadcrumb
  highlight_group = "Comment",       -- Highlight group for virtual text
})
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `true` | Enable or disable the plugin |
| `show_on_cursor_move` | boolean | `true` | Automatically update breadcrumb when cursor moves |
| `virtual_text` | boolean | `true` | Display breadcrumb as virtual text at end of line |
| `separator` | string | `" > "` | String used to separate breadcrumb components |
| `show_line_numbers` | boolean | `false` | Include line numbers in breadcrumb display |
| `highlight_group` | string | `"Comment"` | Neovim highlight group for virtual text styling |

## Usage

### Commands

The plugin provides the following commands:

- `:YamlBreadcrumb` - Show breadcrumb for current line in a notification
- `:YamlBreadcrumbToggle` - Toggle the plugin on/off
- `:YamlBreadcrumbHealth` - Run health check to verify plugin status

### Default Keymaps

| Key | Mode | Action |
|-----|------|--------|
| `<leader>yb` | Normal | Show YAML breadcrumb |
| `<leader>yt` | Normal | Toggle YAML breadcrumb |

### Custom Keymaps

You can set up your own keymaps:

```lua
vim.keymap.set("n", "<your-key>", function()
  require("yaml-breadcrumb").show_breadcrumb()
end, { desc = "Show YAML breadcrumb" })

vim.keymap.set("n", "<your-key>", function()
  require("yaml-breadcrumb").toggle()
end, { desc = "Toggle YAML breadcrumb" })
```

## Examples

### Basic YAML Structure

For this YAML file:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
  namespace: default
data:
  config.yaml: |
    database:
      host: localhost
      port: 5432
```

When your cursor is on the `port: 5432` line, the breadcrumb would show:
```
🍞 apiVersion > kind > metadata > data > config.yaml > database > port
```

### YAML with Arrays

For this YAML file:
```yaml
users:
  - name: john
    email: john@example.com
    roles:
      - admin
      - user
  - name: jane
    email: jane@example.com
```

When your cursor is on `email: jane@example.com`, the breadcrumb would show:
```
🍞 users > [1] > email
```

### With Line Numbers Enabled

With `show_line_numbers = true`, the same breadcrumb would show:
```
🍞 users (L1) > [1] (L8) > email (L9)
```

## Statusline Integration

You can integrate the breadcrumb into your statusline:

### With lualine.nvim

```lua
require('lualine').setup {
  sections = {
    lualine_c = {
      'filename',
      function()
        return require('yaml-breadcrumb').get_current_breadcrumb()
      end
    }
  }
}
```

### With custom statusline

```lua
vim.o.statusline = vim.o.statusline .. '%{luaeval("require(\'yaml-breadcrumb\').get_current_breadcrumb()")}'
```

## Advanced Configuration

### Custom Highlight Groups

Create custom highlight groups for better visual integration:

```lua
-- Define custom highlight
vim.api.nvim_set_hl(0, "YamlBreadcrumb", { 
  fg = "#61AFEF", 
  bg = "NONE", 
  italic = true 
})

-- Use in configuration
require("yaml-breadcrumb").setup({
  highlight_group = "YamlBreadcrumb",
})
```

### Conditional Enabling

Enable only for specific file patterns:

```lua
require("yaml-breadcrumb").setup({
  enabled = vim.fn.expand("%:t"):match(".*%.ya?ml$") ~= nil,
})
```

## Troubleshooting

### Health Check

Run the health check to diagnose issues:
```vim
:YamlBreadcrumbHealth
```

### Common Issues

1. **Breadcrumb not showing**: Ensure you're in a YAML file (`.yaml` or `.yml` extension)
2. **Virtual text not appearing**: Check that `virtual_text = true` in your configuration
3. **Incorrect indentation detection**: The plugin uses space-based indentation detection

### Debug Mode

Enable debug notifications to see what the plugin detects:

```lua
-- The plugin includes debug output in the show_breadcrumb() function
-- Use :YamlBreadcrumb to see debug information
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by IDE breadcrumb navigation features
- Built for the Neovim community
- Thanks to all contributors and testers

---

**Note**: This plugin requires Neovim 0.7+ for virtual text support and modern Lua APIs.

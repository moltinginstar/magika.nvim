# magika.nvim

[Magika](https://github.com/google/magika)-powered filetype detection for Neovim.

## Installation

Install the `magika` CLI first. It needs to be available in `$PATH`:

```sh
magika --version
```

### `lazy.nvim`

```lua

{
  "moltinginstar/magika.nvim",
  lazy = false,
  opts = {},
}
```

### Manual

1. Clone the repository into your Neovim package directory, for example:

   ```sh
   git clone https://github.com/moltinginstar/magika.nvim ~/.local/share/nvim/site/pack/moltinginstar/start/magika.nvim
   ```

2. Add the following line to your `init.lua`:

   ```lua
   require("magika").setup()
   ```

## Behavior

Neovim already has good filetype detection. `magika.nvim` is for the cases where that detection falls back to nothing useful.

By default, Magika only runs when the current buffer filetype is:

- empty
- `text`

If Neovim has already detected something more specific, `magika.nvim` leaves it alone.

The plugin only runs for normal file-backed buffers. It skips scratch buffers, terminals, help buffers, quickfix buffers, and anything else with a non-empty `buftype`. It does not read the buffer into Lua, does not create temp files, and does not pipe buffer contents to stdin. It simply passes the current file path to the Magika CLI.

This means:

- unsaved changes are not used for detection
- unnamed buffers are skipped
- files that do not exist on disk yet are skipped

Magika is called asynchronously with `vim.system()`, and results are cached in memory using the file path, mtime, and size.

## Configuration

```lua
require("magika").setup({
  enabled = true,
  filetypes = { "", "text" },
  magika_cmd = { "magika", "--json" },
  timeout_ms = 1500,
  confidence_threshold = 0.8,
  cache = true,
})
```

`filetypes` controls when Magika is allowed to run, based on the buffer's current filetype.

Magika only applies its result if the buffer still has an allowed filetype when the async classification finishes.

For example, this is the default:

```lua
require("magika").setup({
  filetypes = { "", "text" },
})
```

This lets Magika run on every normal file-backed buffer:

```lua
require("magika").setup({
  filetypes = "*",
})
```

This lets you decide yourself:

```lua
require("magika").setup({
  filetypes = function(ft)
    return ft == "" or ft == "text" or ft == "conf"
  end,
})
```

## Commands

- `:MagikaDetect`: run Magika on the current buffer

The command forces a Magika run for the current buffer. It still operates on the file on disk, not the unsaved buffer contents.

## Trying it

Create a small Excalidraw file:

```sh
cat > /tmp/magika-test.excalidraw <<'EOF'
{
  "type": "excalidraw",
  "version": 2,
  "source": "magika.nvim test",
  "elements": [],
  "appState": {},
  "files": {}
}
EOF
```

Then open it:

```sh
nvim /tmp/magika-test.excalidraw
```

Neovim does not currently detect `.excalidraw` by default, but Magika detects the file as JSON, so `:set filetype?` should show:

```vim
filetype=json
```

## License

This project is licensed under the [MIT License](LICENSE).

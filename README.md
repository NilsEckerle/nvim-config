# nvim offline configuration

## Setup

### 1. Clone

```bash
git clone --recurse-submodules git@github.com:<you>/nvim-offline.git
cd nvim-offline
```

If you already cloned without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

### 2. Build

Compiles Neovim from source and builds the treesitter parser `.so` files.
Requires: `cmake`, `gcc`, `ninja`.

```bash
make build
```

### 3. Test (optional)

Spins up a Docker container with the built artifacts to verify the install.
Requires: `docker`.

```bash
make test DISTRO=debian   # debian | arch | fedora
```

### 4. Install

Installs the Neovim binary, symlinks the config to `~/.config/nvim`,
copies parsers to `~/.local/share/nvim/site/parser`, and installs LSP servers.

```bash
make install
```

To undo:

```bash
make uninstall
```

## Adding a Plugin

```bash
git submodule add git@github.com:<owner>/<repo> nvim/pack/plugins/start/<name>
git add .gitmodules nvim/pack/plugins/start/<name>
git commit -m "feat(plugins): add <name>"
```

To pin a plugin to a specific branch, add a `branch` entry to `.gitmodules`:

```ini
[submodule "nvim/pack/plugins/start/<name>"]
    branch = <branch>
    path = nvim/pack/plugins/start/<name>
    url = git@github.com:<owner>/<repo>
```

Then run `git submodule sync` to apply the change.

### Configuring a Plugin

Create a file in `nvim/lua/plugins/<name>.lua`. It will be auto-loaded by
`lua/config/plugin.lua`. Example:

```lua
local ok, myplugin = pcall(require, "myplugin")
if not ok then return end

myplugin.setup({
    -- your options
})
```

---

---

## Adding a Parser

Add the grammar repo as a submodule:

```bash
git submodule add git@github.com:tree-sitter/tree-sitter-<lang> grammars/<lang>
```

Then add the language to the `LANGUAGES` variable in the Makefile:

```makefile
LANGUAGES := python c cpp bash lua css html <lang>
```

Run `make build-parsers` to compile and verify it builds, then commit:

```bash
git add .gitmodules grammars/<lang> Makefile
git commit -m "feat(parsers): add <lang> parser"
```

---

## Adding an LSP Server

LSP servers are installed via the system package manager in the `install-lsp`
target in the Makefile. Add your server to the relevant lines:

```makefile
install-lsp:
	$(SUDO) apt install -y clangd python3-pylsp python3-pylsp-jsonrpc <your-lsp>
```

If the server has a different package name per distro, add it to all three
package manager branches in `install-deps` as well. Then commit:

```bash
git add Makefile
git commit -m "feat(lsp): add <name> language server"
```

---

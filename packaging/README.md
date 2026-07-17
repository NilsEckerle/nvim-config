# packaging/ — offline Neovim `.deb` builder

Builds a self-contained `nvim-bundle_<version>_amd64.deb` that installs a fully
configured Neovim — editor, this config, all lazy.nvim plugins, compiled
treesitter parsers, and the LSPs/formatters — onto a machine with **no internet**.

The build runs inside a Debian container (for glibc/ABI compatibility) and is
driven from this directory.

## Requirements (build host)

- Docker with the buildx plugin (`pacman -S docker-buildx` on Arch).
- Internet on the build host (the build clones plugins and installs a few npm
  packages). The *target* machine needs no internet.

## Quick start

```sh
cd packaging
make deb     # -> packaging/dist/nvim-bundle_1.0.0_amd64.deb
make test    # offline smoke test in a clean Debian container
```

## Install on the target machine

Copy the `.deb` over, then:

```sh
sudo dpkg -i nvim-bundle_1.0.0_amd64.deb
nvim-bundle-setup     # copies config + plugins into the current user's home
nvim
```

- `dpkg -i` installs the bundle under `/opt/nvim-bundle` and puts `nvim` and
  `nvim-bundle-setup` on `PATH`.
- `nvim-bundle-setup` copies the config into `~/.config/nvim` and the plugins +
  parsers into `~/.local/share/nvim`. Any existing versions of those dirs are
  moved aside to `*.bak.<timestamp>` first. Run it once per user account.
- Remove later with `sudo dpkg -r nvim-bundle` (your `~/.config/nvim` copy stays
  until you delete it yourself).

## Testing it yourself

`make test` is automated. To poke at it by hand in a throwaway offline container:

```sh
make test-shell        # installs the .deb, drops you in a shell as user "dev"
# then inside:
nvim-bundle-setup
nvim
```

Things to check inside nvim:
- Treesitter: `:e /tmp/t.py`, type Python — you should get highlighting.
  (`:checkhealth nvim-treesitter` for detail.)
- LSP: in that file `:LspInfo` should show pyright attached; `:e /tmp/t.c` → clangd.
- Parsers present: `:lua print(vim.inspect(vim.fn.glob(vim.fn.stdpath("data").."/site/parser/*.so")))`

The container runs with `--network none`, so anything that works, works offline.
Exit with `:q` then `exit`; the container is disposable.

## What's in the bundle

- Neovim (vendored official static build)
- This config + all lazy.nvim plugins (pinned by `lazy-lock.json`)
- Compiled treesitter parsers: c, llvm, cpp, cmake, lua, python, r, vim,
  vimdoc, query, markdown, markdown_inline, latex, javascript, html
- LSPs/formatters: clangd, clang-format, gopls (from apt), lua-language-server
  and neocmakelsp (vendored), pyright and tailwindcss-language-server (pinned npm)
- A Node runtime (for the npm-based tools)

Mason is disabled in the bundled config so it never tries to reach the network
on the target. (You may see a harmless `OmniSharp not found` line — ignore it.)

## NOT bundled — install from apt on the target if needed

- LaTeX: `sudo apt install texlab texlive-latex-extra`
- C# (omnisharp/csharpier) and R (r-languageserver/styler): dropped entirely.

## Target compatibility: Debian 13+ only

The build uses Debian **trixie** because the `latex` treesitter grammar requires
a tree-sitter CLI that needs glibc 2.39. That means the resulting `.deb` runs on
**Debian 13 (trixie) and newer, not Debian 12**. To support Debian 12 you'd have
to build the tree-sitter CLI from source against the older glibc.

To build against a different base (advanced): `make deb DEBIAN_IMAGE=debian:trixie
TEST_IMAGE=debian:trixie-slim` — but dropping to bookworm will break the latex
parser unless you also handle the CLI glibc issue.

## Rebuilding for updates

Change a plugin or the config, then re-run `make deb`. Plugin versions are pinned
by `lazy-lock.json`, so builds stay reproducible until you update the lock.

---

# Vendored binaries (`packaging/vendor/`)

These are checked into the repo so the build is fully reproducible and works
offline. The build script consumes them as-is — it never downloads them.

Refresh them manually when you want newer versions (that's the point: nothing
changes under you). After replacing a file, rebuild with `make deb` and test.

## Required files

### neovim (Linux x86_64 static build)
Download `nvim-linux-x86_64.tar.gz` from:
  https://github.com/neovim/neovim/releases (the `stable` release)
Save it here EXACTLY as:
  vendor/nvim-linux-x86_64.tar.gz

### node runtime (Linux x64)
Must match `NODE_VERSION` in `build-deb.sh` (currently 22.14.0).
Download from:
  https://nodejs.org/dist/v22.14.0/node-v22.14.0-linux-x64.tar.xz
Save it here EXACTLY as:
  vendor/node-v22.14.0-linux-x64.tar.xz

### lua-language-server (Linux x86_64 tarball)
Download the `*-linux-x64.tar.gz` asset from:
  https://github.com/LuaLS/lua-language-server/releases
Save it here EXACTLY as:
  vendor/lua-language-server-linux-x64.tar.gz
(Do not extract it — the build extracts it into the bundle. The tarball's top
level contains bin/, main.lua, meta/, etc.)

### neocmakelsp (Linux x86_64 gnu)
The Linux asset is a tarball: `neocmakelsp-x86_64-unknown-linux-gnu.tar.gz` from:
  https://github.com/neocmakelsp/neocmakelsp/releases
Extract just the binary and save it here EXACTLY as:
  vendor/neocmakelsp
For example:
    curl -fsSL -o /tmp/n.tar.gz \
      "https://github.com/neocmakelsp/neocmakelsp/releases/download/vX.Y.Z/neocmakelsp-x86_64-unknown-linux-gnu.tar.gz"
    tar xzf /tmp/n.tar.gz -C packaging/vendor neocmakelsp
    chmod +x packaging/vendor/neocmakelsp

## Versions currently vendored

Record what you dropped in so future-you knows what's shipping:

- neovim:              <fill in version>
- node:                22.14.0
- lua-language-server: <fill in version>
- neocmakelsp:         <fill in version>

## Git size note

These are multi-MB binaries. If the repo grows uncomfortably, track them with
git-lfs:

    git lfs track "packaging/vendor/nvim-linux-x86_64.tar.gz"
    git lfs track "packaging/vendor/node-v*-linux-x64.tar.xz"
    git lfs track "packaging/vendor/lua-language-server-linux-x64.tar.gz"
    git lfs track "packaging/vendor/neocmakelsp"

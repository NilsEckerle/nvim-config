# Third-party licenses

The binaries under `packaging/vendor/` are unmodified upstream builds,
redistributed here so the offline `.deb` can be built without network access.
They are **not** covered by this repository's top-level MIT license — each keeps
its own license, reproduced in this directory as required by those licenses.

| Component | License | Upstream |
|-----------|---------|----------|
| Neovim (`nvim-linux-x86_64.tar.gz`) | Apache 2.0 (parts under the Vim license); bundles libuv, LuaJIT, tree-sitter, etc. | https://github.com/neovim/neovim |
| Node.js (`node-v*-linux-x64.tar.xz`) | MIT (bundles OpenSSL, V8, and others under their own licenses) | https://github.com/nodejs/node |
| lua-language-server (`lua-language-server-linux-x64.tar.gz`) | MIT | https://github.com/LuaLS/lua-language-server |
| neocmakelsp (`neocmakelsp`) | MIT | https://github.com/neocmakelsp/neocmakelsp |

Also pulled in at build time (not vendored, but redistributed inside the `.deb`):

| Component | License | Source |
|-----------|---------|--------|
| clangd, clang-format | Apache 2.0 with LLVM exceptions | Debian `clangd` / `clang-format` packages |
| gopls | BSD-3-Clause | Debian `gopls` package |
| pyright | MIT | npm `pyright` |
| tailwindcss-language-server | MIT | npm `@tailwindcss/language-server` |
| tree-sitter parsers | mostly MIT/Apache-2.0, per-grammar | compiled from the grammars nvim-treesitter fetches |

## How to refresh these license files

The neovim and node release tarballs each ship a `LICENSE` at their top level —
copy it out when you refresh the binary. For the MIT tools, grab `LICENSE` from
the upstream repo. Keep the filenames used here:

    neovim-LICENSE.txt
    node-LICENSE
    lua-language-server-LICENSE
    neocmakelsp-LICENSE

Example (neovim):

    tar xzf ../nvim-linux-x86_64.tar.gz -O nvim-linux-x86_64/share/nvim/runtime/doc/../../.. 2>/dev/null || true
    # simpler: extract the whole tarball to a temp dir and copy its LICENSE

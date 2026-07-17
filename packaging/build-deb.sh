#!/usr/bin/env bash
# Builds nvim-bundle_<version>_amd64.deb.
# Runs INSIDE the Debian build container (packaging/dockerfile.build).
# Do not run this directly on the Arch host.
#
# Tool sources (no fragile "latest" downloads):
#   apt              : clangd, clang-format, gopls   (installed in the Dockerfile)
#   vendored (repo)  : neovim, node, lua-language-server, neocmakelsp  (packaging/vendor/)
#   npm, pinned      : pyright, tailwindcss-language-server
set -euo pipefail

PKG_NAME=nvim-bundle
VERSION="${VERSION:-1.0.0}"
ARCH=amd64
NODE_VERSION="${NODE_VERSION:-22.14.0}"

# Pinned npm versions (bump deliberately; these are exact, not ranges).
PYRIGHT_VERSION="${PYRIGHT_VERSION:-1.1.403}"
TAILWIND_LS_VERSION="${TAILWIND_LS_VERSION:-0.14.25}"

SRC=/src                       # nvim config repo (copied into the image)
VENDOR="$SRC/packaging/vendor"
STAGE=/build/stage             # filesystem root of the .deb
OPT="$STAGE/opt/$PKG_NAME"
TOOLS="$OPT/tools"
DIST=/dist

mkdir -p "$OPT"/{nvim,config,data} "$TOOLS"/bin "$STAGE"/usr/bin "$STAGE"/DEBIAN "$DIST"

log()  { printf '\n==> %s\n' "$*"; }
need() { [ -e "$1" ] || { echo "ERROR: missing vendored file: $1" >&2
         echo "See packaging/vendor/README.md for what to put there." >&2; exit 1; }; }

########################### 0. sanity: vendored files ################
need "$VENDOR/nvim-linux-x86_64.tar.gz"
need "$VENDOR/node-v${NODE_VERSION}-linux-x64.tar.xz"
need "$VENDOR/lua-language-server-linux-x64.tar.gz"
need "$VENDOR/neocmakelsp"

########################### 1. neovim ###############################
log "neovim (vendored official static build)"
tar xz -C "$OPT/nvim" --strip-components=1 -f "$VENDOR/nvim-linux-x86_64.tar.gz"

########################### 2. config ###############################
log "config"
tar -C "$SRC" \
    --exclude=./.git --exclude=./packaging \
    -cf - . | tar -xf - -C "$OPT/config"

########################### 3. apt-provided tools ###################
# clangd, clang-format, gopls come from apt (installed in the Dockerfile).
# Copy the real binaries into the bundle so the target needs no apt packages.
log "apt tools -> bundle (clangd, clang-format, gopls)"
copy_real() {  # copy a binary, resolving symlinks, into $TOOLS/bin
  src=$(command -v "$1") || { echo "ERROR: $1 not on PATH in build image" >&2; exit 1; }
  cp -L "$src" "$TOOLS/bin/$2"
}
copy_real clangd        clangd
copy_real clang-format  clang-format
copy_real gopls         gopls

########################### 4. vendored tools #######################
log "lua-language-server (vendored)"
mkdir -p "$TOOLS/lua-language-server"
tar xz -C "$TOOLS/lua-language-server" -f "$VENDOR/lua-language-server-linux-x64.tar.gz"
ln -sf ../lua-language-server/bin/lua-language-server "$TOOLS/bin/lua-language-server"

log "neocmakelsp (vendored)"
cp "$VENDOR/neocmakelsp" "$TOOLS/bin/neocmakelsp"
chmod +x "$TOOLS/bin/neocmakelsp"

########################### 5. npm tools (pinned) ###################
log "node runtime (vendored) + pinned pyright + tailwindcss-language-server"
mkdir -p "$TOOLS/node"
tar xJ -C "$TOOLS/node" --strip-components=1 -f "$VENDOR/node-v${NODE_VERSION}-linux-x64.tar.xz"
export PATH="$TOOLS/node/bin:$PATH"
npm install -g --prefix "$TOOLS/npm" \
  "pyright@${PYRIGHT_VERSION}" \
  "@tailwindcss/language-server@${TAILWIND_LS_VERSION}"

# Intentionally NOT bundled -- get from Debian repos on the target instead:
#   texlab, latexindent  -> apt install texlab texlive-...
# Dropped entirely: omnisharp, csharpier (no C#), r-languageserver, styler (no R)

########################### 6. plugins + treesitter #################
log "restoring plugins from lazy-lock.json + compiling treesitter parsers"
export HOME=/build/home
mkdir -p "$HOME/.config"
ln -sfn "$OPT/config" "$HOME/.config/nvim"
NVIM="$OPT/nvim/bin/nvim"
export PATH="$TOOLS/bin:$TOOLS/npm/bin:$PATH"

"$NVIM" --headless "+Lazy! restore" +qa
"$NVIM" --headless "+TSUpdateSync" +qa || "$NVIM" --headless "+TSUpdate" +qa || true

cp -a "$HOME/.local/share/nvim/." "$OPT/data/"

########################### 7. wrapper + user setup #################
cat > "$STAGE/usr/bin/nvim" <<'EOF'
#!/bin/sh
B=/opt/nvim-bundle
PATH="$B/tools/bin:$B/tools/npm/bin:$B/tools/node/bin:$PATH"
export PATH
exec "$B/nvim/bin/nvim" "$@"
EOF
chmod 755 "$STAGE/usr/bin/nvim"

cat > "$STAGE/usr/bin/nvim-bundle-setup" <<'EOF'
#!/bin/sh
# Copies the bundled config + plugins/parsers into the current user's home.
# Existing ~/.config/nvim and ~/.local/share/nvim are moved to *.bak.<ts>.
set -e
B=/opt/nvim-bundle
ts=$(date +%Y%m%d%H%M%S)
for d in "$HOME/.config/nvim" "$HOME/.local/share/nvim"; do
  if [ -e "$d" ]; then
    mv "$d" "$d.bak.$ts"
    echo "moved existing $d -> $d.bak.$ts"
  fi
done
mkdir -p "$HOME/.config" "$HOME/.local/share"
cp -a "$B/config" "$HOME/.config/nvim"
cp -a "$B/data"   "$HOME/.local/share/nvim"
echo "done. start with: nvim"
EOF
chmod 755 "$STAGE/usr/bin/nvim-bundle-setup"

########################### 8. build the .deb #######################
cat > "$STAGE/DEBIAN/control" <<EOF
Package: $PKG_NAME
Version: $VERSION
Section: editors
Priority: optional
Architecture: $ARCH
Maintainer: you <you@example.com>
Conflicts: neovim
Recommends: git, build-essential
Suggests: texlab, texlive-latex-extra
Description: Self-contained Neovim with config, plugins, parsers and LSPs
 Offline bundle: neovim, personal config, lazy.nvim plugins, compiled
 treesitter parsers, clangd, clang-format, gopls, lua-language-server,
 pyright, tailwindcss-language-server, neocmakelsp.
EOF

dpkg-deb --build --root-owner-group "$STAGE" "$DIST/${PKG_NAME}_${VERSION}_${ARCH}.deb"
log "wrote ${PKG_NAME}_${VERSION}_${ARCH}.deb"

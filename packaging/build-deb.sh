#!/usr/bin/env bash
# Builds nvim-bundle_<version>_amd64.deb.
# Runs INSIDE the Debian build container (packaging/dockerfile.build).
# Do not run this directly on the Arch host.
set -euo pipefail

PKG_NAME=nvim-bundle
VERSION="${VERSION:-1.0.0}"
ARCH=amd64
NODE_VERSION="${NODE_VERSION:-22.14.0}"

SRC=/src                       # nvim config repo (copied into the image)
STAGE=/build/stage             # filesystem root of the .deb
OPT="$STAGE/opt/$PKG_NAME"
TOOLS="$OPT/tools"
DIST=/dist

mkdir -p "$OPT"/{nvim,config,data} "$TOOLS"/bin "$STAGE"/usr/bin "$STAGE"/DEBIAN "$DIST"

log() { printf '\n==> %s\n' "$*"; }

# $1 = owner/repo, $2 = grep -E pattern matching the wanted asset URL
gh_latest_asset() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
    | grep -oE '"browser_download_url": *"[^"]+"' \
    | cut -d'"' -f4 | grep -E "$2" | head -n1
}

########################### 1. neovim ################################
log "neovim (official stable linux-x86_64 build)"
curl -fsSL https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz \
  | tar xz -C "$OPT/nvim" --strip-components=1

########################### 2. config ################################
log "config"
tar -C "$SRC" \
    --exclude=./.git --exclude=./packaging \
    -cf - . | tar -xf - -C "$OPT/config"

########################### 3. node-based tools ######################
log "node runtime + pyright + tailwindcss-language-server + clang-format"
mkdir -p "$TOOLS/node"
curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
  | tar xJ -C "$TOOLS/node" --strip-components=1
export PATH="$TOOLS/node/bin:$PATH"
npm install -g --prefix "$TOOLS/npm" pyright @tailwindcss/language-server clang-format

########################### 4. standalone LSPs #######################
log "lua-language-server"
mkdir -p "$TOOLS/lua-language-server"
curl -fsSL "$(gh_latest_asset LuaLS/lua-language-server 'linux-x64\.tar\.gz')" \
  | tar xz -C "$TOOLS/lua-language-server"
ln -sf ../lua-language-server/bin/lua-language-server "$TOOLS/bin/lua-language-server"

log "clangd"
curl -fsSLo /tmp/clangd.zip "$(gh_latest_asset clangd/clangd 'clangd-linux-[0-9.]+\.zip')"
unzip -q /tmp/clangd.zip -d /tmp/clangd
mkdir -p "$TOOLS/clangd"
cp -a /tmp/clangd/clangd_*/. "$TOOLS/clangd/"
ln -sf ../clangd/bin/clangd "$TOOLS/bin/clangd"

log "neocmakelsp"
curl -fsSLo "$TOOLS/bin/neocmakelsp" \
  "$(gh_latest_asset neocmakelsp/neocmakelsp 'x86_64-unknown-linux-gnu$')"
chmod +x "$TOOLS/bin/neocmakelsp"

log "gopls (static build)"
GOBIN="$TOOLS/bin" CGO_ENABLED=0 GOFLAGS=-trimpath go install golang.org/x/tools/gopls@latest

# Intentionally NOT bundled -- get from Debian repos on the target instead:
#   texlab, latexindent  -> apt install texlab texlive-...
# Dropped entirely: omnisharp, csharpier (no C#), r-languageserver, styler (no R)

########################### 5. plugins + treesitter ##################
log "restoring plugins from lazy-lock.json + compiling treesitter parsers"
export HOME=/build/home
mkdir -p "$HOME/.config"
ln -sfn "$OPT/config" "$HOME/.config/nvim"
NVIM="$OPT/nvim/bin/nvim"
export PATH="$TOOLS/bin:$TOOLS/npm/bin:$PATH"

"$NVIM" --headless "+Lazy! restore" +qa
# nvim-treesitter master uses TSUpdateSync, main branch uses TSUpdate
"$NVIM" --headless "+TSUpdateSync" +qa || "$NVIM" --headless "+TSUpdate" +qa || true

cp -a "$HOME/.local/share/nvim/." "$OPT/data/"
# Optional: shrink the deb a lot, but breaks `:Lazy` version display/updates
# (which are useless offline anyway). Uncomment if you want:
# rm -rf "$OPT"/data/lazy/*/.git

########################### 6. wrapper + user setup ##################
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

########################### 7. build the .deb ########################
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

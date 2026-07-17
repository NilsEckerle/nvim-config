# Vendored binaries

These are checked into the repo so the build is fully reproducible and works
offline. The build script consumes them as-is — it never downloads them.

Refresh them manually when you want newer versions (that's the point: nothing
changes under you). After replacing a file, rebuild with `make deb` and test.

## Required files

### lua-language-server (Linux x86_64 tarball)
Download the `*-linux-x64.tar.gz` asset from:
  https://github.com/LuaLS/lua-language-server/releases
Save it here EXACTLY as:
  vendor/lua-language-server-linux-x64.tar.gz
(Do not extract it — the build extracts it into the bundle. The tarball's top
level contains bin/, main.lua, meta/, etc.)

### neocmakelsp (Linux x86_64 gnu binary)
Download the `neocmakelsp-x86_64-unknown-linux-gnu` asset from:
  https://github.com/neocmakelsp/neocmakelsp/releases
Save it here EXACTLY as:
  vendor/neocmakelsp
(A single executable. The build chmod +x's it and copies it in.)

## Versions currently vendored

Record what you dropped in so future-you knows what's shipping:

- lua-language-server: <fill in version>
- neocmakelsp:        <fill in version>

## Git size note

These are multi-MB binaries. If the repo grows uncomfortably, track them with
git-lfs:
    git lfs track "packaging/vendor/lua-language-server-linux-x64.tar.gz"
    git lfs track "packaging/vendor/neocmakelsp"

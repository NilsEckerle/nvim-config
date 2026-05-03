.PHONY: update build install uninstall build-neovim build-parsers help

REPO_ROOT   := $(shell pwd)
PARSER_OUT  := $(REPO_ROOT)/parsers
LANGUAGES   := python c cpp bash lua css html
NVIM_DIR    := $(REPO_ROOT)/neovim
PARSER_DIR  := $(HOME)/.local/share/nvim/site/parser
CONFIG_DIR  := $(HOME)/.config/nvim
DIST_OUT    := $(REPO_ROOT)/dist/nvim-offline.tar.gz

SUDO := $(shell [ "$$(id -u)" = "0" ] || echo sudo)

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  update              Pull latest commits for all submodules"
	@echo "  build               Build Neovim and parsers"
	@echo "  build-neovim        Build Neovim .deb package"
	@echo "  build-parsers       Build treesitter parsers only"
	@echo "  dist                Create distributable tarball (runs build-parsers first)"
	@echo "  install             Install Neovim, config, parsers and LSP servers"
	@echo "  install-deps        Install runtime dependencies (libc6)"
	@echo "  install-neovim      Install Neovim from pre-built .deb"
	@echo "  install-config      Symlink nvim config to ~/.config/nvim"
	@echo "  install-parsers     Copy parsers to ~/.local/share/nvim/site/parser"
	@echo "  install-lsp         Install clangd and pylsp via apt"
	@echo "  uninstall           Remove Neovim, config symlink and parsers"
	@echo "  uninstall-neovim    Remove Neovim via apt"
	@echo "  uninstall-config    Remove config symlink and restore backup if present"
	@echo "  uninstall-parsers   Remove installed parser .so files"
	@echo "  test                Build dist and spin up a Docker container"
	@echo "                      Usage: make test DISTRO=debian|arch|fedora"
	@echo ""
	@echo "Examples:"
	@echo "  make update build install"
	@echo "  make test DISTRO=arch"

# ── Update ────────────────────────────────────────────────────────────
update:
	git submodule update --remote --checkout

# ── Build ─────────────────────────────────────────────────────────────
build: build-neovim build-parsers

build-neovim:
	docker run --rm \
		-v "$(NVIM_DIR):/src" \
		-v "$(REPO_ROOT)/neovim/build:/src/build" \
		debian:latest \
		bash -c "apt-get update && apt-get install -y cmake ninja-build gcc g++ file && \
		         cd /src && \
		         make CMAKE_BUILD_TYPE=RelWithDebInfo && \
		         cd build && cpack -G DEB"

build-parsers:
	mkdir -p $(PARSER_OUT)
	$(foreach lang,$(LANGUAGES),$(call compile_parser,$(lang)))

define compile_parser
	$(eval DIR := $(REPO_ROOT)/grammars/$(1))
	$(eval SOURCES := $(DIR)/src/parser.c)
	$(eval SOURCES += $(if $(wildcard $(DIR)/src/scanner.c),$(DIR)/src/scanner.c,))
	$(eval SOURCES += $(if $(wildcard $(DIR)/src/scanner.cc),$(DIR)/src/scanner.cc,))
	cc -O2 -shared -fPIC -o $(PARSER_OUT)/$(1).so -I $(DIR)/src $(SOURCES)
	@echo "  built $(1).so"
endef

dist: build-parsers
	$(eval NVIM_DEB := $(shell ls $(NVIM_DIR)/build/nvim-*.deb 2>/dev/null | head -1))
	@if [ -z "$(NVIM_DEB)" ]; then \
		echo "ERROR: no .deb found in neovim/build/ — run 'make build-neovim' first"; \
		exit 1; \
	fi
	mkdir -p $(REPO_ROOT)/dist
	tar -czf $(DIST_OUT) \
		nvim/ \
		parsers/ \
		neovim/build/nvim-*.deb \
		Makefile
	@echo "Distribution tarball created at $(DIST_OUT)"

# ── Install ───────────────────────────────────────────────────────────
install: install-deps install-neovim install-config install-parsers install-lsp

install-deps:
	@if command -v apt-get > /dev/null; then \
		$(SUDO) apt-get install -y libc6; \
	fi

install-neovim:
	$(eval NVIM_DEB := $(shell ls $(NVIM_DIR)/build/nvim-*.deb 2>/dev/null | head -1))
	@if [ -z "$(NVIM_DEB)" ]; then \
		echo "ERROR: no .deb found in neovim/build/ — run 'make build-neovim' and 'make dist' first"; \
		exit 1; \
	fi
	$(SUDO) apt-get remove -y neovim neovim-runtime
	$(SUDO) apt-get install -y "$(NVIM_DEB)"

install-config:
	@if [ -d "$(CONFIG_DIR)" ] && [ ! -L "$(CONFIG_DIR)" ]; then \
		mv $(CONFIG_DIR) $(CONFIG_DIR).backup; \
		echo "Backed up existing config to $(CONFIG_DIR).backup"; \
	fi
	mkdir -p $(shell dirname $(CONFIG_DIR))
	ln -sfn $(REPO_ROOT)/nvim $(CONFIG_DIR)
	@echo "Config symlinked to $(CONFIG_DIR)"

install-parsers:
	mkdir -p $(PARSER_DIR)
	cp $(PARSER_OUT)/*.so $(PARSER_DIR)/
	@echo "Parsers installed to $(PARSER_DIR)"

install-lsp:
	$(SUDO) apt-get install -y clangd python3-pylsp python3-pylsp-jsonrpc

# ── Uninstall ─────────────────────────────────────────────────────────
uninstall: uninstall-neovim uninstall-config uninstall-parsers

uninstall-neovim:
	$(SUDO) apt-get remove -y neovim

uninstall-config:
	rm -f $(CONFIG_DIR)
	@if [ -d "$(CONFIG_DIR).backup" ]; then \
		mv $(CONFIG_DIR).backup $(CONFIG_DIR); \
		echo "Restored config backup"; \
	fi

uninstall-parsers:
	$(foreach lang,$(LANGUAGES),rm -f $(PARSER_DIR)/$(lang).so;)
	@echo "Parsers removed"

local opts = {
	-- Don't auto-install anything (no internet)
	auto_install = false,

	-- Empty for offline - parsers are manually installed
	ensure_installed = {},

	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},

	indent = {
		enable = true,
	},
}

require("nvim-treesitter.config").setup(opts)

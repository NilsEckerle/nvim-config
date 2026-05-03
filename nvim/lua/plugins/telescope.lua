local opts = {
	defaults = {
		layout_config = {
			horizontal = {
				width = 0.90,
				height = 0.80,
				preview_width = 0.4, -- Increased for better preview
			},
		},
		-- Path display configuration
		path_display = { "truncate" }, -- Options: "hidden", "tail", "absolute", "smart", "shorten", "truncate"
	},
}

require("telescope").setup(opts)

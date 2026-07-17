return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").install({
				"c",
				"llvm",
				"cpp",
				"cmake",
				"lua",
				"python",
				"r",
				"vim",
				"vimdoc",
				"query",
				"markdown",
				"markdown_inline",
				"latex",
				"javascript",
				"html",
			})

			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					local buf = args.buf
					local max_filesize = 100 * 1024
					local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
					if ok and stats and stats.size > max_filesize then
						return
					end
					pcall(vim.treesitter.start)
				end,
			})
		end,
	},
}

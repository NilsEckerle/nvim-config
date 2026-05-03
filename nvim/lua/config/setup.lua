local opt = vim.opt

-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = ","

opt.number = true
opt.relativenumber = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.list = true
opt.listchars = {
	tab = "▸ ",
	trail = "-",
	-- 	space = '·',
	-- 	eol = '¬',
	extends = "❯",
	precedes = "❮",
	-- 	nbsp = '⦸'
}

opt.colorcolumn = "100"
opt.guicursor = "n-v-i-c:block"
opt.scrolloff = 10
opt.conceallevel = 1
opt.breakindent = true

-- opt.textwidth = 80
-- opt.formatoptions = "tcrjna"

opt.foldenable = true
opt.foldlevelstart = 99 -- Opens all folds when entering a buffer
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()" -- fold via treesitter context (functions, classes, ...)
opt.foldcolumn = "0" -- disables fold column
opt.foldtext = "" -- shows the code line in folded state

-- opt.mouse = ""

opt.clipboard = "unnamedplus"
-- opt.signcolumn = "no"
vim.opt.signcolumn = "auto:1" -- Show only when needed, 1 column wide

opt.ignorecase = true
opt.smartcase = true

opt.undofile = true
opt.undodir = vim.fn.stdpath("data") .. "/undo"

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight wen yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

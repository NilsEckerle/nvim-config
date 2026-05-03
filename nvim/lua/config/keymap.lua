---@diagnostic disable: missing-fields
local map = vim.keymap.set
local telescope_builtin = require("telescope.builtin")
local harpoon = require("harpoon")

map("i", "jj", "<esc>")
map("i", "kk", "<esc>")
map("n", "<esc>", "<cmd>noh<CR>", { noremap = true, silent = true })

map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode with double ESC" })

map("n", "<leader><leader>", telescope_builtin.find_files, { desc = "Find Files" })
map("n", "<leader>g", telescope_builtin.live_grep, { desc = "Find Grep" })
map("n", "<leader>cR", require("telescope.builtin").lsp_references, { desc = "Telescope references" })

map("n", "<down>", "<cmd>cnext<CR>", { desc = "Quickfix next" })
map("n", "<up>", "<cmd>cprev<CR>", { desc = "Quickfix previous" })
map("n", "<left>", "<cmd>cclose<CR>", { desc = "Quickfix close" })
map("n", "<right>", "<cmd>copen<CR>", { desc = "Quickfix open" })

-- Replace without loosing p register
map("x", "<leader>p", '"_dP', { desc = "replace while keeping p register" })
map("n", "<leader>p", "p", { desc = "replace while keeping p register" })

vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Oil up baby" })

map("n", "<leader>hh", function()
	harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "open harpoon" })
map("n", "<leader>ha", function()
	harpoon:list():add()
end, { desc = "harpoon file" })
for i = 1, 5 do
	map("n", "<leader>" .. i, function()
		harpoon:list():select(i)
	end, { desc = "harpoon to file " .. i })
end

map("n", "<leader>o", function()
	local file_dir = vim.fn.expand("%:p:h")
	vim.fn.jobstart({ "nemo", file_dir }, {
		detach = true,
		on_exit = function(_, code)
			if code ~= 0 then
				vim.notify("Failed to open Nemo", vim.log.levels.ERROR)
			end
		end,
	})
end, { desc = "Open current file directory in Nemo" })

-- LuaSnip
local luasnip = require("luasnip")
map("i", "<C-h>", function()
	luasnip.expand()
end, { silent = true })
map("i", "<C-j>", function()
	luasnip.jump(1)
end, { silent = true })
map("i", "<C-k>", function()
	luasnip.jump(-1)
end, { silent = true })

-- whichkey
map("n", "<localleader>?", function()
	require("which-key").show({ global = false })
end, { desc = "Buffer Local Keymaps (which-key)" })
map("n", "<leader>?", function()
	require("which-key").show({ global = true })
end, { desc = "Global Keymaps (which-key)" })

-- LSP keymaps
-- format keymaps
vim.api.nvim_create_autocmd("LspAttach", {
	desc = "LSP & Formatter actions",
	callback = function(event)
		local buffer = event.buf
		local lmap = function(key, fn, desc)
			vim.keymap.set("n", key, fn, { buffer = buffer, desc = desc })
		end

		-- LSP keymaps
		lmap("K", vim.lsp.buf.hover, "Hover information")
		lmap("gd", vim.lsp.buf.definition, "Go to definition")
		lmap("gD", vim.lsp.buf.declaration, "Go to declaration")
		lmap("gi", vim.lsp.buf.implementation, "Go to implementation")
		lmap("<leader>ca", vim.lsp.buf.code_action, "Code action")
		lmap("<leader>cd", vim.diagnostic.open_float, "Code diagnostics")
		lmap("<leader>cr", vim.lsp.buf.rename, "Rename")
		lmap("<leader>cR", require("telescope.builtin").lsp_references, "References")

		-- format keymaps
		lmap("<localleader>f", function()
			local mode = vim.api.nvim_get_mode().mode
			if mode == "v" or mode == "V" then
				vim.lsp.buf.format({
					range = {
						start = vim.api.nvim_buf_get_mark(0, "<"),
						["end"] = vim.api.nvim_buf_get_mark(0, ">"),
					},
				})
			else
				vim.lsp.buf.format()
			end
		end, "Format")
		lmap("<localleader>f", vim.lsp.buf.format, "Format")
		vim.keymap.set("v", "<localleader>f", function()
			vim.lsp.buf.format({
				range = {
					start = vim.api.nvim_buf_get_mark(0, "<"),
					["end"] = vim.api.nvim_buf_get_mark(0, ">"),
				},
			})
		end, { buffer = event.buf, desc = "Format selection" })
	end,
})

-- Set buffer-local keymap for Oil buffers
vim.api.nvim_create_autocmd("FileType", {
	pattern = "oil",
	callback = function()
		vim.keymap.set("n", "<leader>o", function()
			local oil = require("oil")
			local dir = oil.get_current_dir()
			if dir then
				vim.fn.jobstart({ "nemo", dir }, { detach = true })
			else
				-- Fallback to current working directory
				vim.fn.jobstart({ "nemo", vim.fn.getcwd() }, { detach = true })
			end
		end, { desc = "Open directory in Nemo", buffer = true })
	end,
})

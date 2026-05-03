local ok, luasnip = pcall(require, "luasnip")
if not ok then
	return
end

luasnip.setup({})

-- Load VSCode-style snippets from friendly-snippets
require("luasnip.loaders.from_vscode").lazy_load()

-- Load your manual snippets from nvim/snippets/
require("luasnip.loaders.from_lua").lazy_load({
	paths = vim.fn.stdpath("config") .. "/snippets",
})

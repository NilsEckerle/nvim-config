local cmp = require("cmp")
local luasnip = require("luasnip")

local opts = {
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	completion = {
		completeopt = "menu,menuone,noinsert", -- Show menu, select first item, but don't insert
	},
	preselect = cmp.PreselectMode.Item, -- Preselect first item
	-- Your preferred keybindings
	mapping = {
		["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
		["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
		["<C-y>"] = cmp.mapping.confirm({ select = true }),
		["<C-h>"] = cmp.mapping.confirm({ select = true }),
		["<C-d>"] = cmp.mapping.scroll_docs(4),
		["<C-u>"] = cmp.mapping.scroll_docs(-4),
	},

	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
		{ name = "path" },
	}, {
		{ name = "buffer" },
	}),

	formatting = {
		format = function(entry, vim_item)
			-- Show source name
			vim_item.menu = ({
				nvim_lsp = "[LSP]",
				buffer = "[Buffer]",
				path = "[Path]",
				luasnip = "[Snip]",
			})[entry.source.name]
			return vim_item
		end,
	},

	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},

	experimental = {
		ghost_text = true,
	},
}

-- needed to get rid of vim standard <C-k> which is conflicting
pcall(vim.keymap.del, "i", "<C-k>")
pcall(vim.keymap.del, "i", "<C-j>")

cmp.setup(opts)

-- Command line completion with same behavior
cmp.setup.cmdline(":", {
	mapping = cmp.mapping.preset.cmdline({
		["<C-j>"] = { c = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }) },
		["<C-k>"] = { c = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }) },
		["<C-y>"] = { c = cmp.mapping.confirm({ select = true }) },
	}),
	completion = {
		completeopt = "menu,menuone,noinsert",
	},
	sources = cmp.config.sources({
		{ name = "path" },
	}, {
		{ name = "cmdline" },
	}),
})

-- Search completion with same behavior
cmp.setup.cmdline({ "/", "?" }, {
	mapping = cmp.mapping.preset.cmdline({
		["<C-j>"] = { c = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }) },
		["<C-k>"] = { c = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }) },
		["<C-y>"] = { c = cmp.mapping.confirm({ select = true }) },
	}),
	completion = {
		completeopt = "menu,menuone,noinsert",
	},
	sources = {
		{ name = "buffer" },
	},
})

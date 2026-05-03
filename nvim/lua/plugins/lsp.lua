local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Apply capabilities and inlay hints to every LSP that attaches
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client then
			return
		end

		-- Merge cmp capabilities
		client.config.capabilities = vim.tbl_deep_extend("force", client.config.capabilities or {}, capabilities)

		-- Inlay hints
		if vim.lsp.inlay_hint and client.server_capabilities.inlayHintProvider then
			vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
		end
	end,
})

require("plugins.lsp.clangd")
require("plugins.lsp.pylsp")

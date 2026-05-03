local ok, whichkey = pcall(require, "which-key")
if not ok then
	return
end

whichkey.setup({
	preset = "helix", -- classic, modern, helix
	delay = 10000,
	spec = {
		{ "<leader>", group = "Leader key for most keybindings" },
		{ "z", group = "[z]old" },
	},
})

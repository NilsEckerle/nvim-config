-- Load all plugin files from the plugins directory
local plugins_dir = vim.fn.stdpath("config") .. "/lua/plugins"

-- Check if the plugins directory exists
if vim.fn.isdirectory(plugins_dir) == 1 then
	-- Get all .lua files in the plugins directory
	local plugin_files = vim.fn.globpath(plugins_dir, "*.lua", false, true)

	for _, file in ipairs(plugin_files) do
		-- Extract filename without path and .lua extension
		local filename = vim.fn.fnamemodify(file, ":t:r")

		-- Require the plugin file
		local ok, err = pcall(require, "plugins." .. filename)
		if not ok then
			vim.notify("Error loading plugin: " .. filename .. "\n" .. err, vim.log.levels.ERROR)
		end
	end
else
	vim.notify("Plugins directory not found: " .. plugins_dir, vim.log.levels.WARN)
end

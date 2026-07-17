return {
	"lervag/vimtex",
	ft = { "tex", "latex" },
	init = function()
		-- Muss vor dem Laden/Initialisieren von VimTeX gesetzt sein
		vim.g.vimtex_view_method = "zathura"
		vim.g.vimtex_view_automatic = 1

		-- Standard: latexmk (TeX Live) für normale Projekte
		vim.g.vimtex_compiler_method = "latexmk"

		-- Tectonic-V2-Projekte erkennen (Tectonic.toml aufwärts suchen)
		-- und dort VimTeX-Kompilierung deaktivieren.
		-- Setzt b:tectonic_root, das auch config/keymap.lua nutzt.
		vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
			pattern = "*.tex",
			callback = function(args)
				local toml = vim.fs.find("Tectonic.toml", {
					upward = true,
					path = vim.fs.dirname(vim.api.nvim_buf_get_name(args.buf)),
				})[1]
				if toml then
					vim.b[args.buf].vimtex_compiler_enabled = 0
					vim.b[args.buf].tectonic_root = vim.fs.dirname(toml)
				end
			end,
		})
	end,
	config = function()
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "tex", "latex" },
			callback = function()
				-- Cursor-Timer für VimtexView nur außerhalb von
				-- Tectonic-Projekten (dort kompiliert VimTeX nicht,
				-- VimtexView kennt das PDF unter build/ nicht)
				if not vim.b.tectonic_root then
					-- Create a timer for delayed execution
					local view_timer = vim.loop.new_timer()
					local timer_running = false

					-- Ensure we clean up the timer when buffer is unloaded
					vim.api.nvim_create_autocmd("BufUnload", {
						buffer = 0,
						callback = function()
							if view_timer then
								view_timer:stop()
								view_timer:close()
							end
						end,
					})

					-- Auto-update Zathura view when cursor moves
					-- (only if viewer is running)
					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
						buffer = 0,
						callback = function()
							if vim.b.vimtex and vim.b.vimtex.viewer and vim.b.vimtex.viewer.xwin_id then
								if timer_running then
									view_timer:stop()
								end
								timer_running = true
								view_timer:start(
									3000,
									0,
									vim.schedule_wrap(function()
										timer_running = false
										local current_window =
											vim.fn.system("hyprctl activewindow -j | jq -r '.address'"):gsub("%s+", "")
										vim.cmd("silent! VimtexView")
										vim.defer_fn(function()
											vim.fn.system("hyprctl dispatch focuswindow address:" .. current_window)
										end, 50)
									end)
								)
							end
						end,
					})
				end

				-- Setup which-key group for LaTeX
				local status_ok, which_key = pcall(require, "which-key")
				if status_ok then
					which_key.add({
						{ "<localleader>l", group = "LaTeX", buffer = 0 },
					})
				end
			end,
		})
	end,
}

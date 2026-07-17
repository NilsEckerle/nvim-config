-- Sourced via:  nvim --headless -c 'luafile .../ts-install.lua' +qa
-- (luafile runs AFTER normal startup, so lazy.nvim and your config are loaded.)
-- Force-loads nvim-treesitter, triggers install for the exact parser list, and
-- blocks until every .so exists. Exits nonzero if any are missing.

local need = {
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
}

local function log(m)
	io.stderr:write("[ts-install] " .. m .. "\n")
end

pcall(function()
	vim.cmd("Lazy! load nvim-treesitter")
end)

local ok, ts = pcall(require, "nvim-treesitter")
if ok and type(ts.install) == "function" then
	pcall(function()
		ts.install(need)
	end)
else
	log("note: install() not directly callable; relying on config-triggered install")
end

local p = vim.fn.stdpath("data") .. "/site/parser"
local function missing()
	local m = {}
	for _, l in ipairs(need) do
		if vim.fn.filereadable(p .. "/" .. l .. ".so") == 0 then
			m[#m + 1] = l
		end
	end
	return m
end

log("waiting for " .. #need .. " parsers to compile into " .. p)
vim.wait(1800000, function()
	return #missing() == 0
end, 500)

local m = missing()
if #m > 0 then
	log("MISSING: " .. table.concat(m, ", "))
	vim.cmd("cquit 1") -- exit nonzero so the build fails loudly
else
	log("all " .. #need .. " parsers compiled")
	vim.cmd("qall!")
end

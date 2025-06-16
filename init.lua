------------------------------------------------------------------------------
-- Clone 'mini.nvim' manually in a way that it gets managed by 'mini.deps'
------------------------------------------------------------------------------

local path_package = vim.fn.stdpath("data") .. "/site/"
local mini_path = path_package .. "pack/deps/start/mini.nvim"
---@diagnostic disable-next-line: undefined-field
if not vim.loop.fs_stat(mini_path) then
	vim.cmd('echo "Installing `mini.nvim`" | redraw')
	local clone_cmd = { "git", "clone", "--filter=blob:none", "https://github.com/echasnovski/mini.nvim", mini_path }
	vim.fn.system(clone_cmd)
	vim.cmd("packadd mini.nvim | helptags ALL")
	vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

-- Set up 'mini.deps' (customize to your liking)
require("mini.deps").setup({ path = { package = path_package } })

-- Use 'mini.deps'. `now()` and `later()` are helpers for a safe two-stage
-- startup and are optional.
---@diagnostic disable-next-line: undefined-global
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

------------------------------------------------------------------------------
-- Global configuration
------------------------------------------------------------------------------

-- Global options
-- Disable unused providers
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

-- Folding
vim.o.foldmethod = "indent"
vim.o.foldlevel = 99

-- Tabs
vim.o.tabstop = 4 -- tabs are 4 characters width
vim.o.shiftwidth = 4
vim.o.expandtab = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
-- vim.schedule(function()
-- 	vim.o.clipboard = "unnamedplus"
-- end)

-- UI
vim.opt.whichwrap = vim.opt.whichwrap + "<,>,h,l" -- eol wrap
vim.o.scrolloff = 14
vim.o.sidescrolloff = 14
vim.o.wrap = true

-- GUI
if vim.g.neovide then
	vim.o.guifont = "MonaspiceNe Nerd Font:h12"
	vim.g.neovide_fullscreen = true
	vim.g.minianimate_disable = true
	-- MacOs fix for paste
	vim.keymap.set({ "n", "v", "s", "x", "o", "i", "l", "c", "t" }, "<D-v>", function()
		vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
	end, { noremap = true, silent = true })
end

-- Autocommands
-- Markdown folding
vim.api.nvim_create_augroup("MarkdownFolding", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	group = "MarkdownFolding",
	callback = function()
		vim.wo.foldmethod = "expr"
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
	end,
})

-- Lua indentation
vim.api.nvim_create_autocmd("FileType", {
	pattern = "lua",
	callback = function()
		vim.bo.tabstop = 2
		vim.bo.shiftwidth = 2
		vim.bo.expandtab = false
	end,
})

------------------------------------------------------------------------------
-- Safely execute immediately
------------------------------------------------------------------------------

-- Mini Basics
now(function()
	require("mini.basics").setup({
		options = {
			basic = true,
			extra_ui = false,
			win_borders = "bold",
		},
		mappings = {
			basic = true,
			windows = true,
		},
		autocommands = {
			basic = true,
			relnum_in_visual_mode = true,
		},
	})
end)

-- Kanagawa colorscheme
now(function()
	add({ source = "rebelot/kanagawa.nvim" })
	vim.cmd("colorscheme kanagawa")
end)

-- Mini Icons
now(function()
	require("mini.icons").setup()

	-- Make mini.completion use mini.icons
	---@diagnostic disable-next-line: undefined-global
	later(MiniIcons.tweak_lsp_kind)
end)

-- Mini Notify
now(function()
	require("mini.notify").setup({
		-- lsp_progress = {
		-- 	enable = false,
		-- },
	})
	vim.notify = require("mini.notify").make_notify()
end)

-- Mini Statusline
now(function()
	local statusline = require("mini.statusline")
	statusline.setup({ use_icons = true })
	-- You can configure sections in the statusline by overriding their
	-- default behavior. For example, here we set the section for
	-- cursor location to LINE:COLUMN
	---@diagnostic disable-next-line: duplicate-set-field
	statusline.section_location = function()
		return "%2l:%-2v"
	end
end)

-- Mini Sessions
now(function()
	require("mini.sessions").setup()
end)

-- Mini Starter
now(function()
	require("mini.starter").setup()

	local starter = require("mini.starter")
	starter.setup({
		evaluate_single = true,
		items = {
			starter.sections.builtin_actions(),
			starter.sections.recent_files(10, false),
			starter.sections.recent_files(10, true),
			-- Use this if you set up 'mini.sessions'
			starter.sections.sessions(5, true),
		},
		content_hooks = {
			starter.gen_hook.adding_bullet(),
			starter.gen_hook.indexing("all", { "Builtin actions" }),
			starter.gen_hook.padding(3, 2),
			starter.gen_hook.aligning("center", "center"),
		},
	})
end)

------------------------------------------------------------------------------
-- Safely execute later
------------------------------------------------------------------------------

-- Mini Animations
later(function()
	require("mini.animate").setup()
end)

-- Better Around/Inside textobjects
-- Examples:
--  - va)  - [V]isually select [A]round [)]paren
--  - yinq - [Y]ank [I]nside [N]ext [Q]uote
--  - ci'  - [C]hange [I]nside [']quote
later(function()
	local gen_ai_spec = require("mini.extra").gen_ai_spec
	require("mini.ai").setup({
		n_lines = 500,
		custom_textobjects = {
			B = gen_ai_spec.buffer(),
			D = gen_ai_spec.diagnostic(),
			I = gen_ai_spec.indent(),
			L = gen_ai_spec.line(),
			N = gen_ai_spec.number(),
		},
	})
end)

-- Mini Bracketed
later(function()
	require("mini.bracketed").setup()
end)

-- Mini Bufremove
later(function()
	require("mini.bufremove").setup()
	vim.keymap.set("n", "<Leader>bd", "<CMD>lua MiniBufremove.delete()<CR>", { desc = "Delete Buffer" })
	vim.keymap.set("n", "<Leader>bu", "<CMD>lua MiniBufremove.unshow()<CR>", { desc = "Unshow Buffer In All Windows" })
	vim.keymap.set(
		"n",
		"<Leader>bU",
		"<CMD>lua MiniBufremove.unshow_in_window()<CR>",
		{ desc = "Unshow Buffer In Current Window" }
	)
	vim.keymap.set("n", "<Leader>bw", "<CMD>lua MiniBufremove.wipeout()<CR>", { desc = "Wipeout Buffer" })
end)

-- Mini Clue
later(function()
	local miniclue = require("mini.clue")
	miniclue.setup({
		window = {
			delay = 500,
			config = {
				width = "auto",
				border = "single",
			},
		},

		triggers = {
			-- Leader triggers
			{ mode = "n", keys = "<Leader>" },
			{ mode = "x", keys = "<Leader>" },

			-- Toggle trigger
			{ mode = "n", keys = "\\" },

			-- Bracketed
			{ mode = "n", keys = "[" },
			{ mode = "n", keys = "]" },

			-- Surround
			{ mode = "n", keys = "s" },

			-- Built-in completion
			{ mode = "i", keys = "<C-x>" },

			-- `g` key
			{ mode = "n", keys = "g" },
			{ mode = "x", keys = "g" },

			-- Marks
			{ mode = "n", keys = "'" },
			{ mode = "n", keys = "`" },
			{ mode = "x", keys = "'" },
			{ mode = "x", keys = "`" },

			-- Registers
			{ mode = "n", keys = '"' },
			{ mode = "x", keys = '"' },
			{ mode = "i", keys = "<C-r>" },
			{ mode = "c", keys = "<C-r>" },

			-- Window commands
			{ mode = "n", keys = "<C-w>" },

			-- `z` key
			{ mode = "n", keys = "z" },
			{ mode = "x", keys = "z" },
		},

		clues = {
			{ mode = "n", keys = "<Leader>b", desc = " Buffers" },
			{ mode = "n", keys = "<Leader>d", desc = " Debug" },
			{ mode = "n", keys = "<Leader>g", desc = " Global" },
			{ mode = "n", keys = "<Leader>pg", desc = "󰊢 Git" },
			-- { mode = "n", keys = "<Leader>i", desc = "󰏪 Insert" },
			{ mode = "n", keys = "<Leader>pl", desc = "󰘦 LSP" },
			-- { mode = "n", keys = "<Leader>m", desc = "Mini" },
			{ mode = "n", keys = "<Leader>p", desc = " Pick" },
			-- { mode = "n", keys = "<Leader>s", desc = "󰆓 Session" },
			-- { mode = "n", keys = "<Leader>t", desc = " Terminal" },
			-- { mode = "n", keys = "<Leader>u", desc = "󰔃 UI" },
			{ mode = "n", keys = "<Leader>pv", desc = " Visits" },
			--
			miniclue.gen_clues.builtin_completion(),
			miniclue.gen_clues.g(),
			miniclue.gen_clues.marks(),
			miniclue.gen_clues.registers(),
			miniclue.gen_clues.windows(),
			miniclue.gen_clues.z(),
		},
	})
end)

-- Mini Comment
later(function()
	require("mini.comment").setup()
end)

-- Mini Cursorword
later(function()
	require("mini.cursorword").setup()
end)

-- Mini Diff
later(function()
	require("mini.diff").setup({
		-- Options for how hunks are visualized
		view = {
			-- Visualization style. Possible values are 'sign' and 'number'.
			-- Default: 'number' if line numbers are enabled, 'sign' otherwise.
			-- style = vim.go.number and 'number' or 'sign',
			style = "number",

			-- Signs used for hunks with 'sign' view
			-- signs = { add = "▒", change = "▒", delete = "▒" },
			-- signs = { add = "+", change = "~", delete = "-" },
			-- signs = { add = "│", change = "│", delete = "│" },

			-- Priority of used visualization extmarks
			priority = 199,
			-- :lua MiniDiff.toggle_overlay()
		},
	})
end)

-- Mini Extra
later(function()
	require("mini.extra").setup()
end)

-- Mini Files
later(function()
	require("mini.files").setup({
		mappings = {
			close = "<ESC>",
		},
		windows = {
			preview = true,
			border = "rounded",
			width_preview = 80,
		},
	})

	-- Oil-like keymap
	vim.keymap.set(
		"n",
		"-",
		"<CMD>lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>",
		{ desc = "Open parent directory" }
	)
end)

-- Mini Jump
later(function()
	require("mini.jump").setup()
end)

-- Mini Git
later(function()
	require("mini.git").setup()
end)

-- Mini Highlighter
later(function()
	require("mini.hipatterns").setup({
		highlighters = {
			-- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
			fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
			hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
			todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
			note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },

			-- Highlight hex color strings (`#123456`) using that color
			hex_color = require("mini.hipatterns").gen_highlighter.hex_color(),
		},
	})
end)

-- Mini Indentscope
later(function()
	require("mini.indentscope").setup({
		symbol = "│",
		draw = { animation = require("mini.indentscope").gen_animation.none() },
	})

	-- Disable for certain filetypes
	local f = function(args)
		local ft = vim.bo[args.buf].filetype
		if ft == "diff" or ft == "help" then
			vim.b[args.buf].miniindentscope_disable = true
		end
	end
	vim.api.nvim_create_autocmd("Filetype", { callback = f })
end)

-- Mini Keymaps
later(function()
	local map_multistep = require("mini.keymap").map_multistep
	map_multistep("i", "<Tab>", { "minisnippets_next", "increase_indent", "minisnippets_expand", "jump_after_close" })
	map_multistep("i", "<S-Tab>", { "minisnippets_prev", "jump_before_open" })
	map_multistep("i", "<CR>", { "pmenu_accept", "minipairs_cr" })
	map_multistep("i", "<BS>", { "minipairs_bs", "decrease_indent" })

	-- disable highlight search
	local action = function()
		vim.cmd("nohlsearch")
	end
	require("mini.keymap").map_combo({ "n", "i", "x", "c" }, "<Esc><Esc>", action)

	-- Disable for a certain filetype (for example, "lua")
	local f = function(args)
		vim.b[args.buf].minikeymap_disable = true
	end
	vim.api.nvim_create_autocmd("Filetype", { pattern = "codecompanion", callback = f })
end)

-- Mini Misc
later(function()
	require("mini.misc").setup()

	---@diagnostic disable-next-line: undefined-global
	MiniMisc.setup_restore_cursor()

	---@diagnostic disable-next-line: undefined-global
	MiniMisc.setup_auto_root()
end)

-- Mini Move
later(function()
	require("mini.move").setup({
		-- Module mappings. Use `''` (empty string) to disable one.
		mappings = {
			-- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
			left = "<C-S-h>",
			right = "<C-S-l>",
			down = "<C-S-j>",
			up = "<C-S-k>",

			-- Move current line in Normal mode
			line_left = "<C-S-h>",
			line_right = "<C-S-l>",
			line_down = "<C-S-j>",
			line_up = "<C-S-k>",
		},
	})
end)

-- Mini Operators
later(function()
	require("mini.operators").setup()
end)

-- Mini Pairs
later(function()
	require("mini.pairs").setup()
end)

-- Mini Pick
later(function()
	require("mini.pick").setup({
		mappings = {
			choose_in_vsplit = "<C-CR>",
		},
	})

	local config_path = vim.fn.stdpath("config")
	vim.keymap.set(
		"n",
		"<Leader>pc",
		'<CMD>lua MiniPick.builtin.files({}, {source = {cwd = "' .. config_path .. '"}})<CR>',
		{ desc = "Pick Configuration" }
	)

	vim.keymap.set("n", "<Leader>pC", "<CMD>Pick colorschemes<CR>", { desc = "Pick Colorschemes" })
	vim.keymap.set("n", "<Leader>pd", "<CMD>Pick diagnostic<CR>", { desc = "Pick Diagnostics" })
	vim.keymap.set("n", "<Leader>pf", "<CMD>Pick explorer<CR>", { desc = "Pick Files" })
	vim.keymap.set("n", "<Leader>pG", "<CMD>Pick grep_live<CR>", { desc = "Pick Live Grep" })
	vim.keymap.set("n", "<Leader>pgb", "<CMD>Pick git_branches<CR>", { desc = "Pick Git Branches" })
	vim.keymap.set("n", "<Leader>pgc", "<CMD>Pick git_commits<CR>", { desc = "Pick Git Commits" })
	vim.keymap.set("n", "<Leader>pgf", "<CMD>Pick git_files<CR>", { desc = "Pick Git Files" })
	vim.keymap.set("n", "<Leader>pgh", "<CMD>Pick git_hunks<CR>", { desc = "Pick Git Hunks" })
	vim.keymap.set("n", "<Leader>pH", "<CMD>Pick hipatterns<CR>", { desc = "Pick Highlights" })
	vim.keymap.set("n", "<Leader>ph", "<CMD>Pick history<CR>", { desc = "Pick History" })
	vim.keymap.set("n", "<Leader>pk", "<CMD>Pick keymaps<CR>", { desc = "Pick Keymaps" })
	vim.keymap.set("n", "<Leader>pL", "<CMD>Pick buf_lines<CR>", { desc = "Pick Buffer Lines" })
	vim.keymap.set("n", "<Leader>plD", "<CMD>Pick lsp scope='declaration'<CR>", { desc = "Pick LSP Declarations" })
	vim.keymap.set("n", "<Leader>pld", "<CMD>Pick lsp scope='definition'<CR>", { desc = "Pick LSP Definitions" })
	vim.keymap.set(
		"n",
		"<Leader>pli",
		"<CMD>Pick lsp scope='implementation'<CR>",
		{ desc = "Pick LSP Implementations" }
	)
	vim.keymap.set("n", "<Leader>plr", "<CMD>Pick lsp scope='references'<CR>", { desc = "Pick LSP References" })
	vim.keymap.set(
		"n",
		"<Leader>pls",
		"<CMD>Pick lsp scope='document_symbol'<CR>",
		{ desc = "Pick LSP Document Symbols" }
	)
	vim.keymap.set(
		"n",
		"<Leader>plw",
		"<CMD>Pick lsp scope='workspace_symbol'<CR>",
		{ desc = "Pick LSP Workspace Symbols" }
	)
	vim.keymap.set("n", "<Leader>pm", "<CMD>Pick marks scope='buf'<CR>", { desc = "Pick Buffer Marks" })
	vim.keymap.set("n", "<Leader>po", "<CMD>Pick oldfiles<CR>", { desc = "Pick Old Files" })
	vim.keymap.set("n", "<Leader>pO", "<CMD>Pick options<CR>", { desc = "Pick Neovim Options" })
	vim.keymap.set("n", "<Leader>pq", "<CMD>Pick list scope='quickfix'<CR>", { desc = "Pick Quickfixes" })
	vim.keymap.set("n", "<Leader>pr", "<CMD>Pick registers<CR>", { desc = "Pick Registers" })
	vim.keymap.set("n", "<Leader>ps", "<CMD>Pick spellsuggest<CR>", { desc = "Pick Spell Suggests" })
	vim.keymap.set("n", "<Leader>pvl", "<CMD>Pick visit_labels<CR>", { desc = "Pick Visits Labels" })
	vim.keymap.set("n", "<Leader>pvp", "<CMD>Pick visit_paths<CR>", { desc = "Pick Visits Paths" })

	vim.keymap.set("n", "<Leader>h", "<CMD>Pick help<CR>", { desc = "Pick Help" })
	vim.keymap.set("n", "<Leader><Leader>", "<CMD>Pick buffers<CR>", { desc = " Pick Buffers" })
end)

-- Mini Surround
later(function()
	-- Add/delete/replace surroundings (brackets, quotes, etc.)
	-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
	-- - sd'   - [S]urround [D]elete [']quotes
	-- - sr)'  - [S]urround [R]eplace [)] [']
	require("mini.surround").setup()
end)

-- Mini Tabline
-- later(function()
-- 	require("mini.tabline").setup({
-- 		show_icons = true,
-- 		format = function(buf_id, label)
-- 			local suffix = vim.bo[buf_id].modified and "+ " or ""
-- 			---@diagnostic disable-next-line: undefined-global
-- 			return MiniTabline.default_format(buf_id, label) .. suffix
-- 		end,
-- 		tabpage_section = "left",
-- 	})
-- 	vim.opt.showtabline = 1
-- end)

-- Mini Trailspace
later(function()
	require("mini.trailspace").setup()
end)

-- Mini Visits
later(function()
	require("mini.visits").setup()
end)

------------------------------------------------------------------------------
-- LSP and Treesitter
------------------------------------------------------------------------------

-- nvim-treesitter
now(function()
	add({
		source = "nvim-treesitter/nvim-treesitter",
		checkout = "master",
		-- Perform action after every checkout
		hooks = {
			post_checkout = function()
				vim.cmd("TSUpdate")
			end,
		},
	})

	-- Possible to immediately execute code which depends on the added plugin
	require("nvim-treesitter.configs").setup({
		ensure_installed = {
			"bash",
			"c",
			"diff",
			"go",
			"gomod",
			"gowork",
			"gosum",
			"html",
			"lua",
			"luadoc",
			"markdown",
			"markdown_inline",
			"powershell",
			"query",
			"rust",
			"toml",
			"vim",
			"vimdoc",
			"yaml",
		},
		highlight = { enable = true },
	})
end)

-- nvim-lspconfig
now(function()
	add({
		source = "neovim/nvim-lspconfig",
		-- NOTE no mason depends, we use mise instead
	})

	-- HACK manual installation of powershell_es is required
	vim.lsp.config("powershell_es", {
		bundle_path = vim.fn.stdpath("data") .. "/PowerShellEditorServices",
	})

	-- NOTE make sure your LSP servers are available on your PATH
	vim.lsp.enable({ "lua_ls", "gopls", "rust_analyzer", "powershell_es", "pyright", "marksman" })

	-- Diagnostic Config
	-- See :help vim.diagnostic.Opts
	vim.diagnostic.config({
		virtual_lines = { current_line = true },
		-- virtual_text = { source = "if_many" },
		float = { border = "rounded", source = true },
		signs = {
			text = {
				[vim.diagnostic.severity.ERROR] = "󰅚 ",
				[vim.diagnostic.severity.WARN] = "󰀪 ",
				[vim.diagnostic.severity.INFO] = "󰋽 ",
				[vim.diagnostic.severity.HINT] = "󰌶 ",
			},
		},
	})

	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
		callback = function(event)
			local map = function(keys, func, desc, mode)
				mode = mode or "n"
				vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
			end

			map("K", function()
				vim.lsp.buf.hover({ border = "single", max_height = 25, max_width = 120 })
			end, "Hover")

			-- Rename the variable under your cursor.
			--  Most Language Servers support renaming across files, etc.
			map("grn", vim.lsp.buf.rename, "Rename Variable")

			-- Execute a code action, usually your cursor needs to be on top of an error
			-- or a suggestion from your LSP for this to activate.
			map("gra", vim.lsp.buf.code_action, "Goto Code Action", { "n", "x" })

			-- Jump to the definition of the word under your cursor.
			--  This is where a variable was first declared, or where a function is defined, etc.
			--  To jump back, press <C-t>.
			map("grd", vim.lsp.buf.definition, "Goto Definition")

			-- WARN: This is not Goto Definition, this is Goto Declaration.
			--  For example, in C this would take you to the header.
			map("grD", vim.lsp.buf.declaration, "Goto Declaration")

			-- Jump to the type of the word under your cursor.
			--  Useful when you're not sure what type a variable is and you want to see
			--  the definition of its *type*, not where it was *defined*.
			map("grt", vim.lsp.buf.type_definition, "Goto Type Definition")
		end,
	})
end)

-- Mini Snippets
later(function()
	add({
		source = "rafamadriz/friendly-snippets",
	})

	local gen_loader = require("mini.snippets").gen_loader
	require("mini.snippets").setup({
		snippets = {
			-- Load custom file with global snippets first (adjust for Windows)
			gen_loader.from_file("~/.config/nvim/snippets/global.json"),

			-- Load snippets based on current language by reading files from
			-- "snippets/" subdirectories from 'runtimepath' directories.
			-- the following line is a fix for markdow snippets
			-- gen_loader.from_lang(),
			gen_loader.from_lang({ lang_patterns = { markdown_inline = { "markdown.json" } } }),
		},
	})

	-- Integration with mini.completion
	---@diagnostic disable-next-line: undefined-global
	MiniSnippets.start_lsp_server({ match = false })
end)

-- Mini Completion
later(function()
	require("mini.completion").setup({
		lsp_completion = { source_func = "omnifunc", auto_setup = false },
	})

	if vim.fn.has("nvim-0.11") == 1 then
		vim.opt.completeopt:append("fuzzy") -- Use fuzzy matching for built-in completion
	end

	local on_attach = function(args)
		vim.bo[args.buf].omnifunc = "v:lua.MiniCompletion.completefunc_lsp"
	end
	vim.api.nvim_create_autocmd("LspAttach", { callback = on_attach })

	---@diagnostic disable-next-line: undefined-global
	vim.lsp.config("*", { capabilities = MiniCompletion.get_lsp_capabilities() })
end)

------------------------------------------------------------------------------
-- External plugins
------------------------------------------------------------------------------

-- vim-sleuth
now(function()
	add({
		source = "tpope/vim-sleuth",
	})
end)

-- vim-startuptime
now(function()
	add({
		source = "dstein64/vim-startuptime",
	})
end)

-- conform.nvim
later(function()
	add({
		source = "stevearc/conform.nvim",
	})

	require("conform").setup({
		format_on_save = {
			-- These options will be passed to conform.format()
			timeout_ms = 500,
			lsp_format = "fallback",
		},
		-- NOTE Please ensure your formatters are present on you path
		formatters_by_ft = {
			lua = { "stylua" },
			go = { "goimports", "gofumpt" },
			markdown = { "prettier" },
			-- Conform will run multiple formatters sequentially
			-- python = { "isort", "black" },
			python = { "ruff_format" },
			-- You can customize some of the format options for the filetype (:help conform.format)
			rust = { "rustfmt" },
			-- Conform will run the first available formatter
			-- javascript = { "prettierd", "prettier", stop_after_first = true },
		},
	})
end)

-- nvim-lint
later(function()
	add({
		source = "mfussenegger/nvim-lint",
	})

	require("lint").linters_by_ft = {
		go = { "golangcilint" },
		rust = { "clippy" },
		sh = { "shellcheck" },
		markdown = { "markdownlint-cli2" },
		python = { "ruff" },
	}

	vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		callback = function()
			-- try_lint without arguments runs the linters defined in `linters_by_ft`
			-- for the current filetype
			require("lint").try_lint()

			-- You can call `try_lint` with a linter name or a list of names to always
			-- run specific linters, independent of the `linters_by_ft` configuration
			-- require("lint").try_lint("cspell")
		end,
	})
end)

-- markview.nvim
now(function()
	add({
		source = "OXY2DEV/markview.nvim",
	})

	require("markview").setup({
		preview = {
			icon_provider = "mini", -- "internal" or "devicons"
			filetypes = { "markdown", "codecompanion" },
			ignore_buftypes = {},
		},
	})
end)

-- csvview
later(function()
	add({
		source = "hat0uma/csvview.nvim",
	})

	require("csvview").setup()

	vim.api.nvim_create_autocmd("FileType", {
		pattern = "csv",
		callback = function()
			vim.cmd("CsvViewEnable")
		end,
	})
end)

------------------------------------------------------------------------------
-- DAP configuration
------------------------------------------------------------------------------

-- nvim-dap
later(function()
	add({
		source = "mfussenegger/nvim-dap",
	})

	vim.keymap.set("n", "<F1>", "<CMD>lua require('dap').step_into()<CR>", { desc = "Debug: Step Into" })
	vim.keymap.set("n", "<F2>", "<CMD>lua require('dap').step_over()<CR>", { desc = "Debug: Step Over" })
	vim.keymap.set("n", "<F3>", "<CMD>lua require('dap').step_out()<CR>", { desc = "Debug: Step Out" })
	vim.keymap.set("n", "<F5>", "<CMD>lua require('dap').continue()<CR>", { desc = "Debug: Start/Continue" })
	vim.keymap.set(
		"n",
		"<Leader>db",
		"<CMD>lua require('dap').toggle_breakpoint()<CR>",
		{ desc = "Debug: Toggle Breakpoint" }
	)
	vim.keymap.set(
		"n",
		"<Leader>dB",
		"<CMD>lua require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')<CR>",
		{ desc = "Debug: Set Breakpoint" }
	)
end)

-- nvim-dap-ui
later(function()
	add({
		source = "rcarriga/nvim-dap-ui",
		depends = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
	})

	require("dapui").setup({
		icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
		controls = {
			icons = {
				pause = "⏸",
				play = "▶",
				step_into = "⏎",
				step_over = "⏭",
				step_out = "⏮",
				step_back = "b",
				run_last = "▶▶",
				terminate = "⏹",
				disconnect = "⏏",
			},
		},
	})

	-- Change breakpoint icons
	vim.api.nvim_set_hl(0, "DapBreak", { fg = "#ec6867" })
	vim.api.nvim_set_hl(0, "DapStop", { fg = "#f1a251" })
	local breakpoint_icons = {
		Breakpoint = "●",
		BreakpointCondition = "⊜",
		BreakpointRejected = "⊘",
		LogPoint = "◆",
		Stopped = "⭔",
	}
	for type, icon in pairs(breakpoint_icons) do
		local tp = "Dap" .. type
		local hl = (type == "Stopped") and "DapStop" or "DapBreak"
		vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
	end

	local dap = require("dap")
	local dapui = require("dapui")
	dap.listeners.after.event_initialized["dapui_config"] = dapui.open
	dap.listeners.before.event_terminated["dapui_config"] = dapui.close
	dap.listeners.before.event_exited["dapui_config"] = dapui.close

	vim.keymap.set("n", "<F7>", "<CMD>lua require('dapui').toggle()<CR>", { desc = "Debug: See last session result." })
end)

-- nvim-dap-virtual-text
later(function()
	add({
		source = "theHamsta/nvim-dap-virtual-text",
		depends = { "mfussenegger/nvim-dap" },
	})
	require("nvim-dap-virtual-text").setup()
end)

-- nvim-dap-go
later(function()
	add({
		source = "leoluz/nvim-dap-go",
		depends = { "mfussenegger/nvim-dap" },
	})

	-- Install golang specific config
	-- require dlv on your PATH
	require("dap-go").setup({
		delve = {
			-- On Windows delve must be run attached or it crashes.
			-- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
			detached = vim.fn.has("win32") == 0,
		},
	})
end)

-- nvim-dap-lldb
later(function()
	add({
		source = "julianolf/nvim-dap-lldb",
		depends = { "mfussenegger/nvim-dap" },
	})

	-- HACK require codelldb manual installation
	require("dap-lldb").setup({
		codelldb_path = vim.fn.stdpath("data") .. "/codelldb/extension/adapter/codelldb",
	})
end)

------------------------------------------------------------------------------
-- AI assistant
------------------------------------------------------------------------------

-- CodeCompanion
later(function()
	add({
		source = "olimorris/codecompanion.nvim",
		depends = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
	})

	require("codecompanion").setup({
		adapters = {
			azure_openai = function()
				return require("codecompanion.adapters").extend("azure_openai", {
					schema = {
						model = {
							default = "gpt-4.1",
						},
					},
				})
			end,
		},
		strategies = {
			chat = {
				adapter = "azure_openai",
			},
			inline = {
				adapter = "azure_openai",
			},
			cmd = {
				adapter = "azure_openai",
			},
		},
	})
end)

-- Supermaven
-- later(function()
-- 	add({
-- 		source = "supermaven-inc/supermaven-nvim",
-- 	})
-- 	require("supermaven-nvim").setup({})
-- end)

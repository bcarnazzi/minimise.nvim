------------------------------------------------------------------------------
-- DAP configuration
------------------------------------------------------------------------------

local deps = require("mini.deps")
local add, now, later = deps.add, deps.now, deps.later

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
	-- NOTE Require dlv on your PATH
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

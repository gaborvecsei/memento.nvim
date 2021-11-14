local List = require("memento.list")
local Ui = require("memento.ui")
local Path = require("plenary.path")
local vim = vim

local M = {}

-- This is where we store the history
local CachePath = Path:new(string.format("%s/memento.json", vim.fn.stdpath("data")))

local function create_data()
    return List.new(vim.g.memento_history)
end

-- History data is stored here
local DataList = create_data()

local function get_current_buffer_info()
    -- https://vi.stackexchange.com/a/34983/38739 - this is why vim.fn.expand("%:p") is not good
    local path_to_file = vim.fn.expand("<afile>:p")
    local cursor_info = vim.api.nvim_win_get_cursor(0)
    return {path = path_to_file, line = cursor_info[1], character = cursor_info[2]}
end

-- Add an entry to the list with the given predefined format
local function add_item_to_list(path, line_number, char_number)
    local data_table = {path = path, line_number = line_number, char_number = char_number, date = os.date("*t")}
    List.add(DataList, data_table)
end

function M.toggle()
    Ui.close_window()
    local popup_info = Ui.create_popup(DataList, vim.g.memento_window_width, vim.g.memento_window_height)

    -- Keymappings for the opened popup window
    vim.api.nvim_buf_set_keymap(
        popup_info.buffer,
        "n",
        "q",
        ":lua require('memento').toggle()<CR>",
        { silent = true }
    )
    vim.api.nvim_buf_set_keymap(
        popup_info.buffer,
        "n",
        "<CR>",
        ":lua require('memento').open_selected()<CR>",
        { silent = true }
    )
end

function M.store_position()
    -- Record file path, line number and char position, then write to a file and save the file
    local info = get_current_buffer_info()
    if (info.path ~= nil and info.path ~= "" and Path:new(info.path):exists()) then
        add_item_to_list(info.path, info.line, info.character)
        M.save()
    end
end

function M.open_selected()
    local line_number, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local selected_item = DataList.list[line_number]
    Ui.close_window()
    vim.api.nvim_command(string.format("e %s", selected_item.path))
    vim.api.nvim_command(string.format(":%d", selected_item.line_number))
end

function M.save()
    CachePath:write(List.to_json(DataList), "w")
end

function M.load()
    List.from_json(DataList, CachePath:read())
end

function M.clear_history()
    DataList = create_data()
    -- We just overwrite the file with an empty table
    M.save()
end

function M.setup(opts)
    local function set_default(opt, default)
        local prefix = "memento_"
		if vim.g[prefix .. opt] ~= nil then
			return
		elseif opts[opt] ~= nil then
			vim.g[prefix .. opt] = opts[opt]
		else
			vim.g[prefix .. opt] = default
		end
	end

    set_default("history", 20)
    set_default("shorten_path", true)
    set_default("window_width", 80)
    set_default("window_height", 14)
end

M.setup({})

return M


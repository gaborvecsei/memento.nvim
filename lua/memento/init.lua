local List = require("memento.list")
local Path = require("plenary.path")
local popup = require("plenary.popup")

local M = {}

-- Popup window (buffer and window id)
local Buf = nil
local Win = nil

-- This is where we store the history
local cache_path = Path:new(string.format("%s/memento.json", vim.fn.stdpath("data")))

local function create_data()
    return List.new(vim.g.memento_history)
end

-- History data is stored here
local Data = create_data()

local function get_current_buffer_info()
    -- https://vi.stackexchange.com/a/34983/38739 - this is why vim.fn.expand("%:p") is not good
    local path_to_file = vim.fn.expand("<afile>:p")
    local cursor_info = vim.api.nvim_win_get_cursor(0)
    return {path = path_to_file, line = cursor_info[1], character = cursor_info[2]}
end

local function add_item_to_list(path, line_number, char_number)
    -- Add an entry to the list with the given predefined format

    local data_table = {path = path, line_number = line_number, char_number = char_number, date = os.date("*t")}
    List.add(Data, data_table)
end

local function create_window(width, height)
    -- Creates a popup window where we will show the prices

    width = width or 80
    height = height or 12
    local borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }
    local bufnr = vim.api.nvim_create_buf(false, false)

    local win_id, win = popup.create(bufnr, {
        title = "Memento - recent buffers",
        highlight = "MementoWindow",
        line = math.floor(((vim.o.lines - height) / 2) - 1),
        col = math.floor((vim.o.columns - width) / 2),
        minwidth = width,
        minheight = height,
        borderchars = borderchars
    })

    vim.api.nvim_win_set_option(win.border.win_id, "winhl", "Normal:MementoBorder")

    return {bufnr = bufnr, win_id = win_id}
end

local function close_window()
    -- Close the popup window

    vim.api.nvim_win_close(Win, true)
    Win = nil
    Buf = nil
end

local function create_popup_content()
    local contents = {}
    for i, x in ipairs(Data.list) do
        local path = x.path
        if vim.g.memento_shorten_path then
            path = Path:new(path):shorten(1)
        end
        local date_str = string.format("%d/%d %d:%d", x.date.month, x.date.day, x.date.hour, x.date.min)
        contents[#contents+1] = string.format("%s, %s, %d", date_str, path, x.line_number)
    end
    return contents
end

function M.toggle()
    if Win ~= nil and vim.api.nvim_win_is_valid(Win) then
        -- If the window already exists, then close it
        close_window()
        return
    end

    -- Create the window, and assign the global variables, so we can use later
    local win_info = create_window(vim.g.memento_window_width, vim.g.memento_window_height)
    Win = win_info.win_id
    Buf = win_info.bufnr

    vim.api.nvim_buf_set_name(Buf, "memento-menu")
    local contents = create_popup_content(Data)
    vim.api.nvim_buf_set_lines(Buf, 0, #contents, false, contents)
    vim.api.nvim_buf_set_option(Buf, "filetype", "memento")
    vim.api.nvim_buf_set_option(Buf, "buftype", "acwrite")
    vim.api.nvim_buf_set_option(Buf, "bufhidden", "delete")
    vim.api.nvim_buf_set_option(Buf, "modifiable", false)
    if #contents > 0 then
        vim.api.nvim_win_set_cursor(0, {#contents, 0})
    end

    -- Keymappings for the opened window
    vim.api.nvim_buf_set_keymap(
        Buf,
        "n",
        "q",
        ":lua require('memento').toggle()<CR>",
        { silent = true }
    )
    vim.api.nvim_buf_set_keymap(
        Buf,
        "n",
        "o",
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
    local line_number, char_number = unpack(vim.api.nvim_win_get_cursor(0))
    local selected_item = Data.list[line_number]
    M.toggle()
    vim.api.nvim_command(string.format("e %s", selected_item.path))
    -- TODO: can't we include the "line jump" in the edit command?
    vim.api.nvim_command(string.format(":%d", selected_item.line_number))
end

function M.save()
    cache_path:write(List.to_json(Data), "w")
end

function M.load()
    List.from_json(Data, cache_path:read())
end

function M.clear_history()
    Data = create_data()
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


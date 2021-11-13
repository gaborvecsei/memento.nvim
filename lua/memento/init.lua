local List = require("memento.list")
local Path = require("plenary.path")
local popup = require("plenary.popup")

local M = {}

-- Popup window
Buf = nil
Win = nil

local cache_path = Path:new(string.format("%s/memento.json", vim.fn.stdpath("data")))

local function create_data()
    -- TODO: make the max number of items configurable
    return List.new(10)
end

Data = create_data()

local function get_current_buffer_info()
    local path_to_file = vim.fn.expand("%:p")
    local cursor_info = vim.api.nvim_win_get_cursor(0)
    return {path = path_to_file, line = cursor_info[1], character = cursor_info[2]}
end

local function add_item_to_list(path, line_number, char_number)
    -- Add an entry to the list with the given predefined format
    local data_table = {path = path, line_number = line_number, char_number = char_number, date = os.date("%c")}
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
        borderchars = borderchars,
    })

    vim.api.nvim_win_set_option(
        win.border.win_id,
        "winhl",
        "Normal:MementoBorder"
    )

    return {
        bufnr = bufnr,
        win_id = win_id,
    }
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
        -- TODO: check if it is more then the popup window width, and shorten the path until it fits
        contents[#contents+1] = string.format("%d: %s, %s, %d", i, x.date, x.path, x.line_number)
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
    local win_info = create_window()
    Win = win_info.win_id
    Buf = win_info.bufnr

    vim.api.nvim_buf_set_name(Buf, "memento-menu")
    local contents = create_popup_content(Data)
    vim.api.nvim_buf_set_lines(Buf, 0, #contents, false, contents)
    vim.api.nvim_buf_set_option(Buf, "filetype", "memento")
    vim.api.nvim_buf_set_option(Buf, "buftype", "acwrite")
    vim.api.nvim_buf_set_option(Buf, "bufhidden", "delete")

    -- Keymappings for the opened window
    vim.api.nvim_buf_set_keymap(
        Buf,
        "n",
        "q",
        ":lua require('memento').toggle()<CR>",
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

function M.save()
    cache_path:write(List.to_json(Data), "w")
end

function M.load()
    -- TODO: immutable or mutable (should I return with the modified object itself?
    Data = List.from_json(Data, cache_path:read())
end

function M.debug_show()
    for i, x in ipairs(Data.list) do
        print(i, x.date, x.path, x.line_number, x.char_number)
    end
end

function M.debug_clear()
    Data = create_data()
    -- We just overwrite the file with an empty table
    M.save()
end
    
function M.setup()
    -- When deleting a buffer, record the infos
    vim.api.nvim_exec(
        [[
        augroup AutoMementoGroup
            autocmd!
            autocmd BufUnload * lua require("memento").store_position()
            autocmd VimEnter * lua require("memento").load()
            autocmd ExitPre * lua require("memento").save()
        augroup END
        ]], false)
end

return M


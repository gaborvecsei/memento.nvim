local popup = require("plenary.popup")
local Path = require("plenary.path")
local vim = vim

local M = {}

-- Popup window (buffer and window id)
local PopupBuffer = nil
local PopupWindow = nil

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

local function create_content(data_list, shorten_path)
    local contents = {}
    for _, x in ipairs(data_list.list) do
        local path = x.path
        if shorten_path then
            path = Path:new(path):shorten(1)
        end
        local date_str = string.format("%d/%d %d:%d", x.date.month, x.date.day, x.date.hour, x.date.min)
        contents[#contents+1] = string.format("%s, %s, %d", date_str, path, x.line_number)
    end
    return contents
end

local function set_popup_contents(contents)
    vim.api.nvim_buf_set_name(PopupBuffer, "memento-menu")
    vim.api.nvim_buf_set_lines(PopupBuffer, 0, #contents, false, contents)
    vim.api.nvim_buf_set_option(PopupBuffer, "filetype", "memento")
    vim.api.nvim_buf_set_option(PopupBuffer, "buftype", "acwrite")
    vim.api.nvim_buf_set_option(PopupBuffer, "bufhidden", "delete")
    vim.api.nvim_buf_set_option(PopupBuffer, "modifiable", false)
    if #contents > 0 then
        vim.api.nvim_win_set_cursor(0, {#contents, 0})
    end
end

function M.create_popup(data_list, width, height, shorten_path)
    -- Create a new popup window, and fill buffer with contents

    local popup_info = create_window(width, height)
    PopupWindow = popup_info.win_id
    PopupBuffer = popup_info.bufnr

    local contents = create_content(data_list, shorten_path)
    set_popup_contents(contents)

    return {window = PopupWindow, buffer = PopupBuffer}
end

function M.close_window()
    -- Close the popup window if it is opened

    if PopupWindow ~= nil and vim.api.nvim_win_is_valid(PopupWindow) then
        vim.api.nvim_win_close(PopupWindow, true)
        PopupWindow = nil
        PopupBuffer = nil
        return true
    end
    return false
end

return M
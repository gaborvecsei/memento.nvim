local List = require("memento.list")
local Path = require("plenary.path")

local M = {}

local cache_path = Path:new(string.format("%s/memento.json", vim.fn.stdpath("data")))

local function create_data()
    -- TODO: make the max number of items configurable
    return List.new(10)
end

local data = create_data()

local function get_current_buffer_info()
    local path_to_file = vim.fn.expand('%:p')
    local cursor_info = vim.api.nvim_win_get_cursor(0)
    return {path = path_to_file, line = cursor_info[1], character = cursor_info[2]}
end

local function add_item_to_list(path, line_number, char_number)
    -- Add an entry to the list with the given predefined format
    local data_table = {path = path, line_number = line_number, char_number = char_number}
    List.add(data, data_table)
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
    cache_path:write(List.to_json(data), "w")
end

function M.load()
    -- TODO: immutable or mutable (should I return with the modified object itself?
    data = List.from_json(data, cache_path:read())
end

function M.debug_show()
    for i, x in ipairs(data.list) do
        print(i, x.path, x.line_number, x.char_number)
    end
end

function M.debug_clear()
    data = create_data()
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


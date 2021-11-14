local vim = vim

local M = {}

--[[
    Dummy FIFO list (queue) implementation
    Operations:
        - new(): creates a new list
        - add(): adds a new element to a list
        - to_json(): serializes the contents (not the object) of the list to a json string
        - from_json(): deserialize contents (not the object) from a json string

    E.g.:
    local my_list = M.new(5)
    for i=1,10 do M.add(my_list, i) end
    -- my_list.data --> is [6, 7, 8, 9, 10]
--]]

-- Constructor
-- @param max: maximum number of items in the list
-- @param data: list of items
function M.new(max_nb_items)
    max_nb_items = max_nb_items or 10
    return {max_nb_items = max_nb_items, data = {}}
end

-- TODO: rename 'obj'

-- Add a new item to the list with respect to the maximum list size
function M.add(obj, item)

    if #obj.data >= obj.max_nb_items then
        -- Remove the first (oldest) item
        table.remove(obj.data, 1)
    end

    -- Add new item to the end of the list
    table.insert(obj.data, #obj.data+1, item)
end

function M.to_json(obj)
    return vim.fn.json_encode(obj.data)
end

function M.from_json(obj, json)
   local data = vim.fn.json_decode(json)
   -- If there are more lines in the file then what is defined as max, remove 'unnecessary' lines
   if #data > obj.max_nb_items then
       for _=1,#data-obj.max_nb_items do
           table.remove(data, 1)
       end
   end

   obj.data = data
   return obj
end

return M

local vim = vim

local M = {}

function M.new(max_nb_items)
    -- Constructor
    -- max: maximum number of items in the list
    -- data: list of items

    max_nb_items = max_nb_items or 10
    return {max_nb_items = max_nb_items, data = {}}
end

-- TODO: rename 'obj'

function M.add(obj, item)
    -- Add a new item to the list with respect to the maximum list size

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
   -- If there is more in the file then what is defined as max, remove 'unnecessary' lines
   if #data > obj.max_nb_items then
       for _=1,#data-obj.max_nb_items do
           table.remove(data, 1)
       end
   end

   obj.data = data
   return obj
end

----------------------------------
-- This is just a random test
-- local asd = M.new(5)
--
-- for i=1,10 do
--     M.add(asd, i)
-- end
--
-- print("------")
--
-- for k, v in ipairs(asd.data) do
--     print(k, v)
-- end
--
----------------------------------

return M

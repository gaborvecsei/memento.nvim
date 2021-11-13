local M = {}

function M.new(max)
    -- Constructor
    -- max: maximum number of items in the list
    -- list: list of items

    max = max or 10
    return {max = max, list = {}}
end

-- TODO: rename 'obj'

function M.add(obj, item)
    -- Add a new item to the list with respect to the maximum list size
 
    if #obj.list >= obj.max then
        -- Remove the first (oldest) item
        table.remove(obj.list, 1)
    end

    -- Add new item to the end of the list
    table.insert(obj.list, #obj.list+1, item)
end

function M.to_json(obj)
    return vim.fn.json_encode(obj.list)
end

function M.from_json(obj, json)
   local data = vim.fn.json_decode(json)
   -- If there is more in the file then what is defined as max, remove 'unnecessary' lines
   if #data > obj.max then
       for i=1,#data-max do
           table.remove(data, 1)
       end
   end

   obj.list = data
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
-- for k, v in ipairs(asd.list) do
--     print(k, v)
-- end
--
----------------------------------

return M

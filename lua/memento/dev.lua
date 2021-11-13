local M = {}

function M.reload()
	require("plenary.reload").reload_module("memento")
end

return M

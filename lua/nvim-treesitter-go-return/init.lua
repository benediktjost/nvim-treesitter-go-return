local ts_utils = require("nvim-treesitter.ts_utils")
local M = {}

local parseToken = function(token)
	local buildIn = {}
	buildIn["string"] = '""'
	buildIn["int"] = "0"
	buildIn["float"] = "0"
	-- TODO (byte), int16, uint16, int32 (rune), uint32, int64, uint64, int, uint, uintptr. float32, float64. complex64, complex128.

	if string.starts(token, "*") then
		return "nil, "
	end
	if buildIn[token] then
		return buildIn[token] .. ", "
	end
	if token == "error" then
		return "err"
	end
	return token .. "{},"
end

function string.starts(String, Start)
	return string.sub(String, 1, string.len(Start)) == Start
end

M.getReturnTypes = function()
	local expr = ts_utils.get_node_at_cursor()

	while expr do
		if expr:type() == "method_declaration" or expr:type() == "function_declaration" then
			break
		end
		expr = expr:parent()
	end

	if not expr then
		print("no function or method found")
	end

	local resultNode = nil
	for node, field in expr:iter_children() do
		if field == "result" then
			resultNode = node
		end
	end

	if not resultNode then
		print("no result node found")
	end

	local result_types = {}
	for node in resultNode:iter_children() do
		if node:type() == "parameter_declaration" then
			if node:named_child_count() == 1 then
				table.insert(result_types, ts_utils.get_node_text(node:named_child())[1])
			else
				for _ = 1, node:named_child_count() - 1, 1 do
					table.insert(
						result_types,
						ts_utils.get_node_text(node:named_child(node:named_child_count() - 1))[1]
					)
				end
			end
		end
	end
	return result_types
end

M.getResultString = function()
	local res = "return "
	for _, val in pairs(M.getReturnTypes()) do
		res = res .. parseToken(val)
	end
	return tostring(res)
end

return M

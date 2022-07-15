local ts_utils = require("nvim-treesitter.ts_utils")

local M = {}

M._buildIn = {}
M._nilReturn = true
M._buildIn = {
	bool = "false",
	string = '""',
	int16 = "0",
	uint16 = "0",
	uint32 = "0",
	uint64 = "0",
	int64 = "0",
	int = "0",
	uint = "0",
	unitptr = "0",
	float = "0",
	float32 = "0",
	float64 = "0",
	complex64 = "0",
	complex128 = "0",
}

local parseToken = function(token, skipError)
	local buildIn = M._buildIn
	if string.starts(token, "*") or string.starts(token, "[]") then
		if M._nilReturn then
			return "nil"
		end
		return "&" .. buildIn[token] .. {}
	end
	if
		string.starts(token, "map[")
		or string.starts(token, "func")
		or string.starts(token, "chan")
		or string.starts(token, "interface")
	then
		return "nil"
	end
	if buildIn[token] then
		return buildIn[token]
	end
	if token == "error" then
		if not skipError then
			return "err"
		end
		return nil
	end
	return token .. "{}"
end

function string.starts(String, Start)
	return string.sub(String, 1, string.len(Start)) == Start
end

M.setup = function(opts)
	for x in pairs(opts.buildIn) do
		if M._buildIn[x] then
			M._buildIn[x] = opts.buildIn[x]
		end
	end
	if opts.useNil then
		M._nilReturn = opts.useNil
	end
end

M.getReturnValues = function(skipError)
	local res = {}
	for _, val in pairs(M.getReturnTypes()) do
		local parsed = parseToken(val, skipError)
		if parsed then
			table.insert(res, parsed)
		end
	end
	return res
end

M.getReturnTypes = function()
	-- get the node at the cursor
	local expr = ts_utils.get_node_at_cursor()

	-- find the method or function node
	while expr do
		if expr:type() == "method_declaration" or expr:type() == "function_declaration" then
			break
		end
		expr = expr:parent()
	end

	if not expr then
		print("no function or method found")
	end

	-- find the result node
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
	-- loop over all parameter_declaration
	for node in resultNode:iter_children() do
		if node:type() == "parameter_declaration" then
			-- in case of an unnamed return
			if node:named_child_count() == 1 then
				table.insert(result_types, ts_utils.get_node_text(node:named_child())[1])
			else
				-- in case of namend returns
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

return M

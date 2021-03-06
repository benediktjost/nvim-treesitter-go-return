# nvim-treesitter-go-return
This plugin uses treesitter to determine the return types of a go function.
It can be used to create snippets for auto filling the go if err!=nil pattern.
![Alt Text](return.gif)

Inspired by [TJDeVries](https://github.com/tjdevries) video on [luasnip](https://www.youtube.com/watch?v=Dn800rlPIho).
## Usage with luasnip:

```
local ls = require("luasnip")
local snip = ls.snippet
local text = ls.text_node
local func = ls.function_node
local input = ls.insert_node

local returnString = function()
	local res = " return "
	require("nvim-treesitter-go-return").setup({ buildIn = { string = "foo" }, useNil = false })
	local values = require("nvim-treesitter-go-return").getReturnValues(true)
	for _, val in pairs(values) do
		res = res .. val
		if val ~= "err" then
			res = res .. ", "
		end
	end
	return { res }
end

ls.add_snippets(nil, {
	all = {
		snip({
			trig = "ie",
		}, {
			text({ "if " }),
			input(1, "err"),
			text({ " != nil {" }),
			text({ " ", " " }),
			func(returnString, {}),
			func(function(args, _, user_arg_1)
				return args [1] [1] .. user_arg_1
			end, { 1 }, { user_args = { "" } }),
			text({ " ", "}", "" }),
		}),
	},
})
```

## Installation

Use your favorite package manager to install the plugin.


## Configuration

Setup function to be run by user. Configures the default return values of the build in golang types via the buildIn table.
If useNil is set to true nil is returned for pointer and slices otherwise pointer of the default values are returned.
Maps, functions an interfaces are always returned as nil.

The defaults are:
```
require("nvim-treesitter-go-return").setup({
	buildIn = {
		bool = '"false"',
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
	},
	useNil = true,
}

```


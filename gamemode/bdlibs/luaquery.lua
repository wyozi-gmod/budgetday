-- SQL Like syntax for querying data from tables

module("luaquery", package.seeall)

local meta = {}

function Select(...)
	local tbl = {
		keys = {...},
		data_history = {}
	}
	setmetatable(tbl, {__index = meta})

	return tbl
end

function meta:get_current_data()
	return self.data_history[#self.data_history]
end

function meta:from(sourcetbl)
	table.insert(self.data_history, sourcetbl)
end

function meta:where(condition)
	local data = self:get_current_data()
	table.insert(self.data_history, sourcetbl)
end
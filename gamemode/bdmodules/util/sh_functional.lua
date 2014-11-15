--- Functions to make working with tables easier
local MODULE = bd.module("util")

-- Transform each value in table to fn(value)
function MODULE.Map(tbl, fn)
	local t = {}
	for k,v in pairs(tbl) do
		t[k] = fn(v, k)
	end
	return t
end

-- Filter for sequential tables
function MODULE.FilterSeq(tbl, fn)
	local t = {}
	for k,v in pairs(tbl) do
		if fn(v, k) then t[#t+1] = v end
	end
	return t
end

-- Group table values into groups
function MODULE.Group(tbl, fn)
	local t = {}
	for k,v in pairs(tbl) do
		local group = fn(v, k)

		t[group] = t[group] or {}
		table.insert(t[group], v)
	end
	return t
end
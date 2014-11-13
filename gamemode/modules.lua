-- Support functions for creating bdmodules

function bd.module(modulename, docs)
	bd[modulename] = bd[modulename] or {}
	
	bd[modulename].__docs = docs

	return bd[modulename]
end
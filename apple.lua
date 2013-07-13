require "iSAC"

local items = iTems()
local Summoners = iSummoners()

function OnLoad()
	items:add("DFG", 3128)
end

function OnTick()
	Summoners:AutoAll()
end

--[[ Produces: 
line634: bad argument #1 to 'pairs' table expected go nil -> since you said it's optional :s
and if you take heal and autoall: line 526 attempt to get length of field '?' a nil value
Added to this it would be cool if you could return the whole minion object like

local Minions = iMinions(range, [includeAD])

function iMinions:GetObject()
	return _enemyMinions
end

Minions:GetObject()
--]]
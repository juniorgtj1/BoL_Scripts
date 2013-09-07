--[[ Shows the enemy range; Fix by Trus ]]--

function OnLoad()
	Config = scriptConfig("Enemy Range","EnemyRange")
	Config:addParam("drawAllys", "Draw Allys", SCRIPT_PARAM_ONOFF, true)

	print("Enemy Range loaded")
end

function OnDraw()
	for i, unit in pairs(GetEnemyHeroes()) do
		if myHero.range + 500 >= GetDistance(unit) and not unit.dead then
			DrawCircle(unit.x, unit.y, unit.z, unit.range + GetDistance(unit.minBBox, unit.maxBBox),  0xFFFFFF00)
		end
	end

	if not Config.drawAllys then return end

	for i, unit in pairs(GetAllyHeroes()) do
		if myHero.range + 500 >= GetDistance(unit) and not unit.dead then
			DrawCircle(unit.x, unit.y, unit.z, unit.range + GetDistance(unit.minBBox, unit.maxBBox),  0xFFFFFF00)
		end
	end
end
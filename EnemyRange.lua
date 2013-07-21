--[[ Shows the enemy range ]]--

local champs = {
	{name = "Ashe", range = 600},
	{name = "Caitlyn", range = 650},
	{name = "Corki", range = 550},
	{name = "Draven", range = 550},
	{name = "Ezrael", range = 550},
	{name = "Graves", range = 525},
	{name = "KogMaw", range = 500},
	{name = "MissFortune", range = 550},
	{name = "Sivir", range = 500},
	{name = "Tristana", range = 550},
	{name = "Twitch", range = 550},
	{name = "Varus", range = 575},
	{name = "Vayne", range = 550}
}

function OnLoad()
	Config = scriptConfig("Enemy Range","EnemyRange")
	Config:addParam("drawAllies", "Draw Allies", SCRIPT_PARAM_ONOFF, true)

	print("Enemy Range loaded")
end

function OnDraw()
	for i=1, heroManager.iCount do
		local Unit = heroManager:GetHero(i)
		for _,champ in pairs(champs) do
			if champ.name == Unit.charName then
				if Unit.team == myHero.team and not Config.drawAllies then return true end
				if champ.name == "Tristana" then
					DrawCircle(Unit.x, Unit.y, Unit.z, ((champ.range+Unit.level*9)-9),  0xFFFFFF00)
				else
					DrawCircle(Unit.x, Unit.y, Unit.z, champ.range, 0xFFFFFF00)
				end
			end
		end
	end
end
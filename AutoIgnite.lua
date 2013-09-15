local IGNITESlot = nil
local IGNITEReady = false

function OnLoad()
IGNITESlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
end

function OnTick()
IGNITEReady = (IGNITESlot ~= nil and myHero:CanUseSpell(IGNITESlot) == READY)
AutoIgnite()
end

function AutoIgnite()
	if not IGNITEReady then return end

	for _, enemy in pairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, 600) then
			if getDmg("IGNITE", enemy, myHero) >= enemy.health then
				CastSpell(IGNITESlot, enemy)
			end
		end
	end
end
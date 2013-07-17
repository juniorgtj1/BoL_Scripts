--[[ Simple Garen Plugin ]]--

local SpellRangeR = 400
local RReady, EReady, IGNITEReady, BARRIERReady = nil, nil, nil, nil

function PluginOnLoad()
	AutoCarry.PluginMenu:addParam("aR", "Use Ulti", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("aE", "Use E after Q", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("aIGN", "Use Ignite", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("aB", "Use Barrier", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("lr", "Barrier Life Ratio", SCRIPT_PARAM_SLICE, 0.15, 0, 1, 2)

	IGNITESlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
	BARRIERSlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerBarrier") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerBarrier") and SUMMONER_2) or nil)
end

function PluginOnTick()
	CooldownHandler()
	if AutoCarry.PluginMenu.aB then AutoBarrier() end
	if AutoCarry.PluginMenu.aR then CastR() end
	if AutoCarry.PluginMenu.aIGN then AutoIgnite() end
end

function PluginOnProcessSpell(unit, spell)
   if unit.isMe and spell.name == myHero:GetSpellData(_Q).name then
      if AutoCarry.PluginMenu.aE and EReady then CastSpell(_E) end
   end
end

function CastR()
	if not RReady then return true end

	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if ValidTarget(enemy, SpellRangeR) and GetDmg(_R, enemy, myHero) >= enemy.health then CastSpell(_R, enemy) end
	end
end

function AutoBarrier()
	if myHero.health/myHero.maxHealth < AutoCarry.PluginMenu.lr and BARRIERReady then CastSpell(BARRIERSlot) end
end

function AutoIgnite()
	if not IGNITEReady then return true end

	local IGNITEDamage = 0
	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if ValidTarget(enemy, 600) then
			IGNITEDamage = 50 + 20 * myHero.level
			if IGNITEDamage >= enemy.health then
				CastSpell(IGNITESlot, enemy)
			end
		end
	end
end

function CooldownHandler()
	RReady = (myHero:CanUseSpell(_R) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	IGNITEReady = (IGNITESlot ~= nil and myHero:CanUseSpell(IGNITESlot) == READY)
	BARRIERReady = (BARRIERSlot ~= nil and myHero:CanUseSpell(BARRIERSlot) == READY)
end
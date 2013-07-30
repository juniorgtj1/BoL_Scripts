--[[ Simple AutoCarry Plugin for Tristana ]]--

local SkillW = {spellKey = _W, range = 900, speed = 1500, delay = 250, width = 200}
local RangeR = myHero:GetSpellData(_R).range

function PluginOnLoad()
	AutoCarry.PluginMenu:addParam("ksW", "Killsteal - Rocket Jump", SCRIPT_PARAM_ONOFF, true)     
	AutoCarry.PluginMenu:addParam("ksR", "Killsteal - Buster Shot", SCRIPT_PARAM_ONOFF, true) 
	AutoCarry.PluginMenu:addParam("eJL", "Enemys Jump Limit", SCRIPT_PARAM_SLICE, 2, 1, 5, 0)
end

function PluginOnTick()
	if AutoCarry.PluginMenu.ksR then KSR() end
	if AutoCarry.PluginMenu.ksW then KSW() end
end

function KSR()
	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if ValidTarget(enemy, RangeR) and getDmg("R", enemy, myHero) >= enemy.health then
			CastSpell(_R, enemy)
		end
	end
end

function KSW()
	local EnemysInRange = CountEnemyHeroInRange()
	for _, enemy in pairs(AutoCarry.EnemyTable) do
		PossibleDmg = getDmg("W", enemy, myHero)
		if ValidTarget(enemy, SkillW.range) and EnemysInRange <= AutoCarry.PluginMenu.eJL and (PossibleDmg >= enemy.health or PossibleDmg >= (enemy.health + (enemy.maxHealth/100*5))) then
			AutoCarry.CastSkillshot(SkillW, enemy)
		end
	end
end
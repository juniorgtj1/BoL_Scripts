local HK1 = string.byte("Y")
local HK2 = string.byte("N")

local SkillQ = { spellKey = _Q, range = 1000, speed = 1.33, delay = 250, width = 120, configName = "boomerangBlade", displayName = "Q (Boomerang Blade)", enabled = true, skillShot = true, minions = false, reset = false, reqTarget = true }

local QReady, WReady = nil, nil

function PluginOnLoad()
	AutoCarry.PluginMenu:addParam("comboQ", "Q in Combo", SCRIPT_PARAM_ONKEYTOGGLE, false, HK1)
	AutoCarry.PluginMenu:addParam("lcW", "W while lane clear", SCRIPT_PARAM_ONKEYTOGGLE, false, HK2)
	AutoCarry.PluginMenu:addParam("lcQ", "Q while lane clear", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("ksQ", "KS with Q", SCRIPT_PARAM_ONOFF, true)
end

function PluginOnTick()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	if AutoCarry.PluginMenu.ksQ and QReady then KSQ() end
	if AutoCarry.MainMenu.AutoCarry and WReady then ComboW() end
	if AutoCarry.PluginMenu.comboQ and QReady and AutoCarry.MainMenu.AutoCarry then ComboQ() end
	if AutoCarry.PluginMenu.lcW and WReady and AutoCarry.MainMenu.LaneClear then LaneClearW() end
	if AutoCarry.PluginMenu.lcQ and QReady and AutoCarry.MainMenu.LaneClear then LaneClearQ() end
end

function OnAttacked()
	if WReady and (AutoCarry.PluginMenu.LaneClear or AutoCarry.MainMenu.AutoCarry) then
		CastSpell(_W)
	end
end

function KSQ()
	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if ValidTarget(enemy, SkillQ.range) and getDmg("Q", enemy, myHero) >= enemy.health then
			AutoCarry.CastSkillshot(SkillQ, enemy)
		end
	end
end

function ComboQ()
	local target = AutoCarry.GetAttackTarget()

	CastSkillshot(SkillQ, target)
end

function LaneClearQ()
	for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
		if ValidTarget(minion, SkillQ.range) then
			AutoCarry.CastSkillshot(SkillQ, minion)
		end
	end
end
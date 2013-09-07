local QReady, WReady, EReady, RReady
local QRange, WRange, ADRange, ERange

function PluginOnLoad()
	AutoCarry.PluginMenu:addParam("lhQ", "Last hit with Q", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("comboR", "Use R in Combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:permaShow("lhQ")

	QReady, WReady, EReady, RReady = false, false, false, false
	QRange = myHero:GetSpellData(_Q).range
	WRange = myHero:GetSpellData(_W).range
	ADRange = myHero.range + GetDistance(myHero.minBBox)
	ERange = myHero:GetSpellData(_E).range

	AutoCarry.SkillsCrosshair.range = WRange
end

function PluginOnTick()
	CDHandler()
	if AutoCarry.MainMenu.AutoCarry then Combo() end
	if AutoCarry.MainMenu.LastHit or AutoCarry.MainMenu.MixedMode or AutoCarry.MainMenu.LaneClear and AutoCarry.PluginMenu.lhQ then Farm() end
end

function Farm()
	if not QReady then return end

	if AutoCarry.GetKillableMinion() then
		CastSpell(_Q)
	end

	for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
		if ValidTarget(minion, QRange) and getDmg("Q", minion, myHero) >= minion.health and (not AutoCarry.GetKillableMinion() or AutoCarry.GetKillableMinion().networkID ~= minion.networkID) then
			CastSpell(_Q)
			myHero:Attack(minion)
		end
	end
end

function Combo()
	local Target = AutoCarry.GetAttackTarget(true)
	local BonusRange = 0

	if TargetHaveBuff("GodOfDeath", myHero) then
		BonusRange = 100
	end

	if ValidTarget(Target) then
		local Distance = myHero:GetDistance(Target)
		local EnemysInRange = CountEnemyHeroInRange(WRange)

		if EnemysInRange >= 2 and AutoCarry.PluginMenu.comboR and RReady then
			CastSpell(_R)
		end
		if ADRange + BonusRange/2 >= Distance and QReady then
			CastSpell(_Q)
		end
		if WRange + BonusRange >= Distance and WReady then
			CastSpell(_W, Target)
		end
		if ERange + BonusRange >= Distance and EReady then
			CastSpell(_E, Target.x, Target.z)
		end
	end
end

function CDHandler() 
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
end
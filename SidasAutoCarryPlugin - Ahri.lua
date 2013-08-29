local SkillQ = {spellKey = _Q, range = 880, speed = 1.1, delay = 500, width = 100}
local SkillE = {spellKey = _E, range = 975, speed = 1.2, delay = 500, width = 60}
local RangeW, RangeR = 750, 800
local EnemyTable
local HK1 = string.byte("L")

function PluginOnLoad()
	AutoCarry.PluginMenu:addParam("harassQ", "Harass with Q", SCRIPT_PARAM_ONKEYTOGGLE, true, HK1)
	AutoCarry.PluginMenu:permaShow("harassQ")

	EnemyTable = AutoCarry.EnemyTable
	AutoCarry.SkillsCrosshair.range = SkillE.range
end

function PluginOnTick()
	CDHandler()
	if AutoCarry.MainMenu.AutoCarry then Combo() end
	if AutoCarry.MainMenu.MixedMode and AutoCarry.PluginMenu.harassQ then Harass() end
end

function CDHandler()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
end

function Combo()
	local Target = AutoCarry.GetAttackTarget(true)

	if ValidTarget(Target) then
		local Distance = myHero:GetDistance(Target)

		if EReady and SkillE.range >= Distance and not AutoCarry.GetCollision(SkillE, myHero, Target) then
			AutoCarry.CastSkillshot(SkillE, Target)
		end

		if QReady and SkillQ.range >= Distance then
			AutoCarry.CastSkillshot(SkillQ, Target)
		end

		if WReady and RangeW >= Distance then
			CastSpell(_W)
		end

		if RReady and RangeR >= Distance then
			CastSpell(_R, Target.x, Target.z)
		end
	end
end

function Harass()
	local Target = AutoCarry.GetAttackTarget(true)
	local Mana = myHero:GetSpellData(_Q).mana*2 + myHero:GetSpellData(_W).mana + myHero:GetSpellData(_E).mana

	if QReady and ValidTarget(Target, SkillQ.range) and myHero.mana >= Mana then
		AutoCarry.CastSkillshot(SkillQ, Target)
	end
end
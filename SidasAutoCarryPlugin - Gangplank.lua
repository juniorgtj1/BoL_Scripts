local QReady, WReady, EReady, RReady
local RangeQ, RangeR = 625, 300
local EnemyTable
local AllyTable

function PluginOnLoad()
	AutoCarry.PluginMenu:addParam("farmQ", "Farm with Q", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("ksQ", "KS with Q", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useWcc", "Use W against CC/Blind", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("useWlhp", "Use W on low HP", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("Wlr", "W Life Ratio", SCRIPT_PARAM_SLICE, 0.1, 0, 1, 2)
	AutoCarry.PluginMenu:addParam("harassQ", "Harass with Q", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("harassE", "Harass with E", SCRIPT_PARAM_ONOFF, false)
	AutoCarry.PluginMenu:addParam("comobQ", "Q in Combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("comboE", "E in Combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("comboR", "R in Combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("autoUlt", "Cast R to assist kills", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("lcQ", "Q while Lane Clear", SCRIPT_PARAM_ONOFF, true)

	EnemyTable = AutoCarry.EnemyTable
	AllyTable = GetAllyHeroes()
end

function PluginOnTick()
	CDHandler()
	if AutoCarry.PluginMenu.ksQ then QKS() end
	if AutoCarry.PluginMenu.useWlhp then WHeal() end
	if AutoCarry.PluginMenu.autoUlt then smartUltimate() end
	if AutoCarry.PluginMenu.farmQ and (AutoCarry.MainMenu.LastHit or AutoCarry.MainMenu.MixedMode) then QFarm() end
	if AutoCarry.PluginMenu.lcQ and AutoCarry.MainMenu.LaneClear then QLaneClear() end
	if (AutoCarry.PluginMenu.harassQ or AutoCarry.PluginMenu.harassE) and AutoCarry.MainMenu.MixedMode then Harass() end
	if (AutoCarry.PluginMenu.comboQ or AutoCarry.PluginMenu.comboE or AutoCarry.PluginMenu.comboR) and AutoCarry.MainMenu.AutoCarry then Combo() end
end

function CDHandler()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
end

function QKS()
	if not QReady then return end

	for _, enemy in pairs(EnemyTable) do
		if ValidTarget(enemy, RangeQ) and getDmg("Q", enemy, myHero) >= enemy.health then
			CastSpell(_Q, enemy)
		end
	end
end

function WHeal()
	if myHero.health/myHero.maxHealth < AutoCarry.PluginMenu.Wlr and WReady then CastSpell(_W) end
end

function QFarm()
	if not QReady then return end

	for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
		if ValidTarget(minion, RangeQ) and getDmg("Q", minion, myHero) >= minion.health and (not AutoCarry.GetKillableMinion() or AutoCarry.GetKillableMinion().networkID ~= minion.networkID) then -- some creds to vadash's yetcass for the GetKillableMinion idea
			CastSpell(_Q, minion)
		end
	end
end

function QLaneClear()
	if not QReady then return end

	for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
		if ValidTarget(minion, RangeQ) and (not AutoCarry.GetKillableMinion() or AutoCarry.GetKillableMinion().networkID ~= minion.networkID) then
			CastSpell(_Q, minion)
		end
	end	
end

function Harass()
	Target = AutoCarry.GetAttackTarget()

	if ValidTarget(Target, RangeQ) then
		if AutoCarry.PluginMenu.harassE and EReady then CastSpell(_E) end
		if AutoCarry.PluginMenu.harassQ and QReady then CastSpell(_Q, Target) end
	end
end

function Combo()
	Target = AutoCarry.GetAttackTarget()

	if ValidTarget(Target, RangeQ) then
		if AutoCarry.PluginMenu.comboR and RReady then CastSpell(_R, Target.x, Target.z) end
		if AutoCarry.PluginMenu.comboE and EReady then CastSpell(_E) end
		if AutoCarry.PluginMenu.comboQ and QReady then CastSpell(_Q, Target) end
	end
end

function smartUltimate()
	if not RReady then return end

	for _, enemy in pairs(EnemyTable) do
		if ValidTarget(enemy) and (enemy.health/enemy.maxHealth) <= 0.2 then
			for _, ally in pairs(AllyTable) do
				if GetDistance(enemy, ally) <= RangeR and (ally.health/ally.maxHealth) <= 0.4 then -- add enemy count, simple function
					CastSpell(_R, enemy.x, enemy.z)
				end
			end
		end
	end
end

function OnGainBuff (unit, buff)
	if unit and unit == myHero and WReady and AutoCarry.PluginMenu.useWcc then
		if buff.type == BUFF_STUN or buff.type == BUFF_ROOT or buff.type == BUFF_SUPPRESS or buff.type == BUFF_SILENCE or buff.type == BUFF_BLIND or buff.type == BUFF_FEAR or buff.type == BUFF_CHARM then
			CastSpell(_W)
		end
	end
end
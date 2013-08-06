local QReady, EReady, RReady = nil, nil, nil
local RangeQ, RangeMeele = 600, 150

function PluginOnLoad()
	AutoCarry.PluginMenu:addParam("autoR", "Auto R in Combo", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("ks", "KS with Q", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("dqR", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
end

function PluginOnTick()
	CDHandler()
	if AutoCarry.PluginMenu.ks then KS() end
	if AutoCarry.MainMenu.AutoCarry then Combo() end
end

function PluginOnDraw()
	if not myHero.dead and AutoCarry.PluginMenu.dqR then
		DrawCircle(myHero.x, myHero.y, myHero.z, RangeQ, 0x00FFFF)
	end
end

function CDHandler()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
end

function KS()
	for _, enemy in pairs(AutoCarry.EnemyTable) do
		if ValidTarget(enemy, RangeQ) and getDmg("Q", enemy, myHero) >= enemy.health then
			CastSpell(_Q, enemy)
		end
	end
end

function Combo()
	local Target = AutoCarry.GetAttackTarget()

	if ValidTarget(Target) then
		local Distance = GetDistance(Target)

		if RReady and Distance <= RangeMeele and AutoCarry.PluginMenu.autoR then CastSpell(_R) end
		if EReady and ((QReady and Distance <= RangeQ) or (Distance <= RangeMeele)) then CastSpell(_E) end
		if QReady and Distance <= RangeQ then CastSpell(_Q, Target) end
	end
end
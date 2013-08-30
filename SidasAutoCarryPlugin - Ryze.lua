local QReady, WReady, EReady, RReady
local QRange
local LastSpell

function PluginOnLoad()
	AutoCarry.SkillsCrosshair.range = 600
	QReady, WReady, EReady, RReady = false, false, false, false
	QRange = 600
end

function PluginOnTick()
	CDHandler()
	if AutoCarry.MainMenu.AutoCarry then Combo() end
	if AutoCarry.MainMenu.LastHit or AutoCarry.MainMenu.MixedMode then Farm() end
end

function Combo()
	Target = AutoCarry.GetAttackTarget(true)

	if myHero.level >= 8 then
		AutoCarry.CanAttack = false
	end

	if ValidTarget(Target, QRange) then
		local EnemysInRange = CountEnemyHeroInRange(QRange)
		local TotalDamage = 0
		local Distance = myHero:GetDistance(Target)

		if getDmg("AD", myHero, Target)*2 >= Target.health or (not QReady and not WReady and not EReady) and myHero:GetDistance(Target) <= QRange-50 then
			AutoCarry.CanAttack = true
		end

		if QReady then
			TotalDamage = getDmg("Q", myHero, Target)
		end
		if WReady then
			TotalDamage = TotalDamage + getDmg("W", myHero, Target)
		end
		if EReady then
			TotalDamage = TotalDamage + getDmg("E", myHero, Target)
		end

		if Target.health > TotalDamage or EnemysInRange >= 2 then
			CastSpell(_R)
		end

		if EnemysInRange == 1 and myHero:GetDistance(Target) >= QRange-50 and WReady then
			CastSpell(_W, Target)
		end

		if math.abs(myHero.cdr*100) <= 35 then -- Credits to TRUS for his ryze rota
			if QReady then
				CastSpell(_Q, Target)
				LastSpell = _Q
			elseif (LastSpell == _Q or LastSpell == _W) and WReady then
				CastSpell(_W, Target)
				LastSpell = _W
			elseif (LastSpell == _Q or LastSpell == _E) and EReady then
				CastSpell(_E, Target)
				LastSpell = _E
			end
		else
			if QReady then
				CastSpell(_Q, Target)
				LastSpell = _Q
			elseif (LastSpell == _Q or LastSpell == _W) and WReady then
				CastSpell(_W, Target)
				LastSpell = _W
			elseif EReady and not WReady and not QReady then
				CastSpell(_E, Target)
				LastSpell = _E
			end
		end
	end
end

function Farm()
	if not QReady then return end

	for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
		if ValidTarget(minion, QRange) and getDmg("Q", minion, myHero) >= minion.health and (not AutoCarry.GetKillableMinion() or AutoCarry.GetKillableMinion().networkID ~= minion.networkID) then
			CastSpell(_Q, minion)
		end
	end
end

function CDHandler() 
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
end
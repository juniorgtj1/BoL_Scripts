require 'Prodiction'
if myHero.charName ~= "Yasuo" or not VIP_USER then return end

local Config
local ts
local SpellData = {}
local BlockTable = {}
local KnockUpTable = {}
local pd, tpQ1, tpQ2
local enemyMinions
local lastJumpMinion = nil
local lastDashEnd = 0
local KillTable = {}
local DebuffTable = {}
local DebuffTime = {10, 9, 8, 7, 6}
local KillText = {"Combo", "Combo+Items", "UltCombo+Items", "UltCombo+Items+Ignite", "Skills not available"}
local QData = {Stacks = 0, TS = 0}
local EStacks = 0
local IgniteSlot = nil
local Orbwalk = {lastAttack = 0, lastWindUp = 0, lastAttackCD = 0, lastAnimation = nil, walkDistance = 300}
local AnimationDashing = false
local InterruptList = {
	{ charName = "Caitlyn", spellName = "CaitlynAceintheHole"},
	{ charName = "FiddleSticks", spellName = "Crowstorm"},
	{ charName = "FiddleSticks", spellName = "DrainChannel"},
	{ charName = "Galio", spellName = "GalioIdolOfDurand"},
	{ charName = "Karthus", spellName = "FallenOne"},
	{ charName = "Katarina", spellName = "KatarinaR"},
	{ charName = "Malzahar", spellName = "AlZaharNetherGrasp"},
	{ charName = "MissFortune", spellName = "MissFortuneBulletTime"},
	{ charName = "Nunu", spellName = "AbsoluteZero"},
	{ charName = "Pantheon", spellName = "Pantheon_GrandSkyfall_Jump"},
	{ charName = "Shen", spellName = "ShenStandUnited"},
	{ charName = "Urgot", spellName = "UrgotSwap2"},
	{ charName = "Varus", spellName = "VarusQ"},
	{ charName = "Warwick", spellName = "InfiniteDuress"}
}
local ToInterrupt = {}
local IsRecalling = false

function OnLoad()
	Config = scriptConfig("[PQMailer] Yasuo", "pqyasuo")
	Config:addParam("focusSelect", "Focus selected target", SCRIPT_PARAM_ONOFF, true)

	Config:addSubMenu("Combo", "combo")
	Config.combo:addParam("teamfight", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config.combo:addParam("useQ1", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.combo:addParam("useQ2", "Use empowered Q", SCRIPT_PARAM_ONOFF, true)
	Config.combo:addParam("useQ2save", "Save empowered Q for knockup", SCRIPT_PARAM_ONKEYTOGGLE, true, GetKey("A"))
	Config.combo:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	Config.combo:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true)
	Config.combo:addParam("useRsingle", "Use R single target", SCRIPT_PARAM_ONOFF, true)
	Config.combo:addParam("useRcount", "Min. enemies to use R", SCRIPT_PARAM_SLICE, 3, 1, 5, 0)
	Config.combo:addParam("useIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)
	Config.combo:addParam("useItems", "Use Items", SCRIPT_PARAM_ONOFF, true)
	Config.combo:addParam("orbWalk", "Orbwalk", SCRIPT_PARAM_ONOFF, true)

	Config:addSubMenu("Harass", "harass")
	Config.harass:addParam("poke", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("C"))
	Config.harass:addParam("smartPoke", "Smart harass", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("V"))
	Config.harass:addParam("useQ1", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.harass:addParam("useQ2", "Use empowered Q", SCRIPT_PARAM_ONOFF, true)
	Config.harass:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, false)
	Config.harass:addParam("manaSlider", "Min. mana percent to use skills", SCRIPT_PARAM_SLICE, 30, 1, 100, 0)
	Config.harass:addParam("orbWalk", "Orbwalk", SCRIPT_PARAM_ONOFF, true)

	Config:addSubMenu("Farm", "farm")
	Config.farm:addParam("doFarm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, GetKey("X"))
	Config.farm:addParam("useQ1", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.farm:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	Config.farm:addParam("orbWalk", "Orbwalk", SCRIPT_PARAM_ONOFF, true)

	Config:addSubMenu("KS", "ks")
	Config.ks:addParam("useQ1", "Use Q", SCRIPT_PARAM_ONOFF, true)
	Config.ks:addParam("useQ2", "Use empowered Q", SCRIPT_PARAM_ONOFF, true)
	Config.ks:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	Config.ks:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, false)
	Config.ks:addParam("useIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)
	Config.ks:addParam("smartKS", "Smart KS", SCRIPT_PARAM_ONOFF, false)

	Config:addSubMenu("Drawing", "draw")
	Config.draw:addParam("disable", "Disable all draws", SCRIPT_PARAM_ONOFF, false)
	Config.draw:addParam("killable", "Draw kill state", SCRIPT_PARAM_ONOFF, true)
	Config.draw:addParam("killableColor", "Kill state color", SCRIPT_PARAM_COLOR, {255, 190, 190, 190})
	Config.draw:addParam("rangeQ", "Draw Q range", SCRIPT_PARAM_ONOFF, true)
	Config.draw:addParam("rangeQcolor", "Q range color", SCRIPT_PARAM_COLOR, {255, 191, 247, 84})
	Config.draw:addParam("rangeE", "Draw E range", SCRIPT_PARAM_ONOFF, true)
	Config.draw:addParam("rangeEcolor", "E range color", SCRIPT_PARAM_COLOR, {255, 86, 223, 255})
	Config.draw:addParam("rangeR", "Draw R range", SCRIPT_PARAM_ONOFF, true)
	Config.draw:addParam("rangeRcolor", "R range color", SCRIPT_PARAM_COLOR, {255, 247, 84, 84})
	Config.draw:addParam("rangeAD", "Draw AD range", SCRIPT_PARAM_ONOFF, true)
	Config.draw:addParam("rangeADcolor", "AD range color", SCRIPT_PARAM_COLOR, {255, 255, 157, 86})
	Config.draw:addParam("rangeForce", "Force range draw", SCRIPT_PARAM_ONOFF, true)

	Config:addSubMenu("Additionals", "extra")
	Config.extra:addParam("interruptQ2", "Interrupt channeled spells with empowered Q", SCRIPT_PARAM_ONOFF, true)
	Config.extra:addParam("interruptQ2print", "Print interrupts", SCRIPT_PARAM_ONOFF, true)
	Config.extra:addParam("antigpQ2", "Kick gapcloser with empowered Q", SCRIPT_PARAM_ONOFF, true)
	Config.extra:addParam("antigpQ2print", "Print kicks", SCRIPT_PARAM_ONOFF, true)
	Config.extra:addParam("autoStackQ", "Auto stack Q", SCRIPT_PARAM_ONOFF, false)
	Config.extra:addParam("autoFireQ", "Prevent wasting Q", SCRIPT_PARAM_ONOFF, false)

	SpellData = {
		Q1 = {Range = 450, Speed = 1200, Delay = 0.360, Width = 90, Radius = 375},
		Q2 = {Range = 850, Speed = 1200, Delay = 0.360, Width = 120, Radius = 375},
		E = {Range = 475},
		R = {Range = 1300, Radius = 400},
		Ignite = {Range = 600}
	}

	for _, Enemy in pairs(GetEnemyHeroes()) do
		KillTable[Enemy.networkID] = 5
	end

	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, SpellData.R.Range, DAMAGE_PHYSICAL)
	ts.name = "Yasuo"
	Config:addTS(ts)

	enemyMinions = minionManager(MINION_ENEMY, 2000, myHero, MINION_SORT_HEALTH_ASC)

	pd = ProdictManager.GetInstance()
	tpQ1 = pd:AddProdictionObject(_Q, SpellData.Q1.Range, SpellData.Q1.Speed, SpellData.Q1.Delay, SpellData.Q1.Width, myHero)
	tpQ2 = pd:AddProdictionObject(_Q, SpellData.Q2.Range, SpellData.Q2.Speed, SpellData.Q2.Delay, SpellData.Q2.Width, myHero)

	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then IgniteSlot = SUMMONER_1 elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then IgniteSlot = SUMMONER_2 end

	for _, enemy in pairs(GetEnemyHeroes()) do
		for _, champ in pairs(InterruptList) do
			if enemy.charName == champ.charName then
				table.insert(ToInterrupt, champ.spellName)
			end
		end
	end

	if #ToInterrupt > 0 then
		PrintChat("[PQYasuo]: I will interrupt "..#ToInterrupt.." spells.")
	end

	PrintChat("[PQMailer] "..myHero.charName.. " v."..tostring(versionGOE).." loaded")
end

function OnTick()
	ts.targetSelected = Config.focusSelect
	ts:update()
	enemyMinions:update()
	CleanDebuffTable()
	CleanKnockUpTable()
	DamageCalculation()
	if lastJumpMinion ~= nil and not lastJumpMinion.valid then lastJumpMinion = nil end
	if os.clock() > QData.TS + 10 then QData.Stacks = 0 end
	RegularKS()
	--if Config.ks.smartKS then SmartKS() end
	if Config.combo.teamfight then Combo() end
	if Config.harass.smartPoke then SmartHarass() end
	if Config.harass.poke then RegularHarass() end
	if Config.extra.autoFireQ then AutoQFire() end
	if Config.extra.autoStackQ then AutoQStack() end
	if Config.farm.doFarm then Farm() end
	if (Config.combo.teamfight and Config.combo.orbWalk) or ((Config.harass.poke or Config.harass.smartPoke) and Config.harass.orbWalk) or (Config.farm.doFarm and Config.farm.orbWalk) then
		if Config.farm.doFarm then
			local Minion = GetNearestMinion()
			OrbWalk(Minion)
		else
			OrbWalk(ts.target)
		end
	end
end

function OnDraw()
	if Config.draw.disable then
		return
	end

	local c = {
		killable = Config.draw.killableColor,
		q = Config.draw.rangeQcolor,
		e = Config.draw.rangeEcolor,
		r = Config.draw.rangeRcolor,
		ad = Config.draw.rangeADcolor
	}

	if Config.draw.killable then
		for _, Enemy in pairs(GetEnemyHeroes()) do
			if ValidTarget(Enemy) then
				DrawText3D(KillText[KillTable[Enemy.networkID]], Enemy.x, Enemy.y, Enemy.z, 16, ARGB(c.killable[1], c.killable[2], c.killable[3], c.killable[4]), true)
			end
		end
	end

	if Config.draw.rangeQ and (Config.draw.rangeForce or myHero:CanUseSpell(_Q) == READY) then
		if QState() ~= 3 then
			DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellData.Q1.Range, 1, ARGB(c.q[1], c.q[2], c.q[3], c.q[4]), 10)
		elseif QState() == 3 then
			DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellData.Q2.Range, 1, ARGB(c.q[1], c.q[2], c.q[3], c.q[4]), 10)
		end
	end
	if Config.draw.rangeE and (Config.draw.rangeForce or myHero:CanUseSpell(_E) == READY) then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellData.E.Range, 1, ARGB(c.e[1], c.e[2], c.e[3], c.e[4]), 10)
	end
	if Config.draw.rangeR and (Config.draw.rangeForce or myHero:CanUseSpell(_R) == READY) then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellData.R.Range, 1, ARGB(c.r[1], c.r[2], c.r[3], c.r[4]), 10)
	end
	if Config.draw.rangeAD or Config.draw.rangeForce then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, 240, 1, ARGB(c.ad[1], c.ad[2], c.ad[3], c.ad[4]), 10)
	end
end

function OnGainBuff(unit, buff)
	if unit.team ~= myHero.team then
		if buff.type == BUFF_KNOCKUP and unit.type:lower() == "obj_ai_hero" then
			KnockUpTable[unit.networkID] = os.clock()
		elseif buff.name == "YasuoDashWrapper" then
			DebuffTable[unit.networkID] = os.clock()
		end
	end

	if unit.isMe then
		if buff.name == "yasuoq" then
			QData.Stacks = 1
			QData.TS = os.clock()
		elseif buff.name == "yasuoq3w" then
			QData.Stacks = 2
			QData.TS = os.clock()
		elseif buff.name == "yasuodashscalar" then
			EStacks = 1
		end
	end
end

function OnUpdateBuff(unit, buff)
	if unit.isMe and buff.name == "yasuodashscalar" then
		EStacks = buff.stack
	end
end

function OnLoseBuff(unit, buff)
	if unit.team ~= myHero.team and buff.type == BUFF_KNOCKUP and unit.type:lower() == "obj_ai_hero" then
		KnockUpTable[unit.networkID] = false
	end
	if unit.isMe and buff.name == "yasuodashscalar" then
		EStacks = 0
	end
end

function OnDash(unit, dash)
	if unit.team ~= myHero.team and ValidTarget(unit, 1000) then
		if Config.extra.antigpQ2 and QState() == 3 and not IsDashing() and myHero:CanUseSpell(_Q) == READY then
			if dash.target == myHero or (dash.distance <= myHero:GetDistance(unit) and myHero:GetDistance(unit) <= SpellData.Q2.Range) then
				if Config.extra.antigpQ2print then print("Tried to kick a dash.") end
				tpQ2:GetPredictionCallBack(unit, CastQ2)
			end
		end
	end
end

function OnProcessSpell(unit, spell)
	if #ToInterrupt > 0 and Config.extra.interruptQ2 and QState() == 3 and not IsDashing() and myHero:CanUseSpell(_Q) == READY then
		for _, ability in pairs(ToInterrupt) do
			if spell.name == ability and unit.team ~= myHero.team then
				if ValidTarget(unit, SpellData.Q2.Range) then
					if Config.extra.interruptQ2print then print("Tried to interrupt " .. spell.name..".") end
					tpQ2:GetPredictionCallBack(unit, CastQ2)
				end
			end
		end
	end

	if unit.isMe and spell.name:lower():find("attack") then
		Orbwalk.lastAttack = GetTickCount() - GetLatency()/2
		Orbwalk.lastWindUp = spell.windUpTime*1000
		Orbwalk.lastAttackCD = spell.animationTime*1000
	end
end

function OnAnimation(unit, animationName)
	if unit.isMe then 
		if Orbwalk.lastAnimation ~= animationName then Orbwalk.lastAnimation = animationName end
		AnimationDashing = (animationName == "Spell3" and true or false)
	end
end

function OnRecall(hero, channelTimeInMs)
	if hero.networkID == player.networkID then
		IsRecalling = true
	end
end

function OnAbortRecall(hero)
	if hero.networkID == player.networkID then
		IsRecalling = false
	end	
end

function OnFinishRecall(hero)
	if hero.networkID == player.networkID then
		IsRecalling = false
	end
end

function Combo()
	if ValidTarget(ts.target) then
		local Distance = myHero:GetDistance(ts.target)

		if Config.combo.useRsingle and Distance <= SpellData.R.Range and IsKnockedUp(ts.target) and myHero:CanUseSpell(_R) == READY and KillTable[ts.target.networkID] ~= 3 and KillTable[ts.target.networkID] ~= 5 then
			CastSpell(_R, ts.target)
		end
		if IsKnockedUp(ts.target) and CountEnemyHeroInRange(SpellData.R.Radius, ts.target) >= Config.combo.useRcount then
			CastSpell(_R, ts.target)
		end
		if ((QState() ~= 3 and Config.combo.useQ1) or (QState() == 3 and Config.combo.useQ2)) and myHero:CanUseSpell(_Q) == READY then
			if IsDashing() then
				if CountEnemyHeroInRange(SpellData.Q1.Radius, myHero) > 0 and not (QState() == 3 and Config.combo.useQ2save) then
						CastSpell(_Q, ts.target.x, ts.target.z)
					end
				else
					if (QState() ~= 3 and Distance <= SpellData.Q1.Range) or (QState() == 3 and Distance <= SpellData.Q2.Range) then
						GetQPrediction(ts.target)
					end
				end
		end
		if Config.combo.useE and myHero:CanUseSpell(_E) == READY then
			if myHero:CanUseSpell(_Q) == READY and CountEnemyHeroInRange(375, ts.target) >= 2 then
				local MECTarget = GetMECYasou(GetEnemyHeroes(), SpellData.E.Range, SpellData.Q1.Radius, VC_YASUO, myHero)
				if ValidTarget(MECTarget, SpellData.E.Range) then
					CastSpell(_E, MECTarget)
				end
			elseif Distance <= SpellData.E.Range and CanUseE(ts.target) and myHero:CanUseSpell(_E) == READY then
				CastSpell(_E, ts.target)
			else
				for _, Enemy in pairs(GetEnemyHeroes()) do
					if ValidTarget(Enemy, SpellData.E.Range) and CanUseE(Enemy) and myHero:CanUseSpell(_E) == READY then
						CastSpell(_E, Enemy)
					end
				end
			end
		end
		if Config.combo.useIgnite and IgniteSlot and myHero:CanUseSpell(IgniteSlot) == READY and KillTable[ts.target.networkID] == 4 then
			CastSpell(IgniteSlot, ts.target)
		end
		if Distance > GetTrueRangeToEnemy(ts.target) then
			local jMinion, eDis = GetNextMinion(ts.target, SpellData.E.Range)
			if ValidTarget(jMinion, SpellData.E.Range) and eDis < Distance*Distance then
				CastSpell(_E, jMinion)
			end
		end
	end
end

function RegularHarass()
	if ValidTarget(ts.target) and ManaCheck() then
		local Distance = myHero:GetDistance(ts.target)

		if (Distance <= SpellData.Q1.Range and QState() ~= 3 and Config.combo.useQ1) or (Distance <= SpellData.Q2.Range and QState() == 3 and Config.combo.useQ2) and myHero:CanUseSpell(_Q) == READY then
			GetQPrediction(ts.target)
		end
		if Config.harass.useE and Distance <= SpellData.E.Range and CanUseE(ts.target) and myHero:CanUseSpell(_E) == READY and IsESafe(ts.target) then
			CastSpell(_E, ts.target)
		end
	end
end

function SmartHarass()
	if ValidTarget(ts.target) and ManaCheck() then
		if myHero:CanUseSpell(_Q) == READY and CountEnemyHeroInRange(SpellData.Q1.Radius, myHero) > 0 and IsDashing() then
			CastSpell(_Q, ts.target.x, ts.target.z)
		elseif myHero:CanUseSpell(_Q) ~= READY and myHero:CanUseSpell(_E) == READY then
			local fjMinion = GetFarestMinion(ts.target, SpellData.E.Range)
			if ValidTarget(fjMinion, SpellData.E.Range) then
				CastSpell(_E, fjMinion)
			end
		end

		if QState() ~= 3 and myHero:CanUseSpell(_Q) == READY and myHero:CanUseSpell(_E) == READY and ValidTarget(ts.target) then
			local jMinion = GetNextMinion(ts.target, SpellData.E.Range)

			if ValidTarget(jMinion, SpellData.E.Range) and GetDistanceSqr(jMinion, ts.target) < GetDistanceSqr(ts.target) and GetDistance(jMinion, ts.target) <= SpellData.Q1.Radius then
				CastSpell(_E, jMinion)
			end
		end
	end
end

function RegularKS()
	for _, Enemy in pairs(GetEnemyHeroes()) do
		if Config.ks.useE and ValidTarget(Enemy, SpellData.E.Range) and GetEDmg(Enemy) >= Enemy.health then
			CastSpell(_E, Enemy)
		elseif Config.ks.useQ1 and QState() ~= 3 and ValidTarget(Enemy, SpellData.Q1.Range) and getDmg("Q", Enemy, myHero) >= Enemy.health then
			GetQPrediction(Enemy)
		elseif Config.ks.useQ2 and QState() == 3 and ValidTarget(Enemy, SpellData.Q2.Range) and getDmg("Q", Enemy, myHero) >= Enemy.health then
			GetQPrediction(Enemy)
		elseif Config.ks.useR and IsKnockedUp(Enemy) and ValidTarget(Enemy, SpellData.R.Range) and getDmg("R", Enemy, myHero) >= Enemy.health then
			CastSpell(_R, Enemy)
		elseif Config.ks.useIgnite and ValidTarget(Enemy, SpellData.Ignite.Range) and IgniteSlot and myHero:CanUseSpell(IgniteSlot) == READY and getDmg("IGNITE", Enemy, myHero) >= Enemy.health then
			CastSpell(IgniteSlot, Enemy)
		end
	end
end

function SmartKS()
	--
end

function Farm()
	for _, Minion in pairs(enemyMinions.objects) do
		if ValidTarget(Minion) then
			local Distance = myHero:GetDistance(Minion)
			if Config.farm.useE and Distance <= SpellData.E.Range and GetEDmg(Minion) >= Minion.health and CanUseE(Minion) and myHero:CanUseSpell(_E) == READY and IsESafe(Minion) then
				CastSpell(_E, Minion)
			elseif Config.farm.useQ1 and QState() ~= 3 and getDmg("Q", Minion, myHero) >= Minion.health and myHero:CanUseSpell(_Q) == READY then
				if IsDashing() then
					if Distance <= SpellData.Q1.Radius then
						CastSpell(_Q, Minion.x, Minion.z)
					end
				else
					if Distance <= SpellData.Q1.Range then
						CastSpell(_Q, Minion.x, Minion.z)
					end
				end
			end
		end
	end
end

function AutoQFire()
	if QState() == 3 and os.clock() > QData.TS + 8 and not IsDashing() and myHero:CanUseSpell(_Q) == READY and not IsRecalling then
		if ValidTarget(ts.target, SpellData.Q2.Range) then
			GetQPrediction(ts.target)
		else
			for _, Minion in pairs(enemyMinions.objects) do
				if ValidTarget(Minion, SpellData.Q2.Range) then
					CastSpell(_Q, Minion.x, Minion.z)
				end
			end
		end
	end
end

function AutoQStack()
	if QState() ~= 3 and os.clock() > QData.TS + 7 and not IsDashing() and myHero:CanUseSpell(_Q) == READY and not IsRecalling then
		if ValidTarget(ts.target, SpellData.Q1.Range) then
			GetQPrediction(ts.target)
		else
			for _, Minion in pairs(enemyMinions.objects) do
				if ValidTarget(Minion, SpellData.Q1.Range) then
					CastSpell(_Q, Minion.x, Minion.z)
				end
			end
		end
	end
end

function CastQ1(unit, pos, spell)
	if ValidTarget(unit, SpellData.Q1.Range) and myHero:CanUseSpell(_Q) == READY then
		CastSpell(_Q, pos.x, pos.z)
	end
end

function CastQ2(unit, pos, spell)
	if ValidTarget(unit, SpellData.Q2.Range) and myHero:CanUseSpell(_Q) == READY then
		CastSpell(_Q, pos.x, pos.z)
	end
end

function GetQPrediction(unit)
	if QState() ~= 3 then
		if IsDashing() then
			if ValidTarget(unit, 375) and not (Config.combo.teamfight and Config.combo.useQ2save) then
				CastSpell(_Q, unit.x, unit.z)
			end
		else
			tpQ1:GetPredictionCallBack(unit, CastQ1)
		end
	elseif QState() == 3 then
		if IsDashing() then
			if ValidTarget(unit, 375) then
				CastSpell(_Q, unit.x, unit.z)
			end
		else
			tpQ2:GetPredictionCallBack(unit, CastQ2)
		end
	end
end

function ManaCheck()
	return (myHero.mana > (myHero.maxMana*(Config.harass.manaSlider/100)))
end

function QState()
	if QData.Stacks == 0 then
		return 1
	elseif QData.Stacks == 1 then
		return 2
	elseif QData.Stacks == 2 then
		return 3
	end
end

function IsKnockedUp(unit)
	return (KnockUpTable[unit.networkID] ~= nil)
end

function IsDashing()
	return AnimationDashing
end

function CleanDebuffTable()
	local Level = myHero:GetSpellData(_E).level

	for ID, TS in pairs(DebuffTable) do
		if os.clock() > TS + DebuffTime[Level] then
			DebuffTable[ID] = nil
		end
	end
end

function CleanKnockUpTable()
	for ID, TS in pairs(KnockUpTable) do
		if os.clock() > TS + 10 then
			KnockUpTable[ID] = nil
		end
	end
end

function CanUseE(unit)
	return (DebuffTable[unit.networkID] == nil)
end

function IsESafe(unit)
	local Pos = Vector(myHero) + (Vector(unit) - Vector(myHero)):normalized() * 475

	if UnderTurret(Pos, true) then
		return false
	else
		return true
	end
end

function GetTrueRangeToEnemy(enemy)
	return GetDistance(myHero.minBBox) + myHero.range + GetDistance(enemy.minBBox,enemy.maxBBox)/2
end

function GetEDmg(unit)
	return myHero:CalcMagicDamage(unit, (((20*myHero:GetSpellData(_E).level)+50+(((20*myHero:GetSpellData(_E).level)+50)/100*(25*EStacks)))+0.6*myHero.ap))
end

function DamageCalculation()
	for _, Enemy in pairs(GetEnemyHeroes()) do
		if ValidTarget(Enemy) then
			local Damage = {Q = 0, E = 0, R = 0, AD = 0, TIAMAT = 0, HYDRA = 0, BWC = 0, RUINEDKING = 0, Ignite = 0, OnHIT = 0, Combo1 = 0, Combo2 = 0, Combo3 = 0, Combo4 = 0}

			Damage.Q = getDmg("Q", Enemy, myHero)
			Damage.E = GetEDmg(Enemy)
			Damage.R = getDmg("R", Enemy, myHero)
			Damage.AD = getDmg("AD", Enemy, myHero)*3
			Damage.TIAMAT = (GetInventoryHaveItem(3077) and getDmg("TIAMAT", Enemy, myHero) or 0)
			Damage.HYDRA = (GetInventoryHaveItem(3074) and getDmg("HYDRA", Enemy, myHero) or 0)
			Damage.BWC = (GetInventoryHaveItem(3144) and getDmg("BWC", Enemy, myHero) or 0)
			Damage.RUINEDKING = (GetInventoryHaveItem(3153) and getDmg("RUINEDKING", Enemy, myHero) or 0)
			Damage.OnHIT = (GetInventoryHaveItem(3057) and getDmg("SHEEN", Enemy, myHero) or 0) + (GetInventoryHaveItem(3078) and getDmg("TRINITY", Enemy, myHero) or 0) + (GetInventoryHaveItem(3100) and getDmg("LICHBANE", Enemy, myHero) or 0) + (GetInventoryHaveItem(3025) and getDmg("ICEBORN", Enemy, myHero) or 0) + (GetInventoryHaveItem(3087) and getDmg("STATIKK", Enemy, myHero) or 0) + (GetInventoryHaveItem(3209) and getDmg("SPIRITLIZARD", Enemy, myHero) or 0)
			Damage.Ignite = (IgniteSlot and getDmg("IGNITE", Enemy, myHero) or 0)

			Damage.Combo1 = Damage.AD + Damage.OnHIT
			Damage.Combo2 = Damage.AD + Damage.OnHIT
			Damage.Combo3 = Damage.AD + Damage.OnHIT
			Damage.Combo4 = Damage.AD + Damage.OnHIT

			if myHero:CanUseSpell(_Q) == READY then
				local Multiplier = 1
				if QState() == 1 then
					Multiplier = 3
				elseif QState() == 2 then
					Multiplier = 2
				elseif QState() == 3 then
					Multiplier = 1
				end

				Damage.Combo1 = Damage.Combo1 + Damage.Q*Multiplier
				Damage.Combo2 = Damage.Combo2 + Damage.Q*Multiplier
				Damage.Combo3 = Damage.Combo3 + Damage.Q*Multiplier
				Damage.Combo4 = Damage.Combo4 + Damage.Q*Multiplier
			end

			if myHero:CanUseSpell(_E) == READY then
				Damage.Combo1 = Damage.Combo1 + Damage.E
				Damage.Combo2 = Damage.Combo2 + Damage.E
				Damage.Combo3 = Damage.Combo3 + Damage.E
				Damage.Combo4 = Damage.Combo4 + Damage.E
			end

			if myHero:CanUseSpell(_R) == READY then
				Damage.Combo3 = Damage.Combo3 + Damage.R
				Damage.Combo4 = Damage.Combo4 + Damage.R
			end

			if GetInventoryItemIsCastable(3077) then
				Damage.Combo2 = Damage.Combo2 + Damage.TIAMAT
				Damage.Combo3 = Damage.Combo3 + Damage.TIAMAT
				Damage.Combo4 = Damage.Combo4 + Damage.TIAMAT
			end

			if GetInventoryItemIsCastable(3074) then
				Damage.Combo2 = Damage.Combo2 + Damage.HYDRA
				Damage.Combo3 = Damage.Combo3 + Damage.HYDRA
				Damage.Combo4 = Damage.Combo4 + Damage.HYDRA
			end

			if GetInventoryItemIsCastable(3144) then
				Damage.Combo2 = Damage.Combo2 + Damage.BWC
				Damage.Combo3 = Damage.Combo3 + Damage.BWC
				Damage.Combo4 = Damage.Combo4 + Damage.BWC
			end

			if GetInventoryItemIsCastable(3153) then
				Damage.Combo2 = Damage.Combo2 + Damage.RUINEDKING
				Damage.Combo3 = Damage.Combo3 + Damage.RUINEDKING
				Damage.Combo4 = Damage.Combo4 + Damage.RUINEDKING
			end

			if IgniteSlot and myHero:CanUseSpell(IgniteSlot) == READY then
				Damage.Combo4 = Damage.Combo4 + Damage.Ignite
			end

			KillTable[Enemy.networkID] = 5

			if Damage.Combo4 >= Enemy.health then
				KillTable[Enemy.networkID] = 4
			end
			if Damage.Combo3 >= Enemy.health then
				KillTable[Enemy.networkID] = 3
			end
			if Damage.Combo2 >= Enemy.health then
				KillTable[Enemy.networkID] = 2
			end
			if Damage.Combo1 >= Enemy.health then
				KillTable[Enemy.networkID] = 1
			end
		end
	end
end

function OrbWalk(target)
	if target ~= nil and GetDistance(target) < GetTrueRangeToEnemy(target) then
		if GetDistance(target) <= 500 and Config.combo.useItems then
			if GetInventoryItemIsCastable(3077) then
				CastItem(3077)
			elseif GetInventoryItemIsCastable(3074) then
				CastItem(3074)
			elseif GetInventoryItemIsCastable(3144) then
				CastItem(3144, target)
			elseif GetInventoryItemIsCastable(3153) then
				CastItem(3153, target)
			end
		end

		if timeToShoot() then
			myHero:Attack(target)
		elseif heroCanMove() then
			moveToCursor()
		end
	elseif heroCanMove() then
		moveToCursor()
	end
end

function heroCanMove()
	return (GetTickCount() + GetLatency()/2 > Orbwalk.lastAttack + Orbwalk.lastWindUp + 20)
end

function timeToShoot()
	return (GetTickCount() + GetLatency()/2 > Orbwalk.lastAttack + Orbwalk.lastAttackCD)
end

function moveToCursor()
	if GetDistance(mousePos) > 50 or Orbwalk.lastAnimation == "Idle1" then
		local moveToPos = myHero + (Vector(mousePos) - myHero):normalized()*Orbwalk.walkDistance
		myHero:MoveTo(moveToPos.x, moveToPos.z)
	end
end

--[[ Yasuo MEC Start ]]--

--Usage
--GetMECYasou(GetEnemyHeroes(), 475, 375, VC_YASUO, myHero)
--Author: NotScarra

local __MEC_MINIONS_INIT__ = false

VC_YASUO = function(object)
	return CanUseE(object)
end

VC_DEFAULT = function(object)
	return true
end

function GetMECYasou(points, range, radius, validCheck, from)
	from = from or myHero
	
	radius = radius * radius
	
	function GetValidity(object)	
		local inPos = 0
		if GetDistance(object) < range and validCheck(object) then
			local pos = Vector(from) + (Vector(object) - Vector(from)):normalized() * range
			for _, p in ipairs(points) do 
				if GetDistanceSqr(p,pos) < radius then
					inPos = inPos + 1
				end
			end
		end
		
		return inPos
	end
	
	if not __MEC_MINIONS_INIT__ then
		__MEC_MINIONS_INIT__ = true
	end
	
	local bestTarget = nil
	local bestAmt = 0
	
	for _, minion in ipairs(enemyMinions.objects) do
		local validity = GetValidity(minion)

		if validity > bestAmt then
			bestAmt = validity
			bestTarget = minion
		end
	end
	
	for _, hero in ipairs(GetEnemyHeroes()) do
		local validity = GetValidity(hero)

		if validity > bestAmt then
			bestAmt = validity
			bestTarget = hero
		end
	end
	
	return bestTarget
end

--[[ Yasuo MEC End ]]--

--Yasuo Gap Closer
--Returns distance to pos after dash squared

function GetNextMinion(pos, range)
	local bestD = GetDistanceSqr(pos)
	local bestM = nil
	
	for _, object in ipairs(enemyMinions.objects) do
		if GetDistance(object) < range and VC_YASUO(object) then
			local p = Vector(myHero) + (Vector(object) - Vector(myHero)):normalized() * 475
			local dsq = GetDistanceSqr(p,pos)
			
			if dsq < bestD then
				bestD = dsq
				bestM = object
			end
		end
	end
	
	return bestM, bestD
end

function GetNearestMinion()
	local bestM = nil

	for _, object in ipairs(enemyMinions.objects) do
		if bestM and bestM.valid and object and object.valid then
			if GetDistanceSqr(object) < GetDistanceSqr(bestM) then
				bestM = object
			end
		else
			bestM = object
		end
	end

	return bestM
end

function GetFarestMinion(unit, range)
	local bestM = nil
	local unit = unit or myHero
	local range = range * range

	for _, object in ipairs(enemyMinions.objects) do
		if bestM and bestM.valid and object and object.valid and unit and unit.valid then
			if GetDistanceSqr(unit, object) > GetDistanceSqr(unit, bestM) and GetDistanceSqr(unit, object) < range then
				bestM = object
			end
		else
			bestM = object
		end
	end

	return bestM
end
--[[ Varus Auto Carry Plugin; Credits to vadash/HeX for some stuff of their Varus scripts]]--

if not VIP_USER then
	print("Varus can only be handled as VIP; Sry")
	return
end

--[[ Variables ]]--
local HK1 = string.byte("Y") -- Harass
local HK2 = string.byte("N") -- jungle clearing
local HK3 = string.byte("E") -- slow nearest target

--->>> Do not touch anything below here <<<---

local SkillQ = {spellKey = _Q, range = 1475, speed = 1.85, delay = 0, width = 60}
local SkillE = {spellKey = _E, range = 925, speed = 1.5, delay = 242, width = 100}
local SkillR = {spellKey = _R, range = 1075, speed = 1.95, delay = 250 , width = 80}
local levelSequence = {nil,0,2,1,1,4,1,3,1,3,4,3,3,2,2,4,2,2} -- we level the spells that way, first point free choice; W or E
local floattext = {"Harass him","Fight him","Kill him","Murder him"} -- text assigned to enemys
local killable = {} -- our enemy array where stored if people are killable
local waittxt = {} -- prevents UI lags, all credits to Dekaron
local QReady, WReady, EReady, RReady, BWCReady, RUINEDKINGReady, QUICKSILVERReady, RANDUINSReady, IGNITEReady, CLEANSEReady = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
local EnemyTable = GetEnemyHeroes()
local MinionTable = AutoCarry.EnemyMinions().objects
local Cast = false
local Tick = 0
local ProcReady = false
local ProcStacks = {}
local Target = nil

--[[ Core]]--
function PluginOnLoad()
	AutoCarry.PluginMenu:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, HK1) -- harass
	AutoCarry.PluginMenu:addParam("jungle", "Jungle clearing", SCRIPT_PARAM_ONKEYTOGGLE, false, HK2) -- jungle clearing
	AutoCarry.PluginMenu:addParam("slow", "Slow nearest enemy with E", SCRIPT_PARAM_ONKEYTOGGLE, false, HK3) -- auto slow

	-- Settings
	AutoCarry.PluginMenu:addParam("lcSkills", "Use Skills with Lane Clear mode", SCRIPT_PARAM_ONOFF, true) -- spamming e on the minions while lane clearing
	AutoCarry.PluginMenu:addParam("aUlti", "Use Ulti in Full Combo", SCRIPT_PARAM_ONOFF, true) -- decide if ulti should be used in full combo
	AutoCarry.PluginMenu:addParam("aItems", "Use Items in Full Combo", SCRIPT_PARAM_ONOFF, true) -- decide if items should be used in full combo
	AutoCarry.PluginMenu:addParam("aIGN", "Auto Ignite", SCRIPT_PARAM_ONOFF, true) -- ignite
	AutoCarry.PluginMenu:addParam("aCL", "Auto Cleanse", SCRIPT_PARAM_ONOFF, true) -- cleanse
	AutoCarry.PluginMenu:addParam("aBA", "Auto Barrier", SCRIPT_PARAM_ONOFF, true) -- barrier
	AutoCarry.PluginMenu:addParam("swR", "Slow with R if E is on CD", SCRIPT_PARAM_ONOFF, false) -- use ulti to escape
	AutoCarry.PluginMenu:addParam("hwQ", "Harass with Q", SCRIPT_PARAM_ONOFF, true) -- Harass with Q
	AutoCarry.PluginMenu:addParam("hwE", "Harass with E", SCRIPT_PARAM_ONOFF, true) -- Harass with E
	AutoCarry.PluginMenu:addParam("aSkills", "Auto Level Skills (Requires Reload)", SCRIPT_PARAM_ONOFF, true) -- auto level skills
	AutoCarry.PluginMenu:addParam("aQ", "Auto Q/E if W is stacked", SCRIPT_PARAM_ONOFF, true) -- Auto Q/E if W is stacked
	AutoCarry.PluginMenu:addParam("waitDelay", "Delay before Q (ms)",SCRIPT_PARAM_SLICE, 250, 0, 2000, 2) -- the q delay
	AutoCarry.PluginMenu:addParam("tryPrioritizeQ", "Try to prioritize Q", SCRIPT_PARAM_ONOFF, true) -- q > e on prock
	AutoCarry.PluginMenu:addParam("aQEWS", "Minimum W Stacks to Q/W", SCRIPT_PARAM_SLICE, 2, 1, 3, 0) -- W stacks to Q
	AutoCarry.PluginMenu:addParam("lhE", "Last hit with E", SCRIPT_PARAM_ONOFF, true) -- Last hit with E
	AutoCarry.PluginMenu:addParam("lhEM", "Last hit until Mana", SCRIPT_PARAM_SLICE, 50, 0, 100, 2) -- mana slider
	AutoCarry.PluginMenu:addParam("lhEMinions", "Minimum amount of minions for E last hit", SCRIPT_PARAM_SLICE, 2, 1, 10, 0) -- minion slider
	AutoCarry.PluginMenu:addParam("ks", "KS with all Skills", SCRIPT_PARAM_ONOFF, true) -- KS with all skills

	-- Visual
	AutoCarry.PluginMenu:addParam("draw", "Draw Circles", SCRIPT_PARAM_ONOFF, false) -- Draw Circles

	-- perma show HK1-4
	AutoCarry.PluginMenu:permaShow("harass")
	AutoCarry.PluginMenu:permaShow("jungle")
	AutoCarry.PluginMenu:permaShow("slow")


	if AutoCarry.PluginMenu.aSkills then -- setup the skill autolevel
		autoLevelSetSequence(levelSequence)
		autoLevelSetFunction(onChoiceFunction) -- add the callback to choose the first skill
	end

	IGNITESlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil) -- do we have ignite?
	CLEANSESlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerCleanse") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerCleanse") and SUMMONER_2) or nil) -- do we have ignite?

	for i=1, heroManager.iCount do waittxt[i] = i*3 end -- All credits to Dekaron

	AutoCarry.SkillsCrosshair.range = SpellRangeQ

	qp = TargetPredictionVIP(SkillQ.range, SkillQ.speed*1000, SkillQ.delay/1000, SkillQ.with)
end

function PluginOnTick()
	CooldownHandler()
	if AutoCarry.PluginMenu.ks then KS() end
	if AutoCarry.PluginMenu.slow then SlowNearestEnemy() end
	if AutoCarry.MainMenu.AutoCarry then FullCombo() end
	if AutoCarry.MainMenu.LaneClear then LaneClear() end
	if AutoCarry.PluginMenu.Harass then Harass() end
	if AutoCarry.MainMenu.LastHit and AutoCarry.PluginMenu.jungle then JungleSteal() end
	if AutoCarry.MainMenu.LaneClear and AutoCarry.PluginMenu.jungle then JungleClear() end
	if (AutoCarry.PluginMenu.aQ or AutoCarry.MainMenu.MixedMode) and not (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.LaneClear or AutoCarry.PluginMenu.Harass) then CastEQAuto() end
	if AutoCarry.MainMenu.LastHit and AutoCarry.PluginMenu.lhE and ((myHero.mana/myHero.maxMana)*100) >= AutoCarry.PluginMenu.lhEM then LastHitE() end

end

function PluginOnDraw()
	if not myHero.dead and AutoCarry.PluginMenu.draw then
		for i=1, heroManager.iCount do
			local Unit = heroManager:GetHero(i)
			if ValidTarget(Unit) then -- we draw our circles
				 if killable[i] == 1 then
				 	DrawCircle(Unit.x, Unit.y, Unit.z, 100, 0xFFFFFF00)
				 end

				 if killable[i] == 2 then
				 	DrawCircle(Unit.x, Unit.y, Unit.z, 100, 0xFFFFFF00)
				 end

				 if killable[i] == 3 then
				 	for j=0, 10 do
				 		DrawCircle(Unit.x, Unit.y, Unit.z, 100+j*0.8, 0x099B2299)
				 	end
				 end

				 if killable[i] == 4 then
				 	for j=0, 10 do
				 		DrawCircle(Unit.x, Unit.y, Unit.z, 100+j*0.8, 0x099B2299)
				 	end
				 end

				 if waittxt[i] == 1 and killable[i] ~= 0 then
				 	PrintFloatText(Unit,0,floattext[killable[i]])
				 end
			end

			if waittxt[i] == 1 then
				waittxt[i] = 30
			else
				waittxt[i] = waittxt[i]-1
			end

		end
	end
end

function PluginOnCreateObj(object)
	if object and object.name == "VarusW_counter_02.troy" and GetDistance(object, Target) <= 125 then
		for i=1, _, enemy in pairs(EnemyTable) do
			if ValidTarget(enemy) and TargetHaveBuff("varuswdebuff", enemy) then
				ProcStacks[i] = 2
			end
		end
		ProcReady = true
	end

	if object and object.name == "VarusW_counter_03.troy" and GetDistance(object, Target) <= 125 then
		for i=1, _, enemy in pairs(EnemyTable) do
			if ValidTarget(enemy) and TargetHaveBuff("varuswdebuff", enemy) then
				ProcStacks[i] = 3
			end
		end
		ProcReady = true
	end
end	

function PluginOnDeleteObj(object)
	if object and object.name == "VarusW_counter_02.troy" then
		for i=1, _, enemy in pairs(EnemyTable) do
			if not TargetHaveBuff("varuswdebuff", enemy) then
				ProcStacks[i] = 0
			end
		end
		ProcReady = false
	end

	if object and object.name == "VarusW_counter_03.troy" then
		for i=1, _, enemy in pairs(EnemyTable) do
			if not TargetHaveBuff("varuswdebuff", enemy) then
				ProcStacks[i] = 0
			end
		end
		ProcReady = false
	end
end

function FullCombo()
	local target = AutoCarry.GetAttackTarget()
	local calcenemy = 1
	local EnemysInRange = CountEnemyHeroInRange()

	if not ValidTarget(target) then return true end

	for i=1, heroManager.iCount do
    	local Unit = heroManager:GetHero(i)
    	if Unit.charName == target.charName then
    		calcenemy = i
    	end
   	end

   	if IGNITEReady and killable[calcenemy] == 3 then CastSpell(IGNITESlot, target) end

   	if AutoCarry.PluginMenu.aItems then
   		if BWCReady and (killable[calcenemy] == 2 or killable[calcenemy] == 3) then CastSpell(BWCSlot, target) end
   		if RUINEDKINGReady and (killable[calcenemy] == 2 or killable[calcenemy] == 3) then CastSpell(RUINEDKINGSlot, target) end
   		if RANDUINSReady then CastSpell(RANDUINSSlot) end
   	end

	if EnemysInRange >= 2 or (myHero.health / myHero.maxHealth <= 0.5) or killable[calcenemy] == 2 or killable[calcenemy] == 3  and AutoCarry.PluginMenu.aUlti then
		if ValidTarget(SkillR.range, target) and RReady then CastSkillshot(SkillR, target) end
	end

	if ValidTarget(SkillE.range, target) and EReady then CastSkillshot(SkillE, target) end

	if ValidTarget(SkillQ.range, target) and QReady and myHero:GetDistance(target) > GetTrueRange then CastQ(target) end
end

function Harass()
	local target = AutoCarry.GetAttackTarget()
	local TrueRange = GetTrueRange
	if ValidTarget(target) then
		if AutoCarry.PluginMenu.hwE and EReady and GetDistance(target) <= SkillE.range then CastSkillshot(SkillE, target) end
		if AutoCarry.PluginMenu.hwQ and QReady and GetDistance(target) <= SkillQ.range and GetDistance(target) > TrueRange then CastQ(target) end
	end
	myHero:MoveTo(mousePos.x, mousePos.z)
	CustomAttackEnemy(target)
end

function LaneClear()
	if not EReady then return true end

	for _, minion in pairs(MinionTable) do
		if ValidTarget(SkillE.range, minion) and getDmg("E", minion, myHero) >= minion.health then CastSkillshot(SkillE, minion) end
	end

	for _, minion in pairs(MinionTable) do
		if ValidTarget(SkillE.range, minion) then CastSkillshot(SkillE, minion) end
	end
end

function LastHitE()
	if not EReady then return true end

	local killableMinions = 0
	local Minions = {}

	for _, minion in pairs(MinionTable) do
		if ValidTarget(SkillE, range) and getDmg("E", minion, myHero) >= minion.health then
			killableMinions = killableMinions + 1
			table.insert(Minions, minion)
		end
	end

	if killableMinions >= AutoCarry.PluginMenu.lhEMinions then
		for _, minion in pairs(Minions)
			if ValidTarget(SkillE.range, minion) and EReady then CastSkillshot(SkillE, minion) end
			return
		end
	end
	return
end

function CastEQAuto()
	if not ProcReady then return true end
	TrueRange = GetTrueRange()

	if AutoCarry.PluginMenu.tryPrioritizeQ and QReady then
		for i=1, _, enemy in pairs(EnemyTable) do
			if ProcStacks[i] >= AutoCarry.PluginMenu.aQEWS and ValidTarget(SkillQ.range, enemy) then
				CastQ(enemy)
			end
		end
	elseif (not AutoCarry.PluginMenu.tryPrioritizeQ and EReady) or (AutoCarry.PluginMenu.tryPrioritizeQ and not QReady and EReady) and GetTickCount() > Tick + (AutoCarry.PluginMenu.waitDelay + 1000) then
		for i=1, _, enemy in pairs(EnemyTable) do
			if ProcStacks[i] >= AutoCarry.PluginMenu.aQEWS and ValidTarget(SkillE.range, enemy) and GetDistance(enemy) > TrueRange then
				CastSkillshot(SkillE, enemy)
			end
		end
	end
end

function CastQ(Unit)
	QPred = qp:GetPrediction(Unit)

	if QPred and not Cast and GetTickCount() - Tick > AutoCarry.PluginMenu.waitDelay then
		CastSpell(_Q, QPred.x, QPred.z)
		Tick = GetTickCount()
		Cast = true
	end

	if QPred and Cast and GetTickCount() - Tick > AutoCarry.PluginMenu.waitDelay then
		PQ2 = CLoLPacket(0xE6)
		PQ2:EncodeF(myHero.networkID)
		PQ2:Encode1(128)
		PQ2:EncodeF(QPred.x)
		PQ2:EncodeF(QPred.y)
		PQ2:EncodeF(QPred.z)
		PQ2.dwArg1 = 1
		PQ2.dwArg2 = 0
		SendPacket(PQ2)
		Tick = GetTickCount()
		Cast = false	
	end
end

function JungleClear()
	local Priority = nil
	local Target = nil
	local TrueRange = GetTrueRange()
	for _, mob in pairs(AutoCarry.GetJungleMobs()) do
		if ValidTarget(mob) then
 			if mob.name == "TT_Spiderboss7.1.1"
			or mob.name == "Worm12.1.1"
			or mob.name == "Dragon6.1.1"
			or mob.name == "AncientGolem1.1.1"
			or mob.name == "AncientGolem7.1.1"
			or mob.name == "LizardElder4.1.1"
			or mob.name == "LizardElder10.1.1"
			or mob.name == "GiantWolf2.1.3"
			or mob.name == "GiantWolf8.1.3"
			or mob.name == "Wraith3.1.3"
			or mob.name == "Wraith9.1.3"
			or mob.name == "Golem5.1.2"
			or mob.name == "Golem11.1.2"
			then
				Priority = mob
			else
				Target = mob
			end
		end
	end

	if Priority then
		Target = Priority
	end

	if ValidTarget(Target) then
		if myHero:GetDistance(Target) <= GetTrueRange then CustomAttackEnemy(Target) end
		if myHero:GetDistance(Target) <= SkillE.range and EReady then CastSkillshot(SkillE, Target) end
	end
end

function JungleSteal()
	for _, mob in pairs(AutoCarry.GetJungleMobs()) do
		if ValidTarget(mob, TrueRange) and getDmg("AD",enemy,myHero) >= mob.health then CustomAttackEnemy(mob) end
		if ValidTarget(mob, SpellRangeE) and EReady and (getDmg("E", mob, myHero) >= mob.health) then CastSkillshot(SkillE, mob) end
	end
end

function KS()
	local TrueRange = GetTrueRange()
	for _, enemy in pairs(EnemyTable) do
		if ValidTarget(enemy, 500) and BWCReady and getDmg("BWC", enemy, myHero) >= enemy.health then
			CastSpell(BWCSlot, enemy)
		elseif ValidTarget(enemy, 500) and RUINEDKINGReady and getDmg("RUINEDKING", enemy, myHero) >= enemy.health then
			CastSpell(RUINEDKINGSlot, enemy)
		elseif ValidTarget(enemy, TrueRange) and getDmg("AD", enemy, myHero) >= enemy.health then
			CustomAttackEnemy(enemy)
		elseif ValidTarget(enemy, SkillE.range) and getDmg("E", enemy, myHero) >= enemy.health then
			CastSkillshot(SkillE, enemy)
		elseif ValidTarget(enemy, SkillQ.range) and getDmg("Q", enemy, myHero) >= enemy.health then
			CastQ(enemy)
 		elseif ValidTarget(enemy, SkillR.range) and getDmg("R", enemy, myHero) >= enemy.health then
			CastSkillshot(SkillR, enemy)
		end
	end
	return
end

function SlowNearestEnemy()
	local NearestEnemy = nil
	for _, enemy in pairs(EnemyTable) do
		if ValidTarget(enemy) and NearestEnemy == nil or GetDistance(enemy) < GetDistance(NearestEnemy) then
			NearestEnemy = enemy
		end
	end

	if RANDUINSReady and GetDistance(NearestEnemy) <= 200 then CastSpell(RANDUINSSlot) end

	if EReady then 
		if ValidTarget(NearestEnemy, SkillE.range) then AutoCarry.CastSkillshot(SkillE, NearestEnemy) end
		return
	end

	if RReady and AutoCarry.PluginMenu.swR then
		if ValidTarget(NearestEnemy, SkillR.range) then AutoCarry.CastSkillshot(SkillR, NearestEnemy) end
	end
end

function onChoiceFunction() -- our callback function for the ability leveling
	if myHero:GetSpellData(_E).level < myHero:GetSpellData(_Q).level then
		return 3
	else
		return 1
	end
end

function GetTrueRange()
	return myHero.range + GetDistance(myHero.minBBox)
end

function CustomAttackEnemy(enemy)
	myHero:Attack(enemy)
	AutoCarry.shotFired = true
end

function CooldownHandler()
	RUINEDKINGSlot, QUICKSILVERSlot, RANDUINSSlot, BWCSlot = GetInventorySlotItem(3153), GetInventorySlotItem(3140), GetInventorySlotItem(3143), GetInventorySlotItem(3144)
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	RUINEDKINGReady = (RUINEDKINGSlot ~= nil and myHero:CanUseSpell(RUINEDKINGSlot) == READY)
	QUICKSILVERReady = (QUICKSILVERSlot ~= nil and myHero:CanUseSpell(QUICKSILVERSlot) == READY)
	RANDUINSReady = (RANDUINSSlot ~= nil and myHero:CanUseSpell(RANDUINSSlot) == READY)
	IGNITEReady = (IGNITESlot ~= nil and myHero:CanUseSpell(IGNITESlot) == READY)
	CLEANSEReady = (CLEANSESlot ~= nil and myHero:CanUseSpell(CLEANSESlot) == READY)
end

function DMGCalculation()
	for i=1, heroManager.iCount do
        local Unit = heroManager:GetHero(i)
        if ValidTarget(Unit) then
        	local RUINEDKINGDamage, IGNITEDamage, BWCDamage = 0, 0, 0
        	local QDamage = getDmg("Q",Unit,myHero)
			local WDamage = getDmg("W",Unit,myHero)
			local EDamage = getDmg("E",Unit,myHero)
			local RDamage = getDmg("R", Unit, myHero)
			local HITDamage = getDmg("AD",Unit,myHero)
			local IGNITEDamage = (IGNITESlot and getDmg("IGNITE",Unit,myHero) or 0)
			local BWCDamage = (BWCSlot and getDmg("BWC",Unit,myHero) or 0)
			local RUINEDKINGDamage = (RUINEDKINGSlot and getDmg("RUINEDKING",Unit,myHero) or 0)
			local combo1 = HITDamage
			local combo2 = HITDamage
			local combo3 = HITDamage
			local mana = 0

			if QReady then
				combo1 = combo1 + QDamage
				combo2 = combo2 + QDamage
				combo3 = combo3 + QDamage
				mana = mana + myHero:GetSpellData(_Q).mana
			end

			if WReady then
				combo1 = combo1 + WDamage
				combo2 = combo2 + WDamage
				combo3 = combo3 + WDamage
				mana = mana + myHero:GetSpellData(_W).mana
			end

			if EReady then
				combo1 = combo1 + EDamage
				combo2 = combo2 + EDamage
				combo3 = combo3 + EDamage
				mana = mana + myHero:GetSpellData(_E).mana
			end

			if RReady then
				combo2 = combo2 + RDamage
				combo3 = combo3 + RDamage
				mana = mana + myHero:GetSpellData(_R).mana
			end

			if BWCReady then
				combo2 = combo2 + BWCDamage
				combo3 = combo3 + BWCDamage
			end

			if RUINEDKINGReady then
				combo2 = combo2 + RUINEDKINGDamage
				combo3 = combo3 + RUINEDKINGDamage
			end

			if IGNITEReady then
				combo3 = combo3 + IGNITEDamage
			end

			killable[i] = 1 -- the default value = harass

			if (combo3 >= Unit.health) and (myHero.mana >= mana) then -- all cooldowns needed
				killable[i] = 2
			end

			if (combo2 >= Unit.health) and (myHero.mana >= mana) then -- only spells + ulti and items needed
				killable[i] = 3
			end

			if (combo1 >= Unit.health) and (myHero.mana >= mana) then -- only spells but no ulti needed
				killable[i] = 4
			end
		end
	end
end
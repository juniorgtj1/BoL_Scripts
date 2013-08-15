require "AoE_Skillshot_Position"

local QReady, WReady, EReady, RReady, IGNITEReady, DFGReady = nil, nil, nil, nil, nil, nil
local IGNITESlot, DFGSlot, LIANDRYSSlot = nil, nil, nil
local RangeQ, RangeW, RangeR, RangeR, RangeAD = 900, 900, 625, 750
local QSpeed, QDelay, QWidth, WSpeed, WDelay, WWidth = 1200, 180, 80, 20, 0.5, 0
local SkillQ = {spellKey = _Q, range = RangeQ, speed = QSpeed, delay = QDelay, width = QWidth}
local SkillW =  {spellKey = _W, range = RangeW, speed = QSpeed, delay = QDelay, width = QWidth}
local floattext = {"Harass him","Fight him","Kill him","Murder him"}
local killable = {}
local waittxt = {}

function PluginOnLoad()
	AutoCarry.PluginMenu:addParam("draw", "Draw Circles/Text", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("smartW", "Smart W in Team Fights", SCRIPT_PARAM_ONOFF, true)

	IGNITESlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
	for i=1, heroManager.iCount do waittxt[i] = i*3 end
	AutoCarry.SkillsCrosshair.range = RangeQ
end

function PluginOnTick()
	CDHandler()
	DMGCalculation()
	if AutoCarry.MainMenu.AutoCarry then Combo() end
end

function PluginOnDraw()
	if not myHero.dead and AutoCarry.PluginMenu.draw then
		for i=1, heroManager.iCount do
			local Unit = heroManager:GetHero(i)
			if ValidTarget(Unit) then
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

function Combo()
	local Target = AutoCarry.GetAttackTarget(true)
	local EnemysInRange = CountEnemyHeroInRange()
	local calcenemy = 1
	local Blazed = false

	if not ValidTarget(Target) then return true end

	for i=1, heroManager.iCount do
    	local Unit = heroManager:GetHero(i)
    	if Unit.charName == Target.charName then
    		calcenemy = i
    	end
   	end

   	if TargetHaveParticle("BrandBlaze_hotfoot.troy", Target, RangeQ) then
   		Blazed = true
   	end

	if EReady then CastSpell(_E, Target) end
	if QReady and Blazed and not AutoCarry.GetCollision(SkillQ, myHero, Target) then AutoCarry.CastSkillshot(SkillQ, Target) end
	if WReady and AutoCarry.PluginMenu.smartW and EnemysInRange >= 2 then
		Pos = GetAoESpellPosition(250, Target)
		CastSpell(_W, Pos.x, Pos.z)
	else
		AutoCarry.CastSkillshot(SkillW, Target)
	end
	if RReady and Blazed and (killable[calcenemy] == 2 or killable[calcenemy] == 3 or EnemysInRange >= 2) then
		CastSpell(_R, Target)
	end
end

function CDHandler()
	DFGSlot, LIANDRYSSlot = GetInventorySlotItem(3128), GetInventorySlotItem(3151)
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	IGNITEReady = (IGNITESlot ~= nil and myHero:CanUseSpell(IGNITESlot) == READY)
	DFGReady = (DFGSlot ~= nil and myHero:CanUseSpell(DFGSlot) == READY)
end

function DMGCalculation()
	for i=1, heroManager.iCount do
        local Unit = heroManager:GetHero(i)
        if ValidTarget(Unit) then
        	local DFGDamage, LIANDRYSDamage, IGNITEDamage = 0, 0, 0
        	local QDamage = getDmg("Q",Unit,myHero)
			local WDamage = getDmg("W",Unit,myHero)
			local EDamage = getDmg("E",Unit,myHero)
			local RDamage = getDmg("R",Unit,myHero)
			local HITDamage = getDmg("AD",Unit,myHero)
			local ONSPELLDamage = (LIANDRYSSlot and getDmg("LIANDRYS",Unit,myHero) or 0)
			local IGNITEDamage = (IGNITESlot and getDmg("IGNITE",Unit,myHero) or 0)
			local DFGDamage = (DFGSlot and getDmg("DFG",Unit,myHero) or 0)
			local combo1 = HITDamage + ONSPELLDamage
			local combo2 = HITDamage + ONSPELLDamage
			local combo3 = HITDamage + ONSPELLDamage
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

			if DFGReady then
				combo2 = combo2 + DFGDamage
				combo3 = combo3 + DFGDamage
			end

			if IGNITEReady then
				combo3 = combo3 + IGNITEDamage
			end

			killable[i] = 1

			if (combo3 >= Unit.health) and (myHero.mana >= mana) then
				killable[i] = 2
			end

			if (combo2 >= Unit.health) and (myHero.mana >= mana) then
				killable[i] = 3
			end

			if (combo1 >= Unit.health) and (myHero.mana >= mana) then
				killable[i] = 4
			end
	end
end
end
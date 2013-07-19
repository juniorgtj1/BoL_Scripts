--[[ Varus Auto Carry Plugin ]]--

--[[ Variables ]]--
local HK1 = string.byte("Y") -- Harass
local HK2 = string.byte("N") -- jungle clearing

--->>> Do not touch anything below here <<<---

local SkillQ = {spellKey = _Q, range = 1600, speed = 1.85, delay = 0, width = 60}
local SkillE = {spellKey = _E, range = 925, speed = 1.5, delay = 242, width = 100}
local SkillR = {spellKey = _R, range = 1190, speed = 1.95, delay = 250 , width = 80}
local levelSequence = {nil,0,1,3,3,4,3,1,3,1,4,1,1,2,2,4,2,2} -- we level the spells that way, first point free choice; W or E
local floattext = {"Harass him","Fight him","Kill him","Murder him"} -- text assigned to enemys
local killable = {} -- our enemy array where stored if people are killable
local waittxt = {} -- prevents UI lags, all credits to Dekaron
local QReady, WReady, EReady, RReady, RUINEDKINGReady, QUICKSILVERReady, RANDUINSReady, IGNITEReady 

--[[ Core]]--
function PluginOnLoad()
	AutoCarry.PluginMenu:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, HK1) -- harass
	AutoCarry.PluginMenu:addParam("jungle", "Jungle clearing", SCRIPT_PARAM_ONKEYTOGGLE, false, HK2) -- jungle clearing

	-- Settings
	AutoCarry.PluginMenu:addParam("lcSkills", "Use Skills with Lane Clear mode", SCRIPT_PARAM_ONOFF, true) -- spamming q/w/e on the minions while lane clearing
	AutoCarry.PluginMenu:addParam("aUlti", "Use Ulti in Full Combo", SCRIPT_PARAM_ONOFF, true) -- decide if ulti should be used in full combo
	AutoCarry.PluginMenu:addParam("aItems", "Use Items in Full Combo", SCRIPT_PARAM_ONOFF, true) -- decide if items should be used in full combo
	AutoCarry.PluginMenu:addParam("aIGN", "Auto Ignite", SCRIPT_PARAM_ONOFF, true) -- decide if summoner spells should be used automatic
	AutoCarry.PluginMenu:addParam("hwQ", "Harass with Q", SCRIPT_PARAM_ONOFF, true) -- Harass with Q
	AutoCarry.PluginMenu:addParam("hwE", "Harass with E", SCRIPT_PARAM_ONOFF, true) -- Harass with E
	AutoCarry.PluginMenu:addParam("aSkills", "Auto Level Skills (Requires Reload)", SCRIPT_PARAM_ONOFF, true) -- auto level skills
	AutoCarry.PluginMenu:addParam("lhE", "Last hit with E", SCRIPT_PARAM_ONOFF, true) -- Last hit with E
	AutoCarry.PluginMenu:addParam("lhEM", "Last hit until Mana", SCRIPT_PARAM_SLICE, 50, 0, 100, 2)
	AutoCarry.PluginMenu:addParam("ks", "KS with all Skills", SCRIPT_PARAM_ONOFF, true) -- KS with Q

	-- Visual
	AutoCarry.PluginMenu:addParam("draw", "Draw Circles", SCRIPT_PARAM_ONOFF, false) -- Draw Circles

	-- perma show HK1-4
	AutoCarry.PluginMenu:permaShow("harass")
	AutoCarry.PluginMenu:permaShow("jungle")


	if AutoCarry.PluginMenu.aSkills then -- setup the skill autolevel
		autoLevelSetSequence(levelSequence)
		autoLevelSetFunction(onChoiceFunction) -- add the callback to choose the first skill
	end

	IGNITESlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil) -- do we have ignite?
	
	for i=1, heroManager.iCount do waittxt[i] = i*3 end -- All credits to Dekaron

	AutoCarry.SkillsCrosshair.range = SpellRangeQ
end

function PluginOnTick()
	CooldownHandler()
end

function onChoiceFunction() -- our callback function for the ability leveling
	if myHero:GetSpellData(_W).level < myHero:GetSpellData(_E).level then
		return 2
	else
		return 3
	end
end

function CooldownHandler()
	RUINEDKINGSlot, QUICKSILVERSlot, RANDUINSSlot = GetInventorySlotItem(3153), GetInventorySlotItem(3140), GetInventorySlotItem(3143)
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	RUINEDKINGReady = (RUINEDKINGSlot ~= nil and myHero:CanUseSpell(RUINEDKINGSlot) == READY)
	QUICKSILVERReady = (QUICKSILVERSlot ~= nil and myHero:CanUseSpell(QUICKSILVERSlot) == READY)
	RANDUINSReady = (RANDUINSSlot ~= nil and myHero:CanUseSpell(RANDUINSSlot) == READY)
	IGNITEReady = (IGNITESlot ~= nil and myHero:CanUseSpell(IGNITESlot) == READY)
end

function DMGCalculation()
	for i=1, heroManager.iCount do
        local Unit = heroManager:GetHero(i)
        if ValidTarget(Unit) then
        	local RUINEDKINGDamage, IGNITEDamage = 0, 0
        	local QDamage = getDmg("Q",Unit,myHero)
			local WDamage = getDmg("W",Unit,myHero)
			local EDamage = getDmg("E",Unit,myHero)
			local RDamage = getDmg("R", Unit, myHero)
			local HITDamage = getDmg("AD",Unit,myHero)
			local IGNITEDamage = (IGNITESlot and getDmg("IGNITE",Unit,myHero) or 0)
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
				combo1 = combo1 + RDamage
				combo2 = combo2 + RDamage
				combo3 = combo3 + RDamage
				mana = mana + myHero:GetSpellData(_E).mana
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

			if (combo2 >= Unit.health) and (myHero.mana >= mana) then -- only spells and items needed
				killable[i] = 3
			end

			if (combo1 >= Unit.health) and (myHero.mana >= mana) then -- only spells needed
				killable[i] = 4
			end
		end
	end
end
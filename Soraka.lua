if myHero.charName ~= "Soraka" then return end

local QReady, WReady, EReady, RReady, IGNITEReady, EXHAUSTReady = nil, nil, nil, nil, nil, nil
local RangeQ, RangeW, RangeE = 530, 750, 725
local IGNITESlot, EXHAUSTSlot = nil, nil
local ts
local allyTable
local enemyTable
local ToInterrupt = {}
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
local priorityTable = {
	AP = {
		"Annie", "Ahri", "Akali", "Anivia", "Annie", "Brand", "Cassiopeia", "Diana", "Evelynn", "FiddleSticks", "Fizz", "Gragas", "Heimerdinger", "Karthus",
		"Kassadin", "Katarina", "Kayle", "Kennen", "Leblanc", "Lissandra", "Lux", "Malzahar", "Mordekaiser", "Morgana", "Nidalee", "Orianna",
		"Rumble", "Ryze", "Sion", "Swain", "Syndra", "Teemo", "TwistedFate", "Veigar", "Viktor", "Vladimir", "Xerath", "Ziggs", "Zyra", "MasterYi", "Yasuo",
	},
	Support = {
		"Alistar", "Blitzcrank", "Janna", "Karma", "Leona", "Lulu", "Nami", "Nunu", "Sona", "Soraka", "Taric", "Thresh", "Zilean",
	},
 
	Tank = {
		"Amumu", "Chogath", "DrMundo", "Galio", "Hecarim", "Malphite", "Maokai", "Nasus", "Rammus", "Sejuani", "Shen", "Singed", "Skarner", "Volibear",
		"Warwick", "Yorick", "Zac",
	},
 
	AD_Carry = {
		"Ashe", "Caitlyn", "Corki", "Draven", "Ezreal", "Graves", "Jayce", "KogMaw", "Lucian", "MissFortune", "Pantheon", "Quinn", "Shaco", "Sivir",
		"Talon", "Tristana", "Twitch", "Urgot", "Varus", "Vayne", "Zed", "Lucian", "Jinx",
	},
 
	Bruiser = {
		"Aatrox", "Darius", "Elise", "Fiora", "Gangplank", "Garen", "Irelia", "JarvanIV", "Jax", "Khazix", "LeeSin", "Nautilus", "Nocturne", "Olaf", "Poppy",
		"Renekton", "Rengar", "Riven", "Shyvana", "Trundle", "Tryndamere", "Udyr", "Vi", "MonkeyKing", "XinZhao",
	},
}

function OnLoad()
	Config = scriptConfig("Soraka", "Soraka")
	Config:addParam("combo", "Silence/Exhaust/Attack Target", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("interrupt", "Interrupt with E", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("printInterrupt", "Print Interrupts", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("autoIGN", "Auto Ignite", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("useQ", "Use Q to harass", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("useE", "Use E on ally", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("minEmana", "Min. E ally mana", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
	Config:addParam("autoR", "Use R", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("minRhealth", "Min. R health limit", SCRIPT_PARAM_SLICE, 15, 0, 100, 0)
	Config:permaShow("combo")

	ts = TargetSelector(TARGET_PRIORITY, RangeE, DAMAGE_MAGIC)
	ts.name = "Soraka"
	Config:addTS(ts)

	IGNITESlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
	EXHAUSTSlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerExhaust") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerExhaust") and SUMMONER_2) or nil)
	
	allyTable = GetAllyHeroes()
	table.insert(allyTable, myHero)

	enemyTable = GetEnemyHeroes()

	for _, enemy in pairs(enemyTable) do
		for _, champ in pairs(InterruptList) do
			if enemy.charName == champ.charName then
				table.insert(ToInterrupt, champ.spellName)
			end
		end
	end

	if heroManager.iCount < 10 then -- borrowed from Sidas Auto Carry
		PrintChat(" >> Too few champions to arrange priority")
	else
		arrangePrioritys()
	end
end

function OnTick()
	CDHandler()
	if Config.autoIGN then AutoIgnite() end
	if Config.autoR then CastR() end
	if Config.useW then CastW() end
	if Config.useQ then CastQ() end
	if Config.useE and not Config.combo then CastE() end
	if Config.combo then Combo() end
end

function CastR()
	if not RReady then return end

	for i=1, #allyTable do
		local Ally = allyTable[i]

		if Ally.health/Ally.maxHealth <= Config.minRhealth/100 then
			CastSpell(_R)
		end
	end
end

function CastW()
	if not WReady then return end

	local HealAmount = myHero:GetSpellData(_W).level*70 + myHero.ap*0.45
	local LowestHealth = nil

	for i=1, #allyTable do
		local Ally = allyTable[i]

		if LowestHealth and LowestHealth.valid and Ally and Ally.valid then
			if Ally.health < LowestHealth.health and RangeW >= myHero:GetDistance(Ally) and (Ally.health + HealAmount) <= Ally.maxHealth then
				LowestHealth = Ally
			end
		else
			LowestHealth = Ally
		end
	end

	if LowestHealth and LowestHealth.valid and RangeW >= myHero:GetDistance(LowestHealth) and (LowestHealth.health + HealAmount) <= LowestHealth.maxHealth then
		CastSpell(_W, LowestHealth)
	end
end

function CastQ()
	if not QReady then return end

	for i=1, #enemyTable do
		local Enemy = enemyTable[i]

		if ValidTarget(Enemy, RangeQ) then
			CastSpell(_Q)
		end
	end
end

function CastE()
	if not EReady then return end

	local LowestMana = nil

	for i=1, #allyTable do
		local Ally = allyTable[i]

		if LowestMana and LowestMana.valid and Ally and Ally.valid then
			if Ally.mana < LowestMana.mana and RangeE >= myHero:GetDistance(Ally) and myHero.networkID ~= Ally.networkID then
				LowestMana = Ally
			end
		else
			LowestMana = Ally
		end
	end

	if LowestMana and LowestMana.valid and RangeE >= myHero:GetDistance(LowestMana) and LowestMana.mana/LowestMana.maxMana <= Config.minEmana/100 then CastSpell(_E, LowestMana) end
end

function Combo()
	ts:update()
	if not ts.target then return end

	if ValidTarget(ts.target, RangeE) then
		if QReady then CastSpell(_Q) end
		if EReady then CastSpell(_E, ts.target) end
		if EXHAUSTReady and myHero:GetDistance(ts.target) <= 550 then CastSpell(EXHAUSTSlot, ts.target) end
		if (myHero.range + myHero:GetDistance(myHero.minBBox)) >= myHero:GetDistance(ts.target) then myHero:Attack(ts.target) end
	end
end

function OnProcessSpell(unit, spell)
	if #ToInterrupt > 0 and Config.interrupt and EReady then
		for _, ability in pairs(ToInterrupt) do
			if spell.name == ability and unit.team ~= myHero.team then
				if RangeE >= myHero:GetDistance(unit) then
					CastSpell(_E, unit)
					if Config.printInterrupt then print("Tried to interrupt " .. spell.name) end
				end
			end
		end
	end
end

function CDHandler()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	IGNITEReady = (IGNITESlot ~= nil and myHero:CanUseSpell(IGNITESlot) == READY)
	EXHAUSTReady = (EXHAUSTSlot ~= nil and myHero:CanUseSpell(EXHAUSTSlot) == READY)
end

function AutoIgnite()
	if not IGNITEReady then return end

	for i=1, #enemyTable do
		local Enemy = enemyTable[i]

		if ValidTarget(Enemy, 600) then
			if getDmg("IGNITE", Enemy, myHero) >= Enemy.health then
				CastSpell(IGNITESlot, Enemy)
			end
		end
	end
end

function SetPriority(table, hero, priority)
	for i=1, #table, 1 do
		if hero.charName:find(table[i]) ~= nil then
			TS_SetHeroPriority(priority, hero.charName)
		end
	end
end
 
function arrangePrioritys()
	for i, enemy in ipairs(enemyTable) do
		SetPriority(priorityTable.AD_Carry, enemy, 1)
		SetPriority(priorityTable.AP, enemy, 2)
		SetPriority(priorityTable.Support, enemy, 3)
		SetPriority(priorityTable.Bruiser, enemy, 4)
		SetPriority(priorityTable.Tank, enemy, 5)
	end
end
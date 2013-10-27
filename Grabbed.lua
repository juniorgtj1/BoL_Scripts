if myHero.charName ~= "Blitzcrank" or not VIP_USER then return end
require 'Collision'
require 'Prodiction'

local RangeAD, RangeQ, RangeR = 175, 1050, 600
local QReady, WReady, EReady, RReady, IGNITEReady = nil, nil, nil, nil, nil
local QSpeed, QDelay, QWidth = 1800, 0.25, 90
local IGNITESlot = nil
local ts
local enemyHeroes
local pd, qp, QCol
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
		"Rumble", "Ryze", "Sion", "Swain", "Syndra", "Teemo", "TwistedFate", "Veigar", "Viktor", "Vladimir", "Xerath", "Ziggs", "Zyra", "MasterYi",
	},
	Support = {
		"Alistar", "Blitzcrank", "Janna", "Karma", "Leona", "Lulu", "Nami", "Nunu", "Sona", "Soraka", "Taric", "Thresh", "Zilean",
	},
 
	Tank = {
		"Amumu", "Chogath", "DrMundo", "Galio", "Hecarim", "Malphite", "Maokai", "Nasus", "Rammus", "Sejuani", "Shen", "Singed", "Skarner", "Volibear",
		"Warwick", "Yorick", "Zac",
	},
 
	AD_Carry = {
		"Ashe", "Caitlyn", "Corki", "Draven", "Ezreal", "Graves", "Jayce", "Jinx", "KogMaw", "Lucian", "MissFortune", "Pantheon", "Quinn", "Shaco", "Sivir",
		"Talon", "Tristana", "Twitch", "Urgot", "Varus", "Vayne", "Zed",
	},
 
	Bruiser = {
		"Aatrox", "Darius", "Elise", "Fiora", "Gangplank", "Garen", "Irelia", "JarvanIV", "Jax", "Khazix", "LeeSin", "Nautilus", "Nocturne", "Olaf", "Poppy",
		"Renekton", "Rengar", "Riven", "Shyvana", "Trundle", "Tryndamere", "Udyr", "Vi", "MonkeyKing", "XinZhao",
	},
}

function OnLoad()
	Config = scriptConfig("Grabbed", "Grabbed")
	Config:addParam("combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("ksR", "KS with R", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("interrupt", "Interrupt with R", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("printInterrupt", "Print Interrupts", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("autoIGN", "Auto Ignite", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("drawCol", "Draw Collision", SCRIPT_PARAM_ONOFF, true)
	Config:permaShow("combo")

	ts = TargetSelector(TARGET_LOW_HP_PRIORITY, RangeQ, DAMAGE_MAGIC or DAMAGE_PHYSICAL)
	ts.name = "Blitzcrank"
	Config:addTS(ts)

	IGNITESlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)

	enemyHeroes = GetEnemyHeroes()

	pd = ProdictManager.GetInstance()
	QCol = Collision(RangeQ, QSpeed, QDelay, QWidth)
	qp = pd:AddProdictionObject(_Q, RangeQ, QSpeed, QDelay, QWidth, myHero, function(unit, pos, castSpell) if QReady and GetDistance(unit) < RangeQ then CastSpell(_Q, pos.x, pos.z) end end)

	for _, enemy in pairs(enemyHeroes) do
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
	ts:update()
	CDHandler()
	if Config.autoIGN then AutoIgnite() end
	if Config.ksR then KSR() end
	if Config.combo then Combo() end
end

function OnDraw()
	if ts.target and Config.drawCol then QCol:DrawCollision(myHero, ts.target) end
end

function OnProcessSpell(unit, spell)
	if #ToInterrupt > 0 and Config.interrupt and RReady then
		for _, ability in pairs(ToInterrupt) do
			if spell.name == ability and unit.team ~= myHero.team then
				if RangeR >= GetDistance(unit) then
					CastSpell(_R)
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
end

function AutoIgnite()
	if not IGNITEReady then return end

	for _, enemy in pairs(enemyHeroes) do
		if ValidTarget(enemy, 600) then
			if getDmg("IGNITE", enemy, myHero) >= enemy.health then
				CastSpell(IGNITESlot, enemy)
			end
		end
	end
end

function KSR()
	if not RReady then return end

	for _, enemy in pairs(enemyHeroes) do
		if ValidTarget(enemy, RangeR) then
			if getDmg("R", enemy, myHero) >= enemy.health then
				CastSpell(_R)
			end
		end
	end
end

function Combo()
	if not ts.target then return end

	local Distance = GetDistance(ts.target)

	if RangeQ >= Distance and RangeAD < Distance then
		CastQ(ts.target)
	end

	if RangeAD >= Distance then
		if EReady and Config.useE then CastSpell(_E, ts.target) end
		if WReady and Config.useW then CastSpell(_W) end
		myHero:Attack(ts.target)
	end
end

function CastQ(Unit)
	local MinionCol = QCol:GetMinionCollision(myHero, Unit)

	if not MinionCol and RangeQ >= GetDistance(Unit) then
		qp:EnableTarget(Unit, true)
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
	for i, enemy in ipairs(enemyHeroes) do
		SetPriority(priorityTable.AD_Carry, enemy, 1)
		SetPriority(priorityTable.AP, enemy, 2)
		SetPriority(priorityTable.Support, enemy, 3)
		SetPriority(priorityTable.Bruiser, enemy, 4)
		SetPriority(priorityTable.Tank, enemy, 5)
	end
end
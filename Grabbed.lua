if myHero.charName ~= "Blitzcrank" or not VIP_USER then return end

local RangeAD, RangeQ, RangeR = 175, 925, 600
local QReady, WReady, EReady, RReady, IGNITEReady = nil, nil, nil, nil, nil
local QSpeed, QDelay, QWidth = 1800, 0.25, 120
local IGNITESlot = nil
local ts
local enemyHeroes
local enemyMinions
local QPred
local Col

function OnLoad()
	Config = scriptConfig("Grabbed", "Grabbed")
	Config:addParam("combo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Config:addParam("ksR", "KS with R", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("autoIGN", "Auto Ignite", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("drawCol", "Draw Collision", SCRIPT_PARAM_ONOFF, true)
	Config:addParam("drawTS", "Draw Target", SCRIPT_PARAM_ONOFF, false)
	Config:addParam("QHitChance", "Min. Q Hit Chance", SCRIPT_PARAM_SLICE, 70, 0, 100, 0)
	Config:permaShow("combo")

	ts = TargetSelector(TARGET_LOW_HP, RangeQ, DAMAGE_MAGIC or DAMAGE_PHYSICAL)
	ts.name = "Blitzcrank"
	Config:addTS(ts)

	IGNITESlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)

	enemyHeroes = GetEnemyHeroes()
	enemyMinions = minionManager(MINION_ENEMY, RangeQ, myHero)

	QPred = TargetPredictionVIP(RangeQ, QSpeed, QDelay, QWidth)
	QCol = Collision(RangeQ, QSpeed, QDelay, QWidth)
end

function OnTick()
	ts:update()
	enemyMinions:update()
	CDHandler()
	if Config.autoIGN then AutoIgnite() end
	if Config.ksR then KSR() end
	if Config.combo then Combo() end
end

function OnDraw()
	if ts.target then
		if Config.drawCol then QCol:DrawCollision(myHero, ts.target) end

		if Config.drawTS then
			DrawText("Target: " .. ts.target.charName, 15, 100, 100, 0xFFFF0000)
			DrawCircle(ts.target.x, ts.target.y, ts.target.z, 100, 0x00FF00)
		end
	 end
end

function CDHandler()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady= (myHero:CanUseSpell(_W) == READY)
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

	if RangeQ >= Distance then
		CastQ(ts.target)
	end

	if RangeAD >= Distance then
		if EReady and Config.useE then CastSpell(_E, ts.target) end
		if WReady and Config.useW then CastSpell(_W) end
	end
end

function CastQ(Unit)
	local HitChance = QPred:GetHitChance(Unit)
	local Position = QPred:GetPrediction(Unit)
	local MinionCol = QCol:GetMinionCollision(myHero, Unit)

	if not MinionCol and HitChance > Config.QHitChance/100 then
		if Position and RangeQ >= GetDistance(Position) then
			CastSpell(_Q, Position.x, Position.z)
		end
	end
end
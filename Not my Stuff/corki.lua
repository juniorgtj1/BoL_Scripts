---------------------#####################################################---------------------
---------------------##										 Corki												##---------------------
---------------------##								Death from Above									##---------------------
---------------------#####################################################---------------------

function PluginOnLoad()
	AutoCarry.SkillsCrosshair.range = 1300
	--> Load
	mainLoad()
	--> Main Menu
	mainMenu()
end

function PluginOnTick()
	Checks()
	--> Barrage
	if Target and (AutoCarry.MainMenu.AutoCarry or AutoCarry.MainMenu.MixedMode) then
		if QREADY and Menu.useQ then castQ(Target) end
		if EREADY and Menu.useE and GetDistance(Target) < eRange then CastSpell(_E) end
		if RREADY and Menu.useR and not Col(SkillR, myHero, Target) then Cast(SkillR, Target) end
	end
	--> Missile KS
	if Menu.missileKS and RREADY then missileKS() end
end

function PluginOnDraw()
	--> Ranges
	if not Menu.drawMaster and not myHero.dead then
		if QREADY and Menu.drawQ then
			DrawCircle(myHero.x, myHero.y, myHero.z, qRange, 0x00FFFF)
		end
		if RREADY and Menu.drawR then
			DrawCircle(myHero.x, myHero.y, myHero.z, rRange, 0x00FF00)
		end
	end
end

function PluginOnProcessSpell(unit, spell)
	if unit.isMe and spell.name == "MissileBarrage" then
		missileCount = missileCount + 1
	end
end

--> Phosphorus Bomb Cast
function castQ(target)
	qPred = AutoCarry.GetPrediction(SkillQ, target)
	if qPred and GetDistance(qPred) <= qRange then
		if GetDistance(qPred) > 600 then
			Distance = GetDistance(qPred) - 600
			TargetPos = Vector(qPred.x, qPred.y, qPred.z)
			MyPos = Vector(myHero.x, myHero.y, myHero.z)
			qPred2 = TargetPos + (TargetPos-MyPos)*((-Distance/GetDistance(qPred)))
			CastSpell(_Q, qPred2.x, qPred2.z)
		else 
			CastSpell(_Q, qPred.x, qPred.z)
		end
	end
end

--> Missile KS
function missileKS()
	for i, enemy in ipairs(GetEnemyHeroes()) do
		local rDmg = nil
		if missileCount == 2 then rDmg = getDmg("R", enemy, myHero)*1.5 
			else rDmg = getDmg("R", enemy, myHero) 
		end
		if enemy and not enemy.dead and enemy.health < rDmg and not Col(SkillR, myHero, enemy) then
			Cast(SkillR, enemy)
		end
	end
end


--> Checks
function Checks()
	Target = AutoCarry.GetAttackTarget()
	if missileCount > 2 then missileCount = 0 end
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
end

--> Main Load
function mainLoad()
	qRange, eRange, rRange = 837.5, 600, 1225
	QREADY, WREADY, RREADY = false, false, false
	missileCount = 0
	SkillQ = {spellKey = _Q, range = qRange, speed = math.huge, delay = 200, width = 475}
	SkillR = {spellKey = _R, range = rRange, speed = 2.0, delay = 175, width = 40}
	Menu = AutoCarry.PluginMenu
	Cast = AutoCarry.CastSkillshot
	Col = AutoCarry.GetCollision
end

--> Main Menu
function mainMenu()
	Menu:addParam("sep1", "-- Load Out Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("useQ", "Load Phosphorus Bombs", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useE", "Fire Gatling Gun", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("useR", "Prep Missile Barrage", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("sep2", "-- Cast Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("missileKS", "Missile - Kill Steal", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("sep3", "-- Draw Options --", SCRIPT_PARAM_INFO, "")
	Menu:addParam("drawMaster", "Disable Draw", SCRIPT_PARAM_ONOFF, false)
	Menu:addParam("drawQ", "Draw - Phosphorus Bombs", SCRIPT_PARAM_ONOFF, false)
	Menu:addParam("drawR", "Draw - Missile Barrage", SCRIPT_PARAM_ONOFF, false)
end
-- [[ Ryze script based on iSAC ]] --
-- TODO: seperate ignite/barrier/heal
-- TODO: support exhaust
-- TODO: don't make them scary with e
-- TODO: ability lasthit
-- TEST: auto ability lvl
-- TODO: fix perma show
-- TODO: AA if not orbwalking
-- TODO: ulti if killable
-- TEST: fixxed last hit
-- TEST: ks
-- TODO: finish damaga calc
-- TODO: CDR check
-- TODO: test SE

if myHero.charName ~= "Ryze" then return end -- check if we have to run the script

require "iSAC" -- include the lib

-- [[ Config ]] --
-- set up all hotkeys
local HK1 = 32 -- Full Combo
local HK2 = string.byte("Y") -- Harass
local HK3 = string.byte("X") -- farm
local HK4 = string.byte("C") -- cage nearest enemy
local HK5 = string.byte("V") -- jungle clearing

-- [[ Variables ]] --
local Orbwalker = iOrbWalker(AARange) -- initialize a orbwalker instance
-- add our four spells to iCaster
local QSpell = iCaster(_Q, 650, SPELL_TARGETED)
local WSpell = iCaster(_W, 625, SPELL_TARGETED)
local ESpell = iCaster(_E, 675, SPELL_TARGETED)
local RSpell = iCaster(_R, nil, SPELL_SELF)
local ts = TargetSelector(TARGET_LOW_HP_PRIORITY, ESpell.range, DAMAGE_MAGIC, true) -- initialize the target selector
local Summoners = iSummoners() -- initialize the summoner spells
local Minions = iMinions(ESpell.range) -- initialize the minion class
local qMinions = iMinions(QSpell.range, false) -- initialize the minion class for q'ing
local items = Items() -- initialize item class
local levelSequence = {nil,0,3,1,1,4,1,2,1,2,4,2,2,3,3,4,3,3} -- we level the spells that way, first point free
local AARange = myHero.range

-- [[ Core ]] --
function OnLoad() -- this things happens once the script loads
	Config = scriptConfig("PQRyze - Yet another Ryze script","PQRyze") -- Create a save file

	Config:addParam("fCombo", "Full Combo", SCRIPT_PARAM_ONKEYDOWN, false, HK1) -- full combo
	Config:addParam("harass", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, HK2) -- harass
	Config:addParam("farm", "Farm", SCRIPT_PARAM_ONKEYDOWN, false, HK3) -- farm
	Config:addParam("cage", "Cage nearest enemy", SCRIPT_PARAM_ONKEYDOWN, false, HK4) -- cage
	Config:addParam("jungle", "Jungle clearing", SCRIPT_PARAM_ONKEYDOWN, false, HK5) -- jungle clearing

	Config:addParam("mMarker", "Minion Marker", SCRIPT_PARAM_ONOFF, true) -- marking killable minions
	Config:addParam("orbWalk", "Orb Walking", SCRIPT_PARAM_ONOFF, true) -- orb walking while farming/combo
	Config:addParam("aUlti", "Use Ulti in Full Combo", SCRIPT_PARAM_ONOFF, true) -- decide if ulti should be used in full combo
	Config:addParam("aItems", "Use Items in Full Combo", SCRIPT_PARAM_ONOFF, true) -- decide if items should be used in full combo
	Config:addParam("aSP", "Use Summoner Spells", SCRIPT_PARAM_ONOFF, true) -- decide if summoner spells should be used automatic
	Config:addParam("hwQ", "Harass with Q", SCRIPT_PARAM_ONOFF, true) -- Harass with Q
	Config:addParam("hwE", "Harass with E", SCRIPT_PARAM_ONOFF, true) -- Harass with E
	Config:addParam("hwW", "Harass with W", SCRIPT_PARAM_ONOFF, false) -- Harass with W
	Config:addParam("aSkills", "Auto Level Skills (Requires Reload)", SCRIPT_PARAM_ONOFF, true) -- auto level skills
	Config:addParam("lhQ", "Last hit with Q", SCRIPT_PARAM_ONOFF, true) -- Last hit with Q
	Config:addParam("ks", "KS with all Skills", SCRIPT_PARAM_ONOFF, true) -- KS with Q

	-- perma show HK1-5
	Config:permaShow("fCombo")
	Config:permaShow("harass")
	Config:permaShow("farm")
	Config:permaShow("cage")
	Config:permaShow("jungle")

	ts.name = "Ryze" -- don't know if it's needed but it can't hurt
	Config:addTS(ts) -- add target selector

	Orbwalker:addAA() -- enable auto attacks while orbwalking
	Orbwalker.AARange = AARange -- set auto attack range

	if Config.aSkills then -- setup the skill autolevel
		autoLevelSetSequence(levelSequence)
		autoLevelSetFunction(onChoiceFunction) -- add the callback to choose the first skill
	end

	-- add all items
	items:add("DFG", 3128) -- Deathfire Grasp
	items:add("HXG", 3146) -- Hextech Gunblade
	items:add("SE", 3040) -- Seraph's Embrace
	items:add("LIANDRYS", 3151) -- Liandry's Torment

	print(">> PQRyze - Yet another Ryze script<<") -- say hello
end

function OnTick() -- this things happen with every tick of the script
	if Config.aSP then -- use all summoner spells automatic
		Summoners:AutoAll()
	end

	ts.range = ESpell.range -- set the range of our spells
	ts:update() -- to update the enemies within the range
	items:update() -- update our items

	if items:have(3040) then -- seraphs embrace to save our ass
		items:Use("SE", nil, nil, (function(item, myHero) return (myHero.health / myHero.maxHealth > 0.3) end))
	end

	if not myHero.dead then
		if Config.ks then KS() end -- Get the kill
		if Config.fCombo then FullCombo() end -- run full combo
		if Config.harass then Harass() end -- harass

		if Config.farm then
			Minions:update() -- get the updated minions around us
			Minions:LastHit(AARange) -- and kill them
		end

		if Config.cage then CageNearestEnemy() end -- cage the nearest enemy
		if Config.jungle then ClearJungle() end -- kill jungle mobs with abilities

		if Config.lhQ and not (Config.fCombo or Config.harass or Config.cage or Config.jungle) then
			qMinions:update()
			-- return all minioins and check if q > health
		end
	end
end

function OnDraw()
	if Config.mMarker then -- mark killable minions
		Minions:update()
		Minions:marker(50, 0xFF80FF00, 5)
	end
end

function OnProcessSpell(unit, spell)
	Orbwalker:OnProcessSpell(unit, spell) -- seems like this keeps the "orb walking"
end

function KS()
	for i=1, heroManager.iCount do
		local killableEnemy = heroManager:GetHero(i)
		if ValidTarget(killableEnemy, QSpell.range) and QSpell:Ready() and (getDmg("Q", killableEnemy, myHero) >= killableEnemy.health) then QSpell:Cast(killableEnemy) end
		if ValidTarget(killableEnemy, ESpell.range) and ESpell:Ready() and (getDmg("E", killableEnemy, myHero) >= killableEnemy.health) then ESpell:Cast(killableEnemy) end
		if ValidTarget(killableEnemy, WSpell.range) and WSpell:Ready() and (getDmg("W", killableEnemy, myHero) >= killableEnemy.health) then WSpell:Cast(killableEnemy) end
	end
end

function FullCombo()

	print(CalculateDMG())

	if CalculateDMG >= ts.target.health then
		RSpell:Cast(nil)
	end

	QSpell:Cast(ts.target)
	WSpell:Cast(ts.target)
	ESpell:Cast(ts.target)

	if Config.orbWalk then -- workaround since Orbwalker:OrbWalk don't work
		Orbwalker:Move(mousePos)
		Orbwalker:Attack(ts.target)
	end
end

function Harass()
	-- check with which spells it should harass
	if Config.hwQ then QSpell:Cast(ts.target) end
	if Config.hwE then ESpell:Cast(ts.target) end
	if Config.hwW then WSpell:Cast(ts.target) end

	if Config.orbWalk then -- workaround since Orbwalker:OrbWalk don't work
		Orbwalker:Move(mousePos)
		Orbwalker:Attack(ts.target)
	end
end

function CageNearestEnemy()
	-- body
end

function ClearJungle()
	-- body
end

function onChoiceFunction() -- our callback function for the ability leveling
	if QSpell.spellData.level < WSpell.spellData.level then
		return 1
	else
		return 2
	end
end

function CalculateDMG()
	if ValidTarget(ts.target) then
		local QDamage = getDmg("Q",ts.target,myHero)
		local WDamage = getDmg("W",ts.target,myHero)
		local EDamage = getDmg("E",ts.targetts.target,myHero)
		local HitDamage = getDmg("AD",ts.target,myHero)
		local DFGDamage = if items:have(3128) then items:Dmg(3128, ts.target) else 0 end
		local HXGDamage = if items:have(3146) then items:Dmg(3146, ts.target) else 0 end
		local LIANDRYSDamage = if items:have(3151) then items:Dmg(3151, ts.target) else 0 end
		local PossibleDMG = QDamage+WDamage+EDamage+HitDamage+DFGDamage+HXGDamage+LIANDRYSDamage 
		
		return PossibleDMG
	else
		return nil
	end
end
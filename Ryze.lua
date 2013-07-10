-- [[ Ryze script based on iSAC ]] --
-- TODO: look which spells reset auto attacks
-- TODO: seperate ignite/barrier/heal
-- TODO: don't make them scary with e
-- TODO: ability lasthit
-- TODO: auto ability lvl
-- TODO: fix perma show
-- TODO: AA if not orbwalking
-- TODO: ulti if killable

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
local Minions = iMinions(ESpell.range) -- initialzie the minion class

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

	-- perma show HK1-5
	Config:permaShow("fCombo")
	Config:permaShow("harass")
	Config:permaShow("farm")
	Config:permaShow("cage")
	Config:permaShow("jungle")

	ts.name = "Ryze" -- don't know if it's needed but it can't hurt
	Config:addTS(ts) -- add target selector

	Orbwalker:addAA() -- enable auto attacks while orbwalking
	--Orbwalker:addReset(QSpell.spellData.name)

	print(">>PQRyze - Yet another Ryze script loaded<<") -- say hello
end

function OnTick() -- this things happen with every tick of the script
	AARange = myHero.range + GetDistance(myHero.minBBox) -- what is minBBox
	Orbwalker.AARange = AARange -- set auto attack range

	if Config.aSP then -- use all summoner spells automatic
		Summoners:AutoAll()
	end

	ts.range = ESpell.range -- set the range of our spells
	ts:update() -- to update the enemies within the range
	-- Use items and stuff here, first a basic rotation

	if not myHero.dead then
		if Config.fCombo then FullCombo() end -- run full combo
		if Config.harass then Harass() end -- harass
		if Config.farm then
			Minions:update() -- get the updated minions around us
			iMinions:LastHit(AARange) -- and kill them
		end
		if Config.cage then CageNearestEnemy() end -- cage the nearest enemy
		if Config.jungle then ClearJungle() end -- kill jungle mobs with abilities
	end
end

function OnDraw()
	-- body
end

function OnProcessSpell(unit, spell)
	Orbwalker:OnProcessSpell(unit, spell) -- seems like this keeps the "orb walking"
end

function FullCombo()
	if Config.aUlti and ValidTarget(ts.target) and QSpell:Ready() and WSpell:Ready() and ESpell:Ready() then
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
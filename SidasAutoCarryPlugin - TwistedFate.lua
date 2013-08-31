local EnemyTable
local SelectedCard
local SelectCard
local StackedDeck
local RangeQ, RangeR = 1450, 5500
local NextCardTick

function PluginOnLoad()
	if not VIP_USER then
		PrintChat("Auto Q only works as VIP")
	end

	AutoCarry.PluginMenu:addParam("castQauto", "Cast Q on stunned enemys", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("cardBlue", "Select Blue Card", SCRIPT_PARAM_ONKEYDOWN, false, 226)
	AutoCarry.PluginMenu:addParam("cardRed", "Select Red Card", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("Y"))
	AutoCarry.PluginMenu:addParam("cardGold", "Select Gold Card", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("E"))
	AutoCarry.PluginMenu:addParam("drawCircle", "Draw Q range", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("cardGoldR", "Select Gold Card after R", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("cardGoldAC", "Select Gold Card with Auto Carry", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("cardBlueMM", "Use Blue/Red Card with Mixed Mode", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("L"))
	AutoCarry.PluginMenu:addParam("cardRedMana", "Use Red until Mana", SCRIPT_PARAM_SLICE, 50, 0, 100, 2)
	AutoCarry.PluginMenu:permaShow("castQauto")
	AutoCarry.PluginMenu:permaShow("cardBlueMM")

	AutoCarry.SkillsCrosshair.range = RangeQ
	AutoCarry.OverrideCustomChampionSupport = true

	EnemyTable = GetEnemyHeroes()
	SelectedCard = nil
	SelectCard = nil
	StackedDeck = false
	NextCardTick = 0
end

function PluginOnTick()
	CDHandler()
	if AutoCarry.MainMenu.AutoCarry and AutoCarry.PluginMenu.cardGoldAC then
		SelectCard = "Gold"
	end
	if AutoCarry.MainMenu.MixedMode and AutoCarry.PluginMenu.cardBlueMM then
		SelectFarmCard()
	end
	if AutoCarry.MainMenu.LaneClear then
		SelectCard = "Red"
	end
	PickCard()
end

function PluginOnApplyParticle(unit, particle)
	if unit and unit.isMe then
		local LastCard = "Blue"

		if particle.name == "Cardmaster_stackready.troy" then
			StackedDeck = true
		end
		if particle.name == "Card_Blue.troy" then
			LastCard = "Blue"
		end
		if particle.name == "Card_Red.troy" then
			LastCard = "Red"
		end
		if particle.name == "Card_Yellow.troy" then
			LastCard = "Gold"
		end
		if particle.name == "AnnieSparks.troy" then
			SelectedCard = LastCard
		end
	end
end

function PluginOnDeleteObj(obj)
	if obj.name == "Cardmaster_stackready.troy" and myHero:GetDistance(obj) <= 50 then
		StackedDeck = false
	end

	if obj.name == "Card_Blue.troy" or obj.name == "Card_Red.troy" or obj.name == "Card_Yellow.troy" then
		if SelectedCard ~= "None" then
			SelectedCard = "None"
		end
	end
end

function PluginBonusLastHitDamage(minion)
	local TotalDamage = 0

	if StackedDeck == true then
		TotalDamage = getDmg("E", minion, myHero)
	end

	if SelectedCard == "Blue" or SelectedCard == "Red" or SelectedCard == "Gold" then
		TotalDamage = TotalDamage + getDmg("W", minion, myHero)
	end

	return TotalDamage
end

function PluginOnProcessSpell(unit, spell)
	if unit.isMe and spell.name == "gate" then
		if AutoCarry.PluginMenu.cardGoldR then
			SelectCard = "Gold"
		end
	end
end

function OnGainBuff(unit, buff)
	if unit.team ~= myHero.team and unit.type == "obj_AI_Hero" and AutoCarry.PluginMenu.castQauto and QReady then
		 if ValidTarget(unit, RangeQ) and (buff.type == BUFF_STUN or buff.type == BUFF_ROOT or buff.type == BUFF_KNOCKUP or buff.type == BUFF_SUPPRESS) then
		 	CastSpell(_Q, unit.x, unit.z)
		 end
	end
end

function CDHandler()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
end

function SelectFarmCard()
	local MinionInRange = 0

	for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
		if myHero:GetDistance(minion) <= RangeQ then
			MinionInRange = MinionInRange + 1
		end
 	end

 	if MinionInRange == 0 then return end

	if (myHero.mana/myHero.maxMana)*100 >= AutoCarry.PluginMenu.cardRedMana and MinionInRange >= 2 then
		SelectCard = "Red"
	else
		SelectCard = "Blue"
	end
end

function PickCard()
	if AutoCarry.PluginMenu.cardBlue then
		SelectCard = "Blue"
	end

	if AutoCarry.PluginMenu.cardRed then
		SelectCard = "Red"
	end

	if AutoCarry.PluginMenu.cardGold then
		SelectCard = "Gold"
	end

	if SelectedCard == "Blue" or SelectedCard == "Red" or SelectedCard == "Gold" then
		SelectCard = nil
	end

	if GetTickCount() > NextCardTick then
		if WReady then
			local Name = myHero:GetSpellData(_W).name

			if Name == "PickACard" and SelectCard ~= nil then
				CastSpell(_W)
			end
			if SelectCard == "Blue" and Name == "bluecardlock" then
				CastSpell(_W)
			end
			if SelectCard == "Red" and Name == "redcardlock" then
				CastSpell(_W)
			end
			if SelectCard == "Gold" and Name == "goldcardlock" then
				CastSpell(_W)
			end
		end

		NextCardTick = GetTickCount() + 250
	end
end
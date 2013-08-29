local EnemyTable
local SelectedCard
local SelectBlueCard
local SelectRedCard
local SelectGoldCard
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
	AutoCarry.PluginMenu:addParam("cardBlueMM", "Use Blue Card with Mixed Mode", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("L"))
	AutoCarry.PluginMenu:permaShow("castQ")
	AutoCarry.PluginMenu:permaShow("cardBlueMM")

	AutoCarry.SkillsCrosshair.range = 1450 
	AutoCarry.OverrideCustomChampionSupport = true

	EnemyTable = GetEnemyHeroes()
	SelectedCard = false
	SelectBlueCard = false
	SelectRedCard = false
	SelectGoldCard = false
	StackedDeck = false
	NextCardTick = 0
end

function PluginOnTick()
	CDHandler()
	if AutoCarry.MainMenu.AutoCarry and AutoCarry.PluginMenu.cardGoldAC then
		SelectGoldCard = true
	end
	if AutoCarry.MainMenu.MixedMode and AutoCarry.PluginMenu.cardBlueMM then
		SelectBlueCard = true
	end
	SelectCard()
end

function PluginOnApplyParticle(unit, particle)
	if unit.isMe then
		local LastCard

		if particle.name == "Cardmaster_stackready.troy" then
			StackedDeck = true
		end
		if particle.name == "Card_Blue.troy" then
			LastCard = "Blue"
		end
		if particle.name == "Card_Red.troy" then
			LastCard = "Red"
		end
		if particle.name == "Card_Gold.troy" then
			LastCard = "Gold"
		end
		if particle.name == "AnineSparks.troy" then
			SelectedCard = LastCard
		end
	end
end

function PluginOnDeleteObj(obj)
	if obj.name == "Cardmaster_stackready.troy" and myHero:GetDistance(obj) <= 50 then
		StackedDeck = false
	end

	if obj.name == "Card_Blue.troy" or obj.name == "Card_Red.troy" or obj.name == "Card_Gold.troy" then
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
			SelectGoldCard = true
		end
	end
end

function OnGainBuff(unit, buff)
	if unit.team ~= myHero.team and AutoCarry.PluginMenu.castQauto and QReady then
		 if ValidTarget(unit, RangeQ) and (buff.type == BUFF_STUN or buff.type == BUFF_ROOT or buff.type == BUFF_KNOCKUP or buff.type == BUFF_SUPPRESS) then
		 	CastSpell(_Q, unit.x, unit.z)
		 end
	end
end

function CDHandler()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
end

function SelectCard()
	if AutoCarry.PluginMenu.cardBlue then
		SelectBlueCard = true
	end

	if AutoCarry.PluginMenu.cardRed then
		SelectRedCard = true
	end

	if AutoCarry.PluginMenu.cardGold then
		SelectGoldCard = true
	end

	if not WReady then
		SelectBlueCard = false
		SelectRedCard = false
		SelectGoldCard = false
	end

	if GetTickCount() > NextCardTick then
		if WReady then
			local Name = myHero:GetSpellData(_W).name

			if SelectBlueCard then
				if Name == "bluecardlock" then
					CastSpell(_W)
				elseif Name == "PickACard" then
					CastSpell(_W)
				end 
			end

			if SelectRedCard then
				if Name == "redcardlock" then
					CastSpell(_W)
				elseif Name == "PickACard" then
					CastSpell(_W)
				end 
			end

			if SelectGoldCard then
				if Name == "goldcardlock" then
					CastSpell(_W)
				elseif Name == "PickACard" then
					CastSpell(_W)
				end 
			end
		end

		NextCardTick = GetTickCount() + 250
	end
end
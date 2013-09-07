local EnemyTable
local SelectedCard
local SelectCard
local spellName
local StackedDeck
local RangeQ, RangeR
local Recall
local QReady, WReady, RReady
local Sheen, Lichbane
local SHEENSlot, LICHBANESlot

function PluginOnLoad()
	if not VIP_USER then
		PrintChat("Auto Q only works as VIP")
	end

	AutoCarry.PluginMenu:addParam("castQauto", "Cast Q on stunned enemys", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("cardBlue", "Select Blue Card", SCRIPT_PARAM_ONKEYDOWN, false, 226)
	AutoCarry.PluginMenu:addParam("cardRed", "Select Red Card", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("Y"))
	AutoCarry.PluginMenu:addParam("cardGold", "Select Gold Card", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("E"))
	AutoCarry.PluginMenu:addParam("drawQ", "Draw Q range", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("drawR", "Draw R range on minimap", SCRIPT_PARAM_ONOFF, true)
	AutoCarry.PluginMenu:addParam("drawRQuality", "Circle Quality", SCRIPT_PARAM_SLICE, 1, 1, 10, 0)
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
	Recall = false
	RangeQ = 1450
	RangeR = 5500
	QReady, WReady, RReady = false, false, false
	Sheen, Lichbane = false, false
	SHEENSlot, LICHBANESlot = false, false
end

function PluginOnTick()
	if Recall then return end
	CDHandler()
	if AutoCarry.MainMenu.AutoCarry and AutoCarry.PluginMenu.cardGoldAC then
		SelectCard = "Gold"
	end
	if AutoCarry.MainMenu.MixedMode or AutoCarry.MainMenu.LastHit and AutoCarry.PluginMenu.cardBlueMM then
		SelectFarmCard()
	end
	if AutoCarry.MainMenu.LaneClear then
		if ((myHero.mana/myHero.maxMana)*100) >= AutoCarry.PluginMenu.cardRedMana then
			SelectCard = "Red"
		else
			SelectCard = "Blue"
		end
	end
	if (not AutoCarry.MainMenu.LastHit and not AutoCarry.MainMenu.MixedMode and not AutoCarry.MainMenu.LaneClear) and (SelectCard == "Blue" or SelectCard == "Red") then
		SelectCard = nil
	end
	PickCard()
end

function PluginOnCreateObj(obj)
	if myHero:GetDistance(obj) <= 50 then
		if obj.name == "Card_Blue.troy" then
			SelectedCard = "Blue"
		elseif obj.name == "Card_Red.troy" then
			SelectedCard = "Red"
		elseif obj.name == "Card_Yellow.troy" then
			SelectedCard = "Gold"
		elseif obj.name == "Cardmaster_stackready.troy" then
			StackedDeck = true
		elseif obj.name == "enrage_buf.troy" then
			Sheen = true
		elseif obj.name == "purplehands_buf.troy" then
			Lichbane = true
		end
	end
end

function PluginOnDeleteObj(obj)
	if myHero:GetDistance(obj) <= 50 then
		if obj.name == "Card_Blue.troy" or obj.name == "Card_Red.troy" or obj.name == "Card_Yellow.troy" then
			SelectedCard = "None"
		elseif obj.name == "Cardmaster_stackready.troy" then
			StackedDeck = false
		elseif obj.name == "purplehands_buf.troy" then
			Sheen = false
		elseif obj.name == "enrage_buf.troy" then
			Lichbane = false
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
	if Sheen then
		TotalDamage = TotalDamage + (SHEENSlot and (getDmg("SHEEN", minion, myHero)) or 0)
	end
	if Lichbane then
		TotalDamage = TotalDamage + (LICHBANESlot and (getDmg("LICHBANE", minion, myHero)) or 0)
	end

	return TotalDamage
end

function PluginOnProcessSpell(unit, spell)
	if unit.isMe and (spell.name == "Recall" or spell.name == "RecallImproved" or spell.name == "OdinRecall") then
		Recall = true
	end
	if unit.isMe and spell.name == "gate" then
		if AutoCarry.PluginMenu.cardGoldR then
			SelectCard = "Gold"
		end
	end
end

function OnFinishRecall(hero)
	if hero.isMe then
		Recall = false
	end
end

function PluginOnDraw()
	if myHero.dead then return end

	if RReady and AutoCarry.PluginMenu.drawR then
		DrawCircleMinimap(myHero.x, myHero.y, myHero.z, RangeR, 1 ,CCCCCC, AutoCarry.PluginMenu.drawRQuality*10)
	end

	if AutoCarry.PluginMenu.drawQ then
		DrawCircle(myHero.x, myHero.y, myHero.z, RangeQ, 0xCCCCCC)
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
	RReady = (myHero:CanUseSpell(_R) == READY)
	SHEENSlot, LICHBANESlot = GetInventorySlotItem(3057), GetInventorySlotItem(3100)
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
	local Name = myHero:GetSpellData(_W).name

	if AutoCarry.PluginMenu.cardBlue then
		SelectCard = "Blue"
	end
	if AutoCarry.PluginMenu.cardRed then
		SelectCard = "Red"
	end
	if AutoCarry.PluginMenu.cardGold then
		SelectCard = "Gold"
	end

	if SelectCard == "Blue" then
		spellName = "bluecardlock"
		if Name == "PickACard" then
			CastSpell(_W)
		end
	end
	if SelectCard == "Red" then
		spellName = "redcardlock"
		if Name == "PickACard" then
			CastSpell(_W)
		end
	end
	if SelectCard == "Gold" then
		spellName = "goldcardlock"
		if Name == "PickACard" then
			CastSpell(_W)
		end
	end

	if Name == spellName then
		CastSpell(_W)
		SelectCard = nil
	end
end
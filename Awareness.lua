--[[ Credits: eXtragoZ: Ward Prediction; bortrik: Baron check; Vice Versa: Possible Position; Manciuszz: Incoming Enemy Marks; Swaggot: EnemyJunglerPosition idea; Apple: jungle mobs; Manciuszz for predators vision idea/some script parts; Klokje: ImLib ]]--
-- Delay to buff left time
--[[
Known Bugs: Wrong Buff Time if owner changes
Should be fixed but untested: Don't draw ss circles if recalled
ToDo: Combine with hidden objects
FIX: Buff Timer
FIX: Recall minimap
ADD: ImLib
FIX: Unique Colors
ADD: OnTheFly Message
ADD: Baron/Dragon Ping x 3
ADD: Fallback ping on enemymark
FIX: Turret Range
ADD: Turret Colors
ADD: Minion vision
ADD: Option to disable turrets per team
ADD: Re from death enemys TEST line 490, maybe 2nd function better idk
IMPRV: removed snidremove
ADD: SS Pings
]]--

--[[
0.1.1
FIX: Death SS
0.1.2
FIX: Jungler SS
]]--

require "MapPosition"
require "ImLib"
if GetGame().map.index ~= 1 then return end

local VisionList = {}
local MissTable = {}
local VisionListLastTick = 0
local MissRefreshLastTick = 0
local MissWarningLastTick = 0
local BuffCheckLastTick = 0
local BuffAnnounceLastTick = {
	["baron"] = 0,
	["red_enemy"] = 0,
	["red_ally"] = 0,
	["blue_enemy"] = 0,
	["blue_ally"] = 0
}
local ImportantVisionLastTick = 0
local ImportantAttackLastTick = 0
local Delay = 1000
local MissWarningDelay = 60000
local EnemyTable = {}
local LaneTable = {}
local TurretTable = {}
local TurretLifeCheckLastTick = 0
local WardTable = {}
local ItemSlot = {ITEM_1, ITEM_2, ITEM_3, ITEM_4, ITEM_5, ITEM_6}
local RecallTable = {}
local DeathTable = {}
local FatCircleTable = {}
local NPCTable = {}
local EnemyJungler = nil
local JungleCamps = {
	["Worm12.1.1"] = true,
	["Dragon6.1.1"] = true,
	["AncientGolem1.1.1"] = true,
	["AncientGolem7.1.1"] =  true,
	["LizardElder4.1.1"] =  true,
	["LizardElder10.1.1"] = true
}
local MinionTable = {}

function OnLoad()
	ConfigGeneral = scriptConfig("[Awareness] General", "awarenessgeneral")
	ConfigGeneral:addParam("SSTime", "Min. Time to count as missing", SCRIPT_PARAM_SLICE, 5, 1, 20, 0)
	ConfigGeneral:addParam("MIAAnnounce", "Announce missing enemies", SCRIPT_PARAM_ONOFF, true)
	if VIP_USER then
		ConfigGeneral:addParam("MIAPingSS", "Ping SS enemies", SCRIPT_PARAM_ONOFF, true)
		ConfigGeneral:addParam("MIAPingSSOwn", "Ping own lane only", SCRIPT_PARAM_ONOFF, true)
	end
	ConfigGeneral:addParam("MIAPingRE", "Ping RE enemies", SCRIPT_PARAM_ONOFF, true)
	ConfigGeneral:addParam("MIAWarn", "Warn on multiple MIA's", SCRIPT_PARAM_ONOFF, true)
	ConfigGeneral:addParam("WardTrack", "Track Wards", SCRIPT_PARAM_ONOFF, true)
	ConfigGeneral:addParam("BuffCheck", "Track Buffs", SCRIPT_PARAM_ONOFF, true)
	ConfigGeneral:addParam("VisionCheck", "Announce missing Baron/Dragon vision", SCRIPT_PARAM_ONOFF, true)
	ConfigGeneral:addParam("AttackCheck", "Announce Baron/Dragon/Buffs losing life", SCRIPT_PARAM_ONOFF, true)
	ConfigGeneral:addParam("TurretCheck", "Announce Turrets losing life", SCRIPT_PARAM_ONOFF, true)

	ConfigDraw = scriptConfig("[Awareness] Draw", "awarenessdraw")
	ConfigDraw:addParam("drawTurretRangeEnemy", "Draw Turret Range (Enemy)", SCRIPT_PARAM_ONOFF, true)
	ConfigDraw:addParam("drawTurretRangeAlly", "Draw Turret Range (Ally)", SCRIPT_PARAM_ONOFF, false)
	ConfigDraw:addParam("drawVisionRangePlayer", "Draw Player Vision Range", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("G"))
	ConfigDraw:addParam("drawVisionRangeMinion", "Draw Minion Vision Range", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("H"))
	ConfigDraw:addParam("MinionVisionRadius", "Radius for Minion Vision", SCRIPT_PARAM_SLICE, 100, 100, 200, 0)
	ConfigDraw:addParam("drawEnemyMark", "Mark Incoming Enemies", SCRIPT_PARAM_ONOFF, true)
	ConfigDraw:addParam("drawRecall", "Draw recalling Enemies", SCRIPT_PARAM_ONOFF, true)
	ConfigDraw:addParam("drawPossiblePosition", "Draw possible position on minimap", SCRIPT_PARAM_ONOFF, true)
	ConfigDraw:addParam("drawJunglerPosition", "Show last jungler position", SCRIPT_PARAM_ONOFF, true)

	ConfigDraw:permaShow("drawVisionRangePlayer")
	ConfigDraw:permaShow("drawVisionRangeMinion")

	EnemyTable = GetEnemyHeroes()

	CreateVisionList()
	CreateTurretTable()
	CreateWardTable()
	CreateNPCTable()
	CreateMinionTable()
	GetEnemyJungler()

	PrintChat("Awareness loaded")
end

function OnTick()
	RefreshVisionList()
	TrackMissingEnemys()
	if ConfigGeneral.MIAWarn then AutoWarning() end
	if ConfigGeneral.BuffCheck then BuffChecks() end
	if ConfigGeneral.WardTrack then RefreshWardTableAndAnnounce() end
	if ConfigGeneral.VisionCheck then ImportantVisionCheck() end
	if ConfigGeneral.AttackCheck then ImportantAttackCheck() end
	if ConfigGeneral.TurretCheck then TurretLifeCheck() end
end

function OnDraw()
	DrawVision()
	if ConfigDraw.drawRecall then DrawRecall() end
	if ConfigDraw.drawEnemyMark then DrawEnemyMark() end
	if ConfigDraw.drawPossiblePosition then DrawPossiblePosition() end
	if ConfigDraw.drawJunglerPosition then DrawJunglerPosition() end
end

function OnProcessSpell(obj, spell)
	if obj and obj.valid and obj.team ~= myHero.team and (spell.name == "Recall" or spell.name == "RecallImproved" or spell.name == "OdinRecall") then
		table.insert(RecallTable, {["obj"] = obj, ["timestamp"] = GetTickCount(), ["announced"] = false})
		VisionList[obj.networkID]["recallTick"] = GetTickCount()
	end
end

function OnCreateObj(obj)
	if obj and obj.type == "obj_AI_Minion" and obj.name and JungleCamps[obj.name] then
		table.insert(NPCTable, {["obj"] = obj, ["lastannounceattack"] = 0, ["lastannouncevision"] = 0})
	end

	 if obj and obj.type == "obj_AI_Minion" and (obj.name:find((myHero.team == TEAM_BLUE and "T200" or "T100")) or obj.name:find((myHero.team == TEAM_BLUE and "Red" or "Blue"))) then
        table.insert(MinionTable, obj)
    end
end

function OnDeleteObj(obj)
	if obj and obj.type == "obj_AI_Minion" and obj.name and JungleCamps[obj.name] then
		for i=1, #NPCTable do
			local NPC = NPCTable[i]["obj"]

			if NPC.name == obj.name then
				table.remove(NPCTable, i)
			end
		end
	end

	if obj and obj.type == "obj_AI_Minion" and #MinionTable > 0 then
		for i=1, #MinionTable do
			local Minion = MinionTable[i]

			if Minion and Minion.name and obj.name:find(Minion.name) then
				table.remove(MinionTable, i)
			end
		end
	end
end

function DrawVision()
	if #TurretTable > 0 and (ConfigDraw.drawTurretRangeEnemy or ConfigDraw.drawTurretRangeAlly) then
		for i=1, #TurretTable do
			local Turret = TurretTable[i]["obj"]

			if Turret ~= nil and Turret.health <= 0 then
				table.remove(TurretTable, i)
				break
			end

			if myHero:GetDistance(Turret) <= 2000 and Turret.valid then
				if (Turret.team == myHero.team and not ConfigDraw.drawTurretRangeAlly) or (Turret.team ~= myHero.team and not ConfigDraw.drawTurretRangeEnemy) then
					break
				end
				DrawCircle(Turret.x, Turret.y, Turret.z, TurretTable[i]["range"], TurretTable[i]["color"])
			end
		end
	end

	if ConfigDraw.drawVisionRangePlayer then
		for i=1, #EnemyTable do
			local Enemy = EnemyTable[i]

			if myHero:GetDistance(Enemy) <= 2000 and Enemy.valid and Enemy.visible and not Enemy.dead then
				DrawCircle(Enemy.x, Enemy.y, Enemy.z, 1400, ColorARGB.White:ToARGB())
			end
		end
	end

	if ConfigDraw.drawVisionRangeMinion then
		DrawCircle(mousePos.x, mousePos.y, mousePos.z, ConfigDraw.MinionVisionRadius, ColorARGB.LightSeaGreen:ToARGB())

		for i=1, #MinionTable do
			local Minion = MinionTable[i]

			if GetDistance(Minion, mousePos) <= ConfigDraw.MinionVisionRadius and Minion.valid and Minion.visible and not Minion.dead then
				DrawCircle(Minion.x, Minion.y, Minion.z, 1200, ColorARGB.White:ToARGB())
			end
		end
	end
end

function DrawRecall()
	if #RecallTable == 0 then return end

	for i=1, #RecallTable do
		local Unit = RecallTable[i]["obj"]

		if GetTickCount() > RecallTable[i]["timestamp"] + 8000 then
			table.remove(RecallTable, i)
			break
		end

		if Unit.valid then
			if not RecallTable[i]["announced"] then
				Message.AddMassage("Recall: "..Unit.charName.." "..GetLane(Unit), ColorARGB.Lime)
				RecallTable[i]["announced"] = true
			end
			DrawCircleMinimap(Unit.x, Unit.y, Unit.z, 1000, 2, ColorARGB.Lime:ToARGB())
		end
	end
end

function DrawEnemyMark()
	if #FatCircleTable == 0 then return end

	for i=1, #FatCircleTable do
		local Enemy = FatCircleTable[i]["obj"]

		if GetTickCount() > FatCircleTable[i]["timestamp"] + 5000 then
			table.remove(FatCircleTable, i)
			break
		end

		if Enemy.valid and myHero:GetDistance(Enemy) < 2000 then
			if not FatCircleTable[i]["announced"] then
				Message.AddMassage("Enemy: "..Enemy.charName, ColorARGB.Red)
				for i=1, 2 do
					PingSignal(PING_FALLBACK, Enemy.x, Enemy.y, Enemy.z, 2)
				end
				FatCircleTable[i]["announced"] = true
			end

			for j=1, 10 do
				DrawCircle(Enemy.x, Enemy.y, Enemy.z, 1250+j*0.25, ColorARGB.Red:ToARGB())
			end
		end
	end
end

function DrawPossiblePosition()
	for i=1, #EnemyTable do
		local Enemy = EnemyTable[i]

		if GetTickCount()-VisionList[Enemy.networkID]["timestamp"] >= 15000 or VisionList[Enemy.networkID]["recallTick"] ~= 0 or Enemy.visible then
			break
		end

		local Distance = ((GetTickCount()-VisionList[Enemy.networkID]["timestamp"])/1000)*Enemy.ms

		if Enemy.valid then
			if Distance <= 5000 then
				DrawCircleMinimap(VisionList[Enemy.networkID]["x"], VisionList[Enemy.networkID]["y"], VisionList[Enemy.networkID]["z"], Distance, 2, ColorARGB.White:ToARGB())
			else
				DrawCircleMinimap(VisionList[Enemy.networkID]["x"], VisionList[Enemy.networkID]["y"], VisionList[Enemy.networkID]["z"], 5000, 2, ColorARGB.Magenta:ToARGB())
			end
		end
	end
end

function DrawJunglerPosition()
	if EnemyJungler == nil then return end

	if EnemyJungler.dead then
		DrawText("Jungler: Dead", 45, 750, 850, ColorARGB.White:ToARGB())
	elseif EnemyJungler.visible then
		DrawText("Jungler: "..tostring(GetLane(EnemyJungler)), 45, 750, 850, ColorARGB.Green:ToARGB())
	else
		DrawText("Jungler: "..tostring(VisionList[EnemyJungler.networkID]["lane"]), 45, 750, 850, ColorARGB.Red:ToARGB())
	end
end

function CreateTurretTable()
	 for i=1, objManager.maxObjects do
		local obj = objManager:getObject(i)

		if obj and obj.valid and obj.type == "obj_AI_Turret" then
			local Range = ((obj.name == "Turret_OrderTurretShrine_A" or obj.name == "Turret_ChaosTurretShrine_A") and 1050 or 950)
			local Color = (obj.team == myHero.team and ColorARGB.Green:ToARGB() or ColorARGB.Red:ToARGB())
			local ColorStatic = (obj.team == myHero.team and ColorARGB.Green or ColorARGB.Red)

			table.insert(TurretTable, {["obj"] = obj, ["range"] = Range, ["color"] = Color, ["colorstatic"] = ColorStatic, ["lasthealth"] = obj.health, ["lastannounce"] = 0})
		end
	 end
end

function BuffChecks()
	local CurrentTick = GetTickCount()

	if CurrentTick < BuffCheckLastTick + Delay then return end

	for i=1,heroManager.iCount,1 do
		local Unit = heroManager:getHero(i)

		for j=1,Unit.buffCount do
			local Buff = Unit:getBuff(j)

			if Buff.valid and Buff.name == "exaltedwithbaronnashor" and CurrentTick > BuffAnnounceLastTick["baron"] + 300000 then
				Announce("Baron respawn: "..(math.floor(Buff.startT/60) + 7)..":"..math.floor(Buff.startT/60), 1)
				BuffAnnounceLastTick["baron"] = CurrentTick
			end

			if Buff.valid and Buff.name == "blessingofthelizardelder" then
				if Unit.team ~= myHero.team then
					if CurrentTick > BuffAnnounceLastTick["red_enemy"] + 180000 then
						Announce("Red respawn (maybe enemy): "..math.floor((Buff.startT/60) + 5)..":"..math.floor(Buff.startT/60), 1)
						BuffAnnounceLastTick["red_enemy"] = CurrentTick
					end
				else
					if CurrentTick > BuffAnnounceLastTick["red_ally"] + 180000 then
						Announce("Red respawn (maybe ally): "..math.floor((Buff.startT/60) + 5)..":"..math.floor(Buff.startT/60), 1)
						BuffAnnounceLastTick["red_ally"] = CurrentTick
					end
				end
			end

			if Buff.valid and Buff.name == "crestoftheancientgolem" then
				if Unit.team ~= myHero.team then
					if CurrentTick > BuffAnnounceLastTick["blue_enemy"] + 180000 then
						Announce("Blue respawn (maybe enemy): "..math.floor((Buff.startT/60) + 5)..":"..math.floor(Buff.startT/60), 1)
						BuffAnnounceLastTick["blue_enemy"] = CurrentTick
					end
				else
					if CurrentTick > BuffAnnounceLastTick["blue_ally"] + 180000 then
						Announce("Blue respawn (maybe ally): "..math.floor((Buff.startT/60) + 5)..":"..math.floor(Buff.startT/60), 1)
						BuffAnnounceLastTick["blue_ally"] = CurrentTick
					end
				end
			end

		end
	end

	BaronCheckLastTick = CurrentTick
end

function CreateWardTable()
	for i=1, heroManager.iCount do
		local Unit = heroManager:GetHero(i)

		WardTable[Unit.networkID] = {
			[1] = {["sight"] = 0, ["vision"] = 0},
			[2] = {["sight"] = 0, ["vision"] = 0}
		}
	end
end

function RefreshWardTableAndAnnounce()
	for i=1, heroManager.iCount do
		local Unit = heroManager:GetHero(i)
		local Color = (Unit.team == myHero.team and "#0095FF" or "#FF0000")

		WardTable[Unit.networkID][1]["sight"] = 0
		WardTable[Unit.networkID][1]["vision"] = 0

		for j=1, 6 do
			local Item = Unit:getItem(ItemSlot[j])

			if Item and Item.id == 2044 then
				WardTable[Unit.networkID][1]["sight"] = WardTable[Unit.networkID][1]["sight"] + Item.stacks
			end

			if Item and Item.id == 2043 then
				WardTable[Unit.networkID][1]["vision"] = WardTable[Unit.networkID][1]["vision"] + Item.stacks
			end
		end

		if WardTable[Unit.networkID][2]["sight"] > WardTable[Unit.networkID][1]["sight"] then
			Announce("<font color='"..Color.."'>"..Unit.charName.."</font><font color='#CCCCCC'> used "..WardTable[Unit.networkID][2]["sight"]-WardTable[Unit.networkID][1]["sight"].." </font><font color='#CCCCCC'>Sight Ward(s)</font>", 3)
		end
		if WardTable[Unit.networkID][2]["sight"] < WardTable[Unit.networkID][1]["sight"] then
			Announce("<font color='"..Color.."'>"..Unit.charName.."</font><font color='#CCCCCC'> bought "..WardTable[Unit.networkID][1]["sight"]-WardTable[Unit.networkID][2]["sight"].." </font><font color='#CCCCCC'>Sight Ward(s)</font>", 3)
		end

		if WardTable[Unit.networkID][2]["vision"] > WardTable[Unit.networkID][1]["vision"] then
			Announce("<font color='"..Color.."'>"..Unit.charName.."</font><font color='#CCCCCC'> used "..WardTable[Unit.networkID][2]["vision"]-WardTable[Unit.networkID][1]["vision"].." </font><font color='#CCCCCC'>Vision Ward(s)</font>", 3)
		end
		if WardTable[Unit.networkID][2]["vision"] < WardTable[Unit.networkID][1]["vision"] then
			Announce("<font color='"..Color.."'>"..Unit.charName.."</font><font color='#CCCCCC'> bought "..WardTable[Unit.networkID][1]["vision"]-WardTable[Unit.networkID][2]["vision"].." </font><font color='#CCCCCC'>Vision Ward(s)</font>", 3)
		end

		WardTable[Unit.networkID][2]["vision"] = WardTable[Unit.networkID][1]["vision"]
		WardTable[Unit.networkID][2]["sight"] = WardTable[Unit.networkID][1]["sight"]	
	end
end

function CreateVisionList()
	for i=1, #EnemyTable do
		local Enemy = EnemyTable[i]

		VisionList[Enemy.networkID] = {
			["visible"] = false,
			["timestamp"] = 0,
			["x"] = 0,
			["y"] = 0,
			["z"] = 0,
			["announced"] = false,
			["lane"] = nil,
			["recallTick"] = 0
		}
	end
end

function RefreshVisionList()
	local CurrentTick = GetTickCount()

	if CurrentTick < VisionListLastTick + Delay then return end

	for i=1, #EnemyTable do
		local Enemy = EnemyTable[i]

		if Enemy.visible then
			VisionList[Enemy.networkID]["visible"] = true
			VisionList[Enemy.networkID]["timestamp"] = CurrentTick
			VisionList[Enemy.networkID]["x"] = Enemy.x
			VisionList[Enemy.networkID]["y"] = Enemy.y
			VisionList[Enemy.networkID]["z"] = Enemy.z
			VisionList[Enemy.networkID]["lane"] = GetLane(Enemy)
			if CurrentTick-VisionList[Enemy.networkID]["recallTick"] >= 10000 then
				VisionList[Enemy.networkID]["recallTick"] = 0
			end
		else
			if not Enemy.dead then
				VisionList[Enemy.networkID]["visible"] = false
			end
		end
	end

	VisionListLastTick = CurrentTick
end

function TrackMissingEnemys()
	local CurrentTick = GetTickCount()

	if CurrentTick < MissRefreshLastTick + Delay then return end

	for i=1, #EnemyTable do
		local Enemy = EnemyTable[i]

		if GetTickCount() > VisionList[Enemy.networkID]["timestamp"] + ConfigGeneral.SSTime*1000 and VisionList[Enemy.networkID]["timestamp"] ~= 0 and VisionList[Enemy.networkID]["announced"] == false then
			if ConfigGeneral.MIAAnnounce then
				Message.AddMassage("Miss: "..Enemy.charName.." "..VisionList[Enemy.networkID]["lane"], ColorARGB.Red)
				if ConfigGeneral.MIAPingSS and not Enemy.dead and not Enemy.networkID == EnemyJungler.networkID then
					if ConfigGeneral.MIAPingSSOwn then
						if VisionList[Enemy.networkID]["lane"] == GetLane(myHero) then
							PingSignalC(VisionList[Enemy.networkID]["x"], VisionList[Enemy.networkID]["z"], Enemy.networkID, 1)
						end
					else
						PingSignalC(VisionList[Enemy.networkID]["x"], VisionList[Enemy.networkID]["z"], Enemy.networkID, 1)
					end
				end
			end
			table.insert(MissTable, Enemy)
			VisionList[Enemy.networkID]["announced"] = true
		end
	end

	if #MissTable > 0 then
		for i=1, #MissTable do
			local Enemy = MissTable[i]

			if Enemy and Enemy.dead then
				table.insert(DeathTable, Enemy)
				table.remove(MissTable, i)
				break
			end

			if Enemy and Enemy.visible then
				Message.AddMassage("Re: "..Enemy.charName.." "..GetLane(Enemy), ColorARGB.White)
				if ConfigGeneral.MIAPingRE then
					PingSignal(0, Enemy.x, Enemy.y, Enemy.z, PING_NORMAL)
				end
				table.insert(FatCircleTable, {["obj"] = Enemy, ["timestamp"] = CurrentTick, ["announced"] = false})
				table.remove(MissTable, i)
				VisionList[Enemy.networkID]["announced"] = false
			end
		end
	end

	if #DeathTable > 0 then
		for i=1, #DeathTable do
			local Enemy = DeathTable[i]

			if Enemy and Enemy.visible then
				Message.AddMassage("Alive and Re: "..Enemy.charName.." "..GetLane(Enemy), ColorARGB.White)
				if ConfigGeneral.MIAPingRE then
					PingSignal(0, Enemy.x, Enemy.y, Enemy.z, PING_NORMAL)
				end
				table.remove(DeathTable, i)
				VisionList[Enemy.networkID]["announced"] = false
			end
		end
	end

	MissRefreshLastTick = CurrentTick
end

function AutoWarning()
	local CurrentTick = GetTickCount()

	if CurrentTick < MissWarningLastTick + MissWarningDelay then return end

	if #MissTable >= 2 then
		Message.AddMassage(#MissTable.." Enemies missing!", ColorARGB.Red)
		MissWarningLastTick = CurrentTick
	end
end

function CreateNPCTable()
	 for i=1, objManager.maxObjects do
		local obj = objManager:getObject(i)

		if obj and obj.type == "obj_AI_Minion" and obj.name and JungleCamps[obj.name] then
			table.insert(NPCTable, {["obj"] = obj, ["lastannounceattack"] = 0, ["lastannouncevision"] = 0})
		end
	 end
end

function CreateMinionTable()
	 for i=1, objManager.maxObjects do
		local obj = objManager:getObject(i)

		if obj and obj.type == "obj_AI_Minion" and obj.team ~= myHero.team and not obj.dead then
			table.insert(MinionTable, obj)
		end
	 end
end

function GetRealNPCName(obj)
	if not obj.name then return nil end

	if obj.name == "Worm12.1.1" then
		return "Baron"
	elseif obj.name == "Dragon6.1.1" then
		return "Dragon"
	elseif obj.name == "LizardElder4.1.1" then
		return "Red (Team Blue)"
	elseif obj.name == "LizardElder10.1.1" then
		return "Red (Team Red)"
	elseif obj.name == "AncientGolem1.1.1" then
		return "Blue (Team Blue)"
	elseif obj.name == "AncientGolem7.1.1" then
		return "Blue (Team Red)"
	end
end

function ImportantVisionCheck()
	local CurrentTick = GetTickCount()

	if CurrentTick < ImportantVisionLastTick + Delay then return end

	for i=1, #NPCTable do
		local NPC = NPCTable[i]["obj"]

		if NPC and not NPC.visible and (NPC.name == "Worm12.1.1" or NPC.name == "Dragon6.1.1") and CurrentTick > NPCTable[i]["lastannouncevision"] + 120000 then
			if #MissTable >= 4 then
				Announce(#MissTable.." Enemys missing and no "..GetRealNPCName(NPC).." vision", 2)
				Message.AddMassage(#MissTable.." Enemys missing and no "..GetRealNPCName(NPC).." vision", ColorARGB.Red)
				NPCTable[i]["lastannouncevision"] = CurrentTick
				break
			end

			if GetTickCount() > GetGame().tick + 900000 then
				Announce("You have no "..GetRealNPCName(NPC).." vision", 1)
				Message.AddMassage("You have no "..GetRealNPCName(NPC).." vision", ColorARGB.White)
				NPCTable[i]["lastannouncevision"] = CurrentTick
				break
			end
		end
	end

	ImportantVisionLastTick = CurrentTick
end

function ImportantAttackCheck()
	local CurrentTick = GetTickCount()

	if CurrentTick < ImportantAttackLastTick + Delay then return end

	for i=1, #NPCTable do
		local NPC = NPCTable[i]["obj"]

		if NPC and NPC.valid and NPC.visible then
			if NPC.health < NPC.maxHealth and CurrentTick > NPCTable[i]["lastannounceattack"] + 180000 then
				Announce(GetRealNPCName(NPC).." gets attacked", 2)
				Message.AddMassage(GetRealNPCName(NPC).." gets attacked", ColorARGB.Red)
				for i=1, 2 do
					PingSignal(0, NPC.x, NPC.y, NPC.z, PING_NORMAL)
				end
				NPCTable[i]["lastannounceattack"] = CurrentTick
			end
		end
	end

	ImportantAttackLastTick = CurrentTick
end

function TurretLifeCheck()
	local CurrentTick = GetTickCount()

	if CurrentTick < TurretLifeCheckLastTick + Delay then return end

	for i=1, #TurretTable do
		local Turret = TurretTable[i]["obj"]

		if Turret.valid and Turret.health < TurretTable[i]["lasthealth"] and CurrentTick > TurretTable[i]["lastannounce"] + 120000 and myHero:GetDistance(Turret) >= 3000 then
			if Turret.health/Turret.maxHealth <= 0.2 then
				Announce("A Turret on "..GetLane(Turret).." Lane goes down", 2)
				Message.AddMassage("A Turret on "..GetLane(Turret).." Lane goes down", TurretTable[i]["colorstatic"])
				for i=1, 2 do
					PingSignal(0, Turret.x, Turret.y, Turret.z, PING_NORMAL)
				end
			else
				Message.AddMassage("A Turret on "..GetLane(Turret).." Lane gets attacked", TurretTable[i]["colorstatic"])
			end
			TurretTable[i]["lastannounce"] = CurrentTick
		end
	end

	TurretLifeCheckLastTick = CurrentTick
end

function GetLane(unit)
	if not unit then return nil end

	local Position = nil

	if MapPosition:onTopLane(unit) then
		Position = "Top"
	elseif MapPosition:onMidLane(unit) then
		Position = "Mid"
	elseif MapPosition:onBotLane(unit) then
		Position = "Bot"
	elseif MapPosition:inOuterJungle(unit) then
		Position = "Outer Jungle"
	elseif MapPosition:inInnerJungle(unit) then
		Position = "Inner Jungle"
	elseif MapPosition:inOuterRiver(unit) then
		Position = "Outer River"
	elseif MapPosition:inInnerRiver(unit) then
		Position = "Inner River"
	elseif MapPosition:inLeftBase(unit) then
		Position = "Blue Base"
	elseif MapPosition:inRightBase(unit) then
		Position = "Purple Base"
	end

	if Position ~= nil then
		return Position
	else
		return nil
	end
end

function GetEnemyJungler()
	for i=1, #EnemyTable do
		local Enemy = EnemyTable[i]

		if Enemy.valid and (Enemy:GetSpellData(SUMMONER_1).name:find("Smite") or Enemy:GetSpellData(SUMMONER_2).name:find("Smite")) then
			EnemyJungler = Enemy
		end
	end

	if EnemyJungler == nil then
		for i=1, #EnemyTable do
			local Enemy = EnemyTable[i]

			if Enemy.valid and (Enemy.charName == "Nunu" or Enemy.charName == "Chogath") then
				EnemyJungler = Enemy
			end
		end
	end
end

function Announce(message, state)
	local state = state or 1

	if message then
		if state == 1 then
			PrintChat(tostring("<font color='#CCCCCC'>"..message.."</font>"))
		elseif state == 2 then
			PrintChat(tostring("<font color='#FF0000'>"..message.."</font>"))
		elseif state == 3 then
			PrintChat(tostring(message))
		end
	end
end

function PingSignalC(x, z, nid, ptype)
	if not VIP_USER then return end

	local ptype = (ptype == 1 and 179 or 05)
	local packet = CLoLPacket(0x56)

	packet:Encode4(0)
	packet:EncodeF(x)
	packet:EncodeF(z)
	packet:EncodeF(nid)
	packet:Encode2(ptype)
	packet.dwArg1 = 1
	packet.dwArg2 = 0

	SendPacket(packet)
end
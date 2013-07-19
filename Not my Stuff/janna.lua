
--[[ Sida's Auto Carry Plugin: Janna LAGGY ALPHA
		by Vadash ]]--
		
if myHero.charName ~= "Janna" then return end

local QRange1 = 1100
local QRange2 = 1700
local QPrediction = TargetPredictionVIP(QRange1, 900, 0.240)
enemyHeroes = {}
allyHeroes = {}
local cast = false
local tick = 0

local SortList = {
    ["Ashe"]= 1,["Caitlyn"] = 1,["Corki"] = 1,["Draven"] = 1,["Ezreal"] = 1,["Graves"] = 1,["Jayce"] = 1,["KogMaw"] = 1,["MissFortune"] = 1,["Quinn"] = 1,["Sivir"] = 1,
    ["Tristana"] = 1,["Twitch"] = 1,["Varus"] = 1,["Vayne"] = 1,

    ["Ahri"] = 2,["Annie"] = 2,["Akali"] = 2,["Anivia"] = 2,["Brand"] = 2,["Cassiopeia"] = 2,["Diana"] = 2,["Evelynn"] = 2,["FiddleSticks"] = 2,["Fizz"] = 2,["Gragas"] = 2,
    ["Heimerdinger"] = 2,["Karthus"] = 2,["Kassadin"] = 2,["Katarina"] = 2,["Kayle"] = 2,["Kennen"] = 2,["Leblanc"] = 2,["Lissandra"] = 2,["Lux"] = 2,["Malzahar"] = 2,["Zed"] = 2,
    ["Mordekaiser"] = 2,["Morgana"] = 2,["Nidalee"] = 2,["Orianna"] = 2,["Rumble"] = 2,["Ryze"] = 2,["Sion"] = 2,["Swain"] = 2,["Syndra"] = 2,["Teemo"] = 2,["TwistedFate"] = 2,
    ["Veigar"] = 2,["Viktor"] = 2,["Vladimir"] = 2,["Xerath"] = 2,["Ziggs"] = 2,["Zyra"] = 2,["MasterYi"] = 2,["Shaco"] = 2,["Jayce"] = 2,["Pantheon"] = 2,["Urgot"] = 2,["Talon"] = 2,
    
    ["Alistar"] = 3,["Blitzcrank"] = 3,["Janna"] = 3,["Karma"] = 3,["Leona"] = 3,["Lulu"] = 3,["Nami"] = 3,["Nunu"] = 3,["Sona"] = 3,["Soraka"] = 3,["Taric"] = 3,["Thresh"] = 3,["Zilean"] = 3,

    ["Darius"] = 4,["Elise"] = 4,["Fiora"] = 4,["Gangplank"] = 4,["Garen"] = 4,["Irelia"] = 4,["JarvanIV"] = 4,["Jax"] = 4,["Khazix"] = 4,["LeeSin"] = 4,["Nautilus"] = 4,
    ["Olaf"] = 4,["Poppy"] = 4,["Renekton"] = 4,["Rengar"] = 4,["Riven"] = 4,["Shyvana"] = 4,["Trundle"] = 4,["Tryndamere"] = 4,["Udyr"] = 4,["Vi"] = 4,["MonkeyKing"] = 4,
    ["Aatrox"] = 4,["Nocturne"] = 4,["XinZhao"] = 4,

    ["Amumu"] = 5,["Chogath"] = 5,["DrMundo"] = 5,["Galio"] = 5,["Hecarim"] = 5,["Malphite"] = 5,["Maokai"] = 5,["Nasus"] = 5,["Rammus"] = 5,["Sejuani"] = 5,["Shen"] = 5,
    ["Singed"] = 5,["Skarner"] = 5,["Volibear"] = 5,["Warwick"] = 5,["Yorick"] = 5,["Zac"] = 5
} 

function objectValid(object)
    return object ~= nil and object.valid and not object.dead and object.bTargetable
end

function PluginOnProcessSpell(object,spell)
	if myHero:CanUseSpell(_E) == READY and object.team == myHero.team and spell.name:find("Attack") and not myHero.dead and not (object.name:find("Minion_") or object.name:find("Odin")) and GetDistance(object) < 1000 then	
		for i, ally in pairs(allyHeroes) do
	        if SortList[ally.charName] == 1 and objectValid(ally) and GetDistance(ally) < 800 and (GetDistance(ally, spell.endPos) < 80 or GetDistance(ally, spell.startPos) < 80) then
	        	CastSpell(_E, ally)
	        	return
	        end
	    end
	end
end

function PluginOnTick()
	Sorting()

	if AutoCarry.MainMenu.AutoCarry then Combo() end

	-- Q end
	if cast then
		CastQ2()
	end	
end

function PluginOnLoad()
    for i = 1, heroManager.iCount do
        local hero = heroManager:GetHero(i)
        if hero.team ~= myHero.team then
            table.insert(enemyHeroes, hero)
        else 
            table.insert(allyHeroes, hero)
        end
    end
end

function Combo()
	if myHero:CanUseSpell(_Q) ~= READY and GetTickCount() - tick > 1000 then
		cast = false
		tick = 0
	end

	-- Q start + W
	for i, target in pairs(enemyHeroes) do
		if myHero:CanUseSpell(_Q) == READY and ValidTarget(target) then
			if not cast then galeStart = myHero end
			local enemyPos = QPrediction:GetPrediction(target)
			if not cast and enemyPos and GetDistance(enemyPos) < 1400 and QPrediction:GetHitChance(target) > 0.7 then
				CastQ1(enemyPos)
				return
			end
		end

		if myHero:CanUseSpell(_W) == READY and ValidTarget(target) and GetDistance(target) < 600 then
			CastSpell(_W, target)
			return
		end
	end
end

function Sorting()
    table.sort(enemyHeroes, function(x,y) 
        local dmgx = myHero:CalcMagicDamage(x, 100)
        local dmgy = myHero:CalcMagicDamage(y, 100)

        dmgx = dmgx/ (1 + (SortList[x.charName]/10) - 0.1)
        dmgy = dmgy/ (1 + (SortList[y.charName]/10) - 0.1)

        local valuex = x.health/dmgx
        local valuey = y.health/dmgy

        return valuex < valuey
        end)
    table.sort(allyHeroes, function(x,y) 
        local mdmgx = myHero:CalcMagicDamage(x, 100)
        local mdmgy = myHero:CalcMagicDamage(y, 100)
        local dmgx = myHero:CalcDamage(x, 100)
        local dmgy = myHero:CalcDamage(y, 100)

        dmgx = (dmgx+mdmgx)/ (1 + (SortList[x.charName]/10) - 0.1)
        dmgy = (dmgy+mdmgy)/ (1 + (SortList[y.charName]/10) - 0.1)

        local valuex = x.health/dmgx
        local valuey = y.health/dmgy

        return valuex < valuey
        end)
end

function CastQ1(enemyPos) --start cast
	if not cast and myHero:CanUseSpell(_Q) == READY then
		--print("open")
		CastSpell(_Q, enemyPos.x, enemyPos.z)
        tick = GetTickCount()
    end
end

function CastQ2() -- end cast
	cast = false
	CastSpell(_Q)
end

function PluginOnDraw()
	if myHero:CanUseSpell(_Q) == READY then
		DrawCircle(player.x, player.y, player.z, QRange1, 0x099B2299)
	end
end
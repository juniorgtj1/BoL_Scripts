--[[ Simple script that casts E at the nearest enemy if you press Q on Soraka ]]--

--[[ Variables ]]--
local NearestEnemy = nil -- our nearest champ

--[[ Core ]]--
function OnLoad()
    print(">>Soraka auto E loaded<<") -- say hello
end

-- Captures the pressed keys
function OnWndMsg(msg, wParam)
    if msg == KEY_DOWN and wParam == 0x51 then CastE() end -- 0x51 == Q key
end

-- Casts E on the nearest enemy champ
function CastE()
	for i=1, heroManager.iCount do -- loop through the enemys
		local Enemy = heroManager:GetHero(i)
        if ValidTarget(NearestEnemy) and ValidTarget(Enemy) then
        	if GetDistance(Enemy) < GetDistance(NearestEnemy) then
            	NearestEnemy = Enemy -- and find the nearest champ
            end
    	else
            NearestEnemy = Enemy
    	end
	end

	if myHero:GetDistance(NearestEnemy) <= 725 then CastSpell(_E, NearestEnemy) end -- finally cast our spell
end
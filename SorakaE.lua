--[[ Simple script that casts E at the nearest enemy if you press Q on Soraka ]]--

local NearestEnemy = nil

function OnWndMsg(msg, wParam) -- Captures the pressed keys
    if msg == KEY_DOWN and wParam == 0x51 then CastE() end -- 0x51 = Q
end

function CastE()
    for i=1, heroManager.iCount do -- first we get the nearest champ
        local Enemy = heroManager:GetHero(i)
        if ValidTarget(NearestEnemy) and ValidTarget(Enemy) then
            if GetDistance(Enemy) < GetDistance(NearestEnemy) then
                NearestEnemy = Enemy
            end
        else
            NearestEnemy = Enemy
        end
    end

    if myHero:GetDistance(NearestEnemy) <= 725 and wait == 1 then CastSpell(_E, NearestEnemy) end
end
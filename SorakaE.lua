local NearestEnemy = nil

function OnWndMsg(msg, wParam)
    if msg == KEY_DOWN and wParam == 0x51 then CastE() end
end

function CastE()
	for i=1, heroManager.iCount do
		local Enemy = heroManager:GetHero(i)
        if ValidTarget(NearestEnemy) and ValidTarget(Enemy) then
        	if GetDistance(Enemy) < GetDistance(NearestEnemy) then
            	NearestEnemy = Enemy
            end
    	else
            NearestEnemy = Enemy
    	end
	end

	if myHero:GetDistance(NearestEnemy) <= 725 then CastSpell(_E, NearestEnemy) end
end
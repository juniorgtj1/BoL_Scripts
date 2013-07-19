if myHero.charName ~= "Varus" then return end
local hotkeyQ, hotkeyW, hotkeyE, hotkeyR = string.byte("Q"), string.byte("W"), string.byte("E"), string.byte("R")

--[[	Prediction	]]--
local qpos, epos, rpos = nil, nil, nil -- predicted positions
local qhc, ehc, rhc = 0, 0, 0 -- hitchances
local Q_RANGE, Q_SPEED, Q_DELAY, Q_WIDTH = 1600, 1850, 0, 60
local E_RANGE, E_SPEED, E_DELAY, E_WIDTH = 925, 1500, 0.242, 100
local R_RANGE, R_SPEED, R_DELAY, R_WIDTH = 1190, 1950, 0.25, 80
local qp, ep, rp = nil, nil, nil

--[[	TS stuff	]]--
local ts = nil
local CURRENT_ENEMY = nil

--[[	Q stuff	]]--
local cast = false
local tick = GetTickCount()
local qChargeTime = 0
local qTarget = nil
local waitDelay = 2000
local dynamicRange = 0
local bBlowQ = false
local OVERSHOOT_RANGE = 70

--[[	W debuffs	]]--
local poisonedtimets2 = 0
local poisonedtimets3 = 0
local poisonedtime2 = {}
local poisonedtime3 = {}
local enemyTable = GetEnemyHeroes()
local N_ENEMYES = 0
local lastBlightProc = {}
local bPoisonUp = false
local delayQE = 3000

--[[	R stuff	]]--
local bBlowR = false
local bAllowR = false

--[[	AA stuff and timers	]]--
local poisonRecheckTimer = GetTickCount()
local qFixTimer = GetTickCount()
local rTimer = 0
local drawTimer = 0
local eTimer = GetTickCount()

local lastAttack = 0
local AttackDelay = 0

--[[	Is abylity ready	]]--
local QREADY, EREADY, RREADY = false, false, false

function OnSendPacket(packet2)
	local packet2New = Packet(packet2) --smartcast fix
    if packet2.header == 0xE6 and cast then -- 2nd cast of channel spells packet2
		packet2.pos = 5
        spelltype = packet2:Decode1()
		if spelltype == 0x80 then -- 0x80 == Q
            packet2.pos = 1
            packet2:Block()
        end
    end
	if packet2New:get('name') == 'S_CAST' then
		if packet2New:get('spellId') == _R and VConfig.autoult then
			if not bAllowR then
				packet2:block()
			else
				bAllowR = false
			end
		end
	end
end

function OnLoad()
	PrintChat("<font color='#CCCCCC'> >> Varus Helper QWER 1.8 loaded (credits going to grey(prediction), hex(base), klokje(fixes for Q), manciuszz (ts tune)! <<</font>")
	PrintChat("DONT CHANGE KEYBINDS VIA SHIFT MENU! Edit in code (line#2).")
	VConfig = scriptConfig("Varus Helper", "VarusHelper")
	VConfig:addParam("blowQold", "Cast Q to enemy / mousepos", SCRIPT_PARAM_ONKEYDOWN, false, hotkeyQ)
	VConfig:addParam("cancelQ", "Q/R emergency cancel", SCRIPT_PARAM_ONKEYDOWN, false, hotkeyW)
	VConfig:addParam("EActive", "Cast E", SCRIPT_PARAM_ONKEYDOWN, false, hotkeyE)
	VConfig:addParam("autoult", "Aim R automatically (u still need to press R)", SCRIPT_PARAM_ONOFF, true)
	VConfig:addParam("tryPrioritizeQ", "Always use Q first to proc stacks", SCRIPT_PARAM_ONOFF, false)
	VConfig:addParam("drawcirclesSelf", "Draw Circles - Self", SCRIPT_PARAM_ONOFF, false)
	VConfig:addParam("drawcirclesEnemy", "Draw Circles - Enemy", SCRIPT_PARAM_ONOFF, false)
	VConfig:addParam("arrangeTS", "Auto arrange priority (if dont work disable and double F9)", SCRIPT_PARAM_ONOFF, true)
	
	qp = TargetPredictionVIP(Q_RANGE, Q_SPEED, Q_DELAY, Q_WIDTH)
	ep = TargetPredictionVIP(E_RANGE, E_SPEED, E_DELAY, E_WIDTH)
	rp = TargetPredictionVIP(R_RANGE, R_SPEED, R_DELAY, R_WIDTH) -- updated from data files (100)
	
	ts = TargetSelector(TARGET_LOW_HP_PRIORITY, 1600, DAMAGE_MAGIC)
	ts.name = "VaruZ"
	VConfig:addTS(ts)
	N_ENEMYES = heroManager.iCount / 2
	for i=1, N_ENEMYES do lastBlightProc[i] = 0 end
	for i=1, N_ENEMYES do poisonedtime2[i] = 0 end
	for i=1, N_ENEMYES do poisonedtime3[i] = 0 end
	if VConfig.arrangeTS then 
		sortEnemyList()
	end
end

function SetPriority(table, hero, priority)
    for i=1, #table, 1 do
        if hero.charName:find(table[i]) ~= nil then
            TS_SetHeroPriority(priority, hero.charName)
        end
    end
end

function sortEnemyList()
	local enemyteam = 0
	if myHero.team == 100 then
		enemyteam = 200
	else
		enemyteam = 100
	end
    for j=1, N_ENEMYES-1 do
        for i=1, N_ENEMYES-1 do
			if TS_GetPriority(enemyTable[i], enemyteam) > TS_GetPriority(enemyTable[i+1], enemyteam) then
				t = enemyTable[i]
				enemyTable[i] = enemyTable[i+1]
				enemyTable[i+1] = t
			end
        end
    end
end

function findlowHpEnemy()
	enemyTableLowHp = GetEnemyHeroes()

    for j=1, N_ENEMYES-1 do
        for i=1, N_ENEMYES-1 do
			if enemyTableLowHp[i].health > enemyTableLowHp[i+1].health then
				t = enemyTableLowHp[i]
				enemyTableLowHp[i] = enemyTableLowHp[i+1]
				enemyTableLowHp[i+1] = t
			end
        end
    end	
	
	for i, enemy in ipairs(enemyTableLowHp) do
		if enemy and enemy.valid and enemy.team ~= myHero.team and not enemy.dead and enemy.visible then
			t1, t2, qpos = qp:GetPrediction(enemy)
			if qpos and GetDistance(qpos) < dynamicRange then
				return enemy
			end
		end
	end
	return nil
end

function blowQ() -- cast Q to lowhp enemy or mousepos
	closestEnemy = findlowHpEnemy()
	if closestEnemy and ValidTarget(closestEnemy, 2000) then
		t1, t2, qpos = qp:GetPrediction(closestEnemy)
	else
		qpos = nil
	end
	CastQ2FAST()
end

function fixQ() -- cast Q to enemy or cancel
	closestEnemy = findlowHpEnemy()
	if closestEnemy and ValidTarget(closestEnemy, 1600) then
		t1, t2, qpos = qp:GetPrediction(closestEnemy)
		if qpos then
			CastQ2FAST()
		else
			CastSpell(10)
			cast = false
		end
	else
		CastSpell(10)
		cast = false
	end
end

function OnWndMsg(msg, key)
    if key == hotkeyQ then
        if msg == KEY_UP then
            bBlowQ = true
        else
			bBlowQ = false
		end
    end
    if key == hotkeyR and VConfig.autoult then
        if msg == KEY_UP or msg == KEY_DOWN then
            rTimer = GetTickCount()
		end
    end
end

function OnTick()
	ts:update()

	AttackDelay = (( 1000 * ( -0.435 + (0.625/0.658)) ) / (myHero.attackSpeed/(1/0.658)))
	
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)	

	if cast then
		qChargeTime = math.max(0, GetTickCount()-tick)
		qChargeTime = math.min(qChargeTime, 2000)
	else
		qChargeTime = 0
	end
	dynamicRange = 925 + (0.3375 * qChargeTime)
	if qChargeTime < 300 then
		dynamicRange = dynamicRange - OVERSHOOT_RANGE
	end
	
	-- Q fix section
	if GetTickCount() - qFixTimer > 99 then
		qFixTimer = GetTickCount()
		if cast and (qTarget and not ValidTarget(qTarget, 1600)) then --automat fix
			closestEnemy = findlowHpEnemy()
			if closestEnemy and GetDistance(closestEnemy) < 450 then
				fixQ()
			end
		end
		if cast and bBlowQ then --cast Q to enemy or mousepos
			blowQ()
			bBlowQ = false
		end
		if cast and VConfig.cancelQ then --drop Q
			CastSpell(10)
			cast = false
		elseif VConfig.cancelQ then
			rTimer = 0
		end
	end
	
	--R
	if not bBlowR and RREADY and GetTickCount() - rTimer < 5000 then
		bBlowR = true
	else
		bBlowR = false
	end	
	if bBlowR and not cast then
		if RREADY then
			koeff = 0.6
			for i, enemy in ipairs(enemyTable) do
				if ValidTarget(enemy) then		
					rhc = rp:GetHitChance(enemy)
					rpos = rp:GetPrediction(enemy)
					if rpos and rhc > koeff and GetDistance(rpos) < R_RANGE then
						bAllowR = true
						CastSpell(_R, rpos.x, rpos.z)
						rTimer = 0
						return
					end
				end
				koeff = koeff + 0.3/N_ENEMYES				
			end
		end
	end   
	
	--E
	if VConfig.EActive and not cast and GetTickCount() - eTimer > 100 then
		eTimer = GetTickCount()
		if EREADY then
			bestHc = 0
			bestPred = nil
			for i, enemy in ipairs(enemyTable) do
				if ValidTarget(enemy) then
					epos = ep:GetPrediction(enemy)
					ehc = ep:GetHitChance(enemy)
					if epos and GetDistance(epos) < E_RANGE and ehc > 0.7 then
						bestHc = ehc
						bestPred = epos
					end
				end
			end
			if bestPred then
				--CastSpell(_E, bestPred.x, bestPred.z)
				pE = CLoLPacket(0x9A)
				pE:EncodeF(myHero.networkID)
				pE:Encode1(2) --E
				pE:EncodeF(bestPred.x)
				pE:EncodeF(bestPred.z)
				pE:EncodeF(0)
				pE:EncodeF(0)
				pE:EncodeF(GetTarget().networkID)
				pE.dwArg1 = 1
				pE.dwArg2 = 0
				SendPacket(pE)				
			end
		end
	end		
	
	-- poison buff recheck every 50-100 ms
	if GetTickCount() - poisonRecheckTimer > 99 then
		poisonRecheckTimer = GetTickCount()
		-- update range
		delayQE = 3*AttackDelay + 1000	
		bPoisonUp = false
		for i, enemy in ipairs(enemyTable) do -- scan enemyes for Q/E proc
			if cast then bPoisonUp = true end
			if ValidTarget(enemy, 1600) then
				if poisonedtime2[i] ~= 0 or poisonedtime3[i] ~= 0 then
					if not TargetHaveBuff("varuswdebuff", enemy) then
						poisonedtime2[i] = 0
						poisonedtime3[i] = 0
					else
						bPoisonUp = true
					end
				end
			end
		end
	end
	
	if ((QREADY or EREADY) and bPoisonUp) then
		bPoisonUp = false
		for i, enemy in ipairs(enemyTable) do -- scan enemyes for Q/E proc
			CURRENT_ENEMY = enemy
			if ValidTarget(CURRENT_ENEMY, 1600) then
				QREADY = (myHero:CanUseSpell(_Q) == READY)
				EREADY = (myHero:CanUseSpell(_E) == READY)
				RREADY = (myHero:CanUseSpell(_R) == READY)
				
				poisonedtimets2 = poisonedtime2[i]
				poisonedtimets3 = poisonedtime3[i]
				
				qpos = qp:GetPrediction(CURRENT_ENEMY)
				qhc = qp:GetHitChance(CURRENT_ENEMY)
				epos = ep:GetPrediction(CURRENT_ENEMY)
				ehc = ep:GetHitChance(CURRENT_ENEMY)

				--[[	Auto Proc	]]--
				if not cast and ((not QREADY and EREADY) or (QREADY and EREADY and not VConfig.tryPrioritizeQ)) then -- E
					if epos and ehc > 0.7 and (GetTickCount() - lastBlightProc[i] > delayQE) and GetDistance(epos) < E_RANGE then
						if GetTickCount() - poisonedtimets3 < 12000 or (GetTickCount() - poisonedtimets2 < 5000 and GetDistance(epos) > E_RANGE / 2) then
							lastBlightProc[i] = GetTickCount()
							--CastSpell(_E, epos.x, epos.z)
							pE = CLoLPacket(0x9A)
							pE:EncodeF(myHero.networkID)
							pE:Encode1(2) --E
							pE:EncodeF(epos.x)
							pE:EncodeF(epos.z)
							pE:EncodeF(0)
							pE:EncodeF(0)
							pE:EncodeF(GetTarget().networkID)
							pE.dwArg1 = 1
							pE.dwArg2 = 0
							SendPacket(pE)
							return
						end
					end
				end
				if (QREADY and not EREADY) or (QREADY and EREADY and VConfig.tryPrioritizeQ) or (QREADY and EREADY and epos and GetDistance(epos) > E_RANGE) or (QREADY and cast) then -- Q
					if not cast and (GetDistance(CURRENT_ENEMY) < 1600 - 2*CURRENT_ENEMY.ms or GetDistance(CURRENT_ENEMY) < 900) and GetTickCount() - poisonedtimets3 < 12000 and (GetTickCount() - lastBlightProc[i] > delayQE) then
						CastQ1()
						qTarget = CURRENT_ENEMY
						lastBlightProc[i] = GetTickCount()
						return
					end
					if cast and qpos and GetDistance(qpos) < dynamicRange and qTarget and CURRENT_ENEMY.networkID == qTarget.networkID and qhc > 0.6 and (GetTickCount()-tick > 300 or (GetDistance(qpos) < 800 and GetTickCount()-tick > 150)) then -- Q on 3 stacks end
						CastQ2()
						qTarget = nil
						lastBlightProc[i] = GetTickCount()
						return
					end				
				end
			end
		end
	end
end

function OnDraw()
	if VConfig.drawcirclesSelf and not myHero.dead then
		if myHero:CanUseSpell(_Q) == READY and not cast then DrawCircle(myHero.x, myHero.y, myHero.z, Q_RANGE, 0xFF0000) end
		if myHero:CanUseSpell(_Q) == READY and cast then DrawCircle(myHero.x, myHero.y, myHero.z, dynamicRange, 0xFF0000) end
	end
	
	if VConfig.drawcirclesEnemy and RREADY and GetTickCount() - rTimer < 5000 and GetTickCount() - drawTimer > 0 then
		PrintFloatText(myHero, 6, "Auto R active! Press W to cancel")
		drawTimer = GetTickCount() + 500
	end
end

function OnProcessSpell(unit, spell)
	if unit.isMe and spell.name:find("Varus") and spell.name:find("Attack") then
		lastAttack = GetTickCount()
	end
end

function OnCreateObj(object)
	if object ~= nil and object.valid and object.name == "VarusQChannel.troy" and GetDistance(object) < 150 then
		cast = true
	end
	if object ~= nil and object.valid and object.name == "VarusW_counter_01.troy" then
		for i, enemy in ipairs(enemyTable) do
			if enemy ~= nil and ValidTarget(enemy, 1000) and enemy.valid and enemy.visible and enemy.team ~= myHero.team and TargetHaveBuff("varuswdebuff", enemy) and GetDistance(enemy, object) < 150 then
				poisonedtime2[i] = 0
				poisonedtime3[i] = 0
			end
		end
	end
	if object ~= nil and object.valid and object.name == "VarusW_counter_02.troy" then
		for i, enemy in ipairs(enemyTable) do
			if enemy ~= nil and ValidTarget(enemy, 1000) and enemy.valid and enemy.visible and enemy.team ~= myHero.team and TargetHaveBuff("varuswdebuff", enemy) and GetDistance(enemy, object) < 150 then
				poisonedtime2[i] = GetTickCount()
				poisonedtime3[i] = 0
			end
		end
	end
	if object ~= nil and object.valid and object.name == "VarusW_counter_03.troy" then
		for i, enemy in ipairs(enemyTable) do
			if enemy ~= nil and ValidTarget(enemy, 1000) and enemy.valid and enemy.visible and enemy.team ~= myHero.team and TargetHaveBuff("varuswdebuff", enemy) and GetDistance(enemy, object) < 150 then
				poisonedtime2[i] = 0
				poisonedtime3[i] = GetTickCount()
			end
		end
	end
end	

function OnDeleteObj(object)
	if object ~= nil and object.valid and object.name == "VarusQChannel.troy" and GetDistance(object) < 300 then
		cast = false
		qTarget = nil
	end
	if object ~= nil and object.valid and (object.name == "VarusW_counter_02.troy") then
		for i, enemy in ipairs(enemyTable) do
			if enemy ~= nil and enemy.valid and enemy.visible and enemy.team ~= myHero.team and not TargetHaveBuff("varuswdebuff", enemy) and GetDistance(enemy, object) < 150 then
				poisonedtime2[i] = 0
			end
		end
	end
	if object ~= nil and object.valid and (object.name == "VarusW_counter_03.troy") then
		for i, enemy in ipairs(enemyTable) do
			if enemy ~= nil and enemy.valid and enemy.visible and enemy.team ~= myHero.team and not TargetHaveBuff("varuswdebuff", enemy) and GetDistance(enemy, object) < 150 then
				poisonedtime3[i] = 0
			end
		end
	end	
end

function CastQ1() --start cast
	if not cast and myHero:CanUseSpell(_Q) == READY then
		if qpos then
			CastSpell(_Q, qpos.x, qpos.z)
		elseif CURRENT_ENEMY then
			CastSpell(_Q, CURRENT_ENEMY.x, CURRENT_ENEMY.z)
		else
			CastSpell(_Q, mousePos.x, mousePos.z)
		end
        cast = true
        tick = GetTickCount()
    end
end

function CastQ2() -- end cast
	if qpos then
		cast = false
		pQ2 = CLoLPacket(0xE6)
		pQ2:EncodeF(myHero.networkID)
		pQ2:Encode1(128) --Q
		pQ2:EncodeF(qpos.x)
		pQ2:EncodeF(qpos.y)
		pQ2:EncodeF(qpos.z)
		pQ2.dwArg1 = 1
		pQ2.dwArg2 = 0
		SendPacket(pQ2)
		tick = GetTickCount()
    end
end

function CastQ2FAST() -- end cast
	if qpos and cast then
		cast = false
		pQ2 = CLoLPacket(0xE6)
		pQ2:EncodeF(myHero.networkID)
		pQ2:Encode1(128) --Q
		pQ2:EncodeF(qpos.x)
		pQ2:EncodeF(qpos.y)
		pQ2:EncodeF(qpos.z)
		pQ2.dwArg1 = 1
		pQ2.dwArg2 = 0
		SendPacket(pQ2)
		tick = GetTickCount()
    elseif cast then
		cast = false
		pQ2 = CLoLPacket(0xE6)
		pQ2:EncodeF(myHero.networkID)
		pQ2:Encode1(128) --Q
		pQ2:EncodeF(mousePos.x)
		pQ2:EncodeF(mousePos.y)
		pQ2:EncodeF(mousePos.z)
		pQ2.dwArg1 = 1
		pQ2.dwArg2 = 0
		SendPacket(pQ2)
		tick = GetTickCount()	
	end
end
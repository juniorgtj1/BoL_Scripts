require 'SOW'
require 'SourceLib'
require 'VPrediction'

_RANGES = {[_Q] = 112.5, [_W] = 125, [_E] = 88888, [_R] = 900} -- Updating in OnBuff
_DELAYS = {[_Q] = 0.5, [_W] = 0.25, [_R] = 0.25}
_SPEEDS = {[_Q] = math.huge, [_E] = 1500, [_R] = 2200} -- E updates in OnDash
_ANGLES = {[_R] = 45*math.pi/180}

function OnLoad()
	_MENU = scriptConfig('Devastating Riven', 'driven')
	_MENU:addParam('enabled', 'Combo', SCRIPT_PARAM_ONKEYDOWN, false, string.byte('A'))
	_MENU:addParam('ultimate', 'Use ultimate', SCRIPT_PARAM_ONOFF, true)

	_TS = SimpleTS(STS_LESS_CAST_PHYSICAL)
	_PREDICTION = VPrediction()
	_SOW = SOW(_PREDICTION)
	_SOW:LoadToMenu(_MENU, _TS)
	_SOW:RegisterAfterAttackCallback(AfterAttack)
	_SOW.Menu.Mode = 2

	AdvancedCallback:bind('OnGainBuff', function(unit, buff) OnBuff(unit, buff, false) end)
	AdvancedCallback:bind('OnUpdateBuff', function(unit, buff) OnBuff(unit, buff, false) end)
	AdvancedCallback:bind('OnLoseBuff', function(unit, buff) OnBuff(unit, buff, true) end)

	print('[DS] Riven: This is a test lol')
end

function OnProcessSpell(object, spell)
	if object.isMe and _MENU.enabled then
		local target = GetTarget() or spell.target

		if ValidTarget(target) and target.type == myHero.type then
			if spell.name == 'RivenTriCleave' then -- _Q
				DelayAction(function()
					if CastE(target) == false then
						Packet('S_MOVE', {x = target.x, y = target.z}):send()
					end
				end, _DELAYS[_Q] + GetLatency() / 2000)
			end

			if spell.name == 'RivenMartyr' then -- _W
				DelayAction(function()
					if CastE(target) == false then
						if _MENU.ultimate then
							CastR1()
						end
					end
				end, _DELAYS[_W] + GetLatency() / 2000)
			end

			if spell.name == 'RivenFeint' then -- _E
				if CastW(target) == false and CastTiamat() == false then
					SendChat('/l')
				end
			end

			if spell.name == 'RivenFengShuiEngine' then -- _R first cast
				if CastE(target) == false and CastTiamat() == false then
					SendChat('/l')
				end
			end

			if spell.name == 'rivenizunablade' then -- _R second cast
				if CastE(target) == false and CastQ(target) == false and CastTiamat() == false then
					SendChat('/l')
				end
			end

			if spell.name == 'ItemTiamatCleave' then -- Tiamat / Hydra
				if CastSpell(_W) == false and CastQ(target) == false and CastE(target) == false then
					SendChat('/l')
				end
			end
		end
	end
end

function OnTick()
	CheckR()
end

function OnDash(unit, dash)
	if unit.isMe then
		_SPEEDS[_E] = dash.speed
	end
end

function OnBuff(unit, buff, isLose)
	if buff and buff.name and unit and unit.isMe then
		UpdateRanges(buff.name, isLose)
	end
end

function AfterAttack(target, mode)
	if _MENU.enabled then
		CastQ(target)
	end
end

function CastQ(target)
	if ValidTarget(target) then
		local predictionPos = _PREDICTION:GetCircularAOECastPosition(target, _DELAYS[_Q], _RANGES[_Q], _RANGES[_Q], _SPEEDS[_Q], myHero, false)

		if predictionPos ~= nil and  GetDistanceSqr(target.visionPos, predictionPos) <= _RANGES[_Q] * _RANGES[_Q] and CastSpell(_Q, predictionPos.x, predictionPos.z) then
			DelayAction(function() _SOW:resetAA() end, _DELAYS[_Q] + 0.25)
			return true
		end
	end

	return false
end

function CastW(target)
	if ValidTarget(target) then
		local predictionPos = _PREDICTION:GetPredictedPos(target, _DELAYS[_W], nil, myHero, false)

		if predictionPos ~= nil and GetDistanceSqr(target.visionPos, predictionPos) <= _RANGES[_W] * _RANGES[_W] and CastSpell(_W) then
			DelayAction(function() _SOW:resetAA() end, _DELAYS[_W] + 0.25)
			return true
		end
	end

	return false
end

function CastE(target)
	local predictionPos = _PREDICTION:GetPredictedPos(target, _RANGES[_E] / _SPEEDS[_E], nil, myHero, false)

	if predictionPos ~= nil then
		local endPos = Vector(myHero.visionPos) + _RANGES[_E] * (Vector(predictionPos) - Vector(myHero.visionPos)):normalized()

		if IsWall(D3DXVECTOR3(predictionPos.x, predictionPos.y, predictionPos.z)) == false and CastSpell(_E, predictionPos.x, predictionPos.z) then
			DelayAction(function() _SOW:resetAA() end, 0.25)
			return true
		end
	end

	return false
end

function CastR1(target)
	if ValidTarget(target) and GetComboDmg(target) > target.health then
		return CastSpell(_R)
	end

	return false
end

function CastR2(target)
	if ValidTarget(target) then
		local predictionPos = _PREDICTION:GetConeAOECastPosition(target, _DELAYS[_R], _ANGLES[_R], _RANGES[_R], _SPEEDS[_R], myHero)

		if predictionPos ~= nil and GetDistanceSqr(target.visionPos, predictionPos) <= _RANGES[_R] * _RANGES[_R] and CastSpell(_R, predictionPos.x, predictionPos.z) then
			DelayAction(function() _SOW:resetAA() end, _DELAYS[_R] + 0.25)
			return true
		end
	end

	return false
end

function CastTiamat()
	if CastItem(3077) or CastItem(3074) then
		DelayAction(function() _SOW:resetAA() end, 0.25)
		return true
	end

	return false
end

function GetComboDmg(target)
	local count = 0
	local totalDmg = 0

	if myHero:CanUseSpell(_Q) == READY then
		count = count + 3
		totalDmg = totalDmg + getDmg('Q', target, myHero) * 3
	end

	if myHero:CanUseSpell(_W) == READY then
		count = count + 1
		totalDmg = totalDmg + getDmg('W', target, myHero)
	end

	if myHero:CanUseSpell(_E) == READY then
		count = count + 1
	end

	if myHero:CanUseSpell(_R) == READY then
		count = count + 2
		totalDmg = totalDmg + getDmg('R', target, myHero)
	end

	totalDmg = totalDmg + getDmg('P', target, myHero) * count

	return totalDmg
end

function CheckR()
	for _, enemy in pairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, _RANGES[_R]) and getDmg('R', enemy, myHero) > enemy.health + enemy.hpRegen/5 * (_DELAYS[_R] + GetDistance(enemy) / _SPEEDS[_R]) then
			CastR2(enemy)
		end
	end
end

function UpdateRanges(name, isLose)
	if name == 'RivenFengShuiEngine' then
		for index, range in pairs(_RANGES) do
			_RANGES[index] = isLose and (range - 50) or (range + 50)
		end
	end

	if name == 'riventricleavesoundtwo' then
		_RANGES[_Q] = isLose and 112.5 or 150
	end
end

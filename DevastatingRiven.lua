require 'SOW'
require 'SourceLib'
require 'VPrediction'

function OnLoad()
	_MENU = scriptConfig('Devastating Riven', 'driven')
	_MENU:addParam('enabled', 'Combo', SCRIPT_PARAM_ONKEYDOWN, false, string.byte('A'))
	_MENU:addParam('ultimate', 'Use ultimate', SCRIPT_PARAM_ONKEYDOWN, false, string.byte('A'))
	_TS = SimpleTS(STS_LESS_CAST_PHYSICAL)
	_SOW = SOW(VPrediction())
	_SOW:LoadToMenu(_MENU, _TS)
	_SOW:RegisterAfterAttackCallback(AfterAttack)
	_SOW.Menu.Mode = 2

	print('This is a test lol')
end

function OnProcessSpell(object, spell)
	if object.isMe and _MENU.enabled then
		local target = GetTarget() or spell.target

		if ValidTarget(target) then
			if spell.name == 'RivenTriCleave' then -- _Q
				DelayAction(function()
					if CastSpell(_E, target.x, target.z) == false then
						Packet('S_MOVE', {}):send()
					end
				end, 0.5 + GetLatency() / 2000)
			end
			if spell.name == 'RivenMartyr' then -- _W
				DelayAction(function()
					if CastSpell(_E, target.x, target.z) == false then
						if _MENU.ultimate then
							CastSpell(_R)
						end
					end
				end, 0.25 + GetLatency() / 2000)
			end
			if spell.name == 'RivenFeint' then -- _E
				if CastItem(3077) == false and CastItem(3074) == false and CastW() == false then
					SendChat('/l')
				end
			end
			if spell.name == 'RivenFengShuiEngine' then -- _R first cast
				if CastSpell(_E, target.x, target.z) == false and CastItem(3077) == false and CastItem(3074) == false then
					SendChat('/l')
				end
			end
			if spell.name == 'rivenizunablade' then -- _R second cast
				if CastSpell(_E, target.x, target.z) == false and CastQ(target) == false then
					CastSpell(_E, target.x, target.z)
				end
			end
			if spell.name == 'ItemTiamatCleave' then -- Tiamat / Hydra
				if CastSpell(_W) == false and CastQ(target) == false then
					CastSpell(_E, target.x, target.z)
				end
			end
		end
	end
end

function AfterAttack(target, mode)
	if _MENU.enabled then
		CastQ(target)
	end
end

function CastQ(target)
	if ValidTarget(target) then
		if CastSpell(_Q, target.x, target.z) then
			DelayAction(function() _SOW:resetAA() end, 0.75)
			return true
		end
	end

	return false
end

function CastW()
	if CastSpell(_W) then
		DelayAction(function() _SOW:resetAA() end, 0.5)
		return true
	end

	return false
end
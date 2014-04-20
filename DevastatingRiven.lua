require 'SOW'
require 'SourceLib'
require 'VPrediction'

function OnLoad()
	_MENU = scriptConfig('Devastating Riven', 'driven')
	_MENU:addParam('enabled', 'Combo', SCRIPT_PARAM_ONKEYDOWN, false, string.byte('A'))
	_TS = SimpleTS(STS_LESS_CAST_PHYSICAL)
	_SOW = SOW(VPrediction())
	_SOW:LoadToMenu(_MENU, _TS)
	_SOW:RegisterAfterAttackCallback(AfterAttack)
end

function OnProcessSpell(object, spell)
	if object.isMe and _MENU.enabled then
		local target = GetTarget() or spell.target

		if ValidTarget(target) then
			if spell.name == 'RivenTriCleave' then
				Packet('S_MOVE',{}):send()
			end
			if spell.name == 'RivenFengShuiEngine' or spell.name == 'rivenizunablade' then
				if myHero:CanUseSpell(_Q) == READY then
					CastSpell(_Q, target.x, target.z)
				else
					CastSpell(_E, target.x, target.z)
				end
			end
			if spell.name == 'RivenKiBurst' then
				DelayAction(function()
					if GetInventoryItemIsCastable(3074) then
						CastItem(3074)
					elseif GetInventoryItemIsCastable(3077) then
						CastItem(3077)
					else
						CastSpell(_Q, target.x, target.z)
					end
				end, 0.25)
			end
		end
	end
end

function AfterAttack(target, mode)
	if _MENU.enabled and ValidTarget(target) then
		if myHero:CanUseSpell(_W) == READY then
			CastSpell(_W)
		else
			CastSpell(_Q, target.x, target.z)
		end
	end
end

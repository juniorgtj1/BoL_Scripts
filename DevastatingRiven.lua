function OnProcessSpell(object, spell)
	if object.isMe and IsKeyDown(string.byte('A')) then
		local target = GetTarget() or spell.target

		if ValidTarget(target) then
			if spell.name == 'RivenTriCleave' then
				Packet('S_MOVE',{}):Send()
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
			if spell.name:lower():find('attack') then
				DelayAction(function()
					if myHero:CanUseSpell(_W) == READY then
						CastSpell(_W)
					else
						CastSpell(_Q, target.x, target.z)
					end
				end, spell.windUpTime - GetLatency() / 2000)
			end
		end
	end
end
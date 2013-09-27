local ZSlot, ZReady = nil, nil
local ZUseTick = nil
local BuffTable = {
	["Zed"] = {spellName = "zedultexecute", onApply = false},
	["Vladimir"] = {spellName = "vladimirhemoplaguedebuff", onApply = false},
	["Fizz"] = {spellName = "fizzmarinerdoombomb", onApply = true}
}

function OnLoad()
	PrintChat("<font color='#CCCCCC'>>> Auto Zhonyas by PQMailer loaded <<</font>")
end

function OnTick()
	ZSlot = GetInventorySlotItem(3157)
	ZReady = (ZSlot~= nil and myHero:CanUseSpell(ZSlot) == READY)

	if ZReady and (ZUseTick ~= nil and GetTickCount() > ZUseTick) then
		CastSpell(ZSlot)
		ZUseTick = nil
	end
end

function OnGainBuff(unit, buff)
	if unit.isMe and buff.valid and ZReady then
		for _, Buff in pairs(BuffTable) do
			if Buff.spellName == buff.name then
				if Buff.onApply then
					ZUseTick = GetTickCount()
				else
					ZUseTick = GetTickCount() + (buff.duration*1000 - 2500)
				end
			end
		end
	end
end
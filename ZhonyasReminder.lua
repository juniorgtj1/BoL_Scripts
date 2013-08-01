--[[ Reminds you to use zhonyas in the heat of fights ]]--

local ZSlot, ZReady = nil, nil
local nextTick = 0
local Delay = 2000 -- 2000 ms = 2 sek

function OnTick()
    if myHero.dead then return true end

    ZSlot = GetInventorySlotItem(3157)
    ZReady = (ZSlot~= nil and myHero:CanUseSpell(ZSlot) == READY)

    if myHero.health/myHero.maxHealth <= 0.4 and ZReady and (nextTick == 0 or GetTickCount() > nextTick + Delay) then
        PrintFloatText(myHero, 10, "BITCH PLS! ZHONYAS!")
        nextTick = GetTickCount()
    end
end
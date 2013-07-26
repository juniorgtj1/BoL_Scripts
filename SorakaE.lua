--[[ Simple script that casts E at the nearest enemy if you press Q on Soraka; Thanks to Sida ]]--

if myHero.charName ~= "Soraka" then return end

local qAt = 0
function OnProcessSpell(unit, spell)
   if unit.isMe and spell.name == myHero:GetSpellData(_Q).name then
      qAt = GetTickCount()
   end
end
 
function OnTick()
   if GetTickCount() > qAt + 900 and GetTickCount() < qAt + 1500 then
      for _, enemy in pairs(GetEnemyHeroes()) do
         if ValidTarget(enemy, 725) then
            CastSpell(_E, enemy)
         end
      end
   end
end
-- [[ Simple Vayne kick ]] --
if myHero.charName ~= "Vayne" then return end

Kicks = {
    { charName = "Caitlyn", spellName = "CaitlynAceintheHole"},
    { charName = "FiddleSticks", spellName = "Crowstorm"},
    { charName = "FiddleSticks", spellName = "DrainChannel"},
    { charName = "Galio", spellName = "GalioIdolOfDurand"},
    { charName = "Karthus", spellName = "FallenOne"},
    { charName = "Katarina", spellName = "KatarinaR"},
    { charName = "Malzahar", spellName = "AlZaharNetherGrasp"},
    { charName = "MissFortune", spellName = "MissFortuneBulletTime"},
    { charName = "Nunu", spellName = "AbsoluteZero"},
    { charName = "Pantheon", spellName = "Pantheon_GrandSkyfall_Jump"},
    { charName = "Shen", spellName = "ShenStandUnited"},
    { charName = "Urgot", spellName = "UrgotSwap2"},
    { charName = "Varus", spellName = "VarusQ"},
    { charName = "Warwick", spellName = "InfiniteDuress"}
}

function OnLoad()
    print(">> KickIt loaded")
end

function OnProcessSpell(unit, spell)
    if myHero:CanUseSpell(_E) == READY then
        for _, kick in pairs(Kicks) do
            if ValidTarget(unit, 550) and unit.name == kick.charName and spell.name == kick.spellName and unit.team ~= myHero.team then
                print("KICK")
                CastSpell(_E, enemy)
            end
        end
    end
end
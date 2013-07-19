--[[
                 _.--""--._
                /  _    _  \
             _  ( (_\  /_) )  _
            { \._\   /\   /_./ }
            /_"=-.}______{.-="_\
             _  _.=("""")=._  _
            (_'"_.-"`~~`"-._"'_)
             {_"            "_}

         Vayne's Mighty Assistant
                    by Manciuszz.

         » Auto-Condemn = Automatically condemns enemy into walls, structures(inhibitors, towers, nexus).
            • Prediction[VIP ONLY]/No Prediction mode

         » Manual Condemn-Assistant = Draws a circle of predicted position after condemn.
            • Draw Arrow/Simple circle

         » Disable Auto-Condemn on certain champions in-game.
]]

--[[
    » Some data out of the game files:
    VayneCondemn(Spell E) projectileSpeed = 2200.0 units/s
    VayneCondemn(Spell E) projectileName = vayne_E_mis.troy
    VayneCondemn(Spell E) range at all lvls = 715+ units
    VayneCondemn(Spell E) max Knockback range at all lvls = 450 units
    VayneCondemn(Spell E) channel time at all lvls = 0.25 miliseconds(probably true, but feels to high)
]]

if myHero.charName ~= "Vayne" then return end
require "MapPosition"

local VayneAssistant

local mapPosition = MapPosition()
local enemyTable = GetEnemyHeroes()
local tp = TargetPredictionVIP(1000, 2200, 0.25)
local AllClassKey = 16

-- Code -------------------------------------------

function OnLoad()
    VayneAssistant = scriptConfig("Vayne's Mighty Assistant", "VayneAssistant")
    VayneAssistant:addParam("autoCondemn", "Auto-Condemn OnHold:", SCRIPT_PARAM_ONKEYTOGGLE, true, GetKey("N"))
    VayneAssistant:addParam("switchKey", "Switch key mode:", SCRIPT_PARAM_ONOFF, true)

    VayneAssistant:addParam("BLANKSPACE", "", SCRIPT_PARAM_INFO, "")
    VayneAssistant:addParam("FeaturesNSettings", "              Features & Settings", SCRIPT_PARAM_INFO, "")
    VayneAssistant:addParam("CondemnAssistant", "Condemn Visual Assistant:", SCRIPT_PARAM_ONOFF, true)
    VayneAssistant:addParam("pushDistance", "Push Distance", SCRIPT_PARAM_SLICE, 300, 0, 450, 0) -- Reducing this value means that the enemy has to be closer to the wall, so you could cast condemn.
    VayneAssistant:addParam("eyeCandy", "DrawArrow/Simple circle:", SCRIPT_PARAM_ONOFF, true)
    if not VIP_USER then
        VayneAssistant:addParam("shootingMode", "Currently: No prediction", SCRIPT_PARAM_INFO, "NOT VIP")
    else
        VayneAssistant:addParam("shootingMode", "Prediction/No prediction", SCRIPT_PARAM_ONOFF, false)
    end
    VayneAssistant:addParam("wallDetection", "Intersection/Inside wall:", SCRIPT_PARAM_ONOFF, true)

    -- Override in case it's stuck.
--    VayneAssistant.pushDistance = 300
    VayneAssistant.autoCondemn = true

    VayneAssistant:addParam("BLANKSPACE2", "", SCRIPT_PARAM_INFO, "")
    VayneAssistant:addParam("BLANKSPACE3", "          Disable Auto-Condemn on", SCRIPT_PARAM_INFO, "")
    for i, enemy in ipairs(enemyTable) do
        VayneAssistant:addParam("disableCondemn"..i, " >> "..enemy.charName, SCRIPT_PARAM_ONOFF, false)
        VayneAssistant["disableCondemn"..i] = false -- Override
    end
    PrintChat(" >> Vayne's Mighty Assistant!")
end

function OnDraw()
    if myHero.dead then return end

    if IsKeyDown(AllClassKey) then
        if VayneAssistant.switchKey then
            VayneAssistant._param[1].pType = 3
            VayneAssistant._param[1].text = "Auto-Condemn Toggle:"
        else
            VayneAssistant._param[1].pType = 2
            VayneAssistant._param[1].text = "Auto-Condemn OnHold:"
        end

        VayneAssistant._param[7].text = VayneAssistant.eyeCandy and "Currently: Drawing Arrows" or "Currently: Drawing Circles"
        VayneAssistant._param[8].text = VayneAssistant.shootingMode and VIP_USER and "Currently: Using Predictions" or "Currently: No prediction"
        VayneAssistant._param[9].text = VayneAssistant.wallDetection and "Currently: Using Intersection Method" or "Currently: Using Simple Wall Check"
        if not VIP_USER then VayneAssistant.shootingMode = "NOT VIP" end
    end

    if VayneAssistant.autoCondemn and myHero:CanUseSpell(_E) == READY then
        local casted = false
        for i, enemyHero in ipairs(enemyTable) do
            if not VayneAssistant["disableCondemn"..i] then
                if not casted then
                    if enemyHero ~= nil and enemyHero.valid and not enemyHero.dead and enemyHero.visible and GetDistance(enemyHero) <= 715 then

                        local enemyPosition = VayneAssistant.shootingMode and VIP_USER and tp:GetPrediction(enemyHero) or enemyHero
                        local PushPos = GetDistance(enemyPosition) > 65 and enemyPosition + (Vector(enemyHero) - myHero):normalized()*(VayneAssistant.pushDistance) or nil

                        if PushPos ~= nil and enemyPosition ~= nil then
                            local enemyHeroPoint     = Point(enemyPosition.x, enemyPosition.z)
                            local condemnPoint       = Point(PushPos.x, PushPos.z)
                            local condemnLineSegment = LineSegment(enemyHeroPoint, condemnPoint)
                            local wallDetection      = VayneAssistant.wallDetection and mapPosition:intersectsWall(condemnLineSegment) or mapPosition:inWall(condemnPoint)

                            if PushPos ~= nil and VayneAssistant.eyeCandy then
                                DrawArrows(enemyPosition, PushPos, 80, 0xFFFFFF, 0)
                            else
                                DrawCircle(PushPos.x, PushPos.y, PushPos.z, 65, 0xFFFF00)
                            end

                            if wallDetection then
                                CastSpell(_E, enemyHero)
                                casted = true
                            end
                        end
                    end
                end
            end
        end
    end
end
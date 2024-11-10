if Game.HashStringSDBM("Zed") ~= Game.localPlayer.hash then
    return
end
--normaly we shuld use waypoint to detect we can blink the shadow but in ls we cant figure out with waypoint.
Champions.CppScriptMaster(false)
local mycommon = Environment.LoadModule("mycommon")
local player = Game.localPlayer
local menu = nil
local lastwcast = 0

--local castposnew = nil

Champions.Q = SDKSpell.Create(SpellSlot.Q, 925, DamageType.Physical)
Champions.W = SDKSpell.Create(SpellSlot.W, 700, DamageType.Physical)
Champions.E = SDKSpell.Create(SpellSlot.E, 290, DamageType.Physical)
Champions.R = SDKSpell.Create (SpellSlot.R, math.flt_max, DamageType.Physical)

Champions.Q:SetSkillshot(0.25, 100, 1700, SkillshotType.SkillshotLine, true, CollisionFlag.CollidesWithYasuoWall, HitChance.Medium, false)


menu = UI.Menu.CreateMenu("DarkZed", "Dark Zed", 2)
Champions.CreateBaseMenu(menu, 0)
-- Prediction Menu
local predictionMenu = menu:AddMenu("predictionMenu", "Prediction Hitchance")
predictionMenu:AddList("qHitchance", "Q Hitchance", { "Low", "Medium", "High", "Very High" }, 2)

-- Combo Menu
local combo = menu:AddMenu("combo", "Combo")
combo:AddCheckBox("combo_q", "Use Q in Combo")
combo:AddCheckBox("combo_q_save", "Try to Save Q for W")
combo:AddCheckBox("combo_w", "Use W in Combo")
combo:AddCheckBox("combo_w_onlyErange", "Use W Only in E Range")
combo:AddCheckBox("combo_wonlyCombo", "Use W Only When Full Combo Available")
combo:AddList("combo_w_targetmode", "W Target Mode", { "Line", "Most Targets" }, 1)
combo:AddCheckBox("combo_w_2", "Use W2")
combo:AddCheckBox("combo_w_2_safety", "Check Safety for W2 / R2")
combo:AddSlider("combo_w_2_safety_count", "Safety Enemy Count >= ", 3, 0, 5)
combo:AddSlider("combo_w_2_safety_range", "Safety Check Range <= ", 500, 0, 1000)
combo:AddList("combo_w_mode", "W2/R2 Mode", { "Always", "If Killable", "If HP > Target HP" }, 2)
combo:AddCheckBox("combo_e", "Use E in Combo")
combo:AddCheckBox("combo_r", "Use R in Combo")
combo:AddCheckBox("combo_r_2", "Use R2 in Combo")
combo:AddList("combo_r_mode", "R Mode", { "Always", "Only Full Combo Available", "If Killable", "If Target HP <= X%" }, 2)
combo:AddSlider("combo_r_health", "Min R Health <= %", 40, 0, 100)
combo:AddKeyBind("toverdive_key", "Tower Dive Key", 1, true, true):PermaShow(true, true)

-- Harass Menu
local harass = menu:AddMenu("harass", "Harass")
harass:AddCheckBox("harass_q", "Use Q in Harass")
harass:AddCheckBox("harass_e", "Use E in Harass")

-- Killsteal Menu
local killsteal = menu:AddMenu("killsteal", "Killsteal")
killsteal:AddCheckBox("killsteal_q", "Killsteal with Q")
killsteal:AddCheckBox("killsteal_w", "Killsteal with W")
killsteal:AddCheckBox("killsteal_e", "Killsteal with E")

-- Misc Menu
local misc = menu:AddMenu("misc", "Misc")
misc:AddCheckBox("misc_w_evade", "Use Shadow to Evade"):AddTooltip("Attempts to evade using W2/R2.")
misc:AddCheckBox("rsettarget", "Focus on Target Marked with R")
misc:AddSlider("misc_w_dangerlevel", "Minimum Evade Danger Level >= ", 4, 0, 5)
-- very lazy for this
-- misc:AddCheckBox("misc_doubleq", "Enable Double Q Bug", false):AddTooltip("This feature is currently very buggy, so I will disable it for a while until I fully optimize it.")


misc:AddMenu("miscevade", "Shadow Evade")
for _, enemy in ObjectManager.enemyHeroes:pairs() do
    misc.miscevade:AddCheckBox("darkzed"..enemy.charName..enemy.networkId, enemy.charName .. " [".. enemy:GetUniqueName() .. "]")
end
--Common.DelayAction(function()
--    local evadeSpellMetaData = Evade.GetSupportedSpellsMetaData()
 --   local slot = {[0] = "Q", "W", "E", "R", "D", "F"}
 --   for _, enemy in ObjectManager.enemyHeroes:pairs() do
--        misc:AddMenu("darkzed"..enemy.charName, enemy.charName)
--        if evadeSpellMetaData then
--            for i, v in evadeSpellMetaData:pairs() do
--                if i == enemy.charName then
--                    print("darkevade loaded.")
 --                   for k, b in v:pairs() do
 --                       if b.SlotType and slot[b.SlotType] then
 --                           misc["darkzed"..i]:AddCheckBox("darkzed"..b.Slot, "[" ..slot[b.Slot].. "] " ..k)
 --                       end
 --                   end
 --               end
 --           end
--        end
--    end
--end, 1)


--misc:AddCheckBox("aramzed", "Use ARAM Zed Logic")
-- misc:AddCheckBox("misc_r_evade", "Use R to Evade")

-- Farm Menu
local farm = menu:AddMenu("farm", "Farm")
farm:AddCheckBox("farm_q", "Farm with Q")
farm:AddCheckBox("farm_e", "Farm with E")
farm:AddSlider("farm_mana", "Minimum Energy to Save >= ", 100, 0, 200)

-- Drawing Menu
Champions.CreateColorMenu(menu:AddMenu("draw", "Drawing"), false)

-- Shadow Drawing Menu
local drawshadow = menu:AddMenu("drawshadow", "Shadow Drawing")
drawshadow:AddCheckBox("draw_shadow_q", "Draw Shadow Q")
drawshadow:AddCheckBox("draw_shadow_e", "Draw Shadow E")
drawshadow:AddCheckBox("draw_shadow_type", "Draw Shadow Type")
drawshadow:AddCheckBox("draw_shadow_time", "Draw Shadow Time")

local objHolder = {}

--why the fuck i cant get object owner
local create_object = function(object)
    if object and object.type == 3399847090 then
        if object:GetUniqueName() == "Shadow" and object:IsValid() and object.isAlly then
            local shadow_type = shadowtype(object)
            objHolder[object] = {
                object = object,
                networkId = object.networkId,
                pos = nil,
                type = "none",
                isUsed = false
            }
            return
        end
    end
end

local delete_object = function(object)
    for storedObject, objs in pairs(objHolder) do
        if objs.object.networkId == object.networkId then
            objHolder[storedObject] = nil
        end
        if not objs.object:IsValid() or not objs.object.isAlive then
            objHolder[storedObject] = nil
        end
    end
end

function length(pos)
    return math.sqrt(pos.x * pos.x + pos.y * pos.y + pos.z * pos.z)
end

function normalize(pos)
    return pos * (-1 / length(pos))
end

function extend(pos_a, pos_b, dist)
    local direction = normalize(pos_a - pos_b)
    return pos_a + direction * dist
end

--local zedwhash = 3020677060
--local zedrhash = 2963263615
local zedwnewhash = Game.fnvhash("zedwshadowbuff")
local zedrnewhash = Game.fnvhash("zedrshadowbuff")
local zedplayerwbuff = Game.fnvhash("ZedWHandler")
local zedplayerrbuff = Game.fnvhash("ZedR2")
shadowtype = function(objs)
    if objs:FindBuff(zedwnewhash) then
        return "W"
    end
    if objs:FindBuff(zedrnewhash) then
        return "R"
    end
    return "none"
end

zedwbuff = function()
    if player:FindBuff(zedplayerwbuff) then return true
    else return false end
end

zedwpressed = function()
    local flag = player:GetSpellSlot(Game.fnvhash("ZedW2"))
    if flag == 1 then
        return false
    elseif flag == 48 then
        return true
    end
    return false
end

zedrpressed = function()
    local flag = player:GetSpellSlot(Game.fnvhash("ZedR2"))
    if flag == 3 then
        return false
    elseif flag == 50 then
        return true
    end
    return false
end


local shadowgetramintime = function(objs)
    local type = shadowtype(objs)
    if type == "W" then
        return objs:FindBuff(zedwnewhash).leftTime
    elseif type == "R" then
        return objs:FindBuff(zedrnewhash).leftTime
    elseif type == "none" then
        return 0
    end
    return 0 
end

local haveshadowinrange = function(pos,range)
    for _, objs in pairs(objHolder) do
        if objs then
            if objs.object.serverPosition:Distance(pos) < range  then
                return true
            end
        end 
    end
    return false
end

local shadowbestdistance = function()
    local closest = nil
    dist = 100
    for _, objs in pairs(objHolder) do
        if objs then
            if objs.object.serverPosition:Distance(player.serverPosition) > dist then
                dist = objs.object.serverPosition:Distance(player.serverPosition)
                closest = objs.object
            end
        end 
    end
    return closest
end

local GetComboDamage = function(target)
    local dmg = 0
    if target == nil then return dmg end
    dmg = dmg + DamageLib.CalculateAutoAttackDamage(player, target)
    if Champions.Q:Ready() then
        dmg = dmg + Champions.Q:GetDamage(target)
    end
    if Champions.W:Ready() then
        if Champions.Q:Ready() then
            dmg = dmg + Champions.Q:GetDamage(target)
        end
        if Champions.E:Ready() then
            dmg = dmg + Champions.E:GetDamage(target)
        end
    end
    if Champions.E:Ready() then
        dmg = dmg + Champions.E:GetDamage(target)
    end
    if Champions.R:Ready() and zedrpressed() then
	--lazy for add r calc
        dmg = dmg + Champions.Q:GetDamage(target)
        dmg = dmg + Champions.E:GetDamage(target)
    end
    return dmg
end

local function GetPredictionForQ(objs,target)
    local input = PredictionInput.new(
        objs.serverPosition,             -- from
        objs.serverPosition,             -- rangeCheckFrom
        0.25,                              -- delay
        100,                               -- radius
        Champions.Q.range,                 -- range
        1700,                              -- speed
        SkillshotType.SkillshotLine,       -- type
        target,                            -- target
        false,                              -- bUseBoundingRadius
        true,                              -- bCollision
        CollisionFlag.CollidesWithYasuoWall, -- collisionFlags
        false,                             -- bAoe
        0                                  -- startOffset
    )
    
    local prediction = MovementPrediction.GetPrediction(input, true, true) -- bFt / coll
    
    return prediction
end

local MyGlowingCircleHash = Game.fnvhash("shadowcircle")
local colorgreen = Renderer.ColorInfo.new(0xFF00FF00, 0xFF00FF00, Renderer.GradientType.Linear)
local colorred = Renderer.ColorInfo.new(0xFFFF0000, 0xFFFF0000, Renderer.GradientType.Linear)
local fontSize = 30
local whiteColor = 0xFFFF0000

local function dmgdraw()
    for i, entity in ObjectManager.enemyHeroes:pairs() do
        if entity ~= nil then

            --local screenPos = entity.serverPosition:Project()
            if entity.isVisibleOnScreen then
            local buff = mycommon.GetBuff(entity, "zedrdeathmark")
            if buff then
                local bufftime = math.floor(buff.leftTime * 100 + 0.5) / 100
                local text = tostring("R "..bufftime)
                local tX, tY = Renderer.CalcTextSize(text, fontSize)
                Renderer.DrawWorldText(text, entity.serverPosition, Math.Vector2(-50, -50), fontSize,0xFF00FF00)
                return target
            end
            Renderer.DamageIndicatorRendering(entity, GetComboDamage(entity), DamageType.Physical, 0, false)
            end
        end
    end
end

local function draw()
  --  if castposnew then
   --     local radius = 50
   --     local sides = 32 -- Çemberin ne kadar düzgün olacağını belirler (32 kenarlı bir çember)
   --     local width = 2 -- Çizgi kalınlığı
         
   --     Renderer.DrawCircle3D(castposnew, radius, sides, width, whiteColor)
  --  end
    for _, objs in pairs(objHolder) do
        if objs and objs.object.isAlive and objs.object:IsValid() then
            local isUsed = objs.isUsed
            local shadowTypeValue = shadowtype(objs.object)
            local uniqueHashQ = Game.fnvhash("shadowcircle_q" .. tostring(objs.networkId))
            local uniqueHashE = Game.fnvhash("shadowcircle_e" .. tostring(objs.networkId))
            if menu.drawshadow.draw_shadow_q.value and shadowTypeValue ~= "none" then
                local color = isUsed and colorred or colorgreen
                Renderer.DrawEffectCircle(uniqueHashQ, objs.object.position2D, Champions.Q.range, color, Renderer.EffectType.GlowingCircle2)
            end
            if menu.drawshadow.draw_shadow_e.value and shadowTypeValue ~= "none" then
                local color = isUsed and colorred or colorgreen
                Renderer.DrawEffectCircle(uniqueHashE, objs.object.position2D, Champions.E.range, color, Renderer.EffectType.GlowingCircle2)
            end
            if menu.drawshadow.draw_shadow_type.value then
                local objPos2D = objs.object.position2D
                local uniqueHashobj = Game.fnvhash("shadowcircle_onj" .. tostring(objs.networkId))
                local color = isUsed and colorred or colorgreen
                Renderer.DrawEffectCircle(uniqueHashobj, objs.object.position2D, 100, color, Renderer.EffectType.PulseCircle2)
                local text = isUsed and "Old " .. shadowTypeValue or shadowTypeValue
                local tX, tY = Renderer.CalcTextSize(text, fontSize)
                Renderer.DrawWorldText(text, objs.object.position, Math.Vector2(-tX / 2, 0), fontSize)
            end
            if menu.drawshadow.draw_shadow_time.value then
                local shadowtime = shadowgetramintime(objs.object)
                local roundedShadowTime = math.floor(shadowtime * 100 + 0.5) / 100
                local shadowtimeText = tostring(roundedShadowTime)
                --local shadowTimeWidth, shadowTimeHeight = Renderer.CalcTextSize(shadowtimeText, fontSize)
                Renderer.DrawWorldText(shadowtimeText, objs.object.position, Math.Vector2(-50 / 2, -25), fontSize)
            end
        end
    end
    dmgdraw()
end

local function Active()
    local tss = TargetSelector.GetTargets(math.flt_max, DamageType.Physical, player.serverPosition, false)
    if tss == nil then return end

    for _, target in tss:pairs() do
        local isKillstealQ = menu.killsteal.killsteal_q.value
        local isKillstealW = menu.killsteal.killsteal_w.value
        local isValidTarget = target:IsValidTarget(Champions.Q.range + Champions.W.range - 100)
        local isQReady = Champions.Q:Ready()
        local isWReady = Champions.W:Ready()
        local targetInWRange = player.serverPosition:Distance(target.serverPosition) < (Champions.Q.range + Champions.W.range - 50)
        local targetOutOfQRange = player.serverPosition:Distance(target.serverPosition) > Champions.Q.range
        local canKillWithQ = Champions.Q:GetDamage(target) > target.totalHealth
        local hasNoShadowInRange = not haveshadowinrange(target.serverPosition, Champions.Q.range)
        local isZedWBuffInactive = not zedwbuff()
        local isWPressed = zedwpressed()
        local hasSufficientMana = (Champions.Q:ManaCost() + Champions.W:ManaCost()) < player.mp
        local isWCastTimeValid = lastwcast + 0.25 < Game.GetTime()

        if isKillstealQ and isKillstealW and isValidTarget and isQReady and isWReady
           and targetOutOfQRange and targetInWRange and canKillWithQ
           and hasNoShadowInRange and isZedWBuffInactive and isWPressed
           and hasSufficientMana and isWCastTimeValid then
            Champions.W:Cast(target.serverPosition)
            lastwcast = Game.GetTime()
        end
        if shadowbestdistance() and (target:IsValidTarget(Champions.Q.range) or (shadowbestdistance() and target:IsValidTarget(shadowbestdistance().serverPosition:Distance(player.serverPosition) + Champions.Q.range))) then
            for _, objs in pairs(objHolder) do
                if objs and objs.object.isAlive and objs.object:IsValid() then
                    local result = GetPredictionForQ(objs.object, target)
                    local qDamage = Champions.Q:GetDamage(target)
                    local eDamage = Champions.E:GetDamage(target)
                    local totalDamage = qDamage + eDamage
                    if menu.killsteal.killsteal_q.value and Champions.Q:Ready() and qDamage > target.totalHealth and result and result.hitchance >= menu.predictionMenu.qHitchance.value then
                        Champions.Q:Cast(result.castPosition)
                    end
                    if menu.killsteal.killsteal_e.value and Champions.E:Ready() and eDamage > target.totalHealth and target.serverPosition:Distance(objs.object.serverPosition) < Champions.E.range then
                        Champions.E:Cast()
                    end
                    if menu.killsteal.killsteal_q.value and menu.killsteal.killsteal_e.value and Champions.Q:Ready() and Champions.E:Ready() and totalDamage > target.totalHealth and target.serverPosition:Distance(objs.object.serverPosition) < Champions.E.range then
                        if result and result.hitchance >= menu.predictionMenu.qHitchance.value then
                            Champions.Q:Cast(result.castPosition)
                        end
                        Common.DelayAction(function()
                            Champions.E:Cast()
                        end, 0.10)      
                    end
                end
            end
        end
        local result = GetPredictionForQ(player, target)
        if menu.killsteal.killsteal_q.value and Champions.Q:Ready() and Champions.Q:GetDamage(target) > target.totalHealth and result and result.hitchance >= menu.predictionMenu.qHitchance.value then
            Champions.Q:Cast(result.castPosition)
        end
        if menu.killsteal.killsteal_e.value and Champions.E:Ready() and Champions.E:GetDamage(target) > target.totalHealth and target.serverPosition:Distance(player.serverPosition) < Champions.E.range then
            Champions.E:Cast()
        end

        local newtotaldamage = 0
        local echeckedonce = false
        if shadowbestdistance() and (target:IsValidTarget(Champions.Q.range) or 
          (shadowbestdistance() and target:IsValidTarget(shadowbestdistance().serverPosition:Distance(player.serverPosition) + Champions.Q.range))) then

         for _, objs in pairs(objHolder) do
              if objs and objs.object.isAlive and objs.object:IsValid() then
                 local result = GetPredictionForQ(objs.object, target)
                    local qDamage = Champions.Q:GetDamage(target)
                    local eDamage = Champions.E:GetDamage(target)

                 if menu.killsteal.killsteal_q.value and Champions.Q:Ready() and 
                    result and result.hitchance >= 3 and 
                     target.position:Distance(objs.object.serverPosition) < Champions.Q.range - 100 and 
                    MovementPrediction.GetPrediction(target, 0.25).unitPosition:Distance(objs.object.serverPosition) < Champions.Q.range - 100 then

                     newtotaldamage = newtotaldamage + qDamage
                 end
            
                 if menu.killsteal.killsteal_e.value and Champions.E:Ready() and 
                    target.serverPosition:Distance(objs.object.serverPosition) < Champions.E.range and 
                       not echeckedonce then

                        newtotaldamage = newtotaldamage + eDamage
                      echeckedonce = true
                    end
                end
            end
        end

        local result = GetPredictionForQ(player, target)
        if menu.killsteal.killsteal_q.value and Champions.Q:Ready() and 
           result and result.hitchance >= menu.predictionMenu.qHitchance.value and 
           target.position:Distance(player.serverPosition) < Champions.Q.range - 100 and 
          MovementPrediction.GetPrediction(target, 0.25).unitPosition:Distance(player.serverPosition) < Champions.Q.range - 100 then

           newtotaldamage = newtotaldamage + Champions.Q:GetDamage(target)
        end

        if menu.killsteal.killsteal_e.value and Champions.E:Ready() and 
         target.serverPosition:Distance(player.serverPosition) < Champions.E.range and 
         not echeckedonce then

          newtotaldamage = newtotaldamage + Champions.E:GetDamage(target)
          echeckedonce = true
        end
        if menu.killsteal.killsteal_q.value and Champions.Q:Ready() and newtotaldamage > target.totalHealth then
            Champions.Q:Cast(result.castPosition)
        end

        if menu.killsteal.killsteal_e.value and Champions.E:Ready() and newtotaldamage > target.totalHealth then
            Champions.E:Cast()
        end
    end
end

local function getclosesenemy(object, range)
    local tss = TargetSelector.GetTargets(range, DamageType.Physical, player.serverPosition, false)
    if not tss then return nil end

    local closestTarget = nil
    local closestDistance = math.flt_max

    for _, target in tss:pairs() do
        local distanceToPlayer = target.serverPosition:Distance(player.serverPosition)
        local extendedDistance = target.serverPosition:Extend(object.serverPosition, -100):Distance(player.serverPosition)

        if target:IsValidTarget(range) and distanceToPlayer <= range 
            and extendedDistance <= range 
            and object.networkId ~= target.networkId then

            if distanceToPlayer < closestDistance then
                closestDistance = distanceToPlayer
                closestTarget = target
            end
        end
    end

    return closestTarget
end


function getfarthestenemy(object, range)
    local tss = TargetSelector.GetTargets(range, DamageType.Physical, player.serverPosition, false)
    if not tss then return nil end

    local farthestTarget = nil
    local farthestDistance = 0 

    for _, target in tss:pairs() do
        if target.networkId ~= object.networkId and target:IsValidTarget(range) then
        local distanceToPlayer = target.serverPosition:Distance(player.serverPosition)
        local extendedDistance = extend(object.serverPosition, target.serverPosition, -100):Distance(player.serverPosition)

        if  distanceToPlayer <= range 
            and extendedDistance <= range 
            and object.networkId ~= target.networkId then

            if distanceToPlayer > farthestDistance then
                farthestDistance = distanceToPlayer
                farthestTarget = target
            end
        end
        end
    end

    return farthestTarget
end


local function GetBestTarget()
    local shadow = shadowbestdistance()
    local range = shadow and shadow.serverPosition:Distance(player.serverPosition) + Champions.Q.range - 100 or Champions.Q.range

    local tss = TargetSelector.GetTargets(range, DamageType.Physical, player.serverPosition, false)
    if not tss then return end
    if menu.misc.rsettarget.value then
        for _, target in tss:pairs() do
            local buff = mycommon.GetBuff(target, "zedrdeathmark")
            if buff and target:IsValidTarget(range) then
                return target
            end
        end
    end
    local target = TargetSelector.GetTarget(range, DamageType.Physical)
    if target and target:IsValidTarget(range) then
        return target
    end
    local tss2 = TargetSelector.GetTargets(range + Champions.W.range, DamageType.Physical, player.serverPosition, false)
    if not tss2 then return end
    for _, target in tss2:pairs() do
        if target and target:IsValidTarget(range + Champions.W.range) then

           -- local result = GetPredictionForQ(player, target)
           -- if result and result.hitchance >= menu.predictionMenu.qHitchance.value then
          --      return target
            --end
            for _, objs in pairs(objHolder) do
                if objs and objs.object.isAlive and objs.object:IsValid() then
                    local result = GetPredictionForQ(objs.object, target)
                    if result and result.hitchance >= menu.predictionMenu.qHitchance.value then
                        return target
                    end                    
                end
            end
            if target and target:IsValidTarget(range + Champions.W.range) then
                return target
            end          
        end
    end  
end

local function Rlogic()
    local target = TargetSelector.GetTarget(625, DamageType.Physical)
    if target and target:IsValidTarget(625) then
        if mycommon.IsInsideEnemyTurret(target.serverPosition) then return end
        if menu.combo.combo_r.value and Champions.R:Ready() and menu.combo.combo_r_mode.value == 0 and zedrpressed() then
            Champions.R:Cast(target)
        end
        if menu.combo.combo_r.value and Champions.R:Ready() and menu.combo.combo_r_mode.value == 1 and zedrpressed() and Champions.Q:Ready() and Champions.W:Ready() and Champions.E:Ready() and (Champions.Q:ManaCost() + Champions.W:ManaCost()) < player.mp then
            Champions.R:Cast(target)
        end
        if menu.combo.combo_r.value and Champions.R:Ready() and menu.combo.combo_r_mode.value == 2 and zedrpressed() and GetComboDamage(target) > target.totalHealth then
            Champions.R:Cast(target)
        end
        if menu.combo.combo_r.value and Champions.R:Ready() and menu.combo.combo_r_mode.value == 3 and zedrpressed() and target.hpPercent <= menu.combo.combo_r_health.value then
            Champions.R:Cast(target)
        end
    end
end

local function canCastW(target, castpos)
    local distanceCheck = MovementPrediction.GetPrediction(target, 0.25).unitPosition:Distance(castpos) < Champions.W.range + Champions.E.range
    local isWall = castpos:IsWallOfType(CellFlag.Wall, 30)
    --print(isWall)
    --castposnew = castpos
    --print(castpos)
    return distanceCheck and not isWall
end


local function Combo()
    local target = GetBestTarget()
    if target then
        if not menu.combo.toverdive_key.value and mycommon.insideaturret() then
            return
        end
        Rlogic()
        if menu.combo.combo_w.value and Champions.W:Ready() then
            if zedwpressed() and not zedwbuff() then
                if menu.combo.combo_w_onlyErange.value then
                    if target:IsValidTarget(Champions.W.range + Champions.E.range - 70) then
                        if menu.combo.combo_wonlyCombo.value then
                            if Champions.Q:Ready() and Champions.E:Ready() then
                                if menu.combo.combo_w_targetmode.value == 0 and lastwcast + 0.30 < Game.GetTime() then
                                    local extendtarget = shadowbestdistance()
                                    local castpos = target.serverPosition
                                    if extendtarget then
                                        castpos = extend(target.serverPosition, extendtarget.serverPosition, -300)
                                    elseif not extendtarget then
                                        castpos = extend(target.serverPosition, player.serverPosition, -100)
                                    end
                                    if player.serverPosition:Distance(castpos) > Champions.W.range then
                                        castpos = extend(player.serverPosition, castpos, Champions.W.range)
                                    end
                                    if canCastW(target,castpos) then
                                        Champions.W:Cast(castpos)
                                    end
                                elseif menu.combo.combo_w_targetmode.value == 1 and lastwcast + 0.30 < Game.GetTime() then
                                    local closesenemy = getfarthestenemy(target, 700)
                                    local castpos = target.serverPosition
                                    if closesenemy then 
                                        local distance = target.serverPosition:Distance(closesenemy.serverPosition)
                                        castpos = extend(target.serverPosition, closesenemy.serverPosition, distance)
                                    elseif not closesenmy then
                                        castpos = extend(target.serverPosition, player.serverPosition, -100)
                                    end
                                    if player.serverPosition:Distance(castpos) > Champions.W.range then
                                        castpos = extend(player.serverPosition, castpos, Champions.W.range)
                                    end
                                    if canCastW(target,castpos) then
                                        Champions.W:Cast(castpos)
                                    end
                                end
                            end
                        else
                            if Champions.Q:Ready() or target.serverPosition:Distance(player.serverPosition) < Champions.W.range + Champions.E.range - 70 then
                            if menu.combo.combo_w_targetmode.value == 0 and lastwcast + 0.30 < Game.GetTime() then
                                local extendtarget = shadowbestdistance()
                                local castpos = target.serverPosition
                                if extendtarget then
                                    castpos = extend(target.serverPosition, extendtarget.serverPosition, -300)
                                elseif not extendtarget then
                                    castpos = extend(target.serverPosition, player.serverPosition, -100)
                                end
                                if player.serverPosition:Distance(castpos) > Champions.W.range then
                                        castpos = extend(player.serverPosition, castpos, Champions.W.range)
                                    end
                                if canCastW(target,castpos) then
                                    Champions.W:Cast(castpos)
                                end                            elseif menu.combo.combo_w_targetmode.value == 1 and lastwcast + 0.30 < Game.GetTime() then
                                local closesenemy = getfarthestenemy(target, 700)
                                local castpos = target.serverPosition
                                if closesenemy then 
                                    local distance = target.serverPosition:Distance(closesenemy.serverPosition)
                                    castpos = extend(target.serverPosition, closesenemy.serverPosition, distance)
                                elseif not closesenmy then
                                    castpos = extend(target.serverPosition, player.serverPosition, -100)
                                end
                                if player.serverPosition:Distance(castpos) > Champions.W.range then
                                        castpos = extend(player.serverPosition, castpos, Champions.W.range)
                                    end
                                if canCastW(target,castpos) then
                                    Champions.W:Cast(castpos)
                                end
                            end
                        end
                        end
                    end
                else
                    if target:IsValidTarget(Champions.W.range + Champions.Q.range - 70) then
                        if menu.combo.combo_wonlyCombo.value then
                            if Champions.Q:Ready() and Champions.E:Ready() then
                                if menu.combo.combo_w_targetmode.value == 0 and lastwcast + 0.30 < Game.GetTime() then
                                    local extendtarget = shadowbestdistance()
                                    local castpos = target.serverPosition
                                    if extendtarget then
                                        castpos = extend(target.serverPosition, extendtarget.serverPosition, -300)
                                    elseif not extendtarget then
                                        castpos = extend(target.serverPosition, player.serverPosition, -100)
                                    end
                                    if player.serverPosition:Distance(castpos) > Champions.W.range then
                                        castpos = extend(player.serverPosition, castpos, Champions.W.range)
                                    end
                                    if canCastW(target,castpos) then
                                        Champions.W:Cast(castpos)
                                    end                                
                                elseif menu.combo.combo_w_targetmode.value == 1 and lastwcast + 0.30 < Game.GetTime() then
                                    local closesenemy = getfarthestenemy(target, 700)
                                    local castpos = target.serverPosition
                                    if closesenemy then 
                                        local distance = target.serverPosition:Distance(closesenemy.serverPosition)
                                        castpos = extend(target.serverPosition, closesenemy.serverPosition, distance)
                                    elseif not closesenmy then
                                        castpos = extend(target.serverPosition, player.serverPosition, -100)
                                    end
                                    if player.serverPosition:Distance(castpos) > Champions.W.range then
                                        castpos = extend(player.serverPosition, castpos, Champions.W.range)
                                    end
                                    if canCastW(target,castpos) then
                                        Champions.W:Cast(castpos)
                                    end                                
                                end
                            end
                        else
                            if Champions.Q:Ready() or target.serverPosition:Distance(player.serverPosition) < Champions.W.range + Champions.E.range -70 then
                            if menu.combo.combo_w_targetmode.value == 0 and lastwcast + 0.30 < Game.GetTime() then
                                local extendtarget = shadowbestdistance()
                                local castpos = target.serverPosition
                                if extendtarget then
                                    castpos = extend(target.serverPosition, extendtarget.serverPosition, -300)
                                elseif not extendtarget then
                                    castpos = extend(target.serverPosition, player.serverPosition, -100)
                                end
                                if player.serverPosition:Distance(castpos) > Champions.W.range then
                                        castpos = extend(player.serverPosition, castpos, Champions.W.range)
                                end
                                if canCastW(target,castpos) then
                                    Champions.W:Cast(castpos)
                                end                               
                                elseif menu.combo.combo_w_targetmode.value == 1 and lastwcast + 0.30 < Game.GetTime() then
                                local closesenemy = getfarthestenemy(target, 700)
                                local castpos = target.serverPosition
                                if closesenemy then 
                                    local distance = target.serverPosition:Distance(closesenemy.serverPosition)
                                    castpos = extend(target.serverPosition, closesenemy.serverPosition, distance)
                                elseif not closesenmy then
                                    castpos = extend(target.serverPosition, player.serverPosition, -100)
                                end
                                if player.serverPosition:Distance(castpos) > Champions.W.range then
                                    castpos = extend(player.serverPosition, castpos, Champions.W.range)
                                end
                                if canCastW(target,castpos) then
                                    Champions.W:Cast(castpos)
                                end                               
                            end
                        end
                        end
                    end
                end
            end
        end
        for _, objs in pairs(objHolder) do
            if objs and objs.object.isAlive and objs.object:IsValid() then
                if menu.combo.combo_q.value and objs.object.serverPosition:Distance(target.serverPosition) < Champions.Q.range and Champions.Q:Ready() then
                    local result = GetPredictionForQ(objs.object, target)
                    if result and result.hitchance >= menu.predictionMenu.qHitchance.value then
                        Champions.Q:Cast(result.castPosition)
                    end
                end
                if menu.combo.combo_e.value and objs.object.serverPosition:Distance(target.serverPosition) < Champions.E.range and Champions.E:Ready() then
                    Champions.E:Cast()
                end
                if menu.combo.combo_w_2.value and not zedwpressed() and zedwbuff() and shadowtype(objs.object) == "W" then
                    if menu.combo.combo_w_2_safety.value and mycommon.GetEnemyCountInRange(objs.object.serverPosition,menu.combo.combo_w_2_safety_range.value) < menu.combo.combo_w_2_safety_count.value then
                        if not mycommon.IsInsideEnemyTurret(objs.object.serverPosition) then
                            if menu.combo.combo_w_mode.value == 0 and Champions.W:Ready() and objs.object.serverPosition:Distance(target.serverPosition) < 350 and objs.object.serverPosition:Distance(target.serverPosition) < player.serverPosition:Distance(target.serverPosition) - 50 and not zedwpressed() and zedwbuff() then
                                Champions.W:Cast()
                            end
                          --  if menu.combo.combo_w_mode.value == 0 and Champions.W:Ready() and objs.object.serverPosition:Distance(target.serverPosition) > Champions.E.range and objs.object.serverPosition:Distance(target.serverPosition) < 350 and objs.object.serverPosition:Distance(target.serverPosition) < player.serverPosition:Distance(target.serverPosition) - 50 and not zedwpressed() and zedwbuff() then
                          --      Champions.W:Cast()
                          --  end
                            if menu.combo.combo_w_mode.value == 1 and Champions.W:Ready() and objs.object.serverPosition:Distance(target.serverPosition) < 350 and GetComboDamage(target) > target.totalHealth and objs.object.serverPosition:Distance(target.serverPosition) < player.serverPosition:Distance(target.serverPosition) - 50 and not zedwpressed() and zedwbuff() then
                                Champions.W:Cast()
                            end
                           -- if menu.combo.combo_w_mode.value == 1 and Champions.W:Ready() and objs.object.serverPosition:Distance(target.serverPosition) > 350 and objs.object.serverPosition:Distance(target.serverPosition) < player.serverPosition:Distance(target.serverPosition) - 50 and not zedwpressed() and zedwbuff() then
                           --     Champions.W:Cast()
                          --  end
                            if menu.combo.combo_w_mode.value == 2 and Champions.W:Ready() and objs.object.serverPosition:Distance(target.serverPosition) < 350 and player.totalHealth > target.totalHealth and objs.object.serverPosition:Distance(target.serverPosition) < player.serverPosition:Distance(target.serverPosition) - 50 and not zedwpressed() and zedwbuff() then
                                Champions.W:Cast()
                            end
                          --  if menu.combo.combo_w_mode.value == 2 and Champions.W:Ready() and objs.object.serverPosition:Distance(target.serverPosition) > 350 and objs.object.serverPosition:Distance(target.serverPosition) < player.serverPosition:Distance(target.serverPosition) - 50 and not zedwpressed() and zedwbuff() then
                          --      Champions.W:Cast()
                          --  end
                        end
                    end
                end
                if menu.combo.combo_r_2.value and not zedrpressed() and shadowtype(objs.object) == "R" then
                    if menu.combo.combo_w_2_safety.value and mycommon.GetEnemyCountInRange(objs.object.serverPosition,menu.combo.combo_w_2_safety_range.value) < menu.combo.combo_w_2_safety_count.value then
                        if not mycommon.IsInsideEnemyTurret(objs.object.serverPosition) then
                            if menu.combo.combo_w_mode.value == 0 and Champions.R:Ready() and objs.object.serverPosition:Distance(target.serverPosition) < 350 and objs.object.serverPosition:Distance(target.serverPosition) < player.serverPosition:Distance(target.serverPosition) - 50 and not zedrpressed() then
                                Champions.R:Cast()
                            end
                            if menu.combo.combo_w_mode.value == 1 and Champions.R:Ready() and objs.object.serverPosition:Distance(target.serverPosition) < 350 and GetComboDamage(target) > target.totalHealth and objs.object.serverPosition:Distance(target.serverPosition) < player.serverPosition:Distance(target.serverPosition) - 50 and not zedrpressed() then
                                Champions.R:Cast()
                            end
                            if menu.combo.combo_w_mode.value == 2 and Champions.R:Ready() and objs.object.serverPosition:Distance(target.serverPosition) < 350 and player.totalHealth > target.totalHealth and objs.object.serverPosition:Distance(target.serverPosition) < player.serverPosition:Distance(target.serverPosition) - 50 and not zedrpressed() then
                                Champions.R:Cast()
                            end
                        end
                    end
                end
            end
        end 
        if menu.combo.combo_q.value and target:IsValidTarget(Champions.Q.range) and Champions.Q:Ready() then
            if menu.combo.combo_q_save.value and (not Champions.W:ReadyPredCast(2.5) or #objHolder > 0) then
                local result = GetPredictionForQ(player, target)
                if result and result.hitchance >= menu.predictionMenu.qHitchance.value then
                    Champions.Q:Cast(result.castPosition)
                end
            end
        end
        if menu.combo.combo_e.value and Champions.E:Ready() and target:IsValidTarget(Champions.E.range) then
            Champions.E:Cast()
        end
    end
    for _, objs in pairs(objHolder) do
        if objs and objs.object.isAlive and objs.object:IsValid() then
            if menu.combo.combo_e.value and Champions.E:Ready() and objs.object.serverPosition:CountEnemiesInRange(Champions.E.range) > 0 then
                Champions.E:Cast()
            end
        end
     end
end

local function harass()
    local target = GetBestTarget()
    if target then
       -- print(menu.combo.toverdive_key.value)
       -- print(mycommon.insideaturret())
        if not menu.combo.toverdive_key.value and mycommon.insideaturret() then
            return
        end 
            for _, objs in pairs(objHolder) do
                if objs and objs.object.isAlive and objs.object:IsValid() then
                    if menu.harass.harass_q.value and objs.object.serverPosition:Distance(target.serverPosition) < Champions.Q.range and Champions.Q:Ready() then
                        local result = GetPredictionForQ(objs.object, target)
                        if result and result.hitchance >= menu.predictionMenu.qHitchance.value then
                            Champions.Q:Cast(result.castPosition)
                        end
                    end
                    if menu.harass.harass_e.value and Champions.E:Ready() and objs.object.serverPosition:CountEnemiesInRange(Champions.E.range) > 0 then
                        Champions.E:Cast()
                    end
                end
            end
        if menu.harass.harass_q.value and target:IsValidTarget(Champions.Q.range) and Champions.Q:Ready() then
                local result = GetPredictionForQ(player, target)
                if result and result.hitchance >= menu.predictionMenu.qHitchance.value then
                    Champions.Q:Cast(result.castPosition)
                end
        end
        if menu.harass.harass_e.value and Champions.E:Ready() and target:IsValidTarget(Champions.E.range) then
            Champions.E:Cast()
        end
    end
end

local function FarmQCast()
    if not Champions.CanSpellFarm() then return end
    if not menu.farm.farm_q.value then return end
    if not Champions.Q:Ready() then return end
    if player.mp - Champions.Q:ManaCost() <= menu.farm.farm_mana.value then return end
    local best = nil
    for _, jungle in ObjectManager.enemyLaneMinions:pairs() do
        if jungle.position:Distance(player.position) <= Champions.Q.range - 30 and jungle:IsValid() and jungle.isVisible and jungle.isAlive and jungle.isAttacableUnit then
            if jungle.isSiegeMinion or jungle.isSuperMinion then
                if Champions.Q:GetDamage(jungle) > jungle.totalHealth then
                    Champions.Q:Cast(jungle)
                end
            end
            if not best then
                best = jungle
            end
            if jungle.totalHealth > best.totalHealth then
                best = jungle
            end
        end
    end
    if best and best.totalHealth > DamageLib.CalculateAutoAttackDamage(player, best) then
        Champions.Q:Cast(best)
    end
    for _, jungle in ObjectManager.jungleMinions:pairs() do
        if jungle.position:Distance(player.position) <= Champions.Q.range - 30 and jungle:IsValid() and jungle.isVisible and jungle.isAlive and jungle.isAttacableUnit and player:GetTarget() and player:GetTarget().networkId == jungle.networkId then
            if not best then
                best = jungle
            end
            if jungle.totalHealth > best.totalHealth then
                best = jungle
            end
        end
    end
    if best and best.totalHealth > DamageLib.CalculateAutoAttackDamage(player, best) then
        Champions.Q:Cast(best)
    end
end

local function FarmECast()
    if not Champions.CanSpellFarm() then return end
    if not menu.farm.farm_e.value then return end
    if not Champions.E:Ready() then return end
    if player.mp - Champions.E:ManaCost() <= menu.farm.farm_mana.value then return end
    if player.serverPosition:CountEnemyLaneMinionsInRange(Champions.E.range) >= 2 then
        Champions.E:Cast()
    end
    for _, jungle in ObjectManager.jungleMinions:pairs() do
        if jungle.position:Distance(player.position) <= Champions.E.range and jungle:IsValid() and jungle.isVisible and jungle.isAlive and jungle.isAttacableUnit and player:GetTarget() and player:GetTarget().networkId == jungle.networkId then
            Champions.E:Cast()
        end
    end
end

local lastdodge = 0
local function shadowevade()
    if player.isAlive then
        local indanger, dangerlevel = Evade.IsInsideSkillshots(player.position2D, true, false)
        
        if indanger and dangerlevel >= menu.misc.misc_w_dangerlevel.value then
            local skillshots = Evade.GetSkillshotsAtPosition(player.position2D)
            
            if skillshots and #skillshots > 0 then
                local wReady = Champions.W:Ready()
                local rReady = Champions.R:Ready()
                for i, ss in skillshots:pairs() do
                    local hittime = ss:GetHitRemainingTime(player.position2D)
                    
                    if hittime and hittime < 0.20 and menu.misc.miscevade["darkzed"..ss.Caster.charName..ss.Caster.networkId] and menu.misc.miscevade["darkzed"..ss.Caster.charName..ss.Caster.networkId].value then
                        for _, objs in pairs(objHolder) do
                            if objs and objs.object.isAlive and objs.object:IsValid() then
                                local objIndanger, _ = Evade.IsInsideSkillshots(objs.object.position2D, true, false)
                                
                                if not objIndanger then
                                    if wReady and not zedwpressed() and zedwbuff() and shadowtype(objs.object) == "W" and  lastdodge + 0.05 < Game.GetTime()  then
                                        Champions.W:Cast()
                                        lastdodge = Game.GetTime()
                                    end
                                    if rReady and not zedrpressed() and shadowtype(objs.object) == "R" and lastdodge + 0.05 < Game.GetTime() then
                                        Champions.R:Cast()
                                        lastdodge = Game.GetTime()
                                    end
                                end
                            end
                        end        
                    end
                end
            end
        end
    end
end



local function OnTick()
    shadowevade()
    Active()
    if bit.band(Orbwalker.activeMode, OrbwalkerMode.Combo) ~= 0 and Orbwalker.CanUseSpell() then
        Combo()
    end
    if bit.band(Orbwalker.activeMode, OrbwalkerMode.Harass) ~= 0 and Orbwalker.CanUseSpell() then
        harass()
    end
    if bit.band(Orbwalker.activeMode, OrbwalkerMode.LaneClear) ~= 0 and Orbwalker.CanUseSpell() then
        FarmQCast()
        FarmECast()
    end
end

local function OnUnload()
    Champions.Clean()
end

local function onfasttick()
    for _, objs in pairs(objHolder) do
        if not objs then goto continue end
        local currentShadowType = shadowtype(objs.object)
        if objs.type == "none" and currentShadowType ~= "none" and objs.pos == nil and not objs.isUsed then
            objs.pos = objs.object.serverPosition
            objs.type = currentShadowType
        end
        if objs.pos and objs.pos ~= objs.object.serverPosition then
            objs.isUsed = true
        end
        if currentShadowType == "W" and not zedwbuff() then
            objs.isUsed = true
        elseif currentShadowType == "R" and zedrpressed() then
            objs.isUsed = true
        end
        ::continue:: 
    end
end

--maybe later?
function OnSpellAnimationStart(sender, CastArgs)
    if sender.isHero and sender.isEnemy and menu.misc["darkzed"..sender.charName] then
      --  print(CastArgs.spell:GetName())
       if menu.misc["darkzed"..sender.charName]["darkzed"..CastArgs.slot] then
        local from = CastArgs.from
        local to = CastArgs.to

        local userPosition = Game.localPlayer.position

        local distance = from:Distance(to)
        --print("Distance to target:", distance)
      --  print("missle accel " ,CastArgs.spell.info.lineWidth)
        if userPosition:IsInRange(from, distance) then
       --     print("User is in the path of the spell!")
        else
       --     print("User is NOT in the path of the spell.")
        end

            local spellSpeed = CastArgs.spell.info.missileSpeed or 1000
        --    print(CastArgs.spell.info.targettingType)
            local timeToHit = distance / spellSpeed
            local totalTimeToHit = timeToHit + CastArgs.delay

          --  print("Time to hit the target (including delay):", totalTimeToHit)
    end
end
end

--Callback.Bind(CallbackType.OnSpellAnimationStart, function(sender, CastArgs) OnSpellAnimationStart(sender, CastArgs) end)
Callback.Bind(CallbackType.OnObjectCreate, function(object) create_object(object) end)
Callback.Bind(CallbackType.OnObjectRemove, function(object) delete_object(object) end)
Callback.Bind(CallbackType.OnImguiDraw, function() draw() end)
Callback.Bind(CallbackType.OnUnload, function() OnUnload() end)
Callback.Bind(CallbackType.OnTick, function() OnTick() end)
Callback.Bind(CallbackType.OnFastTick, function() onfasttick() end)


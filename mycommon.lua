
Champions.CppScriptMaster(false)
local player = Game.localPlayer
local menu = nil

local mycommon = {}

function mycommon.GetClosestAllyTurretPosition()
    return TurretTracker.GetClosestAllyTurretPosition()
end

function mycommon.GetClosestEnemyTurretPosition()
    return TurretTracker.GetClosestEnemyTurretPosition()
end

function mycommon.IsInsideEnemyTurret(position)
for _, turret in ObjectManager.enemyTurrets:pairs() do
    if turret and position:Distance(turret.serverPosition) < 975 then
        return true
    end
end
  return false
end

function mycommon.insideaturret()
    return TurretTracker.IsPlayerInsideTurret()
end

function mycommon.turretattackplayer()
    return TurretTracker.IsPlayerFocusedByTurret()
end

function mycommon.GetEnemyHeroes()
local heroes = {} 
for _, enemy in ObjectManager.enemyHeroes:pairs() do
    if enemy then
        table.insert(heroes, enemy)
    end
end
  return heroes
end

function mycommon.GetAllyHeroes()
local heroes = {}
for _, ally in ObjectManager.allyHeroes:pairs() do
    if ally then
        table.insert(heroes, ally)
    end
end
  return heroes
end

function mycommon.GetEnemyHeroesInRange(pos,range)
local pos = pos or player.serverPosition
local heroes = {}
for _, enemy in ObjectManager.enemyHeroes:pairs() do
    if enemy then
      if enemy.serverPosition:Distance(pos) < range then
        table.insert(heroes, enemy)
      end
    end
end
  return heroes
end

function mycommon.GetEnemyCountInRange(pos, range)
    local pos = pos or player.serverPosition
    local count = 0
    for _, enemy in ObjectManager.enemyHeroes:pairs() do
        if enemy and enemy.serverPosition:Distance(pos) < range and enemy.isAlive and enemy:IsValid() then
            count = count + 1
        end
    end
    return count
end

function mycommon.GetJungleMinionsInRange(pos, range)
    local pos = pos or player.serverPosition
    local jungleMinions = {}
    for _, minion in ObjectManager.jungleMinions:pairs() do
        if minion and minion:IsValidTarget(range,true,pos) then
            table.insert(jungleMinions, minion)
        end
    end
    return jungleMinions
end

function mycommon.GetLaneMinionsInRange(pos, range)
    local pos = pos or player.serverPosition
    local laneMinions = {}
    for _, minion in ObjectManager.enemyLaneMinions:pairs() do
        if minion and minion:IsValidTarget(range,true,pos) then
            table.insert(laneMinions, minion)
        end
    end
    return laneMinions
end

function mycommon.GetCountMinionsInRange(pos, range)
    local pos = pos or player.serverPosition
    local minionsInRange = {}

    for _, minion in ObjectManager.enemyMinions:pairs() do
        if minion and minion:IsValidTarget(range,true,pos) then
            table.insert(minionsInRange, minion)
        end
    end

    return #minionsInRange, minionsInRange
end


function mycommon.printallbuff(objs)
    if objs then
    print("Buffs:")
    local buffs = objs.buffManager.buffs
    for index = 1, #buffs do
        local buff = buffs[index]
        print("  Buff[" .. index .. "]:")
        print("    Name = " .. buff:GetName())
        print("    isValid = " .. tostring(buff.isValid))
        print("    startTime = " .. buff.startTime)
        print("    expireTime = " .. buff.expireTime)
        print("    leftTime = " .. buff.leftTime)
        print("    short = " .. buff.short)
        print("    int = " .. buff.int)
        print("    type = " .. buff.type)
        print("    owner = " .. tostring(buff.owner))
        print("    hash = " .. buff.hash)
        end
    end
    return nil
end

function mycommon.GetBuff(obj,name)
    local obj = obj or player
    local buffhash = Game.fnvhash(name)
    local buff = obj:FindBuff(buffhash)
    if buff and buff.isValid then
        return buff
    end
    return nil
end
function mycommon.GetPercentHealth(target)
  local obj = target or player
  --return (obj.totalHealth / obj.totalMaxHealth) * 100
  return obj.hpPercent
end

function mycommon.GetPercentMana(obj)
  local obj = obj or player
  --return (obj.totalMana / obj.totalMaxMana) * 100
  return obj.mpPercent
end

return mycommon





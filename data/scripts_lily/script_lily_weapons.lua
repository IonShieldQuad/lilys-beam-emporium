
local vter = mods.multiverse.vter
local userdata_table = mods.multiverse.userdata_table
local time_increment = mods.multiverse.time_increment
local check_paused = mods.multiverse.check_paused
local INT_MAX = 2147483647

--1 = MISSILES, 2 = FLAK, 3 = DRONES, 4 = PROJECTILES, 5 = HACKING
local defense_types = {
    DRONES = { [3] = true, [5] = true, name = "Drones" },
    MISSILES = { [1] = true, [2] = true, [5] = true, name = "All Solid Projectiles" },
    DRONES_MISSILES = { [1] = true, [2] = true, [3] = true, [5] = true, name = "All Solid Projectiles and Drones" },
    PROJECTILES = { [4] = true, name = "Non-Solid Projectiles" },
    PROJECTILES_MISSILES = { [1] = true, [2] = true, [4] = true, [5] = true, name = "All Projectiles" },
    ALL = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, name = "All" },
}

local ciwsRenderBeams = {}

--script.on_init(function ()
--    ciwsRenderBeams = {}
--end)

-- Returns a table of all crew belonging to the given ship on the room tile at the given point
local function get_ship_crew_point(shipManager, x, y, maxCount)
    local res = {}
    x = x // 35
    y = y // 35
    for crewmem in vter(shipManager.vCrewList) do
        if crewmem.iShipId == shipManager.iShipId and x == crewmem.x // 35 and y == crewmem.y // 35 then
            table.insert(res, crewmem)
            if maxCount and #res >= maxCount then
                return res
            end
        end
    end
    return res
end

local function dot(a, b)
    return a.X * b.X + a.Y * b.Y;
end
local function magnitude(vec)
    return math.sqrt(vec.X * vec.X + vec.Y * vec.Y);
end
local function angleBetween(b, c)
    return math.acos(dot(b, c) / (magnitude(b) * magnitude(c)));
end
local function addVec(a, b)
    return { X = a.X + b.X, Y = a.Y + b.Y }
end
local function subVec(a, b)
    return { X = a.X + b.X, Y = a.Y + b.Y }
end
local function mulVec(a, k)
    return { X = a.X * k, Y = a.Y * k }
end

local function toPointF(vec)
    return Hyperspace.Pointf(vec.X, vec.Y)
end

local function toVec(point)
    return { X = point.x, Y = point.y }
end

local function find_collision_point(target_pos, target_vel, interceptor_pos, interceptor_speed)
    local k = magnitude(target_vel) / interceptor_speed;
    local distance_to_target = magnitude(subVec(interceptor_pos, target_pos));

    local BA_vel = target_vel
    local CB = subVec(target_pos, interceptor_pos)

    local alpha = angleBetween(BA_vel, CB)
    local gamma = math.asin(k * math.sin(alpha))
    local beta = math.pi - alpha - gamma

    local ratio = distance_to_target / math.sin(beta)

    local kx = ratio * math.sin(gamma)
    local tti = kx / magnitude(target_vel)
    --local BA = mulVec(mulVec(target_vel, 1.0 / magnitude(target_vel))) * kx

    local intercept = addVec(target_pos, mulVec(target_vel, tti))

    return intercept;
end

if mods.lilybeams == nil then
    mods.lilybeams = {}
end

local function offset_point_direction(oldX, oldY, angle, distance)
    local newX = oldX + (distance * math.cos(math.rad(angle)))
    local newY = oldY + (distance * math.sin(math.rad(angle)))
    return Hyperspace.Pointf(newX, newY)
end

local function get_random_point_in_radius(center, radius)
    local r = radius * math.sqrt(math.random())
    local theta = math.random() * 2 * math.pi
    return Hyperspace.Pointf(center.x + r * math.cos(theta), center.y + r * math.sin(theta))
end

local function get_random_point_on_radius(center, radius)
    local r = radius
    local theta = math.random() * 2 * math.pi
    return Hyperspace.Pointf(center.x + r * math.cos(theta), center.y + r * math.sin(theta))
end

-----------------------------------------------------------------
-- BEAM HIT --
-----------------------------------------------------------------

local disintegrators = {}
disintegrators["LILY_BEAM_SIREN_1"] = 1
disintegrators["LILY_BEAM_SIREN_2"] = 1
disintegrators["LILY_BEAM_SIREN_3"] = 2
disintegrators["LILY_BEAM_SIREN_4"] = 3
disintegrators["LILY_BEAM_SIREN_FIRE"] = 0
disintegrators["LILY_BEAM_SIREN_LOCK"] = 0
disintegrators["LILY_BEAM_SIREN_1_CHAOS"] = 1
disintegrators["LILY_BEAM_SIREN_2_CHAOS"] = 1
disintegrators["LILY_BEAM_SIREN_3_CHAOS"] = 2
disintegrators["LILY_BEAM_SIREN_4_CHAOS"] = 3
disintegrators["LILY_BEAM_SIREN_FIRE_CHAOS"] = 0
disintegrators["LILY_BEAM_SIREN_LOCK_CHAOS"] = 0
disintegrators["LILY_BEAM_SIREN_1_ELITE"] = 2
disintegrators["LILY_BEAM_SIREN_2_ELITE"] = 2
disintegrators["LILY_BEAM_SIREN_3_ELITE"] = 3
disintegrators["LILY_BEAM_SIREN_4_ELITE"] = 4
disintegrators["LILY_BEAM_SIREN_FIRE_ELITE"] = 1
disintegrators["LILY_BEAM_SIREN_LOCK_ELITE"] = 1
disintegrators["LILY_SIREN_TRANSPORT_HER_ARTILLERY"] = 4
local chaosfire = {}
chaosfire["LILY_SIREN_TRANSPORT_C_ARTILLERY"] = 60
chaosfire["LILY_BEAM_SIREN_FIRE"] = 20
chaosfire["LILY_BEAM_SIREN_FIRE_CHAOS"] = 40
chaosfire["LILY_BEAM_SIREN_FIRE_ELITE"] = 60
local chaoslock = {}
chaosfire["LILY_BEAM_SIREN_LOCK"] = 20
chaosfire["LILY_BEAM_SIREN_LOCK_CHAOS"] = 40
chaosfire["LILY_BEAM_SIREN_LOCK_ELITE"] = 60

local frostBeams = {}
frostBeams["LILY_BEAM_FROST"] = { removeOxygen = true }
frostBeams["LILY_SIREN_TRANSPORT_B_ARTILLERY_I"] = { removeOxygen = true }
frostBeams["LILY_SIREN_MV_TRANSPORT_ARTILLERY"] = { removeOxygen = false }


local specalWidthBeams = {}
specalWidthBeams["LILY_FOCUS_ION_HEAVY"] = { 3, 0, -1 }
specalWidthBeams["LILY_BEAM_SCISSORS"] = { 2, 0 }

specalWidthBeams["LILY_BEAM_SIREN_1"] = { 1, 0 }
specalWidthBeams["LILY_BEAM_SIREN_2"] = { 1, 0 }
specalWidthBeams["LILY_BEAM_SIREN_3"] = { 2, 0}
specalWidthBeams["LILY_BEAM_SIREN_4"] = { 3, 0}
specalWidthBeams["LILY_BEAM_SIREN_FIRE"] = { 1, 0 }
specalWidthBeams["LILY_BEAM_SIREN_LOCK"] = { 1, 0 }

specalWidthBeams["LILY_BEAM_SIREN_1_CHAOS"] = { 1, 0 }
specalWidthBeams["LILY_BEAM_SIREN_2_CHAOS"] = { 1, 0 }
specalWidthBeams["LILY_BEAM_SIREN_3_CHAOS"] = { 2, 0 }
specalWidthBeams["LILY_BEAM_SIREN_4_CHAOS"] = { 3, 0 }
specalWidthBeams["LILY_BEAM_SIREN_FIRE_CHAOS"] = { 1, 0 }
specalWidthBeams["LILY_BEAM_SIREN_LOCK_CHAOS"] = { 1, 0 }

specalWidthBeams["LILY_BEAM_SIREN_1_ELITE"] = { 1, 0 }
specalWidthBeams["LILY_BEAM_SIREN_2_ELITE"] = { 1, 0 }
specalWidthBeams["LILY_BEAM_SIREN_3_ELITE"] = { 2, 0 }
specalWidthBeams["LILY_BEAM_SIREN_4_ELITE"] = { 3, 0 }
specalWidthBeams["LILY_BEAM_SIREN_FIRE_ELITE"] = { 1, 0 }
specalWidthBeams["LILY_BEAM_SIREN_LOCK_ELITE"] = { 1, 0 }

specalWidthBeams["LILY_SIREN_TRANSPORT_HER_ARTILLERY"] = { 4, 0 }
specalWidthBeams["LILY_SIREN_MV_TRANSPORT_ARTILLERY"] = { 2, 0 }

script.on_internal_event(Defines.InternalEvents.DAMAGE_BEAM,
    function(shipManager, projectile, location, damage, newTile, beamHit)
        local weaponName = projectile and projectile.extend and projectile.extend.name
        --local weaponName = nil
        --if pcall(function() weaponName = projectile.extend.name end) and weaponName then
        if weaponName then
            local otherShip = Hyperspace.ships(1 - shipManager.iShipId)

            -- Make drones target the location the target painter laser hit
            if otherShip and  weaponName == "LILY_FOCUS_POINTER" then
                for drone in vter(otherShip.spaceDrones) do
                    drone.targetLocation = location
                end
            end

            if specalWidthBeams[weaponName] then
                damage.iDamage = specalWidthBeams[weaponName][2]
            end

            if chaosfire[weaponName] then
                local effect_time = chaosfire[weaponName]
                local roomId = shipManager.ship:GetSelectedRoomId(location.x, location.y, true)
                if effect_time ~= nil and roomId ~= -1 then
                    local table = userdata_table(shipManager.ship.vRoomList[roomId], "mods.lilybeams.chaosfire")
                    table.timer = math.max(table.timer, effect_time)
                end
            end

            if disintegrators[weaponName] then
                if beamHit == Defines.BeamHit.NEW_ROOM then
                    local roomId = shipManager.ship:GetSelectedRoomId(location.x, location.y, true)
                    if roomId >= 0 then
                        --[[
                        local sys = shipManager:GetSystemInRoom(roomId)
                        if sys and sys:CompletelyDestroyed() then
                            shipManager:DamageHull(disintegrators[weaponName], false)
                        end
                        --]]
                        
                        local breaches = shipManager.ship:GetHullBreaches(true)
                        local found = false
                        for breach in vter(breaches) do
                            ---@type Hyperspace.Repairable
                            breach = breach
                            if breach.roomId == roomId then
                                found = true
                                break
                            end
                        end
                        if found then
                            shipManager:DamageHull(disintegrators[weaponName], false)
                        end
                        --]]
                    end
                end
            end
            if otherShip and frostBeams[weaponName] then

                if beamHit == Defines.BeamHit.NEW_ROOM or beamHit == Defines.BeamHit.NEW_TILE then
                    local roomId = shipManager.ship:GetSelectedRoomId(location.x, location.y, true)
                    if roomId >= 0 then
                        if frostBeams[weaponName].removeOxygen then
                            shipManager.oxygenSystem:ModifyRoomOxygen(roomId, -999)
                        end
                        local fire = shipManager:GetFireAtPoint(location)
                        fire.fDeathTimer = 0
                        fire.fOxygen = 0
                        fire:OnLoop()
                    end
                    if beamHit == Defines.BeamHit.NEW_ROOM then
                        shipManager.ship:LockdownRoom(roomId, location)
                    end
                end

            end

            if weaponName == "LILY_SIREN_TRANSPORT_B_ARTILLERY_L" then
                damage.iDamage = -3
            end

            if otherShip and (weaponName == "LILY_BEAM_AMP_SIPHON" or weaponName == "LILY_BEAM_AMP_SIPHON_O") then
                if beamHit == Defines.BeamHit.NEW_ROOM then
                    local roomId = shipManager.ship:GetSelectedRoomId(location.x, location.y, true)
                    if roomId >= 0 then
                        local sys = shipManager:GetSystemInRoom(roomId)
                        if sys then
                            sys:ForceDecreasePower(1)
                        end
                    end
                end
            end

            if otherShip and weaponName == "LILY_SIREN_TRANSPORT_A_ARTILLERY" then
                --print("!!!")
                if otherShip.teleportSystem and otherShip.teleportSystem:GetEffectivePower() > 0 then
                    if beamHit == Defines.BeamHit.NEW_ROOM or beamHit == Defines.BeamHit.NEW_TILE then
                        for i, crewmem in ipairs(get_ship_crew_point(shipManager, location.x, location.y)) do
                            crewmem.extend:InitiateTeleport(otherShip.iShipId, otherShip.teleportSystem.roomId)
                            if crewmem.iShipId == otherShip.iShipId then
                                crewmem.fStunTime = 0
                            end
                        end
                        --[[
                        local crew1 = shipManager:GetSelectedCrewPoint(location.x, location.y, false)
                        local crew2 = shipManager:GetSelectedCrewPoint(location.x, location.y, true)
                        if crew1 then
                            crew1.extend:InitiateTeleport(otherShip.iShipId, otherShip.teleportSystem.roomId)
                            if crew1.iShipId == otherShip.iShipId then
                                crew1.fStunTime = 0
                            end
                        end
                        if crew2 then
                            crew2.extend:InitiateTeleport(otherShip.iShipId, otherShip.teleportSystem.roomId)
                            if crew2.iShipId == otherShip.iShipId then
                                crew2.fStunTime = 0
                            end
                        end
                        --]]
                    end
                end
            end
        end
        return Defines.Chain.CONTINUE, beamHit
    end)

-----------------------------------------------------------------
-- SIPHON AND SHOTGUN BEAMS --
-----------------------------------------------------------------

local burstPinpoints = {}
local burstPinpointsAnim = {}
burstPinpoints["LILY_BEAM_AMP_SIPHON_0"] = "LILY_BEAM_AMP_SIPHON"
burstPinpoints["LILY_BEAM_AMP_SIPHON_1"] = "LILY_BEAM_AMP_SIPHON"
burstPinpoints["LILY_BEAM_AMP_SIPHON_2"] = "LILY_BEAM_AMP_SIPHON"
burstPinpoints["LILY_BEAM_AMP_SIPHON_3"] = "LILY_BEAM_AMP_SIPHON"
burstPinpoints["LILY_BEAM_AMP_SIPHON_OD"] = "LILY_BEAM_AMP_SIPHON_O"
burstPinpoints["LILY_BEAM_TOGGLE_AKATSUKI_S"] = "LILY_BEAM_TOGGLE_AKATSUKI_S_BEAM"
burstPinpointsAnim["LILY_BEAM_TOGGLE_AKATSUKI_S"] = true
local howitzers = {}
howitzers["LILY_HOWITZER_1"] = { dmg = 4, primary = "LILY_HOWITZER_1_BEAM_P", secondary = "LILY_HOWITZER_1_BEAM_S" }

mods.lilybeams.burstMultiBarrel = {}
local lilyBurstMultiBarrel = mods.lilybeams.burstMultiBarrel
lilyBurstMultiBarrel["LILY_BEAM_SHOTGUN_S"] = {
    barrelOffset = 6,
    barrelCount = 3
}
lilyBurstMultiBarrel["LILY_BEAM_SHOTGUN_9_S"] = {
    barrelOffset = 8,
    barrelCount = 3
}

local longPins = {}
longPins["LILY_FOCUS_ION_1"] = 5
longPins["LILY_FOCUS_ION_2"] = 5
longPins["LILY_FOCUS_ION_HEAVY"] = 10
longPins["LILY_FOCUS_ION_CHAIN"] = 5
longPins["LILY_FOCUS_ION_FIRE"] = 5
longPins["LILY_FOCUS_ION_STUN"] = 10
longPins["LILY_FOCUS_ION_BIO"] = 5
longPins["LILY_FOCUS_ION_PHASE"] = 8
longPins["LILY_BEAM_TOGGLE_AKATSUKI_F"] = 5
longPins["LILY_BEAM_TOGGLE_AKATSUKI_S"] = 5
longPins["LILY_BEAM_TOGGLE_AKATSUKI_S_BEAM"] = 5
longPins["LILY_FOCUS_PIERCE_1"] = 5
longPins["LILY_FOCUS_PIERCE_1_R"] = 5
longPins["LILY_FOCUS_PIERCE_2"] = 5
longPins["LILY_FOCUS_PIERCE_2_R"] = 5
longPins["LILY_FOCUS_PIERCE_2_O"] = 5
longPins["LILY_FOCUS_PIERCE_2_Y"] = 5
longPins["LILY_FOCUS_PIERCE_2_G"] = 5
longPins["LILY_FOCUS_PIERCE_2_B"] = 5
longPins["LILY_FOCUS_PIERCE_2_I"] = 5
longPins["LILY_FOCUS_PIERCE_2_V"] = 5
longPins["LILY_FOCUS_HACK"] = 15
longPins["LILY_BEAM_AMP_SIPHON"] = 10
longPins["LILY_BEAM_SHOTGUN_P"] = 5
longPins["LILY_BEAM_SHOTGUN_9_P"] = 5
longPins["LILY_FOCUS_POPPER"] = 3

local caleidoscopeBeams = {}
caleidoscopeBeams[1]  = "LILY_SIREN_TRANSPORT_B_ARTILLERY_R"
caleidoscopeBeams[2]  = "LILY_SIREN_TRANSPORT_B_ARTILLERY_O"
caleidoscopeBeams[3]  = "LILY_SIREN_TRANSPORT_B_ARTILLERY_Y"
caleidoscopeBeams[4]  = "LILY_SIREN_TRANSPORT_B_ARTILLERY_L"
caleidoscopeBeams[5]  = "LILY_SIREN_TRANSPORT_B_ARTILLERY_G"
caleidoscopeBeams[6]  = "LILY_SIREN_TRANSPORT_B_ARTILLERY_C"
caleidoscopeBeams[7]  = "LILY_SIREN_TRANSPORT_B_ARTILLERY_B"
caleidoscopeBeams[8]  = "LILY_SIREN_TRANSPORT_B_ARTILLERY_I"
caleidoscopeBeams[9]  = "LILY_SIREN_TRANSPORT_B_ARTILLERY_V"
caleidoscopeBeams[10] = "LILY_SIREN_TRANSPORT_B_ARTILLERY_M"

--[[
script.on_internal_event(Defines.InternalEvents.PROJECTILE_UPDATE_PRE, function(projectile)

    if projectile and projectile.ownerId == 0 then
        local name = projectile.extend.name
        ---@type Hyperspace.BeamWeapon
        ---@diagnostic disable-next-line: assign-type-mismatch
        local bm = projectile
        if bm and bm.length then
            print("UPDATE:")
            print(name .. ": Lifespan = " .. (bm.lifespan or "nil"))
            print(name .. ": Length = " .. (bm.length or "nil"))
            print(name .. ": Speed = " .. (bm.speed.x or "nil") .. "/" .. (bm.speed.y or "nil"))
            print(name .. ": SpeedMag = " .. (bm.speed_magnitude or "nil"))
            print(name .. ": Timer = " .. (bm.timer or "nil"))
            print(name .. ": AnimTimer = " .. (bm.animationTimer or "nil"))
            print(name .. ": Anim = " .. (bm.weapAnimation and "true" or "false"))
            if bm.weapAnimation then
                
                print(name .. ": AnimDelayTime = " .. (bm.weapAnimation.fDelayChargeTime or "nil"))
                print(name .. ": AnimFrame = " .. (bm.weapAnimation.anim.currentFrame or "nil"))
                print(name .. ": AnimTime = " .. (bm.weapAnimation.anim.tracker.time or "nil"))
                print(name .. ": AnimCurrTime = " .. (bm.weapAnimation.anim.tracker.current_time or "nil"))
            end
        end

    end
end)
--]]
script.on_internal_event(Defines.InternalEvents.PROJECTILE_INITIALIZE, function(projectile, blueprint)

    if blueprint and longPins[blueprint.name] then
        projectile.speed_magnitude = 1 / longPins[blueprint.name]
    end

end)

script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)

    --[[if projectile and weapon then
        ---@type Hyperspace.BeamWeapon
        ---@diagnostic disable-next-line: assign-type-mismatch
        local bm = projectile
        if bm and bm.length then
            print("FIRE:")
            --bm.lifespan = 20
            --bm.length = bm.length * 100
            print(weapon.blueprint.name .. ": Lifespan = " .. (bm.lifespan or "nil"))
            print(weapon.blueprint.name .. ": Length = " .. (bm.length or "nil"))
            print(weapon.blueprint.name .. ": Speed = " .. (bm.speed.x or "nil") .. "/" .. (bm.speed.y or "nil"))
            print(weapon.blueprint.name .. ": Timer = " .. (bm.timer or "nil"))
            print(weapon.blueprint.name .. ": AnimTimer = " .. (bm.animationTimer or "nil"))
            print(weapon.blueprint.name .. ": Anim = " .. (bm.weapAnimation and "true" or "false"))
            if bm.weapAnimation then
                --bm.weapAnimation:SetFireTime(10)
                print(weapon.blueprint.name .. ": AnimDelayTime = " .. (bm.weapAnimation.fDelayChargeTime or "nil"))
                print(weapon.blueprint.name .. ": AnimFrame = " .. (bm.weapAnimation.anim.currentFrame or "nil"))
                print(weapon.blueprint.name .. ": AnimTime = " .. (bm.weapAnimation.anim.tracker.time or "nil"))
                print(weapon.blueprint.name .. ": AnimCurrTime = " .. (bm.weapAnimation.anim.tracker.current_time or "nil"))
            end
        end
    end--]]
    --[[
    if weapon.blueprint and longPins[weapon.blueprint.name] then
        projectile.speed_magnitude = 1 / longPins[weapon.blueprint.name]
        ---@type Hyperspace.BeamWeapon
        ---@diagnostic disable-next-line: assign-type-mismatch
        local bm = projectile
        if bm and bm.length then
            bm.length = longPins[weapon.blueprint.name]
            bm.target2 = get_random_point_on_radius(bm.target1, bm.length)
        end
    end
    --]]
    --[[if weapon.blueprint and weapon.blueprint.name == "LILY_FOCUS_CIWS" then
       if projectile then
            print("P: ", projectile.position.x, projectile.position.y)
            print("FMV", weapon.weaponVisual.fireMountVector.x, weapon.weaponVisual.fireMountVector.y)
            print("FP", weapon.weaponVisual.fireLocation.x, weapon.weaponVisual.fireLocation.y)
            print("MP", weapon.weaponVisual.mountPoint.x, weapon.weaponVisual.mountPoint.y)
            print("MP2", weapon.mount.position.x, weapon.mount.position.y)
            print("LP", weapon.localPosition.x, weapon.localPosition.y)
            print("AN", weapon.weaponVisual.anim.position.x, weapon.weaponVisual.anim.position.y)
            print("AN2", weapon.weaponVisual.renderPoint.x, weapon.weaponVisual.renderPoint.y)
            local f = weapon.mount.position + weapon.localPosition + weapon.weaponVisual.fireMountVector
            print("F:", f.x, f.y)
       end
    end--]]
    if weapon.blueprint and weapon.blueprint.name and specalWidthBeams[weapon.blueprint.name] then
        projectile.damage.iDamage = specalWidthBeams[weapon.blueprint.name][1]
        if specalWidthBeams[weapon.blueprint.name][3] then
            projectile.damage.iShieldPiercing = projectile.damage.iShieldPiercing + specalWidthBeams[weapon.blueprint.name][3]
        end
    end

    if weapon.blueprint and weapon.blueprint.name == "LILY_SIREN_TRANSPORT_B_ARTILLERY" then
        local blueprint = Hyperspace.Blueprints:GetWeaponBlueprint(caleidoscopeBeams[math.random(#caleidoscopeBeams)])

        local theta = 2 * math.random() * math.pi
        local r = 100
        local target2 = Hyperspace.Pointf(projectile.target.x + r * math.cos(theta), projectile.target.y + r * math.sin(theta))

        local spaceManager = Hyperspace.App.world.space
        local beam = spaceManager:CreateBeam(
            blueprint,
            projectile.position,
            projectile.currentSpace,
            projectile.ownerId,
            projectile.target,
            target2,
            projectile.destinationSpace,
            r,
            -0.1)
        ---@type Hyperspace.BeamWeapon
        projectile = projectile
        if projectile.sub_start then
            beam.sub_start = projectile.sub_start
        end

        ---@type Hyperspace.BeamWeapon
        local origBeam = projectile

        if origBeam.target2 then
            origBeam.target1 = beam.target1
            origBeam.target2 = beam.target2
            origBeam.length = beam.length
            origBeam.speed_magnitude = beam.speed_magnitude
            origBeam.color = beam.color            
        else
            projectile.speed_magnitude = beam.speed_magnitude / beam.length
        end


        beam:SetWeaponAnimation(weapon.weaponVisual)
        --projectile:Kill()
    end



    if weapon.blueprint and weapon.blueprint.name == "LILY_BEAM_AMP_SIPHON_OD" then
        if math.random() <= 0.02 then
            local sm = Hyperspace.ships(weapon.iShipId)

            if weapon.isArtillery then
                if sm:HasSystem(Hyperspace.ShipSystem.NameToSystemId("artillery")) then
                    local artis = sm.artillerySystems
                    artis:size()
                    sm:StartFire(artis[math.random(artis:size()) - 1].roomId)
                end
            else                 
                if sm:HasSystem(Hyperspace.ShipSystem.NameToSystemId("weapons")) then
                    sm:StartFire(sm.weaponSystem.roomId)
                end
            end 
        end
    end

    if weapon.blueprint and burstPinpoints[weapon.blueprint.name] then
        local burstPinpointBlueprint = Hyperspace.Blueprints:GetWeaponBlueprint(burstPinpoints[weapon.blueprint.name])

        local spaceManager = Hyperspace.App.world.space
        local beam = spaceManager:CreateBeam(
            burstPinpointBlueprint,
            projectile.position,
            projectile.currentSpace,
            projectile.ownerId,
            projectile.target,
            Hyperspace.Pointf(projectile.target.x, projectile.target.y + 1),
            projectile.destinationSpace,
            1,
            -0.1)
        beam.sub_start = offset_point_direction(projectile.target.x, projectile.target.y, projectile.entryAngle, 600)
        if burstPinpointsAnim[weapon.blueprint.name] then
            beam:SetWeaponAnimation(weapon.weaponVisual)
        end
        projectile:Kill()
    end


    if weapon.blueprint and howitzers[weapon.blueprint.name] and projectile.damage.iDamage == howitzers[weapon.blueprint.name].dmg then
        local primaryBlueprint = Hyperspace.Blueprints:GetWeaponBlueprint(howitzers[weapon.blueprint.name].primary)
        local secondaryBlueprint = Hyperspace.Blueprints:GetWeaponBlueprint(howitzers[weapon.blueprint.name].secondary)

        local spaceManager = Hyperspace.App.world.space

        local beam1 = spaceManager:CreateBeam(
            primaryBlueprint,
            projectile.position,
            projectile.currentSpace,
            projectile.ownerId,
            projectile.target,
            Hyperspace.Pointf(projectile.target.x, projectile.target.y + 5),
            projectile.destinationSpace,
            1,
            -0.1)
        beam1.sub_start = offset_point_direction(projectile.target.x, projectile.target.y, projectile.entryAngle, 600)
        local beam2 = spaceManager:CreateBeam(
            secondaryBlueprint,
            projectile.position,
            projectile.currentSpace,
            projectile.ownerId,
            projectile.target,
            Hyperspace.Pointf(projectile.target.x, projectile.target.y + 5),
            projectile.destinationSpace,
            1,
            -0.1)
        beam2.sub_start = offset_point_direction(projectile.target.x, projectile.target.y, projectile.entryAngle, 600)
        projectile:Kill()

    end

    if weapon.blueprint and weapon.blueprint.name == "LILY_FOCUS_ION_PHASE" then

        local damage = projectile.damage
        damage.iShieldPiercing = damage.iIonDamage + 1
        damage.iIonDamage = 2 + (damage.iShieldPiercing > 10 and (damage.iShieldPiercing - 10) / 10 or 0)
        --print(projectile.damage.iIonDamage)
        --print(projectile.damage.iShieldPiercing)
    end

    if weapon.blueprint and weapon.blueprint.name == "LILY_BEAM_SHOTGUN_P" then
        local offsets = {{-1, 0}, {1, 0}}
        local offsets2 = { 6, -6 }
        local gap = 35 * 2
        while #offsets > 0 do
            local idx = math.random(#offsets)
            local offset = table.remove(offsets, idx)
            local vertical = math.random() < 0.5
            if vertical then
                offset[2] = offset[1]
                offset[1] = 0
            end
            idx = math.random(#offsets2)
            local offset2 = table.remove(offsets2, idx)
            local tgt1 = Hyperspace.Pointf(projectile.target.x + offset[1] * gap, projectile.target.y + offset[2] * gap)
            local tgt2 = Hyperspace.Pointf(tgt1.x, tgt1.y + 1)

            local spaceManager = Hyperspace.App.world.space

            local pos = projectile.position
            if projectile.currentSpace == 0 then
                pos = Hyperspace.Pointf(projectile.position.x, projectile.position.y + offset2)
            else
                pos = Hyperspace.Pointf(projectile.position.x + offset2, projectile.position.y)
            end

            local beam = spaceManager:CreateBeam(
                Hyperspace.Blueprints:GetWeaponBlueprint("LILY_BEAM_SHOTGUN_P"),
                pos,
                projectile.currentSpace,
                projectile.ownerId,
                tgt1,
                tgt2,
                projectile.destinationSpace,
                1,
                -0.1)
            ---@diagnostic disable-next-line: undefined-field
            beam.sub_start = projectile.sub_start
            beam:SetWeaponAnimation(weapon.weaponVisual)
            --offset_point_direction(projectile.target.x, projectile.target.y, projectile.entryAngle, 600)

        end
    end

    if weapon.blueprint and weapon.blueprint.name == "LILY_BEAM_SHOTGUN_S" then
        local burstBarrelData = lilyBurstMultiBarrel[weapon and weapon.blueprint and weapon.blueprint.name]
        local offset2 = ((burstBarrelData.barrelCount - weapon.queuedProjectiles:size() % burstBarrelData.barrelCount - 1) - 1) *
            burstBarrelData.barrelOffset
        if weapon.mount.mirror then offset2 = -offset2 end
        if weapon.mount.rotate then
            projectile.position.y = projectile.position.y + offset2
        else
            projectile.position.x = projectile.position.x + offset2
        end
        
        local spaceManager = Hyperspace.App.world.space
        local tgt1 = projectile.target
        local tgt2 = Hyperspace.Pointf(tgt1.x, tgt1.y + 1)
        local pos = projectile.position
        local beam = spaceManager:CreateBeam(
            Hyperspace.Blueprints:GetWeaponBlueprint("LILY_BEAM_SHOTGUN_P"),
            pos,
            projectile.currentSpace,
            projectile.ownerId,
            tgt1,
            tgt2,
            projectile.destinationSpace,
            1,
            -0.1)
        beam.sub_start = offset_point_direction(projectile.target.x, projectile.target.y, projectile.entryAngle, 600)
        beam:SetWeaponAnimation(weapon.weaponVisual)
        projectile:Kill()
        --[[local offsets2 = { 6, 0, -6 }
        while #offsets2 > 0 do
            local idx = math.random(#offsets2)
            local offset2 = table.remove(offsets2, idx)
            local tgt1 = get_random_point_in_radius(projectile.target, 45)
            local tgt2 = Hyperspace.Pointf(tgt1.x, tgt1.y + 1)

            local spaceManager = Hyperspace.App.world.space

            local pos = projectile.position
            if projectile.currentSpace == 0 then
                pos = Hyperspace.Pointf(projectile.position.x, projectile.position.y + offset2)
            else
                pos = Hyperspace.Pointf(projectile.position.x + offset2, projectile.position.y)
            end

            local beam = spaceManager:CreateBeam(
                Hyperspace.Blueprints:GetWeaponBlueprint("LILY_BEAM_SHOTGUN_P"),
                pos,
                projectile.currentSpace,
                projectile.ownerId,
                tgt1,
                tgt2,
                projectile.destinationSpace,
                1,
                -0.1)
            beam.sub_start = offset_point_direction(projectile.target.x, projectile.target.y, projectile.entryAngle, 600)

        end
        projectile:Kill()
        --]]
    end

    if weapon.blueprint and weapon.blueprint.name == "LILY_BEAM_SHOTGUN_9_P" then
        local offsets = { { -1, -1 }, { -1, 0 }, { -1, 1 }, { 0, -1 }, { 0, 1 }, { 1, -1 }, { 1, 0 }, { 1, 1 } }
        local offsets2 = { 8, 8, 8, 0, 0, -8, -8, -8 }
        local gap = 35 * 2
        while #offsets > 0 do
            local idx = math.random(#offsets)
            local offset = table.remove(offsets, idx)
            idx = math.random(#offsets2)
            local offset2 = table.remove(offsets2, idx)
            local tgt1 = Hyperspace.Pointf(projectile.target.x + offset[1] * gap, projectile.target.y + offset[2] * gap)
            local tgt2 = Hyperspace.Pointf(tgt1.x, tgt1.y + 1)

            local spaceManager = Hyperspace.App.world.space

            local pos = projectile.position
            if projectile.currentSpace == 0 then
                pos = Hyperspace.Pointf(projectile.position.x, projectile.position.y + offset2)
            else
                pos = Hyperspace.Pointf(projectile.position.x + offset2, projectile.position.y)
            end

            local beam = spaceManager:CreateBeam(
                Hyperspace.Blueprints:GetWeaponBlueprint("LILY_BEAM_SHOTGUN_9_P"),
                pos,
                projectile.currentSpace,
                projectile.ownerId,
                tgt1,
                tgt2,
                projectile.destinationSpace,
                1,
                -0.1)
            ---@diagnostic disable-next-line: undefined-field
            beam.sub_start = projectile.sub_start
            beam:SetWeaponAnimation(weapon.weaponVisual)
            --offset_point_direction(projectile.target.x, projectile.target.y, projectile.entryAngle, 600)
        end
    end

    if weapon.blueprint and weapon.blueprint.name == "LILY_BEAM_SHOTGUN_9_S" then
        local burstBarrelData = lilyBurstMultiBarrel[weapon and weapon.blueprint and weapon.blueprint.name]
        local offset2 = ((burstBarrelData.barrelCount - weapon.queuedProjectiles:size() % burstBarrelData.barrelCount - 1) - 1) *
            burstBarrelData.barrelOffset
        if weapon.mount.mirror then offset2 = -offset2 end
        if weapon.mount.rotate then
            projectile.position.y = projectile.position.y + offset2
        else
            projectile.position.x = projectile.position.x + offset2
        end

        local spaceManager = Hyperspace.App.world.space
        local tgt1 = projectile.target
        local tgt2 = Hyperspace.Pointf(tgt1.x, tgt1.y + 1)
        local pos = projectile.position
        local beam = spaceManager:CreateBeam(
            Hyperspace.Blueprints:GetWeaponBlueprint("LILY_BEAM_SHOTGUN_P"),
            pos,
            projectile.currentSpace,
            projectile.ownerId,
            tgt1,
            tgt2,
            projectile.destinationSpace,
            1,
            -0.1)
        beam.sub_start = offset_point_direction(projectile.target.x, projectile.target.y, projectile.entryAngle, 600)
        beam:SetWeaponAnimation(weapon.weaponVisual)
        projectile:Kill()

        --[[
        local offsets2 = { 8, 8, 8, 0, 0, 0, -8, -8, -8 }
        while #offsets2 > 0 do
            local idx = math.random(#offsets2)
            local offset2 = table.remove(offsets2, idx)
            local tgt1 = get_random_point_in_radius(projectile.target, 80)
            local tgt2 = Hyperspace.Pointf(tgt1.x, tgt1.y + 1)

            local spaceManager = Hyperspace.App.world.space

            local pos = projectile.position
            if projectile.currentSpace == 0 then
                pos = Hyperspace.Pointf(projectile.position.x, projectile.position.y + offset2)
            else
                pos = Hyperspace.Pointf(projectile.position.x + offset2, projectile.position.y)
            end

            local beam = spaceManager:CreateBeam(
                Hyperspace.Blueprints:GetWeaponBlueprint("LILY_BEAM_SHOTGUN_9_P"),
                pos,
                projectile.currentSpace,
                projectile.ownerId,
                tgt1,
                tgt2,
                projectile.destinationSpace,
                1,
                -0.1)
            beam.sub_start = offset_point_direction(projectile.target.x, projectile.target.y, projectile.entryAngle, 600)
        end
        projectile:Kill()
        --]]
    end


    if weapon.blueprint and weapon.blueprint.name == "LILY_BEAM_SCISSORS" then
    
        local offset2 = Hyperspace.Pointf(13, 0)
        if weapon.mount.mirror then offset2.x = -offset2.x end
        if weapon.mount.rotate then
            offset2.y = offset2.x
            offset2.x = 0
        end
        local spaceManager = Hyperspace.App.world.space
        ---@type Hyperspace.BeamWeapon
        ---@diagnostic disable-next-line: assign-type-mismatch
        local beam1 = projectile

        local tgt1 = beam1.target2 + (beam1.target2 - beam1.target1)
        local tgt2 = beam1.target2
        local pos = projectile.position + offset2

        --print("TGT1 x: " .. beam1.target1.x .. ", y: " .. beam1.target1.y)
        --print("TGT2 x: " .. beam1.target2.x .. ", y: " .. beam1.target2.y)
        --print("TGT3 x: " .. tgt1.x .. ", y: " .. tgt1.y)

        local beam2 = spaceManager:CreateBeam(
            Hyperspace.Blueprints:GetWeaponBlueprint("LILY_BEAM_SCISSORS_SEC"),
            pos,
            projectile.currentSpace,
            projectile.ownerId,
            tgt1,
            tgt2,
            projectile.destinationSpace,
            beam1.length,
            -0.1)
        beam2.sub_start = beam1.sub_start
        beam2:SetWeaponAnimation(beam1.weapAnimation)
        --beam2.lifespan = beam1.lifespan
        --beam2.timer = beam1.timer

        --print("B1  x: " .. tgt1.x .. ", y: " .. tgt1.y)

    end

end)


--LILY_IGNORE_PROJ = LILY_IGNORE_PROJ or {}
local refractors = {}
refractors["LILY_FOCUS_PIERCE_1"] = {num = 1, beams = {"LILY_FOCUS_PIERCE_1_R",}, offsets = {20, } }
refractors["LILY_FOCUS_PIERCE_2"] = { num = 7, beams = { "LILY_FOCUS_PIERCE_2_V", "LILY_FOCUS_PIERCE_2_I", "LILY_FOCUS_PIERCE_2_B", "LILY_FOCUS_PIERCE_2_G", "LILY_FOCUS_PIERCE_2_Y", "LILY_FOCUS_PIERCE_2_O", "LILY_FOCUS_PIERCE_2_R" }, offsets = { 20, 18.33, 16.66, 15, 13.33, 11.66, 10} }

local burstPins = {}
burstPins["LILY_BEAM_AMP_SIPHON"] = { count = 1, countSuper = 1, siphon = true }
burstPins["LILY_BEAM_AMP_SIPHON_O"] = { count = 1, countSuper = 1, siphon = true }
burstPins["LILY_BEAM_SHOTGUN_P"] = { count = 1, countSuper = 1, siphon = false }
burstPins["LILY_BEAM_SHOTGUN_9_P"] = { count = 1, countSuper = 1, siphon = false }
burstPins["LILY_FOCUS_POPPER"] = { count = 2, countSuper = 4, siphon = false }
burstPins["LILY_SIREN_TRANSPORT_HER_ARTILLERY"] = { count = 0, countSuper = 100, siphon = false }


-- Pop shield bubbles
script.on_internal_event(Defines.InternalEvents.SHIELD_COLLISION, function(shipManager, projectile, damage, response)
    local shieldPower = shipManager.shieldSystem.shields.power
    local weaponName = projectile and projectile.extend and projectile.extend.name
    local popData = burstPins[projectile and projectile.extend and projectile.extend.name]
    local otherShip = Hyperspace.ships(1 - shipManager.iShipId)
    local otherShieldPower = otherShip and otherShip.shieldSystem.shields.power or nil

    --[[if weaponName == "LILY_FOCUS_POPPER" then
        ---@type Hyperspace.BeamWeapon
        ---@diagnostic disable-next-line: assign-type-mismatch
        local beam = projectile
        if beam.bDamageSuperShield then
            popData = { count = 1, countSuper = 1, siphon = true }
        end
    end--]]
    ---@type Hyperspace.BeamWeapon
    ---@diagnostic disable-next-line: assign-type-mismatch
    local beam = projectile

    if popData and beam and beam.bDamageSuperShield then
        if shieldPower.super.first > 0 then
            if popData.countSuper > 0 then
                shipManager.shieldSystem:CollisionReal(projectile.position.x, projectile.position.y, Hyperspace.Damage(),
                    true)
                shieldPower.super.first = math.max(0, shieldPower.super.first - popData.countSuper)
                if otherShieldPower and popData.siphon then
                    otherShip.shieldSystem:AddSuperShield(Hyperspace.Point(projectile.position.x, projectile.position.y))
                    --otherShieldPower.super.second = math.max(otherShieldPower.super.second, 5)
                    --otherShieldPower.super.first = math.min(math.max(otherShieldPower.super.second, 5), otherShieldPower.super.first + popData.countSuper)
                end
            end
        else
            local hasShield = shieldPower.first > 0
            shipManager.shieldSystem:CollisionReal(projectile.position.x, projectile.position.y, Hyperspace.Damage(),
                true)
            shieldPower.first = math.max(0, shieldPower.first - popData.count)
            if popData.siphon and otherShieldPower and hasShield then
                if otherShieldPower.first < otherShieldPower.second then
                    otherShieldPower.first = math.min(otherShieldPower.second, otherShieldPower.first + popData.count)
                else
                    if otherShip.shieldSystem and otherShip.shieldSystem.iLockCount > 0 then
                        otherShip.shieldSystem.iLockCount = math.max(0, otherShip.shieldSystem.iLockCount - popData.count)
                        otherShip.shieldSystem:ForceIncreasePower(math.min(popData.count,
                            otherShip.shieldSystem:GetMaxPower() - otherShip.shieldSystem:GetEffectivePower()))
                    end
                    if otherShip:HasAugmentation("UPG_AETHER_SHIELDS") > 0 then
                        otherShip.shieldSystem:AddSuperShield(Hyperspace.Point(projectile.position.x, projectile.position.y))
                        --otherShieldPower.super.first = math.min(otherShieldPower.super.second,
                        --    otherShieldPower.super.first + popData.count)
                    end
                end
            end
        end
        --projectile:Kill()
    end


    -- refractors
    if shieldPower.first > 0 and shieldPower.super.first == 0 and refractors[weaponName] ~= nil and beam and beam.bDamageSuperShield then
        local theta = math.random() * 2 * math.pi
        --LILY_IGNORE_PROJ[projectile] = 50.0
        local refrData = refractors[weaponName]

        --[[local fakeBlueprint = Hyperspace.Blueprints:GetWeaponBlueprint(weaponName .. "_FAKE")
        local spaceManager = Hyperspace.App.world.space
        local fakeBeam = spaceManager:CreateBeam(
            fakeBlueprint,
            projectile.position,
            projectile.currentSpace,
            projectile.ownerId,
            projectile.target,
            Hyperspace.Pointf(projectile.target.x, projectile.target.y + 1),
            projectile.destinationSpace,
            1,
            1)
        fakeBeam.sub_start = projectile.sub_start
        fakeBeam.sub_end = projectile.sub_end--]]


        local i = 1
        while i <= refrData.num do
            local weaponBlueprint = Hyperspace.Blueprints:GetWeaponBlueprint(refrData.beams[i])
            local offset_per_layer = refrData.offsets[i]


            local newTarget1 = Hyperspace.Pointf(
                projectile.target.x + math.cos(theta) * offset_per_layer * shieldPower.first,
                projectile.target.y + math.sin(theta) * offset_per_layer * shieldPower.first)
            local newTarget2 = Hyperspace.Pointf(
                projectile.target.x + math.cos(theta) * offset_per_layer * shieldPower.first,
                projectile.target.y + math.sin(theta) * offset_per_layer * shieldPower.first + 1)

            local spaceManager = Hyperspace.App.world.space
            local beam1 = spaceManager:CreateBeam(
                weaponBlueprint,
                response.point,
                projectile.destinationSpace,
                projectile.ownerId,
                newTarget1,
                newTarget2,
                projectile.destinationSpace,
                1,
                1.0)
            --beam.sub_start = offset_point_direction(projectile.target.x, projectile.target.y, projectile.entryAngle, 600)


            i = i + 1
        end
        --projectile.damage.iDamage = 0
        --projectile.damage.iIonDamage = 0
        --projectile.damage.iSystemDamage = 0
        --projectile.damage.iPersDamage = 0
        --projectile.damage.iStun = 0
        --projectile.damage.fireChance = 0
        --projectile.damage.breachChance = 0
    end

end)

script.on_internal_event(Defines.InternalEvents.WEAPON_RENDERBOX, function(weapon, cooldown, maxCooldown, firstLine, secondLine, thirdLine)
    if weapon.blueprint and weapon.blueprint.name == "LILY_FOCUS_ION_PHASE" then
        --print(firstLine)
        --print(secondLine)
        --print(thirdLine)
        local sp = weapon.boostLevel + 3
        local dmg = 2 + (sp > 10 and (sp - 10.0) / 10 or 0)
        local l2 = (sp - 1.0) .. " Pierce"
        local l3 = (dmg + 0.0) .. " Damage"
        return Defines.Chain.CONTINUE, firstLine, l2, l3
    end
    if weapon.blueprint and weapon.blueprint.name == "LILY_BEAM_CYCLOTRON" then
        local sp = math.max(weapon.weaponVisual.boostLevel, 0)
            local dmg = 1.0 + math.max(weapon.weaponVisual.boostLevel, 0)
            local pdmg = 30.0 + 30 * math.max(weapon.weaponVisual.boostLevel, 0)
        local l3 = string.format("%.0f Pierce", sp)
        local l2 = string.format("%.0f / %.0f Damage", dmg, pdmg)
        --print(l2)
        --print(l3)
        return Defines.Chain.CONTINUE, firstLine, l2, l3
    end

    return Defines.Chain.CONTINUE, firstLine, secondLine, thirdLine
end)
--[[script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    for key, value in pairs(ignoreProj) do
        ignoreProj[key] = value - Hyperspace.FPS.SpeedFactor / 16
        if value < 0 then
            ignoreProj[key] = nil
        end
    end
end)--]]




--Magnifiers
--Uses code from TRC
mods.lilybeams.statChargers = {}
local statChargers = mods.lilybeams.statChargers
statChargers["LILY_BEAM_CYCLOTRON"] = { { stat = "iSystemDamage" }, { stat = "iPersDamage" }, { stat = "iPersDamage" }, { stat = "iShieldPiercing" }, { stat = "breachChance" }, { stat = "breachChance" }, { stat = "breachChance" }}
script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
    local statBoosts = statChargers[weapon and weapon.blueprint and weapon.blueprint.name]
    if statBoosts then
        local boost = weapon.weaponVisual.boostLevel --weapon.queuedProjectiles:size()
        --print("boost: " .. boost)-- Gets how many projectiles are charged up (doesn't include the one that was already shot)
        weapon.queuedProjectiles:clear()              -- Delete all other projectiles
        for _, statBoost in ipairs(statBoosts) do     -- Apply all stat boosts
            --print(statBoost.stat)
            if statBoost.calc then
                projectile.damage[statBoost.stat] = statBoost.calc(boost, projectile.damage[statBoost.stat])
            else
                projectile.damage[statBoost.stat] = boost + projectile.damage[statBoost.stat]
            end
        end
    end
end)

mods.lilybeams.cooldownChargers = {}
local cooldownChargers = mods.lilybeams.cooldownChargers
cooldownChargers["LILY_BEAM_CYCLOTRON"] = 1.5

mods.lilybeams.chargersMaxCharges = {}
local chargersMaxCharges = {}
chargersMaxCharges["LILY_BEAM_CYCLOTRON"] = 4

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(ship)
    local weapons = ship and ship.weaponSystem and ship.weaponSystem.weapons
    if weapons then
        for weapon in vter(weapons) do
            --print(weapon and weapon.blueprint and weapon.blueprint.name .. ": iChargeLevels: " .. weapon.weaponVisual.iChargeLevels)
            -- print(weapon and weapon.blueprint and weapon.blueprint.name ..": boostLevel: " .. weapon.weaponVisual.boostLevel)
            --if weapon.chargeLevel ~= 0 and weapon.chargeLevel < weapon.weaponVisual.iChargeLevels then
            local valid = true
            if not chargersMaxCharges[weapon and weapon.blueprint and weapon.blueprint.name] then
                valid = false
            end 
            if valid then--and weapon.weaponVisual.boostLevel + 1 ~= 0 and weapon.weaponVisual.boostLevel + 1 < chargersMaxCharges[weapon and weapon.blueprint and weapon.blueprint.name] then
                local cdBoost = cooldownChargers[weapon and weapon.blueprint and weapon.blueprint.name]
                if cdBoost then
                    --print(weapon.cooldownModifier)
                    local cdLast = userdata_table(weapon, "mods.lilybeams.weaponStuff").cdLast
                    --print(cdLast)
                    --print("CD: " .. weapon.cooldown.first .. " / " .. weapon.cooldown.second)
                    --print("SCD: " .. weapon.subCooldown.first .. " / " .. weapon.cooldown.second)
                    if cdLast and weapon.cooldown.first > cdLast then
                        -- Calculate the new charge level from number of charges and charge level from last frame
                        local deltaCharge = weapon.cooldown.first - cdLast
                        weapon.cooldown.first = weapon.cooldown.first - deltaCharge
                        --local chargeNew = weapon.cooldown.first - chargeUpdate + cdBoost ^ weapon.chargeLevel * chargeUpdate
                        local deltaChargeN = deltaCharge * (cdBoost ^ (weapon.weaponVisual.boostLevel + 1))
                        --print((cdBoost ^ (weapon.weaponVisual.boostLevel + 1)))
                        --print("----")
                        --print(deltaChargeN)
                        --print(weapon.weaponVisual.boostLevel)
                        --print(weapon.chargeLevel)
                        weapon.cooldown.first = weapon.cooldown.first + deltaChargeN--]]
                        --local extraCharge = nil--userdata_table(weapon, "mods.lilybeams.weaponStuff").extraCharge
                        --if extraCharge and extraCharge > 0 then
                        --    deltaChargeN = deltaChargeN + extraCharge
                    end
                    if weapon.chargeLevel >= chargersMaxCharges[weapon.blueprint.name] then
                        weapon.cooldown.first = math.max(weapon.cooldown.first, weapon.cooldown.second)
                    end
                    if weapon.cooldown.first >= weapon.cooldown.second then
                        if weapon.chargeLevel >= chargersMaxCharges[weapon.blueprint.name] then
                            weapon.cooldown.first = weapon.cooldown.second
                        else
                            weapon.chargeLevel = weapon.chargeLevel + 1
                            weapon.weaponVisual.boostLevel = weapon.chargeLevel - 1
                            if weapon.chargeLevel >= chargersMaxCharges[weapon.blueprint.name] then
                                weapon.cooldown.first = weapon.cooldown.second
                            else
                                weapon.cooldown.first = 0
                            end
                        end
                    end

                        --userdata_table(weapon, "mods.lilybeams.weaponStuff").extraCharge = math.max(0,
                        --weapon.cooldown.first + deltaChargeN - weapon.cooldown.second)

                        --print(chargeNew)
                        -- Apply the new charge level
                        --print("----")
                        --print(weapon.weaponVisual.boostLevel)
                        --print(weapon.chargeLevel)
                        --print("--")
                        --if chargeNew >= weapon.cooldown.second then
                            --weapon.weaponVisual.boostLevel = weapon.weaponVisual.boostLevel + 1
                            --weapon.chargeLevel = weapon.chargeLevel + 1
                            --if weapon.chargeLevel == weapon.weaponVisual.iChargeLevels then
                         --   if weapon.weaponVisual.boostLevel + 1 == chargersMaxCharges[weapon and weapon.blueprint and weapon.blueprint.name] then
                          --      weapon.cooldown.first = weapon.cooldown.second
                           -- else
                             --   weapon.cooldown.first = 0
                          --  end
                       -- else
                         --   weapon.cooldown.first = math.min(chargeNew, weapon.cooldown.second)
                       -- end
                    --end
                    userdata_table(weapon, "mods.lilybeams.weaponStuff").cdLast = weapon.cooldown.first
                end
            end
        end
    end
end)

script.on_internal_event(Defines.InternalEvents.WEAPON_RENDERBOX,
    function(weapon, cooldown, maxCooldown, chargeString, damageString, shotLimitString)
        local chargerBoost = cooldownChargers[weapon and weapon.blueprint and weapon.blueprint.name]
        if chargerBoost then
            local first, second = chargeString:match("([%d%.]+)%s*/%s*([%d%.]+)")
            local boostLevel = math.min(weapon.weaponVisual.boostLevel + 1,
            chargersMaxCharges[weapon and weapon.blueprint and weapon.blueprint.name] - 1)
            first = first / chargerBoost ^ boostLevel
            second = second / chargerBoost ^ boostLevel
            chargeString = string.format("%.1f / %.1f", first, second)
        end
        return Defines.Chain.CONTINUE, chargeString, damageString, shotLimitString
    end)

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager) 


    --Thanks Nauter for this code :)
    for room in vter(shipManager.ship.vRoomList) do
        ---@type Hyperspace.Room
        room = room
        local table = userdata_table(room, "mods.lilybeams.chaosfire")
        if table.timer == nil then table.timer = 0 end
        if table.timer > 0 then
            table.timer = math.max(table.timer - time_increment(), 0)
            local shape = room.rect
            local startX = shape.x // 35
            local startY = shape.y // 35
            local endX = startX + (shape.w // 35) - 1
            local endY = startY + (shape.h // 35) - 1
            for x = startX, endX do
                for y = startY, endY do
                    shipManager:GetFire(x, y).fOxygen = 100
                end
            end
        end
    end


    if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("weapons")) then
        for weapon in vter(shipManager.weaponSystem.weapons) do
            ---@type Hyperspace.ProjectileFactory
            weapon = weapon
            if weapon and weapon.powered and weapon.blueprint.name == "LILY_FOCUS_CIWS" then
                if not userdata_table(weapon, "mods.lilybeams.ciws").delay then
                    userdata_table(weapon, "mods.lilybeams.ciws").delay = 0
                end
                local delay = userdata_table(weapon, "mods.lilybeams.ciws").delay
                delay = delay - (Hyperspace.FPS.SpeedFactor / 16)
                userdata_table(weapon, "mods.lilybeams.ciws").delay = delay
                local ready = weapon.weaponVisual.anim.currentFrame >= 4 and delay <= 0

                
                local firingPoint = weapon.mount.position + weapon.localPosition + weapon.weaponVisual.fireMountVector
                local firingPointf = Hyperspace.Pointf(firingPoint.x, firingPoint.y)
                
                if ready then
                    local spaceManager = Hyperspace.App.world.space
                    local otherShipManager = Hyperspace.ships(1 - shipManager.iShipId)
                    local targets = {}
                    if spaceManager.drones then
                        for drone in vter(spaceManager.drones) do
                            ---@type Hyperspace.SpaceDrone
                            drone = drone
                            
                            if drone.deployed and drone._collideable and drone._targetable --[[and defense_types.DRONES_MISSILES[drone._targetable.type]--]] and drone.currentSpace == shipManager.iShipId and drone.iShipId ~= shipManager.iShipId and drone:ValidTarget() then
                                    if otherShipManager and otherShipManager.hackingSystem and otherShipManager.hackingSystem.drone.currentLocation == drone.currentLocation then
                                        targets[#targets + 1] = { location = drone.currentLocation, velocity = drone.speedVector, isHackingDrone = true }
                                    else
                                        targets[#targets + 1] = { location = drone.currentLocation, velocity = drone.speedVector }
                                    end
                                --if firingPointf:RelativeDistance(drone.currentLocation) < 350 then 
                                --end
                            end
                        end
                    end
                    if spaceManager.projectiles then
                        for proj in vter(spaceManager.projectiles) do
                            ---@type Hyperspace.Projectile
                            proj = proj
                            if proj._targetable and (defense_types.DRONES_MISSILES[proj._targetable.type] or (proj:GetType() == 2 or proj:GetType() == 3)) and (proj:GetType() ~= 4 and proj:GetType() ~= 5 and proj:GetType() ~= 6) and proj._targetable:ValidTarget() and (not proj.startedDeath) and proj.currentSpace == shipManager.iShipId and proj.ownerId ~= shipManager.iShipId and not proj.passedTarget and proj:ValidTarget() then
                                --if firingPointf:RelativeDistance(proj.position) < 350 then
                                    targets[#targets + 1] = { location = proj.position, velocity = proj.speed }
                                --end
                            end
                        end
                    end

                    for _, target in pairs(targets) do
                        if target and target.velocity then
                            target.velocity = Hyperspace.Pointf(target.velocity.x / (18.333 * time_increment(true)),
                            target.velocity.y / (18.333 * time_increment(true)))
                        end
                    end
                    
                    if #targets > 0 then
                        local target = targets[math.random(#targets)]
                        ---@type Hyperspace.Pointf
                        local location = target.location
                        local intercept = find_collision_point(toVec(target.location), toVec(target.velocity),
                            toVec(location), 1000.0)
                        intercept = Hyperspace.Pointf(intercept.X, intercept.Y)
                        --[[local beam = spaceManager:CreateBeam(
                            Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_CIWS"),
                            firingPointf, 
                            shipManager.iShipId,
                            shipManager.iShipId,
                            location,
                            Hyperspace.Pointf(location.x, location.y + 1),
                            shipManager.iShipId,
                            1, -1
                        )--]]
                        local beam = 
                        {
                            position = firingPointf,
                            target = location,
                            space = shipManager.iShipId,
                            lifetime = 0.2
                        }
                        table.insert(ciwsRenderBeams, beam)

                        if target.isHackingDrone then
                            otherShipManager.hackingSystem:BlowHackingDrone()
                        end

                        --print("P", beam.position.x, beam.position.y, "T", beam.target.x, beam.target.y, "O", beam.space,
                        --beam.lifetime)
                        --beam:ComputeHeading()
                        --beam:Initialize(weapon.blueprint)
                        --beam:OnRenderSpecific(shipManager.iShipId)
                        --beam.speed_magnitude = beam.speed_magnitude * 0.1
                        Hyperspace.Sounds:PlaySoundMix("lily_lams_1", -1, false)
                        local p = spaceManager:CreateBurstProjectile(
                            Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_CIWS_PROJ"),
                            "lily_invisible",
                            false,
                            location, 
                            shipManager.iShipId,
                            shipManager.iShipId,
                            intercept,
                            shipManager.iShipId,
                            1
                        )
                        p:ComputeHeading()
                        for i = 1, 10, 1 do
                            local theta = 2 * math.random() * math.pi
                            local r = 5 * math.random()
                            p = spaceManager:CreateBurstProjectile(
                                Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_CIWS_PROJ"),
                                "lily_invisible",
                                false,
                                location,
                                shipManager.iShipId,
                                shipManager.iShipId,
                                Hyperspace.Pointf(intercept.x + r * math.cos(theta), intercept.y + r * math.sin(theta)),
                                shipManager.iShipId,
                                1
                            )
                            p:ComputeHeading()
                        end
                        local theta = 2 * math.random() * math.pi
                        local r = 5 * math.random()
                        p = spaceManager:CreateBurstProjectile(
                            Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_CIWS_PROJ_2"),
                            "lily_invisible",
                            false,
                            Hyperspace.Pointf(location.x + target.velocity.x, location.y + target.velocity.y) ,
                            shipManager.iShipId,
                            shipManager.iShipId,
                            location,
                            shipManager.iShipId,
                            1
                        )
                        p:ComputeHeading()
                        --print(firingPoint.x, firingPoint.y)
                        local cd = math.max(0, weapon.cooldown.first - weapon.cooldown.second / 5)
                        weapon.cooldown.first = cd
                        userdata_table(weapon, "mods.lilybeams.ciws").delay = 0.5
                    end


                end

            
            end

        end

    end



    
end)



script.on_render_event(Defines.RenderEvents.SHIP_SPARKS, function (ship)
    --local spaceManager = Hyperspace.App.world.space
    --print("Render")
    --local combatControl = Hyperspace.App.gui.combatControl
    --print(#ciwsRenderBeams)
    for _, beamData in pairs(ciwsRenderBeams) do

        --print("_", _)
        if ship.iShipId == beamData.space then
            
            if beamData.lifetime > 0 then
                --Graphics.CSurface.GL_PushMatrix()
                --if beamData.space == 0 then
                --Graphics.CSurface.GL_Translate(combatControl.playerShipPosition.x, combatControl.playerShipPosition.y)
            --elseif beamData.space == 1 and Hyperspace.ships.enemy then
                --Graphics.CSurface.GL_Translate(combatControl.targetPosition.x, combatControl.targetPosition.y)
            --end
            Graphics.CSurface.GL_DrawLine(beamData.position.x, beamData.position.y, beamData.target.x, beamData.target.y, 4,
            Graphics.GL_Color(1, 0, 0, 0.25))
            Graphics.CSurface.GL_DrawLine(beamData.position.x, beamData.position.y, beamData.target.x, beamData.target.y, 2,
            Graphics.GL_Color(1, 0, 0, 0.75))
            --Graphics.CSurface.GL_PopMatrix()

            end
            if not check_paused() then
                beamData.lifetime = beamData.lifetime or 0
                beamData.lifetime = beamData.lifetime - time_increment()
                if beamData.lifetime < 0 then
                    table.remove(ciwsRenderBeams, _)
                end
            end
        end

    end

    return Defines.Chain.CONTINUE
end, function () end)


local preigniteWeapons = {}

preigniteWeapons["LILY_FOCUS_CIWS"] = true

script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function (shipManager)
    
    if shipManager then
        if shipManager.weaponSystem and shipManager.weaponSystem.weapons then
            for weapon in vter(shipManager.weaponSystem.weapons) do
                ---@type Hyperspace.ProjectileFactory
                weapon = weapon
                if preigniteWeapons[weapon.name] then
                    weapon.cooldown.first = weapon.cooldown.second
                end
            end
        end
    end

end)
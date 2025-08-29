
local vter = mods.multiverse.vter
local userdata_table = mods.multiverse.userdata_table
local INT_MAX = 2147483647

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
-- LASER POINTER --
-----------------------------------------------------------------


script.on_internal_event(Defines.InternalEvents.DAMAGE_BEAM,
    function(shipManager, projectile, location, damage, newTile, beamHit)
        local weaponName = projectile and projectile.extend and projectile.extend.name
        --local weaponName = nil
        --if pcall(function() weaponName = projectile.extend.name end) and weaponName then
        if weaponName then
            local otherShip = Hyperspace.ships(1 - shipManager.iShipId)

            -- Make drones target the location the target painter laser hit
            if weaponName == "LILY_FOCUS_POINTER" then
                for drone in vter(otherShip.spaceDrones) do
                    drone.targetLocation = location
                end
            end
            if weaponName == "LILY_BEAM_FROST" then

                if beamHit == Defines.BeamHit.NEW_ROOM or beamHit == Defines.BeamHit.NEW_TILE then
                    local roomId = shipManager.ship:GetSelectedRoomId(location.x, location.y, true)
                    if roomId >= 0 then
                        shipManager.oxygenSystem:ModifyRoomOxygen(roomId, -999)
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
        end
        return Defines.Chain.CONTINUE, beamHit
    end)

-----------------------------------------------------------------
-- SIPHON AND SHOTGUN BEAMS --
-----------------------------------------------------------------

local burstPinpoints = {}
burstPinpoints["LILY_BEAM_AMP_SIPHON_0"] = "LILY_BEAM_AMP_SIPHON"
burstPinpoints["LILY_BEAM_AMP_SIPHON_1"] = "LILY_BEAM_AMP_SIPHON"
burstPinpoints["LILY_BEAM_AMP_SIPHON_2"] = "LILY_BEAM_AMP_SIPHON"
burstPinpoints["LILY_BEAM_AMP_SIPHON_3"] = "LILY_BEAM_AMP_SIPHON"
burstPinpoints["LILY_BEAM_TOGGLE_AKATSUKI_S"] = "LILY_BEAM_TOGGLE_AKATSUKI_S_BEAM"
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


script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
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
burstPins["LILY_BEAM_SHOTGUN_P"] = { count = 1, countSuper = 1, siphon = false }
burstPins["LILY_BEAM_SHOTGUN_9_P"] = { count = 1, countSuper = 1, siphon = false }

-- Pop shield bubbles
script.on_internal_event(Defines.InternalEvents.SHIELD_COLLISION, function(shipManager, projectile, damage, response)
    local shieldPower = shipManager.shieldSystem.shields.power
    local weaponName = projectile and projectile.extend and projectile.extend.name
    local popData = burstPins[projectile and projectile.extend and projectile.extend.name]
    local otherShip = Hyperspace.ships(1 - shipManager.iShipId)
    local otherShieldPower = otherShip and otherShip.shieldSystem.shields.power or nil
    if popData then
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
        projectile:Kill()
    end


    -- refractors
    if shieldPower.first > 0 and shieldPower.super.first == 0 and refractors[weaponName] ~= nil then
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
            local beam = spaceManager:CreateBeam(
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
        projectile:Kill()
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

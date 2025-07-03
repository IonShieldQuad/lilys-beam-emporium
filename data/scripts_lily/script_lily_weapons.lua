
local vter = mods.multiverse.vter
local INT_MAX = 2147483647


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

        end
    end)

-----------------------------------------------------------------
-- SIPHON BEAM --
-----------------------------------------------------------------

local burstPinpoints = {}
burstPinpoints["LILY_BEAM_AMP_SIPHON_0"] = "LILY_BEAM_AMP_SIPHON"
burstPinpoints["LILY_BEAM_AMP_SIPHON_1"] = "LILY_BEAM_AMP_SIPHON"
burstPinpoints["LILY_BEAM_AMP_SIPHON_2"] = "LILY_BEAM_AMP_SIPHON"
burstPinpoints["LILY_BEAM_AMP_SIPHON_3"] = "LILY_BEAM_AMP_SIPHON"

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
end)

local burstPins = {}
burstPins["LILY_BEAM_AMP_SIPHON"] = { count = 1, countSuper = 1 }
-- Pop shield bubbles
script.on_internal_event(Defines.InternalEvents.SHIELD_COLLISION, function(shipManager, projectile, damage, response)
    local shieldPower = shipManager.shieldSystem.shields.power
    local popData = burstPins[projectile and projectile.extend and projectile.extend.name]
    local otherShip = Hyperspace.ships(1 - shipManager.iShipId)
    local otherShieldPower = otherShip and otherShip.shieldSystem.shields.power or nil
    if popData then
        if shieldPower.super.first > 0 then
            if popData.countSuper > 0 then
                shipManager.shieldSystem:CollisionReal(projectile.position.x, projectile.position.y, Hyperspace.Damage(),
                    true)
                shieldPower.super.first = math.max(0, shieldPower.super.first - popData.countSuper)
                if otherShieldPower then
                    otherShieldPower.super.first = math.min(math.max(otherShieldPower.super.second, 5), otherShieldPower.super.first + popData.countSuper)
                end
            end
        else
            local hasShield = shieldPower.first > 0
            shipManager.shieldSystem:CollisionReal(projectile.position.x, projectile.position.y, Hyperspace.Damage(),
                true)
            shieldPower.first = math.max(0, shieldPower.first - popData.count)
            if otherShieldPower and hasShield then
                otherShieldPower.first = math.min(otherShieldPower.second,
                otherShieldPower.first + popData.count)
            end
        end
        projectile:Kill()
    end
end)

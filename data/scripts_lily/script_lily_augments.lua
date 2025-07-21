local vter = mods.multiverse.vter
local INT_MAX = 2147483647



script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
    local ship = Hyperspace.ships(projectile.ownerId)
    if ship and ship:HasAugmentation("LILY_TARGETING_BYPASS") > 0 then
        projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod - 30
    end
end)

script.on_internal_event(Defines.InternalEvents.PROJECTILE_INITIALIZE, function(projectile)
    --print("TYPE: " .. projectile:GetType())
    --print("DEST: " .. projectile.destinationSpace)
    --print("X: " .. projectile.target.x)
    --print("Y: " .. projectile.target.y)
    local destination = projectile.destinationSpace
    local ship = Hyperspace.ships(destination)
    --print("SHIP: " .. (ship == nil and "X" or "OK"))
    if ship and ship:HasAugmentation("LILY_ASB_SCRAMBLER") > 0 and projectile:GetType() == 6 then
        projectile.target = Hyperspace.Pointf(-400, projectile.target.y)
        --print("newX: " .. projectile.target.x)
        --print("newY: " .. projectile.target.y)
        projectile:ComputeHeading()
    end
end)

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA,
    function(ship, projectile, location, damage, forceHit, shipFriendlyFire)
        --damage.iDamage = 0
        --damage.breachChance = 0
        --print("TYPE: " .. projectile:GetType())
        local otherShip = Hyperspace.ships(1 - ship.iShipId)
        if ship and ship:HasAugmentation("LILY_ASB_SCRAMBLER") > 0 and projectile and projectile:GetType() == 6 then
            forceHit = Defines.Evasion.MISS
            --projectile:Kill()
            damage.iDamage = 0
            damage.breachChance = 0
            projectile.hitTarget = false
            projectile.missed = true
            return Defines.Chain.CONTINUE, Defines.Evasion.MISS, shipFriendlyFire
        end

        if projectile and ship and otherShip and otherShip:HasAugmentation("LILY_ANTI_CEL") > 0 then
            --ship.weaponSystem.weapons
            local celFound = false
            --for crew in vter(ship.vCrewList) do
                


            --end
            

        end

        return Defines.Chain.CONTINUE, forceHit, shipFriendlyFire
    end)

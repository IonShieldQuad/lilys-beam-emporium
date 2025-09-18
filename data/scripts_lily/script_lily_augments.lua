local vter = mods.multiverse.vter
local INT_MAX = 2147483647



script.on_internal_event(Defines.InternalEvents.JUMP_LEAVE, function(ship)
    if ship.ship.iShipId == 0 then
        Hyperspace.playerVariables.lily_afterburner_active = 0
    end
end)

script.on_internal_event(Defines.InternalEvents.GET_DODGE_FACTOR, function(ship, value)
    if ship.ship.iShipId == 0 and ship:HasAugmentation("LILY_COMBAT_AFTERBURNER") then
        if value == 0 then
            return Defines.Chain.CONTINUE, value
        end
        return Defines.Chain.CONTINUE, value + Hyperspace.playerVariables.lily_afterburner_active * 20
    end
    return Defines.Chain.CONTINUE, value
end)

script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
    local ship = Hyperspace.ships(projectile.ownerId)
    if ship and (ship:HasAugmentation("LILY_TARGETING_BYPASS") > 0 or ship:HasAugmentation("LILY_TARGETING_BYPASS_LOCKED") > 0) and projectile.destinationSpace ~= projectile.currentSpace then
        projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod -
            20 * (ship:HasAugmentation("LILY_TARGETING_BYPASS") + ship:HasAugmentation("LILY_TARGETING_BYPASS_LOCKED"))
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
            local crewList = Hyperspace.Blueprints:GetBlueprintList("LIST_CREW_SYLVAN")
            local itemList = Hyperspace.Blueprints:GetBlueprintList("JUDGELIST_ROCK_NEXUS_LOOT")
            for crew in vter(ship.vCrewList) do
                for crewl in vter(crewList) do
                    --print("C: " .. crew.blueprint.name)
                    --print("L: " .. crewl)
                    if crew.blueprint.name == crewl then
                        celFound = true
                        break
                    end

                    if celFound then
                        break
                    end
                end
                if celFound then
                    break
                end
            end
            
            if not celFound then
                local weapons = ship and ship.weaponSystem and ship.weaponSystem.weapons
                if weapons then
                    for weapon in vter(weapons) do
                        if weapon and weapon.blueprint and weapon.blueprint.name and weapon.blueprint.name then
                            local wname = weapon.blueprint.name

                            for item in vter(itemList) do
                                if item == wname then
                                    celFound = true
                                    break
                                end
                            end
                        end
                        if celFound then
                            break
                        end
                    end
                end
            end

            if not celFound then
                local drones = ship and ship.droneSystem and ship.droneSystem.drones
                if drones then
                    for drone in vter(drones) do
                        if drone and drone.blueprint and drone.blueprint.name and drone.blueprint.name then
                            local dname = drone.blueprint.name

                            for item in vter(itemList) do
                                if item == dname then
                                    celFound = true
                                    break
                                end
                            end
                        end
                        if celFound then
                            break
                        end
                    end
                end
            end
            
            if celFound then
                if damage.iDamage > 0 then
                    damage.iDamage = damage.iDamage * 2
                end
                if damage.iSystemDamage > 0 then
                    damage.iSystemDamage = damage.iSystemDamage * 2
                end
                if damage.iPersDamage > 0 then
                    damage.iPersDamage = damage.iPersDamage * 2
                end
                if damage.iIonDamage > 0 then
                    damage.iIonDamage = damage.iIonDamage * 2
                end
            end


        end

        return Defines.Chain.CONTINUE, forceHit, shipFriendlyFire
    end)



script.on_internal_event(Defines.InternalEvents.DAMAGE_BEAM,
    function(ship, projectile, location, damage, newTile, beamHit)
        local otherShip = Hyperspace.ships(1 - ship.iShipId)
       
        if projectile and ship and otherShip and otherShip:HasAugmentation("LILY_ANTI_CEL") > 0 then
            local celFound = false
            local crewList = Hyperspace.Blueprints:GetBlueprintList("LIST_CREW_SYLVAN")
            local itemList = Hyperspace.Blueprints:GetBlueprintList("JUDGELIST_ROCK_NEXUS_LOOT")
            for crew in vter(ship.vCrewList) do
                for crewl in vter(crewList) do
                    --print("C: " .. crew.blueprint.name)
                    --print("L: " .. crewl)
                    if crew.blueprint.name == crewl then
                        celFound = true
                        break
                    end

                    if celFound then
                        break
                    end
                end
                if celFound then
                    break
                end
            end

            if not celFound then
                local weapons = ship and ship.weaponSystem and ship.weaponSystem.weapons
                if weapons then
                    for weapon in vter(weapons) do
                        if weapon and weapon.blueprint and weapon.blueprint.name and weapon.blueprint.name then
                            local wname = weapon.blueprint.name

                            for item in vter(itemList) do
                                if item == wname then
                                    celFound = true
                                    break
                                end
                            end
                        end
                        if celFound then
                            break
                        end
                    end
                end
            end

            if not celFound then
                local drones = ship and ship.droneSystem and ship.droneSystem.drones
                if drones then
                    for drone in vter(drones) do
                        if drone and drone.blueprint and drone.blueprint.name and drone.blueprint.name then
                            local dname = drone.blueprint.name

                            for item in vter(itemList) do
                                if item == dname then
                                    celFound = true
                                    break
                                end
                            end
                        end
                        if celFound then
                            break
                        end
                    end
                end
            end

            if celFound then
                if damage.iDamage > 0 then
                    damage.iDamage = damage.iDamage * 2
                end
                if damage.iSystemDamage > 0 then
                    damage.iSystemDamage = damage.iSystemDamage * 2
                end
                if damage.iPersDamage > 0 then
                    damage.iPersDamage = damage.iPersDamage * 2
                end
                if damage.iIonDamage > 0 then
                    damage.iIonDamage = damage.iIonDamage * 2
                end
            end
        end

        return Defines.Chain.CONTINUE, beamHit
    end)


    script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager) 
        if shipManager and shipManager:HasAugmentation("LILY_ESTROGEN_DISPERSAL") > 0 then
            for crew in vter(shipManager.vCrewList) do
                ---@type Hyperspace.CrewMember
                crew = crew
                if crew and (crew.iShipId == shipManager.iShipId) then
                    crew:SetSex(false)
                end
            end 
        end
    end)


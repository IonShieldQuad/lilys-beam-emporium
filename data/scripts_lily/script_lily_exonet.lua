local vter = mods.multiverse.vter
local userdata_table = mods.multiverse.userdata_table
local time_increment = mods.multiverse.time_increment
local check_paused = mods.multiverse.check_paused
local INT_MAX = 2147483647

local preigniters = {}
preigniters["LILY_EXONET_WEAPON_CORE_RADIANT"] = true
preigniters["LILY_EXONET_WEAPON_CORE_IRIDIUM"] = true

local reloadBoost = {}
reloadBoost["LILY_EXONET_WEAPON_CORE_VERDANT"] = 0.1
reloadBoost["LILY_EXONET_WEAPON_CORE_CRIMSON"] = 0.25
reloadBoost["LILY_EXONET_WEAPON_CORE_AZURE"] = 0.5
reloadBoost["LILY_EXONET_WEAPON_CORE_RADIANT"] = 1.0
reloadBoost["LILY_EXONET_WEAPON_CORE_IRIDIUM"] = 2.0

local accBoost = {}
accBoost["LILY_EXONET_WEAPON_CORE_VERDANT"] = 10
accBoost["LILY_EXONET_WEAPON_CORE_CRIMSON"] = 20
accBoost["LILY_EXONET_WEAPON_CORE_AZURE"] = 30
accBoost["LILY_EXONET_WEAPON_CORE_RADIANT"] = 50
accBoost["LILY_EXONET_WEAPON_CORE_IRIDIUM"] = 80

local augCheckList = {
    "LILY_EXONET_SHIP_MAINFRAME_VERDANT",
    "LILY_EXONET_SHIP_MAINFRAME_CRIMSON",
    "LILY_EXONET_SHIP_MAINFRAME_AZURE",
    "LILY_EXONET_SHIP_MAINFRAME_RADIANT",
    "LILY_EXONET_SHIP_MAINFRAME_IRIDIUM",
}

local automationLevel = {}
automationLevel["LILY_EXONET_SHIP_MAINFRAME_AZURE"] = 1
automationLevel["LILY_EXONET_SHIP_MAINFRAME_RADIANT"] = 2
automationLevel["LILY_EXONET_SHIP_MAINFRAME_IRIDIUM"] = 3

local allSysBoost = {}
allSysBoost["LILY_EXONET_SHIP_MAINFRAME_VERDANT"] = 0
allSysBoost["LILY_EXONET_SHIP_MAINFRAME_CRIMSON"] = 1
allSysBoost["LILY_EXONET_SHIP_MAINFRAME_AZURE"] = 2
allSysBoost["LILY_EXONET_SHIP_MAINFRAME_RADIANT"] = 4
allSysBoost["LILY_EXONET_SHIP_MAINFRAME_IRIDIUM"] = 6

local sysBoosts = {}
sysBoosts["LILY_EXONET_SHIP_MAINFRAME_VERDANT"] = { engines = 3 }
sysBoosts["LILY_EXONET_SHIP_MAINFRAME_CRIMSON"] = { engines = 4, shields = 2, lily_ablative_armor = 2 }
sysBoosts["LILY_EXONET_SHIP_MAINFRAME_AZURE"] = { engines = 5, shields = 4, lily_ablative_armor = 4, lily_ecm_suite = 4 }
sysBoosts["LILY_EXONET_SHIP_MAINFRAME_RADIANT"] = { engines = 6, shields = 8, lily_ablative_armor = 8, lily_ecm_suite = 6 }
sysBoosts["LILY_EXONET_SHIP_MAINFRAME_IRIDIUM"] = { engines = 8, shields = 16, lily_ablative_armor = 16, lily_ecm_suite = 8 }

-- Preignite logic
script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    if mods.lilybeams.checkStartOK() and shipManager then
        if shipManager.weaponSystem and shipManager.weaponSystem.weapons then
            local preignite = false
            for weapon in vter(shipManager.weaponSystem.weapons) do
                ---@type Hyperspace.ProjectileFactory
                weapon = weapon
                if weapon and preigniters[weapon.blueprint.name] then
                    preignite = true
                end
            end
            if preignite then
                for weapon in vter(shipManager.weaponSystem.weapons) do
                    ---@type Hyperspace.ProjectileFactory
                    weapon = weapon
                    if weapon and weapon.powered then
                        weapon:ForceCoolup()
                    end
                end
            end
        end
    end
end)

-- Reload logic
script.on_internal_event(Defines.InternalEvents.GET_AUGMENTATION_VALUE, function(shipManager, augment, value)
    if mods.lilybeams.checkStartOK() and augment == "AUTO_COOLDOWN" and shipManager and shipManager.weaponSystem and shipManager.weaponSystem.weapons then
        local reloadBoostSum = 0
        for weapon in vter(shipManager.weaponSystem.weapons) do
            ---@type Hyperspace.ProjectileFactory
            weapon = weapon
            if weapon and reloadBoost[weapon.blueprint.name] then
                reloadBoostSum = reloadBoostSum + reloadBoost[weapon.blueprint.name]
            end
            --print(weapon.blueprint.name, reloadBoost[weapon.blueprint.name])
        end

        value = value + reloadBoostSum

    end
    return Defines.Chain.CONTINUE, value
end)

-- Accuracy logic
script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
    if mods.lilybeams.checkStartOK() and projectile then
        local shipManager = Hyperspace.ships(projectile.ownerId)
        local otherShipManager = Hyperspace.ships(1 - projectile.ownerId)
        if shipManager and otherShipManager then
            if shipManager.weaponSystem and shipManager.weaponSystem.weapons then
                local accBoostSum = 0
                for weap in vter(shipManager.weaponSystem.weapons) do
                    ---@type Hyperspace.ProjectileFactory
                    weap = weap
                    if weap and accBoost[weap.blueprint.name] then
                        accBoostSum = accBoostSum + accBoost[weap.blueprint.name]
                    end
                end
                projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod + accBoostSum
            end

        end
    end
end)

script.on_internal_event(Defines.InternalEvents.DRONE_FIRE, function(projectile, spacedrone)
    if mods.lilybeams.checkStartOK() and projectile then
        local shipManager = Hyperspace.ships(projectile.ownerId)
        local otherShipManager = Hyperspace.ships(1 - projectile.ownerId)
        if shipManager and otherShipManager then
            if shipManager.weaponSystem and shipManager.weaponSystem.weapons then
                local accBoostSum = 0
                for weap in vter(shipManager.weaponSystem.weapons) do
                    ---@type Hyperspace.ProjectileFactory
                    weap = weap
                    if weap and accBoost[weap.blueprint.name] then
                        accBoostSum = accBoostSum + accBoost[weap.blueprint.name]
                    end
                end
                projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod + accBoostSum
            end
        end
    end
end)


-- Systems auto logic

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    if mods.lilybeams.checkStartOK() and shipManager then
        local bestAug = nil
        for key, value in ipairs(augCheckList) do
            if shipManager:HasAugmentation(value) > 0 then
                bestAug = value
            end
        end
        if bestAug then
            for sys in vter(shipManager.vSystemList) do
                ---@type Hyperspace.ShipSystem
                sys = sys
                if sys then
                    --sys:PartialRepair(3, true)
                    if automationLevel[bestAug] then
                        sys.iActiveManned = math.max(sys.iActiveManned, automationLevel[bestAug])
                    end
                end
            end
        end
    end
end)

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    if mods.lilybeams.checkStartOK() and shipManager then
        local bestAug = nil
        for key, value in ipairs(augCheckList) do
            if shipManager:HasAugmentation(value) > 0 then
                bestAug = value
            end
        end
        if bestAug then
            for sys in vter(shipManager.vSystemList) do
                ---@type Hyperspace.ShipSystem
                sys = sys
                if sys then
                    --sys:PartialRepair(3, true)
                    if automationLevel[bestAug] then
                        sys.iActiveManned = math.max(sys.iActiveManned, automationLevel[bestAug])
                    end
                end
            end
        end
    end
end)
-- System power logic
script.on_internal_event(Defines.InternalEvents.SET_BONUS_POWER, function(system, amount)

    if mods.lilybeams.checkStartOK() then

        local shipManager = Hyperspace.ships(system._shipObj.iShipId)

        if shipManager and system then
            local bestAug = nil
            for key, value in ipairs(augCheckList) do
                if shipManager:HasAugmentation(value) > 0 then
                    bestAug = value
                end
            end
            if bestAug then
                if allSysBoost[bestAug] then
                    amount = amount + allSysBoost[bestAug]
                end
                local name = Hyperspace.ShipSystem.SystemIdToName(system:GetId())
                if sysBoosts[bestAug] and sysBoosts[bestAug][name] then
                    amount = amount + sysBoosts[bestAug][name]
                    if allSysBoost[bestAug] then
                        amount = amount - allSysBoost[bestAug]
                    end
                end
            end
        end
    end
    return Defines.Chain.CONTINUE, amount
end)

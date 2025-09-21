-- Change short name based on stability
-- Thanks @Alder for the idea

local lilyBeamsNeedsNameGenerated = true

script.on_game_event("START_BEACON", false, function() lilyBeamsNeedsNameGenerated = true end)
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if lilyBeamsNeedsNameGenerated then
        local stability = Hyperspace.playerVariables.stability

        -- Set up weapon data
        local shortDescZoltan2 = stability >= 100 and "'Lucerne'" or "'Lootcerne'"
        local blueprintZoltan2 = Hyperspace.Blueprints:GetWeaponBlueprint("LOOT_ZOLTAN_2")
        local shortDescIon1 = stability >= 100 and "Ionpoint I" or "Pinion I"
        local blueprintIon1 = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_ION_1")
        local shortDescIon2 = stability >= 100 and "Ionpoint II" or "Pinion II"
        local blueprintIon2 = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_ION_2")
        local shortDescIonHeavy = stability >= 100 and "Hv. Ionpoint" or "Hv. Pinion"
        local blueprintIonHeavy = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_ION_HEAVY")
        local shortDescIonChain = stability >= 100 and "Ch. Ionpoint" or "Ch. Pinion"
        local blueprintIonChain = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_ION_CHAIN")
        local shortDescIonPhase = stability >= 100 and "Ph. Ionpoint" or "Ph. Pinion"
        local blueprintIonPhase = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_ION_PHASE")
        local shortDescIonFire = stability >= 100 and "Th. Ionpoint" or "Th. Pinion"
        local blueprintIonFire = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_ION_FIRE")
        local shortDescIonStun = stability >= 100 and "St. Ionpoint" or "St. Pinion"
        local blueprintIonStun = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_ION_STUN")
        local shortDescIonBio = stability >= 100 and "Rad Ionpoint" or "Rad Pinion"
        local blueprintIonBio = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_ION_BIO")


        -- Change the name
        blueprintZoltan2.desc.shortTitle.data = shortDescZoltan2
        blueprintIon1.desc.shortTitle.data = shortDescIon1
        blueprintIon2.desc.shortTitle.data = shortDescIon2
        blueprintIonHeavy.desc.shortTitle.data = shortDescIonHeavy
        blueprintIonChain.desc.shortTitle.data = shortDescIonChain
        blueprintIonPhase.desc.shortTitle.data = shortDescIonPhase
        blueprintIonFire.desc.shortTitle.data = shortDescIonFire
        blueprintIonStun.desc.shortTitle.data = shortDescIonStun
        blueprintIonBio.desc.shortTitle.data = shortDescIonBio

        -- Don't change name until another run is started
        lilyBeamsNeedsNameGenerated = false
    end
end)

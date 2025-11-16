-- Change short name based on stability
-- Thanks @Alder for the idea

local lilyBeamsNeedsNameGenerated = true

script.on_game_event("START_BEACON", false, function() lilyBeamsNeedsNameGenerated = true end)
script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    if Hyperspace.playerVariables and Hyperspace.playerVariables.stability > 0 and lilyBeamsNeedsNameGenerated then
        local stability = Hyperspace.playerVariables.stability

        -- Set up weapon data
        local blueprintZoltan2 = Hyperspace.Blueprints:GetWeaponBlueprint("LOOT_ZOLTAN_2")
        local blueprintIon1 = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_ION_1")
        local blueprintIon2 = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_ION_2")
        local blueprintIonHeavy = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_ION_HEAVY")
        local blueprintIonChain = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_ION_CHAIN")
        local blueprintIonPhase = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_ION_PHASE")
        local blueprintIonFire = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_ION_FIRE")
        local blueprintIonStun = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_ION_STUN")
        local blueprintIonBio = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_ION_BIO")
        local blueprintIon2Player = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_ION_2_PLAYER")
        local blueprintFocusCIWS = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_FOCUS_CIWS")

        -- Change the name
        if stability < 100 then
            
            blueprintZoltan2.desc.shortTitle.data = "lily_text_shortDescZoltan2_alt"
            blueprintIon1.desc.shortTitle.data = "lily_text_shortDescIon1_alt"
            blueprintIon2.desc.shortTitle.data = "lily_text_shortDescIon2_alt"
            blueprintIonHeavy.desc.shortTitle.data = "lily_text_shortDescIonHeavy_alt"
            blueprintIonChain.desc.shortTitle.data = "lily_text_shortDescIonChain_alt"
            blueprintIonPhase.desc.shortTitle.data = "lily_text_shortDescIonPhase_alt"
            blueprintIonFire.desc.shortTitle.data = "lily_text_shortDescIonFire_alt"
            blueprintIonStun.desc.shortTitle.data = "lily_text_shortDescIonStun_alt"
            blueprintIonBio.desc.shortTitle.data = "lily_text_shortDescIonBio_alt"
            blueprintIon2Player.desc.shortTitle.data = "lily_text_shortDescIon2Player_alt"
            blueprintFocusCIWS.desc.shortTitle.data = "lily_text_shortDescFocusCIWS_alt"

            blueprintZoltan2.desc.shortTitle.isLiteral = false
            blueprintIon1.desc.shortTitle.isLiteral = false
            blueprintIon2.desc.shortTitle.isLiteral = false
            blueprintIonHeavy.desc.shortTitle.isLiteral = false
            blueprintIonChain.desc.shortTitle.isLiteral = false
            blueprintIonPhase.desc.shortTitle.isLiteral = false
            blueprintIonFire.desc.shortTitle.isLiteral = false
            blueprintIonStun.desc.shortTitle.isLiteral = false
            blueprintIonBio.desc.shortTitle.isLiteral = false
            blueprintIon2Player.desc.shortTitle.isLiteral = false
            blueprintFocusCIWS.desc.shortTitle.isLiteral = false
            
        end
        -- Don't change name until another run is started
        lilyBeamsNeedsNameGenerated = false
    end
end)

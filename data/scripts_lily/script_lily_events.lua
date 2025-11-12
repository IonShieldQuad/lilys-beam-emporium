local vter = mods.multiverse.vter
local string_starts = mods.multiverse.string_starts
local screen_fade = mods.multiverse.screen_fade
local screen_shake = mods.multiverse.screen_shake
local on_load_game = mods.multiverse.on_load_game
local INT_MAX = 2147483647



mods.lilybeams.lilySylvanHater = {}
mods.lilybeams.lilySylvanHaterNoSur = {}


mods.lilybeams.lilySylvanHater = {}
mods.lilybeams.lilySylvanHaterNoSur = {}
mods.lilybeams.lilySylvanHater["SYLVAN_CASHGRAB"] = true
mods.lilybeams.lilySylvanHater["SYLVAN_REBEL"] = true
mods.lilybeams.lilySylvanHater["SYLVAN_JOKE"] = true
mods.lilybeams.lilySylvanHater["SYLVAN_HARDSCIFI"] = true
mods.lilybeams.lilySylvanHater["SYLVAN_SANS"] = true

mods.lilybeams.lilySylvanHaterNoSur["NEXUS_PORTAL_SURRENDER"] = true
mods.lilybeams.lilySylvanHaterNoSur["SYLVAN_REBEL_SURRENDER"] = true

mods.lilybeams.lilyFightQuotes = {
    Hyperspace.Text:GetText("lily_eventtext_sylvanfight1"),
    Hyperspace.Text:GetText("lily_eventtext_sylvanfight2"),
    Hyperspace.Text:GetText("lily_eventtext_sylvanfight3"),
    Hyperspace.Text:GetText("lily_eventtext_sylvanfight4"),
    Hyperspace.Text:GetText("lily_eventtext_sylvanfight5")
}
mods.lilybeams.lilyNoSurQuotes = {
    Hyperspace.Text:GetText("lily_eventtext_sylvannosur1"),
    Hyperspace.Text:GetText("lily_eventtext_sylvannosur2"),
    Hyperspace.Text:GetText("lily_eventtext_sylvannosur3"),
    Hyperspace.Text:GetText("lily_eventtext_sylvannosur4"),
    Hyperspace.Text:GetText("lily_eventtext_sylvannosur5")
}

mods.lilybeams.lilyVisionQuotes = {
    Hyperspace.Text:GetText("lily_eventtext_visiontext1"),
    Hyperspace.Text:GetText("lily_eventtext_visiontext2"),
    Hyperspace.Text:GetText("lily_eventtext_visiontext3"),
    Hyperspace.Text:GetText("lily_eventtext_visiontext4")
}

local function LilyForceFight(event)
    local invalid = Hyperspace.Event:CreateEvent("OPTION_INVALID", Hyperspace.App.world.starMap.worldLevel, true);
    local fight = Hyperspace.Event:CreateEvent("LILY_MAD_FIGHT", Hyperspace.App.world.starMap.worldLevel, true);
    local Choices = event:GetChoices()
    for choice in vter(Choices) do
        choice.event = invalid
    end
    local req = Hyperspace.ChoiceReq()
    req.object = "LILY_PATRONAGE"
    req.min_level = 1
    req.max_level = 999
    req.max_group = 0
    req.blue = true
    event:AddChoice(fight, mods.lilybeams.lilyFightQuotes[math.random(#mods.lilybeams.lilyFightQuotes)], req, false)
end

local function LilyForceNoSur(event)
    local invalid = Hyperspace.Event:CreateEvent("OPTION_INVALID", Hyperspace.App.world.starMap.worldLevel, true);
    local fight = Hyperspace.Event:CreateEvent("LILY_MAD_SURRENDER", Hyperspace.App.world.starMap.worldLevel, true);
    local Choices = event:GetChoices()
    for choice in vter(Choices) do
        choice.event = invalid
    end
    local req = Hyperspace.ChoiceReq()
    req.object = "LILY_PATRONAGE"
    req.min_level = 1
    req.max_level = 999
    req.max_group = 0
    req.blue = true
    event:AddChoice(fight, mods.lilybeams.lilyNoSurQuotes[math.random(#mods.lilybeams.lilyNoSurQuotes)], req, false)
end

mods.lilybeams.LilyForceFight = LilyForceFight
mods.lilybeams.LilyForceNoSur = LilyForceNoSur

script.on_internal_event(Defines.InternalEvents.PRE_CREATE_CHOICEBOX, function(event)
    if event.eventName == "LILY_EMPORIUM_GLITCH" then
        Hyperspace.playerVariables.lily_backdoor = 1
    end
    --print(event.eventName)
    local shipManager = Hyperspace.ships.player

    -- If player visited Lily and made a deal
    if shipManager and shipManager:HasAugmentation("LILY_PATRONAGE") > 0 then


        if event.eventName == "TRANSPORT_CAPTURE_STARGROVE" then
            local replace = Hyperspace.Event:CreateEvent("TRANSPORT_CAPTURE_STARGROVE_LILY",
                Hyperspace.App.world.starMap.worldLevel, true);
            local req = Hyperspace.ChoiceReq()
            req.object = "LILY_PATRONAGE"
            req.min_level = 1
            req.max_level = 999
            req.max_group = 0
            req.blue = false
            local Choices = event:GetChoices()
            for choice in vter(Choices) do
                choice.event = replace
                choice.textv = Hyperspace.Text:GetText("lily_eventtext_continue")
            end
        end











        --Nexus stuff ahead
        if mods.lilybeams.lilySylvanHater[event.eventName] ~= nil then
            LilyForceFight(event)
        end
        if mods.lilybeams.lilySylvanHaterNoSur[event.eventName] ~= nil then
            LilyForceNoSur(event)
        end
        local invalid = Hyperspace.Event:CreateEvent("OPTION_INVALID", Hyperspace.App.world.starMap.worldLevel, true);

        -- G-Van
        if event.eventName == "NEXUS_GUARD_SURRENDER" then
            local Choices = event:GetChoices()
            local i = 1
            for choice in vter(Choices) do
                if i == 1 then
                    choice.event = invalid
                end
                if i == 2 then
                    choice.text.data = mods.lilybeams.lilyNoSurQuotes[math.random(#mods.lilybeams.lilyNoSurQuotes)]
                end
                i = i + 1
            end
        end

        -- Narrator
        if event.eventName == "SYLVAN_NARRATOR_AGAIN" then
            local Choices = event:GetChoices()
            local i = 1
            for choice in vter(Choices) do
                if i == 1 then
                    choice.event = invalid
                end
                i = i + 1
            end
        end

        -- Dylan
        if event.eventName == "DYLAN" then
            local Choices = event:GetChoices()
            local i = 1
            for choice in vter(Choices) do
                if i <= 2 then
                    choice.event = invalid
                end
                if i == 3 then
                    choice.text.data = mods.lilybeams.lilyFightQuotes[math.random(#mods.lilybeams.lilyFightQuotes)]
                end
                i = i + 1
            end
        end

        --[[ Capitalist
        if event.eventName == "SYLVAN_CASHGRAB" then
            local fight = Hyperspace.Event:CreateEvent("LILY_MAD_FIGHT", Hyperspace.App.world.starMap.worldLevel, true,
                Hyperspace.Global.currentSeed);
            local Choices = event:GetChoices()
            for choice in vter(Choices) do
                choice.event = invalid
            end
            local req = Hyperspace.ChoiceReq()
            req.object = "LILY_PATRONAGE"
            req.min_level = 1
            req.max_level = 999
            req.max_group = 0
            req.blue = true
            event:AddChoice(fight, mods.lilybeams.lilyFightQuotes[math.random(#mods.lilybeams.lilyFightQuotes)], req, false)
        end]]--

        -- Everything
        if event.eventName == "SYLVAN_EVERYTHING" then
            local Choices = event:GetChoices()
            local i = 1
            for choice in vter(Choices) do
                if i == 1 then
                    choice.event = invalid
                end
                i = i + 1
            end
        end


        -- Surrender
        if event.eventName == "SYLVAN_PRIME_SURRENDER_REAL" then
            local Choices = event:GetChoices()
            local i = 1
            for choice in vter(Choices) do
                if i == 1 then
                    choice.event = invalid
                    choice.text.data = Hyperspace.Text:GetText("lily_eventtext_nospareprime")
                end
                i = i + 1
            end
        end

        -- Gnome
        if event.eventName == "SYLVAN_PRIME_SURRENDER_GNOME_2" then
            local gnomealt = Hyperspace.Event:CreateEvent("NEXUS_HER_REVEAL_FADE_LILY",
            Hyperspace.App.world.starMap.worldLevel, true);
            local Choices = event:GetChoices()
            local i = 1
            for choice in vter(Choices) do
                if i == 1 then
                    choice.event = gnomealt
                end
                i = i + 1
            end
        end

        -- Her realm
        if event.eventName == "REALM_MADNESS_START" then
            event.text.data = Hyperspace.Text:GetText("lily_eventtext_herrealm_alt")
            local replace = Hyperspace.Event:CreateEvent("REALM_MADNESS_START_LILY",
                Hyperspace.App.world.starMap.worldLevel, true);
            local req = Hyperspace.ChoiceReq()
            req.object = "LILY_PATRONAGE"
            req.min_level = 1
            req.max_level = 999
            req.max_group = 0
            req.blue = true
            --event:AddChoice(replace, "Continue...", req, false)

        end

        -- Vision
        if event.eventName == "VISION_ENCOUNTER" then
            event.text.data = mods.lilybeams.lilyVisionQuotes[math.random(#mods.lilybeams.lilyVisionQuotes)]

            local replace1 = Hyperspace.Event:CreateEvent("VISION_ENCOUNTER_LILY",
                Hyperspace.App.world.starMap.worldLevel, true);
            local req = Hyperspace.ChoiceReq()
            req.object = "LILY_PATRONAGE"
            req.min_level = 1
            req.max_level = 999
            req.max_group = 0
            req.blue = true
            --event:AddChoice(replace1, "Continue...", req, false)
            local Choices = event:GetChoices()
            for choice in vter(Choices) do
                choice.event = replace1
            end
        end

        -- Her
        if event.eventName == "HER_FIGHT" then
            event.text.data = Hyperspace.Text:GetText("lily_eventtext_hernofight")
            local replace2 = Hyperspace.Event:CreateEvent("HER_NOFIGHT_LILY",
                Hyperspace.App.world.starMap.worldLevel, true);
            local req = Hyperspace.ChoiceReq()
            req.object = "LILY_PATRONAGE"
            req.min_level = 1
            req.max_level = 999
            req.max_group = 0
            req.blue = true
            local Choices = event:GetChoices()
            for choice in vter(Choices) do
                choice.event = replace2
            end
            --event:AddChoice(replace, "Continue...", req, false)
        end
    end

    -- If player visited Lily but did NOT make a deal
    if (shipManager and shipManager:HasAugmentation("LILY_PATRONAGE") <= 0) and (Hyperspace.playerVariables.lily_backdoor > 0) then
        -- Prime gets sniped
        if event.eventName == "SHE_IS_DEFEATED" then
            event.text.data = Hyperspace.Text:GetText("lily_eventtext_lilysnipesprime")
            Hyperspace.Sounds:PlaySoundMix("focus_strong", -1, false)
            local replace3 = Hyperspace.Event:CreateEvent("SHE_IS_DEFEATED_NOT",
                Hyperspace.App.world.starMap.worldLevel, true);
            local Choices = event:GetChoices()
            for choice in vter(Choices) do
                choice.event = replace3
            end
        end

        -- Her
        if event.eventName == "HER_FIGHT" then
            event.text.data = event.text.data .. "\n\n" .. Hyperspace.Text:GetText("lily_eventtext_hernukewarning")
        end

        if event.eventName == "HER_SUPPORT" then
            local replace4 = Hyperspace.Event:CreateEvent("LILY_NUKE_INCOMING",
                Hyperspace.App.world.starMap.worldLevel, true);
            local Choices = event:GetChoices()
            for choice in vter(Choices) do
                choice.event = replace4
            end
        end


    end

end)

script.on_game_event("NEXUS_HER_REVEAL_FADE_LILY", false, function()
    screen_shake(3.7) --Here we shake the screen for 3.7 seconds, and start a fade to black that will mask the transition before fading out for one second. This is just long enough for the triggered event to happen, so we can easily tell that our effects are synchronized just by looking at the timer.
    screen_fade(Graphics.GL_Color(0, 0, 0, 1), 2, 1.7, 1)
end)

script.on_game_event("NEXUS_ENDING_NOTGOOD_FADE", false, function()
    screen_fade(Graphics.GL_Color(0.75, 0, 0, 1)) --Here we start a fade to red that will last 3 seconds, such that the transition at 2 seconds is masked
end)

script.on_game_event("LILY_NUKE_PORTAL_FADE", false, function()
    screen_shake(6)
    screen_fade(Graphics.GL_Color(1, 1, 1, 1), 1, 5, 1) --Here we shake the screen for 6 seconds, and start a fade to white that will mask the transition before fading out for one second.
end)

script.on_game_event("HER_NOFIGHT_LILY", false, function()
---@diagnostic disable-next-line: lowercase-global
    herVirus = true
---@diagnostic disable-next-line: lowercase-global
    titleSet = false
    Hyperspace.setWindowTitle(Hyperspace.Text:GetText("lily_text_multiverse_crp"))
end)


if not mods.lilybeams then
    mods.lilybeams = {}
end

local time_increment = mods.multiverse.time_increment

mods.lilybeams.startOk = false
mods.lilybeams.startTimer = 0

mods.lilybeams.checkVarsOK = function()
    return Hyperspace.playerVariables and Hyperspace.playerVariables["mods_lilybeams_init_check"] == 1
end

mods.lilybeams.checkStartOK = function()
    return mods.lilybeams.startOk
end

script.on_init(function(newGame)
    if newGame then
        Hyperspace.playerVariables["mods_lilybeams_init_check"] = 1
    end
    mods.lilybeams.startOk = false
    mods.lilybeams.startTimer = 0
end)

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    --print("ok", mods.lilybeams.checkStartOK())
    --print("t", mods.lilybeams.startTimer.currTime)
    if shipManager and shipManager.iShipId == 0 and mods.lilybeams.checkVarsOK() and mods.lilybeams.startOk == false then
        mods.lilybeams.startTimer = (mods.lilybeams.startTimer or 0) + time_increment()

        if mods.lilybeams.startTimer > 0.5 then
            mods.lilybeams.startOk = true
        end
    end
end)

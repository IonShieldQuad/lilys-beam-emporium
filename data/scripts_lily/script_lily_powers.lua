local vter = mods.multiverse.vter
local INT_MAX = 2147483647



LILY_POWER_BEAM_CURSOR = Hyperspace.Resources:CreateImagePrimitive(
Hyperspace.Resources:GetImageId("mouse/mouse_lily_beam.png"), 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
LILY_POWER_ION_CURSOR = Hyperspace.Resources:CreateImagePrimitive(
Hyperspace.Resources:GetImageId("mouse/mouse_lily_ion.png"), 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)

local function offset_point_direction(oldX, oldY, angle, distance)
    local newX = oldX + (distance * math.cos(math.rad(angle)))
    local newY = oldY + (distance * math.sin(math.rad(angle)))
    return Hyperspace.Pointf(newX, newY)
end

local function userdata_table(userdata, tableName)
    if not userdata.table[tableName] then userdata.table[tableName] = {} end
    return userdata.table[tableName]
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

local function get_distance(point1, point2)
    return math.sqrt(((point2.x - point1.x) ^ 2) + ((point2.y - point1.y) ^ 2))
end

-- Find ID of a room at the given location
local function get_room_at_location(shipManager, location, includeWalls)
    return Hyperspace.ShipGraph.GetShipInfo(shipManager.iShipId):GetSelectedRoom(location.x, location.y, includeWalls)
end

-- written by kokoro
local function convertMousePositionToEnemyShipPosition(mousePosition)
    local cApp = Hyperspace.Global.GetInstance():GetCApp()
    local combatControl = cApp.gui.combatControl
    local position = combatControl.position
    local targetPosition = combatControl.targetPosition
    local enemyShipOriginX = position.x + targetPosition.x
    local enemyShipOriginY = position.y + targetPosition.y
    return Hyperspace.Point(mousePosition.x - enemyShipOriginX, mousePosition.y - enemyShipOriginY)
end

local function convertMousePositionToPlayerShipPosition(mousePosition)
    local cApp = Hyperspace.Global.GetInstance():GetCApp()
    local combatControl = cApp.gui.combatControl
    local playerPosition = combatControl.playerShipPosition
    return Hyperspace.Point(mousePosition.x - playerPosition.x, mousePosition.y - playerPosition.y)
end


script.on_internal_event(Defines.InternalEvents.ACTIVATE_POWER,
    function(power, ship)
        --print(power.crew_ex:GetDefinition().race)
        --print(power.def.name)
        --print(power.def.cooldownColor)
        --print(power.def.cooldownColor.r)
        if (power.crew_ex:GetDefinition().race == "unique_lily_avatar") then
            --print("true")
            if power.def.cooldownColor.r > 0.5 then
                Hyperspace.playerVariables.lily_beam_active = 1
            else
                Hyperspace.playerVariables.lily_ion_active = 1
            end
        end
        
        return Defines.Chain.CONTINUE
    end)

script.on_internal_event(Defines.InternalEvents.POWER_ON_UPDATE,
    function(power)
        if (power.crew_ex:GetDefinition().race == "unique_lily_avatar") then
            --print("true")
            if power.def.cooldownColor.r > 0.5 then
            else
                --print(power.temporaryPowerActive)
                if not power.temporaryPowerActive and Hyperspace.playerVariables.lily_ion_active > 0 then
                    Hyperspace.Sounds:PlaySoundMix("temporalEnd", -1, false)
                end
                if not power.temporaryPowerActive then
                    Hyperspace.playerVariables.lily_ion_active = 0
                end
            end
        end
        return Defines.Chain.CONTINUE
    end)


local playerCursorRestore
local playerCursorRestoreInvalid

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    local commandGui = Hyperspace.App.gui

    if Hyperspace.App.menu.shipBuilder.bOpen or not Hyperspace.App.world.bStartedGame then
        Hyperspace.playerVariables.lily_beam_active = 0
        Hyperspace.playerVariables.lily_ion_active = 0
    end

    local count = (Hyperspace.playerVariables.lily_ion_active == 1 and 1 or 0) +
    (Hyperspace.playerVariables.lily_beam_active == 1 and 1 or 0)


    if count > 0 then
        local crewControl = Hyperspace.App.gui.crewControl
        crewControl.potentialSelectedCrew:clear()
        crewControl.selectedCrew:clear()

        if not playerCursorRestore then
            playerCursorRestore = Hyperspace.Mouse.validPointer
            playerCursorRestoreInvalid = Hyperspace.Mouse.invalidPointer
        end
        --Hyperspace.Mouse.validPointer = Hyperspace.Resources:GetImageId("effects_lily/invisible.png")
        --Hyperspace.Mouse.invalidPointer = Hyperspace.Resources:GetImageId("effects_lily/invisible.png")
        Hyperspace.Mouse.animateDoor = 0
    elseif playerCursorRestore then
        --Hyperspace.Mouse.validPointer = playerCursorRestore
        --Hyperspace.Mouse.invalidPointer = playerCursorRestoreInvalid
        playerCursorRestore = nil
        playerCursorRestoreInvalid = nil
            
    end


    if Hyperspace.playerVariables.lily_ion_active == 1 and not (commandGui.event_pause or commandGui.menu_pause) then

        if commandGui.bPaused then
            commandGui.bPaused = false
        end
    end
end)


script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_DOWN, function(x, y)
    local commandGui = Hyperspace.App.gui
    local powerActive = Hyperspace.playerVariables.lily_ion_active == 1 or Hyperspace.playerVariables.lily_beam_active == 1
    local count = (Hyperspace.playerVariables.lily_ion_active == 1 and 1 or 0) +
    (Hyperspace.playerVariables.lily_beam_active == 1 and 1 or 0)
    if powerActive and not (commandGui.bPaused or commandGui.event_pause or commandGui.menu_pause) then
        local mousePos = Hyperspace.Mouse.position
        local mousePosLocal = convertMousePositionToEnemyShipPosition(mousePos)
        local shipAtMouse = -1
        local roomAtMouse = -1
        --print("MOUSE POS X:"..mousePos.x.." Y:"..mousePos.y.." LOCAL X:"..mousePosLocal.x.." Y:"..mousePosLocal.y)
        if Hyperspace.ships.enemy and mousePosLocal.x >= 0 then
            shipAtMouse = 1
            roomAtMouse = get_room_at_location(Hyperspace.ships.enemy, mousePosLocal, true)
            --if roomAtMouse >= 0 then
            --print(roomAtMouse)
            --end
        else
            shipAtMouse = 0
            mousePosLocal = convertMousePositionToPlayerShipPosition(mousePos)
            roomAtMouse = get_room_at_location(Hyperspace.ships.player, mousePosLocal, true)
        end
        --print(shipAtMouse .. " " .. roomAtMouse)
        --print(Hyperspace.playerVariables.lily_beam_active == 1 .. " " .. Hyperspace.playerVariables.lily_ion_active == 1)
        --print("Count: " .. count)
        if shipAtMouse > -1 and roomAtMouse > -1 then
            local spaceManager = Hyperspace.App.world.space
            local target1 = Hyperspace.Pointf(mousePosLocal.x, mousePosLocal.y)
            local target2 = Hyperspace.Pointf(mousePosLocal.x, mousePosLocal.y + 1)
            --print("target_ok")

            if (Hyperspace.playerVariables.lily_ion_active == 1) then
                local start = get_random_point_on_radius(target1, 600)
                local beam = spaceManager:CreateBeam(
                    Hyperspace.Blueprints:GetWeaponBlueprint("LILY_POWER_ION"),
                    start,
                    shipAtMouse,
                    1 - shipAtMouse,
                    target1,
                    target2,
                    shipAtMouse,
                    1,
                    -0.1)
                Hyperspace.Sounds:PlaySoundMix("ionShoot1", -1, false)
            end

            if (Hyperspace.playerVariables.lily_beam_active == 1) then
                --print("beam_ok")
                --print(spaceManager)
                --print(spaceManager ~= nil)
                local start = get_random_point_on_radius(target1, 600)
                --offset_point_direction(mousePosLocal.x, mousePosLocal.y, math.random * 360, 600)
                --print(start.x .. " | " .. start.y)
                --print(target1.x .. " | " .. target1.x)
                --print("beam_ok2")
                local beam = spaceManager:CreateBeam(
                    Hyperspace.Blueprints:GetWeaponBlueprint("LILY_POWER_BEAM"),
                    start,
                    shipAtMouse,
                    1 - shipAtMouse,
                    target1,
                    target2,
                    shipAtMouse,
                    1,
                    -0.1)
                --print("beam_ok3")
                Hyperspace.Sounds:PlaySoundMix("focus_weak", -1, false)
                Hyperspace.playerVariables.lily_beam_active = 0
            end
        end

    end
    return Defines.Chain.CONTINUE
end)


script.on_render_event(Defines.RenderEvents.MOUSE_CONTROL, function()
    local commandGui = Hyperspace.App.gui
    local mousePos = Hyperspace.Mouse.position

    local count = (Hyperspace.playerVariables.lily_ion_active == 1 and 1 or 0) + (Hyperspace.playerVariables.lily_beam_active == 1 and 1 or 0)

    if count > 0 then
        Graphics.CSurface.GL_PushMatrix()
        Graphics.CSurface.GL_Translate(mousePos.x, mousePos.y, 0)
        Graphics.CSurface.GL_Translate(-5, -5, 0)
        if count == 2 then
            Graphics.CSurface.GL_Translate(-2, 2, 0)
            Graphics.CSurface.GL_RenderPrimitive(LILY_POWER_ION_CURSOR)
            Graphics.CSurface.GL_Translate(4, -4, 0)
            Graphics.CSurface.GL_RenderPrimitive(LILY_POWER_BEAM_CURSOR)
        else

            if Hyperspace.playerVariables.lily_ion_active == 1 then
                Graphics.CSurface.GL_Translate(-2, 2, 0)
                Graphics.CSurface.GL_RenderPrimitive(LILY_POWER_ION_CURSOR)
            else
                Graphics.CSurface.GL_Translate(2, -2, 0)
                Graphics.CSurface.GL_RenderPrimitive(LILY_POWER_BEAM_CURSOR)
            end

        end
        Graphics.CSurface.GL_PopMatrix()
    end

end, function() end)


script.on_internal_event(Defines.InternalEvents.SYSTEM_BOX_MOUSE_CLICK, function (systemBox, shift)
    --[[print("***************************************************************")
    print(Hyperspace.ShipSystem.SystemIdToName(systemBox.pSystem:GetId()), systemBox.pSystem._shipObj.iShipId)
    print("Mou", Hyperspace.Mouse.position.x, Hyperspace.Mouse.position.y)
    print("Sys", systemBox.location.x, systemBox.location.y)
    print("Diff1", systemBox.location:Distance(Hyperspace.Mouse.position))
    print("Diff2", systemBox.location:RelativeDistance(Hyperspace.Mouse.position))--]]
end, INT_MAX)
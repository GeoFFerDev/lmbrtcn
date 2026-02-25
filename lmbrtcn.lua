--[[
    LT2 Axe Dupe Script
    Game: Lumber Tycoon 2
    
    How it works:
      1. Saves your current slot (axe is in backpack → gets saved)
      2. Drops the axe on the ground
      3. Loads the save back (server re-creates the axe in your backpack)
      4. You now have the axe in backpack AND a copy on the ground
      5. Walk over the dropped copy to pick it up → two axes

    Requirements:
      - Must be holding / have the axe in your backpack
      - Must already have a save slot loaded (CurrentSaveSlot >= 1)
      - Run in a Roblox executor (Synapse X, KRNL, etc.)
]]

local Players       = game:GetService("Players")
local LocalPlayer   = Players.LocalPlayer
local RS            = game:GetService("ReplicatedStorage")
local LSR           = RS:WaitForChild("LoadSaveRequests")

local RequestSave   = LSR:WaitForChild("RequestSave")
local ClientMayLoad = LSR:WaitForChild("ClientMayLoad")
local RequestLoad   = LSR:WaitForChild("RequestLoad")
local SendNotice    = RS.Notices.SendUserNotice

-- Helper: fire the in-game notice banner
local function notify(msg)
    pcall(function() SendNotice:Fire(msg, 2) end)
    print("[AxeDupe] " .. msg)
end

-- Find the axe tool in the local backpack
local function findAxe()
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("ToolName") then
            return tool
        end
    end
    -- Also check character (equipped)
    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("ToolName") then
                return tool
            end
        end
    end
    return nil
end

-- Get the current save slot number from the player
local function getCurrentSlot()
    local slotVal = LocalPlayer:FindFirstChild("CurrentSaveSlot")
    if slotVal then
        return slotVal.Value
    end
    return nil
end

-- Main dupe function
local function dupeAxe()
    -- Step 1: Validate
    local axe = findAxe()
    if not axe then
        notify("ERROR: No axe found in backpack!")
        return
    end

    local slot = getCurrentSlot()
    if not slot or slot <= 0 then
        notify("ERROR: No active save slot found. Load a slot first.")
        return
    end

    notify("Axe found: " .. axe.Name .. " | Slot: " .. slot)
    task.wait(0.5)

    -- Step 2: Save current state (axe is in backpack, gets saved)
    notify("Saving slot " .. slot .. "...")
    local saveOk, saveErr = RequestSave:InvokeServer(slot, LocalPlayer)
    if not saveOk then
        notify("ERROR: Save failed - " .. tostring(saveErr))
        return
    end
    notify("Save successful!")
    task.wait(0.5)

    -- Step 3: Drop the axe
    -- If axe is equipped (in character), unequip first
    local char = LocalPlayer.Character
    if char and char:FindFirstChild(axe.Name) then
        notify("Unequipping axe...")
        -- Fire humanoid unequip
        LocalPlayer.Character.Humanoid:UnequipTools()
        task.wait(0.3)
    end

    -- Drop via MoveToBackpack and then drop
    notify("Dropping axe...")
    -- The standard drop method: move the tool to workspace
    axe.Parent = workspace
    -- Position it near the player's character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        axe:MoveTo(hrp.Position + hrp.CFrame.LookVector * 5)
    end
    task.wait(0.5)

    -- Step 4: Check if server allows load
    local mayLoad, mayErr = ClientMayLoad:InvokeServer(LocalPlayer)
    if not mayLoad then
        notify("ERROR: Cannot load - " .. tostring(mayErr))
        -- Try to recover: pick axe back up
        axe.Parent = LocalPlayer.Backpack
        return
    end

    -- Step 5: Load the save (server re-gives the axe)
    notify("Loading save to re-create axe...")
    local loadOk, loadErr = RequestLoad:InvokeServer(slot, LocalPlayer, nil)
    if loadOk then
        notify("SUCCESS! Dupe complete. Walk over the dropped axe to pick it up.")
    else
        if loadErr ~= "No property found" then
            notify("Load returned: " .. tostring(loadErr))
        else
            notify("Load triggered. Check your backpack and the ground!")
        end
    end
end

-- Run it
notify("LT2 Axe Dupe starting...")
task.wait(1)
dupeAxe()

-- ZEN | Item Hunter | Toggle O/P | Looping | Closest Target

local Players = game:GetService("Players")
local VirtualInput = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local STAGING_POS = Vector3.new(794, 127, 7)
local RETURN_POS = Vector3.new(784, 127, -2107)
local HOLD_E_DURATION = 2
local MIN_Y = 100

local targetNames = {"tuff toucan", "swaggy bros", "job job job sahur"}

local running = false

-- Press number 1 key
local function pressOne()
    pcall(function()
        VirtualInput:SendKeyEvent(true, Enum.KeyCode.One, false, game)
        task.wait(0.05)
        VirtualInput:SendKeyEvent(false, Enum.KeyCode.One, false, game)
        print("ZEN | Pressed 1")
    end)
end

-- 1 key thread
local oneThread = nil
local oneActive = false

local function startOneSpam()
    if oneActive then return end
    oneActive = true
    oneThread = task.spawn(function()
        print("ZEN | 1 key spam started (every 1.5s)")
        while oneActive do
            pressOne()
            task.wait(1.5)
        end
    end)
end

local function stopOneSpam()
    oneActive = false
    if oneThread then
        task.cancel(oneThread)
        oneThread = nil
    end
    print("ZEN | 1 key spam stopped")
end

-- Get ground level
local function getGroundLevel(pos)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {Character}
    
    local rayOrigin = Vector3.new(pos.X, pos.Y + 100, pos.Z)
    local rayDirection = Vector3.new(0, -250, 0)
    
    local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    if rayResult then
        return rayResult.Position.Y + 3
    end
    
    return pos.Y
end

-- Find CLOSEST target item on ground
local function findClosestGroundTarget()
    local allDescendants = workspace:GetDescendants()
    local currentPos = HumanoidRootPart.Position
    local closestPos = nil
    local closestDist = math.huge
    local closestItem = nil
    
    for _, item in ipairs(allDescendants) do
        local nameLower = string.lower(item.Name or "")
        
        for _, target in ipairs(targetNames) do
            if string.find(nameLower, target) then
                local pos = nil
                
                if item:IsA("BasePart") then
                    pos = item.Position
                elseif item:FindFirstChildWhichIsA("BasePart") then
                    pos = item:FindFirstChildWhichIsA("BasePart").Position
                elseif item:IsA("Model") and item.PrimaryPart then
                    pos = item.PrimaryPart.Position
                end
                
                if pos then
                    -- Skip underground items
                    if pos.Y < MIN_Y then
                        break
                    end
                    
                    local groundY = getGroundLevel(pos)
                    local groundPos = Vector3.new(pos.X, groundY, pos.Z)
                    local dist = (groundPos - currentPos).Magnitude
                    
                    if dist < closestDist then
                        closestDist = dist
                        closestPos = groundPos
                        closestItem = item
                    end
                    break
                end
            end
        end
    end
    
    if closestPos then
        print("ZEN | Found closest target:", closestItem.Name, "distance:", math.floor(closestDist), "at", closestPos)
        return closestPos, closestItem
    end
    
    return nil, nil
end

local function teleport(pos)
    pcall(function()
        HumanoidRootPart.CFrame = CFrame.new(pos)
        task.wait(0.1)
    end)
end

local function holdE()
    pcall(function()
        VirtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(HOLD_E_DURATION)
        VirtualInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

-- Main loop
local function mainLoop()
    while running do
        print("ZEN | Cycle starting...")
        
        teleport(STAGING_POS)
        task.wait(0.5)
        
        task.wait(1)
        
        print("ZEN | Searching for closest target...")
        local targetPos, targetItem = findClosestGroundTarget()
        
        if not targetPos then
            print("ZEN | No target found, returning...")
            teleport(RETURN_POS)
            task.wait(1)
        else
            print("ZEN | Teleporting to closest target...")
            teleport(targetPos + Vector3.new(0, 2, 0))
            task.wait(0.3)
            
            print("ZEN | Holding E...")
            holdE()
            task.wait(0.3)
            
            print("ZEN | Returning...")
            teleport(RETURN_POS)
        end
        
        print("ZEN | Cycle complete. Looping...")
        task.wait(0.5)
    end
end

-- Toggle functions
local function start()
    if running then
        print("ZEN | Already running")
        return
    end
    running = true
    startOneSpam()
    print("ZEN | Started! Press P to stop")
    task.spawn(mainLoop)
end

local function stop()
    if not running then
        print("ZEN | Not running")
        return
    end
    running = false
    stopOneSpam()
    print("ZEN | Stopped! Press O to start again")
end

-- Keybinds
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.K then
        start()
    elseif input.KeyCode == Enum.KeyCode.L then
        stop()
    end
end)

print("========================================")
print("ZEN | Item Hunter - Closest Target")
print("Press O to START (looping + 1 key every 1.5s)")
print("Press P to STOP")
print("Targets: tuff toucan, swaggy bros, job job job sahur")
print("========================================")

-- Rayfield Loader
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
if not Rayfield then
    print("Failed to load Rayfield library")
    return
end
print("Rayfield loaded successfully")

-- Create Rayfield Window
local Window = Rayfield:CreateWindow({
    Name = "Phanclon ware- MM2",
    LoadingTitle = "Phanclone ware",
    LoadingSubtitle = "by phantom and clon",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "PhanclonConfig",
        FileName = "MM2Config"
    },
    KeySystem = false
})
Rayfield:SetVisibility(true) -- Force UI visible

-- Create Tabs
local MainTab = Window:CreateTab("Main", 4483362458) -- Home icon
local VisualsTab = Window:CreateTab("Visuals", 4483362458) -- Eye icon
local MiscTab = Window:CreateTab("Misc", 4483362458) -- Flame icon
print("Tabs created")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

-- Aimbot and Silent Aim Settings
local AIMBOT_ENABLED = false
local SILENTAIM_ENABLED = false
local TEAM_CHECK = false
local WALL_CHECK = false
local SMOOTHNESS_ENABLED = true
local FOV_RADIUS = 90
local SMOOTHNESS = 0.1
local LOCK_PART = "Head"
local DRAW_FOV = false
local HitChance = 100

-- Create FOV Circle
local success, FOVCircle = pcall(Drawing.new, "Circle")
if success then
    FOVCircle.Radius = FOV_RADIUS
    FOVCircle.Thickness = 2
    FOVCircle.Color = Color3.fromRGB(255, 0, 0)
    FOVCircle.Filled = false
    FOVCircle.Visible = false
else
    print("Drawing library not supported by executor")
end

-- Update FOV Circle Position
RunService.RenderStepped:Connect(function()
    if FOVCircle then
        local screenCenter = Camera.ViewportSize / 2
        FOVCircle.Position = Vector2.new(screenCenter.X, screenCenter.Y)
        FOVCircle.Visible = DRAW_FOV
    end
end)

-- Function to Check if Target is Valid
local function IsValidTarget(player)
    if not player or not player.Character then return false end
    if TEAM_CHECK and player.Team == LocalPlayer.Team then return false end
    if WALL_CHECK then
        local head = player.Character:FindFirstChild(LOCK_PART)
        if head then
            local origin = Camera.CFrame.Position
            local ray = Ray.new(origin, (head.Position - origin).Unit * (head.Position - origin).Magnitude)
            local hitPart = workspace:FindPartOnRay(ray, LocalPlayer.Character, true)
            return hitPart == head
        end
        return false
    end
    return true
end

-- Function to Find Closest Player
local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = FOV_RADIUS
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(LOCK_PART) and IsValidTarget(player) then
            local head = player.Character:FindFirstChild(LOCK_PART)
            local headScreenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local distance = (Vector2.new(headScreenPos.X, headScreenPos.Y) - screenCenter).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

-- Aimbot Logic
RunService.RenderStepped:Connect(function()
    if AIMBOT_ENABLED and LocalPlayer.Character then
        local target = GetClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild(LOCK_PART) then
            local head = target.Character:FindFirstChild(LOCK_PART)
            local currentCameraCFrame = Camera.CFrame
            local targetCameraCFrame = CFrame.new(currentCameraCFrame.Position, head.Position)
            if SMOOTHNESS_ENABLED then
                Camera.CFrame = currentCameraCFrame:Lerp(targetCameraCFrame, SMOOTHNESS)
            else
                Camera.CFrame = targetCameraCFrame
            end
        end
    end
end)

-- Silent Aim Logic
local lockedplayer
local highlight = Instance.new("Highlight")
highlight.FillColor = Color3.fromRGB(255, 0, 0)
highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
highlight.OutlineTransparency = 0.5
highlight.FillTransparency = 0.3

local function closestPlayer()
    local closest, closestDistance
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetpart = player.Character.HumanoidRootPart
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetpart.Position)
            local mousePos = Vector2.new(LocalPlayer:GetMouse().X, LocalPlayer:GetMouse().Y)
            local distance = (mousePos - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
            if onScreen and (not closest or distance < closestDistance) then
                closest = player
                closestDistance = distance
            end
        end
    end
    return closest
end

local function updateLock()
    if SILENTAIM_ENABLED then
        lockedplayer = closestPlayer()
        if lockedplayer and lockedplayer.Character then
            highlight.Parent = lockedplayer.Character
        end
    else
        highlight.Parent = nil
        lockedplayer = nil
    end
end

if hookmetamethod then
    LPH_NO_VIRTUALIZE(function()
        local originalmethod
        originalmethod = hookmetamethod(game, "__index", function(self, key)
            if not checkcaller() and self:IsA("Mouse") and key == "Hit" then
                if SILENTAIM_ENABLED and lockedplayer and lockedplayer.Character and lockedplayer.Character:FindFirstChild("HumanoidRootPart") then
                    if math.random(1, 100) <= HitChance then
                        return lockedplayer.Character.HumanoidRootPart.CFrame
                    end
                end
            end
            return originalmethod(self, key)
        end)
    end)()
else
    print("hookmetamethod not supported by executor. Silent Aim disabled")
    SILENTAIM_ENABLED = false
end
RunService.RenderStepped:Connect(updateLock)

-- Main Tab: Player Movement and Aimbot/Silent Aim
print("Creating MainTab elements")
MainTab:CreateSection("Player Movement")

local WalkspeedSlider = MainTab:CreateSlider({
    Name = "Walkspeed",
    Range = {16, 100},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "Walkspeed",
    Callback = function(Value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = Value
        end
        print("Walkspeed set to:", Value)
    end,
})
print("Element added: Walkspeed Slider")

local JumpPowerSlider = MainTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 200},
    Increment = 1,
    Suffix = "Power",
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(Value)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = Value
        end
        print("Jump Power set to:", Value)
    end,
})
print("Element added: Jump Power Slider")

local GravitySlider = MainTab:CreateSlider({
    Name = "Gravity",
    Range = {0, 300},
    Increment = 1,
    Suffix = "Gravity",
    CurrentValue = workspace.Gravity,
    Flag = "Gravity",
    Callback = function(Value)
        workspace.Gravity = Value
        print("Gravity set to:", Value)
    end,
})
print("Element added: Gravity Slider")

local FOVSlider = MainTab:CreateSlider({
    Name = "Field of View",
    Range = {20, 120},
    Increment = 1,
    Suffix = "FOV",
    CurrentValue = Camera.FieldOfView,
    Flag = "FOV",
    Callback = function(Value)
        Camera.FieldOfView = Value
        print("FOV set to:", Value)
    end,
})
print("Element added: FOV Slider")

local InfJumpToggle = MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(Value)
        local InfJumpConnection
        if Value then
            InfJumpConnection = UserInputService.JumpRequest:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            if InfJumpConnection then
                InfJumpConnection:Disconnect()
            end
        end
        print("Infinite Jump toggled:", Value)
    end,
})
print("Element added: Infinite Jump Toggle")

local NoclipToggle = MainTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(Value)
        local NoclipConnection
        if Value then
            NoclipConnection = RunService.Stepped:Connect(function()
                if LocalPlayer.Character then
                    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            if NoclipConnection then
                NoclipConnection:Disconnect()
            end
        end
        print("Noclip toggled:", Value)
    end,
})
print("Element added: Noclip Toggle")

local FlyToggle = MainTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(Value)
        local FlyBodyVelocity, FlyBodyGyro, FlyConnection
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if Value then
            FlyBodyVelocity = Instance.new("BodyVelocity")
            FlyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            FlyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            FlyBodyVelocity.Parent = hrp
            FlyBodyGyro = Instance.new("BodyGyro")
            FlyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            FlyBodyGyro.CFrame = hrp.CFrame
            FlyBodyGyro.Parent = hrp
            FlyConnection = RunService.RenderStepped:Connect(function()
                local direction = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    direction = direction + Camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    direction = direction - Camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    direction = direction - Camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    direction = direction + Camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                    direction = direction + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                    direction = direction - Vector3.new(0, 1, 0)
                end
                FlyBodyVelocity.Velocity = direction * (FlySpeedSlider and FlySpeedSlider.CurrentValue or 50)
                if direction.Magnitude > 0 then
                    FlyBodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + direction)
                else
                    FlyBodyGyro.CFrame = hrp.CFrame
                end
            end)
        else
            if FlyConnection then FlyConnection:Disconnect() end
            if FlyBodyVelocity then FlyBodyVelocity:Destroy() end
            if FlyBodyGyro then FlyBodyGyro:Destroy() end
        end
        print("Fly toggled:", Value)
    end,
})
print("Element added: Fly Toggle")

local FlySpeedSlider = MainTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(Value)
        print("Fly Speed set to:", Value)
    end,
})
print("Element added: Fly Speed Slider")

local ResetPlayerButton = MainTab:CreateButton({
    Name = "Reset Player",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = 50
        end
        print("Reset Player button clicked")
    end,
})
print("Element added: Reset Player Button")

MainTab:CreateSection("Aimbot and Silent Aim")

local SilentAimToggle = MainTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Flag = "SilentAimToggle",
    Callback = function(Value)
        SILENTAIM_ENABLED = Value
        print("Silent Aim toggled:", Value)
    end,
})
print("Element added: Silent Aim Toggle")

local HitChanceSlider = MainTab:CreateSlider({
    Name = "Hit Chance",
    Range = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 100,
    Flag = "HitChanceSlider",
    Callback = function(Value)
        HitChance = Value
        print("Hit Chance set to:", Value)
    end,
})
print("Element added: Hit Chance Slider")

local AimbotToggle = MainTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(Value)
        AIMBOT_ENABLED = Value
        print("Aimbot toggled:", Value)
    end,
})
print("Element added: Aimbot Toggle")

local TeamCheckToggle = MainTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "TeamCheckToggle",
    Callback = function(Value)
        TEAM_CHECK = Value
        print("Team Check toggled:", Value)
    end,
})
print("Element added: Team Check Toggle")

local WallCheckToggle = MainTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Flag = "WallCheckToggle",
    Callback = function(Value)
        WALL_CHECK = Value
        print("Wall Check toggled:", Value)
    end,
})
print("Element added: Wall Check Toggle")

local SmoothnessToggle = MainTab:CreateToggle({
    Name = "Smoothness",
    CurrentValue = true,
    Flag = "SmoothnessToggle",
    Callback = function(Value)
        SMOOTHNESS_ENABLED = Value
        print("Smoothness toggled:", Value)
    end,
})
print("Element added: Smoothness Toggle")

local DrawFOVToggle = MainTab:CreateToggle({
    Name = "Draw FOV",
    CurrentValue = false,
    Flag = "FOVToggle",
    Callback = function(Value)
        DRAW_FOV = Value
        print("Draw FOV toggled:", Value)
    end,
})
print("Element added: Draw FOV Toggle")

local FOVRadiusInput = MainTab:CreateInput({
    Name = "FOV Radius",
    PlaceholderText = "Enter FOV Radius",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        FOV_RADIUS = tonumber(Text) or FOV_RADIUS
        if FOVCircle then FOVCircle.Radius = FOV_RADIUS end
        print("FOV Radius set to:", FOV_RADIUS)
    end,
})
print("Element added: FOV Radius Input")

local SmoothnessInput = MainTab:CreateInput({
    Name = "Smoothness",
    PlaceholderText = "Enter Smoothness Value",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        SMOOTHNESS = tonumber(Text) or SMOOTHNESS
        print("Smoothness set to:", SMOOTHNESS)
    end,
})
print("Element added: Smoothness Input")

local TargetPartDropdown = MainTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "Torso"},
    CurrentOption = {"Head"},
    Flag = "TargetPartDropdown",
    Callback = function(Options)
        LOCK_PART = Options[1] or "Head"
        print("Target Part set to:", LOCK_PART)
    end,
})
print("Element added: Target Part Dropdown")

MainTab:CreateSection("Murderer and Sheriff Functions")

local function findRoles()
    local murdererName, sheriffName
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        local function hasTool(toolName)
            if player:FindFirstChild("Backpack") then
                for _, tool in ipairs(player.Backpack:GetChildren()) do
                    if tool:IsA("Tool") and tool.Name == toolName then
                        return true
                    end
                end
            end
            for _, item in ipairs(player.Character:GetChildren()) do
                if item:IsA("Tool") and item.Name == toolName then
                    return true
                end
            end
            return false
        end
        if hasTool("Knife") then
            murdererName = player.Name
        elseif hasTool("Gun") then
            sheriffName = player.Name
        end
    end
    return murdererName, sheriffName
end

local RevealRolesButton = MainTab:CreateButton({
    Name = "Reveal Roles",
    Callback = function()
        local murderer, sheriff = findRoles()
        if murderer and sheriff then
            local message = string.format("%s is the Murderer, and %s is the Sheriff!", murderer, sheriff)
            TextChatService.TextChannels.RBXGeneral:SendAsync(message)
        end
        print("Reveal Roles button clicked")
    end,
})
print("Element added: Reveal Roles Button")

-- Visuals Tab: ESP
print("Creating VisualsTab elements")
VisualsTab:CreateSection("ESP")

local espEnabled = false
local checkingThread = nil
local murdererESPToggle = VisualsTab:CreateToggle({
    Name = "All ESP",
    CurrentValue = false,
    Flag = "MurdererESP",
    Callback = function(Value)
        espEnabled = Value
        if Value then
            UpdateHighlights()
        end
        print("All ESP toggled:", Value)
    end,
})
print("Element added: All ESP Toggle")

local function CreateHighlight()
    for _, player in pairs(Players:GetChildren()) do
        if player ~= LocalPlayer and player.Character and not player.Character:FindFirstChild("PlayerHighlight") then
            local hl = Instance.new("Highlight", player.Character)
            hl.Name = "PlayerHighlight"
            hl.FillColor = Color3.fromRGB(0, 225, 0)
            hl.OutlineTransparency = 0.5
            hl.FillTransparency = 0.3
        end
    end
end

local function UpdateHighlights()
    local roles = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    local Murder, Sheriff, Hero
    for i, v in pairs(roles) do
        if v.Role == "Murderer" then Murder = i
        elseif v.Role == "Sheriff" then Sheriff = i
        elseif v.Role == "Hero" then Hero = i
        end
    end
    for _, player in pairs(Players:GetChildren()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("PlayerHighlight") then
            local Highlight = player.Character:FindFirstChild("PlayerHighlight")
            local function IsAlive(Player)
                for i, v in pairs(roles) do
                    if Player.Name == i then
                        return not v.Killed and not v.Dead
                    end
                end
                return false
            end
            if player.Name == Murder and IsAlive(player) and murdererESPToggle and murdererESPToggle.CurrentValue then
                Highlight.FillColor = Color3.fromRGB(225, 0, 0)
            elseif player.Name == Sheriff and IsAlive(player) then
                Highlight.FillColor = Color3.fromRGB(0, 0, 225)
            elseif player.Name == Hero and IsAlive(player) and (not Sheriff or not IsAlive(Players[Sheriff])) then
                Highlight.FillColor = Color3.fromRGB(255, 250, 0)
            else
                Highlight.FillColor = Color3.fromRGB(0, 225, 0)
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    if espEnabled then
        CreateHighlight()
        UpdateHighlights()
    end
end)

local gunEspEnabled = false
local function toggleGunESP(enabled)
    local normal = workspace:FindFirstChild("Normal")
    if normal then
        for _, gunDrop in ipairs(normal:GetChildren()) do
            if gunDrop.Name == "GunDrop" then
                local highlight = gunDrop:FindFirstChild("GunHighlight")
                if enabled and not highlight then
                    local hl = Instance.new("Highlight", gunDrop)
                    hl.Name = "GunHighlight"
                    hl.FillColor = Color3.fromRGB(7, 0, 255)
                    hl.OutlineTransparency = 0.75
                    hl.FillTransparency = 0.3
                elseif not enabled and highlight then
                    highlight:Destroy()
                end
            end
        end
    end
end

local function checkForNewGunDrops()
    while gunEspEnabled do
        local normal = workspace:FindFirstChild("Normal")
        if normal then
            for _, gunDrop in ipairs(normal:GetChildren()) do
                if gunDrop.Name == "GunDrop" and not gunDrop:FindFirstChild("GunHighlight") then
                    local hl = Instance.new("Highlight", gunDrop)
                    hl.Name = "GunHighlight"
                    hl.FillColor = Color3.fromRGB(7, 0, 255)
                    hl.OutlineTransparency = 0.75
                    hl.FillTransparency = 0.3
                end
            end
        end
        task.wait(0.5)
    end
end

local GunESPToggle = VisualsTab:CreateToggle({
    Name = "Gun ESP",
    CurrentValue = false,
    Flag = "GunESP",
    Callback = function(Value)
        gunEspEnabled = Value
        toggleGunESP(Value)
        if Value then
            if checkingThread then task.cancel(checkingThread) end
            checkingThread = task.spawn(checkForNewGunDrops)
        else
            if checkingThread then
                task.cancel(checkingThread)
                checkingThread = nil
            end
            toggleGunESP(false)
        end
        print("Gun ESP toggled:", Value)
    end,
})
print("Element added: Gun ESP Toggle")

workspace.ChildAdded:Connect(function(child)
    if child.Name == "Normal" and gunEspEnabled then
        toggleGunESP(true)
    end
end)

-- Misc Tab: Player Utilities and Autofarm
print("Creating MiscTab elements")
MiscTab:CreateSection("Player Utilities")

local selectedPlayer = nil
local viewPlayerToggle = false
local massTeleportToggle = false
local orbitToggle = false
local orbitSpeed = 1
local orbitDistance = 10

local function getPlayers()
    local playerNames = {}
    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(playerNames, player.Name)
    end
    return playerNames
end

local PlayerDropdown = MiscTab:CreateDropdown({
    Name = "Select Player",
    Options = getPlayers(),
    CurrentOption = getPlayers()[1] and {getPlayers()[1]} or {"None"},
    Flag = "PlayerDropdown",
    Callback = function(Options)
        selectedPlayer = Options[1] or "None"
        print("Player selected:", selectedPlayer)
    end,
})
print("Element added: Select Player Dropdown")

Players.PlayerAdded:Connect(function()
    PlayerDropdown:Refresh(getPlayers())
    print("Player list refreshed (PlayerAdded)")
end)

Players.PlayerRemoving:Connect(function()
    PlayerDropdown:Refresh(getPlayers())
    print("Player list refreshed (PlayerRemoving)")
end)

local ViewPlayerToggle = MiscTab:CreateToggle({
    Name = "View Player",
    CurrentValue = false,
    Flag = "ToggleViewPlayer",
    Callback = function(Value)
        viewPlayerToggle = Value
        if viewPlayerToggle and selectedPlayer and selectedPlayer ~= "None" then
            local target = Players:FindFirstChild(selectedPlayer)
            if target and target.Character and target.Character:FindFirstChild("Humanoid") then
                Camera.CameraSubject = target.Character.Humanoid
            else
                Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") or Camera
            end
        else
            Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") or Camera
        end
        print("View Player toggled:", Value)
    end,
})
print("Element added: View Player Toggle")

local TeleportToPlayerButton = MiscTab:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        if selectedPlayer and selectedPlayer ~= "None" then
            local target = Players:FindFirstChild(selectedPlayer)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
            end
        end
        print("Teleport to Player button clicked")
    end,
})
print("Element added: Teleport to Player Button")

local BringPlayerButton = MiscTab:CreateButton({
    Name = "Bring Player (Client-Sided)",
    Callback = function()
        if selectedPlayer and selectedPlayer ~= "None" then
            local target = Players:FindFirstChild(selectedPlayer)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                target.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
            end
        end
        print("Bring Player button clicked")
    end,
})
print("Element added: Bring Player Button")

local MassTeleportToggle = MiscTab:CreateToggle({
    Name = "Mass Teleport",
    CurrentValue = false,
    Flag = "MassTeleport",
    Callback = function(Value)
        massTeleportToggle = Value
        local massTeleportLoop
        if massTeleportToggle and selectedPlayer and selectedPlayer ~= "None" then
            massTeleportLoop = RunService.Stepped:Connect(function()
                local target = Players:FindFirstChild(selectedPlayer)
                if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
                end
            end)
        else
            if massTeleportLoop then massTeleportLoop:Disconnect() end
        end
        print("Mass Teleport toggled:", Value)
    end,
})
print("Element added: Mass Teleport Toggle")

local RemovePlayerButton = MiscTab:CreateButton({
    Name = "Remove Player (Client-Sided)",
    Callback = function()
        if selectedPlayer and selectedPlayer ~= "None" then
            local target = Players:FindFirstChild(selectedPlayer)
            if target then
                target:Destroy()
            end
        end
        print("Remove Player button clicked")
    end,
})
print("Element added: Remove Player Button")

local OrbitToggle = MiscTab:CreateToggle({
    Name = "Orbit Around Player",
    CurrentValue = false,
    Flag = "ToggleOrbit",
    Callback = function(Value)
        orbitToggle = Value
        if orbitToggle and selectedPlayer and selectedPlayer ~= "None" then
            local target = Players:FindFirstChild(selectedPlayer)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local orbitConnection = RunService.Heartbeat:Connect(function()
                    if orbitToggle and target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                        local targetPos = target.Character.HumanoidRootPart.Position
                        local newPos = targetPos + Vector3.new(math.sin(tick() * orbitSpeed) * orbitDistance, 0, math.cos(tick() * orbitSpeed) * orbitDistance)
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(newPos)
                    end
                end)
                if not Value then orbitConnection:Disconnect() end
            end
        end
        print("Orbit toggled:", Value)
    end,
})
print("Element added: Orbit Toggle")

local OrbitSpeedInput = MiscTab:CreateInput({
    Name = "Orbit Speed",
    PlaceholderText = "Enter Speed",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        orbitSpeed = tonumber(Text) or 1
        print("Orbit Speed set to:", orbitSpeed)
    end,
})
print("Element added: Orbit Speed Input")

local OrbitDistanceInput = MiscTab:CreateInput({
    Name = "Orbit Distance",
    PlaceholderText = "Enter Distance",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        orbitDistance = tonumber(Text) or 10
        print("Orbit Distance set to:", orbitDistance)
    end,
})
print("Element added: Orbit Distance Input")

MiscTab:CreateSection("Autofarm")

local autoFarmToggle = false
local farmDelay = 2
local lastCoin = nil
local autoFarmLoop = nil
local teleportMode = "Teleport to coin"
local teleportOffset = 8

local function getCoins()
    local coins = {}
    for _, container in ipairs(workspace:GetDescendants()) do
        if container:IsA("Model") and container.Name == "CoinContainer" then
            for _, coinServer in ipairs(container:GetChildren()) do
                if coinServer.Name == "Coin_Server" then
                    local coinVisual = coinServer:FindFirstChild("CoinVisual")
                    if coinVisual then
                        local mainCoin = coinVisual:FindFirstChild("MainCoin")
                        if mainCoin and mainCoin:IsA("MeshPart") then
                            table.insert(coins, mainCoin)
                        end
                    end
                end
            end
        end
    end
    return coins
end

local function freezeCharacter(freeze)
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character.Humanoid
        if freeze then
            humanoid.PlatformStand = true
            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        else
            humanoid.PlatformStand = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end

local function teleportToCoin()
    local coins = getCoins()
    if #coins > 0 then
        local randomIndex = math.random(1, #coins)
        local targetCoin = coins[randomIndex]
        if targetCoin == lastCoin then
            randomIndex = (randomIndex % #coins) + 1
            targetCoin = coins[randomIndex]
        end
        lastCoin = targetCoin
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = LocalPlayer.Character.HumanoidRootPart
            if teleportMode == "Teleport above" then
                rootPart.CFrame = targetCoin.CFrame + Vector3.new(0, teleportOffset, 0)
            elseif teleportMode == "Teleport under" then
                rootPart.CFrame = targetCoin.CFrame - Vector3.new(0, teleportOffset, 0)
            else
                rootPart.CFrame = targetCoin.CFrame + Vector3.new(0, 3, 0)
            end
        end
        freezeCharacter(true)
        task.wait(farmDelay)
        freezeCharacter(false)
    end
end

local AutoFarmToggle = MiscTab:CreateToggle({
    Name = "AutoFarm Coins",
    CurrentValue = false,
    Flag = "AutoFarmToggle",
    Callback = function(Value)
        autoFarmToggle = Value
        if autoFarmToggle then
            autoFarmLoop = task.spawn(function()
                while autoFarmToggle do
                    teleportToCoin()
                    task.wait(farmDelay)
                end
            end)
        else
            if autoFarmLoop then task.cancel(autoFarmLoop) end
        end
        print("AutoFarm toggled:", Value)
    end,
})
print("Element added: AutoFarm Toggle")

local TeleportModeDropdown = MiscTab:CreateDropdown({
    Name = "Teleport Mode",
    Options = {"Teleport above", "Teleport to coin", "Teleport under"},
    CurrentOption = {"Teleport to coin"},
    Flag = "TeleportModeDropdown",
    Callback = function(Options)
        teleportMode = Options[1] or "Teleport to coin"
        print("Teleport Mode set to:", teleportMode)
    end,
})
print("Element added: Teleport Mode Dropdown")

local TeleportOffsetSlider = MiscTab:CreateSlider({
    Name = "Teleport Offset",
    Range = {1, 20},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 8,
    Flag = "TeleportOffsetSlider",
    Callback = function(Value)
        teleportOffset = Value
        print("Teleport Offset set to:", Value)
    end,
})
print("Element added: Teleport Offset Slider")

local AutoFarmDelaySlider = MiscTab:CreateSlider({
    Name = "AutoFarm Delay",
    Range = {0, 5},
    Increment = 0.1,
    Suffix = "Seconds",
    CurrentValue = 2,
    Flag = "AutoFarmDelay",
    Callback = function(Value)
        farmDelay = Value
        print("AutoFarm Delay set to:", Value)
    end,
})
print("Element added: AutoFarm Delay Slider")

MiscTab:CreateParagraph({
    Title = "Kicked",
    Content = "If you had been kicked from the experience, rejoin and stay inside the game for about 2 mins and then activate the autofarm."
})
print("Element added: Kicked Paragraph")

MiscTab:CreateParagraph({
    Title = "To Avoid Detection",
    Content = "Set the autofarm delay larger than 0.9"
})
print("Element added: Avoid Detection Paragraph")

MiscTab:CreateSection("Server Utilities")

local RejoinButton = MiscTab:CreateButton({
    Name = "Rejoin",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
        print("Rejoin button clicked")
    end,
})
print("Element added: Rejoin Button")

local ServerhopButton = MiscTab:CreateButton({
    Name = "Serverhop",
    Callback = function()
        local req = syn and syn.request or http_request or request
        if not req then
            print("Serverhop failed: no HTTP request function")
            return
        end
        local response = req({ Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100", Method = "GET" })
        if response and response.Body then
            local data = HttpService:JSONDecode(response.Body)
            local servers = {}
            for _, v in ipairs(data.data) do
                if v.playing < v.maxPlayers then
                    table.insert(servers, v.id)
                end
            end
            if #servers > 0 then
                local randomServer = servers[math.random(1, #servers)]
                TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, LocalPlayer)
            end
        end
        print("Serverhop button clicked")
    end,
})
print("Element added: Serverhop Button")

MiscTab:CreateParagraph({
    Title = "Executor Type",
    Content = "Executor: " .. (identifyexecutor and identifyexecutor() or "Unknown")
})
print("Element added: Executor Type Paragraph")

local SetFPSCapButton = MiscTab:CreateButton({
    Name = "Set FPS Cap",
    Callback = function()
        if setfpscap then
            setfpscap(999)
        end
        print("Set FPS Cap button clicked")
    end,
})
print("Element added: Set FPS Cap Button")

-- Load Configuration
Rayfield:LoadConfiguration()
print("Configuration loaded")

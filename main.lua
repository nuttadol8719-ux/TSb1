local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create Window
local Window = Rayfield:CreateWindow({
    Name = "น้องปอนด์ Hub",
    LoadingTitle = "น้องปอนด์ Hub",
    LoadingSubtitle = "by pond - Thai edition",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "PondHub",
        FileName = "PondHubConfig"
    },
    Discord = {Enabled = false},
    KeySystem = false
})

-- Tabs
local MainTab = Window:CreateTab("Main", 4483362458)
local OtherTab = Window:CreateTab("อื่นๆ", 4483345998)

-- Variables
local enabled = false
local remoteEnabled = false
local AutoSkill = false
local flyEnabled = false
local selectedPlayer = nil
local selectedPlayerName = nil
local distance = 5
local flySpeed = 50
local orbitSpeed = 0.5
local mode = "เข้าหลัง💦"
local orbitAngle = 0
local BV = nil
local BG = nil

-- Functions
local function GetPlayers()
    local t = {}
    for _,v in pairs(Players:GetPlayers()) do
        if v ~= player then
            table.insert(t, v.Name)
        end
    end
    return t
end

-- ==================== MAIN TAB ====================

local PlayerDropdown = MainTab:CreateDropdown({
    Name = "เลือกผู้เล่น",
    Options = GetPlayers(),
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "PlayerDropdown",
    Callback = function(Option)
        selectedPlayerName = Option[1] or Option
        selectedPlayer = Players:FindFirstChild(selectedPlayerName)
    end,
})

MainTab:CreateButton({
    Name = "รีเซ็ตผู้เล่น",
    Callback = function()
        PlayerDropdown:Refresh(GetPlayers())
        Rayfield:Notify({
            Title = "รีเซ็ตสำเร็จ",
            Content = "รายชื่อผู้เล่นถูกอัพเดทแล้ว",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

MainTab:CreateToggle({
    Name = "เข้าหลัง💦",
    CurrentValue = false,
    Flag = "BackToggle",
    Callback = function(Value)
        enabled = Value
    end,
})

MainTab:CreateToggle({
    Name = "ต่อย",
    CurrentValue = false,
    Flag = "PunchToggle",
    Callback = function(Value)
        remoteEnabled = Value
    end,
})

MainTab:CreateToggle({
    Name = "สกิว (หัวไข่เท่านั้น)",
    CurrentValue = false,
    Flag = "SkillToggle",
    Callback = function(Value)
        AutoSkill = Value
    end,
})

MainTab:CreateToggle({
    Name = "เทพเจ้าลอยฟ้า (คีย์ลัด: C)",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(Value)
        flyEnabled = Value
        if not Value then
            if BV then BV:Destroy() BV = nil end
            if BG then BG:Destroy() BG = nil end
        end
    end,
})

MainTab:CreateSlider({
    Name = "ระยะ",
    Range = {1, 20},
    Increment = 1,
    Suffix = "m",
    CurrentValue = 5,
    Flag = "DistanceSlider",
    Callback = function(Value)
        distance = Value
    end,
})

MainTab:CreateSlider({
    Name = "ความเร็วบิน",
    Range = {10, 200},
    Increment = 1,
    Suffix = "speed",
    CurrentValue = 50,
    Flag = "FlySpeedSlider",
    Callback = function(Value)
        flySpeed = Value
    end,
})

MainTab:CreateDropdown({
    Name = "โหมด",
    Options = {"เข้าหลัง💦", "หน้า", "ซ้าย", "ขวา", "หมุนตริ้ว"},
    CurrentOption = {"เข้าหลัง💦"},
    MultipleOptions = false,
    Flag = "ModeDropdown",
    Callback = function(Option)
        mode = Option[1] or Option
    end,
})

MainTab:CreateSlider({
    Name = "ความเร็วหมุนตริ้ว",
    Range = {0.1, 5},
    Increment = 0.1,
    Suffix = "speed",
    CurrentValue = 0.5,
    Flag = "OrbitSpeedSlider",
    Callback = function(Value)
        orbitSpeed = Value
    end,
})

MainTab:CreateParagraph({
    Title = "คำแนะนำ",
    Content = "💡 คีย์ลัดเทพเจ้าลอยฟ้า: กด C\n✈️ บินอิสระตามกล้อง (PC: WASD / Mobile: จอยเสมือน)"
})

-- ==================== OTHER TAB ====================

OtherTab:CreateParagraph({
    Title = "ℹ️ ข้อมูล UI",
    Content = "UI Library: Rayfield\nVersion: Latest\nCreated by: pond"
})

-- ==================== KEYBIND HANDLER ====================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.C then
        flyEnabled = not flyEnabled
        Rayfield.Flags["FlyToggle"]:Set(flyEnabled)
    end
end)

-- ==================== LOOPS ====================

task.spawn(function()
    while task.wait(0.1) do
        if remoteEnabled then
            local char = player.Character
            if char and char:FindFirstChild("Communicate") then
                char.Communicate:FireServer({
                    Goal = "LeftClick",
                    Mobile = true
                })
            end
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if AutoSkill then
            local char = player.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local backpack = player:FindFirstChild("Backpack")
            if char and hum and hum.Health > 0 and backpack then
                local communicate = char:FindFirstChild("Communicate")
                if communicate then
                    local skills = {"Normal Punch","Consecutive Punches","Shove","Uppercut"}
                    for _, skillName in ipairs(skills) do
                        local skill = backpack:FindFirstChild(skillName)
                        if skill and AutoSkill then
                            local args = {{
                                IsAutoActivate = true,
                                Goal = "Console Move",
                                Tool = skill,
                                ToolName = skillName
                            }}
                            communicate:FireServer(unpack(args))
                            task.wait(0.5)
                        end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if selectedPlayerName then
            local targetPlayer = Players:FindFirstChild(selectedPlayerName)
            selectedPlayer = targetPlayer or nil
        end
    end
end)

-- ==================== PROPER MOBILE FLY SYSTEM ====================

RunService.Heartbeat:Connect(function()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if flyEnabled then
        if not BV then
            BV = Instance.new("BodyVelocity")
            BV.Parent = hrp
            BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        end
        if not BG then
            BG = Instance.new("BodyGyro")
            BG.Parent = hrp
            BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            BG.P = 10000
            BG.D = 500
        end

        local cam = workspace.CurrentCamera
        local moveDirection = Vector3.new(0, 0, 0)

        -- PC Controls
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + cam.CFrame.RightVector
        end

        -- Mobile Controls (Proper Camera-relative Mapping)
        if UserInputService.TouchEnabled and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
            local moveVector = player.Character:FindFirstChildOfClass("Humanoid").MoveDirection
            if moveVector.Magnitude > 0 then
                local forward = cam.CFrame.LookVector * moveVector.Z
                local right = cam.CFrame.RightVector * moveVector.X
                moveDirection = forward + right
            end
        end

        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
        end

        BV.Velocity = moveDirection * flySpeed
        BG.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
    else
        if BV then BV:Destroy() BV = nil end
        if BG then BG:Destroy() BG = nil end
    end
end)

-- ==================== MOVEMENT SYSTEM ====================

RunService.RenderStepped:Connect(function()
    if enabled and selectedPlayer then
        local target = selectedPlayer.Character
        local me = player.Character
        if target and me then
            local tHRP = target:FindFirstChild("HumanoidRootPart")
            local mHRP = me:FindFirstChild("HumanoidRootPart")
            if tHRP and mHRP then
                local targetPos
                if mode == "เข้าหลัง💦" then
                    targetPos = (tHRP.CFrame * CFrame.new(0, 0, distance)).Position
                elseif mode == "หน้า" then
                    targetPos = (tHRP.CFrame * CFrame.new(0, 0, -distance)).Position
                elseif mode == "ซ้าย" then
                    targetPos = (tHRP.CFrame * CFrame.new(-distance, 0, 0)).Position
                elseif mode == "ขวา" then
                    targetPos = (tHRP.CFrame * CFrame.new(distance, 0, 0)).Position
                elseif mode == "หมุนตริ้ว" then
                    orbitAngle += orbitSpeed * 0.05
                    local x = math.cos(orbitAngle) * distance
                    local z = math.sin(orbitAngle) * distance
                    targetPos = tHRP.Position + Vector3.new(x, 0, z)
                end
                mHRP.CFrame = CFrame.lookAt(targetPos, tHRP.Position)
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(newPlayer)
    PlayerDropdown:Refresh(GetPlayers())
    if newPlayer.Name == selectedPlayerName then
        task.wait(0.5)
        selectedPlayer = newPlayer
    end
end)

Players.PlayerRemoving:Connect(function()
    PlayerDropdown:Refresh(GetPlayers())
end)

Rayfield:Notify({
    Title = "น้องปอนด์ Hub",
    Content = "โหลดสำเร็จ! ยินดีต้อนรับ 🎨",
    Duration = 5,
    Image = 4483362458,
})

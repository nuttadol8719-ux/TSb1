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
local freezeAnimEnabled = false
local fakeBugEnabled = false
local showFlyButton = true
local selectedPlayer = nil
local selectedPlayerName = nil
local distance = 5
local flySpeed = 50
local orbitSpeed = 0.5
local mode = "เข้าหลัง💦"
local orbitAngle = 0
local BV = nil
local BG = nil
local FakeBugGyro = nil
local previousPosition = nil
local moveThreshold = 0.05
local animationConnection = nil

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

-- ล้างค่าตัวแปรเมื่อตัวละครเกิดใหม่
player.CharacterAdded:Connect(function()
    BV = nil
    BG = nil
    FakeBugGyro = nil
    previousPosition = nil
end)

-- ==================== FLOATING FLY BUTTON ====================

local PlayerGui = player:WaitForChild("PlayerGui")

local FlyButtonGui = Instance.new("ScreenGui")
FlyButtonGui.Name = "FlyButtonGui"
FlyButtonGui.ResetOnSpawn = false
FlyButtonGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
FlyButtonGui.Parent = PlayerGui
FlyButtonGui.Enabled = true

local FlyButton = Instance.new("TextButton")
FlyButton.Name = "FlyButton"
FlyButton.Size = UDim2.new(0, 80, 0, 80)
FlyButton.Position = UDim2.new(1, -100, 0.5, -40)
FlyButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
FlyButton.BorderSizePixel = 0
FlyButton.Text = "✈️"
FlyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyButton.TextSize = 40
FlyButton.Font = Enum.Font.GothamBold
FlyButton.Parent = FlyButtonGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 15)
Corner.Parent = FlyButton

local function UpdateButtonColor()
    if flyEnabled then
        FlyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        FlyButton.Text = "✈️ ON"
        FlyButton.TextSize = 24
    else
        FlyButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        FlyButton.Text = "✈️"
        FlyButton.TextSize = 40
    end
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

local FlyToggle = MainTab:CreateToggle({
    Name = "เทพเจ้าลอยฟ้า (คีย์ลัด: C)",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(Value)
        flyEnabled = Value
        UpdateButtonColor()
        if not Value then
            if BV then BV:Destroy() BV = nil end
            if BG then BG:Destroy() BG = nil end
        end
    end,
})

-- ปุ่มลอยควบคุมการกด บิน
FlyButton.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    FlyToggle:Set(flyEnabled)
end)

-- คีย์ลัดกด C บิน
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.C then
        flyEnabled = not flyEnabled
        FlyToggle:Set(flyEnabled)
    end
end)

-- Dragging ปุ่มลอย
local dragging = false
local dragInput, mousePos, framePos

FlyButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        mousePos = input.Position
        framePos = FlyButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

FlyButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        FlyButton.Position = UDim2.new(
            framePos.X.Scale,
            framePos.X.Offset + delta.X,
            framePos.Y.Scale,
            framePos.Y.Offset + delta.Y
        )
    end
end)

MainTab:CreateToggle({
    Name = "แสดงปุ่มลอย ✈️",
    CurrentValue = true,
    Flag = "ShowFlyButtonToggle",
    Callback = function(Value)
        showFlyButton = Value
        FlyButtonGui.Enabled = Value
    end,
})

MainTab:CreateToggle({
    Name = "อนิเมชั่นเพิ่มดาเมจ",
    CurrentValue = false,
    Flag = "FreezeAnimToggle",
    Callback = function(Value)
        freezeAnimEnabled = Value
        local char = player.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        if Value then
            if animationConnection then
                animationConnection:Disconnect()
                animationConnection = nil
            end
            animationConnection = humanoid.AnimationPlayed:Connect(function(track)
                pcall(function()
                    track:AdjustSpeed(0)
                    track.TimePosition = 0
                end)
            end)
            Rayfield:Notify({
                Title = "อนิเมชั่นเพิ่มดาเมจ เปิด",
                Content = "หยุดอนิเมชั่นทั้งหมดเพื่อเพิ่มดาเมจ",
                Duration = 3,
                Image = 4483362458,
            })
        else
            if animationConnection then
                animationConnection:Disconnect()
                animationConnection = nil
            end
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                    pcall(function()
                        track:AdjustSpeed(1)
                    end)
                end
            end
            Rayfield:Notify({
                Title = "อนิเมชั่นเพิ่มดาเมจ ปิด",
                Content = "อนิเมชั่นกลับมาปกติแล้ว",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

MainTab:CreateToggle({
    Name = "🌀 บัคปลอม (Fake Bug)",
    CurrentValue = false,
    Flag = "FakeBugToggle",
    Callback = function(Value)
        fakeBugEnabled = Value
        if not Value then
            if FakeBugGyro then
                FakeBugGyro:Destroy()
                FakeBugGyro = nil
            end
            previousPosition = nil
            Rayfield:Notify({
                Title = "บัคปลอม ปิด",
                Content = "กลับสู่ปกติแล้ว",
                Duration = 3,
                Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title = "บัคปลอม เปิด",
                Content = "ตัวจะแหงนขึ้น 35° เมื่อเคลื่อนไหว",
                Duration = 3,
                Image = 4483362458,
            })
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

-- ==================== SYSTEMS ====================

RunService.Heartbeat:Connect(function(dt)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- ล็อคอนิเมชั่นเพิ่มดาเมจ
    if freezeAnimEnabled then
        local animator = hum:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                pcall(function()
                    track.TimePosition = 0
                    track:AdjustSpeed(0)
                end)
            end
        end
    end

    -- ระบบบัคปลอม (Fake Bug 35 Degree Pitch)
    if fakeBugEnabled then
        local currentPos = hrp.Position
        local isMoving = false
        if previousPosition then
            isMoving = (Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(previousPosition.X, 0, previousPosition.Z)).Magnitude > moveThreshold
        end
        previousPosition = currentPos

        if isMoving then
            if not FakeBugGyro then
                FakeBugGyro = Instance.new("BodyGyro")
                FakeBugGyro.Name = "FakeBugGyro"
                FakeBugGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                FakeBugGyro.P = 10000
                FakeBugGyro.Parent = hrp
            end
            FakeBugGyro.CFrame = hrp.CFrame * CFrame.Angles(math.rad(35), 0, 0)
        else
            if FakeBugGyro then
                FakeBugGyro:Destroy()
                FakeBugGyro = nil
            end
        end
    else
        if FakeBugGyro then
            FakeBugGyro:Destroy()
            FakeBugGyro = nil
        end
        previousPosition = nil
    end

    -- ระบบบิน (Fly System)
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

-- ==================== REMOTE LOOPS ====================

-- Punch Loop
task.spawn(function()
    while task.wait(0.1) do
        if remoteEnabled then
            local char = player.Character
            if char and char:FindFirstChild("Communicate") then
                pcall(function()
                    char.Communicate:FireServer({
                        Goal = "LeftClick",
                        Mobile = true
                    })
                end)
            end
        end
    end
end)

-- Auto Skill Loop
task.spawn(function()
    while task.wait(0.5) do
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
                            pcall(function()
                                communicate:FireServer(unpack(args))
                            end)
                            task.wait(0.5)
                        end
                    end
                end
            end
        end
    end
end)

Rayfield:Notify({
    Title = "น้องปอนด์ Hub",
    Content = "โหลดสำเร็จ! แก้ไขระบบทั้งหมดเรียบร้อยแล้ว",
    Duration = 5,
    Image = 4483362458,
})

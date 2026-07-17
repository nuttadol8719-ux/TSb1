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
local tiltActive = false
local tiltTimer = 0
local tiltDuration = 0.5
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

FlyButton.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    UpdateButtonColor()
    if not flyEnabled then
        if BV then BV:Destroy() BV = nil end
        if BG then BG:Destroy() BG = nil end
    end
    if Rayfield.Flags["FlyToggle"] then
        Rayfield.Flags["FlyToggle"]:Set(flyEnabled)
    end
end)

-- Dragging
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
        UpdateButtonColor()
        if not Value then
            if BV then BV:Destroy() BV = nil end
            if BG then BG:Destroy() BG = nil end
        end
    end,
})

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
            tiltActive = false
            tiltTimer = 0
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

MainTab:CreateParagraph({
    Title = "คำแนะนำ",
    Content = "💡 คีย์ลัดเทพเจ้าลอยฟ้า: กด C หรือปุ่มลอย ✈️\n✈️ ปุ่มลอยสามารถซ่อน/แสดงได้\nอนิเมชั่นเพิ่มดาเมจ: หยุดอนิเมชั่นเพื่อเพิ่มดาเมจ\n🌀 บัคปลอม: ตัวแหงนขึ้น 35° เมื่อเคลื่อนไหว"
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
        UpdateButtonColor()
        Rayfield.Flags["FlyToggle"]:Set(flyEnabled)
    end
end)

-- ==================== SYSTEMS ====================

RunService.Heartbeat:Connect(function(dt)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    -- Freeze Animation System
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

    -- Fly System
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
        if UserInputService.TouchEnabled then
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
                local camCF = cam.CFrame
                local camLook = camCF.LookVector
                local camRight = camCF.RightVector
                local forwardAmount = moveDir:Dot(Vector3.new(camLook.X, 0, camLook.Z).Unit)
                local rightAmount = moveDir:Dot(Vector3.new(camRight.X, 0, camRight.Z).Unit)
                moveDirection = moveDirection + (camLook * forwardAmount) + (camRight * rightAmount)
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

    -- Fake Bug System
    if fakeBugEnabled then
        if not FakeBugGyro or FakeBugGyro.Parent ~= hrp then
            FakeBugGyro = Instance.new("BodyGyro")
            FakeBugGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            FakeBugGyro.P = 10000
            FakeBugGyro.D = 500
            FakeBugGyro.Parent = hrp
            previousPosition = hrp.Position
        end
        local currentState = hum:GetState()
        local isDown = (hum.Health <= 0 or currentState == Enum.HumanoidStateType.Dead or currentState == Enum.HumanoidStateType.Ragdoll or currentState == Enum.HumanoidStateType.FallingDown or currentState == Enum.HumanoidStateType.Physics)
        local isGettingUp = (currentState == Enum.HumanoidStateType.GettingUp)
        if isDown then
            FakeBugGyro.MaxTorque = Vector3.new(0, 0, 0)
        elseif isGettingUp then
            FakeBugGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            FakeBugGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + hrp.CFrame.LookVector)
        else
            FakeBugGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            if previousPosition then
                local distanceMoved = (hrp.Position - previousPosition).Magnitude
                if distanceMoved > moveThreshold then
                    tiltActive = true
                    tiltTimer = tiltDuration
                else
                    if tiltTimer > 0 then
                        tiltTimer -= dt
                    else
                        tiltActive = false
                    end
                end
                previousPosition = hrp.Position
            else
                previousPosition = hrp.Position
            end
            if tiltActive then
                local lookVector = hrp.CFrame.LookVector
                local tiltCF = CFrame.new(hrp.Position, hrp.Position + lookVector) * CFrame.Angles(math.rad(35), 0, 0)
                FakeBugGyro.CFrame = tiltCF
            else
                FakeBugGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + hrp.CFrame.LookVector)
            end
        end
    else
        if FakeBugGyro then
            FakeBugGyro:Destroy()
            FakeBugGyro = nil
        end
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
    Content = "โหลดสำเร็จ! ระบบอนิเมชั่นเพิ่มดาเมจกลับมาแล้ว",
    Duration = 5,
    Image = 4483362458,
})

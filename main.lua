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
    LoadingSubtitle = "by pond",
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
local BlockTab = Window:CreateTab("Auto Block", 4483362458)
local CounterTab = Window:CreateTab("ตั้งค่าต่อยสวน", 4483345998)
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
local predictionTime = 0.3
local BV = nil
local BG = nil
local FakeBugGyro = nil
local previousPosition = nil
local moveThreshold = 0.05
local tiltActive = false
local tiltTimer = 0
local tiltDuration = 0.5
local animationConnection = nil

-- Auto Block Variables
local autoBlockEnabled = false
local blockDistance = 10       -- ระยะตรวจจับการโจมตี (เมตร)
local blockDuration = 0.35    -- ระยะเวลาถือบล็อกต่อการโจมตี 1 ครั้ง (วินาที)
local isBlocking = false
local autoUnblock = true       -- ปลดบล็อกอัตโนมัติเมื่อการโจมตีจบ

-- Counter Attack Variables
local counterEnabled = true    -- เปิด/ปิด การต่อยสวน 1 ครั้งหลังบล็อก
local counterDelay = 0.05      -- เวลาดีเลย์ก่อนกดต่อยสวน (วินาที)
local isCountering = false

-- Target Animation IDs Table
local targetAnimationIds = {
    ["10469493270"] = true, ["10469630950"] = true, ["10469639222"] = true, ["10469643643"] = true,
    ["10503381238"] = true, ["10479335397"] = true, ["10466974800"] = true, ["10468665991"] = true,
    ["13532562418"] = true, ["13532600125"] = true, ["13532604085"] = true, ["13294471966"] = true,
    ["12296882427"] = true, ["13380255751"] = true, ["13370310513"] = true, ["13390230973"] = true,
    ["13378751717"] = true, ["13378708199"] = true, ["10470104242"] = true, ["13379003796"] = true,
    ["13294790250"] = true, ["13376962659"] = true, ["14004222985"] = true, ["13997092940"] = true,
    ["14001963401"] = true, ["14136436157"] = true, ["14046756619"] = true, ["14004235777"] = true,
    ["15259161390"] = true, ["15240216931"] = true, ["15240176873"] = true, ["15162694192"] = true,
    ["15290930205"] = true, ["15295895753"] = true, ["16515503507"] = true, ["16515448089"] = true,
    ["16515520431"] = true, ["16552234590"] = true, ["16139108718"] = true, ["16139402582"] = true,
    ["17799224866"] = true, ["17857788598"] = true, ["17857880283"] = true, ["18179181663"] = true,
    ["77509627104305"] = true, ["123005629431309"] = true,
}

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

-- Remote Punch Counter Function
local function PerformSinglePunchRemote()
    local char = player.Character
    if not char then return end

    local communicate = char:FindFirstChild("Communicate")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if communicate then
        pcall(function()
            local currentCF = hrp and hrp.CFrame or CFrame.new()

            communicate:FireServer({
                Mobile = true,
                Goal = "LeftClick",
                MousePos = currentCF
            })

            task.wait(0.03)

            communicate:FireServer({
                Goal = "LeftClickRelease"
            })
        end)
    end
end

-- Remote Block Trigger Function
local function TriggerBlockRemote()
    if isBlocking then return end
    
    local char = player.Character
    if not char then return end

    local communicate = char:FindFirstChild("Communicate")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if not communicate then return end

    isBlocking = true

    -- 1. ยิง Remote กดบล็อก (KeyPress -> KeyCode.F)
    pcall(function()
        local currentCF = hrp and hrp.CFrame or CFrame.new()
        communicate:FireServer({
            Goal = "KeyPress",
            Key = Enum.KeyCode.F,
            MousePos = currentCF
        })
    end)

    -- 2. รอนานเท่ากับ blockDuration แล้วยิง Remote ปล่อยบล็อก (KeyRelease)
    task.delay(blockDuration, function()
        if isBlocking and autoUnblock then
            pcall(function()
                communicate:FireServer({
                    Goal = "KeyRelease",
                    Key = Enum.KeyCode.F
                })
            end)
            isBlocking = false

            -- ทำการต่อยสวน 1 ครั้งหลังปล่อยบล็อก
            if counterEnabled and not isCountering then
                isCountering = true
                task.wait(counterDelay)
                PerformSinglePunchRemote()
                task.wait(0.1)
                isCountering = false
            end
        end
    end)
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

MainTab:CreateSlider({
    Name = "ติดหนึบ",
    Range = {0, 0.5},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = 0.3,
    Flag = "PredictionSlider",
    Callback = function(Value)
        predictionTime = Value
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
    Name = "🌀 บัคปลอม",
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

-- ==================== AUTO BLOCK TAB ====================

BlockTab:CreateParagraph({
    Title = "🛡️ ระบบ Auto Block (Pure Remote Mode)",
    Content = "ใช้การยิง Remote Event 'Communicate' ทั้งกดและปล่อยบล็อกอัตโนมัติ"
})

BlockTab:CreateToggle({
    Name = "🛡️ เปิดใช้งาน Auto Block",
    CurrentValue = false,
    Flag = "AutoBlockToggle",
    Callback = function(Value)
        autoBlockEnabled = Value
        if not Value and isBlocking then
            local char = player.Character
            if char and char:FindFirstChild("Communicate") then
                char.Communicate:FireServer({
                    Goal = "KeyRelease",
                    Key = Enum.KeyCode.F
                })
            end
            isBlocking = false
        end
    end,
})

BlockTab:CreateSlider({
    Name = "ระยะตรวจจับการโจมตี",
    Range = {4, 20},
    Increment = 1,
    Suffix = "m",
    CurrentValue = 10,
    Flag = "BlockDistanceSlider",
    Callback = function(Value)
        blockDistance = Value
    end,
})

BlockTab:CreateSlider({
    Name = "ระยะเวลาค้างบล็อก",
    Range = {0.1, 1.2},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = 0.35,
    Flag = "BlockDurationSlider",
    Callback = function(Value)
        blockDuration = Value
    end,
})

-- ==================== COUNTER TAB ====================

CounterTab:CreateParagraph({
    Title = "⚔️ ตั้งค่าระบบต่อยสวน (Counter Attack)",
    Content = "ยิง Remote สั่ง M1 สวนกลับทันทีที่ปล่อยการ์ดบล็อก"
})

CounterTab:CreateToggle({
    Name = "⚔️ เปิดใช้งานต่อยสวนหลังบล็อก",
    CurrentValue = true,
    Flag = "CounterToggle",
    Callback = function(Value)
        counterEnabled = Value
    end,
})

CounterTab:CreateSlider({
    Name = "ดีเลย์ก่อนกดต่อยสวน",
    Range = {0, 0.3},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = 0.05,
    Flag = "CounterDelaySlider",
    Callback = function(Value)
        counterDelay = Value
    end,
})

-- ==================== OTHER TAB ====================

OtherTab:CreateParagraph({
    Title = "ℹ️ ข้อมูล UI",
    Content = "UI Library: Rayfield\nCreated by: pond"
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

    -- Auto Block Engine Loop
    if autoBlockEnabled then
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character then
                local targetChar = otherPlayer.Character
                local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                local targetHum = targetChar:FindFirstChildOfClass("Humanoid")

                if targetHRP and targetHum then
                    local dist = (hrp.Position - targetHRP.Position).Magnitude

                    if dist <= blockDistance then
                        local animator = targetHum:FindFirstChildOfClass("Animator")
                        if animator then
                            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                                if track.IsPlaying and track.Animation then
                                    local animId = tostring(track.Animation.AnimationId or ""):match("%d+")
                                    
                                    if animId and targetAnimationIds[animId] and track.TimePosition < 0.35 then
                                        TriggerBlockRemote()
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ==================== TELEPORT ENGINE ====================

local function UpdatePosition()
    if enabled and selectedPlayer then
        local target = selectedPlayer.Character
        local me = player.Character
        if target and me then
            local tHRP = target:FindFirstChild("HumanoidRootPart")
            local mHRP = me:FindFirstChild("HumanoidRootPart")

            if tHRP and mHRP then
                local predictedTargetPos = tHRP.Position + (tHRP.Velocity * predictionTime)
                local predictedCFrame = CFrame.new(predictedTargetPos) * (tHRP.CFrame - tHRP.Position)

                local finalTargetPos
                if mode == "เข้าหลัง💦" then
                    finalTargetPos = (predictedCFrame * CFrame.new(0, 0, distance)).Position
                elseif mode == "หน้า" then
                    finalTargetPos = (predictedCFrame * CFrame.new(0, 0, -distance)).Position
                elseif mode == "ซ้าย" then
                    finalTargetPos = (predictedCFrame * CFrame.new(-distance, 0, 0)).Position
                elseif mode == "ขวา" then
                    finalTargetPos = (predictedCFrame * CFrame.new(distance, 0, 0)).Position
                elseif mode == "หมุนตริ้ว" then
                    orbitAngle += orbitSpeed * 0.05
                    local x = math.cos(orbitAngle) * distance
                    local z = math.sin(orbitAngle) * distance
                    finalTargetPos = predictedTargetPos + Vector3.new(x, 0, z)
                end

                mHRP.CFrame = CFrame.lookAt(finalTargetPos, predictedTargetPos)
            end
        end
    end
end

RunService.RenderStepped:Connect(UpdatePosition)

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
    Content = "อัปเดตระบบ Auto Block & Counter Remote Event เข้าเมนูเรียบร้อยแล้ว!",
    Duration = 5,
    Image = 4483362458,
})

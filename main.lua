local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Load Fluent UI Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Create Window
local Window = Fluent:CreateWindow({
    Title = "น้องปอนด์ Hub",
    SubTitle = "by pond - Thai edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Create Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Other = Window:AddTab({ Title = "อื่นๆ", Icon = "settings" })
}

-- Variables
local enabled = false
local remoteEnabled = false
local AutoSkill = false
local flyEnabled = false

local selectedPlayer = nil
local selectedPlayerName = nil

local distance = 5
local flySpeed = 50

local mode = "เข้าหลัง💦"

local orbitAngle = 0
local orbitSpeed = 0.5

-- Fly Objects
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

-- Player Selection
local PlayerDropdown = Tabs.Main:AddDropdown("PlayerDropdown", {
    Title = "เลือกผู้เล่น",
    Values = GetPlayers(),
    Multi = false,
    Default = nil,
    Callback = function(Value)
        selectedPlayerName = Value
        selectedPlayer = Players:FindFirstChild(selectedPlayerName)
    end
})

-- Refresh Players Button
Tabs.Main:AddButton({
    Title = "รีเซ็ตผู้เล่น",
    Description = "อัพเดทรายชื่อผู้เล่น",
    Callback = function()
        PlayerDropdown:SetValues(GetPlayers())
        Fluent:Notify({
            Title = "รีเซ็ตสำเร็จ",
            Content = "รายชื่อผู้เล่นถูกอัพเดทแล้ว",
            Duration = 3
        })
    end
})

-- Toggles
Tabs.Main:AddToggle("BackToggle", {
    Title = "เข้าหลัง💦",
    Default = false,
    Callback = function(Value)
        enabled = Value
    end
})

Tabs.Main:AddToggle("PunchToggle", {
    Title = "ต่อย",
    Default = false,
    Callback = function(Value)
        remoteEnabled = Value
    end
})

Tabs.Main:AddToggle("SkillToggle", {
    Title = "สกิว (หัวไข่เท่านั้น)",
    Default = false,
    Callback = function(Value)
        AutoSkill = Value
    end
})

Tabs.Main:AddToggle("FlyToggle", {
    Title = "เทพเจ้าลอยฟ้า (คีย์ลัด: C)",
    Default = false,
    Callback = function(Value)
        flyEnabled = Value
        if not Value then
            if BV then BV:Destroy() BV = nil end
            if BG then BG:Destroy() BG = nil end
        end
    end
})

-- Sliders
Tabs.Main:AddSlider("DistanceSlider", {
    Title = "ระยะ",
    Description = "ปรับระยะห่างจากเป้าหมาย",
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 0,
    Callback = function(Value)
        distance = Value
    end
})

Tabs.Main:AddSlider("FlySpeedSlider", {
    Title = "ความเร็วบิน",
    Description = "ปรับความเร็วในการบิน",
    Default = 50,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Callback = function(Value)
        flySpeed = Value
    end
})

-- Mode Dropdown
Tabs.Main:AddDropdown("ModeDropdown", {
    Title = "โหมด",
    Values = {"เข้าหลัง💦", "หน้า", "ซ้าย", "ขวา", "หมุนตริ้ว"},
    Multi = false,
    Default = "เข้าหลัง💦",
    Callback = function(Value)
        mode = Value
    end
})

-- Orbit Speed Slider
Tabs.Main:AddSlider("OrbitSpeedSlider", {
    Title = "ความเร็วหมุนตริ้ว",
    Description = "ปรับความเร็วในการหมุนรอบเป้าหมาย",
    Default = 0.5,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
    Callback = function(Value)
        orbitSpeed = Value
    end
})

-- Info Paragraph
Tabs.Main:AddParagraph({
    Title = "คำแนะนำ",
    Content = "💡 คีย์ลัดเทพเจ้าลอยฟ้า: กด C\n✈️ W/S = บินไปข้างหน้า/หลัง (ตามกล้อง)\n✈️ A/D = บินไปซ้าย/ขวา"
})

-- ==================== OTHER TAB (สี) ====================

Tabs.Other:AddParagraph({
    Title = "🎨 เปลี่ยนสีธีม",
    Content = "เลือกสีธีมที่คุณชอบด้านล่าง"
})

-- Theme Colors Dropdown
Tabs.Other:AddDropdown("ThemeDropdown", {
    Title = "เลือกสีธีม",
    Description = "เปลี่ยนสีของ UI",
    Values = {
        "Dark",      -- สีเข้มมาตรฐาน
        "Darker",    -- สีเข้มกว่า
        "Light",     -- สีสว่าง
        "Aqua",      -- สีฟ้าน้ำทะเล
        "Amethyst",  -- สีม่วงอเมทิสต์
        "Rose",      -- สีชมพูกุหลาบ
    },
    Multi = false,
    Default = "Dark",
    Callback = function(Value)
        Fluent:SetTheme(Value)
        Fluent:Notify({
            Title = "เปลี่ยนธีมสำเร็จ",
            Content = "ธีม: " .. Value,
            Duration = 3
        })
    end
})

-- Individual Color Buttons (ปุ่มสีแต่ละสี)
Tabs.Other:AddButton({
    Title = "🌑 Dark (สีเข้มมาตรฐาน)",
    Description = "ธีมสีเข้มคลาสสิก",
    Callback = function()
        Fluent:SetTheme("Dark")
        Fluent:Notify({
            Title = "เปลี่ยนเป็น Dark",
            Content = "ธีมสีเข้มมาตรฐาน",
            Duration = 2
        })
    end
})

Tabs.Other:AddButton({
    Title = "⚫ Darker (สีเข้มมาก)",
    Description = "ธีมสีดำเข้มขึ้น",
    Callback = function()
        Fluent:SetTheme("Darker")
        Fluent:Notify({
            Title = "เปลี่ยนเป็น Darker",
            Content = "ธีมสีดำเข้มมาก",
            Duration = 2
        })
    end
})

Tabs.Other:AddButton({
    Title = "☀️ Light (สีสว่าง)",
    Description = "ธีมสีสว่างสบายตา",
    Callback = function()
        Fluent:SetTheme("Light")
        Fluent:Notify({
            Title = "เปลี่ยนเป็น Light",
            Content = "ธีมสีสว่าง",
            Duration = 2
        })
    end
})

Tabs.Other:AddButton({
    Title = "🌊 Aqua (สีฟ้าน้ำทะเล)",
    Description = "ธีมสีฟ้าสดใส",
    Callback = function()
        Fluent:SetTheme("Aqua")
        Fluent:Notify({
            Title = "เปลี่ยนเป็น Aqua",
            Content = "ธีมสีฟ้าน้ำทะเล",
            Duration = 2
        })
    end
})

Tabs.Other:AddButton({
    Title = "💜 Amethyst (สีม่วงอเมทิสต์)",
    Description = "ธีมสีม่วงสวยงาม",
    Callback = function()
        Fluent:SetTheme("Amethyst")
        Fluent:Notify({
            Title = "เปลี่ยนเป็น Amethyst",
            Content = "ธีมสีม่วงอเมทิสต์",
            Duration = 2
        })
    end
})

Tabs.Other:AddButton({
    Title = "🌹 Rose (สีชมพูกุหลาบ)",
    Description = "ธีมสีชมพูหวาน",
    Callback = function()
        Fluent:SetTheme("Rose")
        Fluent:Notify({
            Title = "เปลี่ยนเป็น Rose",
            Content = "ธีมสีชมพูกุหลาบ",
            Duration = 2
        })
    end
})

-- Acrylic Toggle
Tabs.Other:AddToggle("AcrylicToggle", {
    Title = "เอฟเฟกต์กระจก (Acrylic)",
    Description = "เปิด/ปิดเอฟเฟกต์พื้นหลังแบบกระจก",
    Default = true,
    Callback = function(Value)
        -- Note: Acrylic effect might need to be set during window creation
        Fluent:Notify({
            Title = "Acrylic Effect",
            Content = Value and "เปิด" or "ปิด",
            Duration = 2
        })
    end
})

-- UI Info
Tabs.Other:AddParagraph({
    Title = "ℹ️ ข้อมูล UI",
    Content = "UI Library: Fluent\nVersion: Latest\nCreated by: pond\n\n🎨 สีที่มีทั้งหมด 6 สี:\n• Dark\n• Darker\n• Light\n• Aqua\n• Rose\n• Amethyst"
})

-- ==================== KEYBIND HANDLER ====================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.C then
        flyEnabled = not flyEnabled
        if not flyEnabled then
            if BV then BV:Destroy() BV = nil end
            if BG then BG:Destroy() BG = nil end
        end
        Fluent:Notify({
            Title = "เทพเจ้าลอยฟ้า",
            Content = flyEnabled and "เปิด ✨" or "ปิด",
            Duration = 2
        })
    end
end)

-- ==================== LOOPS ====================

-- Remote Loop
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

-- Auto Skill Loop
task.spawn(function()
    while task.wait() do
        if AutoSkill then
            local char = player.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local backpack = player:FindFirstChild("Backpack")
            
            if char and hum and hum.Health > 0 and backpack then
                local communicate = char:FindFirstChild("Communicate")
                if communicate then
                    local skills = {
                        "Normal Punch",
                        "Consecutive Punches",
                        "Shove",
                        "Uppercut"
                    }
                    
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

-- Target Lock System
task.spawn(function()
    while task.wait(0.5) do
        if selectedPlayerName then
            local targetPlayer = Players:FindFirstChild(selectedPlayerName)
            selectedPlayer = targetPlayer or nil
        end
    end
end)

-- Fly System
RunService.Heartbeat:Connect(function()
    local char = player.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
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
                BG.CFrame = cam.CFrame
            else
                if BV then BV:Destroy() BV = nil end
                if BG then BG:Destroy() BG = nil end
            end
        end
    end
end)

-- Movement System
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

-- Player Events
Players.PlayerAdded:Connect(function(newPlayer)
    PlayerDropdown:SetValues(GetPlayers())
    if newPlayer.Name == selectedPlayerName then
        task.wait(0.5)
        selectedPlayer = newPlayer
    end
end)

Players.PlayerRemoving:Connect(function()
    PlayerDropdown:SetValues(GetPlayers())
end)

-- Notification
Fluent:Notify({
    Title = "น้องปอนด์ Hub",
    Content = "โหลดสำเร็จ! ยินดีต้อนรับ 🎨",
    Duration = 5
})

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local locked, target = false, nil
local lockKey = Enum.KeyCode.Q
local lockSmoothness = 0.15
local lockCooldown = false
local lockEnabled = false

local teleportEnabled, noclipEnabled = false, false
local teleportKey = Enum.KeyCode.Z
local FOV = 70

local espEnabled = false
local espColor = Color3.fromRGB(255,0,0)
local espObjects = {}

local invisibleEnabled = false -- invisibilidad solo para el cliente

-- FUNCIONES
local function getClosest()
    local closest, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
            local d = (p.Character.Head.Position - camera.CFrame.Position).Magnitude
            if d < dist then
                dist, closest = d, p
            end
        end
    end
    return closest
end

local function setInvisible(state)
    invisibleEnabled = state
    if player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.LocalTransparencyModifier = state and 1 or 0
            elseif part:IsA("Decal") then
                part.LocalTransparencyModifier = state and 1 or 0
            end
        end
    end
end

-- WELCOME GUI
local welcomeGui = Instance.new("ScreenGui")
welcomeGui.Name = "WelcomeGUI"
welcomeGui.DisplayOrder = 999999
welcomeGui.IgnoreGuiInset = true
welcomeGui.ResetOnSpawn = false
welcomeGui.Parent = player:WaitForChild("PlayerGui")

local welcomeFrame = Instance.new("Frame")
welcomeFrame.Parent = welcomeGui
welcomeFrame.Size = UDim2.new(0,400,0,100)
welcomeFrame.Position = UDim2.new(0.5,-200,0.5,-50)
welcomeFrame.BackgroundColor3 = Color3.fromRGB(12,12,12)
welcomeFrame.BorderSizePixel = 0
Instance.new("UICorner", welcomeFrame).CornerRadius = UDim.new(0,12)

local welcomeText = Instance.new("TextLabel")
welcomeText.Parent = welcomeFrame
welcomeText.Size = UDim2.new(1,0,1,0)
welcomeText.BackgroundTransparency = 1
welcomeText.Text = "Welcome to INFZ3rk HUB!"
welcomeText.TextColor3 = Color3.fromRGB(255,0,0)
welcomeText.Font = Enum.Font.GothamBold
welcomeText.TextScaled = true
welcomeText.TextXAlignment = Enum.TextXAlignment.Center
welcomeText.TextYAlignment = Enum.TextYAlignment.Center

-- MAIN GUI
local gui = Instance.new("ScreenGui")
gui.Name = "INFZ3rkHub"
gui.DisplayOrder = 999998
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
gui.Enabled = false

local main = Instance.new("Frame")
main.Parent = gui
main.Size = UDim2.new(0,600,0,500) -- aumentado para que quepa el slider del Spin Speed
main.Position = UDim2.new(0.5,-300,0.5,-250) -- centrado con la nueva altura
main.BackgroundColor3 = Color3.fromRGB(12,12,12)
main.BorderSizePixel = 0
Instance.new("UICorner", main).CornerRadius = UDim.new(0,12)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(255,0,0)
stroke.Thickness = 2

local topBar = Instance.new("Frame")
topBar.Parent = main
topBar.Size = UDim2.new(1,0,0,50)
topBar.BackgroundColor3 = Color3.fromRGB(16,16,16)
topBar.BorderSizePixel = 0
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0,12)

local title = Instance.new("TextLabel")
title.Parent = topBar
title.Size = UDim2.new(1,-20,1,0)
title.Position = UDim2.new(0,10,0,0)
title.BackgroundTransparency = 1
title.Text = "INFZ3rk HUB"
title.TextColor3 = Color3.fromRGB(255,0,0)
title.Font = Enum.Font.GothamBold
title.TextScaled = false
title.TextSize = 32
title.TextXAlignment = Enum.TextXAlignment.Center
title.TextYAlignment = Enum.TextYAlignment.Center

-- CLOSE Y MINIMIZE
local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0,40,0,40)
closeBtn.Position = UDim2.new(1,-45,0,5)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 22
closeBtn.TextColor3 = Color3.fromRGB(255,80,80)
closeBtn.BackgroundTransparency = 1
closeBtn.MouseButton1Click:Connect(function()
    gui.Enabled = false
end)

local minimizeBtn = Instance.new("TextButton", topBar)
minimizeBtn.Size = UDim2.new(0,40,0,40)
minimizeBtn.Position = UDim2.new(1,-90,0,3)
minimizeBtn.Text = "–"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 28
minimizeBtn.TextColor3 = Color3.fromRGB(200,200,200)
minimizeBtn.BackgroundTransparency = 1

local content = Instance.new("Frame", main)
content.Position = UDim2.new(0,0,0,50)
content.Size = UDim2.new(1,0,1,-50)
content.BackgroundTransparency = 1

local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    content.Visible = not minimized
    main.Size = minimized and UDim2.new(0,600,0,50) or UDim2.new(0,600,0,500)
end)

-- DRAG
local dragging, dragStart, startPos
topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)
topBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- TOGGLES Y SLIDERS
local function addToggle(y,text,callback,key)
    local frame = Instance.new("Frame")
    frame.Parent = content
    frame.Size = UDim2.new(1,-40,0,35)
    frame.Position = UDim2.new(0,20,0,y)
    frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    frame.BorderSizePixel = 0
    Instance.new("UICorner",frame).CornerRadius = UDim.new(0,6)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Size = UDim2.new(0.7,0,1,0)
    label.Position = UDim2.new(0,10,0,0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.Gotham
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Parent = frame
    toggleBtn.Size = UDim2.new(0,30,0,20)
    toggleBtn.Position = UDim2.new(1,-70,0.5,-10)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    toggleBtn.Text = ""
    Instance.new("UICorner",toggleBtn).CornerRadius = UDim.new(0,4)

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Parent = frame
    keyLabel.Size = UDim2.new(0,30,0,20)
    keyLabel.Position = UDim2.new(1,-35,0.5,-10)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Text = key and "("..key.Name..")" or ""
    keyLabel.TextColor3 = Color3.fromRGB(200,200,200)
    keyLabel.Font = Enum.Font.Gotham
    keyLabel.TextScaled = true

    local state = false
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        toggleBtn.BackgroundColor3 = state and Color3.fromRGB(0,200,0) or Color3.fromRGB(50,50,50)
        callback(state)
    end)
end

local function addSlider(y,text,min,max,default,callback)
    local frame = Instance.new("Frame")
    frame.Parent = content
    frame.Size = UDim2.new(1,-40,0,35)
    frame.Position = UDim2.new(0,20,0,y)
    frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    frame.BorderSizePixel = 0
    Instance.new("UICorner",frame).CornerRadius = UDim.new(0,6)

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.Size = UDim2.new(0.3,0,1,0)
    label.Position = UDim2.new(0,10,0,0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.Gotham
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left

    local slider = Instance.new("Frame")
    slider.Parent = frame
    slider.Size = UDim2.new(0.5,0,0,8)
    slider.Position = UDim2.new(0.35,0,0.5,-4)
    slider.BackgroundColor3 = Color3.fromRGB(50,50,50)
    Instance.new("UICorner",slider).CornerRadius = UDim.new(0,4)

    local fill = Instance.new("Frame")
    fill.Parent = slider
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(255,0,0)
    Instance.new("UICorner",fill).CornerRadius = UDim.new(0,4)

    local handle = Instance.new("Frame")
    handle.Parent = fill
    handle.Size = UDim2.new(0,15,1.5,0)
    handle.Position = UDim2.new(1,-7,-0.25,0)
    handle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner",handle).CornerRadius = UDim.new(0,7)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = frame
    valueLabel.Size = UDim2.new(0,40,1,0)
    valueLabel.Position = UDim2.new(1,-45,0,0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Color3.fromRGB(200,200,200)
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextScaled = true

    local dragging = false
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local mouseX = UIS:GetMouseLocation().X
            local sliderX = slider.AbsolutePosition.X
            local sliderW = slider.AbsoluteSize.X
            local pct = math.clamp((mouseX - sliderX)/sliderW,0,1)
            fill.Size = UDim2.new(pct,0,1,0)
            handle.Position = UDim2.new(1,-7,-0.25,0)
            local val = math.floor(min + (max-min)*pct)
            valueLabel.Text = tostring(val)
            callback(val)
        end
    end)
end

-- ADD TOGGLES
local yStart, gap = 20, 50
addToggle(yStart + gap*0,"Aimbot",function(v) lockEnabled = v end, lockKey)
addToggle(yStart + gap*1,"Teleport",function(v) teleportEnabled = v end, teleportKey)
addToggle(yStart + gap*2,"Noclip",function(v) noclipEnabled = v end)
addSlider(yStart + gap*3,"FOV",70,120,FOV,function(v) FOV = v camera.FieldOfView = FOV end)
addToggle(yStart + gap*4,"ESP",function(v) espEnabled = v end)
addToggle(yStart + gap*5,'Invisibility (Client)', setInvisible)

-- ==========================
-- TELEPORT TROLL + SPIN SPEED SLIDER
-- ==========================
local spinTarget = nil
local spinEnabled = false
local spinRadius = 5
local spinSpeed = 4
local angle = 0

addToggle(yStart + gap*6,"Teleport Troll",function(state)
    spinEnabled = state
    if state then
        spinTarget = getClosest()
    else
        spinTarget = nil
    end
end)

-- Slider para la velocidad del spin
addSlider(yStart + gap*7,"Spin Speed",1,20,spinSpeed,function(v)
    spinSpeed = v
end)

-- INPUT ORIGINAL
UIS.InputBegan:Connect(function(input,g)
    if g then return end
    if input.KeyCode == Enum.KeyCode.M then gui.Enabled = not gui.Enabled end

    if input.KeyCode == lockKey and not lockCooldown and lockEnabled then
        lockCooldown = true
        locked = true
        target = getClosest()
        task.delay(0.3,function()
            locked = false
            target = nil
            lockCooldown = false
        end)
    end

    if input.KeyCode == teleportKey and teleportEnabled then
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(player:GetMouse().Hit.Position + Vector3.new(0,3,0))
        end
    end
end)

-- ESP Y Noclip
Players.PlayerRemoving:Connect(function(p)
    if espObjects[p] then espObjects[p]:Remove() espObjects[p]=nil end
end)

RunService.RenderStepped:Connect(function(dt)
    if noclipEnabled and player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    if locked and target and target.Character and target.Character:FindFirstChild("Head") then
        camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, target.Character.Head.Position), lockSmoothness)
    end

    -- ESP
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
            if espEnabled then
                if not espObjects[p] then
                    local box = Drawing.new("Square")
                    box.Thickness = 2
                    box.Color = espColor
                    box.Visible = true
                    espObjects[p] = box
                end
                local pos,onScreen = camera:WorldToViewportPoint(p.Character.Head.Position)
                if onScreen then
                    espObjects[p].Position = Vector2.new(pos.X-10,pos.Y-10)
                    espObjects[p].Size = Vector2.new(20,20)
                    espObjects[p].Visible = true
                else
                    espObjects[p].Visible = false
                end
            elseif espObjects[p] then
                espObjects[p]:Remove()
                espObjects[p]=nil
            end
        end
    end

    -- TELEPORT TROLL
    if spinEnabled and spinTarget and spinTarget.Character and spinTarget.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        local targetHRP = spinTarget.Character.HumanoidRootPart
        angle += spinSpeed * dt
        local offset = Vector3.new(
            math.cos(angle) * spinRadius,
            0,
            math.sin(angle) * spinRadius
        )
        hrp.CFrame = CFrame.new(targetHRP.Position + offset, targetHRP.Position)
    end

    -- Invisibilidad
    if invisibleEnabled and player.Character then
        setInvisible(true)
    end
end)

-- WELCOME GUI DESTROY
task.delay(3,function()
    welcomeGui:Destroy()
    gui.Enabled = true
end)

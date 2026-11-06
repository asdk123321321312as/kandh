--[[ Venice · Korblox + Headless · universal
     работает на R6 и на R15, в любой игре
     H — голова, K — коробокс, Z — меню ]]

if getgenv().VeniceCos then pcall(function() getgenv().VeniceCos:Destroy() end) end
if getgenv().VeniceCosConns then
    for _, c in ipairs(getgenv().VeniceCosConns) do pcall(function() c:Disconnect() end) end
end
getgenv().VeniceCosConns = {}

local ref = cloneref or function(s) return s end
local Players   = ref(game:GetService("Players"))
local UIS       = ref(game:GetService("UserInputService"))
local TweenS    = ref(game:GetService("TweenService"))
local LP        = Players.LocalPlayer
while not LP do task.wait() end

local function track(c) table.insert(getgenv().VeniceCosConns, c) return c end

local CONFIG = {
    korblox  = true,
    headless = true,
}

local MESH = "rbxassetid://101851696"
local TEX  = "rbxassetid://101851254"

local ACCENT = Color3.fromRGB(152, 132, 255)
local BG     = Color3.fromRGB(9, 9, 11)
local ROW    = Color3.fromRGB(23, 23, 28)
local STROKE = Color3.fromRGB(41, 41, 49)
local TEXT   = Color3.fromRGB(238, 238, 244)
local SUB    = Color3.fromRGB(128, 128, 144)
local OKC    = Color3.fromRGB(120, 220, 160)

-- ============================== голова ==============================

local function applyHeadless(on)
    local char = LP.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    if head:IsA("BasePart") then head.Transparency = on and 1 or 0 end
    for _, d in ipairs(head:GetDescendants()) do
        if d:IsA("Decal") then d.Transparency = on and 1 or 0 end
    end
end

-- ============================== коробокс ==============================

local function clearKorblox()
    local char = LP.Character
    if not char then return end
    for _, n in ipairs({ "VeniceKorblox", "VeniceKorbloxLeg" }) do
        local o = char:FindFirstChild(n)
        if o then pcall(function() o:Destroy() end) end
    end
    for _, n in ipairs({ "Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot" }) do
        local p = char:FindFirstChild(n)
        if p and p:IsA("BasePart") then p.Transparency = 0 end
    end
end

local function applyKorblox(on)
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if not on then clearKorblox() return end

    if hum.RigType == Enum.HumanoidRigType.R6 then
        if char:FindFirstChild("VeniceKorblox") then return end
        local m = Instance.new("CharacterMesh")
        m.Name = "VeniceKorblox"
        m.BodyPart = Enum.BodyPart.RightLeg
        m.MeshId = 101851696
        m.OverlayTextureId = 101851254
        m.Parent = char
        return
    end

    if char:FindFirstChild("VeniceKorbloxLeg") then return end

    local upper = char:FindFirstChild("RightUpperLeg")
    local lower = char:FindFirstChild("RightLowerLeg")
    local foot  = char:FindFirstChild("RightFoot")
    if not upper or not upper:IsA("BasePart") then return end

    local top = upper.CFrame * CFrame.new(0, upper.Size.Y / 2, 0)
    local bottom
    if foot and foot:IsA("BasePart") then
        bottom = foot.CFrame * CFrame.new(0, -foot.Size.Y / 2, 0)
    elseif lower and lower:IsA("BasePart") then
        bottom = lower.CFrame * CFrame.new(0, -lower.Size.Y / 2, 0)
    else
        bottom = upper.CFrame * CFrame.new(0, -upper.Size.Y, 0)
    end

    local a, b = top.Position, bottom.Position
    local len = math.max((a - b).Magnitude, 0.5)
    local rot = upper.CFrame - upper.CFrame.Position

    local part = Instance.new("Part")
    part.Name = "VeniceKorbloxLeg"
    part.Size = Vector3.new(1, len, 1)
    part.CFrame = CFrame.new((a + b) / 2) * rot
    part.Anchored = false
    part.CanCollide = false
    part.Massless = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth

    local mesh = Instance.new("SpecialMesh", part)
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = MESH
    mesh.TextureId = TEX

    part.Parent = char

    for _, p in ipairs({ upper, lower, foot }) do
        if p and p:IsA("BasePart") then p.Transparency = 1 end
    end

    local w = Instance.new("WeldConstraint")
    w.Part0 = part
    w.Part1 = upper
    w.Parent = part
end

-- ============================== watchdog ==============================

task.spawn(function()
    while getgenv().VeniceCos do
        task.wait(0.2)
        if LP.Character then
            if CONFIG.headless then pcall(applyHeadless, true) end
            if CONFIG.korblox then pcall(applyKorblox, true) end
        end
    end
end)

track(LP.CharacterAdded:Connect(function()
    task.wait(1.2)
    if CONFIG.headless then pcall(applyHeadless, true) end
    if CONFIG.korblox then pcall(applyKorblox, true) end
end))

-- ============================== меню ==============================

local gui, main, open = nil, nil, false

local function tw(o, t, p) TweenS:Create(o, TweenInfo.new(t), p):Play() end

local function row(text, default, cb)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1, -8, 0, 30)
    r.BackgroundColor3 = ROW
    r.BorderSizePixel = 0
    r.Parent = main
    Instance.new("UICorner", r).CornerRadius = UDim.new(0, 8)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -60, 1, 0)
    l.Position = UDim2.fromOffset(10, 0)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = 12
    l.TextColor3 = TEXT
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = text
    l.Parent = r

    local t = Instance.new("Frame")
    t.Size = UDim2.fromOffset(32, 16)
    t.Position = UDim2.new(1, -42, 0.5, -8)
    t.BackgroundColor3 = default and ACCENT or Color3.fromRGB(45, 45, 54)
    t.BorderSizePixel = 0
    t.Parent = r
    Instance.new("UICorner", t).CornerRadius = UDim.new(1, 0)

    local k = Instance.new("Frame")
    k.Size = UDim2.fromOffset(10, 10)
    k.Position = default and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3)
    k.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    k.BorderSizePixel = 0
    k.Parent = t
    Instance.new("UICorner", k).CornerRadius = UDim.new(1, 0)

    local state = default
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = r
    btn.MouseButton1Click:Connect(function()
        state = not state
        tw(t, 0.15, { BackgroundColor3 = state and ACCENT or Color3.fromRGB(45, 45, 54) })
        tw(k, 0.15, { Position = state and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3) })
        pcall(cb, state)
    end)
end

local function setOpen(force)
    if not main then return end
    open = force ~= nil and force or not open
    if open then
        main.Visible = true
        main.BackgroundTransparency = 1
        tw(main, 0.2, { BackgroundTransparency = 0.05 })
    else
        tw(main, 0.15, { BackgroundTransparency = 1 })
        task.delay(0.16, function() if not open and main then main.Visible = false end end)
    end
end

local function build()
    gui = Instance.new("ScreenGui")
    gui.Name = "VeniceCos"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    getgenv().VeniceCos = gui

    local ok, h = pcall(function() return gethui and gethui() end)
    if not (ok and h and pcall(function() gui.Parent = h end)) then
        local prot = protectgui or protect_gui
        local core = game:GetService("CoreGui")
        if prot then pcall(prot, gui) end
        if not pcall(function() gui.Parent = core end) then
            gui.Parent = LP:WaitForChild("PlayerGui")
        end
    end

    main = Instance.new("Frame")
    main.AnchorPoint = Vector2.new(0, 0)
    main.Position = UDim2.fromOffset(20, 100)
    main.Size = UDim2.fromOffset(190, 112)
    main.BackgroundColor3 = BG
    main.BackgroundTransparency = 0.05
    main.BorderSizePixel = 0
    main.Visible = false
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 11)
    local st = Instance.new("UIStroke", main)
    st.Color = STROKE
    st.Transparency = 0.3

    local head = Instance.new("Frame")
    head.Size = UDim2.new(1, 0, 0, 30)
    head.BackgroundTransparency = 1
    head.Parent = main

    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(6, 6)
    dot.Position = UDim2.fromOffset(12, 12)
    dot.BackgroundColor3 = ACCENT
    dot.BorderSizePixel = 0
    dot.Parent = head
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -30, 0, 12)
    title.Position = UDim2.fromOffset(24, 9)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 11
    title.TextColor3 = TEXT
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "VENICE · COSMETICS"
    title.Parent = head

    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, -8, 1, -36)
    list.Position = UDim2.fromOffset(4, 32)
    list.BackgroundTransparency = 1
    list.Parent = main
    local lay = Instance.new("UIListLayout", list)
    lay.Padding = UDim.new(0, 5)

    -- строки строим в list
    local saved = main
    main = list
    row("Headless", CONFIG.headless, function(v)
        CONFIG.headless = v
        pcall(applyHeadless, v)
        print("[Venice] headless:", v)
    end)
    row("Korblox", CONFIG.korblox, function(v)
        CONFIG.korblox = v
        pcall(applyKorblox, v)
        print("[Venice] korblox:", v)
    end)
    main = saved

    local drag, ds, sp
    head.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag, ds, sp = true, i.Position, main.Position
        end
    end)
    track(UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end))
    track(UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end))

    print("[Venice] косметика загружена · H голова · K коробокс · Z меню")
end

build()

track(UIS.InputBegan:Connect(function(i, gp)
    if gp or UIS:GetFocusedTextBox() then return end
    if i.KeyCode == Enum.KeyCode.H then
        CONFIG.headless = not CONFIG.headless
        pcall(applyHeadless, CONFIG.headless)
        print("[Venice] headless:", CONFIG.headless)
    elseif i.KeyCode == Enum.KeyCode.K then
        CONFIG.korblox = not CONFIG.korblox
        pcall(applyKorblox, CONFIG.korblox)
        print("[Venice] korblox:", CONFIG.korblox)
    elseif i.KeyCode == Enum.KeyCode.Z then
        setOpen()
    end
end))

task.wait(1)
if CONFIG.headless then pcall(applyHeadless, true) end
if CONFIG.korblox then pcall(applyKorblox, true) end

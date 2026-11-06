--[[ Venice · Korblox + Headless + FPS · v4 universal
     R6 / R15 / кастомные риги
     H — голова, K — коробокс, F — буст, Z — меню
     v4: аксессуары, восстановление оригиналов, валидация, force-режим ]]

if getgenv().VeniceCos then pcall(function() getgenv().VeniceCos:Destroy() end) end
if getgenv().VeniceCosConns then
    for _, c in ipairs(getgenv().VeniceCosConns) do pcall(function() c:Disconnect() end) end
end
getgenv().VeniceCosConns = {}

local ref = cloneref or function(s) return s end
local Players  = ref(game:GetService("Players"))
local UIS      = ref(game:GetService("UserInputService"))
local TweenS   = ref(game:GetService("TweenService"))
local Lighting = ref(game:GetService("Lighting"))
local AssetS   = ref(game:GetService("AssetService"))
local RunS     = ref(game:GetService("RunService"))
local LP       = Players.LocalPlayer
while not LP do task.wait() end

local function track(c) table.insert(getgenv().VeniceCosConns, c) return c end

local CONFIG = { korblox = true, headless = true, force = false }
local FPS = { boost = false, shadowsOff = false, fxOff = false, partsOff = false, cap = 240 }

local MESH = "rbxassetid://101851696"
local TEX  = "rbxassetid://101851254"

local ACCENT = Color3.fromRGB(152, 132, 255)
local BG     = Color3.fromRGB(9, 9, 11)
local ROW    = Color3.fromRGB(23, 23, 28)
local STROKE = Color3.fromRGB(41, 41, 49)
local TEXT   = Color3.fromRGB(238, 238, 244)
local SUB    = Color3.fromRGB(128, 128, 144)
local OKC    = Color3.fromRGB(120, 220, 160)

if setthreadidentity then pcall(setthreadidentity, 7) end

local function stealthGui(g)
    local h = gethui and gethui()
    local prot = protectgui or protect_gui or (syn and syn.protect_gui)
    if prot then pcall(prot, g) end
    if h then if pcall(function() g.Parent = h end) then return true end end
    return pcall(function() g.Parent = game:GetService("CoreGui") end)
end

-- ============================== скрытие / восстановление ==============================

local hiddenOrig = {}

local function setHidden(inst, on)
    if not inst then return end
    if on then
        if hiddenOrig[inst] == nil then hiddenOrig[inst] = inst.Transparency end
        if inst.Transparency ~= 1 then inst.Transparency = 1 end
    else
        local o = hiddenOrig[inst]
        if o ~= nil then
            pcall(function() inst.Transparency = o end)
            hiddenOrig[inst] = nil
        end
    end
end

-- ============================== голова ==============================

local function headAccessories(char, head)
    local out = {}
    for _, d in ipairs(char:GetChildren()) do
        if d:IsA("Accessory") or d:IsA("Hat") then
            local w = d:FindFirstChildWhichIsA("Weld", true)
            if w and (w.Part0 == head or w.Part1 == head) then
                table.insert(out, d)
            end
        end
    end
    return out
end

local function applyHeadless(on)
    local char = LP.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    setHidden(head, on)
    for _, d in ipairs(head:GetDescendants()) do
        if d:IsA("Decal") then setHidden(d, on) end
    end
    for _, acc in ipairs(headAccessories(char, head)) do
        for _, d in ipairs(acc:GetDescendants()) do
            if d:IsA("BasePart") or d:IsA("Decal") then setHidden(d, on) end
        end
    end
end

-- ============================== коробокс ==============================

local meshCache = nil
local savedCharMesh = nil

local function findLegParts(char)
    local upper = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg") or char:FindFirstChild("RightLeg")
    if not upper then
        for _, d in ipairs(char:GetChildren()) do
            if d:IsA("BasePart") and d.Name:match("^Right.*[Uu]pper.*Leg$") then upper = d break end
        end
    end
    if not upper then
        for _, d in ipairs(char:GetChildren()) do
            if d:IsA("BasePart") and d.Name:match("^Right.*Leg$") then upper = d break end
        end
    end
    local lower = char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Lower Leg")
    local foot  = char:FindFirstChild("RightFoot") or char:FindFirstChild("Right Foot")
    return upper, lower, foot
end

local function korbloxOk(char)
    if char:FindFirstChild("VeniceKorblox") then return true end
    local p = char:FindFirstChild("VeniceKorbloxLeg")
    if not p or not p:IsA("BasePart") then return false end
    local w = p:FindFirstChildWhichIsA("WeldConstraint") or p:FindFirstChildWhichIsA("Weld")
    if not w or not w.Part1 or not w.Part1:IsDescendantOf(char) then return false end
    return true
end

local function clearKorblox()
    local char = LP.Character
    if not char then return end
    for _, n in ipairs({ "VeniceKorblox", "VeniceKorbloxLeg" }) do
        local o = char:FindFirstChild(n)
        if o then pcall(function() o:Destroy() end) end
    end
    local upper, lower, foot = findLegParts(char)
    setHidden(upper, false)
    setHidden(lower, false)
    setHidden(foot, false)
    if savedCharMesh then
        local m = Instance.new("CharacterMesh")
        m.Name = "VeniceKorbloxRestore"
        m.BodyPart = Enum.BodyPart.RightLeg
        m.MeshId = savedCharMesh.mesh
        m.OverlayTextureId = savedCharMesh.tex
        m.Parent = char
        savedCharMesh = nil
    end
end

local function getMeshPart()
    if meshCache and meshCache.Parent then return meshCache end
    local ok, part = pcall(function()
        return AssetS:CreateMeshPartAsync(MESH, Enum.CollisionFidelity.Box)
    end)
    if ok and typeof(part) == "MeshPart" then
        meshCache = part
        return part
    end
    return nil
end

local function applyKorblox(on)
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if not on then clearKorblox() return end
    if korbloxOk(char) then return end

    if hum.RigType == Enum.HumanoidRigType.R6 then
        for _, d in ipairs(char:GetChildren()) do
            if d:IsA("CharacterMesh") and d.BodyPart == Enum.BodyPart.RightLeg and d.Name ~= "VeniceKorblox" then
                savedCharMesh = { mesh = d.MeshId, tex = d.OverlayTextureId }
                pcall(function() d:Destroy() end)
                break
            end
        end
        local m = Instance.new("CharacterMesh")
        m.Name = "VeniceKorblox"
        m.BodyPart = Enum.BodyPart.RightLeg
        m.MeshId = 101851696
        m.OverlayTextureId = 101851254
        m.Parent = char
        return
    end

    local stale = char:FindFirstChild("VeniceKorbloxLeg")
    if stale then pcall(function() stale:Destroy() end) end

    local upper, lower, foot = findLegParts(char)
    if not upper then return end

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
    local delta = a - b
    local len = math.clamp(delta.Magnitude, 1, 9)
    local up = delta.Magnitude > 1e-3 and delta.Unit or Vector3.new(0, 1, 0)
    local mid = (a + b) / 2
    local w = math.clamp(math.max(upper.Size.X, upper.Size.Z) * 1.05, 0.3, 3)

    local part = getMeshPart()
    if part then
        pcall(function()
            part.TextureID = TEX
            part.MeshId = MESH
        end)
        part.Name = "VeniceKorbloxLeg"
    else
        part = Instance.new("Part")
        part.Name = "VeniceKorbloxLeg"
        local sm = Instance.new("SpecialMesh", part)
        sm.MeshType = Enum.MeshType.FileMesh
        sm.MeshId = MESH
        sm.TextureId = TEX
    end

    part.Size = Vector3.new(w, len, w)
    part.CFrame = CFrame.lookAt(mid, mid + upper.CFrame.RightVector, up)
    part.Anchored = false
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = true
    pcall(function() part.Massless = true end)
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = char

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = part
    weld.Part1 = upper
    weld.Parent = part

    setHidden(upper, true)
    setHidden(lower, true)
    setHidden(foot, true)
end

-- ============================== фиксация ==============================

local function enforce()
    local char = LP.Character
    if not char or not LP:HasAppearanceLoaded() then return end
    if CONFIG.headless then pcall(applyHeadless, true) end
    if CONFIG.korblox then pcall(applyKorblox, true) end
end

local acc = 0
track(RunS.Heartbeat:Connect(function(dt)
    if CONFIG.force then
        enforce()
    else
        acc = acc + dt
        if acc >= 0.1 then
            acc = 0
            enforce()
        end
    end
end))

local function hookChar(char)
    table.clear(hiddenOrig)
    meshCache = nil
    savedCharMesh = nil
    task.delay(0.6, enforce)
    track(char.DescendantAdded:Connect(function()
        task.delay(0.05, enforce)
    end))
end

if LP.Character then hookChar(LP.Character) end
track(LP.CharacterAdded:Connect(hookChar))
track(LP.CharacterAppearanceLoaded:Connect(enforce))

-- ============================== fps ==============================

local saved = {}
local killedFx = {}
local killedParts = {}

local function killAll(classList, store)
    local n = 0
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA(classList[1]) or (classList[2] and d:IsA(classList[2])) then
            if d.Enabled then
                d.Enabled = false
                table.insert(store, d)
                n = n + 1
                if n > 4000 then break end
            end
        end
    end
end

local function restore(list)
    for _, d in ipairs(list) do
        if d.Parent then pcall(function() d.Enabled = true end) end
    end
    table.clear(list)
end

local function setQuality(off)
    if off then
        pcall(function() saved.quality = settings().Rendering.QualityLevel end)
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    else
        pcall(function() settings().Rendering.QualityLevel = saved.quality or Enum.QualityLevel.Automatic end)
    end
end

local function setShadows(off)
    if off then
        saved.shadows = Lighting.GlobalShadows
        saved.diffuse = Lighting.EnvironmentDiffuseScale
        saved.spec = Lighting.EnvironmentSpecularScale
        Lighting.GlobalShadows = false
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
    else
        Lighting.GlobalShadows = saved.shadows ~= false
        Lighting.EnvironmentDiffuseScale = saved.diffuse or 1
        Lighting.EnvironmentSpecularScale = saved.spec or 1
    end
end

local function setPostFx(off)
    if off then
        for _, d in ipairs(Lighting:GetChildren()) do
            if d:IsA("PostEffect") and d.Enabled then
                d.Enabled = false
                table.insert(killedFx, d)
            end
        end
    else
        restore(killedFx)
    end
end

local function setParticles(off)
    if off then
        killAll({ "ParticleEmitter", "Beam" }, killedParts)
        killAll({ "Trail", "Smoke" }, killedParts)
        killAll({ "Fire", "Sparkles" }, killedParts)
        pcall(function()
            local t = workspace:FindFirstChildOfClass("Terrain")
            if t then
                saved.waveSize = t.WaterWaveSize
                t.WaterWaveSize = 0
                t.WaterReflectance = 0
                t.Decoration = false
            end
        end)
    else
        restore(killedParts)
        pcall(function()
            local t = workspace:FindFirstChildOfClass("Terrain")
            if t then
                t.WaterWaveSize = saved.waveSize or 0.15
                t.Decoration = true
            end
        end)
    end
end

local function setCap(v)
    if setfpscap then pcall(setfpscap, FPS.boost and v or 9999) end
end

local function syncFps()
    setQuality(FPS.boost)
    setShadows(FPS.boost and FPS.shadowsOff)
    setPostFx(FPS.boost and FPS.fxOff)
    setParticles(FPS.boost and FPS.partsOff)
    setCap(FPS.cap)
end

-- ============================== меню ==============================

local gui, panel, open = nil, nil, false

local function tw(o, t, p) TweenS:Create(o, TweenInfo.new(t), p):Play() end

local function section(text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -8, 0, 16)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.TextSize = 9
    l.TextColor3 = SUB
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = "  " .. text
    l.Parent = panel
end

local function row(text, default, cb, h)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1, -8, 0, h or 30)
    r.BackgroundColor3 = ROW
    r.BorderSizePixel = 0
    r.Parent = panel
    Instance.new("UICorner", r).CornerRadius = UDim.new(0, 8)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -56, 1, 0)
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
        task.spawn(function() pcall(cb, state) end)
    end)
end

local function button(text, cb)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1, -8, 0, 28)
    r.BackgroundColor3 = ROW
    r.BorderSizePixel = 0
    r.Parent = panel
    Instance.new("UICorner", r).CornerRadius = UDim.new(0, 8)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.fromScale(1, 1)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = 11
    l.TextColor3 = TEXT
    l.Text = text
    l.Parent = r

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = r
    btn.MouseButton1Click:Connect(function()
        tw(l, 0.1, { TextColor3 = OKC })
        task.delay(0.25, function() tw(l, 0.2, { TextColor3 = TEXT }) end)
        task.spawn(function() pcall(cb) end)
    end)
end

local function slider(text, min, max, default, cb)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1, -8, 0, 40)
    r.BackgroundColor3 = ROW
    r.BorderSizePixel = 0
    r.Parent = panel
    Instance.new("UICorner", r).CornerRadius = UDim.new(0, 8)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -50, 0, 16)
    l.Position = UDim2.fromOffset(10, 5)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = 11
    l.TextColor3 = TEXT
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = text
    l.Parent = r

    local v = Instance.new("TextLabel")
    v.Size = UDim2.fromOffset(38, 16)
    v.Position = UDim2.new(1, -46, 0, 5)
    v.BackgroundTransparency = 1
    v.Font = Enum.Font.GothamBold
    v.TextSize = 11
    v.TextColor3 = ACCENT
    v.TextXAlignment = Enum.TextXAlignment.Right
    v.Text = tostring(default)
    v.Parent = r

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 4)
    bar.Position = UDim2.fromOffset(10, 27)
    bar.BackgroundColor3 = Color3.fromRGB(45, 45, 54)
    bar.BorderSizePixel = 0
    bar.Parent = r
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale((default - min) / (max - min), 1)
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local drag = false
    local function setX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel + 0.5)
        v.Text = tostring(val)
        fill.Size = UDim2.fromScale(rel, 1)
        pcall(cb, val)
    end
    track(bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = true
            setX(i.Position.X)
        end
    end))
    track(UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setX(i.Position.X)
        end
    end))
    track(UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end))
end

local function setOpen(force)
    if not panel then return end
    open = force ~= nil and force or not open
    if open then
        panel.Visible = true
        panel.BackgroundTransparency = 1
        tw(panel, 0.2, { BackgroundTransparency = 0.05 })
    else
        tw(panel, 0.15, { BackgroundTransparency = 1 })
        task.delay(0.16, function() if not open and panel then panel.Visible = false end end)
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
    if not stealthGui(gui) then gui.Parent = LP:WaitForChild("PlayerGui") end

    panel = Instance.new("Frame")
    panel.Position = UDim2.fromOffset(20, 90)
    panel.Size = UDim2.fromOffset(206, 384)
    panel.BackgroundColor3 = BG
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
    local st = Instance.new("UIStroke", panel)
    st.Color = STROKE
    st.Transparency = 0.3

    local head = Instance.new("Frame")
    head.Size = UDim2.new(1, 0, 0, 32)
    head.BackgroundTransparency = 1
    head.Parent = panel

    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(6, 6)
    dot.Position = UDim2.fromOffset(13, 13)
    dot.BackgroundColor3 = ACCENT
    dot.BorderSizePixel = 0
    dot.Parent = head
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -34, 0, 13)
    title.Position = UDim2.fromOffset(25, 9)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 11
    title.TextColor3 = TEXT
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "VENICE · COSMETICS"
    title.Parent = head

    local body = Instance.new("ScrollingFrame")
    body.Size = UDim2.new(1, -8, 1, -40)
    body.Position = UDim2.fromOffset(4, 34)
    body.BackgroundTransparency = 1
    body.BorderSizePixel = 0
    body.ScrollBarThickness = 2
    body.ScrollBarImageColor3 = ACCENT
    body.CanvasSize = UDim2.new()
    body.AutomaticCanvasSize = Enum.AutomaticSize.Y
    body.Parent = panel
    local lay = Instance.new("UIListLayout", body)
    lay.Padding = UDim.new(0, 5)

    local savedPanel = panel
    panel = body

    section("ВНЕШКА")
    row("Headless", CONFIG.headless, function(v)
        CONFIG.headless = v
        pcall(applyHeadless, v)
    end)
    row("Korblox", CONFIG.korblox, function(v)
        CONFIG.korblox = v
        pcall(applyKorblox, v)
    end)
    row("Жёсткая фиксация", CONFIG.force, function(v)
        CONFIG.force = v
        enforce()
    end, 26)

    section("FPS")
    row("FPS Boost", FPS.boost, function(v)
        FPS.boost = v
        if v then FPS.shadowsOff, FPS.fxOff, FPS.partsOff = true, true, true end
        syncFps()
    end)
    row("Тени off", FPS.shadowsOff, function(v)
        FPS.shadowsOff = v
        setShadows(FPS.boost and v)
    end, 26)
    row("Эффекты off", FPS.fxOff, function(v)
        FPS.fxOff = v
        setPostFx(FPS.boost and v)
    end, 26)
    row("Частицы off", FPS.partsOff, function(v)
        FPS.partsOff = v
        setParticles(FPS.boost and v)
    end, 26)
    slider("Лимит FPS", 30, 360, FPS.cap, function(v)
        FPS.cap = v
        setCap(v)
    end)

    section("ПРОЧЕЕ")
    button("Переприменить", function()
        enforce()
    end)
    button("Диагностика", function()
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        print("[Venice] риг:", hum and hum.RigType.Name or "нет")
        print("[Venice] CreateMeshPartAsync:", meshCache and "ок" or "недоступен")
        print("[Venice] аксессуаров на голове:", char and #headAccessories(char, char:FindFirstChild("Head")) or 0)
        if char then
            for _, d in ipairs(char:GetChildren()) do
                if d:IsA("BasePart") then print("  ", d.Name, d.Size, d.Transparency) end
            end
        end
    end)
    button("Убрать всё", function()
        CONFIG.headless, CONFIG.korblox, CONFIG.force = false, false, false
        FPS.boost, FPS.shadowsOff, FPS.fxOff, FPS.partsOff = false, false, false, false
        syncFps()
        pcall(applyHeadless, false)
        pcall(clearKorblox)
    end)

    panel = savedPanel

    local drag, ds, sp
    head.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag, ds, sp = true, i.Position, panel.Position
        end
    end)
    track(UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            panel.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end))
    track(UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end))

    print("[Venice] v4 · H голова · K коробокс · F буст · Z меню")
end

build()

track(UIS.InputBegan:Connect(function(i, gp)
    if gp or UIS:GetFocusedTextBox() then return end
    if i.KeyCode == Enum.KeyCode.H then
        CONFIG.headless = not CONFIG.headless
        pcall(applyHeadless, CONFIG.headless)
    elseif i.KeyCode == Enum.KeyCode.K then
        CONFIG.korblox = not CONFIG.korblox
        pcall(applyKorblox, CONFIG.korblox)
    elseif i.KeyCode == Enum.KeyCode.F then
        FPS.boost = not FPS.boost
        if FPS.boost then FPS.shadowsOff, FPS.fxOff, FPS.partsOff = true, true, true end
        syncFps()
    elseif i.KeyCode == Enum.KeyCode.Z then
        setOpen()
    end
end))

task.wait(1.2)
enforce()

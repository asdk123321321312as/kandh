--[[ Venice · Korblox + Headless + FPS + FOV + Sky · v6 universal
     H — голова, K — коробокс, F — буст, Z — меню
     v6: RenderStep-фиксация, weld-фолбэк R6, перехват подмены головы, FOV, небо ]]

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
local WS       = ref(workspace)
local LP       = Players.LocalPlayer
while not LP do task.wait() end

local function track(c) table.insert(getgenv().VeniceCosConns, c) return c end

local CONFIG = { korblox = true, headless = true, force = true }
local FPS = { boost = false, shadowsOff = false, fxOff = false, partsOff = false, cap = 240 }

local MESH = "rbxassetid://101851696"
local TEX  = "rbxassetid://101851254"

local ACCENT = Color3.fromRGB(152, 132, 255)
local BG     = Color3.fromRGB(9, 9, 11)
local ROW    = Color3.fromRGB(23, 23, 28)
local OFF    = Color3.fromRGB(45, 45, 54)
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

local function headParts(char)
    local head = char:FindFirstChild("Head")
    if not head then return {}, nil end
    if head:IsA("BasePart") then return { head }, head end
    local out = {}
    for _, d in ipairs(head:GetDescendants()) do
        if d:IsA("BasePart") then table.insert(out, d) end
    end
    return out, head
end

local function headAccessories(char, parts)
    local set = {}
    for _, p in ipairs(parts) do set[p] = true end
    local out = {}
    for _, d in ipairs(char:GetChildren()) do
        if d:IsA("Accessory") or d:IsA("Hat") then
            local w = d:FindFirstChildWhichIsA("Weld", true)
            if w and (set[w.Part0] or set[w.Part1]) then
                table.insert(out, d)
            end
        end
    end
    return out
end

local function applyHeadless(on)
    local char = LP.Character
    if not char then return end
    local parts = headParts(char)
    if #parts == 0 then return end

    for _, p in ipairs(parts) do
        setHidden(p, on)
        for _, d in ipairs(p:GetDescendants()) do
            if d:IsA("Decal") then setHidden(d, on) end
        end
    end
    for _, acc in ipairs(headAccessories(char, parts)) do
        for _, d in ipairs(acc:GetDescendants()) do
            if d:IsA("BasePart") or d:IsA("Decal") then setHidden(d, on) end
        end
    end
end

-- ============================== коробокс ==============================

local meshCache = nil
local savedCharMesh = nil
local weldMode = false
local cmMisses = 0

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

local function buildKorbloxLeg(char, upper, lower, foot)
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
    local len = math.clamp(delta.Magnitude, 0.5, 9)
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

local function applyKorblox(on)
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if not on then clearKorblox() return end
    if korbloxOk(char) then return end

    if hum.RigType == Enum.HumanoidRigType.R6 and not weldMode then
        local stale = char:FindFirstChild("VeniceKorbloxLeg")
        if stale then pcall(function() stale:Destroy() end) end
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
    buildKorbloxLeg(char, upper, lower, foot)
end

-- ============================== fov ==============================

local fovTarget = 70

local function applyFov()
    local cam = WS.CurrentCamera
    if not cam then return end
    if math.abs(cam.FieldOfView - fovTarget) > 0.2 then
        pcall(function() cam.FieldOfView = fovTarget end)
    end
end

track(WS:GetPropertyChangedSignal("CurrentCamera"):Connect(applyFov))

-- ============================== небо ==============================

local NIGHT = {
    Bk = "rbxassetid://159454299", Dn = "rbxassetid://159454296",
    Ft = "rbxassetid://159454293", Lf = "rbxassetid://159454290",
    Rt = "rbxassetid://159454287", Up = "rbxassetid://159454284",
}

local SKY = { mode = "off", stars = 800, fog = 600, clock = 1, tint = Color3.fromRGB(0, 0, 0) }
local skySaved = nil
local ourSky = nil

local function saveLighting()
    if skySaved then return end
    skySaved = {
        sky = Lighting:FindFirstChildOfClass("Sky"),
        ambient = Lighting.Ambient,
        outdoor = Lighting.OutdoorAmbient,
        brightness = Lighting.Brightness,
        fogColor = Lighting.FogColor,
        fogStart = Lighting.FogStart,
        fogEnd = Lighting.FogEnd,
        clock = Lighting.ClockTime,
    }
end

local function restoreLighting()
    if ourSky then pcall(function() ourSky:Destroy() end) ourSky = nil end
    if not skySaved then return end
    local s = skySaved
    skySaved = nil
    if s.sky and s.sky.Parent == nil then pcall(function() s.sky.Parent = Lighting end) end
    pcall(function()
        Lighting.Ambient = s.ambient
        Lighting.OutdoorAmbient = s.outdoor
        Lighting.Brightness = s.brightness
        Lighting.FogColor = s.fogColor
        Lighting.FogStart = s.fogStart
        Lighting.FogEnd = s.fogEnd
        Lighting.ClockTime = s.clock
    end)
end

local function applySky(mode)
    SKY.mode = mode
    if mode == "off" then
        restoreLighting()
        return
    end

    saveLighting()
    if ourSky then pcall(function() ourSky:Destroy() end) ourSky = nil end

    local gameSky = Lighting:FindFirstChildOfClass("Sky")
    if gameSky and gameSky ~= skySaved.sky then pcall(function() gameSky.Parent = nil end) end
    if skySaved.sky then pcall(function() skySaved.sky.Parent = nil end) end

    if mode == "void" then
        Lighting.Ambient = Color3.new(0, 0, 0)
        Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
        Lighting.Brightness = 0.6
        Lighting.FogColor = SKY.tint
        Lighting.FogStart = 0
        Lighting.FogEnd = SKY.fog
        Lighting.ClockTime = SKY.clock
        return
    end

    ourSky = Instance.new("Sky")
    ourSky.SkyboxBk = NIGHT.Bk
    ourSky.SkyboxDn = NIGHT.Dn
    ourSky.SkyboxFt = NIGHT.Ft
    ourSky.SkyboxLf = NIGHT.Lf
    ourSky.SkyboxRt = NIGHT.Rt
    ourSky.SkyboxUp = NIGHT.Up
    ourSky.StarCount = SKY.stars
    ourSky.CelestialBodiesShown = true
    ourSky.SunAngularSize = 11
    ourSky.MoonAngularSize = 14
    ourSky.Parent = Lighting

    Lighting.ClockTime = mode == "space" and 0 or SKY.clock
    Lighting.Ambient = mode == "space" and Color3.new(0, 0, 0) or skySaved.ambient
    Lighting.OutdoorAmbient = mode == "space" and Color3.fromRGB(20, 20, 30) or skySaved.outdoor
    Lighting.FogColor = SKY.tint
    Lighting.FogStart = 0
    Lighting.FogEnd = SKY.fog
end

local function syncSky()
    if SKY.mode == "off" then return end
    if SKY.mode == "void" then
        if ourSky then pcall(function() ourSky:Destroy() end) ourSky = nil end
        local s = Lighting:FindFirstChildOfClass("Sky")
        if s and s ~= skySaved.sky then pcall(function() s.Parent = nil end) end
        if Lighting.FogEnd ~= SKY.fog then Lighting.FogEnd = SKY.fog end
        if Lighting.FogColor ~= SKY.tint then Lighting.FogColor = SKY.tint end
        return
    end
    local s = ourSky
    if not s or not s.Parent then
        applySky(SKY.mode)
        return
    end
    if s.StarCount ~= SKY.stars then s.StarCount = SKY.stars end
    if Lighting.FogEnd ~= SKY.fog then Lighting.FogEnd = SKY.fog end
    if Lighting.FogColor ~= SKY.tint then Lighting.FogColor = SKY.tint end
end

-- ============================== фиксация ==============================

local function enforce()
    local char = LP.Character
    if not char then return end

    if CONFIG.headless then pcall(applyHeadless, true) end

    if CONFIG.korblox then
        if not korbloxOk(char) then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.RigType == Enum.HumanoidRigType.R6 and not char:FindFirstChild("VeniceKorblox") then
                cmMisses = cmMisses + 1
                if cmMisses >= 5 then weldMode = true end
            end
        end
        pcall(applyKorblox, true)
    end

    pcall(applyFov)
    pcall(syncSky)
end

local acc = 0
local BOUND = false
pcall(function()
    RunS:BindToRenderStep("VeniceEnforce", Enum.RenderPriority.Last.Value - 1, function(dt)
        if CONFIG.force then
            enforce()
        else
            acc = acc + dt
            if acc >= 0.1 then
                acc = 0
                enforce()
            end
        end
    end)
    BOUND = true
end)

if not BOUND then
    track(RunS.Heartbeat:Connect(function(dt)
        acc = acc + dt
        if acc >= 0.1 then acc = 0 enforce() end
    end))
end

local function watchHead(char)
    local parts, head = headParts(char)
    for _, p in ipairs(parts) do
        track(p:GetPropertyChangedSignal("Transparency"):Connect(function()
            if CONFIG.headless and p.Transparency ~= 1 then p.Transparency = 1 end
        end))
    end
    if head and head:IsA("Model") then
        track(head.DescendantAdded:Connect(function(d)
            if CONFIG.headless and (d:IsA("BasePart") or d:IsA("Decal")) then setHidden(d, true) end
        end))
    end
end

local function watchChar(char)
    table.clear(hiddenOrig)
    meshCache = nil
    savedCharMesh = nil
    cmMisses = 0
    enforce()
    task.delay(0.25, enforce)
    task.delay(0.8, enforce)
    task.delay(1.6, enforce)

    track(char.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") or d:IsA("Accessory") or d:IsA("Hat") or d:IsA("Decal") or d:IsA("CharacterMesh") then
            task.defer(enforce)
            if d.Name == "Head" then task.defer(watchHead, char) end
        end
    end))
    track(char.AncestryChanged:Connect(function() task.defer(enforce) end))

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        track(hum.ChildAdded:Connect(function() task.defer(enforce) end))
        track(hum:GetPropertyChangedSignal("RigType"):Connect(function() task.defer(enforce) end))
    end

    task.spawn(function()
        local head = char:FindFirstChild("Head") or char:WaitForChild("Head", 5)
        if head then watchHead(char) end
    end)
end

if LP.Character then watchChar(LP.Character) end
track(LP.CharacterAdded:Connect(watchChar))
track(LP.CharacterAppearanceLoaded:Connect(enforce))

-- ============================== fps ==============================

local saved = {}
local killedFx = {}
local killedParts = {}

local function killAll(classList, store)
    local n = 0
    for _, d in ipairs(WS:GetDescendants()) do
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
            local t = WS:FindFirstChildOfClass("Terrain")
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
            local t = WS:FindFirstChildOfClass("Terrain")
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
    t.BackgroundColor3 = default and ACCENT or OFF
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
    local function paint(v)
        t.BackgroundColor3 = v and ACCENT or OFF
        k.Position = v and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3)
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = r
    btn.MouseButton1Click:Connect(function()
        state = not state
        paint(state)
        task.spawn(function() pcall(cb, state) end)
    end)

    return function(v)
        state = v
        paint(v)
        task.spawn(function() pcall(cb, v) end)
    end
end

local function button(text, cb, highlight)
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
    l.TextColor3 = highlight and ACCENT or TEXT
    l.Text = text
    l.Parent = r

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = r
    btn.MouseButton1Click:Connect(function()
        tw(l, 0.1, { TextColor3 = OKC })
        task.delay(0.25, function() tw(l, 0.2, { TextColor3 = highlight and ACCENT or TEXT }) end)
        task.spawn(function() pcall(cb) end)
    end)
    return l
end

local function slider(text, min, max, default, cb, step)
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
    v.Size = UDim2.fromOffset(44, 16)
    v.Position = UDim2.new(1, -52, 0, 5)
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
    bar.BackgroundColor3 = OFF
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
        local raw = min + (max - min) * rel
        local val = step and (math.floor(raw / step + 0.5) * step) or math.floor(raw + 0.5)
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

local setHeadless, setKorblox, setForce, setBoost

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
    panel.Position = UDim2.fromOffset(20, 70)
    panel.Size = UDim2.fromOffset(210, 430)
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
    setHeadless = row("Headless", CONFIG.headless, function(v)
        CONFIG.headless = v
        pcall(applyHeadless, v)
    end)
    setKorblox = row("Korblox", CONFIG.korblox, function(v)
        CONFIG.korblox = v
        pcall(applyKorblox, v)
    end)
    setForce = row("Жёсткая фиксация", CONFIG.force, function(v)
        CONFIG.force = v
        enforce()
    end, 26)

    section("КАМЕРА")
    slider("FOV", 40, 120, fovTarget, function(v)
        fovTarget = v
        applyFov()
    end, 1)

    section("НЕБО")
    button("Ночь", function() applySky("night") end)
    button("Космос", function() applySky("space") end)
    button("Пустота", function() applySky("void") end)
    button("Небо выкл", function() applySky("off") end)
    slider("Звёзды", 0, 3000, SKY.stars, function(v)
        SKY.stars = v
        syncSky()
    end, 50)
    slider("Туман", 50, 5000, SKY.fog, function(v)
        SKY.fog = v
        syncSky()
    end, 50)
    slider("Время", 0, 24, SKY.clock, function(v)
        SKY.clock = v
        if SKY.mode ~= "off" then applySky(SKY.mode) end
    end, 1)
    button("Фон: чёрный", function() SKY.tint = Color3.fromRGB(0, 0, 0) syncSky() end)
    button("Фон: синий", function() SKY.tint = Color3.fromRGB(10, 14, 40) syncSky() end)
    button("Фон: серый", function() SKY.tint = Color3.fromRGB(60, 62, 70) syncSky() end)

    section("FPS")
    setBoost = row("FPS Boost", FPS.boost, function(v)
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
    end, 5)

    section("ПРОЧЕЕ")
    button("Переприменить", function()
        CONFIG.headless, CONFIG.korblox, CONFIG.force = true, true, true
        if setHeadless then setHeadless(true) end
        if setKorblox then setKorblox(true) end
        if setForce then setForce(true) end

        if LP.Character then pcall(clearKorblox) end
        table.clear(hiddenOrig)
        syncFps()
        if SKY.mode ~= "off" then pcall(applySky, SKY.mode) end

        for _ = 1, 6 do
            task.wait(0.15)
            enforce()
        end
        print("[Venice] переприменено")
    end, true)
    button("Диагностика", function()
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        print("[Venice] риг:", hum and hum.RigType.Name or "нет")
        print("[Venice] weld-режим:", tostring(weldMode))
        print("[Venice] CreateMeshPartAsync:", meshCache and "ок" or "недоступен")
        local parts = char and headParts(char) or {}
        print("[Venice] частей головы:", #parts)
        print("[Venice] аксессуаров на голове:", char and #headAccessories(char, parts) or 0)
        print("[Venice] FOV:", tostring(fovTarget), "небо:", SKY.mode)
        if char then
            for _, d in ipairs(char:GetChildren()) do
                if d:IsA("BasePart") then print("  ", d.Name, d.Size, d.Transparency) end
            end
        end
    end)
    button("Убрать всё", function()
        CONFIG.headless, CONFIG.korblox, CONFIG.force = false, false, false
        FPS.boost, FPS.shadowsOff, FPS.fxOff, FPS.partsOff = false, false, false, false
        if setHeadless then setHeadless(false) end
        if setKorblox then setKorblox(false) end
        if setForce then setForce(false) end
        if setBoost then setBoost(false) end
        syncFps()
        pcall(applyHeadless, false)
        pcall(clearKorblox)
        pcall(applySky, "off")
        fovTarget = 70
        pcall(applyFov)
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

    gui.Destroying:Connect(function()
        pcall(function() RunS:UnbindFromRenderStep("VeniceEnforce") end)
    end)

    print("[Venice] v6 · H голова · K коробокс · F буст · Z меню")
end

build()

track(UIS.InputBegan:Connect(function(i, gp)
    if gp or UIS:GetFocusedTextBox() then return end
    if i.KeyCode == Enum.KeyCode.H then
        CONFIG.headless = not CONFIG.headless
        if setHeadless then setHeadless(CONFIG.headless) end
        pcall(applyHeadless, CONFIG.headless)
    elseif i.KeyCode == Enum.KeyCode.K then
        CONFIG.korblox = not CONFIG.korblox
        if setKorblox then setKorblox(CONFIG.korblox) end
        pcall(applyKorblox, CONFIG.korblox)
    elseif i.KeyCode == Enum.KeyCode.F then
        FPS.boost = not FPS.boost
        if FPS.boost then FPS.shadowsOff, FPS.fxOff, FPS.partsOff = true, true, true end
        if setBoost then setBoost(FPS.boost) end
        syncFps()
    elseif i.KeyCode == Enum.KeyCode.Z then
        setOpen()
    end
end))

task.wait(1.2)
enforce()

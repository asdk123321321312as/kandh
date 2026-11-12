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
local CAS      = ref(game:GetService("ContextActionService"))
local WS       = ref(workspace)
local LP       = Players.LocalPlayer
while not LP do task.wait() end

local function track(c) table.insert(getgenv().VeniceCosConns, c) return c end

local CONFIG = { korblox = true, headless = true, force = true, infJump = false, jumpLimit = -1 }
local FPS = { boost = false, shadowsOff = false, fxOff = false, partsOff = false, cap = 240 }
local AURA = { on = false, size = 1, speed = 1, hue = 0, mode = "rainbow", color = Color3.fromRGB(152, 132, 255), style = "both" }

local ACCS = {
    { id = 132809431,  name = "Doomsekkar" },
    { id = 74891470,   name = "Frozen Horns" },
    { id = 215718515,  name = "Fiery Horns" },
    { id = 1744060292, name = "Poisoned Horns" },
}
local accCurrent = 0
local accOffsetY = 0

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

-- ============================== поиск целей ==============================

local scanCache = {}
local scanAt = 0

local function addModel(list, seen, m)
    if not m or seen[m] then return end
    if not m:IsA("Model") then return end
    if not m:FindFirstChildOfClass("Humanoid") then return end
    if not m:FindFirstChild("Head") then return end
    seen[m] = true
    table.insert(list, m)
end

local function scanName(list, seen, name)
    if not name or name == "" then return end
    for _, m in ipairs(WS:GetChildren()) do
        if m.Name == name then
            addModel(list, seen, m)
        elseif m:IsA("Folder") or m:IsA("Model") then
            for _, c in ipairs(m:GetChildren()) do
                if c.Name == name then addModel(list, seen, c) end
            end
        end
    end
end

local function refreshScan()
    scanAt = os.clock()
    local list, seen = {}, {}
    scanName(list, seen, LP.Name)
    if LP.DisplayName ~= LP.Name then scanName(list, seen, LP.DisplayName) end
    scanCache = list
end

local function targets()
    if os.clock() - scanAt > 0.3 then refreshScan() end
    local list, seen = {}, {}
    addModel(list, seen, LP.Character)
    local cam = WS.CurrentCamera
    if cam then
        local subj = cam.CameraSubject
        if subj then addModel(list, seen, subj.Parent) end
    end
    for _, m in ipairs(scanCache) do addModel(list, seen, m) end
    return list
end

-- ============================== откат свойств ==============================

local hidingNow = false
local hooked = setmetatable({}, { __mode = "k" })
local ATTR = "VeniceOrigT"

local function hookPart(p)
    if hooked[p] then return end
    hooked[p] = true
    track(p:GetPropertyChangedSignal("Transparency"):Connect(function()
        if hidingNow then return end
        if CONFIG.headless and p.Transparency ~= 1 then
            hidingNow = true
            pcall(function() p.Transparency = 1 end)
            hidingNow = false
        end
    end))
end

local function setHidden(inst, on)
    if not inst then return end
    if on then
        if inst:GetAttribute(ATTR) == nil then
            pcall(function() inst:SetAttribute(ATTR, inst.Transparency) end)
        end
        if inst.Transparency ~= 1 then
            hidingNow = true
            pcall(function() inst.Transparency = 1 end)
            hidingNow = false
        end
    else
        local o = inst:GetAttribute(ATTR)
        if o == nil then o = 0 end
        hidingNow = true
        pcall(function() inst.Transparency = o end)
        hidingNow = false
        pcall(function() inst:SetAttribute(ATTR, nil) end)
    end
end

-- ============================== голова ==============================

local function headParts(char)
    local head = char:FindFirstChild("Head")
    if not head then return {} end
    if head:IsA("BasePart") then return { head } end
    local out = {}
    for _, d in ipairs(head:GetDescendants()) do
        if d:IsA("BasePart") then table.insert(out, d) end
    end
    return out
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

local function applyHeadless(char, on)
    if not char then return end
    local parts = headParts(char)
    if #parts == 0 then return end

    for _, p in ipairs(parts) do
        hookPart(p)
        setHidden(p, on)
        for _, d in ipairs(p:GetDescendants()) do
            if d:IsA("Decal") then setHidden(d, on) end
        end
    end
    for _, acc in ipairs(headAccessories(char, parts)) do
        if not acc:GetAttribute("VeniceHat") then
            for _, d in ipairs(acc:GetDescendants()) do
                if d:IsA("BasePart") or d:IsA("Decal") then
                    if d:IsA("BasePart") then hookPart(d) end
                    setHidden(d, on)
                end
            end
        end
    end
end

-- ============================== папка частей ==============================

local partsFolder = nil

local function getFolder()
    if partsFolder and partsFolder.Parent then return partsFolder end
    local f = WS:FindFirstChild("VeniceCosParts")
    if not f then
        f = Instance.new("Folder")
        f.Name = "VeniceCosParts"
        f.Archivable = false
        f.Parent = WS
    end
    partsFolder = f
    return f
end

-- ============================== свой персонаж ==============================

local function myChar()
    local c = LP.Character
    if c and c:FindFirstChild("Head") then return c end
    if os.clock() - scanAt > 0.3 then refreshScan() end
    for _, m in ipairs(scanCache) do
        if m.Parent and m:FindFirstChild("Head") then return m end
    end
    local cam = WS.CurrentCamera
    local subj = cam and cam.CameraSubject
    if subj and subj.Parent and subj.Parent:FindFirstChild("Head") then return subj.Parent end
    return nil
end

-- ============================== аксессуары ==============================

local ACC_ATTR = "VeniceHatPart"
local accBusy = false
local accAt = 0
local accLast = "не запускалось"
local accTimer = nil

local function accParts()
    local out = {}
    if not partsFolder then return out end
    for _, p in ipairs(partsFolder:GetChildren()) do
        if p:GetAttribute(ACC_ATTR) then table.insert(out, p) end
    end
    return out
end

local function hasAcc() return #accParts() > 0 end

local function clearAcc()
    for _, p in ipairs(accParts()) do pcall(function() p:Destroy() end) end
end

local function grab(container)
    for _, o in ipairs(container) do
        if o:IsA("Accessory") or o:IsA("Hat") then return o end
        for _, d in ipairs(o:GetDescendants()) do
            if d:IsA("Accessory") or d:IsA("Hat") then return d end
        end
    end
    for _, o in ipairs(container) do
        if o:IsA("BasePart") then return o end
        for _, d in ipairs(o:GetDescendants()) do
            if d:IsA("BasePart") then return d end
        end
    end
end

local function loadAcc(id)
    local errs = {}

    local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
    if ok and objs and #objs > 0 then
        local g = grab(objs)
        if g then return g end
        table.insert(errs, "GetObjects без частей")
    else
        table.insert(errs, "GetObjects " .. tostring(objs))
    end

    local ok2, model = pcall(function() return game:GetService("InsertService"):LoadAsset(id) end)
    if ok2 and model then
        local g = grab(model:GetChildren())
        if g then return g end
        table.insert(errs, "LoadAsset без частей")
    else
        table.insert(errs, "LoadAsset " .. tostring(model))
    end

    return nil, table.concat(errs, " | ")
end

local function applyAcc(id)
    if accBusy then return end
    local char = myChar()
    local head = char and char:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then
        accLast = "нет головы | Character=" .. tostring(LP.Character)
        return
    end
    if hasAcc() then return end
    accBusy = true

    local ok, res = pcall(function()
        local found, why = loadAcc(id)
        if not found then error("ассет: " .. tostring(why)) end

        local handle
        if found:IsA("Accessory") or found:IsA("Hat") then
            handle = found:FindFirstChild("Handle") or found:FindFirstChildWhichIsA("BasePart", true)
        elseif found:IsA("BasePart") then
            handle = found
        else
            handle = found:FindFirstChildWhichIsA("BasePart", true)
        end
        if not handle then error("в ассете нет Handle") end

        handle.Name = "VeniceHatHandle"
        handle:SetAttribute(ACC_ATTR, true)
        handle.Anchored = false
        handle.CanCollide = false
        handle.CanQuery = false
        handle.CanTouch = false
        handle.CastShadow = true
        handle.Transparency = 0
        pcall(function() handle.Massless = true end)
        handle.Parent = getFolder()

        handle.LocalTransparencyModifier = 0
        local biggest = math.max(handle.Size.X, handle.Size.Y, handle.Size.Z)
        if biggest < 0.25 then
            handle.Size = handle.Size * (0.6 / math.max(biggest, 0.01))
        end

        local att = handle:FindFirstChildWhichIsA("Attachment")
        if att then
            handle.CFrame = head.CFrame * CFrame.new(0, head.Size.Y / 2 + accOffsetY, 0) * att.CFrame:Inverse()
        else
            local lift = head.Size.Y / 2 + handle.Size.Y / 2 * 0.5 + accOffsetY
            handle.CFrame = head.CFrame * CFrame.new(0, lift, 0)
        end

        local w = Instance.new("WeldConstraint")
        w.Part0 = handle
        w.Part1 = head
        w.Parent = handle
        return "приварено (папка)"
    end)

    accBusy = false
    accLast = ok and res or ("ошибка: " .. tostring(res))
end

local function setAcc(id)
    accCurrent = id
    pcall(clearAcc)
    accAt = 0
    if id ~= 0 then
        task.spawn(function() pcall(applyAcc, id) end)
    else
        accLast = "снято"
    end
end

local function reAcc()
    if accTimer then pcall(function() task.cancel(accTimer) end) end
    accTimer = task.delay(0.2, function()
        accTimer = nil
        pcall(clearAcc)
        accAt = 0
        if accCurrent ~= 0 then task.spawn(function() pcall(applyAcc, accCurrent) end) end
    end)
end

-- ============================== коробокс ==============================

local meshCache = nil
local savedCharMesh = {}
local charMode = setmetatable({}, { __mode = "k" })
local cmTries  = setmetatable({}, { __mode = "k" })
local weldMode = false

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

local function findKorbloxPart(char)
    if not partsFolder or not partsFolder.Parent then return nil end
    for _, p in ipairs(partsFolder:GetChildren()) do
        if p:IsA("BasePart") and p.Name == "VeniceKorbloxLeg" then
            local w = p:FindFirstChildWhichIsA("WeldConstraint")
            if w and w.Part1 and w.Part1:IsDescendantOf(char) then return p end
        end
    end
end

local function korbloxOk(char)
    if char:FindFirstChild("VeniceKorblox") then return true end
    return findKorbloxPart(char) ~= nil
end

local function clearKorblox(char)
    if not char then return end
    local cm = char:FindFirstChild("VeniceKorblox")
    if cm then pcall(function() cm:Destroy() end) end
    local p = findKorbloxPart(char)
    if p then pcall(function() p:Destroy() end) end
    local upper, lower, foot = findLegParts(char)
    setHidden(upper, false)
    setHidden(lower, false)
    setHidden(foot, false)
    local s = savedCharMesh[char]
    if s then
        local m = Instance.new("CharacterMesh")
        m.Name = "VeniceKorbloxRestore"
        m.BodyPart = Enum.BodyPart.RightLeg
        m.MeshId = s.mesh
        m.OverlayTextureId = s.tex
        m.Parent = char
        savedCharMesh[char] = nil
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
    local w = math.clamp(math.max(upper.Size.X, upper.Size.Z) * 1.05, 0.3, 1.2)

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
    part.Parent = getFolder()

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = part
    weld.Part1 = upper
    weld.Parent = part

    setHidden(upper, true)
    setHidden(lower, true)
    setHidden(foot, true)
end

local function applyKorblox(char, on)
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if not on then
        clearKorblox(char)
        charMode[char] = nil
        cmTries[char] = nil
        return
    end
    if korbloxOk(char) then return end

    if hum.RigType == Enum.HumanoidRigType.R6 and charMode[char] ~= "weld" then
        cmTries[char] = (cmTries[char] or 0) + 1
        if cmTries[char] > 5 then
            charMode[char] = "weld"
            weldMode = true
        else
            for _, d in ipairs(char:GetChildren()) do
                if d:IsA("CharacterMesh") and d.BodyPart == Enum.BodyPart.RightLeg and d.Name ~= "VeniceKorblox" then
                    savedCharMesh[char] = { mesh = d.MeshId, tex = d.OverlayTextureId }
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
    end

    local upper, lower, foot = findLegParts(char)
    if not upper then return end
    buildKorbloxLeg(char, upper, lower, foot)
end

local function cleanupParts(list)
    if not partsFolder or not partsFolder.Parent then return end
    for _, p in ipairs(partsFolder:GetChildren()) do
        local w = p:FindFirstChildWhichIsA("WeldConstraint")
        local alive = false
        if w then
            for _, c in ipairs(list) do
                if (w.Part0 and w.Part0:IsDescendantOf(c)) or (w.Part1 and w.Part1:IsDescendantOf(c)) then
                    alive = true
                    break
                end
            end
        end
        if not alive then pcall(function() p:Destroy() end) end
    end
    if meshCache and not meshCache.Parent then meshCache = nil end
end

-- ============================== аура ==============================

local auraState = setmetatable({}, { __mode = "k" })

local function rainbow(h) return Color3.fromHSV(h % 1, 1, 1) end

local function rainbowSeq(phase)
    local kp = {}
    for i = 0, 6 do
        local t = i / 6
        table.insert(kp, ColorSequenceKeypoint.new(t, rainbow(phase + t)))
    end
    return ColorSequence.new(kp)
end

local function auraColor(off)
    if AURA.mode == "rainbow" then return rainbow(AURA.hue + (off or 0)) end
    return AURA.color
end

local function auraSeq(off)
    if AURA.mode == "rainbow" then return rainbowSeq(AURA.hue + (off or 0)) end
    return ColorSequence.new(AURA.color)
end

local AURA_COLORS = {
    { name = "Радуга",  mode = "rainbow" },
    { name = "Фиолет",  color = Color3.fromRGB(152, 132, 255) },
    { name = "Красный", color = Color3.fromRGB(255, 60, 60) },
    { name = "Оранж",   color = Color3.fromRGB(255, 140, 40) },
    { name = "Золото",  color = Color3.fromRGB(255, 205, 60) },
    { name = "Лайм",    color = Color3.fromRGB(160, 255, 60) },
    { name = "Матрица", color = Color3.fromRGB(40, 255, 80) },
    { name = "Циан",    color = Color3.fromRGB(70, 230, 255) },
    { name = "Синий",   color = Color3.fromRGB(70, 130, 255) },
    { name = "Розовый", color = Color3.fromRGB(255, 110, 210) },
    { name = "Белый",   color = Color3.fromRGB(255, 255, 255) },
    { name = "Кровь",   color = Color3.fromRGB(170, 20, 20) },
    { name = "Лёд",     color = Color3.fromRGB(170, 225, 255) },
    { name = "Пустота", color = Color3.fromRGB(90, 40, 160) },
    { name = "Огонь",   color = Color3.fromRGB(255, 90, 20) },
    { name = "Токсик",  color = Color3.fromRGB(180, 255, 40) },
}

local AURA_STYLES = {
    { name = "Кольцо", id = "ring" },
    { name = "Туман",  id = "mist" },
    { name = "Оба",    id = "both" },
    { name = "Вихрь",  id = "vortex" },
}

local function clearAura(char)
    local s = auraState[char]
    if not s then return end
    auraState[char] = nil
    for _, o in ipairs(s) do pcall(function() o:Destroy() end) end
end

local function clearAuraAll()
    for c in pairs(auraState) do clearAura(c) end
end

local function makeRing(att, made, inward)
    local e = Instance.new("ParticleEmitter")
    e.Name = inward and "VeniceAuraRingIn" or "VeniceAuraRing"
    e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    e.Shape = Enum.ParticleEmitterShape.Disc
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
    e.ShapeInOut = inward and Enum.ParticleEmitterShapeInOut.Inward or Enum.ParticleEmitterShapeInOut.Outward
    e.ShapePartial = 1
    e.Rate = (inward and 26 or 40) * AURA.size
    e.Lifetime = NumberRange.new(0.6, 1.1)
    e.Speed = NumberRange.new(0.6, 2.2)
    e.Drag = 3
    e.Acceleration = Vector3.new(0, inward and 1.2 or 2.6, 0)
    e.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5 * AURA.size),
        NumberSequenceKeypoint.new(0.35, 0.85 * AURA.size),
        NumberSequenceKeypoint.new(1, 0),
    })
    e.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(1, 1),
    })
    e.LightEmission = 1
    e.LightInfluence = 0
    e.RotSpeed = NumberRange.new(inward and 120 or -120, inward and 240 or 120)
    e.Color = auraSeq(inward and 0.2 or 0)
    e:SetAttribute("VeniceAura", true)
    e.Parent = att
    table.insert(made, e)
end

local function makeMist(att, made)
    local e = Instance.new("ParticleEmitter")
    e.Name = "VeniceAuraMist"
    e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    e.Shape = Enum.ParticleEmitterShape.Sphere
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
    e.Rate = 12 * AURA.size
    e.Lifetime = NumberRange.new(1, 1.8)
    e.Speed = NumberRange.new(0.2, 0.9)
    e.Drag = 4
    e.Acceleration = Vector3.new(0, 1.1, 0)
    e.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.1 * AURA.size),
        NumberSequenceKeypoint.new(1, 0),
    })
    e.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.55),
        NumberSequenceKeypoint.new(1, 1),
    })
    e.LightEmission = 1
    e.LightInfluence = 0
    e.Color = auraSeq(0.3)
    e:SetAttribute("VeniceAura", true)
    e.Parent = att
    table.insert(made, e)
end

local function applyAura(char, on)
    if not char then return end
    if not on then clearAura(char) return end
    if auraState[char] then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = (hum and hum.RootPart) or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart
    if not root then return end

    local made = {}
    local ok = pcall(function()
        local att = Instance.new("Attachment")
        att.Name = "VeniceAuraAtt"
        att.Orientation = Vector3.new(-90, 0, 0)
        att.Parent = root
        table.insert(made, att)

        local st = AURA.style
        if st == "ring" then
            makeRing(att, made, false)
        elseif st == "mist" then
            makeMist(att, made)
        elseif st == "vortex" then
            makeRing(att, made, false)
            makeRing(att, made, true)
        else
            makeRing(att, made, false)
            makeMist(att, made)
        end

        local light = Instance.new("PointLight")
        light.Name = "VeniceAuraLight"
        light.Brightness = 2
        light.Range = 13
        light.Color = auraColor()
        light.Parent = att
        table.insert(made, light)

        local hl = Instance.new("Highlight")
        hl.Name = "VeniceAuraHL"
        hl.Adornee = char
        hl.FillTransparency = 0.72
        hl.OutlineTransparency = 0.25
        hl.DepthMode = Enum.HighlightDepthMode.Occluded
        hl.FillColor = auraColor()
        hl.OutlineColor = auraColor(0.5)
        hl.Parent = char
        table.insert(made, hl)
    end)

    if ok then
        auraState[char] = made
    else
        for _, o in ipairs(made) do pcall(function() o:Destroy() end) end
    end
end

local function refreshAura()
    local list = targets()
    for _, c in ipairs(list) do pcall(clearAura, c) end
    if AURA.on then
        for _, c in ipairs(list) do pcall(applyAura, c, true) end
    end
end

task.spawn(function()
    local step = 0
    while true do
        local dt = task.wait()
        if AURA.on then
            if AURA.mode == "rainbow" then AURA.hue = (AURA.hue + dt * 0.22 * AURA.speed) % 1 end
            step = step + dt
            local rebuild = step > 0.07
            if rebuild then step = 0 end
            for char, s in pairs(auraState) do
                if not char.Parent then
                    clearAura(char)
                else
                    local c = auraColor()
                    for _, o in ipairs(s) do
                        if o:IsA("Highlight") then
                            o.FillColor = c
                            o.OutlineColor = auraColor(0.5)
                        elseif o:IsA("PointLight") then
                            o.Color = c
                        elseif o:IsA("ParticleEmitter") and rebuild then
                            local ph = (o.Name == "VeniceAuraMist") and 0.3 or 0
                            if o.Name == "VeniceAuraRingIn" then ph = 0.2 end
                            o.Color = auraSeq(ph)
                        end
                    end
                end
            end
        end
    end
end)

-- ============================== fov ==============================

local fovTarget = 70
local fovWriting = false

local function applyFov()
    local cam = WS.CurrentCamera
    if not cam then return end
    if math.abs(cam.FieldOfView - fovTarget) > 0.2 then
        fovWriting = true
        pcall(function() cam.FieldOfView = fovTarget end)
        fovWriting = false
    end
end

local function bindCam(cam)
    if not cam then return end
    track(cam:GetPropertyChangedSignal("FieldOfView"):Connect(function()
        if fovWriting then return end
        if math.abs(cam.FieldOfView - fovTarget) > 0.2 then
            fovWriting = true
            pcall(function() cam.FieldOfView = fovTarget end)
            fovWriting = false
        end
    end))
end

bindCam(WS.CurrentCamera)
track(WS:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    bindCam(WS.CurrentCamera)
    applyFov()
end))

-- ============================== прыжок ==============================

local lastJump = 0
local airJumps = 0

local function holdingJump()
    return UIS:IsKeyDown(Enum.KeyCode.Space) or UIS:IsKeyDown(Enum.KeyCode.ButtonA)
end

local function infJump(auto)
    if not CONFIG.infJump then return end
    local now = os.clock()
    if now - lastJump < 0.04 then return end
    if auto and now - lastJump < 0.15 then return end

    local char = LP.Character or myChar()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local root = hum.RootPart
    if not root or root.Anchored then return end

    local grounded = hum.FloorMaterial ~= Enum.Material.Air
    if grounded then
        airJumps = 0
    else
        if CONFIG.jumpLimit >= 0 and airJumps >= CONFIG.jumpLimit then return end
        airJumps = airJumps + 1
    end
    lastJump = now

    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)

    local jp = hum.JumpPower
    if not hum.UseJumpPower then
        jp = math.sqrt(2 * WS.Gravity * hum.JumpHeight)
    end
    if jp and jp > 0 then
        local v = root.AssemblyLinearVelocity
        if v.Y < jp * 0.95 then
            root.AssemblyLinearVelocity = Vector3.new(v.X, jp, v.Z)
        end
    end
end

track(UIS.JumpRequest:Connect(function() pcall(infJump) end))

track(RunS.Stepped:Connect(function()
    if not CONFIG.infJump then return end
    local char = LP.Character or myChar()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if hum.FloorMaterial ~= Enum.Material.Air then
        airJumps = 0
        if CONFIG.jumpLimit == 0 and holdingJump() then pcall(infJump, true) end
    end
end))

-- ============================== небо ==============================

local NIGHT = {
    Bk = "rbxassetid://159454299", Dn = "rbxassetid://159454296",
    Ft = "rbxassetid://159454293", Lf = "rbxassetid://159454290",
    Rt = "rbxassetid://159454287", Up = "rbxassetid://159454284",
}

local CLASSIC = {
    Bk = "rbxasset://textures/sky/sky512_bk.tex", Dn = "rbxasset://textures/sky/sky512_dn.tex",
    Ft = "rbxasset://textures/sky/sky512_ft.tex", Lf = "rbxasset://textures/sky/sky512_lf.tex",
    Rt = "rbxasset://textures/sky/sky512_rt.tex", Up = "rbxasset://textures/sky/sky512_up.tex",
}

local SKY = { mode = "off", stars = 0, fog = 600, clock = 1, tint = Color3.fromRGB(0, 0, 0), ambient = Color3.fromRGB(0, 0, 0), outdoor = Color3.fromRGB(0, 0, 0), brightness = 1 }

local PRESETS = {
    night    = { set = NIGHT,   clock = 1,    stars = 800,  fog = 700,  tint = Color3.fromRGB(0, 0, 0),        ambient = Color3.fromRGB(12, 12, 20),   outdoor = Color3.fromRGB(20, 20, 32),   brightness = 1.0 },
    space    = { set = NIGHT,   clock = 0,    stars = 3000, fog = 6000, tint = Color3.fromRGB(0, 0, 0),        ambient = Color3.fromRGB(0, 0, 0),      outdoor = Color3.fromRGB(10, 10, 18),   brightness = 0.4 },
    sunset   = { set = NIGHT,   clock = 18.2, stars = 150,  fog = 1500, tint = Color3.fromRGB(60, 30, 24),     ambient = Color3.fromRGB(42, 22, 26),   outdoor = Color3.fromRGB(84, 46, 40),   brightness = 1.2 },
    classic  = { set = CLASSIC, clock = 14,   stars = 0,    fog = 6000, tint = Color3.fromRGB(140, 170, 200),  brightness = 2.0 },
    overcast = { set = CLASSIC, clock = 13,   stars = 0,    fog = 800,  tint = Color3.fromRGB(118, 122, 130),  ambient = Color3.fromRGB(70, 72, 78),   outdoor = Color3.fromRGB(92, 94, 100),  brightness = 1.4 },
    dusk     = { set = CLASSIC, clock = 17.6, stars = 60,   fog = 1800, tint = Color3.fromRGB(70, 55, 80),     ambient = Color3.fromRGB(45, 38, 55),   outdoor = Color3.fromRGB(70, 55, 80),   brightness = 1.1 },
    void     = { set = nil,     clock = 1,    stars = 0,    fog = 600,  tint = Color3.fromRGB(0, 0, 0),        ambient = Color3.fromRGB(0, 0, 0),      outdoor = Color3.fromRGB(0, 0, 0),      brightness = 0.6 },
    inferno  = { set = nil,     clock = 17,   stars = 0,    fog = 420,  tint = Color3.fromRGB(72, 14, 8),      ambient = Color3.fromRGB(44, 12, 8),    outdoor = Color3.fromRGB(62, 20, 12),   brightness = 1.2 },
    ice      = { set = nil,     clock = 10,   stars = 0,    fog = 520,  tint = Color3.fromRGB(150, 180, 205),  ambient = Color3.fromRGB(32, 42, 52),   outdoor = Color3.fromRGB(46, 62, 78),   brightness = 1.4 },
    matrix   = { set = nil,     clock = 2,    stars = 0,    fog = 460,  tint = Color3.fromRGB(6, 42, 12),      ambient = Color3.fromRGB(4, 18, 6),     outdoor = Color3.fromRGB(8, 30, 10),    brightness = 0.9 },
    blood    = { set = nil,     clock = 0,    stars = 0,    fog = 340,  tint = Color3.fromRGB(58, 6, 6),       ambient = Color3.fromRGB(30, 4, 4),     outdoor = Color3.fromRGB(44, 8, 8),     brightness = 0.8 },
}

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
    local p = PRESETS[mode]
    SKY.mode = mode
    if not p then
        restoreLighting()
        return
    end

    saveLighting()
    if ourSky then pcall(function() ourSky:Destroy() end) ourSky = nil end

    local gameSky = Lighting:FindFirstChildOfClass("Sky")
    if gameSky and gameSky ~= skySaved.sky then pcall(function() gameSky.Parent = nil end) end
    if skySaved.sky then pcall(function() skySaved.sky.Parent = nil end) end

    SKY.stars = p.stars
    SKY.fog = p.fog
    SKY.clock = p.clock
    SKY.tint = p.tint
    SKY.ambient = p.ambient or skySaved.ambient
    SKY.outdoor = p.outdoor or skySaved.outdoor
    SKY.brightness = p.brightness or skySaved.brightness

    if p.set then
        ourSky = Instance.new("Sky")
        ourSky.SkyboxBk = p.set.Bk
        ourSky.SkyboxDn = p.set.Dn
        ourSky.SkyboxFt = p.set.Ft
        ourSky.SkyboxLf = p.set.Lf
        ourSky.SkyboxRt = p.set.Rt
        ourSky.SkyboxUp = p.set.Up
        ourSky.StarCount = SKY.stars
        ourSky.CelestialBodiesShown = true
        ourSky.SunAngularSize = 11
        ourSky.MoonAngularSize = 14
        ourSky.Parent = Lighting
    end

    Lighting.ClockTime = SKY.clock
    Lighting.Ambient = SKY.ambient
    Lighting.OutdoorAmbient = SKY.outdoor
    Lighting.Brightness = SKY.brightness
    Lighting.FogColor = SKY.tint
    Lighting.FogStart = 0
    Lighting.FogEnd = SKY.fog
end

local function syncSky()
    local p = PRESETS[SKY.mode]
    if not p then return end
    if p.set then
        if not ourSky or not ourSky.Parent then
            applySky(SKY.mode)
            return
        end
        if ourSky.StarCount ~= SKY.stars then ourSky.StarCount = SKY.stars end
    end
    if Lighting.FogEnd ~= SKY.fog then Lighting.FogEnd = SKY.fog end
    if Lighting.FogColor ~= SKY.tint then Lighting.FogColor = SKY.tint end
    if Lighting.Ambient ~= SKY.ambient then Lighting.Ambient = SKY.ambient end
end

track(Lighting.ChildAdded:Connect(function(d)
    if SKY.mode == "off" then return end
    if d:IsA("Sky") and d ~= ourSky then
        task.defer(function()
            if SKY.mode ~= "off" and d.Parent then pcall(function() d.Parent = nil end) end
        end)
    end
end))

-- ============================== fps ==============================

local orig = {}
local killedFx = {}
local killedParts = {}

local function isEmitter(d)
    return d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail")
        or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles")
end

local function isAuraFx(d)
    return d:GetAttribute("VeniceAura") == true
end

local function capture()
    if orig.done then return end
    orig.done = true
    pcall(function() orig.quality = settings().Rendering.QualityLevel end)
    orig.shadows = Lighting.GlobalShadows
    orig.diffuse = Lighting.EnvironmentDiffuseScale
    orig.spec = Lighting.EnvironmentSpecularScale
    local t = WS:FindFirstChildOfClass("Terrain")
    if t then
        orig.wave = t.WaterWaveSize
        orig.refl = t.WaterReflectance
        orig.deco = t.Decoration
    end
end

local function killEmitter(d)
    if isAuraFx(d) then return end
    if not d.Enabled then return end
    d.Enabled = false
    table.insert(killedParts, d)
end

local function killFx(d)
    if not d.Enabled then return end
    d.Enabled = false
    table.insert(killedFx, d)
end

local function setQuality(off)
    if off then
        capture()
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    else
        if not orig.done then return end
        pcall(function() settings().Rendering.QualityLevel = orig.quality or Enum.QualityLevel.Automatic end)
    end
end

local function setShadows(off)
    if off then
        capture()
        Lighting.GlobalShadows = false
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
    else
        if not orig.done then return end
        Lighting.GlobalShadows = orig.shadows ~= false
        Lighting.EnvironmentDiffuseScale = orig.diffuse or 1
        Lighting.EnvironmentSpecularScale = orig.spec or 1
    end
end

local function setPostFx(off)
    if off then
        for _, d in ipairs(Lighting:GetChildren()) do
            if d:IsA("PostEffect") then killFx(d) end
        end
    else
        for _, d in ipairs(killedFx) do
            if d.Parent then pcall(function() d.Enabled = true end) end
        end
        table.clear(killedFx)
    end
end

local function setParticles(off)
    if off then
        capture()
        local n = 0
        for _, d in ipairs(WS:GetDescendants()) do
            if isEmitter(d) and d.Enabled and not isAuraFx(d) then
                d.Enabled = false
                table.insert(killedParts, d)
                n = n + 1
                if n > 6000 then break end
            end
        end
        pcall(function()
            local t = WS:FindFirstChildOfClass("Terrain")
            if t then
                t.WaterWaveSize = 0
                t.WaterReflectance = 0
                t.Decoration = false
            end
        end)
    else
        for _, d in ipairs(killedParts) do
            if d.Parent then pcall(function() d.Enabled = true end) end
        end
        table.clear(killedParts)
        pcall(function()
            local t = WS:FindFirstChildOfClass("Terrain")
            if t then
                if orig.wave ~= nil then t.WaterWaveSize = orig.wave end
                if orig.refl ~= nil then t.WaterReflectance = orig.refl end
                if orig.deco ~= nil then t.Decoration = orig.deco end
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

track(WS.DescendantAdded:Connect(function(d)
    if not FPS.boost then return end
    if FPS.partsOff and isEmitter(d) then
        pcall(killEmitter, d)
    end
end))

track(Lighting.ChildAdded:Connect(function(d)
    if not FPS.boost then return end
    if FPS.fxOff and d:IsA("PostEffect") then
        pcall(killFx, d)
    end
end))

task.spawn(function()
    while true do
        task.wait(2)
        if FPS.boost then
            for _, d in ipairs(killedParts) do
                if d.Parent and d.Enabled then pcall(function() d.Enabled = false end) end
            end
            for _, d in ipairs(killedFx) do
                if d.Parent and d.Enabled then pcall(function() d.Enabled = false end) end
            end
        end
    end
end)

-- ============================== скины других игроков ==============================

local skinBusy = false
local skinCurrent = nil
local skinLast = "не запускалось"
local skinLabels = {}

local function setSkinStatus(t)
    skinLast = t
    for _, l in ipairs(skinLabels) do
        if l.Parent then pcall(function() l.Text = "  " .. t end) end
    end
end

local function clearAccessories(char)
    for _, d in ipairs(char:GetChildren()) do
        if d:IsA("Accessory") or d:IsA("Hat") then pcall(function() d:Destroy() end) end
    end
end

local function copyAppearanceFallback(char, uid)
    local model = Players:GetCharacterAppearanceAsync(uid)
    if not model then error("нет модели аватара") end

    local bc = model:FindFirstChildOfClass("BodyColors")
    if bc then
        local old = char:FindFirstChildOfClass("BodyColors")
        if old then pcall(function() old:Destroy() end) end
        pcall(function() bc:Clone().Parent = char end)
    end

    clearAccessories(char)

    for _, acc in ipairs(model:GetChildren()) do
        if acc:IsA("Accessory") or acc:IsA("Hat") then
            local handle = acc:FindFirstChild("Handle")
            local w = handle and handle:FindFirstChildWhichIsA("Weld")
            local targetName = w and w.Part1 and w.Part1.Name
            local target = targetName and char:FindFirstChild(targetName)
            if target and target:IsA("BasePart") then
                local clone = acc:Clone()
                for _, d in ipairs(clone:GetDescendants()) do
                    if d:IsA("Weld") or d:IsA("Motor6D") then pcall(function() d:Destroy() end) end
                end
                local ch = clone:FindFirstChild("Handle")
                if ch then
                    ch.Anchored = false
                    ch.CanCollide = false
                    pcall(function() ch.Massless = true end)
                    local att = ch:FindFirstChildWhichIsA("Attachment")
                    local tatt = att and target:FindFirstChild(att.Name)
                    if tatt and tatt:IsA("Attachment") then
                        ch.CFrame = tatt.WorldCFrame * att.CFrame:Inverse()
                    else
                        ch.CFrame = target.CFrame
                    end
                    local wc = Instance.new("WeldConstraint")
                    wc.Part0 = ch
                    wc.Part1 = target
                    wc.Parent = ch
                end
                clone.Parent = char
            end
        end
    end
end

local function applySkinUserId(uid, quiet)
    if skinBusy then return false end
    local char = myChar()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then setSkinStatus("нет персонажа") return false end

    skinBusy = true
    local ok, err = pcall(function()
        local desc = Players:GetHumanoidDescriptionFromUserId(uid)
        if not desc then error("нет описания") end
        hum:ApplyDescription(desc)
    end)
    if not ok then
        ok, err = pcall(copyAppearanceFallback, char, uid)
    end
    skinBusy = false

    if ok then
        skinCurrent = uid
        local nm = ""
        pcall(function() nm = Players:GetNameFromUserIdAsync(uid) end)
        setSkinStatus("надет скин " .. (nm ~= "" and nm or tostring(uid)))
        task.defer(enforce)
        task.delay(0.3, enforce)
        task.delay(0.9, enforce)
        task.delay(1.8, enforce)
        return true
    end
    setSkinStatus("ошибка: " .. tostring(err))
    return false
end

local function resolveUser(name)
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil, "пустое имя" end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == name:lower() or p.DisplayName:lower() == name:lower() then
            return p.UserId, p.Name
        end
    end
    local ok, id = pcall(function() return Players:GetUserIdFromNameAsync(name) end)
    if ok and id then return id, name end
    return nil, "игрок не найден"
end

local function copySkin(name)
    task.spawn(function()
        local uid, uname = resolveUser(name)
        if not uid then
            setSkinStatus(tostring(uname))
            return
        end
        setSkinStatus("загрузка " .. tostring(uname))
        applySkinUserId(uid)
    end)
end

local function removeSkin()
    skinCurrent = nil
    applySkinUserId(LP.UserId)
    setSkinStatus("свой скин")
end

-- ============================== фиксация ==============================

local function enforce()
    if not partsFolder or not partsFolder.Parent then pcall(getFolder) end
    local list = targets()
    if #list == 0 then return end

    for _, char in ipairs(list) do
        if CONFIG.headless then pcall(applyHeadless, char, true) end
        if CONFIG.korblox then
            if not korbloxOk(char) then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.RigType == Enum.HumanoidRigType.R6 and charMode[char] == "weld" then
                    weldMode = true
                end
            end
            pcall(applyKorblox, char, true)
        end
        if AURA.on then pcall(applyAura, char, true) end
    end

    pcall(cleanupParts, list)

    if accCurrent ~= 0 and not accBusy and not hasAcc() and os.clock() - accAt > 0.4 then
        accAt = os.clock()
        task.spawn(function() pcall(applyAcc, accCurrent) end)
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

-- ============================== слежение за персонажем ==============================

local watched = setmetatable({}, { __mode = "k" })

local function watchChar(char)
    if not char then return end
    if watched[char] then return end
    watched[char] = true

    meshCache = nil
    cmTries[char] = nil
    charMode[char] = nil
    airJumps = 0
    accAt = 0
    skinBusy = false

    enforce()
    for _, d in ipairs({ 0.2, 0.5, 0.9, 1.4, 2.2, 3.2 }) do
        task.delay(d, enforce)
    end

    if skinCurrent then
        task.delay(0.6, function()
            if skinCurrent then pcall(applySkinUserId, skinCurrent, true) end
        end)
    end

    track(char.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") or d:IsA("Accessory") or d:IsA("Hat") or d:IsA("Decal") or d:IsA("CharacterMesh") then
            if d:IsA("BasePart") then hookPart(d) end
            task.defer(enforce)
        end
    end))

    -- движок подкинул свой меш правой ноги — перетираем и ставим свой
    track(char.ChildAdded:Connect(function(d)
        if not CONFIG.korblox then return end
        if d:IsA("CharacterMesh") and d.BodyPart == Enum.BodyPart.RightLeg and d.Name ~= "VeniceKorblox" then
            pcall(function() d:Destroy() end)
            task.defer(enforce)
        end
    end))

    -- меш снесли (респавн аватарки, ApplyDescription) — возвращаем
    track(char.ChildRemoved:Connect(function(d)
        if not CONFIG.korblox then return end
        if d.Name == "VeniceKorblox" then
            task.defer(enforce)
        elseif d:IsA("CharacterMesh") and d.BodyPart == Enum.BodyPart.RightLeg then
            task.defer(enforce)
        end
    end))

    track(char.AncestryChanged:Connect(function() task.defer(enforce) end))

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        track(hum.ChildAdded:Connect(function() task.defer(enforce) end))
        track(hum:GetPropertyChangedSignal("RigType"):Connect(function() task.defer(enforce) end))
        track(hum.Died:Connect(function()
            -- после смерти всё равно дожимаем, пока не придёт новый персонаж
            for _, d in ipairs({ 0.2, 0.6, 1.2 }) do task.delay(d, enforce) end
        end))
    end
end

if LP.Character then watchChar(LP.Character) end
track(LP.CharacterAdded:Connect(watchChar))
track(LP.CharacterAppearanceLoaded:Connect(enforce))

-- watchdog: ловим смену персонажа даже если CharacterAdded не дошёл
local lastChar = LP.Character
task.spawn(function()
    while true do
        task.wait(0.4)
        local c = myChar()
        if c and not watched[c] then watchChar(c) end
        if c and c ~= lastChar then
            lastChar = c
            watchChar(c)
        end
        if LP.Character and LP.Character ~= lastChar then
            lastChar = LP.Character
            watchChar(LP.Character)
        end
    end
end)

track(WS.ChildAdded:Connect(function(m)
    if not m:IsA("Model") then return end
    if m.Name == LP.Name or m.Name == LP.DisplayName then
        task.defer(function()
            if m:FindFirstChild("Head") and m:FindFirstChildOfClass("Humanoid") then
                watchChar(m)
            end
        end)
    end
end))

-- ============================== меню ==============================

local gui, panel, open = nil, nil, false
local pages, tabBtns, activeTab = {}, {}, nil

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

local function chip(parent, text, cb, color)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = ROW
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Font = Enum.Font.GothamBold
    b.TextSize = 9
    b.TextColor3 = TEXT
    b.Text = text
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    if color then
        local dot = Instance.new("Frame")
        dot.Size = UDim2.fromOffset(8, 8)
        dot.Position = UDim2.new(0, 5, 0.5, -4)
        dot.BackgroundColor3 = color
        dot.BorderSizePixel = 0
        dot.Parent = b
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        b.TextXAlignment = Enum.TextXAlignment.Center
        b.Text = "    " .. text
    end
    b.MouseButton1Click:Connect(function()
        tw(b, 0.1, { BackgroundColor3 = ACCENT })
        task.delay(0.2, function() tw(b, 0.2, { BackgroundColor3 = ROW }) end)
        task.spawn(function() pcall(cb) end)
    end)
    return b
end

local function gridBox(rows)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -8, 0, rows * 30)
    f.BackgroundTransparency = 1
    f.Parent = panel
    local g = Instance.new("UIGridLayout", f)
    g.CellSize = UDim2.new(0.25, -4, 0, 26)
    g.CellPadding = UDim2.new(0, 4, 0, 4)
    return f
end

local function textbox(placeholder, cb)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1, -8, 0, 30)
    r.BackgroundColor3 = ROW
    r.BorderSizePixel = 0
    r.Parent = panel
    Instance.new("UICorner", r).CornerRadius = UDim.new(0, 8)

    local t = Instance.new("TextBox")
    t.Size = UDim2.new(1, -16, 1, 0)
    t.Position = UDim2.fromOffset(8, 0)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamSemibold
    t.TextSize = 12
    t.TextColor3 = TEXT
    t.PlaceholderText = placeholder
    t.PlaceholderColor3 = SUB
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.ClearTextOnFocus = false
    t.Text = ""
    t.Parent = r
    t.FocusLost:Connect(function(enter)
        if enter then task.spawn(function() pcall(cb, t.Text) end) end
    end)
    return t
end

local function statusLine()
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -8, 0, 14)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 10
    l.TextColor3 = SUB
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = "  " .. skinLast
    l.Parent = panel
    table.insert(skinLabels, l)
    return l
end

local function slider(text, min, max, default, cb, step, fmt)
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
    v.Text = fmt and fmt(default) or tostring(default)
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
        v.Text = fmt and fmt(val) or tostring(val)
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

local setHeadless, setKorblox, setForce, setBoost, setInf, setAura

local function setTab(id)
    activeTab = id
    for k, p in pairs(pages) do p.Visible = (k == id) end
    for k, b in pairs(tabBtns) do
        b.BackgroundColor3 = (k == id) and ACCENT or ROW
        b.TextColor3 = (k == id) and BG or SUB
    end
end

local TABS = {
    { id = "look", label = "Внешка" },
    { id = "aura", label = "Аура" },
    { id = "head", label = "Голова" },
    { id = "move", label = "Движение" },
    { id = "cam",  label = "Камера" },
    { id = "sky",  label = "Небо" },
    { id = "fps",  label = "FPS" },
    { id = "misc", label = "Прочее" },
}

local function build()
    gui = Instance.new("ScreenGui")
    gui.Name = "VeniceCos"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 1000000
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    getgenv().VeniceCos = gui
    if not stealthGui(gui) then gui.Parent = LP:WaitForChild("PlayerGui") end

    local shell = Instance.new("Frame")
    shell.Position = UDim2.fromOffset(20, 70)
    shell.Size = UDim2.fromOffset(480, 330)
    shell.BackgroundColor3 = BG
    shell.BackgroundTransparency = 0.05
    shell.BorderSizePixel = 0
    shell.Visible = false
    shell.Parent = gui
    Instance.new("UICorner", shell).CornerRadius = UDim.new(0, 12)
    local st = Instance.new("UIStroke", shell)
    st.Color = STROKE
    st.Transparency = 0.3

    local head = Instance.new("Frame")
    head.Size = UDim2.new(1, 0, 0, 30)
    head.BackgroundTransparency = 1
    head.Parent = shell

    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(6, 6)
    dot.Position = UDim2.fromOffset(13, 12)
    dot.BackgroundColor3 = ACCENT
    dot.BorderSizePixel = 0
    dot.Parent = head
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -34, 0, 13)
    title.Position = UDim2.fromOffset(25, 8)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 11
    title.TextColor3 = TEXT
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "VENICE · COSMETICS"
    title.Parent = head

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -8, 0, 24)
    bar.Position = UDim2.fromOffset(4, 32)
    bar.BackgroundTransparency = 1
    bar.Parent = shell
    local bl = Instance.new("UIListLayout", bar)
    bl.FillDirection = Enum.FillDirection.Horizontal
    bl.Padding = UDim.new(0, 3)
    bl.SortOrder = Enum.SortOrder.LayoutOrder

    for i, t in ipairs(TABS) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(52, 22)
        b.LayoutOrder = i
        b.BackgroundColor3 = ROW
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.Font = Enum.Font.GothamBold
        b.TextSize = 9
        b.TextColor3 = SUB
        b.Text = t.label
        b.Parent = bar
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        tabBtns[t.id] = b
        b.MouseButton1Click:Connect(function() setTab(t.id) end)

        local p = Instance.new("ScrollingFrame")
        p.Size = UDim2.new(1, -8, 1, -66)
        p.Position = UDim2.fromOffset(4, 62)
        p.BackgroundTransparency = 1
        p.BorderSizePixel = 0
        p.ScrollBarThickness = 2
        p.ScrollBarImageColor3 = ACCENT
        p.CanvasSize = UDim2.new()
        p.AutomaticCanvasSize = Enum.AutomaticSize.Y
        p.Visible = false
        p.Parent = shell
        local lay = Instance.new("UIListLayout", p)
        lay.Padding = UDim.new(0, 5)
        pages[t.id] = p
    end

    panel = pages.look
    section("ВНЕШКА")
    setHeadless = row("Headless", CONFIG.headless, function(v)
        CONFIG.headless = v
        for _, c in ipairs(targets()) do pcall(applyHeadless, c, v) end
    end)
    setKorblox = row("Korblox", CONFIG.korblox, function(v)
        CONFIG.korblox = v
        for _, c in ipairs(targets()) do pcall(applyKorblox, c, v) end
    end)
    setForce = row("Жёсткая фиксация", CONFIG.force, function(v)
        CONFIG.force = v
        enforce()
    end, 26)

    panel = pages.aura
    section("ЦВЕТ")
    local cg = gridBox(4)
    for _, c in ipairs(AURA_COLORS) do
        chip(cg, c.name, function()
            if c.mode == "rainbow" then
                AURA.mode = "rainbow"
            else
                AURA.mode = "solid"
                AURA.color = c.color
            end
            if AURA.on then refreshAura() end
        end, c.color)
    end
    section("СТИЛЬ")
    local sg = gridBox(1)
    for _, s in ipairs(AURA_STYLES) do
        chip(sg, s.name, function()
            AURA.style = s.id
            if AURA.on then refreshAura() end
        end)
    end
    section("ПАРАМЕТРЫ")
    setAura = row("Аура вкл", AURA.on, function(v)
        AURA.on = v
        if v then
            for _, c in ipairs(targets()) do pcall(applyAura, c, true) end
        else
            clearAuraAll()
        end
    end)
    slider("Размер", 0.3, 2.5, AURA.size, function(v)
        AURA.size = v
        if AURA.on then refreshAura() end
    end, 0.1, function(v) return string.format("%.1f", v) end)
    slider("Скорость цвета", 0.1, 3, AURA.speed, function(v)
        AURA.speed = v
    end, 0.1, function(v) return string.format("%.1f", v) end)
    button("Убрать ауру", function()
        if setAura then setAura(false) end
    end)

    panel = pages.head
    section("СКИН ИГРОКА")
    local skinBox = textbox("ник игрока → Enter", function(t) copySkin(t) end)
    button("Применить скин по нику", function() copySkin(skinBox.Text) end, true)
    button("Мой скин обратно", function() removeSkin() end)
    statusLine()

    section("АКСЕССУАРЫ")
    for _, a in ipairs(ACCS) do
        button(a.name, function() setAcc(a.id) end)
    end
    button("Снять", function() setAcc(0) end)
    slider("Смещение", -0.6, 1.2, accOffsetY, function(v)
        accOffsetY = v
        if accCurrent ~= 0 then reAcc() end
    end, 0.05)
    button("Вернуть голову", function()
        CONFIG.headless = false
        if setHeadless then setHeadless(false) end
        for _, c in ipairs(targets()) do pcall(applyHeadless, c, false) end
        enforce()
    end)

    panel = pages.move
    section("ДВИЖЕНИЕ")
    setInf = row("Бесконечный прыжок", CONFIG.infJump, function(v)
        CONFIG.infJump = v
        airJumps = 0
    end)
    slider("Прыжков в воздухе", -1, 10, CONFIG.jumpLimit, function(v)
        CONFIG.jumpLimit = v
        airJumps = 0
    end, 1, function(v)
        if v < 0 then return "∞" end
        if v == 0 then return "бхоп" end
        return tostring(v)
    end)

    panel = pages.cam
    section("КАМЕРА")
    slider("FOV", 40, 120, fovTarget, function(v)
        fovTarget = v
        applyFov()
    end, 1)

    local skyPage = pages.sky
    local sl = skyPage:FindFirstChildOfClass("UIListLayout")
    if sl then sl:Destroy() end
    local grid = Instance.new("UIGridLayout", skyPage)
    grid.CellSize = UDim2.new(0.333, -4, 0, 26)
    grid.CellPadding = UDim2.new(0, 4, 0, 4)
    panel = skyPage
    button("Выкл", function() applySky("off") end)
    button("Ночь", function() applySky("night") end)
    button("Космос", function() applySky("space") end)
    button("Закат", function() applySky("sunset") end)
    button("Сумерки", function() applySky("dusk") end)
    button("Классика", function() applySky("classic") end)
    button("Пасмурно", function() applySky("overcast") end)
    button("Пустота", function() applySky("void") end)
    button("Инферно", function() applySky("inferno") end)
    button("Лёд", function() applySky("ice") end)
    button("Матрица", function() applySky("matrix") end)
    button("Кровь", function() applySky("blood") end)

    panel = pages.fps
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

    panel = pages.misc
    section("ПРОЧЕЕ")
    button("Аксессуар заново", function()
        if accCurrent == 0 then accCurrent = ACCS[1].id end
        pcall(clearAcc)
        accAt = 0
        task.spawn(function() pcall(applyAcc, accCurrent) end)
    end)
    button("Переприменить", function()
        CONFIG.headless, CONFIG.korblox, CONFIG.force = true, true, true
        if setHeadless then setHeadless(true) end
        if setKorblox then setKorblox(true) end
        if setForce then setForce(true) end
        if accCurrent ~= 0 then
            accAt = 0
            task.spawn(function() pcall(applyAcc, accCurrent) end)
        end

        refreshScan()
        syncFps()
        if AURA.on then refreshAura() end
        if SKY.mode ~= "off" then pcall(applySky, SKY.mode) end

        for _ = 1, 6 do
            task.wait(0.15)
            enforce()
        end
        print("[Venice] переприменено")
    end, true)
    button("Диагностика", function()
        local list = targets()
        print("[Venice] целей найдено:", #list)
        print("[Venice] LP.Character:", tostring(LP.Character))
        print("[Venice] myChar:", tostring(myChar()))
        local char = list[1]
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        print("[Venice] риг:", hum and hum.RigType.Name or "нет")
        print("[Venice] weld-режим:", tostring(weldMode), "попыток меша:", char and tostring(cmTries[char]) or "-")
        print("[Venice] CreateMeshPartAsync:", meshCache and "ок" or "недоступен")
        print("[Venice] аура:", tostring(AURA.on), "режим:", AURA.mode, "стиль:", AURA.style, "объектов:", auraState[char or LP.Character] and #auraState[char or LP.Character] or 0)
        print("[Venice] аксессуар:", accCurrent, "| на голове:", tostring(hasAcc()), "| статус:", accLast)
        print("[Venice] скин:", tostring(skinCurrent), "|", skinLast)
        print("[Venice] частей в папке:", partsFolder and #partsFolder:GetChildren() or 0)
        print("[Venice] инф.прыжок:", tostring(CONFIG.infJump), "лимит:", CONFIG.jumpLimit)
        print("[Venice] fps:", tostring(FPS.boost), "частиц убито:", #killedParts, "эффектов:", #killedFx)
        print("[Venice] FOV:", tostring(fovTarget), "небо:", SKY.mode)
    end)
    button("Убрать всё", function()
        CONFIG.headless, CONFIG.korblox, CONFIG.force = false, false, false
        CONFIG.infJump = false
        AURA.on = false
        accCurrent = 0
        skinCurrent = nil
        FPS.boost, FPS.shadowsOff, FPS.fxOff, FPS.partsOff = false, false, false, false
        if setHeadless then setHeadless(false) end
        if setKorblox then setKorblox(false) end
        if setForce then setForce(false) end
        if setBoost then setBoost(false) end
        if setInf then setInf(false) end
        if setAura then setAura(false) end
        syncFps()
        for _, c in ipairs(targets()) do
            pcall(applyHeadless, c, false)
            pcall(clearKorblox, c)
            pcall(clearAura, c)
        end
        pcall(clearAcc)
        pcall(applySky, "off")
        fovTarget = 70
        pcall(applyFov)
    end)

    panel = shell
    setTab("look")

    local drag, ds, sp
    head.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag, ds, sp = true, i.Position, shell.Position
        end
    end)
    track(UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            shell.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end))
    track(UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end))

    gui.Destroying:Connect(function()
        pcall(function() RunS:UnbindFromRenderStep("VeniceEnforce") end)
        pcall(function() CAS:UnbindAction("VeniceMenu") end)
        pcall(clearAuraAll)
        if partsFolder then
            for _, o in ipairs(partsFolder:GetChildren()) do pcall(function() o:Destroy() end) end
        end
    end)

    print("[Venice] v33 · Z меню")
end

build()

pcall(function()
    CAS:BindActionAtPriority("VeniceMenu", function(_, state, input)
        if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
        if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
        if input.KeyCode == Enum.KeyCode.Z then
            setOpen()
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Z)
end)

track(UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode ~= Enum.KeyCode.Z then return end
    if UIS:GetFocusedTextBox() then return end
    setOpen()
end))

pcall(getFolder)

task.wait(1.2)
enforce()

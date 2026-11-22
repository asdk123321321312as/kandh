local G = (type(getgenv) == "function" and getgenv()) or (type(getgenv) == "table" and getgenv) or _G
if type(G) ~= "table" then G = _G end
if G.VeniceCos then pcall(function() G.VeniceCos:Destroy() end) end
if type(G.VeniceCosConns) == "table" then
    for _, c in ipairs(G.VeniceCosConns) do pcall(function() c:Disconnect() end) end
end
G.VeniceCosConns = {} -- пошёл нахуй

local ref = (type(cloneref) == "function" and cloneref) or function(s) return s end
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

local function track(c) table.insert(G.VeniceCosConns, c) return c end

local CONFIG = { korblox = true, headless = true, force = true, infJump = false, jumpLimit = -1, noclip = false }
local FPS    = { boost = false, shadowsOff = false, fxOff = false, partsOff = false, cap = 240 }
local AURA   = { on = false, size = 1, speed = 1, spin = 1, hue = 0, mode = "rainbow", color = Color3.fromRGB(152, 132, 255), style = "ring" }
local PROTECT = { parts = false, godHealth = false }
local ESP = {
    on = false, box = true, name = true, dist = true, health = true, tracer = true,
    rainbow = true, color = Color3.fromRGB(152, 132, 255),
    style = "full", textSize = 12, thickness = 1, maxDist = 500,
    transparency = 0.35, outline = true, rate = 0.12, stealth = true,
}

local ACCS = {
    { id = 132809431,  name = "Doomsekkar" },
    { id = 74891470,   name = "Frozen Horns" },
    { id = 215718515,  name = "Fiery Horns" },
    { id = 1744060292, name = "Poisoned Horns" },
}
local accCurrent, accOffsetY = 0, 0
local MESH, TEX = "rbxassetid://101851696", "rbxassetid://101851254"

local ACCENT = Color3.fromRGB(152, 132, 255)
local ACCENT2 = Color3.fromRGB(96, 180, 255)
local BG     = Color3.fromRGB(11, 11, 14)
local BG2    = Color3.fromRGB(16, 16, 21)
local ROW    = Color3.fromRGB(24, 24, 30)
local HOVER  = Color3.fromRGB(35, 35, 44)
local OFF    = Color3.fromRGB(46, 46, 56)
local STROKE = Color3.fromRGB(44, 44, 56)
local TEXT   = Color3.fromRGB(238, 238, 244)
local SUB    = Color3.fromRGB(126, 126, 144)
local OKC    = Color3.fromRGB(120, 220, 160)

if type(setthreadidentity) == "function" then pcall(setthreadidentity, 7) end

local errAt = {}
local function safe(name, fn)
    return function(...)
        local now = os.clock()
        local last = errAt[name]
        if last and now - last < 2 then return end
        local ok, err = pcall(fn, ...)
        if not ok then
            errAt[name] = now
            warn("[Sleepscript] " .. name .. ": " .. tostring(err))
        end
    end
end

local RNDC = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
local function rnd(n)
    local s = ""
    for _ = 1, (n or 8) do
        local k = math.random(1, #RNDC)
        s = s .. RNDC:sub(k, k)
    end
    return s
end

local function hiddenParent()
    if type(gethui) == "function" then
        local h = gethui()
        if h then return h end
    end
    return game:GetService("CoreGui")
end

local function stealthGui(g)
    local prot = protectgui or protect_gui or (syn and syn.protect_gui)
    if type(prot) == "function" then pcall(prot, g) end
    local h = (type(gethui) == "function") and gethui() or nil
    if h then if pcall(function() g.Parent = h end) then return true end end
    return pcall(function() g.Parent = game:GetService("CoreGui") end)
end

-- ============================== цели ==============================

local scanCache, scanAt = {}, 0

local function addModel(list, seen, m)
    if not m or seen[m] then return end
    if not m:IsA("Model") then return end
    if not m:FindFirstChildOfClass("Humanoid") then return end
    if not m:FindFirstChild("Head") then return end
    seen[m] = true
    list[#list + 1] = m
end

local function refreshScan()
    scanAt = os.clock()
    local list, seen = {}, {}
    for _, m in ipairs(WS:GetChildren()) do
        if m.Name == LP.Name or m.Name == LP.DisplayName then addModel(list, seen, m) end
    end
    scanCache = list
end

local function targets()
    if os.clock() - scanAt > 0.5 then refreshScan() end
    local list, seen = {}, {}
    addModel(list, seen, LP.Character)
    local cam = WS.CurrentCamera
    local subj = cam and cam.CameraSubject
    if subj then addModel(list, seen, subj.Parent) end
    for _, m in ipairs(scanCache) do addModel(list, seen, m) end
    return list
end

local function espTargets()
    local list, seen = {}, {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP then addModel(list, seen, pl.Character) end
    end
    local mine = LP.Character
    for _, m in ipairs(targets()) do
        if m ~= mine then addModel(list, seen, m) end
    end
    return list
end

local function myChar()
    local c = LP.Character
    if c and c:FindFirstChild("Head") then return c end
    if os.clock() - scanAt > 0.5 then refreshScan() end
    for _, m in ipairs(scanCache) do
        if m.Parent then return m end
    end
    return nil
end

-- ============================== скрытие ==============================

local hidingNow = false
local hooked = setmetatable({}, { __mode = "k" })
local ATTR = "SleepOrigT"

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

local function headParts(char)
    local head = char:FindFirstChild("Head")
    if not head then return {} end
    if head:IsA("BasePart") then return { head } end
    local out = {}
    for _, d in ipairs(head:GetDescendants()) do
        if d:IsA("BasePart") then out[#out + 1] = d end
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
            if w and (set[w.Part0] or set[w.Part1]) then out[#out + 1] = d end
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
        if not acc:GetAttribute("SleepHat") then
            for _, d in ipairs(acc:GetDescendants()) do
                if d:IsA("BasePart") then
                    hookPart(d)
                    setHidden(d, on)
                elseif d:IsA("Decal") then
                    setHidden(d, on)
                end
            end
        end
    end
end

-- ============================== папка частей ==============================

local partsFolder
local function getFolder()
    if partsFolder and partsFolder.Parent then return partsFolder end
    local f = WS:FindFirstChild("SleepParts")
    if not f then
        f = Instance.new("Folder")
        f.Name = "SleepParts"
        f.Archivable = false
        f.Parent = WS
    end
    partsFolder = f
    return f
end

-- ============================== аксессуары ==============================

local ACC_ATTR = "SleepHatPart"
local accLast, accTemplate, accState, accMountAt, accFailAt = "не запускалось", nil, "idle", 0, 0
local accCache = {}

local function accParts()
    local out = {}
    if not partsFolder then return out end
    for _, p in ipairs(partsFolder:GetChildren()) do
        if p:GetAttribute(ACC_ATTR) then out[#out + 1] = p end
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
    if accCache[id] then return accCache[id] end
    local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
    if ok and objs and #objs > 0 then
        local g = grab(objs)
        if g then accCache[id] = g return g end
    end
    local ok2, model = pcall(function() return game:GetService("InsertService"):LoadAsset(id) end)
    if ok2 and model then
        local g = grab(model:GetChildren())
        if g then accCache[id] = g return g end
    end
    return nil
end

local function loadAccAsync(id)
    if accState == "loading" then return end
    accState = "loading"
    accLast = "загрузка"
    task.spawn(function()
        for attempt = 1, 3 do
            local ok, res = pcall(loadAcc, id)
            if accCurrent ~= id then accState = "idle" return end
            if ok and res then
                accTemplate, accState, accLast, accMountAt = res, "ready", "готово", 0
                return
            end
            accLast = "ошибка загрузки"
            task.wait(0.5 * attempt)
        end
        accState = "failed"
        accFailAt = os.clock()
    end)
end

local function handleFrom(t)
    if t:IsA("Accessory") or t:IsA("Hat") then
        return t:FindFirstChild("Handle") or t:FindFirstChildWhichIsA("BasePart", true)
    end
    if t:IsA("BasePart") then return t end
    return t:FindFirstChildWhichIsA("BasePart", true)
end

local function mountAcc()
    if accState ~= "ready" or not accTemplate or hasAcc() then return end
    local char = LP.Character
    local head = char and char:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then return end
    local src = handleFrom(accTemplate)
    if not src then accState = "failed" accFailAt = os.clock() return end

    local h = src:Clone()
    h.Name = "SleepHatHandle"
    h:SetAttribute(ACC_ATTR, true)
    h.Anchored = false
    h.CanCollide = false
    h.CanQuery = false
    h.CanTouch = false
    h.CastShadow = true
    h.Transparency = 0
    h.LocalTransparencyModifier = 0
    pcall(function() h.Massless = true end)

    local biggest = math.max(h.Size.X, h.Size.Y, h.Size.Z)
    if biggest < 0.25 then h.Size = h.Size * (0.6 / math.max(biggest, 0.01)) end

    local att = h:FindFirstChildWhichIsA("Attachment")
    if att then
        h.CFrame = head.CFrame * CFrame.new(0, head.Size.Y / 2 + accOffsetY, 0) * att.CFrame:Inverse()
    else
        h.CFrame = head.CFrame * CFrame.new(0, head.Size.Y / 2 + h.Size.Y / 2 * 0.5 + accOffsetY, 0)
    end

    h.Parent = getFolder()
    local w = Instance.new("WeldConstraint")
    w.Part0 = h
    w.Part1 = head
    w.Parent = h
    accLast = "надет"
end

local function setAcc(id)
    accCurrent = id
    pcall(clearAcc)
    accTemplate, accMountAt = nil, 0
    if id == 0 then accState, accLast = "idle", "снято" return end
    accState = "idle"
    loadAccAsync(id)
end

local function reAcc()
    pcall(clearAcc)
    accMountAt = 0
    if accCurrent == 0 then return end
    if accTemplate then
        accState = "ready"
        task.defer(function() pcall(mountAcc) end)
    else
        loadAccAsync(accCurrent)
    end
end

-- ============================== коробокс ==============================

local meshCache
local savedCharMesh = {}
local charMode = setmetatable({}, { __mode = "k" })
local cmTries  = setmetatable({}, { __mode = "k" })

local function findLegParts(char)
    local upper = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg") or char:FindFirstChild("RightLeg")
    local lower = char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Lower Leg")
    local foot  = char:FindFirstChild("RightFoot") or char:FindFirstChild("Right Foot")
    return upper, lower, foot
end

local function findKorbloxPart(char)
    if not partsFolder then return nil end
    for _, p in ipairs(partsFolder:GetChildren()) do
        if p.Name == "SleepKorbloxLeg" then
            local w = p:FindFirstChildWhichIsA("WeldConstraint")
            if w and w.Part1 and w.Part1:IsDescendantOf(char) then return p end
        end
    end
end

local function korbloxOk(char)
    return char:FindFirstChild("SleepKorblox") ~= nil or findKorbloxPart(char) ~= nil
end

local function clearKorblox(char)
    if not char then return end
    local cm = char:FindFirstChild("SleepKorblox")
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
        m.Name = "SleepKorbloxRestore"
        m.BodyPart = Enum.BodyPart.RightLeg
        m.MeshId = s.mesh
        m.OverlayTextureId = s.tex
        m.Parent = char
        savedCharMesh[char] = nil
    end
end

local function getMeshPart()
    if meshCache and meshCache.Parent then return meshCache end
    local ok, part = pcall(function() return AssetS:CreateMeshPartAsync(MESH, Enum.CollisionFidelity.Box) end)
    if ok and typeof(part) == "MeshPart" then
        meshCache = part
        return part
    end
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
        part.Name = "SleepKorbloxLeg"
    else
        part = Instance.new("Part")
        part.Name = "SleepKorbloxLeg"
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
        charMode[char], cmTries[char] = nil, nil
        return
    end
    if korbloxOk(char) then return end

    if hum.RigType == Enum.HumanoidRigType.R6 and charMode[char] ~= "weld" then
        cmTries[char] = (cmTries[char] or 0) + 1
        if cmTries[char] > 5 then
            charMode[char] = "weld"
        else
            for _, d in ipairs(char:GetChildren()) do
                if d:IsA("CharacterMesh") and d.BodyPart == Enum.BodyPart.RightLeg and d.Name ~= "SleepKorblox" then
                    savedCharMesh[char] = { mesh = d.MeshId, tex = d.OverlayTextureId }
                    pcall(function() d:Destroy() end)
                    break
                end
            end
            local m = Instance.new("CharacterMesh")
            m.Name = "SleepKorblox"
            m.BodyPart = Enum.BodyPart.RightLeg
            m.MeshId = 101851696
            m.OverlayTextureId = 101851254
            m.Parent = char
            return
        end
    end

    local upper, lower, foot = findLegParts(char)
    if upper then buildKorbloxLeg(char, upper, lower, foot) end
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

-- ============================== ноклип ==============================

local noclipSaved = {}
local noclipActive = false

local function noclipOne(d, on)
    if not d:IsA("BasePart") then return end
    if on then
        if noclipSaved[d] == nil then noclipSaved[d] = d.CanCollide end
        if d.CanCollide then pcall(function() d.CanCollide = false end) end
    else
        local o = noclipSaved[d]
        noclipSaved[d] = nil
        if o ~= nil then pcall(function() d.CanCollide = o end) end
    end
end

local function unstick(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = hum and hum.RootPart
    if not root then return end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char }
    local hit = WS:Raycast(root.Position + Vector3.new(0, 200, 0), Vector3.new(0, -400, 0), params)
    if hit and hit.Position.Y > root.Position.Y - 0.5 then
        local delta = math.min(hit.Position.Y - root.Position.Y + 3, 200)
        if delta > 0.2 then
            char:PivotTo(char:GetPivot() + Vector3.new(0, delta, 0))
            pcall(function() root.AssemblyLinearVelocity = Vector3.zero end)
        end
    end
end

local function restoreNoclip()
    local snap = noclipSaved
    noclipSaved = {}
    for d, o in pairs(snap) do
        if d.Parent then pcall(function() d.CanCollide = o end) end
    end
    task.delay(0.3, function()
        for d, o in pairs(snap) do
            if d.Parent and d.CanCollide ~= o then pcall(function() d.CanCollide = o end) end
        end
    end)
end

local function setNoclip(on)
    CONFIG.noclip = on
    noclipActive = on
    if on then
        local c = LP.Character
        if c then
            for _, d in ipairs(c:GetDescendants()) do
                if d:IsA("BasePart") then noclipOne(d, true) end
            end
        end
    else
        restoreNoclip()
        task.delay(0.15, function()
            local c = LP.Character
            if c then pcall(unstick, c) end
        end)
    end
end

local function noclipTick()
    if not noclipActive then return end
    local c = LP.Character
    if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") and d.CanCollide then noclipOne(d, true) end
    end
end

-- ============================== защита ==============================

local TOUCH_ATTR = "SleepOrigTouch"
local HAZ = {
    "kill", "damage", "dmg", "hurt", "lava", "spike", "saw", "trap", "hazard",
    "death", "die", "void", "poison", "acid", "burn", "crush", "squash",
    "checkpoint", "check_point", "respawn", "reset", "teleport", "killbrick",
}

local function isHazName(name)
    local n = name:lower()
    for _, p in ipairs(HAZ) do
        if n:find(p, 1, true) then return true end
    end
    return false
end

local function protectPart(d, on)
    if not d:IsA("BasePart") then return end
    local char = LP.Character
    if char and d:IsDescendantOf(char) then return end
    if on then
        if not isHazName(d.Name) then return end
        if d:GetAttribute(TOUCH_ATTR) == nil then
            pcall(function() d:SetAttribute(TOUCH_ATTR, d.CanTouch) end)
        end
        if d.CanTouch then pcall(function() d.CanTouch = false end) end
    else
        local o = d:GetAttribute(TOUCH_ATTR)
        if o ~= nil then
            pcall(function() d.CanTouch = o end)
            pcall(function() d:SetAttribute(TOUCH_ATTR, nil) end)
        end
    end
end

local function scanHazards()
    if not PROTECT.parts then return end
    local n = 0
    for _, d in ipairs(WS:GetDescendants()) do
        if d:IsA("BasePart") and isHazName(d.Name) then
            protectPart(d, true)
            n = n + 1
            if n > 8000 then break end
        end
    end
    print("[Sleepscript] защищено частей:", n)
end

local function clearHazards()
    for _, d in ipairs(WS:GetDescendants()) do
        if d:IsA("BasePart") and d:GetAttribute(TOUCH_ATTR) ~= nil then protectPart(d, false) end
    end
end

track(WS.DescendantAdded:Connect(function(d)
    if not PROTECT.parts then return end
    if d:IsA("BasePart") and isHazName(d.Name) then pcall(protectPart, d, true) end
end))

-- ============================== аура ==============================

local auraChar, auraParts, auraLight = nil, nil, nil
local auraNodes, auraEmitters = {}, {}
local auraT, auraNext = 0, 0

local function rainbow(h) return Color3.fromHSV(h % 1, 1, 1) end
local function rainbowSeq(phase)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, rainbow(phase)),
        ColorSequenceKeypoint.new(0.5, rainbow(phase + 0.33)),
        ColorSequenceKeypoint.new(1, rainbow(phase + 0.66)),
    })
end
local function auraColor(off)
    if AURA.mode == "rainbow" then return rainbow(AURA.hue + (off or 0)) end
    return AURA.color
end
local function auraSeq()
    if AURA.mode == "rainbow" then return rainbowSeq(AURA.hue) end
    return ColorSequence.new(AURA.color)
end
local function kp(t, v) return NumberSequenceKeypoint.new(t, v) end

local AURA_COLORS = {
    { name = "Радуга",  mode = "rainbow" },
    { name = "Фиолет",  color = Color3.fromRGB(152, 132, 255) },
    { name = "Красный", color = Color3.fromRGB(255, 60, 60) },
    { name = "Золото",  color = Color3.fromRGB(255, 205, 60) },
    { name = "Лайм",    color = Color3.fromRGB(160, 255, 60) },
    { name = "Циан",    color = Color3.fromRGB(70, 230, 255) },
    { name = "Розовый", color = Color3.fromRGB(255, 110, 210) },
    { name = "Белый",   color = Color3.fromRGB(255, 255, 255) },
}

local AURA_STYLES = {
    { name = "Кольцо",    id = "ring" },
    { name = "Туман",     id = "mist" },
    { name = "Орбита",    id = "orbit" },
    { name = "Спираль",   id = "spiral" },
    { name = "Мерцание",  id = "flicker" },
    { name = "Пульс",     id = "pulse" },
    { name = "Вихрь",     id = "vortex" },
    { name = "Волна",     id = "wave" },
    { name = "Пламя",     id = "flame" },
    { name = "Звездопад", id = "rain" },
    { name = "Клетка",    id = "cage" },
    { name = "Вспышка",   id = "burst" },
}

local function clearAura()
    if auraParts then
        for _, o in ipairs(auraParts) do pcall(function() o:Destroy() end) end
    end
    auraChar, auraParts, auraLight = nil, nil, nil
    auraNodes, auraEmitters = {}, {}
    auraT, auraNext = 0, 0
end

local function baseEmitter()
    local e = Instance.new("ParticleEmitter")
    e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    e.LightEmission = 1
    e.LightInfluence = 0
    e.Color = auraSeq()
    e:SetAttribute("SleepAura", true)
    return e
end

local function newAtt(root, made, y)
    local a = Instance.new("Attachment")
    a.Name = "SleepAuraNode"
    a:SetAttribute("SleepAura", true)
    if y then a.Position = Vector3.new(0, y, 0) end
    a.Parent = root
    made[#made + 1] = a
    auraNodes[#auraNodes + 1] = a
    return a
end

local function push(e, parent, made)
    e.Parent = parent
    made[#made + 1] = e
    auraEmitters[#auraEmitters + 1] = e
end

local function makeRing(root, att, made)
    local e = baseEmitter()
    e.Shape = Enum.ParticleEmitterShape.Disc
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
    e.ShapePartial = 1
    e.Rate = 22 * AURA.size
    e.Lifetime = NumberRange.new(0.6, 1.1)
    e.Speed = NumberRange.new(0.6, 2.2)
    e.Drag = 3
    e.Acceleration = Vector3.new(0, 2.6, 0)
    e.Size = NumberSequence.new({ kp(0, 0.5 * AURA.size), kp(0.35, 0.85 * AURA.size), kp(1, 0) })
    e.Transparency = NumberSequence.new({ kp(0, 0.15), kp(1, 1) })
    e.RotSpeed = NumberRange.new(-120, 120)
    push(e, att, made)
end

local function makeMist(root, att, made)
    local e = baseEmitter()
    e.Shape = Enum.ParticleEmitterShape.Sphere
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
    e.Rate = 10 * AURA.size
    e.Lifetime = NumberRange.new(1, 1.8)
    e.Speed = NumberRange.new(0.2, 0.9)
    e.Drag = 4
    e.Acceleration = Vector3.new(0, 1.1, 0)
    e.Size = NumberSequence.new({ kp(0, 1.1 * AURA.size), kp(1, 0) })
    e.Transparency = NumberSequence.new({ kp(0, 0.55), kp(1, 1) })
    push(e, att, made)
end

local function makeOrbit(root, att, made)
    for i = 1, 3 do
        local a = newAtt(root, made, 0.4)
        a.Position = Vector3.new(math.cos(i * 2.09) * 2, 0.4, math.sin(i * 2.09) * 2)
        local e = baseEmitter()
        e.Shape = Enum.ParticleEmitterShape.Sphere
        e.Rate = 50 * AURA.size
        e.Lifetime = NumberRange.new(0.25, 0.5)
        e.Speed = NumberRange.new(0.05, 0.4)
        e.Drag = 2
        e.Size = NumberSequence.new({ kp(0, 0.5 * AURA.size), kp(1, 0) })
        e.Transparency = NumberSequence.new({ kp(0, 0.1), kp(1, 1) })
        e.RotSpeed = NumberRange.new(-200, 200)
        push(e, a, made)
    end
end

local function makeSpiral(root, att, made)
    local a = newAtt(root, made)
    local e = baseEmitter()
    e.Shape = Enum.ParticleEmitterShape.Sphere
    e.Rate = 45 * AURA.size
    e.Lifetime = NumberRange.new(0.4, 0.8)
    e.Speed = NumberRange.new(0.1, 0.5)
    e.Drag = 1.5
    e.Size = NumberSequence.new({ kp(0, 0.55 * AURA.size), kp(1, 0) })
    e.Transparency = NumberSequence.new({ kp(0, 0.1), kp(1, 1) })
    e.RotSpeed = NumberRange.new(-260, 260)
    push(e, a, made)
end

local function makeVortex(root, att, made)
    local a = newAtt(root, made, 0.2)
    local e = baseEmitter()
    e.Shape = Enum.ParticleEmitterShape.Disc
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
    e.ShapePartial = 1
    pcall(function() e.ShapeRadius = 1.6 * AURA.size end)
    e.Rate = 80 * AURA.size
    e.Lifetime = NumberRange.new(0.5, 1.1)
    e.Speed = NumberRange.new(0.1, 0.7)
    e.Drag = 2
    e.Acceleration = Vector3.new(0, 9, 0)
    e.Size = NumberSequence.new({ kp(0, 0.4 * AURA.size), kp(1, 0) })
    e.Transparency = NumberSequence.new({ kp(0, 0.1), kp(1, 1) })
    e.RotSpeed = NumberRange.new(-300, 300)
    push(e, a, made)
end

local function makeWave(root, att, made)
    local a = newAtt(root, made, 0.3)
    local e = baseEmitter()
    e.Shape = Enum.ParticleEmitterShape.Disc
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
    e.ShapePartial = 1
    pcall(function() e.ShapeRadius = 0.6 * AURA.size end)
    e.Rate = 0
    e.Lifetime = NumberRange.new(0.5, 0.85)
    e.Speed = NumberRange.new(6, 9)
    e.Drag = 3
    e.Acceleration = Vector3.new(0, 0.6, 0)
    e.Size = NumberSequence.new({ kp(0, 0.5 * AURA.size), kp(1, 0.15 * AURA.size) })
    e.Transparency = NumberSequence.new({ kp(0, 0.2), kp(1, 1) })
    push(e, a, made)
end

local function makeFlame(root, att, made)
    local a = newAtt(root, made, -1)
    local e = baseEmitter()
    e.Shape = Enum.ParticleEmitterShape.Disc
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
    pcall(function() e.ShapeRadius = 0.9 * AURA.size end)
    e.Rate = 70 * AURA.size
    e.Lifetime = NumberRange.new(0.35, 0.7)
    e.Speed = NumberRange.new(1.5, 3.5)
    e.Acceleration = Vector3.new(0, 7, 0)
    e.Drag = 2
    e.Size = NumberSequence.new({ kp(0, 0.65 * AURA.size), kp(1, 0) })
    e.Transparency = NumberSequence.new({ kp(0, 0.1), kp(1, 1) })
    e.RotSpeed = NumberRange.new(-160, 160)
    push(e, a, made)
end

local function makeRain(root, att, made)
    local a = newAtt(root, made, 6 * AURA.size)
    local e = baseEmitter()
    e.Shape = Enum.ParticleEmitterShape.Sphere
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
    pcall(function() e.ShapeRadius = 3 * AURA.size end)
    e.Rate = 40 * AURA.size
    e.Lifetime = NumberRange.new(1.1, 1.6)
    e.Speed = NumberRange.new(0, 0.4)
    e.Acceleration = Vector3.new(0, -10, 0)
    e.Size = NumberSequence.new({ kp(0, 0.25 * AURA.size), kp(1, 0.05 * AURA.size) })
    e.Transparency = NumberSequence.new({ kp(0, 0.1), kp(1, 1) })
    push(e, a, made)
end

local function makeCage(root, att, made)
    local a = newAtt(root, made, 1.2)
    local e = baseEmitter()
    e.Shape = Enum.ParticleEmitterShape.Sphere
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
    pcall(function() e.ShapeRadius = 2 * AURA.size end)
    e.Rate = 35 * AURA.size
    e.Lifetime = NumberRange.new(0.7, 1)
    e.Speed = NumberRange.new(0.02, 0.15)
    e.Size = NumberSequence.new({ kp(0, 0.32 * AURA.size), kp(1, 0) })
    e.Transparency = NumberSequence.new({ kp(0, 0.15), kp(1, 1) })
    e.RotSpeed = NumberRange.new(-90, 90)
    push(e, a, made)
end

local function makeBurst(root, att, made)
    local a = newAtt(root, made, 0.6)
    local e = baseEmitter()
    e.Shape = Enum.ParticleEmitterShape.Sphere
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
    pcall(function() e.ShapeRadius = 0.5 * AURA.size end)
    e.Rate = 0
    e.Lifetime = NumberRange.new(0.45, 0.8)
    e.Speed = NumberRange.new(5, 8)
    e.Drag = 5
    e.Size = NumberSequence.new({ kp(0, 0.5 * AURA.size), kp(1, 0) })
    e.Transparency = NumberSequence.new({ kp(0, 0.1), kp(1, 1) })
    e.RotSpeed = NumberRange.new(-240, 240)
    push(e, a, made)
end

local BUILDERS = {
    ring = makeRing, mist = makeMist, orbit = makeOrbit, spiral = makeSpiral,
    vortex = makeVortex, wave = makeWave, flame = makeFlame, rain = makeRain,
    cage = makeCage, burst = makeBurst,
}

local function buildStyle(root, att, made)
    local b = BUILDERS[AURA.style] or BUILDERS.ring
    local ok = pcall(b, root, att, made)
    if not ok or #auraEmitters == 0 then
        pcall(BUILDERS.ring, root, att, made)
    end
end

local function applyAura(char, on)
    if not on then clearAura() return end
    if not char or auraChar == char then return end
    clearAura()

    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = (hum and hum.RootPart) or char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    if not root then return end

    local made = {}
    local ok = pcall(function()
        local att = Instance.new("Attachment")
        att.Name = "SleepAuraAtt"
        att.Orientation = Vector3.new(-90, 0, 0)
        att:SetAttribute("SleepAura", true)
        att.Parent = root
        made[#made + 1] = att

        buildStyle(root, att, made)

        local light = Instance.new("PointLight")
        light.Brightness = 2
        light.Range = 12 * AURA.size
        light.Color = auraColor()
        light.Parent = att
        made[#made + 1] = light
        auraLight = light

        local hl = Instance.new("Highlight")
        hl.Adornee = char
        hl.FillTransparency = 0.72
        hl.OutlineTransparency = 0.25
        hl.DepthMode = Enum.HighlightDepthMode.Occluded
        hl.FillColor = auraColor()
        hl.OutlineColor = auraColor(0.5)
        hl.Parent = char
        made[#made + 1] = hl
    end)

    if ok then
        auraChar, auraParts = char, made
    else
        for _, o in ipairs(made) do pcall(function() o:Destroy() end) end
        auraNodes, auraEmitters, auraLight = {}, {}, nil
    end
end

local function updateAura(dt)
    auraT = auraT + dt
    local st = AURA.style
    if st == "orbit" then
        local r = 2.1 * AURA.size
        local y = 0.4 + math.sin(auraT * 2) * 0.3 * AURA.size
        for i, a in ipairs(auraNodes) do
            if a.Parent then
                local ang = auraT * 2.2 * AURA.spin + (i - 1) * (math.pi * 2 / 3)
                a.Position = Vector3.new(math.cos(ang) * r, y, math.sin(ang) * r)
            end
        end
    elseif st == "spiral" then
        local frac = (auraT * 0.45 * AURA.spin) % 1
        local a = auraNodes[1]
        if a and a.Parent then
            local r = (1 - frac) * 2.4 * AURA.size
            local ang = frac * math.pi * 6
            a.Position = Vector3.new(math.cos(ang) * r, frac * 4.2 * AURA.size - 0.4, math.sin(ang) * r)
        end
    elseif st == "vortex" then
        local a = auraNodes[1]
        if a and a.Parent then
            local ang = auraT * 1.6 * AURA.spin
            a.Position = Vector3.new(math.cos(ang) * 0.3, 0.2, math.sin(ang) * 0.3)
        end
    elseif st == "flicker" then
        local e = auraEmitters[1]
        if e then
            if math.random() < 0.25 then
                e.Rate = (60 + math.random() * 80) * AURA.size
                pcall(function() e:Emit(math.random(2, 5)) end)
            else
                e.Rate = 6 * AURA.size
            end
        end
        if auraLight then auraLight.Brightness = math.random() < 0.35 and 5 or 0.4 end
    elseif st == "pulse" then
        local s = (math.sin(auraT * 3 * AURA.speed) + 1) / 2
        local e = auraEmitters[1]
        if e then e.Rate = (6 + 50 * s) * AURA.size end
        if auraLight then auraLight.Brightness = 1 + s * 3 end
    elseif st == "wave" or st == "burst" then
        if auraT >= auraNext then
            local gap = st == "wave" and 0.55 or 0.7
            auraNext = auraT + gap / AURA.speed
            local e = auraEmitters[1]
            if e then pcall(function() e:Emit(math.floor((st == "wave" and 24 or 18) * AURA.size)) end) end
            if st == "wave" and auraLight then auraLight.Brightness = 4 end
        end
    end
end

local function refreshAura()
    clearAura()
    if AURA.on then
        local c = myChar()
        if c then pcall(applyAura, c, true) end
    end
end

task.spawn(function()
    local last = os.clock()
    while true do
        task.wait(0.05)
        local now = os.clock()
        local dt = now - last
        last = now
        if auraChar and not auraChar.Parent then clearAura() end
        if AURA.on and auraChar and auraParts then
            pcall(updateAura, dt)
            if AURA.mode == "rainbow" then
                AURA.hue = (AURA.hue + dt * 0.22 * AURA.speed) % 1
                local c = rainbow(AURA.hue)
                local seq = rainbowSeq(AURA.hue)
                for _, o in ipairs(auraParts) do
                    if o:IsA("Highlight") then
                        o.FillColor = c
                        o.OutlineColor = rainbow(AURA.hue + 0.5)
                    elseif o:IsA("PointLight") then
                        o.Color = c
                    elseif o:IsA("ParticleEmitter") then
                        o.Color = seq
                    end
                end
            end
        end
    end
end)

-- ============================== esp ==============================

local espContainer
local espData = setmetatable({}, { __mode = "k" })
local espHue = 0
local DrawingLib
pcall(function() if Drawing and Drawing.new then DrawingLib = Drawing end end)

local function espColor(i)
    if ESP.rainbow then return Color3.fromHSV((espHue + (i or 0) * 0.13) % 1, 0.85, 1) end
    return ESP.color
end

local function getEspContainer()
    if espContainer and espContainer.Parent then return espContainer end
    local f = Instance.new("Folder")
    f.Name = ESP.stealth and rnd(10) or "SleepEsp"
    f.Archivable = false
    local target = ESP.stealth and hiddenParent() or WS
    if not pcall(function() f.Parent = target end) then f.Parent = WS end
    espContainer = f
    return f
end

local function newLine(col)
    local l = DrawingLib.new("Line")
    l.Thickness = ESP.thickness
    l.Transparency = ESP.transparency * 0.6
    l.Color = col
    l.Visible = false
    return l
end

local function makeEsp(char, i)
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart") or head
    if not root then return nil end

    local d = { root = root, head = head, style = ESP.style }
    local col = espColor(i)
    local container = getEspContainer()

    if ESP.box then
        if ESP.style == "corner" and DrawingLib then
            d.corners = {}
            for _ = 1, 8 do d.corners[#d.corners + 1] = newLine(col) end
        else
            local box = Instance.new("BoxHandleAdornment")
            box.Name = ESP.stealth and rnd(8) or "SleepEspBox"
            box.Adornee = root
            box.Size = Vector3.new(4, 5.5, 1.2)
            box.AlwaysOnTop = true
            box.ZIndex = 5
            box.Transparency = ESP.transparency
            box.Color3 = col
            box.Archivable = false
            box.Parent = container
            d.box = box
        end
    end

    if head then
        local bb = Instance.new("BillboardGui")
        bb.Name = ESP.stealth and rnd(8) or "SleepEspTag"
        bb.AlwaysOnTop = true
        bb.Adornee = head
        bb.MaxDistance = ESP.maxDist
        bb.LightInfluence = 0
        bb.Archivable = false
        bb.Parent = container
        d.bb = bb

        local nm = Instance.new("TextLabel")
        nm.Size = UDim2.new(1, 0, 0, 16)
        nm.BackgroundTransparency = 1
        nm.Font = Enum.Font.GothamBold
        nm.TextSize = ESP.textSize
        nm.TextColor3 = col
        nm.TextStrokeTransparency = ESP.outline and 0.4 or 1
        nm.Text = char.Name
        nm.Parent = bb
        d.name = nm

        local ds = Instance.new("TextLabel")
        ds.Size = UDim2.new(1, 0, 0, 13)
        ds.BackgroundTransparency = 1
        ds.Font = Enum.Font.GothamMedium
        ds.TextSize = math.max(8, ESP.textSize - 2)
        ds.TextColor3 = Color3.fromRGB(220, 220, 230)
        ds.TextStrokeTransparency = ESP.outline and 0.5 or 1
        ds.Parent = bb
        d.dist = ds

        local hb = Instance.new("Frame")
        hb.Size = UDim2.new(1, -30, 0, 3)
        hb.Position = UDim2.new(0, 15, 1, -7)
        hb.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        hb.BorderSizePixel = 0
        hb.Parent = bb
        d.hpBg = hb

        local hf = Instance.new("Frame")
        hf.Size = UDim2.fromScale(1, 1)
        hf.BackgroundColor3 = OKC
        hf.BorderSizePixel = 0
        hf.Parent = hb
        d.hpFill = hf
    end

    if DrawingLib then d.line = newLine(col) end
    return d
end

local function destroyEsp(char)
    local d = espData[char]
    if not d then return end
    espData[char] = nil
    if d.box then pcall(function() d.box:Destroy() end) end
    if d.bb then pcall(function() d.bb:Destroy() end) end
    if d.corners then
        for _, l in ipairs(d.corners) do pcall(function() l:Remove() end) end
    end
    if d.line then pcall(function() d.line:Remove() end) end
end

local function clearEsp()
    for char in pairs(espData) do destroyEsp(char) end
    if espContainer then
        for _, o in ipairs(espContainer:GetChildren()) do pcall(function() o:Destroy() end) end
    end
end

local function updateCorners(d, col, cam, root, size)
    local hide = not ESP.box or ESP.style ~= "corner" or not cam or not root
    if hide then
        for _, l in ipairs(d.corners) do l.Visible = false end
        return
    end
    local topSp, topOn = cam:WorldToViewportPoint(root.Position + Vector3.new(0, size.Y / 2, 0))
    local botSp, botOn = cam:WorldToViewportPoint(root.Position - Vector3.new(0, size.Y / 2, 0))
    local h = math.abs(botSp.Y - topSp.Y)
    if not (topOn and botOn and topSp.Z > 0 and botSp.Z > 0 and h > 4) then
        for _, l in ipairs(d.corners) do l.Visible = false end
        return
    end
    local w = h * math.clamp(size.X / math.max(size.Y, 0.1), 0.35, 1.1)
    local cx = (topSp.X + botSp.X) / 2
    local cy = (topSp.Y + botSp.Y) / 2
    local len = math.max(3, math.min(w, h) * 0.22)
    local left, right = cx - w / 2, cx + w / 2
    local top, bottom = cy - h / 2, cy + h / 2
    local segs = {
        { left, top, left + len, top }, { left, top, left, top + len },
        { right, top, right - len, top }, { right, top, right, top + len },
        { left, bottom, left + len, bottom }, { left, bottom, left, bottom - len },
        { right, bottom, right - len, bottom }, { right, bottom, right, bottom - len },
    }
    for i, s in ipairs(segs) do
        local l = d.corners[i]
        if l then
            l.From = Vector2.new(s[1], s[2])
            l.To = Vector2.new(s[3], s[4])
            l.Color = col
            l.Thickness = ESP.thickness
            l.Transparency = ESP.transparency * 0.6
            l.Visible = true
        end
    end
end

local function espStep()
    local cam = WS.CurrentCamera
    local camPos = cam and cam.CFrame.Position or Vector3.zero
    local list = espTargets()
    local alive = {}

    for i, char in ipairs(list) do
        alive[char] = true
        local head = char:FindFirstChild("Head")
        local root = char:FindFirstChild("HumanoidRootPart") or head
        local hum = char:FindFirstChildOfClass("Humanoid")
        local dist = root and (root.Position - camPos).Magnitude or 0

        local d = espData[char]
        if not d or d.root ~= root or not d.root.Parent or d.style ~= ESP.style then
            if d then destroyEsp(char) end
            d = makeEsp(char, i)
            if d then espData[char] = d end
        end

        if d then
            local col = espColor(i)
            local show = dist <= ESP.maxDist
            local boxOn = show and ESP.box
            local okB, _, size = pcall(function() return char:GetBoundingBox() end)
            if not (okB and size) then size = Vector3.new(4, 5.5, 1.2) end

            if d.box then
                d.box.Color3 = col
                d.box.Visible = boxOn
                if boxOn then
                    d.box.Size = Vector3.new(math.max(size.X, 1), math.max(size.Y, 1), math.max(size.Z, 1))
                end
            end
            if d.corners then
                if boxOn then updateCorners(d, col, cam, root, size)
                else for _, l in ipairs(d.corners) do l.Visible = false end end
            end

            if d.bb then
                local tagOn = show and (ESP.name or ESP.dist or ESP.health)
                d.bb.Enabled = tagOn
                if tagOn then
                    d.bb.Size = UDim2.fromOffset(70 + ESP.textSize * 9, 18 + ESP.textSize * 2.2)
                    d.bb.StudsOffset = Vector3.new(0, math.max(size.Y / 2 + 0.7, 2.2), 0)
                    if d.name then
                        d.name.Visible = ESP.name
                        d.name.TextColor3 = col
                        d.name.Text = char.Name
                    end
                    if d.dist then
                        d.dist.Visible = ESP.dist
                        d.dist.Text = "[" .. math.floor(dist) .. "m]"
                    end
                    if d.hpBg and d.hpFill then
                        local showHp = ESP.health and hum ~= nil
                        d.hpBg.Visible = showHp
                        if showHp then
                            local r = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                            d.hpFill.Size = UDim2.fromScale(r, 1)
                            d.hpFill.BackgroundColor3 = Color3.fromRGB(
                                math.floor(255 * (1 - r) + 120 * r), math.floor(60 + 160 * r), 90)
                        end
                    end
                end
            end

            if d.line then
                if show and ESP.tracer and cam and root then
                    local sp, onScreen = cam:WorldToViewportPoint(root.Position)
                    if onScreen and sp.Z > 0 then
                        d.line.Visible = true
                        d.line.Color = col
                        d.line.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                        d.line.To = Vector2.new(sp.X, sp.Y)
                    else
                        d.line.Visible = false
                    end
                else
                    d.line.Visible = false
                end
            end
        end
    end

    for char in pairs(espData) do
        if not alive[char] then destroyEsp(char) end
    end
end

task.spawn(function()
    while true do
        local r = ESP.rate
        task.wait(r + (ESP.stealth and math.random() * r * 0.6 or 0))
        if ESP.on then
            espHue = (espHue + 0.006) % 1
            pcall(espStep)
        end
    end
end)

-- ============================== fov ==============================

local FOV_MIN, FOV_MAX = 20, 120
local FOV_EPS  = 0.05 -- порог «значение наше»
local FOV_JUMP = 1.2  -- рывок игры, после которого уступаем
local FOV_HOLD = 0.45 -- сколько уступаем
local FOV_MAXY = 1.6  -- максимум уступания подряд
local FOV_COOL = 0.6  -- пауза перед повторным уступанием

local F = {
    on = false,
    yieldZoom = true,
    wheel = true,
    target = 70,
    cur = 70,
    wrote = nil,
    lastGame = nil,
    before = nil,
    smooth = 0.35,
    cam = nil,
    yielding = false,
    yieldStart = 0,
    yieldUntil = 0,
    armAt = 0,
}

local function fovClamp(v)
    if v ~= v then return 70 end
    return math.clamp(v, FOV_MIN, FOV_MAX)
end

local function fovAlpha(dt)
    if F.smooth <= 0.02 then return 1 end
    local speed = 2 + (1 - F.smooth) * 42
    return 1 - math.exp(-speed * math.max(dt, 0.001))
end

local function fovBind(cam)
    F.cam = cam
    F.cur = cam and cam.FieldOfView or 70
    F.wrote = F.cur
    F.lastGame = nil
    F.yielding = false
    F.yieldStart, F.yieldUntil, F.armAt = 0, 0, 0
end

local function fovWrite(v)
    local cam = WS.CurrentCamera
    if not cam then return end
    v = fovClamp(v)
    if math.abs(cam.FieldOfView - v) > 0.005 then
        pcall(function() cam.FieldOfView = v end)
    end
    F.wrote, F.cur = v, v
end

local function fovStep(dt)
    if not F.on then return end
    local cam = WS.CurrentCamera
    if not cam then return end
    if cam ~= F.cam or F.wrote == nil then fovBind(cam) end

    local now = os.clock()
    local cur = cam.FieldOfView
    local ours = math.abs(cur - F.wrote) <= FOV_EPS
    local gameDelta = 0

    if ours then
        F.lastGame = nil
    else
        gameDelta = math.abs(cur - (F.lastGame or cur))
        F.lastGame = cur
    end

    if F.yielding then
        if gameDelta > FOV_JUMP then
            local cap = (F.yieldStart > 0 and F.yieldStart or now) + FOV_MAXY
            F.yieldUntil = math.min(F.yieldUntil + FOV_HOLD, cap)
        end
        if now < F.yieldUntil then
            F.cur, F.wrote = cur, cur
            return
        end
        F.yielding = false
        F.cur = cur
        F.armAt = now + FOV_COOL
    elseif F.yieldZoom and gameDelta > FOV_JUMP and now >= F.armAt then
        F.yielding = true
        F.yieldStart = now
        F.yieldUntil = now + FOV_HOLD
        F.cur, F.wrote = cur, cur
        return
    end

    local want = fovClamp(F.target)
    local nextv = F.cur + (want - F.cur) * fovAlpha(dt)
    if math.abs(nextv - want) < 0.02 then nextv = want end
    fovWrite(nextv)
end

local function fovSet(v)
    local cam = WS.CurrentCamera
    if not cam then return end
    if not F.on then F.before = cam.FieldOfView end
    if cam ~= F.cam or F.wrote == nil then fovBind(cam) end
    F.target = fovClamp(v)
    F.on = true
    F.yielding = false
    F.yieldStart, F.yieldUntil, F.armAt = 0, 0, 0
    fovStep(0.12)
end

local function fovYield(v)
    F.yieldZoom = v
    if not v then
        F.yielding = false
        F.yieldUntil, F.armAt = 0, 0
    end
end

local function fovRelease()
    F.on = false
    local cam = WS.CurrentCamera
    if cam and F.before then pcall(function() cam.FieldOfView = F.before end) end
    F.before = nil
    F.yielding = false
    F.cam, F.wrote, F.lastGame = nil, nil, nil
    F.yieldStart, F.yieldUntil, F.armAt = 0, 0, 0
end

local function fovHold(seconds)
    local now = os.clock()
    F.yielding = true
    F.yieldStart = now
    F.yieldUntil = now + seconds
end

local function fovWheel(dir)
    if not F.on then return end
    F.target = fovClamp(F.target + 4 * dir)
    F.yielding = false
    F.yieldUntil, F.armAt = 0, 0
end

local fovBound = pcall(function()
    RunS:BindToRenderStep("SleepFov", Enum.RenderPriority.Last.Value - 5, safe("fov", fovStep))
end)
if not fovBound then track(RunS.Heartbeat:Connect(safe("fov", fovStep))) end

track(WS:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    F.cam, F.wrote, F.lastGame = nil, nil, nil
    fovHold(0.8)
end))

track(UIS.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
    if not F.on or not F.wheel then return end
    if UIS:GetFocusedTextBox() then return end
    fovWheel(input.Position.Z > 0 and -1 or 1)
end))

-- ============================== прыжок ==============================

local lastJump, airJumps = 0, 0
local function infJump(auto)
    if not CONFIG.infJump then return end
    local now = os.clock()
    if now - lastJump < (auto and 0.15 or 0.04) then return end
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local root = hum.RootPart
    if not root or root.Anchored then return end
    if hum.FloorMaterial == Enum.Material.Air then
        if CONFIG.jumpLimit >= 0 and airJumps >= CONFIG.jumpLimit then return end
        airJumps = airJumps + 1
    else
        airJumps = 0
    end
    lastJump = now
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    local jp = hum.JumpPower
    if not hum.UseJumpPower then jp = math.sqrt(2 * WS.Gravity * hum.JumpHeight) end
    if jp and jp > 0 then
        local v = root.AssemblyLinearVelocity
        if v.Y < jp * 0.95 then root.AssemblyLinearVelocity = Vector3.new(v.X, jp, v.Z) end
    end
end

track(UIS.JumpRequest:Connect(function() pcall(infJump) end))

-- ============================== небо ==============================

local NIGHT = {
    Bk = "rbxassetid://159454299", Dn = "rbxassetid://159454296", Ft = "rbxassetid://159454293",
    Lf = "rbxassetid://159454290", Rt = "rbxassetid://159454287", Up = "rbxassetid://159454284",
}
local CLASSIC = {
    Bk = "rbxasset://textures/sky/sky512_bk.tex", Dn = "rbxasset://textures/sky/sky512_dn.tex",
    Ft = "rbxasset://textures/sky/sky512_ft.tex", Lf = "rbxasset://textures/sky/sky512_lf.tex",
    Rt = "rbxasset://textures/sky/sky512_rt.tex", Up = "rbxasset://textures/sky/sky512_up.tex",
}
local SKY = { mode = "off", stars = 0, fog = 600, clock = 1, tint = Color3.new(), ambient = Color3.new(), outdoor = Color3.new(), brightness = 1 }

local PRESETS = {
    night    = { set = NIGHT,   clock = 1,    stars = 800,  fog = 700,  tint = Color3.fromRGB(0, 0, 0),       ambient = Color3.fromRGB(12, 12, 20),  outdoor = Color3.fromRGB(20, 20, 32),  brightness = 1.0 },
    space    = { set = NIGHT,   clock = 0,    stars = 3000, fog = 6000, tint = Color3.fromRGB(0, 0, 0),       ambient = Color3.fromRGB(0, 0, 0),     outdoor = Color3.fromRGB(10, 10, 18),  brightness = 0.4 },
    sunset   = { set = NIGHT,   clock = 18.2, stars = 150,  fog = 1500, tint = Color3.fromRGB(60, 30, 24),    ambient = Color3.fromRGB(42, 22, 26),  outdoor = Color3.fromRGB(84, 46, 40),  brightness = 1.2 },
    classic  = { set = CLASSIC, clock = 14,   stars = 0,    fog = 6000, tint = Color3.fromRGB(140, 170, 200), brightness = 2.0 },
    overcast = { set = CLASSIC, clock = 13,   stars = 0,    fog = 800,  tint = Color3.fromRGB(118, 122, 130), ambient = Color3.fromRGB(70, 72, 78),  outdoor = Color3.fromRGB(92, 94, 100), brightness = 1.4 },
    dusk     = { set = CLASSIC, clock = 17.6, stars = 60,   fog = 1800, tint = Color3.fromRGB(70, 55, 80),    ambient = Color3.fromRGB(45, 38, 55),  outdoor = Color3.fromRGB(70, 55, 80),  brightness = 1.1 },
    void     = { set = nil,     clock = 1,    stars = 0,    fog = 600,  tint = Color3.fromRGB(0, 0, 0),       ambient = Color3.fromRGB(0, 0, 0),     outdoor = Color3.fromRGB(0, 0, 0),     brightness = 0.6 },
    inferno  = { set = nil,     clock = 17,   stars = 0,    fog = 420,  tint = Color3.fromRGB(72, 14, 8),     ambient = Color3.fromRGB(44, 12, 8),   outdoor = Color3.fromRGB(62, 20, 12),  brightness = 1.2 },
    ice      = { set = nil,     clock = 10,   stars = 0,    fog = 520,  tint = Color3.fromRGB(150, 180, 205), ambient = Color3.fromRGB(32, 42, 52),  outdoor = Color3.fromRGB(46, 62, 78),  brightness = 1.4 },
    matrix   = { set = nil,     clock = 2,    stars = 0,    fog = 460,  tint = Color3.fromRGB(6, 42, 12),     ambient = Color3.fromRGB(4, 18, 6),    outdoor = Color3.fromRGB(8, 30, 10),   brightness = 0.9 },
    blood    = { set = nil,     clock = 0,    stars = 0,    fog = 340,  tint = Color3.fromRGB(58, 6, 6),      ambient = Color3.fromRGB(30, 4, 4),    outdoor = Color3.fromRGB(44, 8, 8),    brightness = 0.8 },
}

local skySaved, ourSky

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
    if not p then restoreLighting() return end

    if not skySaved then
        skySaved = {
            sky = Lighting:FindFirstChildOfClass("Sky"),
            ambient = Lighting.Ambient, outdoor = Lighting.OutdoorAmbient,
            brightness = Lighting.Brightness, fogColor = Lighting.FogColor,
            fogStart = Lighting.FogStart, fogEnd = Lighting.FogEnd, clock = Lighting.ClockTime,
        }
    end

    if ourSky then pcall(function() ourSky:Destroy() end) ourSky = nil end
    local gameSky = Lighting:FindFirstChildOfClass("Sky")
    if gameSky and gameSky ~= skySaved.sky then pcall(function() gameSky.Parent = nil end) end
    if skySaved.sky then pcall(function() skySaved.sky.Parent = nil end) end

    SKY.stars, SKY.fog, SKY.clock, SKY.tint = p.stars, p.fog, p.clock, p.tint
    SKY.ambient = p.ambient or skySaved.ambient
    SKY.outdoor = p.outdoor or skySaved.outdoor
    SKY.brightness = p.brightness or skySaved.brightness

    if p.set then
        ourSky = Instance.new("Sky")
        ourSky.SkyboxBk, ourSky.SkyboxDn, ourSky.SkyboxFt = p.set.Bk, p.set.Dn, p.set.Ft
        ourSky.SkyboxLf, ourSky.SkyboxRt, ourSky.SkyboxUp = p.set.Lf, p.set.Rt, p.set.Up
        ourSky.StarCount = SKY.stars
        ourSky.CelestialBodiesShown = true
        ourSky.SunAngularSize, ourSky.MoonAngularSize = 11, 14
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
        if not ourSky or not ourSky.Parent then applySky(SKY.mode) return end
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
local killedFx, killedParts = {}, {}

local function isEmitter(d)
    return d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail")
        or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles")
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
        orig.wave, orig.refl, orig.deco = t.WaterWaveSize, t.WaterReflectance, t.Decoration
    end
end

local function setQuality(off)
    if off then
        capture()
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    elseif orig.done then
        pcall(function() settings().Rendering.QualityLevel = orig.quality or Enum.QualityLevel.Automatic end)
    end
end

local function setShadows(off)
    if off then
        capture()
        Lighting.GlobalShadows = false
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
    elseif orig.done then
        Lighting.GlobalShadows = orig.shadows ~= false
        Lighting.EnvironmentDiffuseScale = orig.diffuse or 1
        Lighting.EnvironmentSpecularScale = orig.spec or 1
    end
end

local function setPostFx(off)
    if off then
        for _, d in ipairs(Lighting:GetChildren()) do
            if d:IsA("PostEffect") and d.Enabled then
                d.Enabled = false
                killedFx[#killedFx + 1] = d
            end
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
            if isEmitter(d) and d.Enabled and not d:GetAttribute("SleepAura") then
                d.Enabled = false
                killedParts[#killedParts + 1] = d
                n = n + 1
                if n > 6000 then break end
            end
        end
        pcall(function()
            local t = WS:FindFirstChildOfClass("Terrain")
            if t then
                t.WaterWaveSize, t.WaterReflectance, t.Decoration = 0, 0, false
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
    if type(setfpscap) == "function" then pcall(setfpscap, FPS.boost and v or 9999) end
end

local function syncFps()
    setQuality(FPS.boost)
    setShadows(FPS.boost and FPS.shadowsOff)
    setPostFx(FPS.boost and FPS.fxOff)
    setParticles(FPS.boost and FPS.partsOff)
    setCap(FPS.cap)
end

track(WS.DescendantAdded:Connect(function(d)
    if not FPS.boost or not FPS.partsOff then return end
    if isEmitter(d) and not d:GetAttribute("SleepAura") then
        d.Enabled = false
        killedParts[#killedParts + 1] = d
    end
end))

track(Lighting.ChildAdded:Connect(function(d)
    if not FPS.boost or not FPS.fxOff then return end
    if d:IsA("PostEffect") then
        d.Enabled = false
        killedFx[#killedFx + 1] = d
    end
end))

-- ============================== фиксация ==============================

local function enforce()
    if not partsFolder or not partsFolder.Parent then pcall(getFolder) end
    local list = targets()
    if #list == 0 then return end

    for _, char in ipairs(list) do
        if CONFIG.headless then pcall(applyHeadless, char, true) end
        if CONFIG.korblox then pcall(applyKorblox, char, true) end
    end

    local mine = LP.Character
    if mine and AURA.on then pcall(applyAura, mine, true) end
    pcall(cleanupParts, list)

    if accCurrent ~= 0 then
        if accState == "ready" and not hasAcc() and os.clock() - accMountAt > 0.4 then
            accMountAt = os.clock()
            pcall(mountAcc)
        elseif accState == "failed" and os.clock() - accFailAt > 3 then
            loadAccAsync(accCurrent)
        end
    end

    if SKY.mode ~= "off" then pcall(syncSky) end
end

local function slowTick()
    pcall(noclipTick)
    if FPS.boost then
        if FPS.partsOff then
            for _, d in ipairs(killedParts) do
                if d.Parent and d.Enabled then pcall(function() d.Enabled = false end) end
            end
        end
        for _, d in ipairs(killedFx) do
            if d.Parent and d.Enabled then pcall(function() d.Enabled = false end) end
        end
    end
    if CONFIG.infJump then
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.FloorMaterial ~= Enum.Material.Air then
            airJumps = 0
            if CONFIG.jumpLimit == 0 and UIS:IsKeyDown(Enum.KeyCode.Space) then pcall(infJump, true) end
        end
    end
end

local tickAcc, slowAcc = 0, 0
local function loop(dt)
    tickAcc = tickAcc + dt
    if tickAcc >= (CONFIG.force and 0.05 or 0.1) then
        tickAcc = 0
        enforce()
    end
    slowAcc = slowAcc + dt
    if slowAcc >= 0.25 then
        slowAcc = 0
        slowTick()
    end
end

local bound = false
pcall(function()
    RunS:BindToRenderStep("SleepLoop", Enum.RenderPriority.Last.Value - 1, safe("loop", loop))
    bound = true
end)
if not bound then track(RunS.Heartbeat:Connect(safe("loop", loop))) end

-- ============================== слежение ==============================

local watched = setmetatable({}, { __mode = "k" })
local healthGuard = false

local function watchChar(char)
    if not char or watched[char] then return end
    watched[char] = true
    meshCache = nil
    cmTries[char], charMode[char] = nil, nil
    airJumps = 0
    accMountAt = 0
    accState = accTemplate and "ready" or "idle"
    fovHold(1.2)

    enforce()
    for _, d in ipairs({ 0.2, 0.6, 1.2, 2.4 }) do task.delay(d, enforce) end

    if accCurrent ~= 0 and not accTemplate then
        task.delay(0.5, function()
            if accCurrent ~= 0 and not accTemplate and accState ~= "loading" then loadAccAsync(accCurrent) end
        end)
    end

    track(char.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") then
            hookPart(d)
            if noclipActive then pcall(noclipOne, d, true) end
            task.defer(enforce)
        elseif d:IsA("Accessory") or d:IsA("Hat") or d:IsA("Decal") or d:IsA("CharacterMesh") then
            task.defer(enforce)
        end
    end))

    track(char.ChildAdded:Connect(function(d)
        if CONFIG.korblox and d:IsA("CharacterMesh") and d.BodyPart == Enum.BodyPart.RightLeg
            and d.Name ~= "SleepKorblox" then
            pcall(function() d:Destroy() end)
            task.defer(enforce)
        end
    end))

    track(char.ChildRemoved:Connect(function(d)
        if not CONFIG.korblox then return end
        if d.Name == "SleepKorblox" or (d:IsA("CharacterMesh") and d.BodyPart == Enum.BodyPart.RightLeg) then
            task.defer(enforce)
        end
    end))

    track(char.AncestryChanged:Connect(function() task.defer(enforce) end))

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        track(hum:GetPropertyChangedSignal("Health"):Connect(function()
            if not PROTECT.godHealth or healthGuard then return end
            if hum.Health < hum.MaxHealth then
                healthGuard = true
                pcall(function() hum.Health = hum.MaxHealth end)
                healthGuard = false
            end
        end))
        track(hum.Died:Connect(function()
            for _, d in ipairs({ 0.2, 0.8 }) do task.delay(d, enforce) end
        end))
    end
end

if LP.Character then watchChar(LP.Character) end
track(LP.CharacterAdded:Connect(watchChar))
track(LP.CharacterAppearanceLoaded:Connect(function()
    fovHold(1)
    enforce()
end))

task.spawn(function()
    while true do
        task.wait(0.5)
        local c = myChar()
        if c and not watched[c] then watchChar(c) end
        if LP.Character and not watched[LP.Character] then watchChar(LP.Character) end
    end
end)

-- ============================== меню ==============================

local gui, panel, open, shellRef
local pages, tabBtns = {}, {}
local statusLabel
local setHeadless, setKorblox, setForce, setBoost, setInf, setAura, setNoClip, setEsp, setProtect, setGod

local function tw(o, t, p) TweenS:Create(o, TweenInfo.new(t), p):Play() end
local function corner(o, r) Instance.new("UICorner", o).CornerRadius = UDim.new(0, r) end

local function section(text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 0, 14)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.TextSize = 9
    l.TextColor3 = Color3.fromRGB(150, 140, 200)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = "  " .. text
    l.Parent = panel
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -10, 0, 1)
    line.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
    line.BorderSizePixel = 0
    line.Parent = panel
end

local function hoverFx(b)
    track(b.MouseEnter:Connect(function() tw(b, 0.12, { BackgroundColor3 = HOVER }) end))
    track(b.MouseLeave:Connect(function() tw(b, 0.12, { BackgroundColor3 = ROW }) end))
end

local function row(text, default, cb, h)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1, -10, 0, h or 28)
    r.BackgroundColor3 = ROW
    r.BorderSizePixel = 0
    r.Parent = panel
    corner(r, 7)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -54, 1, 0)
    l.Position = UDim2.fromOffset(10, 0)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = 12
    l.TextColor3 = TEXT
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = text
    l.Parent = r

    local t = Instance.new("Frame")
    t.Size = UDim2.fromOffset(30, 15)
    t.Position = UDim2.new(1, -40, 0.5, -7)
    t.BackgroundColor3 = default and ACCENT or OFF
    t.BorderSizePixel = 0
    t.Parent = r
    Instance.new("UICorner", t).CornerRadius = UDim.new(1, 0)

    local k = Instance.new("Frame")
    k.Size = UDim2.fromOffset(9, 9)
    k.Position = default and UDim2.fromOffset(18, 3) or UDim2.fromOffset(3, 3)
    k.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    k.BorderSizePixel = 0
    k.Parent = t
    Instance.new("UICorner", k).CornerRadius = UDim.new(1, 0)

    local state = default
    local function paint(v)
        tw(t, 0.12, { BackgroundColor3 = v and ACCENT or OFF })
        tw(k, 0.12, { Position = v and UDim2.fromOffset(18, 3) or UDim2.fromOffset(3, 3) })
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
    hoverFx(r)

    return function(v)
        state = v
        paint(v)
        task.spawn(function() pcall(cb, v) end)
    end
end

local function button(text, cb, highlight)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1, -10, 0, 27)
    r.BackgroundColor3 = ROW
    r.BorderSizePixel = 0
    r.Parent = panel
    corner(r, 7)

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
        task.delay(0.22, function() tw(l, 0.2, { TextColor3 = highlight and ACCENT or TEXT }) end)
        task.spawn(function() pcall(cb) end)
    end)
    hoverFx(r)
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
    corner(b, 6)
    if color then
        local dot = Instance.new("Frame")
        dot.Size = UDim2.fromOffset(7, 7)
        dot.Position = UDim2.new(0, 6, 0.5, -3.5)
        dot.BackgroundColor3 = color
        dot.BorderSizePixel = 0
        dot.Parent = b
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        b.TextXAlignment = Enum.TextXAlignment.Center
        b.Text = "    " .. text
    end
    b.MouseButton1Click:Connect(function()
        tw(b, 0.1, { BackgroundColor3 = ACCENT })
        task.delay(0.18, function() tw(b, 0.2, { BackgroundColor3 = ROW }) end)
        task.spawn(function() pcall(cb) end)
    end)
    hoverFx(b)
    return b
end

local function gridBox(rows)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, rows * 28)
    f.BackgroundTransparency = 1
    f.Parent = panel
    local g = Instance.new("UIGridLayout", f)
    g.CellSize = UDim2.new(0.25, -4, 0, 24)
    g.CellPadding = UDim2.fromOffset(4, 4)
    return f
end

local function slider(text, min, max, default, cb, step, fmt)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1, -10, 0, 38)
    r.BackgroundColor3 = ROW
    r.BorderSizePixel = 0
    r.Parent = panel
    corner(r, 7)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -50, 0, 15)
    l.Position = UDim2.fromOffset(10, 5)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = 11
    l.TextColor3 = TEXT
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = text
    l.Parent = r

    local v = Instance.new("TextLabel")
    v.Size = UDim2.fromOffset(42, 15)
    v.Position = UDim2.new(1, -50, 0, 5)
    v.BackgroundTransparency = 1
    v.Font = Enum.Font.GothamBold
    v.TextSize = 11
    v.TextColor3 = ACCENT
    v.TextXAlignment = Enum.TextXAlignment.Right
    v.Text = fmt and fmt(default) or tostring(default)
    v.Parent = r

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 3)
    bar.Position = UDim2.fromOffset(10, 26)
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
    if not shellRef then return end
    open = force ~= nil and force or not open
    if open then
        shellRef.Visible = true
        shellRef.BackgroundTransparency = 1
        tw(shellRef, 0.18, { BackgroundTransparency = 0.03 })
    else
        tw(shellRef, 0.14, { BackgroundTransparency = 1 })
        task.delay(0.15, function()
            if not open and shellRef then shellRef.Visible = false end
        end)
    end
end

local function setTab(id)
    for k, p in pairs(pages) do p.Visible = (k == id) end
    for k, b in pairs(tabBtns) do
        tw(b, 0.12, { BackgroundColor3 = (k == id) and ACCENT or ROW })
        b.TextColor3 = (k == id) and BG or SUB
    end
end

local TABS = {
    { id = "look", label = "Внешка" },
    { id = "aura", label = "Аура" },
    { id = "esp",  label = "ESP" },
    { id = "head", label = "Голова" },
    { id = "move", label = "Движение" },
    { id = "cam",  label = "Камера" },
    { id = "sky",  label = "Небо" },
    { id = "fps",  label = "FPS" },
    { id = "misc", label = "Прочее" },
}

local function countActive()
    local n = 0
    if CONFIG.headless then n = n + 1 end
    if CONFIG.korblox then n = n + 1 end
    if CONFIG.noclip then n = n + 1 end
    if CONFIG.infJump then n = n + 1 end
    if AURA.on then n = n + 1 end
    if ESP.on then n = n + 1 end
    if PROTECT.parts then n = n + 1 end
    if FPS.boost then n = n + 1 end
    if SKY.mode ~= "off" then n = n + 1 end
    if accCurrent ~= 0 then n = n + 1 end
    if F.on then n = n + 1 end
    return n
end

local function build()
    gui = Instance.new("ScreenGui")
    gui.Name = rnd(9)
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 1000000
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Archivable = false
    G.VeniceCos = gui
    if not stealthGui(gui) then gui.Parent = LP:WaitForChild("PlayerGui") end

    local shell = Instance.new("Frame")
    shell.Position = UDim2.fromOffset(24, 80)
    shell.Size = UDim2.fromOffset(520, 360)
    shell.BackgroundColor3 = BG
    shell.BackgroundTransparency = 0.03
    shell.BorderSizePixel = 0
    shell.Visible = false
    shell.Parent = gui
    shellRef = shell
    corner(shell, 14)

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(BG, BG2)
    grad.Rotation = 90
    grad.Parent = shell

    local stroke = Instance.new("UIStroke", shell)
    stroke.Color = STROKE
    stroke.Transparency = 0.2
    stroke.Thickness = 1

    local head = Instance.new("Frame")
    head.Size = UDim2.new(1, 0, 0, 46)
    head.BackgroundTransparency = 1
    head.Parent = shell

    local strip = Instance.new("Frame")
    strip.Size = UDim2.fromOffset(3, 22)
    strip.Position = UDim2.fromOffset(14, 12)
    strip.BackgroundColor3 = ACCENT
    strip.BorderSizePixel = 0
    strip.Parent = head
    corner(strip, 2)
    local sgrad = Instance.new("UIGradient")
    sgrad.Color = ColorSequence.new(ACCENT, ACCENT2)
    sgrad.Rotation = 90
    sgrad.Parent = strip

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 0, 16)
    title.Position = UDim2.fromOffset(25, 9)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = TEXT
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "SLEEPSCRIPT"
    title.Parent = head

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -100, 0, 12)
    sub.Position = UDim2.fromOffset(25, 25)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.GothamMedium
    sub.TextSize = 9
    sub.TextColor3 = SUB
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Text = "cosmetics · esp · fps"
    sub.Parent = head

    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(24, 24)
    close.Position = UDim2.new(1, -34, 0, 11)
    close.BackgroundColor3 = ROW
    close.BorderSizePixel = 0
    close.AutoButtonColor = false
    close.Font = Enum.Font.GothamBold
    close.TextSize = 13
    close.TextColor3 = SUB
    close.Text = "×"
    close.Parent = head
    corner(close, 7)
    close.MouseButton1Click:Connect(function() setOpen(false) end)
    close.MouseEnter:Connect(function()
        tw(close, 0.12, { BackgroundColor3 = Color3.fromRGB(70, 40, 48), TextColor3 = Color3.fromRGB(255, 120, 120) })
    end)
    close.MouseLeave:Connect(function()
        tw(close, 0.12, { BackgroundColor3 = ROW, TextColor3 = SUB })
    end)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 22)
    bar.Position = UDim2.fromOffset(10, 48)
    bar.BackgroundTransparency = 1
    bar.Parent = shell
    local bl = Instance.new("UIListLayout", bar)
    bl.FillDirection = Enum.FillDirection.Horizontal
    bl.Padding = UDim.new(0, 4)
    bl.SortOrder = Enum.SortOrder.LayoutOrder

    for i, t in ipairs(TABS) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(50, 22)
        b.LayoutOrder = i
        b.BackgroundColor3 = ROW
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.Font = Enum.Font.GothamBold
        b.TextSize = 9
        b.TextColor3 = SUB
        b.Text = t.label
        b.Parent = bar
        corner(b, 6)
        tabBtns[t.id] = b
        b.MouseButton1Click:Connect(function() setTab(t.id) end)

        local p = Instance.new("ScrollingFrame")
        p.Size = UDim2.new(1, -14, 1, -104)
        p.Position = UDim2.fromOffset(8, 78)
        p.BackgroundTransparency = 1
        p.BorderSizePixel = 0
        p.ScrollBarThickness = 2
        p.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 84)
        p.CanvasSize = UDim2.new()
        p.AutomaticCanvasSize = Enum.AutomaticSize.Y
        p.Visible = false
        p.Parent = shell
        local lay = Instance.new("UIListLayout", p)
        lay.Padding = UDim.new(0, 4)
        pages[t.id] = p
    end

    local foot = Instance.new("Frame")
    foot.Size = UDim2.new(1, -16, 0, 18)
    foot.Position = UDim2.new(0, 8, 1, -22)
    foot.BackgroundTransparency = 1
    foot.Parent = shell

    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -8, 1, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.TextSize = 9
    statusLabel.TextColor3 = SUB
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Text = "активно: 0 · Z — меню"
    statusLabel.Parent = foot

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
    setForce = row("Жёсткая фиксация", CONFIG.force, function(v) CONFIG.force = v end, 26)

    panel = pages.aura
    section("ЦВЕТ")
    local cg = gridBox(2)
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
    local sg = gridBox(3)
    for _, s in ipairs(AURA_STYLES) do
        chip(sg, s.name, function()
            AURA.style = s.id
            if AURA.on then refreshAura() end
        end)
    end
    section("ПАРАМЕТРЫ")
    setAura = row("Аура", AURA.on, function(v)
        AURA.on = v
        if v then
            local c = myChar()
            if c then pcall(applyAura, c, true) end
        else
            clearAura()
        end
    end)
    slider("Размер", 0.3, 2.5, AURA.size, function(v)
        AURA.size = v
        if AURA.on then refreshAura() end
    end, 0.1, function(v) return string.format("%.1f", v) end)
    slider("Скорость цвета", 0.1, 3, AURA.speed, function(v) AURA.speed = v end, 0.1,
        function(v) return string.format("%.1f", v) end)
    slider("Скорость вращения", 0.1, 4, AURA.spin, function(v) AURA.spin = v end, 0.1,
        function(v) return string.format("%.1f", v) end)
    button("Убрать ауру", function() if setAura then setAura(false) end end)

    panel = pages.esp
    section("ОСНОВА")
    setEsp = row("ESP", ESP.on, function(v)
        ESP.on = v
        if v then task.spawn(function() pcall(espStep) end) else clearEsp() end
    end)
    section("ЭЛЕМЕНТЫ")
    row("Бокс", ESP.box, function(v) ESP.box = v end, 26)
    row("Имя", ESP.name, function(v) ESP.name = v end, 26)
    row("Дистанция", ESP.dist, function(v) ESP.dist = v end, 26)
    row("Здоровье", ESP.health, function(v) ESP.health = v end, 26)
    row("Линия к цели", ESP.tracer, function(v) ESP.tracer = v end, 26)
    section("СТИЛЬ БОКСА")
    local bgx = gridBox(1)
    chip(bgx, "Полный", function()
        ESP.style = "full"
        clearEsp()
        if ESP.on then task.spawn(function() pcall(espStep) end) end
    end)
    chip(bgx, "Уголки", function()
        ESP.style = "corner"
        clearEsp()
        if ESP.on then task.spawn(function() pcall(espStep) end) end
    end)
    section("ВИД")
    slider("Толщина", 1, 4, ESP.thickness, function(v) ESP.thickness = v end, 1)
    slider("Размер текста", 8, 22, ESP.textSize, function(v) ESP.textSize = v end, 1)
    slider("Дальность", 50, 2000, ESP.maxDist, function(v) ESP.maxDist = v end, 25)
    slider("Прозрачность", 0, 0.9, ESP.transparency, function(v) ESP.transparency = v end, 0.05,
        function(v) return string.format("%.2f", v) end)
    row("Обводка текста", ESP.outline, function(v) ESP.outline = v end, 26)
    section("ЦВЕТ ESP")
    local eg = gridBox(2)
    for _, c in ipairs(AURA_COLORS) do
        chip(eg, c.name, function()
            if c.mode == "rainbow" then
                ESP.rainbow = true
            else
                ESP.rainbow = false
                ESP.color = c.color
            end
        end, c.color)
    end
    section("АНТИ-ДЕТЕКТ")
    row("Скрытая папка и рандом имён", ESP.stealth, function(v)
        ESP.stealth = v
        clearEsp()
        espContainer = nil
    end)
    slider("Частота обновления", 0.05, 0.5, ESP.rate, function(v) ESP.rate = v end, 0.01,
        function(v) return string.format("%.2f", v) end)
    button("Пересобрать ESP", function()
        clearEsp()
        if ESP.on then task.spawn(function() pcall(espStep) end) end
    end)

    panel = pages.head
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
    end)

    panel = pages.move
    section("ПРЫЖОК")
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
    slider("FOV", FOV_MIN, FOV_MAX, F.target, fovSet, 1)
    row("Уступать зуму игры", F.yieldZoom, fovYield, 26)
    row("Колесо мыши", F.wheel, function(v) F.wheel = v end, 26)
    slider("Сглаживание", 0, 1, F.smooth, function(v) F.smooth = v end, 0.05,
        function(v) return string.format("%.2f", v) end)
    button("Сбросить FOV", fovRelease)

    local skyPage = pages.sky
    local sl = skyPage:FindFirstChildOfClass("UIListLayout")
    if sl then sl:Destroy() end
    local grid = Instance.new("UIGridLayout", skyPage)
    grid.CellSize = UDim2.new(0.333, -4, 0, 24)
    grid.CellPadding = UDim2.fromOffset(4, 4)
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
    section("ПРОИЗВОДИТЕЛЬНОСТЬ")
    setBoost = row("FPS Boost", FPS.boost, function(v)
        FPS.boost = v
        if v then
            FPS.shadowsOff, FPS.fxOff = true, true
        end
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
    section("КОЛЛИЗИИ")
    setNoClip = row("Ноклип", CONFIG.noclip, function(v) setNoclip(v) end)
    section("ЗАЩИТА")
    setProtect = row("Иммунитет к урону и чекпоинтам", PROTECT.parts, function(v)
        PROTECT.parts = v
        if v then scanHazards() else clearHazards() end
    end)
    setGod = row("Держать здоровье", PROTECT.godHealth, function(v)
        PROTECT.godHealth = v
        if v then
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then hum.Health = hum.MaxHealth end
        end
    end, 26)
    section("ПРОЧЕЕ")
    button("Аксессуар заново", function()
        if accCurrent == 0 then accCurrent = ACCS[1].id end
        reAcc()
    end)
    button("Переприменить", function()
        CONFIG.headless, CONFIG.korblox, CONFIG.force = true, true, true
        if setHeadless then setHeadless(true) end
        if setKorblox then setKorblox(true) end
        if setForce then setForce(true) end
        if accCurrent ~= 0 then reAcc() end
        refreshScan()
        syncFps()
        if PROTECT.parts then pcall(scanHazards) end
        if AURA.on then refreshAura() end
        if ESP.on then pcall(espStep) end
        if SKY.mode ~= "off" then pcall(applySky, SKY.mode) end
        if F.on then pcall(fovStep, 0.2) end
        for _ = 1, 6 do
            task.wait(0.12)
            enforce()
        end
        print("[Sleepscript] переприменено")
    end, true)
    button("Диагностика", function()
        print("[Sleepscript] целей:", #targets(), "| частей в папке:", partsFolder and #partsFolder:GetChildren() or 0)
        print("[Sleepscript] меш:", meshCache and "ок" or "нет", "| аксессуар:", accState, accLast)
        print("[Sleepscript] аура:", tostring(AURA.on), AURA.style, "| эмиттеров:", #auraEmitters)
        print("[Sleepscript] fps:", tostring(FPS.boost), "| ноклип:", tostring(noclipActive), "| под ноклипом:", (function()
            local n = 0
            for _ in pairs(noclipSaved) do n = n + 1 end
            return n
        end)())
        print("[Sleepscript] защита:", tostring(PROTECT.parts), "| здоровье:", tostring(PROTECT.godHealth))
        print("[Sleepscript] fov:", tostring(F.on), "| цель:", tostring(F.target), "| текущее:", tostring(F.cur), "| уступание:", tostring(F.yielding), "| зум-режим:", tostring(F.yieldZoom))
        print("[Sleepscript] esp:", tostring(ESP.on), "| Drawing:", DrawingLib and "есть" or "нет")
    end)
    button("Убрать всё", function()
        CONFIG.headless, CONFIG.korblox, CONFIG.force = false, false, false
        CONFIG.infJump = false
        AURA.on, ESP.on = false, false
        PROTECT.parts, PROTECT.godHealth = false, false
        accCurrent, accTemplate, accState = 0, nil, "idle"
        FPS.boost, FPS.shadowsOff, FPS.fxOff, FPS.partsOff = false, false, false, false
        if setHeadless then setHeadless(false) end
        if setKorblox then setKorblox(false) end
        if setForce then setForce(false) end
        if setBoost then setBoost(false) end
        if setInf then setInf(false) end
        if setAura then setAura(false) end
        if setNoClip then setNoClip(false) end
        if setEsp then setEsp(false) end
        if setProtect then setProtect(false) end
        if setGod then setGod(false) end
        pcall(restoreNoclip)
        pcall(clearHazards)
        syncFps()
        for _, c in ipairs(targets()) do
            pcall(applyHeadless, c, false)
            pcall(clearKorblox, c)
        end
        pcall(clearAura)
        pcall(clearAcc)
        pcall(clearEsp)
        pcall(applySky, "off")
        fovRelease()
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

    task.spawn(function()
        while true do
            task.wait(0.5)
            if statusLabel and statusLabel.Parent then
                statusLabel.Text = "активно: " .. countActive() .. " · Z — меню"
            end
        end
    end)

    gui.Destroying:Connect(function()
        pcall(function() RunS:UnbindFromRenderStep("SleepLoop") end)
        pcall(function() RunS:UnbindFromRenderStep("SleepFov") end)
        pcall(function() CAS:UnbindAction("SleepMenu") end)
        pcall(clearAura)
        pcall(clearEsp)
        pcall(restoreNoclip)
        if partsFolder then
            for _, o in ipairs(partsFolder:GetChildren()) do pcall(function() o:Destroy() end) end
        end
    end)

    print("[Sleepscript] загружено · Z меню")
end

local okBuild, errBuild = xpcall(build, debug.traceback)
if not okBuild then warn("[Sleepscript] ошибка UI: " .. tostring(errBuild)) end

local okTail, errTail = xpcall(function()
    pcall(function()
        CAS:BindActionAtPriority("SleepMenu", function(_, state, input)
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
        if gp or UIS:GetFocusedTextBox() then return end
        if input.KeyCode == Enum.KeyCode.Z then setOpen() end
    end))

    pcall(getFolder)
    task.wait(1)
    pcall(enforce)
end, debug.traceback)
if not okTail then warn("[Sleepscript] старт: " .. tostring(errTail)) end

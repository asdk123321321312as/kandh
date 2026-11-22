-- ===================== SLEEPSCRIPT =====================
if getgenv().Sleepscript then pcall(function() getgenv().Sleepscript:Destroy() end) end
if getgenv().VeniceCos then pcall(function() getgenv().VeniceCos:Destroy() end) end
if getgenv().SleepConns then
    for _, c in ipairs(getgenv().SleepConns) do pcall(function() c:Disconnect() end) end
end
getgenv().SleepConns = {} --пизда

local ref = cloneref or function(s) return s end
local Players  = ref(game:GetService("Players"))
local UIS      = ref(game:GetService("UserInputService"))
local TweenS   = ref(game:GetService("TweenService"))
local Lighting = ref(game:GetService("Lighting"))
local AssetS   = ref(game:GetService("AssetService"))
local RunS     = ref(game:GetService("RunService"))
local CAS      = ref(game:GetService("ContextActionService"))
local Stats    = ref(game:GetService("Stats"))
local WS       = ref(workspace)
local LP       = Players.LocalPlayer
while not LP do task.wait() end

local function track(c) table.insert(getgenv().SleepConns, c) return c end

-- ВСЁ ВЫКЛЮЧЕНО ПО УМОЛЧАНИЮ
local CONFIG = {
    korblox = false, headless = false, force = false,
    infJump = false, jumpLimit = -1,
    noclip = false,
}
local FPS = { boost = false, shadowsOff = false, fxOff = false, partsOff = false, cap = 240 }
local AURA = { on = false, size = 1, speed = 1, hue = 0, mode = "rainbow", color = Color3.fromRGB(152, 132, 255), style = "ring" }
local PROTECT = { parts = false, godHealth = false }
local HUD = { on = false }

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
local ACCENT2 = Color3.fromRGB(96, 220, 255)
local BG     = Color3.fromRGB(9, 9, 11)
local ROW    = Color3.fromRGB(23, 23, 28)
local OFF    = Color3.fromRGB(45, 45, 54)
local STROKE = Color3.fromRGB(48, 46, 62)
local TEXT   = Color3.fromRGB(238, 238, 244)
local SUB    = Color3.fromRGB(128, 128, 144)
local OKC    = Color3.fromRGB(120, 220, 160)
local WARN   = Color3.fromRGB(240, 200, 90)
local BAD    = Color3.fromRGB(235, 95, 95)

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

local tmpList, tmpSeen = {}, {}
local function targets()
    if os.clock() - scanAt > 0.3 then refreshScan() end
    table.clear(tmpList)
    table.clear(tmpSeen)
    addModel(tmpList, tmpSeen, LP.Character)
    local cam = WS.CurrentCamera
    if cam then
        local subj = cam.CameraSubject
        if subj then addModel(tmpList, tmpSeen, subj.Parent) end
    end
    local n = #scanCache
    for i = 1, n do addModel(tmpList, tmpSeen, scanCache[i]) end
    return tmpList
end

-- ============================== откат свойств ==============================

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
        if not acc:GetAttribute("SleepHat") then
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

local ACC_ATTR = "SleepHatPart"
local accLast = "не запускалось"
local accTemplate = nil
local accState = "idle"
local accMountAt = 0
local accFailAt = 0
local accCache = {}

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
    if accCache[id] then return accCache[id] end
    local errs = {}

    local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
    if ok and objs and #objs > 0 then
        local g = grab(objs)
        if g then accCache[id] = g return g end
        table.insert(errs, "GetObjects без частей")
    else
        table.insert(errs, "GetObjects")
    end

    local ok2, model = pcall(function() return game:GetService("InsertService"):LoadAsset(id) end)
    if ok2 and model then
        local g = grab(model:GetChildren())
        if g then accCache[id] = g return g end
        table.insert(errs, "LoadAsset без частей")
    else
        table.insert(errs, "LoadAsset")
    end

    return nil, table.concat(errs, " | ")
end

local function loadAccAsync(id)
    if accState == "loading" then return end
    accState = "loading"
    accLast = "загрузка ассета"
    task.spawn(function()
        local why = "?"
        for attempt = 1, 3 do
            local ok, res = pcall(function()
                local h, e = loadAcc(id)
                if not h then error(e or "нет частей") end
                return h
            end)
            if accCurrent ~= id then
                accState = "idle"
                return
            end
            if ok then
                accTemplate = res
                accState = "ready"
                accLast = "ассет готов"
                accMountAt = 0
                return
            end
            why = tostring(res)
            accLast = "ошибка: " .. why
            task.wait(0.5 * attempt)
        end
        accState = "failed"
        accFailAt = os.clock()
    end)
end

local function handleFrom(template)
    if template:IsA("Accessory") or template:IsA("Hat") then
        return template:FindFirstChild("Handle") or template:FindFirstChildWhichIsA("BasePart", true)
    end
    if template:IsA("BasePart") then return template end
    return template:FindFirstChildWhichIsA("BasePart", true)
end

local function mountAcc()
    if accState ~= "ready" or not accTemplate then return end
    if hasAcc() then return end
    local char = LP.Character or myChar()
    local head = char and char:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then
        accLast = "нет головы"
        return
    end

    local src = handleFrom(accTemplate)
    if not src then accState = "failed" accFailAt = os.clock() return end

    local handle = src:Clone()
    handle.Name = "SleepHatHandle"
    handle:SetAttribute(ACC_ATTR, true)
    handle.Anchored = false
    handle.CanCollide = false
    handle.CanQuery = false
    handle.CanTouch = false
    handle.CastShadow = true
    handle.Transparency = 0
    pcall(function() handle.Massless = true end)

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

    handle.Parent = getFolder()

    local w = Instance.new("WeldConstraint")
    w.Part0 = handle
    w.Part1 = head
    w.Parent = handle

    accLast = "надет"
end

local function setAcc(id)
    accCurrent = id
    pcall(clearAcc)
    accTemplate = nil
    accMountAt = 0
    if id == 0 then
        accState = "idle"
        accLast = "снято"
        return
    end
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
        if p:IsA("BasePart") and p.Name == "SleepKorbloxLeg" then
            local w = p:FindFirstChildWhichIsA("WeldConstraint")
            if w and w.Part1 and w.Part1:IsDescendantOf(char) then return p end
        end
    end
end

local function korbloxOk(char)
    if char:FindFirstChild("SleepKorblox") then return true end
    return findKorbloxPart(char) ~= nil
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
    if not upper then return end
    buildKorbloxLeg(char, upper, lower, foot)
end

local function cleanupParts(list)
    if not partsFolder or not partsFolder.Parent then return end
    for _, p in ipairs(partsFolder:GetChildren()) do
        local w = p:FindFirstChildWhichIsA("WeldConstraint")
        local alive = false
        if w then
            for i = 1, #list do
                local c = list[i]
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

-- ============================== ввод ==============================

local function inputDir()
    local cam = WS.CurrentCamera
    if not cam then return Vector3.zero end
    local cf = cam.CFrame
    local v = Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W) then v = v + cf.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then v = v - cf.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then v = v - cf.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then v = v + cf.RightVector end
    v = Vector3.new(v.X, 0, v.Z)
    if v.Magnitude > 0.01 then return v.Unit end
    return Vector3.zero
end

-- ============================== ноклип ==============================

local noclipSaved = {}
local noclipLock = false

local function unstick(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = hum and hum.RootPart
    if not root then return end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { char }
    local hit = WS:Raycast(root.Position + Vector3.new(0, 300, 0), Vector3.new(0, -700, 0), params)
    if hit and hit.Position.Y > root.Position.Y + 1.5 then
        local delta = math.min(hit.Position.Y - root.Position.Y + 3, 400)
        char:PivotTo(char:GetPivot() + Vector3.new(0, delta, 0))
        pcall(function() root.AssemblyLinearVelocity = Vector3.zero end)
    end
end

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

local function restoreNoclip()
    for d, o in pairs(noclipSaved) do
        if d.Parent then pcall(function() d.CanCollide = o end) end
        noclipSaved[d] = nil
    end
    table.clear(noclipSaved)
end

local function setNoClip(char, on)
    if on then
        if noclipLock then return end
        noclipLock = true
        if char then
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BasePart") then noclipOne(d, true) end
            end
        end
        noclipLock = false
        return
    end
    restoreNoclip()
    local mine = LP.Character or myChar()
    if mine then pcall(unstick, mine) end
end

task.spawn(function()
    while true do
        task.wait(0.1)
        if CONFIG.noclip then
            local c = LP.Character
            if c and not noclipLock then
                for _, d in ipairs(c:GetDescendants()) do
                    if d:IsA("BasePart") and d.CanCollide then noclipOne(d, true) end
                end
            end
        end
    end
end)

-- ============================== защита ==============================

local TOUCH_ATTR = "SleepOrigTouch"
local HAZ = {
    "kill", "damage", "dmg", "hurt", "lava", "spike", "saw", "trap", "hazard",
    "death", "die", "void", "poison", "acid", "burn", "crush", "squash",
    "checkpoint", "check_point", "respawn", "reset", "teleport", "killbrick",
}

local function isHazName(name)
    local n = name:lower()
    for i = 1, #HAZ do
        if n:find(HAZ[i], 1, true) then return true end
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
    print("[Sleep] защищено частей:", n)
end

local function clearHazards()
    for _, d in ipairs(WS:GetDescendants()) do
        if d:IsA("BasePart") and d:GetAttribute(TOUCH_ATTR) ~= nil then
            protectPart(d, false)
        end
    end
end

local function healNow()
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then pcall(function() hum.Health = hum.MaxHealth end) end
end

task.spawn(function()
    while true do
        task.wait(4)
        if PROTECT.parts then pcall(scanHazards) end
    end
end)

track(WS.DescendantAdded:Connect(function(d)
    if not PROTECT.parts then return end
    if d:IsA("BasePart") and isHazName(d.Name) then pcall(protectPart, d, true) end
end))

-- ============================== аура ==============================

local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local auraChar, auraParts, auraSpin = nil, nil, nil

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

local AURA_COLORS = {
    { name = "Радуга",   mode = "rainbow" },
    { name = "Фиолет",   color = Color3.fromRGB(152, 132, 255) },
    { name = "Индиго",   color = Color3.fromRGB(96, 92, 220) },
    { name = "Лиловый",  color = Color3.fromRGB(196, 130, 255) },
    { name = "Магента",  color = Color3.fromRGB(255, 60, 190) },
    { name = "Розовый",  color = Color3.fromRGB(255, 140, 200) },
    { name = "Красный",  color = Color3.fromRGB(255, 60, 60) },
    { name = "Коралл",   color = Color3.fromRGB(255, 120, 100) },
    { name = "Оранж",    color = Color3.fromRGB(255, 145, 40) },
    { name = "Янтарь",   color = Color3.fromRGB(255, 180, 70) },
    { name = "Золото",   color = Color3.fromRGB(255, 210, 70) },
    { name = "Лайм",     color = Color3.fromRGB(175, 255, 70) },
    { name = "Зелёный",  color = Color3.fromRGB(60, 230, 110) },
    { name = "Изумруд",  color = Color3.fromRGB(40, 220, 160) },
    { name = "Мята",     color = Color3.fromRGB(120, 255, 200) },
    { name = "Циан",     color = Color3.fromRGB(70, 230, 255) },
    { name = "Бирюза",   color = Color3.fromRGB(60, 200, 210) },
    { name = "Небо",     color = Color3.fromRGB(110, 175, 255) },
    { name = "Синий",    color = Color3.fromRGB(60, 110, 255) },
    { name = "Лаванда",  color = Color3.fromRGB(190, 170, 255) },
    { name = "Белый",    color = Color3.fromRGB(255, 255, 255) },
    { name = "Пепел",    color = Color3.fromRGB(190, 190, 205) },
}

local AURA_STYLES = {
    { name = "Кольцо",  id = "ring" },
    { name = "Туман",   id = "mist" },
    { name = "Вихрь",   id = "vortex" },
    { name = "Спираль", id = "spiral" },
    { name = "Взрыв",   id = "burst" },
    { name = "Ореол",   id = "halo" },
    { name = "Орбита",  id = "orbit" },
    { name = "Пульс",   id = "pulse" },
    { name = "Гроза",   id = "storm" },
    { name = "Снег",    id = "snow" },
    { name = "Пламя",   id = "flame" },
    { name = "Звёзды",  id = "stars" },
}

local function clearAura()
    if auraParts then
        for i = 1, #auraParts do pcall(function() auraParts[i]:Destroy() end) end
    end
    auraChar, auraParts, auraSpin = nil, nil, nil
end

local function auraBase(made, tex, rate)
    local e = Instance.new("ParticleEmitter")
    e.Texture = tex or SPARK
    e.LightEmission = 1
    e.LightInfluence = 0
    e.Color = auraSeq()
    e.Rate = rate
    e:SetAttribute("SleepAura", true)
    e:SetAttribute("SleepRate", rate)
    table.insert(made, e)
    return e
end

local function spinAtt(parent, made, radius, y, phase)
    local a = Instance.new("Attachment")
    a.Name = "SleepAuraSpin"
    a:SetAttribute("SleepAura", true)
    a:SetAttribute("R", radius)
    a:SetAttribute("Y", y)
    a:SetAttribute("Ph", phase or 0)
    a.Parent = parent
    table.insert(made, a)
    table.insert(auraSpin, a)
    return a
end

local function styleRing(att, made)
    local sz = AURA.size
    local e = auraBase(made, SPARK, 22 * sz)
    e.Shape = Enum.ParticleEmitterShape.Disc
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
    e.ShapePartial = 1
    e.Lifetime = NumberRange.new(0.6, 1.1)
    e.Speed = NumberRange.new(0.6, 2.2)
    e.Drag = 3
    e.Acceleration = Vector3.new(0, 2.6, 0)
    e.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5 * sz),
        NumberSequenceKeypoint.new(0.35, 0.85 * sz),
        NumberSequenceKeypoint.new(1, 0),
    })
    e.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(1, 1),
    })
    e.RotSpeed = NumberRange.new(-120, 120)
    e.Parent = att
end

local function styleMist(att, made)
    local sz = AURA.size
    local e = auraBase(made, SMOKE, 9 * sz)
    e.Shape = Enum.ParticleEmitterShape.Sphere
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
    e.ShapeRadius = 2.2
    e.Lifetime = NumberRange.new(1, 1.8)
    e.Speed = NumberRange.new(0.2, 0.9)
    e.Drag = 4
    e.Acceleration = Vector3.new(0, 1.1, 0)
    e.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.1 * sz),
        NumberSequenceKeypoint.new(1, 0),
    })
    e.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.55),
        NumberSequenceKeypoint.new(1, 1),
    })
    e.Parent = att
end

local function styleVortex(att, made)
    local sz = AURA.size
    local e = auraBase(made, SPARK, 30 * sz)
    e.Shape = Enum.ParticleEmitterShape.Disc
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
    e.ShapePartial = 1
    e.Lifetime = NumberRange.new(0.45, 0.85)
    e.Speed = NumberRange.new(1.6, 3.6)
    e.Drag = 7
    e.Acceleration = Vector3.new(0, 4.5, 0)
    e.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.55 * sz),
        NumberSequenceKeypoint.new(1, 0),
    })
    e.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 1),
    })
    e.RotSpeed = NumberRange.new(200, 420)
    e.Parent = att
end

local function styleSpiral(att, made)
    local sz = AURA.size
    local s = spinAtt(att, made, 1.7, 0, 0)
    local e = auraBase(made, SPARK, 55 * sz)
    e.Lifetime = NumberRange.new(0.8, 1.3)
    e.Speed = NumberRange.new(0.05, 0.2)
    e.Drag = 0
    e.Acceleration = Vector3.new(0, 1.4, 0)
    e.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5 * sz),
        NumberSequenceKeypoint.new(1, 0),
    })
    e.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    e.Parent = s
end

local function styleBurst(att, made)
    local sz = AURA.size
    local e = auraBase(made, SPARK, 110 * sz)
    e.Lifetime = NumberRange.new(0.3, 0.6)
    e.Speed = NumberRange.new(4, 9)
    e.Drag = 9
    e.Acceleration = Vector3.new(0, -2.5, 0)
    e.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.45 * sz),
        NumberSequenceKeypoint.new(1, 0),
    })
    e.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 1),
    })
    e.Parent = att
end

local function styleHalo(att, made)
    local sz = AURA.size
    local s = spinAtt(att, made, 0, 2.6, 0)
    local e = auraBase(made, SPARK, 14 * sz)
    e.Shape = Enum.ParticleEmitterShape.Disc
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
    e.ShapePartial = 1
    e.Lifetime = NumberRange.new(1, 1.6)
    e.Speed = NumberRange.new(0.1, 0.4)
    e.Acceleration = Vector3.new(0, 0.8, 0)
    e.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.45 * sz),
        NumberSequenceKeypoint.new(1, 0),
    })
    e.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    e.Parent = s
end

local function styleOrbit(att, made)
    local sz = AURA.size
    for i = 1, 3 do
        local s = spinAtt(att, made, 1.9 + i * 0.15, 0.4 * (i - 2), (i - 1) * 2.1)
        local e = auraBase(made, SPARK, 40 * sz)
        e.Lifetime = NumberRange.new(0.3, 0.45)
        e.Speed = NumberRange.new(0, 0.05)
        e.Drag = 0
        e.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.45 * sz),
            NumberSequenceKeypoint.new(1, 0),
        })
        e.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(1, 1),
        })
        e.Parent = s
    end
end

local function stylePulse(att, made)
    local sz = AURA.size
    local e = auraBase(made, SPARK, 34 * sz)
    e.Shape = Enum.ParticleEmitterShape.Disc
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
    e.ShapePartial = 1
    e.Lifetime = NumberRange.new(0.4, 0.7)
    e.Speed = NumberRange.new(1, 3)
    e.Drag = 5
    e.Acceleration = Vector3.new(0, 3, 0)
    e.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.6 * sz),
        NumberSequenceKeypoint.new(1, 0),
    })
    e.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 1),
    })
    e.Parent = att
end

local function styleStorm(att, made)
    local sz = AURA.size
    local e = auraBase(made, SPARK, 18 * sz)
    e.Shape = Enum.ParticleEmitterShape.Sphere
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
    e.ShapeRadius = 3
    e.Lifetime = NumberRange.new(0.5, 1)
    e.Speed = NumberRange.new(1, 4)
    e.Drag = 2
    e.Acceleration = Vector3.new(0, 1.5, 0)
    e.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5 * sz),
        NumberSequenceKeypoint.new(1, 0),
    })
    e.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(1, 1),
    })
    e.RotSpeed = NumberRange.new(-300, 300)
    e.Parent = att
end

local function styleSnow(att, made)
    local sz = AURA.size
    local e = auraBase(made, SPARK, 22 * sz)
    e.Shape = Enum.ParticleEmitterShape.Sphere
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
    e.ShapeRadius = 3.2
    e.Lifetime = NumberRange.new(1.5, 2.6)
    e.Speed = NumberRange.new(0.1, 0.5)
    e.Drag = 0.5
    e.Acceleration = Vector3.new(0, -2.6, 0)
    e.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.35 * sz),
        NumberSequenceKeypoint.new(1, 0.2 * sz),
    })
    e.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    e.RotSpeed = NumberRange.new(-60, 60)
    e.Parent = att
end

local function styleFlame(att, made)
    local sz = AURA.size
    local e = auraBase(made, SMOKE, 32 * sz)
    e.Shape = Enum.ParticleEmitterShape.Disc
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
    e.ShapePartial = 1
    e.Lifetime = NumberRange.new(0.4, 0.8)
    e.Speed = NumberRange.new(1, 3)
    e.Drag = 4
    e.Acceleration = Vector3.new(0, 6, 0)
    e.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8 * sz),
        NumberSequenceKeypoint.new(1, 0),
    })
    e.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.25),
        NumberSequenceKeypoint.new(1, 1),
    })
    e.RotSpeed = NumberRange.new(-90, 90)
    e.Parent = att
end

local function styleStars(att, made)
    local sz = AURA.size
    local e = auraBase(made, SPARK, 7 * sz)
    e.Shape = Enum.ParticleEmitterShape.Sphere
    e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
    e.ShapeRadius = 2.8
    e.Lifetime = NumberRange.new(1.5, 2.6)
    e.Speed = NumberRange.new(0, 0.1)
    e.Drag = 0
    e.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4 * sz),
        NumberSequenceKeypoint.new(0.5, 0.15 * sz),
        NumberSequenceKeypoint.new(1, 0),
    })
    e.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(0.5, 0.6),
        NumberSequenceKeypoint.new(1, 1),
    })
    e.Parent = att
end

local STYLE_FN = {
    ring = styleRing, mist = styleMist, vortex = styleVortex, spiral = styleSpiral,
    burst = styleBurst, halo = styleHalo, orbit = styleOrbit, pulse = stylePulse,
    storm = styleStorm, snow = styleSnow, flame = styleFlame, stars = styleStars,
}

local function applyAura(char, on)
    if not on then clearAura() return end
    if not char or auraChar == char then return end
    clearAura()

    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = (hum and hum.RootPart) or char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    if not root then return end

    local made, spins = {}, {}
    auraSpin = spins

    local ok = pcall(function()
        local att = Instance.new("Attachment")
        att.Name = "SleepAuraAtt"
        att.Orientation = Vector3.new(-90, 0, 0)
        att:SetAttribute("SleepAura", true)
        att.Parent = root
        table.insert(made, att)

        local fn = STYLE_FN[AURA.style] or styleRing
        fn(att, made)

        local light = Instance.new("PointLight")
        light.Name = "SleepAuraLight"
        light.Brightness = 2
        light.Range = 12
        light.Color = auraColor()
        light.Parent = att
        table.insert(made, light)

        local hl = Instance.new("Highlight")
        hl.Name = "SleepAuraHL"
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
        auraChar = char
        auraParts = made
    else
        for i = 1, #made do pcall(function() made[i]:Destroy() end) end
        auraSpin = nil
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
    local t = 0
    while true do
        local dt = task.wait(0.05)
        t = t + dt
        if auraChar and not auraChar.Parent then clearAura() end
        if AURA.on and auraChar and auraParts and auraSpin then
            if AURA.mode == "rainbow" then
                AURA.hue = (AURA.hue + dt * 0.22 * AURA.speed) % 1
                local c = rainbow(AURA.hue)
                local seq = rainbowSeq(AURA.hue)
                for i = 1, #auraParts do
                    local o = auraParts[i]
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
            local ph = t * AURA.speed * 1.6
            for i = 1, #auraSpin do
                local s = auraSpin[i]
                s.CFrame = CFrame.Angles(0, ph + (s:GetAttribute("Ph") or 0), 0)
                    * CFrame.new(s:GetAttribute("R") or 1.5, s:GetAttribute("Y") or 0, 0)
            end
            local mod = 0.55 + 0.45 * math.sin(t * 5 * AURA.speed)
            for i = 1, #auraParts do
                local o = auraParts[i]
                if o:IsA("ParticleEmitter") and o.Name:find("Pulse") then
                    o.Rate = (o:GetAttribute("SleepRate") or 20) * mod
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
    return d:GetAttribute("SleepAura") == true
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
        for i = 1, #killedFx do
            local d = killedFx[i]
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
        for i = 1, #killedParts do
            local d = killedParts[i]
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
            for i = 1, #killedParts do
                local d = killedParts[i]
                if d.Parent and d.Enabled then pcall(function() d.Enabled = false end) end
            end
            for i = 1, #killedFx do
                local d = killedFx[i]
                if d.Parent and d.Enabled then pcall(function() d.Enabled = false end) end
            end
        end
    end
end)

-- ============================== фиксация ==============================

local function enforce()
    if not partsFolder or not partsFolder.Parent then pcall(getFolder) end
    local list = targets()
    local n = #list

    if n > 0 and (CONFIG.headless or CONFIG.korblox) then
        for i = 1, n do
            local char = list[i]
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
        end
    end

    if n > 0 then pcall(cleanupParts, list) end

    if AURA.on then
        local mine = LP.Character or myChar()
        if mine then pcall(applyAura, mine, true) end
    end

    if accCurrent ~= 0 then
        if accState == "ready" and not hasAcc() and os.clock() - accMountAt > 0.4 then
            accMountAt = os.clock()
            pcall(mountAcc)
        elseif accState == "failed" and os.clock() - accFailAt > 3 then
            loadAccAsync(accCurrent)
        end
    end

    pcall(applyFov)
    if SKY.mode ~= "off" then pcall(syncSky) end
end

local acc = 0
local BOUND = false
pcall(function()
    RunS:BindToRenderStep("SleepEnforce", Enum.RenderPriority.Last.Value - 1, function(dt)
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
local healthGuard = false

local function watchChar(char)
    if not char then return end
    if watched[char] then return end
    watched[char] = true

    meshCache = nil
    cmTries[char] = nil
    charMode[char] = nil
    airJumps = 0
    accMountAt = 0
    accState = accTemplate and "ready" or "idle"

    enforce()
    for _, d in ipairs({ 0.2, 0.5, 0.9, 1.4, 2.2, 3.2 }) do
        task.delay(d, enforce)
    end

    if accCurrent ~= 0 and not accTemplate then
        task.delay(0.5, function()
            if accCurrent ~= 0 and not accTemplate and accState ~= "loading" then
                loadAccAsync(accCurrent)
            end
        end)
    end

    track(char.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") or d:IsA("Accessory") or d:IsA("Hat") or d:IsA("Decal") or d:IsA("CharacterMesh") then
            if d:IsA("BasePart") then
                hookPart(d)
                if CONFIG.noclip then pcall(noclipOne, d, true) end
            end
            task.defer(enforce)
        end
    end))

    track(char.ChildAdded:Connect(function(d)
        if not CONFIG.korblox then return end
        if d:IsA("CharacterMesh") and d.BodyPart == Enum.BodyPart.RightLeg and d.Name ~= "SleepKorblox" then
            pcall(function() d:Destroy() end)
            task.defer(enforce)
        end
    end))

    track(char.ChildRemoved:Connect(function(d)
        if not CONFIG.korblox then return end
        if d.Name == "SleepKorblox" then
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
        track(hum:GetPropertyChangedSignal("Health"):Connect(function()
            if not PROTECT.godHealth or healthGuard then return end
            if hum.Health < hum.MaxHealth then
                healthGuard = true
                pcall(function() hum.Health = hum.MaxHealth end)
                healthGuard = false
            end
        end))
        track(hum.Died:Connect(function()
            for _, d in ipairs({ 0.2, 0.6, 1.2 }) do task.delay(d, enforce) end
        end))
    end
end

if LP.Character then watchChar(LP.Character) end
track(LP.CharacterAdded:Connect(watchChar))
track(LP.CharacterAppearanceLoaded:Connect(enforce))

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

local gui, panel, shellRef, open = nil, nil, nil, false
local hudFrame, hudFps, hudPing
local pages, tabBtns, activeTab = {}, {}, nil
local statusLabel, statusToken = nil, 0
local setHeadless, setKorblox, setForce, setBoost, setInf, setAura, setNoClip, setHudRow

local function tw(o, t, p) TweenS:Create(o, TweenInfo.new(t), p):Play() end

local function status(text, color)
    if not statusLabel then return end
    statusToken = statusToken + 1
    local token = statusToken
    statusLabel.Text = text
    statusLabel.TextColor3 = color or ACCENT
    tw(statusLabel, 0.12, { TextTransparency = 0 })
    task.delay(1.8, function()
        if statusToken == token then tw(statusLabel, 0.5, { TextTransparency = 1 }) end
    end)
end

local function section(text)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -8, 0, 18)
    f.BackgroundTransparency = 1
    f.Parent = panel

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 0, 1, 0)
    l.AutomaticSize = Enum.AutomaticSize.X
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.TextSize = 9
    l.TextColor3 = SUB
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = text
    l.Parent = f

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -l.AbsoluteSize.X - 10, 0, 1)
    line.Position = UDim2.new(0, l.AbsoluteSize.X + 8, 0.5, 0)
    line.BackgroundColor3 = STROKE
    line.BorderSizePixel = 0
    line.Parent = f
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
        tw(t, 0.14, { BackgroundColor3 = v and ACCENT or OFF })
        tw(k, 0.14, { Position = v and UDim2.fromOffset(19, 3) or UDim2.fromOffset(3, 3) })
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
    btn.MouseEnter:Connect(function() tw(r, 0.12, { BackgroundColor3 = ROW:Lerp(Color3.new(1, 1, 1), 0.07) }) end)
    btn.MouseLeave:Connect(function() tw(r, 0.12, { BackgroundColor3 = ROW }) end)

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
    btn.MouseEnter:Connect(function() tw(r, 0.12, { BackgroundColor3 = ROW:Lerp(Color3.new(1, 1, 1), 0.07) }) end)
    btn.MouseLeave:Connect(function() tw(r, 0.12, { BackgroundColor3 = ROW }) end)
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
        tw(b, 0.1, { BackgroundColor3 = ACCENT, TextColor3 = BG })
        task.delay(0.22, function() tw(b, 0.22, { BackgroundColor3 = ROW, TextColor3 = TEXT }) end)
        task.spawn(function() pcall(cb) end)
    end)
    return b
end

local function gridBox(rows, cols)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -8, 0, rows * 30)
    f.BackgroundTransparency = 1
    f.Parent = panel
    local g = Instance.new("UIGridLayout", f)
    g.CellSize = UDim2.new(1 / cols, -4, 0, 26)
    g.CellPadding = UDim2.fromOffset(4, 4)
    return f
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
    if not shellRef then return end
    open = force ~= nil and force or not open
    if open then
        shellRef.Visible = true
        shellRef.BackgroundTransparency = 1
        shellRef.Size = UDim2.fromOffset(480, 320)
        tw(shellRef, 0.18, { BackgroundTransparency = 0.05, Size = UDim2.fromOffset(500, 360) })
    else
        tw(shellRef, 0.14, { BackgroundTransparency = 1, Size = UDim2.fromOffset(480, 320) })
        task.delay(0.16, function() if not open and shellRef then shellRef.Visible = false end end)
    end
end

local function setTab(id)
    activeTab = id
    for k, p in pairs(pages) do p.Visible = (k == id) end
    for k, b in pairs(tabBtns) do
        if k == id then
            tw(b, 0.15, { BackgroundColor3 = ACCENT, TextColor3 = BG })
        else
            tw(b, 0.15, { BackgroundColor3 = ROW, TextColor3 = SUB })
        end
    end
end

local function hudTone(v, good, mid)
    if v == nil then return SUB end
    if v >= good then return OKC end
    if v >= mid then return WARN end
    return BAD
end

local function setHud(on)
    HUD.on = on
    if not hudFrame then return end
    if on then
        hudFrame.Visible = true
        hudFrame.BackgroundTransparency = 1
        tw(hudFrame, 0.18, { BackgroundTransparency = 0.12 })
    else
        tw(hudFrame, 0.14, { BackgroundTransparency = 1 })
        task.delay(0.15, function() if not HUD.on and hudFrame then hudFrame.Visible = false end end)
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

local function buildHud()
    local cam = WS.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)

    hudFrame = Instance.new("Frame")
    hudFrame.Size = UDim2.fromOffset(132, 58)
    hudFrame.BackgroundColor3 = BG
    hudFrame.BackgroundTransparency = 0.12
    hudFrame.BorderSizePixel = 0
    hudFrame.Visible = false
    hudFrame.Parent = gui
    Instance.new("UICorner", hudFrame).CornerRadius = UDim.new(0, 10)

    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(Color3.fromRGB(20, 18, 28), Color3.fromRGB(10, 10, 14))
    g.Rotation = 90
    g.Parent = hudFrame

    local st = Instance.new("UIStroke", hudFrame)
    st.Thickness = 1
    st.Transparency = 0.3
    local sg = Instance.new("UIGradient")
    sg.Color = ColorSequence.new(ACCENT, ACCENT2)
    sg.Parent = st

    local saved = getgenv().SleepHudPos
    if saved then
        hudFrame.Position = UDim2.fromOffset(saved.X, saved.Y)
    else
        hudFrame.Position = UDim2.fromOffset(vp.X - 152, 70)
    end

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -14, 0, 12)
    title.Position = UDim2.fromOffset(8, 5)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 8
    title.TextColor3 = SUB
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "SLEEP · STATS"
    title.Parent = hudFrame

    local grip = Instance.new("TextLabel")
    grip.Size = UDim2.fromOffset(20, 12)
    grip.Position = UDim2.new(1, -24, 0, 5)
    grip.BackgroundTransparency = 1
    grip.Font = Enum.Font.GothamBold
    grip.TextSize = 9
    grip.TextColor3 = SUB
    grip.Text = "⋮⋮"
    grip.Parent = hudFrame

    local function line(y, label)
        local nl = Instance.new("TextLabel")
        nl.Size = UDim2.fromOffset(48, 16)
        nl.Position = UDim2.fromOffset(9, y)
        nl.BackgroundTransparency = 1
        nl.Font = Enum.Font.GothamBold
        nl.TextSize = 9
        nl.TextColor3 = SUB
        nl.TextXAlignment = Enum.TextXAlignment.Left
        nl.Text = label
        nl.Parent = hudFrame

        local nv = Instance.new("TextLabel")
        nv.Size = UDim2.fromOffset(58, 16)
        nv.Position = UDim2.new(1, -68, 0, y)
        nv.BackgroundTransparency = 1
        nv.Font = Enum.Font.GothamBlack
        nv.TextSize = 12
        nv.TextColor3 = TEXT
        nv.TextXAlignment = Enum.TextXAlignment.Right
        nv.Text = "--"
        nv.Parent = hudFrame
        return nv
    end

    hudFps = line(18, "FPS")
    hudPing = line(35, "PING")

    local hudDrag = false
    local hudStart, hudStartPos
    hudFrame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            hudDrag = true
            hudStart = i.Position
            hudStartPos = hudFrame.Position
        end
    end)
    track(UIS.InputChanged:Connect(function(i)
        if not hudDrag then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = i.Position - hudStart
        local c2 = WS.CurrentCamera
        local size = c2 and c2.ViewportSize or Vector2.new(1280, 720)
        local x = math.clamp(hudStartPos.X.Offset + d.X, 0, math.max(size.X - hudFrame.AbsoluteSize.X, 0))
        local y = math.clamp(hudStartPos.Y.Offset + d.Y, 0, math.max(size.Y - hudFrame.AbsoluteSize.Y, 0))
        hudFrame.Position = UDim2.fromOffset(x, y)
    end))
    track(UIS.InputEnded:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
        if hudDrag then
            hudDrag = false
            getgenv().SleepHudPos = Vector2.new(hudFrame.Position.X.Offset, hudFrame.Position.Y.Offset)
        end
    end))
end

local function hudLoop()
    local frames = 0
    track(RunS.RenderStepped:Connect(function() frames = frames + 1 end))
    local lastT = os.clock()
    while true do
        task.wait(0.5)
        local now = os.clock()
        local span = now - lastT
        lastT = now
        if HUD.on and hudFps and hudPing then
            local fps = span > 0 and math.floor(frames / span + 0.5) or 0
            frames = 0
            local ping
            local ok, v = pcall(function()
                return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            end)
            if ok and type(v) == "number" then ping = math.floor(v + 0.5) end

            hudFps.Text = tostring(fps)
            hudFps.TextColor3 = hudTone(fps, 50, 28)
            hudPing.Text = ping and tostring(ping) or "--"
            hudPing.TextColor3 = ping and hudTone(1000 - ping * 5, 700, 400) or SUB
            if ping then
                if ping <= 80 then hudPing.TextColor3 = OKC
                elseif ping <= 160 then hudPing.TextColor3 = WARN
                else hudPing.TextColor3 = BAD end
            end
        else
            frames = 0
        end
    end
end

local function build()
    gui = Instance.new("ScreenGui")
    gui.Name = "Sleepscript"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 1000000
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    getgenv().Sleepscript = gui
    if not stealthGui(gui) then gui.Parent = LP:WaitForChild("PlayerGui") end

    local shell = Instance.new("Frame")
    shell.Position = UDim2.fromOffset(20, 70)
    shell.Size = UDim2.fromOffset(500, 360)
    shell.BackgroundColor3 = BG
    shell.BackgroundTransparency = 0.05
    shell.BorderSizePixel = 0
    shell.Visible = false
    shell.Parent = gui
    shellRef = shell
    Instance.new("UICorner", shell).CornerRadius = UDim.new(0, 14)

    local bg = Instance.new("UIGradient")
    bg.Color = ColorSequence.new(Color3.fromRGB(22, 20, 32), Color3.fromRGB(9, 9, 12))
    bg.Rotation = 90
    bg.Parent = shell

    local st = Instance.new("UIStroke", shell)
    st.Thickness = 1
    st.Transparency = 0.25
    local stg = Instance.new("UIGradient")
    stg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, ACCENT),
        ColorSequenceKeypoint.new(0.5, STROKE),
        ColorSequenceKeypoint.new(1, ACCENT2),
    })
    stg.Parent = st

    local head = Instance.new("Frame")
    head.Size = UDim2.new(1, 0, 0, 42)
    head.BackgroundTransparency = 1
    head.Parent = shell

    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(8, 8)
    dot.Position = UDim2.fromOffset(16, 17)
    dot.BackgroundColor3 = ACCENT
    dot.BorderSizePixel = 0
    dot.Parent = head
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    task.spawn(function()
        while dot.Parent do
            tw(dot, 0.9, { BackgroundTransparency = 0.55 })
            task.wait(0.95)
            tw(dot, 0.9, { BackgroundTransparency = 0 })
            task.wait(0.95)
        end
    end)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 0, 14)
    title.Position = UDim2.fromOffset(30, 10)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 13
    title.TextColor3 = TEXT
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "SLEEPSCRIPT"
    title.Parent = head

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -80, 0, 12)
    sub.Position = UDim2.fromOffset(31, 24)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.GothamMedium
    sub.TextSize = 9
    sub.TextColor3 = SUB
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Text = "cosmetics · qol"
    sub.Parent = head

    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(22, 22)
    close.Position = UDim2.new(1, -30, 0, 10)
    close.BackgroundColor3 = ROW
    close.BorderSizePixel = 0
    close.AutoButtonColor = false
    close.Font = Enum.Font.GothamBold
    close.TextSize = 13
    close.TextColor3 = SUB
    close.Text = "×"
    close.Parent = head
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
    close.MouseButton1Click:Connect(function() setOpen(false) end)
    close.MouseEnter:Connect(function() tw(close, 0.12, { BackgroundColor3 = ACCENT, TextColor3 = BG }) end)
    close.MouseLeave:Connect(function() tw(close, 0.12, { BackgroundColor3 = ROW, TextColor3 = SUB }) end)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -8, 0, 24)
    bar.Position = UDim2.fromOffset(4, 44)
    bar.BackgroundTransparency = 1
    bar.Parent = shell
    local bl = Instance.new("UIListLayout", bar)
    bl.FillDirection = Enum.FillDirection.Horizontal
    bl.Padding = UDim.new(0, 3)
    bl.SortOrder = Enum.SortOrder.LayoutOrder

    for i, t in ipairs(TABS) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(56, 22)
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
        p.Size = UDim2.new(1, -8, 1, -92)
        p.Position = UDim2.fromOffset(4, 72)
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

    local foot = Instance.new("Frame")
    foot.Size = UDim2.new(1, -8, 0, 14)
    foot.Position = UDim2.new(0, 4, 1, -18)
    foot.BackgroundTransparency = 1
    foot.Parent = shell

    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -70, 1, 0)
    statusLabel.Position = UDim2.fromOffset(6, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 9
    statusLabel.TextColor3 = ACCENT
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextTransparency = 1
    statusLabel.Text = ""
    statusLabel.Parent = foot

    local hint = Instance.new("TextLabel")
    hint.Size = UDim2.fromOffset(64, 14)
    hint.Position = UDim2.new(1, -70, 0, 0)
    hint.BackgroundTransparency = 1
    hint.Font = Enum.Font.GothamBold
    hint.TextSize = 9
    hint.TextColor3 = SUB
    hint.TextXAlignment = Enum.TextXAlignment.Right
    hint.Text = "Z · меню"
    hint.Parent = foot

    panel = pages.look
    section("ВНЕШКА")
    setHeadless = row("Headless", CONFIG.headless, function(v)
        CONFIG.headless = v
        if v and not CONFIG.force and setForce then setForce(true) end
        for i = 1, #targets() do
            local c = tmpList[i]
            pcall(applyHeadless, c, v)
        end
        status(v and "headless включён" or "headless выключен")
    end)
    setKorblox = row("Korblox", CONFIG.korblox, function(v)
        CONFIG.korblox = v
        if v and not CONFIG.force and setForce then setForce(true) end
        for i = 1, #targets() do
            local c = tmpList[i]
            pcall(applyKorblox, c, v)
        end
        status(v and "korblox включён" or "korblox выключен")
    end)
    setForce = row("Жёсткая фиксация", CONFIG.force, function(v)
        CONFIG.force = v
        enforce()
        status(v and "фиксация: жёсткая" or "фиксация: мягкая")
    end, 26)

    panel = pages.aura
    section("ЦВЕТ")
    local cg = gridBox(6, 4)
    for _, c in ipairs(AURA_COLORS) do
        chip(cg, c.name, function()
            if c.mode == "rainbow" then
                AURA.mode = "rainbow"
            else
                AURA.mode = "solid"
                AURA.color = c.color
            end
            if AURA.on then refreshAura() end
            status("цвет: " .. c.name)
        end, c.color)
    end
    section("СТИЛЬ")
    local sg = gridBox(4, 3)
    for _, s in ipairs(AURA_STYLES) do
        chip(sg, s.name, function()
            AURA.style = s.id
            if AURA.on then refreshAura() end
            status("стиль: " .. s.name)
        end)
    end
    section("ПАРАМЕТРЫ")
    setAura = row("Аура вкл", AURA.on, function(v)
        AURA.on = v
        if v then
            local c = myChar()
            if c then pcall(applyAura, c, true) end
            status("аура включена")
        else
            clearAura()
            status("аура выключена")
        end
    end)
    slider("Размер", 0.3, 2.5, AURA.size, function(v)
        AURA.size = v
        if AURA.on then refreshAura() end
    end, 0.1, function(v) return string.format("%.1f", v) end)
    slider("Скорость цвета", 0.1, 3, AURA.speed, function(v)
        AURA.speed = v
    end, 0.1, function(v) return string.format("%.1f", v) end)

    panel = pages.head
    section("АКСЕССУАРЫ")
    for _, a in ipairs(ACCS) do
        button(a.name, function()
            setAcc(a.id)
            status("аксессуар: " .. a.name)
        end)
    end
    button("Снять", function()
        setAcc(0)
        status("аксессуар снят")
    end)
    slider("Смещение", -0.6, 1.2, accOffsetY, function(v)
        accOffsetY = v
        if accCurrent ~= 0 then reAcc() end
    end, 0.05)

    panel = pages.move
    section("ПРЫЖОК")
    setInf = row("Бесконечный прыжок", CONFIG.infJump, function(v)
        CONFIG.infJump = v
        airJumps = 0
        status(v and "прыжок: ∞" or "прыжок: обычный")
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
    grid.CellPadding = UDim2.fromOffset(4, 4)
    panel = skyPage
    button("Выкл", function() applySky("off") status("небо: выкл") end)
    button("Ночь", function() applySky("night") status("небо: ночь") end)
    button("Космос", function() applySky("space") status("небо: космос") end)
    button("Закат", function() applySky("sunset") status("небо: закат") end)
    button("Сумерки", function() applySky("dusk") status("небо: сумерки") end)
    button("Классика", function() applySky("classic") status("небо: классика") end)
    button("Пасмурно", function() applySky("overcast") status("небо: пасмурно") end)
    button("Пустота", function() applySky("void") status("небо: пустота") end)
    button("Инферно", function() applySky("inferno") status("небо: инферно") end)
    button("Лёд", function() applySky("ice") status("небо: лёд") end)
    button("Матрица", function() applySky("matrix") status("небо: матрица") end)
    button("Кровь", function() applySky("blood") status("небо: кровь") end)

    panel = pages.fps
    section("FPS")
    setBoost = row("FPS Boost", FPS.boost, function(v)
        FPS.boost = v
        if v then FPS.shadowsOff, FPS.fxOff, FPS.partsOff = true, true, true end
        syncFps()
        status(v and "boost включён" or "boost выключен")
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
    section("HUD")
    setHudRow = row("Счётчик FPS и пинга", HUD.on, function(v)
        setHud(v)
        status(v and "HUD включён" or "HUD выключен")
    end)
    button("Сбросить позицию HUD", function()
        getgenv().SleepHudPos = nil
        if hudFrame then
            local cam = WS.CurrentCamera
            local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
            tw(hudFrame, 0.18, { Position = UDim2.fromOffset(vp.X - 152, 70) })
        end
        status("позиция HUD сброшена")
    end)
    section("КОЛЛИЗИИ")
    setNoClip = row("Ноклип", CONFIG.noclip, function(v)
        CONFIG.noclip = v
        local mine = LP.Character or myChar()
        pcall(setNoClip, v and mine or nil, v)
        status(v and "ноклип включён" or "ноклип выключен")
    end)
    section("ЗАЩИТА")
    row("Иммунитет к урону и чекпоинтам", PROTECT.parts, function(v)
        PROTECT.parts = v
        if v then scanHazards() else clearHazards() end
        status(v and "иммунитет включён" or "иммунитет выключен")
    end)
    row("Держать здоровье", PROTECT.godHealth, function(v)
        PROTECT.godHealth = v
        if v then healNow() end
        status(v and "здоровье зафиксировано" or "здоровье свободно")
    end, 26)
    button("Просканировать опасные части", function()
        scanHazards()
        status("скан выполнен")
    end)
    section("ПРОЧЕЕ")
    button("Аксессуар заново", function()
        if accCurrent == 0 then accCurrent = ACCS[1].id end
        reAcc()
        status("аксессуар переустановлен")
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
        if SKY.mode ~= "off" then pcall(applySky, SKY.mode) end

        for _ = 1, 6 do
            task.wait(0.15)
            enforce()
        end
        status("всё переприменено", OKC)
        print("[Sleep] переприменено")
    end, true)
    button("Диагностика", function()
        local list = targets()
        print("[Sleep] целей найдено:", #list)
        print("[Sleep] LP.Character:", tostring(LP.Character))
        local char = list[1]
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        print("[Sleep] риг:", hum and hum.RigType.Name or "нет")
        print("[Sleep] weld-режим:", tostring(weldMode), "попыток меша:", char and tostring(cmTries[char]) or "-")
        print("[Sleep] CreateMeshPartAsync:", meshCache and "ок" or "недоступен")
        print("[Sleep] аура:", tostring(AURA.on), "режим:", AURA.mode, "стиль:", AURA.style, "цель:", auraChar and "есть" or "нет")
        print("[Sleep] аксессуар:", accCurrent, "| состояние:", accState, "| кэш:", accTemplate and "есть" or "нет", "| на голове:", tostring(hasAcc()), "| статус:", accLast)
        print("[Sleep] защита частей:", tostring(PROTECT.parts), "здоровье:", tostring(PROTECT.godHealth))
        print("[Sleep] ноклип:", tostring(CONFIG.noclip), "частей под ноклипом:", #noclipSaved)
        print("[Sleep] частей в папке:", partsFolder and #partsFolder:GetChildren() or 0)
        print("[Sleep] fps:", tostring(FPS.boost), "частиц убито:", #killedParts, "эффектов:", #killedFx)
        print("[Sleep] FOV:", tostring(fovTarget), "небо:", SKY.mode, "HUD:", tostring(HUD.on))
        status("диагностика в консоли")
    end)
    button("Убрать всё", function()
        CONFIG.headless, CONFIG.korblox, CONFIG.force = false, false, false
        CONFIG.infJump = false
        CONFIG.noclip = false
        AURA.on = false
        PROTECT.parts = false
        PROTECT.godHealth = false
        accCurrent = 0
        accTemplate = nil
        accState = "idle"
        FPS.boost, FPS.shadowsOff, FPS.fxOff, FPS.partsOff = false, false, false, false
        if setHeadless then setHeadless(false) end
        if setKorblox then setKorblox(false) end
        if setForce then setForce(false) end
        if setBoost then setBoost(false) end
        if setInf then setInf(false) end
        if setAura then setAura(false) end
        if setNoClip then setNoClip(false) end
        if setHudRow then setHudRow(false) end
        pcall(restoreNoclip)
        pcall(clearHazards)
        syncFps()
        local list = targets()
        for i = 1, #list do
            pcall(applyHeadless, list[i], false)
            pcall(clearKorblox, list[i])
        end
        pcall(clearAura)
        pcall(clearAcc)
        pcall(applySky, "off")
        fovTarget = 70
        pcall(applyFov)
        status("всё выключено", OKC)
    end)

    panel = shell
    setTab("look")

    buildHud()

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
        pcall(function() RunS:UnbindFromRenderStep("SleepEnforce") end)
        pcall(function() CAS:UnbindAction("SleepMenu") end)
        pcall(function() CAS:UnbindAction("SleepHud") end)
        pcall(clearAura)
        pcall(restoreNoclip)
        if partsFolder then
            for _, o in ipairs(partsFolder:GetChildren()) do pcall(function() o:Destroy() end) end
        end
    end)

    print("[Sleep] v1 · Z меню · H HUD · всё выключено")
end

build()
task.spawn(hudLoop)

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

pcall(function()
    CAS:BindActionAtPriority("SleepHud", function(_, state, input)
        if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
        if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
        if input.KeyCode == Enum.KeyCode.H then
            if setHudRow then setHudRow(not HUD.on) else setHud(not HUD.on) end
            return Enum.ContextActionResult.Sink
        end
        return Enum.ContextActionResult.Pass
    end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.H)
end)

track(UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if UIS:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.Z then setOpen() end
end))

pcall(getFolder)

task.wait(1.2)
enforce()

if getgenv().VeniceCos then pcall(function() getgenv().VeniceCos:Destroy() end) end
if getgenv().VeniceCosConns then
    for _, c in ipairs(getgenv().VeniceCosConns) do pcall(function() c:Disconnect() end) end
end
getgenv().VeniceCosConns = {} -- fff

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

local CONFIG = { korbloxR = true, korbloxL = true, headless = true, force = true, infJump = false, jumpLimit = -1 }
local FPS = { boost = false, shadowsOff = false, fxOff = false, partsOff = false, cap = 240 }

local ACCS = {
    { id = 132809431,  name = "Doomsekkar" },
    { id = 74891470,   name = "Frozen Horns" },
    { id = 215718515,  name = "Fiery Horns" },
    { id = 1744060292, name = "Poisoned Horns" },
}
local accCurrent = 0
local accOffsetY = 0

local TEX = "rbxassetid://101851254"

local SIDES = {
    R = {
        body  = Enum.BodyPart.RightLeg,
        meshId = "rbxassetid://101851696",
        texId  = TEX,
        upper = { "RightUpperLeg", "Right Leg", "RightLeg" },
        lower = { "RightLowerLeg", "Right Lower Leg" },
        foot  = { "RightFoot", "Right Foot" },
        pat   = "Right",
        yaw   = 0,
        pitch = 0,
    },
    L = {
        body  = Enum.BodyPart.LeftLeg,
        catalog = 139607673,
        meshId = nil,
        texId  = TEX,
        upper = { "LeftUpperLeg", "Left Leg", "LeftLeg" },
        lower = { "LeftLowerLeg", "Left Lower Leg" },
        foot  = { "LeftFoot", "Left Foot" },
        pat   = "Left",
        yaw   = 0,
        pitch = 0,
    },
}
local SIDE_LIST = { "R", "L" }

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

local meshCache = {}
local meshNative = {}
local savedCharMesh = setmetatable({}, { __mode = "k" })
local weldMode = { R = false, L = false }
local cmMisses = { R = 0, L = 0 }

local function stripJoints(part)
    for _, d in ipairs(part:GetChildren()) do
        if d:IsA("JointInstance") or d:IsA("WeldConstraint") or d:IsA("Motor6D") then
            pcall(function() d:Destroy() end)
        end
    end
end

local function findPartIn(container, out)
    for _, o in ipairs(container) do
        if out[1] then return end
        if o:IsA("BasePart") then
            out[1] = o
            return
        end
        if o:IsA("Model") or o:IsA("Folder") or o:IsA("Accessory") then
            findPartIn(o:GetChildren(), out)
        end
    end
end

local function loadCatalogPart(id)
    if not id then return nil end
    local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. tostring(id)) end)
    if not ok or not objs or #objs == 0 then return nil end
    local out = {}
    local ok2 = pcall(findPartIn, objs, out)
    local part = ok2 and out[1]
    if not part then return nil end
    stripJoints(part)
    return part
end

local function meshOf(part)
    if part:IsA("MeshPart") then
        return part.MeshId, part.TextureID
    end
    local sm = part:FindFirstChildWhichIsA("SpecialMesh")
    if sm then
        return sm.MeshId, sm.TextureId
    end
    return nil, nil
end

local function resolveAsset(side)
    local cfg = SIDES[side]
    if cfg.meshId then return cfg.meshId, cfg.texId end
    if not cfg.catalog then return nil end

    local part = loadCatalogPart(cfg.catalog)
    if not part then return nil end
    local mid, tex = meshOf(part)
    pcall(function() part:Destroy() end)
    if not mid or mid == "" then return nil end

    cfg.meshId = mid
    if tex and tex ~= "" then cfg.texId = tex end
    print("[Venice] " .. side .. " нога: меш " .. tostring(mid) .. " | текстура " .. tostring(cfg.texId))
    return cfg.meshId, cfg.texId
end

local function findLegParts(char, side)
    local d = SIDES[side]
    local upper, lower, foot
    for _, n in ipairs(d.upper) do upper = char:FindFirstChild(n) if upper then break end end
    if not upper then
        for _, c in ipairs(char:GetChildren()) do
            if c:IsA("BasePart") and c.Name:match("^" .. d.pat .. ".*[Uu]pper.*Leg$") then upper = c break end
        end
    end
    if not upper then
        for _, c in ipairs(char:GetChildren()) do
            if c:IsA("BasePart") and c.Name:match("^" .. d.pat .. ".*Leg$") then upper = c break end
        end
    end
    for _, n in ipairs(d.lower) do lower = char:FindFirstChild(n) if lower then break end end
    for _, n in ipairs(d.foot) do foot = char:FindFirstChild(n) if foot then break end end
    return upper, lower, foot
end

local function findKorbloxPart(char, side)
    if not partsFolder then return nil end
    for _, p in ipairs(partsFolder:GetChildren()) do
        if p:IsA("BasePart") and p.Name == "VeniceKorbloxLeg" .. side then
            local w = p:FindFirstChildWhichIsA("WeldConstraint")
            if w and w.Part1 and w.Part1:IsDescendantOf(char) then return p end
        end
    end
end

local function korbloxOk(char, side)
    if char:FindFirstChild("VeniceKorblox" .. side) then return true end
    return findKorbloxPart(char, side) ~= nil
end

local function clearKorblox(char, side)
    if not char then return end
    local cm = char:FindFirstChild("VeniceKorblox" .. side)
    if cm then pcall(function() cm:Destroy() end) end
    local p = findKorbloxPart(char, side)
    if p then pcall(function() p:Destroy() end) end
    local upper, lower, foot = findLegParts(char, side)
    setHidden(upper, false)
    setHidden(lower, false)
    setHidden(foot, false)
    local s = savedCharMesh[char] and savedCharMesh[char][side]
    if s then
        local m = Instance.new("CharacterMesh")
        m.Name = "VeniceKorbloxRestore"
        m.BodyPart = SIDES[side].body
        m.MeshId = s.mesh
        m.OverlayTextureId = s.tex
        m.Parent = char
        savedCharMesh[char][side] = nil
    end
end

local function clearKorbloxAll(char)
    for _, s in ipairs(SIDE_LIST) do pcall(clearKorblox, char, s) end
end

local function getMeshPart(side)
    local c = meshCache[side]
    if c and c.Parent then return c end
    local cfg = SIDES[side]
    local mid, tex = resolveAsset(side)
    if not mid then return nil end

    local part
    for _ = 1, 2 do
        local ok, res = pcall(function()
            return AssetS:CreateMeshPartAsync(mid, Enum.CollisionFidelity.Box)
        end)
        if ok and typeof(res) == "MeshPart" and res.Size.Magnitude > 0.05 then
            part = res
            break
        end
        task.wait(0.05)
    end
    if not part then return nil end

    meshNative[side] = part.Size
    pcall(function()
        part.MeshId = mid
        if tex then part.TextureID = tex end
    end)
    meshCache[side] = part
    return part
end

local function buildKorbloxLeg(char, side, upper, lower, foot)
    local cfg = SIDES[side]

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

    local part = getMeshPart(side)
    local native = meshNative[side]

    if not part and cfg.catalog then
        part = loadCatalogPart(cfg.catalog)
        if part then native = part.Size end
    end
    if not part then return end
    native = native or Vector3.new(1, 1, 1)

    local rot = CFrame.new()
    local size
    if native.X >= native.Y and native.X >= native.Z then
        size = Vector3.new(len, w, w)
        rot = CFrame.Angles(0, 0, math.rad(90))
    elseif native.Z > native.Y and native.Z > native.X then
        size = Vector3.new(w, w, len)
        rot = CFrame.Angles(math.rad(-90), 0, 0)
    else
        size = Vector3.new(w, len, w)
    end

    part.Name = "VeniceKorbloxLeg" .. side

    local sm = part:FindFirstChildWhichIsA("SpecialMesh")
    if part:IsA("MeshPart") or not sm then
        part.Size = size
    else
        sm.Scale = Vector3.new(
            sm.Scale.X * (size.X / math.max(native.X, 0.01)),
            sm.Scale.Y * (size.Y / math.max(native.Y, 0.01)),
            sm.Scale.Z * (size.Z / math.max(native.Z, 0.01))
        )
        part.Size = size
    end

    local base = CFrame.lookAt(mid, mid + upper.CFrame.RightVector, up)
        * CFrame.Angles(math.rad(cfg.pitch or 0), math.rad(cfg.yaw or 0), 0)

    part.CFrame = base * rot
    part.Anchored = false
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = true
    pcall(function() part.Massless = true end)
    part.Transparency = 0
    part.LocalTransparencyModifier = 0
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

local function applyKorblox(char, on, side)
    if not char then return end
    local d = SIDES[side]
    if not d then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if not on then clearKorblox(char, side) return end
    if korbloxOk(char, side) then return end

    if hum.RigType == Enum.HumanoidRigType.R6 and not weldMode[side] then
        local mid, tex = resolveAsset(side)
        if mid then
            for _, c in ipairs(char:GetChildren()) do
                if c:IsA("CharacterMesh") and c.BodyPart == d.body and c.Name ~= "VeniceKorblox" .. side then
                    savedCharMesh[char] = savedCharMesh[char] or {}
                    savedCharMesh[char][side] = { mesh = c.MeshId, tex = c.OverlayTextureId }
                    pcall(function() c:Destroy() end)
                    break
                end
            end
            local m = Instance.new("CharacterMesh")
            m.Name = "VeniceKorblox" .. side
            m.BodyPart = d.body
            m.MeshId = mid
            m.OverlayTextureId = tex
            m.Parent = char
            return
        end
    end

    local upper, lower, foot = findLegParts(char, side)
    if not upper then return end
    buildKorbloxLeg(char, side, upper, lower, foot)
end

local function reKorblox()
    for _, c in ipairs(targets()) do
        for _, s in ipairs(SIDE_LIST) do
            pcall(clearKorblox, c, s)
            local on = (s == "R") and CONFIG.korbloxR or CONFIG.korbloxL
            if on then pcall(applyKorblox, c, true, s) end
        end
    end
    enforce()
end

local function cleanupParts(list)
    if not partsFolder then return end
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
end

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
            if isEmitter(d) and d.Enabled then
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

-- ============================== фиксация ==============================

local function enforce()
    local list = targets()
    if #list == 0 then return end

    for _, char in ipairs(list) do
        if CONFIG.headless then pcall(applyHeadless, char, true) end
        for _, s in ipairs(SIDE_LIST) do
            local on = (s == "R") and CONFIG.korbloxR or CONFIG.korbloxL
            if on then
                if not korbloxOk(char, s) then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.RigType == Enum.HumanoidRigType.R6 and not char:FindFirstChild("VeniceKorblox" .. s) then
                        cmMisses[s] = cmMisses[s] + 1
                        if cmMisses[s] >= 4 then weldMode[s] = true end
                    end
                end
                pcall(applyKorblox, char, true, s)
            end
        end
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

local function watchChar(char)
    table.clear(meshCache)
    cmMisses.R, cmMisses.L = 0, 0
    airJumps = 0
    accAt = 0
    enforce()
    task.delay(0.25, enforce)
    task.delay(0.8, enforce)
    task.delay(1.6, enforce)

    track(char.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") or d:IsA("Accessory") or d:IsA("Hat") or d:IsA("Decal") or d:IsA("CharacterMesh") then
            if d:IsA("BasePart") then hookPart(d) end
            task.defer(enforce)
        end
    end))
    track(char.AncestryChanged:Connect(function() task.defer(enforce) end))

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        track(hum.ChildAdded:Connect(function() task.defer(enforce) end))
        track(hum:GetPropertyChangedSignal("RigType"):Connect(function() task.defer(enforce) end))
    end
end

if LP.Character then watchChar(LP.Character) end
track(LP.CharacterAdded:Connect(watchChar))
track(LP.CharacterAppearanceLoaded:Connect(enforce))

local watched = setmetatable({}, { __mode = "k" })
task.spawn(function()
    while true do
        task.wait(0.5)
        local c = myChar()
        if c and not watched[c] then
            watched[c] = true
            watchChar(c)
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

local setHeadless, setKorbloxR, setKorbloxL, setForce, setBoost, setInf

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
    shell.Size = UDim2.fromOffset(480, 306)
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
    bl.Padding = UDim.new(0, 4)
    bl.SortOrder = Enum.SortOrder.LayoutOrder

    for i, t in ipairs(TABS) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(56, 22)
        b.LayoutOrder = i
        b.BackgroundColor3 = ROW
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
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
    setKorbloxR = row("Korblox · правая нога", CONFIG.korbloxR, function(v)
        CONFIG.korbloxR = v
        for _, c in ipairs(targets()) do pcall(applyKorblox, c, v, "R") end
    end)
    setKorbloxL = row("Korblox · левая нога", CONFIG.korbloxL, function(v)
        CONFIG.korbloxL = v
        for _, c in ipairs(targets()) do pcall(applyKorblox, c, v, "L") end
    end)
    button("Обе ноги", function()
        if setKorbloxR then setKorbloxR(true) end
        if setKorbloxL then setKorbloxL(true) end
    end)
    button("Снять обе ноги", function()
        if setKorbloxR then setKorbloxR(false) end
        if setKorbloxL then setKorbloxL(false) end
    end)
    setForce = row("Жёсткая фиксация", CONFIG.force, function(v)
        CONFIG.force = v
        enforce()
    end, 26)

    section("ПОДГОНКА ЛЕВОЙ")
    slider("Разворот", -180, 180, SIDES.L.yaw, function(v)
        SIDES.L.yaw = v
        pcall(reKorblox)
    end, 5, function(v) return tostring(math.floor(v + 0.5)) end)
    row("Переворот", false, function(v)
        SIDES.L.pitch = v and 180 or 0
        pcall(reKorblox)
    end, 26)

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
        CONFIG.headless, CONFIG.korbloxR, CONFIG.korbloxL, CONFIG.force = true, true, true, true
        if setHeadless then setHeadless(true) end
        if setKorbloxR then setKorbloxR(true) end
        if setKorbloxL then setKorbloxL(true) end
        if setForce then setForce(true) end
        if accCurrent ~= 0 then
            accAt = 0
            task.spawn(function() pcall(applyAcc, accCurrent) end)
        end

        refreshScan()
        syncFps()
        if SKY.mode ~= "off" then pcall(applySky, SKY.mode) end

        for _ = 1, 6 do
            task.wait(0.15)
            enforce()
        end
        print("[Venice] переприменено")
    end, true)
    button("Сброс подгонки", function()
        SIDES.L.yaw, SIDES.L.pitch = 0, 0
        pcall(reKorblox)
    end)
    button("Диагностика", function()
        local list = targets()
        print("[Venice] целей найдено:", #list)
        print("[Venice] LP.Character:", tostring(LP.Character))
        print("[Venice] myChar:", tostring(myChar()))
        local char = list[1]
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        print("[Venice] риг:", hum and hum.RigType.Name or "нет")
        print("[Venice] weld-режим: R=", tostring(weldMode.R), "L=", tostring(weldMode.L))
        print("[Venice] меш R:", tostring(SIDES.R.meshId), "| L:", tostring(SIDES.L.meshId))
        print("[Venice] текстура L:", tostring(SIDES.L.texId))
        print("[Venice] yaw L:", SIDES.L.yaw, "pitch L:", SIDES.L.pitch)
        print("[Venice] ноги: правая=", tostring(CONFIG.korbloxR), "левая=", tostring(CONFIG.korbloxL))
        for _, s in ipairs(SIDE_LIST) do
            print("  сторона", s, "надето:", char and tostring(korbloxOk(char, s)) or "нет цели")
        end
        print("[Venice] аксессуар:", accCurrent, "| статус:", accLast, "| смещение:", accOffsetY)
        print("[Venice] частей в папке:", partsFolder and #partsFolder:GetChildren() or 0)
        print("[Venice] fps:", tostring(FPS.boost), "FOV:", tostring(fovTarget), "небо:", SKY.mode)
    end)
    button("Убрать всё", function()
        CONFIG.headless, CONFIG.korbloxR, CONFIG.korbloxL, CONFIG.force = false, false, false, false
        CONFIG.infJump = false
        accCurrent = 0
        FPS.boost, FPS.shadowsOff, FPS.fxOff, FPS.partsOff = false, false, false, false
        if setHeadless then setHeadless(false) end
        if setKorbloxR then setKorbloxR(false) end
        if setKorbloxL then setKorbloxL(false) end
        if setForce then setForce(false) end
        if setBoost then setBoost(false) end
        if setInf then setInf(false) end
        syncFps()
        for _, c in ipairs(targets()) do
            pcall(applyHeadless, c, false)
            pcall(clearKorbloxAll, c)
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
        if partsFolder then
            for _, o in ipairs(partsFolder:GetChildren()) do pcall(function() o:Destroy() end) end
        end
    end)

    print("[Venice] v30 · Z меню")
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

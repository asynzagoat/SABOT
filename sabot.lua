
if _G.MTC and _G.MTC.stop then pcall(_G.MTC.stop) end

local RS        = game:GetService("RunService")
local Players   = game:GetService("Players")
local LP        = Players.LocalPlayer
local Workspace = workspace

local FACTION_COLOR = {
    ["Eagle Federation"] = "Dark green",
    ["Hawk Republic"]    = "Bright red",
}
local myTeamColor = nil

local Vector2_new = Vector2.new
local Vector3_new = Vector3.new
local CFrame_new  = CFrame.new
local Color3_rgb  = Color3.fromRGB
local Color3_new  = Color3.new
local floor       = math.floor
local huge        = math.huge
local WTS         = WorldToScreen

local FONT_SYS, FONT_MONO = 1, 5

local STUD_PER_M = 2.7777778
local STUDS_TO_M = 1 / STUD_PER_M
local FADE_START = 450
local FADE_END   = 3200
local ABANDONED  = "Unoccupied/Abandoned"
local DRONE_MAX  = 500

local COL_BOX    = Color3_rgb(255, 255, 255)
local COL_NAME   = Color3_rgb(255, 255, 255)
local COL_DIST   = Color3_rgb(140, 220, 255)
local COL_CLASS  = Color3_rgb(255, 180, 80)
local COL_OVR    = Color3_rgb(235, 235, 235)
local COL_ACC    = Color3_rgb(120, 200, 120)
local COL_DRONE  = Color3_rgb(120, 255, 180)
local COL_ENGINE = Color3_rgb(255, 140, 0)
local COL_AMMO   = Color3_rgb(255, 40, 40)
local MOD_FILL_A = 0.5

local COL_MISSILE = Color3_rgb(255, 170, 40)
local COL_THREAT  = Color3_rgb(255, 40, 40)
local MSL_MOVE2   = 4
local MSLPOOL     = 24

local RELOAD_VK   = 0x45
local FLARE_VK    = 0x47
local FLARE_RANGE = 900
local FLARE_COOL  = 5

local KD_DROP_Y   = -100
local KD_CYCLE    = 27

local MOD_GROUP   = 32966202
local MOD_ROLES   = { { id = 348178106, name = "Administrator" }, { id = 347606116, name = "Moderator" }, { id = 348814130, name = "Content Creator" } }
local COL_STAFF   = Color3_rgb(255, 30, 60)
local STAFFPOOL   = 12

local COL_BALL    = Color3_rgb(120, 255, 180)

local PROJ_GRAV   = 17.64
local SHELL_VEL_DEFAULT = 1000

local Config = {
    Enabled = true, Box = true, Names = true, Class = true, Distance = true, Overlay = false,
    Fade = true, MaxDist = 3200, Heli = false, Drone = false, OccupiedOnly = false, TeamCheck = false,

    ModOutline = false, ModFilled = false, ModEngine = true, ModAmmo = true, ModMaxDist = 400,

    HideGrain = false, Missile = false, AutoReload = false, ModChecker = false, Ballistic = false,
    AutoFlare = false, ReloadStatus = false, KDDrop = false,
}

local BoxEdges = {
    { 1, 2 }, { 3, 4 }, { 1, 3 }, { 2, 4 },
    { 5, 6 }, { 7, 8 }, { 5, 7 }, { 6, 8 },
    { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 },
}

local FaceTris = {
    { 1, 2, 4 }, { 1, 4, 3 },
    { 5, 6, 8 }, { 5, 8, 7 },
    { 1, 2, 6 }, { 1, 6, 5 },
    { 3, 4, 8 }, { 3, 8, 7 },
    { 1, 3, 7 }, { 1, 7, 5 },
    { 2, 4, 8 }, { 2, 8, 6 },
}

local CLASS_ABBR = {
    ["Main Battle Tank"] = "MBT", ["Medium Tank"] = "MT", ["Light Tank"] = "LT",
    ["Heavy Tank"] = "HT", ["Tank Destroyer"] = "TD", ["Infantry Fighting Vehicle"] = "IFV",
    ["Armored Personnel Carrier"] = "APC", ["Armoured Personnel Carrier"] = "APC",
    ["Self Propelled Howitzer"] = "SPH",
    ["Self Propelled Gun"] = "SPG",

    ["Self Propelled Anti Aircraft"] = "SPAA", ["Self-Propelled Anti-Aircraft"] = "SPAA",
    ["Self Propelled Anti-Aircraft"] = "SPAA", ["Self-Propelled Anti Aircraft"] = "SPAA",
    ["Self Propelled Anti-Air"] = "SPAA", ["Self Propelled Anti Air"] = "SPAA",
    ["Anti-Air"] = "AA",
    ["Attack Helicopter"] = "AH", ["Helicopter"] = "HELI",
}
local function classAbbr(s)
    if type(s) ~= "string" then return nil end
    return CLASS_ABBR[s] or s
end

local POOL    = 40
local MODPOOL = 48

local function newText()
    local t = Drawing.new("Text"); t.Size = 13; t.Center = true; t.Outline = true; t.Font = FONT_SYS; t.Visible = false
    return t
end

local slots = {}
for i = 1, POOL do
    local s = { lines = {} }
    for j = 1, 12 do
        local l = Drawing.new("Line"); l.Thickness = 1; l.Color = COL_BOX; l.Visible = false
        s.lines[j] = l
    end
    s.name = newText(); s.cls = newText(); s.dist = newText(); s.reload = newText()
    local mk = Drawing.new("Circle"); mk.Thickness = 1.5; mk.NumSides = 16; mk.Filled = false; mk.Color = COL_BOX; mk.Visible = false
    s.marker = mk
    slots[i] = s
end
local function hideSlot(s)
    for j = 1, 12 do s.lines[j].Visible = false end
    s.name.Visible = false; s.cls.Visible = false; s.dist.Visible = false; s.reload.Visible = false; s.marker.Visible = false
end

local modSlots = {}
for i = 1, MODPOOL do
    local ms = { lines = {}, tris = {} }
    for j = 1, 12 do
        local l = Drawing.new("Line"); l.Thickness = 1; l.Visible = false; ms.lines[j] = l
        local tr = Drawing.new("Triangle"); tr.Filled = true; tr.Visible = false; ms.tris[j] = tr
    end
    modSlots[i] = ms
end
local function hideModSlot(ms)
    for j = 1, 12 do ms.lines[j].Visible = false; ms.tris[j].Visible = false end
end

local mslSlots = {}
for i = 1, MSLPOOL do
    local mk = Drawing.new("Circle"); mk.Thickness = 1.5; mk.NumSides = 12; mk.Filled = false; mk.Visible = false
    local tag = Drawing.new("Text"); tag.Size = 13; tag.Center = true; tag.Outline = true; tag.Font = FONT_SYS; tag.Visible = false
    mslSlots[i] = { marker = mk, tag = tag }
end
local function hideMslSlot(m) m.marker.Visible = false; m.tag.Visible = false end

local ovrBg = Drawing.new("Square")
ovrBg.Filled = true; ovrBg.Rounding = 0; ovrBg.Color = Color3_rgb(10, 10, 12)
ovrBg.Transparency = 0.45; ovrBg.Position = Vector2_new(12, 12); ovrBg.Size = Vector2_new(168, 108); ovrBg.Visible = false
local ovrTitle = Drawing.new("Text")
ovrTitle.Size = 14; ovrTitle.Font = FONT_MONO; ovrTitle.Outline = true; ovrTitle.Color = COL_ACC
ovrTitle.Position = Vector2_new(20, 18); ovrTitle.Visible = false
local ovrLines = {}
for i = 1, 5 do
    local t = Drawing.new("Text"); t.Size = 13; t.Font = FONT_MONO; t.Outline = true; t.Color = COL_OVR
    t.Position = Vector2_new(20, 38 + (i - 1) * 16); t.Visible = false
    ovrLines[i] = t
end

local ballRay = Drawing.new("Line")
ballRay.Thickness = 1.5; ballRay.Color = COL_BALL; ballRay.Transparency = 1; ballRay.Visible = false

local ballCrossH = Drawing.new("Line")
ballCrossH.Thickness = 2; ballCrossH.Color = COL_BALL; ballCrossH.Transparency = 1; ballCrossH.Visible = false
local ballCrossV = Drawing.new("Line")
ballCrossV.Thickness = 2; ballCrossV.Color = COL_BALL; ballCrossV.Transparency = 1; ballCrossV.Visible = false
local ballBg = Drawing.new("Square")
ballBg.Filled = true; ballBg.Rounding = 0; ballBg.Color = Color3_rgb(8, 14, 11); ballBg.Transparency = 0.5; ballBg.Visible = false
local ballTitle = Drawing.new("Text")
ballTitle.Size = 14; ballTitle.Font = FONT_MONO; ballTitle.Outline = true; ballTitle.Color = COL_BALL; ballTitle.Visible = false
local ballLines = {}
for i = 1, 5 do
    local t = Drawing.new("Text"); t.Size = 13; t.Font = FONT_MONO; t.Outline = true; t.Color = COL_OVR; t.Visible = false
    ballLines[i] = t
end
local ballRange = Drawing.new("Text")
ballRange.Size = 16; ballRange.Center = true; ballRange.Outline = true; ballRange.Font = FONT_MONO; ballRange.Color = COL_BALL; ballRange.Visible = false

local staffSlots = {}
for i = 1, STAFFPOOL do
    local mk = Drawing.new("Circle"); mk.Thickness = 2; mk.NumSides = 20; mk.Filled = false; mk.Color = COL_STAFF; mk.Visible = false
    local tag = Drawing.new("Text"); tag.Size = 13; tag.Center = true; tag.Outline = true; tag.Font = FONT_SYS; tag.Color = COL_STAFF; tag.Visible = false
    staffSlots[i] = { marker = mk, tag = tag }
end
local function hideStaffSlot(s) s.marker.Visible = false; s.tag.Visible = false end
local lastStaffDrawn = 0
local staffBg = Drawing.new("Square")
staffBg.Filled = true; staffBg.Rounding = 0; staffBg.Color = Color3_rgb(22, 6, 8); staffBg.Transparency = 0.55; staffBg.Visible = false
local staffTitle = Drawing.new("Text")
staffTitle.Size = 14; staffTitle.Font = FONT_MONO; staffTitle.Outline = true; staffTitle.Color = COL_STAFF; staffTitle.Visible = false
local staffLines = {}
for i = 1, STAFFPOOL do
    local t = Drawing.new("Text"); t.Size = 13; t.Font = FONT_MONO; t.Outline = true; t.Color = Color3_rgb(255, 175, 185); t.Visible = false
    staffLines[i] = t
end
local staffPopup = Drawing.new("Text")
staffPopup.Size = 22; staffPopup.Center = true; staffPopup.Outline = true; staffPopup.Font = FONT_MONO; staffPopup.Color = COL_STAFF; staffPopup.Visible = false

local cache = {}
local targets = {}

local function partCorners(part)
    local sz = part.Size
    if not sz then return nil end
    local hx, hy, hz = sz.X * 0.5, sz.Y * 0.5, sz.Z * 0.5
    return {
        { -hx, -hy, -hz }, { hx, -hy, -hz }, { -hx, -hy, hz }, { hx, -hy, hz },
        { -hx, hy, -hz },  { hx, hy, -hz },  { -hx, hy, hz },  { hx, hy, hz },
    }
end

local function collectModules(veh)
    local out = {}
    local dm = veh:FindFirstChild("DamageModules")
    if not dm then return out end
    for _, mdl in ipairs(dm:GetChildren()) do
        for _, p in ipairs(mdl:GetChildren()) do
            local nm = p.Name
            local kind
            if nm == "Engine" then kind = "eng"
            elseif nm:match("^AmmoModel%d+$") then kind = "ammo" end
            if kind then
                local ok, cr = pcall(partCorners, p)
                if ok and cr then out[#out + 1] = { part = p, corners = cr, kind = kind } end
            end
        end
    end
    return out
end

local function ballCaliber(name)
    local mm = name:match("(%d+%.?%d*)mm")
    if mm then return tonumber(mm) end
    local cal = name:match("(%d+%.?%d*)%s*[Cc]al")
    if cal then return tonumber(cal) / 100 * 25.4 end
    return 0
end

local function ballMainGun(veh)
    local turrets = veh and veh:FindFirstChild("Turrets")
    local t1 = turrets and turrets:FindFirstChild("Turret1")
    local w = t1 and t1:FindFirstChild("Weapons")
    if not w then return nil end
    local best, bestCal
    for _, g in ipairs(w:GetChildren()) do
        local c = ballCaliber(g.Name)
        if c >= 20 and (not bestCal or c > bestCal) then best = g; bestCal = c end
    end
    return best
end

local function buildVehicle(veh)
    local hull = veh:FindFirstChild("Hull")
    local mass = hull and hull:FindFirstChild("Mass")
    if not mass then return nil end
    local corners = partCorners(mass)
    if not corners then return nil end
    local gun = ballMainGun(veh)
    return {
        anchor  = mass, name = veh.Name,
        kind    = veh:GetAttribute("Type"),
        class   = classAbbr(veh:GetAttribute("VehicleClass")),
        gun     = gun,
        loaded  = gun and gun:FindFirstChild("CurrentlyLoaded"),
        teamColor = veh:GetAttribute("Team"),
        ownerVal = veh:FindFirstChild("Owner"),
        replen  = veh:FindFirstChild("Replenishable"),
        occupied = true,
        corners = corners,
        mods    = collectModules(veh),
    }
end

local function buildDrone(m)
    local pp = m.PrimaryPart
    if not pp then return nil end
    return {
        anchor = pp, name = m.Name, kind = "Drone",
        tag = (m.Name:gsub("%s*Drone%s*", "")):gsub("^%s*(.-)%s*$", "%1"),
        teamColor = m:GetAttribute("Team"),
        ownerVal = m:FindFirstChild("Owner"),
        ownerTag = m:FindFirstChild("OwnershipTag"),
        occupied = true,
    }
end

local function resolveAlly(e, myTeamName)
    if myTeamColor and e.teamColor then return e.teamColor == myTeamColor end
    if not myTeamName then return nil end

    local ov = e.ownerVal
    local plr = ov and ov.Value
    if plr then
        local ok, tm = pcall(function() return plr.Team end)
        if ok and tm and tm.Name then return tm.Name == myTeamName end
    end

    local ot = e.ownerTag
    local nm = ot and ot.Value
    if type(nm) == "string" and nm ~= "" then
        local p2 = Players:FindFirstChild(nm)
        local ok, tm = pcall(function() return p2 and p2.Team end)
        if ok and tm and tm.Name then return tm.Name == myTeamName end
    end
    return nil
end

local GRAIN_VISIBLE_OFFSET = 0x5ad

local RSTORAGE = game:GetService("ReplicatedStorage")
local GRAIN_TEMPLATES = {
    { RSTORAGE, "PlaceableModels", "Drone", "Script", "ControlGUI", "Grain" },
    { RSTORAGE, "PlaceableModels", "Recon Drone", "Script", "ControlGUI", "Grain" },
    { RSTORAGE, "PlaceableModels", "RPG Drone", "Script", "ControlGUI", "Grain" },
    { RSTORAGE, "PlaceableModels", "Rifle Drone", "Script", "ControlGUI", "Grain" },
    { RSTORAGE, "PlaceableModels", "Lancet Launcher", "Script", "ScreenGui", "Grain" },
    { RSTORAGE, "TankModules", "Drones", "ControlGUI", "Grain" },
}

local grainAddrs = {}
local grainOrig  = {}
local grainTick = 0

local function refreshGrainAddrs()
    local out = {}
    local pg = LP and LP:FindFirstChild("PlayerGui")
    if pg then

        local ctrl = pg:FindFirstChild("ControlGUI")
        if ctrl then
            for _, d in ipairs(ctrl:GetDescendants()) do
                if d.Name == "Grain" then
                    local a = d.Address
                    if a and a > 4096 then out[#out + 1] = a end
                end
            end
        end
    end
    for i = 1, #GRAIN_TEMPLATES do
        local p = GRAIN_TEMPLATES[i]
        local node = p[1]
        for j = 2, #p do node = node and node:FindFirstChild(p[j]) end
        local a = node and node.Address
        if a and a > 4096 then out[#out + 1] = a end
    end

    for i = 1, #out do
        local a = out[i]
        if grainOrig[a] == nil then
            local ok, b = pcall(memory_read, "byte", a + GRAIN_VISIBLE_OFFSET)
            if ok and b then grainOrig[a] = b end
        end
    end
    grainAddrs = out
end

local function enforceGrain()
    for i = 1, #grainAddrs do
        local a = grainAddrs[i]
        local ok, b = pcall(memory_read, "byte", a + GRAIN_VISIBLE_OFFSET)
        if ok and b ~= 0 then pcall(memory_write, "byte", a + GRAIN_VISIBLE_OFFSET, 0) end
    end
end

local function restoreGrain()
    for a, orig in pairs(grainOrig) do
        pcall(memory_write, "byte", a + GRAIN_VISIBLE_OFFSET, orig)
    end
    grainOrig = {}
    grainAddrs = {}
end

local PROJ = {}
do
    local function P(label, threat, names)
        for _, n in ipairs(names) do PROJ[n:lower()] = { label = label, threat = threat } end
    end
    P("AA",     true,  { "SAM", "SAM1", "SAM2", "SAM3", "StingerRocket", "PATRIOTProj", "aim9m", "kugelblitz" })
    P("ATGM",   false, { "wireatgm", "roketatgm", "KornetATGMModel", "302ATM", "DragonATGM", "nlawmis", "STURM", "SS.11", "losat", "testatgm", "Brimstone" })
    P("AGM",    false, { "agm65", "kh25ml", "kh35", "kh38mle" })
    P("Rocket", false, { "MLRSRocket", "RP3RocketModel", "RP3Rocket", "RGB-60", "roket", "roketbeg", "RPG", "IskanderRocket", "HERO-120" })
    P("Bomb",   true,  { "Bomb", "fab500m62", "mk842000lbs" })
end
local mslContainers = {}
do
    local ok, shells = pcall(function() return game:GetService("ReplicatedStorage").PHRST.Shells end)
    if ok and shells then local f = shells:FindFirstChild("PhysicalBullets"); if f then mslContainers[#mslContainers + 1] = f end end
    local ter = Workspace:FindFirstChild("Terrain"); if ter then mslContainers[#mslContainers + 1] = ter end
end
local mslTargets = {}
local mslPrev = {}
local lastMslDrawn = 0

local crewLoadBar = nil
local reloadArmed    = true
local reloadNextFire = 0
local reloadLastNX   = nil

local flareArmed  = true
local flareNextAt = 0
local function tapFlare()
    keypress(FLARE_VK); task.wait(0.05); pcall(keyrelease, FLARE_VK)
end
local function throwFlares()
    tapFlare(); task.wait(0.12); tapFlare()
    task.wait(1.6)
    tapFlare(); task.wait(0.12); tapFlare()
end

local modSet = {}
local modReady = false
local modTargets = {}
local modSeen = {}
local staffPopupText, staffPopupUntil = nil, 0
local HttpSvc = game:GetService("HttpService")
task.spawn(function()
    for _, r in ipairs(MOD_ROLES) do
        local url = "https://groups.roblox.com/v1/groups/" .. MOD_GROUP .. "/roles/" .. r.id .. "/users?limit=100&sortOrder=Asc"
        local ok, res = pcall(httpget, url)
        if ok and res then
            local dok, data = pcall(function() return HttpSvc:JSONDecode(res) end)
            if dok and type(data) == "table" and data.data then
                for _, u in ipairs(data.data) do
                    local uid = tonumber(u.userId)
                    if uid then modSet[uid] = r.name end
                end
            end
        end
        task.wait(0.2)
    end
    modReady = true
end)

local LocalPlayers = game:GetService("Players")
local function kdStaffPresent()
    if not modReady then return nil end
    local myId = LP and LP.UserId
    for _, pl in ipairs(LocalPlayers:GetPlayers()) do
        local uid = pl.UserId
        if uid and uid ~= myId and modSet[uid] then return pl.Name end
    end
    return nil
end

local function kdEnabled()
    if Config.KDDrop then return true end
    local ok, v = pcall(UI.GetValue, "kd_drop")
    return ok and v == true
end
task.spawn(function()
    local warned = false
    while running do
        if kdEnabled() then
            local staff = kdStaffPresent()
            if staff then
                if not warned then pcall(notify, "KD DROPPER", "Staff in server (" .. tostring(staff) .. ") - paused", 4); warned = true end
                task.wait(3)
            else
                warned = false
                local ch = LP and LP.Character
                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local p = hrp.Position
                    pcall(function() hrp.CFrame = CFrame_new(p.X, KD_DROP_Y, p.Z) end)

                    local w = 0
                    while w < KD_CYCLE and kdEnabled() do
                        task.wait(1); w = w + 1
                        if w < 3 and kdStaffPresent() then break end
                    end
                else
                    task.wait(1)
                end
            end
        else
            warned = false
            task.wait(0.3)
        end
    end
end)

local running = true
task.spawn(function()
    while running do
        local mt = LP and LP.Team
        local myTeamName = mt and mt.Name or nil
        myTeamColor = mt and FACTION_COLOR[mt.Name] or nil
        do
            local pg = LP and LP:FindFirstChild("PlayerGui")
            local cg = pg and pg:FindFirstChild("CrewGui")
            crewLoadBar = cg and cg:FindFirstChild("loadBar") or nil
        end

        if Config.HideGrain then
            grainTick = grainTick + 1
            if grainTick >= 4 or #grainAddrs == 0 then grainTick = 0; refreshGrainAddrs() end
        end
        local out = {}
        local sv = Workspace:FindFirstChild("SpawnedVehicles")
        if sv then
            local seen = {}
            for _, veh in ipairs(sv:GetChildren()) do
                local addr = veh.Address
                if addr then
                    seen[addr] = true
                    local e = cache[addr]
                    if e == nil then e = buildVehicle(veh); cache[addr] = e or false end
                    if e then
                        e.occupied = veh:GetAttribute("Occupied") ~= false
                        e.ally = resolveAlly(e, myTeamName)
                        out[#out + 1] = e
                    end
                end
            end

            local pb = Workspace:FindFirstChild("PlacedBuildings")
            if pb and Config.Drone then
                for _, m in ipairs(pb:GetChildren()) do
                    if m:GetAttribute("Drone") then
                        local addr = m.Address

                        local pp = m.PrimaryPart
                        if addr and pp then
                            seen[addr] = true
                            local e = cache[addr]
                            if e == nil then e = buildDrone(m); cache[addr] = e or false end
                            if e then
                                e.anchor = pp
                                e.ally = resolveAlly(e, myTeamName)
                                out[#out + 1] = e
                            end
                        elseif addr then
                            cache[addr] = nil
                        end
                    end
                end
            end
            for addr in pairs(cache) do if not seen[addr] then cache[addr] = nil end end
        end

        if Config.ModChecker and modReady then
            local mout = {}
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LP then
                    local role = modSet[pl.UserId]
                    if role then
                        local ch = pl.Character
                        local root = ch and (ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Head"))
                        mout[#mout + 1] = { root = root, name = pl.Name, role = role }
                        if not modSeen[pl.UserId] then
                            modSeen[pl.UserId] = true
                            pcall(notify, "STAFF IN SERVER", role .. ": " .. pl.Name, 8)
                            staffPopupText = role:upper() .. "  -  " .. pl.Name .. "  IS IN THE SERVER"
                            staffPopupUntil = tick() + 6
                        end
                    end
                end
            end
            modTargets = mout
        elseif #modTargets > 0 and not Config.ModChecker then
            modTargets = {}
        end
        targets = out
        task.wait(0.5)
    end
end)

task.spawn(function()
    while running do
        if Config.Missile or Config.AutoFlare then
            local mout, mseen = {}, {}

            local myPos
            if Config.AutoFlare then
                local ch = LP and LP.Character
                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                myPos = hrp and hrp.Position
                if not myPos then local cc = Workspace.CurrentCamera; myPos = cc and cc.CFrame.Position end
            end
            local threatNear = false
            for _, cont in ipairs(mslContainers) do
                for _, c in ipairs(cont:GetChildren()) do
                    local cn = c.ClassName
                    local anchor
                    if cn == "MeshPart" or cn == "Part" or cn == "UnionOperation" then anchor = c
                    elseif cn == "Model" then anchor = c.PrimaryPart end
                    if anchor then
                        local cat = PROJ[c.Name:lower()]
                        if cat then
                            local a2 = c.Address
                            local pp = anchor.Position
                            if a2 and pp then
                                mseen[a2] = true
                                local px, py, pz = pp.X, pp.Y, pp.Z
                                local moving = false
                                local vel = anchor.AssemblyLinearVelocity
                                if vel and (vel.X * vel.X + vel.Y * vel.Y + vel.Z * vel.Z) > 100 then moving = true end
                                local pv = mslPrev[a2]
                                local mvx, mvy, mvz = 0, 0, 0
                                if pv then
                                    mvx, mvy, mvz = px - pv[1], py - pv[2], pz - pv[3]
                                    if not moving and (mvx * mvx + mvy * mvy + mvz * mvz) > MSL_MOVE2 then moving = true end
                                    pv[1], pv[2], pv[3] = px, py, pz
                                else
                                    mslPrev[a2] = { px, py, pz }
                                end
                                if moving then
                                    mout[#mout + 1] = { anchor = anchor, label = cat.label, threat = cat.threat }

                                    if Config.AutoFlare and cat.threat and cat.label == "AA" and myPos and pv then
                                        local tmx, tmy, tmz = myPos.X - px, myPos.Y - py, myPos.Z - pz
                                        if (tmx * tmx + tmy * tmy + tmz * tmz) < (FLARE_RANGE * FLARE_RANGE)
                                           and (mvx * tmx + mvy * tmy + mvz * tmz) > 0 then
                                            threatNear = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            for a2 in pairs(mslPrev) do if not mseen[a2] then mslPrev[a2] = nil end end
            mslTargets = mout

            if Config.AutoFlare then
                if threatNear and flareArmed and os.clock() >= flareNextAt then
                    flareArmed = false
                    flareNextAt = os.clock() + FLARE_COOL
                    pcall(notify, "THREAT", "SAM inbound, deploying flares", 3)
                    task.spawn(throwFlares)
                elseif not threatNear then
                    flareArmed = true
                end
            end
        elseif #mslTargets > 0 then
            mslTargets = {}
            for k in pairs(mslPrev) do mslPrev[k] = nil end
        end
        task.wait(0.1)
    end
end)

local ballResult = nil
local function ballVehOf(inst)
    local sv = Workspace:FindFirstChild("SpawnedVehicles")
    local svA = sv and sv.Address
    local n = inst
    while n and n.Parent do
        local pa = n.Parent.Address
        if pa and svA and pa == svA then return n end
        n = n.Parent
    end
end

local function ballOwnVehicle()
    local ch = LP and LP.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil end
    local prm = RaycastParams.new(); prm.FilterType = Enum.RaycastFilterType.Exclude; prm.FilterDescendantsInstances = { ch }
    local r = Workspace:Raycast(hrp.Position, Vector3_new(0, -60, 0), prm)
    return (r and ballVehOf(r.Instance)) or nil, ch
end

local function ballBarrel(gun)
    local mo = gun and gun:FindFirstChild("Muzzle")
    if mo and mo.Value and mo.Value.CFrame then return mo.Value end
    local cm = gun and gun:FindFirstChild("CurrentMuzzle")
    local inner = cm and cm.Value and cm.Value:FindFirstChild("Muzzle")
    if inner and inner.Value then return inner.Value end
    return nil
end

local function ballOptic(veh)
    local turrets = veh and veh:FindFirstChild("Turrets")
    local t1 = turrets and turrets:FindFirstChild("Turret1")
    local cams = t1 and t1:FindFirstChild("Cameras")
    if not cams then return nil end
    for _, nm in ipairs({ "MainSight", "TelescopeSight", "PeriscopeSight", "GunnerSight" }) do
        local o = cams:FindFirstChild(nm)
        if o and o.Value and o.Value.CFrame then return o.Value end
    end
    for _, o in ipairs(cams:GetChildren()) do
        local ln = o.Name:lower()
        if o.Value and o.Value.CFrame and not ln:find("backup") and not ln:find("mg") then return o.Value end
    end
    return nil
end

local function ballHullCenter(veh)
    local sx, sy, sz, n = 0, 0, 0, 0
    for _, d in ipairs(veh:GetDescendants()) do
        local cn = d.ClassName
        if cn == "Part" or cn == "MeshPart" then
            local p = d.Position; sx = sx + p.X; sy = sy + p.Y; sz = sz + p.Z; n = n + 1
        end
    end
    if n == 0 then return nil end
    return Vector3_new(sx / n, sy / n, sz / n)
end

local ballShellMap = {}
local function ballBuildShellMap()
    local map = {}
    local pg = LP and LP:FindFirstChild("PlayerGui")
    local cg = pg and pg:FindFirstChild("CrewGui")
    if not cg then return map end
    for _, d in ipairs(cg:GetDescendants()) do
        if d.Name == "AmmoName" and d.ClassName == "TextLabel" and d.Text and d.Text ~= "" then
            local entry = d.Parent
            local dt = entry and entry:FindFirstChild("DataTable")
            local velL = dt and dt:FindFirstChild("Velocity")
            if velL then
                local v = tonumber((velL.Text or ""):match("(%d+)"))
                if v then
                    local typeL = entry:FindFirstChild("AmmoType")
                    map[d.Text] = { vel = v, typ = (typeL and typeL.Text) or "" }
                end
            end
        end
    end
    return map
end
task.spawn(function()
    local ballVehA, ballSign = nil, 1
    local mapClock = 0
    while running do
        if Config.Ballistic then
            local pg = LP and LP:FindFirstChild("PlayerGui")
            local crewing = pg and pg:FindFirstChild("CrewGui")
            local veh, ch = nil, nil
            if crewing then veh, ch = ballOwnVehicle() end
            local gun = veh and ballMainGun(veh)

            local barrel = gun and ballBarrel(gun)
            local optic  = veh and ballOptic(veh)
            local part   = barrel or optic
            local pcf = part and part.CFrame
            if pcf then
                if os.clock() - mapClock > 1.5 then ballShellMap = ballBuildShellMap(); mapClock = os.clock() end
                local o = pcf.Position
                local dir = pcf.LookVector

                local vehA = veh.Address
                if vehA ~= ballVehA then
                    local center = ballHullCenter(veh)
                    ballSign = (center and dir:Dot(o - center) < 0) and -1 or 1
                    ballVehA = vehA
                end
                dir = dir * ballSign
                local refPos = (optic and optic.CFrame and optic.CFrame.Position) or o
                local prm = RaycastParams.new(); prm.FilterType = Enum.RaycastFilterType.Exclude
                prm.FilterDescendantsInstances = { ch, veh }
                local origin, hit = o, nil
                for _ = 1, 6 do
                    local r = Workspace:Raycast(origin, dir * 9000, prm)
                    if not r then break end
                    local hv = ballVehOf(r.Instance)
                    local ownHit = (hv and hv.Address == vehA) or (ch and r.Instance:IsDescendantOf(ch))
                    if ownHit then origin = r.Position + dir * 3 else hit = r; break end
                end
                if hit then
                    local studs = (hit.Position - refPos).Magnitude
                    local loaded = gun and gun:FindFirstChild("CurrentlyLoaded")
                    local sname = loaded and loaded.Value
                    local sd = sname and ballShellMap[sname]
                    local vel = (sd and sd.vel) or SHELL_VEL_DEFAULT
                    local flightT = studs / (vel * STUD_PER_M)
                    ballResult = {
                        distM   = studs * STUDS_TO_M,
                        hitPos  = hit.Position,
                        originPos = o,
                        shell   = sname,
                        shType  = sd and sd.typ,
                        vel     = vel,
                        flightT = flightT,
                        dropM   = (0.5 * PROJ_GRAV * flightT * flightT) * STUDS_TO_M,
                    }
                else
                    ballResult = { distM = nil, originPos = o, tipPos = o + dir * 300 }
                end
            else
                ballResult = nil
            end
        elseif ballResult then
            ballResult = nil
        end
        task.wait(0.06)
    end
end)

local fps = 60
local PTS, FRONT   = {}, {}
local MPTS, MFRONT = {}, {}
local lastDrawn, lastModDrawn = 0, 0

local function readCP(id, defCol, defA)
    local ok, r, g, b, a = pcall(UI.GetValue, id)
    if not ok or type(r) ~= "number" then return defCol, defA end
    local col = defCol
    if type(g) == "number" and type(b) == "number" then
        col = (r <= 1 and g <= 1 and b <= 1) and Color3_new(r, g, b) or Color3_rgb(r, g, b)
    end
    local al = defA
    if type(a) == "number" then al = (a > 1) and (a / 255) or a end
    return col, al
end

local function projectBox(cf, corners, pts, front, sw, sh)
    local center = cf.Position
    local rv, uv, lv = cf.RightVector, cf.UpVector, cf.LookVector
    local px, py, pz = center.X, center.Y, center.Z
    local rx, ry, rz = rv.X, rv.Y, rv.Z
    local ux, uy, uz = uv.X, uv.Y, uv.Z
    local lx, ly, lz = lv.X, lv.Y, lv.Z
    local anyVis = false
    local minX, minY, maxX = huge, huge, -huge
    for c = 1, 8 do
        local lc = corners[c]
        local ax, ay, az = lc[1], lc[2], lc[3]
        local sp, vis = WTS(Vector3_new(px + rx * ax + ux * ay - lx * az, py + ry * ax + uy * ay - ly * az, pz + rz * ax + uz * ay - lz * az))
        if vis and sp then
            local x, y = floor(sp.X + 0.5), floor(sp.Y + 0.5)
            pts[c] = Vector2_new(x, y); front[c] = true
            local cxp = x < 0 and 0 or (x > sw and sw or x)
            local cyp = y < 0 and 0 or (y > sh and sh or y)
            if cxp < minX then minX = cxp end
            if cxp > maxX then maxX = cxp end
            if cyp < minY then minY = cyp end
            if x >= 0 and y >= 0 and x <= sw and y <= sh then anyVis = true end
        else
            front[c] = false
        end
    end
    return anyVis, minX, minY, maxX
end

local function drawEdges(lines, pts, front, col, alpha)
    for j = 1, 12 do
        local e = BoxEdges[j]
        local l = lines[j]
        local a, b = e[1], e[2]
        if front[a] and front[b] then
            l.From = pts[a]; l.To = pts[b]; l.Color = col; l.Transparency = alpha; l.Visible = true
        else
            l.Visible = false
        end
    end
end

local function drawFaces(tris, pts, front, col, alpha)
    for j = 1, 12 do
        local f = FaceTris[j]
        local tr = tris[j]
        local a, b, c = f[1], f[2], f[3]
        if front[a] and front[b] and front[c] then
            tr.PointA = pts[a]; tr.PointB = pts[b]; tr.PointC = pts[c]
            tr.Color = col; tr.Filled = true; tr.Transparency = alpha; tr.Visible = true
        else
            tr.Visible = false
        end
    end
end

local conn = RS.RenderStepped:Connect(function(dt)
    if not running then return end
    if dt and dt > 0 then fps = fps * 0.9 + (1 / dt) * 0.1 end

    if Config.AutoReload and crewLoadBar then
        local needle, win
        for _, d in ipairs(crewLoadBar:GetDescendants()) do
            local n = d.Name
            if n == "Needle" then needle = d elseif n == "FastReloadWindow" then win = d end
        end
        if needle and win then
            local nAbs, wAbs, wSz = needle.AbsolutePosition, win.AbsolutePosition, win.AbsoluteSize
            if nAbs and wAbs and wSz and wSz.X > 0 then
                local nx = nAbs.X + 1
                local ws, we = wAbs.X, wAbs.X + wSz.X
                local now = tick()

                if reloadLastNX and nx < reloadLastNX - 50 then reloadArmed = true end
                if reloadArmed and now >= reloadNextFire and reloadLastNX then
                    local lo, hi = reloadLastNX, nx
                    if lo > hi then lo, hi = hi, lo end
                    if lo <= we and hi >= ws then
                        reloadArmed = false
                        reloadNextFire = now + 1.0
                        keypress(RELOAD_VK)
                        task.delay(0.045, function() pcall(keyrelease, RELOAD_VK) end)
                    end
                end
                reloadLastNX = nx
            end
        else
            reloadArmed = true; reloadLastNX = nil
        end
    end

    if Config.HideGrain then enforceGrain() end

    ovrBg.Visible = Config.Overlay; ovrTitle.Visible = Config.Overlay
    for i = 1, 5 do ovrLines[i].Visible = Config.Overlay end

    if Config.Ballistic and ballResult then

        local ballCol, ballA = readCP("misc_ball_col", COL_BALL, 1)
        ballRay.Color = ballCol; ballRay.Transparency = ballA
        ballCrossH.Color = ballCol; ballCrossH.Transparency = ballA
        ballCrossV.Color = ballCol; ballCrossV.Transparency = ballA
        ballRange.Color = ballCol; ballRange.Transparency = ballA
        ballTitle.Color = ballCol; ballTitle.Transparency = ballA
        ballBg.Transparency = 0.5 * ballA
        for i = 1, 5 do ballLines[i].Transparency = ballA end
        local bcam = Workspace.CurrentCamera
        local bvp = bcam and bcam.ViewportSize
        local vpy = (bvp and bvp.Y) or 1080
        local px, py = 12, vpy - 138
        ballBg.Position = Vector2_new(px, py); ballBg.Size = Vector2_new(184, 122); ballBg.Visible = true
        ballTitle.Text = "BALLISTIC"; ballTitle.Position = Vector2_new(px + 10, py + 6); ballTitle.Visible = true

        local sO, visO = WTS(ballResult.originPos)
        if ballResult.distM then
            local sH, visH = WTS(ballResult.hitPos)
            if visH and sH then
                local x, y = floor(sH.X + 0.5), floor(sH.Y + 0.5)
                local h = 7
                ballCrossH.From = Vector2_new(x - h, y); ballCrossH.To = Vector2_new(x + h, y); ballCrossH.Visible = true
                ballCrossV.From = Vector2_new(x, y - h); ballCrossV.To = Vector2_new(x, y + h); ballCrossV.Visible = true
                ballRange.Text = string.format("%.0f m", ballResult.distM)
                ballRange.Position = Vector2_new(x, y + 12); ballRange.Visible = true
                if visO and sO then
                    ballRay.From = Vector2_new(floor(sO.X + 0.5), floor(sO.Y + 0.5)); ballRay.To = Vector2_new(x, y); ballRay.Visible = true
                else ballRay.Visible = false end
            else
                ballCrossH.Visible = false; ballCrossV.Visible = false; ballRange.Visible = false; ballRay.Visible = false
            end
            local shell = ballResult.shell or "?"
            if ballResult.shType and ballResult.shType ~= "" then shell = shell .. " (" .. ballResult.shType .. ")" end
            ballLines[1].Text = string.format("Range   %.0f m", ballResult.distM)
            ballLines[2].Text = "Shell   " .. shell
            ballLines[3].Text = string.format("Vel     %d m/s", ballResult.vel or 0)
            ballLines[4].Text = string.format("Flight  ~%.2f s", ballResult.flightT)
            ballLines[5].Text = string.format("Drop    ~%.2f m", ballResult.dropM)
            for i = 1, 5 do ballLines[i].Position = Vector2_new(px + 10, py + 27 + (i - 1) * 17); ballLines[i].Visible = true end
        else

            ballCrossH.Visible = false; ballCrossV.Visible = false; ballRange.Visible = false
            local sT, visT = WTS(ballResult.tipPos or ballResult.originPos)
            if visO and sO and visT and sT then
                ballRay.From = Vector2_new(floor(sO.X + 0.5), floor(sO.Y + 0.5)); ballRay.To = Vector2_new(floor(sT.X + 0.5), floor(sT.Y + 0.5)); ballRay.Visible = true
            else ballRay.Visible = false end
            ballLines[1].Text = "Range   (no target)"; ballLines[1].Position = Vector2_new(px + 10, py + 27); ballLines[1].Visible = true
            for i = 2, 5 do ballLines[i].Visible = false end
        end
    else
        ballCrossH.Visible = false; ballCrossV.Visible = false; ballRange.Visible = false; ballRay.Visible = false
        ballBg.Visible = false; ballTitle.Visible = false
        for i = 1, 5 do ballLines[i].Visible = false end
    end

    if not Config.Enabled then
        for i = 1, lastDrawn do hideSlot(slots[i]) end
        for i = 1, lastModDrawn do hideModSlot(modSlots[i]) end
        lastDrawn, lastModDrawn = 0, 0
        if Config.Overlay then ovrTitle.Text = "BUYCHEAT.ORG  [off]"; for i = 1, 5 do ovrLines[i].Text = "" end end
        return
    end

    local cam = Workspace.CurrentCamera
    local camCF = cam and cam.CFrame
    local eye = camCF and camCF.Position
    local look = camCF and camCF.LookVector
    local vp  = cam and cam.ViewportSize
    local sw  = (vp and vp.X) or 1920
    local sh  = (vp and vp.Y) or 1080
    local list = targets
    local showBox, showName, showClass, showDist = Config.Box, Config.Names, Config.Class, Config.Distance
    local fade, maxDist = Config.Fade, Config.MaxDist
    local heliOn, droneOn, occOnly, teamChk = Config.Heli, Config.Drone, Config.OccupiedOnly, Config.TeamCheck
    local modOn = (Config.ModOutline or Config.ModFilled) and (Config.ModEngine or Config.ModAmmo)
    local modMax = Config.ModMaxDist
    local engCol, engA = readCP("mod_engine_col", COL_ENGINE, MOD_FILL_A)
    local ammoCol, ammoA = readCP("mod_ammo_col", COL_AMMO, MOD_FILL_A)

    local boxCol, boxA     = readCP("mtc_box_col",   COL_BOX,   1)
    local nameCol, nameA   = readCP("mtc_name_col",  COL_NAME,  1)
    local classCol, classA = readCP("mtc_class_col", COL_CLASS, 1)
    local distCol, distA   = readCP("mtc_dist_col",  COL_DIST,  1)

    local detected = #list
    local drawn, modDrawn = 0, 0
    local nearName, nearM = nil, huge

    for i = 1, detected do
        if drawn >= POOL then break end
        local t = list[i]
        local isHeli = (t.kind == "Heli")
        local isDrone = (t.kind == "Drone")

        if (isHeli and not heliOn) or (isDrone and not droneOn) or (occOnly and not t.occupied)
            or (teamChk and t.ally == true) then

        else
            local anchor = t.anchor
            local cf = anchor and anchor.CFrame
            if cf then
                local center = cf.Position
                local dm, behind = nil, false
                if eye then
                    local rel = center - eye
                    dm = floor(rel.Magnitude * STUDS_TO_M)
                    if dm < nearM then nearM = dm; nearName = t.name end
                    if look and rel:Dot(look) <= 0 then behind = true end
                end

                local skip = behind or (dm ~= nil and dm > (isDrone and DRONE_MAX or maxDist))
                local alpha = 1
                if fade and dm and not isDrone then
                    alpha = (FADE_END - dm) / (FADE_END - FADE_START)
                    if alpha > 1 then alpha = 1 elseif alpha <= 0 then skip = true; alpha = 0 end
                end

                if not skip then
                    local fsize = 14
                    if dm then fsize = 14 - dm * 0.004; if fsize < 9 then fsize = 9 elseif fsize > 14 then fsize = 14 end; fsize = floor(fsize + 0.5) end
                    local step = fsize + 2

                    if isHeli or isDrone then

                        local sp, vis = WTS(center)
                        if vis and sp then
                            local x, y = floor(sp.X + 0.5), floor(sp.Y + 0.5)
                            if x >= 0 and x <= sw and y >= 0 and y <= sh then
                                drawn = drawn + 1
                                local s = slots[drawn]
                                for j = 1, 12 do s.lines[j].Visible = false end
                                s.marker.Position = Vector2_new(x, y); s.marker.Radius = fsize * 0.5
                                s.marker.Color = isDrone and COL_DRONE or boxCol
                                s.marker.Transparency = isDrone and alpha or (alpha * boxA); s.marker.Visible = isDrone or showBox
                                s.cls.Visible = false
                                local yy = y - floor(fsize * 0.5) - 4 - fsize
                                if isDrone then

                                    s.dist.Visible = false
                                    s.name.Size = fsize; s.name.Text = t.tag; s.name.Color = COL_DRONE
                                    s.name.Transparency = alpha; s.name.Position = Vector2_new(x, yy); s.name.Visible = true
                                else
                                    if showDist and dm then
                                        s.dist.Size = fsize; s.dist.Text = dm .. "m"; s.dist.Color = distCol
                                        s.dist.Transparency = alpha * distA; s.dist.Position = Vector2_new(x, yy); s.dist.Visible = true; yy = yy - step
                                    else s.dist.Visible = false end
                                    if showName then
                                        s.name.Size = fsize; s.name.Text = t.name; s.name.Color = nameCol
                                        s.name.Transparency = alpha * nameA; s.name.Position = Vector2_new(x, yy); s.name.Visible = true
                                    else s.name.Visible = false end
                                end
                            end
                        end
                    else
                        local anyVis, minX, minY, maxX = projectBox(cf, t.corners, PTS, FRONT, sw, sh)
                        if anyVis then
                            drawn = drawn + 1
                            local s = slots[drawn]
                            s.marker.Visible = false

                            if showBox then drawEdges(s.lines, PTS, FRONT, boxCol, alpha * boxA)
                            else for j = 1, 12 do s.lines[j].Visible = false end end

                            local cx = floor((minX + maxX) / 2)
                            local yy = minY - 4 - fsize

                            if showDist and dm then
                                s.dist.Size = fsize; s.dist.Text = dm .. "m"; s.dist.Color = distCol
                                s.dist.Transparency = alpha * distA; s.dist.Position = Vector2_new(cx, yy); s.dist.Visible = true; yy = yy - step
                            else s.dist.Visible = false end
                            if showName then
                                s.name.Size = fsize; s.name.Text = t.name; s.name.Color = nameCol
                                s.name.Transparency = alpha * nameA; s.name.Position = Vector2_new(cx, yy); s.name.Visible = true; yy = yy - step
                            else s.name.Visible = false end
                            if showClass and t.class then
                                s.cls.Size = fsize; s.cls.Text = t.class; s.cls.Color = classCol
                                s.cls.Transparency = alpha * classA; s.cls.Position = Vector2_new(cx, yy); s.cls.Visible = true; yy = yy - step
                            else s.cls.Visible = false end

                            if Config.ReloadStatus and t.gun then
                                local rl = t.gun:GetAttribute("reloading")
                                local reloading = (rl == true) or (type(rl) == "string" and rl ~= "" and rl:lower() ~= "false")
                                local loadedName = t.loaded and t.loaded.Value
                                local chambered = loadedName ~= nil and loadedName ~= "" and loadedName ~= "Unloaded"
                                local txt, col
                                if reloading then txt, col = "RELOADING", COL_CLASS
                                elseif chambered then txt, col = "READY", COL_ACC
                                else txt, col = "EMPTY", COL_AMMO end
                                s.reload.Size = fsize
                                s.reload.Text = txt; s.reload.Color = col
                                s.reload.Transparency = alpha; s.reload.Position = Vector2_new(cx, yy); s.reload.Visible = true
                            else s.reload.Visible = false end

                            if modOn and dm and dm <= modMax then
                                local mods = t.mods
                                for mi = 1, #mods do
                                    if modDrawn >= MODPOOL then break end
                                    local m = mods[mi]
                                    if (m.kind == "eng" and Config.ModEngine) or (m.kind == "ammo" and Config.ModAmmo) then
                                        local mcf = m.part.CFrame
                                        if mcf then
                                            local mvis = projectBox(mcf, m.corners, MPTS, MFRONT, sw, sh)
                                            if mvis then
                                                modDrawn = modDrawn + 1
                                                local ms = modSlots[modDrawn]
                                                local isEng = (m.kind == "eng")
                                                local col = isEng and engCol or ammoCol
                                                if Config.ModOutline then drawEdges(ms.lines, MPTS, MFRONT, col, 1)
                                                else for j = 1, 12 do ms.lines[j].Visible = false end end
                                                if Config.ModFilled then drawFaces(ms.tris, MPTS, MFRONT, col, isEng and engA or ammoA)
                                                else for j = 1, 12 do ms.tris[j].Visible = false end end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for i = drawn + 1, lastDrawn do hideSlot(slots[i]) end
    for i = modDrawn + 1, lastModDrawn do hideModSlot(modSlots[i]) end
    lastDrawn, lastModDrawn = drawn, modDrawn

    local mdrawn = 0
    if Config.Missile then
        local ml = mslTargets
        local cam = Workspace.CurrentCamera
        local campos = cam and cam.CFrame.Position
        for i = 1, #ml do
            if mdrawn >= MSLPOOL then break end
            local t = ml[i]
            local anchor = t.anchor
            if anchor and anchor.Parent then
                local pos = anchor.Position
                local sp, vis = WTS(pos)
                if vis and sp then
                    mdrawn = mdrawn + 1
                    local m = mslSlots[mdrawn]
                    local col = t.threat and COL_THREAT or COL_MISSILE
                    local x, y = floor(sp.X + 0.5), floor(sp.Y + 0.5)
                    m.marker.Position = Vector2_new(x, y); m.marker.Radius = 6
                    m.marker.Color = col; m.marker.Transparency = 1; m.marker.Visible = true
                    local lbl = t.label
                    if campos then lbl = lbl .. "  " .. floor((pos - campos).Magnitude * STUDS_TO_M) .. "m" end
                    m.tag.Text = lbl; m.tag.Color = col
                    m.tag.Position = Vector2_new(x, y - 18); m.tag.Transparency = 1; m.tag.Visible = true
                end
            end
        end
    end
    for i = mdrawn + 1, lastMslDrawn do hideMslSlot(mslSlots[i]) end
    lastMslDrawn = mdrawn

    local staffDrawn = 0
    if Config.ModChecker then
        local ml = modTargets
        for i = 1, #ml do
            if staffDrawn >= STAFFPOOL then break end
            local root = ml[i].root
            if root then
                local pos = root.Position
                local top, v1 = WTS(Vector3_new(pos.X, pos.Y + 3, pos.Z))
                local bot, v2 = WTS(Vector3_new(pos.X, pos.Y - 3, pos.Z))
                if v1 and v2 and top and bot then
                    staffDrawn = staffDrawn + 1
                    local s = staffSlots[staffDrawn]
                    local cx = (top.X + bot.X) * 0.5
                    local cy = (top.Y + bot.Y) * 0.5
                    local rad = (bot.Y - top.Y) * 0.5; if rad < 0 then rad = -rad end; if rad < 6 then rad = 6 end
                    s.marker.Position = Vector2_new(floor(cx + 0.5), floor(cy + 0.5))
                    s.marker.Radius = rad; s.marker.Visible = true
                    s.tag.Text = ml[i].role .. "  " .. ml[i].name
                    s.tag.Position = Vector2_new(floor(cx + 0.5), floor(top.Y - 15))
                    s.tag.Visible = true
                end
            end
        end
    end
    for i = staffDrawn + 1, lastStaffDrawn do hideStaffSlot(staffSlots[i]) end
    lastStaffDrawn = staffDrawn

    if Config.ModChecker and #modTargets > 0 then
        local cam = Workspace.CurrentCamera
        local vpx = (cam and cam.ViewportSize.X) or 1920
        local px = vpx - 236
        local n = #modTargets; if n > STAFFPOOL then n = STAFFPOOL end
        staffBg.Position = Vector2_new(px, 12); staffBg.Size = Vector2_new(224, 26 + n * 16); staffBg.Visible = true
        staffTitle.Text = "STAFF IN SERVER (" .. #modTargets .. ")"; staffTitle.Position = Vector2_new(px + 8, 18); staffTitle.Visible = true
        for i = 1, STAFFPOOL do
            local t = modTargets[i]
            if t then
                staffLines[i].Text = t.role .. "  " .. t.name
                staffLines[i].Position = Vector2_new(px + 8, 40 + (i - 1) * 16)
                staffLines[i].Visible = true
            else
                staffLines[i].Visible = false
            end
        end
    else
        staffBg.Visible = false; staffTitle.Visible = false
        for i = 1, STAFFPOOL do staffLines[i].Visible = false end
    end

    if Config.ModChecker and #modTargets > 0 then
        local cam = Workspace.CurrentCamera
        local vp = (cam and cam.ViewportSize) or Vector2_new(1920, 1080)
        local n = #modTargets
        staffPopup.Text = "!!  " .. (n > 1 and (n .. " STAFF") or modTargets[1].role:upper()) .. " IN THE SERVER  !!"
        staffPopup.Position = Vector2_new(vp.X * 0.5, vp.Y * 0.12); staffPopup.Visible = true
    else
        staffPopup.Visible = false
    end

    if Config.Overlay then
        ovrTitle.Text = "BUYCHEAT.ORG"
        ovrLines[1].Text = "FPS       " .. floor(fps)
        ovrLines[2].Text = "Ping      " .. floor(GetPingValue() or 0) .. "ms"
        ovrLines[3].Text = "Vehicles  " .. detected
        ovrLines[4].Text = "On-screen " .. drawn
        ovrLines[5].Text = "Nearest   " .. (nearName and (nearName .. " " .. nearM .. "m") or "-")
    end
end)

local function try(f) local ok, e = pcall(f); if not ok then warn("[MTC] widget:", e) end end
local NOOP = function() end

local uiOk, uiErr = pcall(function()
    UI.AddTab("MTC", function(tab)
        local sec = tab:Section("Tank ESP", "Left")
        try(function() sec:Toggle("mtc_enabled", "Tank ESP", Config.Enabled, function(v) Config.Enabled = v end) end)

        try(function() sec:Toggle("mtc_box", "Box ESP", Config.Box, function(v) Config.Box = v end) end)
        try(function() sec:ColorPicker("mtc_box_col", 255, 255, 255, 255, NOOP) end)
        try(function() sec:Toggle("mtc_names", "Names", Config.Names, function(v) Config.Names = v end) end)
        try(function() sec:ColorPicker("mtc_name_col", 255, 255, 255, 255, NOOP) end)
        try(function() sec:Toggle("mtc_class", "Vehicle Class", Config.Class, function(v) Config.Class = v end) end)
        try(function() sec:ColorPicker("mtc_class_col", 255, 180, 80, 255, NOOP) end)
        try(function() sec:Toggle("mtc_dist", "Distance", Config.Distance, function(v) Config.Distance = v end) end)
        try(function() sec:ColorPicker("mtc_dist_col", 140, 220, 255, 255, NOOP) end)
        try(function() sec:Toggle("mtc_reload", "Reload Status", Config.ReloadStatus, function(v) Config.ReloadStatus = v end) end)
        try(function() sec:Toggle("mtc_fade", "Distance Fade", Config.Fade, function(v) Config.Fade = v end) end)
        try(function() sec:Toggle("mtc_heli", "Helicopter ESP", Config.Heli, function(v) Config.Heli = v end) end)
        try(function() sec:Toggle("mtc_occ", "Occupied Only", Config.OccupiedOnly, function(v) Config.OccupiedOnly = v end) end)
        try(function() sec:Toggle("mtc_team", "Team Check", Config.TeamCheck, function(v) Config.TeamCheck = v end) end)
        try(function() sec:Toggle("mtc_overlay", "Info Overlay", Config.Overlay, function(v) Config.Overlay = v end) end)
        try(function() sec:SliderInt("mtc_maxdist", "Max Distance", 0, 4000, Config.MaxDist, function(v) Config.MaxDist = v end) end)

        local msec = tab:Section("Tank Module", "Left")
        try(function() msec:Toggle("mod_outline", "Outline", Config.ModOutline, function(v) Config.ModOutline = v end) end)
        try(function() msec:Toggle("mod_filled", "Filled", Config.ModFilled, function(v) Config.ModFilled = v end) end)

        try(function() msec:Toggle("mod_engine", "Engine", Config.ModEngine, function(v) Config.ModEngine = v end) end)
        try(function() msec:ColorPicker("mod_engine_col", 255, 140, 0, MOD_FILL_A, NOOP) end)
        try(function() msec:Toggle("mod_ammo", "Ammo", Config.ModAmmo, function(v) Config.ModAmmo = v end) end)
        try(function() msec:ColorPicker("mod_ammo_col", 255, 40, 40, MOD_FILL_A, NOOP) end)
        try(function() msec:SliderInt("mod_maxdist", "Module Distance", 0, 4000, Config.ModMaxDist, function(v) Config.ModMaxDist = v end) end)

        local xsec = tab:Section("Misc", "Right")
        try(function() xsec:Toggle("misc_grain", "Hide Drone Grain", Config.HideGrain, function(v)
            Config.HideGrain = v
            if v then refreshGrainAddrs(); enforceGrain() else restoreGrain() end
        end) end)
        try(function() xsec:Toggle("misc_drone", "Drone ESP", Config.Drone, function(v) Config.Drone = v end) end)
        try(function() xsec:Toggle("misc_missile", "Missile ESP", Config.Missile, function(v) Config.Missile = v end) end)
        try(function() xsec:Toggle("misc_autoreload", "Auto Fast Reload", Config.AutoReload, function(v) Config.AutoReload = v end) end)
        try(function() xsec:Toggle("misc_modcheck", "Mod Checker", Config.ModChecker, function(v) Config.ModChecker = v end) end)
        try(function() xsec:Toggle("misc_ballistic", "Ballistic Calc", Config.Ballistic, function(v) Config.Ballistic = v end) end)
        try(function() xsec:ColorPicker("misc_ball_col", 120, 255, 180, 255, NOOP) end)
        try(function() xsec:Toggle("misc_autoflare", "Auto Flare", Config.AutoFlare, function(v) Config.AutoFlare = v end) end)

        local ksec = tab:Section("KD Dropper", "Right")
        try(function() ksec:Toggle("kd_drop", "KD Dropper", Config.KDDrop, function(v) Config.KDDrop = v end) end)
    end)
end)
if not uiOk then pcall(notify, "MTC", "UI failed: " .. tostring(uiErr), 8) end

_G.MTC = {
    stop = function()
        running = false
        if Config.HideGrain then pcall(restoreGrain) end
        pcall(function() conn:Disconnect() end)
        for i = 1, POOL do
            local s = slots[i]
            for j = 1, 12 do pcall(function() s.lines[j]:Remove() end) end
            pcall(function() s.name:Remove() end); pcall(function() s.cls:Remove() end); pcall(function() s.dist:Remove() end); pcall(function() s.reload:Remove() end)
            pcall(function() s.marker:Remove() end)
        end
        for i = 1, MODPOOL do
            local ms = modSlots[i]
            for j = 1, 12 do pcall(function() ms.lines[j]:Remove() end); pcall(function() ms.tris[j]:Remove() end) end
        end
        for i = 1, MSLPOOL do
            pcall(function() mslSlots[i].marker:Remove() end); pcall(function() mslSlots[i].tag:Remove() end)
        end
        for i = 1, STAFFPOOL do
            pcall(function() staffSlots[i].marker:Remove() end); pcall(function() staffSlots[i].tag:Remove() end)
            pcall(function() staffLines[i]:Remove() end)
        end
        pcall(function() staffBg:Remove() end); pcall(function() staffTitle:Remove() end); pcall(function() staffPopup:Remove() end)
        pcall(function() ballRay:Remove() end); pcall(function() ballCrossH:Remove() end); pcall(function() ballCrossV:Remove() end); pcall(function() ballBg:Remove() end)
        pcall(function() ballTitle:Remove() end); pcall(function() ballRange:Remove() end)
        for i = 1, 5 do pcall(function() ballLines[i]:Remove() end) end
        pcall(function() ovrBg:Remove() end); pcall(function() ovrTitle:Remove() end)
        for i = 1, 5 do pcall(function() ovrLines[i]:Remove() end) end
        pcall(function() UI.RemoveTab("MTC") end)
    end,
}

pcall(notify, "MTC", "Vehicle ESP + Module ESP loaded", 4)
print("[MTC] loaded, uiOk=", uiOk)

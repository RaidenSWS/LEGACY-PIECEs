local playersService = cloneref(game:GetService("Players"))
local replicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local workspaceService = cloneref(game:GetService("Workspace"))
local tweenService = cloneref(game:GetService("TweenService"))
local runService = cloneref(game:GetService("RunService"))
local httpService = cloneref(game:GetService("HttpService"))
local virtualInputManager = cloneref(game:GetService("VirtualInputManager"))

local localPlayer = playersService.LocalPlayer
local remotesFolder = replicatedStorage:WaitForChild("Remotes")
local functionsFolder = remotesFolder:WaitForChild("Functions")
local eventsFolder = remotesFolder:FindFirstChild("Events")
local inputFunction = functionsFolder:WaitForChild("Input")
local inputEvent = remotesFolder:WaitForChild("Input")
local equipRemote = remotesFolder:FindFirstChild("RE_Equip")
local islandSpotRemote = remotesFolder:FindFirstChild("TeleportToIslandSpot")
local npcsFolder = workspaceService:WaitForChild("NPCs")
local enemiesFolder = workspaceService:WaitForChild("Enemies")
local extraFolder = workspaceService:WaitForChild("Extra")
local whaleFolder = workspaceService:FindFirstChild("Whale")
local configurationsFolder = replicatedStorage:WaitForChild("Modules"):WaitForChild("Configurations")
local questData = require(configurationsFolder:WaitForChild("QuestData"))
local prestigeData = require(configurationsFolder:WaitForChild("PrestigeData"))
local itemData = require(configurationsFolder:WaitForChild("ItemData"))
local toolData = require(configurationsFolder:WaitForChild("ToolData"))
local dialogueData = require(configurationsFolder:WaitForChild("DialogueData"))
local npcData = require(configurationsFolder:WaitForChild("NPCData"))
local grindDropSystem = require(configurationsFolder:WaitForChild("GrindDropSystem"))
local summonBossData = require(configurationsFolder:WaitForChild("SummonBossData"))
local summonDifficultyData = require(configurationsFolder:WaitForChild("SummonDifficultyData"))
local materialShopData = require(configurationsFolder:WaitForChild("MaterialShopData"))
local islandsConfig = require(configurationsFolder:WaitForChild("IslandsConfig"))

local macLibSource = ""
pcall(function()
    macLibSource = game:HttpGet("https://raw.githubusercontent.com/biggaboy212/Public-Resources/main/MacLib/maclib.lua")
end)
if #macLibSource == 0 then
    pcall(function()
        macLibSource = game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt")
    end)
end
local MacLib = loadstring(macLibSource)()

local State = {
    FarmLevelEnabled = false,
    FarmQuestEnabled = false,
    PrestigeEnabled = false,
    AutoCodeEnabled = false,
    UnlockEnabled = false,
    AutoPickupEnabled = false,
    BossFarmEnabled = false,
    AutoSummonBoss = false,
    PrestigeBossAutoTarget = false,
    AutoStatEnabled = false,
    StatusRefreshEnabled = false,
    SelectedQuest = nil,
    FarmCombatType = "Ability",
    FarmCombatTypes = { Sword = true, Ability = true },
    FarmSkills = { Z = true, X = true, C = true, V = false, F = false, B = false },
    AutoUseSkills = true,
    MultiCastSkills = false,
    FarmDistance = 25,
    FarmPosition = "Below",
    TweenSpeed = 60,
    SafeTravel = false,
    AbilityFlight = true,
    PullBackPause = false,
    MaxHopDistance = 180,
    PickupRange = 1200,
    StatPriority = { "Weapon", "Ability", "Strength", "Defense" },
    BossDifficulty = "Normal",
    BossSelection = {},
    BossStatus = "Idle",
    UnlockCategory = "Style",
    UnlockStatus = "Idle",
    PrestigeStatus = "Idle",
    PrestigeMissing = "-",
    TravelStatus = "Idle",
    StatStatus = "Idle",
    RemoteStatus = "Idle",
    CombatStatus = "Idle",
    AutoChestEnabled = false,
    ChestSelection = {},
    ChestStatus = "Idle",
    AutoBuyBossTicket = false,
    PickupTargets = {},
    DungeonAutoDifficulty = false,
    DungeonDifficulty = "Hard",
    DungeonAutoReplay = false,
    AutoWhaleEnabled = false,
    AutoFishEnabled = false,
    FishStatus = "Idle",
    AutoDeepsharkEnabled = false,
    AutoArayaEnabled = false,
    AutoTwohEnabled = false,
    AutoYhwachEnabled = false,
    AutoDungeonEnabled = false,
    AutoDungeonTarget = "Realm Beyond Heaven (TWOH)",
    AutoBankaiEnabled = false,
    AutoSolemnEnabled = false,
    AutoTraitEnabled = false,
    TraitTargets = {},
    AutoCoffinEnabled = false,
    AutoAmbushEnabled = false,
    AutoAmbushOnlyEnabled = false,
    AutoFireForceTrialEnabled = false,
    MobFarmEnabled = false,
    MobFarmSelection = {},
    MobFarmStatus = "Idle",
    ExtraStatus = "Idle",
    QuincyBanked = nil,
    QuincyBlockedAt = nil,
    UnlockTargets = {
        Style = nil,
        Weapon = nil,
        Ability = nil
    }
}

getgenv().HubState = State
getgenv().HubSessionToken = {}

if getgenv().HubCleanup then
    pcall(getgenv().HubCleanup)
end

if getgenv().HubNotifyConnection then
    pcall(function()
        getgenv().HubNotifyConnection:Disconnect()
    end)
    getgenv().HubNotifyConnection = nil
end

if getgenv().HubPrestigeConnections then
    for _, connection in ipairs(getgenv().HubPrestigeConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
end
getgenv().HubPrestigeConnections = {}

pcall(function()
    sethiddenproperty(workspaceService, "StreamingMinRadius", 1024)
    sethiddenproperty(workspaceService, "StreamingTargetRadius", 2048)
end)

State.LastNotifyText = ""
State.LastNotifyTime = 0
State.SkillCooldowns = {}
State.SkillCasting = {}

pcall(function()
    local outputRemote = remotesFolder:FindFirstChild("Output")
    if outputRemote and outputRemote:IsA("RemoteEvent") then
        getgenv().HubNotifyConnection = outputRemote.OnClientEvent:Connect(function(kind, ...)
            if kind == "Cooldown" then
                local toolName, duration, skillKey, startTime = ...
                if typeof(toolName) == "string" and typeof(skillKey) == "string" and tonumber(duration) then
                    State.SkillCooldowns[toolName .. "|" .. skillKey] = (tonumber(startTime) or workspaceService:GetServerTimeNow()) + tonumber(duration)
                    State.SkillCasting[skillKey] = nil
                end
                return
            end
            if kind == "Function" then
                local owner, _, info, skillKey, phase, duration = ...
                if skillKey == "F" and typeof(owner) == "Instance" and owner.Name == localPlayer.Name and typeof(info) == "table" and tostring(info.Module) == "The World" then
                    if phase == "Stop" then
                        State.TwohZaWarudoUntil = os.clock() + (tonumber(duration) or 9)
                    elseif phase == "Resume" then
                        State.TwohZaWarudoUntil = nil
                    end
                end
                if (owner == localPlayer or owner == localPlayer.Character) and typeof(skillKey) == "string" and #skillKey <= 2 and phase == nil then
                    State.SkillCasting[skillKey] = os.clock()
                    State.LastSkillStart = os.clock()
                end
                return
            end
            if kind ~= "Notify" then
                return
            end
            local parts = {}
            for _, value in ipairs({ ... }) do
                if typeof(value) == "string" then
                    table.insert(parts, value)
                end
            end
            local joined = table.concat(parts, " | ")
            if joined ~= "" then
                State.LastNotifyText = string.gsub(joined, "<[^<>]->", "")
                State.LastNotifyTime = os.clock()
                if parts[1] == "Obtain" and parts[2] then
                    State.LastObtain = parts[2]
                    State.LastObtainTime = os.clock()
                    local runDrops = State.TwohRunDrops
                    if runDrops and runDrops.Watch[parts[2]] then
                        local amount = tonumber((select(3, ...))) or 1
                        runDrops.Items[parts[2]] = (runDrops.Items[parts[2]] or 0) + amount
                    end
                end
                if parts[1] == "WorldBoss" and parts[2] then
                    State.LastWorldBoss = {
                        Name = (string.gsub(parts[2], "<[^<>]->", "")),
                        Island = parts[3] and (string.gsub(parts[3], "<[^<>]->", "")) or nil,
                        Time = os.clock()
                    }
                end
                local banked = string.match(State.LastNotifyText, "Quincy Soldiers banked:%s*(%d+)")
                if banked then
                    State.QuincyBanked = tonumber(banked)
                    State.QuincyBankedAt = os.clock()
                end
                if string.find(State.LastNotifyText, "Only a Quincy", 1, true) then
                    State.QuincyBlockedAt = os.clock()
                end
                if string.find(State.LastNotifyText, "maximum number of bosses", 1, true) then
                    State.BossCapAt = os.clock()
                end
            end
        end)
    end
end)

local UnlockFarm = {}
local BossFarm = {}
local Prestige = {}
local AutoPickup = {}
local AutoCode = {}
local AutoChest = {}
local FarmLevel = {}
local FarmQuest = {}
local UIController = {}
local Extras = {}

local Combat = {
    PendingUntil = {},
    SpecialKeys = {},
    MoveParams = setmetatable({}, { __mode = "k" }),
    KeyCache = setmetatable({}, { __mode = "k" }),
    NextCastAt = 0,
    NextAttackAt = 0,
    NextEquipAt = 0,
    AimRoot = nil,
    AimUntil = 0,
    AimOverride = nil,
    HoverOverride = nil,
    HoverCastRange = nil,
    OverrideUntil = 0,
    AimCalls = 0,
    ActingSince = nil,
    QueuedWhileActing = false,
    SnapDistance = 25,
    SkillRange = 80,
    MeleeRange = 40,
    CastingGrace = 0.6,
    PendingSeconds = 0.5,
    TypeOrder = { "Sword", "Ability", "Style" },
    Rotation = { SwitchedAt = 0 },
    MinDwell = 0.6,
    AimOffset = 18,
    AwakenAttempts = 0,
    AwakenBackoffUntil = 0,
    SkillRules = {
        Ichigo = { F = "awakened" },
        Tatsumaki = { F = "never" },
        ["Solemn Lament"] = { F = "reload" }
    },
    AmmoRules = {
        ["Solemn Lament"] = { Attributes = { "SolemnLamentLivingAmmo", "SolemnLamentDepartedAmmo" }, ReloadAt = 2, FormAttribute = "SolemnLamentForm" }
    },
    AwakenSkills = {
        Ichigo = { Key = "B", Unlocked = "IchigoBankaiUnlocked", Active = "IchigoBankai", ReadyAt = "IchigoBankaiReadyAt", MaxCooldown = 300 }
    },
    LockedMobName = nil,
    LockedAllowBoss = false
}
local lockedEnemyRoot = nil
local lockedTargetCFrame = nil
local lastKnownMobCFrame = nil
local pickupActive = false
local prestigeActive = false
local travelActive = false
local debugActive = false
local bossPriority = false
local movementOwner = nil
local movementOwnerSince = 0
local bossEventConnections = {}
local lastBossAlert = nil
local npcCooldownUntil = {}
local mobAnchorCache = {}

local statNames = { "Strength", "Defense", "Weapon", "Ability" }
local StatMeta = {
    FallbackCap = 7000,
    Display = { Strength = "Style", Defense = "Defense", Weapon = "Weapon", Ability = "Ability" },
    Options = {},
    FromDisplay = {},
    Allocating = false,
    PrestigeData = nil
}
local statLookup = {}
for _, statName in ipairs(statNames) do
    table.insert(StatMeta.Options, StatMeta.Display[statName])
    StatMeta.FromDisplay[StatMeta.Display[statName]] = statName
    statLookup[statName] = true
end

local islandConfigMap = {
    ["Ubuyashiki Mansion"] = "Slayer Mansion",
    ["Hueco Mundo"] = "Hollow Land"
}

local combatTypeToItemType = {
    Sword = "Weapon",
    Ability = "Ability",
    Style = "Style"
}

local skillKeyOrder = { "Z", "X", "C", "V", "F", "B" }
local prestigeIslandName = "Legacy Island"
local prestigeNPCName = "Prestige Overseer"
local pickupFolderNames = { "Effects", "Items", "Chests", "HollowEchoFragments" }
local confirmButtonTexts = { "yes!", "yes", "confirm", "accept", "obtain", "ok", "prestige" }
local continueButtonTexts = { "next", "continue", "skip", ">" }
local positiveChoiceWords = { "yes!", "yes", "accept", "buy", "claim", "learn", "obtain", "inherit", "begin", "ascend", "evolve", "assemble", "summon boss", "touch", "face", "return", "tell me", "awaken", "inscribe", "continue", "teach me", "teach", "train me", "train" }
local negativeChoiceWords = { "no.", "no", "decline", "leave", "cancel", "not now", "goodbye", "nevermind", "back", "close", "maybe later" }

local timedBossNames = { "Yhwach", "Ancient Deepshark", "World Whale Event" }
local fieldBossNames = { "The Dihui Star, Araya", "Rien", "Dio Heaven Ascension" }
BossFarm.Quincy = {
    SoldierName = "Quincy Soldier",
    KillsPerSummon = 50,
    KillRange = 150,
    Kills = 0,
    KillsTarget = 0,
    Tracked = {},
    NextScanAt = 0,
    StatusBoss = nil
}

local bossCatalogGroups = {
    { Label = "Summon", Names = { "One-Eyed Owl", "Cid Kagenou", "The Red Mist", "Demon Infernal", "Dio" } },
    { Label = "Whisperer", Names = { "Sosuke Aizen", "Ichigo Kurosaki", "Ichigo Kurosaki Bankai", "Satoru Gojo", "Ryomen Sukuna", "Garou", "Blast", "Flashy Flash", "Ken Kaneki", "Akaza", "Chihora", "Solemn Lament", "Ichigo True Bankai", "Chad", "Undyne", "Fishman Captain" } },
    { Label = "Quincy", Names = { "As Nodt", "Askin Nakk Le Vaar", "Bambietta Basterbine", "Gremmy Thoumeaux", "Jugram Haschwalth" } },
    { Label = "World/Raid", Names = { "Yhwach (Global Boss)" } }
}

local prestigeKillBossMap = {
    CidKills = "Cid Kagenou",
    OwlKills = "One-Eyed Owl",
    RedMistKills = "The Red Mist",
    DemonInfernalKills = "Demon Infernal",
    DioKills = "Dio",
    DioHeavenAscensionKills = "Dio Heaven Ascension",
    RienKills = "Rien",
    YhwachKills = "Yhwach",
    ArayaKills = "The Dihui Star, Araya",
    AncientDeepsharkKills = "Ancient Deepshark",
    InfernalAmbusherKills = "Infernal Ambusher",
    SpecialKills = "One-Eyed Owl",
    BossKills = "Sosuke Aizen"
}

local knownBossNames = {
    ["Yhwach"] = true,
    ["Yhwach Not Dungeon"] = true,
    ["Yhwach (Global Boss)"] = true,
    ["Yhwach (Summoned)"] = true,
    ["The Dihui Star, Araya"] = true,
    ["Rien"] = true,
    ["Dio Heaven Ascension"] = true,
    ["Ancient Deepshark"] = true,
    ["World Whale Event"] = true
}
for _, group in ipairs(bossCatalogGroups) do
    for _, bossName in ipairs(group.Names) do
        knownBossNames[bossName] = true
    end
end

local function isFarmActive()
    return State.FarmLevelEnabled or State.FarmQuestEnabled or State.UnlockEnabled or State.BossFarmEnabled or (State.PrestigeEnabled and not Prestige.Idle) or pickupActive or prestigeActive or debugActive or (State.AutoWhaleEnabled and Extras.WhaleActive == true) or State.AutoCoffinEnabled or State.AutoAmbushEnabled or State.AutoAmbushOnlyEnabled or State.AutoFireForceTrialEnabled or State.MobFarmEnabled or (State.AutoDeepsharkEnabled and movementOwner == "deepshark") or State.AutoArayaEnabled or State.AutoTwohEnabled or State.AutoDungeonEnabled or State.AutoBankaiEnabled or State.AutoSolemnEnabled or State.AutoYhwachEnabled or (State.AutoFishEnabled and movementOwner == "fishing")
end

function Extras.otherFarmActive()
    return State.FarmLevelEnabled or State.FarmQuestEnabled or State.UnlockEnabled or State.BossFarmEnabled or (State.PrestigeEnabled and not Prestige.Idle) or State.AutoCoffinEnabled or State.AutoAmbushEnabled or State.AutoAmbushOnlyEnabled or State.AutoFireForceTrialEnabled or State.MobFarmEnabled or State.AutoArayaEnabled or (State.AutoTwohEnabled and not (Extras.Twoh and Extras.Twoh.Idle)) or State.AutoDungeonEnabled or State.AutoBankaiEnabled or State.AutoSolemnEnabled or (State.AutoYhwachEnabled and not (Extras.Yhwach and Extras.Yhwach.Idle)) or false
end

local movementOwnerActiveCheck = {
    level = function()
        return State.FarmLevelEnabled
    end,
    quest = function()
        return State.FarmQuestEnabled
    end,
    unlock = function()
        return State.UnlockEnabled
    end,
    boss = function()
        return State.BossFarmEnabled
    end,
    prestige = function()
        return State.PrestigeEnabled
    end,
    pickup = function()
        return pickupActive or State.AutoPickupEnabled
    end,
    pickupevent = function()
        return State.AutoPickupEnabled
    end,
    fishing = function()
        return State.AutoFishEnabled
    end,
    whale = function()
        return State.AutoWhaleEnabled
    end,
    coffin = function()
        return State.AutoCoffinEnabled
    end,
    ambush = function()
        return State.AutoAmbushEnabled
    end,
    ambushonly = function()
        return State.AutoAmbushOnlyEnabled
    end,
    dungeon = function()
        return State.AutoDungeonEnabled
    end,
    deepshark = function()
        return State.AutoDeepsharkEnabled
    end,
    araya = function()
        return State.AutoArayaEnabled
    end,
    twoh = function()
        return State.AutoTwohEnabled or (Extras.Twoh ~= nil and Extras.Twoh.isActive())
    end,
    yhwach = function()
        return State.AutoYhwachEnabled
    end,
    bankai = function()
        return State.AutoBankaiEnabled
    end,
    solemn = function()
        return State.AutoSolemnEnabled
    end,
    fireforce = function()
        return State.AutoFireForceTrialEnabled
    end,
    mob = function()
        return State.MobFarmEnabled
    end
}

local function acquireMovement(ownerName)
    if movementOwner ~= nil and movementOwner ~= ownerName then
        local checker = movementOwnerActiveCheck[movementOwner]
        if (checker and not checker()) or (os.clock() - movementOwnerSince) > 240 then
            movementOwner = nil
        end
    end

    local eventPriority = Extras.PriorityRequest
    if eventPriority == "twoh" and not (State.AutoTwohEnabled or (Extras.Twoh ~= nil and Extras.Twoh.isActive())) then
        Extras.PriorityRequest = nil
        eventPriority = nil
    end
    if eventPriority == "yhwach" and not State.AutoYhwachEnabled then
        Extras.PriorityRequest = nil
        eventPriority = nil
    end
    if eventPriority and ownerName ~= eventPriority then
        return false
    end

    if not eventPriority and bossPriority and ownerName ~= "boss" then
        return false
    end

    if not eventPriority and Prestige.priorityRequest and State.PrestigeEnabled and ownerName ~= "prestige" and ownerName ~= "pickup" then
        return false
    end

    if State.AutoDeepsharkEnabled and Extras.DeepsharkRequesters and Extras.DeepsharkRequesters.prestige
        and (ownerName == "level" or ownerName == "quest" or ownerName == "mob") then
        return false
    end

    if movementOwner ~= nil and movementOwner ~= ownerName then
        return false
    end

    movementOwner = ownerName
    movementOwnerSince = os.clock()
    return true
end

local function releaseMovement(ownerName)
    if movementOwner == ownerName then
        movementOwner = nil
    end
end

local function reacquireMovement(ownerName)
    local waited = 0
    while not acquireMovement(ownerName) and waited < 150 do
        task.wait(0.1)
        waited = waited + 1
    end
    return movementOwner == ownerName
end

local function setFarmStatus(message)
    if movementOwner == "prestige" then
        State.PrestigeStatus = message
    elseif movementOwner == "boss" then
        State.BossStatus = message
    elseif movementOwner == "unlock" then
        State.UnlockStatus = message
    elseif movementOwner == "mob" then
        State.MobFarmStatus = message
    elseif movementOwner == "bankai" then
        State.ExtraStatus = "Ichigo Bankai: " .. tostring(message)
    elseif movementOwner == "solemn" then
        State.ExtraStatus = "Solemn Lament: " .. tostring(message)
    elseif movementOwner == "twoh" then
        Extras.Twoh.status(message)
    elseif movementOwner == "yhwach" then
        Extras.Yhwach.FarmNote = tostring(message)
    elseif movementOwner == "whale" or movementOwner == "coffin" or movementOwner == "ambush" or movementOwner == "ambushonly" or movementOwner == "deepshark" or movementOwner == "araya" or movementOwner == "fireforce" then
        State.ExtraStatus = message
    elseif State.BossFarmEnabled then
        State.BossStatus = message
    elseif State.PrestigeEnabled then
        State.PrestigeStatus = message
    else
        State.UnlockStatus = message
    end
end

local function invokeInput(...)
    local args = table.pack(...)
    local finished = false
    local returnedValue = nil

    task.spawn(function()
        local ok, result = pcall(function()
            return inputFunction:InvokeServer(table.unpack(args, 1, args.n))
        end)
        if ok then
            returnedValue = result
        end
        finished = true
    end)

    local waited = 0
    while not finished and waited < 6 do
        task.wait(0.1)
        waited = waited + 0.1
    end

    if finished then
        State.RemoteStatus = "Input remote ok"
    else
        State.RemoteStatus = "Input remote timeout"
    end

    return finished, returnedValue
end

local function normalizeName(name)
    if not name then
        return ""
    end
    local lower = string.lower(tostring(name))
    return string.gsub(lower, "[%s%p%c]", "")
end

local function stripBossTag(name)
    local stripped = string.gsub(tostring(name), "%s*%[.-%]%s*", "")
    stripped = string.gsub(stripped, "^%s+", "")
    stripped = string.gsub(stripped, "%s+$", "")
    return stripped
end

local function stripRichText(text)
    local cleaned = string.gsub(tostring(text), "<[^<>]->", "")
    cleaned = string.gsub(cleaned, "^%s+", "")
    cleaned = string.gsub(cleaned, "%s+$", "")
    return cleaned
end

local function isKnownBossName(mobName)
    if not mobName then
        return false
    end
    if knownBossNames[mobName] then
        return true
    end
    local normalizedMob = normalizeName(stripBossTag(mobName))
    for bossName in pairs(knownBossNames) do
        local normalizedBoss = normalizeName(bossName)
        if normalizedMob == normalizedBoss or string.find(normalizedMob, normalizedBoss, 1, true) == 1 then
            return true
        end
    end
    return false
end

local function setNPCCooldown(npcName, seconds)
    if npcName then
        npcCooldownUntil[npcName] = os.clock() + (seconds or 20)
    end
end

local function getNPCCooldown(npcName)
    if not npcName then
        return 0
    end
    local remaining = (npcCooldownUntil[npcName] or 0) - os.clock()
    if remaining < 0 then
        return 0
    end
    return remaining
end

local summonCatalog = {}
local summonNpcByBoss = {}
local summonEntryByName = {}
local bossSummonCooldown = {}

local function buildSummonCatalog()
    for npcName, bossList in pairs(summonBossData.npcBosses or {}) do
        for _, bossName in ipairs(bossList) do
            summonNpcByBoss[bossName] = npcName
        end
    end

    for _, entry in ipairs(summonBossData.list or {}) do
        local npcName = summonNpcByBoss[entry.Name]
        local group = "Summon"
        if npcName == "Sacrifice Table" then
            group = "Summon"
        elseif entry.TicketItem == "Reishi Fragment" then
            group = "Quincy"
        elseif npcName then
            group = "Whisperer"
        end

        local item = {
            Name = entry.Name,
            NPC = npcName,
            Group = group,
            Entry = entry
        }

        table.insert(summonCatalog, item)
        summonEntryByName[normalizeName(entry.Name)] = item
    end
end

buildSummonCatalog()

local materialSources = {}
local materialShopIndex = {}
local questAnchorByMob = {}
local unlockRecipes = {}

local function buildMaterialSources()
    for npcName, info in pairs(npcData) do
        if typeof(info) == "table" and typeof(info.Drops) == "table" then
            local cleanName = stripBossTag(npcName)
            for materialName, dropInfo in pairs(info.Drops) do
                local chance = 0
                if typeof(dropInfo) == "table" then
                    chance = tonumber(dropInfo.Chance) or 0
                end

                materialSources[materialName] = materialSources[materialName] or {}
                table.insert(materialSources[materialName], {
                    Name = cleanName,
                    RawName = npcName,
                    Level = tonumber(info.Level) or 0,
                    Chance = chance,
                    Summon = summonEntryByName[normalizeName(cleanName)]
                })
            end
        end
    end

    for _, entry in ipairs(summonBossData.list or {}) do
        local cleanName = entry.Name
        local bossInfo = npcData[cleanName] or npcData[cleanName .. " [Boss]"]
        local drops = (bossInfo and typeof(bossInfo) == "table" and typeof(bossInfo.Drops) == "table" and bossInfo.Drops) or (typeof(entry.Drops) == "table" and entry.Drops)
        local summonItem = summonEntryByName[normalizeName(cleanName)]
        if drops then
            for materialName, dropInfo in pairs(drops) do
                local chance = 0
                if typeof(dropInfo) == "table" then
                    chance = tonumber(dropInfo.Chance) or 0
                end
                materialSources[materialName] = materialSources[materialName] or {}
                local alreadyPresent = false
                for _, s in ipairs(materialSources[materialName]) do
                    if s.Name == cleanName then
                        s.Summon = s.Summon or summonItem
                        s.IsBoss = true
                        alreadyPresent = true
                        break
                    end
                end
                if not alreadyPresent then
                    table.insert(materialSources[materialName], {
                        Name = cleanName,
                        RawName = cleanName,
                        Level = (bossInfo and tonumber(bossInfo.Level)) or 5000,
                        Chance = chance,
                        Summon = summonItem,
                        IsBoss = true
                    })
                end
            end
        end
    end

    if grindDropSystem and grindDropSystem.GetDrops then
        for tier = 1, (grindDropSystem.TIER_MAX or 10) do
            local drops = nil
            pcall(function()
                drops = grindDropSystem.GetDrops(tier)
            end)
            if typeof(drops) == "table" then
                for materialName in pairs(drops) do
                    materialSources[materialName] = materialSources[materialName] or {}
                end
            end
            local bossDrops = nil
            pcall(function()
                bossDrops = grindDropSystem.GetBossDrops(tier)
            end)
            if typeof(bossDrops) == "table" then
                for materialName in pairs(bossDrops) do
                    materialSources[materialName] = materialSources[materialName] or {}
                end
            end
        end
    end

    for _, sourceList in pairs(materialSources) do
        table.sort(sourceList, function(a, b)
            if a.Level == b.Level then
                return (a.Chance or 0) > (b.Chance or 0)
            end
            return a.Level < b.Level
        end)
    end
end

local function buildMaterialShopIndex()
    for index, entry in ipairs(materialShopData) do
        if typeof(entry) == "table" and typeof(entry.Name) == "string" then
            materialShopIndex[entry.Name] = {
                Index = index,
                Cost = tonumber(entry.Cost) or 0,
                Currency = entry.Currency or "Shards"
            }
        end
    end
end

local function buildQuestAnchors()
    for questName, questInfo in pairs(questData.Main) do
        local isGrind = string.find(questName, "^Quest%s") ~= nil and typeof(questInfo.LevelRanging) == "table"
        local goalTarget = questInfo.Goal and questInfo.Goal.Target
        local targets = {}

        if typeof(goalTarget) == "string" then
            table.insert(targets, goalTarget)
        elseif typeof(goalTarget) == "table" then
            for _, value in pairs(goalTarget) do
                if typeof(value) == "string" then
                    table.insert(targets, value)
                end
            end
        end

        for _, target in ipairs(targets) do
            local key = normalizeName(stripBossTag(target))
            if key ~= "" then
                local currentQuest = questAnchorByMob[key]
                local currentIsGrind = currentQuest and (string.find(currentQuest, "^Quest%s") ~= nil and typeof(questData.Main[currentQuest]) == "table" and typeof(questData.Main[currentQuest].LevelRanging) == "table")
                if not currentQuest or (isGrind and not currentIsGrind) then
                    questAnchorByMob[key] = questName
                end
            end
        end
    end
end

local function buildUnlockRecipes()
    for npcName, entry in pairs(dialogueData) do
        if typeof(entry) == "table" and typeof(entry.Choice) == "table" then
            for _, page in pairs(entry.Choice) do
                if typeof(page) == "table" then
                    for _, choice in pairs(page) do
                        if typeof(choice) == "table" and typeof(choice[3]) == "table" and typeof(choice[3].Buy) == "string" then
                            local buyItem = choice[3].Buy
                            local requirement = {}

                            if typeof(entry.Requirement) == "table" then
                                for materialName, amount in pairs(entry.Requirement) do
                                    if typeof(materialName) == "string" and tonumber(amount) then
                                        requirement[materialName] = tonumber(amount)
                                    end
                                end
                            end

                            if typeof(choice[3].Requirement) == "table" then
                                for _, pair in pairs(choice[3].Requirement) do
                                    if typeof(pair) == "table" and typeof(pair[1]) == "string" and tonumber(pair[2]) then
                                        requirement[pair[1]] = tonumber(pair[2])
                                    end
                                end
                            end

                            unlockRecipes[buyItem] = {
                                NPC = npcName,
                                Requirement = requirement,
                                ChoiceText = stripRichText(choice[1]),
                                Gate = (typeof(entry.Gate) == "table" and entry.Gate) or nil
                            }
                        end
                    end
                end
            end
        end
    end
end

buildMaterialSources()
buildMaterialShopIndex()
buildQuestAnchors()
buildUnlockRecipes()

if unlockRecipes["The World"] and unlockRecipes["Blood-Stained Stand Arrow"] then
    unlockRecipes["The World"].Requirement = { ["Blood-Stained Stand Arrow"] = 1 }
    unlockRecipes["The World"].FightBoss = "Shadow Dio"
    unlockRecipes["Blood-Stained Stand Arrow"].Money = 25000000
end

if unlockRecipes["Tatsumaki"] then
    unlockRecipes["Tatsumaki"].Money = 500000
    unlockRecipes["Tatsumaki"].NPC = "Tatsumaki"
    unlockRecipes["Tatsumaki"].Island = "Legacy Island"
end
if unlockRecipes["Storm Esper"] then
    unlockRecipes["Storm Esper"].Money = 500000
    unlockRecipes["Storm Esper"].NPC = "Tatsumaki"
    unlockRecipes["Storm Esper"].Island = "Legacy Island"
end
materialSources["Meteor Fragment"] = {
    { Name = "Meteor Shower", Event = true, Island = "Legacy Island" }
}

local islandSpotByNpc = {}
local islandSpotList = {}

local function buildIslandSpots()
    for islandName, info in pairs(islandsConfig) do
        if typeof(info) == "table" and typeof(info.Npcs) == "table" then
            islandSpotList[islandName] = {}
            for npcKey, npcInfo in pairs(info.Npcs) do
                local targetName = (typeof(npcInfo) == "table" and npcInfo.Target) or npcKey
                local spot = { Island = islandName, Target = targetName }
                table.insert(islandSpotList[islandName], spot)
                islandSpotByNpc[normalizeName(targetName)] = spot
                islandSpotByNpc[normalizeName(npcKey)] = islandSpotByNpc[normalizeName(npcKey)] or spot
            end
        end
    end
end

buildIslandSpots()

function Extras.aboveWater(targetCFrame)
    if not targetCFrame then
        return targetCFrame
    end
    if workspaceService:GetAttribute("Dungeon") ~= nil then
        local floorY = Extras.DungeonFloorLevel
        if not floorY then
            return targetCFrame
        end
        Extras.DungeonCeiling = floorY + 120
        local clampedY = math.clamp(targetCFrame.Position.Y, floorY + 3.5, Extras.DungeonCeiling)
        if clampedY == targetCFrame.Position.Y then
            return targetCFrame
        end
        return CFrame.new(targetCFrame.Position.X, clampedY, targetCFrame.Position.Z) * targetCFrame.Rotation
    end
    if targetCFrame.Position.Y >= 3.5 then
        return targetCFrame
    end
    return CFrame.new(targetCFrame.Position.X, 3.5, targetCFrame.Position.Z) * targetCFrame.Rotation
end

Extras.FloorCache = setmetatable({}, { __mode = "k" })

function Extras.getDungeonFloorY(enemyRoot)
    if workspaceService:GetAttribute("Dungeon") == nil then
        return nil
    end
    local cached = Extras.FloorCache[enemyRoot]
    if cached and os.clock() - cached.At < 2 then
        return cached.Y
    end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { localPlayer.Character, enemiesFolder, npcsFolder, extraFolder }
    raycastParams.IgnoreWater = true
    local hit = workspaceService:Raycast(enemyRoot.Position + Vector3.new(0, 2, 0), Vector3.new(0, -200, 0), raycastParams)
    local floorY = hit and hit.Normal.Y > 0.6 and hit.Position.Y or nil
    Extras.FloorCache[enemyRoot] = { Y = floorY, At = os.clock() }
    if floorY then
        Extras.DungeonFloorLevel = floorY
    end
    return floorY
end

local function getFarmCFrame(enemyRoot)
    local farmDistance = math.clamp(State.FarmDistanceOverride or State.FarmDistance or 7.5, 3, 60)
    local farmPosition = State.FarmPosition or "Above"
    Extras.getDungeonFloorY(enemyRoot)

    if farmPosition == "Behind" then
        local targetPosition = (enemyRoot.CFrame * CFrame.new(0, 1.5, farmDistance)).Position
        return Extras.aboveWater(CFrame.lookAt(targetPosition, enemyRoot.Position))
    end

    if farmPosition == "Below" then
        local floorY = Extras.getDungeonFloorY(enemyRoot)
        if floorY and enemyRoot.Position.Y - farmDistance < floorY + 3.5 then
            local behind = enemyRoot.CFrame.LookVector * -math.min(farmDistance, 15)
            local standPosition = Vector3.new(enemyRoot.Position.X + behind.X, floorY + 3.5, enemyRoot.Position.Z + behind.Z)
            return CFrame.lookAt(standPosition, Vector3.new(enemyRoot.Position.X, standPosition.Y, enemyRoot.Position.Z))
        end
        return Extras.aboveWater(CFrame.new(enemyRoot.Position - Vector3.new(0, farmDistance, 0)) * CFrame.Angles(math.rad(90), 0, 0))
    end

    return Extras.aboveWater(CFrame.new(enemyRoot.Position + Vector3.new(0, farmDistance, 0)) * CFrame.Angles(math.rad(-90), 0, 0))
end

local targetBox = Instance.new("SelectionBox")
targetBox.Color3 = Color3.fromRGB(0, 255, 120)
targetBox.LineThickness = 0.06
targetBox.SurfaceTransparency = 0.7
targetBox.SurfaceColor3 = Color3.fromRGB(0, 255, 120)
targetBox.Parent = workspaceService

local function setTargetBox(adornee)
    if targetBox then
        pcall(function()
            targetBox.Adornee = adornee
        end)
    end
end

local lastNoClipCheck = 0
local noClipConnection = runService.Stepped:Connect(function()
    local now = os.clock()
    if now - lastNoClipCheck < 0.1 then
        return
    end
    lastNoClipCheck = now
    local playerCharacter = localPlayer.Character
    if playerCharacter and isFarmActive() and not Extras.Walking then
        for _, part in ipairs(playerCharacter:GetChildren()) do
            if part:IsA("BasePart") and part.CanCollide == true then
                part.CanCollide = false
            end
        end
    end
end)

local function getRoot()
    local playerCharacter = localPlayer.Character
    return playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart"), playerCharacter and playerCharacter:FindFirstChildOfClass("Humanoid")
end

local function getOrCreateFloat(rootPart)
    local floatForce = rootPart:FindFirstChild("FarmFloat")
    if not floatForce then
        floatForce = Instance.new("BodyVelocity")
        floatForce.Name = "FarmFloat"
        floatForce.Velocity = Vector3.zero
        floatForce.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        floatForce.Parent = rootPart
    end
    return floatForce
end

local function removeFloat(rootPart)
    if rootPart then
        local floatForce = rootPart:FindFirstChild("FarmFloat")
        if floatForce then
            floatForce:Destroy()
        end
    end
end

function Extras.leaveWater()
    local rootPart = getRoot()
    if not rootPart or workspaceService:GetAttribute("Dungeon") ~= nil then
        return true
    end
    if not rootPart:FindFirstChild("Swim") and rootPart.Position.Y > 2 then
        return true
    end
    for _ = 1, 6 do
        rootPart = getRoot()
        if not rootPart then
            return false
        end
        rootPart.CFrame = CFrame.new(rootPart.Position.X, 6, rootPart.Position.Z) * rootPart.CFrame.Rotation
        rootPart.AssemblyLinearVelocity = Vector3.zero
        getOrCreateFloat(rootPart)
        local deadline = os.clock() + 0.35
        while os.clock() < deadline do
            task.wait()
            if not rootPart:FindFirstChild("Swim") and rootPart.Position.Y > 2 then
                return true
            end
        end
    end
    return false
end

local currentTween = nil
local function stopTween()
    if currentTween then
        pcall(function()
            currentTween:Cancel()
        end)
        currentTween = nil
    end
end

local function buildRaycastParams()
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { localPlayer.Character, enemiesFolder, npcsFolder, extraFolder }
    raycastParams.IgnoreWater = true
    return raycastParams
end

local function hasGroundBelow(rootPart)
    local result = workspaceService:Raycast(rootPart.Position, Vector3.new(0, -14, 0), buildRaycastParams())
    return result ~= nil
end

local function findGroundPosition(position)
    local result = workspaceService:Raycast(position + Vector3.new(0, 24, 0), Vector3.new(0, -90, 0), buildRaycastParams())
    if result then
        return result.Position
    end
    return nil
end

local function isPathBlocked(fromPosition, toPosition)
    local direction = toPosition - fromPosition
    local distance = direction.Magnitude
    if distance < 1 then
        return false
    end

    local result = workspaceService:Raycast(fromPosition, direction.Unit * distance, buildRaycastParams())
    if not result then
        return false
    end

    return (result.Position - fromPosition).Magnitude < (distance - 2)
end

local function settleCharacter()
    stopTween()
    local rootPart, playerHumanoid = getRoot()
    if not rootPart then
        return
    end

    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero

    if hasGroundBelow(rootPart) then
        removeFloat(rootPart)
        if playerHumanoid then
            pcall(function()
                playerHumanoid:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end
    else
        getOrCreateFloat(rootPart)
    end

    task.wait(0.25)
end

local function holdPosition(targetCFrame)
    local rootPart, playerHumanoid = getRoot()
    if not rootPart then
        return
    end

    stopTween()
    getOrCreateFloat(rootPart)
    if playerHumanoid then
        pcall(function()
            playerHumanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end)
    end

    if targetCFrame and (targetCFrame.Position - rootPart.Position).Magnitude <= 30 then
        rootPart.CFrame = targetCFrame
    end
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
end

local function getNPCPrompt(targetNPC)
    if not targetNPC or not targetNPC.Parent then
        return nil, nil
    end

    local prompt = targetNPC:FindFirstChildWhichIsA("ProximityPrompt", true)
    local promptPart = prompt and prompt.Parent
    if promptPart and not promptPart:IsA("BasePart") then
        promptPart = promptPart:FindFirstChildWhichIsA("BasePart") or nil
    end
    return prompt, promptPart
end

local function getNPCAnchorPosition(targetNPC)
    local _, promptPart = getNPCPrompt(targetNPC)
    if promptPart then
        return promptPart.Position
    end

    local pivotOk, pivot = pcall(function()
        return targetNPC:GetPivot()
    end)
    if pivotOk then
        return pivot.Position
    end
    return nil
end

local function computeTalkCFrame(targetNPC)
    local prompt, promptPart = getNPCPrompt(targetNPC)
    local anchorPosition = nil
    local lookVector = Vector3.new(0, 0, 1)

    if promptPart and promptPart:IsA("BasePart") then
        anchorPosition = promptPart.Position
        lookVector = promptPart.CFrame.LookVector
    else
        local pivotOk, pivot = pcall(function()
            return targetNPC:GetPivot()
        end)
        if pivotOk and pivot then
            anchorPosition = pivot.Position
            lookVector = pivot.LookVector
        end
    end

    if not anchorPosition then
        return nil, nil
    end

    local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
    if flatLook.Magnitude > 0.01 then
        flatLook = flatLook.Unit
    else
        flatLook = Vector3.new(0, 0, 1)
    end

    local candidate = anchorPosition + flatLook * 3.2
    local groundPosition = findGroundPosition(candidate)
    local standPosition = groundPosition and (groundPosition + Vector3.new(0, 3.2, 0)) or Vector3.new(candidate.X, anchorPosition.Y, candidate.Z)
    if groundPosition and math.abs(anchorPosition.Y - standPosition.Y) > 5 then
        standPosition = Vector3.new(candidate.X, anchorPosition.Y, candidate.Z)
    end

    if not isPathBlocked(standPosition, anchorPosition) then
        return CFrame.lookAt(standPosition, Vector3.new(anchorPosition.X, standPosition.Y, anchorPosition.Z)), anchorPosition
    end

    for step = 1, 7 do
        local angle = (math.pi * 2 / 8) * step
        local rotatedLook = Vector3.new(
            flatLook.X * math.cos(angle) - flatLook.Z * math.sin(angle),
            0,
            flatLook.X * math.sin(angle) + flatLook.Z * math.cos(angle)
        ).Unit
        local testCand = anchorPosition + rotatedLook * 3.2
        local testGround = findGroundPosition(testCand)
        local testStand = testGround and (testGround + Vector3.new(0, 3.2, 0)) or Vector3.new(testCand.X, anchorPosition.Y, testCand.Z)
        if not isPathBlocked(testStand, anchorPosition) then
            return CFrame.lookAt(testStand, Vector3.new(anchorPosition.X, testStand.Y, anchorPosition.Z)), anchorPosition
        end
    end

    return CFrame.lookAt(standPosition, Vector3.new(anchorPosition.X, standPosition.Y, anchorPosition.Z)), anchorPosition
end

local function triggerPrompt(prompt)
    if not prompt or not prompt.Parent then
        return false
    end
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt, 0)
        end
    end)
    pcall(function()
        prompt:InputHoldBegin()
    end)
    task.wait((prompt.HoldDuration or 0) + 0.08)
    pcall(function()
        prompt:InputHoldEnd()
    end)
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt, 0)
        end
    end)
    return true
end

local function isGuiEffectivelyVisible(guiObject)
    local cursor = guiObject
    while cursor do
        if cursor:IsA("ScreenGui") then
            return cursor.Enabled
        end
        if cursor:IsA("GuiObject") and not cursor.Visible then
            return false
        end
        cursor = cursor.Parent
    end
    return false
end

local function findVisibleButton(matchTexts)
    local playerGui = localPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        return nil
    end

    for _, guiObject in ipairs(playerGui:GetDescendants()) do
        if guiObject:IsA("TextButton") and isGuiEffectivelyVisible(guiObject) then
            local buttonText = string.lower(stripRichText(guiObject.Text))
            for _, needle in ipairs(matchTexts) do
                if buttonText == needle then
                    return guiObject
                end
            end
        end
    end

    return nil
end

local function clickGuiButton(button)
    local firedConnection = false

    pcall(function()
        for _, connection in ipairs(getconnections(button.MouseButton1Click)) do
            connection:Fire()
            firedConnection = true
        end
    end)

    pcall(function()
        for _, connection in ipairs(getconnections(button.Activated)) do
            connection:Fire()
            firedConnection = true
        end
    end)

    if firedConnection then
        return true
    end

    local clicked = pcall(function()
        local center = button.AbsolutePosition + button.AbsoluteSize / 2
        virtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
        task.wait(0.06)
        virtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
    end)

    return clicked
end

local function confirmDialogue(timeoutSeconds)
    local deadline = os.clock() + (timeoutSeconds or 3)

    while os.clock() < deadline do
        local confirmButton = findVisibleButton(confirmButtonTexts)
        if confirmButton then
            clickGuiButton(confirmButton)
            return true
        end

        local continueButton = findVisibleButton(continueButtonTexts)
        if continueButton then
            clickGuiButton(continueButton)
        end

        task.wait(0.2)
    end

    return false
end

local function getDialogueRoot()
    local playerGui = localPlayer:FindFirstChild("PlayerGui")
    local dialogueUI = playerGui and playerGui:FindFirstChild("DialogueUI")
    return dialogueUI and dialogueUI:FindFirstChild("Dialogue")
end

local function isDialogueOpen()
    local dialogueRoot = getDialogueRoot()
    return dialogueRoot ~= nil and dialogueRoot.Visible == true
end

local function isSummonUIOpen()
    local playerGui = localPlayer:FindFirstChild("PlayerGui")
    local summonUI = playerGui and playerGui:FindFirstChild("SummonBossUI")
    return summonUI ~= nil and summonUI.Enabled == true
end

local function closeSummonUI()
    local playerGui = localPlayer:FindFirstChild("PlayerGui")
    local summonUI = playerGui and playerGui:FindFirstChild("SummonBossUI")
    if summonUI then
        pcall(function()
            summonUI.Enabled = false
        end)
    end
end

local function getDialogueChoices()
    local results = {}
    local dialogueRoot = getDialogueRoot()
    if not dialogueRoot then
        return results
    end

    for _, descendant in ipairs(dialogueRoot:GetDescendants()) do
        if descendant:IsA("GuiObject") and descendant:GetAttribute("DialogueChoice") == true then
            local button = descendant:FindFirstChild("Hitbox")
            if not button or not button:IsA("TextButton") then
                button = descendant:FindFirstChildWhichIsA("TextButton", true)
            end

            local choiceText = string.gsub(descendant.Name, "^Choice_", "")
            if choiceText == descendant.Name then
                local label = descendant:FindFirstChildWhichIsA("TextLabel", true)
                choiceText = (label and label.Text) or ""
            end

            if button then
                table.insert(results, { Button = button, Text = stripRichText(choiceText) })
            end
        end
    end

    return results
end

local function matchesAnyWord(text, wordList)
    local loweredText = string.lower(text)
    for _, word in ipairs(wordList) do
        if loweredText == word or string.find(loweredText, word, 1, true) then
            return true
        end
    end
    return false
end

local function pickDialogueChoice(choices, preferredText)
    if preferredText and preferredText ~= "" then
        local normalizedPreferred = normalizeName(preferredText)

        for _, choice in ipairs(choices) do
            if normalizeName(choice.Text) == normalizedPreferred then
                return choice
            end
        end

        if #normalizedPreferred > 3 then
            for _, choice in ipairs(choices) do
                local normalizedChoice = normalizeName(choice.Text)
                if #normalizedChoice > 0 and (string.find(normalizedChoice, normalizedPreferred, 1, true) or string.find(normalizedPreferred, normalizedChoice, 1, true)) then
                    return choice
                end
            end
        end
    end

    for _, choice in ipairs(choices) do
        if not matchesAnyWord(choice.Text, negativeChoiceWords) and matchesAnyWord(choice.Text, positiveChoiceWords) then
            return choice
        end
    end

    return nil
end

local function openNPCDialogue(targetNPC, timeoutSeconds)
    if not targetNPC or not targetNPC.Parent then
        return false
    end

    local deadline = os.clock() + (timeoutSeconds or 6)
    local talkCFrame = computeTalkCFrame(targetNPC)

    while os.clock() < deadline do
        if isDialogueOpen() or isSummonUIOpen() then
            return true
        end

        local prompt = getNPCPrompt(targetNPC)
        if prompt then
            triggerPrompt(prompt)
            task.wait(0.4)
        else
            holdPosition(talkCFrame)
            task.wait(0.3)
        end
    end

    return isDialogueOpen() or isSummonUIOpen()
end

local function autoDialogue(preferredText, stopCondition, timeoutSeconds)
    local deadline = os.clock() + (timeoutSeconds or 8)
    local clickCount = 0

    while os.clock() < deadline do
        if stopCondition and stopCondition() == true then
            return true
        end

        local continueOrConfirm = findVisibleButton(continueButtonTexts) or findVisibleButton(confirmButtonTexts)
        if continueOrConfirm then
            clickGuiButton(continueOrConfirm)
            task.wait(0.4)
        else
            local choices = getDialogueChoices()
            if #choices > 0 then
                local choice = pickDialogueChoice(choices, preferredText)
                if not choice then
                    return stopCondition ~= nil and stopCondition() == true
                end

                clickGuiButton(choice.Button)
                clickCount = clickCount + 1
                task.wait(0.55)

                if clickCount >= 6 then
                    return stopCondition ~= nil and stopCondition() == true
                end
            elseif not isDialogueOpen() then
                if stopCondition then
                    task.wait(0.4)
                    return stopCondition() == true
                end
                return true
            else
                task.wait(0.2)
            end
        end
    end

    return stopCondition ~= nil and stopCondition() == true
end

function Extras.isGameHoldingCharacter(rootPart)
    local character = rootPart and rootPart.Parent
    if not character then
        return false
    end
    if rootPart.Anchored or character:FindFirstChild("MovementDisabled") or character:FindFirstChild("CutsceneShield") then
        return true
    end
    if character:FindFirstChild("Acting") and os.clock() - (Extras.SkillMovedAt or 0) < 4 then
        return true
    end
    for _, child in ipairs(rootPart:GetChildren()) do
        if child:IsA("Weld") and string.find(child.Name, "Grab", 1, true) then
            return true
        end
    end
    return false
end

local lockConnection = runService.Heartbeat:Connect(function(deltaTime)
    if pickupActive or travelActive or not isFarmActive() then
        return
    end

    local rootPart, playerHumanoid = getRoot()
    if not rootPart or not rootPart.Parent or not playerHumanoid or playerHumanoid.Health <= 0 then
        return
    end

    if currentTween then
        return
    end

    if Extras.isGameHoldingCharacter(rootPart) then
        Extras.HeldByGameAt = os.clock()
        return
    end

    local desiredCFrame = nil
    if lockedEnemyRoot and lockedEnemyRoot.Parent then
        desiredCFrame = getFarmCFrame(lockedEnemyRoot)
        if Combat.HoverOverride and os.clock() < Combat.OverrideUntil then
            desiredCFrame = Combat.HoverOverride
        end
    elseif lockedTargetCFrame then
        desiredCFrame = lockedTargetCFrame
    end
    if not desiredCFrame then
        return
    end
    desiredCFrame = Extras.aboveWater(desiredCFrame)

    local offset = desiredCFrame.Position - rootPart.Position
    local walkInstead = State.SafeTravel or Extras.shouldWalkAfterPullBack()
    if not walkInstead and Extras.isMovementBlocked() and offset.Magnitude > 30 then
        return
    end
    if walkInstead and offset.Magnitude > 30 then
        local revertWatch = Extras.RevertWatch
        if os.clock() - (revertWatch.LastWalkOrder or 0) >= 0.25 then
            revertWatch.LastWalkOrder = os.clock()
            removeFloat(rootPart)
            if playerHumanoid:GetState() == Enum.HumanoidStateType.Physics then
                pcall(function()
                    playerHumanoid:ChangeState(Enum.HumanoidStateType.Running)
                end)
            end
            playerHumanoid:MoveTo(Vector3.new(desiredCFrame.Position.X, rootPart.Position.Y, desiredCFrame.Position.Z))
            State.TravelStatus = string.format("Walking %d studs to the target (the server rejected flying)", math.floor(offset.Magnitude))
        end
        return
    end
    getOrCreateFloat(rootPart)
    pcall(function()
        playerHumanoid:ChangeState(Enum.HumanoidStateType.Physics)
    end)
    local maxStep = 60 * math.min(deltaTime, 0.1)
    local distance = offset.Magnitude
    if distance > math.max(maxStep, 45) then
        rootPart.CFrame = CFrame.new(rootPart.Position + offset.Unit * maxStep) * desiredCFrame.Rotation
    elseif distance > 2 then
        local stepSize = math.min(distance, math.max(distance * 0.35, maxStep))
        rootPart.CFrame = CFrame.new(rootPart.Position + offset.Unit * stepSize) * desiredCFrame.Rotation
    else
        rootPart.CFrame = desiredCFrame
    end
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
end)

Extras.RevertWatch = {
    LastPosition = nil,
    LastCharacter = nil,
    Jumps = {},
    Backoff = 3,
    BlockedUntil = 0,
    LastRejectAt = -math.huge,
    ExpectUntil = 0
}

function Extras.isMovementBlocked()
    return os.clock() < Extras.RevertWatch.BlockedUntil
end

function Extras.shouldWalkAfterPullBack()
    if not State.PullBackPause then
        return false
    end
    local revertWatch = Extras.RevertWatch
    return (revertWatch.Streak or 0) >= 2 and os.clock() - revertWatch.LastRejectAt <= 60
end

function Extras.expectTeleport(seconds)
    Extras.RevertWatch.ExpectUntil = os.clock() + (seconds or 8)
end

if getgenv().HubDodgeConnection then
    pcall(function()
        getgenv().HubDodgeConnection:Disconnect()
    end)
    getgenv().HubDodgeConnection = nil
end
getgenv().HubDodgeLearned = nil

if getgenv().HubRevertConnection then
    pcall(function()
        getgenv().HubRevertConnection:Disconnect()
    end)
end

getgenv().HubRevertConnection = runService.Heartbeat:Connect(function()
    local revertWatch = Extras.RevertWatch
    local playerCharacter = localPlayer.Character
    local rootPart = playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        revertWatch.LastPosition = nil
        return
    end

    if isFarmActive() and (travelActive or currentTween or lockedEnemyRoot or lockedTargetCFrame) then
        local swimLock = rootPart:FindFirstChild("Swim")
        if swimLock and swimLock:IsA("BodyPosition") and swimLock.MaxForce.Magnitude > 0 then
            swimLock.MaxForce = Vector3.zero
        end
    end

    local currentPosition = rootPart.Position
    if playerCharacter ~= revertWatch.LastCharacter then
        revertWatch.LastCharacter = playerCharacter
        revertWatch.LastPosition = currentPosition
        revertWatch.Jumps = {}
        return
    end

    local previousPosition = revertWatch.LastPosition
    revertWatch.LastPosition = currentPosition
    if not previousPosition or (currentPosition - previousPosition).Magnitude < 60 then
        return
    end
    if playerCharacter:FindFirstChild("Acting") then
        Extras.SkillMovedAt = os.clock()
        return
    end
    if Extras.isGameHoldingCharacter(rootPart) then
        return
    end

    local now = os.clock()
    if now < revertWatch.ExpectUntil then
        return
    end

    table.insert(revertWatch.Jumps, now)
    while revertWatch.Jumps[1] and now - revertWatch.Jumps[1] > 2 do
        table.remove(revertWatch.Jumps, 1)
    end

    if #revertWatch.Jumps >= 1 and not State.PullBackPause then
        revertWatch.Jumps = {}
        revertWatch.LastRejectAt = now
        revertWatch.RejectCount = (revertWatch.RejectCount or 0) + 1
        State.TravelStatus = "The server pulled the character back | continuing (pause off)"
        return
    end

    if #revertWatch.Jumps >= 1 and not Extras.isMovementBlocked() then
        if now - revertWatch.LastRejectAt > 60 then
            revertWatch.Backoff = 3
            revertWatch.Streak = 1
        else
            revertWatch.Backoff = math.min(revertWatch.Backoff * 2, 30)
            revertWatch.Streak = (revertWatch.Streak or 1) + 1
        end
        revertWatch.LastRejectAt = now
        revertWatch.BlockedUntil = now + revertWatch.Backoff
        revertWatch.Jumps = {}
        stopTween()
        lockedEnemyRoot = nil
        lockedTargetCFrame = nil
        State.ExtraStatus = string.format("Movement: the server pulled the character back | holding still for %ds", revertWatch.Backoff)
    end
end)

getgenv().HubCleanup = function()
    for key, value in pairs(State) do
        if type(value) == "boolean" and string.sub(key, -7) == "Enabled" then
            State[key] = false
        end
    end
    State.FarmLevelEnabled = false
    State.FarmQuestEnabled = false
    State.PrestigeEnabled = false
    State.AutoCodeEnabled = false
    State.AutoChestEnabled = false
    State.UnlockEnabled = false
    State.AutoPickupEnabled = false
    State.BossFarmEnabled = false
    State.StatusRefreshEnabled = false
    State.CombatToken = nil
    pickupActive = false
    prestigeActive = false
    travelActive = false
    bossPriority = false
    movementOwner = nil
    stopTween()
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    lastKnownMobCFrame = nil
    for _, connection in ipairs(bossEventConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    bossEventConnections = {}
    if noClipConnection then
        noClipConnection:Disconnect()
        noClipConnection = nil
    end
    if lockConnection then
        lockConnection:Disconnect()
        lockConnection = nil
    end
    if getgenv().HubRevertConnection then
        getgenv().HubRevertConnection:Disconnect()
        getgenv().HubRevertConnection = nil
    end
    if targetBox then
        targetBox:Destroy()
        targetBox = nil
    end
    if getgenv().HubNotifyConnection then
        pcall(function()
            getgenv().HubNotifyConnection:Disconnect()
        end)
        getgenv().HubNotifyConnection = nil
    end
    for _, connection in ipairs(getgenv().HubPrestigeConnections or {}) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    getgenv().HubPrestigeConnections = {}
    pcall(Combat.removeAimHook)
    pcall(function()
        if Extras.Yhwach then
            Extras.Yhwach.releaseAll()
            Extras.Yhwach.save()
        end
    end)
    pcall(Extras.stopAll)
    if getgenv().HubDungeonConnection then
        pcall(function()
            getgenv().HubDungeonConnection:Disconnect()
        end)
        getgenv().HubDungeonConnection = nil
    end
    local rootPart = getRoot()
    removeFloat(rootPart)
end

local function getInventoryAmount(itemName)
    if not itemName then
        return 0
    end
    local dataFolder = localPlayer:FindFirstChild("Data")
    local inventoryFolder = dataFolder and dataFolder:FindFirstChild("Inventory")
    local item = inventoryFolder and inventoryFolder:FindFirstChild(itemName)
    if not item then
        return 0
    end
    local amountValue = item:FindFirstChild("Amount")
    if amountValue then
        return amountValue.Value
    end
    return 1
end

function Extras.isItemFull(itemName)
    if type(itemName) ~= "string" or itemName == "" then
        return false
    end
    local resolvedName = itemName
    local entry = itemData[itemName]
    if type(entry) ~= "table" then
        if not Extras.ItemNameByKey then
            Extras.ItemNameByKey = {}
            for name, data in pairs(itemData) do
                if type(name) == "string" and type(data) == "table" then
                    Extras.ItemNameByKey[normalizeName(name)] = name
                end
            end
        end
        resolvedName = Extras.ItemNameByKey[normalizeName(itemName)]
        entry = resolvedName and itemData[resolvedName]
    end
    local maxAmount = type(entry) == "table" and tonumber(entry.MaxAmount) or nil
    return maxAmount ~= nil and getInventoryAmount(resolvedName) >= maxAmount
end

local function getDataValue(valueName)
    local dataFolder = localPlayer:FindFirstChild("Data")
    local dataValue = dataFolder and dataFolder:FindFirstChild(valueName)
    return (dataValue and dataValue.Value) or 0
end

local function getMoney()
    return getDataValue("Money")
end

local function getShards()
    return getDataValue("Shards")
end

local function getPlayerLevel()
    local dataFolder = localPlayer:FindFirstChild("Data")
    if not dataFolder then
        return 1
    end

    local levelValue = dataFolder:FindFirstChild("Level")
    if levelValue and (levelValue:IsA("NumberValue") or levelValue:IsA("IntValue")) then
        return levelValue.Value
    end

    return 1
end

local function getStatPriorityOrder()
    local ordered = {}
    local seen = {}

    for _, statName in ipairs(State.StatPriority) do
        if statLookup[statName] and not seen[statName] then
            seen[statName] = true
            table.insert(ordered, statName)
        end
    end

    for _, statName in ipairs(statNames) do
        if not seen[statName] then
            seen[statName] = true
            table.insert(ordered, statName)
        end
    end

    return ordered
end

function StatMeta.getCap()
    if StatMeta.PrestigeData == nil then
        StatMeta.PrestigeData = false
        pcall(function()
            StatMeta.PrestigeData = require(replicatedStorage.Modules.Configurations.PrestigeData)
        end)
    end
    local cap = nil
    local prestigeData = StatMeta.PrestigeData
    if prestigeData and typeof(prestigeData.GetLevelCap) == "function" then
        local ok, result = pcall(prestigeData.GetLevelCap, getDataValue("Prestige"))
        if ok and typeof(result) == "number" and result > 0 then
            cap = result
        end
    end
    return math.max(cap or StatMeta.FallbackCap, getPlayerLevel())
end

local function autoAllocateStats()
    if not State.AutoStatEnabled or StatMeta.Allocating then
        return
    end

    local dataFolder = localPlayer:FindFirstChild("Data")
    local pointsValue = dataFolder and dataFolder:FindFirstChild("Points")
    if not pointsValue or pointsValue.Value <= 0 then
        return
    end

    StatMeta.Allocating = true
    local statCap = StatMeta.getCap()
    local spentAny = false

    for _, statName in ipairs(getStatPriorityOrder()) do
        local available = pointsValue.Value
        if available <= 0 then
            break
        end

        local room = statCap - getDataValue(statName)
        local amount = math.floor(math.min(room, available))
        if amount > 0 and invokeInput("AddPoint", statName, amount) then
            spentAny = true
            local deadline = os.clock() + 1
            while pointsValue.Value == available and os.clock() < deadline do
                task.wait()
            end
            State.StatStatus = string.format("%s %d/%d | points left %d", StatMeta.Display[statName] or statName, math.floor(getDataValue(statName)), statCap, math.floor(pointsValue.Value))
        end
    end

    if not spentAny and pointsValue.Value > 0 then
        State.StatStatus = string.format("Points %d | priority stats already at the %d cap", math.floor(pointsValue.Value), statCap)
    end
    StatMeta.Allocating = false
end

function StatMeta.connectWatcher()
    for _, connection in ipairs(getgenv().HubStatConnections or {}) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    local connections = {}
    getgenv().HubStatConnections = connections
    task.spawn(function()
        local dataFolder = localPlayer:WaitForChild("Data", 60)
        local pointsValue = dataFolder and dataFolder:WaitForChild("Points", 30)
        if not pointsValue or getgenv().HubStatConnections ~= connections then
            return
        end
        table.insert(connections, pointsValue:GetPropertyChangedSignal("Value"):Connect(function()
            if State.AutoStatEnabled and pointsValue.Value > 0 then
                task.defer(autoAllocateStats)
            end
        end))
        while getgenv().HubStatConnections == connections do
            if State.AutoStatEnabled and pointsValue.Value > 0 and not StatMeta.Allocating then
                autoAllocateStats()
            end
            task.wait(0.5)
        end
    end)
end

StatMeta.connectWatcher()

local function findNPCByName(npcName)
    if not npcName then
        return nil
    end

    local direct = npcsFolder:FindFirstChild(npcName)
    if direct then
        return direct
    end

    local normalizedTarget = normalizeName(npcName)
    for _, npc in ipairs(npcsFolder:GetChildren()) do
        if normalizeName(npc.Name) == normalizedTarget then
            return npc
        end
    end

    for _, npc in ipairs(npcsFolder:GetChildren()) do
        if normalizeName(stripBossTag(npc.Name)) == normalizedTarget then
            return npc
        end
    end

    return nil
end

local function isItemEquipped(itemName)
    local itemInfo = itemData[itemName]
    if not itemInfo or not itemInfo.Type then
        return false
    end

    local dataFolder = localPlayer:FindFirstChild("Data")
    local currentValue = dataFolder and dataFolder:FindFirstChild("Current" .. tostring(itemInfo.Type))
    if not currentValue then
        return false
    end

    local inventoryFolder = dataFolder:FindFirstChild("Inventory")
    local item = inventoryFolder and inventoryFolder:FindFirstChild(itemName)
    local identityValue = item and item:FindFirstChild("Identity")
    if identityValue and currentValue.Value == identityValue.Value then
        return true
    end

    return currentValue.Value == itemName
end

local function equipInventoryItem(itemName)
    if not itemName or isItemEquipped(itemName) then
        return true
    end

    local dataFolder = localPlayer:FindFirstChild("Data")
    local inventoryFolder = dataFolder and dataFolder:FindFirstChild("Inventory")
    local item = inventoryFolder and inventoryFolder:FindFirstChild(itemName)
    if not item then
        return false
    end

    local identityValue = item:FindFirstChild("Identity")
    local identity = (identityValue and identityValue.Value) or itemName

    if equipRemote then
        local itemInfo = itemData[itemName]
        if itemInfo and itemInfo.Type then
            pcall(function()
                equipRemote:FireServer(itemInfo.Type, itemName, identity)
            end)
            task.wait(0.35)
            if isItemEquipped(itemName) then
                return true
            end
        end

        pcall(function()
            equipRemote:FireServer(identity)
        end)
        task.wait(0.35)
        if isItemEquipped(itemName) then
            return true
        end

        pcall(function()
            equipRemote:FireServer(itemName)
        end)
        task.wait(0.35)
        if isItemEquipped(itemName) then
            return true
        end
    end

    invokeInput("Equip", identity)
    task.wait(0.35)

    return isItemEquipped(itemName)
end

local function getNearestIslandName(targetPosition)
    local islandsFolder = workspaceService:FindFirstChild("Islands") and workspaceService.Islands:FindFirstChild("Islands")
    if not islandsFolder then
        return nil
    end

    local nearestIsland = nil
    local nearestDistance = math.huge

    for _, island in ipairs(islandsFolder:GetChildren()) do
        local islandPosition = (island:IsA("Model") and island:GetPivot().Position) or (island:IsA("BasePart") and island.Position)
        if islandPosition then
            local distance = (islandPosition - targetPosition).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestIsland = island
            end
        end
    end

    return nearestIsland and nearestIsland.Name
end

local function waitForCombatClear(maxSeconds)
    local deadline = os.clock() + (maxSeconds or 5)
    while os.clock() < deadline do
        local playerCharacter = localPlayer.Character
        if not playerCharacter or not playerCharacter:FindFirstChild("InCombat") then
            return true
        end
        task.wait(0.5)
    end

    local playerCharacter = localPlayer.Character
    return playerCharacter == nil or playerCharacter:FindFirstChild("InCombat") == nil
end

local function tweenSegment(targetCFrame)
    local rootPart, playerHumanoid = getRoot()
    if not rootPart then
        return 0, 0
    end

    local startPosition = rootPart.Position
    local expectedDistance = (targetCFrame.Position - startPosition).Magnitude
    if Extras.isMovementBlocked() then
        return 0, expectedDistance
    end

    getOrCreateFloat(rootPart)
    if playerHumanoid then
        pcall(function()
            playerHumanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end)
    end

    stopTween()
    targetCFrame = Extras.aboveWater(targetCFrame)
    Extras.leaveWater()
    local duration = math.max(expectedDistance / 60, 0.08)
    if duration ~= duration or duration > 30 then
        return 0, expectedDistance
    end
    Extras.TravelStage = string.format("tweenSegment %.0f", expectedDistance)
    Extras.TweenCaller = debug.traceback()
    local segmentTween = tweenService:Create(rootPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = targetCFrame })
    currentTween = segmentTween
    local finished = false
    local completedConnection = segmentTween.Completed:Connect(function()
        finished = true
    end)
    segmentTween:Play()
    local deadline = os.clock() + duration + 1
    while not finished and os.clock() < deadline do
        task.wait()
    end
    completedConnection:Disconnect()
    stopTween()

    rootPart, playerHumanoid = getRoot()
    if not rootPart then
        return 0, expectedDistance
    end

    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero

    return (rootPart.Position - startPosition).Magnitude, expectedDistance
end

function Extras.walkTo(targetPosition, checkCondition)
    local rootPart, playerHumanoid = getRoot()
    if not rootPart or not playerHumanoid then
        return false
    end
    local flatOffset = Vector3.new(targetPosition.X - rootPart.Position.X, 0, targetPosition.Z - rootPart.Position.Z)
    if flatOffset.Magnitude > ((State.SafeTravel or Extras.ForceWalk) and 6000 or 1500) then
        return false
    end

    stopTween()
    removeFloat(rootPart)
    pcall(function()
        playerHumanoid:ChangeState(Enum.HumanoidStateType.Running)
    end)

    local function flatDistance(position)
        return Vector3.new(targetPosition.X - position.X, 0, targetPosition.Z - position.Z).Magnitude
    end
    local function shouldStop()
        return not isFarmActive() or (checkCondition and checkCondition() == false) or not (State.SafeTravel or Extras.ForceWalk or Extras.isMovementBlocked() or Extras.shouldWalkAfterPullBack())
    end

    Extras.Walking = true
    local playerCharacter = localPlayer.Character
    for _, partName in ipairs({ "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", "Head" }) do
        local part = playerCharacter and playerCharacter:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            part.CanCollide = true
        end
    end

    local result = false
    local stuckCount = 0
    while stuckCount < 4 do
        rootPart, playerHumanoid = getRoot()
        if not rootPart or not playerHumanoid or playerHumanoid.Health <= 0 then
            break
        end
        if flatDistance(rootPart.Position) <= 6 then
            result = true
            break
        end
        if shouldStop() then
            break
        end

        Extras.TravelStage = "walk:path"
        local waypoints = Extras.computeWalkPath(rootPart.Position, targetPosition)
        Extras.TravelStage = "walk:follow"
        local outcome = Extras.followWaypoints(waypoints, flatDistance, shouldStop)
        if outcome == "arrived" then
            result = true
            break
        elseif outcome == "stopped" then
            break
        elseif outcome == "stuck" then
            stuckCount = stuckCount + 1
        end
    end

    Extras.Walking = false
    rootPart, playerHumanoid = getRoot()
    if rootPart and playerHumanoid then
        playerHumanoid:MoveTo(rootPart.Position)
    end
    return result
end

Extras.PathfindingService = game:GetService("PathfindingService")

function Extras.computeWalkPath(fromPosition, targetPosition)
    local goal = targetPosition
    local downHit = workspaceService:Raycast(targetPosition + Vector3.new(0, 5, 0), Vector3.new(0, -300, 0), buildRaycastParams())
    if downHit then
        goal = downHit.Position
    end

    local path = Extras.PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = true,
        WaypointSpacing = 8
    })

    local goals = { goal }
    local offset = goal - fromPosition
    if offset.Magnitude > 700 then
        table.insert(goals, fromPosition + offset.Unit * 700)
    end
    for _, candidate in ipairs(goals) do
        local ok = pcall(function()
            path:ComputeAsync(fromPosition, candidate)
        end)
        if ok and path.Status == Enum.PathStatus.Success then
            return path:GetWaypoints()
        end
    end
    return { { Position = Vector3.new(targetPosition.X, fromPosition.Y, targetPosition.Z), Action = Enum.PathWaypointAction.Walk } }
end

function Extras.followWaypoints(waypoints, flatDistance, shouldStop)
    for index, waypoint in ipairs(waypoints) do
        local rootPart, playerHumanoid = getRoot()
        if not rootPart or not playerHumanoid or playerHumanoid.Health <= 0 then
            return "stopped"
        end
        local waypointFlat = Vector3.new(waypoint.Position.X - rootPart.Position.X, 0, waypoint.Position.Z - rootPart.Position.Z).Magnitude
        if index > 1 or waypointFlat > 4 then
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                playerHumanoid.Jump = true
            end
            playerHumanoid:MoveTo(waypoint.Position)
            local deadline = os.clock() + math.clamp(waypointFlat / 8, 3, 12)
            local lastJumpAt = os.clock()
            while true do
                task.wait(0.1)
                rootPart, playerHumanoid = getRoot()
                if not rootPart or not playerHumanoid or playerHumanoid.Health <= 0 then
                    return "stopped"
                end
                if shouldStop() then
                    return "stopped"
                end
                local remaining = flatDistance(rootPart.Position)
                if remaining <= 6 then
                    return "arrived"
                end
                State.TravelStatus = string.format("Walking %d studs (safe travel)", math.floor(remaining))
                local toWaypoint = Vector3.new(waypoint.Position.X - rootPart.Position.X, 0, waypoint.Position.Z - rootPart.Position.Z).Magnitude
                if toWaypoint <= 4 then
                    break
                end
                if os.clock() > deadline then
                    return "stuck"
                end
                if playerHumanoid:GetState() == Enum.HumanoidStateType.Swimming and os.clock() - lastJumpAt > 1 then
                    lastJumpAt = os.clock()
                    playerHumanoid.Jump = true
                end
                playerHumanoid:MoveTo(waypoint.Position)
            end
        end
    end
    return "moved"
end

local function travelSegments(targetSource, checkCondition)
    local rejectedSegments = 0
    local dynamicTarget = type(targetSource) == "function"
    local startRejects = Extras.RevertWatch.RejectCount or 0

    while true do
        if not isFarmActive() then
            return false
        end

        if checkCondition and checkCondition() == false then
            return false
        end

        if Extras.PriorityRequest and movementOwner ~= Extras.PriorityRequest then
            return false
        end

        if (Extras.RevertWatch.RejectCount or 0) - startRejects >= 8 then
            Extras.RevertWatch.TripAbortedAt = os.clock()
            State.TravelStatus = "The server pulled the character back 8 times on this trip | giving up this trip"
            return false
        end

        local targetCFrame = targetSource
        if dynamicTarget then
            targetCFrame = targetSource()
            if not targetCFrame then
                return false
            end
        end

        if State.SafeTravel or Extras.ForceWalk or Extras.shouldWalkAfterPullBack() then
            Extras.TravelStage = "segments:walk"
            return Extras.walkTo(targetCFrame.Position, checkCondition)
        end

        Extras.TravelStage = "segments:loop"
        if Extras.isMovementBlocked() then
            State.TravelStatus = string.format("Pulled back by the server | holding %.0fs, then flying again", Extras.RevertWatch.BlockedUntil - os.clock())
            while Extras.isMovementBlocked() do
                if not isFarmActive() or (checkCondition and checkCondition() == false) then
                    return false
                end
                task.wait(0.2)
            end
        end

        local rootPart = getRoot()
        if not rootPart then
            return false
        end

        local remaining = (targetCFrame.Position - rootPart.Position).Magnitude
        if remaining <= 6 then
            tweenSegment(targetCFrame)
            return true
        end

        local hopDistance = math.min(remaining, dynamicTarget and 60 or (State.MaxHopDistance or 180))
        local direction = (targetCFrame.Position - rootPart.Position).Unit
        local waypoint = CFrame.new(rootPart.Position + direction * hopDistance)

        local movedDistance, expectedDistance = tweenSegment(waypoint)

        if movedDistance < expectedDistance * 0.35 then
            rejectedSegments = rejectedSegments + 1
            if rejectedSegments >= 3 then
                return false
            end
            task.wait(0.6)
        else
            rejectedSegments = 0
            task.wait(0.08)
        end
    end
end

local function travelTo(targetCFrame, checkCondition)
    Extras.TravelCaller = debug.traceback()
    travelActive = true
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil

    if State.AbilityFlight and not State.SafeTravel and not Extras.ForceWalk and Extras.flyLongTrip then
        Extras.TravelStage = "travelTo:flyLongTrip"
        pcall(Extras.flyLongTrip, targetCFrame, checkCondition)
    end

    Extras.TravelStage = "travelTo:segments"
    local success, arrived = pcall(travelSegments, targetCFrame, checkCondition)

    Extras.TravelStage = "travelTo:done"
    travelActive = false
    stopTween()

    return success and arrived == true
end

Extras.TeleportOverhead = 250
Extras.PortalLandings = {
    ["Hueco Mundo"] = Vector3.new(-200, 26, 3099),
    ["Grave Island"] = Vector3.new(2896, 39, -3138)
}
Extras.SpotLandings = {}
Extras.LearnedPath = "LEGACY PIECE/LP_learned.json"

function Extras.saveLearned()
    local data = { Portals = {}, Spots = {} }
    for name, position in pairs(Extras.PortalLandings) do
        data.Portals[name] = { position.X, position.Y, position.Z }
    end
    for name, position in pairs(Extras.SpotLandings) do
        data.Spots[name] = { position.X, position.Y, position.Z }
    end
    local spawnValue = Extras.SpawnSetValue
    if Extras.SpawnSetPosition and (type(spawnValue) == "string" or type(spawnValue) == "number") then
        data.Spawn = { Position = { Extras.SpawnSetPosition.X, Extras.SpawnSetPosition.Y, Extras.SpawnSetPosition.Z }, Value = spawnValue }
    end
    pcall(function()
        writefile(Extras.LearnedPath, httpService:JSONEncode(data))
    end)
end

function Extras.loadLearned()
    local ok, data = pcall(function()
        return httpService:JSONDecode(readfile(Extras.LearnedPath))
    end)
    if not ok or type(data) ~= "table" then
        return
    end
    for name, xyz in pairs(data.Portals or {}) do
        Extras.PortalLandings[name] = Vector3.new(xyz[1], xyz[2], xyz[3])
    end
    for name, xyz in pairs(data.Spots or {}) do
        Extras.SpotLandings[name] = Vector3.new(xyz[1], xyz[2], xyz[3])
    end
    if type(data.Spawn) == "table" and type(data.Spawn.Position) == "table" then
        local xyz = data.Spawn.Position
        Extras.SpawnSetPosition = Vector3.new(xyz[1], xyz[2], xyz[3])
        Extras.SpawnSetValue = data.Spawn.Value
    end
end

Extras.loadLearned()

Extras.getSpotLanding = function(targetName)
    return Extras.SpotLandings[targetName] or Extras.worldPositionOf(findNPCByName(targetName))
end

Extras.worldPositionOf = function(model)
    if not model then
        return nil
    end
    local cframeAttribute = model:GetAttribute("CFrame")
    if typeof(cframeAttribute) == "CFrame" then
        return cframeAttribute.Position
    end
    local part = model:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

Extras.findNearestTeleporter = function(position)
    local bestNpc, bestPosition, bestDistance = nil, nil, math.huge
    for _, npc in ipairs(npcsFolder:GetChildren()) do
        if string.find(string.lower(npc.Name), "teleport", 1, true) then
            local npcPosition = Extras.worldPositionOf(npc)
            if npcPosition then
                local distance = (npcPosition - position).Magnitude
                if distance < bestDistance then
                    bestNpc, bestPosition, bestDistance = npc, npcPosition, distance
                end
            end
        end
    end
    return bestNpc, bestPosition, bestDistance
end

Extras.flyToTeleporter = function(label)
    local rootPart = getRoot()
    if not rootPart then
        return false
    end
    local teleporter, teleporterPosition, teleporterDistance = Extras.findNearestTeleporter(rootPart.Position)
    if not teleporter then
        State.TravelStatus = "No teleporter NPC found"
        return false
    end
    if teleporterDistance > 12 then
        State.TravelStatus = "Flying to teleporter (" .. tostring(math.floor(teleporterDistance)) .. " studs) for " .. label
        if not travelTo(CFrame.new(teleporterPosition + Vector3.new(0, 1.5, 3.5))) then
            State.TravelStatus = "Could not reach teleporter for " .. label
            return false
        end
    end
    return true, teleporter, CFrame.new(teleporterPosition + Vector3.new(0, 1.5, 3.5))
end

Extras.fireTeleportWithRetry = function(label, fireTeleport, hasArrived)
    for attempt = 1, 4 do
        local character = localPlayer.Character
        if character and character:FindFirstChild("InCombat") then
            State.TravelStatus = "At the teleporter | waiting for In Combat to clear (" .. label .. ")"
            waitForCombatClear(20)
        end
        local rootPart = getRoot()
        if not rootPart then
            return false
        end
        local startPosition = rootPart.Position
        travelActive = true
        stopTween()
        lockedEnemyRoot = nil
        lockedTargetCFrame = nil
        State.TravelStatus = string.format("Teleporting to %s (try %d)", label, attempt)
        Extras.expectTeleport(8)
        pcall(fireTeleport)
        local deadline = os.clock() + 5
        while os.clock() < deadline do
            task.wait(0.1)
            local currentRoot = getRoot()
            if currentRoot and hasArrived(currentRoot, startPosition) then
                travelActive = false
                return true
            end
        end
        travelActive = false
        task.wait(0.5)
    end
    return false
end

local function teleportToSpot(islandName, targetName, force)
    if not islandSpotRemote or not islandName or not targetName then
        return false
    end

    local rootPart = getRoot()
    if not rootPart then
        return false
    end

    if not force then
        local spotPosition = Extras.getSpotLanding(targetName)
        local _, _, teleporterDistance = Extras.findNearestTeleporter(rootPart.Position)
        if spotPosition and (spotPosition - rootPart.Position).Magnitude <= teleporterDistance + (State.SafeTravel and 60 or Extras.TeleportOverhead) then
            return true
        end
    end

    if not Extras.flyToTeleporter(targetName) then
        return false
    end

    local arrived = Extras.fireTeleportWithRetry(targetName .. " (" .. islandName .. ")", function()
        islandSpotRemote:FireServer(islandName, targetName)
    end, function(currentRoot, startPosition)
        return (currentRoot.Position - startPosition).Magnitude > 40 and getNearestIslandName(currentRoot.Position) == islandName
    end)

    if arrived then
        local landedRoot = getRoot()
        if landedRoot then
            Extras.SpotLandings[targetName] = landedRoot.Position
            Extras.saveLearned()
        end
        State.TravelStatus = "Arrived at " .. targetName .. " (" .. islandName .. ")"
        settleCharacter()
    else
        State.TravelStatus = "Island spot teleport failed for " .. targetName
    end

    return arrived
end

local function getSpotForNPCName(npcName)
    if not npcName then
        return nil
    end
    return islandSpotByNpc[normalizeName(npcName)]
end

local function pickIslandSpot(islandName, targetPosition)
    local spots = islandSpotList[islandName]
    if not spots or #spots == 0 then
        return nil
    end

    if not targetPosition then
        return spots[1]
    end

    local bestSpot = spots[1]
    local bestDistance = math.huge

    for _, spot in ipairs(spots) do
        local spotPosition = Extras.getSpotLanding(spot.Target)
        if spotPosition then
            local distance = (spotPosition - targetPosition).Magnitude
            if distance < bestDistance then
                bestDistance = distance
                bestSpot = spot
            end
        end
    end

    return bestSpot
end

local teleportToIsland

local function teleportViaTeleporter(targetIslandName)
    local configName = islandConfigMap[targetIslandName] or targetIslandName
    local rootPart = getRoot()
    if not rootPart then
        return false
    end

    local reachedTeleporter, nearestTeleporter, teleporterCFrame = Extras.flyToTeleporter(configName)
    if not reachedTeleporter then
        return false
    end

    do
        local portalRemote = remotesFolder:FindFirstChild("TeleportToPortal")
        local islandInfo = islandsConfig[configName] or islandsConfig[targetIslandName]
        local portalId = typeof(islandInfo) == "table" and islandInfo.PortalId
        if portalRemote and portalId then
            local portalArrived = Extras.fireTeleportWithRetry(configName, function()
                portalRemote:FireServer(portalId)
            end, function(currentRoot, startPosition)
                return (currentRoot.Position - startPosition).Magnitude > 300 and getNearestIslandName(currentRoot.Position) == targetIslandName
            end)
            local afterRoot = getRoot()
            if portalArrived and afterRoot then
                State.TravelStatus = "Portal teleport finished at " .. targetIslandName
                Extras.PortalLandings[targetIslandName] = afterRoot.Position
                Extras.saveLearned()
                removeFloat(afterRoot)
                return true
            end
        end
    end

    local function runTeleportSequence()
        stopTween()
        local hoverRoot = getRoot()
        if hoverRoot then
            getOrCreateFloat(hoverRoot)
            hoverRoot.AssemblyLinearVelocity = Vector3.zero
        end

        local prompt = nil
        for _ = 1, 12 do
            prompt = nearestTeleporter:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                break
            end
            hoverRoot = getRoot()
            if hoverRoot then
                hoverRoot.CFrame = teleporterCFrame
                hoverRoot.AssemblyLinearVelocity = Vector3.zero
            end
            task.wait(0.3)
        end

        local renv = (getrenv and getrenv()) or {}
        local teleportUI = (renv._G and renv._G.TeleportUI) or _G.TeleportUI
        if not teleportUI then
            State.TravelStatus = "TeleportUI not found"
            return false
        end

        pcall(function()
            teleportUI:reset()
        end)

        if prompt then
            for _ = 1, 4 do
                if teleportUI._isAppeared then
                    break
                end
                triggerPrompt(prompt)
                task.wait(0.35)
            end
        end

        if not teleportUI._isAppeared then
            pcall(function()
                teleportUI:appear()
            end)
            task.wait(0.5)
        end

        State.TravelStatus = "Teleport UI " .. (teleportUI._isAppeared and "open" or "closed") .. " | selecting " .. configName

        for _ = 1, 2 do
            local currentTarget = typeof(teleportUI.Target) == "table" and teleportUI.Target.Island or nil
            if currentTarget == configName then
                break
            end
            pcall(function()
                teleportUI:selectIsland(configName)
            end)
            task.wait(0.2)
        end

        local selectedIsland = typeof(teleportUI.Target) == "table" and teleportUI.Target.Island or nil
        if selectedIsland ~= configName then
            State.TravelStatus = "selectIsland failed for " .. configName
            return false
        end
        task.wait(0.3)

        local canTeleport = false
        local canDeadline = os.clock() + 20
        repeat
            pcall(function()
                canTeleport = teleportUI:canTeleport()
            end)
            if not canTeleport then
                State.TravelStatus = "At the teleporter | waiting for In Combat to clear (" .. configName .. ")"
                task.wait(0.5)
            end
        until canTeleport or os.clock() > canDeadline
        if not canTeleport then
            State.TravelStatus = "canTeleport false for " .. configName
            return false
        end

        local startPosition = getRoot() and getRoot().Position
        Extras.expectTeleport(8)
        pcall(function()
            teleportUI:teleport()
        end)

        local deadline = os.clock() + 8
        while os.clock() < deadline do
            task.wait(0.5)
            local currentRoot = getRoot()
            if currentRoot and startPosition and (currentRoot.Position - startPosition).Magnitude > 300 then
                break
            end
        end

        local arrivedRoot = getRoot()
        if not arrivedRoot then
            State.TravelStatus = "Character missing after teleport"
            return false
        end

        local arrivedIsland = getNearestIslandName(arrivedRoot.Position)
        State.TravelStatus = "Teleport finished at " .. tostring(arrivedIsland)
        return arrivedIsland == targetIslandName
    end

    travelActive = true
    local sequenceOk, sequenceResult = pcall(runTeleportSequence)
    travelActive = false

    if sequenceOk and sequenceResult == true then
        removeFloat(getRoot())
        return true
    end

    if not sequenceOk then
        State.TravelStatus = "Teleport error: " .. tostring(sequenceResult)
    end

    return false
end

teleportToIsland = function(targetIslandName, targetPosition)
    if not targetIslandName or workspaceService:GetAttribute("Dungeon") ~= nil then
        return false
    end

    local rootPart = getRoot()
    if not rootPart then
        return false
    end

    if getNearestIslandName(rootPart.Position) == targetIslandName then
        return true
    end

    local spot = pickIslandSpot(targetIslandName, targetPosition)
    if spot and teleportToSpot(spot.Island, spot.Target) then
        return true
    end

    return teleportViaTeleporter(targetIslandName)
end

Extras.tryTeleportShortcut = function(fromPosition, toPosition)
    if workspaceService:GetAttribute("Dungeon") ~= nil then
        return false
    end
    local _, teleporterPosition, teleporterDistance = Extras.findNearestTeleporter(fromPosition)
    if not teleporterPosition then
        return false
    end
    local directDistance = (toPosition - fromPosition).Magnitude
    local viaCost = teleporterDistance + (State.SafeTravel and 60 or Extras.TeleportOverhead)

    local bestSpot, bestSpotLanding = nil, math.huge
    for _, spots in pairs(islandSpotList) do
        for _, spot in ipairs(spots) do
            local landing = Extras.getSpotLanding(spot.Target)
            if landing then
                local landingDistance = (landing - toPosition).Magnitude
                if landingDistance < bestSpotLanding then
                    bestSpot, bestSpotLanding = spot, landingDistance
                end
            end
        end
    end

    local bestPortal, bestPortalLanding = nil, math.huge
    for islandName, landing in pairs(Extras.PortalLandings) do
        local landingDistance = (landing - toPosition).Magnitude
        if landingDistance < bestPortalLanding then
            bestPortal, bestPortalLanding = islandName, landingDistance
        end
    end

    local spotCost = bestSpot and (viaCost + bestSpotLanding) or math.huge
    local portalCost = bestPortal and (viaCost + bestPortalLanding) or math.huge
    if math.min(spotCost, portalCost) >= directDistance * 0.8 then
        return false
    end

    if spotCost <= portalCost then
        State.TravelStatus = string.format("Teleport shortcut to %s saves ~%d studs", bestSpot.Target, math.floor(directDistance - spotCost))
        return teleportToSpot(bestSpot.Island, bestSpot.Target, true)
    end
    State.TravelStatus = string.format("Portal shortcut to %s saves ~%d studs", bestPortal, math.floor(directDistance - portalCost))
    return teleportViaTeleporter(bestPortal)
end

local function safeTravelTo(targetCFrame, checkCondition)
    local rootPart = getRoot()
    if not rootPart then
        return false
    end

    local totalDistance = (targetCFrame.Position - rootPart.Position).Magnitude

    if totalDistance > (State.SafeTravel and 150 or 350) and Extras.tryTeleportShortcut(rootPart.Position, targetCFrame.Position) then
        task.wait(0.4)
        rootPart = getRoot()
        if not rootPart then
            return false
        end
        totalDistance = (targetCFrame.Position - rootPart.Position).Magnitude
    end

    if totalDistance > 400 then
        local targetIslandName = getNearestIslandName(targetCFrame.Position)
        local currentIslandName = getNearestIslandName(rootPart.Position)

        if targetIslandName and currentIslandName ~= targetIslandName then
            if teleportToIsland(targetIslandName, targetCFrame.Position) then
                task.wait(0.4)
            end
        end
    end

    return travelTo(targetCFrame, checkCondition)
end

local function travelToNPC(targetNPC, checkCondition)
    if not targetNPC or not targetNPC.Parent then
        return false
    end

    local rootPart = getRoot()
    if not rootPart then
        return false
    end

    local anchorPosition = getNPCAnchorPosition(targetNPC)
    if not anchorPosition then
        return false
    end

    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    setTargetBox(nil)

    local npcDistance = (anchorPosition - rootPart.Position).Magnitude
    local npcIslandName = getNearestIslandName(anchorPosition)
    local differentIsland = npcIslandName ~= nil and getNearestIslandName(rootPart.Position) ~= npcIslandName

    local shortcutTaken = npcDistance > (State.SafeTravel and 150 or 350) and Extras.tryTeleportShortcut(rootPart.Position, anchorPosition)
    if not shortcutTaken and npcDistance > 60 and (differentIsland or npcDistance > 900) then
        local spot = getSpotForNPCName(targetNPC.Name)
        local spotArrived = false
        if spot then
            spotArrived = teleportToSpot(spot.Island, spot.Target)
        end
        if not spotArrived and differentIsland then
            teleportToIsland(npcIslandName, anchorPosition)
        end
    end

    anchorPosition = getNPCAnchorPosition(targetNPC) or anchorPosition
    local talkCFrame = computeTalkCFrame(targetNPC)
    rootPart = getRoot()
    if not rootPart or not talkCFrame then
        return false
    end

    if (talkCFrame.Position - rootPart.Position).Magnitude > 6 then
        travelTo(talkCFrame, checkCondition)
    end

    rootPart = getRoot()
    if not rootPart then
        return false
    end

    local settledCFrame = computeTalkCFrame(targetNPC) or talkCFrame
    if (settledCFrame.Position - rootPart.Position).Magnitude > 6 then
        travelTo(settledCFrame, checkCondition)
    end

    holdPosition(settledCFrame)
    lockedTargetCFrame = settledCFrame
    task.wait(0.3)

    rootPart = getRoot()
    anchorPosition = getNPCAnchorPosition(targetNPC) or anchorPosition
    if not rootPart or not anchorPosition then
        return false
    end
    local prompt = getNPCPrompt(targetNPC)
    local maxDist = (prompt and prompt.MaxActivationDistance and (prompt.MaxActivationDistance + 2)) or 14
    if maxDist < 12 then
        maxDist = 12
    end
    local distance = (anchorPosition - rootPart.Position).Magnitude
    local horizontalDist = (Vector3.new(anchorPosition.X, 0, anchorPosition.Z) - Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)).Magnitude
    return distance <= maxDist or (horizontalDist <= 7 and math.abs(anchorPosition.Y - rootPart.Position.Y) <= 12)
end

local function talkToNPC(targetNPC, preferredText, stopCondition, timeoutSeconds)
    local talkCFrame = computeTalkCFrame(targetNPC)
    holdPosition(talkCFrame)
    lockedTargetCFrame = talkCFrame

    local opened = openNPCDialogue(targetNPC, 5)
    local finished = false

    if opened then
        finished = autoDialogue(preferredText, stopCondition, timeoutSeconds or 10)
    end

    lockedTargetCFrame = nil
    return opened, finished
end

local function approachNPC(targetNPC, checkCondition)
    local reached = travelToNPC(targetNPC, checkCondition)
    lockedTargetCFrame = nil
    if not reached then
        settleCharacter()
        local rootPart = getRoot()
        local anchorPosition = getNPCAnchorPosition(targetNPC)
        if not rootPart or not anchorPosition then
            return false
        end
        local prompt = getNPCPrompt(targetNPC)
        local maxDist = (prompt and prompt.MaxActivationDistance and (prompt.MaxActivationDistance + 2)) or 14
        if maxDist < 12 then
            maxDist = 12
        end
        local distance = (anchorPosition - rootPart.Position).Magnitude
        local horizontalDist = (Vector3.new(anchorPosition.X, 0, anchorPosition.Z) - Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)).Magnitude
        return distance <= maxDist or (horizontalDist <= 7 and math.abs(anchorPosition.Y - rootPart.Position.Y) <= 12)
    end
    return true
end

local function getPickupLabel(prompt)
    local objectText = tostring(prompt.ObjectText)
    if objectText ~= "" then
        return objectText
    end
    return tostring(prompt.ActionText)
end

local function isPickupPrompt(prompt)
    if not prompt.Enabled then
        return false
    end

    local parentPart = prompt.Parent
    if not parentPart or not parentPart:IsA("BasePart") then
        return false
    end

    local label = getPickupLabel(prompt)
    if label == "" or string.find(label, "Require", 1, true) then
        return false
    end

    return true
end

AutoPickup.FolderQuest = {
    HollowEchoFragments = "Four Origins - Hollow Echo"
}
AutoPickup.FailedPrompts = setmetatable({}, { __mode = "k" })

local function getPickupPrompts()
    local results = {}

    for _, folderName in ipairs(pickupFolderNames) do
        local folder = extraFolder:FindFirstChild(folderName)
        local requiredQuest = AutoPickup.FolderQuest[folderName]
        local questAllows = requiredQuest == nil or UnlockFarm.getActiveQuestFolder(requiredQuest) ~= nil
        if folder and questAllows then
            for _, descendant in ipairs(folder:GetDescendants()) do
                if descendant:IsA("ProximityPrompt") and isPickupPrompt(descendant) and (AutoPickup.FailedPrompts[descendant] or 0) <= os.clock() and not Extras.isItemFull(getPickupLabel(descendant)) then
                    table.insert(results, descendant)
                end
            end
        end
    end

    return results
end

local function findPickupByName(itemName)
    local normalizedTarget = normalizeName(itemName)
    if normalizedTarget == "" then
        return nil
    end

    for _, prompt in ipairs(getPickupPrompts()) do
        local normalizedLabel = normalizeName(getPickupLabel(prompt))
        if normalizedLabel == normalizedTarget or string.find(normalizedLabel, normalizedTarget, 1, true) then
            return prompt
        end
    end

    return nil
end

local function getNearestPickup(maxDistance)
    local rootPart = getRoot()
    if not rootPart then
        return nil
    end

    local nearestPrompt = nil
    local nearestDistance = math.huge

    for _, prompt in ipairs(getPickupPrompts()) do
        local distance = (prompt.Parent.Position - rootPart.Position).Magnitude
        if distance < nearestDistance and distance <= maxDistance then
            nearestDistance = distance
            nearestPrompt = prompt
        end
    end

    return nearestPrompt
end

local function collectPickup(prompt, checkCondition)
    local promptPart = prompt.Parent
    if not promptPart or not promptPart:IsA("BasePart") then
        return false
    end

    if not acquireMovement("pickup") then
        return false
    end

    local label = getPickupLabel(prompt)
    local amountBefore = getInventoryAmount(label)

    pickupActive = true
    stopTween()
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    setTargetBox(nil)

    local rootPart = getRoot()
    local reach = math.max((prompt.MaxActivationDistance or 10) - 4, 3)

    if rootPart and (promptPart.Position - rootPart.Position).Magnitude > reach then
        safeTravelTo(promptPart.CFrame * CFrame.new(0, 2, 4), checkCondition)
    end

    settleCharacter()

    rootPart = getRoot()
    local reached = rootPart ~= nil and promptPart.Parent ~= nil
        and (promptPart.Position - rootPart.Position).Magnitude <= (prompt.MaxActivationDistance or 10)

    if reached then
        for _ = 1, 4 do
            if not promptPart.Parent or not prompt.Enabled then
                break
            end

            triggerPrompt(prompt)
            task.wait(0.5)

            if getInventoryAmount(label) > amountBefore then
                break
            end
        end
    end

    pickupActive = false
    releaseMovement("pickup")

    local collected = promptPart.Parent == nil or getInventoryAmount(label) > amountBefore
    if reached and not collected then
        AutoPickup.FailedPrompts[prompt] = os.clock() + 300
    end
    return collected
end

local function getQuestNPC(questName)
    if not questName then
        return nil
    end

    local direct = npcsFolder:FindFirstChild(questName)
    if direct then
        return direct
    end

    local questInfo = questData.Main[questName]
    if questInfo and questInfo.NPC then
        local npcByData = npcsFolder:FindFirstChild(questInfo.NPC)
        if npcByData then
            return npcByData
        end
    end

    local normalizedTarget = normalizeName(questName)
    for _, npc in ipairs(npcsFolder:GetChildren()) do
        local normalizedNpc = normalizeName(npc.Name)
        if normalizedNpc == normalizedTarget or string.find(normalizedNpc, normalizedTarget, 1, true) or string.find(normalizedTarget, normalizedNpc, 1, true) then
            return npc
        end
    end

    return nil
end

local function getTargetMobName(questFolder)
    if not questFolder then
        return nil
    end

    local questInfo = questData.Main[questFolder.Name]
    if questInfo and questInfo.Goal and questInfo.Goal.Target then
        if typeof(questInfo.Goal.Target) == "string" then
            return questInfo.Goal.Target
        elseif typeof(questInfo.Goal.Target) == "table" then
            return questInfo.Goal.Target[1]
        end
    end

    local cleanName = string.gsub(questFolder.Name, "^Quest%s*", "")
    return string.gsub(cleanName, "s$", "")
end

local function isLivingEnemy(enemy)
    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
    local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
    return humanoid ~= nil and humanoid.Health > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Dead and enemyRoot ~= nil, enemyRoot
end

local function findEnemyIn(container, mobName, playerPosition, allowBoss)
    if not container then
        return nil, math.huge
    end

    local strippedMob = stripBossTag(mobName)
    local normalizedMob = normalizeName(strippedMob)
    local lowerMob = string.lower(mobName)
    local bossRequested = allowBoss
        or (string.find(lowerMob, "boss", 1, true) ~= nil)
        or (string.find(lowerMob, "true form", 1, true) ~= nil)
        or (string.find(lowerMob, "leader", 1, true) ~= nil)

    local bestEnemy = nil
    local bestDist = math.huge

    for _, enemy in ipairs(container:GetChildren()) do
        local enemyName = enemy.Name
        local normalizedEnemy = normalizeName(stripBossTag(enemyName))
        if enemyName == mobName or normalizedEnemy == normalizedMob then
            local alive, enemyRoot = isLivingEnemy(enemy)
            if alive then
                local distance = (enemyRoot.Position - playerPosition).Magnitude
                if distance < bestDist then
                    bestDist = distance
                    bestEnemy = enemy
                end
            end
        end
    end

    if bestEnemy then
        return bestEnemy, bestDist
    end

    if npcData[strippedMob] ~= nil then
        return nil, math.huge
    end

    for _, enemy in ipairs(container:GetChildren()) do
        local enemyName = enemy.Name
        local normalizedEnemy = normalizeName(stripBossTag(enemyName))
        local lowerEnemy = string.lower(enemyName)

        local isEnemyBoss = (string.find(lowerEnemy, "true form", 1, true) ~= nil)
            or (string.find(lowerEnemy, "boss", 1, true) ~= nil)
            or (string.find(lowerEnemy, "leader", 1, true) ~= nil)

        local isDifferentKnownBoss = knownBossNames[stripBossTag(enemyName)] ~= nil and normalizedEnemy ~= normalizedMob

        if (bossRequested or not isEnemyBoss) and not isDifferentKnownBoss then
            local isMatch = (string.find(normalizedEnemy, normalizedMob, 1, true) == 1)
                or (string.find(normalizedMob, normalizedEnemy, 1, true) == 1)
                or (string.find(enemyName, strippedMob, 1, true) ~= nil)

            if isMatch then
                local alive, enemyRoot = isLivingEnemy(enemy)
                if alive then
                    local distance = (enemyRoot.Position - playerPosition).Magnitude
                    if distance < bestDist then
                        bestDist = distance
                        bestEnemy = enemy
                    end
                end
            end
        end
    end

    return bestEnemy, bestDist
end

local function getTargetEnemy(mobName, playerPosition, allowBoss)
    if not mobName then
        return nil
    end

    local bossMode = allowBoss or State.BossFarmEnabled or isKnownBossName(mobName)

    local enemy = findEnemyIn(enemiesFolder, mobName, playerPosition, bossMode)
    if enemy then
        return enemy
    end

    if whaleFolder then
        enemy = findEnemyIn(whaleFolder, mobName, playerPosition, true)
    end

    return enemy
end

local function findToolForCombatType(character, combatType)
    local wantedType = combatTypeToItemType[combatType or State.FarmCombatType or "Sword"] or "Weapon"
    local backpack = localPlayer:FindFirstChild("Backpack")

    local function matches(tool)
        if not tool:IsA("Tool") then
            return false
        end
        local attributeType = tool:GetAttribute("Type")
        if attributeType then
            return attributeType == wantedType
        end
        local info = itemData[tool.Name]
        return info ~= nil and info.Type == wantedType
    end

    for _, tool in ipairs(character:GetChildren()) do
        if matches(tool) then
            return tool, true
        end
    end

    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if matches(tool) then
                return tool, false
            end
        end
    end

    return nil, false
end

local function equipCombatTool(character)
    local wantedTool, alreadyHeld = findToolForCombatType(character)

    if wantedTool and alreadyHeld then
        return wantedTool
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if wantedTool and humanoid then
        humanoid:EquipTool(wantedTool)
        task.wait(0.2)
        return wantedTool
    end

    local heldTool = character:FindFirstChildOfClass("Tool")
    if heldTool then
        return heldTool
    end

    local backpack = localPlayer:FindFirstChild("Backpack")
    local fallbackTool = backpack and backpack:FindFirstChildOfClass("Tool")
    if fallbackTool and humanoid then
        humanoid:EquipTool(fallbackTool)
        task.wait(0.2)
        return fallbackTool
    end

    return nil
end

function Combat.getActiveTool(toolInstance)
    local gameGlobals = getrenv and getrenv()._G
    local activeTool = gameGlobals and gameGlobals.ActiveToolSelf
    if typeof(activeTool) == "table" and activeTool.Tool == toolInstance then
        return activeTool
    end
    return nil
end

function Combat.getSkillKeys(activeTool)
    if not activeTool or typeof(activeTool.SkillList) ~= "table" then
        return nil
    end

    local cached = Combat.KeyCache[activeTool.SkillList]
    if cached then
        return cached
    end

    local keys = {}
    local found = false
    for _, entry in ipairs(activeTool.SkillList) do
        if typeof(entry) == "table" and typeof(entry.Key) == "string" and entry.Key ~= "" then
            keys[string.sub(string.upper(entry.Key), 1, 1)] = true
            found = true
        end
    end

    if not found then
        return nil
    end

    Combat.KeyCache[activeTool.SkillList] = keys
    return keys
end

function Combat.isSpecialMove(activeTool)
    local move = activeTool and activeTool.Move
    if typeof(move) ~= "function" then
        return false
    end

    local cached = Combat.MoveParams[move]
    if cached == nil then
        local infoOk, paramCount = pcall(function()
            return debug.getinfo(move).numparams
        end)
        cached = infoOk and (tonumber(paramCount) or 0) >= 2
        Combat.MoveParams[move] = cached
    end

    return cached
end

function Combat.isGuiCooldown(skillKey)
    local playerGui = localPlayer:FindFirstChild("PlayerGui")
    local abilityDisplay = playerGui and playerGui:FindFirstChild("AbilityDisplay")
    local skillDisplay = abilityDisplay and abilityDisplay:FindFirstChild("SkillDisplay")
    if not skillDisplay then
        return false
    end

    for _, template in ipairs(skillDisplay:GetChildren()) do
        if template.Name == "AbilityTemplate" and template:GetAttribute("SlotKey") == skillKey then
            local abilityFrame = template:FindFirstChild("AbilityFrame")
            local cooldownLabel = abilityFrame and abilityFrame:FindFirstChild("Cooldown")
            local cooldownText = cooldownLabel and cooldownLabel.Text or ""
            return cooldownText ~= "" and cooldownText ~= "0" and cooldownText ~= "0s"
        end
    end

    return false
end

function Combat.isOnCooldown(toolInstance, activeTool, skillKey, character)
    local cooldownKey = skillKey
    if activeTool and typeof(activeTool.CooldownKeyFor) == "function" then
        local mapOk, mapped = pcall(activeTool.CooldownKeyFor, skillKey, skillKey)
        if mapOk and typeof(mapped) == "string" then
            cooldownKey = mapped
        end
    end

    local markerName = tostring(toolInstance:GetAttribute("Type") or "Weapon") .. "-" .. cooldownKey
    if localPlayer:FindFirstChild(markerName) or character:FindFirstChild(markerName) then
        return true
    end

    local castingSince = State.SkillCasting[skillKey]
    if castingSince then
        local castingAge = os.clock() - castingSince
        if castingAge < Combat.CastingGrace or (castingAge < 8 and character:FindFirstChild("Acting")) then
            return true
        end
        State.SkillCasting[skillKey] = nil
    end

    local serverNow = workspaceService:GetServerTimeNow()
    local readyAt = State.SkillCooldowns[toolInstance.Name .. "|" .. skillKey]
    if readyAt and serverNow < readyAt - 0.05 then
        return true
    end

    if cooldownKey ~= skillKey then
        local mappedReadyAt = State.SkillCooldowns[toolInstance.Name .. "|" .. cooldownKey]
        if mappedReadyAt and serverNow < mappedReadyAt - 0.05 then
            return true
        end
    end

    return Combat.isGuiCooldown(skillKey)
end

function Combat.installAimHook()
    local gameGlobals = getrenv and getrenv()._G
    if typeof(gameGlobals) ~= "table" or typeof(gameGlobals.GetMouse) ~= "function" then
        return false
    end

    if gameGlobals.GetMouse == getgenv().HubAimHook then
        return true
    end

    local originalGetMouse = gameGlobals.GetMouse
    local aimHook = function(...)
        Combat.AimCalls = Combat.AimCalls + 1
        local aimRoot = Combat.AimRoot
        if aimRoot and aimRoot.Parent and os.clock() < Combat.AimUntil then
            return Combat.aimPoint(aimRoot)
        end
        return originalGetMouse(...)
    end

    getgenv().HubOriginalGetMouse = originalGetMouse
    getgenv().HubAimHook = aimHook
    gameGlobals.GetMouse = aimHook
    return true
end

function Combat.removeAimHook()
    local gameGlobals = getrenv and getrenv()._G
    if typeof(gameGlobals) == "table" and getgenv().HubAimHook and gameGlobals.GetMouse == getgenv().HubAimHook then
        gameGlobals.GetMouse = getgenv().HubOriginalGetMouse
    end
    getgenv().HubAimHook = nil
    Combat.AimRoot = nil
    Combat.AimUntil = 0
end

function Combat.aimPoint(enemyRoot)
    if Combat.AimOverride and os.clock() < Combat.OverrideUntil then
        return Combat.AimOverride
    end
    if not State.FarmDistanceOverride then
        return enemyRoot.Position
    end
    local farmPosition = State.FarmPosition
    if farmPosition == "Below" then
        return enemyRoot.Position - Vector3.new(0, Combat.AimOffset, 0)
    elseif farmPosition == "Above" then
        return enemyRoot.Position + Vector3.new(0, Combat.AimOffset, 0)
    end
    return enemyRoot.Position
end

function Combat.fireSkill(toolInstance, activeTool, skillKey, enemyRoot)
    if activeTool and Combat.isSpecialMove(activeTool) then
        Combat.installAimHook()
        Combat.AimRoot = enemyRoot
        Combat.AimUntil = os.clock() + 3
        local aimCallsBefore = Combat.AimCalls

        task.spawn(function()
            pcall(activeTool.Move, skillKey)
        end)

        local firedNormally = Combat.AimCalls > aimCallsBefore
        local startedFlight = typeof(activeTool.Events) == "table" and activeTool.Events.Flight ~= nil

        if startedFlight then
            Combat.SpecialKeys[toolInstance.Name .. "|" .. skillKey] = true
            State.CombatStatus = "Skipping flight skill " .. skillKey .. " on " .. toolInstance.Name .. " | reselect Farm Skills to retry"
        elseif firedNormally then
            return
        end

        task.delay(0.2, function()
            pcall(activeTool.Move, skillKey, "Ended")
        end)
        return
    end

    pcall(function()
        inputEvent:FireServer("Tool", toolInstance, skillKey, Combat.aimPoint(enemyRoot))
    end)
end

function Combat.isAwakenReady(toolInstance, character)
    local awaken = toolInstance and Combat.AwakenSkills[toolInstance.Name]
    if not awaken or character:GetAttribute(awaken.Unlocked) ~= true or character:GetAttribute(awaken.Active) == true then
        return false, awaken
    end
    local markerName = tostring(toolInstance:GetAttribute("Type") or "Weapon") .. "-" .. awaken.Key
    if localPlayer:FindFirstChild(markerName) or character:FindFirstChild(markerName) then
        return false, awaken
    end
    if toolInstance.Parent == character and Combat.isGuiCooldown(awaken.Key) then
        return false, awaken
    end
    if os.clock() < Combat.AwakenBackoffUntil then
        return false, awaken
    end
    return true, awaken
end

function Combat.isAwakenActive(toolInstance, character)
    local awaken = toolInstance and Combat.AwakenSkills[toolInstance.Name]
    return awaken ~= nil and character:GetAttribute(awaken.Active) == true
end

function Combat.needsReload(toolInstance, character)
    local ammoRule = Combat.AmmoRules[toolInstance.Name]
    if not ammoRule or not character then
        return false
    end
    if ammoRule.FormAttribute and character:GetAttribute(ammoRule.FormAttribute) then
        return false
    end
    for _, attributeName in ipairs(ammoRule.Attributes) do
        local ammo = tonumber(character:GetAttribute(attributeName))
        if ammo and ammo <= ammoRule.ReloadAt then
            return true
        end
    end
    return false
end

function Combat.isSkillWanted(toolInstance, skillKey, character)
    local rule = Combat.SkillRules[toolInstance.Name]
    local override = rule and rule[skillKey]
    if override == "never" then
        return false
    elseif override == "awakened" and Combat.isAwakenActive(toolInstance, character) then
        return true
    elseif override == "reload" then
        return Combat.needsReload(toolInstance, character)
    end
    return State.FarmSkills[skillKey] == true
end

function Combat.tryAwaken(toolInstance, character, enemyRoot)
    local ready, awaken = Combat.isAwakenReady(toolInstance, character)
    if not ready then
        Combat.AwakenAttempts = 0
        return false
    end
    local now = os.clock()
    local pendingKey = toolInstance.Name .. "|" .. awaken.Key
    if now < (Combat.PendingUntil[pendingKey] or 0) then
        return true
    end
    Combat.AwakenAttempts = Combat.AwakenAttempts + 1
    if Combat.AwakenAttempts > 4 then
        Combat.AwakenAttempts = 0
        Combat.AwakenBackoffUntil = now + 20
        return false
    end
    Combat.PendingUntil[pendingKey] = now + 1.5
    Combat.NextCastAt = now + 0.25
    pcall(function()
        inputEvent:FireServer("Tool", toolInstance, awaken.Key, Combat.aimPoint(enemyRoot))
    end)
    return true
end

function Combat.castSkills(toolInstance, character, enemyRoot)
    local now = os.clock()
    if now < Combat.NextCastAt then
        return false
    end

    if Combat.tryAwaken(toolInstance, character, enemyRoot) then
        return true
    end

    local activeTool = Combat.getActiveTool(toolInstance)
    local availableKeys = Combat.getSkillKeys(activeTool)

    for skillKey, override in pairs(Combat.SkillRules[toolInstance.Name] or {}) do
        local pendingKey = toolInstance.Name .. "|" .. skillKey
        if override == "reload" and Combat.needsReload(toolInstance, character)
            and (availableKeys == nil or availableKeys[skillKey])
            and now >= (Combat.PendingUntil[pendingKey] or 0)
            and not Combat.isOnCooldown(toolInstance, activeTool, skillKey, character) then
            Combat.PendingUntil[pendingKey] = now + 1.2
            Combat.NextCastAt = now + 0.35
            Combat.fireSkill(toolInstance, activeTool, skillKey, enemyRoot)
            return true
        end
    end

    for _, skillKey in ipairs(skillKeyOrder) do
        local pendingKey = toolInstance.Name .. "|" .. skillKey
        if Combat.isSkillWanted(toolInstance, skillKey, character)
            and (availableKeys == nil or availableKeys[skillKey])
            and not Combat.SpecialKeys[pendingKey]
            and now >= (Combat.PendingUntil[pendingKey] or 0)
            and not Combat.isOnCooldown(toolInstance, activeTool, skillKey, character) then
            Combat.PendingUntil[pendingKey] = now + Combat.PendingSeconds
            Combat.NextCastAt = now + 0.25
            Combat.fireSkill(toolInstance, activeTool, skillKey, enemyRoot)
            return true
        end
    end

    return false
end

function Combat.retarget(rootPart)
    local mobName = Combat.LockedMobName
    if not mobName or not lockedEnemyRoot then
        return nil
    end

    local nextEnemy = getTargetEnemy(mobName, rootPart.Position, Combat.LockedAllowBoss)
    local nextRoot = nextEnemy and nextEnemy:FindFirstChild("HumanoidRootPart")
    if not nextRoot then
        return nil
    end

    local nextCFrame = getFarmCFrame(nextRoot)
    if (nextCFrame.Position - rootPart.Position).Magnitude > Combat.SnapDistance then
        return nil
    end

    lockedEnemyRoot = nextRoot
    lastKnownMobCFrame = nextCFrame
    setTargetBox(nextEnemy)
    return nextRoot
end

function Combat.allSkillsOnCooldown(toolInstance, character)
    local activeTool = Combat.getActiveTool(toolInstance)
    local availableKeys = Combat.getSkillKeys(activeTool)
    local anySelected = false
    for _, skillKey in ipairs(skillKeyOrder) do
        if Combat.isSkillWanted(toolInstance, skillKey, character)
            and (availableKeys == nil or availableKeys[skillKey])
            and not Combat.SpecialKeys[toolInstance.Name .. "|" .. skillKey] then
            anySelected = true
            if not Combat.isOnCooldown(toolInstance, activeTool, skillKey, character) then
                return false
            end
        end
    end
    return anySelected
end

function Combat.hasReadySkill(toolInstance, character)
    local serverNow = workspaceService:GetServerTimeNow()
    local typeName = tostring(toolInstance:GetAttribute("Type") or "Weapon")
    for _, skillKey in ipairs(skillKeyOrder) do
        if Combat.isSkillWanted(toolInstance, skillKey, character) and not Combat.SpecialKeys[toolInstance.Name .. "|" .. skillKey] then
            local markerName = typeName .. "-" .. skillKey
            local readyAt = State.SkillCooldowns[toolInstance.Name .. "|" .. skillKey]
            local cooling = localPlayer:FindFirstChild(markerName) or character:FindFirstChild(markerName) or (readyAt and serverNow < readyAt - 0.05)
            if not cooling then
                return true
            end
        end
    end
    return false
end

function Combat.updateRotation(character)
    local selectedTypes = {}
    for _, typeName in ipairs(Combat.TypeOrder) do
        if State.FarmCombatTypes[typeName] then
            table.insert(selectedTypes, typeName)
        end
    end
    if #selectedTypes == 0 then
        return
    end
    local rotation = Combat.Rotation
    local now = os.clock()
    local currentIndex = table.find(selectedTypes, State.FarmCombatType)
    if not currentIndex then
        State.FarmCombatType = selectedTypes[1]
        rotation.SwitchedAt = now
        return
    end
    if #selectedTypes == 1 or character:FindFirstChild("Acting") or now - rotation.SwitchedAt < Combat.MinDwell then
        return
    end
    local heldTool, alreadyHeld = findToolForCombatType(character)
    if heldTool and (Combat.isAwakenReady(heldTool, character) or Combat.isAwakenActive(heldTool, character)) then
        return
    end
    for _, typeName in ipairs(selectedTypes) do
        if typeName ~= State.FarmCombatType then
            local awakenTool = findToolForCombatType(character, typeName)
            if awakenTool and Combat.isAwakenReady(awakenTool, character) then
                State.FarmCombatType = typeName
                rotation.SwitchedAt = now
                return
            end
        end
    end
    local exhausted = heldTool == nil or (alreadyHeld and Combat.allSkillsOnCooldown(heldTool, character))
    if not exhausted then
        return
    end
    for offset = 1, #selectedTypes - 1 do
        local candidateType = selectedTypes[(currentIndex - 1 + offset) % #selectedTypes + 1]
        local candidateTool = findToolForCombatType(character, candidateType)
        if candidateTool and Combat.hasReadySkill(candidateTool, character) then
            State.FarmCombatType = candidateType
            rotation.SwitchedAt = now
            return
        end
    end
end

function Combat.tick()
    if not isFarmActive() or pickupActive or (Extras.OverHeaven and Extras.OverHeaven.Busy) then
        return
    end

    local approaching = travelActive or currentTween ~= nil
    if approaching and not Combat.ApproachRoot then
        return
    end

    local rootPart, playerHumanoid = getRoot()
    if not rootPart or not playerHumanoid or playerHumanoid.Health <= 0 then
        return
    end

    local enemyRoot = approaching and Combat.ApproachRoot or lockedEnemyRoot
    local enemyModel = enemyRoot and enemyRoot.Parent
    local enemyHumanoid = enemyModel and enemyModel:FindFirstChildOfClass("Humanoid")
    if approaching and (not enemyHumanoid or enemyHumanoid.Health <= 0) then
        return
    end
    if not enemyHumanoid or enemyHumanoid.Health <= 0 then
        enemyRoot = Combat.retarget(rootPart)
        enemyModel = enemyRoot and enemyRoot.Parent
        enemyHumanoid = enemyModel and enemyModel:FindFirstChildOfClass("Humanoid")
        if not enemyHumanoid or enemyHumanoid.Health <= 0 then
            return
        end
    end

    local enemyDistance = (enemyRoot.Position - rootPart.Position).Magnitude
    if enemyDistance > Combat.SkillRange then
        return
    end
    if Combat.HoverOverride and Combat.HoverCastRange and os.clock() < Combat.OverrideUntil and (Combat.HoverOverride.Position - rootPart.Position).Magnitude > Combat.HoverCastRange then
        return
    end

    local character = localPlayer.Character
    if character:FindFirstChild("Stunned") then
        return
    end

    local now = os.clock()
    Combat.updateRotation(character)
    local toolInstance, alreadyHeld = findToolForCombatType(character)
    if toolInstance and not alreadyHeld then
        if now >= Combat.NextEquipAt then
            Combat.NextEquipAt = now + 0.5
            equipCombatTool(character)
        end
        return
    end
    if not toolInstance then
        toolInstance = character:FindFirstChildOfClass("Tool")
    end
    if not toolInstance then
        return
    end

    local acting = character:FindFirstChild("Acting") ~= nil
    if acting then
        Combat.ActingSince = Combat.ActingSince or now
    else
        Combat.ActingSince = nil
        Combat.QueuedWhileActing = false
    end

    if now - (State.LastSkillStart or 0) < 0.2 then
        return
    end

    if State.AutoUseSkills then
        local canCast = not acting or (State.MultiCastSkills and not Combat.QueuedWhileActing and (now - Combat.ActingSince) >= 0.2)
        if canCast and Combat.castSkills(toolInstance, character, enemyRoot) then
            if acting then
                Combat.QueuedWhileActing = true
            end
            return
        end
    end

    if acting or enemyDistance > Combat.MeleeRange or now < Combat.NextCastAt or now < Combat.NextAttackAt then
        return
    end

    Combat.NextAttackAt = now + 0.15
    pcall(function()
        inputEvent:FireServer("Tool", toolInstance, "M1")
    end)
end

function BossFarm.refreshQuincyStatus()
    local quincy = BossFarm.Quincy
    if quincy.StatusBoss and quincy.Kills < quincy.KillsTarget then
        setFarmStatus(string.format("%s | %s %d/%d", quincy.StatusBoss, quincy.SoldierName, quincy.Kills, quincy.KillsTarget))
    end
end

function BossFarm.scanSoldierKills()
    local quincy = BossFarm.Quincy
    local now = os.clock()
    if now < quincy.NextScanAt then
        return
    end
    quincy.NextScanAt = now + 0.1

    local rootPart = getRoot()
    if not rootPart then
        return
    end

    local counted = false
    for humanoid, info in pairs(quincy.Tracked) do
        local removed = info.Model.Parent ~= enemiesFolder
        local dead = humanoid.Health <= 0
        if dead or removed then
            if info.Near and (dead or info.HealthRatio < 0.35) then
                quincy.Kills = quincy.Kills + 1
                counted = true
            end
            quincy.Tracked[humanoid] = nil
        end
    end

    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if stripBossTag(enemy.Name) == quincy.SoldierName then
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
            if humanoid and enemyRoot and humanoid.Health > 0 then
                local info = quincy.Tracked[humanoid] or { Model = enemy }
                info.HealthRatio = humanoid.Health / math.max(humanoid.MaxHealth, 1)
                info.Near = (enemyRoot.Position - rootPart.Position).Magnitude <= quincy.KillRange
                quincy.Tracked[humanoid] = info
            end
        end
    end

    if counted then
        BossFarm.refreshQuincyStatus()
    end
end

local function engageMob(targetMobName, isFarmingActiveCondition, allowBoss)
    local rootPart, playerHumanoid = getRoot()
    if not rootPart or not playerHumanoid or playerHumanoid.Health <= 0 then
        return
    end

    local targetEnemy = getTargetEnemy(targetMobName, rootPart.Position, allowBoss)

    if not targetEnemy then
        setTargetBox(nil)
        lockedEnemyRoot = nil

        if lastKnownMobCFrame then
            local distToLast = (lastKnownMobCFrame.Position - rootPart.Position).Magnitude
            if distToLast > 150 then
                safeTravelTo(lastKnownMobCFrame, function()
                    local currentRoot = getRoot()
                    return isFarmingActiveCondition() and currentRoot ~= nil and getTargetEnemy(targetMobName, currentRoot.Position, allowBoss) == nil
                end)
            else
                lockedTargetCFrame = lastKnownMobCFrame
            end
        end
        task.wait(0.2)
        return
    end

    setTargetBox(targetEnemy)
    local enemyRoot = targetEnemy:FindFirstChild("HumanoidRootPart")
    local enemyHumanoid = targetEnemy:FindFirstChildOfClass("Humanoid")

    if not enemyRoot or not enemyHumanoid or enemyHumanoid.Health <= 0 or enemyHumanoid:GetState() == Enum.HumanoidStateType.Dead then
        lockedEnemyRoot = nil
        setTargetBox(nil)
        return
    end

    local enemyTargetCFrame = getFarmCFrame(enemyRoot)
    lastKnownMobCFrame = enemyTargetCFrame

    local enemyIsland = getNearestIslandName(enemyRoot.Position)
    local needsTrip = (enemyRoot.Position - rootPart.Position).Magnitude > 150
        or (enemyIsland ~= nil and getNearestIslandName(rootPart.Position) ~= enemyIsland and (enemyRoot.Position - rootPart.Position).Magnitude > 60)
    if needsTrip then
        lockedEnemyRoot = nil
        lockedTargetCFrame = nil
        Combat.ApproachRoot = enemyRoot
        local function enemyStillValid()
            return isFarmingActiveCondition() and enemyHumanoid.Health > 0 and enemyRoot.Parent ~= nil
        end
        if (enemyTargetCFrame.Position - rootPart.Position).Magnitude > 400 then
            safeTravelTo(enemyTargetCFrame, function()
                local currentRoot = getRoot()
                return enemyStillValid() and currentRoot ~= nil and (currentRoot.Position - enemyRoot.Position).Magnitude > 300
            end)
        end
        travelTo(function()
            if not enemyStillValid() then
                return nil
            end
            local currentRoot = getRoot()
            if currentRoot and (currentRoot.Position - enemyRoot.Position).Magnitude <= 60 then
                return nil
            end
            return getFarmCFrame(enemyRoot)
        end, enemyStillValid)
        Combat.ApproachRoot = nil
        rootPart = getRoot()
        if not rootPart or enemyRoot.Parent == nil or enemyHumanoid.Health <= 0 then
            return
        end
    end

    lockedTargetCFrame = nil
    lockedEnemyRoot = enemyRoot
    Combat.LockedMobName = targetMobName
    Combat.LockedAllowBoss = allowBoss

    pcall(function()
        if enemyRoot:GetNetworkOwner() == localPlayer then
            enemyRoot.AssemblyLinearVelocity = Vector3.zero
            enemyRoot.AssemblyAngularVelocity = Vector3.zero
        end
    end)

    local playerCharacter = localPlayer.Character
    if playerCharacter then
        equipCombatTool(playerCharacter)
    end
end

State.CombatToken = {}
task.spawn(function()
    local combatToken = State.CombatToken
    while State.CombatToken == combatToken do
        task.wait(isFarmActive() and 0.05 or 0.25)
        pcall(Combat.tick)
        pcall(BossFarm.scanSoldierKills)
        pcall(Extras.recordMobSpawns)
    end
end)

local function getMobAnchor(mobName)
    if not mobName then
        return nil
    end

    local cached = mobAnchorCache[mobName]
    if cached and cached.Parent then
        return cached
    end

    local strippedMob = stripBossTag(mobName)
    local rootPart = getRoot()
    local origin = (rootPart and rootPart.Position) or Vector3.zero

    local liveEnemy = getTargetEnemy(mobName, origin, true)
    if liveEnemy then
        return liveEnemy
    end

    local direct = findNPCByName(mobName) or findNPCByName(strippedMob)
    if direct then
        mobAnchorCache[mobName] = direct
        return direct
    end

    local normalizedMob = normalizeName(strippedMob)
    local questName = questAnchorByMob[normalizedMob]

    if not questName and #normalizedMob > 3 then
        for key, candidateQuest in pairs(questAnchorByMob) do
            if string.find(key, normalizedMob, 1, true) == 1 or string.find(normalizedMob, key, 1, true) == 1 then
                questName = candidateQuest
                break
            end
        end
    end

    if questName then
        local npc = getQuestNPC(questName)
        if npc then
            mobAnchorCache[mobName] = npc
            return npc
        end
    end

    local summonItem = summonEntryByName[normalizedMob]
    if summonItem and summonItem.NPC then
        local summonNPC = findNPCByName(summonItem.NPC)
        if summonNPC then
            mobAnchorCache[mobName] = summonNPC
            return summonNPC
        end
    end

    local trimmedMob = string.gsub(normalizedMob, "ancient", "")
    if #trimmedMob > 5 then
        for _, child in ipairs(workspaceService:GetChildren()) do
            local normalizedChild = normalizeName(child.Name)
            if #normalizedChild > 4 and (string.find(normalizedChild, trimmedMob, 1, true) or string.find(trimmedMob, normalizedChild, 1, true)) then
                if child:IsA("Model") or child:IsA("BasePart") then
                    return child
                end
                local descendantPart = child:FindFirstChildWhichIsA("BasePart", true)
                if descendantPart then
                    return descendantPart
                end
            end
        end
    end

    for dialogueKey in pairs(dialogueData) do
        if string.find(dialogueKey, "^Quest%s") then
            local normalizedKey = normalizeName(string.gsub(dialogueKey, "^Quest%s*", ""))
            if #normalizedKey > 3 and (string.find(normalizedKey, normalizedMob, 1, true) == 1 or string.find(normalizedMob, normalizedKey, 1, true) == 1) then
                local npc = getQuestNPC(dialogueKey)
                if npc then
                    mobAnchorCache[mobName] = npc
                    return npc
                end
            end
        end
    end

    return nil
end

local function farmMobWithAnchor(mobName, isActiveCondition, allowBoss)
    local rootPart = getRoot()
    if not rootPart or not mobName then
        return false
    end

    if not getTargetEnemy(mobName, rootPart.Position, allowBoss) then
        if lastKnownMobCFrame and (lastKnownMobCFrame.Position - rootPart.Position).Magnitude <= 400 then
            engageMob(mobName, isActiveCondition, allowBoss)
            return true
        end

        local anchor = getMobAnchor(mobName)
        if not anchor then
            setFarmStatus("Cannot locate " .. mobName .. " (summon or event target)")
            task.wait(2)
            return false
        end

        lastKnownMobCFrame = nil
        setTargetBox(nil)
        lockedEnemyRoot = nil

        local anchorPivot = anchor:GetPivot()
        local arrived = safeTravelTo(anchorPivot * CFrame.new(0, 0, 8), function()
            local currentRoot = getRoot()
            return isActiveCondition() and currentRoot ~= nil and getTargetEnemy(mobName, currentRoot.Position, allowBoss) == nil
        end)

        if not arrived then
            local currentRoot = getRoot()
            if not currentRoot or not getTargetEnemy(mobName, currentRoot.Position, allowBoss) then
                setFarmStatus("Movement blocked while travelling to " .. mobName)
                task.wait(2)
                return false
            end
        end
        task.wait(0.4)
    end

    engageMob(mobName, isActiveCondition, allowBoss)
    return true
end

local function executeQuestCombat(questInstance, isFarmingActiveCondition)
    farmMobWithAnchor(getTargetMobName(questInstance), isFarmingActiveCondition, false)
end

local function collectNearbyPickup(ownerName)
    if not State.AutoPickupEnabled then
        return false
    end

    local prompt = getNearestPickup(State.PickupRange or 1200)
    if not prompt then
        return false
    end

    releaseMovement(ownerName)
    local collected = collectPickup(prompt, function()
        return State.AutoPickupEnabled
    end)
    reacquireMovement(ownerName)

    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    lastKnownMobCFrame = nil

    return collected
end

local function getGateQuest(materialName)
    local hiddenQuest = grindDropSystem.HiddenUnlessQuest and grindDropSystem.HiddenUnlessQuest[materialName]
    if typeof(hiddenQuest) == "string" then
        return hiddenQuest
    end

    local gatedInfo = grindDropSystem.QuestGatedDrops and grindDropSystem.QuestGatedDrops[materialName]
    if typeof(gatedInfo) == "table" and typeof(gatedInfo.Quest) == "string" then
        return gatedInfo.Quest
    end

    return nil
end

local function pickMaterialSource(materialName, avoidSummon)
    local sourceList = materialSources[materialName]
    if not sourceList or #sourceList == 0 then
        return nil
    end

    local rootPart = getRoot()
    local origin = (rootPart and rootPart.Position) or Vector3.zero
    local aliveSource = nil
    local anchoredSource = nil
    local summonSource = nil
    local fallbackSource = nil

    for _, source in ipairs(sourceList) do
        if not source.Summon or not avoidSummon then
            fallbackSource = fallbackSource or source

            if not aliveSource and getTargetEnemy(source.Name, origin, true) then
                aliveSource = source
            end

            if source.Summon then
                summonSource = summonSource or source
            elseif not anchoredSource and getMobAnchor(source.Name) then
                anchoredSource = source
            end
        end
    end

    if avoidSummon then
        return aliveSource or anchoredSource or fallbackSource
    end

    return aliveSource or anchoredSource or summonSource or fallbackSource
end

local function buyFromMaterialShop(materialName, quantity)
    local shopEntry = materialShopIndex[materialName]
    if not shopEntry then
        return false
    end

    local cost = math.max(shopEntry.Cost, 1)
    local affordable = math.floor(getShards() / cost)
    if affordable < 1 then
        return false
    end

    local requested = math.clamp(math.floor(quantity or 1), 1, math.min(affordable, 50))
    local amountBefore = getInventoryAmount(materialName)

    invokeInput("MaterialShop", shopEntry.Index, requested)
    task.wait(0.7)

    return getInventoryAmount(materialName) > amountBefore
end

local function getMaterialPlan(materialName, avoidSummon)
    local plan = { Item = materialName, Kind = "none" }

    if findPickupByName(materialName) then
        plan.Kind = "pickup"
        return plan
    end

    local shopEntry = materialShopIndex[materialName]
    if shopEntry and getShards() >= shopEntry.Cost then
        plan.Kind = "shop"
        plan.Shop = shopEntry
        return plan
    end

    local gateQuest = getGateQuest(materialName)
    if gateQuest and not UnlockFarm.isQuestCompleted(gateQuest) then
        plan.Kind = "gate"
        plan.Quest = gateQuest
        return plan
    end

    local source = pickMaterialSource(materialName, avoidSummon)
    if source then
        plan.Mob = source.Name
        if source.Summon then
            plan.Kind = "boss"
            plan.Summon = source.Summon
        elseif getMobAnchor(source.Name) then
            plan.Kind = "mob"
        else
            plan.Kind = "event"
        end
        return plan
    end

    if unlockRecipes[materialName] then
        plan.Kind = "craft"
        plan.Recipe = unlockRecipes[materialName]
        return plan
    end

    if shopEntry then
        plan.Kind = "shopLocked"
        plan.Shop = shopEntry
    end

    return plan
end

local function describeMaterialPlan(materialName)
    local plan = getMaterialPlan(materialName)

    if plan.Kind == "pickup" then
        return "world drop nearby"
    elseif plan.Kind == "shop" then
        return "shard shop " .. tostring(plan.Shop.Cost)
    elseif plan.Kind == "shopLocked" then
        return "shard shop " .. tostring(plan.Shop.Cost) .. " (need shards)"
    elseif plan.Kind == "gate" then
        return "gate quest " .. tostring(plan.Quest)
    elseif plan.Kind == "boss" then
        return "summon boss " .. tostring(plan.Mob)
    elseif plan.Kind == "mob" then
        return "mob " .. tostring(plan.Mob)
    elseif plan.Kind == "event" then
        return "event target " .. tostring(plan.Mob) .. " (not spawned)"
    elseif plan.Kind == "craft" then
        return "craft at " .. tostring(plan.Recipe.NPC) .. " (" .. tostring(plan.Recipe.ChoiceText) .. ")"
    end

    return "no known source"
end

AutoPickup.TimedItems = { "Nothing There Egg", "Coffin", "Curse Box", "Six Eyes", "Dragon Ball", "Muzan Blood", "Ancient Infernal Core" }
AutoPickup.IgnoreUntil = {}
AutoPickup.IgnoredAt = {}
AutoPickup.NextNearbyAt = 0

for _, timedItemName in ipairs(AutoPickup.TimedItems) do
    State.PickupTargets[timedItemName] = true
end

function AutoPickup.isActive()
    return State.AutoPickupEnabled
end

function AutoPickup.findWorldItem(itemName)
    local key = normalizeName(itemName)
    local itemsFolder = extraFolder:FindFirstChild("Items")
    local model = itemsFolder and itemsFolder:FindFirstChild(itemName)
    local indicator = Extras.findItemIndicator(key)
    local ignored = (AutoPickup.IgnoreUntil[key] or 0) > os.clock()
    if indicator and (not ignored or indicator.Time > (AutoPickup.IgnoredAt[key] or 0)) then
        return { Name = itemName, Key = key, Position = indicator.Position, Model = model }
    end
    if ignored then
        return nil
    end
    local rootPart = getRoot()
    if model and rootPart and (model:GetPivot().Position - rootPart.Position).Magnitude <= 300 then
        local part = model:FindFirstChildWhichIsA("BasePart", true)
        local position = part and part.Position
        if not position then
            local ok, pivot = pcall(function()
                return model:GetPivot()
            end)
            position = ok and pivot.Position or nil
        end
        if position then
            return { Name = itemName, Key = key, Position = position, Model = model }
        end
    end
    return nil
end

AutoPickup.ItemQuest = {
    ["Muzan Blood"] = "Akaza Quest 1"
}

function AutoPickup.findTimedTarget()
    if workspaceService:GetAttribute("Dungeon") ~= nil then
        return nil
    end
    for _, itemName in ipairs(AutoPickup.TimedItems) do
        local requiredQuest = AutoPickup.ItemQuest[itemName]
        local questAllows = requiredQuest == nil or UnlockFarm.getActiveQuestFolder(requiredQuest) ~= nil
        if State.PickupTargets[itemName] and questAllows and not Extras.isItemFull(itemName) then
            if itemName == "Coffin" then
                if (AutoPickup.IgnoreUntil.coffin or 0) <= os.clock() and Extras.isCoffinAvailable() then
                    return { Name = itemName, Key = "coffin", Coffin = true }
                end
            else
                local target = AutoPickup.findWorldItem(itemName)
                if target then
                    return target
                end
            end
        end
    end
    return nil
end

function AutoPickup.findPromptNear(target)
    local itemsFolder = extraFolder:FindFirstChild("Items")
    local model = (target.Model and target.Model.Parent and target.Model) or (itemsFolder and itemsFolder:FindFirstChild(target.Name))
    if model then
        local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            return prompt, model
        end
    end
    for _, descendant in ipairs(extraFolder:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") and descendant.Enabled then
            local holder = descendant.Parent
            local position = (holder:IsA("BasePart") and holder.Position) or (holder:IsA("Attachment") and holder.WorldPosition) or nil
            if position and (position - target.Position).Magnitude < 25 then
                return descendant, model
            end
        end
    end
    return nil, model
end

function AutoPickup.collectWorldItem(target)
    local amountBefore = getInventoryAmount(target.Name)
    local function stillMissing()
        return State.AutoPickupEnabled and getInventoryAmount(target.Name) <= amountBefore
    end

    Extras.clearCombatLocks()
    State.ExtraStatus = "Pickup: " .. target.Name .. " spawned | flying to it"
    safeTravelTo(CFrame.new(target.Position + Vector3.new(0, 4, 4)), stillMissing)

    local prompt, model = nil, nil
    local deadline = os.clock() + 6
    while stillMissing() and os.clock() < deadline do
        prompt, model = AutoPickup.findPromptNear(target)
        if prompt then
            break
        end
        task.wait(0.3)
    end

    if prompt then
        local holder = prompt.Parent
        local promptPosition = (holder:IsA("BasePart") and holder.Position) or (holder:IsA("Attachment") and holder.WorldPosition) or target.Position
        State.ExtraStatus = "Pickup: collecting " .. target.Name
        travelTo(CFrame.new(promptPosition + Vector3.new(0, 2, 3)), stillMissing)
        settleCharacter()
        for _ = 1, 4 do
            if not stillMissing() or not prompt.Parent then
                break
            end
            triggerPrompt(prompt)
            task.wait(0.6)
        end
    elseif model then
        local part = model:FindFirstChildWhichIsA("BasePart", true)
        local rootPart = getRoot()
        if part and rootPart then
            holdPosition(part.CFrame * CFrame.new(0, 2, 0))
            pcall(function()
                firetouchinterest(rootPart, part, 0)
                task.wait(0.1)
                firetouchinterest(rootPart, part, 1)
            end)
            task.wait(1)
        end
    end

    if getInventoryAmount(target.Name) > amountBefore then
        State.ExtraStatus = "Pickup: collected " .. target.Name
        Extras.forgetItemIndicator(target.Key)
        return true
    end

    local rootPart = getRoot()
    local arrived = rootPart ~= nil and (rootPart.Position - target.Position).Magnitude < 60
    if arrived and not prompt then
        Extras.forgetItemIndicator(target.Key)
        AutoPickup.IgnoreUntil[target.Key] = os.clock() + 900
        AutoPickup.IgnoredAt[target.Key] = os.clock()
        State.ExtraStatus = "Pickup: " .. target.Name .. " was already gone"
    else
        local tripAborted = os.clock() - (Extras.RevertWatch.TripAbortedAt or -math.huge) < 15
        AutoPickup.IgnoreUntil[target.Key] = os.clock() + ((prompt or tripAborted) and 300 or 20)
        AutoPickup.IgnoredAt[target.Key] = os.clock()
        State.ExtraStatus = "Pickup: could not collect " .. target.Name .. " | " .. tostring(State.LastNotifyText)
    end
    return false
end

function Extras.resetCharacter()
    local oldCharacter = localPlayer.Character
    local oldHumanoid = oldCharacter and oldCharacter:FindFirstChildOfClass("Humanoid")
    if not oldHumanoid or oldHumanoid.Health <= 0 then
        return false
    end
    stopTween()
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    setTargetBox(nil)
    pcall(function()
        oldHumanoid.Health = 0
    end)
    local deadline = os.clock() + 15
    while os.clock() < deadline do
        local newCharacter = localPlayer.Character
        local newRoot = newCharacter and newCharacter ~= oldCharacter and newCharacter:FindFirstChild("HumanoidRootPart")
        local newHumanoid = newRoot and newCharacter:FindFirstChildOfClass("Humanoid")
        if newHumanoid and newHumanoid.Health > 0 then
            task.wait(0.5)
            return true
        end
        task.wait(0.2)
    end
    return false
end

Extras.StuckWatch = { Position = nil, Since = os.clock(), Seconds = 25 }

function Extras.getFightTarget()
    if lockedEnemyRoot and lockedEnemyRoot.Parent then
        return lockedEnemyRoot
    end
    if Combat.ApproachRoot and Combat.ApproachRoot.Parent then
        return Combat.ApproachRoot
    end
    if State.AutoSolemnEnabled then
        local boss = enemiesFolder:FindFirstChild(Extras.Solemn.BossName)
        local bossRoot = boss and boss:FindFirstChild("HumanoidRootPart")
        local bossHumanoid = boss and boss:FindFirstChildOfClass("Humanoid")
        if bossRoot and bossHumanoid and bossHumanoid.Health > 0 then
            return bossRoot
        end
    end
    if State.AutoBankaiEnabled then
        for _, bossName in ipairs({ Extras.Bankai.TitleBoss, Extras.Bankai.RedMistName }) do
            local boss = enemiesFolder:FindFirstChild(bossName)
            local bossRoot = boss and boss:FindFirstChild("HumanoidRootPart")
            local bossHumanoid = boss and boss:FindFirstChildOfClass("Humanoid")
            if bossRoot and bossHumanoid and bossHumanoid.Health > 0 then
                return bossRoot
            end
        end
    end
    return nil
end

function Extras.checkStuck()
    local watch = Extras.StuckWatch
    local now = os.clock()
    local rootPart, playerHumanoid = getRoot()
    local target = Extras.getFightTarget()
    local excused = not rootPart or not playerHumanoid or playerHumanoid.Health <= 0 or not target
        or pickupActive or (Extras.PriorityRequest ~= nil and Extras.PriorityRequest ~= "twoh" and Extras.PriorityRequest ~= "yhwach") or Extras.isMovementBlocked()
        or Extras.isCarryingCoffin() or not isFarmActive()
    if excused or (rootPart.Position - target.Position).Magnitude <= 45 or (rootPart.Position - target.Position).Magnitude > 1000 then
        watch.Position = rootPart and rootPart.Position
        watch.Since = now
        return
    end
    if not watch.Position or (rootPart.Position - watch.Position).Magnitude > 5 then
        watch.Position = rootPart.Position
        watch.Since = now
        return
    end
    if now - watch.Since >= watch.Seconds then
        watch.Since = now
        watch.Position = nil
        State.ExtraStatus = string.format("Stuck %ds, %d studs from the target | resetting the character", watch.Seconds, math.floor((rootPart.Position - target.Position).Magnitude))
        Extras.resetCharacter()
    end
end

getgenv().HubStuckToken = {}
task.spawn(function()
    local stuckToken = getgenv().HubStuckToken
    while getgenv().HubStuckToken == stuckToken do
        pcall(Extras.checkStuck)
        task.wait(1)
    end
end)

function AutoPickup.shedCombat(target)
    local playerCharacter = localPlayer.Character
    if not playerCharacter or not playerCharacter:FindFirstChild("InCombat") then
        return
    end
    if Extras.isCarryingCoffin() then
        return
    end
    local rootPart = getRoot()
    local targetPosition = target.Position or (target.Coffin and Extras.findCoffinModelPosition())
    if rootPart and targetPosition and (rootPart.Position - targetPosition).Magnitude < 300 then
        return
    end
    State.ExtraStatus = "Pickup: " .. target.Name .. " spawned | resetting to drop In Combat"
    Extras.resetCharacter()
end

function AutoPickup.shouldFinishFight(target)
    if target.Coffin and Extras.isCarryingCoffin() then
        return false
    end
    local playerCharacter = localPlayer.Character
    if not playerCharacter or not playerCharacter:FindFirstChild("InCombat") then
        return false
    end
    local rootPart = getRoot()
    local fightTarget = Extras.getFightTarget()
    if not rootPart or not fightTarget then
        return false
    end
    local enemyModel = fightTarget.Parent
    local enemyHumanoid = enemyModel and enemyModel:FindFirstChildOfClass("Humanoid")
    if not enemyHumanoid or enemyHumanoid.Health <= 0 then
        return false
    end
    return (fightTarget.Position - rootPart.Position).Magnitude <= 1000
end

function AutoPickup.handleTimed(target)
    Extras.PriorityRequest = "pickupevent"
    local startedAt = os.clock()
    while State.AutoPickupEnabled and not acquireMovement("pickupevent") do
        State.ExtraStatus = "Pickup: " .. target.Name .. " spawned | taking over from " .. tostring(movementOwner)
        if os.clock() - startedAt > 20 then
            stopTween()
            movementOwner = nil
        end
        task.wait(0.2)
    end

    if State.AutoPickupEnabled then
        pickupActive = true
        local ok, errorMessage = pcall(function()
            AutoPickup.shedCombat(target)
            if target.Coffin then
                local delivered = Extras.runCoffinStep(AutoPickup.isActive)
                if not delivered and not Extras.isCarryingCoffin() then
                    AutoPickup.IgnoreUntil.coffin = os.clock() + 60
                end
            else
                AutoPickup.collectWorldItem(target)
            end
        end)
        if not ok then
            State.ExtraStatus = "Pickup error: " .. tostring(errorMessage)
        end
        pickupActive = false
        lockedTargetCFrame = nil
        releaseMovement("pickupevent")
    end

    if Extras.PriorityRequest == "pickupevent" then
        Extras.PriorityRequest = nil
    end
end

function AutoPickup.Start()
    if State.AutoPickupEnabled then
        return
    end

    State.AutoPickupEnabled = true
    Extras.connectItemIndicators()
    Extras.watchCoffins()

    AutoPickup.Thread = task.spawn(function()
        while State.AutoPickupEnabled do
            task.wait(0.5)

            local _, playerHumanoid = getRoot()
            if playerHumanoid and playerHumanoid.Health > 0 then
                local target = AutoPickup.findTimedTarget()
                if target and AutoPickup.shouldFinishFight(target) then
                    AutoPickup.WaitingFor = target.Name
                elseif target then
                    AutoPickup.WaitingFor = nil
                    AutoPickup.handleTimed(target)
                else
                    if Extras.PriorityRequest == "pickupevent" then
                        Extras.PriorityRequest = nil
                    end
                    local otherLoopRunning = isFarmActive() or movementOwner ~= nil
                    if not otherLoopRunning and os.clock() >= AutoPickup.NextNearbyAt then
                        AutoPickup.NextNearbyAt = os.clock() + 1.5
                        local prompt = getNearestPickup(State.PickupRange or 1200)
                        if prompt then
                            collectPickup(prompt, AutoPickup.isActive)
                        end
                    end
                end
            end
        end
        if Extras.PriorityRequest == "pickupevent" then
            Extras.PriorityRequest = nil
        end
    end)
end

function AutoPickup.Stop()
    State.AutoPickupEnabled = false
    pickupActive = false
    if Extras.PriorityRequest == "pickupevent" then
        Extras.PriorityRequest = nil
    end
end

AutoCode.FallbackList = {
    "UPDATE2.1!!",
    "UPD2.05!!",
    "SORRYFORBUGS18!!",
    "SORRYFORDELAY8!!",
    "THANKSFOR17KCCU!!",
    "THANKSFOR16KCCU!!"
}
AutoCode.Thread = nil

function AutoCode.getRedeemedCodes()
    local dataFolder = localPlayer:FindFirstChild("Data")
    local codesValue = dataFolder and dataFolder:FindFirstChild("Codes")
    if not codesValue or codesValue.Value == "" then
        return {}
    end
    local success, decoded = pcall(function()
        return httpService:JSONDecode(codesValue.Value)
    end)
    if success and typeof(decoded) == "table" then
        return decoded
    end
    return {}
end

function AutoCode.isCodeRedeemed(code)
    if not code then
        return true
    end
    return AutoCode.getRedeemedCodes()[string.lower(code)] == true
end

function AutoCode.redeemCode(code)
    if AutoCode.isCodeRedeemed(code) then
        return "Already Used"
    end
    local success, result = invokeInput("Code", code)
    if success then
        return result
    end
    return "Error"
end

function AutoCode.getGuidebookCodes()
    local codes = {}
    local seen = {}
    pcall(function()
        local providers = require(replicatedStorage:WaitForChild("Modules"):WaitForChild("GUI"):WaitForChild("GuidebookProviders"))
        if providers and typeof(providers.CatalogRows) == "function" and getupvalues then
            local uvs = getupvalues(providers.CatalogRows)
            for _, fn in pairs(uvs) do
                if typeof(fn) == "function" then
                    local consts = (getconstants and getconstants(fn)) or {}
                    local isCodeProvider = false
                    for _, c in pairs(consts) do
                        if c == "CodeResults" or c == "REDEEMED" then
                            isCodeProvider = true
                            break
                        end
                    end
                    if isCodeProvider then
                        local rows = fn()
                        if typeof(rows) == "table" then
                            for _, item in ipairs(rows) do
                                local codeName = item.Title or item.Key or item.Name
                                if typeof(codeName) == "string" and #codeName > 0 and not seen[string.lower(codeName)] then
                                    seen[string.lower(codeName)] = true
                                    table.insert(codes, {
                                        Code = codeName,
                                        Redeemed = item.Has == true or item.Status == "REDEEMED" or AutoCode.isCodeRedeemed(codeName)
                                    })
                                end
                            end
                        end
                        if #codes > 0 then
                            return
                        end
                    end
                end
            end
        end
    end)
    if #codes == 0 then
        pcall(function()
            local providers = require(replicatedStorage:WaitForChild("Modules"):WaitForChild("GUI"):WaitForChild("GuidebookProviders"))
            if providers and getupvalues then
                local uvs = getupvalues(providers.CatalogRows)
                for _, fn in pairs(uvs) do
                    if typeof(fn) == "function" then
                        local fnUvs = getupvalues(fn)
                        for _, uv in pairs(fnUvs) do
                            if typeof(uv) == "table" and uv.Codes and typeof(uv.Codes) == "table" then
                                for rawCode, info in pairs(uv.Codes) do
                                    local codeStr = tostring(rawCode)
                                    if not seen[string.lower(codeStr)] then
                                        local isCreator = typeof(info) == "table" and info.ContentCreatorOnly == true
                                        if not isCreator then
                                            seen[string.lower(codeStr)] = true
                                            table.insert(codes, {
                                                Code = codeStr,
                                                Redeemed = AutoCode.isCodeRedeemed(codeStr)
                                            })
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
    if #codes == 0 then
        pcall(function()
            local pg = localPlayer:FindFirstChild("PlayerGui")
            local gbGui = pg and pg:FindFirstChild("Guidebook")
            if gbGui then
                for _, desc in ipairs(gbGui:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Name == "Label" and desc.Parent and desc.Parent.Name == "CatalogRow" then
                        local txt = desc.Text
                        if typeof(txt) == "string" and #txt > 0 and not seen[string.lower(txt)] then
                            seen[string.lower(txt)] = true
                            table.insert(codes, {
                                Code = txt,
                                Redeemed = AutoCode.isCodeRedeemed(txt)
                            })
                        end
                    end
                end
            end
        end)
    end
    for _, fallbackCode in ipairs(AutoCode.FallbackList or {}) do
        if not seen[string.lower(fallbackCode)] then
            seen[string.lower(fallbackCode)] = true
            table.insert(codes, {
                Code = fallbackCode,
                Redeemed = AutoCode.isCodeRedeemed(fallbackCode)
            })
        end
    end
    return codes
end

function AutoCode.redeemAll()
    local unredeemedCount = 0
    local entries = AutoCode.getGuidebookCodes()
    for _, entry in ipairs(entries) do
        local code = entry.Code
        if not entry.Redeemed and not AutoCode.isCodeRedeemed(code) then
            unredeemedCount = unredeemedCount + 1
            AutoCode.redeemCode(code)
            task.wait(0.6)
        end
    end
    return unredeemedCount
end

function AutoCode.Start()
    if State.AutoCodeEnabled then
        return
    end
    State.AutoCodeEnabled = true
    AutoCode.Thread = task.spawn(function()
        while State.AutoCodeEnabled do
            AutoCode.redeemAll()
            task.wait(45)
        end
    end)
end

function AutoCode.Stop()
    State.AutoCodeEnabled = false
    if AutoCode.Thread then
        task.cancel(AutoCode.Thread)
        AutoCode.Thread = nil
    end
end

AutoChest.Thread = nil
AutoChest.RetryAt = {}
AutoChest.TotalOpened = 0

function AutoChest.getCatalog()
    local list = {}
    for itemName, itemInfo in pairs(itemData) do
        if typeof(itemInfo) == "table" and itemInfo.Type == "Item" and (string.find(itemName, "Chest", 1, true) or string.find(itemName, "Crate", 1, true)) then
            table.insert(list, itemName)
        end
    end
    table.sort(list)
    return list
end

function AutoChest.getSelected()
    local selected = {}
    for chestName, enabled in pairs(State.ChestSelection) do
        if enabled then
            table.insert(selected, chestName)
        end
    end
    table.sort(selected)
    return selected
end

function AutoChest.openChest(chestName)
    local owned = getInventoryAmount(chestName)
    if owned <= 0 then
        return 0
    end

    local useRemote = remotesFolder:FindFirstChild("RE_UseItem")
    if not useRemote then
        State.ChestStatus = "RE_UseItem remote not found"
        return 0
    end

    local batchSize = 1
    if string.find(chestName, "Chest", 1, true) then
        batchSize = math.floor(math.min(owned, 1000))
    end

    for _ = 1, 15 do
        local sentAt = os.clock()
        pcall(function()
            useRemote:FireServer(chestName, batchSize, 0)
        end)

        local refused = false
        local deadline = os.clock() + math.clamp(3 + batchSize * 0.01, 3, 12)
        while os.clock() < deadline and getInventoryAmount(chestName) >= owned do
            task.wait(0.05)
            if (State.LastNotifyTime or 0) >= sentAt and string.find(string.lower(tostring(State.LastNotifyText)), "cannot use items", 1, true) then
                refused = true
                break
            end
        end

        local opened = math.max(owned - getInventoryAmount(chestName), 0)
        if opened > 0 or not refused then
            return opened
        end
        State.ChestStatus = chestName .. " | busy with a skill, retrying"
        task.wait(0.3)
    end

    return 0
end

function AutoChest.Start()
    if State.AutoChestEnabled then
        return
    end

    State.AutoChestEnabled = true
    AutoChest.RetryAt = {}

    AutoChest.Thread = task.spawn(function()
        while State.AutoChestEnabled do
            local openedAny = false

            for _, chestName in ipairs(AutoChest.getSelected()) do
                if not State.AutoChestEnabled then
                    break
                end

                local owned = getInventoryAmount(chestName)
                if owned > 0 and os.clock() >= (AutoChest.RetryAt[chestName] or 0) then
                    State.ChestStatus = "Opening " .. chestName .. " (" .. tostring(math.floor(owned)) .. " left)"
                    local opened = AutoChest.openChest(chestName)
                    if opened > 0 then
                        openedAny = true
                        AutoChest.TotalOpened = AutoChest.TotalOpened + opened
                    else
                        AutoChest.RetryAt[chestName] = os.clock() + 5
                        State.ChestStatus = chestName .. " not opened | " .. tostring(State.LastNotifyText)
                    end
                    task.wait(0.5)
                end
            end

            if not openedAny then
                if #AutoChest.getSelected() == 0 then
                    State.ChestStatus = "No chest selected"
                else
                    State.ChestStatus = "Waiting for selected chests | opened " .. tostring(AutoChest.TotalOpened)
                end
                task.wait(2)
            end
        end
    end)
end

function AutoChest.Stop()
    State.AutoChestEnabled = false
    State.ChestStatus = "Idle"
    if AutoChest.Thread then
        task.cancel(AutoChest.Thread)
        AutoChest.Thread = nil
    end
end

Extras.Threads = {}
Extras.CoffinCandidates = {}
Extras.TraitByLabel = {}
Extras.DungeonFolder = "LEGACY PIECE"
Extras.DungeonSettingsPath = "LEGACY PIECE/dungeon_settings.json"
Extras.DungeonHelperPath = "LEGACY PIECE/dungeon_helper.luau"
Extras.DungeonDifficulties = { "Easy", "Medium", "Hard", "Extreme" }
Extras.DungeonHelperSource = [==[
local replicatedStorage = game:GetService("ReplicatedStorage")
local httpService = game:GetService("HttpService")
local settingsPath = "LEGACY PIECE/dungeon_settings.json"
local helperLoader = 'loadstring(readfile("LEGACY PIECE/dungeon_helper.luau"))()'

local function readSettings()
    local ok, decoded = pcall(function()
        return httpService:JSONDecode(readfile(settingsPath))
    end)
    if ok and typeof(decoded) == "table" then
        return decoded
    end
    return {}
end

if getgenv().HubDungeonConnection then
    pcall(function()
        getgenv().HubDungeonConnection:Disconnect()
    end)
    getgenv().HubDungeonConnection = nil
end

local startSettings = readSettings()
if not startSettings.AutoDifficulty and not startSettings.AutoReplay then
    return
end

pcall(function()
    queue_on_teleport(helperLoader)
end)

local remotes = replicatedStorage:WaitForChild("Remotes", 30)
local events = remotes and remotes:WaitForChild("Events", 30)
local syncRemote = events and events:WaitForChild("DungeonInsideSync", 30)
if not syncRemote then
    return
end

local lastStatus = nil
getgenv().HubDungeonConnection = syncRemote.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" or payload.Type ~= "State" then
        return
    end

    local status = payload.Status
    if status == lastStatus then
        return
    end
    lastStatus = status

    local settings = readSettings()
    if status == "Vote" and settings.AutoDifficulty then
        task.delay(1, function()
            pcall(function()
                syncRemote:FireServer("Vote", settings.Difficulty or "Hard")
            end)
        end)
    elseif (status == "Clear" or status == "Lose") and settings.AutoReplay then
        task.delay(3, function()
            pcall(function()
                syncRemote:FireServer("ReplayVote")
            end)
        end)
    end
end)
]==]

function Extras.loadDungeonSettings()
    pcall(function()
        local decoded = httpService:JSONDecode(readfile(Extras.DungeonSettingsPath))
        if typeof(decoded) == "table" then
            State.DungeonAutoDifficulty = decoded.AutoDifficulty == true
            State.DungeonAutoReplay = decoded.AutoReplay == true
            if typeof(decoded.Difficulty) == "string" then
                State.DungeonDifficulty = decoded.Difficulty
            end
        end
    end)
end

function Extras.saveDungeonSettings()
    local saved = pcall(function()
        if not isfolder(Extras.DungeonFolder) then
            makefolder(Extras.DungeonFolder)
        end
        writefile(Extras.DungeonSettingsPath, httpService:JSONEncode({
            AutoDifficulty = State.DungeonAutoDifficulty,
            Difficulty = State.DungeonDifficulty,
            AutoReplay = State.DungeonAutoReplay
        }))
        writefile(Extras.DungeonHelperPath, Extras.DungeonHelperSource)
    end)

    if not saved then
        State.ExtraStatus = "Dungeon: cannot write settings file"
        return
    end

    pcall(function()
        loadstring(Extras.DungeonHelperSource)()
    end)

    if State.DungeonAutoDifficulty or State.DungeonAutoReplay then
        State.ExtraStatus = "Dungeon: helper armed (" .. tostring(State.DungeonDifficulty) .. ")"
    else
        State.ExtraStatus = "Dungeon: helper off"
    end
end

Extras.GoldShopPosition = Vector3.new(-8.7, 15.2, -9.8)

function Extras.buyBossTickets(amount)
    local goldShopRemote = eventsFolder and eventsFolder:FindFirstChild("GoldShopBuy")
    if not goldShopRemote then
        return false
    end

    local ticketCost = 30000
    pcall(function()
        local goldShopData = require(configurationsFolder:FindFirstChild("GoldShopData"))
        ticketCost = goldShopData.ByName["Boss Ticket"].Cost or ticketCost
    end)

    local quantity = math.min(math.max(math.ceil(amount), 1), 999, math.floor(getMoney() / ticketCost))
    if quantity < 1 then
        setFarmStatus("Boss Ticket | not enough money")
        return false
    end

    local ticketsBefore = getInventoryAmount("Boss Ticket")
    local shopPosition = Extras.getNPCWorldPosition("Gold Shop", Extras.GoldShopPosition)
    for attempt = 1, 2 do
        local rootPart = getRoot()
        if rootPart and (rootPart.Position - shopPosition).Magnitude > 40 then
            setFarmStatus(string.format("flying to the Gold Shop to buy %d Boss Ticket", quantity))
            Extras.clearCombatLocks()
            safeTravelTo(CFrame.new(shopPosition + Vector3.new(0, 3, 8)), function()
                return isFarmActive()
            end)
        end
        waitForCombatClear(3)
        setFarmStatus("Buying " .. tostring(quantity) .. " Boss Ticket at the Gold Shop")
        pcall(function()
            goldShopRemote:FireServer("Boss Ticket", quantity)
        end)

        local deadline = os.clock() + 3
        while os.clock() < deadline and getInventoryAmount("Boss Ticket") <= ticketsBefore do
            task.wait(0.1)
        end
        if getInventoryAmount("Boss Ticket") > ticketsBefore then
            return true
        end
    end

    setFarmStatus("Boss Ticket purchase refused by the Gold Shop")
    task.wait(2)
    return false
end

function Extras.startLoop(flagName, cycle)
    if State[flagName] then
        return
    end

    State[flagName] = true
    Extras.Threads[flagName] = task.spawn(function()
        while State[flagName] do
            local ok, errorMessage = pcall(cycle)
            if not ok then
                State.ExtraStatus = "Error: " .. tostring(errorMessage)
                task.wait(1)
            end
            task.wait(0.2)
        end
    end)
end

function Extras.stopLoop(flagName, ownerName)
    State[flagName] = false
    local thread = Extras.Threads[flagName]
    Extras.Threads[flagName] = nil
    if thread and thread ~= coroutine.running() then
        local cancelled = pcall(task.cancel, thread)
        if cancelled and travelActive then
            travelActive = false
            stopTween()
        end
    end
    if ownerName and movementOwner == ownerName then
        stopTween()
        Combat.ApproachRoot = nil
        lockedEnemyRoot = nil
        lockedTargetCFrame = nil
        setTargetBox(nil)
        releaseMovement(ownerName)
    end
end

function Extras.syncToggle(toggleName, value)
    local toggle = UIController[toggleName]
    if not toggle then
        return
    end
    UIController.IsSyncingUI = true
    pcall(function()
        toggle:UpdateState(value)
    end)
    UIController.IsSyncingUI = false
end

function Extras.getTraitOptions()
    local okConfig, traitConfig = pcall(require, replicatedStorage.Modules.TraitConfig)
    if not okConfig or typeof(traitConfig) ~= "table" or typeof(traitConfig.Traits) ~= "table" then
        return {}
    end

    local rarityRank = {}
    for index, rarityName in ipairs(traitConfig.RarityOrder or {}) do
        rarityRank[rarityName] = index
    end

    local traitNames = {}
    for traitName in pairs(traitConfig.Traits) do
        table.insert(traitNames, traitName)
    end
    table.sort(traitNames, function(first, second)
        local firstRank = rarityRank[traitConfig.Traits[first].Rarity] or 99
        local secondRank = rarityRank[traitConfig.Traits[second].Rarity] or 99
        if firstRank ~= secondRank then
            return firstRank < secondRank
        end
        return first < second
    end)

    local labels = {}
    for _, traitName in ipairs(traitNames) do
        local label = "[" .. tostring(traitConfig.Traits[traitName].Rarity) .. "] " .. traitName
        table.insert(labels, label)
        Extras.TraitByLabel[label] = traitName
    end
    return labels
end

function Extras.getCurrentTrait()
    local dataFolder = localPlayer:FindFirstChild("Data")
    local traitValue = dataFolder and dataFolder:FindFirstChild("Trait")
    return traitValue and tostring(traitValue.Value) or ""
end

function Extras.rollTrait()
    local rerollRemote = remotesFolder:FindFirstChild("TraitReroll")
    if not rerollRemote then
        return nil
    end

    local finished = false
    local result = nil
    task.spawn(function()
        local ok, value = pcall(function()
            return rerollRemote:InvokeServer()
        end)
        if ok then
            result = value
        end
        finished = true
    end)

    local deadline = os.clock() + 6
    while not finished and os.clock() < deadline do
        task.wait(0.05)
    end
    return result
end

function Extras.runTraitCycle()
    local currentTrait = Extras.getCurrentTrait()
    local rerollsLeft = getInventoryAmount("Trait Reroll")

    if next(State.TraitTargets) == nil then
        State.ExtraStatus = "Trait: select target traits"
        task.wait(1)
        return
    end

    if State.TraitTargets[currentTrait] then
        State.ExtraStatus = "Trait: have " .. currentTrait .. " | stopped"
        Extras.stopLoop("AutoTraitEnabled")
        Extras.syncToggle("TraitToggle", false)
        return
    end

    if rerollsLeft <= 0 then
        State.ExtraStatus = "Trait: no Trait Reroll left | stopped"
        Extras.stopLoop("AutoTraitEnabled")
        Extras.syncToggle("TraitToggle", false)
        return
    end

    local result = Extras.rollTrait()
    Extras.TraitRolls = (Extras.TraitRolls or 0) + 1

    if typeof(result) == "table" and result.Error then
        State.ExtraStatus = "Trait: " .. tostring(result.Error)
        task.wait(1)
        return
    end

    local rolledTrait = typeof(result) == "table" and tostring(result.RolledTrait or result.Trait or "") or ""
    if rolledTrait ~= "" and State.TraitTargets[rolledTrait] then
        State.ExtraStatus = "Trait: rolled " .. rolledTrait .. " after " .. tostring(Extras.TraitRolls) .. " rolls | stopped"
        Extras.stopLoop("AutoTraitEnabled")
        Extras.syncToggle("TraitToggle", false)
        return
    end

    State.ExtraStatus = string.format("Trait: %s | %d rolls | %d left", rolledTrait ~= "" and rolledTrait or Extras.getCurrentTrait(), Extras.TraitRolls, math.max(rerollsLeft - 1, 0))
    task.wait(0.1)
end

function Extras.findWhaleIndicator()
    for _, child in ipairs(workspaceService:GetChildren()) do
        if child:IsA("BasePart") and string.sub(child.Name, 1, 15) == "WhaleIndicator_" then
            return child
        end
    end
    return nil
end

function Extras.equipFishingRod()
    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not humanoid then
        return false
    end

    local rodNames = {}
    pcall(function()
        rodNames = require(configurationsFolder:FindFirstChild("FishingRodData"))
    end)

    local function isRod(tool)
        return tool:IsA("Tool") and ((typeof(rodNames) == "table" and rodNames[tool.Name] ~= nil) or string.find(tool.Name, "Rod", 1, true) ~= nil)
    end

    for _, tool in ipairs(character:GetChildren()) do
        if isRod(tool) then
            return true
        end
    end

    local backpack = localPlayer:FindFirstChild("Backpack")
    for _, tool in ipairs(backpack and backpack:GetChildren() or {}) do
        if isRod(tool) then
            humanoid:EquipTool(tool)
            return true
        end
    end

    return false
end

function Extras.hasFishingLicense()
    local dataFolder = localPlayer:FindFirstChild("Data")
    local passes = dataFolder and dataFolder:FindFirstChild("Passes")
    local license = passes and passes:FindFirstChild("Fishing License")
    return license ~= nil and license.Value == true
end

function Extras.endWhaleEvent()
    if Extras.WhaleActive then
        Extras.WhaleActive = false
        lockedTargetCFrame = nil
        if Extras.WhaleFishing then
            Extras.WhaleFishing = false
            if not State.AutoFishEnabled and not Extras.DeepsharkFishing then
                Extras.stopFishing()
            end
        end
        releaseMovement("whale")
    end
    Extras.WhaleWaitSince = nil
    if Extras.PriorityRequest == "whale" then
        Extras.PriorityRequest = nil
    end
end

function Extras.runWhaleCycle()
    local indicator = Extras.findWhaleIndicator()
    if not indicator or Extras.PriorityRequest == "pickupevent" then
        Extras.endWhaleEvent()
        if not Extras.otherFarmActive() or not State.AutoFishEnabled then
            State.ExtraStatus = indicator and "Whale: paused while Auto Pickup collects an item" or "Whale: waiting for the whale event"
        end
        task.wait(indicator and 0.5 or 2)
        return
    end

    if not State.AutoFishEnabled then
        Extras.endWhaleEvent()
        State.ExtraStatus = "Whale: event is up | turn on Auto Fishing too (Whale sends Auto Fishing to the whale)"
        task.wait(2)
        return
    end

    if not Extras.PriorityRequest then
        Extras.PriorityRequest = "whale"
    end
    if not acquireMovement("whale") then
        Extras.WhaleWaitSince = Extras.WhaleWaitSince or os.clock()
        if os.clock() - Extras.WhaleWaitSince > 8 and Extras.PriorityRequest ~= "twoh" then
            stopTween()
            movementOwner = nil
        end
        State.ExtraStatus = "Whale: whale spawned | taking over from " .. tostring(movementOwner)
        task.wait(0.3)
        return
    end
    Extras.WhaleWaitSince = nil

    Extras.WhaleActive = true
    local hoverCFrame = CFrame.new(indicator.Position + Vector3.new(40, 6, 0))
    local rootPart = getRoot()
    if rootPart and (hoverCFrame.Position - rootPart.Position).Magnitude > 30 then
        Extras.clearCombatLocks()
        State.ExtraStatus = "Whale: flying to the whale"
        safeTravelTo(hoverCFrame, function()
            return State.AutoWhaleEnabled and indicator.Parent ~= nil and Extras.PriorityRequest ~= "pickupevent"
        end)
    end
    lockedTargetCFrame = hoverCFrame

    if State.AutoFishEnabled then
        State.ExtraStatus = "Whale: at the whale | Auto Fishing (Fast) is casting | " .. tostring(State.FishStatus)
        task.wait(1)
        return
    end

    Extras.WhaleFishing = true
    State.ExtraStatus = "Whale: fishing at the whale | " .. tostring(State.FishStatus)
    Extras.runFishingCycle()
    State.ExtraStatus = "Whale: fishing at the whale | " .. tostring(State.FishStatus)
end

Extras.Fishing = {
    CastPower = 0.78,
    ShakeInterval = 0.1,
    ReelMargin = 0.15,
    Caught = 0,
    Missed = 0,
    StartedAt = 0,
    Rejects = 0
}

function Extras.isFishingActive()
    return State.AutoFishEnabled or (State.AutoDeepsharkEnabled and Extras.DeepsharkFishing == true) or (State.AutoWhaleEnabled and Extras.WhaleFishing == true and Extras.PriorityRequest ~= "pickupevent") or (Extras.TwohFishing == true and Extras.Twoh.isActive())
end

function Extras.getFishingRemote()
    local remote = remotesFolder:FindFirstChild("RE_FishingMinigame")
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    return nil
end

function Extras.findFishingAim(preferredPoint)
    local rootPart = getRoot()
    local character = localPlayer.Character
    if not rootPart or not character then
        return nil
    end

    local fishing = Extras.Fishing
    if not preferredPoint and fishing.AimPoint and fishing.AimFrom and (fishing.AimFrom - rootPart.Position).Magnitude < 4 then
        return fishing.AimPoint
    end

    local okOcean, oceanData = pcall(require, configurationsFolder:FindFirstChild("OceanData"))
    if not okOcean or typeof(oceanData) ~= "table" then
        return nil
    end

    local ignoreList = { character }
    local extraFolder = workspaceService:FindFirstChild("Extra")
    if extraFolder then
        table.insert(ignoreList, extraFolder)
    end

    local directions = {}
    if preferredPoint then
        local towardPoint = Vector3.new(preferredPoint.X - rootPart.Position.X, 0, preferredPoint.Z - rootPart.Position.Z)
        if towardPoint.Magnitude > 1 then
            table.insert(directions, towardPoint.Unit)
        end
    end
    local flatLook = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z)
    if flatLook.Magnitude > 0.05 then
        table.insert(directions, flatLook.Unit)
    end
    for index = 0, 15 do
        table.insert(directions, CFrame.Angles(0, index * math.pi / 8, 0).LookVector)
    end

    for _, direction in ipairs(directions) do
        for _, distance in ipairs({ 55, 40, 70, 25 }) do
            local okPoint, surfacePoint = pcall(oceanData.SnapToSurface, rootPart.Position + direction * distance)
            if okPoint and typeof(surfacePoint) == "Vector3" then
                local okWater, isOpen = pcall(oceanData.IsOpenWater, surfacePoint, ignoreList)
                if okWater and isOpen then
                    fishing.AimPoint = surfacePoint
                    fishing.AimFrom = rootPart.Position
                    return surfacePoint
                end
            end
        end
    end

    return nil
end

function Extras.muteGameFishing(muted)
    local fishing = Extras.Fishing
    if muted then
        local remote = Extras.getFishingRemote()
        if fishing.MutedConnections or not remote then
            return
        end
        fishing.MutedConnections = {}
        pcall(function()
            for _, connection in ipairs(getconnections(remote.OnClientEvent)) do
                local handler = connection.Function
                local isGameHandler = handler ~= nil and not (isexecutorclosure and isexecutorclosure(handler))
                if isGameHandler then
                    connection:Disable()
                    table.insert(fishing.MutedConnections, connection)
                end
            end
        end)
        return
    end

    for _, connection in ipairs(fishing.MutedConnections or {}) do
        pcall(function()
            connection:Enable()
        end)
    end
    fishing.MutedConnections = nil
end

function Extras.connectFishing(remote)
    if getgenv().HubFishingConnection then
        return
    end

    getgenv().HubFishingConnection = remote.OnClientEvent:Connect(function(kind, ...)
        local fishing = Extras.Fishing
        local eventArgs = table.pack(...)
        if kind == "Shake" then
            fishing.ShakeReceived = true
            if typeof(eventArgs[2]) == "number" then
                fishing.Session = eventArgs[2]
                fishing.LastSession = eventArgs[2]
            end
        elseif kind == "Bite" then
            local biteSession = eventArgs[4]
            if fishing.Session and typeof(biteSession) == "number" and biteSession ~= fishing.Session then
                return
            end
            fishing.BiteAt = os.clock()
            fishing.ReelGain = math.clamp(tonumber(eventArgs[2]) or 1, 0.5, 2)
        elseif kind == "CastRejected" then
            if not fishing.ShakeReceived then
                fishing.Finished = "CastRejected"
                fishing.RejectReason = typeof(eventArgs[1]) == "string" and eventArgs[1] or nil
            end
        elseif kind == "Done" then
            fishing.Finished = "Done"
        end
    end)
end

function Extras.releaseFishingSession(remote, sessionId)
    pcall(function()
        remote:FireServer("Result", false, 0, sessionId)
        remote:FireServer("Cancel", sessionId)
    end)
end

function Extras.resetFishingRound()
    local fishing = Extras.Fishing
    fishing.Session = nil
    fishing.ShakeReceived = false
    fishing.BiteAt = nil
    fishing.ReelGain = 1
    fishing.Finished = nil
    fishing.RejectReason = nil
end

function Extras.getFishingSummary()
    local fishing = Extras.Fishing
    local minutes = math.max((os.clock() - fishing.StartedAt) / 60, 1 / 60)
    return string.format("caught %d | missed %d | %.1f/min | last %s", fishing.Caught, fishing.Missed, fishing.Caught / minutes, tostring(fishing.LastCatch or "-"))
end

function Extras.findOpenWaterSpot(origin)
    local okOcean, oceanData = pcall(require, configurationsFolder:FindFirstChild("OceanData"))
    if not okOcean or typeof(oceanData) ~= "table" then
        return nil
    end
    local ignoreList = { localPlayer.Character, extraFolder }
    local function openSurface(point)
        local okPoint, surface = pcall(oceanData.SnapToSurface, point)
        if not okPoint or typeof(surface) ~= "Vector3" then
            return nil
        end
        local okWater, isOpen = pcall(oceanData.IsOpenWater, surface, ignoreList)
        return (okWater and isOpen) and surface or nil
    end
    local roomOffsets = { Vector3.new(60, 0, 0), Vector3.new(-60, 0, 0), Vector3.new(0, 0, 60), Vector3.new(0, 0, -60) }
    for _, radius in ipairs({ 100, 200, 350, 500, 750, 1000, 1400, 1900 }) do
        for index = 0, 15 do
            local surface = openSurface(origin + CFrame.Angles(0, index * math.pi / 8, 0).LookVector * radius)
            if surface then
                local roomy = true
                for _, offset in ipairs(roomOffsets) do
                    if not openSurface(surface + offset) then
                        roomy = false
                        break
                    end
                end
                if roomy then
                    return surface
                end
            end
        end
    end
    return Extras.DeepSeaPoints[1]
end

function Extras.goToOpenWater()
    if Extras.PriorityRequest or not acquireMovement("fishing") then
        State.FishStatus = "no water in reach | waiting for " .. tostring(Extras.PriorityRequest or movementOwner)
        return false
    end
    local rootPart = getRoot()
    local spot = rootPart and Extras.findOpenWaterSpot(rootPart.Position)
    if not spot then
        releaseMovement("fishing")
        State.FishStatus = "no open water found nearby"
        return false
    end
    State.FishStatus = string.format("flying out to open water (%d studs)", math.floor((spot - rootPart.Position).Magnitude))
    Extras.clearCombatLocks()
    local hoverCFrame = CFrame.new(spot + Vector3.new(0, 8, 0))
    safeTravelTo(hoverCFrame, function()
        return State.AutoFishEnabled and Extras.PriorityRequest == nil
    end)
    Extras.Fishing.AimPoint = nil
    Extras.FishingSpot = hoverCFrame
    lockedTargetCFrame = hoverCFrame
    return true
end

function Extras.releaseFishingSpot()
    if Extras.FishingSpot and lockedTargetCFrame == Extras.FishingSpot then
        lockedTargetCFrame = nil
    end
    Extras.FishingSpot = nil
    releaseMovement("fishing")
end

function Extras.runFishingCycle()
    local fishing = Extras.Fishing
    local twohThread = Extras.TwohFishing == true and coroutine.running() == Extras.TwohFishingThread

    if Extras.TwohFishing and Extras.Twoh.isActive() and not twohThread then
        State.FishStatus = "standing by | Auto TWOH is fishing"
        task.wait(1)
        return
    end

    if State.AutoFishEnabled and not Extras.DeepsharkFishing and not twohThread then
        local whaleEvent = State.AutoWhaleEnabled and Extras.findWhaleIndicator() ~= nil
        local deepsharkBusy = State.AutoDeepsharkEnabled and (getInventoryAmount(Extras.DeepsharkBait) > 0 or Extras.getDeepsharkEnemy() ~= nil)
        if whaleEvent and movementOwner ~= "whale" then
            if movementOwner == "fishing" then
                Extras.releaseFishingSpot()
            end
            State.FishStatus = "whale event | heading to the whale"
            task.wait(0.3)
            return
        end
        if not whaleEvent and (deepsharkBusy or Extras.otherFarmActive()) then
            if movementOwner == "fishing" then
                Extras.releaseFishingSpot()
            end
            State.FishStatus = deepsharkBusy and "standing by | Ancient Deepshark is using Abyssal Bait" or (State.AutoWhaleEnabled and "standing by | another farm is on, fishing only during whale events" or "standing by | another farm is on (turn on Whale to fish at whale events)")
            task.wait(1)
            return
        end
    end

    if Extras.PriorityRequest and movementOwner == "fishing" then
        Extras.releaseFishingSpot()
    end

    if movementOwner and movementOwner ~= "whale" and movementOwner ~= "fishing" and not (movementOwner == "deepshark" and Extras.DeepsharkFishing) and not (movementOwner == "twoh" and twohThread) then
        State.FishStatus = "paused | " .. tostring(movementOwner) .. " is active"
        task.wait(1)
        return
    end

    local remote = Extras.getFishingRemote()
    if not remote then
        State.FishStatus = "fishing remote not found"
        task.wait(2)
        return
    end

    if not Extras.equipFishingRod() then
        State.FishStatus = "no fishing rod in backpack"
        task.wait(2)
        return
    end

    local whaleIndicator = (State.AutoWhaleEnabled or Extras.DeepsharkFishing or twohThread) and Extras.findWhaleIndicator() or nil
    local aimPoint = Extras.findFishingAim(whaleIndicator and whaleIndicator.Position or nil)
    if not aimPoint and State.AutoFishEnabled and not Extras.DeepsharkFishing and not Extras.WhaleFishing and not twohThread and Extras.goToOpenWater() then
        aimPoint = Extras.findFishingAim(nil)
    end
    if not aimPoint then
        if not string.find(tostring(State.FishStatus), "waiting for", 1, true) then
            State.FishStatus = "no open water nearby"
        end
        task.wait(1)
        return
    end

    Extras.muteGameFishing(true)
    Extras.connectFishing(remote)

    local rootPart = getRoot()
    if rootPart and not lockedTargetCFrame then
        rootPart.CFrame = CFrame.lookAt(rootPart.Position, Vector3.new(aimPoint.X, rootPart.Position.Y, aimPoint.Z))
    end

    Extras.resetFishingRound()
    pcall(function()
        remote:FireServer("Cast", fishing.CastPower, aimPoint)
    end)

    local castAt = os.clock()
    while Extras.isFishingActive() and not fishing.ShakeReceived and not fishing.Finished and os.clock() - castAt < 2 do
        task.wait()
    end

    if not fishing.ShakeReceived then
        fishing.Rejects = fishing.Rejects + 1
        if fishing.Rejects >= 6 and fishing.LastSession then
            Extras.releaseFishingSession(remote, fishing.LastSession)
            fishing.Rejects = 0
        end
        State.FishStatus = "cast rejected x" .. tostring(fishing.Rejects) .. " | " .. tostring(fishing.RejectReason or "retrying")
        fishing.AimPoint = nil
        task.wait(0.25)
        return
    end

    fishing.Rejects = 0
    local sessionId = fishing.Session
    State.FishStatus = "shaking | " .. Extras.getFishingSummary()

    while Extras.isFishingActive() and not fishing.BiteAt and not fishing.Finished and os.clock() - castAt < 40 do
        pcall(function()
            remote:FireServer("Shake", sessionId)
        end)
        task.wait(fishing.ShakeInterval)
    end

    if not fishing.BiteAt then
        if not fishing.Finished then
            Extras.releaseFishingSession(remote, sessionId)
        end
        return
    end

    local reelTime = 1 / (0.105 * fishing.ReelGain) - fishing.ReelMargin
    while Extras.isFishingActive() and not fishing.Finished and os.clock() - fishing.BiteAt < reelTime do
        State.FishStatus = string.format("reeling %.1fs | %s", math.max(reelTime - (os.clock() - fishing.BiteAt), 0), Extras.getFishingSummary())
        task.wait(0.1)
    end

    if not Extras.isFishingActive() then
        Extras.releaseFishingSession(remote, sessionId)
        return
    end

    if fishing.Finished then
        fishing.Missed = fishing.Missed + 1
        return
    end

    local passExpBefore = localPlayer:GetAttribute("FishingPassExp")
    local sentAt = os.clock()
    pcall(function()
        remote:FireServer("Result", true, 1, sessionId)
    end)

    while not fishing.Finished and os.clock() - sentAt < 6 do
        task.wait()
    end
    if not fishing.Finished then
        Extras.releaseFishingSession(remote, sessionId)
    end
    task.wait(0.05)

    local obtainedNow = (State.LastObtainTime or 0) >= sentAt
    if obtainedNow or localPlayer:GetAttribute("FishingPassExp") ~= passExpBefore then
        fishing.Caught = fishing.Caught + 1
        if obtainedNow then
            fishing.LastCatch = State.LastObtain
        end
    else
        fishing.Missed = fishing.Missed + 1
    end
    State.FishStatus = Extras.getFishingSummary()
end

function Extras.startFastFishing()
    local fishing = Extras.Fishing
    fishing.Caught = 0
    fishing.Missed = 0
    fishing.Rejects = 0
    fishing.LastCatch = nil
    fishing.AimPoint = nil
    fishing.StartedAt = os.clock()
    State.FishStatus = "starting"
    Extras.startLoop("AutoFishEnabled", Extras.runFishingCycle)
end

function Extras.stopFishing()
    Extras.stopLoop("AutoFishEnabled")
    Extras.releaseFishingSpot()
    local fishing = Extras.Fishing
    local remote = Extras.getFishingRemote()
    if remote and fishing.ShakeReceived and not fishing.Finished then
        Extras.releaseFishingSession(remote, fishing.Session)
    end
    if getgenv().HubFishingConnection then
        pcall(function()
            getgenv().HubFishingConnection:Disconnect()
        end)
        getgenv().HubFishingConnection = nil
    end
    Extras.muteGameFishing(false)
    Extras.resetFishingRound()
end

Extras.DeepsharkName = "Ancient Deepshark"
Extras.DeepsharkBait = "Abyssal Bait"
Extras.DeepSeaPoints = {
    Vector3.new(5713, 0, -832),
    Vector3.new(6500, 0, -900)
}
Extras.DeepSeaIndex = 1

function Extras.getDeepsharkKillStat()
    local kills = 0
    pcall(function()
        local statsValue = localPlayer.Data:FindFirstChild("PrestigeStats")
        local decoded = httpService:JSONDecode(statsValue.Value)
        kills = tonumber(decoded.AncientDeepsharkKills) or 0
    end)
    return kills
end

function Extras.getDeepsharkEnemy()
    local rootPart = getRoot()
    if not rootPart then
        return nil
    end
    return getTargetEnemy(Extras.DeepsharkName, rootPart.Position, true)
end

function Extras.getDeepSeaPoint()
    Extras.DeepSeaIndex = math.clamp(Extras.DeepSeaIndex or 1, 1, #Extras.DeepSeaPoints)
    return Extras.DeepSeaPoints[Extras.DeepSeaIndex]
end

function Extras.getFlatDistance(firstPosition, secondPosition)
    return Vector3.new(firstPosition.X - secondPosition.X, 0, firstPosition.Z - secondPosition.Z).Magnitude
end

function Extras.getWhaleFishingPoint()
    local indicator = Extras.findWhaleIndicator()
    if not indicator then
        return nil
    end
    return Vector3.new(indicator.Position.X + 40, 0, indicator.Position.Z), indicator
end

function Extras.goToDeepSea(targetPoint, label, isActive)
    isActive = isActive or function()
        return State.AutoDeepsharkEnabled
    end
    local point = targetPoint or Extras.getDeepSeaPoint()
    local rootPart = getRoot()
    if not rootPart then
        return false
    end

    if Extras.getFlatDistance(rootPart.Position, point) > 40 then
        State.ExtraStatus = "Deepshark: flying " .. (label or "out to the open sea")
        lockedEnemyRoot = nil
        lockedTargetCFrame = nil
        Combat.LockedMobName = nil
        setTargetBox(nil)
        safeTravelTo(CFrame.new(point + Vector3.new(0, 20, 0)), isActive)
    end

    rootPart = getRoot()
    return rootPart ~= nil and Extras.getFlatDistance(rootPart.Position, point) <= 60
end

function Extras.enterSeaWater(isActive)
    isActive = isActive or function()
        return State.AutoDeepsharkEnabled
    end
    local rootPart = getRoot()
    if not rootPart then
        return false
    end
    if rootPart.Position.Y <= 0.5 and not rootPart:FindFirstChild("FarmFloat") then
        return true
    end

    State.ExtraStatus = "Deepshark: dropping into the water"
    stopTween()
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    local deadline = os.clock() + 8
    while isActive() and os.clock() < deadline do
        rootPart = getRoot()
        if not rootPart then
            return false
        end
        removeFloat(rootPart)
        if rootPart.Position.Y <= 0.3 then
            task.wait(0.2)
            return true
        end
        task.wait(0.1)
    end
    rootPart = getRoot()
    return rootPart ~= nil and rootPart.Position.Y <= 0.5
end

function Extras.useAbyssalBait()
    local useRemote = remotesFolder:FindFirstChild("RE_UseItem")
    local outputRemote = remotesFolder:FindFirstChild("Output")
    if not useRemote then
        return "noremote", nil
    end

    local replies = {}
    local replyConnection = nil
    if outputRemote then
        replyConnection = outputRemote.OnClientEvent:Connect(function(kind, ...)
            if kind ~= "Notify" then
                return
            end
            local parts = {}
            for _, value in ipairs({ ... }) do
                if typeof(value) == "string" then
                    table.insert(parts, value)
                end
            end
            table.insert(replies, string.lower((string.gsub(table.concat(parts, " | "), "<[^<>]->", ""))))
        end)
    end

    local baitBefore = getInventoryAmount(Extras.DeepsharkBait)
    pcall(function()
        useRemote:FireServer(Extras.DeepsharkBait, 1, 0)
    end)

    local result, distance = nil, nil
    local deadline = os.clock() + 4
    while os.clock() < deadline and not result do
        for _, reply in ipairs(replies) do
            if string.find(reply, "summoned from the depths", 1, true) then
                result = "summoned"
            elseif string.find(reply, "already hunting", 1, true) then
                result = "alive"
                distance = tonumber(string.match(reply, "about%s*(%d+)"))
            elseif string.find(reply, "close to land", 1, true) then
                result = "land"
            elseif string.find(reply, "swimming", 1, true) then
                result = "swim"
            end
        end
        if not result and getInventoryAmount(Extras.DeepsharkBait) < baitBefore then
            result = "summoned"
        end
        task.wait(0.1)
    end

    if replyConnection then
        replyConnection:Disconnect()
    end
    return result or "noreply", distance
end

function Extras.endDeepsharkFishing()
    if not Extras.DeepsharkFishing then
        return
    end
    Extras.DeepsharkFishing = false
    if not State.AutoFishEnabled then
        Extras.stopFishing()
    end
end

function Extras.releaseDeepsharkPriority()
    if Extras.PriorityRequest == "deepshark" then
        Extras.PriorityRequest = nil
    end
    Extras.DeepsharkPriorityUntil = nil
end

function Extras.runDeepsharkCycle()
    local baitCount = getInventoryAmount(Extras.DeepsharkBait)
    if baitCount <= 0 and not Extras.DeepsharkDelegated and not Extras.getDeepsharkEnemy() then
        Extras.endDeepsharkFishing()
        Extras.releaseDeepsharkPriority()
        releaseMovement("deepshark")
        if not Extras.otherFarmActive() or not State.AutoFishEnabled then
            State.ExtraStatus = State.AutoFishEnabled and "Deepshark: no Abyssal Bait | Auto Fishing is catching more" or "Deepshark: no Abyssal Bait | turn on Auto Fishing to catch more"
        end
        task.wait(2)
        return
    end

    local whaleEvent = State.AutoWhaleEnabled and State.AutoFishEnabled and Extras.findWhaleIndicator() ~= nil
    if not whaleEvent and not Extras.PriorityRequest and os.clock() >= (Extras.DeepsharkBackoffUntil or 0) then
        Extras.PriorityRequest = "deepshark"
        Extras.DeepsharkPriorityUntil = os.clock() + 150
    end
    if Extras.PriorityRequest == "deepshark" and os.clock() > (Extras.DeepsharkPriorityUntil or math.huge) then
        Extras.releaseDeepsharkPriority()
        Extras.DeepsharkBackoffUntil = os.clock() + 120
    end

    if not acquireMovement("deepshark") then
        Extras.DeepsharkWaitSince = Extras.DeepsharkWaitSince or os.clock()
        if Extras.PriorityRequest == "deepshark" and os.clock() - Extras.DeepsharkWaitSince > 8 then
            stopTween()
            movementOwner = nil
        end
        State.ExtraStatus = "Deepshark: Abyssal Bait ready | waiting for " .. tostring(movementOwner) .. " to finish"
        task.wait(0.5)
        return
    end
    Extras.DeepsharkWaitSince = nil
    if Extras.getDeepsharkEnemy() then
        Extras.endDeepsharkFishing()
        local killsSoFar = Extras.getDeepsharkKillStat() - (Extras.DeepsharkKillsAtStart or Extras.getDeepsharkKillStat())
        State.ExtraStatus = string.format("Deepshark: fighting %s | bait left %d | kills %d", Extras.DeepsharkName, baitCount, killsSoFar)
        farmMobWithAnchor(Extras.DeepsharkName, function()
            return State.AutoDeepsharkEnabled
        end, true)
        releaseMovement("deepshark")
        return
    end

    if baitCount > 0 and Extras.DeepsharkFishing then
        Extras.endDeepsharkFishing()
        local currentRoot = getRoot()
        if currentRoot and currentRoot.Position.Y <= 0.5 then
            State.ExtraStatus = string.format("Deepshark: got Abyssal Bait | trying to summon right here (%d left)", baitCount)
            local hereResult, hereDistance = Extras.useAbyssalBait()
            if hereResult == "summoned" then
                local deadline = os.clock() + 6
                while State.AutoDeepsharkEnabled and os.clock() < deadline and not Extras.getDeepsharkEnemy() do
                    task.wait(0.2)
                end
                releaseMovement("deepshark")
                return
            elseif hereResult == "alive" then
                State.ExtraStatus = "Deepshark: one is already hunting about " .. tostring(hereDistance or "?") .. " studs away | searching"
                releaseMovement("deepshark")
                task.wait(2)
                return
            end
        end
    end

    local whalePoint = nil
    if baitCount <= 0 then
        whalePoint = Extras.getWhaleFishingPoint()
    end

    if not Extras.goToDeepSea(whalePoint, whalePoint and "to the whale for blessed fishing" or nil) then
        State.ExtraStatus = whalePoint and "Deepshark: could not reach the whale" or "Deepshark: could not reach the open sea"
        releaseMovement("deepshark")
        task.wait(1)
        return
    end

    if baitCount <= 0 then
        local spotLabel = whalePoint and "at the whale" or "in the open sea"
        if not Extras.DeepsharkFishing then
            Extras.DeepsharkFishing = true
            Extras.Fishing.Caught = 0
            Extras.Fishing.Missed = 0
            Extras.Fishing.AimPoint = nil
            Extras.Fishing.StartedAt = os.clock()
        end
        Extras.enterSeaWater()
        State.ExtraStatus = "Deepshark: no Abyssal Bait | fishing " .. spotLabel .. " | " .. tostring(State.FishStatus)
        Extras.runFishingCycle()
        State.ExtraStatus = "Deepshark: no Abyssal Bait | fishing " .. spotLabel .. " | " .. tostring(State.FishStatus)
        releaseMovement("deepshark")
        return
    end

    Extras.endDeepsharkFishing()

    if not Extras.enterSeaWater() then
        State.ExtraStatus = "Deepshark: could not get into the water"
        releaseMovement("deepshark")
        task.wait(1)
        return
    end

    State.ExtraStatus = string.format("Deepshark: using Abyssal Bait (%d left)", baitCount)
    local result, distance = Extras.useAbyssalBait()
    if result == "summoned" then
        local deadline = os.clock() + 6
        while State.AutoDeepsharkEnabled and os.clock() < deadline and not Extras.getDeepsharkEnemy() do
            task.wait(0.2)
        end
        State.ExtraStatus = "Deepshark: summoned | engaging"
    elseif result == "alive" then
        State.ExtraStatus = "Deepshark: one is already hunting about " .. tostring(distance or "?") .. " studs away | searching"
        task.wait(2)
    elseif result == "land" then
        Extras.DeepSeaIndex = (Extras.DeepSeaIndex % #Extras.DeepSeaPoints) + 1
        State.ExtraStatus = "Deepshark: too close to land | moving further out"
    elseif result == "swim" then
        State.ExtraStatus = "Deepshark: not swimming yet | retrying"
        task.wait(0.5)
    else
        State.ExtraStatus = "Deepshark: no reply to the bait (" .. tostring(result) .. ")"
        task.wait(1)
    end

    releaseMovement("deepshark")
end

Extras.Araya = {
    NPCName = "Lost Afterimage",
    NPCPosition = Vector3.new(3842, 96, -3034),
    Quest1 = "The Moment Left Behind 1",
    Quest2 = "The Moment Left Behind 2",
    Quest3 = "The Moment Left Behind 3",
    KillGoal = 180,
    DungeonPlaceId = 105440532661931,
    EstateName = "Abandoned Spider Estate",
    BossName = "The Dihui Star, Araya",
    SettingsPath = "LEGACY PIECE/araya_settings.json",
    Difficulty = "Easy",
    MoneyCost = 75000000,
    ShardCost = 500000,
    Materials = {
        { "Thread of the Past", 1 },
        { "Thread of the Present", 1 },
        { "Thread of the Future", 1 },
        { "Thread of the Unsevered", 1 },
        { "Time Safe Core", 15 }
    },
    TitleName = "The Pinky Nursefather",
    HubLoader = 'if getgenv().HubAutoLoaded then return end getgenv().HubAutoLoaded = true if not game:IsLoaded() then game.Loaded:Wait() end local players = game:GetService("Players") while not players.LocalPlayer do task.wait() end players.LocalPlayer:WaitForChild("Data", 60) task.wait(2) loadstring(readfile("LEGACY PIECE/legacy_piece.luau"))()'
}

Extras.Araya.MaxTimeSafeLosses = math.huge
Extras.Araya.Retreat = { Below = 0.4, Until = 0.8, Height = 150, IgnoreRespawn = true }

function Extras.arayaAnchorsAlive()
    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if string.find(enemy.Name, "Anchor", 1, true) then
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                return true
            end
        end
    end
    return false
end

function Extras.saveArayaSettings(enabled, losses)
    if losses ~= nil then
        Extras.Araya.TimeSafeLosses = losses
    end
    pcall(function()
        if not isfolder(Extras.DungeonFolder) then
            makefolder(Extras.DungeonFolder)
        end
        writefile(Extras.Araya.SettingsPath, httpService:JSONEncode({
            Enabled = enabled == true,
            Difficulty = Extras.Araya.Difficulty,
            TimeSafeLosses = Extras.Araya.TimeSafeLosses or 0
        }))
    end)
end

function Extras.stopArayaForLosses()
    local araya = Extras.Araya
    State.ExtraStatus = string.format("Araya: lost the Time Safe %d times in a row | too strong solo, bring a party or more damage | stopped", araya.TimeSafeLosses or 0)
    Extras.saveArayaSettings(false, 0)
    Extras.stopLoop("AutoArayaEnabled", "araya")
    Extras.syncToggle("ArayaToggle", false)
end

function Extras.loadArayaSettings()
    local settings = {}
    pcall(function()
        local decoded = httpService:JSONDecode(readfile(Extras.Araya.SettingsPath))
        if typeof(decoded) == "table" then
            settings = decoded
        end
    end)
    return settings
end

function Extras.queueArayaReload()
    if not Extras.Araya.PreQueued then
        Extras.Araya.PreQueued = pcall(function()
            queue_on_teleport(Extras.Araya.HubLoader)
        end)
        Extras.Araya.LastQueuedAt = os.clock()
    end
    if getgenv().HubArayaTeleportConnection then
        return
    end
    getgenv().HubArayaTeleportConnection = localPlayer.OnTeleport:Connect(function(teleportState)
        if teleportState ~= Enum.TeleportState.Started or not State.AutoArayaEnabled then
            return
        end
        if Extras.Araya.PreQueued or os.clock() - (Extras.Araya.LastQueuedAt or 0) < 5 then
            return
        end
        Extras.Araya.LastQueuedAt = os.clock()
        pcall(function()
            queue_on_teleport(Extras.Araya.HubLoader)
        end)
    end)
end

function Extras.getArayaDungeonName()
    if game.PlaceId ~= Extras.Araya.DungeonPlaceId then
        return nil
    end
    local dungeonName = workspaceService:GetAttribute("Dungeon")
    return typeof(dungeonName) == "string" and dungeonName or nil
end

function Extras.isArayaDungeon(dungeonName)
    if not dungeonName then
        return false
    end
    local lowered = string.lower(dungeonName)
    return dungeonName == Extras.Araya.EstateName or string.find(lowered, "time safe", 1, true) ~= nil
end

function Extras.getArayaKills()
    local questFolder = UnlockFarm.getActiveQuestFolder(Extras.Araya.Quest1)
    local progressValue = questFolder and questFolder:FindFirstChild("Progress")
    return progressValue and progressValue.Value or 0
end

function Extras.hasArayaTitle()
    local dataFolder = localPlayer:FindFirstChild("Data")
    local titlesFolder = dataFolder and dataFolder:FindFirstChild("Titles")
    if titlesFolder and titlesFolder:FindFirstChild(Extras.Araya.TitleName) then
        return true
    end
    return getInventoryAmount(Extras.Araya.TitleName) > 0
end

function Extras.getArayaMissing()
    local missing = {}
    for _, entry in ipairs(Extras.Araya.Materials) do
        local have = getInventoryAmount(entry[1])
        if have < entry[2] then
            table.insert(missing, string.format("%s %d/%d", entry[1], have, entry[2]))
        end
    end
    if not Extras.hasArayaTitle() then
        table.insert(missing, Extras.Araya.TitleName)
    end
    local dataFolder = localPlayer:FindFirstChild("Data")
    local money = dataFolder and dataFolder:FindFirstChild("Money")
    local shards = dataFolder and dataFolder:FindFirstChild("Shards")
    if not money or money.Value < Extras.Araya.MoneyCost then
        table.insert(missing, "$75M")
    end
    if not shards or shards.Value < Extras.Araya.ShardCost then
        table.insert(missing, "500K Shards")
    end
    return missing
end

function Extras.hasAraya()
    local dataFolder = localPlayer:FindFirstChild("Data")
    local inventoryFolder = dataFolder and dataFolder:FindFirstChild("Inventory")
    return inventoryFolder ~= nil and inventoryFolder:FindFirstChild("Araya") ~= nil
end

function Extras.isArayaActive()
    return State.AutoArayaEnabled
end

function Extras.getArayaStage()
    local araya = Extras.Araya
    if Extras.hasAraya() then
        return "done"
    end
    if not UnlockFarm.isQuestCompleted(araya.Quest1) then
        if not UnlockFarm.getActiveQuestFolder(araya.Quest1) then
            return "accept"
        end
        if UnlockFarm.isQuestReadyToClaim(araya.Quest1) or Extras.getArayaKills() >= araya.KillGoal then
            return "claim", araya.Quest1
        end
        return "estate"
    end
    if not UnlockFarm.isQuestCompleted(araya.Quest2) then
        if not UnlockFarm.getActiveQuestFolder(araya.Quest2) then
            return "accept"
        end
        if UnlockFarm.isQuestReadyToClaim(araya.Quest2) then
            return "claim", araya.Quest2
        end
        return "timesafe"
    end
    if #Extras.getArayaMissing() == 0 then
        return "turnin"
    end
    if Extras.arayaOnlyMoneyMissing() then
        return "money"
    end
    return "timesafe"
end

function Extras.arayaOnlyMoneyMissing()
    if not UnlockFarm.isQuestCompleted(Extras.Araya.Quest2) then
        return false
    end
    for _, entry in ipairs(Extras.getArayaMissing()) do
        if entry ~= "$75M" then
            return false
        end
    end
    return true
end

function Extras.goToLostAfterimage()
    local araya = Extras.Araya
    local npc = npcsFolder:FindFirstChild(araya.NPCName)
    local rootPart = getRoot()
    if not npc and rootPart and (rootPart.Position - araya.NPCPosition).Magnitude > 150 then
        State.ExtraStatus = "Araya: flying to the Lost Afterimage"
        safeTravelTo(CFrame.new(araya.NPCPosition + Vector3.new(0, 6, 0)), Extras.isArayaActive)
    end
    npc = npcsFolder:FindFirstChild(araya.NPCName) or npcsFolder:WaitForChild(araya.NPCName, 5)
    if not npc then
        return nil
    end
    if not travelToNPC(npc, Extras.isArayaActive) then
        return nil
    end
    return npcsFolder:FindFirstChild(araya.NPCName) or npc
end

function Extras.openArayaDialogue(npc)
    if isDialogueOpen() then
        return true
    end
    local opened = talkToNPC(npc, "__araya__", function()
        return false
    end, 1)
    if not opened then
        return false
    end
    local deadline = os.clock() + 3
    while os.clock() < deadline and not isDialogueOpen() do
        task.wait(0.1)
    end
    return isDialogueOpen()
end

function Extras.pickArayaChoice(wantedText, stopCondition)
    local loweredWanted = string.lower(wantedText)
    for _ = 1, 8 do
        if stopCondition and stopCondition() then
            return true
        end
        local choices = getDialogueChoices()
        local listenChoice = nil
        for _, choice in ipairs(choices) do
            local loweredChoice = string.lower(choice.Text)
            if string.find(loweredChoice, loweredWanted, 1, true) then
                clickGuiButton(choice.Button)
                task.wait(0.8)
                return true
            end
            if loweredChoice == "listen" then
                listenChoice = choice
            end
        end
        if listenChoice then
            clickGuiButton(listenChoice.Button)
        end
        task.wait(0.6)
    end
    return stopCondition ~= nil and stopCondition()
end

function Extras.enterArayaDungeon(inputAction, portalName, label)
    local npc = Extras.goToLostAfterimage()
    if not npc then
        State.ExtraStatus = "Araya: cannot reach the Lost Afterimage"
        task.wait(1)
        return
    end

    Extras.saveArayaSettings(true)
    Extras.queueArayaReload()

    State.ExtraStatus = "Araya: opening the " .. label .. " lobby"
    Extras.openArayaDialogue(npc)
    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        pcall(fireproximityprompt, prompt)
    end
    task.wait(0.3)

    local inputRemote = remotesFolder:FindFirstChild("Input")
    local portalRemote = eventsFolder and eventsFolder:FindFirstChild(portalName)
    if not inputRemote or not portalRemote then
        State.ExtraStatus = "Araya: " .. label .. " remotes not found"
        task.wait(2)
        return
    end

    pcall(function()
        inputRemote:FireServer(inputAction)
    end)
    task.wait(1.2)
    pcall(function()
        portalRemote:FireServer("Start")
    end)

    State.ExtraStatus = "Araya: starting " .. label .. " | waiting for teleport"
    local deadline = os.clock() + 30
    while State.AutoArayaEnabled and os.clock() < deadline do
        task.wait(0.5)
    end
    if State.AutoArayaEnabled then
        State.ExtraStatus = "Araya: " .. label .. " did not start | " .. tostring(State.LastNotifyText)
        pcall(function()
            portalRemote:FireServer("Leave")
        end)
        task.wait(2)
    end
end

function Extras.connectArayaDungeon()
    if getgenv().HubArayaConnection then
        return
    end
    local syncRemote = eventsFolder and eventsFolder:FindFirstChild("DungeonInsideSync")
    if not syncRemote then
        return
    end
    getgenv().HubArayaConnection = syncRemote.OnClientEvent:Connect(function(payload)
        if typeof(payload) ~= "table" or payload.Type ~= "State" then
            return
        end
        local araya = Extras.Araya
        araya.DungeonWave = payload.CurrentWave
        araya.DungeonMaxWave = payload.MaxWave
        local status = payload.Status
        if status == araya.LastDungeonStatus then
            return
        end
        araya.LastDungeonStatus = status
        if not State.AutoArayaEnabled then
            return
        end
        if status == "Vote" then
            task.delay(1, function()
                pcall(function()
                    syncRemote:FireServer("Vote", araya.Difficulty)
                end)
            end)
        elseif status == "Clear" or status == "Lose" then
            local dungeonName = Extras.getArayaDungeonName()
            local wantsReplay = false
            if dungeonName == araya.EstateName then
                wantsReplay = not UnlockFarm.isQuestCompleted(araya.Quest1) and Extras.getArayaKills() < araya.KillGoal
            elseif Extras.isArayaDungeon(dungeonName) then
                if status == "Lose" then
                    Extras.saveArayaSettings(true, (araya.TimeSafeLosses or 0) + 1)
                else
                    Extras.saveArayaSettings(true, 0)
                end
                if (araya.TimeSafeLosses or 0) >= araya.MaxTimeSafeLosses then
                    Extras.stopArayaForLosses()
                    return
                end
                wantsReplay = not (Extras.arayaOnlyMoneyMissing() or #Extras.getArayaMissing() == 0)
            end
            if wantsReplay then
                task.delay(2, function()
                    pcall(function()
                        syncRemote:FireServer("ReplayVote")
                    end)
                end)
            end
        end
    end)
end

function Extras.pickArayaTarget(rootPart)
    local araya = Extras.Araya
    local bestEnemy, bestScore = nil, math.huge
    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        local alive, enemyRoot = isLivingEnemy(enemy)
        local isAfterimage = string.find(enemy.Name, "Afterimage", 1, true) ~= nil
        local isMarked = enemy:GetAttribute("ArayaMarkTarget") == true
        if alive and (not isAfterimage or isMarked) then
            local score = (enemyRoot.Position - rootPart.Position).Magnitude
            local loweredName = string.lower(enemy.Name)
            if string.find(loweredName, "anchor", 1, true) then
                score = score - 100000
            elseif isMarked then
                score = score - 50000
            elseif string.find(enemy.Name, araya.BossName, 1, true) then
                score = score - 1000
            end
            if score < bestScore then
                bestScore = score
                bestEnemy = enemy
            end
        end
    end
    return bestEnemy
end

function Extras.runArayaDungeonCycle(dungeonName)
    Extras.connectArayaDungeon()
    Extras.queueArayaReload()

    if not acquireMovement("araya") then
        State.ExtraStatus = "Araya: waiting for " .. tostring(movementOwner) .. " to finish"
        task.wait(1)
        return
    end

    local araya = Extras.Araya
    if Extras.isArayaDungeon(dungeonName) and (Extras.arayaOnlyMoneyMissing() or (UnlockFarm.isQuestCompleted(araya.Quest2) and #Extras.getArayaMissing() == 0)) then
        State.FarmDistanceOverride = nil
        lockedEnemyRoot = nil
        lockedTargetCFrame = nil
        State.ExtraStatus = "Araya: items complete | leaving the Time Safe to " .. (#Extras.getArayaMissing() == 0 and "turn in" or "farm money (Ambush)")
        if os.clock() - (araya.LeaveSentAt or 0) > 8 then
            araya.LeaveSentAt = os.clock()
            Extras.expectTeleport(15)
            local leaveRemote = eventsFolder and eventsFolder:FindFirstChild("DungeonLeave")
            if leaveRemote then
                pcall(function()
                    leaveRemote:FireServer()
                end)
            end
        end
        releaseMovement("araya")
        task.wait(1)
        return
    end
    local waveText = string.format("wave %s/%s", tostring(araya.DungeonWave or "?"), tostring(araya.DungeonMaxWave or "?"))
    local progressText
    if dungeonName == araya.EstateName then
        if UnlockFarm.isQuestCompleted(araya.Quest1) then
            progressText = "echoes done | leaving after this run"
        else
            progressText = string.format("echoes %d/%d", Extras.getArayaKills(), araya.KillGoal)
        end
    elseif not UnlockFarm.isQuestCompleted(araya.Quest2) then
        progressText = "defeat " .. araya.BossName
    else
        progressText = "missing: " .. table.concat(Extras.getArayaMissing(), ", ")
    end

    local rootPart = getRoot()
    local target = rootPart and Extras.pickArayaTarget(rootPart)
    State.FarmDistanceOverride = target and string.find(target.Name, araya.BossName, 1, true) and araya.BossDistance or nil
    if target then
        State.ExtraStatus = string.format("Araya [%s]: fighting %s | %s | %s", dungeonName, target.Name, waveText, progressText)
        farmMobWithAnchor(target.Name, function()
            return State.AutoArayaEnabled and target.Parent ~= nil
        end, true)
    else
        State.ExtraStatus = string.format("Araya [%s]: waiting for the next wave | %s | %s", dungeonName, waveText, progressText)
        local now = os.clock()
        araya.IdleSince = araya.IdleSince or now
        if now - araya.IdleSince >= 12 and now - (araya.LastNudgeAt or 0) >= 10 then
            araya.LastNudgeAt = now
            local syncRemote = eventsFolder and eventsFolder:FindFirstChild("DungeonInsideSync")
            if syncRemote then
                pcall(function()
                    syncRemote:FireServer("ReplayVote")
                end)
                pcall(function()
                    syncRemote:FireServer("Vote", araya.Difficulty)
                end)
            end
        end
        task.wait(0.5)
        releaseMovement("araya")
        return
    end
    araya.IdleSince = nil

    releaseMovement("araya")
end

function Extras.runArayaCycle()
    local dungeonName = Extras.getArayaDungeonName()
    if not dungeonName or not Extras.isArayaDungeon(dungeonName) then
        State.FarmDistanceOverride = nil
    end
    if dungeonName then
        if Extras.isArayaDungeon(dungeonName) then
            Extras.runArayaDungeonCycle(dungeonName)
        else
            State.ExtraStatus = "Araya: inside another dungeon (" .. dungeonName .. ")"
            task.wait(2)
        end
        return
    end

    local araya = Extras.Araya
    local stage, questName = Extras.getArayaStage()

    if stage == "done" then
        State.FarmDistanceOverride = nil
        Extras.saveArayaSettings(false, 0)
        Extras.stopLoop("AutoArayaEnabled", "araya")
        Extras.syncToggle("ArayaToggle", false)
        State.ExtraStatus = "Araya: obtained | Auto Araya stopped"
        return
    end

    if not acquireMovement("araya") then
        State.ExtraStatus = "Araya: waiting for " .. tostring(movementOwner) .. " to finish"
        task.wait(1)
        return
    end

    if stage == "accept" then
        local npc = Extras.goToLostAfterimage()
        if npc and Extras.openArayaDialogue(npc) then
            State.ExtraStatus = "Araya: accepting the next Moment Left Behind quest"
            Extras.pickArayaChoice("i will find your moment", function()
                return Extras.getArayaStage() ~= "accept"
            end)
        else
            State.ExtraStatus = "Araya: cannot talk to the Lost Afterimage"
            task.wait(1)
        end
    elseif stage == "claim" then
        State.ExtraStatus = "Araya: claiming " .. tostring(questName)
        Extras.goToLostAfterimage()
        invokeInput("Quest", "Claim", questName)
        task.wait(1)
    elseif stage == "estate" then
        State.ExtraStatus = string.format("Araya: echoes %d/%d | entering the Abandoned Estate", Extras.getArayaKills(), araya.KillGoal)
        Extras.enterArayaDungeon("EnterSpiderEstate", "SpiderEstatePortal", "Abandoned Estate")
    elseif stage == "timesafe" then
        Extras.enterArayaDungeon("EnterTimeSafe", "TimeSafePortal", "Time Safe")
    elseif stage == "money" then
        local label = string.format("Araya: items complete | money $%dM/%dM | Ambush", math.floor(getMoney() / 1000000), math.floor(araya.MoneyCost / 1000000))
        if not Extras.runAmbushDuty(function()
            return State.AutoArayaEnabled and getMoney() < araya.MoneyCost
        end, label) then
            State.ExtraStatus = label .. ": waiting for the next ambush"
            task.wait(0.5)
        end
    elseif stage == "turnin" then
        local npc = Extras.goToLostAfterimage()
        if npc then
            State.ExtraStatus = "Araya: returning the threads"
            if UnlockFarm.isQuestReadyToClaim(araya.Quest3) then
                invokeInput("Quest", "Claim", araya.Quest3)
                task.wait(1)
            end
            invokeInput("Shop", npc, "Araya")
            task.wait(1.5)
            if not Extras.hasAraya() then
                State.ExtraStatus = "Araya: turn-in not accepted | " .. tostring(State.LastNotifyText)
                task.wait(2)
            end
        end
    end

    lockedTargetCFrame = nil
    releaseMovement("araya")
end

Extras.Dungeons = {
    { Name = "Realm Beyond Heaven (TWOH)", Key = "Realm Beyond Heaven", NPC = "The Gatekeeper", NPCPosition = Vector3.new(-876, 114, -1547), Portal = "RealmBeyondHeavenPortal", Item = "Realm Beyond Heaven Key", Style = "The World", KeyBoss = "Chihora" },
    { Name = "Excutioners Arrival (Cursed Child)", Key = "Excutioners Arrival", NPC = "The Gatekeeper", NPCPosition = Vector3.new(-876, 114, -1547), Portal = "CursedChildPortal", Item = "Cursed Child Key" },
    { Name = "House of Spiders (Rien)", Key = "House of Spiders", NPC = "Index Messenger", NPCPosition = Vector3.new(2881, 37, -2852), Input = "EnterHouseOfSpiders", Portal = "HouseOfSpidersPortal" },
    { Name = "Devil's Route (Vergil, Dante)", Key = "Devil's Route", NPC = "Marlow, The Last Conductor", NPCPosition = Vector3.new(630, -3524, 2046), Input = "EnterDevilsRoute", Portal = "DevilsRoutePortal", Quest = "The Final Route" },
    { Name = "The Time Safe (Araya)", Key = "The House of Spiders: The Time Safe", NPC = "Lost Afterimage", NPCPosition = Vector3.new(3842, 96, -3034), Input = "EnterTimeSafe", Portal = "TimeSafePortal" },
    { Name = "Abandoned Spider Estate", Key = "Abandoned Spider Estate", NPC = "Lost Afterimage", NPCPosition = Vector3.new(3842, 96, -3034), Input = "EnterSpiderEstate", Portal = "SpiderEstatePortal" }
}

function Extras.getDungeonOptions()
    local options = {}
    for _, entry in ipairs(Extras.Dungeons) do
        table.insert(options, entry.Name)
    end
    return options
end

function Extras.getSelectedDungeon()
    for _, entry in ipairs(Extras.Dungeons) do
        if entry.Name == State.AutoDungeonTarget then
            return entry
        end
    end
    return Extras.Dungeons[1]
end

function Extras.isDungeonActive()
    return State.AutoDungeonEnabled
end

function Extras.dungeonStatus(message)
    State.ExtraStatus = "Dungeon: " .. message
end

function Extras.connectAutoDungeon()
    if getgenv().HubAutoDungeonConnection and getgenv().HubAutoDungeonConnection.Connected ~= false then
        return
    end
    local syncRemote = eventsFolder and eventsFolder:FindFirstChild("DungeonInsideSync")
    if not syncRemote then
        return
    end
    local lastStatus = nil
    getgenv().HubAutoDungeonConnection = syncRemote.OnClientEvent:Connect(function(payload)
        if typeof(payload) ~= "table" or payload.Type ~= "State" then
            return
        end
        Extras.DungeonWave = payload.CurrentWave
        Extras.DungeonMaxWave = payload.MaxWave
        local hubState = getgenv().State
        local currentDungeon = workspaceService:GetAttribute("Dungeon")
        local twohRealm = hubState and Extras.Twoh.isActive() and currentDungeon == Extras.Twoh.RealmName
        if twohRealm then
            Extras.Twoh.DungeonStatus = payload.Status
        end
        Prestige.DungeonStatus = payload.Status
        if payload.Status == lastStatus then
            return
        end
        lastStatus = payload.Status
        if twohRealm then
            if payload.Status == "Vote" then
                task.delay(1, function()
                    pcall(function()
                        syncRemote:FireServer("Vote", Extras.Twoh.RealmDifficulty)
                    end)
                end)
            end
            return
        end
        if Prestige.ownsDungeon(currentDungeon) then
            Prestige.onDungeonState(syncRemote, payload.Status, currentDungeon)
            return
        end
        if not hubState or not hubState.AutoDungeonEnabled or hubState.AutoArayaEnabled then
            return
        end
        if payload.Status == "Vote" then
            task.delay(1, function()
                pcall(function()
                    syncRemote:FireServer("Vote", hubState.DungeonDifficulty or "Hard")
                end)
            end)
        elseif payload.Status == "Clear" or payload.Status == "Lose" then
            task.delay(2, function()
                pcall(function()
                    syncRemote:FireServer("ReplayVote")
                end)
            end)
        end
    end)
end

function Extras.pickDungeonTarget(rootPart)
    local bestEnemy, bestScore = nil, math.huge
    local floorY = Extras.DungeonFloorLevel
    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        local alive, enemyRoot = isLivingEnemy(enemy)
        if alive and floorY and enemyRoot.Position.Y > floorY + 150 then
            alive = false
            Extras.HighEnemySeenAt = os.clock()
        end
        if alive then
            local score = (enemyRoot.Position - rootPart.Position).Magnitude
            if enemy:GetAttribute("Boss") == true then
                score = score + 200
            end
            if score < bestScore then
                bestEnemy, bestScore = enemy, score
            end
        end
    end
    return bestEnemy
end

function Extras.solveDungeonSeal(prompt, dungeonName)
    local twoh = Extras.Twoh
    if twoh and twoh.hasWorld and twoh.hasWorld() then
        twoh.stillSeal(prompt)
        return
    end
    local holder = prompt.Parent
    local part = holder and (holder:IsA("BasePart") and holder or prompt:FindFirstAncestorWhichIsA("BasePart"))
    if not part then
        task.wait(0.2)
        return
    end
    local sealName = holder.Parent and holder.Parent.Name or "?"
    local standCFrame = CFrame.new(part.Position + Vector3.new(0, 4, 3))
    local rootPart = getRoot()
    if not rootPart then
        task.wait(0.2)
        return
    end
    local distance = (rootPart.Position - part.Position).Magnitude
    if distance > 7 then
        Extras.clearCombatLocks()
        Extras.dungeonStatus(string.format("[%s] moving to Chrono Seal %s", tostring(dungeonName), sealName))
        safeTravelTo(standCFrame, function()
            return (State.AutoDungeonEnabled or State.PrestigeEnabled) and prompt.Enabled
        end)
    end
    lockedEnemyRoot = nil
    lockedTargetCFrame = standCFrame
    Extras.dungeonStatus(string.format("[%s] activating Chrono Seal %s", tostring(dungeonName), sealName))
    triggerPrompt(prompt)
    task.wait(0.6)
    lockedTargetCFrame = nil
end

function Extras.runDungeonInside(dungeonName)
    Extras.connectAutoDungeon()
    pcall(Extras.queueArayaReload)
    if not acquireMovement("dungeon") then
        Extras.dungeonStatus("waiting for " .. tostring(movementOwner) .. " to finish")
        task.wait(1)
        return
    end
    local sealPrompt = Extras.Twoh and Extras.Twoh.findSealPrompt()
    if sealPrompt and not (Extras.Twoh and Extras.Twoh.anyLivingEnemy()) then
        Extras.solveDungeonSeal(sealPrompt, dungeonName)
        releaseMovement("dungeon")
        return
    end
    local waveText = string.format("wave %s/%s", tostring(Extras.DungeonWave or "?"), tostring(Extras.DungeonMaxWave or "?"))
    local rootPart = getRoot()
    local target = rootPart and Extras.pickDungeonTarget(rootPart)
    if target then
        Extras.DungeonIdleSince = nil
        Extras.dungeonStatus(string.format("[%s] fighting %s | %s", dungeonName, target.Name, waveText))
        farmMobWithAnchor(target.Name, function()
            return State.AutoDungeonEnabled and target.Parent ~= nil
        end, true)
    else
        Extras.dungeonStatus(string.format("[%s] waiting for the next wave | %s", dungeonName, waveText))
        local now = os.clock()
        Extras.DungeonIdleSince = Extras.DungeonIdleSince or now
        if now - Extras.DungeonIdleSince >= 12 and now - (Extras.DungeonNudgeAt or 0) >= 10 then
            Extras.DungeonNudgeAt = now
            local syncRemote = eventsFolder and eventsFolder:FindFirstChild("DungeonInsideSync")
            if syncRemote then
                pcall(function()
                    syncRemote:FireServer("ReplayVote")
                end)
                pcall(function()
                    syncRemote:FireServer("Vote", State.DungeonDifficulty or "Hard")
                end)
            end
        end
        task.wait(0.5)
    end
    releaseMovement("dungeon")
end

function Extras.enterSelectedDungeon(entry, isActive, statusSetter, prepareStyle)
    isActive = isActive or Extras.isDungeonActive
    statusSetter = statusSetter or Extras.dungeonStatus
    local portalRemote = eventsFolder and eventsFolder:FindFirstChild(entry.Portal)
    if not portalRemote then
        statusSetter(entry.Name .. " | portal remote not found")
        task.wait(2)
        return false
    end
    if prepareStyle then
        prepareStyle()
    elseif entry.Style and not isItemEquipped(entry.Style) then
        statusSetter(entry.Name .. " | equipping " .. entry.Style .. " (required)")
        equipInventoryItem(entry.Style)
    end
    local npc = Extras.goToNPCAt(entry.NPC, entry.NPCPosition, isActive, statusSetter)
    if not npc then
        statusSetter("cannot reach " .. entry.NPC)
        task.wait(1)
        return false
    end
    pcall(Extras.queueArayaReload)
    local sentAt = os.clock()
    local portalReplies = {}
    if Extras.PortalReplyConnection then
        pcall(function()
            Extras.PortalReplyConnection:Disconnect()
        end)
    end
    local replyConnection = portalRemote.OnClientEvent:Connect(function(kind, payload)
        table.insert(portalReplies, tostring(kind) .. (typeof(payload) == "string" and (":" .. payload) or ""))
    end)
    Extras.PortalReplyConnection = replyConnection
    Extras.LastPortalReplies = portalReplies
    statusSetter("opening the " .. entry.Name .. " lobby")
    if entry.Input then
        Extras.openArayaDialogue(npc)
    end
    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        pcall(fireproximityprompt, prompt)
    end
    task.wait(0.4)
    local keysBefore = entry.Item and getInventoryAmount(entry.Item) or nil
    if entry.Input then
        pcall(function()
            inputEvent:FireServer(entry.Input)
        end)
    else
        pcall(function()
            portalRemote:FireServer("Create")
        end)
    end
    local paidDeadline = os.clock() + 3
    while keysBefore and os.clock() < paidDeadline and getInventoryAmount(entry.Item) >= keysBefore do
        task.wait(0.1)
    end
    local keyPaid = keysBefore ~= nil and getInventoryAmount(entry.Item) < keysBefore
    Extras.LastEntryKeyPaid = keyPaid
    task.wait(0.8)
    for attempt = 1, (keyPaid and 3 or 1) do
        Extras.expectTeleport(30)
        pcall(function()
            portalRemote:FireServer("Start")
        end)
        statusSetter(string.format("starting %s | waiting for the teleport%s", entry.Name, attempt > 1 and (" (Start retry " .. attempt .. ", key already paid)") or ""))
        local deadline = os.clock() + (attempt == 1 and 25 or 15)
        while isActive() and os.clock() < deadline do
            task.wait(0.5)
        end
        if not isActive() then
            break
        end
    end
    replyConnection:Disconnect()
    if Extras.PortalReplyConnection == replyConnection then
        Extras.PortalReplyConnection = nil
    end
    if isActive() then
        local reply = (State.LastNotifyTime or 0) >= sentAt and tostring(State.LastNotifyText) or "no reply"
        statusSetter(entry.Name .. " did not start | key paid " .. tostring(keyPaid) .. " | " .. reply .. " | portal: " .. table.concat(portalReplies, ","))
        if not keyPaid then
            pcall(function()
                portalRemote:FireServer("Leave")
            end)
        end
        task.wait(3)
        return false
    end
    return true
end

function Extras.runDungeonCycle()
    local dungeonName = workspaceService:GetAttribute("Dungeon")
    if typeof(dungeonName) == "string" then
        if State.AutoArayaEnabled and Extras.isArayaDungeon(dungeonName) then
            task.wait(1)
            return
        end
        local realmOwner = Extras.Twoh.realmOwner()
        if realmOwner and dungeonName == Extras.Twoh.RealmName then
            Extras.dungeonStatus("paused: " .. realmOwner .. " owns Realm Beyond Heaven")
            task.wait(2)
            return
        end
        if Prestige.ownsDungeon(dungeonName) then
            Extras.dungeonStatus("paused: Auto Prestige is running " .. dungeonName)
            task.wait(2)
            return
        end
        Extras.runDungeonInside(dungeonName)
        return
    end

    local entry = Extras.getSelectedDungeon()
    local realmOwner = Extras.Twoh.realmOwner()
    if realmOwner and entry.Key == Extras.Twoh.RealmName then
        Extras.dungeonStatus("paused: " .. realmOwner .. " owns Realm Beyond Heaven and its keys")
        task.wait(3)
        return
    end
    if State.PrestigeEnabled and Prestige.DungeonWork then
        Extras.dungeonStatus("paused: Auto Prestige is heading to " .. tostring(Prestige.DungeonWork))
        task.wait(3)
        return
    end
    if entry.Quest and not UnlockFarm.isQuestCompleted(entry.Quest) then
        Extras.dungeonStatus(entry.Name .. " | finish the quest \"" .. entry.Quest .. "\" first")
        task.wait(3)
        return
    end
    if not acquireMovement("dungeon") then
        Extras.dungeonStatus("waiting for " .. tostring(movementOwner) .. " to finish")
        task.wait(1)
        return
    end
    if entry.Item and getInventoryAmount(entry.Item) < 1 then
        if entry.KeyBoss then
            local catalogItem = BossFarm.getSummonEntry(entry.KeyBoss)
            Extras.dungeonStatus(string.format("%s | no %s | farming %s for it", entry.Name, entry.Item, entry.KeyBoss))
            BossFarm.prepareAndKill(catalogItem, function()
                return State.AutoDungeonEnabled and getInventoryAmount(entry.Item) < 1
            end, "dungeon")
        else
            Extras.dungeonStatus(entry.Name .. " | missing " .. entry.Item)
            task.wait(3)
        end
    else
        Extras.enterSelectedDungeon(entry)
    end
    lockedTargetCFrame = nil
    releaseMovement("dungeon")
end

function Extras.resumeArayaAfterTeleport()
    local settings = Extras.loadArayaSettings()
    if settings.Enabled ~= true then
        return
    end
    if typeof(settings.Difficulty) == "string" then
        Extras.Araya.Difficulty = settings.Difficulty
    end
    Extras.Araya.TimeSafeLosses = tonumber(settings.TimeSafeLosses) or 0
    Extras.stopFishing()
    Extras.syncToggle("FishToggle", false)
    Extras.startLoop("AutoArayaEnabled", Extras.runArayaCycle)
    Extras.syncToggle("ArayaToggle", true)
end

Extras.Twoh = {
    NPCName = "Dio",
    NPCPosition = Vector3.new(-2644, 102, 3279),
    QuestNPCs = {
        Dio = Vector3.new(-2644, 102, 3279),
        ["The Gatekeeper"] = Vector3.new(-876, 114, -1547)
    },
    StyleName = "The World",
    BossName = "Dio",
    EarnedFlag = "TheWorldOverHeavenEarned",
    RequiredLevel = 10,
    Quests = { "Earthly Proofs 1", "Earthly Proofs 2", "Earthly Proofs 3", "Earthly Proofs 4", "Earthly Proofs 5" },
    NextSteps = { "EP1 Dio", "EP2 diaries", "EP3 Chrono Seals", "EP4 Echo of the Rewritten Hour", "EP5 Proofs of Heaven" },
    AcceptGrace = 8,
    AcceptSeenAt = {},
    EnhanceLevel = nil,
    EnhanceCheckedAt = -math.huge,
    SavedCombat = nil,
    WaitSince = nil,
    RealmRequesters = {},
    Delegated = false,
    PrestigeKillType = "DioHeavenAscensionKills"
}

function Extras.Twoh.status(message)
    State.ExtraStatus = "TWOH: " .. tostring(message)
    if Extras.Twoh.isDelegatedOnly() then
        State.PrestigeStatus = "Prestige: " .. tostring(Extras.Twoh.PrestigeLabel or "Dio Heaven Ascension kills") .. " | " .. tostring(message)
    end
end

function Extras.Twoh.isActive()
    return State.AutoTwohEnabled or (Extras.Twoh.Delegated == true and State.PrestigeEnabled == true)
end

function Extras.Twoh.isDelegatedOnly()
    return Extras.Twoh.Delegated == true and State.PrestigeEnabled == true and not State.AutoTwohEnabled
end

function Extras.Twoh.hasWorld()
    local dataFolder = localPlayer:FindFirstChild("Data")
    local inventoryFolder = dataFolder and dataFolder:FindFirstChild("Inventory")
    return inventoryFolder ~= nil and inventoryFolder:FindFirstChild(Extras.Twoh.StyleName) ~= nil
end

function Extras.Twoh.isEarned()
    local twoh = Extras.Twoh
    if localPlayer:GetAttribute(twoh.EarnedFlag) == true then
        return true
    end
    local dataFolder = localPlayer:FindFirstChild("Data")
    local flagValue = dataFolder and dataFolder:FindFirstChild(twoh.EarnedFlag)
    return flagValue ~= nil and flagValue:IsA("BoolValue") and flagValue.Value == true
end

function Extras.Twoh.getEnhanceLevel()
    local twoh = Extras.Twoh
    local maxAge = (twoh.EnhanceLevel or 0) >= twoh.RequiredLevel and 600 or 30
    if os.clock() - twoh.EnhanceCheckedAt < maxAge then
        return twoh.EnhanceLevel
    end
    twoh.EnhanceCheckedAt = os.clock()
    local dataFolder = localPlayer:FindFirstChild("Data")
    local inventoryFolder = dataFolder and dataFolder:FindFirstChild("Inventory")
    local item = inventoryFolder and inventoryFolder:FindFirstChild(twoh.StyleName)
    local identityValue = item and item:FindFirstChild("Identity")
    local snapshotRemote = remotesFolder:FindFirstChild("RF_SpecEnchantGetSnapshot")
    if not identityValue or not snapshotRemote then
        return twoh.EnhanceLevel
    end
    local finished, reply = false, nil
    task.spawn(function()
        local ok, result = pcall(function()
            return snapshotRemote:InvokeServer(identityValue.Value)
        end)
        if ok then
            reply = result
        end
        finished = true
    end)
    local deadline = os.clock() + 5
    while not finished and os.clock() < deadline do
        task.wait(0.1)
    end
    if typeof(reply) == "table" and reply.ok ~= false then
        local level = tonumber(reply.Level) or (typeof(reply.Snapshot) == "table" and tonumber(reply.Snapshot.Level)) or nil
        if level then
            twoh.EnhanceLevel = level
        end
    end
    return twoh.EnhanceLevel
end

function Extras.Twoh.getStage()
    local twoh = Extras.Twoh
    if twoh.isEarned() or UnlockFarm.isQuestCompleted(twoh.Quests[5]) then
        return "done"
    end
    if not twoh.hasWorld() then
        return "needsWorld"
    end
    for index, questName in ipairs(twoh.Quests) do
        if not UnlockFarm.isQuestCompleted(questName) then
            if not UnlockFarm.getActiveQuestFolder(questName) then
                if index == 1 then
                    local level = twoh.getEnhanceLevel()
                    if level and level < twoh.RequiredLevel then
                        return "needsEnhance", questName, index
                    end
                end
                return "accept", questName, index
            end
            if UnlockFarm.isQuestReadyToClaim(questName) then
                return "claim", questName, index
            end
            if index == 1 then
                return "dio", questName, index
            end
            return "ep" .. index, questName, index
        end
    end
    return "done"
end

function Extras.Twoh.claim()
    local twoh = Extras.Twoh
    if Extras.PriorityRequest == nil then
        Extras.PriorityRequest = "twoh"
    end
    if Extras.PriorityRequest ~= "twoh" then
        twoh.WaitSince = nil
        return false, Extras.PriorityRequest
    end
    if acquireMovement("twoh") then
        twoh.WaitSince = nil
        twoh.Idle = false
        return true
    end
    twoh.WaitSince = twoh.WaitSince or os.clock()
    local teleporting = (Extras.RevertWatch.ExpectUntil or 0) > os.clock()
    local entering = movementOwner == "dungeon" or movementOwner == "araya"
    if os.clock() - twoh.WaitSince > 8 and not teleporting and not entering then
        stopTween()
        movementOwner = nil
    end
    return false, movementOwner
end

function Extras.Twoh.releaseAll()
    if Extras.PriorityRequest == "twoh" then
        Extras.PriorityRequest = nil
    end
    Extras.Twoh.WaitSince = nil
    Extras.Twoh.Idle = false
    Extras.Twoh.stopFishing()
    releaseMovement("twoh")
end

function Extras.Twoh.startFishing()
    local twoh = Extras.Twoh
    local fishingState = Extras.Fishing
    if not Extras.TwohFishing and State.AutoFishEnabled and fishingState.Session and not fishingState.Finished then
        local remote = Extras.getFishingRemote()
        if remote then
            Extras.releaseFishingSession(remote, fishingState.Session)
        end
        Extras.resetFishingRound()
        task.wait(0.5)
    end
    if not twoh.FishStartedAt then
        local fishing = Extras.Fishing
        fishing.Caught = 0
        fishing.Missed = 0
        fishing.Rejects = 0
        fishing.LastCatch = nil
        fishing.AimPoint = nil
        fishing.StartedAt = os.clock()
        twoh.FishStartedAt = os.clock()
    end
    Extras.TwohFishing = true
    Extras.TwohFishingThread = coroutine.running()
end

function Extras.Twoh.stopFishing()
    local twoh = Extras.Twoh
    if twoh.FishSpot and lockedTargetCFrame == twoh.FishSpot then
        lockedTargetCFrame = nil
    end
    twoh.FishSpot = nil
    if not Extras.TwohFishing then
        return
    end
    Extras.TwohFishing = false
    Extras.TwohFishingThread = nil
    if not State.AutoFishEnabled and not Extras.DeepsharkFishing and not Extras.WhaleFishing then
        Extras.stopFishing()
    end
end

function Extras.Twoh.fail(reason)
    local twoh = Extras.Twoh
    twoh.Fails = (twoh.Fails or 0) + 1
    if twoh.Fails >= 3 and twoh.isDelegatedOnly() then
        twoh.Fails = 0
        twoh.prestigeGiveUp(reason)
        return
    end
    if twoh.Fails >= 3 then
        twoh.Fails = 0
        twoh.idle(reason .. " | retrying in 30s")
        local resumeAt = os.clock() + 27
        while twoh.isActive() and os.clock() < resumeAt do
            task.wait(0.5)
        end
        return
    end
    twoh.status(string.format("%s (attempt %d/3)", reason, twoh.Fails))
    task.wait(1)
end

function Extras.Twoh.applyStyle()
    local twoh = Extras.Twoh
    if not twoh.SavedCombat then
        twoh.SavedCombat = {}
        if not isItemEquipped(twoh.StyleName) then
            local dataFolder = localPlayer:FindFirstChild("Data")
            local currentStyle = dataFolder and dataFolder:FindFirstChild("CurrentStyle")
            local previous = currentStyle and Extras.findInventoryItemByIdentity(currentStyle.Value) or nil
            twoh.SavedCombat.Style = previous or "__none"
            getgenv().HubTwohPrevStyle = twoh.SavedCombat.Style
        elseif typeof(getgenv().HubTwohPrevStyle) == "string" then
            twoh.SavedCombat.Style = getgenv().HubTwohPrevStyle
        end
    end
    if not isItemEquipped(twoh.StyleName) then
        equipInventoryItem(twoh.StyleName)
    end
end

function Extras.Twoh.restoreStyle()
    local twoh = Extras.Twoh
    local saved = twoh.SavedCombat
    if not saved then
        local marker = getgenv().HubTwohPrevStyle
        if marker == "__none" or (typeof(marker) == "string" and getInventoryAmount(marker) <= 0) then
            getgenv().HubTwohPrevStyle = nil
        elseif typeof(marker) == "string" and marker ~= twoh.StyleName and isItemEquipped(twoh.StyleName) and (twoh.RestoreTries or 0) < 3 then
            twoh.RestoreTries = (twoh.RestoreTries or 0) + 1
            if equipInventoryItem(marker) then
                getgenv().HubTwohPrevStyle = nil
                twoh.RestoreTries = 0
            end
        end
        return
    end
    twoh.SavedCombat = nil
    local previous = saved.Style
    if previous and previous ~= "__none" and previous ~= twoh.StyleName and getInventoryAmount(previous) > 0 then
        if equipInventoryItem(previous) then
            getgenv().HubTwohPrevStyle = nil
        end
    else
        getgenv().HubTwohPrevStyle = nil
    end
end

function Extras.Twoh.stop(syncUI)
    Extras.stopLoop("AutoTwohEnabled", "twoh")
    Extras.Twoh.releaseAll()
    Extras.Twoh.unlockF()
    Extras.Twoh.restoreDungeonHelper()
    if syncUI then
        Extras.syncToggle("TwohToggle", false)
    end
    task.spawn(Extras.Twoh.restoreStyle)
end

function Extras.Twoh.prestigeGiveUp(reason)
    local twoh = Extras.Twoh
    twoh.PrestigeGiveUpUntil = os.clock() + 600
    twoh.PrestigeGiveUpReason = tostring(reason)
    twoh.PrestigeCheckUntil = nil
    twoh.log("PRESTIGE GIVE UP " .. tostring(reason))
    twoh.idle(tostring(reason) .. " | Prestige continues with other requirements for 10 min")
end

function Extras.Twoh.idle(message)
    local twoh = Extras.Twoh
    twoh.releaseAll()
    twoh.Idle = true
    twoh.restoreStyle()
    twoh.status(message)
    task.wait(3)
end

function Extras.Twoh.questNPCName(questName, index)
    local twoh = Extras.Twoh
    local questInfo = questData.Main[questName]
    if index == 1 or typeof(questInfo) ~= "table" or typeof(questInfo.NPC) ~= "string" then
        return twoh.NPCName
    end
    return questInfo.NPC
end

function Extras.Twoh.goToNPC(npcName)
    local twoh = Extras.Twoh
    return Extras.goToNPCAt(npcName, twoh.QuestNPCs[npcName] or twoh.NPCPosition, twoh.isActive, twoh.status)
end

function Extras.Twoh.inAcceptGrace(questName, index)
    local twoh = Extras.Twoh
    if index <= 1 then
        return false
    end
    local seenAt = twoh.AcceptSeenAt[questName] or os.clock()
    twoh.AcceptSeenAt[questName] = seenAt
    return os.clock() - seenAt < twoh.AcceptGrace
end

function Extras.Twoh.acceptQuest(questName, index)
    local twoh = Extras.Twoh
    local npcName = twoh.questNPCName(questName, index)
    local function accepted()
        return UnlockFarm.getActiveQuestFolder(questName) ~= nil or UnlockFarm.isQuestCompleted(questName)
    end
    twoh.status("going to " .. npcName .. " to accept " .. questName)
    local npc = twoh.goToNPC(npcName)
    if not npc then
        twoh.fail("cannot reach " .. npcName .. " to accept " .. questName)
        return
    end
    if index > 1 then
        invokeInput("Quest", "Accept", npc, questName)
        task.wait(0.5)
        if accepted() then
            twoh.Fails = 0
            twoh.status(questName .. " accepted (fallback Quest Accept)")
            return
        end
    end
    if npcName == twoh.NPCName and Extras.openArayaDialogue(npc) then
        twoh.status("asking Dio about the road to Heaven")
        Extras.pickArayaChoice("ask about the road to heaven", accepted)
        Extras.pickArayaChoice("i am ready to walk it", accepted)
        local deadline = os.clock() + 3
        while not accepted() and os.clock() < deadline do
            task.wait(0.2)
        end
    end
    if accepted() then
        twoh.Fails = 0
        twoh.status(questName .. " accepted")
    else
        twoh.fail(questName .. " was not accepted | " .. tostring(State.LastNotifyText))
    end
end

function Extras.Twoh.fightBoss(bossName, stopFn, label)
    local twoh = Extras.Twoh
    local entry = BossFarm.getSummonEntry(bossName)
    if not entry then
        twoh.fail("no summon entry for " .. bossName)
        return
    end
    twoh.status(label)
    local ticketsBefore, moneyBefore = getInventoryAmount("Boss Ticket"), getMoney()
    local result = BossFarm.prepareAndKill(entry, function()
        return twoh.isActive() and stopFn()
    end, "twoh")
    local progressed = result == true or BossFarm.isBossAlive(bossName) or getInventoryAmount("Boss Ticket") ~= ticketsBefore or getMoney() ~= moneyBefore
    if progressed or not stopFn() then
        twoh.Fails = 0
    else
        twoh.fail(bossName .. ": no progress | " .. tostring(State.LastNotifyText))
    end
end

function Extras.Twoh.fightDio(questName)
    local twoh = Extras.Twoh
    twoh.fightBoss(twoh.BossName, function()
        return UnlockFarm.getActiveQuestFolder(questName) ~= nil and not UnlockFarm.isQuestReadyToClaim(questName)
    end, string.format("%s | kill Dio %d/1 | %d Boss Ticket", questName, Extras.getQuestProgress(questName), getInventoryAmount("Boss Ticket")))
end

Extras.Twoh.DiaryItem = "Heavenly Diary"
Extras.Twoh.DiaryGoal = 5

function Extras.Twoh.getDiaries(questName)
    return math.max(Extras.getQuestProgress(questName), getInventoryAmount(Extras.Twoh.DiaryItem))
end

function Extras.Twoh.fishAt(hoverCFrame, label, stillValid)
    local twoh = Extras.Twoh
    local rootPart = getRoot()
    if not rootPart then
        task.wait(1)
        return
    end
    if (hoverCFrame.Position - rootPart.Position).Magnitude > 30 then
        twoh.stopFishing()
        Extras.clearCombatLocks()
        twoh.status(label .. " | flying there")
        safeTravelTo(hoverCFrame, function()
            return twoh.isActive() and (stillValid == nil or stillValid())
        end)
        rootPart = getRoot()
        if not rootPart or (hoverCFrame.Position - rootPart.Position).Magnitude > 60 then
            if stillValid == nil or stillValid() then
                twoh.fail("could not reach the fishing spot (" .. label .. ")")
            end
            return
        end
        Extras.Fishing.AimPoint = nil
    end
    twoh.FishSpot = hoverCFrame
    lockedTargetCFrame = hoverCFrame
    twoh.startFishing()
    local caughtBefore = Extras.Fishing.Caught
    twoh.status(label .. " | " .. tostring(State.FishStatus))
    Extras.runFishingCycle()
    if Extras.Fishing.Caught > caughtBefore then
        twoh.Fails = 0
    elseif string.find(tostring(State.FishStatus), "no open water", 1, true) or string.find(tostring(State.FishStatus), "no fishing rod", 1, true) then
        twoh.OpenSpot = nil
        twoh.fail("fishing failed | " .. tostring(State.FishStatus))
    end
    twoh.status(label .. " | " .. tostring(State.FishStatus))
end

function Extras.Twoh.summonDeepshark(prefix)
    local twoh = Extras.Twoh
    twoh.stopFishing()
    lockedTargetCFrame = nil
    twoh.status(prefix .. " | taking Abyssal Bait to the open sea")
    if not Extras.goToDeepSea(nil, "out to the open sea", twoh.isActive) then
        twoh.fail("could not reach the open sea for the Ancient Deepshark")
        return
    end
    if not Extras.enterSeaWater(twoh.isActive) then
        twoh.fail("could not get into the water for the Ancient Deepshark")
        return
    end
    twoh.status(prefix .. string.format(" | using Abyssal Bait (%d left)", getInventoryAmount(Extras.DeepsharkBait)))
    local result, distance = Extras.useAbyssalBait()
    if result == "summoned" then
        twoh.Fails = 0
        local deadline = os.clock() + 6
        while twoh.isActive() and os.clock() < deadline and not Extras.getDeepsharkEnemy() do
            task.wait(0.2)
        end
    elseif result == "alive" then
        twoh.SharkBackoffUntil = os.clock() + 90
        twoh.status(prefix .. " | an Ancient Deepshark is already hunting about " .. tostring(distance or "?") .. " studs away")
        task.wait(1)
    elseif result == "land" then
        Extras.DeepSeaIndex = (Extras.DeepSeaIndex % #Extras.DeepSeaPoints) + 1
        twoh.fail("Abyssal Bait: too close to land")
    elseif result == "swim" then
        task.wait(0.5)
    else
        twoh.fail("Abyssal Bait: " .. tostring(result))
        if (twoh.Fails or 0) == 0 then
            twoh.SharkBackoffUntil = os.clock() + 300
        end
    end
end

function Extras.Twoh.runDiaries(questName)
    local twoh = Extras.Twoh
    local prefix = string.format("EP2 diaries %d/%d", twoh.getDiaries(questName), twoh.DiaryGoal)
    local function stillOnEP2()
        return twoh.isActive() and UnlockFarm.getActiveQuestFolder(questName) ~= nil
    end
    local shark = Extras.getDeepsharkEnemy()
    local rootPart = getRoot()
    local sharkRoot = shark and shark:FindFirstChild("HumanoidRootPart")
    if sharkRoot and rootPart and (sharkRoot.Position - rootPart.Position).Magnitude < 800 then
        twoh.stopFishing()
        twoh.status(prefix .. " | fighting the Ancient Deepshark (3% diary)")
        farmMobWithAnchor(Extras.DeepsharkName, function()
            return stillOnEP2() and shark.Parent ~= nil
        end, true)
        return
    end
    twoh.restoreStyle()
    local whale = Extras.findWhaleIndicator()
    if whale then
        twoh.fishAt(CFrame.new(whale.Position + Vector3.new(40, 6, 0)), prefix .. " | whale zone (x2)", function()
            return whale.Parent ~= nil and stillOnEP2()
        end)
        return
    end
    if getInventoryAmount(Extras.DeepsharkBait) > 0 and os.clock() >= (twoh.SharkBackoffUntil or 0) and next(Extras.DeepsharkRequesters) == nil then
        twoh.summonDeepshark(prefix)
        return
    end
    if not twoh.OpenSpot then
        local origin = rootPart and rootPart.Position
        local spot = origin and Extras.findOpenWaterSpot(origin)
        if not spot then
            twoh.fail("no open water found")
            return
        end
        twoh.OpenSpot = CFrame.new(spot.X, 8, spot.Z)
    end
    twoh.fishAt(twoh.OpenSpot, prefix .. " | open water", stillOnEP2)
end

Extras.Twoh.RealmName = "Realm Beyond Heaven"
Extras.Twoh.RealmDifficulty = "Easy"
Extras.Twoh.KeyItem = "Realm Beyond Heaven Key"
Extras.Twoh.KeyFarmTarget = 2
Extras.Twoh.KeyBoss = "Chihora"
Extras.Twoh.MoneyFloor = 500000
Extras.Twoh.MoneyTarget = 3000000
Extras.Twoh.StatePath = "LEGACY PIECE/twoh_state.json"
Extras.Twoh.LogPath = "LEGACY PIECE/twoh_realm_log.txt"
Extras.Twoh.MaxLoses = 3
Extras.Twoh.MaxWatchdog = 3
Extras.Twoh.ReplayWait = 25
Extras.Twoh.DropDelay = 3
Extras.Twoh.RealmStages = {
    ep3 = { Label = "EP3 Seals" },
    ep4 = { Label = "EP4 Echo" },
    ep5 = { Label = "EP5 Proofs" },
    prestige = { Label = "Realm Beyond Heaven" }
}
Extras.Twoh.WatchDrops = {
    ["Realm Beyond Heaven Key"] = true,
    ["Echo of the Rewritten Hour"] = true,
    ["Fragment of Heaven"] = true,
    ["Heavenly Chest"] = true,
    ["Heaven Ascension Relic"] = true,
    ["Stilled Shadow"] = true,
    ["Frozen Time Core"] = true,
    ["Chrono Echo"] = true
}

Extras.Twoh.Ep5Labels = { "FTC", "Relic", "Shadow", "Title", "Frag" }
Extras.Twoh.MoneyPhaseCap = 1200
Extras.Twoh.StuckSeconds = 900

function Extras.Twoh.getEp5()
    local twoh = Extras.Twoh
    local questName = twoh.Quests[5]
    local info = questData.Main[questName]
    local objectives = typeof(info) == "table" and typeof(info.Objectives) == "table" and info.Objectives or {}
    local progress = tonumber(Extras.getQuestProgress(questName)) or 0
    local result = { Short = 0, List = {} }
    for index = 1, #objectives do
        local objective = objectives[index]
        local have = math.floor(progress / (1000 ^ (index - 1))) % 1000
        local need = tonumber(objective.Amount) or 0
        local entry = { Target = objective.Target, Have = have, Need = need, Short = math.max(need - have, 0), Label = twoh.Ep5Labels[index] or tostring(objective.Target) }
        result.List[index] = entry
        result.Short = result.Short + entry.Short
    end
    return result
end

function Extras.Twoh.ep5Text(ep5)
    local parts = {}
    for _, entry in ipairs(ep5.List) do
        if entry.Label ~= "Title" then
            table.insert(parts, string.format("%s %d/%d", entry.Label, entry.Have, entry.Need))
        elseif entry.Short > 0 then
            table.insert(parts, string.format("Title 0/1 (pity %s)", tostring(localPlayer:GetAttribute("TitlePity_Dio_Heaven_Ascension") or 0)))
        end
    end
    return table.concat(parts, " ")
end

function Extras.Twoh.ep5Prefix(ep5)
    local twoh = Extras.Twoh
    local runNumber = twoh.Run and twoh.Run.Number or tonumber(twoh.loadState().RunCount) or 0
    return string.format("EP5 | %s | run %s | keys %d", twoh.ep5Text(ep5 or twoh.getEp5()), tostring(runNumber), getInventoryAmount(twoh.KeyItem))
end

function Extras.Twoh.ftcShort()
    local first = Extras.Twoh.getEp5().List[1]
    return first ~= nil and first.Short > 0
end

function Extras.Twoh.wantsRealmRun(stage)
    if stage == "ep3" or stage == "ep4" then
        return true
    end
    if stage ~= "ep5" then
        return false
    end
    local ep5 = Extras.Twoh.getEp5()
    if ep5.List[1] and ep5.List[1].Short > 0 then
        return false
    end
    for index = 2, #ep5.List do
        if ep5.List[index].Short > 0 then
            return true
        end
    end
    return false
end

function Extras.Twoh.moneyPhase(label)
    local twoh = Extras.Twoh
    local money = getMoney()
    if not twoh.MoneyPhase and money < twoh.MoneyFloor then
        twoh.MoneyPhase = true
        twoh.MoneyPhaseStartedAt = os.clock()
    end
    if twoh.MoneyPhase and (money >= twoh.MoneyTarget or os.clock() - (twoh.MoneyPhaseStartedAt or 0) > twoh.MoneyPhaseCap) then
        twoh.MoneyPhase = false
        return false
    end
    if not twoh.MoneyPhase then
        return false
    end
    local rank = Extras.getFireForceRank()
    if rank == "" or rank == "None" then
        twoh.MoneyPhase = false
        if twoh.isDelegatedOnly() then
            twoh.prestigeGiveUp(string.format("%s | money $%.2fM is below $%.1fM and Ambush is unavailable (Fire Force rank needed)", label, money / 1000000, twoh.MoneyFloor / 1000000))
            return true
        end
        twoh.idle(string.format("%s | money $%.2fM is below $%.1fM and Ambush is unavailable (Fire Force rank needed) | waiting", label, money / 1000000, twoh.MoneyFloor / 1000000))
        return true
    end
    local text = string.format("TWOH: %s | money $%.1fM/%.0fM | Ambush (%dm left in this phase)", label, money / 1000000, twoh.MoneyTarget / 1000000, math.max(0, math.floor((twoh.MoneyPhaseCap - (os.clock() - twoh.MoneyPhaseStartedAt)) / 60)))
    if twoh.isDelegatedOnly() then
        State.PrestigeStatus = "Prestige: " .. tostring(twoh.PrestigeLabel) .. " | " .. text
    end
    if not Extras.runAmbushDuty(function()
        return twoh.isActive() and getMoney() < twoh.MoneyTarget
    end, text) then
        State.ExtraStatus = text .. " | waiting for the next ambush | " .. tostring(State.LastNotifyText)
        task.wait(0.5)
    end
    return true
end

function Extras.Twoh.farmFTC(ep5)
    local twoh = Extras.Twoh
    local prefix = twoh.ep5Prefix(ep5)
    if twoh.moneyPhase(prefix) then
        return
    end
    twoh.fightBoss(twoh.BossName, twoh.ftcShort, string.format("%s | Dio for Frozen Time Core (15%%) | %d tickets", prefix, getInventoryAmount("Boss Ticket")))
end

function Extras.Twoh.claimEp5()
    local twoh = Extras.Twoh
    local questName = twoh.Quests[5]
    twoh.status(twoh.ep5Prefix() .. " | all objectives met | claiming at Dio")
    if twoh.goToNPC(twoh.NPCName) then
        invokeInput("Quest", "Claim", questName)
        task.wait(2)
    end
    if UnlockFarm.getActiveQuestFolder(questName) then
        twoh.fail("EP5 objectives met but the claim was not accepted | " .. tostring(State.LastNotifyText))
    end
end

function Extras.Twoh.loadState()
    local saved = {}
    pcall(function()
        local decoded = httpService:JSONDecode(readfile(Extras.Twoh.StatePath))
        if typeof(decoded) == "table" then
            saved = decoded
        end
    end)
    return saved
end

function Extras.Twoh.saveState(changes)
    local saved = Extras.Twoh.loadState()
    for key, value in pairs(changes) do
        saved[key] = value
    end
    pcall(writefile, Extras.Twoh.StatePath, httpService:JSONEncode(saved))
end

function Extras.Twoh.log(text)
    local line = os.date("%H:%M:%S") .. " " .. tostring(text) .. "\n"
    local ok = pcall(appendfile, Extras.Twoh.LogPath, line)
    if not ok then
        pcall(writefile, Extras.Twoh.LogPath, line)
    end
end

function Extras.Twoh.lockF()
    local twoh = Extras.Twoh
    if twoh.FLocked then
        return
    end
    local rules = Combat.SkillRules[twoh.StyleName]
    twoh.SavedFRule = { Had = rules ~= nil, Value = rules and rules.F or nil }
    if not rules then
        rules = {}
        Combat.SkillRules[twoh.StyleName] = rules
    end
    rules.F = "never"
    twoh.FLocked = true
end

function Extras.Twoh.unlockF()
    local twoh = Extras.Twoh
    if not twoh.FLocked then
        return
    end
    twoh.FLocked = false
    local saved = twoh.SavedFRule or {}
    if saved.Had then
        local rules = Combat.SkillRules[twoh.StyleName]
        if rules then
            rules.F = saved.Value
        end
    else
        Combat.SkillRules[twoh.StyleName] = nil
    end
end

function Extras.Twoh.connectFloorReset()
    if not getgenv().HubTwohEnemyAddConnection then
        getgenv().HubTwohEnemyAddConnection = enemiesFolder.ChildAdded:Connect(function()
            State.LastBossSpawnAt = os.clock()
        end)
    end
    if getgenv().HubTwohDungeonAttrConnection then
        return
    end
    getgenv().HubTwohDungeonAttrConnection = workspaceService:GetAttributeChangedSignal("Dungeon"):Connect(function()
        Extras.DungeonFloorLevel = nil
        Extras.DungeonCeiling = nil
    end)
end

function Extras.Twoh.muteDungeonHelper()
    local connection = getgenv().HubDungeonConnection
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
        getgenv().HubDungeonConnection = nil
        Extras.Twoh.HelperMuted = true
    end
end

function Extras.Twoh.restoreDungeonHelper()
    local twoh = Extras.Twoh
    if not twoh.HelperMuted then
        return
    end
    twoh.HelperMuted = false
    pcall(function()
        loadstring(Extras.DungeonHelperSource)()
    end)
end

function Extras.Twoh.combatReady()
    local types = State.FarmCombatTypes or {}
    local dataFolder = localPlayer:FindFirstChild("Data")
    local inventoryFolder = dataFolder and dataFolder:FindFirstChild("Inventory")
    return types.Ability == true and inventoryFolder ~= nil and inventoryFolder:FindFirstChild("Araya") ~= nil
end

function Extras.Twoh.halt(reason)
    local twoh = Extras.Twoh
    twoh.HaltReason = reason
    twoh.saveState({ Halt = reason })
    twoh.log("HALT " .. reason)
end

function Extras.Twoh.getRealmEntry()
    for _, entry in ipairs(Extras.Dungeons) do
        if entry.Key == Extras.Twoh.RealmName then
            return entry
        end
    end
    return nil
end

function Extras.Twoh.stageLabel(stage)
    local info = Extras.Twoh.RealmStages[stage or ""]
    return info and info.Label or tostring(stage)
end

function Extras.Twoh.realmStatus(phase)
    local twoh = Extras.Twoh
    local run = twoh.Run
    if twoh.isDelegatedOnly() then
        twoh.status(string.format("Realm run %s | keys %d | wave %s/%s | %s", run and tostring(run.Number) or "-", getInventoryAmount(twoh.KeyItem), tostring(Extras.DungeonWave or "?"), tostring(Extras.DungeonMaxWave or "?"), tostring(phase)))
        return
    end
    if twoh.Stage == "ep5" then
        if os.clock() - (twoh.Ep5CachedAt or 0) > 2 then
            twoh.Ep5Cached = twoh.getEp5()
            twoh.Ep5CachedAt = os.clock()
        end
        twoh.status(string.format("%s | wave %s/%s | %s", twoh.ep5Prefix(twoh.Ep5Cached), tostring(Extras.DungeonWave or "?"), tostring(Extras.DungeonMaxWave or "?"), tostring(phase)))
        return
    end
    twoh.status(string.format("%s | run %s | keys %d | wave %s/%s | %s", twoh.stageLabel(twoh.Stage), run and tostring(run.Number) or "-", getInventoryAmount(twoh.KeyItem), tostring(Extras.DungeonWave or "?"), tostring(Extras.DungeonMaxWave or "?"), tostring(phase)))
end

function Extras.Twoh.farmKeys(stage)
    local twoh = Extras.Twoh
    local keys = getInventoryAmount(twoh.KeyItem)
    local money = getMoney()
    local label = stage == "ep5" and twoh.ep5Prefix() or twoh.stageLabel(stage)
    if twoh.moneyPhase(string.format("%s | keys %d/%d", label, keys, twoh.KeyFarmTarget)) then
        return
    end
    local entry = BossFarm.getSummonEntry(twoh.KeyBoss)
    if not entry then
        twoh.fail("no summon entry for " .. twoh.KeyBoss)
        return
    end
    twoh.status(string.format("%s | keys %d/%d | %s (18%%) | %d Boss Ticket | $%.1fM", label, keys, twoh.KeyFarmTarget, twoh.KeyBoss, getInventoryAmount("Boss Ticket"), money / 1000000))
    local ticketsBefore = getInventoryAmount("Boss Ticket")
    local result = BossFarm.prepareAndKill(entry, function()
        return twoh.isActive() and getInventoryAmount(twoh.KeyItem) < twoh.KeyFarmTarget
    end, "twoh")
    local progressed = result == true or BossFarm.isBossAlive(twoh.KeyBoss) or getInventoryAmount("Boss Ticket") ~= ticketsBefore or getMoney() ~= money or getInventoryAmount(twoh.KeyItem) ~= keys
    if progressed then
        twoh.Fails = 0
    else
        twoh.fail(string.format("no keys and %s farming made no progress (tickets %d, money $%.1fM) | %s", twoh.KeyBoss, getInventoryAmount("Boss Ticket"), getMoney() / 1000000, tostring(State.LastNotifyText)))
    end
end

function Extras.Twoh.enterRealm(stage)
    local twoh = Extras.Twoh
    local entry = twoh.getRealmEntry()
    if not entry then
        twoh.fail("Realm Beyond Heaven entry data missing")
        return
    end
    local label = twoh.stageLabel(stage)
    local keysBefore = getInventoryAmount(twoh.KeyItem)
    twoh.saveState({ PendingKeys = keysBefore, PendingVia = "entry" })
    twoh.log(string.format("ENTER stage=%s keys=%d", tostring(stage), keysBefore))
    local started = Extras.enterSelectedDungeon(entry, twoh.isActive, function(message)
        twoh.status(label .. " | keys " .. getInventoryAmount(twoh.KeyItem) .. " | " .. tostring(message))
    end, twoh.applyStyle)
    if not started and twoh.isActive() then
        twoh.log(string.format("ENTER FAILED keys %d -> %d paid=%s portal=%s", keysBefore, getInventoryAmount(twoh.KeyItem), tostring(Extras.LastEntryKeyPaid), table.concat(Extras.LastPortalReplies or {}, ",")))
        twoh.fail("Realm Beyond Heaven did not start | keys " .. keysBefore .. " -> " .. getInventoryAmount(twoh.KeyItem))
    end
end

function Extras.Twoh.runRealmStage(stage)
    local twoh = Extras.Twoh
    if stage == "ep5" then
        local ep5 = twoh.getEp5()
        if ep5.List[1] and ep5.List[1].Short > 0 then
            twoh.farmFTC(ep5)
            return
        end
        if not twoh.wantsRealmRun(stage) then
            twoh.claimEp5()
            return
        end
    end
    local keys = getInventoryAmount(twoh.KeyItem)
    if keys <= 0 then
        twoh.FarmingKeys = true
    elseif keys >= twoh.KeyFarmTarget then
        twoh.FarmingKeys = false
    end
    if twoh.FarmingKeys then
        twoh.farmKeys(stage)
        return
    end
    twoh.enterRealm(stage)
end

function Extras.Twoh.leaveRealm(reason)
    local twoh = Extras.Twoh
    twoh.releaseAll()
    twoh.realmStatus("leaving (" .. tostring(reason) .. ")")
    if os.clock() - (twoh.LeaveSentAt or 0) > 8 then
        twoh.LeaveSentAt = os.clock()
        twoh.log("LEAVE " .. tostring(reason))
        Extras.expectTeleport(15)
        local leaveRemote = eventsFolder and eventsFolder:FindFirstChild("DungeonLeave")
        if leaveRemote then
            pcall(function()
                leaveRemote:FireServer()
            end)
        end
    end
    task.wait(1)
end

function Extras.Twoh.resetRunFields()
    local twoh = Extras.Twoh
    twoh.SealPrompt = nil
    twoh.SealStartedAt = nil
    twoh.SealRetries = 0
    twoh.RealmIdleSince = nil
    twoh.ClearAt = nil
    twoh.ReplayFailed = false
    twoh.LeaveSentAt = nil
    twoh.LastProgressAt = os.clock()
    twoh.ProgressSignature = nil
    twoh.LastPersistAt = 0
end

function Extras.Twoh.persistRun()
    local twoh = Extras.Twoh
    local run = twoh.Run
    if not run or run.Finished then
        return
    end
    twoh.LastPersistAt = os.clock()
    twoh.saveState({
        ActiveRun = {
            Id = run.Id,
            Number = run.Number,
            JobId = game.JobId,
            StartedAtTime = run.StartedAtTime,
            KeysBefore = run.KeysBefore,
            KeysAtStart = run.KeysAtStart,
            Stage = run.Stage,
            Via = run.Via,
            MaxYOverFloor = math.floor(run.MaxYOverFloor),
            Seals = run.Seals,
            Watchdog = run.Watchdog,
            Deaths = run.Deaths,
            ReplayVoteDelay = run.ReplayVoteDelay,
            SealHold = twoh.SealHoldSeen,
            Resumed = run.Resumed,
            Drops = State.TwohRunDrops and State.TwohRunDrops.Items or {},
            UpdatedAt = os.time()
        }
    })
end

function Extras.Twoh.recordRun(record, saved)
    local twoh = Extras.Twoh
    local runs = typeof(saved.Runs) == "table" and saved.Runs or {}
    for _, existing in ipairs(runs) do
        if record.Id and existing.Id == record.Id then
            return false
        end
    end
    table.insert(runs, record)
    while #runs > 60 do
        table.remove(runs, 1)
    end
    local totals = typeof(saved.Totals) == "table" and saved.Totals or {}
    totals.Runs = (tonumber(totals.Runs) or 0) + 1
    totals[record.Result] = (tonumber(totals[record.Result]) or 0) + 1
    totals.Deaths = (tonumber(totals.Deaths) or 0) + (tonumber(record.Deaths) or 0)
    totals.KeyDelta = (tonumber(totals.KeyDelta) or 0) + (tonumber(record.KeyDelta) or 0)
    totals.Seconds = (tonumber(totals.Seconds) or 0) + (tonumber(record.Duration) or 0)
    totals.Drops = typeof(totals.Drops) == "table" and totals.Drops or {}
    for itemName, amount in pairs(record.Drops or {}) do
        totals.Drops[itemName] = (tonumber(totals.Drops[itemName]) or 0) + (tonumber(amount) or 0)
    end
    saved.Runs = runs
    saved.Totals = totals
    return true
end

function Extras.Twoh.beginRun(resumeOnly)
    local twoh = Extras.Twoh
    local saved = twoh.loadState()
    local active = saved.ActiveRun
    if typeof(active) == "table" and active.JobId == game.JobId and os.time() - (tonumber(active.UpdatedAt) or 0) < 900 then
        twoh.Run = {
            Id = active.Id,
            Number = active.Number,
            StartedAtTime = active.StartedAtTime,
            StartedAt = os.clock() - math.max(0, os.time() - (tonumber(active.StartedAtTime) or os.time())),
            KeysBefore = active.KeysBefore,
            KeysAtStart = active.KeysAtStart,
            Stage = active.Stage or twoh.Stage,
            Via = active.Via,
            MaxYOverFloor = tonumber(active.MaxYOverFloor) or 0,
            Seals = typeof(active.Seals) == "table" and active.Seals or {},
            Watchdog = tonumber(active.Watchdog) or 0,
            Deaths = tonumber(active.Deaths) or 0,
            ReplayVoteDelay = active.ReplayVoteDelay,
            Resumed = (tonumber(active.Resumed) or 0) + 1
        }
        State.TwohRunDrops = { Watch = twoh.WatchDrops, Items = typeof(active.Drops) == "table" and active.Drops or {} }
        twoh.SealHoldSeen = active.SealHold == true
        twoh.ReplaySentAt = nil
        twoh.resetRunFields()
        twoh.persistRun()
        twoh.log(string.format("RUN %d RESUMED after a reload (resume #%d)", twoh.Run.Number, twoh.Run.Resumed))
        return true
    end
    if typeof(active) == "table" and active.Id then
        local keysNow = getInventoryAmount(twoh.KeyItem)
        twoh.recordRun({
            Id = active.Id,
            Run = active.Number,
            Stage = active.Stage,
            Result = "Abandoned",
            Via = active.Via,
            Duration = math.max(0, (tonumber(active.UpdatedAt) or os.time()) - (tonumber(active.StartedAtTime) or os.time())),
            KeysBefore = active.KeysBefore,
            KeysAfter = keysNow,
            KeyDelta = 0,
            Drops = active.Drops,
            Seals = active.Seals,
            Deaths = active.Deaths,
            MaxYOverFloor = active.MaxYOverFloor,
            At = os.time()
        }, saved)
        saved.ActiveRun = false
        pcall(writefile, twoh.StatePath, httpService:JSONEncode(saved))
        twoh.log(string.format("RUN %s recorded as Abandoned (other server or stale)", tostring(active.Number)))
    end
    if resumeOnly then
        return false
    end
    saved = twoh.loadState()
    local number = (tonumber(saved.RunCount) or 0) + 1
    local keysNow = getInventoryAmount(twoh.KeyItem)
    local via = typeof(saved.PendingVia) == "string" and saved.PendingVia or "resume"
    twoh.Run = {
        Id = string.format("%s:%d:%d", tostring(game.JobId), number, os.time()),
        Number = number,
        StartedAtTime = os.time(),
        StartedAt = os.clock(),
        KeysBefore = tonumber(saved.PendingKeys) or keysNow,
        KeysAtStart = keysNow,
        Stage = twoh.Stage,
        Via = via,
        MaxYOverFloor = 0,
        Seals = {},
        Watchdog = 0,
        Deaths = 0,
        Resumed = 0,
        ReplayVoteDelay = twoh.ReplaySentAt and math.floor((os.clock() - twoh.ReplaySentAt) * 10) / 10 or nil
    }
    State.TwohRunDrops = { Watch = twoh.WatchDrops, Items = {} }
    twoh.SealHoldSeen = false
    twoh.ReplaySentAt = nil
    twoh.resetRunFields()
    twoh.saveState({ RunCount = number, PendingKeys = false, PendingVia = false })
    twoh.persistRun()
    twoh.log(string.format("RUN %d START stage=%s via=%s keysBefore=%s keysNow=%d replayVoteDelay=%s", number, tostring(twoh.Stage), via, tostring(twoh.Run.KeysBefore), keysNow, tostring(twoh.Run.ReplayVoteDelay)))
    return true
end

function Extras.Twoh.finishRun(result)
    local twoh = Extras.Twoh
    local run = twoh.Run
    if not run or run.Finished then
        return
    end
    run.Finished = true
    local keysAfter = getInventoryAmount(twoh.KeyItem)
    local saved = twoh.loadState()
    twoh.recordRun({
        Id = run.Id,
        Run = run.Number,
        Stage = run.Stage,
        Result = result,
        Via = run.Via,
        Duration = math.floor(os.clock() - run.StartedAt),
        KeysBefore = run.KeysBefore,
        KeysAfter = keysAfter,
        KeyDelta = keysAfter - (run.KeysBefore or keysAfter),
        Drops = State.TwohRunDrops and State.TwohRunDrops.Items or {},
        Seals = run.Seals,
        SealHold = twoh.SealHoldSeen,
        MaxYOverFloor = math.floor(run.MaxYOverFloor),
        Watchdog = run.Watchdog,
        Deaths = run.Deaths,
        ReplayVoteDelay = run.ReplayVoteDelay,
        Resumed = run.Resumed,
        At = os.time()
    }, saved)
    local loseStreak = result == "Lose" and (tonumber(saved.LoseStreak) or 0) + 1 or 0
    saved.LoseStreak = loseStreak
    saved.ActiveRun = false
    pcall(writefile, twoh.StatePath, httpService:JSONEncode(saved))
    twoh.log(string.format("RUN %d END %s %ds keys %s -> %d deaths %d maxY+%d watchdog %d seals %d resumed %d", run.Number, result, math.floor(os.clock() - run.StartedAt), tostring(run.KeysBefore), keysAfter, run.Deaths, math.floor(run.MaxYOverFloor), run.Watchdog, #run.Seals, run.Resumed or 0))
    if loseStreak >= twoh.MaxLoses then
        twoh.halt(string.format("lost the Realm Beyond Heaven %d times in a row", loseStreak))
    end
end

function Extras.Twoh.sampleRealm()
    local twoh = Extras.Twoh
    local run = twoh.Run
    if not run or os.clock() - (twoh.LastSampleAt or 0) < 1 then
        return
    end
    twoh.LastSampleAt = os.clock()
    if os.clock() - (twoh.LastPersistAt or 0) > 10 then
        twoh.persistRun()
    end
    local rootPart, humanoid = getRoot()
    if humanoid and humanoid.Health <= 0 then
        if not twoh.WasDead then
            run.Deaths = run.Deaths + 1
            twoh.log(string.format("RUN %d DEATH", run.Number))
        end
        twoh.WasDead = true
    else
        twoh.WasDead = false
    end
    if workspaceService:GetAttribute("DungeonWaveHold") == true then
        twoh.SealHoldSeen = true
    end
    if not rootPart then
        return
    end
    local floorY = Extras.DungeonFloorLevel
    local over = floorY and (rootPart.Position.Y - floorY) or 0
    if over > run.MaxYOverFloor then
        run.MaxYOverFloor = over
    end
    local movers = {}
    for _, child in ipairs(rootPart:GetChildren()) do
        if child:IsA("BodyMover") or child:IsA("Constraint") then
            table.insert(movers, child.Name)
        end
    end
    local character = localPlayer.Character
    twoh.log(string.format("run %d Y %.0f (+%.0f) target %s acting %s movers [%s] %s", run.Number, rootPart.Position.Y, over, lockedEnemyRoot and string.format("%.0f", lockedEnemyRoot.Position.Y) or "-", tostring(character and character:FindFirstChild("Acting") ~= nil), table.concat(movers, ","), tostring(State.ExtraStatus)))
end

function Extras.Twoh.checkHeight()
    local twoh = Extras.Twoh
    local rootPart = getRoot()
    local floorY = Extras.DungeonFloorLevel
    if not rootPart or not floorY then
        return false
    end
    local over = rootPart.Position.Y - floorY
    if over <= 60 then
        twoh.LastGoodCFrame = rootPart.CFrame
    end
    if over <= 250 then
        return false
    end
    local run = twoh.Run
    if run then
        run.Watchdog = run.Watchdog + 1
    end
    twoh.log(string.format("WATCHDOG Y %.0f (+%.0f) | returning", rootPart.Position.Y, over))
    Extras.clearCombatLocks()
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    local target = twoh.LastGoodCFrame or CFrame.new(rootPart.Position.X, floorY + 8, rootPart.Position.Z)
    twoh.realmStatus(string.format("height watchdog (+%.0f) | returning down", over))
    safeTravelTo(target, function()
        return twoh.isActive()
    end)
    if run and run.Watchdog >= twoh.MaxWatchdog then
        twoh.halt("height watchdog fired " .. run.Watchdog .. " times in one run")
    end
    return true
end

function Extras.Twoh.handleRunEnd(status)
    local twoh = Extras.Twoh
    twoh.ClearAt = twoh.ClearAt or os.clock()
    if os.clock() - twoh.ClearAt < twoh.DropDelay then
        twoh.realmStatus(status .. " | collecting drops")
        task.wait(0.5)
        return
    end
    if twoh.Run and not twoh.Run.Finished then
        twoh.finishRun(status)
        if getInventoryAmount("Heavenly Chest") > 0 then
            local opened = AutoChest.openChest("Heavenly Chest")
            twoh.log("opened Heavenly Chest x" .. tostring(opened) .. " | keys now " .. getInventoryAmount(twoh.KeyItem))
        end
    end
    if twoh.HaltReason then
        twoh.leaveRealm(twoh.HaltReason)
        return
    end
    local stage = twoh.getStage()
    local delegatedOnly = twoh.isDelegatedOnly()
    local wantsRuns = (delegatedOnly and twoh.prestigeNeed() ~= nil) or (not delegatedOnly and twoh.wantsRealmRun(stage))
    local keys = getInventoryAmount(twoh.KeyItem)
    if wantsRuns and keys >= 1 and not twoh.ReplayFailed then
        if not twoh.ReplaySentAt then
            twoh.ReplaySentAt = os.clock()
            twoh.saveState({ PendingKeys = keys, PendingVia = "replay" })
            twoh.log(string.format("REPLAY vote sent keys=%d", keys))
            local syncRemote = eventsFolder and eventsFolder:FindFirstChild("DungeonInsideSync")
            if syncRemote then
                pcall(function()
                    syncRemote:FireServer("ReplayVote")
                end)
            end
        elseif os.clock() - twoh.ReplaySentAt > twoh.ReplayWait then
            twoh.ReplayFailed = true
            twoh.log(string.format("REPLAY no new Vote within %ds | keys %d", twoh.ReplayWait, getInventoryAmount(twoh.KeyItem)))
            twoh.saveState({ PendingKeys = false, PendingVia = false })
        end
        twoh.realmStatus(status .. " | replay voted, waiting for the next run")
        task.wait(0.5)
        return
    end
    local reason = "replay did not start"
    if not wantsRuns and delegatedOnly then
        reason = "Prestige has enough Dio Heaven Ascension kills"
    elseif not wantsRuns then
        reason = (stage == "ep5" and twoh.ftcShort()) and "Frozen Time Core short | Dio between runs" or ("stage " .. tostring(stage) .. " needs no more runs")
    elseif keys < 1 then
        reason = "no keys left"
    end
    twoh.leaveRealm(reason)
end

function Extras.Twoh.findSealPrompt()
    local islands = workspaceService:FindFirstChild("Islands")
    local realm = islands and islands:FindFirstChild(Extras.Twoh.RealmName)
    local inner = realm and realm:FindFirstChild(Extras.Twoh.RealmName)
    local seals = inner and inner:FindFirstChild("Chrono Seal")
    if not seals then
        return nil
    end
    for _, prompt in ipairs(seals:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            return prompt
        end
    end
    return nil
end

function Extras.Twoh.anyLivingEnemy()
    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if isLivingEnemy(enemy) then
            return true
        end
    end
    return false
end

function Extras.Twoh.holdTheWorld()
    local twoh = Extras.Twoh
    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local backpack = localPlayer:FindFirstChild("Backpack")
    local tool = character and (character:FindFirstChild(twoh.StyleName) or (backpack and backpack:FindFirstChild(twoh.StyleName)))
    if not tool or not humanoid then
        twoh.applyStyle()
        return nil
    end
    if tool.Parent ~= character then
        humanoid:EquipTool(tool)
        local deadline = os.clock() + 0.5
        while tool.Parent ~= character and os.clock() < deadline do
            task.wait(0.03)
        end
    end
    return tool.Parent == character and tool or nil
end

function Extras.Twoh.windowLeft()
    local untilAt = State.TwohZaWarudoUntil
    return untilAt and (untilAt - os.clock()) or 0
end

function Extras.Twoh.castZaWarudo(aimPosition)
    local twoh = Extras.Twoh
    local tool = twoh.holdTheWorld()
    if not tool then
        return false
    end
    local character = localPlayer.Character
    local actingDeadline = os.clock() + 1.5
    while character and (character:FindFirstChild("Acting") or character:FindFirstChild("Stunned")) and os.clock() < actingDeadline do
        task.wait(0.03)
    end
    local readyAt = State.SkillCooldowns[twoh.StyleName .. "|F"] or 0
    State.TwohZaWarudoUntil = nil
    twoh.LastCastAt = os.clock()
    pcall(function()
        inputEvent:FireServer("Tool", tool, "F", aimPosition)
    end)
    local deadline = os.clock() + 1.6
    while os.clock() < deadline do
        if twoh.windowLeft() > 0 then
            return true
        end
        if (State.SkillCooldowns[twoh.StyleName .. "|F"] or 0) > readyAt + 1 then
            if not State.TwohZaWarudoUntil then
                State.TwohZaWarudoUntil = os.clock() + 9
            end
            return true
        end
        task.wait(0.03)
    end
    return false
end

function Extras.Twoh.stillSeal(prompt)
    local twoh = Extras.Twoh
    local holder = prompt.Parent
    local part = holder and (holder:IsA("BasePart") and holder or prompt:FindFirstAncestorWhichIsA("BasePart"))
    if not part then
        task.wait(0.2)
        return
    end
    local sealName = holder.Parent and holder.Parent.Name or "?"
    local questName = twoh.Quests[3]
    if twoh.SealPrompt ~= prompt then
        twoh.SealPrompt = prompt
        twoh.SealStartedAt = os.clock()
        twoh.SealRetries = 0
    end
    if os.clock() - twoh.SealStartedAt > 70 then
        twoh.SealRetries = (twoh.SealRetries or 0) + 1
        twoh.SealStartedAt = os.clock()
        twoh.log(string.format("SEAL %s no progress for 70s (retry %d) | last reply: %s", sealName, twoh.SealRetries, tostring(State.LastNotifyText)))
        if twoh.SealRetries >= 3 then
            twoh.finishRun("SealStuck")
            twoh.ReplayFailed = true
            twoh.leaveRealm("seal stuck")
            return
        end
    end
    local rootPart = getRoot()
    if not rootPart then
        task.wait(0.2)
        return
    end
    local standCFrame = CFrame.new(part.Position + Vector3.new(0, 4, 3))
    local distance = (rootPart.Position - part.Position).Magnitude
    local speed = math.max(tonumber(State.TweenSpeed) or 60, 1)
    local windowLeft = twoh.windowLeft()
    local stopAt = State.TwohZaWarudoUntil and (State.TwohZaWarudoUntil - 9) or nil

    if windowLeft <= 0.3 then
        local cooldownLeft = (State.SkillCooldowns[twoh.StyleName .. "|F"] or 0) - workspaceService:GetServerTimeNow() + 0.25
        local reachable = distance / speed + 1.4 < 8.3
        if cooldownLeft <= 0 and reachable then
            twoh.realmStatus(string.format("casting Za Warudo for Chrono Seal %s (%.0f studs away)", sealName, distance))
            if twoh.castZaWarudo(part.Position) then
                twoh.SealCastAt = twoh.LastCastAt
                return
            end
            twoh.realmStatus("Chrono Seal " .. sealName .. ": Za Warudo did not start | retrying")
            task.wait(0.2)
            return
        end
        if distance > 7 then
            Extras.clearCombatLocks()
            twoh.realmStatus(string.format("moving to Chrono Seal %s | Za Warudo in %.0fs", sealName, math.max(cooldownLeft, 0)))
            safeTravelTo(standCFrame, function()
                return twoh.isActive() and prompt.Enabled
            end)
        end
        lockedEnemyRoot = nil
        lockedTargetCFrame = standCFrame
        if cooldownLeft > 0 then
            twoh.holdTheWorld()
            twoh.realmStatus(string.format("at Chrono Seal %s | Za Warudo ready in %.1fs", sealName, cooldownLeft))
            task.wait(math.clamp(cooldownLeft, 0.03, 0.25))
        end
        return
    end

    if distance > 7 then
        Extras.clearCombatLocks()
        twoh.realmStatus(string.format("racing to Chrono Seal %s | time stop %.1fs left", sealName, windowLeft))
        safeTravelTo(standCFrame, function()
            return twoh.isActive() and prompt.Enabled and twoh.windowLeft() > 0.2
        end)
        rootPart = getRoot()
        if not rootPart then
            return
        end
        distance = (rootPart.Position - part.Position).Magnitude
    end
    lockedEnemyRoot = nil
    lockedTargetCFrame = standCFrame
    if distance > 9 then
        twoh.realmStatus(string.format("Chrono Seal %s: %.0f studs away when the time stop ended", sealName, distance))
        return
    end
    if stopAt and os.clock() < stopAt + 0.5 then
        task.wait(stopAt + 0.5 - os.clock())
    end
    if twoh.windowLeft() <= 0.1 then
        return
    end
    local before = Extras.getQuestProgress(questName)
    local ep3Active = UnlockFarm.getActiveQuestFolder(questName) ~= nil
    local firedAt = os.clock()
    local notifyBefore = State.LastNotifyTime or 0
    pcall(fireproximityprompt, prompt)
    local function sealed()
        if not prompt.Enabled or prompt.Parent == nil then
            return true
        end
        if State.LastObtain == "Chrono Echo" and (State.LastObtainTime or 0) >= firedAt then
            return true
        end
        if (State.LastBossSpawnAt or 0) >= firedAt then
            return true
        end
        return ep3Active and Extras.getQuestProgress(questName) > before
    end
    local verifyDeadline = os.clock() + 1.2
    while os.clock() < verifyDeadline and not sealed() do
        task.wait(0.03)
    end
    if sealed() then
        twoh.Fails = 0
        local acceptedAt = os.clock()
        local enabledAt = twoh.SealEnabledAt or twoh.SealStartedAt or acceptedAt
        local record = {
            Seal = sealName,
            Seconds = math.floor((acceptedAt - enabledAt) * 10) / 10,
            FromClear = math.floor((acceptedAt - (twoh.SealStartedAt or acceptedAt)) * 10) / 10,
            CastToAccept = twoh.SealCastAt and math.floor((acceptedAt - twoh.SealCastAt) * 10) / 10 or nil,
            Window = "stop"
        }
        if twoh.Run then
            table.insert(twoh.Run.Seals, record)
            twoh.persistRun()
        end
        twoh.log(string.format("SEAL %s stilled %.1fs after it enabled, %.1fs after the area was clear (cast to accept %s)", sealName, record.Seconds, record.FromClear, tostring(record.CastToAccept)))
        twoh.SealPrompt = nil
        twoh.SealCastAt = nil
        lockedTargetCFrame = nil
        twoh.realmStatus("Chrono Seal " .. sealName .. " stilled | the shadow comes")
    else
        local reply = (State.LastNotifyTime or 0) > notifyBefore and tostring(State.LastNotifyText) or "no reply"
        twoh.log(string.format("SEAL %s prompt not accepted (%s) | window %.1fs left", sealName, reply, twoh.windowLeft()))
        twoh.realmStatus(string.format("Chrono Seal %s: prompt not accepted (%s) | retrying", sealName, reply))
    end
end

function Extras.Twoh.runRealm()
    local twoh = Extras.Twoh
    Extras.connectAutoDungeon()
    pcall(Extras.queueArayaReload)
    twoh.muteDungeonHelper()
    twoh.Stage = twoh.getStage()
    local status = twoh.DungeonStatus
    local ended = status == "Clear" or status == "Lose"
    if twoh.Run and twoh.Run.Finished and not ended then
        twoh.Run = nil
    end
    if not twoh.Run then
        twoh.beginRun(ended)
    end
    twoh.sampleRealm()
    if ended then
        twoh.handleRunEnd(status)
        return
    end
    if twoh.Stage == "ep5" and not twoh.isDelegatedOnly() and not twoh.wantsRealmRun("ep5") then
        twoh.finishRun("LeftEarly")
        twoh.ReplayFailed = true
        twoh.leaveRealm(twoh.ftcShort() and "only Frozen Time Core is missing | going to Dio" or "EP5 needs nothing from the realm")
        return
    end
    local signature = string.format("%s|%s|%d|%d", tostring(status), tostring(Extras.DungeonWave), #enemiesFolder:GetChildren(), #(twoh.Run and twoh.Run.Seals or {}))
    if signature ~= twoh.ProgressSignature then
        twoh.ProgressSignature = signature
        twoh.LastProgressAt = os.clock()
    elseif os.clock() - (twoh.LastProgressAt or os.clock()) > twoh.StuckSeconds then
        twoh.log("STUCK no wave or status progress for " .. twoh.StuckSeconds .. "s")
        twoh.finishRun("Stuck")
        twoh.ReplayFailed = true
        twoh.leaveRealm("no progress for 15 minutes")
        return
    end
    if twoh.HaltReason then
        twoh.leaveRealm(twoh.HaltReason)
        return
    end
    if not twoh.isDelegatedOnly() and not twoh.combatReady() then
        twoh.releaseAll()
        twoh.realmStatus("set Auto Farm combat type to Ability (Araya)")
        task.wait(2)
        return
    end
    local owned, holder = twoh.claim()
    if not owned then
        twoh.realmStatus("waiting for " .. tostring(holder))
        task.wait(0.5)
        return
    end
    twoh.applyStyle()
    if twoh.checkHeight() then
        releaseMovement("twoh")
        return
    end
    local sealPrompt = twoh.findSealPrompt()
    if sealPrompt ~= twoh.SeenSealPrompt then
        twoh.SeenSealPrompt = sealPrompt
        twoh.SealEnabledAt = sealPrompt and os.clock() or nil
    end
    if sealPrompt and not twoh.anyLivingEnemy() then
        twoh.stillSeal(sealPrompt)
        releaseMovement("twoh")
        return
    end
    local rootPart = getRoot()
    local target = rootPart and Extras.pickDungeonTarget(rootPart)
    if target then
        twoh.RealmIdleSince = nil
        twoh.realmStatus("fighting " .. target.Name)
        farmMobWithAnchor(target.Name, function()
            return twoh.isActive() and target.Parent ~= nil
        end, true)
    else
        local now = os.clock()
        twoh.RealmIdleSince = twoh.RealmIdleSince or now
        local tooHigh = now - (Extras.HighEnemySeenAt or 0) < 2
        twoh.realmStatus(tooHigh and "enemy out of reach (too high) | waiting" or (tostring(status) .. " | waiting for enemies"))
        if now - twoh.RealmIdleSince >= 12 and now - (twoh.RealmNudgeAt or 0) >= 10 then
            twoh.RealmNudgeAt = now
            local syncRemote = eventsFolder and eventsFolder:FindFirstChild("DungeonInsideSync")
            if syncRemote then
                pcall(function()
                    syncRemote:FireServer("Vote", twoh.RealmDifficulty)
                end)
            end
        end
        task.wait(0.2)
    end
    releaseMovement("twoh")
end

function Extras.Twoh.runCycle()
    local twoh = Extras.Twoh
    twoh.lockF()
    twoh.connectFloorReset()
    local ok, errorMessage = pcall(twoh.runStep)
    if not ok then
        twoh.unlockF()
        twoh.releaseAll()
        twoh.status("error: " .. tostring(errorMessage))
        twoh.log("ERROR " .. tostring(errorMessage))
        task.wait(2)
    end
end

function Extras.Twoh.runStep()
    local twoh = Extras.Twoh
    local dungeonName = workspaceService:GetAttribute("Dungeon")
    if dungeonName == twoh.RealmName then
        twoh.runRealm()
        return
    end
    if dungeonName ~= nil then
        twoh.releaseAll()
        twoh.status("inside another dungeon (" .. tostring(dungeonName) .. ") | waiting")
        task.wait(2)
        return
    end
    local halt = twoh.loadState().Halt
    if typeof(halt) == "string" and halt ~= "" then
        twoh.stop(true)
        twoh.status("halted: " .. halt .. " | turn Auto TWOH on again to resume")
        return
    end
    local stage, questName, index = twoh.getStage()
    if stage ~= twoh.Stage then
        twoh.Fails = 0
        twoh.FishStartedAt = nil
        if twoh.Stage == "ep2" then
            twoh.stopFishing()
        end
    end
    twoh.Stage = stage
    if stage == "done" then
        twoh.stop(true)
        twoh.status("obtained! B - Over Heaven unlocked")
        return
    end
    if stage == "needsWorld" then
        twoh.idle("The World (Style) is not owned | get it first")
        return
    end
    if stage == "needsEnhance" then
        twoh.idle(string.format("The World is +%d | needs +%d before Earthly Proofs", twoh.EnhanceLevel or 0, twoh.RequiredLevel))
        return
    end
    local realmStage = twoh.RealmStages[stage] ~= nil
    if stage ~= "accept" and stage ~= "claim" and stage ~= "dio" and stage ~= "ep2" and not realmStage then
        twoh.idle(string.format("%s (next step) | %s active", twoh.NextSteps[index] or stage, tostring(questName)))
        return
    end
    if (stage == "dio" or realmStage) and not twoh.combatReady() then
        twoh.idle("set Auto Farm combat type to Ability (Araya)")
        return
    end
    twoh.runQuestStage(stage, questName, index)
end

function Extras.Twoh.runQuestStage(stage, questName, index)
    local twoh = Extras.Twoh
    local realmStage = twoh.RealmStages[stage] ~= nil
    if stage == "accept" and twoh.inAcceptGrace(questName, index) then
        twoh.releaseAll()
        twoh.status(questName .. " should auto-accept | waiting")
        task.wait(1)
        return
    end
    local owned, holder = twoh.claim()
    if not owned then
        twoh.status("waiting for " .. tostring(holder) .. " to hand over movement")
        task.wait(0.5)
        return
    end
    if stage == "accept" then
        twoh.acceptQuest(questName, index)
    elseif stage == "claim" then
        twoh.status("claiming " .. questName)
        if twoh.goToNPC(twoh.questNPCName(questName, index)) then
            invokeInput("Quest", "Claim", questName)
            task.wait(1)
        else
            twoh.fail("cannot reach " .. twoh.questNPCName(questName, index) .. " to claim " .. questName)
        end
    elseif stage == "dio" then
        twoh.fightDio(questName)
    elseif stage == "ep2" then
        twoh.runDiaries(questName)
        releaseMovement("twoh")
        return
    elseif realmStage then
        twoh.runRealmStage(stage)
    end
    lockedTargetCFrame = nil
    releaseMovement("twoh")
end

function Extras.Twoh.prestigeNeed()
    if not State.PrestigeEnabled then
        return nil
    end
    local progress = Prestige.getRequirementProgress()
    for _, entry in ipairs(progress or {}) do
        if entry.Type == Extras.Twoh.PrestigeKillType and not entry.Done then
            return entry
        end
    end
    return nil
end

function Extras.Twoh.realmOwner()
    local twoh = Extras.Twoh
    if State.AutoTwohEnabled then
        return "Auto TWOH"
    end
    if State.PrestigeEnabled and (twoh.Delegated or next(twoh.RealmRequesters) ~= nil) then
        return "Auto Prestige"
    end
    return nil
end

function Extras.Twoh.requestRealm(requester, drive)
    local twoh = Extras.Twoh
    twoh.RealmRequesters[requester] = true
    if drive and not State.AutoTwohEnabled then
        twoh.Delegated = true
    end
end

function Extras.Twoh.releaseRealm(requester)
    local twoh = Extras.Twoh
    twoh.RealmRequesters[requester] = nil
    if not twoh.Delegated or next(twoh.RealmRequesters) ~= nil then
        return
    end
    twoh.Delegated = false
    twoh.PrestigeLabel = nil
    twoh.FarmingKeys = false
    twoh.MoneyPhase = false
    twoh.PrestigeCheckUntil = nil
    if State.AutoTwohEnabled then
        return
    end
    twoh.releaseAll()
    twoh.unlockF()
    twoh.restoreDungeonHelper()
    task.spawn(twoh.restoreStyle)
end

function Extras.Twoh.prestigeSkipReason()
    local twoh = Extras.Twoh
    if os.clock() < (twoh.PrestigeGiveUpUntil or 0) then
        return string.format("gave up: %s | retry in %ds", tostring(twoh.PrestigeGiveUpReason), math.ceil(twoh.PrestigeGiveUpUntil - os.clock()))
    end
    local dungeonName = workspaceService:GetAttribute("Dungeon")
    if dungeonName == twoh.RealmName then
        return nil
    end
    if dungeonName ~= nil then
        return "inside another dungeon (" .. tostring(dungeonName) .. ")"
    end
    if os.clock() < (twoh.PrestigeCheckUntil or 0) then
        return twoh.PrestigeSkip
    end
    local reason = nil
    local halt = twoh.HaltReason or twoh.loadState().Halt
    if not twoh.hasWorld() then
        reason = "requires The World style (not owned)"
    elseif typeof(halt) == "string" and halt ~= "" then
        reason = "Realm runs halted (" .. halt .. ") | turn Auto Prestige off and on to retry"
    elseif getInventoryAmount(twoh.KeyItem) < 1 and not UnlockFarm.isQuestCompleted(twoh.Quests[2]) and twoh.getStage() == "needsEnhance" then
        reason = string.format("needs The World +%d for Earthly Proofs (now +%d) | can't get keys", twoh.RequiredLevel, twoh.EnhanceLevel or 0)
    end
    twoh.PrestigeSkip = reason
    twoh.PrestigeCheckUntil = os.clock() + (reason and 10 or 5)
    return reason
end

function Extras.Twoh.prestigeStep(req)
    local twoh = Extras.Twoh
    twoh.requestRealm("prestige", true)
    if req then
        twoh.PrestigeLabel = string.format("Dio Heaven Ascension %d/%d", math.floor(req.Current), math.floor(req.Needed))
    else
        twoh.PrestigeLabel = "Dio Heaven Ascension done | finishing this realm run"
    end
    twoh.lockF()
    twoh.connectFloorReset()
    local ok, errorMessage = pcall(twoh.prestigeRun)
    if not ok then
        twoh.releaseAll()
        twoh.status("error: " .. tostring(errorMessage) .. " | retrying in 5s")
        twoh.log("PRESTIGE ERROR " .. tostring(errorMessage))
        task.wait(5)
    end
end

function Extras.Twoh.prestigeRun()
    local twoh = Extras.Twoh
    if workspaceService:GetAttribute("Dungeon") == twoh.RealmName then
        twoh.runRealm()
        return
    end
    local keys = getInventoryAmount(twoh.KeyItem)
    local ep2Done = UnlockFarm.isQuestCompleted(twoh.Quests[2])
    if keys < 1 and not ep2Done then
        twoh.prestigeUnlockKeys()
        return
    end
    if keys >= 1 then
        twoh.FarmingKeys = false
    end
    local owned, holder = twoh.claim()
    if not owned then
        twoh.status("waiting for " .. tostring(holder) .. " to hand over movement")
        task.wait(0.5)
        return
    end
    twoh.runRealmStage("prestige")
    lockedTargetCFrame = nil
    releaseMovement("twoh")
end

function Extras.Twoh.prestigeUnlockKeys()
    local twoh = Extras.Twoh
    twoh.PrestigeLabel = tostring(twoh.PrestigeLabel) .. " | no keys | unlocking Realm keys via Earthly Proofs 1-2"
    local stage, questName, index = twoh.getStage()
    if stage ~= twoh.Stage then
        twoh.Fails = 0
        twoh.FishStartedAt = nil
        if twoh.Stage == "ep2" then
            twoh.stopFishing()
        end
    end
    twoh.Stage = stage
    if stage == "needsWorld" or stage == "needsEnhance" then
        twoh.releaseAll()
        twoh.status(stage == "needsWorld" and "requires The World style (not owned) | skipping" or string.format("needs The World +%d for Earthly Proofs (now +%d) | can't get keys | skipping", twoh.RequiredLevel, twoh.EnhanceLevel or 0))
        twoh.PrestigeCheckUntil = nil
        task.wait(3)
        return
    end
    if stage ~= "accept" and stage ~= "claim" and stage ~= "dio" and stage ~= "ep2" then
        twoh.releaseAll()
        twoh.status("Earthly Proofs 2 not completed but the stage is " .. tostring(stage) .. " | rechecking in 3s")
        task.wait(3)
        return
    end
    twoh.runQuestStage(stage, questName, index)
end

Extras.Yhwach = {
    NPCName = "Quincy Herald",
    NPCPosition = Vector3.new(2739, 22, -5141),
    StyleName = "Yhwach",
    KingName = "Yhwach Not Dungeon",
    TitleName = "The Quincy King",
    PityAttribute = "TitlePity_Yhwach_Not_Dungeon",
    TitlePity = 35,
    Letters = "Letters of the King",
    Successor = "Successor of the Quincy King",
    Audience = "Audience with the King",
    InheritBuy = "InheritQuincyKing",
    ReishiItem = "Reishi Fragment",
    SoulItem = "Quincy King's Soul",
    SoldierName = "Quincy Soldier",
    SoldierSpot = Vector3.new(2980, 32, -5420),
    KingSpot = Vector3.new(2797.5, 22, -5732.4),
    NoKingLimit = 4,
    DeathLoopCount = 4,
    DeathLoopWindow = 600,
    DeathLoopPause = 300,
    RefusedBackoff = 30,
    StallLimit = 180,
    ErrorStreakLimit = 20,
    ErrorPause = 60,
    SummonReishi = 20,
    SummonKills = 50,
    CraftReishi = 200,
    BaseSchriftTarget = 2,
    AcceptGrace = 8,
    MoneyMargin = 20000000,
    MoneyPhaseCap = 1200,
    KingWait = 45,
    FightTimeout = 900,
    SoldierBurst = 30,
    ReturnRange = 250,
    BatchSize = 5,
    BossArea = Vector3.new(2358, 22, -5495),
    SummonLostAfter = 20,
    ClusterFarm = true,
    ClusterRadius = 40,
    ClusterTravel = 120,
    ClusterSwitchMargin = 1.5,
    ClusterAim = true,
    ClusterCastRange = 20,
    CapBackoff = 20,
    BankMargin = 2,
    MaxAliveDefault = 3,
    MaxAliveRetry = 600,
    PullCooldown = 60,
    PullHold = 1.5,
    StatePath = "LEGACY PIECE/yhwach_state.json",
    LogPath = "LEGACY PIECE/yhwach_log.txt",
    Route = { "As Nodt", "Jugram Haschwalth", "Bambietta Basterbine", "Askin Nakk Le Vaar", "Gremmy Thoumeaux" },
    Statues = {
        ["As Nodt"] = { Short = "F", Material = "Fear Thorn", Schrift = "Schrift of Fear", Choice = "the fear", Position = Vector3.new(2989.6, 22, -5092.6) },
        ["Askin Nakk Le Vaar"] = { Short = "D", Material = "Lethal Essence", Schrift = "Schrift of Deathdealing", Choice = "the deathdealing", Position = Vector3.new(2591.1, 25, -5648.4) },
        ["Bambietta Basterbine"] = { Short = "E", Material = "Explosive Reishi Core", Schrift = "Schrift of Explode", Choice = "the explode", Position = Vector3.new(3006.1, 25.4, -5680.6) },
        ["Gremmy Thoumeaux"] = { Short = "V", Material = "Visionary Fragment", Schrift = "Schrift of Visionary", Choice = "the visionary", Position = Vector3.new(2593.4, 23.4, -5315.7) },
        ["Jugram Haschwalth"] = { Short = "B", Material = "Balance Fragment", Schrift = "Schrift of Balance", Choice = "the balance", Position = Vector3.new(3101.4, 24.4, -5320.3) }
    },
    KingDrops = {
        { Item = "Quincy King's Soul", Label = "Soul", Chance = 0.3 },
        { Item = "Wandenreich Sigil", Label = "Sigil", Chance = 0.5 },
        { Item = "Sovereign's Crown Shard", Label = "Crown", Chance = 0.3 },
        { Item = "Emperor's Reishi Heart", Label = "Heart", Chance = 0.2 }
    },
    BusyUntil = {},
    GoneSince = {},
    GraceSeen = {},
    Fails = 0,
    Deaths = 0,
    Idle = false,
    StatusText = "Idle",
    Detail = "",
    EtaText = ""
}

function Extras.Yhwach.status(message)
    Extras.Yhwach.StatusText = tostring(message)
    State.ExtraStatus = "Yhwach: " .. tostring(message)
end

function Extras.Yhwach.isActive()
    return State.AutoYhwachEnabled == true or (State.BossFarmEnabled and (State.BossSelection["Yhwach (Summoned)"] == true or State.BossSelection["Yhwach Not Dungeon"] == true))
end

function Extras.Yhwach.data()
    local yh = Extras.Yhwach
    if not yh.Data then
        local saved = {}
        pcall(function()
            local decoded = httpService:JSONDecode(readfile(yh.StatePath))
            if typeof(decoded) == "table" then
                saved = decoded
            end
        end)
        if typeof(saved.Stats) ~= "table" then
            saved.Stats = {}
        end
        if typeof(saved.SetKills) ~= "table" or saved.JobId ~= game.JobId then
            saved.SetKills = {}
            saved.Summoned = {}
            saved.MaxAlive = nil
            saved.MaxAliveAt = nil
            saved.Bank = nil
            saved.BankKnown = false
            saved.KingFullSet = nil
        end
        if typeof(saved.Summoned) ~= "table" then
            saved.Summoned = {}
        end
        saved.JobId = game.JobId
        yh.Data = saved
    end
    return yh.Data
end

function Extras.Yhwach.save()
    local yh = Extras.Yhwach
    pcall(function()
        writefile(yh.StatePath, httpService:JSONEncode(yh.data()))
    end)
end

function Extras.Yhwach.log(text)
    local yh = Extras.Yhwach
    local line = os.date("%H:%M:%S") .. " " .. tostring(text) .. "\n"
    local ok = pcall(appendfile, yh.LogPath, line)
    if not ok then
        local checked, exists = pcall(isfile, yh.LogPath)
        if checked and exists == false then
            pcall(writefile, yh.LogPath, line)
        end
    end
end

function Extras.Yhwach.stat(key, amount)
    local stats = Extras.Yhwach.data().Stats
    stats[key] = (tonumber(stats[key]) or 0) + (amount or 1)
end

function Extras.Yhwach.ownsStyle()
    local dataFolder = localPlayer:FindFirstChild("Data")
    local inventoryFolder = dataFolder and dataFolder:FindFirstChild("Inventory")
    return inventoryFolder ~= nil and inventoryFolder:FindFirstChild(Extras.Yhwach.StyleName) ~= nil
end

function Extras.Yhwach.getRace()
    local dataFolder = localPlayer:FindFirstChild("Data")
    local raceValue = dataFolder and dataFolder:FindFirstChild("Race")
    return raceValue and raceValue.Value or ""
end

function Extras.Yhwach.decode(questName)
    local info = questData.Main[questName]
    local objectives = typeof(info) == "table" and typeof(info.Objectives) == "table" and info.Objectives or {}
    local progress = tonumber(Extras.getQuestProgress(questName)) or 0
    local list = {}
    for index = 1, #objectives do
        local objective = objectives[index]
        local have = math.floor(progress / (1000 ^ (index - 1))) % 1000
        list[index] = { Target = objective.Target, Type = objective.Type, Have = have, Need = tonumber(objective.Amount) or 1 }
    end
    return list
end

function Extras.Yhwach.audienceGoals()
    local info = questData.Main[Extras.Yhwach.Audience]
    local goals = {}
    for _, objective in ipairs(typeof(info) == "table" and info.Objectives or {}) do
        goals[objective.Target] = tonumber(objective.Amount) or 1
    end
    return goals
end

function Extras.Yhwach.getCounts()
    local yh = Extras.Yhwach
    local counts = { Reishi = getInventoryAmount(yh.ReishiItem), Soul = getInventoryAmount(yh.SoulItem), Money = getMoney(), Shards = getShards(), Mat = {}, Schrift = {}, Drop = {} }
    for _, drop in ipairs(yh.KingDrops) do
        counts.Drop[drop.Item] = getInventoryAmount(drop.Item)
    end
    for name, info in pairs(yh.Statues) do
        counts.Mat[name] = getInventoryAmount(info.Material)
        counts.Schrift[name] = getInventoryAmount(info.Schrift)
    end
    return counts
end

function Extras.Yhwach.schriftTarget()
    return Extras.Yhwach.BaseSchriftTarget
end

function Extras.Yhwach.getNeeds(counts, stage)
    local yh = Extras.Yhwach
    local audienceDone = UnlockFarm.isQuestCompleted(yh.Audience)
    local target = yh.schriftTarget()
    local needs = { Mat = {}, Letters = {}, Drop = {}, CraftsLeft = 0, MatMax = 0, Title = false, KingKill = false, King = false }
    for name, info in pairs(yh.Statues) do
        local craftsLeft = audienceDone and 0 or math.max(0, target - counts.Schrift[name])
        needs.CraftsLeft = needs.CraftsLeft + craftsLeft
        needs.Mat[name] = math.max(0, craftsLeft * 5 - counts.Mat[name])
        needs.MatMax = math.max(needs.MatMax, needs.Mat[name])
    end
    if stage == "letters" then
        for _, objective in ipairs(yh.decode(yh.Letters)) do
            if objective.Have < objective.Need then
                needs.Letters[objective.Target] = true
            end
        end
    end
    if not audienceDone then
        local goals = yh.audienceGoals()
        for _, drop in ipairs(yh.KingDrops) do
            local goal = goals[drop.Item] or 0
            if drop.Item == yh.SoulItem then
                goal = goal + needs.CraftsLeft
            end
            needs.Drop[drop.Item] = math.max(0, goal - counts.Drop[drop.Item])
            if needs.Drop[drop.Item] > 0 then
                needs.King = true
            end
        end
        needs.Title = not Extras.hasTitle(yh.TitleName)
        needs.KingKill = true
        if UnlockFarm.getActiveQuestFolder(yh.Audience) then
            local first = yh.decode(yh.Audience)[1]
            needs.KingKill = first == nil or first.Have < first.Need
        end
        needs.King = needs.King or needs.Title or needs.KingKill
    end
    return needs
end

function Extras.Yhwach.getStage()
    local yh = Extras.Yhwach
    if yh.ownsStyle() then
        return "done"
    end
    if yh.getRace() ~= "Quincy" then
        return "needsQuincy"
    end
    if not UnlockFarm.isQuestCompleted(yh.Letters) then
        if not UnlockFarm.getActiveQuestFolder(yh.Letters) then
            return "acceptLetters"
        end
        if UnlockFarm.isQuestReadyToClaim(yh.Letters) then
            return "claimLetters"
        end
        return "letters"
    end
    if not UnlockFarm.isQuestCompleted(yh.Successor) then
        if not UnlockFarm.getActiveQuestFolder(yh.Successor) then
            return "waitSuccessor"
        end
        if UnlockFarm.isQuestReadyToClaim(yh.Successor) then
            return "claimSuccessor"
        end
        return "successor"
    end
    if not UnlockFarm.isQuestCompleted(yh.Audience) then
        if not UnlockFarm.getActiveQuestFolder(yh.Audience) then
            return "acceptAudience"
        end
        if UnlockFarm.isQuestReadyToClaim(yh.Audience) and yh.getNeeds(yh.getCounts(), "audience").CraftsLeft == 0 then
            return "claimAudience"
        end
        return "audience"
    end
    return "inherit"
end

function Extras.Yhwach.bank()
    return tonumber(Extras.Yhwach.data().Bank) or 0
end

function Extras.Yhwach.syncBank()
    local yh = Extras.Yhwach
    local data = yh.data()
    local kills = BossFarm.Quincy.Kills
    local delta = kills - (yh.LastSoldierKills or kills)
    if delta > 0 then
        data.Bank = yh.bank() + delta
    end
    yh.LastSoldierKills = kills
    if State.QuincyBanked ~= nil and (State.QuincyBankedAt or 0) > (yh.BankNotifyAt or 0) then
        yh.BankNotifyAt = State.QuincyBankedAt
        data.Bank = State.QuincyBanked
        data.BankKnown = true
        yh.log("BANK notify " .. tostring(State.QuincyBanked))
    end
end

function Extras.Yhwach.trackDeaths()
    local yh = Extras.Yhwach
    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 and yh.DeadCharacter ~= character then
        yh.DeadCharacter = character
        yh.Deaths = yh.Deaths + 1
        yh.stat("Deaths")
        yh.DeathTimes = yh.DeathTimes or {}
        table.insert(yh.DeathTimes, os.clock())
        yh.log("DEATH")
    end
end

function Extras.Yhwach.recentDeaths()
    local yh = Extras.Yhwach
    local now = os.clock()
    local kept = {}
    for _, at in ipairs(yh.DeathTimes or {}) do
        if now - at < yh.DeathLoopWindow then
            table.insert(kept, at)
        end
    end
    yh.DeathTimes = kept
    return #kept
end

function Extras.Yhwach.findKing()
    local wanted = normalizeName(Extras.Yhwach.KingName)
    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if normalizeName(stripBossTag(enemy.Name)) == wanted then
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and enemy:FindFirstChild("HumanoidRootPart") then
                return enemy
            end
        end
    end
    return nil
end

function Extras.Yhwach.findBoss(name)
    local rootPart = getRoot()
    return getTargetEnemy(name, rootPart and rootPart.Position or Vector3.zero, true)
end

function Extras.Yhwach.getStatuePrompt(name)
    local islandsFolder = workspaceService:FindFirstChild("Islands")
    local islandList = islandsFolder and islandsFolder:FindFirstChild("Islands")
    local castle = islandList and islandList:FindFirstChild("Quincy Castle")
    local statue = castle and castle:FindFirstChild(name)
    local part = statue and statue:FindFirstChild("Part")
    return part, part and part:FindFirstChild("SummonPrompt")
end

function Extras.Yhwach.getRequirement(buyName)
    local entry = dialogueData[Extras.Yhwach.NPCName]
    for _, key in ipairs({ "Choice", "PostQuestChoice" }) do
        local pages = typeof(entry) == "table" and entry[key]
        if typeof(pages) == "table" then
            for _, page in pairs(pages) do
                if typeof(page) == "table" then
                    for _, choice in pairs(page) do
                        local info = typeof(choice) == "table" and choice[3]
                        if typeof(info) == "table" and info.Buy == buyName then
                            local list = {}
                            for _, requirement in ipairs(typeof(info.Requirement) == "table" and info.Requirement or {}) do
                                table.insert(list, { Item = requirement[1], Amount = tonumber(requirement[2]) or 0 })
                            end
                            return list
                        end
                    end
                end
            end
        end
    end
    return nil
end

function Extras.Yhwach.missing(requirement)
    local parts = {}
    for _, entry in ipairs(requirement or {}) do
        local have = getInventoryAmount(entry.Item)
        if have < entry.Amount then
            table.insert(parts, string.format("%s %d/%d", entry.Item, have, entry.Amount))
        end
    end
    if #parts == 0 then
        return nil
    end
    return table.concat(parts, ", ")
end

function Extras.Yhwach.snapshot()
    local yh = Extras.Yhwach
    local counts = yh.getCounts()
    local parts = { string.format("Reishi %d Soul %d $%.1fM shards %d", counts.Reishi, counts.Soul, counts.Money / 1000000, counts.Shards) }
    for _, name in ipairs(yh.Route) do
        local info = yh.Statues[name]
        table.insert(parts, string.format("%s mat %d sch %d", info.Short, counts.Mat[name], counts.Schrift[name]))
    end
    for _, drop in ipairs(yh.KingDrops) do
        table.insert(parts, drop.Label .. " " .. tostring(counts.Drop[drop.Item]))
    end
    return table.concat(parts, " | ")
end

function Extras.Yhwach.setCount()
    local count = 0
    for _ in pairs(Extras.Yhwach.data().SetKills) do
        count = count + 1
    end
    return count
end

function Extras.Yhwach.summary(counts, needs)
    local yh = Extras.Yhwach
    local data = yh.data()
    local goals = yh.audienceGoals()
    local schrift, mats = {}, {}
    for _, name in ipairs(yh.Route) do
        local info = yh.Statues[name]
        table.insert(schrift, info.Short .. tostring(counts.Schrift[name]))
        table.insert(mats, tostring(counts.Mat[name]))
    end
    local dropParts = {}
    for _, drop in ipairs(yh.KingDrops) do
        local goal = goals[drop.Item] or 0
        if drop.Item == yh.SoulItem then
            goal = goal + needs.CraftsLeft
        end
        table.insert(dropParts, string.format("%s %d/%d", drop.Label, counts.Drop[drop.Item], goal))
    end
    return string.format("set %d/5 | sets %d King %d | Reishi %d bank %d | %s | pity %s/%d | Schrift %s (x%d) | mats %s", yh.setCount(), tonumber(data.Sets) or 0, tonumber(data.KingKills) or 0, counts.Reishi, yh.bank(), table.concat(dropParts, " "), tostring(localPlayer:GetAttribute(yh.PityAttribute) or 0), yh.TitlePity, table.concat(schrift, " "), yh.schriftTarget(), table.concat(mats, "/"))
end

function Extras.Yhwach.estimate(counts, needs)
    local yh = Extras.Yhwach
    local stats = yh.data().Stats
    local pity = tonumber(localPlayer:GetAttribute(yh.PityAttribute)) or 0
    local setsLeft = needs.MatMax
    for _, drop in ipairs(yh.KingDrops) do
        setsLeft = math.max(setsLeft, (needs.Drop[drop.Item] or 0) / drop.Chance)
    end
    if needs.Title then
        setsLeft = math.max(setsLeft, math.max(1, yh.TitlePity - pity))
    end
    if needs.KingKill then
        setsLeft = math.max(setsLeft, 1)
    end
    setsLeft = math.ceil(setsLeft)
    local farmSeconds = tonumber(stats.FarmSeconds) or 0
    local farmKills = tonumber(stats.FarmKills) or 0
    local statueFights = tonumber(stats.StatueFights) or 0
    if farmSeconds < 60 or farmKills < 20 or statueFights < 1 then
        yh.EtaText = string.format("ETA: ~%d sets left | measuring rates (soldiers %ds/%d kills, statues %d)", setsLeft, math.floor(farmSeconds), farmKills, statueFights)
        return
    end
    local killRate = farmKills / farmSeconds
    local reishiPerKill = (tonumber(stats.FarmReishi) or 0) / farmKills
    local statueSeconds = (tonumber(stats.StatueSeconds) or 0) / statueFights
    local statueReishi = (tonumber(stats.StatueReishi) or 0) / statueFights
    local kingFights = tonumber(stats.KingFights) or 0
    local kingSeconds = kingFights > 0 and (tonumber(stats.KingSeconds) or 0) / kingFights or statueSeconds * 3
    local kingReishi = kingFights > 0 and (tonumber(stats.KingReishi) or 0) / kingFights or 7.5
    local setSeconds = 5 * (statueSeconds + 25 + yh.SummonKills / killRate) + kingSeconds + 20
    local reishiNeed = setsLeft * (5 * yh.SummonReishi - 5 * statueReishi - kingReishi - 5 * yh.SummonKills * reishiPerKill) + needs.CraftsLeft * yh.CraftReishi - counts.Reishi
    local extraSeconds = reishiPerKill > 0 and math.max(0, reishiNeed) / (reishiPerKill * killRate) or 0
    local recent = yh.data().RecentSets
    if typeof(recent) == "table" and #recent > 0 then
        local sorted = {}
        for _, seconds in ipairs(recent) do
            table.insert(sorted, tonumber(seconds) or 0)
        end
        table.sort(sorted)
        local middle = math.floor((#sorted + 1) / 2)
        setSeconds = #sorted % 2 == 1 and sorted[middle] or (sorted[middle] + sorted[middle + 1]) / 2
        reishiNeed = needs.CraftsLeft * yh.CraftReishi - counts.Reishi
        extraSeconds = reishiPerKill > 0 and math.max(0, reishiNeed) / (reishiPerKill * killRate) or 0
    end
    local total = setsLeft * setSeconds + extraSeconds
    yh.EtaText = string.format("ETA: %.1fh | %d sets x %.1fmin + %.1fh extra soldiers for %d Reishi | soldiers %.1f/min, %.3f Reishi/kill | statue %.0fs, King %.0fs", total / 3600, setsLeft, setSeconds / 60, extraSeconds / 3600, math.max(0, math.floor(reishiNeed)), killRate * 60, reishiPerKill, statueSeconds, kingSeconds)
end

function Extras.Yhwach.claim()
    local yh = Extras.Yhwach
    local request = Extras.PriorityRequest
    local checker = request ~= nil and request ~= "yhwach" and movementOwnerActiveCheck[request]
    if checker and not checker() then
        yh.log("PRIORITY cleared stale request " .. tostring(request))
        Extras.PriorityRequest = nil
        request = nil
    end
    if request == nil or (request == "twoh" and workspaceService:GetAttribute("Dungeon") == nil) then
        Extras.PriorityRequest = "yhwach"
    end
    if Extras.PriorityRequest ~= "yhwach" then
        yh.WaitSince = nil
        return false, Extras.PriorityRequest
    end
    if acquireMovement("yhwach") then
        yh.WaitSince = nil
        return true
    end
    yh.WaitSince = yh.WaitSince or os.clock()
    local teleporting = (Extras.RevertWatch.ExpectUntil or 0) > os.clock()
    local entering = movementOwner == "dungeon" or movementOwner == "araya"
    if os.clock() - yh.WaitSince > 8 and not teleporting and not entering then
        stopTween()
        movementOwner = nil
    end
    return false, movementOwner
end

function Extras.Yhwach.releaseAll()
    local yh = Extras.Yhwach
    if Extras.PriorityRequest == "yhwach" then
        Extras.PriorityRequest = nil
    end
    yh.WaitSince = nil
    yh.MoneyPhase = false
    if movementOwner == "yhwach" then
        stopTween()
        Combat.ApproachRoot = nil
        lockedEnemyRoot = nil
        lockedTargetCFrame = nil
        setTargetBox(nil)
    end
    releaseMovement("yhwach")
end

function Extras.Yhwach.idle(message)
    local yh = Extras.Yhwach
    yh.releaseAll()
    yh.Idle = true
    yh.status(message)
    task.wait(3)
end

function Extras.Yhwach.stop(syncUI)
    Extras.stopLoop("AutoYhwachEnabled", "yhwach")
    Extras.Yhwach.releaseAll()
    Extras.Yhwach.Idle = false
    if syncUI then
        Extras.syncToggle("YhwachToggle", false)
    end
end

function Extras.Yhwach.halt(reason)
    local yh = Extras.Yhwach
    yh.data().Halt = reason
    yh.save()
    yh.log("HALT " .. tostring(reason))
    yh.status("halted: " .. tostring(reason))
    yh.stop(true)
end

function Extras.Yhwach.fail(reason)
    local yh = Extras.Yhwach
    yh.Fails = yh.Fails + 1
    yh.log("FAIL " .. tostring(reason) .. " | " .. tostring(State.LastNotifyText))
    if yh.Fails >= 3 then
        yh.Fails = 0
        yh.idle(tostring(reason) .. " | retrying in 30s")
        local resumeAt = os.clock() + 27
        while yh.isActive() and os.clock() < resumeAt do
            task.wait(0.5)
        end
        return
    end
    yh.status(string.format("%s (attempt %d/3)", tostring(reason), yh.Fails))
    task.wait(1)
end

function Extras.Yhwach.goToHerald()
    local yh = Extras.Yhwach
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    setTargetBox(nil)
    return Extras.goToNPCAt(yh.NPCName, yh.NPCPosition, yh.isActive, yh.status)
end

function Extras.Yhwach.inAcceptGrace(key)
    local yh = Extras.Yhwach
    local seenAt = yh.GraceSeen[key] or os.clock()
    yh.GraceSeen[key] = seenAt
    return os.clock() - seenAt < yh.AcceptGrace
end

function Extras.Yhwach.acceptQuest(questName, choiceText)
    local yh = Extras.Yhwach
    local function accepted()
        return UnlockFarm.getActiveQuestFolder(questName) ~= nil or UnlockFarm.isQuestCompleted(questName)
    end
    yh.status("going to the Quincy Herald to accept " .. questName)
    local npc = yh.goToHerald()
    if not npc then
        yh.fail("cannot reach the Quincy Herald to accept " .. questName)
        return
    end
    local _, reply = invokeInput("Quest", "Accept", npc, questName)
    task.wait(0.8)
    if not accepted() and choiceText and Extras.openArayaDialogue(npc) then
        Extras.pickArayaChoice(choiceText, accepted)
        local deadline = os.clock() + 3
        while not accepted() and os.clock() < deadline do
            task.wait(0.2)
        end
        if isDialogueOpen() then
            Extras.pickArayaChoice("leave")
        end
    end
    yh.log(string.format("ACCEPT %s reply=%s accepted=%s | %s", questName, tostring(reply), tostring(accepted()), tostring(State.LastNotifyText)))
    if accepted() then
        yh.Fails = 0
        yh.status(questName .. " accepted")
    else
        yh.fail(questName .. " was not accepted")
    end
end

function Extras.Yhwach.claimQuest(questName)
    local yh = Extras.Yhwach
    yh.status("claiming " .. questName .. " at the Quincy Herald")
    local npc = yh.goToHerald()
    if not npc then
        yh.fail("cannot reach the Quincy Herald to claim " .. questName)
        return false
    end
    local before = yh.getCounts()
    local beforeText = yh.snapshot()
    local _, reply = invokeInput("Quest", "Claim", questName)
    local deadline = os.clock() + 4
    while not UnlockFarm.isQuestCompleted(questName) and os.clock() < deadline do
        task.wait(0.2)
    end
    task.wait(1)
    local after = yh.getCounts()
    yh.log(string.format("CLAIM %s reply=%s completed=%s | notify %s", questName, tostring(reply), tostring(UnlockFarm.isQuestCompleted(questName)), tostring(State.LastNotifyText)))
    yh.log("  before " .. beforeText)
    yh.log("  after  " .. yh.snapshot())
    if not UnlockFarm.isQuestCompleted(questName) then
        yh.fail(questName .. " claim was not accepted")
        return false
    end
    yh.Fails = 0
    if questName == yh.Successor then
        local consumed = 0
        for name in pairs(yh.Statues) do
            consumed = math.max(consumed, before.Schrift[name] - after.Schrift[name])
        end
        yh.log("Successor claim Schrift counts | consumed " .. tostring(consumed) .. " of each | target stays " .. tostring(yh.schriftTarget()))
        for _, name in ipairs(yh.Route) do
            yh.log(string.format("  %s %d -> %d", yh.Statues[name].Schrift, before.Schrift[name], after.Schrift[name]))
        end
        yh.save()
    end
    yh.GraceSeen = {}
    return true
end

function Extras.Yhwach.moneyPhase(floor, target, label)
    local yh = Extras.Yhwach
    local money = getMoney()
    if not yh.MoneyPhase and money < floor then
        yh.MoneyPhase = true
        yh.MoneyPhaseStartedAt = os.clock()
        yh.log(string.format("MONEY phase start $%.1fM < $%.1fM", money / 1000000, floor / 1000000))
    end
    if yh.MoneyPhase and (money >= target or os.clock() - (yh.MoneyPhaseStartedAt or 0) > yh.MoneyPhaseCap) then
        yh.MoneyPhase = false
        return false
    end
    if not yh.MoneyPhase then
        return false
    end
    local rank = Extras.getFireForceRank()
    if rank == "" or rank == "None" then
        yh.MoneyPhase = false
        yh.idle(string.format("%s | money $%.1fM below $%.1fM and Ambush needs a Fire Force rank | waiting", label, money / 1000000, floor / 1000000))
        return true
    end
    local text = string.format("Yhwach: %s | money $%.1fM/%.0fM | Ambush", label, money / 1000000, target / 1000000)
    if not Extras.runAmbushDuty(function()
        return yh.isActive() and getMoney() < target
    end, text) then
        State.ExtraStatus = text .. " | waiting for the next ambush"
        task.wait(0.5)
    end
    return true
end

function Extras.Yhwach.craftSchrift(name)
    local yh = Extras.Yhwach
    local info = yh.Statues[name]
    local requirement = yh.getRequirement(info.Schrift)
    if not requirement then
        yh.halt("the Herald has no recipe for " .. info.Schrift)
        return
    end
    local missingText = yh.missing(requirement)
    if missingText then
        yh.fail("cannot inscribe " .. info.Schrift .. ": " .. missingText)
        return
    end
    yh.status("inscribing " .. info.Schrift .. " at the Quincy Herald")
    local npc = yh.goToHerald()
    if not npc then
        yh.fail("cannot reach the Quincy Herald to inscribe " .. info.Schrift)
        return
    end
    missingText = yh.missing(requirement)
    if missingText then
        yh.fail("cannot inscribe " .. info.Schrift .. ": " .. missingText)
        return
    end
    local before = getInventoryAmount(info.Schrift)
    local beforeText = yh.snapshot()
    local finished, reply = invokeInput("Shop", npc, info.Schrift)
    local deadline = os.clock() + ((reply == true or not finished) and 8 or 3)
    while getInventoryAmount(info.Schrift) <= before and os.clock() < deadline do
        task.wait(0.2)
    end
    local method = "shop"
    if getInventoryAmount(info.Schrift) <= before and finished and reply ~= true and reply ~= "Full" and Extras.openArayaDialogue(npc) then
        method = "dialogue"
        Extras.pickArayaChoice(info.Choice, function()
            return getInventoryAmount(info.Schrift) > before
        end)
        deadline = os.clock() + 3
        while getInventoryAmount(info.Schrift) <= before and os.clock() < deadline do
            task.wait(0.2)
        end
        if isDialogueOpen() then
            Extras.pickArayaChoice("leave")
        end
    end
    local crafted = getInventoryAmount(info.Schrift) > before
    yh.log(string.format("CRAFT %s via %s reply=%s crafted=%s | %s", info.Schrift, method, tostring(reply), tostring(crafted), tostring(State.LastNotifyText)))
    yh.log("  before " .. beforeText)
    yh.log("  after  " .. yh.snapshot())
    if crafted then
        yh.Fails = 0
        yh.stat("Crafts")
        yh.save()
    elseif reply == "Full" then
        yh.halt("inventory full: free an inventory slot for " .. info.Schrift)
    else
        yh.fail(info.Schrift .. " was not inscribed (reply " .. tostring(reply) .. ")")
    end
end

function Extras.Yhwach.nextCraft(counts, stage)
    local yh = Extras.Yhwach
    if stage ~= "successor" and stage ~= "audience" then
        return nil
    end
    local target = stage == "successor" and 1 or yh.schriftTarget()
    local blocked = nil
    for _, name in ipairs(yh.Route) do
        local info = yh.Statues[name]
        if counts.Schrift[name] < target then
            local requirement = yh.getRequirement(info.Schrift)
            if not requirement then
                yh.NoRecipeLogged = yh.NoRecipeLogged or {}
                if not yh.NoRecipeLogged[info.Schrift] then
                    yh.NoRecipeLogged[info.Schrift] = true
                    yh.log("no recipe found for " .. info.Schrift)
                end
            end
            local onlyReishi = requirement ~= nil
            local ready = requirement ~= nil
            for _, entry in ipairs(requirement or {}) do
                if getInventoryAmount(entry.Item) < entry.Amount then
                    ready = false
                    if entry.Item ~= yh.ReishiItem then
                        onlyReishi = false
                    end
                end
            end
            if ready then
                return name
            end
            if onlyReishi then
                blocked = name
            end
        end
    end
    return nil, blocked
end

function Extras.Yhwach.fightActive()
    local yh = Extras.Yhwach
    if not yh.isActive() then
        return false
    end
    if movementOwner == "boss" and State.BossFarmEnabled then
        movementOwnerSince = os.clock()
        return true
    end
    if not (Extras.PriorityRequest == "yhwach" and movementOwner == "yhwach") then
        return false
    end
    movementOwnerSince = os.clock()
    return true
end

function Extras.Yhwach.killBoss(finder, label)
    local yh = Extras.Yhwach
    local enemy = finder()
    if not enemy then
        return false, 0, 0
    end
    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
    local maxHealth = humanoid and humanoid.MaxHealth or 0
    local startedAt = os.clock()
    local deathsBefore = yh.Deaths
    local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
    local lastPosition = enemyRoot and enemyRoot.Position or Vector3.zero
    local lastRatio = humanoid and humanoid.Health / math.max(humanoid.MaxHealth, 1) or 1
    local missingSince = nil
    local killed = false
    yh.log(string.format("FIGHT %s start | model %s | MaxHealth %.0f Health %.0f | at %s", label, enemy.Name, maxHealth, humanoid and humanoid.Health or 0, tostring(lastPosition)))
    while yh.fightActive() and os.clock() - startedAt < yh.FightTimeout do
        yh.trackDeaths()
        yh.syncBank()
        local rootPart, playerHumanoid = getRoot()
        local current = finder()
        if current then
            missingSince = nil
            enemy = current
            humanoid = enemy:FindFirstChildOfClass("Humanoid")
            enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
            if enemyRoot then
                lastPosition = enemyRoot.Position
            end
            if humanoid then
                lastRatio = humanoid.Health / math.max(humanoid.MaxHealth, 1)
                maxHealth = math.max(maxHealth, humanoid.MaxHealth)
            end
            if not (Extras.OverHeaven and Extras.OverHeaven.Busy) then
                farmMobWithAnchor(enemy.Name, function()
                    return yh.fightActive() and finder() ~= nil
                end, true)
            end
            yh.status(string.format("%s | %s %.1f%% HP | %.0fs | deaths %d", yh.Prefix or "", label, lastRatio * 100, os.clock() - startedAt, yh.Deaths - deathsBefore))
        elseif not rootPart or not playerHumanoid or playerHumanoid.Health <= 0 then
            yh.status(string.format("%s | dead during %s | waiting to respawn", yh.Prefix or "", label))
            task.wait(0.5)
        elseif (rootPart.Position - lastPosition).Magnitude > yh.ReturnRange then
            missingSince = nil
            yh.status(string.format("%s | returning to %s (%.0f studs)", yh.Prefix or "", label, (rootPart.Position - lastPosition).Magnitude))
            lockedEnemyRoot = nil
            lockedTargetCFrame = nil
            setTargetBox(nil)
            safeTravelTo(CFrame.new(lastPosition + Vector3.new(0, 20, 0)), function()
                local currentRoot = getRoot()
                return yh.fightActive() and finder() == nil and currentRoot ~= nil and (currentRoot.Position - lastPosition).Magnitude > yh.ReturnRange * 0.6
            end)
        else
            missingSince = missingSince or os.clock()
            local gone = enemy.Parent == nil or (humanoid ~= nil and humanoid.Health <= 0)
            if gone or os.clock() - missingSince > 4 then
                killed = gone and lastRatio < 0.35 or (humanoid ~= nil and humanoid.Health <= 0)
                break
            end
        end
        task.wait(0.1)
    end
    local seconds = os.clock() - startedAt
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    Combat.LockedMobName = nil
    setTargetBox(nil)
    yh.log(string.format("FIGHT %s end | killed %s | last HP %.1f%% | %.1fs | deaths %d | %.0f HP/s", label, tostring(killed), lastRatio * 100, seconds, yh.Deaths - deathsBefore, seconds > 0 and maxHealth / seconds or 0))
    return killed, seconds, maxHealth
end

function Extras.Yhwach.pickSoldier(origin, current)
    local yh = Extras.Yhwach
    local alive = {}
    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if enemy.Name == yh.SoldierName then
            local living, enemyRoot = isLivingEnemy(enemy)
            if living then
                table.insert(alive, enemyRoot)
            end
        end
    end
    local best, bestValue, currentValue = nil, -math.huge, -math.huge
    for _, enemyRoot in ipairs(alive) do
        local count, spread = 0, 0
        for _, other in ipairs(alive) do
            local gap = (other.Position - enemyRoot.Position).Magnitude
            if gap <= yh.ClusterRadius then
                count = count + 1
                spread = spread + gap
            end
        end
        local value = count - (enemyRoot.Position - origin).Magnitude / yh.ClusterTravel - spread / 1000
        if enemyRoot == current then
            currentValue = value
        end
        if value > bestValue then
            best, bestValue = enemyRoot, value
        end
    end
    return best, bestValue, currentValue
end

function Extras.Yhwach.engageCluster(active)
    local yh = Extras.Yhwach
    local rootPart = getRoot()
    if not rootPart then
        return
    end
    local current = lockedEnemyRoot
    local currentModel = current and current.Parent
    local currentValid = currentModel ~= nil and currentModel.Name == yh.SoldierName and isLivingEnemy(currentModel)
    local best, bestValue, currentValue = yh.pickSoldier(rootPart.Position, currentValid and current or nil)
    if currentValid and (best == nil or bestValue < currentValue + yh.ClusterSwitchMargin) then
        best = current
    end
    if not best then
        lockedEnemyRoot = nil
        task.wait(0.2)
        return
    end
    local enemyModel = best.Parent
    local enemyHumanoid = enemyModel and enemyModel:FindFirstChildOfClass("Humanoid")
    if not enemyHumanoid then
        return
    end
    setTargetBox(enemyModel)
    lastKnownMobCFrame = getFarmCFrame(best)
    if best ~= current and (best.Position - rootPart.Position).Magnitude > 150 then
        lockedEnemyRoot = nil
        lockedTargetCFrame = nil
        Combat.ApproachRoot = best
        local function stillValid()
            return active() and enemyHumanoid.Health > 0 and best.Parent ~= nil
        end
        travelTo(function()
            if not stillValid() then
                return nil
            end
            local currentRoot = getRoot()
            if currentRoot and (currentRoot.Position - best.Position).Magnitude <= 60 then
                return nil
            end
            return getFarmCFrame(best)
        end, stillValid)
        Combat.ApproachRoot = nil
        if best.Parent == nil or enemyHumanoid.Health <= 0 then
            return
        end
    end
    lockedTargetCFrame = nil
    lockedEnemyRoot = best
    Combat.LockedMobName = yh.SoldierName
    Combat.LockedAllowBoss = false
    if yh.ClusterAim then
        local sum, members = Vector3.zero, 0
        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            if enemy.Name == yh.SoldierName then
                local living, enemyRoot = isLivingEnemy(enemy)
                if living and (enemyRoot.Position - best.Position).Magnitude <= yh.ClusterRadius then
                    sum = sum + enemyRoot.Position
                    members = members + 1
                end
            end
        end
        local center = members > 1 and sum / members or best.Position
        Combat.AimOverride = center
        Combat.HoverOverride = getFarmCFrame(best) + (center - best.Position)
        Combat.HoverCastRange = yh.ClusterCastRange
        Combat.OverrideUntil = os.clock() + 0.6
    end
    local character = localPlayer.Character
    if character then
        equipCombatTool(character)
    end
end

function Extras.Yhwach.farmSoldiers(label, keepGoing)
    local yh = Extras.Yhwach
    local function active()
        return yh.fightActive() and keepGoing() and yh.findKing() == nil
    end
    local rootPart = getRoot()
    if not rootPart then
        task.wait(1)
        return
    end
    local nearSoldier = getTargetEnemy(yh.SoldierName, rootPart.Position, false)
    local nearRoot = nearSoldier and nearSoldier:FindFirstChild("HumanoidRootPart")
    if (not nearRoot or (nearRoot.Position - rootPart.Position).Magnitude > 600) and (rootPart.Position - yh.SoldierSpot).Magnitude > 150 then
        yh.status(label .. " | flying to the Quincy Soldiers")
        lockedEnemyRoot = nil
        lockedTargetCFrame = nil
        lastKnownMobCFrame = nil
        setTargetBox(nil)
        safeTravelTo(CFrame.new(yh.SoldierSpot + Vector3.new(0, 8, 0)), function()
            local currentRoot = getRoot()
            return active() and currentRoot ~= nil and (currentRoot.Position - yh.SoldierSpot).Magnitude > 120
        end)
    end
    local startedAt = os.clock()
    local reishiBefore = getInventoryAmount(yh.ReishiItem)
    local killsBefore = BossFarm.Quincy.Kills
    while active() and os.clock() - startedAt < yh.SoldierBurst do
        yh.trackDeaths()
        local currentRoot = getRoot()
        if currentRoot and getTargetEnemy(yh.SoldierName, currentRoot.Position, false) then
            if not (Extras.OverHeaven and Extras.OverHeaven.Busy) then
                if yh.ClusterFarm then
                    yh.engageCluster(active)
                else
                    farmMobWithAnchor(yh.SoldierName, active, false)
                end
            end
        else
            task.wait(0.4)
        end
        yh.syncBank()
        yh.status(string.format("%s | soldiers | bank %d | Reishi %d", label, yh.bank(), getInventoryAmount(yh.ReishiItem)))
        task.wait(0.1)
    end
    Combat.OverrideUntil = 0
    local seconds = os.clock() - startedAt
    local kills = math.max(0, BossFarm.Quincy.Kills - killsBefore)
    local gained = math.max(0, getInventoryAmount(yh.ReishiItem) - reishiBefore)
    yh.stat("FarmSeconds", seconds)
    yh.stat("FarmKills", kills)
    yh.stat("FarmReishi", gained)
    yh.log(string.format("SOLDIERS %.0fs kills %d Reishi +%d bank %d", seconds, kills, gained, yh.bank()))
    yh.save()
end

function Extras.Yhwach.summonStatue(name)
    local yh = Extras.Yhwach
    local data = yh.data()
    local info = yh.Statues[name]
    local function finder()
        return yh.findBoss(name)
    end
    if finder() then
        return "alive"
    end
    local part, prompt = yh.getStatuePrompt(name)
    local rootPart = getRoot()
    local standPosition = (part and part.Position or info.Position) + Vector3.new(0, 3, 6)
    if not rootPart or not part or (part.Position - rootPart.Position).Magnitude > 10 then
        yh.status(string.format("%s | flying to the %s statue", yh.Prefix or "", name))
        lockedEnemyRoot = nil
        lockedTargetCFrame = nil
        setTargetBox(nil)
        safeTravelTo(CFrame.new(standPosition), function()
            return yh.fightActive() and not finder()
        end)
        task.wait(0.5)
        part, prompt = yh.getStatuePrompt(name)
        rootPart = getRoot()
    end
    if finder() then
        return "alive"
    end
    if not prompt or not rootPart or (part.Position - rootPart.Position).Magnitude > 14 then
        yh.fail("cannot reach the " .. name .. " statue")
        return "fail"
    end
    if not prompt.Enabled then
        yh.BusyUntil[name] = os.clock() + 20
        yh.log("STATUE " .. name .. " prompt disabled (busy)")
        yh.status(name .. " statue is busy | trying the next one")
        return "busy"
    end
    local reishiBefore = getInventoryAmount(yh.ReishiItem)
    local matBefore = getInventoryAmount(info.Material)
    local sentAt = os.clock()
    triggerPrompt(prompt)
    local spawned = false
    local deadline = os.clock() + 4
    while os.clock() < deadline do
        if getInventoryAmount(yh.ReishiItem) < reishiBefore or finder() then
            spawned = true
            break
        end
        task.wait(0.1)
    end
    local notifyText = (State.LastNotifyTime or 0) >= sentAt and tostring(State.LastNotifyText) or ""
    yh.syncBank()
    yh.log(string.format("SUMMON %s spawned=%s reishi %d->%d bank %d | %s", name, tostring(spawned), reishiBefore, getInventoryAmount(yh.ReishiItem), yh.bank(), notifyText))
    if not spawned then
        if (State.BossCapAt or 0) >= sentAt then
            yh.CapUntil = os.clock() + yh.CapBackoff
            yh.log(string.format("SUMMON %s refused | the server is at its boss cap | retry after a kill or in %ds", name, yh.CapBackoff))
            return "cap"
        end
        local lowered = string.lower(notifyText)
        local slain = string.match(lowered, "slain[^%(]*%((%d+)/%d+%)")
        if slain then
            data.BankKnown = true
            data.Bank = tonumber(slain)
            yh.log("BANK resync from refusal " .. tostring(slain))
            yh.save()
            return "refused"
        end
        if string.find(lowered, "banked", 1, true) then
            data.BankKnown = true
            if yh.bank() >= yh.SummonKills then
                data.Bank = 0
            end
            yh.save()
            return "refused"
        end
        if string.find(lowered, "at a time", 1, true) or string.find(lowered, "already", 1, true) then
            yh.BusyUntil[name] = os.clock() + 20
            return "busy"
        end
        if not data.BankKnown then
            data.BankKnown = true
            data.Bank = 0
            yh.save()
            return "refused"
        end
        yh.BusyUntil[name] = os.clock() + yh.RefusedBackoff
        data.Bank = math.max(0, yh.bank() - 10)
        yh.save()
        yh.log(string.format("SUMMON %s refused without a count | backing off %ds | bank lowered to %d", name, yh.RefusedBackoff, yh.bank()))
        yh.fail(name .. " summon rejected | " .. notifyText)
        return "fail"
    end
    yh.stat("Summons")
    data.Bank = math.max(0, yh.bank() - yh.SummonKills)
    data.BankKnown = true
    data.Summoned[name] = { Mat = matBefore }
    yh.GoneSince[name] = nil
    yh.SetStartedAt = yh.SetStartedAt or os.clock()
    yh.save()
    local streamDeadline = os.clock() + 6
    while os.clock() < streamDeadline and not finder() do
        task.wait(0.2)
    end
    if not finder() then
        yh.BusyUntil[name] = os.clock() + 15
        yh.log("SUMMON " .. name .. " paid but no boss seen within 6s")
        return "unseen"
    end
    return "spawned"
end

function Extras.Yhwach.reconcileSummoned()
    local yh = Extras.Yhwach
    local data = yh.data()
    local changed = false
    for name, entry in pairs(data.Summoned) do
        local info = yh.Statues[name]
        if not info or typeof(entry) ~= "table" then
            data.Summoned[name] = nil
            changed = true
        elseif yh.findBoss(name) then
            yh.GoneSince[name] = nil
        else
            local have = getInventoryAmount(info.Material)
            local had = tonumber(entry.Mat) or have
            if have > had then
                data.Summoned[name] = nil
                yh.GoneSince[name] = nil
                if not data.SetKills[name] then
                    data.SetKills[name] = true
                    yh.stat("StatueKills")
                    yh.stat("SplashKills")
                    yh.Fails = 0
                end
                yh.log(string.format("STATUE %s died beside another fight | credited mat %d->%d | set %d/5", name, had, have, yh.setCount()))
                changed = true
            else
                yh.GoneSince[name] = yh.GoneSince[name] or os.clock()
                if os.clock() - yh.GoneSince[name] > yh.SummonLostAfter then
                    data.Summoned[name] = nil
                    yh.GoneSince[name] = nil
                    yh.log(string.format("STATUE %s boss gone for %ds without a credit | will summon again", name, yh.SummonLostAfter))
                    changed = true
                end
            end
        end
    end
    if changed then
        yh.save()
    end
end

function Extras.Yhwach.routeOrder(pending, count)
    local yh = Extras.Yhwach
    local rootPart = getRoot()
    local start = rootPart and rootPart.Position or yh.SoldierSpot
    local bestOrder, bestCost = nil, math.huge
    local used = {}
    local path = {}
    local function walk(position, cost)
        if cost >= bestCost then
            return
        end
        if #path == count then
            local total = cost + (yh.BossArea - position).Magnitude
            if total < bestCost then
                bestCost = total
                bestOrder = table.clone(path)
            end
            return
        end
        for _, name in ipairs(pending) do
            if not used[name] then
                local statuePosition = yh.Statues[name].Position
                used[name] = true
                table.insert(path, name)
                walk(statuePosition, cost + (statuePosition - position).Magnitude)
                table.remove(path)
                used[name] = nil
            end
        end
    end
    walk(start, 0)
    return bestOrder or {}, bestCost
end

function Extras.Yhwach.summonBatch(pending)
    local yh = Extras.Yhwach
    local data = yh.data()
    local count = math.min(#pending, math.max(1, yh.BatchSize))
    local needReishi = count * yh.SummonReishi
    local needBank = count * yh.SummonKills + yh.BankMargin
    local reishi = getInventoryAmount(yh.ReishiItem)
    if reishi < needReishi or (data.BankKnown and yh.bank() < needBank) then
        yh.farmSoldiers(string.format("%s | batch of %d | Reishi %d/%d bank %d/%d", yh.Prefix or "", count, reishi, needReishi, yh.bank(), needBank), function()
            return getInventoryAmount(yh.ReishiItem) < needReishi or (yh.data().BankKnown and yh.bank() < needBank)
        end)
        return
    end
    local maxAlive = tonumber(data.MaxAlive) or yh.MaxAliveDefault
    if data.MaxAlive and os.time() - (tonumber(data.MaxAliveAt) or 0) > yh.MaxAliveRetry then
        maxAlive = maxAlive + 1
    end
    local order, cost = yh.routeOrder(pending, maxAlive and math.max(1, math.min(count, maxAlive)) or count)
    local startedAt = os.clock()
    yh.log(string.format("BATCH summon %d (%s) | route %.0f studs | Reishi %d bank %d", #order, table.concat(order, ", "), cost, reishi, yh.bank()))
    local summoned = 0
    for _, name in ipairs(order) do
        if not yh.fightActive() or yh.findKing() then
            break
        end
        if getInventoryAmount(yh.ReishiItem) < yh.SummonReishi then
            break
        end
        local result = yh.summonStatue(name)
        if result == "spawned" or result == "alive" then
            summoned = summoned + 1
        elseif result == "cap" then
            if summoned > 0 then
                data.MaxAlive = summoned
                data.MaxAliveAt = os.time()
                yh.log("BATCH learned the boss cap: " .. tostring(summoned) .. " at a time")
                yh.save()
            end
            break
        elseif result == "refused" or result == "fail" then
            break
        end
    end
    if data.MaxAlive and summoned >= #order and summoned > tonumber(data.MaxAlive) then
        data.MaxAlive = summoned
        data.MaxAliveAt = os.time()
        yh.log("BATCH boss cap raised to " .. tostring(summoned) .. " at a time")
        yh.save()
    end
    yh.stat("BatchSeconds", os.clock() - startedAt)
    yh.log(string.format("BATCH done | %d/%d up | %.1fs", summoned, #order, os.clock() - startedAt))
end

function Extras.Yhwach.fightStatue(name)
    local yh = Extras.Yhwach
    local data = yh.data()
    local function finder()
        return yh.findBoss(name)
    end
    if not finder() then
        local reishi = getInventoryAmount(yh.ReishiItem)
        if reishi < yh.SummonReishi then
            yh.farmSoldiers(string.format("%s | Reishi %d/%d for %s", yh.Prefix or "", reishi, yh.SummonReishi, name), function()
                return getInventoryAmount(yh.ReishiItem) < yh.SummonReishi
            end)
            return
        end
        if data.BankKnown and yh.bank() < yh.SummonKills then
            yh.farmSoldiers(string.format("%s | bank %d/%d for %s", yh.Prefix or "", yh.bank(), yh.SummonKills, name), function()
                return yh.bank() < yh.SummonKills
            end)
            return
        end
        local result = yh.summonStatue(name)
        if result ~= "spawned" and result ~= "alive" then
            return
        end
    end
    local before = yh.getCounts()
    local lettersBefore = tonumber(Extras.getQuestProgress(yh.Letters)) or 0
    local killed, seconds, maxHealth = yh.killBoss(finder, name)
    yh.CapUntil = nil
    task.wait(1.5)
    local after = yh.getCounts()
    local credited = after.Mat[name] > before.Mat[name] or (tonumber(Extras.getQuestProgress(yh.Letters)) or 0) ~= lettersBefore
    if killed or credited then
        yh.stat("StatueFights")
        yh.stat("StatueSeconds", seconds)
        yh.stat("StatueReishi", math.max(0, after.Reishi - before.Reishi))
        data.LastStatueMaxHealth = maxHealth
    end
    if credited then
        if not data.SetKills[name] then
            yh.stat("StatueKills")
        end
        data.SetKills[name] = true
        data.Summoned[name] = nil
        yh.GoneSince[name] = nil
        yh.Fails = 0
    end
    yh.log(string.format("STATUE %s killed=%s credited=%s mat %d->%d Reishi %d->%d | set %d/5", name, tostring(killed), tostring(credited), before.Mat[name], after.Mat[name], before.Reishi, after.Reishi, yh.setCount()))
    yh.save()
    yh.reconcileSummoned()
end

function Extras.Yhwach.fightKing(king)
    local yh = Extras.Yhwach
    local data = yh.data()
    yh.SetDoneAt = nil
    local before = yh.getCounts()
    local beforeText = yh.snapshot()
    local pityBefore = localPlayer:GetAttribute(yh.PityAttribute)
    yh.reconcileSummoned()
    if data.KingFullSet == nil then
        data.KingFullSet = yh.setCount() >= #yh.Route
    end
    local fullSet = data.KingFullSet == true
    if yh.setCount() > 0 then
        yh.log(string.format("KING engaged | server set reset | clearing set %d/5 (fullSet=%s)", yh.setCount(), tostring(fullSet)))
    end
    data.SetKills = {}
    data.Summoned = {}
    yh.GoneSince = {}
    yh.save()
    local killed, seconds, maxHealth = yh.killBoss(yh.findKing, "Quincy King")
    task.wait(2)
    local after = yh.getCounts()
    local gotDrop = false
    for _, drop in ipairs(yh.KingDrops) do
        if after.Drop[drop.Item] > before.Drop[drop.Item] then
            gotDrop = true
        end
    end
    if killed or gotDrop then
        data.KingKills = (tonumber(data.KingKills) or 0) + 1
        data.NoKingSets = 0
        data.LastKingMaxHealth = maxHealth
        if fullSet then
            data.Sets = (tonumber(data.Sets) or 0) + 1
        end
        yh.stat("KingFights")
        yh.stat("KingSeconds", seconds)
        yh.stat("KingReishi", math.max(0, after.Reishi - before.Reishi))
        for _, drop in ipairs(yh.KingDrops) do
            if after.Drop[drop.Item] > before.Drop[drop.Item] then
                yh.stat("Drop " .. drop.Label, after.Drop[drop.Item] - before.Drop[drop.Item])
            end
        end
        if yh.SetStartedAt and fullSet then
            yh.stat("SetSeconds", os.clock() - yh.SetStartedAt)
            yh.stat("SetsTimed")
            yh.SetStartedAt = nil
        end
        local nowTime = os.time()
        local lastKingAt = tonumber(data.LastKingAt)
        if fullSet and lastKingAt and nowTime - lastKingAt < 3600 then
            data.RecentSets = typeof(data.RecentSets) == "table" and data.RecentSets or {}
            table.insert(data.RecentSets, nowTime - lastKingAt)
            while #data.RecentSets > 6 do
                table.remove(data.RecentSets, 1)
            end
            yh.log(string.format("CYCLE %.1f min King to King", (nowTime - lastKingAt) / 60))
        end
        data.LastKingAt = nowTime
    end
    if killed or gotDrop or not yh.findKing() then
        data.KingFullSet = nil
    end
    yh.log(string.format("KING killed=%s fullSet=%s pity %s->%s", tostring(killed), tostring(fullSet), tostring(pityBefore), tostring(localPlayer:GetAttribute(yh.PityAttribute))))
    yh.log("  before " .. beforeText)
    yh.log("  after  " .. yh.snapshot())
    yh.save()
end

function Extras.Yhwach.waitKing()
    local yh = Extras.Yhwach
    local data = yh.data()
    if not yh.SetDoneAt then
        yh.SetDoneAt = os.clock()
        yh.log("SET complete | waiting for the Quincy King")
    end
    local king = yh.findKing()
    if king then
        yh.log(string.format("KING appeared after %.1fs as %s", os.clock() - yh.SetDoneAt, king.Name))
        yh.fightKing(king)
        return
    end
    local waited = os.clock() - yh.SetDoneAt
    if waited < yh.KingWait then
        yh.status(string.format("%s | set complete | waiting for the Quincy King (%ds)", yh.Prefix or "", math.floor(waited)))
        task.wait(0.5)
        return
    end
    yh.status(string.format("%s | no King seen | checking the King spot", yh.Prefix or ""))
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    setTargetBox(nil)
    safeTravelTo(CFrame.new(yh.KingSpot + Vector3.new(0, 25, 0)), function()
        return yh.fightActive() and yh.findKing() == nil
    end)
    local scanUntil = os.clock() + 8
    while yh.fightActive() and os.clock() < scanUntil and not yh.findKing() do
        task.wait(0.5)
    end
    if yh.findKing() then
        yh.log("KING found at the King spot after the rescan")
        return
    end
    if not yh.fightActive() then
        return
    end
    yh.SetDoneAt = nil
    data.NoKingSets = (tonumber(data.NoKingSets) or 0) + 1
    data.SetKills = {}
    data.Summoned = {}
    yh.log("NO KING after a full set and a rescan at the King spot (" .. tostring(data.NoKingSets) .. " in a row)")
    yh.save()
    if data.NoKingSets >= yh.NoKingLimit then
        yh.halt(string.format("the Quincy King did not appear after %d full sets in a row", yh.NoKingLimit))
    end
end

function Extras.Yhwach.grindStep(stage)
    local yh = Extras.Yhwach
    local data = yh.data()
    yh.syncBank()
    local counts = yh.getCounts()
    local needs = yh.getNeeds(counts, stage)
    yh.Prefix = stage
    yh.Detail = yh.summary(counts, needs)
    yh.estimate(counts, needs)
    local craftName, blockedBy = yh.nextCraft(counts, stage)
    if craftName then
        yh.StallSince = nil
        yh.craftSchrift(craftName)
        return
    end
    if blockedBy then
        yh.StallSince = nil
        yh.farmSoldiers(string.format("%s | Reishi %d/%d to inscribe %s", stage, counts.Reishi, yh.CraftReishi, yh.Statues[blockedBy].Schrift), function()
            return getInventoryAmount(yh.ReishiItem) < yh.CraftReishi
        end)
        return
    end
    yh.reconcileSummoned()
    local wanted = {}
    for _, name in ipairs(yh.Route) do
        if needs.King then
            wanted[name] = not data.SetKills[name]
        else
            wanted[name] = needs.Letters[name] == true or needs.Mat[name] > 0
        end
    end
    local rootPart = getRoot()
    local origin = rootPart and rootPart.Position or yh.SoldierSpot
    local anyWanted = false
    local aliveName, aliveDistance = nil, math.huge
    local pending = {}
    for _, name in ipairs(yh.Route) do
        if wanted[name] then
            anyWanted = true
            local boss = yh.findBoss(name)
            local bossRoot = boss and boss:FindFirstChild("HumanoidRootPart")
            if bossRoot then
                local distance = (bossRoot.Position - origin).Magnitude
                if distance < aliveDistance then
                    aliveName, aliveDistance = name, distance
                end
            elseif not data.Summoned[name] and os.clock() >= (yh.BusyUntil[name] or 0) then
                table.insert(pending, name)
            end
        end
    end
    if aliveName then
        yh.StallSince = nil
        local aliveCount = 0
        for _, name in ipairs(yh.Route) do
            if wanted[name] and yh.findBoss(name) then
                aliveCount = aliveCount + 1
            end
        end
        if aliveCount >= 2 and os.clock() - (yh.PulledAt or 0) > yh.PullCooldown then
            yh.PulledAt = os.clock()
            yh.status(string.format("%s | gathering %d Sternritter at the boss area", stage, aliveCount))
            lockedEnemyRoot = nil
            lockedTargetCFrame = nil
            setTargetBox(nil)
            safeTravelTo(CFrame.new(yh.BossArea + Vector3.new(0, 15, 0)), function()
                return yh.fightActive()
            end)
            local holdUntil = os.clock() + yh.PullHold
            lockedTargetCFrame = CFrame.new(yh.BossArea + Vector3.new(0, 15, 0))
            while yh.fightActive() and os.clock() < holdUntil do
                task.wait(0.1)
            end
            lockedTargetCFrame = nil
            yh.log(string.format("PULL %d Sternritter at the boss area", aliveCount))
        end
        yh.fightStatue(aliveName)
        return
    end
    if #pending > 0 then
        yh.StallSince = nil
        if os.clock() < (yh.CapUntil or 0) then
            yh.farmSoldiers(string.format("%s | server boss cap | farming soldiers until a retry", stage), function()
                return os.clock() < (yh.CapUntil or 0)
            end)
            return
        end
        if yh.BatchSize > 1 then
            yh.summonBatch(pending)
        else
            yh.fightStatue(pending[1])
        end
        return
    end
    if anyWanted then
        yh.StallSince = nil
        yh.status(stage .. " | every wanted statue is busy | waiting")
        task.wait(1)
        return
    end
    if needs.King then
        yh.StallSince = nil
        yh.waitKing()
        return
    end
    yh.StallSince = yh.StallSince or os.clock()
    local stalled = os.clock() - yh.StallSince
    if stalled > yh.StallLimit then
        yh.StallSince = nil
        yh.log("STALL " .. stage .. " | nothing left to farm for " .. math.floor(stalled) .. "s | " .. yh.snapshot())
        local quests = { yh.Audience }
        local stageQuest = ({ letters = yh.Letters, successor = yh.Successor })[stage]
        if stageQuest then
            table.insert(quests, stageQuest)
        end
        for _, questName in ipairs(quests) do
            yh.log(string.format("  %s active=%s ready=%s", questName, tostring(UnlockFarm.getActiveQuestFolder(questName) ~= nil), tostring(UnlockFarm.isQuestReadyToClaim(questName))))
            for _, objective in ipairs(yh.decode(questName)) do
                yh.log(string.format("  objective %s %s %d/%d", tostring(objective.Type), tostring(objective.Target), objective.Have, objective.Need))
            end
        end
        yh.halt(string.format("nothing left to farm for %ds but %s is not ready to claim | see yhwach_log.txt", yh.StallLimit, stage))
        return
    end
    yh.status(string.format("%s | nothing left to farm for this stage | rechecking (%ds/%ds)", stage, math.floor(stalled), yh.StallLimit))
    task.wait(2)
end

function Extras.Yhwach.claimAudience()
    local yh = Extras.Yhwach
    local info = questData.Main[yh.Audience]
    local cost = typeof(info) == "table" and typeof(info.ClaimCost) == "table" and info.ClaimCost or {}
    local moneyCost = tonumber(cost.Money) or 0
    local shardCost = tonumber(cost.Shards) or 0
    if getMoney() < moneyCost + yh.MoneyMargin or yh.MoneyPhase then
        if yh.moneyPhase(moneyCost + yh.MoneyMargin, moneyCost + yh.MoneyMargin * 2, "Audience costs $" .. tostring(moneyCost / 1000000) .. "M") then
            return
        end
    end
    if getMoney() < moneyCost then
        yh.fail(string.format("Audience needs $%.0fM (have $%.1fM)", moneyCost / 1000000, getMoney() / 1000000))
        return
    end
    if getShards() < shardCost then
        yh.idle(string.format("Audience needs %d shards (have %d) | waiting", shardCost, getShards()))
        return
    end
    if not UnlockFarm.isQuestReadyToClaim(yh.Audience) then
        yh.status("Audience is not ready to claim yet")
        return
    end
    yh.log(string.format("AUDIENCE claim | cost $%d + %d shards", moneyCost, shardCost))
    yh.claimQuest(yh.Audience)
end

function Extras.Yhwach.inherit()
    local yh = Extras.Yhwach
    local requirement = yh.getRequirement(yh.InheritBuy)
    if not requirement then
        yh.halt("the Herald has no " .. yh.InheritBuy .. " choice")
        return
    end
    local missingText = yh.missing(requirement)
    if missingText then
        yh.halt("Audience is done but the inheritance is short: " .. missingText)
        return
    end
    yh.status("inheriting the Quincy King's power at the Herald")
    local npc = yh.goToHerald()
    if not npc then
        yh.fail("cannot reach the Quincy Herald to inherit")
        return
    end
    local beforeText = yh.snapshot()
    local finished, reply = invokeInput("Shop", npc, yh.InheritBuy)
    local deadline = os.clock() + ((reply == true or not finished) and 8 or 4)
    while not yh.ownsStyle() and os.clock() < deadline do
        task.wait(0.2)
    end
    local method = "shop"
    if not yh.ownsStyle() and finished and reply ~= true and reply ~= "Full" and Extras.openArayaDialogue(npc) then
        method = "dialogue"
        Extras.pickArayaChoice("inherit the king", yh.ownsStyle)
        deadline = os.clock() + 4
        while not yh.ownsStyle() and os.clock() < deadline do
            task.wait(0.2)
        end
        if isDialogueOpen() then
            Extras.pickArayaChoice("leave")
        end
    end
    yh.log(string.format("INHERIT via %s reply=%s owns=%s | %s", method, tostring(reply), tostring(yh.ownsStyle()), tostring(State.LastNotifyText)))
    yh.log("  before " .. beforeText)
    yh.log("  after  " .. yh.snapshot())
    if reply == "Full" then
        yh.halt("inventory full: free a slot for Yhwach")
    elseif not yh.ownsStyle() then
        yh.fail("inheritance not granted (reply " .. tostring(reply) .. ")")
    end
end

function Extras.Yhwach.runCycle()
    local yh = Extras.Yhwach
    local ok, errorMessage = pcall(yh.runStep)
    if ok then
        yh.ErrorStreak = 0
        return
    end
    yh.ErrorStreak = (yh.ErrorStreak or 0) + 1
    yh.releaseAll()
    yh.status("error: " .. tostring(errorMessage))
    yh.log("ERROR " .. tostring(errorMessage))
    if yh.ErrorStreak >= yh.ErrorStreakLimit then
        yh.ErrorStreak = 0
        yh.log(string.format("ERROR streak %d | pausing %ds", yh.ErrorStreakLimit, yh.ErrorPause))
        yh.idle(string.format("%d errors in a row | pausing %ds | see yhwach_log.txt", yh.ErrorStreakLimit, yh.ErrorPause))
        local resumeAt = os.clock() + yh.ErrorPause - 3
        while yh.isActive() and os.clock() < resumeAt do
            task.wait(0.5)
        end
        return
    end
    task.wait(2)
end

function Extras.Yhwach.runStep()
    local yh = Extras.Yhwach
    local dungeonName = workspaceService:GetAttribute("Dungeon")
    if dungeonName ~= nil then
        yh.releaseAll()
        yh.Idle = true
        yh.status("inside a dungeon (" .. tostring(dungeonName) .. ") | waiting")
        task.wait(2)
        return
    end
    local data = yh.data()
    if typeof(data.Halt) == "string" and data.Halt ~= "" then
        yh.stop(true)
        yh.status("halted: " .. data.Halt .. " | turn Auto Yhwach on again to retry")
        return
    end
    if yh.recentDeaths() >= yh.DeathLoopCount then
        yh.DeathTimes = {}
        yh.log(string.format("DEATH LOOP | %d deaths in %d min | pausing %ds", yh.DeathLoopCount, yh.DeathLoopWindow / 60, yh.DeathLoopPause))
        yh.idle(string.format("death loop: %d deaths in %d min | pausing %d min", yh.DeathLoopCount, yh.DeathLoopWindow / 60, yh.DeathLoopPause / 60))
        local resumeAt = os.clock() + yh.DeathLoopPause - 3
        while yh.isActive() and os.clock() < resumeAt do
            yh.status(string.format("death loop: %d deaths in %d min | resuming in %ds", yh.DeathLoopCount, yh.DeathLoopWindow / 60, math.ceil(resumeAt - os.clock())))
            task.wait(1)
        end
        yh.log("DEATH LOOP pause over | resuming")
        return
    end
    local stage = yh.getStage()
    if stage ~= yh.Stage then
        yh.Fails = 0
        yh.log("STAGE " .. tostring(stage) .. " | " .. yh.snapshot())
    end
    yh.Stage = stage
    if stage == "done" then
        yh.log("DONE Yhwach is in the inventory")
        yh.stop(true)
        yh.status("Yhwach obtained | Auto Yhwach turned itself off")
        return
    end
    if stage == "needsQuincy" then
        yh.idle("your race is not Quincy | awaken the Quincy blood first")
        return
    end
    if (stage == "waitSuccessor" or stage == "acceptAudience") and yh.inAcceptGrace(stage) then
        yh.status(stage .. " | waiting for the next quest to auto-accept")
        task.wait(1)
        return
    end
    local owned, holder = yh.claim()
    if not owned then
        yh.status("waiting for " .. tostring(holder) .. " to hand over movement")
        task.wait(0.5)
        return
    end
    yh.Idle = false
    pcall(function()
        local counts = yh.getCounts()
        yh.Detail = yh.summary(counts, yh.getNeeds(counts, stage))
    end)
    local king = yh.findKing()
    local fighting = king ~= nil and stage ~= "inherit"
    if fighting or not (stage == "letters" or stage == "successor" or stage == "audience") then
        yh.StallSince = nil
    end
    if fighting then
        yh.fightKing(king)
    elseif stage == "acceptLetters" then
        yh.acceptQuest(yh.Letters, "letters of the king")
    elseif stage == "claimLetters" then
        yh.claimQuest(yh.Letters)
    elseif stage == "waitSuccessor" then
        yh.acceptQuest(yh.Successor, nil)
    elseif stage == "claimSuccessor" then
        yh.claimQuest(yh.Successor)
    elseif stage == "acceptAudience" then
        yh.acceptQuest(yh.Audience, "audience with the king")
    elseif stage == "claimAudience" then
        yh.claimAudience()
    elseif stage == "inherit" then
        yh.inherit()
    else
        yh.grindStep(stage)
    end
    lockedTargetCFrame = nil
    releaseMovement("yhwach")
end

Extras.Bankai = {
    NPCName = "Hollow Reaper",
    NPCPosition = Vector3.new(-580, 176, 2776),
    Quest1 = "Blade Within 1",
    Quest2 = "Blade Within 2",
    Quest3 = "Blade Within 3",
    WeaponName = "Ichigo",
    WorldBossGoal = 30,
    WorldBossOrder = { "One-Eyed Owl", "Cid Kagenou", "Demon Infernal", "Dio" },
    FragmentItem = "Fragment of Stilled Reishi",
    HeartItem = "Abyssal Hollow Heart",
    RemnantItem = "Crimson Soul Remnant",
    EggName = "Nothing There Egg",
    RedMistName = "The Red Mist",
    DioName = "Dio",
    TitleName = "The Hollow Reaper",
    TitleBoss = "Ichigo Kurosaki Bankai",
    PassiveFlag = "IchigoBankaiEarned",
    SeaAmbient = Color3.fromRGB(70, 80, 92),
    SeaCooldownSeconds = 600,
    ScanPath = "LEGACY PIECE/LP_sea_of_blades_scan.txt",
    TitleKills = 0,
    AmbushWhenDone = true
}

Extras.Retreat = {
    Below = 0.45,
    Until = 0.95,
    Height = 200,
    PreferRespawn = true,
    RespawnRange = 900
}

function Extras.bankaiStatus(message)
    State.ExtraStatus = "Ichigo Bankai: " .. message
end

function Extras.isBankaiActive()
    return State.AutoBankaiEnabled
end

function Extras.hasTitle(titleName)
    local dataFolder = localPlayer:FindFirstChild("Data")
    local titlesFolder = dataFolder and dataFolder:FindFirstChild("Titles")
    if titlesFolder and titlesFolder:FindFirstChild(titleName) then
        return true
    end
    return getInventoryAmount(titleName) > 0
end

function Extras.hasBankaiPassive()
    local bankai = Extras.Bankai
    if UnlockFarm.isQuestCompleted(bankai.Quest3) then
        return true
    end
    local dataFolder = localPlayer:FindFirstChild("Data")
    local flagValue = dataFolder and dataFolder:FindFirstChild(bankai.PassiveFlag)
    if flagValue and flagValue:IsA("BoolValue") and flagValue.Value then
        return true
    end
    return localPlayer:GetAttribute(bankai.PassiveFlag) == true
end

function Extras.getBankaiMissing()
    local bankai = Extras.Bankai
    local missing = {}
    for _, itemName in ipairs({ bankai.FragmentItem, bankai.HeartItem, bankai.RemnantItem }) do
        if getInventoryAmount(itemName) < 1 then
            missing[itemName] = true
            table.insert(missing, itemName)
        end
    end
    if not Extras.hasTitle(bankai.TitleName) then
        missing[bankai.TitleName] = true
        table.insert(missing, "title " .. bankai.TitleName)
    end
    return missing
end

function Extras.getBankaiStage()
    local bankai = Extras.Bankai
    if Extras.hasBankaiPassive() then
        return "done"
    end
    if getInventoryAmount(bankai.WeaponName) <= 0 then
        return "noichigo"
    end
    if not UnlockFarm.isQuestCompleted(bankai.Quest1) then
        if not UnlockFarm.getActiveQuestFolder(bankai.Quest1) then
            return "accept", bankai.Quest1
        end
        if UnlockFarm.isQuestReadyToClaim(bankai.Quest1) or Extras.getQuestProgress(bankai.Quest1) >= bankai.WorldBossGoal then
            return "claim", bankai.Quest1
        end
        return "worldboss"
    end
    if not UnlockFarm.isQuestCompleted(bankai.Quest2) then
        if not UnlockFarm.getActiveQuestFolder(bankai.Quest2) then
            return "accept", bankai.Quest2
        end
        if UnlockFarm.isQuestReadyToClaim(bankai.Quest2) or #Extras.getBankaiMissing() == 0 then
            return "claim", bankai.Quest2
        end
        return "remnants"
    end
    return "sea"
end

Extras.ItemIndicators = {}

function Extras.connectItemIndicators()
    if getgenv().HubItemIndicatorConnections then
        return
    end
    local connections = {}
    local spawnedRemote = eventsFolder and eventsFolder:FindFirstChild("ItemIndicatorSpawned")
    local removedRemote = eventsFolder and eventsFolder:FindFirstChild("ItemIndicatorRemoved")
    if spawnedRemote then
        table.insert(connections, spawnedRemote.OnClientEvent:Connect(function(indicatorId, itemName, position)
            if typeof(position) == "Vector3" then
                Extras.ItemIndicators[tostring(indicatorId)] = {
                    Id = tostring(indicatorId),
                    Label = normalizeName(tostring(indicatorId) .. tostring(itemName)),
                    Position = position,
                    Time = os.clock()
                }
            end
        end))
    end
    if removedRemote then
        table.insert(connections, removedRemote.OnClientEvent:Connect(function(indicatorId)
            Extras.ItemIndicators[tostring(indicatorId)] = nil
        end))
    end
    getgenv().HubItemIndicatorConnections = connections
end

function Extras.findItemIndicator(keyword)
    local newest = nil
    for indicatorId, indicator in pairs(Extras.ItemIndicators) do
        if os.clock() - indicator.Time > 1800 then
            Extras.ItemIndicators[indicatorId] = nil
        elseif string.find(indicator.Label, keyword, 1, true) and (not newest or indicator.Time > newest.Time) then
            newest = indicator
        end
    end
    return newest
end

function Extras.forgetItemIndicator(keyword)
    local indicator = Extras.findItemIndicator(keyword)
    if indicator then
        Extras.ItemIndicators[indicator.Id] = nil
    end
end

function Extras.getNPCWorldPosition(npcName, fallbackPosition)
    local npc = npcsFolder:FindFirstChild(npcName)
    local part = npc and npc:FindFirstChildWhichIsA("BasePart", true)
    if part then
        return part.Position
    end
    local cframeAttribute = npc and npc:GetAttribute("CFrame")
    if typeof(cframeAttribute) == "CFrame" then
        return cframeAttribute.Position
    end
    return fallbackPosition
end

function Extras.getBankaiEggModel()
    local itemsFolder = extraFolder:FindFirstChild("Items")
    return itemsFolder and itemsFolder:FindFirstChild(Extras.Bankai.EggName)
end

function Extras.getBankaiEggPosition()
    local eggIndicator = Extras.findItemIndicator("nothingthere")
    if eggIndicator then
        return eggIndicator.Position
    end
    local eggModel = Extras.getBankaiEggModel()
    if not eggModel then
        return nil
    end
    local eggPart = eggModel:FindFirstChildWhichIsA("BasePart", true)
    if eggPart then
        return eggPart.Position
    end
    local ok, pivot = pcall(function()
        return eggModel:GetPivot()
    end)
    return ok and pivot.Position or nil
end

function Extras.collectBankaiEgg()
    local bankai = Extras.Bankai
    local eggPosition = Extras.getBankaiEggPosition()
    if not eggPosition then
        return false
    end
    local eggsBefore = getInventoryAmount(bankai.EggName)
    local function stillMissing()
        return State.AutoBankaiEnabled and getInventoryAmount(bankai.EggName) <= eggsBefore
    end

    Extras.bankaiStatus("a Nothing There Egg spawned | flying to collect it")
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    Combat.LockedMobName = nil
    setTargetBox(nil)
    safeTravelTo(CFrame.new(eggPosition + Vector3.new(0, 4, 0)), stillMissing)

    local prompt = nil
    local deadline = os.clock() + 6
    while stillMissing() and os.clock() < deadline do
        local eggModel = Extras.getBankaiEggModel()
        prompt = eggModel and eggModel:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt or not eggModel then
            break
        end
        task.wait(0.3)
    end

    if prompt then
        releaseMovement("bankai")
        collectPickup(prompt, stillMissing)
        reacquireMovement("bankai")
    else
        local eggModel = Extras.getBankaiEggModel()
        local eggPart = eggModel and eggModel:FindFirstChildWhichIsA("BasePart", true)
        local rootPart = getRoot()
        if eggPart and rootPart then
            holdPosition(eggPart.CFrame * CFrame.new(0, 2, 0))
            pcall(function()
                firetouchinterest(rootPart, eggPart, 0)
                task.wait(0.1)
                firetouchinterest(rootPart, eggPart, 1)
            end)
            task.wait(1)
        end
    end

    local collected = getInventoryAmount(bankai.EggName) > eggsBefore
    if collected or not Extras.getBankaiEggModel() then
        Extras.forgetItemIndicator("nothingthere")
    end
    if not collected then
        Extras.bankaiStatus("could not pick up the Nothing There Egg | " .. tostring(State.LastNotifyText))
        task.wait(1)
    end
    return collected
end

function Extras.getRedMistAlert()
    local alert = State.LastWorldBoss
    if not alert or alert.Handled or os.clock() - alert.Time > 480 then
        return nil
    end
    if alert.Time < (Extras.Bankai.LastRedMistEngageAt or -math.huge) + 120 then
        return nil
    end
    if normalizeName(stripBossTag(alert.Name)) ~= normalizeName(Extras.Bankai.RedMistName) then
        return nil
    end
    return alert
end

function Extras.findBossIndicator(bossName)
    local wanted = normalizeName(bossName)
    for _, child in ipairs(workspaceService:GetChildren()) do
        if child:IsA("BasePart") and string.find(child.Name, "BossIndicator", 1, true) and string.find(normalizeName(child.Name), wanted, 1, true) then
            return child
        end
    end
    return nil
end

function Extras.chaseRedMist(alert, fightCondition)
    local bankai = Extras.Bankai
    alert.Handled = true
    local indicator = Extras.findBossIndicator(bankai.RedMistName)
    if not BossFarm.isBossAlive(bankai.RedMistName) and not indicator then
        return false
    end
    Extras.bankaiStatus("The Red Mist world boss is up" .. (alert.Island and (" on " .. alert.Island) or "") .. " | flying there")
    if indicator and not BossFarm.isBossAlive(bankai.RedMistName) then
        safeTravelTo(CFrame.new(indicator.Position + Vector3.new(0, 12, 0)), function()
            return State.AutoBankaiEnabled and not BossFarm.isBossAlive(bankai.RedMistName)
        end)
    end
    if BossFarm.isBossAlive(bankai.RedMistName) then
        Extras.bankaiStatus("fighting The Red Mist (world boss) for " .. bankai.RemnantItem)
        farmMobWithAnchor(bankai.RedMistName, fightCondition, true)
        return true
    end
    Extras.bankaiStatus("The Red Mist was already gone")
    task.wait(1)
    return false
end

function Extras.delegateBankaiDeepshark(needed)
    Extras.requestDeepshark("bankai", needed)
end

Extras.DeepsharkRequesters = {}

function Extras.requestDeepshark(requester, needed)
    Extras.DeepsharkRequesters[requester] = needed and true or nil
    if needed then
        if not State.AutoDeepsharkEnabled then
            Extras.DeepsharkDelegated = true
            Extras.startLoop("AutoDeepsharkEnabled", Extras.runDeepsharkCycle)
            Extras.syncToggle("DeepsharkToggle", true)
        end
        return
    end
    if Extras.DeepsharkDelegated and next(Extras.DeepsharkRequesters) == nil then
        Extras.DeepsharkDelegated = false
        Extras.endDeepsharkFishing()
        Extras.stopLoop("AutoDeepsharkEnabled", "deepshark")
        Extras.syncToggle("DeepsharkToggle", false)
    end
end

function Extras.findInventoryItemByIdentity(identity)
    local dataFolder = localPlayer:FindFirstChild("Data")
    local inventoryFolder = dataFolder and dataFolder:FindFirstChild("Inventory")
    if not inventoryFolder then
        return nil
    end
    for _, item in ipairs(inventoryFolder:GetChildren()) do
        local identityValue = item:FindFirstChild("Identity")
        if (identityValue and identityValue.Value == identity) or item.Name == identity then
            return item.Name
        end
    end
    return nil
end

function Extras.holdIchigo()
    local bankai = Extras.Bankai
    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end
    if character:FindFirstChild(bankai.WeaponName) then
        return true
    end

    if not isItemEquipped(bankai.WeaponName) then
        local dataFolder = localPlayer:FindFirstChild("Data")
        local currentWeapon = dataFolder and dataFolder:FindFirstChild("CurrentWeapon")
        if currentWeapon and not bankai.PreviousWeapon then
            bankai.PreviousWeapon = Extras.findInventoryItemByIdentity(currentWeapon.Value)
        end
        equipInventoryItem(bankai.WeaponName)
    end

    local backpack = localPlayer:FindFirstChild("Backpack")
    local deadline = os.clock() + 4
    local tool = nil
    while os.clock() < deadline do
        tool = (backpack and backpack:FindFirstChild(bankai.WeaponName)) or character:FindFirstChild(bankai.WeaponName)
        if tool then
            break
        end
        task.wait(0.2)
    end
    if not tool then
        return false
    end
    if tool.Parent ~= character then
        humanoid:EquipTool(tool)
        task.wait(0.4)
    end
    return character:FindFirstChild(bankai.WeaponName) ~= nil
end

function Extras.restoreBankaiWeapon()
    local bankai = Extras.Bankai
    local previous = bankai.PreviousWeapon
    bankai.PreviousWeapon = nil
    if previous and previous ~= bankai.WeaponName and getInventoryAmount(previous) > 0 then
        equipInventoryItem(previous)
    end
end

function Extras.goToHollowReaper()
    local bankai = Extras.Bankai
    local rootPart = getRoot()
    if rootPart and (rootPart.Position - bankai.NPCPosition).Magnitude > 150 then
        Extras.bankaiStatus("flying to the Hollow Reaper (Hollow Land)")
        safeTravelTo(CFrame.new(bankai.NPCPosition + Vector3.new(0, 6, 0)), Extras.isBankaiActive)
    end
    local npc = npcsFolder:FindFirstChild(bankai.NPCName) or npcsFolder:WaitForChild(bankai.NPCName, 5)
    local deadline = os.clock() + 5
    while npc and not npc:FindFirstChildWhichIsA("BasePart", true) and os.clock() < deadline do
        task.wait(0.2)
    end
    if not npc or not npc:FindFirstChildWhichIsA("BasePart", true) then
        return nil
    end
    if not travelToNPC(npc, Extras.isBankaiActive) then
        return nil
    end
    return npcsFolder:FindFirstChild(bankai.NPCName) or npc
end

function Extras.getDialogueText()
    local dialogueRoot = getDialogueRoot()
    if not dialogueRoot then
        return ""
    end
    local texts = {}
    for _, descendant in ipairs(dialogueRoot:GetDescendants()) do
        if descendant:IsA("TextLabel") and descendant.Text ~= "" then
            table.insert(texts, stripRichText(descendant.Text))
        end
    end
    return table.concat(texts, " ")
end

function Extras.pickBankaiWorldBoss()
    local bankai = Extras.Bankai
    for _, bossName in ipairs(bankai.WorldBossOrder) do
        local catalogItem = BossFarm.getSummonEntry(bossName)
        if catalogItem and #BossFarm.getSummonShortfall(catalogItem) == 0 then
            return catalogItem
        end
    end
    return BossFarm.getSummonEntry(bankai.WorldBossOrder[1])
end

function Extras.runBankaiWorldBoss()
    local bankai = Extras.Bankai
    local function stillCounting()
        return State.AutoBankaiEnabled and Extras.getQuestProgress(bankai.Quest1) < bankai.WorldBossGoal
    end
    local progressText = string.format("World Bosses %d/%d", Extras.getQuestProgress(bankai.Quest1), bankai.WorldBossGoal)

    for _, bossName in ipairs({ "One-Eyed Owl", "Cid Kagenou", "Demon Infernal", "Dio", bankai.RedMistName }) do
        if BossFarm.isBossAlive(bossName) then
            Extras.bankaiStatus(progressText .. " | fighting " .. bossName)
            farmMobWithAnchor(bossName, stillCounting, true)
            return
        end
    end

    local catalogItem = Extras.pickBankaiWorldBoss()
    if not catalogItem then
        Extras.bankaiStatus(progressText .. " | no summonable world boss found")
        task.wait(2)
        return
    end
    Extras.bankaiStatus(progressText .. " | summoning " .. catalogItem.Name)
    BossFarm.prepareAndKill(catalogItem, stillCounting, "bankai")
end

function Extras.planBankaiRemnants(missing)
    local bankai = Extras.Bankai
    local solemn = Extras.Solemn
    local ownBossAlive = BossFarm.isBossAlive(bankai.TitleBoss) or BossFarm.isBossAlive(bankai.RedMistName)
    if not ownBossAlive and (bankai.TicketMoneyActive or (getMoney() < solemn.TicketMoneyFloor and getInventoryAmount("Boss Ticket") < 100)) then
        bankai.TicketMoneyActive = getMoney() < solemn.TicketMoneyTarget
        if bankai.TicketMoneyActive then
            return "ticketmoney"
        end
    end
    if missing[bankai.RemnantItem] then
        if BossFarm.isBossAlive(bankai.RedMistName) then
            return "redmist"
        end
        if getInventoryAmount(bankai.EggName) > 0 then
            return "redmist"
        end
        if Extras.getBankaiEggPosition() then
            return "egg"
        end
        if Extras.getRedMistAlert() then
            return "chase"
        end
    end
    if missing[bankai.FragmentItem] then
        return "dio"
    end
    if missing[bankai.HeartItem] then
        return "deepshark"
    end
    if missing[bankai.TitleName] then
        return "title"
    end
    if missing[bankai.RemnantItem] then
        return "wait"
    end
    return "claim"
end

function Extras.bankaiFightCondition()
    local bankai = Extras.Bankai
    return function()
        if not State.AutoBankaiEnabled then
            return false
        end
        local wantsEgg = getInventoryAmount(bankai.RemnantItem) < 1 and getInventoryAmount(bankai.EggName) <= 0
        if wantsEgg and Extras.getBankaiEggPosition() then
            return false
        end
        return true
    end
end

function Extras.findNearestSpawner(position)
    local bestSpawner, bestPosition, bestDistance = nil, nil, math.huge
    for _, npc in ipairs(npcsFolder:GetChildren()) do
        if npc.Name == "Spawner" then
            local cframeAttribute = npc:GetAttribute("CFrame")
            local part = npc:FindFirstChildWhichIsA("BasePart", true)
            local spawnerPosition = (typeof(cframeAttribute) == "CFrame" and cframeAttribute.Position) or (part and part.Position)
            if spawnerPosition then
                local distance = (spawnerPosition - position).Magnitude
                if distance < bestDistance then
                    bestSpawner, bestPosition, bestDistance = npc, spawnerPosition, distance
                end
            end
        end
    end
    return bestSpawner, bestPosition, bestDistance
end

function Extras.isRespawnNear(position)
    local spawnValue = localPlayer:FindFirstChild("Data") and localPlayer.Data:FindFirstChild("Spawn")
    return Extras.SpawnSetPosition ~= nil and spawnValue ~= nil and spawnValue.Value == Extras.SpawnSetValue
        and (Extras.SpawnSetPosition - position).Magnitude <= Extras.Retreat.RespawnRange
end

function Extras.ensureSpawnNear(position, isActive, statusSetter)
    if not position or Extras.isRespawnNear(position) then
        return true
    end
    local spawner, spawnerPosition, distance = Extras.findNearestSpawner(position)
    if not spawner or distance > Extras.Retreat.RespawnRange then
        return false
    end
    local spawnValue = localPlayer:FindFirstChild("Data") and localPlayer.Data:FindFirstChild("Spawn")
    if not spawnValue then
        return false
    end

    statusSetter("setting the respawn point at the Spawner next to the fight")
    Extras.clearCombatLocks()
    safeTravelTo(CFrame.new(spawnerPosition + Vector3.new(0, 4, 5)), isActive)
    local prompt = nil
    local deadline = os.clock() + 6
    while isActive() and os.clock() < deadline and not prompt do
        for _, npc in ipairs(npcsFolder:GetChildren()) do
            if npc.Name == "Spawner" then
                local part = npc:FindFirstChildWhichIsA("BasePart", true)
                if part and (part.Position - spawnerPosition).Magnitude < 30 then
                    prompt = npc:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then
                        spawner = npc
                        break
                    end
                end
            end
        end
        if not prompt then
            task.wait(0.3)
        end
    end
    if not prompt then
        statusSetter("could not reach the Spawner")
        return false
    end

    local spawnBefore = spawnValue.Value
    local sentAt = os.clock()
    local promptHolder = prompt.Parent
    local promptPosition = (promptHolder:IsA("BasePart") and promptHolder.Position) or (promptHolder:IsA("Attachment") and promptHolder.WorldPosition) or spawnerPosition
    settleCharacter()
    travelTo(CFrame.new(promptPosition + Vector3.new(0, 2, 4)), isActive)
    triggerPrompt(prompt)
    local confirmDeadline = os.clock() + 4
    local confirmed = false
    while os.clock() < confirmDeadline do
        if spawnValue.Value ~= spawnBefore then
            confirmed = true
            break
        end
        if (State.LastNotifyTime or 0) >= sentAt and string.find(string.lower(tostring(State.LastNotifyText)), "spawn", 1, true) then
            confirmed = true
            break
        end
        if string.find(string.lower(Extras.getDialogueText()), "already set spawn", 1, true) then
            confirmed = true
            break
        end
        task.wait(0.2)
    end
    if not confirmed then
        statusSetter("Spawner did not answer | " .. tostring(State.LastNotifyText))
        return false
    end
    Extras.SpawnSetPosition = spawnerPosition
    Extras.SpawnSetValue = spawnValue.Value
    Extras.saveLearned()
    return true
end

function Extras.recoverHealth(isActive, label, options)
    options = options or {}
    local retreat = Extras.Retreat
    local rootPart, humanoid = getRoot()
    if not rootPart or not humanoid or humanoid.Health <= 0 or humanoid.MaxHealth <= 0 then
        return false
    end
    if State.SafeTravel or (not options.IgnoreRespawn and retreat.PreferRespawn and Extras.isRespawnNear(rootPart.Position)) then
        return false
    end
    if humanoid.Health / humanoid.MaxHealth >= (options.Below or retreat.Below) then
        return false
    end

    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    Combat.LockedMobName = nil
    setTargetBox(nil)
    local safeCFrame = CFrame.new(rootPart.Position + Vector3.new(0, options.Height or retreat.Height, 0))
    travelTo(safeCFrame, function()
        return isActive() and humanoid.Health > 0
    end)
    lockedTargetCFrame = safeCFrame

    local untilRatio = options.Until or retreat.Until
    local deadline = os.clock() + 90
    while isActive() and humanoid.Parent and humanoid.Health > 0 and humanoid.Health / humanoid.MaxHealth < untilRatio and os.clock() < deadline do
        State.ExtraStatus = string.format("%s: HP %d%% | backing off to heal before going back in", label, math.floor(humanoid.Health / humanoid.MaxHealth * 100))
        holdPosition(safeCFrame)
        task.wait(0.5)
    end
    lockedTargetCFrame = nil
    return true
end

function Extras.recoverBankaiHealth()
    return Extras.recoverHealth(Extras.isBankaiActive, "Ichigo Bankai")
end

function Extras.trackBossKills(holder, bossName)
    local tracked = holder.TrackedBoss
    if tracked then
        local humanoid = tracked.Model:FindFirstChildOfClass("Humanoid")
        if tracked.Model.Parent == nil or not humanoid or humanoid.Health <= 0 then
            if tracked.LowestRatio <= 0.2 then
                holder.TitleKills = holder.TitleKills + 1
                holder.Escapes = 0
            elseif tracked.Model.Parent == nil and (not humanoid or humanoid.Health > 0) then
                local currentRoot = getRoot()
                if currentRoot and tracked.LastPosition and (currentRoot.Position - tracked.LastPosition).Magnitude < 1200 then
                    holder.Escapes = (holder.Escapes or 0) + 1
                end
            end
            holder.TrackedBoss = nil
            tracked = nil
        else
            tracked.LowestRatio = math.min(tracked.LowestRatio, humanoid.Health / math.max(humanoid.MaxHealth, 1))
            local trackedRoot = tracked.Model:FindFirstChild("HumanoidRootPart")
            if trackedRoot then
                tracked.LastPosition = trackedRoot.Position
            end
        end
    end
    local rootPart = getRoot()
    local enemy = rootPart and getTargetEnemy(bossName, rootPart.Position, true)
    if enemy and (not tracked or tracked.Model ~= enemy) then
        local humanoid = enemy:FindFirstChildOfClass("Humanoid")
        holder.TrackedBoss = {
            Model = enemy,
            LowestRatio = humanoid and humanoid.Health / math.max(humanoid.MaxHealth, 1) or 1
        }
    end
end

function Extras.trackTitleBoss()
    Extras.trackBossKills(Extras.Bankai, Extras.Bankai.TitleBoss)
end

function Extras.runBankaiRemnants(plan, missing)
    local bankai = Extras.Bankai
    local missingText = "missing: " .. table.concat(missing, ", ")
    local fightCondition = Extras.bankaiFightCondition()

    if plan == "egg" then
        Extras.collectBankaiEgg()
    elseif plan == "ticketmoney" then
        local target = Extras.Solemn.TicketMoneyTarget
        local label = string.format("money for Boss Tickets $%dM/%dM", math.floor(getMoney() / 1000000), math.floor(target / 1000000))
        local isActive = function()
            return fightCondition() and getMoney() < target
        end
        if not Extras.runAmbushDuty(isActive, "Ichigo Bankai: " .. label .. " | Ambush") then
            Extras.bankaiStatus(label .. " | Ambush: waiting for the next ambush")
            task.wait(0.5)
        end
    elseif plan == "chase" then
        Extras.chaseRedMist(Extras.getRedMistAlert(), fightCondition)
    elseif plan == "redmist" then
        Extras.bankaiStatus(string.format("The Red Mist for %s | eggs %d | %s", bankai.RemnantItem, getInventoryAmount(bankai.EggName), missingText))
        bankai.LastRedMistEngageAt = os.clock()
        BossFarm.prepareAndKill(BossFarm.getSummonEntry(bankai.RedMistName), fightCondition, "bankai")
        bankai.LastRedMistEngageAt = os.clock()
    elseif plan == "dio" then
        Extras.bankaiStatus("Dio for " .. bankai.FragmentItem .. " | " .. missingText)
        BossFarm.prepareAndKill(BossFarm.getSummonEntry(bankai.DioName), fightCondition, "bankai")
    elseif plan == "title" then
        Extras.ensureSpawnNear(Extras.getNPCWorldPosition("The Whisperer"), Extras.isBankaiActive, Extras.bankaiStatus)
        Extras.trackTitleBoss()
        Extras.bankaiStatus(string.format("%s for the title (kills this session %d, pity 80) | %s", bankai.TitleBoss, bankai.TitleKills, missingText))
        BossFarm.prepareAndKill(BossFarm.getSummonEntry(bankai.TitleBoss), fightCondition, "bankai")
        Extras.trackTitleBoss()
    elseif plan == "wait" then
        Extras.bankaiStatus(string.format("waiting for a Nothing There Egg to spawn or a Red Mist world boss (eggs %d) | %s", getInventoryAmount(bankai.EggName), missingText))
        task.wait(2)
    end
end

function Extras.isInSeaOfBlades()
    local rootPart = getRoot()
    if not rootPart or (rootPart.Position - Extras.Bankai.NPCPosition).Magnitude <= 400 then
        return false
    end
    local trialsFolder = workspaceService:FindFirstChild("IchigoTrials")
    if trialsFolder then
        for _, trial in ipairs(trialsFolder:GetChildren()) do
            local spawnPart = trial:FindFirstChild("Spawn")
            local swordsModel = trial:FindFirstChild("Swords")
            local anchorPosition = (spawnPart and spawnPart:IsA("BasePart") and spawnPart.Position) or (swordsModel and swordsModel:IsA("Model") and swordsModel:GetPivot().Position) or nil
            if anchorPosition and (anchorPosition - rootPart.Position).Magnitude <= 6000 then
                return true
            end
        end
    end
    local ambient = game:GetService("Lighting").Ambient
    local wanted = Extras.Bankai.SeaAmbient
    return math.abs(ambient.R - wanted.R) < 0.02 and math.abs(ambient.G - wanted.G) < 0.02 and math.abs(ambient.B - wanted.B) < 0.02
end

function Extras.describeBladeCandidate(prompt)
    local holder = prompt.Parent
    local model = prompt:FindFirstAncestorOfClass("Model") or holder
    local names = { model.Name, holder.Name, prompt.ObjectText, prompt.ActionText }
    local attributes = {}
    for _, instance in ipairs({ model, holder, prompt }) do
        for key, value in pairs(instance:GetAttributes()) do
            table.insert(attributes, { Key = string.lower(tostring(key)), Value = value })
        end
    end
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("TextLabel") and descendant.Text ~= "" then
            table.insert(names, stripRichText(descendant.Text))
        end
    end
    return model, names, attributes
end

function Extras.scoreBladeCandidate(names, attributes)
    local loweredNames = string.lower(table.concat(names, " | "))
    local trueKeys = { ["true"] = true, istrue = true, correct = true, iscorrect = true, real = true, isreal = true, genuine = true, trueblade = true, istrueblade = true }
    local falseKeys = { fake = true, isfake = true, ["false"] = true, decoy = true, isdecoy = true, falseblade = true, isfalseblade = true }
    for _, attribute in ipairs(attributes) do
        if trueKeys[attribute.Key] and attribute.Value == true then
            return 1
        end
        if falseKeys[attribute.Key] and attribute.Value == true then
            return -1
        end
        if typeof(attribute.Value) == "string" then
            local loweredValue = string.lower(attribute.Value)
            if string.find(loweredValue, "true blade", 1, true) or loweredValue == "true" then
                return 1
            end
            if string.find(loweredValue, "false", 1, true) or string.find(loweredValue, "fake", 1, true) then
                return -1
            end
        end
    end
    if string.find(loweredNames, "false", 1, true) or string.find(loweredNames, "fake", 1, true) or string.find(loweredNames, "decoy", 1, true) then
        return -1
    end
    if string.find(loweredNames, "%f[%a]true%f[%A]") then
        return 1
    end
    return 0
end

function Extras.scanSeaBlades()
    local rootPart = getRoot()
    local candidates = {}
    if not rootPart then
        return candidates
    end
    for _, descendant in ipairs(workspaceService:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") and descendant.Enabled and not descendant:IsDescendantOf(npcsFolder) then
            local holder = descendant.Parent
            local position = nil
            if holder and holder:IsA("BasePart") then
                position = holder.Position
            elseif holder and holder:IsA("Attachment") then
                position = holder.WorldPosition
            end
            if position and (position - rootPart.Position).Magnitude <= 600 then
                local model, names, attributes = Extras.describeBladeCandidate(descendant)
                local loweredNames = string.lower(table.concat(names, " "))
                if string.find(loweredNames, "zangetsu", 1, true) or string.find(loweredNames, "blade", 1, true) or string.find(loweredNames, "sword", 1, true) then
                    table.insert(candidates, {
                        Prompt = descendant,
                        Position = position,
                        Model = model,
                        Names = names,
                        Attributes = attributes,
                        Score = Extras.scoreBladeCandidate(names, attributes),
                        Signature = model.Name .. "|" .. descendant.ObjectText .. "|" .. descendant.ActionText
                    })
                end
            end
        end
    end
    return candidates
end

function Extras.chooseTrueBlade(candidates)
    local marked = {}
    local unmarked = {}
    for _, candidate in ipairs(candidates) do
        if candidate.Score > 0 then
            table.insert(marked, candidate)
        elseif candidate.Score == 0 then
            table.insert(unmarked, candidate)
        end
    end
    if #marked == 1 then
        return marked[1], "marked true"
    end
    local pool = #marked > 1 and marked or unmarked
    if #pool >= 3 then
        local signatureCount = {}
        for _, candidate in ipairs(pool) do
            signatureCount[candidate.Signature] = (signatureCount[candidate.Signature] or 0) + 1
        end
        local oddOnes = {}
        for _, candidate in ipairs(pool) do
            if signatureCount[candidate.Signature] == 1 then
                table.insert(oddOnes, candidate)
            end
        end
        if #oddOnes == 1 then
            return oddOnes[1], "only blade that looks different"
        end
    end
    if #pool > 0 then
        return pool[math.random(1, #pool)], "no marker found, guessed"
    end
    return nil, "no blades found"
end

function Extras.saveBladeScan(candidates, chosen, reason)
    local lines = { os.date("%Y-%m-%d %H:%M:%S") .. " candidates=" .. #candidates .. " choice=" .. tostring(chosen and chosen.Signature) .. " reason=" .. tostring(reason) }
    local rootPart = getRoot()
    for index, candidate in ipairs(candidates) do
        local attributeParts = {}
        for _, attribute in ipairs(candidate.Attributes) do
            table.insert(attributeParts, attribute.Key .. "=" .. tostring(attribute.Value))
        end
        table.insert(lines, string.format("%d score=%d dist=%d path=%s names=[%s] attrs=[%s]", index, candidate.Score, rootPart and math.floor((candidate.Position - rootPart.Position).Magnitude) or -1, candidate.Prompt:GetFullName(), table.concat(candidate.Names, " / "), table.concat(attributeParts, ", ")))
    end
    pcall(function()
        appendfile(Extras.Bankai.ScanPath, table.concat(lines, "\n") .. "\n\n")
    end)
end

function Extras.pickSeaBlade()
    local bankai = Extras.Bankai
    Extras.holdIchigo()
    local candidates = Extras.scanSeaBlades()
    local chosen, reason = Extras.chooseTrueBlade(candidates)
    Extras.saveBladeScan(candidates, chosen, reason)
    if not chosen then
        Extras.bankaiStatus("inside the Sea of Blades | no blades found yet")
        task.wait(1.5)
        return
    end

    Extras.bankaiStatus(string.format("Sea of Blades: taking a blade (%s, %d candidates)", reason, #candidates))
    local rootPart = getRoot()
    if rootPart and (chosen.Position - rootPart.Position).Magnitude > math.max((chosen.Prompt.MaxActivationDistance or 10) - 3, 3) then
        travelTo(CFrame.new(chosen.Position + Vector3.new(0, 3, 4), chosen.Position), Extras.isBankaiActive)
    end
    lockedTargetCFrame = CFrame.new(chosen.Position + Vector3.new(0, 3, 4), chosen.Position)
    settleCharacter()
    Extras.holdIchigo()
    task.wait(0.5)
    local livePrompt = (chosen.Model and chosen.Model:FindFirstChildWhichIsA("ProximityPrompt", true)) or chosen.Prompt
    triggerPrompt(livePrompt)

    local deadline = os.clock() + 10
    while State.AutoBankaiEnabled and os.clock() < deadline do
        if Extras.hasBankaiPassive() then
            Extras.bankaiStatus("the true Zangetsu answered | Bankai obtained")
            return
        end
        if not Extras.isInSeaOfBlades() then
            break
        end
        task.wait(0.3)
    end
    if not Extras.hasBankaiPassive() and not Extras.isInSeaOfBlades() then
        bankai.SeaCooldownUntil = os.clock() + bankai.SeaCooldownSeconds
        Extras.bankaiStatus("wrong blade | the Sea rejected us, retrying in 10 minutes")
    end
end

function Extras.runBankaiSea()
    local bankai = Extras.Bankai
    if Extras.isInSeaOfBlades() then
        Extras.pickSeaBlade()
        return
    end

    local cooldownLeft = (bankai.SeaCooldownUntil or 0) - os.clock()
    if cooldownLeft > 0 then
        Extras.bankaiStatus(string.format("Sea of Blades cooldown %d:%02d", math.floor(cooldownLeft / 60), math.floor(cooldownLeft % 60)))
        task.wait(2)
        return
    end

    local npc = Extras.goToHollowReaper()
    if not npc then
        Extras.bankaiStatus("cannot reach the Hollow Reaper")
        task.wait(1)
        return
    end
    if not Extras.holdIchigo() then
        Extras.bankaiStatus("could not draw Ichigo")
        task.wait(1)
        return
    end

    Extras.bankaiStatus("asking the Hollow Reaper to open the Sea of Blades")
    Extras.openArayaDialogue(npc)
    Extras.pickArayaChoice("open the sea of blades", function()
        return Extras.isInSeaOfBlades()
    end)

    local deadline = os.clock() + 12
    while State.AutoBankaiEnabled and os.clock() < deadline and not Extras.isInSeaOfBlades() do
        local dialogueText = string.lower(Extras.getDialogueText())
        local minutes = tonumber(string.match(dialogueText, "(%d+)%s*minute"))
        if minutes then
            bankai.SeaCooldownUntil = os.clock() + minutes * 60
            Extras.bankaiStatus("the Sea of Blades is on cooldown for " .. minutes .. " minute(s)")
            return
        end
        if string.find(dialogueText, "too young", 1, true) then
            Extras.bankaiStatus("Ichigo must be enhanced to +10 first | stopped")
            Extras.stopBankai()
            return
        end
        task.wait(0.3)
    end
    if not Extras.isInSeaOfBlades() then
        Extras.bankaiStatus("the Sea of Blades did not open | " .. stripRichText(Extras.getDialogueText()))
        task.wait(2)
    end
end

function Extras.stopBankai()
    Extras.delegateBankaiDeepshark(false)
    Extras.stopLoop("AutoBankaiEnabled", "bankai")
    Extras.syncToggle("BankaiToggle", false)
    task.spawn(Extras.restoreBankaiWeapon)
end

function Extras.startBankaiAmbush()
    local bankai = Extras.Bankai
    bankai.PreviousWeapon = nil
    Extras.delegateBankaiDeepshark(false)
    Extras.stopLoop("AutoBankaiEnabled", "bankai")
    Extras.syncToggle("BankaiToggle", false)
    if not isItemEquipped(bankai.WeaponName) then
        equipInventoryItem(bankai.WeaponName)
    end
    State.FarmCombatType = "Sword"
    State.FarmCombatTypes = { Sword = true }
    pcall(function()
        UIController.WeaponTypeDropdown:UpdateSelection({ "Sword" })
    end)
    Extras.NextAmbushAt = 0
    Extras.startLoop("AutoAmbushOnlyEnabled", Extras.runAmbushOnlyCycle)
    Extras.syncToggle("AmbushOnlyToggle", true)
    State.ExtraStatus = "Ichigo Bankai: passive obtained | farming Auto Ambush with " .. bankai.WeaponName
end

function Extras.runBankaiCycle()
    Extras.connectItemIndicators()
    local bankai = Extras.Bankai
    local stage, questName = Extras.getBankaiStage()

    if stage == "done" then
        if bankai.AmbushWhenDone then
            Extras.startBankaiAmbush()
            return
        end
        Extras.bankaiStatus("Bankai passive obtained | stopped")
        Extras.stopBankai()
        return
    end
    if stage == "noichigo" then
        Extras.bankaiStatus("you do not own Ichigo | stopped")
        Extras.stopBankai()
        return
    end

    local missing = Extras.getBankaiMissing()
    local plan = stage == "remnants" and Extras.planBankaiRemnants(missing) or nil
    if plan == "deepshark" then
        if not State.AutoDeepsharkEnabled then
            Extras.bankaiStatus("need " .. bankai.HeartItem .. " | starting Auto Ancient Deepshark")
        end
        Extras.delegateBankaiDeepshark(true)
        task.wait(2)
        return
    end
    Extras.delegateBankaiDeepshark(false)

    if not acquireMovement("bankai") then
        Extras.bankaiStatus("waiting for " .. tostring(movementOwner) .. " to finish")
        task.wait(1)
        return
    end

    if (stage == "worldboss" or stage == "remnants") and Extras.recoverBankaiHealth() then
        releaseMovement("bankai")
        return
    end

    if stage == "accept" then
        Extras.bankaiStatus("accepting " .. questName)
        local npc = Extras.goToHollowReaper()
        if npc then
            Extras.holdIchigo()
            UnlockFarm.acceptQuest(questName)
            if not UnlockFarm.getActiveQuestFolder(questName) then
                local dialogueText = string.lower(Extras.getDialogueText())
                if string.find(dialogueText, "too young", 1, true) then
                    Extras.bankaiStatus("Ichigo must be enhanced to +10 before the Hollow Reaper will talk | stopped")
                    releaseMovement("bankai")
                    Extras.stopBankai()
                    return
                end
                Extras.bankaiStatus(questName .. " not accepted | " .. tostring(State.LastNotifyText))
                task.wait(2)
            end
            Extras.restoreBankaiWeapon()
        else
            Extras.bankaiStatus("cannot reach the Hollow Reaper")
            task.wait(1)
        end
    elseif stage == "claim" then
        Extras.bankaiStatus("turning in " .. questName)
        if Extras.goToHollowReaper() then
            UnlockFarm.claimQuest(questName)
            if not UnlockFarm.isQuestCompleted(questName) then
                Extras.bankaiStatus(questName .. " not accepted yet | " .. tostring(State.LastNotifyText))
                task.wait(2)
            end
        else
            Extras.bankaiStatus("cannot reach the Hollow Reaper")
            task.wait(1)
        end
    elseif stage == "worldboss" then
        Extras.runBankaiWorldBoss()
    elseif stage == "remnants" then
        Extras.runBankaiRemnants(plan, missing)
    elseif stage == "sea" then
        Extras.runBankaiSea()
    end

    lockedTargetCFrame = nil
    releaseMovement("bankai")
end

function Extras.isCoffinCandidate(instance)
    if not instance or not instance.Parent then
        return false
    end
    if not (instance:IsA("Model") or instance:IsA("BasePart")) then
        return false
    end
    if not string.find(string.lower(instance.Name), "coffin", 1, true) then
        return false
    end
    local islandsFolder = workspaceService:FindFirstChild("Islands")
    if islandsFolder and instance:IsDescendantOf(islandsFolder) then
        return false
    end
    if instance:IsDescendantOf(enemiesFolder) or instance:IsDescendantOf(npcsFolder) then
        return false
    end
    for _, player in ipairs(playersService:GetPlayers()) do
        if player.Character and instance:IsDescendantOf(player.Character) then
            return false
        end
    end
    return true
end

function Extras.getCoffinPrompt(coffin)
    for _, descendant in ipairs(coffin:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") and descendant.Enabled then
            return descendant
        end
    end
    return nil
end

function Extras.watchCoffins()
    if getgenv().HubCoffinConnection then
        pcall(function()
            getgenv().HubCoffinConnection:Disconnect()
        end)
    end

    Extras.CoffinCandidates = {}
    for _, descendant in ipairs(extraFolder:GetDescendants()) do
        if Extras.isCoffinCandidate(descendant) then
            Extras.CoffinCandidates[descendant] = true
        end
    end
    for _, child in ipairs(workspaceService:GetChildren()) do
        if Extras.isCoffinCandidate(child) then
            Extras.CoffinCandidates[child] = true
        end
    end

    getgenv().HubCoffinConnection = workspaceService.DescendantAdded:Connect(function(descendant)
        if string.find(string.lower(descendant.Name), "coffin", 1, true) then
            task.defer(function()
                if Extras.isCoffinCandidate(descendant) then
                    Extras.CoffinCandidates[descendant] = true
                end
            end)
        end
    end)
end

function Extras.findCoffin()
    for coffin in pairs(Extras.CoffinCandidates) do
        if not Extras.isCoffinCandidate(coffin) then
            Extras.CoffinCandidates[coffin] = nil
        else
            local prompt = Extras.getCoffinPrompt(coffin)
            if prompt then
                return coffin, prompt
            end
        end
    end
    return nil, nil
end

function Extras.isCarryingCoffin()
    local character = localPlayer.Character
    if not character then
        return false
    end
    for _, descendant in ipairs(character:GetDescendants()) do
        if string.find(string.lower(descendant.Name), "coffin", 1, true) then
            local topLevel = descendant
            while topLevel.Parent and topLevel.Parent ~= character do
                topLevel = topLevel.Parent
            end
            local cosmetic = topLevel ~= descendant and (topLevel:IsA("Tool") or topLevel:IsA("Accessory") or string.sub(topLevel.Name, -6) == " Model" or string.sub(topLevel.Name, -6) == " Style")
            if not cosmetic then
                return true
            end
        end
    end
    for _, holder in ipairs({ character, localPlayer }) do
        for attributeName, attributeValue in pairs(holder:GetAttributes()) do
            if string.find(string.lower(attributeName), "coffin", 1, true) and attributeValue then
                return true
            end
        end
    end
    return false
end

Extras.StrangerName = "Mysterious Stranger"
Extras.StrangerPosition = Vector3.new(2956, 66, -3174)

function Extras.isAutoCoffinActive()
    return State.AutoCoffinEnabled
end

function Extras.clearCombatLocks()
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    Combat.ApproachRoot = nil
    Combat.LockedMobName = nil
    setTargetBox(nil)
end

Extras.FlightKeyCache = Extras.FlightKeyCache or {}

function Extras.findFlightAbility()
    local playerCharacter = localPlayer.Character
    local backpack = localPlayer:FindFirstChild("Backpack")
    for _, container in ipairs({ playerCharacter, backpack }) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and tool:GetAttribute("Type") == "Ability" then
                    if tool.Parent == playerCharacter and Extras.FlightKeyCache[tool.Name] == nil then
                        local activeTool = Combat.getActiveTool(tool)
                        if activeTool then
                            Extras.FlightKeyCache[tool.Name] = Extras.getFlightKey(activeTool) or false
                        end
                    end
                    if Extras.FlightKeyCache[tool.Name] ~= false then
                        return tool
                    end
                end
            end
        end
    end
    return nil
end

function Extras.getFlightKey(activeTool)
    if not activeTool or type(activeTool.SkillList) ~= "table" then
        return nil
    end
    for _, entry in ipairs(activeTool.SkillList) do
        if type(entry) == "table" and type(entry.AbilityName) == "string" and type(entry.Key) == "string"
            and string.find(string.lower(entry.AbilityName), "flight", 1, true) then
            return string.sub(string.upper(entry.Key), 1, 1)
        end
    end
    return nil
end

function Extras.abilityFlyTo(targetPosition, isActive, maxSeconds)
    local tool = Extras.findFlightAbility()
    local swimRoot, playerHumanoid = getRoot()
    if not tool or not playerHumanoid then
        return false
    end
    if swimRoot and swimRoot:FindFirstChild("Swim") then
        State.TravelStatus = "In the water | rising above the surface before flying"
        if not Extras.leaveWater() then
            State.TravelStatus = "In the water (swim lock) | could not rise above the surface"
            return false
        end
        swimRoot, playerHumanoid = getRoot()
        if not swimRoot or not playerHumanoid then
            return false
        end
    end
    if tool.Parent ~= localPlayer.Character then
        pcall(function()
            playerHumanoid:EquipTool(tool)
        end)
        task.wait(0.8)
    end
    local activeTool = Combat.getActiveTool(tool)
    local flightKey = Extras.getFlightKey(activeTool)
    if activeTool then
        Extras.FlightKeyCache[tool.Name] = flightKey or false
    end
    if not activeTool or not flightKey or not Combat.installAimHook() then
        return false
    end

    local marker = Instance.new("Part")
    marker.Anchored = true
    marker.CanCollide = false
    marker.CanQuery = false
    marker.CanTouch = false
    marker.Transparency = 1
    marker.Size = Vector3.new(1, 1, 1)
    local cruiseHeight = math.max(targetPosition.Y, swimRoot.Position.Y, 40) + 50
    marker.Position = Vector3.new(targetPosition.X, cruiseHeight, targetPosition.Z)
    marker.Parent = workspaceService
    Combat.AimRoot = marker

    local deadline = os.clock() + (maxSeconds or 60)
    local lastPress = 0
    local arrived = false
    while os.clock() < deadline and isActive() do
        local rootPart = getRoot()
        if not rootPart then
            break
        end
        local flatDistance = Vector3.new(targetPosition.X - rootPart.Position.X, 0, targetPosition.Z - rootPart.Position.Z).Magnitude
        if flatDistance <= 40 then
            arrived = true
            break
        end
        Combat.AimUntil = os.clock() + 1
        local outsideDungeon = workspaceService:GetAttribute("Dungeon") == nil
        if outsideDungeon and (rootPart:FindFirstChild("Swim") or rootPart.Position.Y < 4) then
            State.TravelStatus = "Flight dipped into the water | rising and re-casting " .. flightKey
            Extras.leaveWater()
            lastPress = 0
            rootPart = getRoot()
            if not rootPart then
                break
            end
        end
        if rootPart:FindFirstChild("FlightVelocity") then
            removeFloat(rootPart)
        else
            getOrCreateFloat(rootPart)
            if os.clock() - lastPress > 0.8 then
                lastPress = os.clock()
                task.spawn(function()
                    pcall(activeTool.Move, flightKey)
                end)
            end
        end
        State.TravelStatus = string.format("Flying with %s %s (%d studs)", tool.Name, flightKey, math.floor(flatDistance))
        task.wait(0.1)
    end

    task.spawn(function()
        pcall(activeTool.Move, flightKey, "Ended")
    end)
    Combat.AimUntil = 0
    Combat.AimRoot = nil
    marker:Destroy()
    return arrived
end

function Extras.flyLongTrip(targetSource, checkCondition)
    local target = targetSource
    if type(targetSource) == "function" then
        target = targetSource()
    end
    local rootPart = getRoot()
    if not target or not rootPart then
        return false
    end
    local distance = (target.Position - rootPart.Position).Magnitude
    local recentlyPulledBack = os.clock() - (Extras.RevertWatch.LastRejectAt or -math.huge) < 20
    if distance < 600 and not (recentlyPulledBack and distance > 100) then
        return false
    end
    if Extras.PriorityRequest and movementOwner ~= Extras.PriorityRequest then
        return false
    end
    local targetIslandName = getNearestIslandName(target.Position)
    if distance > 400 and not Extras.IslandHopActive and workspaceService:GetAttribute("Dungeon") == nil and targetIslandName and getNearestIslandName(rootPart.Position) ~= targetIslandName and not Extras.isCarryingCoffin() then
        Extras.IslandHopActive = true
        local hopOk, hopArrived = pcall(teleportToIsland, targetIslandName, target.Position)
        Extras.IslandHopActive = false
        if hopOk and hopArrived then
            task.wait(0.4)
            rootPart = getRoot()
            if not rootPart then
                return false
            end
            distance = (target.Position - rootPart.Position).Magnitude
            if distance < 600 then
                return true
            end
        end
    end
    if not Extras.findFlightAbility() then
        return false
    end
    local isActive = function()
        if not isFarmActive() then
            return false
        end
        if checkCondition and checkCondition() == false then
            return false
        end
        return true
    end
    return Extras.abilityFlyTo(target.Position + Vector3.new(0, 10, 0), isActive, math.clamp(distance / 120 + 10, 15, 90))
end

function Extras.deliverCoffin(isActive)
    isActive = isActive or Extras.isAutoCoffinActive
    local strangerPosition = Extras.getNPCWorldPosition(Extras.StrangerName, Extras.StrangerPosition)
    local rootPart = getRoot()
    if not rootPart then
        return false
    end

    Extras.clearCombatLocks()
    if (rootPart.Position - strangerPosition).Magnitude > 150 then
        State.ExtraStatus = "Coffin: carrying to Mysterious Stranger (ability flight)"
        pcall(Extras.abilityFlyTo, strangerPosition + Vector3.new(0, 15, 0), isActive, 120)
    end
    State.ExtraStatus = "Coffin: carrying to Mysterious Stranger (walking the last stretch)"
    Extras.ForceWalk = true
    pcall(function()
        travelTo(CFrame.new(strangerPosition + Vector3.new(0, 3, 6)), isActive)
    end)
    Extras.ForceWalk = false
    local arrivedRoot = getRoot()
    if not arrivedRoot or (arrivedRoot.Position - strangerPosition).Magnitude > 40 then
        State.ExtraStatus = "Coffin: could not reach the Mysterious Stranger on foot yet"
        task.wait(1)
        return false
    end

    local strangerModel = npcsFolder:FindFirstChild(Extras.StrangerName)
    local streamDeadline = os.clock() + 5
    while strangerModel and not strangerModel:FindFirstChildWhichIsA("BasePart", true) and os.clock() < streamDeadline do
        task.wait(0.2)
    end
    if not strangerModel then
        State.ExtraStatus = "Coffin: Mysterious Stranger not found"
        return false
    end

    local pagesBefore = getInventoryAmount("Coffin Page")
    State.ExtraStatus = "Coffin: handing coffin to Mysterious Stranger"
    for _, descendant in ipairs(strangerModel:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") and descendant.Enabled and string.find(string.lower(descendant.ActionText), "deliver", 1, true) then
            triggerPrompt(descendant)
            task.wait(1.5)
            break
        end
    end
    if Extras.isCarryingCoffin() then
        talkToNPC(strangerModel, "coffin", function()
            return not Extras.isCarryingCoffin()
        end, 10)
    end
    task.wait(1)

    local gained = getInventoryAmount("Coffin Page") - pagesBefore
    if gained > 0 then
        Extras.CoffinDeliveryFails = 0
        State.ExtraStatus = "Coffin: delivered | +" .. tostring(gained) .. " Coffin Page"
        return true
    end
    if Extras.isCarryingCoffin() then
        Extras.CoffinDeliveryFails = (Extras.CoffinDeliveryFails or 0) + 1
        if Extras.CoffinDeliveryFails >= 2 then
            Extras.CoffinDeliveryFails = 0
            Extras.CoffinBlockedUntil = os.clock() + 600
            State.ExtraStatus = "Coffin: the Stranger refused twice | pausing coffins for 10 min | " .. tostring(State.LastNotifyText)
            return false
        end
    else
        Extras.CoffinDeliveryFails = 0
    end
    State.ExtraStatus = "Coffin: delivery done | " .. tostring(State.LastNotifyText)
    return not Extras.isCarryingCoffin()
end

function Extras.findCoffinModelPosition()
    for coffin in pairs(Extras.CoffinCandidates or {}) do
        if Extras.isCoffinCandidate(coffin) then
            local ok, position = pcall(function()
                return coffin:IsA("Model") and coffin:GetPivot().Position or coffin.Position
            end)
            if ok and position then
                return position
            end
        end
    end
    return nil
end

function Extras.isCoffinAvailable()
    if os.clock() < (Extras.CoffinBlockedUntil or 0) or workspaceService:GetAttribute("Dungeon") ~= nil then
        return false
    end
    if not Extras.CoffinCandidates then
        return Extras.isCarryingCoffin() or Extras.findItemIndicator("coffin") ~= nil
    end
    return Extras.isCarryingCoffin() or Extras.findCoffin() ~= nil or Extras.findItemIndicator("coffin") ~= nil or Extras.findCoffinModelPosition() ~= nil
end

function Extras.runCoffinStep(isActive)
    isActive = isActive or Extras.isAutoCoffinActive
    if workspaceService:GetAttribute("Dungeon") ~= nil then
        return false
    end
    Extras.connectItemIndicators()
    if not getgenv().HubCoffinConnection or not Extras.CoffinCandidates then
        Extras.watchCoffins()
    end

    if Extras.isCarryingCoffin() then
        Extras.forgetItemIndicator("coffin")
        return Extras.deliverCoffin(isActive)
    end

    local coffin, prompt = Extras.findCoffin()
    if not coffin then
        local indicator = Extras.findItemIndicator("coffin")
        local markerPosition = indicator and indicator.Position or Extras.findCoffinModelPosition()
        if not markerPosition then
            return false
        end
        indicator = { Position = markerPosition }
        State.ExtraStatus = "Coffin: a coffin surfaced | flying to it"
        Extras.clearCombatLocks()
        safeTravelTo(CFrame.new(indicator.Position + Vector3.new(0, 10, 0)), function()
            return isActive() and Extras.findCoffin() == nil
        end)
        local deadline = os.clock() + 6
        while isActive() and os.clock() < deadline do
            coffin, prompt = Extras.findCoffin()
            if coffin then
                break
            end
            task.wait(0.3)
        end
        if not coffin then
            local rootPart = getRoot()
            if rootPart and (rootPart.Position - indicator.Position).Magnitude < 60 then
                Extras.forgetItemIndicator("coffin")
            end
            State.ExtraStatus = "Coffin: no coffin at the marker"
            return false
        end
    end

    local coffinPosition = coffin:IsA("Model") and coffin:GetPivot().Position or coffin.Position
    State.ExtraStatus = "Coffin: found | flying to it"
    Extras.clearCombatLocks()
    safeTravelTo(CFrame.new(coffinPosition + Vector3.new(0, 8, 0)), function()
        return isActive() and coffin.Parent ~= nil
    end)

    State.ExtraStatus = "Coffin: picking up"
    triggerPrompt(prompt)
    local deadline = os.clock() + 3
    while os.clock() < deadline and not Extras.isCarryingCoffin() and coffin.Parent ~= nil do
        task.wait(0.1)
    end

    if Extras.isCarryingCoffin() or coffin.Parent == nil then
        Extras.forgetItemIndicator("coffin")
        return Extras.deliverCoffin(isActive)
    end
    State.ExtraStatus = "Coffin: pickup failed | " .. tostring(State.LastNotifyText)
    task.wait(2)
    return false
end

function Extras.runCoffinCycle()
    Extras.connectItemIndicators()
    if not Extras.isCoffinAvailable() then
        State.ExtraStatus = "Coffin: waiting for a coffin to surface"
        task.wait(2)
        return
    end

    if not acquireMovement("coffin") then
        State.ExtraStatus = "Coffin: waiting for " .. tostring(movementOwner) .. " to finish"
        task.wait(1)
        return
    end

    Extras.runCoffinStep(Extras.isAutoCoffinActive)
    releaseMovement("coffin")
end

Extras.Solemn = {
    FerrymanName = "Griefbound Ferryman",
    FerrymanPosition = Vector3.new(3431, 71, -2920),
    Quest1 = "Solemn Lament 1",
    GraveKeys = { "Bell", "Name", "Fear" },
    GraveIsland = "Grave Island",
    BossName = "Solemn Lament",
    ItemName = "Solemn Lament",
    TitleName = "The Butterfly's Lament",
    GunsShopItem = "Solemn Lament Guns",
    Guns = { "Solemn Gun", "Lament Gun" },
    GunParts = { "Solemn Parts", "Lament Parts" },
    GunPartsNeeded = 200,
    GunMoney = 50000000,
    FinalMoney = 100000000,
    ButterflyItem = "Soul Butterflies",
    ButterflyNeeded = 500,
    ButterflySummonCost = 50,
    ButterflyBosses = { "Chihora" },
    EternalPage = "Eternal Rest Page",
    CoffinPage = "Coffin Page",
    LamentPage = "Lament Page",
    MaxEscapes = 2,
    TicketBatch = 400,
    MoneyMob = nil,
    TicketMoneyFloor = 15000000,
    TicketMoneyTarget = 40000000,
    FallbackRequirement = {
        ["Soul Butterflies"] = 500,
        ["Lament Gun"] = 1,
        ["Lament Page"] = 10,
        ["Coffin Page"] = 1,
        ["Eternal Rest Page"] = 10,
        ["Solemn Gun"] = 1
    },
    TitleKills = 0
}

function Extras.isSolemnActive()
    return State.AutoSolemnEnabled
end

function Extras.solemnStatus(message)
    State.ExtraStatus = "Solemn Lament: " .. message
end

function Extras.getSolemnRequirement()
    local ferrymanDialogue = dialogueData[Extras.Solemn.FerrymanName]
    if typeof(ferrymanDialogue) == "table" and typeof(ferrymanDialogue.Requirement) == "table" then
        return ferrymanDialogue.Requirement
    end
    return Extras.Solemn.FallbackRequirement
end

function Extras.hasSolemnGuns()
    for _, gunName in ipairs(Extras.Solemn.Guns) do
        if getInventoryAmount(gunName) < 1 then
            return false
        end
    end
    return true
end

function Extras.getSolemnMissing()
    local solemn = Extras.Solemn
    local missing = {}
    for itemName, needed in pairs(Extras.getSolemnRequirement()) do
        local have = getInventoryAmount(itemName)
        if have < needed then
            missing[itemName] = needed - have
            table.insert(missing, string.format("%s %d/%d", itemName, have, needed))
        end
    end
    if not Extras.hasTitle(solemn.TitleName) then
        missing[solemn.TitleName] = 1
        table.insert(missing, "title " .. solemn.TitleName)
    end
    if getMoney() < solemn.FinalMoney then
        missing.Money = solemn.FinalMoney - getMoney()
        table.insert(missing, string.format("$%dM/%dM", math.floor(getMoney() / 1000000), math.floor(solemn.FinalMoney / 1000000)))
    end
    table.sort(missing)
    return missing
end

function Extras.getSolemnStage()
    local solemn = Extras.Solemn
    if getInventoryAmount(solemn.ItemName) > 0 then
        return "done"
    end
    if not UnlockFarm.isQuestCompleted(solemn.Quest1) then
        if UnlockFarm.isQuestReadyToClaim(solemn.Quest1) then
            return "claim"
        end
        if not UnlockFarm.getActiveQuestFolder(solemn.Quest1) then
            return "accept"
        end
        return "graves"
    end
    if not Extras.hasSolemnGuns() then
        for _, partName in ipairs(solemn.GunParts) do
            if getInventoryAmount(partName) < solemn.GunPartsNeeded then
                return "parts"
            end
        end
        if getMoney() < solemn.GunMoney then
            return "gunmoney"
        end
        return "guns"
    end
    if #Extras.getSolemnMissing() == 0 and not solemn.NeedOwnKill then
        return "final"
    end
    return "gather"
end

function Extras.planSolemnGather()
    local solemn = Extras.Solemn
    local missing = Extras.getSolemnMissing()
    local butterflies = getInventoryAmount(solemn.ButterflyItem)
    if missing[solemn.CoffinPage] and Extras.isCoffinAvailable() then
        return "coffin", missing
    end
    local butterflyBossAlive = false
    for _, bossName in ipairs(solemn.ButterflyBosses) do
        butterflyBossAlive = butterflyBossAlive or BossFarm.isBossAlive(bossName)
    end
    local nextEntry = BossFarm.getSummonEntry(butterflies >= solemn.ButterflySummonCost and solemn.BossName or solemn.ButterflyBosses[1])
    local outOfTickets = nextEntry == nil
    if nextEntry then
        for _, shortfall in ipairs(BossFarm.getSummonShortfall(nextEntry)) do
            outOfTickets = outOfTickets or shortfall.Item == "Boss Ticket"
        end
    end
    if not BossFarm.isBossAlive(solemn.BossName) and not butterflyBossAlive and (solemn.TicketMoneyActive or (getMoney() < solemn.TicketMoneyFloor and outOfTickets)) then
        solemn.TicketMoneyActive = getMoney() < solemn.TicketMoneyTarget
        if solemn.TicketMoneyActive then
            return "ticketmoney", missing
        end
    end
    local wantsKill = missing[solemn.TitleName] ~= nil or solemn.NeedOwnKill == true
    local summonBlocked = (solemn.Escapes or 0) >= solemn.MaxEscapes
    if wantsKill and BossFarm.isBossAlive(solemn.BossName) then
        return "summon", missing
    end
    if wantsKill and not summonBlocked then
        if butterflies >= solemn.ButterflySummonCost then
            return "summon", missing
        end
        return "butterflies", missing
    end
    if missing[solemn.ButterflyItem] then
        return "butterflies", missing
    end
    if missing[solemn.EternalPage] then
        return "deepshark", missing
    end
    if missing[solemn.LamentPage] then
        return "butterflies", missing
    end
    if missing.Money then
        return "money", missing
    end
    if missing[solemn.CoffinPage] then
        return "waitcoffin", missing
    end
    if wantsKill then
        return "blocked", missing
    end
    return "final", missing
end

function Extras.goToNPCAt(npcName, knownPosition, isActive, statusSetter)
    local position = Extras.getNPCWorldPosition(npcName, knownPosition)
    local rootPart = getRoot()
    if rootPart and position and (rootPart.Position - position).Magnitude > 150 then
        statusSetter("flying to the " .. npcName)
        safeTravelTo(CFrame.new(position + Vector3.new(0, 6, 0)), isActive)
    end
    local npc = npcsFolder:FindFirstChild(npcName) or npcsFolder:WaitForChild(npcName, 5)
    local deadline = os.clock() + 5
    while npc and not npc:FindFirstChildWhichIsA("BasePart", true) and os.clock() < deadline do
        task.wait(0.2)
    end
    if not npc or not npc:FindFirstChildWhichIsA("BasePart", true) then
        return nil
    end
    if not travelToNPC(npc, isActive) then
        return nil
    end
    return npcsFolder:FindFirstChild(npcName) or npc
end

function Extras.goToFerryman()
    local solemn = Extras.Solemn
    return Extras.goToNPCAt(solemn.FerrymanName, solemn.FerrymanPosition, Extras.isSolemnActive, Extras.solemnStatus)
end

function Extras.solemnFightCondition()
    local solemn = Extras.Solemn
    return function()
        if not State.AutoSolemnEnabled then
            return false
        end
        if getInventoryAmount(solemn.CoffinPage) < 1 and Extras.isCoffinAvailable() then
            return false
        end
        return true
    end
end

function Extras.readSolemnGraves()
    local solemn = Extras.Solemn
    local startProgress = Extras.getQuestProgress(solemn.Quest1)
    Extras.solemnStatus(string.format("reading the forgotten graves (%d/3)", startProgress))
    local rootPart = getRoot()
    if rootPart and (rootPart.Position - solemn.FerrymanPosition).Magnitude > 400 then
        safeTravelTo(CFrame.new(solemn.FerrymanPosition + Vector3.new(0, 8, 0)), Extras.isSolemnActive)
    end
    local islandsFolder = workspaceService:FindFirstChild("Islands")
    local islandList = islandsFolder and islandsFolder:FindFirstChild("Islands")
    local island = islandList and islandList:FindFirstChild(solemn.GraveIsland)
    if not island then
        Extras.solemnStatus("Grave Island not found")
        task.wait(2)
        return
    end

    for _, graveKey in ipairs(solemn.GraveKeys) do
        if not State.AutoSolemnEnabled or UnlockFarm.isQuestReadyToClaim(solemn.Quest1) or UnlockFarm.isQuestCompleted(solemn.Quest1) then
            return
        end
        local marker = "(" .. string.lower(graveKey) .. ")"
        local grave = nil
        for _, descendant in ipairs(island:GetDescendants()) do
            if (descendant:IsA("Model") or descendant:IsA("BasePart")) and string.find(string.lower(descendant.Name), marker, 1, true) then
                grave = descendant
                break
            end
        end
        if grave then
            local gravePosition = grave:IsA("Model") and grave:GetPivot().Position or grave.Position
            Extras.solemnStatus(string.format("reading the %s grave (%d/3)", graveKey, Extras.getQuestProgress(solemn.Quest1)))
            travelTo(CFrame.new(gravePosition + Vector3.new(0, 4, 6), gravePosition), Extras.isSolemnActive)
            local prompt = nil
            local deadline = os.clock() + 4
            while not prompt and os.clock() < deadline do
                prompt = grave:FindFirstChildWhichIsA("ProximityPrompt", true)
                if not prompt then
                    for _, descendant in ipairs(island:GetDescendants()) do
                        if descendant:IsA("ProximityPrompt") and descendant.Enabled and descendant.Parent and descendant.Parent:IsA("BasePart") and (descendant.Parent.Position - gravePosition).Magnitude < 15 then
                            prompt = descendant
                            break
                        end
                    end
                end
                if not prompt then
                    task.wait(0.3)
                end
            end
            if prompt then
                settleCharacter()
                triggerPrompt(prompt)
                task.wait(1.5)
            end
        end
    end

    if Extras.getQuestProgress(solemn.Quest1) <= startProgress and not UnlockFarm.isQuestReadyToClaim(solemn.Quest1) then
        Extras.solemnStatus("graves did not respond | " .. tostring(State.LastNotifyText))
        task.wait(3)
    end
end

function Extras.pickButterflyBoss()
    for _, bossName in ipairs(Extras.Solemn.ButterflyBosses) do
        local catalogItem = BossFarm.getSummonEntry(bossName)
        if catalogItem and #BossFarm.getSummonShortfall(catalogItem) == 0 then
            return catalogItem
        end
    end
    return BossFarm.getSummonEntry(Extras.Solemn.ButterflyBosses[1])
end

function Extras.farmSolemnGrind(isStillNeeded, label)
    local grindMob = UnlockFarm.getGrindMobName()
    if not grindMob then
        Extras.solemnStatus(label .. " | no grind mob for your level")
        task.wait(2)
        return
    end
    Extras.solemnStatus(label .. " | farming " .. grindMob)
    farmMobWithAnchor(grindMob, function()
        return Extras.solemnFightCondition()() and isStillNeeded()
    end, false)
end

function Extras.ensureMobQuest(mobName, isActive, statusSetter)
    local questName = questAnchorByMob[normalizeName(stripBossTag(mobName))]
    if not questName or FarmLevel.getActiveQuest(questName) then
        return questName
    end
    local targetNPC = getQuestNPC(questName)
    if not targetNPC then
        return questName
    end
    statusSetter("accepting " .. questName .. " for " .. mobName)
    local reached = travelToNPC(targetNPC, function()
        return isActive() and FarmLevel.getActiveQuest(questName) == nil
    end)
    if reached then
        invokeInput("Quest", "Accept", targetNPC, questName)
        task.wait(0.4)
        if FarmLevel.getActiveQuest(questName) == nil then
            talkToNPC(targetNPC, "Accept", function()
                return FarmLevel.getActiveQuest(questName) ~= nil
            end, 6)
        end
    end
    lockedTargetCFrame = nil
    return questName
end

function Extras.farmSolemnMoney(isStillNeeded, label)
    local moneyMob = Extras.Solemn.MoneyMob
    if moneyMob then
        local isActive = function()
            return Extras.solemnFightCondition()() and isStillNeeded()
        end
        local questName = Extras.ensureMobQuest(moneyMob, isActive, Extras.solemnStatus)
        local questFolder = questName and FarmLevel.getActiveQuest(questName)
        local progressValue = questFolder and questFolder:FindFirstChild("Progress")
        Extras.solemnStatus(string.format("%s | farming %s | quest %s %s", label, moneyMob, tostring(questName), progressValue and tostring(progressValue.Value) or "-"))
        farmMobWithAnchor(moneyMob, isActive, false)
        return
    end
    local rank = Extras.getFireForceRank()
    if rank == "" or rank == "None" then
        Extras.farmSolemnGrind(isStillNeeded, label)
        return
    end
    local isActive = function()
        return Extras.solemnFightCondition()() and isStillNeeded()
    end
    if not Extras.runAmbushDuty(isActive, "Solemn Lament: " .. label .. " | Ambush") then
        Extras.solemnStatus(label .. " | Ambush: waiting for the next ambush")
        task.wait(0.5)
    end
end

function Extras.buySolemnGuns()
    local solemn = Extras.Solemn
    local stranger = Extras.goToNPCAt(Extras.StrangerName, Extras.StrangerPosition, Extras.isSolemnActive, Extras.solemnStatus)
    if not stranger then
        Extras.solemnStatus("cannot reach the Mysterious Stranger")
        task.wait(1)
        return
    end
    Extras.solemnStatus("assembling the Solemn Gun and Lament Gun ($50M)")
    invokeInput("Shop", stranger, solemn.GunsShopItem)
    task.wait(1.5)
    if not Extras.hasSolemnGuns() then
        Extras.solemnStatus("gun assembly refused | " .. tostring(State.LastNotifyText))
        task.wait(2)
    end
end

function Extras.claimSolemnLament()
    local solemn = Extras.Solemn
    local ferryman = Extras.goToFerryman()
    if not ferryman then
        Extras.solemnStatus("cannot reach the Griefbound Ferryman")
        task.wait(1)
        return
    end
    Extras.solemnStatus("exchanging everything for Solemn Lament")
    local sentAt = os.clock()
    invokeInput("Shop", ferryman, solemn.ItemName)
    task.wait(1.5)
    if getInventoryAmount(solemn.ItemName) > 0 then
        Extras.solemnStatus("Solemn Lament obtained")
        return
    end
    local reply = string.lower(tostring(State.LastNotifyText))
    if (State.LastNotifyTime or 0) >= sentAt and (string.find(reply, "not overcome", 1, true) or string.find(reply, "defeat solemn", 1, true)) then
        solemn.NeedOwnKill = true
        Extras.solemnStatus("the Ferryman wants a Solemn Lament you summoned yourself | summoning one")
    else
        Extras.solemnStatus("exchange refused | " .. tostring(State.LastNotifyText))
    end
    task.wait(2)
end

function Extras.runSolemnGather(plan, missing)
    local solemn = Extras.Solemn
    local missingText = "missing: " .. table.concat(missing, ", ")
    local fightCondition = Extras.solemnFightCondition()
    if solemn.TrackedBoss then
        Extras.trackBossKills(solemn, solemn.BossName)
    end

    if plan == "coffin" then
        Extras.runCoffinStep(Extras.isSolemnActive)
    elseif plan == "summon" then
        Extras.ensureSpawnNear(solemn.FerrymanPosition, Extras.isSolemnActive, Extras.solemnStatus)
        Extras.trackBossKills(solemn, solemn.BossName)
        Extras.solemnStatus(string.format("%s for the title (pity %s/80, kills this session %d) | butterflies %d | %s", solemn.BossName, tostring(localPlayer:GetAttribute("TitlePity_Solemn_Lament") or "?"), solemn.TitleKills, getInventoryAmount(solemn.ButterflyItem), missingText))
        local killsBefore = solemn.TitleKills
        BossFarm.prepareAndKill(BossFarm.getSummonEntry(solemn.BossName), fightCondition, "solemn")
        Extras.trackBossKills(solemn, solemn.BossName)
        if solemn.TitleKills > killsBefore then
            solemn.NeedOwnKill = false
        end
    elseif plan == "butterflies" then
        local catalogItem = Extras.pickButterflyBoss()
        Extras.solemnStatus(string.format("farming %s for Soul Butterflies %d/%d | title pity %s/80 | %s", catalogItem and catalogItem.Name or "?", getInventoryAmount(solemn.ButterflyItem), missing[solemn.TitleName] and solemn.ButterflySummonCost or solemn.ButterflyNeeded, tostring(localPlayer:GetAttribute("TitlePity_Solemn_Lament") or "?"), missingText))
        BossFarm.prepareAndKill(catalogItem, fightCondition, "solemn")
    elseif plan == "ticketmoney" then
        Extras.farmSolemnMoney(function()
            return getMoney() < solemn.TicketMoneyTarget
        end, string.format("money for Boss Tickets $%dM/%dM", math.floor(getMoney() / 1000000), math.floor(solemn.TicketMoneyTarget / 1000000)))
    elseif plan == "money" then
        Extras.farmSolemnMoney(function()
            return getMoney() < solemn.FinalMoney
        end, string.format("money $%dM/%dM", math.floor(getMoney() / 1000000), math.floor(solemn.FinalMoney / 1000000)))
    elseif plan == "waitcoffin" then
        Extras.solemnStatus("everything else is ready | waiting for a coffin to surface (10% every 5 minutes)")
        task.wait(2)
    elseif plan == "blocked" then
        Extras.solemnStatus(string.format("Solemn Lament escaped %d summons in a row (too strong solo) | everything else is gathered, the title needs a party or more damage | toggle off and on to retry", solemn.Escapes or 0))
        task.wait(3)
    elseif plan == "final" then
        Extras.claimSolemnLament()
    end
end

function Extras.stopSolemn()
    Extras.requestDeepshark("solemn", false)
    Extras.stopLoop("AutoSolemnEnabled", "solemn")
    Extras.syncToggle("SolemnToggle", false)
end

function Extras.runSolemnCycle()
    Extras.connectItemIndicators()
    local solemn = Extras.Solemn
    local stage = Extras.getSolemnStage()

    if stage == "done" then
        Extras.solemnStatus("obtained | stopped")
        Extras.stopSolemn()
        return
    end

    local plan, missing = nil, nil
    if stage == "gather" then
        plan, missing = Extras.planSolemnGather()
    end
    if plan == "deepshark" then
        if not State.AutoDeepsharkEnabled then
            Extras.solemnStatus("need " .. solemn.EternalPage .. " | starting Auto Ancient Deepshark")
        end
        Extras.requestDeepshark("solemn", true)
        task.wait(2)
        return
    end
    Extras.requestDeepshark("solemn", false)

    if not acquireMovement("solemn") then
        Extras.solemnStatus("waiting for " .. tostring(movementOwner) .. " to finish")
        task.wait(1)
        return
    end

    if (stage == "gather" or stage == "parts" or stage == "gunmoney") and plan ~= "coffin" and Extras.recoverHealth(Extras.isSolemnActive, "Solemn Lament") then
        releaseMovement("solemn")
        return
    end

    if stage == "accept" then
        Extras.solemnStatus("accepting " .. solemn.Quest1)
        if Extras.goToFerryman() then
            UnlockFarm.acceptQuest(solemn.Quest1)
            if not UnlockFarm.getActiveQuestFolder(solemn.Quest1) then
                local ferryman = npcsFolder:FindFirstChild(solemn.FerrymanName)
                if ferryman and Extras.openArayaDialogue(ferryman) then
                    Extras.pickArayaChoice("i will listen to the forgotten", function()
                        return UnlockFarm.getActiveQuestFolder(solemn.Quest1) ~= nil
                    end)
                end
            end
        else
            Extras.solemnStatus("cannot reach the Griefbound Ferryman")
            task.wait(1)
        end
    elseif stage == "claim" then
        if Extras.goToFerryman() then
            UnlockFarm.claimQuest(solemn.Quest1)
        end
    elseif stage == "graves" then
        Extras.readSolemnGraves()
    elseif stage == "parts" then
        Extras.farmSolemnGrind(function()
            return getInventoryAmount(solemn.GunParts[1]) < solemn.GunPartsNeeded or getInventoryAmount(solemn.GunParts[2]) < solemn.GunPartsNeeded
        end, string.format("gun parts %d/%d + %d/%d", getInventoryAmount(solemn.GunParts[1]), solemn.GunPartsNeeded, getInventoryAmount(solemn.GunParts[2]), solemn.GunPartsNeeded))
    elseif stage == "gunmoney" then
        Extras.farmSolemnMoney(function()
            return getMoney() < solemn.GunMoney
        end, string.format("money for the guns $%dM/50M", math.floor(getMoney() / 1000000)))
    elseif stage == "guns" then
        Extras.buySolemnGuns()
    elseif stage == "final" then
        Extras.claimSolemnLament()
    elseif stage == "gather" then
        Extras.runSolemnGather(plan, missing)
    end

    lockedTargetCFrame = nil
    releaseMovement("solemn")
end

Extras.DutyBlockedUntil = {}
Extras.DutyOrder = { "AH", "HR", "CH" }

function Extras.getFireForceRank()
    local dataFolder = localPlayer:FindFirstChild("Data")
    local rankValue = dataFolder and dataFolder:FindFirstChild("FireForceRank")
    return rankValue and tostring(rankValue.Value) or "None"
end

function Extras.findOwnAmbusher()
    local rootPart = getRoot()
    if not rootPart then
        return nil
    end
    local best, bestDistance = nil, math.huge
    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        if enemy.Name == "Infernal Ambusher" then
            local ownerId = enemy:GetAttribute("OwnerUserId")
            local humanoid = enemy:FindFirstChildOfClass("Humanoid")
            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
            if (ownerId == nil or ownerId == localPlayer.UserId) and humanoid and humanoid.Health > 0 and enemyRoot then
                local distance = (enemyRoot.Position - rootPart.Position).Magnitude
                if distance < bestDistance then
                    best, bestDistance = enemy, distance
                end
            end
        end
    end
    return best
end

function Extras.isAmbushOnCooldown()
    return os.clock() < (Extras.NextAmbushAt or 0) and Extras.findFireForceZone() == nil
end

function Extras.pickNextDuty()
    local bestCode = nil
    local bestScore = math.huge
    for _, code in ipairs(Extras.DutyOrder) do
        local blocked = os.clock() < (Extras.DutyBlockedUntil[code] or 0) or (code == "AH" and Extras.isAmbushOnCooldown())
        if not blocked and not Extras.isDutyDone(code) then
            local tier, progress, amount = Extras.getDutyState(code)
            local score = tier + math.clamp(progress / math.max(amount, 1), 0, 0.99)
            if score < bestScore then
                bestScore = score
                bestCode = code
            end
        end
    end
    return bestCode
end

function Extras.runAmbushDuty(isActive, statusPrefix)
    isActive = isActive or function()
        return State.AutoAmbushEnabled
    end
    statusPrefix = statusPrefix or "Fire Company Ambush"
    local ambusherName = "Infernal Ambusher"
    local progressText = Extras.describeProgress("AH")
    if Extras.findOwnAmbusher() then
        State.ExtraStatus = statusPrefix .. ": fighting " .. ambusherName .. " " .. progressText
        engageMob(ambusherName, isActive, true)
        return true
    end

    if Extras.triggerFireForceZone(statusPrefix .. " " .. progressText .. ": ", isActive) then
        return true
    end

    if os.clock() < (Extras.NextAmbushAt or 0) then
        return false
    end

    local sentAt = os.clock()
    State.ExtraStatus = statusPrefix .. ": requesting a new ambush " .. progressText
    local accepted = invokeInput("FireForce", "Ambush")
    if accepted == true then
        Extras.NextAmbushAt = os.clock() + 1
        local deadline = os.clock() + 3
        while os.clock() < deadline and Extras.findFireForceZone() == nil do
            task.wait(0.1)
        end
        return true
    end

    task.wait(0.3)
    local notifyText = (State.LastNotifyTime or 0) >= sentAt and string.lower(tostring(State.LastNotifyText)) or ""
    local waitSeconds = tonumber(string.match(notifyText, "(%d+)%s*s"))
    Extras.NextAmbushAt = os.clock() + math.clamp(waitSeconds or 5, 3, 900)
    State.ExtraStatus = statusPrefix .. ": not available | " .. tostring(State.LastNotifyText)
    return false
end

function Extras.runAmbushOnlyCycle()
    local rank = Extras.getFireForceRank()
    if rank == "" or rank == "None" then
        State.ExtraStatus = "Ambush: join the Fire Force first (Captain Burns trial)"
        task.wait(3)
        return
    end

    if not acquireMovement("ambushonly") then
        State.ExtraStatus = "Ambush: waiting for " .. tostring(movementOwner) .. " to finish"
        task.wait(1)
        return
    end

    if not Extras.runAmbushDuty(function()
        return State.AutoAmbushOnlyEnabled
    end, "Ambush") then
        State.ExtraStatus = "Ambush: waiting for the next ambush | " .. tostring(State.LastNotifyText)
        task.wait(0.5)
    end

    lockedTargetCFrame = nil
    releaseMovement("ambushonly")
end

function Extras.runAmbushCycle()
    local rank = Extras.getFireForceRank()
    if rank == "" or rank == "None" then
        State.ExtraStatus = "Fire Company: join the Fire Force first (Captain Burns trial)"
        task.wait(3)
        return
    end

    if not acquireMovement("ambush") then
        State.ExtraStatus = "Fire Company: waiting for " .. tostring(movementOwner) .. " to finish"
        task.wait(1)
        return
    end

    Extras.claimReadyDuties()

    local handled = false
    if Extras.isCarryingHostage() or Extras.ActiveHostage then
        handled = Extras.runHostageStep("HR")
    end

    if not handled then
        local rootPart = getRoot()
        if rootPart and getTargetEnemy("Infernal Ambusher", rootPart.Position, true) then
            handled = Extras.runAmbushDuty()
        end
    end

    if not handled then
        local duty = Extras.pickNextDuty()
        if duty == "AH" then
            handled = Extras.runAmbushDuty()
        elseif duty == "HR" then
            handled = Extras.runHostageStep("HR")
        elseif duty == "CH" then
            handled = Extras.runCatStep("CH")
        else
            local allDone = true
            for _, code in ipairs(Extras.DutyOrder) do
                if not Extras.isDutyDone(code) then
                    allDone = false
                end
            end
            if allDone then
                handled = Extras.runAmbushDuty()
                if not handled then
                    State.ExtraStatus = "Fire Company: all duties at max tier | waiting for ambush"
                end
            else
                State.ExtraStatus = "Fire Company: waiting for an ambush, hostage or cat to be ready"
            end
            task.wait(1)
        end
        if duty and not handled then
            Extras.DutyBlockedUntil[duty] = os.clock() + (duty == "AH" and 2 or 15)
        end
    end

    lockedTargetCFrame = nil
    releaseMovement("ambush")
end

Extras.FireForceQuests = { "Mission Fire Force 1", "Mission Fire Force 2", "Mission Fire Force 3" }
Extras.FireForceGoals = { 3, 5, 3 }
Extras.HostageSkipUntil = {}

function Extras.isFireForceTrialActive()
    return State.AutoFireForceTrialEnabled
end

function Extras.getFireForceFolder()
    return extraFolder:FindFirstChild("FireForceQuest")
end

Extras.BurnsPosition = Vector3.new(-516.5, 21.3, 5167)
Extras.DutyNames = { AH = "Ambush", HR = "Hostage", CH = "Cat" }

function Extras.isFireForceLoopActive()
    return State.AutoFireForceTrialEnabled or State.AutoAmbushEnabled
end

function Extras.getDutyObjectives()
    if Extras.DutyObjectives then
        return Extras.DutyObjectives
    end
    local okData, dutyData = pcall(require, configurationsFolder:FindFirstChild("FireForceQuestData"))
    if not okData or typeof(dutyData) ~= "table" or typeof(dutyData.Objectives) ~= "table" then
        return {}
    end
    Extras.DutyObjectives = {}
    for _, objective in ipairs(dutyData.Objectives) do
        if objective.Code then
            Extras.DutyObjectives[objective.Code] = objective
        end
    end
    return Extras.DutyObjectives
end

function Extras.getDutyState(code)
    local objective = Extras.getDutyObjectives()[code]
    local dataFolder = localPlayer:FindFirstChild("Data")
    local stateValue = dataFolder and dataFolder:FindFirstChild("FireForceQuestState")
    local decoded = {}
    if stateValue then
        pcall(function()
            decoded = httpService:JSONDecode(stateValue.Value)
        end)
    end
    local entry = typeof(decoded) == "table" and decoded[code] or nil
    local tier = typeof(entry) == "table" and (tonumber(entry[1]) or 1) or 1
    local progress = typeof(entry) == "table" and (tonumber(entry[2]) or 0) or 0
    local tiers = objective and objective.Tiers or {}
    tier = math.clamp(math.floor(tier), 1, math.max(#tiers, 1))
    local amount = tiers[tier] and tonumber(tiers[tier].Amount) or 1
    return tier, progress, amount, #tiers, objective and objective.Key
end

function Extras.isDutyDone(code)
    local tier, progress, amount, tierCount = Extras.getDutyState(code)
    return tier >= tierCount and progress >= amount
end

Extras.DutyClaimAt = {}

function Extras.claimReadyDuties()
    for code in pairs(Extras.getDutyObjectives()) do
        local _, progress, amount, _, key = Extras.getDutyState(code)
        if key and progress >= amount and os.clock() >= (Extras.DutyClaimAt[code] or 0) then
            Extras.DutyClaimAt[code] = os.clock() + 20
            invokeInput("FireForce", "Claim", key)
        end
    end
end

function Extras.describeProgress(questName, trialGoal)
    if Extras.DutyNames[questName] then
        local tier, progress, amount = Extras.getDutyState(questName)
        return string.format("(tier %d %d/%d)", tier, progress, amount)
    end
    return string.format("(%d/%d)", Extras.getQuestProgress(questName), trialGoal)
end

function Extras.statusPrefix(questName, trialLabel)
    if Extras.DutyNames[questName] then
        return "Fire Company " .. Extras.DutyNames[questName]
    end
    return trialLabel
end

function Extras.getQuestProgress(questName)
    if Extras.DutyNames[questName] then
        local tier, progress = Extras.getDutyState(questName)
        return tier * 100000 + progress
    end
    local questFolder = UnlockFarm.getActiveQuestFolder(questName)
    local progressValue = questFolder and questFolder:FindFirstChild("Progress")
    return progressValue and progressValue.Value or 0
end

function Extras.goToCaptainBurns()
    local captain = npcsFolder:FindFirstChild("Captain Burns")
    if not captain then
        State.ExtraStatus = "Fire Force: Captain Burns not found"
        return nil
    end
    if not travelToNPC(captain, Extras.isFireForceTrialActive) then
        lockedTargetCFrame = nil
        State.ExtraStatus = "Fire Force: cannot reach Captain Burns"
        return nil
    end
    return npcsFolder:FindFirstChild("Captain Burns") or captain
end

function Extras.acceptFireForceQuest(questName)
    local captain = Extras.goToCaptainBurns()
    if not captain then
        return false
    end

    State.ExtraStatus = "Fire Force: accepting " .. questName
    invokeInput("Quest", "Accept", captain, questName)
    task.wait(0.8)

    if not UnlockFarm.getActiveQuestFolder(questName) then
        talkToNPC(captain, "Join the Fire Force", function()
            return UnlockFarm.getActiveQuestFolder(questName) ~= nil
        end, 8)
    end

    lockedTargetCFrame = nil
    return UnlockFarm.getActiveQuestFolder(questName) ~= nil
end

function Extras.claimFireForceQuest(questName)
    local captain = Extras.goToCaptainBurns()
    if not captain then
        return false
    end

    State.ExtraStatus = "Fire Force: claiming " .. questName
    invokeInput("Quest", "Claim", questName)
    task.wait(0.8)

    if not UnlockFarm.isQuestCompleted(questName) then
        talkToNPC(captain, nil, function()
            return UnlockFarm.isQuestCompleted(questName)
        end, 8)
    end

    lockedTargetCFrame = nil
    return UnlockFarm.isQuestCompleted(questName)
end

function Extras.pressFireForcePrompt(model, questName)
    local rootPart = getRoot()
    if not rootPart or not model.Parent then
        return false
    end

    if (model:GetPivot().Position - rootPart.Position).Magnitude > 8 then
        lockedEnemyRoot = nil
        lockedTargetCFrame = nil
        setTargetBox(nil)
        safeTravelTo(CFrame.new(model:GetPivot().Position + Vector3.new(0, 3, 3)), function()
            return Extras.isFireForceLoopActive() and model.Parent ~= nil
        end)
        task.wait(0.4)
    end

    local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
    if not prompt or not prompt.Enabled then
        return false
    end

    rootPart = getRoot()
    local modelPosition = model:GetPivot().Position
    if rootPart and (modelPosition - rootPart.Position).Magnitude > math.max((prompt.MaxActivationDistance or 10) - 2, 4) then
        travelTo(CFrame.new(modelPosition + Vector3.new(0, 3, 3)), function()
            return Extras.isFireForceLoopActive() and model.Parent ~= nil
        end)
        task.wait(0.2)
    end

    local progressBefore = Extras.getQuestProgress(questName)
    triggerPrompt(prompt)

    local deadline = os.clock() + 3
    while os.clock() < deadline and Extras.getQuestProgress(questName) <= progressBefore and not UnlockFarm.isQuestReadyToClaim(questName) and not Extras.isCarryingHostage() do
        task.wait(0.1)
    end

    return Extras.getQuestProgress(questName) > progressBefore or UnlockFarm.isQuestReadyToClaim(questName)
end

function Extras.runCatStep(questName)
    local prefix = Extras.statusPrefix(questName, "Fire Force 1/3")
    local folder = Extras.getFireForceFolder()
    local cat = folder and folder:FindFirstChild("Lost Cat")
    if not cat then
        State.ExtraStatus = prefix .. ": waiting for the Lost Cat"
        task.wait(1)
        return false
    end

    State.ExtraStatus = prefix .. ": catching Lost Cat " .. Extras.describeProgress(questName, Extras.FireForceGoals[1])
    if not Extras.pressFireForcePrompt(cat, questName) then
        State.ExtraStatus = prefix .. ": cat got away | " .. tostring(State.LastNotifyText)
        task.wait(0.5)
        return false
    end
    return true
end

function Extras.getNearbyEnemy(position, radius)
    local bestEnemy = nil
    local bestDistance = radius
    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        local alive, enemyRoot = isLivingEnemy(enemy)
        if alive then
            local distance = (enemyRoot.Position - position).Magnitude
            if distance <= bestDistance then
                bestDistance = distance
                bestEnemy = enemy
            end
        end
    end
    return bestEnemy
end

function Extras.runActiveHostage(questName)
    local hostage = Extras.ActiveHostage
    if not hostage or not hostage.Parent or os.clock() - (Extras.ActiveHostageAt or 0) > 120 then
        Extras.ActiveHostage = nil
        return false
    end

    local prefix = Extras.statusPrefix(questName, "Fire Force 2/3")
    local progressText = Extras.describeProgress(questName, Extras.FireForceGoals[2])
    if Extras.getQuestProgress(questName) > (Extras.ActiveHostageProgress or 0) or UnlockFarm.isQuestReadyToClaim(questName) then
        Extras.ActiveHostage = nil
        return false
    end

    local hostagePosition = hostage:GetPivot().Position
    local enemy = Extras.getNearbyEnemy(hostagePosition, 80)
    if enemy then
        Extras.HostageClearedAt = nil
        State.ExtraStatus = prefix .. ": clearing ambush at hostage " .. progressText
        farmMobWithAnchor(enemy.Name, function()
            return Extras.isFireForceLoopActive() and enemy.Parent ~= nil
        end, true)
        return true
    end

    Extras.HostageClearedAt = Extras.HostageClearedAt or os.clock()
    local prompt = hostage:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.Enabled then
        State.ExtraStatus = prefix .. ": freeing hostage " .. progressText
        Extras.pressFireForcePrompt(hostage, questName)
        if Extras.isCarryingHostage() then
            Extras.ActiveHostage = nil
            Extras.HostageClearedAt = nil
            return true
        end
    else
        State.ExtraStatus = prefix .. ": ambush cleared, waiting for hostage " .. progressText
        task.wait(0.5)
    end

    if os.clock() - Extras.HostageClearedAt > 15 then
        Extras.ActiveHostage = nil
        Extras.HostageClearedAt = nil
    end
    return true
end

function Extras.isCarryingHostage()
    local character = localPlayer.Character
    return localPlayer:GetAttribute("CarryingHostage") == true or (character ~= nil and character:GetAttribute("CarryingHostage") == true)
end

function Extras.deliverHostageToBurns(questName)
    local prefix = Extras.statusPrefix(questName, "Fire Force 2/3")
    local rootPart = getRoot()
    if not rootPart then
        task.wait(1)
        return false
    end

    local captain = npcsFolder:FindFirstChild("Captain Burns")
    local captainPosition = captain and (getNPCAnchorPosition(captain) or captain:GetPivot().Position) or Extras.BurnsPosition
    local progressBefore = Extras.getQuestProgress(questName)
    local function stillCarrying()
        return Extras.isFireForceLoopActive() and Extras.isCarryingHostage()
    end

    State.ExtraStatus = prefix .. ": carrying hostage to Captain Burns via teleporter " .. Extras.describeProgress(questName, Extras.FireForceGoals[2])
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    Combat.LockedMobName = nil
    setTargetBox(nil)

    if getNearestIslandName(rootPart.Position) ~= "7th Company Island" then
        teleportToIsland("7th Company Island", captainPosition)
        task.wait(0.4)
    end
    if not stillCarrying() then
        State.ExtraStatus = prefix .. ": hostage dropped on the way | " .. tostring(State.LastNotifyText)
        return false
    end

    captain = npcsFolder:FindFirstChild("Captain Burns") or npcsFolder:WaitForChild("Captain Burns", 3)
    if captain then
        captainPosition = getNPCAnchorPosition(captain) or captain:GetPivot().Position
    end
    safeTravelTo(CFrame.new(captainPosition + Vector3.new(0, 3, 6)), stillCarrying)

    local captainModel = npcsFolder:FindFirstChild("Captain Burns") or captain
    if not captainModel then
        State.ExtraStatus = prefix .. ": Captain Burns not streamed in"
        task.wait(1)
        return false
    end
    local deliverPrompt = captainModel:FindFirstChild("FireForceDeliverPrompt", true)
    for _ = 1, 3 do
        if not Extras.isCarryingHostage() or Extras.getQuestProgress(questName) > progressBefore then
            break
        end
        if deliverPrompt and deliverPrompt.Enabled then
            State.ExtraStatus = prefix .. ": delivering hostage"
            triggerPrompt(deliverPrompt)
        end
        local deadline = os.clock() + 2
        while os.clock() < deadline and Extras.getQuestProgress(questName) <= progressBefore and Extras.isCarryingHostage() do
            task.wait(0.1)
        end
        deliverPrompt = captainModel:FindFirstChild("FireForceDeliverPrompt", true)
    end

    local delivered = Extras.getQuestProgress(questName) > progressBefore or UnlockFarm.isQuestReadyToClaim(questName)
    if not delivered and not Extras.isCarryingHostage() then
        State.ExtraStatus = prefix .. ": hostage dropped | " .. tostring(State.LastNotifyText)
    end
    return delivered
end

function Extras.runHostageStep(questName)
    local prefix = Extras.statusPrefix(questName, "Fire Force 2/3")
    local folder = Extras.getFireForceFolder()
    local rootPart = getRoot()
    if not folder or not rootPart then
        task.wait(1)
        return false
    end

    if Extras.isCarryingHostage() then
        Extras.deliverHostageToBurns(questName)
        Extras.ActiveHostage = nil
        Extras.HostageClearedAt = nil
        return true
    end

    if Extras.runActiveHostage(questName) then
        return true
    end

    local hostages = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") and child.Name == "Fire Force Hostage" and os.clock() >= (Extras.HostageSkipUntil[child] or 0) then
            table.insert(hostages, child)
        end
    end

    if #hostages == 0 then
        State.ExtraStatus = prefix .. ": waiting for a hostage"
        task.wait(1)
        return false
    end

    local origin = rootPart.Position
    table.sort(hostages, function(first, second)
        local firstPrompt = first:FindFirstChildWhichIsA("ProximityPrompt", true)
        local secondPrompt = second:FindFirstChildWhichIsA("ProximityPrompt", true)
        local firstReady = firstPrompt ~= nil and firstPrompt.Enabled
        local secondReady = secondPrompt ~= nil and secondPrompt.Enabled
        if firstReady ~= secondReady then
            return firstReady
        end
        return (first:GetPivot().Position - origin).Magnitude < (second:GetPivot().Position - origin).Magnitude
    end)

    local target = hostages[1]
    local progressBefore = Extras.getQuestProgress(questName)
    State.ExtraStatus = prefix .. ": rescuing hostage " .. Extras.describeProgress(questName, Extras.FireForceGoals[2])
    if Extras.pressFireForcePrompt(target, questName) or Extras.isCarryingHostage() then
        return true
    end

    if Extras.getNearbyEnemy(target:GetPivot().Position, 80) then
        Extras.ActiveHostage = target
        Extras.ActiveHostageAt = os.clock()
        Extras.ActiveHostageProgress = progressBefore
        Extras.HostageClearedAt = nil
        return true
    end

    Extras.HostageSkipUntil[target] = os.clock() + 10
    State.ExtraStatus = prefix .. ": hostage not rescued | " .. tostring(State.LastNotifyText)
    task.wait(0.3)
    return false
end

function Extras.findFireForceZone()
    for _, child in ipairs(workspaceService:GetChildren()) do
        if child.Name == "FireForceZone" and child:IsA("Model") then
            local ownerId = child:GetAttribute("OwnerUserId")
            if ownerId == nil or ownerId == localPlayer.UserId then
                return child
            end
        end
    end
    return nil
end

function Extras.getFireForceZonePrompt(zone)
    local prompt = zone:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and prompt.Enabled and prompt.Parent and prompt.Parent:IsA("BasePart") then
        return prompt
    end
    return nil
end

Extras.AmbushIslands = { "A-City", "Ruin City", "7th Company Island" }

function Extras.getFireForceZoneRoot(zone)
    local root = zone:FindFirstChild("Root")
    if root and root:IsA("BasePart") then
        return root
    end
    return zone:FindFirstChildWhichIsA("BasePart", true)
end

Extras.KnownZonePositions = { Vector3.new(1322, 11, 2302) }
Extras.ZonePath = "LEGACY PIECE/ambush_zones.json"
pcall(function()
    local decoded = httpService:JSONDecode(readfile(Extras.ZonePath))
    for _, point in ipairs(decoded) do
        if tonumber(point.X) and tonumber(point.Y) and tonumber(point.Z) then
            local position = Vector3.new(point.X, point.Y, point.Z)
            local known = false
            for _, existing in ipairs(Extras.KnownZonePositions) do
                known = known or (existing - position).Magnitude < 60
            end
            if not known then
                table.insert(Extras.KnownZonePositions, position)
            end
        end
    end
end)

function Extras.rememberZonePosition(position)
    for _, known in ipairs(Extras.KnownZonePositions) do
        if (known - position).Magnitude < 60 then
            return
        end
    end
    table.insert(Extras.KnownZonePositions, 1, position)
    local encoded = {}
    for _, known in ipairs(Extras.KnownZonePositions) do
        table.insert(encoded, { X = math.floor(known.X), Y = math.floor(known.Y), Z = math.floor(known.Z) })
    end
    pcall(writefile, Extras.ZonePath, httpService:JSONEncode(encoded))
end

function Extras.locateFireForceZone(zone, isActive)
    local root = Extras.getFireForceZoneRoot(zone)
    if root then
        Extras.rememberZonePosition(root.Position)
        return root.Position
    end

    local candidates = {}
    for _, known in ipairs(Extras.KnownZonePositions) do
        table.insert(candidates, known)
    end
    local islandsFolder = workspaceService:FindFirstChild("Islands")
    local islandList = islandsFolder and islandsFolder:FindFirstChild("Islands")
    for _, islandName in ipairs(Extras.AmbushIslands) do
        local island = islandList and islandList:FindFirstChild(islandName)
        if island then
            table.insert(candidates, island:GetPivot().Position)
        end
    end
    if #candidates == 0 then
        return nil
    end

    Extras.ZoneSearchIndex = ((Extras.ZoneSearchIndex or 0) % #candidates) + 1
    local target = candidates[Extras.ZoneSearchIndex]
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    setTargetBox(nil)
    safeTravelTo(CFrame.new(target + Vector3.new(0, 10, 0)), function()
        return isActive() and zone.Parent ~= nil and Extras.getFireForceZoneRoot(zone) == nil
    end)
    task.wait(0.4)

    root = zone.Parent and Extras.getFireForceZoneRoot(zone)
    if root then
        Extras.rememberZonePosition(root.Position)
        return root.Position
    end
    return nil
end

function Extras.triggerFireForceZone(statusPrefix, isActive)
    local zone = Extras.findFireForceZone()
    if not zone then
        return false
    end

    local prompt = Extras.getFireForceZonePrompt(zone)
    if not prompt and not Extras.getFireForceZoneRoot(zone) then
        State.ExtraStatus = statusPrefix .. "searching islands for the ambush zone"
    end
    local zonePosition = prompt and prompt.Parent.Position or Extras.locateFireForceZone(zone, isActive)
    if not zonePosition then
        return true
    end
    local rootPart = getRoot()
    if rootPart and (zonePosition - rootPart.Position).Magnitude > 8 then
        State.ExtraStatus = statusPrefix .. "flying to ambush zone"
        lockedEnemyRoot = nil
        lockedTargetCFrame = nil
        setTargetBox(nil)
        safeTravelTo(CFrame.new(zonePosition + Vector3.new(0, 4, 3)), function()
            return isActive() and zone.Parent ~= nil
        end)
        task.wait(0.2)
    end

    prompt = zone.Parent and Extras.getFireForceZonePrompt(zone)
    if not prompt then
        State.ExtraStatus = statusPrefix .. "ambush zone prompt not ready"
        task.wait(0.4)
        return true
    end

    rootPart = getRoot()
    if rootPart and (prompt.Parent.Position - rootPart.Position).Magnitude > math.max((prompt.MaxActivationDistance or 10) - 2, 4) then
        travelTo(CFrame.new(prompt.Parent.Position + Vector3.new(0, 4, 3)), function()
            return isActive() and zone.Parent ~= nil
        end)
        task.wait(0.2)
    end

    State.ExtraStatus = statusPrefix .. "investigating ambush zone"
    triggerPrompt(prompt)

    local deadline = os.clock() + 10
    while os.clock() < deadline and isActive() do
        local currentRoot = getRoot()
        if currentRoot and getTargetEnemy("Infernal Ambusher", currentRoot.Position, true) then
            break
        end
        task.wait(0.2)
    end
    return true
end

function Extras.runTrialAmbushStep(questName)
    local ambusherName = "Infernal Ambusher"
    local rootPart = getRoot()
    local progressText = string.format("(%d/%d)", Extras.getQuestProgress(questName), Extras.FireForceGoals[3])

    if rootPart and Extras.findOwnAmbusher() then
        State.ExtraStatus = "Fire Force 3/3: fighting " .. ambusherName .. " " .. progressText
        engageMob(ambusherName, function()
            return State.AutoFireForceTrialEnabled and not UnlockFarm.isQuestReadyToClaim(questName)
        end, true)
        return
    end

    if Extras.triggerFireForceZone("Fire Force 3/3 " .. progressText .. ": ", Extras.isFireForceTrialActive) then
        return
    end

    State.ExtraStatus = "Fire Force 3/3: waiting for an ambush zone on A-City / Ruin City / 7th Company " .. progressText
    task.wait(2)
end

function Extras.runFireForceTrialCycle()
    if not acquireMovement("fireforce") then
        State.ExtraStatus = "Fire Force: waiting for " .. tostring(movementOwner) .. " to finish"
        task.wait(1)
        return
    end

    for index, questName in ipairs(Extras.FireForceQuests) do
        if not UnlockFarm.isQuestCompleted(questName) then
            if UnlockFarm.isQuestReadyToClaim(questName) then
                Extras.claimFireForceQuest(questName)
            elseif not UnlockFarm.getActiveQuestFolder(questName) then
                if not Extras.acceptFireForceQuest(questName) then
                    State.ExtraStatus = "Fire Force: cannot accept " .. questName .. " | " .. tostring(State.LastNotifyText)
                    task.wait(2)
                end
            elseif index == 1 then
                Extras.runCatStep(questName)
            elseif index == 2 then
                Extras.runHostageStep(questName)
            else
                Extras.runTrialAmbushStep(questName)
            end
            releaseMovement("fireforce")
            return
        end
    end

    local dataFolder = localPlayer:FindFirstChild("Data")
    local rankValue = dataFolder and dataFolder:FindFirstChild("FireForceRank")
    if rankValue and (rankValue.Value == "" or rankValue.Value == "None") then
        Extras.JoinAttempts = (Extras.JoinAttempts or 0) + 1
        if Extras.JoinAttempts <= 3 then
            local captain = Extras.goToCaptainBurns()
            if captain then
                State.ExtraStatus = "Fire Force: joining the Fire Force"
                talkToNPC(captain, "Join the Fire Force", function()
                    return rankValue.Value ~= "" and rankValue.Value ~= "None"
                end, 8)
                lockedTargetCFrame = nil
            end
            releaseMovement("fireforce")
            return
        end
    end

    State.ExtraStatus = "Fire Force: trial complete | rank " .. tostring(rankValue and rankValue.Value)
    Extras.stopLoop("AutoFireForceTrialEnabled", "fireforce")
    releaseMovement("fireforce")
    Extras.syncToggle("FireForceTrialToggle", false)
end

Extras.MobSpawnPath = "LEGACY PIECE/mob_spawns.json"
Extras.MobSpawnCache = {}
Extras.MobSpawnSeeds = {
    ["Quincy Soldier"] = Vector3.new(2980, 32, -5420)
}

function Extras.loadMobSpawns()
    pcall(function()
        local decoded = httpService:JSONDecode(readfile(Extras.MobSpawnPath))
        if typeof(decoded) == "table" then
            for mobName, point in pairs(decoded) do
                if typeof(point) == "table" and tonumber(point.X) and tonumber(point.Y) and tonumber(point.Z) then
                    Extras.MobSpawnCache[mobName] = Vector3.new(point.X, point.Y, point.Z)
                end
            end
        end
    end)
end

function Extras.saveMobSpawns()
    pcall(function()
        if not isfolder(Extras.DungeonFolder) then
            makefolder(Extras.DungeonFolder)
        end
        local encoded = {}
        for mobName, position in pairs(Extras.MobSpawnCache) do
            encoded[mobName] = { X = math.floor(position.X), Y = math.floor(position.Y), Z = math.floor(position.Z) }
        end
        writefile(Extras.MobSpawnPath, httpService:JSONEncode(encoded))
    end)
end

function Extras.recordMobSpawns()
    local now = os.clock()
    if now < (Extras.NextSpawnRecordAt or 0) then
        return
    end
    Extras.NextSpawnRecordAt = now + 2

    local changed = false
    for _, enemy in ipairs(enemiesFolder:GetChildren()) do
        local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
        if enemyRoot then
            local mobName = stripBossTag(enemy.Name)
            if not Extras.MobSpawnCache[mobName] then
                Extras.MobSpawnCache[mobName] = enemyRoot.Position
                changed = true
            end
        end
    end

    if changed then
        Extras.saveMobSpawns()
    end
end

function Extras.getMobIsland(mobName)
    local islandsFolder = workspaceService:FindFirstChild("Islands")
    local islandList = islandsFolder and islandsFolder:FindFirstChild("Islands")
    if not islandList then
        return nil
    end
    for word in string.gmatch(string.lower(mobName), "%a+") do
        if #word >= 4 then
            for _, island in ipairs(islandList:GetChildren()) do
                if string.find(string.lower(island.Name), word, 1, true) then
                    return island
                end
            end
        end
    end
    return nil
end

function Extras.goToMobSpawn(mobName)
    local spawnPosition = Extras.MobSpawnCache[mobName] or Extras.MobSpawnSeeds[mobName]
    local rootPart = getRoot()
    if not rootPart then
        return false
    end

    if spawnPosition then
        if (spawnPosition - rootPart.Position).Magnitude > 60 then
            State.MobFarmStatus = "Travelling to " .. mobName .. " spawn"
            lockedEnemyRoot = nil
            lockedTargetCFrame = nil
            setTargetBox(nil)
            safeTravelTo(CFrame.new(spawnPosition + Vector3.new(0, 8, 0)), function()
                local currentRoot = getRoot()
                return State.MobFarmEnabled and currentRoot ~= nil and getTargetEnemy(mobName, currentRoot.Position, false) == nil
            end)
        else
            State.MobFarmStatus = "Waiting for " .. mobName .. " to spawn"
            task.wait(0.5)
        end
        return true
    end

    local island = Extras.getMobIsland(mobName)
    if island then
        if getNearestIslandName(rootPart.Position) ~= island.Name then
            State.MobFarmStatus = "Travelling to " .. island.Name .. " for " .. mobName
            lockedEnemyRoot = nil
            lockedTargetCFrame = nil
            setTargetBox(nil)
            teleportToIsland(island.Name, island:GetPivot().Position)
        else
            State.MobFarmStatus = "On " .. island.Name .. " | searching for " .. mobName
            task.wait(1)
        end
        return true
    end

    return false
end

function Extras.getMobFarmOptions()
    local names = {}
    local seen = {}
    for npcName in pairs(npcData) do
        local cleanName = stripBossTag(npcName)
        if not seen[cleanName] and not isKnownBossName(cleanName) and summonEntryByName[normalizeName(cleanName)] == nil then
            seen[cleanName] = true
            table.insert(names, cleanName)
        end
    end
    table.sort(names)
    return names
end

function Extras.getSelectedMobs()
    local selected = {}
    for mobName, enabled in pairs(State.MobFarmSelection) do
        if enabled then
            table.insert(selected, mobName)
        end
    end
    table.sort(selected)
    return selected
end

function Extras.runMobFarmCycle()
    local selected = Extras.getSelectedMobs()
    if #selected == 0 then
        State.MobFarmStatus = "Select mobs to farm"
        task.wait(1)
        return
    end

    if Prestige.isHandlingRequirements() then
        State.MobFarmStatus = "Paused | Auto Prestige is working"
        task.wait(0.5)
        return
    end

    if not acquireMovement("mob") then
        State.MobFarmStatus = "Waiting for " .. tostring(movementOwner) .. " to finish"
        task.wait(0.5)
        return
    end

    local rootPart, playerHumanoid = getRoot()
    if rootPart and playerHumanoid and playerHumanoid.Health > 0 then
        autoAllocateStats()
        collectNearbyPickup("mob")

        rootPart = getRoot()
        local targetMob = nil
        local bestDistance = math.huge
        for _, mobName in ipairs(selected) do
            local enemy = rootPart and getTargetEnemy(mobName, rootPart.Position, false)
            local enemyRoot = enemy and enemy:FindFirstChild("HumanoidRootPart")
            if enemyRoot then
                local distance = (enemyRoot.Position - rootPart.Position).Magnitude
                if distance < bestDistance then
                    bestDistance = distance
                    targetMob = mobName
                end
            end
        end

        local targetVisible = targetMob ~= nil
        if not targetMob then
            Extras.MobFarmCursor = math.clamp(Extras.MobFarmCursor or 1, 1, #selected)
            targetMob = selected[Extras.MobFarmCursor]
        end

        if targetMob ~= Extras.LastMobTarget then
            lastKnownMobCFrame = nil
            lockedEnemyRoot = nil
            Combat.LockedMobName = nil
            Extras.LastMobTarget = targetMob
        end

        local function isActive()
            return State.MobFarmEnabled
        end

        if targetVisible then
            State.MobFarmStatus = "Farming " .. targetMob
            farmMobWithAnchor(targetMob, isActive, false)
        elseif Extras.MobSpawnCache[targetMob] or Extras.MobSpawnSeeds[targetMob] then
            Extras.goToMobSpawn(targetMob)
        elseif getMobAnchor(targetMob) then
            State.MobFarmStatus = "Farming " .. targetMob
            if not farmMobWithAnchor(targetMob, isActive, false) then
                Extras.MobFarmCursor = ((Extras.MobFarmCursor or 1) % #selected) + 1
            end
        elseif not Extras.goToMobSpawn(targetMob) then
            State.MobFarmStatus = "Cannot locate " .. targetMob .. " | visit its island once so the hub can learn it"
            Extras.MobFarmCursor = ((Extras.MobFarmCursor or 1) % #selected) + 1
            task.wait(1)
        end
    end

    releaseMovement("mob")
end

function Extras.stopAll()
    Extras.stopLoop("MobFarmEnabled", "mob")
    Extras.stopLoop("AutoFireForceTrialEnabled", "fireforce")
    Extras.stopLoop("AutoTraitEnabled")
    Extras.stopLoop("AutoWhaleEnabled", "whale")
    Extras.WhaleActive = false
    Extras.WhaleFishing = false
    Extras.PriorityRequest = nil
    Extras.stopLoop("AutoDeepsharkEnabled", "deepshark")
    Extras.stopLoop("AutoArayaEnabled", "araya")
    Extras.stopLoop("AutoTwohEnabled", "twoh")
    if Extras.Twoh then
        Extras.Twoh.RealmRequesters = {}
        Extras.Twoh.Delegated = false
        pcall(Extras.Twoh.releaseAll)
        pcall(Extras.Twoh.unlockF)
        State.TwohRunDrops = nil
        task.spawn(Extras.Twoh.restoreStyle)
    end
    Extras.stopLoop("AutoYhwachEnabled", "yhwach")
    if Extras.Yhwach then
        pcall(Extras.Yhwach.releaseAll)
    end
    Extras.stopLoop("AutoBankaiEnabled", "bankai")
    Extras.stopLoop("AutoSolemnEnabled", "solemn")
    Extras.DeepsharkRequesters = {}
    Extras.DeepsharkDelegated = false
    if getgenv().HubItemIndicatorConnections then
        for _, connection in ipairs(getgenv().HubItemIndicatorConnections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
        getgenv().HubItemIndicatorConnections = nil
    end
    for _, connectionName in ipairs({ "HubArayaConnection", "HubArayaTeleportConnection", "HubAutoDungeonConnection", "HubTwohDungeonAttrConnection", "HubTwohEnemyAddConnection" }) do
        if getgenv()[connectionName] then
            pcall(function()
                getgenv()[connectionName]:Disconnect()
            end)
            getgenv()[connectionName] = nil
        end
    end
    Extras.DeepsharkFishing = false
    Extras.stopFishing()
    Extras.stopLoop("AutoCoffinEnabled", "coffin")
    Extras.stopLoop("AutoAmbushEnabled", "ambush")
    Extras.stopLoop("AutoAmbushOnlyEnabled", "ambushonly")
    if getgenv().HubCoffinConnection then
        pcall(function()
            getgenv().HubCoffinConnection:Disconnect()
        end)
        getgenv().HubCoffinConnection = nil
    end
end

local prestigeThread = nil

function Prestige.getRequirementProgress()
    local dataFolder = localPlayer:FindFirstChild("Data")
    if not dataFolder then
        return nil, "Data not loaded"
    end

    local prestigeValue = dataFolder:FindFirstChild("Prestige")
    local levelValue = dataFolder:FindFirstChild("Level")
    if not prestigeValue or not levelValue then
        return nil, "Data not loaded"
    end

    local currentPrestige = prestigeValue.Value
    if currentPrestige >= (prestigeData.MAX_PRESTIGE or math.huge) then
        return nil, "Max prestige reached"
    end

    local requirements = prestigeData.GetRequirements(currentPrestige + 1)
    if typeof(requirements) ~= "table" then
        return nil, "No requirements for prestige " .. tostring(currentPrestige + 1)
    end

    local decodedStats = {}
    local prestigeStatsValue = dataFolder:FindFirstChild("PrestigeStats")
    if prestigeStatsValue and prestigeStatsValue.Value ~= "" then
        pcall(function()
            decodedStats = httpService:JSONDecode(prestigeStatsValue.Value)
        end)
    end

    local progress = {}
    for _, requirement in ipairs(requirements) do
        local currentAmount = 0
        if requirement.Type == "Level" then
            currentAmount = levelValue.Value
        elseif requirement.Type == "Material" then
            currentAmount = getInventoryAmount(requirement.Name)
        else
            currentAmount = tonumber(decodedStats[requirement.Type]) or 0
        end

        table.insert(progress, {
            Label = requirement.Name or requirement.Type,
            Type = requirement.Type,
            Name = requirement.Name,
            Current = currentAmount,
            Needed = requirement.Value or 0,
            Done = currentAmount >= (requirement.Value or 0)
        })
    end

    return progress, nil
end

function Prestige.getMissing()
    local progress, failureReason = Prestige.getRequirementProgress()
    if not progress then
        return { failureReason }
    end

    local missing = {}
    for _, entry in ipairs(progress) do
        if not entry.Done then
            table.insert(missing, string.format("%s (%d/%d)", entry.Label, math.floor(entry.Current), math.floor(entry.Needed)))
        end
    end

    return missing
end

function Prestige.canPrestige()
    local progress = Prestige.getRequirementProgress()
    if not progress then
        return false
    end

    for _, entry in ipairs(progress) do
        if not entry.Done then
            return false
        end
    end

    return true
end

function Prestige.needsBossOrMaterial()
    local progress = Prestige.getRequirementProgress()
    if not progress then
        return false
    end

    for _, entry in ipairs(progress) do
        if not entry.Done then
            if (string.find(entry.Type, "Kills$") and entry.Type ~= "NPCKills") or entry.Type == "Material" then
                return true
            end
        end
    end

    return false
end

function Prestige.getCurrentValue()
    return getDataValue("Prestige")
end

function Prestige.isHandlingRequirements()
    return State.PrestigeEnabled and Prestige.activeWork ~= nil
end

function Prestige.getOtherFarmMode()
    if State.FarmLevelEnabled then
        return "Auto Farm Level"
    elseif State.FarmQuestEnabled then
        return "Auto Farm Quest"
    elseif State.BossFarmEnabled then
        return "Auto Farm Bosses"
    elseif State.UnlockEnabled then
        return "Auto Unlock"
    end
    return nil
end

function Prestige.tryRemote()
    local prestigeBefore = Prestige.getCurrentValue()
    invokeInput("Prestige")
    local deadline = os.clock() + 2
    while os.clock() < deadline do
        if Prestige.getCurrentValue() > prestigeBefore then
            return true
        end
        task.wait(0.1)
    end
    return Prestige.getCurrentValue() > prestigeBefore
end

function Prestige.isEntryMissing(entryType, entryName)
    local progress = Prestige.getRequirementProgress()
    if not progress then
        return false
    end
    for _, entry in ipairs(progress) do
        if entry.Type == entryType and entry.Name == entryName then
            return not entry.Done
        end
    end
    return false
end

function Prestige.describeMissing(progress)
    local parts = {}
    for _, entry in ipairs(progress or {}) do
        if not entry.Done then
            table.insert(parts, string.format("%s %d/%d", tostring(entry.Label), math.floor(entry.Current), math.floor(entry.Needed)))
        end
    end
    return table.concat(parts, ", ")
end

function Prestige.refreshLive()
    local progress, failureReason = Prestige.getRequirementProgress()
    if not progress then
        State.PrestigeMissing = tostring(failureReason)
        return
    end
    local missingText = Prestige.describeMissing(progress)
    if missingText == "" then
        State.PrestigeMissing = "none (ready)"
    else
        State.PrestigeMissing = missingText
    end
end

function Prestige.hookSignals()
    for _, connection in ipairs(getgenv().HubPrestigeConnections or {}) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    local connections = {}
    getgenv().HubPrestigeConnections = connections

    local dataFolder = localPlayer:FindFirstChild("Data")
    if not dataFolder then
        return
    end

    local function onChanged()
        Prestige.lastSignal = os.clock()
        Prestige.refreshLive()
    end

    for _, valueName in ipairs({ "Level", "Prestige", "PrestigeStats" }) do
        local valueObject = dataFolder:FindFirstChild(valueName)
        if valueObject then
            table.insert(connections, valueObject.Changed:Connect(onChanged))
        end
    end

    local inventoryFolder = dataFolder:FindFirstChild("Inventory")
    if inventoryFolder then
        table.insert(connections, inventoryFolder.DescendantAdded:Connect(function(descendant)
            onChanged()
            if descendant.Name == "Amount" and descendant:IsA("ValueBase") then
                table.insert(connections, descendant.Changed:Connect(onChanged))
            end
        end))
        table.insert(connections, inventoryFolder.ChildRemoved:Connect(onChanged))
        for _, descendant in ipairs(inventoryFolder:GetDescendants()) do
            if descendant.Name == "Amount" and descendant:IsA("ValueBase") then
                table.insert(connections, descendant.Changed:Connect(onChanged))
            end
        end
    end

    Prestige.refreshLive()
end

function Prestige.travelAndPrestige(skipRemote)
    if not skipRemote then
        State.PrestigeStatus = "Prestiging via remote"
        if Prestige.tryRemote() then
            return true
        end
    end

    local rootPart = getRoot()
    if not rootPart then
        return false
    end

    prestigeActive = true
    stopTween()
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    lastKnownMobCFrame = nil
    setTargetBox(nil)

    local overseer = findNPCByName(prestigeNPCName)

    if not overseer or getNearestIslandName(rootPart.Position) ~= prestigeIslandName then
        State.PrestigeStatus = "Travelling to " .. prestigeNPCName
        local spot = getSpotForNPCName(prestigeNPCName)
        local travelled = false

        if spot then
            travelled = teleportToSpot(spot.Island, spot.Target)
        end

        if not travelled then
            travelled = teleportToIsland(prestigeIslandName)
        end

        if not travelled then
            State.PrestigeStatus = "Travel to " .. prestigeIslandName .. " failed"
            prestigeActive = false
            return false
        end
        task.wait(0.3)
        overseer = findNPCByName(prestigeNPCName)
    end

    if not overseer then
        State.PrestigeStatus = prestigeNPCName .. " not found"
        prestigeActive = false
        return false
    end

    State.PrestigeStatus = "Approaching " .. prestigeNPCName
    local reached = travelToNPC(overseer, function()
        return State.PrestigeEnabled
    end)

    if not reached then
        State.PrestigeStatus = "Cannot reach " .. prestigeNPCName
        lockedTargetCFrame = nil
        prestigeActive = false
        return false
    end

    State.PrestigeStatus = "Prestiging at " .. prestigeNPCName
    local prompt = getNPCPrompt(overseer)
    if prompt then
        triggerPrompt(prompt)
        task.wait(0.2)
    end

    local success = Prestige.tryRemote()
    if not success then
        success = Prestige.tryRemote()
    end

    lockedTargetCFrame = nil
    prestigeActive = false
    return success
end

local prestigeBossMap = {
    CidKills = "Cid Kagenou",
    OwlKills = "One-Eyed Owl",
    RedMistKills = "The Red Mist",
    DioKills = "Dio",
    InfernalAmbusherKills = "Infernal Ambusher",
    DemonInfernalKills = "Demon Infernal",
    DioHeavenAscensionKills = "Dio Heaven Ascension",
    RienKills = "Rien",
    ArayaKills = "The Dihui Star, Araya",
    AncientDeepsharkKills = "Ancient Deepshark",
    YhwachKills = "Yhwach",
    SpecialKills = "Cid Kagenou"
}

function Prestige.handleBossRequirement(req, bossName)
    local reqType = req.Type
    local reqName = req.Name
    local stillMissing = function()
        return State.PrestigeEnabled and Prestige.isEntryMissing(reqType, reqName)
    end

    State.PrestigeStatus = string.format("Prestige Boss: %s (%d/%d)", bossName, math.floor(req.Current), math.floor(req.Needed)) .. Prestige.ParkedSuffix

    local catalogItem = summonEntryByName[normalizeName(bossName)]
    if catalogItem then
        BossFarm.prepareAndKill(catalogItem, stillMissing, "prestige")
        local occupant = catalogItem.NPC and BossFarm.getAltarOccupant(catalogItem.NPC)
        while stillMissing() and (BossFarm.isBossAlive(bossName) or (occupant and BossFarm.isBossAlive(occupant))) do
            local currentTarget = BossFarm.isBossAlive(bossName) and bossName or occupant
            if not currentTarget or not BossFarm.isBossAlive(currentTarget) then
                break
            end
            if currentTarget ~= bossName then
                setFarmStatus("Clearing " .. currentTarget .. " to free " .. tostring(catalogItem.NPC))
            end
            farmMobWithAnchor(currentTarget, function()
                return stillMissing() and BossFarm.isBossAlive(currentTarget)
            end, true)
            task.wait(0.05)
            occupant = catalogItem.NPC and BossFarm.getAltarOccupant(catalogItem.NPC)
        end
        return
    end

    while stillMissing() and BossFarm.isBossAlive(bossName) do
        farmMobWithAnchor(bossName, function()
            return stillMissing() and BossFarm.isBossAlive(bossName)
        end, true)
        task.wait(0.05)
    end
end

function Prestige.handleLevelRequirement(req)
    local reqType = req.Type
    local reqName = req.Name
    local stillMissing = function()
        return State.PrestigeEnabled and Prestige.isEntryMissing(reqType, reqName)
    end

    State.PrestigeStatus = string.format("Prestige %s: %d/%d", tostring(req.Label), math.floor(req.Current), math.floor(req.Needed)) .. Prestige.ParkedSuffix
    autoAllocateStats()
    collectNearbyPickup("prestige")

    local currentQuest = FarmLevel.pickActiveQuest()
    if currentQuest then
        executeQuestCombat(currentQuest, stillMissing)
        return
    end

    local targetNPC, targetQuestName = FarmLevel.getRecommendedQuest()
    if not targetNPC then
        State.PrestigeStatus = "No quest available for level " .. tostring(getPlayerLevel())
        task.wait(1)
        return
    end

    local reached = travelToNPC(targetNPC, function()
        return stillMissing() and FarmLevel.getActiveQuest(targetQuestName) == nil
    end)
    if reached then
        invokeInput("Quest", "Accept", targetNPC, targetQuestName)
        task.wait(0.3)
        if FarmLevel.getActiveQuest(targetQuestName) == nil then
            talkToNPC(targetNPC, "Accept", function()
                return FarmLevel.getActiveQuest(targetQuestName) ~= nil
            end, 5)
        end
    end
    lockedTargetCFrame = nil
end

Prestige.DungeonBlocked = {}
Prestige.DungeonDifficulty = "Easy"

function Prestige.getDungeonData()
    if Prestige.DungeonDataCache == nil or (Prestige.DungeonDataCache == false and os.clock() - (Prestige.DungeonDataFailedAt or 0) > 30) then
        local ok, result = pcall(function()
            return require(configurationsFolder:WaitForChild("DungeonData", 5))
        end)
        Prestige.DungeonDataCache = (ok and typeof(result) == "table") and result or false
        if Prestige.DungeonDataCache == false then
            Prestige.DungeonDataFailedAt = os.clock()
        end
        Prestige.BossDungeonMemo = {}
    end
    return Prestige.DungeonDataCache or nil
end

function Prestige.findBossDungeon(bossName)
    local data = Prestige.getDungeonData()
    if not data or not bossName then
        return nil
    end
    Prestige.BossDungeonMemo = Prestige.BossDungeonMemo or {}
    local memo = Prestige.BossDungeonMemo[bossName]
    if memo then
        return memo.Key, memo.Info
    end
    local wanted = normalizeName(bossName)
    local foundKey, foundInfo = nil, nil
    for dungeonKey, info in pairs(data) do
        if not foundKey and typeof(info) == "table" and typeof(info.Bosses) == "table" then
            for _, listed in pairs(info.Bosses) do
                if typeof(listed) == "string" and normalizeName(listed) == wanted then
                    foundKey, foundInfo = dungeonKey, info
                    break
                end
            end
        end
    end
    Prestige.BossDungeonMemo[bossName] = { Key = foundKey, Info = foundInfo }
    return foundKey, foundInfo
end

function Prestige.isKnownDungeon(dungeonName)
    if Prestige.getDungeonEntry(dungeonName) then
        return true
    end
    local data = Prestige.getDungeonData()
    local info = data and data[dungeonName]
    return typeof(info) == "table" and typeof(info.Bosses) == "table"
end

function Prestige.getDungeonEntry(dungeonKey)
    for _, entry in ipairs(Extras.Dungeons) do
        if entry.Key == dungeonKey then
            return entry
        end
    end
    return nil
end

Prestige.ParkedTypes = { YhwachKills = "Yhwach Global Boss kills" }
Prestige.ParkedSuffix = ""
Prestige.Idle = false

function Prestige.parkedText(plan)
    local parts = {}
    for _, req in ipairs(plan.Parked) do
        table.insert(parts, Prestige.ParkedTypes[req.Type] .. ": skipped (manual)")
    end
    return table.concat(parts, " | ")
end

function Prestige.planRequirements(progress)
    local plan = { Dungeons = {}, Waiting = {}, Parked = {} }
    for _, req in ipairs(progress or {}) do
        if not req.Done then
            if Prestige.ParkedTypes[req.Type] then
                table.insert(plan.Parked, req)
            elseif string.find(req.Type, "Kills$") and req.Type ~= "NPCKills" then
                local bossName = prestigeBossMap[req.Type] or prestigeKillBossMap[req.Type] or req.Name
                if bossName then
                    local summonable = summonEntryByName[normalizeName(bossName)] ~= nil
                    local dungeonKey, dungeonInfo = nil, nil
                    if not summonable then
                        dungeonKey, dungeonInfo = Prestige.findBossDungeon(bossName)
                    end
                    if req.Type == Extras.Twoh.PrestigeKillType or dungeonKey == Extras.Twoh.RealmName then
                        plan.Realm = plan.Realm or req
                    elseif dungeonKey then
                        table.insert(plan.Dungeons, { Req = req, Boss = bossName, Key = dungeonKey, Info = dungeonInfo, Entry = Prestige.getDungeonEntry(dungeonKey) })
                    elseif not plan.Boss and (summonable or BossFarm.isBossAlive(bossName)) then
                        plan.Boss = req
                        plan.BossTarget = bossName
                    elseif not summonable then
                        if bossName == Extras.DeepsharkName then
                            plan.Deepshark = true
                        else
                            table.insert(plan.Waiting, bossName)
                        end
                    end
                end
            elseif req.Type == "Material" then
                plan.Material = plan.Material or req
            elseif req.Type == "Level" or req.Type == "NPCKills" then
                plan.Level = plan.Level or req
            end
        end
    end
    if plan.BossTarget == Extras.DeepsharkName then
        plan.Deepshark = true
    end
    return plan
end

function Prestige.neededDungeons(fresh)
    local cache = Prestige.NeededCache
    if not fresh and cache and os.clock() - cache.At < 1 then
        return cache.Map
    end
    local map = {}
    local progress = Prestige.getRequirementProgress()
    if progress then
        for _, work in ipairs(Prestige.planRequirements(progress).Dungeons) do
            map[work.Key] = map[work.Key] or work
        end
    end
    Prestige.NeededCache = { At = os.clock(), Map = map }
    return map
end

function Prestige.ownsDungeon(dungeonName)
    if not State.PrestigeEnabled or typeof(dungeonName) ~= "string" or dungeonName == Extras.Twoh.RealmName then
        return false
    end
    if State.AutoArayaEnabled and Extras.isArayaDungeon(dungeonName) then
        return false
    end
    return Prestige.neededDungeons()[dungeonName] ~= nil
end

function Prestige.onDungeonState(syncRemote, status, dungeonName)
    if status == "Vote" then
        task.delay(1, function()
            pcall(function()
                syncRemote:FireServer("Vote", Prestige.DungeonDifficulty)
            end)
        end)
    elseif status == "Clear" or status == "Lose" then
        Prestige.LoseStreak = Prestige.LoseStreak or {}
        if status == "Clear" then
            Prestige.LoseStreak[dungeonName] = 0
        else
            Prestige.LoseStreak[dungeonName] = (Prestige.LoseStreak[dungeonName] or 0) + 1
            if Prestige.LoseStreak[dungeonName] >= 4 then
                Prestige.LoseStreak[dungeonName] = 0
                Prestige.blockDungeon(dungeonName, "lost 4 runs in a row", 600)
            end
        end
        task.delay(2, function()
            local keyItem = Prestige.dungeonKeyItem(dungeonName)
            if keyItem and getInventoryAmount(keyItem) < 1 then
                return
            end
            if State.PrestigeEnabled and Prestige.neededDungeons(true)[dungeonName] and not Prestige.isDungeonBlocked(dungeonName) then
                Prestige.ReplaySentAt = os.clock()
                pcall(function()
                    syncRemote:FireServer("ReplayVote")
                end)
            end
        end)
    end
end

function Prestige.dungeonKeyItem(dungeonName)
    local entry = Prestige.getDungeonEntry(dungeonName)
    local data = Prestige.getDungeonData()
    local info = data and data[dungeonName]
    if entry and entry.Item then
        return entry.Item
    end
    if typeof(info) == "table" and typeof(info.PortalKey) == "string" then
        return info.PortalKey
    end
    return nil
end

function Prestige.workLabel(work)
    return string.format("Prestige: %s %d/%d", tostring(work.Boss), math.floor(work.Req.Current), math.floor(work.Req.Needed))
end

function Prestige.blockDungeon(dungeonKey, reason, seconds, static)
    local blocked = Prestige.DungeonBlocked[dungeonKey] or { Fails = 0 }
    if static then
        blocked.Static = true
        blocked.Until = math.huge
        blocked.Reason = tostring(reason)
        Prestige.DungeonBlocked[dungeonKey] = blocked
        return
    end
    blocked.Static = nil
    blocked.Fails = blocked.Fails + 1
    blocked.Until = os.clock() + (seconds or math.min(30 * 2 ^ (blocked.Fails - 1), 600))
    blocked.Reason = tostring(reason)
    Prestige.DungeonBlocked[dungeonKey] = blocked
end

function Prestige.refreshStaticBlock(work)
    local blocker = Prestige.dungeonBlocker(work)
    local blocked = Prestige.DungeonBlocked[work.Key]
    if blocker then
        if not (blocked and not blocked.Static and os.clock() < blocked.Until) then
            Prestige.blockDungeon(work.Key, blocker, nil, true)
        end
    elseif blocked and blocked.Static then
        Prestige.DungeonBlocked[work.Key] = nil
    end
end

function Prestige.blockedText(work)
    local blocked = Prestige.DungeonBlocked[work.Key]
    local tail = (blocked and blocked.Static) and "waiting for it" or ("retry in " .. math.max(0, math.floor((blocked and blocked.Until or os.clock()) - os.clock())) .. "s")
    return string.format("%s %d/%d: %s blocked (%s) | %s", tostring(work.Boss), math.floor(work.Req.Current), math.floor(work.Req.Needed), work.Entry and work.Entry.Name or tostring(work.Key), tostring(blocked and blocked.Reason), tail)
end

function Prestige.isDungeonBlocked(dungeonKey)
    local blocked = Prestige.DungeonBlocked[dungeonKey]
    return blocked ~= nil and os.clock() < blocked.Until
end

function Prestige.dungeonBlocker(work)
    local entry = work.Entry
    local info = work.Info or {}
    if not entry then
        return "the hub has no entry route for " .. tostring(work.Key)
    end
    if State.AutoArayaEnabled and Extras.isArayaDungeon(work.Key) then
        return "Auto Araya is running it (its kills count too)"
    end
    if entry.Quest and not UnlockFarm.isQuestCompleted(entry.Quest) then
        return "finish the quest \"" .. entry.Quest .. "\" first"
    end
    local keyItem = entry.Item or (typeof(info.PortalKey) == "string" and info.PortalKey or nil)
    if keyItem and getInventoryAmount(keyItem) < 1 then
        return "needs 1 " .. keyItem .. " (have 0)"
    end
    local requiredStyle = entry.Style or (typeof(info.RequiredStyle) == "string" and info.RequiredStyle or nil)
    if requiredStyle and getInventoryAmount(requiredStyle) < 1 then
        return "requires " .. requiredStyle .. " (not owned)"
    end
    return nil
end

function Prestige.leaveDungeon(reason)
    State.PrestigeStatus = "Prestige: leaving " .. tostring(workspaceService:GetAttribute("Dungeon")) .. " | " .. tostring(reason)
    Prestige.DungeonWork = nil
    pcall(Extras.queueArayaReload)
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    if os.clock() - (Prestige.LeaveSentAt or 0) > 8 then
        Prestige.LeaveSentAt = os.clock()
        Extras.expectTeleport(15)
        local leaveRemote = eventsFolder and eventsFolder:FindFirstChild("DungeonLeave")
        if leaveRemote then
            pcall(function()
                leaveRemote:FireServer()
            end)
        end
    end
    task.wait(1)
end

function Prestige.enterDungeon(work)
    local entry = work.Entry
    local label = Prestige.workLabel(work) .. " | " .. entry.Name .. " (" .. Prestige.DungeonDifficulty .. ")"
    local function setStatus(message)
        Prestige.LastDungeonMessage = tostring(message)
        State.PrestigeStatus = label .. " | " .. tostring(message)
    end
    if not acquireMovement("prestige") then
        setStatus("waiting for " .. tostring(Extras.PriorityRequest or movementOwner) .. " to finish")
        task.wait(0.5)
        return
    end
    Prestige.LastDungeonMessage = nil
    local started = Extras.enterSelectedDungeon(entry, function()
        return State.PrestigeEnabled
    end, setStatus)
    lockedTargetCFrame = nil
    releaseMovement("prestige")
    if not started and State.PrestigeEnabled then
        Prestige.blockDungeon(work.Key, Prestige.LastDungeonMessage or "entry failed")
    end
end

function Prestige.runDungeonInside(work, dungeonName)
    Extras.connectAutoDungeon()
    Extras.Twoh.muteDungeonHelper()
    pcall(Extras.queueArayaReload)
    Prestige.DungeonWork = dungeonName
    local label = Prestige.workLabel(work) .. " | in " .. dungeonName
    if not acquireMovement("prestige") then
        State.PrestigeStatus = label .. " | waiting for " .. tostring(Extras.PriorityRequest or movementOwner) .. " to finish"
        task.wait(0.5)
        return
    end
    local sealPrompt = Extras.Twoh and Extras.Twoh.findSealPrompt()
    if sealPrompt and not (Extras.Twoh and Extras.Twoh.anyLivingEnemy()) then
        Extras.solveDungeonSeal(sealPrompt, dungeonName)
        releaseMovement("prestige")
        return
    end
    local waveText = string.format("wave %s/%s", tostring(Extras.DungeonWave or "?"), tostring(Extras.DungeonMaxWave or "?"))
    local rootPart = getRoot()
    local timeSafe = Extras.isArayaDungeon(dungeonName) and dungeonName ~= Extras.Araya.EstateName
    local target = nil
    if rootPart then
        target = timeSafe and Extras.pickArayaTarget(rootPart) or Extras.pickDungeonTarget(rootPart)
    end
    if target then
        Prestige.DungeonIdleSince = nil
        State.PrestigeStatus = label .. " | fighting " .. target.Name .. " | " .. waveText
        farmMobWithAnchor(target.Name, function()
            return State.PrestigeEnabled and target.Parent ~= nil and Prestige.neededDungeons()[dungeonName] ~= nil
        end, true)
    else
        local now = os.clock()
        local status = tostring(Prestige.DungeonStatus or "?")
        State.PrestigeStatus = label .. " | " .. status .. " | waiting for enemies | " .. waveText
        Prestige.DungeonIdleSince = Prestige.DungeonIdleSince or now
        if (status == "Clear" or status == "Lose") and now - Prestige.DungeonIdleSince > 30 then
            Prestige.DungeonIdleSince = nil
            releaseMovement("prestige")
            Prestige.leaveDungeon("run ended and the replay did not start (keys or lobby) | leaving")
            return
        end
        if now - Prestige.DungeonIdleSince >= 12 and now - (Prestige.DungeonNudgeAt or 0) >= 10 then
            Prestige.DungeonNudgeAt = now
            local syncRemote = eventsFolder and eventsFolder:FindFirstChild("DungeonInsideSync")
            if syncRemote then
                pcall(function()
                    syncRemote:FireServer("ReplayVote")
                end)
                pcall(function()
                    syncRemote:FireServer("Vote", Prestige.DungeonDifficulty)
                end)
            end
        end
        task.wait(0.5)
    end
    releaseMovement("prestige")
end

function Prestige.handleInsideDungeon(plan, dungeonName, missingText)
    if State.AutoArayaEnabled and Extras.isArayaDungeon(dungeonName) then
        Prestige.activeWork = nil
        Prestige.DungeonWork = nil
        State.PrestigeStatus = "Prestige: Auto Araya is running " .. dungeonName .. " | waiting | missing: " .. missingText
        task.wait(1)
        return
    end
    local otherWorkReady = false
    for _, work in ipairs(plan.Dungeons) do
        if work.Key == dungeonName then
            if Prestige.isDungeonBlocked(dungeonName) then
                Prestige.activeWork = "leave " .. dungeonName
                Prestige.leaveDungeon(Prestige.blockedText(work) .. " | leaving")
                return
            end
            Prestige.activeWork = "dungeon " .. dungeonName
            Prestige.runDungeonInside(work, dungeonName)
            return
        end
        if not Prestige.isDungeonBlocked(work.Key) and Prestige.dungeonBlocker(work) == nil then
            otherWorkReady = true
        end
    end
    Prestige.DungeonWork = nil
    if State.AutoDungeonEnabled and not otherWorkReady then
        Prestige.activeWork = nil
        Prestige.restoreHelper()
        State.PrestigeStatus = "Prestige: inside " .. dungeonName .. " (Auto Dungeon run) | Prestige re-evaluates on the main map | missing: " .. missingText
        task.wait(1)
        return
    end
    if not Prestige.isKnownDungeon(dungeonName) then
        Prestige.activeWork = nil
        Prestige.Idle = true
        releaseMovement("prestige")
        State.PrestigeStatus = "Prestige: inside " .. dungeonName .. " (not a Prestige dungeon, left alone) | waiting to return to the main map | missing: " .. missingText
        task.wait(1)
        return
    end
    Prestige.activeWork = "leave " .. dungeonName
    Prestige.leaveDungeon("Prestige needs nothing here | re-evaluating on the main map | missing: " .. missingText)
end

function Prestige.restoreHelper()
    if not Extras.Twoh.isActive() then
        Extras.Twoh.restoreDungeonHelper()
    end
end

function Prestige.handleMissing(progress, missingText)
    local plan = Prestige.planRequirements(progress)
    Prestige.Idle = false
    Prestige.ParkedSuffix = #plan.Parked > 0 and (" | " .. Prestige.parkedText(plan)) or ""
    local dungeonName = workspaceService:GetAttribute("Dungeon")
    if typeof(dungeonName) ~= "string" then
        dungeonName = nil
    end
    local inRealm = dungeonName ~= nil and dungeonName == Extras.Twoh.RealmName

    if dungeonName and not inRealm then
        Extras.Twoh.releaseRealm("prestige")
        Extras.requestDeepshark("prestige", false)
        Prestige.handleInsideDungeon(plan, dungeonName, missingText)
        return
    end

    local dungeonWork = nil
    local blockedWorks = {}
    if not inRealm then
        for _, work in ipairs(plan.Dungeons) do
            Prestige.refreshStaticBlock(work)
            if Prestige.isDungeonBlocked(work.Key) then
                table.insert(blockedWorks, work)
            elseif not dungeonWork then
                dungeonWork = work
            end
        end
    end
    Prestige.DungeonWork = dungeonWork and dungeonWork.Key or nil

    local realmMode, realmSkip = nil, nil
    if inRealm then
        if not State.AutoTwohEnabled and (plan.Realm or not State.AutoDungeonEnabled) then
            realmMode = "drive"
        end
    elseif plan.Realm and not plan.Boss and not dungeonWork then
        if State.AutoTwohEnabled then
            realmMode = "twoh"
        else
            realmSkip = Extras.Twoh.prestigeSkipReason()
            realmMode = realmSkip == nil and "drive" or nil
        end
    end
    if realmMode ~= "drive" then
        Extras.Twoh.releaseRealm("prestige")
    end
    if realmMode == "twoh" then
        Extras.Twoh.requestRealm("prestige", false)
    end

    if inRealm and realmMode ~= "drive" then
        Extras.requestDeepshark("prestige", false)
        Prestige.activeWork = nil
        State.PrestigeStatus = "Prestige: inside Realm Beyond Heaven (" .. (State.AutoTwohEnabled and "Auto TWOH" or "Auto Dungeon") .. " run) | waiting | missing: " .. missingText
        task.wait(1)
        return
    end
    if inRealm and realmMode == "drive" and not plan.Realm then
        Extras.requestDeepshark("prestige", false)
        Prestige.activeWork = "leave " .. tostring(dungeonName)
        Extras.Twoh.finishRun("LeftEarly")
        Extras.Twoh.ReplayFailed = true
        Extras.Twoh.leaveRealm("Prestige has enough Dio Heaven Ascension kills")
        return
    end
    if inRealm then
        Extras.requestDeepshark("prestige", false)
        Prestige.activeWork = "realm Dio Heaven Ascension"
        Extras.Twoh.prestigeStep(plan.Realm)
        return
    end

    local deepsharkNeeded = plan.Deepshark == true and not inRealm and not dungeonWork
    Extras.requestDeepshark("prestige", deepsharkNeeded)

    if plan.Boss then
        Prestige.activeWork = "boss " .. tostring(plan.BossTarget)
    elseif dungeonWork then
        Prestige.activeWork = "dungeon " .. tostring(dungeonWork.Key)
    elseif realmMode then
        Prestige.activeWork = "realm Dio Heaven Ascension"
    elseif deepsharkNeeded then
        Prestige.activeWork = "boss " .. Extras.DeepsharkName
    elseif plan.Material then
        Prestige.activeWork = "item " .. tostring(plan.Material.Name)
    else
        Prestige.activeWork = nil
    end

    if plan.Boss then
        if acquireMovement("prestige") then
            Prestige.handleBossRequirement(plan.Boss, plan.BossTarget)
            releaseMovement("prestige")
        else
            State.PrestigeStatus = "Boss " .. plan.BossTarget .. " pending | waiting for " .. tostring(Extras.PriorityRequest or movementOwner) .. " to finish"
            task.wait(0.3)
        end
    elseif dungeonWork then
        Prestige.enterDungeon(dungeonWork)
    elseif realmMode == "drive" then
        Extras.Twoh.prestigeStep(plan.Realm)
    elseif realmMode == "twoh" then
        State.PrestigeStatus = string.format("Prestige: Dio Heaven Ascension %d/%d | waiting for Auto TWOH realm runs | %s", math.floor(plan.Realm.Current), math.floor(plan.Realm.Needed), tostring(State.ExtraStatus))
        task.wait(1)
    elseif plan.Material then
        local materialRequirement = plan.Material
        State.PrestigeStatus = string.format("Prestige Item: %s (%d/%d) | %s", tostring(materialRequirement.Name), math.floor(materialRequirement.Current), math.floor(materialRequirement.Needed), describeMaterialPlan(materialRequirement.Name))
        if acquireMovement("prestige") then
            UnlockFarm.gatherMaterial(materialRequirement.Name, materialRequirement.Needed, materialRequirement.Current, nil, "prestige")
            releaseMovement("prestige")
        else
            task.wait(0.3)
        end
    elseif plan.Level then
        local levelRequirement = plan.Level
        local otherMode = Prestige.getOtherFarmMode()
        if otherMode then
            State.PrestigeStatus = otherMode .. " is running | prestige waits for " .. string.format("%s %d/%d", tostring(levelRequirement.Label), math.floor(levelRequirement.Current), math.floor(levelRequirement.Needed)) .. Prestige.ParkedSuffix
            task.wait(0.5)
        elseif acquireMovement("prestige") then
            Prestige.handleLevelRequirement(levelRequirement)
            releaseMovement("prestige")
        else
            task.wait(0.3)
        end
    else
        local parts = {}
        if deepsharkNeeded then
            table.insert(parts, "needs " .. Extras.DeepsharkName .. " | running Auto Ancient Deepshark | " .. tostring(State.ExtraStatus))
        end
        for _, work in ipairs(blockedWorks) do
            table.insert(parts, Prestige.blockedText(work))
        end
        if realmSkip then
            table.insert(parts, "Dio Heaven Ascension kills: " .. realmSkip .. " | skipping")
        end
        for _, bossName in ipairs(plan.Waiting) do
            table.insert(parts, "waiting for " .. bossName .. " to spawn (world spawn, not summonable, in no dungeon)")
        end
        if not deepsharkNeeded then
            Prestige.Idle = true
            Prestige.activeWork = nil
            Prestige.priorityRequest = false
            Prestige.DungeonWork = nil
            prestigeActive = false
            releaseMovement("prestige")
        end
        if #parts == 0 and #plan.Parked > 0 then
            local labels = {}
            for _, req in ipairs(plan.Parked) do
                table.insert(labels, Prestige.ParkedTypes[req.Type])
            end
            State.PrestigeStatus = string.format("Prestige %d waiting: only %s left (skipped, do it manually)", math.floor(getDataValue("Prestige")) + 1, table.concat(labels, " and "))
        else
            if #parts == 0 then
                table.insert(parts, "missing: " .. missingText)
            end
            State.PrestigeStatus = "Prestige: " .. table.concat(parts, " || ") .. Prestige.ParkedSuffix
        end
        task.wait(1)
    end
end

function Prestige.Start()
    if State.PrestigeEnabled then
        return
    end

    State.PrestigeEnabled = true
    Prestige.priorityRequest = false
    Prestige.remoteFailures = 0
    Prestige.hookSignals()

    prestigeThread = task.spawn(function()
        while State.PrestigeEnabled do
            task.wait(0.1)
            local ok, stepError = pcall(Prestige.step)
            if not ok then
                releaseMovement("prestige")
                Extras.Twoh.releaseRealm("prestige")
                State.PrestigeStatus = "Prestige error: " .. tostring(stepError) .. " | retrying in 3s"
                task.wait(3)
            end
        end

        Prestige.priorityRequest = false
        Prestige.activeWork = nil
        Prestige.DungeonWork = nil
        prestigeActive = false
        releaseMovement("prestige")
        Extras.Twoh.releaseRealm("prestige")
        Prestige.restoreHelper()
    end)
end

function Prestige.step()
    local _, playerHumanoid = getRoot()
    if not playerHumanoid or playerHumanoid.Health <= 0 then
        State.PrestigeStatus = "Prestige: dead | waiting for respawn" .. (Prestige.DungeonWork and (" | " .. tostring(Prestige.DungeonWork)) or "")
        task.wait(0.5)
        return
    end
    local progress, failureReason = Prestige.getRequirementProgress()

    if not progress then
        Prestige.Idle = true
        releaseMovement("prestige")
        Prestige.priorityRequest = false
        Prestige.activeWork = nil
        Prestige.DungeonWork = nil
        State.PrestigeStatus = failureReason or "Cannot load prestige requirements"
        State.PrestigeMissing = tostring(failureReason)
        task.wait(1)
        return
    end

    local missingText = Prestige.describeMissing(progress)

    if missingText ~= "" then
        State.PrestigeMissing = missingText
        Prestige.priorityRequest = false
        Prestige.handleMissing(progress, missingText)
        return
    end

    Prestige.Idle = false
    Extras.requestDeepshark("prestige", false)
    Extras.Twoh.releaseRealm("prestige")
    Prestige.DungeonWork = nil
    State.PrestigeMissing = "none (ready)"
    Prestige.priorityRequest = true
    Prestige.activeWork = "prestige"
    local success = false
    local insideDungeon = typeof(workspaceService:GetAttribute("Dungeon")) == "string"

    if (Prestige.remoteFailures or 0) < 3 or (insideDungeon and os.clock() - (Prestige.LeaveSentAt or 0) > 15) then
        State.PrestigeStatus = "Requirements met | prestiging via remote"
        success = Prestige.tryRemote()
        if not success then
            Prestige.remoteFailures = (Prestige.remoteFailures or 0) + 1
        end
    end

    if not success and insideDungeon then
        Prestige.leaveDungeon("requirements met | leaving to prestige on the main map")
    elseif not success then
        if acquireMovement("prestige") then
            State.PrestigeStatus = "Remote refused | going to " .. prestigeNPCName
            success = Prestige.travelAndPrestige(true)
            releaseMovement("prestige")
            settleCharacter()
        else
            State.PrestigeStatus = "Ready to prestige, waiting for " .. tostring(Extras.PriorityRequest or movementOwner) .. " to finish"
        end
    end

    if success then
        Prestige.remoteFailures = 0
        Prestige.priorityRequest = false
        Prestige.activeWork = nil
        State.PrestigeStatus = "Prestige " .. tostring(Prestige.getCurrentValue()) .. " complete!"
        Prestige.refreshLive()
    end
    task.wait(0.5)
end

function Prestige.Stop()
    State.PrestigeEnabled = false
    Prestige.Idle = false
    State.PrestigeStatus = "Idle"
    Extras.requestDeepshark("prestige", false)
    Prestige.priorityRequest = false
    Prestige.activeWork = nil
    for _, connection in ipairs(getgenv().HubPrestigeConnections or {}) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    getgenv().HubPrestigeConnections = {}
    local wasTravelling = prestigeActive or movementOwner == "prestige"
    prestigeActive = false
    travelActive = false
    lockedTargetCFrame = nil
    Prestige.DungeonWork = nil
    releaseMovement("prestige")
    if prestigeThread then
        task.cancel(prestigeThread)
        prestigeThread = nil
    end
    if Extras.Twoh.Delegated and not State.AutoTwohEnabled then
        wasTravelling = true
        Extras.clearCombatLocks()
    end
    Extras.Twoh.releaseRealm("prestige")
    Prestige.restoreHelper()
    if Extras.PortalReplyConnection then
        pcall(function()
            Extras.PortalReplyConnection:Disconnect()
        end)
        Extras.PortalReplyConnection = nil
    end
    if wasTravelling then
        stopTween()
        removeFloat(getRoot())
    end
end

local unlockFarmThread = nil
local unlockFailureCount = 0

function UnlockFarm.getCatalog(categoryName)
    local list = {}
    for itemName, itemInfo in pairs(itemData) do
        if typeof(itemInfo) == "table" and itemInfo.Type == categoryName and toolData[itemName] then
            table.insert(list, itemName)
        end
    end
    table.sort(list)
    return list
end

function UnlockFarm.isOwned(itemName)
    return getInventoryAmount(itemName) > 0
end

function UnlockFarm.getMissing(categoryName)
    local missing = {}
    for _, itemName in ipairs(UnlockFarm.getCatalog(categoryName)) do
        if not UnlockFarm.isOwned(itemName) then
            table.insert(missing, itemName)
        end
    end
    return missing
end

function UnlockFarm.isQuestCompleted(questName)
    local dataFolder = localPlayer:FindFirstChild("Data")
    local questsFolder = dataFolder and dataFolder:FindFirstChild("Quests")
    local completedFolder = questsFolder and questsFolder:FindFirstChild("Completed")
    return completedFolder ~= nil and completedFolder:FindFirstChild(questName) ~= nil
end

function UnlockFarm.getActiveQuestFolder(questName)
    local dataFolder = localPlayer:FindFirstChild("Data")
    local questsFolder = dataFolder and dataFolder:FindFirstChild("Quests")
    local mainFolder = questsFolder and questsFolder:FindFirstChild("Main")
    return mainFolder and mainFolder:FindFirstChild(questName)
end

function UnlockFarm.isQuestReadyToClaim(questName)
    local questFolder = UnlockFarm.getActiveQuestFolder(questName)
    local completedValue = questFolder and questFolder:FindFirstChild("Completed")
    return completedValue ~= nil and completedValue.Value == true
end

function UnlockFarm.getChainForQuest(questName)
    local chain = {}
    local cursor = questName
    local guard = 0

    while cursor and questData.Main[cursor] and guard < 16 do
        table.insert(chain, 1, cursor)
        guard = guard + 1
        local requirements = questData.Main[cursor].Requirements
        cursor = requirements and requirements.Quest
    end

    return chain
end

function UnlockFarm.getQuestChainForItem(itemName)
    local normalizedItem = normalizeName(itemName)
    local endpoints = {}

    for questName, questInfo in pairs(questData.Main) do
        local rewardItems = questInfo.Rewards and questInfo.Rewards.Items
        local normalizedQuest = normalizeName(questName)

        local isMatch = (rewardItems ~= nil and rewardItems[itemName] ~= nil)
            or (#normalizedItem > 2 and string.find(normalizedQuest, normalizedItem, 1, true) == 1)

        if isMatch then
            table.insert(endpoints, questName)
        end
    end

    table.sort(endpoints)

    local ordered = {}
    local seen = {}

    for _, questName in ipairs(endpoints) do
        for _, chainQuest in ipairs(UnlockFarm.getChainForQuest(questName)) do
            if not seen[chainQuest] then
                seen[chainQuest] = true
                table.insert(ordered, chainQuest)
            end
        end
    end

    return ordered
end

function UnlockFarm.getNextIncomplete(chain)
    for _, questName in ipairs(chain) do
        if not UnlockFarm.isQuestCompleted(questName) then
            return questName
        end
    end
    return nil
end

function UnlockFarm.getMobAnchor(mobName)
    return getMobAnchor(mobName)
end

function UnlockFarm.farmMob(mobName, isActiveCondition, allowBoss)
    return farmMobWithAnchor(mobName, isActiveCondition, allowBoss)
end

function UnlockFarm.getMissingRequirements(recipe)
    local missing = {}
    for materialName, neededAmount in pairs(recipe.Requirement) do
        local currentAmount = getInventoryAmount(materialName)
        if currentAmount < neededAmount then
            table.insert(missing, {
                Item = materialName,
                Needed = neededAmount,
                Current = currentAmount
            })
        end
    end

    table.sort(missing, function(a, b)
        return a.Item < b.Item
    end)

    return missing
end

function UnlockFarm.getActionableRequirement(recipe)
    local missing = UnlockFarm.getMissingRequirements(recipe)
    if #missing == 0 then
        return nil, missing
    end

    for _, entry in ipairs(missing) do
        local plan = getMaterialPlan(entry.Item)
        if plan.Kind ~= "none" and plan.Kind ~= "shopLocked" and plan.Kind ~= "event" then
            entry.Plan = plan
            return entry, missing
        end
    end

    for _, entry in ipairs(missing) do
        local plan = getMaterialPlan(entry.Item)
        if plan.Kind == "event" then
            entry.Plan = plan
            return entry, missing
        end
    end

    return nil, missing
end

function UnlockFarm.getObjectives(questInfo)
    if typeof(questInfo.Objectives) == "table" then
        return questInfo.Objectives
    end

    if typeof(questInfo.Checklist) == "table" then
        return questInfo.Checklist
    end

    if typeof(questInfo.Goal) == "table" then
        return { questInfo.Goal }
    end

    return {}
end

function UnlockFarm.isObjectiveDone(objective)
    if objective.Type == "Obtain" and objective.Target then
        return getInventoryAmount(objective.Target) >= (objective.Amount or 1)
    end
    return false
end

function UnlockFarm.getGrindMobName()
    local currentLevel = getPlayerLevel()
    local bestMob = nil
    local highestMin = -1

    for questName, questInfo in pairs(questData.Main) do
        if string.find(questName, "^Quest%s") and typeof(questInfo.LevelRanging) == "table" then
            local minLevel = questInfo.LevelRanging[1] or 0
            local goalTarget = questInfo.Goal and questInfo.Goal.Target
            if currentLevel >= minLevel and minLevel > highestMin and typeof(goalTarget) == "string" then
                highestMin = minLevel
                bestMob = goalTarget
            end
        end
    end

    return bestMob
end

function UnlockFarm.getMaterialMob(materialName)
    local source = pickMaterialSource(materialName)
    return source and source.Name
end

function UnlockFarm.resolveMobName(questInfo, objective)
    local objectiveType = tostring(objective.Type)

    if string.find(objectiveType, "Kill", 1, true) then
        if typeof(objective.Target) == "string" then
            return objective.Target
        end
        if typeof(objective.Targets) == "table" and typeof(objective.Targets[1]) == "string" then
            return objective.Targets[1]
        end
    end

    if objectiveType == "Obtain" and typeof(objective.Target) == "string" then
        local materialMob = UnlockFarm.getMaterialMob(objective.Target)
        if materialMob then
            return materialMob
        end
    end

    local label = objective.Label
    if typeof(label) == "string" then
        local inside = string.match(label, "%(([^%)]+)%)")
        if inside and not string.find(string.lower(inside), "equipped", 1, true) then
            return inside
        end
    end

    if typeof(questInfo.Name) == "string" then
        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            if #enemy.Name > 3 and string.find(questInfo.Name, enemy.Name, 1, true) then
                return enemy.Name
            end
        end
    end

    if objectiveType == "Obtain" then
        return UnlockFarm.getGrindMobName()
    end

    return nil
end

function UnlockFarm.acceptQuest(questName)
    local questInfo = questData.Main[questName]
    if not questInfo then
        return false
    end

    local targetNPC = getQuestNPC(questInfo.NPC or questName)

    if targetNPC then
        local reached = travelToNPC(targetNPC, function()
            return isFarmActive() and UnlockFarm.getActiveQuestFolder(questName) == nil
        end)

        if not reached then
            lockedTargetCFrame = nil
            setNPCCooldown(targetNPC.Name, 15)
            State.UnlockStatus = "Cannot reach NPC for " .. questName
            return false
        end
    end

    invokeInput("Quest", "Accept", targetNPC, questName)
    task.wait(0.6)

    if UnlockFarm.getActiveQuestFolder(questName) then
        lockedTargetCFrame = nil
        return true
    end

    if targetNPC then
        talkToNPC(targetNPC, "Accept", function()
            return UnlockFarm.getActiveQuestFolder(questName) ~= nil
        end, 8)
    end

    lockedTargetCFrame = nil
    return UnlockFarm.getActiveQuestFolder(questName) ~= nil
end

function UnlockFarm.claimQuest(questName)
    local questInfo = questData.Main[questName]
    local targetNPC = questInfo and getQuestNPC(questInfo.NPC or questName)

    if targetNPC then
        local reached = travelToNPC(targetNPC, function()
            return isFarmActive()
        end)

        if not reached then
            lockedTargetCFrame = nil
            setNPCCooldown(targetNPC.Name, 15)
            State.UnlockStatus = "Cannot reach NPC to claim " .. questName
            return false
        end
    end

    invokeInput("Quest", "Claim", questName)
    task.wait(0.8)

    if UnlockFarm.isQuestCompleted(questName) then
        lockedTargetCFrame = nil
        return true
    end

    if targetNPC then
        talkToNPC(targetNPC, "Claim", function()
            return UnlockFarm.isQuestCompleted(questName)
        end, 8)
    end

    lockedTargetCFrame = nil
    return UnlockFarm.isQuestCompleted(questName)
end

function UnlockFarm.describeGate(recipe)
    if typeof(recipe.Gate) ~= "table" then
        return nil
    end

    local parts = {}
    for gateKey, gateValue in pairs(recipe.Gate) do
        table.insert(parts, tostring(gateKey) .. " " .. tostring(gateValue))
    end
    table.sort(parts)

    if #parts == 0 then
        return nil
    end

    return table.concat(parts, ", ")
end

function UnlockFarm.buyItem(itemName, recipe)
    local cooldown = getNPCCooldown(recipe.NPC)
    if cooldown > 0 then
        State.UnlockStatus = itemName .. " | " .. recipe.NPC .. " retry in " .. tostring(math.ceil(cooldown)) .. "s"
        task.wait(1)
        return false
    end

    local targetNPC = findNPCByName(recipe.NPC)
    if not targetNPC then
        State.UnlockStatus = "NPC " .. tostring(recipe.NPC) .. " not found"
        setNPCCooldown(recipe.NPC, 20)
        return false
    end

    setTargetBox(nil)
    lockedEnemyRoot = nil
    lastKnownMobCFrame = nil

    State.UnlockStatus = "Going to " .. recipe.NPC .. " for " .. itemName
    local reached = travelToNPC(targetNPC, function()
        return State.UnlockEnabled and not UnlockFarm.isOwned(itemName)
    end)

    if not reached then
        lockedTargetCFrame = nil
        State.UnlockStatus = "Cannot reach " .. recipe.NPC .. " | retry later"
        setNPCCooldown(recipe.NPC, 20)
        return false
    end

    State.UnlockStatus = "Talking to " .. recipe.NPC .. " for " .. itemName
    local opened, finished = talkToNPC(targetNPC, recipe.ChoiceText, function()
        return UnlockFarm.isOwned(itemName)
    end, 12)

    if UnlockFarm.isOwned(itemName) then
        lockedTargetCFrame = nil
        return true
    end

    if not opened then
        State.UnlockStatus = "Dialogue did not open at " .. recipe.NPC
    elseif not finished then
        State.UnlockStatus = "Dialogue choice unresolved at " .. recipe.NPC
    end

    invokeInput("Shop", targetNPC, itemName)
    task.wait(1.2)
    confirmDialogue(2)
    task.wait(0.6)

    lockedTargetCFrame = nil

    if UnlockFarm.isOwned(itemName) then
        return true
    end

    local gateText = UnlockFarm.describeGate(recipe)
    if gateText then
        State.UnlockStatus = itemName .. " blocked by gate: " .. gateText
        setNPCCooldown(recipe.NPC, 60)
    else
        State.UnlockStatus = itemName .. " purchase rejected | money " .. tostring(math.floor(getMoney()))
        setNPCCooldown(recipe.NPC, 30)
    end

    return false
end

function UnlockFarm.progressQuest(questName)
    if UnlockFarm.isQuestReadyToClaim(questName) then
        State.UnlockStatus = "Claiming " .. questName
        setTargetBox(nil)
        lockedEnemyRoot = nil
        lastKnownMobCFrame = nil

        if UnlockFarm.claimQuest(questName) then
            unlockFailureCount = 0
        else
            unlockFailureCount = unlockFailureCount + 1
            task.wait(2)
        end
        return
    end

    if not UnlockFarm.getActiveQuestFolder(questName) then
        State.UnlockStatus = "Accepting " .. questName
        setTargetBox(nil)
        lockedEnemyRoot = nil
        lastKnownMobCFrame = nil

        if UnlockFarm.acceptQuest(questName) then
            unlockFailureCount = 0
        else
            unlockFailureCount = unlockFailureCount + 1
            task.wait(2)
        end
        return
    end

    UnlockFarm.driveQuest(questName)
end

function UnlockFarm.driveQuest(questName)
    local questInfo = questData.Main[questName]
    if not questInfo then
        return
    end

    if questInfo.RequireEquipped then
        equipInventoryItem(questInfo.RequireEquipped)
    end

    local pendingObjective = nil
    for _, objective in ipairs(UnlockFarm.getObjectives(questInfo)) do
        if not UnlockFarm.isObjectiveDone(objective) then
            pendingObjective = objective
            break
        end
    end

    if not pendingObjective then
        State.UnlockStatus = "Waiting for " .. questName .. " to complete"
        task.wait(0.5)
        return
    end

    if pendingObjective.Type == "Obtain" and typeof(pendingObjective.Target) == "string" then
        local worldPickup = findPickupByName(pendingObjective.Target)
        if worldPickup then
            local questOwner = movementOwner or "unlock"
            setFarmStatus("Collecting " .. pendingObjective.Target .. " drop")
            releaseMovement(questOwner)
            collectPickup(worldPickup, function()
                return isFarmActive()
            end)
            reacquireMovement(questOwner)
            return
        end
    end

    local mobName = UnlockFarm.resolveMobName(questInfo, pendingObjective)
    if not mobName then
        setFarmStatus("Unsupported objective in " .. questName)
        task.wait(2)
        return
    end

    setFarmStatus("Quest " .. questName .. " | farming " .. mobName)
    UnlockFarm.farmMob(mobName, function()
        return isFarmActive() and not UnlockFarm.isQuestReadyToClaim(questName)
    end, isKnownBossName(mobName))
end

function UnlockFarm.gatherMaterial(materialName, neededAmount, currentAmount, plan, ownerName)
    ownerName = ownerName or "unlock"
    local ownerCheck = movementOwnerActiveCheck[ownerName] or function()
        return State.UnlockEnabled
    end
    local activePlan = plan or getMaterialPlan(materialName)
    local shortage = math.max(math.floor((neededAmount or 1) - (currentAmount or 0)), 1)

    if materialName == "Meteor Fragment" then
        local rootPart = getRoot()
        local currentIsland = rootPart and getNearestIslandName(rootPart.Position)
        if currentIsland ~= "Legacy Island" then
            setFarmStatus("Warping to Legacy Island for Meteor Shower")
            local arrived = teleportToIsland("Legacy Island")
            if not arrived then
                local tatsumakiNPC = findNPCByName("Tatsumaki")
                if tatsumakiNPC then
                    travelToNPC(tatsumakiNPC, function()
                        return ownerCheck() and getInventoryAmount(materialName) < neededAmount
                    end)
                end
            end
            task.wait(1)
            return
        end

        local worldPickup = findPickupByName("Meteor Fragment")
        if worldPickup then
            setFarmStatus(string.format("%s %d/%d | collecting meteor drop", materialName, currentAmount, neededAmount))
            releaseMovement(ownerName)
            collectPickup(worldPickup, function()
                return ownerCheck() and getInventoryAmount(materialName) < neededAmount
            end)
            reacquireMovement(ownerName)
            return
        end

        local meteorPrompt = nil
        local spawnsFolder = extraFolder:FindFirstChild("Spawns") and extraFolder.Spawns:FindFirstChild("Meteors")
        if spawnsFolder then
            for _, spawnPoint in ipairs(spawnsFolder:GetChildren()) do
                local prompt = spawnPoint:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and prompt.Enabled then
                    meteorPrompt = prompt
                    break
                end
            end
        end
        if meteorPrompt then
            setFarmStatus(string.format("%s %d/%d | mining fallen meteor", materialName, currentAmount, neededAmount))
            local standCFrame = CFrame.new(meteorPrompt.Parent.Position + Vector3.new(0, 4, 3))
            safeTravelTo(standCFrame, function()
                return ownerCheck() and meteorPrompt.Enabled
            end)
            triggerPrompt(meteorPrompt)
            task.wait(0.5)
            return
        end

        local tatsumakiNPC = findNPCByName("Tatsumaki")
        local waitCFrame = tatsumakiNPC and computeTalkCFrame(tatsumakiNPC) or CFrame.new(-75.7, 52, 129.1)
        if rootPart and (rootPart.Position - waitCFrame.Position).Magnitude > 25 then
            safeTravelTo(waitCFrame, function()
                return ownerCheck() and getInventoryAmount(materialName) < neededAmount
            end)
        else
            holdPosition(waitCFrame)
        end
        setFarmStatus(string.format("Tatsumaki | waiting on Legacy Island for Meteor Shower (%d/%d)", currentAmount, neededAmount))
        task.wait(2)
        return
    end

    if activePlan.Kind == "pickup" then
        local worldPickup = findPickupByName(materialName)
        if worldPickup then
            setFarmStatus(string.format("%s %d/%d | collecting world drop", materialName, currentAmount, neededAmount))
            releaseMovement(ownerName)
            collectPickup(worldPickup, function()
                return ownerCheck() and getInventoryAmount(materialName) < neededAmount
            end)
            reacquireMovement(ownerName)
            return
        end
    end

    if activePlan.Kind == "shop" then
        setFarmStatus(string.format("%s %d/%d | buying from shard shop", materialName, currentAmount, neededAmount))
        if buyFromMaterialShop(materialName, shortage) then
            return
        end
        task.wait(0.6)
        return
    end

    if activePlan.Kind == "gate" then
        local gateQuest = activePlan.Quest
        local nextGateQuest = UnlockFarm.getNextIncomplete(UnlockFarm.getChainForQuest(gateQuest)) or gateQuest
        setFarmStatus("Gate quest " .. nextGateQuest .. " for " .. materialName)
        UnlockFarm.progressQuest(nextGateQuest)
        return
    end

    if activePlan.Kind == "boss" then
        setFarmStatus(string.format("%s %d/%d | boss %s", materialName, currentAmount, neededAmount, tostring(activePlan.Mob)))
        BossFarm.prepareAndKill(activePlan.Summon, function()
            return ownerCheck() and getInventoryAmount(materialName) < neededAmount
        end, ownerName)
        return
    end

    if activePlan.Kind == "mob" then
        setFarmStatus(string.format("%s %d/%d from %s", materialName, currentAmount, neededAmount, tostring(activePlan.Mob)))
        UnlockFarm.farmMob(activePlan.Mob, function()
            return ownerCheck() and getInventoryAmount(materialName) < neededAmount
        end, isKnownBossName(activePlan.Mob))
        return
    end

    if activePlan.Kind == "event" then
        local rootPart = getRoot()
        if rootPart and getTargetEnemy(activePlan.Mob, rootPart.Position, true) then
            setFarmStatus(string.format("%s %d/%d | event target %s is up", materialName, currentAmount, neededAmount, tostring(activePlan.Mob)))
            UnlockFarm.farmMob(activePlan.Mob, function()
                return ownerCheck() and getInventoryAmount(materialName) < neededAmount
            end, true)
            return
        end

        setFarmStatus(string.format("%s %d/%d | waiting for event target %s", materialName, currentAmount, neededAmount, tostring(activePlan.Mob)))
        task.wait(4)
        return
    end

    if activePlan.Kind == "shopLocked" then
        setFarmStatus(string.format("%s %d/%d | need %d shards (have %d)", materialName, currentAmount, neededAmount, activePlan.Shop.Cost, math.floor(getShards())))
        task.wait(2)
        return
    end

    if activePlan.Kind == "craft" then
        local recipe = activePlan.Recipe
        local actionable, missing = UnlockFarm.getActionableRequirement(recipe)
        if actionable then
            UnlockFarm.gatherMaterial(actionable.Item, actionable.Needed, actionable.Current, actionable.Plan, ownerName)
            return
        end
        if #missing > 0 then
            local parts = {}
            for _, entry in ipairs(missing) do
                table.insert(parts, string.format("%s %d/%d", entry.Item, math.floor(entry.Current), math.floor(entry.Needed)))
            end
            setFarmStatus(materialName .. " waiting | " .. table.concat(parts, ", "))
            task.wait(3)
            return
        end
        if recipe.Money and getMoney() < recipe.Money then
            setFarmStatus(string.format("%s | need $%d (have $%d)", materialName, recipe.Money, math.floor(getMoney())))
            task.wait(3)
            return
        end
        setFarmStatus("Crafting " .. materialName .. " at " .. tostring(recipe.NPC))
        UnlockFarm.buyItem(materialName, recipe)
        return
    end

    setFarmStatus(string.format("%s %d/%d | no known source", materialName, currentAmount, neededAmount))
    task.wait(3)
end

function UnlockFarm.runTarget(targetItem)
    if UnlockFarm.isOwned(targetItem) then
        State.UnlockStatus = targetItem .. " already unlocked"
        setTargetBox(nil)
        lockedEnemyRoot = nil
        lockedTargetCFrame = nil
        task.wait(1.5)
        return
    end

    if targetItem == "Tatsumaki" or targetItem == "Storm Esper" then
        local rootPart = getRoot()
        local currentIsland = rootPart and getNearestIslandName(rootPart.Position)
        if currentIsland ~= "Legacy Island" and getInventoryAmount("Meteor Fragment") < 15 then
            State.UnlockStatus = "Warping to Legacy Island for Tatsumaki"
            local arrived = teleportToIsland("Legacy Island")
            if not arrived then
                local tatsumakiNPC = findNPCByName("Tatsumaki")
                if tatsumakiNPC then
                    travelToNPC(tatsumakiNPC, function()
                        return State.UnlockEnabled and not UnlockFarm.isOwned(targetItem)
                    end)
                end
            end
        end
    end

    local nextQuest = UnlockFarm.getNextIncomplete(UnlockFarm.getQuestChainForItem(targetItem))
    local recipe = unlockRecipes[targetItem]

    if recipe and recipe.FightBoss then
        local rootPart = getRoot()
        local fightTarget = rootPart and getTargetEnemy(recipe.FightBoss, rootPart.Position, true)
        if fightTarget then
            setTargetBox(nil)
            State.UnlockStatus = "Fighting " .. fightTarget.Name .. " for " .. targetItem
            UnlockFarm.farmMob(fightTarget.Name, function()
                return State.UnlockEnabled and fightTarget.Parent ~= nil and not UnlockFarm.isOwned(targetItem)
            end, true)
            return
        end
    end

    if nextQuest then
        UnlockFarm.progressQuest(nextQuest)
        return
    end

    if not recipe then
        State.UnlockStatus = "No unlock path found for " .. targetItem
        task.wait(3)
        return
    end

    local actionable, missing = UnlockFarm.getActionableRequirement(recipe)

    if actionable then
        UnlockFarm.gatherMaterial(actionable.Item, actionable.Needed, actionable.Current, actionable.Plan)
        return
    end

    if #missing > 0 then
        local parts = {}
        for _, entry in ipairs(missing) do
            table.insert(parts, string.format("%s %d/%d (%s)", entry.Item, math.floor(entry.Current), math.floor(entry.Needed), describeMaterialPlan(entry.Item)))
        end
        State.UnlockStatus = targetItem .. " waiting | " .. table.concat(parts, ", ")
        task.wait(3)
        return
    end

    State.UnlockStatus = "Buying " .. targetItem .. " from " .. recipe.NPC
    if UnlockFarm.buyItem(targetItem, recipe) then
        unlockFailureCount = 0
        State.UnlockStatus = targetItem .. " unlocked"
    else
        unlockFailureCount = unlockFailureCount + 1
        task.wait(1.5)
    end
end

function UnlockFarm.Start()
    if State.UnlockEnabled then
        return
    end

    State.UnlockEnabled = true
    unlockFailureCount = 0

    unlockFarmThread = task.spawn(function()
        while State.UnlockEnabled do
            task.wait(0.3)

            if Prestige.isHandlingRequirements() then
                State.UnlockStatus = "Paused | Auto Prestige is working on " .. tostring(Prestige.activeWork)
                task.wait(0.5)
            elseif not acquireMovement("unlock") then
                task.wait(0.5)
            else
                local rootPart, playerHumanoid = getRoot()

                if rootPart and playerHumanoid and playerHumanoid.Health > 0 then
                    autoAllocateStats()
                    collectNearbyPickup("unlock")

                    local targetItem = State.UnlockTargets[State.UnlockCategory]

                    if not targetItem then
                        State.UnlockStatus = "No " .. tostring(State.UnlockCategory) .. " target selected"
                        task.wait(1)
                    else
                        UnlockFarm.runTarget(targetItem)
                    end
                end

                releaseMovement("unlock")
            end

            if unlockFailureCount >= 6 then
                State.UnlockStatus = "Paused after repeated failures | " .. tostring(State.UnlockStatus)
                unlockFailureCount = 0
                task.wait(10)
            end
        end

        releaseMovement("unlock")
        settleCharacter()
        lockedEnemyRoot = nil
        lockedTargetCFrame = nil
        lastKnownMobCFrame = nil
        setTargetBox(nil)
    end)
end

function UnlockFarm.Stop()
    State.UnlockEnabled = false
    State.UnlockStatus = "Idle"
    releaseMovement("unlock")
    stopTween()
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    lastKnownMobCFrame = nil
    setTargetBox(nil)
    removeFloat(getRoot())
end

function UnlockFarm.describeTarget(itemName)
    local lines = {}
    if not itemName then
        return { "no target selected" }
    end

    local chain = UnlockFarm.getQuestChainForItem(itemName)

    if #chain > 0 then
        local questStates = {}
        for _, questName in ipairs(chain) do
            local mark = UnlockFarm.isQuestCompleted(questName) and "done" or "todo"
            table.insert(questStates, questName .. "[" .. mark .. "]")
        end
        table.insert(lines, "quests: " .. table.concat(questStates, " > "))
    end

    local recipe = unlockRecipes[itemName]
    if recipe then
        table.insert(lines, "npc: " .. recipe.NPC .. " | choice: " .. tostring(recipe.ChoiceText))
        local gateText = UnlockFarm.describeGate(recipe)
        if gateText then
            table.insert(lines, "gate: " .. gateText)
        end
        for materialName, neededAmount in pairs(recipe.Requirement) do
            table.insert(lines, string.format("%s %d/%d via %s", materialName, math.floor(getInventoryAmount(materialName)), math.floor(neededAmount), describeMaterialPlan(materialName)))
        end
    end

    if #lines == 0 then
        table.insert(lines, "no unlock path found")
    end

    return lines
end

local bossFarmThread = nil

function BossFarm.getSummonEntry(bossName)
    if not bossName then
        return nil
    end

    local direct = summonEntryByName[normalizeName(bossName)]
    if direct then
        return direct
    end

    local normalizedTarget = normalizeName(stripBossTag(bossName))
    local stripped = summonEntryByName[normalizedTarget]
    if stripped then
        return stripped
    end

    for _, item in ipairs(summonCatalog) do
        local normalizedItem = normalizeName(item.Name)
        if #normalizedItem > 3 and (string.find(normalizedTarget, normalizedItem, 1, true) == 1 or string.find(normalizedItem, normalizedTarget, 1, true) == 1) then
            return item
        end
    end

    return nil
end

function BossFarm.resolveBossName(mobName)
    if mobName == "Yhwach (Global Boss)" then
        return "Yhwach"
    end
    if mobName == "Yhwach (Summoned)" or mobName == "Yhwach Not Dungeon" then
        return "Yhwach Not Dungeon"
    end

    local catalogItem = BossFarm.getSummonEntry(mobName)
    if catalogItem then
        return catalogItem.Name
    end

    local normalizedMob = normalizeName(stripBossTag(mobName))
    for _, bossName in ipairs(timedBossNames) do
        if string.find(normalizedMob, normalizeName(bossName), 1, true) == 1 then
            return bossName
        end
    end

    for _, bossName in ipairs(fieldBossNames) do
        if string.find(normalizedMob, normalizeName(bossName), 1, true) == 1 then
            return bossName
        end
    end

    return mobName
end

function BossFarm.getDifficulty(entry)
    local enabled = true
    pcall(function()
        enabled = summonBossData.difficultyEnabled(entry) ~= false
    end)

    if not enabled then
        return nil
    end

    local resolved = State.BossDifficulty or "Normal"
    pcall(function()
        resolved = summonDifficultyData.resolve(State.BossDifficulty) or resolved
    end)

    return resolved
end

function BossFarm.getSummonShortfall(catalogItem)
    local entry = catalogItem.Entry
    local difficulty = BossFarm.getDifficulty(entry)
    local shortfalls = {}

    if entry.RequiredQuest and not UnlockFarm.isQuestCompleted(entry.RequiredQuest) then
        table.insert(shortfalls, { Kind = "quest", Item = entry.RequiredQuest, Have = 0, Need = 1 })
    end

    local ticketsNeeded = entry.Tickets or 0
    pcall(function()
        ticketsNeeded = summonBossData.ticketCost(entry, difficulty) or ticketsNeeded
    end)
    local ticketItem = entry.TicketItem or "Boss Ticket"
    local ticketsHave = getInventoryAmount(ticketItem)
    if ticketsHave < ticketsNeeded then
        table.insert(shortfalls, { Kind = "item", Item = ticketItem, Have = ticketsHave, Need = ticketsNeeded })
    end

    local moneyNeeded = entry.Money or 0
    pcall(function()
        moneyNeeded = summonBossData.moneyCost(entry, difficulty) or moneyNeeded
    end)
    if getMoney() < moneyNeeded then
        table.insert(shortfalls, { Kind = "money", Item = "Money", Have = getMoney(), Need = moneyNeeded })
    end

    if typeof(entry.Extra) == "table" then
        for _, extra in ipairs(entry.Extra) do
            local extraNeeded = extra.Amount or 1
            pcall(function()
                extraNeeded = summonBossData.extraCost(entry, extra.Amount, difficulty) or extraNeeded
            end)
            local extraHave = getInventoryAmount(extra.Item)
            if extraHave < extraNeeded then
                table.insert(shortfalls, { Kind = "item", Item = extra.Item, Have = extraHave, Need = extraNeeded })
            end
        end
    end

    return shortfalls
end

function BossFarm.describeShortfall(shortfalls)
    local parts = {}
    for _, entry in ipairs(shortfalls) do
        if entry.Kind == "quest" then
            table.insert(parts, "quest " .. tostring(entry.Item))
        else
            table.insert(parts, string.format("%s %d/%d", tostring(entry.Item), math.floor(entry.Have), math.floor(entry.Need)))
        end
    end
    return table.concat(parts, ", ")
end

function BossFarm.isBossAlive(bossName)
    local rootPart = getRoot()
    local origin = rootPart and rootPart.Position or Vector3.zero
    if bossName == "Yhwach (Global Boss)" or bossName == "Yhwach" then
        return getTargetEnemy("Yhwach", origin, true) ~= nil
    end
    if bossName == "Yhwach (Summoned)" or bossName == "Yhwach Not Dungeon" then
        if Extras.Yhwach and Extras.Yhwach.findKing() then
            return true
        end
        return getTargetEnemy("Yhwach Not Dungeon", origin, true) ~= nil
    end
    return getTargetEnemy(bossName, origin, true) ~= nil
end

function BossFarm.getAltarOccupant(npcName)
    if not npcName then
        return nil
    end

    local bossesForNpc = (summonBossData and summonBossData.npcBosses and summonBossData.npcBosses[npcName])
    if not bossesForNpc or #bossesForNpc == 0 then
        bossesForNpc = {}
        for bName, nName in pairs(summonNpcByBoss) do
            if nName == npcName then
                table.insert(bossesForNpc, bName)
            end
        end
    end

    local rootPart = getRoot()
    local origin = rootPart and rootPart.Position or Vector3.zero

    for _, bName in ipairs(bossesForNpc) do
        local enemy = getTargetEnemy(bName, origin, true)
        if enemy then
            local alive, enemyRoot = isLivingEnemy(enemy)
            if alive and enemyRoot then
                return bName, enemy
            end
        end
    end

    local summonNPC = findNPCByName(npcName)
    local npcPos = summonNPC and summonNPC:GetPivot().Position

    if enemiesFolder then
        for _, enemy in ipairs(enemiesFolder:GetChildren()) do
            local alive, enemyRoot = isLivingEnemy(enemy)
            if alive and enemyRoot then
                local strippedName = stripBossTag(enemy.Name)
                local normEnemy = normalizeName(strippedName)
                for _, bName in ipairs(bossesForNpc) do
                    if normEnemy == normalizeName(bName) then
                        return bName, enemy
                    end
                end
                local isBossEnemy = isKnownBossName(strippedName) or summonEntryByName[normEnemy] ~= nil
                if isBossEnemy and npcPos and (enemyRoot.Position - npcPos).Magnitude <= 350 then
                    return strippedName, enemy
                end
            end
        end
    end

    return nil
end

function BossFarm.getSelectedBosses()
    local selected = {}
    for bossName, enabled in pairs(State.BossSelection) do
        if enabled then
            table.insert(selected, bossName)
        end
    end
    table.sort(selected)
    return selected
end

function BossFarm.getPrestigeBossTargets()
    local targets = {}
    local progress = Prestige.getRequirementProgress()
    if not progress then
        return targets
    end

    for _, entry in ipairs(progress) do
        if not entry.Done then
            if entry.Type == "Material" and entry.Name then
                local source = pickMaterialSource(entry.Name)
                if source then
                    targets[BossFarm.resolveBossName(source.Name)] = true
                end
            else
                local mappedBoss = prestigeKillBossMap[entry.Type]
                if mappedBoss then
                    targets[mappedBoss] = true
                end
            end
        end
    end

    return targets
end

function BossFarm.getActiveTargets()
    local active = {}
    local seen = {}

    for _, bossName in ipairs(BossFarm.getSelectedBosses()) do
        if not seen[bossName] then
            seen[bossName] = true
            table.insert(active, bossName)
        end
    end

    if State.PrestigeBossAutoTarget then
        local prestigeTargets = BossFarm.getPrestigeBossTargets()
        local sortedNames = {}
        for bossName in pairs(prestigeTargets) do
            table.insert(sortedNames, bossName)
        end
        table.sort(sortedNames)
        for _, bossName in ipairs(sortedNames) do
            if not seen[bossName] then
                seen[bossName] = true
                table.insert(active, bossName)
            end
        end
    end

    return active
end

function BossFarm.hookBossEvents()
    if not eventsFolder then
        return
    end

    for _, connection in ipairs(bossEventConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    bossEventConnections = {}

    local function recordAlert(sourceName, ...)
        local args = { ... }
        local alert = { Source = sourceName, Time = os.clock(), Name = nil, Position = nil }

        for _, value in ipairs(args) do
            if typeof(value) == "string" and not alert.Name then
                alert.Name = value
            elseif typeof(value) == "Vector3" then
                alert.Position = value
            elseif typeof(value) == "CFrame" then
                alert.Position = value.Position
            elseif typeof(value) == "Instance" then
                local pivotOk, pivot = pcall(function()
                    return value:GetPivot()
                end)
                if pivotOk then
                    alert.Position = pivot.Position
                end
                if not alert.Name then
                    alert.Name = value.Name
                end
            elseif typeof(value) == "table" then
                alert.Name = alert.Name or value.Name or value.Boss or value.BossName
                local tablePosition = value.Position or value.CFrame
                if typeof(tablePosition) == "Vector3" then
                    alert.Position = tablePosition
                elseif typeof(tablePosition) == "CFrame" then
                    alert.Position = tablePosition.Position
                end
            end
        end

        lastBossAlert = alert
        State.BossStatus = "Boss alert: " .. tostring(alert.Name or sourceName)
    end

    for _, eventName in ipairs({ "GlobalBossEvent", "BossIndicatorSpawned", "BossAnnounce" }) do
        local remoteEvent = eventsFolder:FindFirstChild(eventName)
        if remoteEvent and remoteEvent:IsA("RemoteEvent") then
            table.insert(bossEventConnections, remoteEvent.OnClientEvent:Connect(function(...)
                recordAlert(eventName, ...)
            end))
        end
    end
end

function BossFarm.findTimedBoss()
    local rootPart = getRoot()
    local origin = rootPart and rootPart.Position or Vector3.zero

    for _, bossName in ipairs(timedBossNames) do
        local isSelected = State.BossSelection[bossName] or (bossName == "Yhwach" and State.BossSelection["Yhwach (Global Boss)"])
        if isSelected then
            if bossName == "World Whale Event" then
                if whaleFolder then
                    for _, model in ipairs(whaleFolder:GetChildren()) do
                        local humanoid = model:FindFirstChildOfClass("Humanoid")
                        if humanoid and humanoid.Health > 0 and model:FindFirstChild("HumanoidRootPart") then
                            return model.Name
                        end
                    end
                end
            elseif getTargetEnemy(bossName, origin, true) then
                return bossName
            end
        end
    end

    if lastBossAlert and (os.clock() - lastBossAlert.Time) < 180 and lastBossAlert.Name then
        for _, bossName in ipairs(timedBossNames) do
            local isSelected = State.BossSelection[bossName] or (bossName == "Yhwach" and State.BossSelection["Yhwach (Global Boss)"])
            if isSelected and string.find(normalizeName(lastBossAlert.Name), normalizeName(bossName), 1, true) then
                return bossName, lastBossAlert.Position
            end
        end
    end

    return nil
end

function BossFarm.getStatue(catalogItem)
    local islandsFolder = workspaceService:FindFirstChild("Islands")
    local islandList = islandsFolder and islandsFolder:FindFirstChild("Islands")
    local castleModel = islandList and islandList:FindFirstChild("Quincy Castle")
    return castleModel and castleModel:FindFirstChild(catalogItem.Entry.Location or catalogItem.Name)
end

function BossFarm.getQuincyBlockReason()
    local dataFolder = localPlayer:FindFirstChild("Data")
    local raceValue = dataFolder and dataFolder:FindFirstChild("Race")
    if raceValue and raceValue.Value == "Quincy" then
        return nil
    end
    if State.QuincyBlockedAt and os.clock() - State.QuincyBlockedAt < 120 then
        return "server: only a Quincy or Quincy Echo can wake the statue"
    end
    if UnlockFarm.getActiveQuestFolder("Four Origins - Quincy Echo") then
        return nil
    end
    return "needs Race Quincy or active quest Four Origins - Quincy Echo"
end

function BossFarm.summonAtStatue(catalogItem, stopCondition)
    local bossName = catalogItem.Name
    local statue = BossFarm.getStatue(catalogItem)
    if not statue then
        setFarmStatus(bossName .. " statue not found")
        task.wait(2)
        return false
    end

    local function isActive()
        return stopCondition == nil or stopCondition()
    end

    local quincy = BossFarm.Quincy
    local soldierName = quincy.SoldierName

    if State.QuincyBanked then
        quincy.Kills = State.QuincyBanked
        quincy.KillsTarget = quincy.KillsPerSummon
    end

    if quincy.Kills < quincy.KillsTarget then
        quincy.StatusBoss = bossName
        BossFarm.refreshQuincyStatus()
        local rootPart = getRoot()
        local statuePosition = statue:GetPivot().Position
        if rootPart and not getTargetEnemy(soldierName, rootPart.Position, false) and (statuePosition - rootPart.Position).Magnitude > 300 then
            lastKnownMobCFrame = nil
            safeTravelTo(CFrame.new(statuePosition + Vector3.new(0, 3, 12)), function()
                local currentRoot = getRoot()
                return isActive() and currentRoot ~= nil and getTargetEnemy(soldierName, currentRoot.Position, false) == nil
            end)
            task.wait(0.5)
        end
        farmMobWithAnchor(soldierName, function()
            return isActive() and quincy.Kills < quincy.KillsTarget
        end, false)
        return true
    end

    quincy.StatusBoss = nil
    lockedEnemyRoot = nil
    Combat.LockedMobName = nil
    setTargetBox(nil)

    local statuePart = statue:FindFirstChild("Part")
    local summonPrompt = statuePart and statuePart:FindFirstChild("SummonPrompt")
    local rootPart = getRoot()

    if not summonPrompt or not rootPart or (statuePart.Position - rootPart.Position).Magnitude > 10 then
        setFarmStatus("Moving to " .. bossName .. " statue")
        local standPosition = (statuePart and statuePart.Position or statue:GetPivot().Position) + Vector3.new(0, 3, 6)
        safeTravelTo(CFrame.new(standPosition), function()
            return isActive() and not BossFarm.isBossAlive(bossName)
        end)
        task.wait(0.5)

        if BossFarm.isBossAlive(bossName) then
            return farmMobWithAnchor(bossName, stopCondition, true)
        end

        statuePart = statue:FindFirstChild("Part")
        summonPrompt = statuePart and statuePart:FindFirstChild("SummonPrompt")
        rootPart = getRoot()
        if not summonPrompt or not rootPart or (statuePart.Position - rootPart.Position).Magnitude > 12 then
            setFarmStatus("Cannot reach " .. bossName .. " statue")
            bossSummonCooldown[bossName] = os.clock() + 3
            return false
        end
    end

    if not summonPrompt.Enabled then
        setFarmStatus(bossName .. " statue busy")
        bossSummonCooldown[bossName] = os.clock() + 5
        return false
    end

    local ticketItem = catalogItem.Entry.TicketItem or "Reishi Fragment"
    local ticketsBefore = getInventoryAmount(ticketItem)
    local sentAt = os.clock()
    setFarmStatus("Summoning " .. bossName .. " at statue")
    triggerPrompt(summonPrompt)

    local outcome = "rejected"
    local deadline = os.clock() + 3
    while os.clock() < deadline do
        if getInventoryAmount(ticketItem) < ticketsBefore or BossFarm.isBossAlive(bossName) then
            outcome = "spawned"
            break
        end
        if (State.LastNotifyTime or 0) >= sentAt then
            local lowered = string.lower(tostring(State.LastNotifyText))
            if string.find(lowered, "already", 1, true) or string.find(lowered, "at a time", 1, true) then
                outcome = "occupied"
                break
            end
        end
        task.wait(0.1)
    end

    if outcome == "spawned" then
        quincy.Kills = 0
        quincy.KillsTarget = quincy.KillsPerSummon
        if State.QuincyBanked then
            State.QuincyBanked = math.max(0, State.QuincyBanked - quincy.KillsPerSummon)
        end
        bossSummonCooldown[bossName] = nil
        setFarmStatus(bossName .. " summoned | engaging")
        local streamDeadline = os.clock() + 6
        while os.clock() < streamDeadline and not BossFarm.isBossAlive(bossName) do
            task.wait(0.2)
        end
        return farmMobWithAnchor(bossName, stopCondition, true)
    end

    if outcome == "occupied" then
        setFarmStatus(bossName .. " statue busy | " .. tostring(State.LastNotifyText))
        bossSummonCooldown[bossName] = os.clock() + 10
        return false
    end

    if State.QuincyBanked and State.QuincyBanked >= quincy.KillsPerSummon then
        setFarmStatus(bossName .. " summon rejected | " .. tostring(State.LastNotifyText))
        bossSummonCooldown[bossName] = os.clock() + 10
        return false
    end

    quincy.KillsTarget = math.max(quincy.KillsPerSummon, quincy.Kills + 5)
    setFarmStatus(string.format("%s summon rejected | %s %d/%d", bossName, soldierName, quincy.Kills, quincy.KillsTarget))
    return false
end

function BossFarm.stepSummonedYhwach(stopCondition)
    local yh = Extras.Yhwach
    if not yh then
        return false
    end
    local king = yh.findKing()
    if not king then
        local rootPart = getRoot()
        local origin = rootPart and rootPart.Position or Vector3.zero
        king = getTargetEnemy("Yhwach Not Dungeon", origin, true)
    end
    if king then
        setFarmStatus("Engaging Quincy King (Yhwach Not Dungeon)")
        yh.fightKing(king)
        return true
    end
    if not State.AutoSummonBoss then
        setFarmStatus("Waiting for Yhwach (Summoned) to spawn (auto summon off)")
        task.wait(2)
        return false
    end
    local blockReason = BossFarm.getQuincyBlockReason()
    if blockReason then
        setFarmStatus("Yhwach (Summoned) | " .. blockReason)
        task.wait(2)
        return false
    end
    yh.syncBank()
    yh.reconcileSummoned()
    local data = yh.data()
    local nextStatue = nil
    for _, name in ipairs(yh.Route) do
        local aliveBoss = yh.findBoss(name)
        if aliveBoss then
            nextStatue = name
            break
        end
        if not data.SetKills[name] and not nextStatue then
            nextStatue = name
        end
    end
    if not nextStatue then
        if yh.setCount() >= #yh.Route then
            setFarmStatus("All 5 statues killed | waiting for Quincy King to spawn")
            local deadline = os.clock() + 15
            while os.clock() < deadline and (stopCondition == nil or stopCondition()) do
                king = yh.findKing()
                if king then
                    setFarmStatus("Engaging Quincy King")
                    yh.fightKing(king)
                    return true
                end
                task.wait(0.5)
            end
            data.SetKills = {}
            yh.save()
        else
            data.SetKills = {}
            yh.save()
        end
        return false
    end
    setFarmStatus("Yhwach Summon Set (" .. tostring(yh.setCount()) .. "/5) | " .. nextStatue)
    yh.fightStatue(nextStatue)
    return true
end

function BossFarm.summonBoss(catalogItem)
    local entry = catalogItem.Entry
    local npcName = catalogItem.NPC

    if not npcName then
        State.BossStatus = catalogItem.Name .. " has no summon NPC"
        task.wait(2)
        return false
    end

    local cooldown = getNPCCooldown(npcName)
    if cooldown > 0 then
        State.BossStatus = npcName .. " retry in " .. tostring(math.ceil(cooldown)) .. "s"
        task.wait(1)
        return false
    end

    local summonNPC = findNPCByName(npcName)
    if not summonNPC then
        State.BossStatus = "Summon NPC " .. npcName .. " not found"
        setNPCCooldown(npcName, 4)
        task.wait(1)
        return false
    end

    local difficulty = BossFarm.getDifficulty(entry)
    local ticketItem = entry.TicketItem or "Boss Ticket"

    local function attemptSpawn()
        local ticketsBefore = getInventoryAmount(ticketItem)
        local moneyBefore = getMoney()
        local sentAt = os.clock()
        local _, spawnResult = invokeInput("SpawnBoss", npcName, catalogItem.Name, difficulty)
        local deadline = os.clock() + 2.5

        while os.clock() < deadline do
            if getInventoryAmount(ticketItem) < ticketsBefore or getMoney() < moneyBefore or BossFarm.isBossAlive(catalogItem.Name) then
                return "spawned"
            end
            if (State.LastNotifyTime or 0) >= sentAt then
                local lowered = string.lower(tostring(State.LastNotifyText))
                if string.find(lowered, "too far", 1, true) then
                    return "far"
                end
                if string.find(lowered, "already", 1, true) then
                    return "occupied"
                end
                if string.find(lowered, "enough", 1, true) or string.find(lowered, "require", 1, true) or string.find(lowered, "need", 1, true) then
                    return "missing"
                end
            end
            task.wait(0.1)
        end

        if spawnResult == "Have" then
            return "occupied"
        end
        return "unknown"
    end

    local function moveNearSummon(closeDistance)
        local rootPart = getRoot()
        local npcPivot = summonNPC:GetPivot()
        if not rootPart then
            return false
        end

        local npcIsland = getNearestIslandName(npcPivot.Position)
        if npcIsland and getNearestIslandName(rootPart.Position) ~= npcIsland then
            local spot = getSpotForNPCName(npcName)
            local hopped = false
            if spot then
                hopped = teleportToSpot(spot.Island, spot.Target)
            end
            if not hopped then
                teleportToIsland(npcIsland, npcPivot.Position)
            end
        end

        rootPart = getRoot()
        if not rootPart then
            return false
        end

        if (npcPivot.Position - rootPart.Position).Magnitude > closeDistance then
            travelTo(npcPivot * CFrame.new(0, 3, 8), function()
                return isFarmActive()
            end)
        end

        rootPart = getRoot()
        return rootPart ~= nil and (npcPivot.Position - rootPart.Position).Magnitude <= closeDistance + 20
    end

    local rootPart = getRoot()
    local summonPosition = summonNPC:GetPivot().Position
    local summonDistance = rootPart and (summonPosition - rootPart.Position).Magnitude or math.huge
    local summonIsland = getNearestIslandName(summonPosition)
    local sameIsland = rootPart ~= nil and summonIsland ~= nil and getNearestIslandName(rootPart.Position) == summonIsland

    if summonDistance > 1500 or not sameIsland then
        setFarmStatus("Moving to " .. npcName .. " to summon " .. catalogItem.Name)
        if not moveNearSummon(250) then
            setFarmStatus("Cannot reach " .. npcName)
            setNPCCooldown(npcName, 4)
            return false
        end
    end

    setFarmStatus("Summoning " .. catalogItem.Name .. " (" .. tostring(difficulty or "default") .. ")")
    local wantedName = normalizeName(catalogItem.Name)
    local spawnSeen = false
    local seenConnection = enemiesFolder.ChildAdded:Connect(function(child)
        if normalizeName(stripBossTag(child.Name)) == wantedName then
            spawnSeen = true
        end
    end)
    local outcome = attemptSpawn()

    if outcome == "far" then
        setFarmStatus("Too far from " .. catalogItem.Name .. " spawn | moving closer")
        moveNearSummon(20)
        outcome = attemptSpawn()
    end

    if outcome == "spawned" then
        setFarmStatus(catalogItem.Name .. " summoned | engaging")
        local streamDeadline = os.clock() + 6
        while os.clock() < streamDeadline and not spawnSeen and not BossFarm.isBossAlive(catalogItem.Name) do
            task.wait(0.05)
        end
    end
    seenConnection:Disconnect()

    closeSummonUI()
    lockedTargetCFrame = nil

    if outcome == "spawned" then
        return true
    end

    if outcome == "occupied" then
        local occupant = BossFarm.getAltarOccupant(npcName)
        if not occupant then
            local npcPosition = summonNPC:GetPivot().Position
            local nearestIndicator = nil
            local nearestIndicatorDistance = 2500
            for _, child in ipairs(workspaceService:GetChildren()) do
                if child:IsA("BasePart") and string.find(child.Name, "BossIndicator", 1, true) then
                    local indicatorDistance = (child.Position - npcPosition).Magnitude
                    if indicatorDistance < nearestIndicatorDistance then
                        nearestIndicatorDistance = indicatorDistance
                        nearestIndicator = child
                    end
                end
            end
            if nearestIndicator then
                setFarmStatus("Boss already active | flying to its marker")
                travelTo(CFrame.new(nearestIndicator.Position + Vector3.new(0, 12, 0)), function()
                    return isFarmActive() and BossFarm.getAltarOccupant(npcName) == nil
                end)
                occupant = BossFarm.getAltarOccupant(npcName)
            end
        end
        if occupant then
            if normalizeName(occupant) == normalizeName(catalogItem.Name) then
                setFarmStatus(catalogItem.Name .. " already spawned")
                return true
            end
            setFarmStatus("Altar occupied by " .. occupant .. " | clearing")
            return false, occupant
        end
        setFarmStatus("Boss already active | searching occupant")
        return false, "occupied"
    end

    setFarmStatus("Summon failed for " .. catalogItem.Name .. " (" .. outcome .. ") " .. tostring(State.LastNotifyText))
    return false
end

function BossFarm.engageBoss(bossName, alertPosition)
    local rootPart = getRoot()
    if not rootPart then
        return false
    end

    if not getTargetEnemy(bossName, rootPart.Position, true) and alertPosition then
        State.BossStatus = "Flying to " .. bossName .. " alert position"
        safeTravelTo(CFrame.new(alertPosition + Vector3.new(0, 10, 0)), function()
            local currentRoot = getRoot()
            return State.BossFarmEnabled and currentRoot ~= nil and getTargetEnemy(bossName, currentRoot.Position, true) == nil
        end)
    end

    State.BossStatus = "Fighting " .. bossName
    local engaged = farmMobWithAnchor(bossName, function()
        return State.BossFarmEnabled
    end, true)

    if not engaged then
        local currentRoot = getRoot()
        if not currentRoot or not getTargetEnemy(bossName, currentRoot.Position, true) then
            lastBossAlert = nil
        end
    end

    return engaged
end

function BossFarm.prepareAndKill(catalogItem, stopCondition, ownerName)
    if not catalogItem then
        return false
    end

    local bossName = catalogItem.Name

    if BossFarm.isBossAlive(bossName) then
        return farmMobWithAnchor(bossName, stopCondition, true)
    end

    if catalogItem.Group == "Quincy" then
        local blockReason = BossFarm.getQuincyBlockReason()
        if blockReason then
            setFarmStatus(bossName .. " | " .. blockReason)
            bossSummonCooldown[bossName] = os.clock() + 30
            task.wait(1)
            return false
        end
    end

    local occupantName = catalogItem.NPC and BossFarm.getAltarOccupant(catalogItem.NPC)
    if occupantName and normalizeName(occupantName) ~= normalizeName(bossName) then
        if BossFarm.isBossAlive(occupantName) then
            setFarmStatus("Clearing " .. occupantName .. " to free " .. tostring(catalogItem.NPC))
            return farmMobWithAnchor(occupantName, function()
                return BossFarm.isBossAlive(occupantName) and (stopCondition == nil or stopCondition())
            end, true)
        end
    end

    local npcName = catalogItem.NPC
    local summonNPC = npcName and findNPCByName(npcName)
    local rootPart = getRoot()

    local summonFarAway = false
    if summonNPC and rootPart then
        local summonPosition = summonNPC:GetPivot().Position
        local summonIsland = getNearestIslandName(summonPosition)
        summonFarAway = (summonPosition - rootPart.Position).Magnitude > 1500
            or (summonIsland ~= nil and getNearestIslandName(rootPart.Position) ~= summonIsland)
    end

    if summonFarAway then
        safeTravelTo(summonNPC:GetPivot() * CFrame.new(0, 0, 10), function()
            local cr = getRoot()
            return (stopCondition == nil or stopCondition()) and cr ~= nil and not BossFarm.isBossAlive(bossName)
        end)
        task.wait(0.5)
        if BossFarm.isBossAlive(bossName) then
            return farmMobWithAnchor(bossName, stopCondition, true)
        end
        local recheckOccupant = npcName and BossFarm.getAltarOccupant(npcName)
        if recheckOccupant and normalizeName(recheckOccupant) ~= normalizeName(bossName) then
            if BossFarm.isBossAlive(recheckOccupant) then
                setFarmStatus("Clearing " .. recheckOccupant .. " to free " .. tostring(npcName))
                return farmMobWithAnchor(recheckOccupant, function()
                    return BossFarm.isBossAlive(recheckOccupant) and (stopCondition == nil or stopCondition())
                end, true)
            end
        end
    end

    local shortfalls = BossFarm.getSummonShortfall(catalogItem)

    if #shortfalls == 0 then
        if BossFarm.isBossAlive(bossName) then
            bossSummonCooldown[bossName] = nil
            return farmMobWithAnchor(bossName, stopCondition, true)
        end

        if catalogItem.Group == "Quincy" then
            return BossFarm.summonAtStatue(catalogItem, stopCondition)
        end

        local finalOccupant = npcName and BossFarm.getAltarOccupant(npcName)
        if finalOccupant and normalizeName(finalOccupant) ~= normalizeName(bossName) then
            if BossFarm.isBossAlive(finalOccupant) then
                setFarmStatus("Clearing " .. finalOccupant .. " to free " .. tostring(npcName))
                return farmMobWithAnchor(finalOccupant, function()
                    return BossFarm.isBossAlive(finalOccupant) and (stopCondition == nil or stopCondition())
                end, true)
            end
        end

        local cooldownLeft = (bossSummonCooldown[bossName] or 0) - os.clock()
        if cooldownLeft > 0 then
            setFarmStatus(bossName .. " summon cooldown " .. tostring(math.ceil(cooldownLeft)) .. "s")
            task.wait(1)
            return false
        end

        local summoned, summonOccupant = BossFarm.summonBoss(catalogItem)
        if summoned then
            bossSummonCooldown[bossName] = nil
            if not BossFarm.isBossAlive(bossName) then
                return true
            end
            return farmMobWithAnchor(bossName, stopCondition, true)
        end

        if summonOccupant and summonOccupant ~= "occupied" and normalizeName(summonOccupant) ~= normalizeName(bossName) then
            if BossFarm.isBossAlive(summonOccupant) then
                bossSummonCooldown[bossName] = nil
                setFarmStatus("Clearing " .. summonOccupant .. " to free " .. tostring(npcName))
                return farmMobWithAnchor(summonOccupant, function()
                    return BossFarm.isBossAlive(summonOccupant) and (stopCondition == nil or stopCondition())
                end, true)
            end
        end

        local postOccupant = npcName and BossFarm.getAltarOccupant(npcName)
        if postOccupant and normalizeName(postOccupant) ~= normalizeName(bossName) then
            if BossFarm.isBossAlive(postOccupant) then
                bossSummonCooldown[bossName] = nil
                setFarmStatus("Clearing " .. postOccupant .. " to free " .. tostring(npcName))
                return farmMobWithAnchor(postOccupant, function()
                    return BossFarm.isBossAlive(postOccupant) and (stopCondition == nil or stopCondition())
                end, true)
            end
        end

        bossSummonCooldown[bossName] = os.clock() + 4
        return false
    end

    for _, shortfall in ipairs(shortfalls) do
        if shortfall.Kind == "quest" then
            setFarmStatus(bossName .. " needs quest " .. tostring(shortfall.Item))
            UnlockFarm.progressQuest(shortfall.Item)
            return false
        end
    end

    for _, shortfall in ipairs(shortfalls) do
        if shortfall.Kind == "item" and shortfall.Item == "Boss Ticket" and (State.AutoBuyBossTicket or ownerName == "solemn" or ownerName == "bankai" or ownerName == "dungeon" or ownerName == "twoh") then
            local buyAmount = shortfall.Need - shortfall.Have
            if ownerName == "solemn" or ownerName == "bankai" or ownerName == "twoh" then
                buyAmount = math.max(buyAmount, Extras.Solemn.TicketBatch, math.min(999, math.floor(getMoney() * 0.9 / 30000)))
            end
            if Extras.buyBossTickets(buyAmount) then
                return false
            end
        end
    end

    for _, shortfall in ipairs(shortfalls) do
        if shortfall.Kind == "item" then
            local plan = getMaterialPlan(shortfall.Item, true)
            if plan.Kind == "shop" then
                setFarmStatus(bossName .. " | buying " .. shortfall.Item)
                buyFromMaterialShop(shortfall.Item, shortfall.Need - shortfall.Have)
                return false
            end
            if plan.Kind == "pickup" then
                local worldPickup = findPickupByName(shortfall.Item)
                if worldPickup then
                    setFarmStatus(bossName .. " | collecting " .. shortfall.Item)
                    releaseMovement(ownerName or "boss")
                    collectPickup(worldPickup, stopCondition)
                    reacquireMovement(ownerName or "boss")
                    return false
                end
            end
            if plan.Kind == "mob" then
                setFarmStatus(string.format("%s | %s %d/%d from %s", bossName, shortfall.Item, math.floor(shortfall.Have), math.floor(shortfall.Need), tostring(plan.Mob)))
                farmMobWithAnchor(plan.Mob, function()
                    return (stopCondition == nil or stopCondition()) and getInventoryAmount(shortfall.Item) < shortfall.Need
                end, isKnownBossName(plan.Mob))
                return false
            end
        end
    end

    for _, shortfall in ipairs(shortfalls) do
        if shortfall.Kind == "money" then
            local grindMob = UnlockFarm.getGrindMobName()
            setFarmStatus(string.format("%s | money %d/%d", bossName, math.floor(shortfall.Have), math.floor(shortfall.Need)))
            if grindMob then
                farmMobWithAnchor(grindMob, function()
                    return (stopCondition == nil or stopCondition()) and getMoney() < shortfall.Need
                end, false)
            else
                task.wait(2)
            end
            return false
        end
    end

    setFarmStatus(bossName .. " needs " .. BossFarm.describeShortfall(shortfalls))
    task.wait(2)
    return false
end

function BossFarm.runCycle()
    local timedBoss, alertPosition = BossFarm.findTimedBoss()
    if timedBoss then
        bossPriority = true
        BossFarm.engageBoss(timedBoss, alertPosition)
        return
    end
    bossPriority = false

    local targets = BossFarm.getActiveTargets()
    if #targets == 0 then
        State.BossStatus = "No bosses selected"
        task.wait(2)
        return
    end

    for _, bossName in ipairs(targets) do
        if not State.BossFarmEnabled then
            return
        end

        if bossName == "Yhwach (Summoned)" or bossName == "Yhwach Not Dungeon" then
            local king = Extras.Yhwach and Extras.Yhwach.findKing()
            if king then
                BossFarm.stepSummonedYhwach(function()
                    return State.BossFarmEnabled
                end)
                return
            end
        elseif BossFarm.isBossAlive(bossName) then
            BossFarm.engageBoss(bossName, nil)
            return
        end
    end

    if not State.AutoSummonBoss then
        State.BossStatus = "Waiting for selected bosses to spawn (auto summon off)"
        task.wait(3)
        return
    end

    if State.BossSelection["Yhwach (Summoned)"] or State.BossSelection["Yhwach Not Dungeon"] then
        if BossFarm.stepSummonedYhwach(function()
            return State.BossFarmEnabled
        end) then
            return
        end
    end

    local now = os.clock()
    local anySummonable = false

    for _, bossName in ipairs(targets) do
        if not State.BossFarmEnabled then
            return
        end

        if bossName ~= "Yhwach (Summoned)" and bossName ~= "Yhwach Not Dungeon" and bossName ~= "Yhwach (Global Boss)" then
            local catalogItem = BossFarm.getSummonEntry(bossName)
            local cooldownUntil = bossSummonCooldown[bossName] or 0

            if catalogItem and now >= cooldownUntil then
                anySummonable = true
                BossFarm.prepareAndKill(catalogItem, function()
                    return State.BossFarmEnabled
                end, "boss")
                return
            elseif catalogItem then
                State.BossStatus = bossName .. " on cooldown " .. tostring(math.ceil(cooldownUntil - now)) .. "s"
                task.wait(0.2)
            end
        end
    end

    if not anySummonable then
        State.BossStatus = "Waiting for selected bosses | " .. tostring(#targets) .. " targets"
    end
    task.wait(2)
end

function BossFarm.Start()
    if State.BossFarmEnabled then
        return
    end

    State.BossFarmEnabled = true
    BossFarm.hookBossEvents()

    bossFarmThread = task.spawn(function()
        while State.BossFarmEnabled do
            task.wait(0.3)

            if Prestige.isHandlingRequirements() then
                bossPriority = false
                State.BossStatus = "Paused | Auto Prestige is working on " .. tostring(Prestige.activeWork)
                task.wait(0.5)
            elseif acquireMovement("boss") then
                local rootPart, playerHumanoid = getRoot()
                if rootPart and playerHumanoid and playerHumanoid.Health > 0 then
                    autoAllocateStats()
                    collectNearbyPickup("boss")
                    BossFarm.runCycle()
                end
                releaseMovement("boss")
            else
                task.wait(0.5)
            end
        end

        bossPriority = false
        releaseMovement("boss")
        settleCharacter()
        lockedEnemyRoot = nil
        lockedTargetCFrame = nil
        lastKnownMobCFrame = nil
        setTargetBox(nil)
    end)
end

function BossFarm.Stop()
    State.BossFarmEnabled = false
    State.BossStatus = "Idle"
    bossPriority = false
    releaseMovement("boss")
    stopTween()
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    lastKnownMobCFrame = nil
    setTargetBox(nil)
    removeFloat(getRoot())
end

local farmLevelThread = nil

function FarmLevel.getRecommendedQuest()
    local currentLevel = getPlayerLevel()
    local bestQuestName = nil
    local bestNPC = nil
    local highestMin = -1

    for questName, questInfo in pairs(questData.Main) do
        if string.find(questName, "^Quest%s") and typeof(questInfo.LevelRanging) == "table" then
            local minLevel = questInfo.LevelRanging[1] or 0
            local maxLevel = questInfo.LevelRanging[2] or math.huge

            if currentLevel >= minLevel and currentLevel <= maxLevel then
                local npc = getQuestNPC(questName)
                if npc and minLevel > highestMin then
                    highestMin = minLevel
                    bestQuestName = questName
                    bestNPC = npc
                end
            end
        end
    end

    if not bestNPC then
        for questName, questInfo in pairs(questData.Main) do
            if string.find(questName, "^Quest%s") and typeof(questInfo.LevelRanging) == "table" then
                local minLevel = questInfo.LevelRanging[1] or 0
                if currentLevel >= minLevel and minLevel > highestMin then
                    local npc = getQuestNPC(questName)
                    if npc then
                        highestMin = minLevel
                        bestQuestName = questName
                        bestNPC = npc
                    end
                end
            end
        end
    end

    return bestNPC, bestQuestName
end

function FarmLevel.getActiveQuest(questName)
    local questFolder = questName and UnlockFarm.getActiveQuestFolder(questName)
    local completedValue = questFolder and questFolder:FindFirstChild("Completed")
    if questFolder and not (completedValue and completedValue.Value == true) then
        return questFolder
    end
    return nil
end

function FarmLevel.isGrindQuest(questName)
    local questInfo = questData.Main[questName]
    return string.find(questName, "^Quest%s") ~= nil and typeof(questInfo) == "table" and typeof(questInfo.LevelRanging) == "table"
end

function FarmLevel.pickActiveQuest()
    local _, recommendedName = FarmLevel.getRecommendedQuest()
    local recommendedQuest = FarmLevel.getActiveQuest(recommendedName)
    if recommendedQuest then
        return recommendedQuest
    end

    local dataFolder = localPlayer:FindFirstChild("Data")
    local questsFolder = dataFolder and dataFolder:FindFirstChild("Quests")
    local mainQuests = questsFolder and questsFolder:FindFirstChild("Main")
    if not mainQuests then
        return nil
    end

    for _, quest in ipairs(mainQuests:GetChildren()) do
        if FarmLevel.isGrindQuest(quest.Name) and FarmLevel.getActiveQuest(quest.Name) then
            return quest
        end
    end

    return nil
end

function FarmLevel.Start()
    if State.FarmLevelEnabled then
        return
    end

    State.FarmLevelEnabled = true

    farmLevelThread = task.spawn(function()
        while State.FarmLevelEnabled do
            task.wait(0.15)

            if Prestige.isHandlingRequirements() then
                task.wait(0.5)
            elseif acquireMovement("level") then
                local rootPart, playerHumanoid = getRoot()

                if rootPart and playerHumanoid and playerHumanoid.Health > 0 then
                    autoAllocateStats()
                    collectNearbyPickup("level")

                    local currentQuest = FarmLevel.pickActiveQuest()

                    if not currentQuest then
                        setTargetBox(nil)
                        lockedEnemyRoot = nil
                        lastKnownMobCFrame = nil

                        local targetNPC, targetQuestName = FarmLevel.getRecommendedQuest()
                        if targetNPC then
                            local reached = travelToNPC(targetNPC, function()
                                return State.FarmLevelEnabled and FarmLevel.getActiveQuest(targetQuestName) == nil and not Prestige.isHandlingRequirements()
                            end)

                            if reached then
                                invokeInput("Quest", "Accept", targetNPC, targetQuestName)
                                task.wait(0.4)

                                if FarmLevel.getActiveQuest(targetQuestName) == nil then
                                    talkToNPC(targetNPC, "Accept", function()
                                        return FarmLevel.getActiveQuest(targetQuestName) ~= nil
                                    end, 6)
                                end
                                lockedTargetCFrame = nil
                            else
                                lockedTargetCFrame = nil
                                task.wait(1.5)
                            end
                        end
                    else
                        executeQuestCombat(currentQuest, function()
                            return State.FarmLevelEnabled and not Prestige.isHandlingRequirements()
                        end)
                    end
                end

                releaseMovement("level")
            end
        end

        releaseMovement("level")
        settleCharacter()
        lockedEnemyRoot = nil
        lockedTargetCFrame = nil
        lastKnownMobCFrame = nil
        setTargetBox(nil)
    end)
end

function FarmLevel.Stop()
    State.FarmLevelEnabled = false
    releaseMovement("level")
    stopTween()
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    lastKnownMobCFrame = nil
    setTargetBox(nil)
    removeFloat(getRoot())
end

local farmQuestThread = nil

function FarmQuest.Start()
    if State.FarmQuestEnabled then
        return
    end

    State.FarmQuestEnabled = true

    farmQuestThread = task.spawn(function()
        while State.FarmQuestEnabled do
            task.wait(0.15)

            if Prestige.isHandlingRequirements() then
                task.wait(0.5)
            elseif acquireMovement("quest") then
                local rootPart, playerHumanoid = getRoot()

                if rootPart and playerHumanoid and playerHumanoid.Health > 0 then
                    autoAllocateStats()
                    collectNearbyPickup("quest")

                    local selectedQuestName = State.SelectedQuest

                    if not selectedQuestName then
                        task.wait(0.5)
                    else
                        local currentQuest = FarmLevel.getActiveQuest(selectedQuestName)

                        if not currentQuest then
                            setTargetBox(nil)
                            lockedEnemyRoot = nil
                            lastKnownMobCFrame = nil

                            local targetNPC = getQuestNPC(selectedQuestName)
                            if targetNPC then
                                local reached = travelToNPC(targetNPC, function()
                                    return State.FarmQuestEnabled and State.SelectedQuest == selectedQuestName and FarmLevel.getActiveQuest(selectedQuestName) == nil
                                end)

                                if reached then
                                    invokeInput("Quest", "Accept", targetNPC, selectedQuestName)
                                    task.wait(0.4)

                                    if FarmLevel.getActiveQuest(selectedQuestName) == nil then
                                        talkToNPC(targetNPC, "Accept", function()
                                            return FarmLevel.getActiveQuest(selectedQuestName) ~= nil
                                        end, 6)
                                    end
                                    lockedTargetCFrame = nil
                                else
                                    lockedTargetCFrame = nil
                                    task.wait(1.5)
                                end
                            end
                        else
                            executeQuestCombat(currentQuest, function()
                                return State.FarmQuestEnabled and State.SelectedQuest == selectedQuestName
                            end)
                        end
                    end
                end

                releaseMovement("quest")
            end
        end

        releaseMovement("quest")
        settleCharacter()
        lockedEnemyRoot = nil
        lockedTargetCFrame = nil
        lastKnownMobCFrame = nil
        setTargetBox(nil)
    end)
end

function FarmQuest.Stop()
    State.FarmQuestEnabled = false
    releaseMovement("quest")
    stopTween()
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    lastKnownMobCFrame = nil
    setTargetBox(nil)
    removeFloat(getRoot())
end

UIController.LevelToggle = nil
UIController.QuestToggle = nil
UIController.PrestigeToggle = nil
UIController.CodeToggle = nil
UIController.UnlockToggle = nil
UIController.PickupToggle = nil
UIController.BossToggle = nil
UIController.QuestDropdown = nil
UIController.StatusParagraph = nil
UIController.PrestigeParagraph = nil
UIController.BossParagraph = nil
UIController.UnlockParagraph = nil
UIController.StatParagraph = nil
UIController.IsSyncingUI = false

local statusRefreshThread = nil

local function parseMultiSelection(value)
    local selected = {}

    if typeof(value) == "string" then
        selected[value] = true
        return selected
    end

    if typeof(value) ~= "table" then
        return selected
    end

    for key, entry in pairs(value) do
        if typeof(key) == "number" and typeof(entry) == "string" then
            selected[entry] = true
        elseif typeof(key) == "string" and entry then
            selected[key] = true
        end
    end

    return selected
end

function UIController.stopOthers(keepName)
    UIController.IsSyncingUI = true

    if keepName ~= "level" and State.FarmLevelEnabled then
        FarmLevel.Stop()
        if UIController.LevelToggle then
            pcall(function()
                UIController.LevelToggle:UpdateState(false)
            end)
        end
    end

    if keepName ~= "quest" and State.FarmQuestEnabled then
        FarmQuest.Stop()
        if UIController.QuestToggle then
            pcall(function()
                UIController.QuestToggle:UpdateState(false)
            end)
        end
    end

    if keepName ~= "unlock" and State.UnlockEnabled then
        UnlockFarm.Stop()
        if UIController.UnlockToggle then
            pcall(function()
                UIController.UnlockToggle:UpdateState(false)
            end)
        end
    end

    if keepName ~= "boss" and State.BossFarmEnabled then
        BossFarm.Stop()
        if UIController.BossToggle then
            pcall(function()
                UIController.BossToggle:UpdateState(false)
            end)
        end
    end

    if keepName ~= "mob" and State.MobFarmEnabled then
        Extras.stopLoop("MobFarmEnabled", "mob")
        State.MobFarmStatus = "Idle"
        if UIController.MobFarmToggle then
            pcall(function()
                UIController.MobFarmToggle:UpdateState(false)
            end)
        end
    end

    UIController.IsSyncingUI = false
end

function UIController.setStatPriority(slotIndex, statName)
    local current = {}
    for index, existing in ipairs(State.StatPriority) do
        current[index] = existing
    end

    local previousIndex = nil
    for index, existing in ipairs(current) do
        if existing == statName then
            previousIndex = index
            break
        end
    end

    local displaced = current[slotIndex]
    current[slotIndex] = statName
    if previousIndex and previousIndex ~= slotIndex then
        current[previousIndex] = displaced
    end

    local ordered = {}
    local seen = {}
    for _, existing in ipairs(current) do
        if statLookup[existing] and not seen[existing] then
            seen[existing] = true
            table.insert(ordered, existing)
        end
    end
    for _, existing in ipairs(statNames) do
        if not seen[existing] then
            seen[existing] = true
            table.insert(ordered, existing)
        end
    end

    State.StatPriority = ordered
    UIController.syncStatDropdowns()
    task.spawn(autoAllocateStats)
end

function UIController.syncStatDropdowns()
    for index, dropdown in ipairs(UIController.StatDropdowns or {}) do
        local statName = State.StatPriority[index]
        local optionIndex = table.find(statNames, statName)
        if dropdown and optionIndex then
            pcall(function()
                dropdown:UpdateSelection(optionIndex)
                dropdown:UpdateName(UIController.StatSlotLabels[index] .. " • " .. StatMeta.Display[statName])
            end)
        end
    end
end

function UIController.refreshStatus(includeHeavy)
    if UIController.StatusParagraph then
        local lines = {
            "Farm: " .. tostring(State.UnlockStatus),
            "Boss: " .. tostring(State.BossStatus),
            "Mob Farm: " .. tostring(State.MobFarmStatus),
            "Prestige: " .. tostring(State.PrestigeStatus),
            "Prestige Missing: " .. tostring(State.PrestigeMissing or "-"),
            "Travel: " .. tostring(State.TravelStatus),
            "Stats: " .. tostring(State.StatStatus),
            "Chests: " .. tostring(State.ChestStatus),
            "Combat: " .. tostring(State.CombatStatus),
            "Extras: " .. tostring(State.ExtraStatus),
            "Fishing: " .. tostring(State.FishStatus),
            "Remote: " .. tostring(State.RemoteStatus),
            "Lock: " .. tostring(movementOwner or "free")
        }
        pcall(function()
            UIController.StatusParagraph:UpdateBody(table.concat(lines, "\n"))
        end)
    end

    if UIController.ExtrasParagraph then
        pcall(function()
            UIController.ExtrasParagraph:UpdateBody(tostring(State.ExtraStatus) .. "\nFishing: " .. tostring(State.FishStatus))
        end)
    end

    if UIController.YhwachParagraph and Extras.Yhwach then
        local yh = Extras.Yhwach
        pcall(function()
            UIController.YhwachParagraph:UpdateBody(table.concat({ tostring(yh.StatusText), tostring(yh.Detail), tostring(yh.EtaText), "Farm: " .. tostring(yh.FarmNote or "-") }, "\n"))
        end)
    end

    if UIController.StatParagraph then
        local lines = {}
        for index, statName in ipairs(getStatPriorityOrder()) do
            table.insert(lines, string.format("%d. %s %d/%d", index, StatMeta.Display[statName] or statName, math.floor(getDataValue(statName)), StatMeta.getCap()))
        end
        table.insert(lines, "Points: " .. tostring(math.floor(getDataValue("Points"))))
        pcall(function()
            UIController.StatParagraph:UpdateBody(table.concat(lines, "\n"))
        end)
    end

    if UIController.PrestigeParagraph then
        local progress, failureReason = Prestige.getRequirementProgress()
        local lines = {}
        if not progress then
            table.insert(lines, tostring(failureReason))
        else
            table.insert(lines, "Next prestige: " .. tostring(Prestige.getCurrentValue() + 1))
            for _, entry in ipairs(progress) do
                table.insert(lines, string.format("[%s] %s %d/%d", entry.Done and "OK" or "NO", entry.Label, math.floor(entry.Current), math.floor(entry.Needed)))
            end
        end
        pcall(function()
            UIController.PrestigeParagraph:UpdateBody(table.concat(lines, "\n"))
        end)
    end

    if not includeHeavy then
        return
    end

    if UIController.BossParagraph then
        local lines = {}
        local targets = BossFarm.getActiveTargets()
        if #targets == 0 then
            table.insert(lines, "no boss selected")
        end
        for _, bossName in ipairs(targets) do
            if bossName == "Yhwach (Summoned)" or bossName == "Yhwach Not Dungeon" then
                local yh = Extras.Yhwach
                local king = yh and yh.findKing()
                if king then
                    table.insert(lines, "Yhwach (Summoned) | ALIVE (Quincy King ready)")
                else
                    local setKills = yh and yh.setCount() or 0
                    local reishi = getInventoryAmount(yh and yh.ReishiItem or "Reishi Fragment")
                    table.insert(lines, string.format("Yhwach (Summoned) | Set: %d/5 statues | Reishi: %d", setKills, reishi))
                end
            elseif bossName == "Yhwach (Global Boss)" or bossName == "Yhwach" then
                local alive = BossFarm.isBossAlive("Yhwach")
                table.insert(lines, string.format("Yhwach (Global Boss) | %s", alive and "ALIVE (World Event)" or "waiting for event spawn"))
            else
                local catalogItem = BossFarm.getSummonEntry(bossName)
                local aliveText = BossFarm.isBossAlive(bossName) and "alive" or "not spawned"
                if catalogItem then
                    local shortfalls = BossFarm.getSummonShortfall(catalogItem)
                    local needText = (#shortfalls == 0) and "summon ready" or ("need " .. BossFarm.describeShortfall(shortfalls))
                    table.insert(lines, string.format("%s | %s | %s | %s", bossName, tostring(catalogItem.NPC or "event"), aliveText, needText))
                else
                    table.insert(lines, string.format("%s | %s", bossName, aliveText))
                end
            end
        end
        pcall(function()
            UIController.BossParagraph:UpdateBody(table.concat(lines, "\n"))
        end)
    end

    if UIController.UnlockParagraph then
        local targetItem = State.UnlockTargets[State.UnlockCategory]
        local lines = { "target: " .. tostring(targetItem) }
        for _, line in ipairs(UnlockFarm.describeTarget(targetItem)) do
            table.insert(lines, line)
        end
        table.insert(lines, "shards: " .. tostring(math.floor(getShards())) .. " | money: " .. tostring(math.floor(getMoney())))
        pcall(function()
            UIController.UnlockParagraph:UpdateBody(table.concat(lines, "\n"))
        end)
    end
end

function UIController.startStatusRefresh()
    if State.StatusRefreshEnabled then
        return
    end

    State.StatusRefreshEnabled = true

    statusRefreshThread = task.spawn(function()
        local refreshCount = 0
        while State.StatusRefreshEnabled do
            local isWindowOpen = getgenv().HubWindow and getgenv().HubWindow:GetState()
            task.wait(isWindowOpen and 0.8 or 2.0)
            refreshCount = refreshCount + 1
            pcall(UIController.refreshStatus, refreshCount % 3 == 0)
        end
    end)
end

do
    local username = (localPlayer and localPlayer.Name) or "Default"
    local configFolder = "LEGACY PIECE/Configs"
    pcall(function()
        if makefolder and not isfolder(configFolder) then
            makefolder(configFolder)
        end
    end)
    local cfgPath = configFolder .. "/" .. username .. ".json"
    local sessPath = configFolder .. "/" .. username .. "_session.json"
    pcall(function()
        if isfile and not isfile(cfgPath) then
            if isfile("LEGACY PIECE/hub_settings.json") then
                local oldContent = readfile("LEGACY PIECE/hub_settings.json")
                if oldContent and #oldContent > 2 then
                    writefile(cfgPath, oldContent)
                end
            elseif isfile("LEGACY PIECE/Configs/Default.json") then
                local defContent = readfile("LEGACY PIECE/Configs/Default.json")
                if defContent and #defContent > 2 then
                    writefile(cfgPath, defContent)
                end
            end
        end
    end)
    UIController.Username = username
    UIController.Settings = { Path = cfgPath, Values = {}, Elements = {}, Dirty = false }
    Extras.SessionPath = sessPath
end

function UIController.recordSetting(kind, name, config, value)
    local settings = UIController.Settings
    if kind == "Dropdown" and config.Multi then
        local current = {}
        for _, optionName in ipairs(typeof(settings.Values[name]) == "table" and settings.Values[name] or {}) do
            current[optionName] = true
        end
        if typeof(value) == "string" then
            current[value] = not current[value] or nil
        elseif typeof(value) == "table" then
            current = {}
            for key, picked in pairs(value) do
                if typeof(key) == "number" then
                    current[picked] = true
                elseif picked then
                    current[key] = true
                end
            end
        end
        local list = {}
        for optionName in pairs(current) do
            table.insert(list, optionName)
        end
        table.sort(list)
        settings.Values[name] = list
    elseif typeof(value) == "boolean" or typeof(value) == "number" or typeof(value) == "string" then
        settings.Values[name] = value
    else
        return
    end
    settings.Dirty = true
end

function UIController.trackToggles(tab)
    local originalSection = tab.Section
    if typeof(originalSection) ~= "function" then
        return
    end
    tab.Section = function(tabSelf, sectionConfig)
        local section = originalSection(tabSelf, sectionConfig)
        for _, kind in ipairs({ "Toggle", "Dropdown", "Slider", "Input" }) do
            local originalControl = section and section[kind]
            if typeof(originalControl) == "function" then
                section[kind] = function(sectionSelf, controlConfig)
                    local name = typeof(controlConfig) == "table" and controlConfig.Name or nil
                    local entry = nil
                    if name and typeof(controlConfig.Callback) == "function" then
                        local userCallback = controlConfig.Callback
                        entry = { Kind = kind, Callback = userCallback, Config = controlConfig }
                        controlConfig.Callback = function(value, ...)
                            UIController.recordSetting(kind, name, controlConfig, value)
                            return userCallback(value, ...)
                        end
                    end
                    local control = originalControl(sectionSelf, controlConfig)
                    if entry then
                        entry.Object = control
                        UIController.Settings.Elements[name] = entry
                    end
                    if kind == "Toggle" and name then
                        UIController.Toggles[name] = control
                    end
                    return control
                end
            end
        end
        return section
    end
end

function UIController.restoreSettings()
    local settings = UIController.Settings
    local saved = nil
    pcall(function()
        saved = httpService:JSONDecode(readfile(settings.Path))
    end)
    if typeof(saved) ~= "table" then
        return false
    end
    settings.Values = saved
    local farmToggles = {}
    for _, entry in ipairs(Extras.Session.Map) do
        farmToggles[entry[2]] = true
    end
    farmToggles["Auto Araya (Lost Afterimage)"] = true
    for _, slotLabel in ipairs(UIController.StatSlotLabels or {}) do
        saved[slotLabel] = nil
    end
    local function apply(name, entry, value)
        pcall(function()
            if entry.Kind == "Toggle" then
                entry.Object:UpdateState(value == true)
            elseif entry.Kind == "Slider" then
                entry.Object:UpdateValue(value)
                entry.Callback(value)
            elseif entry.Kind == "Input" then
                entry.Object:UpdateText(tostring(value))
                entry.Callback(tostring(value))
            elseif entry.Kind == "Dropdown" then
                if entry.Config.Multi then
                    local map = {}
                    for _, optionName in ipairs(value) do
                        map[optionName] = true
                    end
                    entry.Object:UpdateSelection(value)
                    entry.Callback(map)
                else
                    local index = table.find(entry.Config.Options or {}, value)
                    if index then
                        entry.Object:UpdateSelection(index)
                        entry.Callback(value)
                    end
                end
            end
        end)
    end
    for pass = 1, 3 do
        for name, value in pairs(saved) do
            local entry = settings.Elements[name]
            if entry then
                local isToggle = entry.Kind == "Toggle"
                local isFarm = farmToggles[name] == true
                if (pass == 1 and not isToggle) or (pass == 2 and isToggle and not isFarm) or (pass == 3 and isToggle and isFarm and value == true) then
                    apply(name, entry, value)
                end
            end
        end
    end
    settings.Dirty = false
    return true
end

function UIController.startSettingsSaver()
    local token = getgenv().HubSessionToken
    task.spawn(function()
        while token and getgenv().HubSessionToken == token do
            local settings = UIController.Settings
            if settings.Dirty then
                settings.Dirty = false
                pcall(writefile, settings.Path, httpService:JSONEncode(settings.Values))
            end
            task.wait(2)
        end
    end)
end

UIController.FastModeActive = false
UIController.FastModeConn = nil

local function stripTexture(v)
    pcall(function()
        if v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
            v.Texture = ""
        elseif v:IsA("SurfaceAppearance") then
            v:Destroy()
        elseif v:IsA("MeshPart") then
            v.TextureID = ""
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false
        elseif v:IsA("SpecialMesh") then
            v.TextureId = ""
        elseif v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false
        elseif v:IsA("Shirt") then
            v.ShirtTemplate = ""
        elseif v:IsA("Pants") then
            v.PantsTemplate = ""
        elseif v:IsA("ShirtGraphic") then
            v.Graphic = ""
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") or v:IsA("Beam") or v:IsA("Highlight") then
            v.Enabled = false
        elseif v:IsA("PostProcessEffect") or v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BlurEffect") then
            v.Enabled = false
        elseif v:IsA("Sky") then
            v.SkyboxBk = ""
            v.SkyboxDn = ""
            v.SkyboxFt = ""
            v.SkyboxLf = ""
            v.SkyboxRt = ""
            v.SkyboxUp = ""
            v.SunTextureId = ""
            v.MoonTextureId = ""
        elseif v:IsA("Clouds") then
            v.Enabled = false
        end
    end)
end

local function applyFastMode(enabled)
    UIController.FastModeActive = enabled == true
    if UIController.FastModeConn then
        UIController.FastModeConn:Disconnect()
        UIController.FastModeConn = nil
    end
    if not UIController.FastModeActive then
        return
    end
    pcall(function()
        local lightingService = cloneref(game:GetService("Lighting"))
        lightingService.GlobalShadows = false
        lightingService.FogEnd = 9e9
        lightingService.ShadowSoftness = 0
        for _, effect in ipairs(lightingService:GetChildren()) do
            stripTexture(effect)
        end
    end)
    pcall(function()
        local terrain = workspaceService:FindFirstChildOfClass("Terrain")
        if terrain then
            pcall(function() terrain.WaterWaveSize = 0 end)
            pcall(function() terrain.WaterWaveSpeed = 0 end)
            for _, c in ipairs(terrain:GetDescendants()) do
                stripTexture(c)
            end
        end
    end)
    for _, v in ipairs(workspaceService:GetDescendants()) do
        stripTexture(v)
    end
    if setfpscap then
        pcall(setfpscap, 60)
    end
    UIController.FastModeConn = workspaceService.DescendantAdded:Connect(function(v)
        if UIController.FastModeActive then
            stripTexture(v)
        end
    end)
end

function UIController.createMobileToggle()
    local existing = game:GetService("CoreGui"):FindFirstChild("HubMobileToggleGui") or (localPlayer:FindFirstChild("PlayerGui") and localPlayer.PlayerGui:FindFirstChild("HubMobileToggleGui"))
    if existing then
        existing:Destroy()
    end

    local parent = nil
    pcall(function()
        if gethui then
            parent = gethui()
        end
    end)
    if not parent then
        pcall(function()
            parent = game:GetService("CoreGui")
        end)
    end
    if not parent then
        parent = localPlayer:FindFirstChildOfClass("PlayerGui")
    end
    if not parent then
        return
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HubMobileToggleGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local button = Instance.new("TextButton")
    button.Name = "ToggleButton"
    button.Size = UDim2.fromOffset(50, 50)
    button.Position = UDim2.new(0, 15, 0.5, -25)
    button.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    button.BackgroundTransparency = 0.15
    button.BorderSizePixel = 0
    button.Text = "HUB"
    button.TextColor3 = Color3.fromRGB(235, 235, 245)
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.Active = true
    button.AutoButtonColor = false
    button.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Name = "Stroke"
    stroke.Color = Color3.fromRGB(80, 80, 95)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2
    stroke.Parent = button

    local dragging = false
    local dragStart = nil
    local startPos = nil
    local movedFar = false

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = button.Position
            movedFar = false
        end
    end)

    button.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 6 then
                movedFar = true
            end
            button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local function finishDrag(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            if not movedFar and getgenv().HubWindow then
                local nextState = not getgenv().HubWindow:GetState()
                getgenv().HubWindow:SetState(nextState)
                if stroke then
                    stroke.Color = nextState and Color3.fromRGB(110, 150, 255) or Color3.fromRGB(80, 80, 95)
                    button.TextColor3 = nextState and Color3.fromRGB(110, 150, 255) or Color3.fromRGB(235, 235, 245)
                end
            end
        end
    end

    button.InputEnded:Connect(finishDrag)
    screenGui.Parent = parent
    UIController.MobileToggleGui = screenGui
    UIController.applyFastMode = applyFastMode
    if not UIController.MobileToggleConnected then
        UIController.MobileToggleConnected = true
        localPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            if not UIController.MobileToggleGui or not UIController.MobileToggleGui.Parent then
                UIController.createMobileToggle()
            end
        end)
    end
end

function UIController.Init()
    local questOptionsList = {}
    for qName, qInfo in pairs(questData.Main) do
        if string.find(qName, "^Quest%s") then
            local minLvl = (qInfo.LevelRanging and qInfo.LevelRanging[1]) or 0
            local maxLvl = (qInfo.LevelRanging and qInfo.LevelRanging[2]) or 0
            table.insert(questOptionsList, { Name = qName, MinLevel = minLvl, MaxLevel = maxLvl })
        end
    end

    table.sort(questOptionsList, function(a, b)
        return a.MinLevel < b.MinLevel
    end)

    local questLabels = {}
    local questNameByLabel = {}
    for _, item in ipairs(questOptionsList) do
        local label = string.format("[Lv. %d - %d] %s", item.MinLevel, item.MaxLevel, item.Name)
        table.insert(questLabels, label)
        questNameByLabel[label] = item.Name
    end

    if #questOptionsList > 0 then
        State.SelectedQuest = questOptionsList[1].Name
    end

    if getgenv().HubWindow then
        pcall(function()
            getgenv().HubWindow:Unload()
        end)
        getgenv().HubWindow = nil
    end

    local Window = MacLib:Window({
        Title = "Auto Farm Hub",
        Subtitle = "Universal Edition (" .. tostring(UIController.Username or "Default") .. ")",
        Size = UDim2.fromOffset(800, 500),
        DragStyle = 1
    })
    getgenv().HubWindow = Window

    local TabGroup = Window:TabGroup()
    local MainTab = TabGroup:Tab({ Name = "Automation", Image = "rbxassetid://10723407389" })
    local StatTab = TabGroup:Tab({ Name = "Stats", Image = "rbxassetid://10723407389" })
    local BossTab = TabGroup:Tab({ Name = "Bosses", Image = "rbxassetid://10723407389" })
    local UnlockTab = TabGroup:Tab({ Name = "Unlock", Image = "rbxassetid://10723407389" })
    local ExtrasTab = TabGroup:Tab({ Name = "Extras", Image = "rbxassetid://10723407389" })
    UIController.Toggles = {}
    for _, tab in ipairs({ MainTab, StatTab, BossTab, UnlockTab, ExtrasTab }) do
        UIController.trackToggles(tab)
    end

    local leftSection = MainTab:Section({ Side = "Left" })
    local rightSection = MainTab:Section({ Side = "Right" })

    leftSection:Header({ Text = "Combat & Weapon Settings" })
    UIController.WeaponTypeDropdown = leftSection:Dropdown({
        Name = "Farm Weapon Types (Multi-Select)",
        Multi = true,
        Required = false,
        Options = Combat.TypeOrder,
        Default = { "Sword", "Ability" },
        Callback = function(value)
            if typeof(value) == "string" then
                State.FarmCombatTypes[value] = not State.FarmCombatTypes[value]
            else
                local selected = parseMultiSelection(value)
                for _, typeName in ipairs(Combat.TypeOrder) do
                    State.FarmCombatTypes[typeName] = selected[typeName] == true
                end
            end
            Combat.Rotation.SwitchedAt = 0
        end
    })

    local skillDropdownCreated = pcall(function()
        UIController.SkillDropdown = leftSection:Dropdown({
            Name = "Farm Skills (Multi-Select)",
            Search = true,
            Multi = true,
            Required = false,
            Options = skillKeyOrder,
            Default = { "Z", "X", "C" },
            Callback = function(value)
                Combat.SpecialKeys = {}
                State.CombatStatus = "Idle"
                if typeof(value) == "string" then
                    State.FarmSkills[string.upper(value)] = not State.FarmSkills[string.upper(value)]
                    return
                end
                local selected = parseMultiSelection(value)
                for _, key in ipairs(skillKeyOrder) do
                    State.FarmSkills[key] = selected[key] == true
                end
            end
        })
    end)

    if not skillDropdownCreated then
        for _, key in ipairs(skillKeyOrder) do
            leftSection:Toggle({
                Name = "Skill " .. key,
                Default = State.FarmSkills[key] == true,
                Callback = function(value)
                    Combat.SpecialKeys = {}
                    State.CombatStatus = "Idle"
                    State.FarmSkills[key] = value
                end
            })
        end
    end

    leftSection:Toggle({
        Name = "Auto Use Skills",
        Default = true,
        Callback = function(value)
            State.AutoUseSkills = value
        end
    })

    leftSection:Dropdown({
        Name = "Farm Position",
        Options = { "Above", "Behind", "Below" },
        Default = 3,
        Callback = function(selectedName)
            State.FarmPosition = selectedName
        end
    })

    pcall(function()
        leftSection:Slider({
            Name = "Farm Distance",
            Default = 25,
            Minimum = 3,
            Maximum = 60,
            DisplayMethod = "Value",
            Precision = 1,
            Callback = function(value)
                State.FarmDistance = value
            end
        })
    end)

    leftSection:Header({ Text = "General Farming" })
    UIController.LevelToggle = leftSection:Toggle({
        Name = "Auto Farm Level",
        Default = false,
        Callback = function(value)
            if UIController.IsSyncingUI then
                return
            end

            if value then
                UIController.stopOthers("level")
                FarmLevel.Start()
            else
                FarmLevel.Stop()
            end
        end
    })

    UIController.QuestDropdown = leftSection:Dropdown({
        Name = "Select Farm Quest",
        Options = questLabels,
        Default = 1,
        Callback = function(selectedLabel)
            State.SelectedQuest = questNameByLabel[selectedLabel] or selectedLabel
        end
    })

    UIController.QuestToggle = leftSection:Toggle({
        Name = "Auto Farm Selected Quest",
        Default = false,
        Callback = function(value)
            if UIController.IsSyncingUI then
                return
            end

            if value then
                UIController.stopOthers("quest")
                FarmQuest.Start()
            else
                FarmQuest.Stop()
            end
        end
    })

    Extras.loadMobSpawns()
    leftSection:Dropdown({
        Name = "Select Mobs To Farm (Multi-Select)",
        Search = true,
        Multi = true,
        Required = false,
        Options = Extras.getMobFarmOptions(),
        Default = {},
        Callback = function(value)
            if typeof(value) == "string" then
                State.MobFarmSelection[value] = (not State.MobFarmSelection[value]) or nil
                return
            end
            State.MobFarmSelection = parseMultiSelection(value)
        end
    })

    UIController.MobFarmToggle = leftSection:Toggle({
        Name = "Auto Farm Selected Mobs",
        Default = false,
        Callback = function(value)
            if UIController.IsSyncingUI then
                return
            end

            if value then
                UIController.stopOthers("mob")
                Extras.MobFarmCursor = 1
                Extras.startLoop("MobFarmEnabled", Extras.runMobFarmCycle)
            else
                Extras.stopLoop("MobFarmEnabled", "mob")
                State.MobFarmStatus = "Idle"
                removeFloat(getRoot())
            end
        end
    })

    UIController.PrestigeToggle = leftSection:Toggle({
        Name = "Auto Prestige",
        Default = false,
        Callback = function(value)
            if value then
                if not UIController.Restoring then
                    local halt = Extras.Twoh.loadState().Halt
                    if Extras.Twoh.HaltReason or (typeof(halt) == "string" and halt ~= "") then
                        Extras.Twoh.HaltReason = nil
                        Extras.Twoh.saveState({ Halt = "", LoseStreak = 0 })
                    end
                    Extras.Twoh.PrestigeGiveUpUntil = nil
                    Prestige.DungeonBlocked = {}
                end
                Prestige.Start()
            else
                Prestige.Stop()
            end
        end
    })

    rightSection:Header({ Text = "Live Status" })
    UIController.StatusParagraph = rightSection:Paragraph({
        Header = "Hub Status",
        Body = "waiting for data"
    })

    rightSection:Header({ Text = "World Pickup" })
    UIController.PickupToggle = rightSection:Toggle({
        Name = "Auto Pickup (timed spawns first, then nearby)",
        Default = false,
        Callback = function(value)
            if value then
                AutoPickup.Start()
            else
                AutoPickup.Stop()
            end
        end
    })

    local defaultPickupTargets = {}
    for _, itemName in ipairs(AutoPickup.TimedItems) do
        if State.PickupTargets[itemName] then
            table.insert(defaultPickupTargets, itemName)
        end
    end
    rightSection:Dropdown({
        Name = "Pickup Items (timed spawns)",
        Search = true,
        Multi = true,
        Required = false,
        Options = AutoPickup.TimedItems,
        Default = defaultPickupTargets,
        Callback = function(value)
            if typeof(value) == "string" then
                State.PickupTargets[value] = not State.PickupTargets[value]
                return
            end
            local selected = parseMultiSelection(value)
            for _, itemName in ipairs(AutoPickup.TimedItems) do
                State.PickupTargets[itemName] = selected[itemName] == true
            end
        end
    })

    rightSection:Header({ Text = "Auto Code" })
    UIController.CodeToggle = rightSection:Toggle({
        Name = "Auto Code Loop",
        Default = false,
        Callback = function(value)
            if value then
                AutoCode.Start()
            else
                AutoCode.Stop()
            end
        end
    })

    rightSection:Button({
        Name = "Redeem All Codes Now",
        Callback = function()
            task.spawn(function()
                AutoCode.redeemAll()
            end)
        end
    })

    rightSection:Header({ Text = "Auto Open Chests" })
    local chestCatalog = AutoChest.getCatalog()
    for _, chestName in ipairs(chestCatalog) do
        State.ChestSelection[chestName] = true
    end
    local chestDropdownCreated = pcall(function()
        rightSection:Dropdown({
            Name = "Select Chests (Multi-Select)",
            Search = true,
            Multi = true,
            Required = false,
            Options = chestCatalog,
            Default = chestCatalog,
            Callback = function(value)
                if typeof(value) == "string" then
                    State.ChestSelection[value] = (not State.ChestSelection[value]) or nil
                    return
                end
                State.ChestSelection = parseMultiSelection(value)
            end
        })
    end)

    if not chestDropdownCreated then
        for _, chestName in ipairs(chestCatalog) do
            rightSection:Toggle({
                Name = chestName,
                Default = true,
                Callback = function(value)
                    State.ChestSelection[chestName] = value or nil
                end
            })
        end
    end

    UIController.ChestToggle = rightSection:Toggle({
        Name = "Auto Open Selected Chests",
        Default = false,
        Callback = function(value)
            if value then
                AutoChest.Start()
            else
                AutoChest.Stop()
            end
        end
    })

    local statLeft = StatTab:Section({ Side = "Left" })
    local statRight = StatTab:Section({ Side = "Right" })

    statLeft:Header({ Text = "Priority Order Auto Stats" })
    statLeft:Toggle({
        Name = "Auto Stats Enabled",
        Default = State.AutoStatEnabled,
        Callback = function(value)
            State.AutoStatEnabled = value == true
            if State.AutoStatEnabled then
                task.spawn(autoAllocateStats)
            end
        end
    })

    UIController.StatDropdowns = {}
    local slotLabels = { "1st Priority", "2nd Priority", "3rd Priority", "4th Priority" }
    UIController.StatSlotLabels = slotLabels

    for slotIndex, slotLabel in ipairs(slotLabels) do
        local defaultIndex = 1
        for index, statName in ipairs(statNames) do
            if statName == State.StatPriority[slotIndex] then
                defaultIndex = index
                break
            end
        end

        UIController.StatDropdowns[slotIndex] = statLeft:Dropdown({
            Name = slotLabel,
            Options = StatMeta.Options,
            Default = defaultIndex,
            Callback = function(selectedName)
                local statName = typeof(selectedName) == "string" and (StatMeta.FromDisplay[selectedName] or selectedName)
                if statName and statLookup[statName] then
                    UIController.setStatPriority(slotIndex, statName)
                end
            end
        })
    end
    UIController.syncStatDropdowns()

    statLeft:Button({
        Name = "Allocate Points Now",
        Callback = function()
            task.spawn(autoAllocateStats)
        end
    })

    statRight:Header({ Text = "Stat Overview" })
    UIController.StatParagraph = statRight:Paragraph({
        Header = "Priority & Values",
        Body = "waiting for data"
    })

    statRight:Header({ Text = "Prestige Requirements" })
    UIController.PrestigeParagraph = statRight:Paragraph({
        Header = "Next Prestige",
        Body = "waiting for data"
    })

    local bossLeft = BossTab:Section({ Side = "Left" })
    local bossRight = BossTab:Section({ Side = "Right" })

    do
        local quincyStatueOptions = {
            "As Nodt",
            "Askin Nakk Le Vaar",
            "Bambietta Basterbine",
            "Gremmy Thoumeaux",
            "Jugram Haschwalth"
        }

        local altarBossOptions = {
            "One-Eyed Owl",
            "Cid Kagenou",
            "The Red Mist",
            "Demon Infernal",
            "Dio"
        }

        local whispererBossOptions = {
            "Sosuke Aizen",
            "Ichigo Kurosaki",
            "Ichigo Kurosaki Bankai",
            "Ichigo True Bankai",
            "Satoru Gojo",
            "Ryomen Sukuna",
            "Garou",
            "Blast",
            "Flashy Flash",
            "Ken Kaneki",
            "Akaza",
            "Chihora",
            "Solemn Lament",
            "Chad",
            "Undyne",
            "Fishman Captain"
        }

        local function getDefaults(options)
            local defaults = {}
            for _, opt in ipairs(options) do
                if State.BossSelection[opt] then
                    table.insert(defaults, opt)
                end
            end
            return defaults
        end

        bossLeft:Header({ Text = "Quick Actions" })
        bossLeft:Button({
            Name = "Clear All Selected Bosses",
            Callback = function()
                State.BossSelection = {}
                pcall(function()
                    if UIController.YhwachGlobalToggle then
                        UIController.YhwachGlobalToggle:UpdateState(false)
                    end
                    if UIController.YhwachSummonToggle then
                        UIController.YhwachSummonToggle:UpdateState(false)
                    end
                    if UIController.AltarDropdown then
                        UIController.AltarDropdown:UpdateSelection({})
                    end
                    if UIController.QuincyDropdown then
                        UIController.QuincyDropdown:UpdateSelection({})
                    end
                    if UIController.WhispererDropdown then
                        UIController.WhispererDropdown:UpdateSelection({})
                    end
                end)
            end
        })

        bossLeft:Button({
            Name = "Select All Altar Bosses",
            Callback = function()
                local map = {}
                for _, name in ipairs(altarBossOptions) do
                    State.BossSelection[name] = true
                    map[name] = true
                end
                pcall(function()
                    if UIController.AltarDropdown then
                        UIController.AltarDropdown:UpdateSelection(map)
                    end
                end)
            end
        })

        bossLeft:Button({
            Name = "Select All Quincy Statues",
            Callback = function()
                local map = {}
                for _, name in ipairs(quincyStatueOptions) do
                    State.BossSelection[name] = true
                    map[name] = true
                end
                pcall(function()
                    if UIController.QuincyDropdown then
                        UIController.QuincyDropdown:UpdateSelection(map)
                    end
                end)
            end
        })

        bossLeft:Header({ Text = "Yhwach Bosses" })
        UIController.YhwachGlobalToggle = bossLeft:Toggle({
            Name = "Yhwach (Global Boss)",
            Default = State.BossSelection["Yhwach (Global Boss)"] == true or State.BossSelection["Yhwach"] == true,
            Callback = function(value)
                State.BossSelection["Yhwach (Global Boss)"] = value or nil
                State.BossSelection["Yhwach"] = value or nil
            end
        })

        UIController.YhwachSummonToggle = bossLeft:Toggle({
            Name = "Yhwach (Summoned - Auto 5 Statues)",
            Default = State.BossSelection["Yhwach (Summoned)"] == true or State.BossSelection["Yhwach Not Dungeon"] == true,
            Callback = function(value)
                State.BossSelection["Yhwach (Summoned)"] = value or nil
                State.BossSelection["Yhwach Not Dungeon"] = value or nil
            end
        })

        bossLeft:Header({ Text = "Altar Summon Bosses" })
        UIController.AltarDropdown = bossLeft:Dropdown({
            Name = "Altar Bosses (Multi-Select)",
            Multi = true,
            Required = false,
            Options = altarBossOptions,
            Default = getDefaults(altarBossOptions),
            Callback = function(value)
                if typeof(value) == "string" then
                    State.BossSelection[value] = (not State.BossSelection[value]) or nil
                    return
                end
                local selected = parseMultiSelection(value)
                for _, opt in ipairs(altarBossOptions) do
                    State.BossSelection[opt] = selected[opt] == true or nil
                end
            end
        })

        bossLeft:Header({ Text = "Quincy Statues (Material Farm)" })
        UIController.QuincyDropdown = bossLeft:Dropdown({
            Name = "Quincy Statues (Multi-Select)",
            Multi = true,
            Required = false,
            Options = quincyStatueOptions,
            Default = getDefaults(quincyStatueOptions),
            Callback = function(value)
                if typeof(value) == "string" then
                    State.BossSelection[value] = (not State.BossSelection[value]) or nil
                    return
                end
                local selected = parseMultiSelection(value)
                for _, opt in ipairs(quincyStatueOptions) do
                    State.BossSelection[opt] = selected[opt] == true or nil
                end
            end
        })

        bossLeft:Header({ Text = "Whisperer Bosses" })
        UIController.WhispererDropdown = bossLeft:Dropdown({
            Name = "Whisperer Bosses (Multi-Select)",
            Search = true,
            Multi = true,
            Required = false,
            Options = whispererBossOptions,
            Default = getDefaults(whispererBossOptions),
            Callback = function(value)
                if typeof(value) == "string" then
                    State.BossSelection[value] = (not State.BossSelection[value]) or nil
                    return
                end
                local selected = parseMultiSelection(value)
                for _, opt in ipairs(whispererBossOptions) do
                    State.BossSelection[opt] = selected[opt] == true or nil
                end
            end
        })
    end

    bossRight:Header({ Text = "Boss Farming" })
    UIController.BossToggle = bossRight:Toggle({
        Name = "Auto Farm Selected Bosses",
        Default = false,
        Callback = function(value)
            if UIController.IsSyncingUI then
                return
            end

            if value then
                UIController.stopOthers("boss")
                BossFarm.Start()
            else
                BossFarm.Stop()
            end
        end
    })

    bossRight:Toggle({
        Name = "Auto Summon Boss When Missing",
        Default = State.AutoSummonBoss,
        Callback = function(value)
            State.AutoSummonBoss = value
        end
    })

    bossRight:Toggle({
        Name = "Auto Buy Boss Ticket (Gold Shop)",
        Default = State.AutoBuyBossTicket,
        Callback = function(value)
            State.AutoBuyBossTicket = value
        end
    })

    bossRight:Toggle({
        Name = "Auto Farm Missing Prestige Bosses",
        Default = false,
        Callback = function(value)
            State.PrestigeBossAutoTarget = value
        end
    })

    local difficultyOptions = {}
    for _, difficultyName in ipairs(summonDifficultyData.Order or { "Normal" }) do
        table.insert(difficultyOptions, difficultyName)
    end
    bossRight:Dropdown({
        Name = "Summon Difficulty",
        Options = difficultyOptions,
        Default = 1,
        Callback = function(selectedName)
            State.BossDifficulty = selectedName
        end
    })

    bossRight:Header({ Text = "Boss Overview" })
    UIController.BossParagraph = bossRight:Paragraph({
        Header = "Targets",
        Body = "waiting for data"
    })

    local unlockLeft = UnlockTab:Section({ Side = "Left" })
    local unlockRight = UnlockTab:Section({ Side = "Right" })

    for _, categoryName in ipairs({ "Style", "Weapon", "Ability" }) do
        local missingList = UnlockFarm.getMissing(categoryName)
        local farmableList = {}

        for _, itemName in ipairs(missingList) do
            if unlockRecipes[itemName] or #UnlockFarm.getQuestChainForItem(itemName) > 0 then
                table.insert(farmableList, itemName)
            end
        end

        local optionList = farmableList
        if #optionList == 0 then
            optionList = missingList
        end
        if #optionList == 0 then
            optionList = UnlockFarm.getCatalog(categoryName)
        end

        State.UnlockTargets[categoryName] = optionList[1]

        unlockLeft:Header({ Text = categoryName .. " (" .. tostring(#farmableList) .. " farmable / " .. tostring(#missingList) .. " missing)" })
        unlockLeft:Dropdown({
            Name = "Select " .. categoryName,
            Options = optionList,
            Default = 1,
            Callback = function(selectedName)
                State.UnlockTargets[categoryName] = selectedName
            end
        })
    end

    unlockRight:Header({ Text = "Auto Unlock" })
    unlockRight:Dropdown({
        Name = "Farm Category",
        Options = { "Style", "Weapon", "Ability" },
        Default = 1,
        Callback = function(selectedName)
            State.UnlockCategory = selectedName
        end
    })

    UIController.UnlockToggle = unlockRight:Toggle({
        Name = "Auto Unlock Selected",
        Default = false,
        Callback = function(value)
            if UIController.IsSyncingUI then
                return
            end

            if value then
                UIController.stopOthers("unlock")
                UnlockFarm.Start()
            else
                UnlockFarm.Stop()
            end
        end
    })

    unlockRight:Button({
        Name = "Force Dialogue Step",
        Callback = function()
            task.spawn(function()
                autoDialogue(nil, nil, 4)
            end)
        end
    })

    unlockRight:Header({ Text = "Unlock Overview" })
    UIController.UnlockParagraph = unlockRight:Paragraph({
        Header = "Selected Target",
        Body = "waiting for data"
    })

    local extrasLeft = ExtrasTab:Section({ Side = "Left" })
    local extrasRight = ExtrasTab:Section({ Side = "Right" })

    Extras.loadDungeonSettings()
    extrasLeft:Header({ Text = "Dungeon" })
    extrasLeft:Toggle({
        Name = "Auto Select Difficulty",
        Default = State.DungeonAutoDifficulty,
        Callback = function(value)
            State.DungeonAutoDifficulty = value
            Extras.saveDungeonSettings()
        end
    })

    local difficultyDefault = 3
    for index, difficultyName in ipairs(Extras.DungeonDifficulties) do
        if difficultyName == State.DungeonDifficulty then
            difficultyDefault = index
        end
    end
    extrasLeft:Dropdown({
        Name = "Dungeon Difficulty",
        Options = Extras.DungeonDifficulties,
        Default = difficultyDefault,
        Callback = function(selectedName)
            State.DungeonDifficulty = selectedName
            Extras.saveDungeonSettings()
        end
    })

    extrasLeft:Toggle({
        Name = "Auto Replay Dungeon",
        Default = State.DungeonAutoReplay,
        Callback = function(value)
            State.DungeonAutoReplay = value
            Extras.saveDungeonSettings()
        end
    })

    local dungeonOptions = Extras.getDungeonOptions()
    extrasLeft:Dropdown({
        Name = "Auto Dungeon Target",
        Options = dungeonOptions,
        Default = table.find(dungeonOptions, State.AutoDungeonTarget) or 1,
        Callback = function(selectedName)
            if typeof(selectedName) == "string" then
                State.AutoDungeonTarget = selectedName
            end
        end
    })

    UIController.DungeonToggle = extrasLeft:Toggle({
        Name = "Auto Dungeon (enter + farm + replay)",
        Default = false,
        Callback = function(value)
            if UIController.IsSyncingUI then
                return
            end
            if value then
                Extras.startLoop("AutoDungeonEnabled", Extras.runDungeonCycle)
            else
                Extras.stopLoop("AutoDungeonEnabled", "dungeon")
                State.ExtraStatus = "Dungeon: stopped"
            end
        end
    })

    if State.DungeonAutoDifficulty or State.DungeonAutoReplay then
        Extras.saveDungeonSettings()
    end

    extrasLeft:Header({ Text = "Trait Reroll" })
    extrasLeft:Dropdown({
        Name = "Stop On Trait (Multi-Select)",
        Search = true,
        Multi = true,
        Required = false,
        Options = Extras.getTraitOptions(),
        Default = {},
        Callback = function(value)
            if typeof(value) == "string" then
                local toggledTrait = Extras.TraitByLabel[value] or value
                State.TraitTargets[toggledTrait] = (not State.TraitTargets[toggledTrait]) or nil
                return
            end
            local selectedLabels = parseMultiSelection(value)
            local newTargets = {}
            for label in pairs(selectedLabels) do
                newTargets[Extras.TraitByLabel[label] or label] = true
            end
            State.TraitTargets = newTargets
        end
    })

    UIController.TraitToggle = extrasLeft:Toggle({
        Name = "Auto Reroll Trait",
        Default = false,
        Callback = function(value)
            if UIController.IsSyncingUI then
                return
            end
            if value then
                Extras.TraitRolls = 0
                Extras.startLoop("AutoTraitEnabled", Extras.runTraitCycle)
            else
                Extras.stopLoop("AutoTraitEnabled")
                State.ExtraStatus = "Trait: stopped"
            end
        end
    })

    extrasLeft:Header({ Text = "Fishing" })
    UIController.FishToggle = extrasLeft:Toggle({
        Name = "Auto Fishing (Fast)",
        Default = false,
        Callback = function(value)
            if UIController.IsSyncingUI then
                return
            end
            if value then
                Extras.startFastFishing()
            else
                Extras.stopFishing()
                State.FishStatus = "stopped"
            end
        end
    })

    extrasLeft:Toggle({
        Name = "Fish At Whale Event (with Auto Fishing)",
        Default = false,
        Callback = function(value)
            if value then
                Extras.startLoop("AutoWhaleEnabled", Extras.runWhaleCycle)
            else
                Extras.stopLoop("AutoWhaleEnabled", "whale")
                Extras.endWhaleEvent()
                State.ExtraStatus = "Whale: stopped"
            end
        end
    })

    UIController.DeepsharkToggle = extrasLeft:Toggle({
        Name = "Auto Ancient Deepshark (uses Abyssal Bait)",
        Default = false,
        Callback = function(value)
            if UIController.IsSyncingUI then
                return
            end
            if value then
                Extras.DeepsharkKillsAtStart = Extras.getDeepsharkKillStat()
                Extras.DeepSeaIndex = 1
                Extras.startLoop("AutoDeepsharkEnabled", Extras.runDeepsharkCycle)
            else
                Extras.stopLoop("AutoDeepsharkEnabled", "deepshark")
                Extras.endDeepsharkFishing()
                Extras.releaseDeepsharkPriority()
                State.ExtraStatus = "Deepshark: stopped"
            end
        end
    })

    extrasRight:Header({ Text = "World Events" })

    extrasRight:Toggle({
        Name = "Auto Coffin Page (Mysterious Stranger)",
        Default = false,
        Callback = function(value)
            if value then
                Extras.watchCoffins()
                Extras.startLoop("AutoCoffinEnabled", Extras.runCoffinCycle)
            else
                Extras.stopLoop("AutoCoffinEnabled", "coffin")
                State.ExtraStatus = "Coffin: stopped"
            end
        end
    })

    UIController.FireForceTrialToggle = extrasRight:Toggle({
        Name = "Auto Fire Force Trial (Captain Burns)",
        Default = false,
        Callback = function(value)
            if UIController.IsSyncingUI then
                return
            end
            if value then
                Extras.startLoop("AutoFireForceTrialEnabled", Extras.runFireForceTrialCycle)
            else
                Extras.stopLoop("AutoFireForceTrialEnabled", "fireforce")
                State.ExtraStatus = "Fire Force: stopped"
            end
        end
    })

    UIController.AmbushOnlyToggle = extrasRight:Toggle({
        Name = "Auto Ambush",
        Default = false,
        Callback = function(value)
            if UIController.IsSyncingUI then
                return
            end
            if value then
                Extras.NextAmbushAt = 0
                Extras.startLoop("AutoAmbushOnlyEnabled", Extras.runAmbushOnlyCycle)
            else
                Extras.stopLoop("AutoAmbushOnlyEnabled", "ambushonly")
                State.ExtraStatus = "Ambush: stopped"
            end
        end
    })

    extrasRight:Toggle({
        Name = "Auto Fire Fighter Company",
        Default = false,
        Callback = function(value)
            if value then
                Extras.DutyBlockedUntil = {}
                Extras.NextAmbushAt = 0
                Extras.startLoop("AutoAmbushEnabled", Extras.runAmbushCycle)
            else
                Extras.stopLoop("AutoAmbushEnabled", "ambush")
                State.ExtraStatus = "Fire Company: stopped"
            end
        end
    })

    extrasRight:Header({ Text = "Araya" })
    UIController.ArayaToggle = extrasRight:Toggle({
        Name = "Auto Araya (Lost Afterimage)",
        Default = false,
        Callback = function(value)
            if UIController.IsSyncingUI then
                return
            end
            if value then
                Extras.saveArayaSettings(true, 0)
                Extras.startLoop("AutoArayaEnabled", Extras.runArayaCycle)
            else
                Extras.saveArayaSettings(false)
                Extras.stopLoop("AutoArayaEnabled", "araya")
                State.FarmDistanceOverride = nil
                State.ExtraStatus = "Araya: stopped"
            end
        end
    })

    extrasRight:Header({ Text = "The World Over Heaven" })
    UIController.TwohToggle = extrasRight:Toggle({
        Name = "Auto TWOH (Dio / Earthly Proofs)",
        Default = false,
        Callback = function(value)
            if UIController.IsSyncingUI then
                return
            end
            if value then
                Extras.Twoh.AcceptSeenAt = {}
                if not UIController.Restoring then
                    Extras.Twoh.HaltReason = nil
                    Extras.Twoh.saveState({ Halt = "", LoseStreak = 0 })
                end
                Extras.startLoop("AutoTwohEnabled", Extras.Twoh.runCycle)
            else
                Extras.Twoh.stop(false)
                State.ExtraStatus = "TWOH: stopped"
            end
        end
    })

    UIController.YhwachToggle = extrasRight:Toggle({
        Name = "Auto Yhwach (Quincy Herald)",
        Default = false,
        Callback = function(value)
            if UIController.IsSyncingUI then
                return
            end
            if value then
                Extras.Yhwach.GraceSeen = {}
                Extras.Yhwach.BusyUntil = {}
                Extras.Yhwach.Fails = 0
                if not UIController.Restoring then
                    Extras.Yhwach.data().Halt = ""
                    Extras.Yhwach.save()
                end
                Extras.startLoop("AutoYhwachEnabled", Extras.Yhwach.runCycle)
            else
                Extras.Yhwach.stop(false)
                Extras.Yhwach.status("stopped")
            end
        end
    })
    UIController.YhwachParagraph = extrasRight:Paragraph({
        Header = "Yhwach Status",
        Body = "Idle"
    })

    extrasRight:Toggle({
        Name = "Auto Over Heaven Buff (The World B)",
        Default = false,
        Callback = function(value)
            State.AutoOverHeavenEnabled = value == true
            Extras.OverHeaven.NextTryAt = 0
            Extras.OverHeaven.Fails = 0
        end
    })

    UIController.FastModeToggle = extrasRight:Toggle({
        Name = "Fast Mode / Lag Reducer (Mobile)",
        Default = false,
        Callback = function(value)
            applyFastMode(value == true)
        end
    })

    extrasRight:Header({ Text = "Ichigo Bankai" })
    UIController.BankaiToggle = extrasRight:Toggle({
        Name = "Auto Ichigo Bankai (Hollow Reaper)",
        Default = false,
        Callback = function(value)
            if UIController.IsSyncingUI then
                return
            end
            if value then
                Extras.Bankai.SeaCooldownUntil = nil
                Extras.startLoop("AutoBankaiEnabled", Extras.runBankaiCycle)
            else
                Extras.stopBankai()
                State.ExtraStatus = "Ichigo Bankai: stopped"
            end
        end
    })

    extrasRight:Header({ Text = "Solemn Lament" })
    UIController.SolemnToggle = extrasRight:Toggle({
        Name = "Auto Solemn Lament (Griefbound Ferryman)",
        Default = false,
        Callback = function(value)
            if UIController.IsSyncingUI then
                return
            end
            if value then
                Extras.Solemn.NeedOwnKill = nil
                Extras.Solemn.Escapes = 0
                Extras.startLoop("AutoSolemnEnabled", Extras.runSolemnCycle)
            else
                Extras.stopSolemn()
                State.ExtraStatus = "Solemn Lament: stopped"
            end
        end
    })

    extrasRight:Header({ Text = "Extras Status" })
    UIController.ExtrasParagraph = extrasRight:Paragraph({
        Header = "Status",
        Body = "Idle"
    })

    local ownCleanup = getgenv().HubCleanup
    Window.onUnloaded(function()
        if ownCleanup and getgenv().HubCleanup == ownCleanup then
            ownCleanup()
        end
    end)

    UIController.startStatusRefresh()
    UIController.createMobileToggle()
end

getgenv().HubUI = UIController
getgenv().State = State
getgenv().FarmLevel = FarmLevel
getgenv().FarmQuest = FarmQuest
getgenv().UnlockFarm = UnlockFarm
getgenv().AutoPickup = AutoPickup
getgenv().AutoChest = AutoChest
getgenv().Prestige = Prestige
getgenv().BossFarm = BossFarm
getgenv().Extras = Extras
getgenv().HubDebug = {
    teleportToIsland = teleportToIsland,
    teleportToSpot = teleportToSpot,
    safeTravelTo = safeTravelTo,
    travelToNPC = travelToNPC,
    talkToNPC = talkToNPC,
    getTargetEnemy = getTargetEnemy,
    getMobAnchor = getMobAnchor,
    getMaterialPlan = getMaterialPlan,
    describeMaterialPlan = describeMaterialPlan,
    getNearestIslandName = getNearestIslandName,
    getDialogueChoices = getDialogueChoices,
    autoAllocateStats = autoAllocateStats,
    getCombatSnapshot = function()
        return {
            LockedEnemyRoot = lockedEnemyRoot,
            LockedTargetCFrame = lockedTargetCFrame,
            TravelActive = travelActive,
            Tweening = currentTween ~= nil,
            PickupActive = pickupActive,
            MovementOwner = movementOwner,
            Combat = Combat
        }
    end,
    setDebugActive = function(value)
        debugActive = value == true
    end
}

Extras.Session = {
    Path = Extras.SessionPath or "LEGACY PIECE/hub_session.json",
    LogPath = "LEGACY PIECE/LP_disconnects.txt",
    MaxAge = 43200,
    MainPlaceId = 111097829542198,
    LastFlags = {},
    Map = {
        { "AutoStatEnabled", "Auto Stats Enabled" },
        { "AutoSummonBoss", "Auto Summon Boss When Missing" },
        { "AutoBuyBossTicket", "Auto Buy Boss Ticket (Gold Shop)" },
        { "PrestigeBossAutoTarget", "Auto Farm Missing Prestige Bosses" },
        { "AutoPickupEnabled", "Auto Pickup (timed spawns first, then nearby)" },
        { "AutoCodeEnabled", "Auto Code Loop" },
        { "AutoChestEnabled", "Auto Open Selected Chests" },
        { "FarmLevelEnabled", "Auto Farm Level" },
        { "BossFarmEnabled", "Auto Farm Selected Bosses" },
        { "PrestigeEnabled", "Auto Prestige" },
        { "AutoFishEnabled", "Auto Fishing (Fast)" },
        { "AutoDeepsharkEnabled", "Auto Ancient Deepshark (uses Abyssal Bait)" },
        { "AutoWhaleEnabled", "Fish At Whale Event (with Auto Fishing)" },
        { "AutoCoffinEnabled", "Auto Coffin Page (Mysterious Stranger)" },
        { "AutoFireForceTrialEnabled", "Auto Fire Force Trial (Captain Burns)" },
        { "AutoAmbushOnlyEnabled", "Auto Ambush" },
        { "AutoAmbushEnabled", "Auto Fire Fighter Company" },
        { "AutoBankaiEnabled", "Auto Ichigo Bankai (Hollow Reaper)" },
        { "AutoSolemnEnabled", "Auto Solemn Lament (Griefbound Ferryman)" },
        { "AutoDungeonEnabled", "Auto Dungeon (enter + farm + replay)" },
        { "AutoTwohEnabled", "Auto TWOH (Dio / Earthly Proofs)" },
        { "AutoYhwachEnabled", "Auto Yhwach (Quincy Herald)" }
    }
}

function Extras.saveSession()
    local session = Extras.Session
    local flags = {}
    for _, entry in ipairs(session.Map) do
        if State[entry[1]] == true and not (entry[1] == "AutoDeepsharkEnabled" and Extras.DeepsharkDelegated) then
            table.insert(flags, entry[1])
        end
    end
    session.LastFlags = flags
    local function selectionList(selection)
        local names = {}
        for name, picked in pairs(selection or {}) do
            if picked then
                table.insert(names, name)
            end
        end
        table.sort(names)
        return names
    end
    local payload = {
        Flags = flags,
        StatPriority = State.StatPriority,
        BossDifficulty = State.BossDifficulty,
        BossSelection = selectionList(State.BossSelection),
        ChestSelection = selectionList(State.ChestSelection),
        CombatTypes = selectionList(Extras.Twoh.SavedCombat and Extras.Twoh.SavedCombat.Types or State.FarmCombatTypes),
        PickupTargets = selectionList(State.PickupTargets)
    }
    local encoded = httpService:JSONEncode(payload)
    if encoded == session.LastEncoded and os.clock() - (session.LastWriteAt or 0) < 600 then
        return
    end
    session.LastEncoded = encoded
    session.LastWriteAt = os.clock()
    payload.SavedAt = os.time()
    pcall(writefile, session.Path, httpService:JSONEncode(payload))
end

function Extras.resumeSession(phase)
    local session = Extras.Session
    local saved = nil
    pcall(function()
        saved = httpService:JSONDecode(readfile(session.Path))
    end)
    if typeof(saved) ~= "table" then
        return
    end
    if phase == "flags" then
        if typeof(saved.Flags) ~= "table" or #saved.Flags == 0 or os.time() - (tonumber(saved.SavedAt) or 0) > session.MaxAge then
            return
        end
        if typeof(saved.BossSelection) == "table" then
            for _, bossName in ipairs(saved.BossSelection) do
                State.BossSelection[bossName] = true
                local toggle = UIController.Toggles[bossName]
                if toggle then
                    pcall(function()
                        toggle:UpdateState(true)
                    end)
                end
            end
        end
        local wanted = {}
        for _, flagName in ipairs(saved.Flags) do
            wanted[flagName] = true
        end
        for _, entry in ipairs(session.Map) do
            local toggle = UIController.Toggles[entry[2]]
            if wanted[entry[1]] and not State[entry[1]] and toggle then
                pcall(function()
                    toggle:UpdateState(true)
                end)
            end
        end
        return
    end
    if typeof(saved.StatPriority) == "table" and #saved.StatPriority == #statNames then
        local valid = true
        for _, statName in ipairs(saved.StatPriority) do
            valid = valid and table.find(statNames, statName) ~= nil
        end
        if valid then
            State.StatPriority = saved.StatPriority
            pcall(UIController.syncStatDropdowns)
        end
    end
    if typeof(saved.BossDifficulty) == "string" then
        State.BossDifficulty = saved.BossDifficulty
    end
    if typeof(saved.CombatTypes) == "table" and #saved.CombatTypes > 0 then
        State.FarmCombatTypes = {}
        for _, typeName in ipairs(saved.CombatTypes) do
            State.FarmCombatTypes[typeName] = true
        end
        State.FarmCombatType = State.FarmCombatTypes[State.FarmCombatType] and State.FarmCombatType or saved.CombatTypes[1]
        pcall(function()
            UIController.WeaponTypeDropdown:UpdateSelection(saved.CombatTypes)
        end)
    end
    if typeof(saved.PickupTargets) == "table" and #saved.PickupTargets > 0 then
        for itemName in pairs(State.PickupTargets) do
            State.PickupTargets[itemName] = false
        end
        for _, itemName in ipairs(saved.PickupTargets) do
            State.PickupTargets[itemName] = true
        end
    end
    if typeof(saved.ChestSelection) == "table" and #saved.ChestSelection > 0 then
        State.ChestSelection = {}
        for _, chestName in ipairs(saved.ChestSelection) do
            State.ChestSelection[chestName] = true
        end
    end
end

function Extras.startSessionSaver()
    local token = getgenv().HubSessionToken
    task.spawn(function()
        while token and getgenv().HubSessionToken == token do
            Extras.saveSession()
            task.wait(3)
        end
    end)
end

function Extras.Session.oneLine(value)
    return (string.gsub(tostring(value or ""), "[\r\n]+", " "))
end

function Extras.Session.writeLog(line)
    local path = Extras.Session.LogPath
    local exists = false
    pcall(function()
        exists = isfile(path)
    end)
    if exists and pcall(appendfile, path, line) then
        return true
    end
    local previous = ""
    if exists then
        pcall(function()
            previous = readfile(path)
        end)
    end
    return (pcall(writefile, path, previous .. line))
end

function Extras.Session.describeContext()
    local session = Extras.Session
    local yhwach = Extras.Yhwach
    local serverAge = 0
    pcall(function()
        serverAge = math.floor(workspaceService.DistributedGameTime)
    end)
    return string.format("job=%s place=%d age=%ds owner=%s priority=%s farms=%s yhwach=%s", game.JobId, game.PlaceId, serverAge, tostring(movementOwner), tostring(Extras.PriorityRequest), table.concat(session.LastFlags, ","), session.oneLine(yhwach and yhwach.StatusText or "nil"))
end

function Extras.Session.readErrorPrompt()
    local title, body = "", ""
    pcall(function()
        local promptGui = cloneref(game:GetService("CoreGui")):FindFirstChild("RobloxPromptGui")
        local overlay = promptGui and promptGui:FindFirstChild("promptOverlay")
        local errorPrompt = overlay and overlay:FindFirstChild("ErrorPrompt")
        if not errorPrompt then
            return
        end
        for _, descendant in ipairs(errorPrompt:GetDescendants()) do
            if descendant:IsA("TextLabel") then
                if descendant.Name == "ErrorTitle" then
                    title = descendant.Text
                elseif descendant.Name == "ErrorMessage" then
                    body = descendant.Text
                end
            end
        end
    end)
    return title, body
end

function Extras.connectAutoRejoin()
    for _, key in ipairs({ "HubRejoinConnection", "HubTeleportFailConnection" }) do
        if getgenv()[key] then
            pcall(function()
                getgenv()[key]:Disconnect()
            end)
            getgenv()[key] = nil
        end
    end
    local guiService = cloneref(game:GetService("GuiService"))
    local teleportService = cloneref(game:GetService("TeleportService"))
    getgenv().HubTeleportFailConnection = teleportService.TeleportInitFailed:Connect(function(_, result, errorMessage)
        local session = Extras.Session
        session.TeleportFailedAt = os.clock()
        session.writeLog(string.format("%s TELEPORT FAILED result=%s | %s | %s\n", os.date("%Y-%m-%d %X"), tostring(result), session.oneLine(errorMessage), session.describeContext()))
    end)
    getgenv().HubRejoinConnection = guiService.ErrorMessageChanged:Connect(function(message)
        local session = Extras.Session
        if typeof(message) ~= "string" or message == "" or session.Rejoining then
            return
        end
        local context = session.describeContext()
        local errorCode = "unknown"
        pcall(function()
            local code = guiService:GetErrorCode()
            errorCode = string.format("%s(%d)", code.Name, code.Value)
        end)
        task.wait(0.5)
        local promptTitle, promptBody = session.readErrorPrompt()
        local kickMessage = ""
        if string.find(errorCode, "Kick", 1, true) or string.find(string.lower(message), "kick", 1, true) then
            kickMessage = message
        end
        session.writeLog(string.format("%s DISCONNECT code=%s | message=%s | prompt=%s / %s | kick=%s | %s\n", os.date("%Y-%m-%d %X"), errorCode, session.oneLine(message), session.oneLine(promptTitle), session.oneLine(promptBody), session.oneLine(kickMessage), context))
        task.wait(2.5)
        local replicatorAlive = false
        pcall(function()
            local networkClient = game:FindService("NetworkClient")
            replicatorAlive = networkClient ~= nil and #networkClient:GetChildren() > 0
        end)
        local lowered = string.lower(message)
        local looksDisconnected = string.find(lowered, "disconnect", 1, true) or string.find(lowered, "connection", 1, true) or string.find(lowered, "kick", 1, true)
        if replicatorAlive and not looksDisconnected then
            session.writeLog(string.format("%s IGNORED still connected\n", os.date("%Y-%m-%d %X")))
            return
        end
        if #session.LastFlags == 0 and not State.AutoArayaEnabled then
            session.writeLog(string.format("%s NO REJOIN no farms on\n", os.date("%Y-%m-%d %X")))
            return
        end
        session.Rejoining = true
        for attempt = 1, 40 do
            pcall(function()
                queue_on_teleport(Extras.Araya.HubLoader)
            end)
            session.TeleportFailedAt = nil
            session.writeLog(string.format("%s REJOIN attempt %d Teleport(%d)\n", os.date("%Y-%m-%d %X"), attempt, session.MainPlaceId))
            local firedAt = os.clock()
            pcall(function()
                teleportService:Teleport(session.MainPlaceId, localPlayer)
            end)
            while os.clock() - firedAt < 20 and not session.TeleportFailedAt do
                task.wait(0.5)
            end
            if session.TeleportFailedAt then
                task.wait(4)
            end
        end
    end)
end

Extras.OverHeaven = { StyleName = "The World", Key = "B", Busy = false, NextTryAt = 0, Fails = 0 }

function Extras.OverHeaven.isActive()
    local character = localPlayer.Character
    return character ~= nil and character:GetAttribute("TheWorldOverHeaven") == true
end

function Extras.OverHeaven.isReady()
    local readyAt = tonumber(localPlayer:GetAttribute("TheWorldOverHeavenReadyAt"))
    return readyAt == nil or workspaceService.DistributedGameTime >= readyAt
end

function Extras.OverHeaven.shouldCast()
    local overHeaven = Extras.OverHeaven
    if not State.AutoOverHeavenEnabled or overHeaven.Busy or os.clock() < overHeaven.NextTryAt then
        return false
    end
    if localPlayer:GetAttribute("TheWorldOverHeavenEarned") ~= true or overHeaven.isActive() or not overHeaven.isReady() then
        return false
    end
    local rootPart, playerHumanoid = getRoot()
    if not rootPart or not playerHumanoid or playerHumanoid.Health <= 0 or Extras.isGameHoldingCharacter(rootPart) then
        return false
    end
    if rootPart:FindFirstChild("Swim") or pickupActive or (Extras.Twoh and Extras.Twoh.SealPrompt) then
        return false
    end
    return getInventoryAmount(overHeaven.StyleName) > 0
end

function Extras.OverHeaven.cast()
    local overHeaven = Extras.OverHeaven
    local character = localPlayer.Character
    local playerHumanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not playerHumanoid then
        return
    end
    overHeaven.Busy = true
    local previousTool = character:FindFirstChildOfClass("Tool")
    if not isItemEquipped(overHeaven.StyleName) then
        equipInventoryItem(overHeaven.StyleName)
        task.wait(0.5)
    end
    local styleTool = character:FindFirstChild(overHeaven.StyleName)
    local backpack = localPlayer:FindFirstChild("Backpack")
    if not styleTool and backpack then
        styleTool = backpack:FindFirstChild(overHeaven.StyleName)
        if styleTool then
            pcall(function()
                playerHumanoid:EquipTool(styleTool)
            end)
            task.wait(0.4)
        end
    end
    if styleTool and styleTool.Parent == character then
        local rootPart = getRoot()
        pcall(function()
            inputEvent:FireServer("Tool", styleTool, overHeaven.Key, rootPart and (rootPart.Position + rootPart.CFrame.LookVector * 20) or Vector3.zero)
        end)
        local deadline = os.clock() + 8
        while os.clock() < deadline and not overHeaven.isActive() do
            task.wait(0.1)
        end
    end
    if overHeaven.isActive() then
        overHeaven.Fails = 0
        overHeaven.NextTryAt = os.clock() + 5
    else
        overHeaven.Fails = overHeaven.Fails + 1
        overHeaven.NextTryAt = os.clock() + math.min(20 * overHeaven.Fails, 120)
    end
    if previousTool and previousTool ~= styleTool and previousTool.Parent and not isFarmActive() then
        pcall(function()
            playerHumanoid:EquipTool(previousTool)
        end)
    end
    overHeaven.Busy = false
end

function Extras.OverHeaven.start()
    local token = getgenv().HubSessionToken
    task.spawn(function()
        while token and getgenv().HubSessionToken == token do
            if Extras.OverHeaven.shouldCast() then
                local ok = pcall(Extras.OverHeaven.cast)
                if not ok then
                    Extras.OverHeaven.Busy = false
                    Extras.OverHeaven.NextTryAt = os.clock() + 20
                end
            end
            task.wait(1)
        end
    end)
end

function Extras.connectAntiAfk()
    if getgenv().HubIdleConnection then
        pcall(function()
            getgenv().HubIdleConnection:Disconnect()
        end)
    end
    local virtualUser = cloneref(game:GetService("VirtualUser"))
    getgenv().HubIdleConnection = localPlayer.Idled:Connect(function()
        Extras.Session.IdleNudges = (Extras.Session.IdleNudges or 0) + 1
        pcall(function()
            virtualUser:CaptureController()
            virtualUser:ClickButton2(Vector2.new())
        end)
        Extras.Session.nudgeMouse()
    end)
    local token = getgenv().HubSessionToken
    task.spawn(function()
        while token and getgenv().HubSessionToken == token do
            task.wait(30)
            if Extras.Session.gameIdleSeconds() >= Extras.Session.MouseNudgeAfter then
                Extras.Session.nudgeMouse()
            end
        end
    end)
end

Extras.Session.MouseNudgeAfter = 120

function Extras.Session.gameIdleSeconds()
    local lastActive = localPlayer:GetAttribute("_AFKClientLastActive")
    if type(lastActive) ~= "number" then
        return math.huge
    end
    return os.clock() - lastActive
end

function Extras.Session.nudgeMouse()
    local session = Extras.Session
    pcall(function()
        local inputManager = cloneref(game:GetService("VirtualInputManager"))
        local mouseLocation = cloneref(game:GetService("UserInputService")):GetMouseLocation()
        inputManager:SendMouseMoveEvent(mouseLocation.X + 1, mouseLocation.Y, game)
        task.wait(0.05)
        inputManager:SendMouseMoveEvent(mouseLocation.X, mouseLocation.Y, game)
        session.MouseNudges = (session.MouseNudges or 0) + 1
        session.LastMouseNudgeAt = os.date("%X")
    end)
end

function Extras.releaseCharacter()
    stopTween()
    travelActive = false
    lockedEnemyRoot = nil
    lockedTargetCFrame = nil
    Extras.Walking = nil
    local rootPart, playerHumanoid = getRoot()
    if not rootPart or not playerHumanoid then
        return
    end
    removeFloat(rootPart)
    local playerCharacter = rootPart.Parent
    for _, partName in ipairs({ "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso", "Head" }) do
        local part = playerCharacter and playerCharacter:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    playerHumanoid.PlatformStand = false
    local humanoidState = playerHumanoid:GetState()
    if humanoidState == Enum.HumanoidStateType.Physics or humanoidState == Enum.HumanoidStateType.PlatformStanding then
        pcall(function()
            playerHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
    task.spawn(function()
        if not pcall(Extras.settleOnLand) then
            Extras.Settling = false
        end
    end)
end

function Extras.findStandableLand(origin)
    local raycastParams = buildRaycastParams()
    for _, castHeight in ipairs({ 40, 400 }) do
        for radius = 0, 300, 15 do
            local best, bestScore = nil, math.huge
            local steps = math.max(1, math.floor(radius / 6))
            for step = 0, steps - 1 do
                local angle = (step / steps) * math.pi * 2
                local probe = origin + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
                local hit = workspaceService:Raycast(Vector3.new(probe.X, origin.Y + castHeight, probe.Z), Vector3.new(0, -(castHeight + 500), 0), raycastParams)
                if hit and hit.Position.Y > 3 and hit.Normal.Y > 0.7 then
                    local score = Vector3.new(hit.Position.X - origin.X, 0, hit.Position.Z - origin.Z).Magnitude + math.abs(hit.Position.Y - origin.Y)
                    if score < bestScore then
                        best, bestScore = hit.Position, score
                    end
                end
            end
            if best then
                return best
            end
        end
    end
    return nil
end

function Extras.settleOnLand()
    if Extras.Settling then
        return
    end
    local rootPart, playerHumanoid = getRoot()
    if not rootPart or not playerHumanoid or playerHumanoid.Health <= 0 then
        return
    end
    local swimHold = rootPart:FindFirstChild("Swim")
    local groundHit = workspaceService:Raycast(rootPart.Position, Vector3.new(0, -8, 0), buildRaycastParams())
    if groundHit and not swimHold then
        return
    end
    local waitUntil = os.clock() + 8
    while not swimHold do
        task.wait(0.25)
        rootPart, playerHumanoid = getRoot()
        if not rootPart or not playerHumanoid or isFarmActive() or travelActive or os.clock() > waitUntil then
            return
        end
        if playerHumanoid.FloorMaterial ~= Enum.Material.Air then
            return
        end
        swimHold = rootPart:FindFirstChild("Swim") or (rootPart.Position.Y <= 2 and rootPart.AssemblyLinearVelocity.Magnitude < 1 and rootPart)
    end
    local land = Extras.findStandableLand(rootPart.Position)
    if not land then
        return
    end
    Extras.Settling = true
    local target = CFrame.new(land + Vector3.new(0, 3.5, 0)) * rootPart.CFrame.Rotation
    local floatForce = getOrCreateFloat(rootPart)
    local landTween = tweenService:Create(rootPart, TweenInfo.new(math.max((target.Position - rootPart.Position).Magnitude / 60, 0.1), Enum.EasingStyle.Linear), { CFrame = target })
    landTween:Play()
    local deadline = os.clock() + 15
    while landTween.PlaybackState == Enum.PlaybackState.Playing and os.clock() < deadline do
        if isFarmActive() or travelActive then
            landTween:Cancel()
            break
        end
        task.wait(0.05)
    end
    if not isFarmActive() and not travelActive then
        pcall(function()
            floatForce:Destroy()
        end)
        rootPart.AssemblyLinearVelocity = Vector3.zero
        pcall(function()
            playerHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
    Extras.Settling = false
end

function Extras.watchCharacterRelease()
    local token = getgenv().HubSessionToken
    task.spawn(function()
        local function anythingMoving()
            return isFarmActive() or travelActive or pickupActive
        end
        local wasActive = anythingMoving()
        if not wasActive then
            Extras.releaseCharacter()
        end
        while token and getgenv().HubSessionToken == token do
            local active = anythingMoving()
            if wasActive and not active then
                task.wait(0.3)
                active = anythingMoving()
                if not active then
                    Extras.releaseCharacter()
                end
            elseif not active then
                local rootPart = getRoot()
                if rootPart and rootPart:FindFirstChild("FarmFloat") and not Extras.Settling then
                    Extras.releaseCharacter()
                end
            end
            wasActive = active
            task.wait(0.25)
        end
    end)
end

UIController.Init()
Extras.connectAntiAfk()
Extras.OverHeaven.start()
Extras.connectItemIndicators()
Extras.watchCoffins()
Extras.resumeArayaAfterTeleport()
UIController.Restoring = true
Extras.resumeSession("values")
if not UIController.restoreSettings() then
    Extras.resumeSession("flags")
end
UIController.Restoring = false
UIController.Settings.Dirty = true
UIController.startSettingsSaver()
Extras.watchCharacterRelease()
Extras.startSessionSaver()
Extras.connectAutoRejoin()


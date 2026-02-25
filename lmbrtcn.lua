--[[
    LT2 Remote Spy - Capture all outgoing remote calls
    
    Run this BEFORE running the other dupe script.
    Every FireServer and InvokeServer call will be printed
    with the remote path and all arguments.
    
    Then run the dupe script and watch the output.
    Copy everything that prints and share it.
]]

local LOG = {}

local function serialize(val, depth)
    depth = depth or 0
    if depth > 3 then return "..." end
    local t = typeof(val)
    if t == "string" then
        return '"' .. val .. '"'
    elseif t == "number" or t == "boolean" then
        return tostring(val)
    elseif t == "nil" then
        return "nil"
    elseif t == "Instance" then
        local ok, path = pcall(function() return val:GetFullName() end)
        return ok and ("[Instance] " .. path) or "[Instance] (destroyed)"
    elseif t == "CFrame" then
        local p = val.Position
        return string.format("CFrame(%.2f, %.2f, %.2f)", p.X, p.Y, p.Z)
    elseif t == "Vector3" then
        return string.format("Vector3(%.2f, %.2f, %.2f)", val.X, val.Y, val.Z)
    elseif t == "table" then
        local parts = {}
        for k, v in pairs(val) do
            local key = type(k) == "string" and ('"'..k..'"') or tostring(k)
            table.insert(parts, "[" .. key .. "] = " .. serialize(v, depth + 1))
        end
        return "{ " .. table.concat(parts, ", ") .. " }"
    else
        return "(" .. t .. ") " .. tostring(val)
    end
end

local function logCall(callType, remote, args, rets)
    local remotePath = ""
    pcall(function() remotePath = remote:GetFullName() end)

    local argStrs = {}
    for _, v in ipairs(args) do
        table.insert(argStrs, serialize(v))
    end

    local entry = string.format("[%s] %s\n    args: (%s)", 
        callType,
        remotePath,
        #argStrs > 0 and table.concat(argStrs, ", ") or "none"
    )

    if rets and #rets > 0 then
        local retStrs = {}
        for _, v in ipairs(rets) do table.insert(retStrs, serialize(v)) end
        entry = entry .. "\n    returns: (" .. table.concat(retStrs, ", ") .. ")"
    end

    table.insert(LOG, entry)
    print(entry)
end

-- ── Hook via __namecall metamethod ───────────────────────────────────────
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if self:IsA("RemoteEvent") and method == "FireServer" then
        logCall("FireServer", self, args, nil)

    elseif self:IsA("RemoteFunction") and method == "InvokeServer" then
        local rets = table.pack(oldNamecall(self, ...))
        rets.n = nil
        logCall("InvokeServer", self, args, rets)
        return table.unpack(rets)
    end

    return oldNamecall(self, ...)
end)

print("=================================================")
print("  Remote Spy ACTIVE - all calls will be logged  ")
print("  Now run the dupe script and watch here        ")
print("=================================================")
print("  _G.dumpLog()  = reprint full log")
print("  _G.clearLog() = clear and restart")
print("=================================================")

_G.dumpLog = function()
    print("\n===== FULL LOG (" .. #LOG .. " entries) =====")
    for i, entry in ipairs(LOG) do
        print(i .. ". " .. entry)
    end
    print("===== END =====")
end

_G.clearLog = function()
    LOG = {}
    print("Log cleared.")
end

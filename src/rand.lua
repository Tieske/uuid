local sha256 = require("sha256")
local rand = {}
rand.__index = rand

-- Converts a number into a 6-byte string. Max: (2^48)-1.
local function num2s(l)
    local s = ""
    local n = 6
    for i = 1, n do
        local rem = l % 256
        s = string.char(rem) .. s
        l = (l - rem) / 256
    end
    return s
end

function rand.new(initstring) 
    local self = setmetatable({}, rand)

    self.counter = 0
    self.initstring = (initstring or "") .. (tostring(os.time()) .. tostring({})) -- tostring({}) to take advanatage of ASLR

    return self
end

function rand:Generate(extraData) 
    extraData = extraData or ""
    local stringToBeHashed = self.initstring .. num2s(self.counter) .. extraData
    self.counter = self.counter + 1
    local resultingBytes = sha256(stringToBeHashed)
    return resultingBytes:sub(0, 16)
end

function rand:SetSeed(newSeed) 
    self.initstring = newSeed
end

return rand
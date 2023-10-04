-- Modified version of BitOp-lua (https://github.com/AlberTajuelo/bitop-lua)
-- The following code is licensed under the MIT license. A copy of the license can be found below.
--[[
MIT License

Copyright (c).  Licensed under the same terms as Lua (MIT).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
local M = {}
local floor = math.floor

local MOD = 2 ^ 32
local MODM = MOD - 1

local function memoize(f)
    local mt = {}
    local t = setmetatable({}, mt)

    function mt:__index(k)
        local v = f(k)
        t[k] = v
        return v
    end

    return t
end

local function make_bitop_uncached(t, m)
    local function bitop(a, b)
        local res, p = 0, 1
        while a ~= 0 and b ~= 0 do
            local am, bm = a % m, b % m
            res = res + t[am][bm] * p
            a = (a - am) / m
            b = (b - bm) / m
            p = p * m
        end
        res = res + (a + b) * p
        return res
    end
    return bitop
end

local function make_bitop(t)
    local op1 = make_bitop_uncached(t, 2 ^ 1)
    local op2 = memoize(function(a)
        return memoize(function(b)
            return op1(a, b)
        end)
    end)
    return make_bitop_uncached(op2, 2 ^ (t.n or 1))
end

local bxor = make_bitop { [0] = { [0] = 0, [1] = 1 }, [1] = { [0] = 1, [1] = 0 }, n = 4 }

local function band(a, b) return ((a + b) - bxor(a, b)) / 2 end

local lshift, rshift

lshift = function(a, disp) -- Lua5.2 inspired
    if disp < 0 then return rshift(a, -disp) end
    return (a * 2 ^ disp) % 2 ^ 32
end

rshift = function(a, disp) -- Lua5.2 insipred
    if disp < 0 then return lshift(a, -disp) end
    return floor(a % 2 ^ 32 / 2 ^ disp)
end

local function rrotate(x, disp) -- Lua5.2 inspired
    disp = disp % 32
    local low = band(x, 2 ^ disp - 1)
    return rshift(x, disp) + lshift(low, 32 - disp)
end


local function bit32_bnot(x)
    return (-1 - x) % MOD
end
M.bnot = bit32_bnot

local function bit32_bxor(a, b, c, ...)
    local z
    if b then
        a = a % MOD
        b = b % MOD
        z = bxor(a, b)
        if c then
            z = bit32_bxor(z, c, ...)
        end
        return z
    elseif a then
        return a % MOD
    else
        return 0
    end
end
M.bxor = bit32_bxor

local function bit32_band(a, b, c, ...)
    local z
    if b then
        a = a % MOD
        b = b % MOD
        z = ((a + b) - bxor(a, b)) / 2
        if c then
            z = bit32_band(z, c, ...)
        end
        return z
    elseif a then
        return a % MOD
    else
        return MODM
    end
end
M.band = bit32_band

function M.rrotate(x, disp)
    return rrotate(x % MOD, disp)
end

function M.rshift(x, disp)
    if disp > 31 or disp < -31 then return 0 end
    return rshift(x % MOD, disp)
end

return M
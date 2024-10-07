---------------------------------------------------------------------------------------
-- Copyright 2012 Rackspace (original), 2013-2024 Thijs Schreijer (modifications)
--
-- see [http://www.ietf.org/rfc/rfc4122.txt](http://www.ietf.org/rfc/rfc4122.txt)
--
-- @license Apache 2.0, see `LICENSE.md`.


local math = require('math')
local string = require('string')
local format = string.format
local char = string.char
local byte = string.byte

local MATRIX_AND = {{0,0},{0,1} }
local MATRIX_OR = {{0,1},{1,1}}

local math_floor = math.floor
local to_number = tonumber
local assert = assert
local type = type



local M = {
  rng = require "uuid.rng",
}



-- performs the bitwise operation specified by truth matrix on two numbers.
local function BITWISE(x, y, matrix)
  local z = 0
  local pow = 1
  while x > 0 or y > 0 do
    z = z + (matrix[x%2+1][y%2+1] * pow)
    pow = pow * 2
    x = math_floor(x/2)
    y = math_floor(y/2)
  end
  return z
end


-- converts a HW identifier (mac address) to a string of byte values
local hwaddr_to_bytes do
  -- typically there is 1 address, so cache that one
  local hwaddr_stored, bytes_stored

  local function convert(hwaddr)
    assert(type(hwaddr)=="string", "Expected hex string, got "..type(hwaddr))
    -- Cleanup provided string, assume mac address, so start from back and cleanup until we've got 12 characters
    local hwaddr_clean = hwaddr:gsub("[^%x]",""):sub(1,12):lower()
    assert(#hwaddr_clean == 12, "Provided string did not contain at least 12 hex characters, got '"..hwaddr.."'")

    return char(
      to_number(hwaddr_clean:sub(1, 2), 16),
      to_number(hwaddr_clean:sub(3, 4), 16),
      to_number(hwaddr_clean:sub(5, 6), 16),
      to_number(hwaddr_clean:sub(7, 8), 16),
      to_number(hwaddr_clean:sub(9, 10), 16),
      to_number(hwaddr_clean:sub(11, 12), 16)
    )
  end

  function hwaddr_to_bytes(hwaddr)
    if hwaddr_stored ~= hwaddr then
      hwaddr_stored = hwaddr
      bytes_stored = convert(hwaddr)
    end
    return bytes_stored
  end
end



-- placeholder function until replaced
local function random_bytes(n)
  error("Not implemented, please set a function to generate random bytes by calling `uuid.set_rng(func)`")
end



----------------------------------------------------------------------------
-- Sets the function to be used to generate random bytes. The signature of
-- the function should be `func(n)`, where `n` is the number of bytes to
-- generate. The function should return a binary string  of random bytes
-- (not hex or otherwise encoded). Upon error it should return `nil + error message`.
-- @tparam function func the function to be used to generate random bytes
-- @treturn boolean `true`
function M.set_rng(func)
  assert(type(func) == "function", "Expected function, got "..type(func))
  random_bytes = func
  return true
end



----------------------------------------------------------------------------
-- Creates a new v4 uuid.
-- Calling on the module table is a shortcut for this function.
-- @treturn string a properly formatted uuid string
function M.v4()
  local b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16 = byte(random_bytes(16), 1, 16)

  -- set the version
  b7 = BITWISE(b7, 0x0f, MATRIX_AND)
  b7 = BITWISE(b7, 0x40, MATRIX_OR)
  -- set the variant
  b9 = BITWISE(b9, 0x3f, MATRIX_AND)
  b9 = BITWISE(b9, 0x80, MATRIX_OR)

  return format("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
                b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16)
end



-- backward compatibility, to be removed in a future version
M.seed = M.rng.seed
M.randomseed = M.rng.math_randomseed
M.new = function(hwaddr)
  if not hwaddr then
    return M.v4()
  end

  assert(type(hwaddr)=="string", "Expected hex string, got "..type(hwaddr))
  local hwaddr_clean = hwaddr:gsub("[^%x]",""):sub(1,12):lower()
  assert(#hwaddr_clean == 12, "Provided string did not contain at least 12 hex characters, got '"..hwaddr.."'")

  local b1, b2, b3, b4, b5, b6, b7, b8, b9, b10 = byte(random_bytes(10), 1, 10)
  local b11, b12, b13, b14, b15, b16 = byte(hwaddr_to_bytes(hwaddr_clean), 1, 6)

  -- set the version
  b7 = BITWISE(b7, 0x0f, MATRIX_AND)
  b7 = BITWISE(b7, 0x40, MATRIX_OR)
  -- set the variant
  b9 = BITWISE(b9, 0x3f, MATRIX_AND)
  b9 = BITWISE(b9, 0x80, MATRIX_OR)

  return format("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
                b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16)
end



return setmetatable( M, { __call = function(self) return self.v4() end} )

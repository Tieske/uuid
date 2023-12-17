---------------------------------------------------------------------------------------
-- Copyright 2012 Rackspace (original), 2013-2021 Thijs Schreijer (modifications)
--
-- see [http://www.ietf.org/rfc/rfc4122.txt](http://www.ietf.org/rfc/rfc4122.txt)
--
-- @license MIT, see `LICENSE.md`.


local M = {}
local math = require('math')
local os = require('os')
local string = require('string')
local format = string.format
local char = string.char
local byte = string.byte

local bitsize = 32  -- bitsize assumed for Lua VM. See randomseed function below.
local lua_version = tonumber(_VERSION:match("%d%.*%d*"))  -- grab Lua version used

local MATRIX_AND = {{0,0},{0,1} }
local MATRIX_OR = {{0,1},{1,1}}

local math_floor = math.floor
local math_random = math.random
local math_abs = math.abs
local to_number = tonumber
local assert = assert
local type = type

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


----------------------------------------------------------------------------
-- [REPLACE] Should return a set of random bytes.
-- This function MUST be replaced by a proper implementation. This is done
-- purposely to force the user to think about the randomness of the bytes
-- generated.
-- @tparam integer n number of bytes to generate
-- @treturn string of random bytes
-- @usage
-- local ok, system = pcall(require, "system")
-- if ok then
--   -- set the Lua-System random generator as the one to use
--   uuid.get_random_bytes = system.get_random_bytes
-- else
--   -- use the weak one as a fallback
--   uuid.get_random_bytes = uuid.weak_random_bytes
-- end
function M.get_random_bytes(n)
  assert(n, "Expected number of bytes to generate")
  error("Not implemented, please set a function to generate random bytes")
end

----------------------------------------------------------------------------
-- Returns a set of random bytes. This implementation uses the default Lua
-- `math.random()` function, which is not very random. It is recommended to
-- replace this function with a better implementation.
-- @tparam integer n number of bytes to generate
-- @treturn string of random bytes
-- @usage
function M.weak_random_bytes(n)
  assert(n, "Expected number of bytes to generate")
  local bytes = {}
  for i = 1, n do
    bytes[i] = char(math_random(0, 255))
  end
  return table.concat(bytes)
end


----------------------------------------------------------------------------
-- Creates a new uuid. Either provide a unique hex string, or make sure the
-- random seed is properly set. The module table itself is a shortcut to this
-- function, so `my_uuid = uuid.new()` equals `my_uuid = uuid()`.
--
-- For proper use there are 3 options;
--
-- 1. first require `luasocket`, then call `uuid.seed()`, and request a uuid using no
-- parameter, eg. `my_uuid = uuid()`
-- 2. use `uuid` without `luasocket`, set a random seed using `uuid.randomseed(some_good_seed)`,
-- and request a uuid using no parameter, eg. `my_uuid = uuid()`
-- 3. use `uuid` without `luasocket`, and request a uuid using an unique hex string,
-- eg. `my_uuid = uuid(my_networkcard_macaddress)`
--
-- @return a properly formatted uuid string
-- @param hwaddr (optional) string containing a unique hex value (e.g.: `00:0c:29:69:41:c6`),
-- to be used to compensate for the lesser `math_random()` function. Use a mac address for solid
-- results. If omitted, a fully randomized uuid will be generated, but then you must ensure that
-- the random seed is set properly!
-- @usage
-- local uuid = require("uuid")
-- print("here's a new uuid: ",uuid())
function M.new(hwaddr)
  local bytes
  if hwaddr then
    assert(type(hwaddr)=="string", "Expected hex string, got "..type(hwaddr))
    -- Cleanup provided string, assume mac address, so start from back and cleanup until we've got 12 characters
    local hwaddr_clean = hwaddr:gsub("[^%x]",""):sub(1,12):lower()
    assert(#hwaddr_clean == 12, "Provided string did not contain at least 12 hex characters, got '"..hwaddr.."'")

    bytes = hwaddr_to_bytes(hwaddr_clean)
  else
    bytes = M.get_random_bytes(6)
  end

  local byte_7, byte_9
  -- set the version
  byte_7 = byte(M.get_random_bytes(1))
  byte_7 = BITWISE(byte_7, 0x0f, MATRIX_AND)
  byte_7 = BITWISE(byte_7, 0x40, MATRIX_OR)
  byte_7 = char(byte_7)
  -- set the variant
  byte_9 = byte(M.get_random_bytes(1))
  byte_9 = BITWISE(byte_9, 0x3f, MATRIX_AND)
  byte_9 = BITWISE(byte_9, 0x80, MATRIX_OR)
  byte_9 = char(byte_9)

  bytes = M.get_random_bytes(6) .. byte_7 .. M.get_random_bytes(1) .. byte_9 .. M.get_random_bytes(1) .. bytes

  return format("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x", byte(bytes, 1, 16))
end

----------------------------------------------------------------------------
-- Improved randomseed function.
-- Lua 5.1 and 5.2 both truncate the seed given if it exceeds the integer
-- range. If this happens, the seed will be 0 or 1 and all randomness will
-- be gone (each application run will generate the same sequence of random
-- numbers in that case). This improved version drops the most significant
-- bits in those cases to get the seed within the proper range again.
-- @param seed the random seed to set (integer from 0 - 2^32, negative values will be made positive)
-- @return the (potentially modified) seed used
-- @usage
-- local socket = require("socket")  -- gettime() has higher precision than os.time()
-- local uuid = require("uuid")
-- -- see also example at uuid.seed()
-- uuid.randomseed(socket.gettime()*10000)
-- print("here's a new uuid: ",uuid())
function M.randomseed(seed)
  seed = math_floor(math_abs(seed))
  if seed >= (2^bitsize) then
    -- integer overflow, so reduce to prevent a bad seed
    seed = seed - math_floor(seed / 2^bitsize) * (2^bitsize)
  end
  if lua_version < 5.2 then
    -- 5.1 uses (incorrect) signed int
    math.randomseed(seed - 2^(bitsize-1))
  else
    -- 5.2 uses (correct) unsigned int
    math.randomseed(seed)
  end
  return seed
end

----------------------------------------------------------------------------
-- Seeds the random generator.
-- It does so in 3 possible ways;
--
-- 1. if in ngx_lua, use `ngx.time() + ngx.worker.pid()` to ensure a unique seed
-- for each worker. It should ideally be called from the `init_worker` context.
-- 2. use luasocket `gettime()` function, but it only does so when LuaSocket
-- has been required already.
-- 3. use `os.time()`: this only offers resolution to one second (used when
-- LuaSocket hasn't been loaded)
--
-- **Important:** the random seed is a global piece of data. Hence setting it is
-- an application level responsibility, libraries should never set it!
-- @usage
-- local socket = require("socket")  -- gettime() has higher precision than os.time()
-- -- LuaSocket loaded, so below line does the same as the example from randomseed()
-- uuid.seed()
-- print("here's a new uuid: ",uuid())
function M.seed()
  if _G.ngx ~= nil then
    return M.randomseed(ngx.time() + ngx.worker.pid())  -- luacheck: ignore
  elseif package.loaded["socket"] and package.loaded["socket"].gettime then
    return M.randomseed(package.loaded["socket"].gettime()*10000)
  else
    return M.randomseed(os.time())
  end
end

return setmetatable( M, { __call = function(self, hwaddr) return self.new(hwaddr) end} )

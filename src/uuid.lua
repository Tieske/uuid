---------------------------------------------------------------------------------------
-- Copyright 2012 Rackspace (original), 2013-2021 Thijs Schreijer (modifications)
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS-IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- see http://www.ietf.org/rfc/rfc4122.txt
--
-- Note that this is not a true version 4 (random) UUID.  Since `os.time()` precision is only 1 second, it would be hard
-- to guarantee spacial uniqueness when two hosts generate a uuid after being seeded during the same second.  This
-- is solved by using the node field from a version 1 UUID.  It represents the mac address.
--
-- 28-apr-2013 modified by Thijs Schreijer from the original [Rackspace code](https://github.com/kans/zirgo/blob/807250b1af6725bad4776c931c89a784c1e34db2/util/uuid.lua) as a generic Lua module.
-- Regarding the above mention on `os.time()`; the modifications use the `socket.gettime()` function from LuaSocket
-- if available and hence reduce that problem (provided LuaSocket has been loaded before uuid).
--
-- **Important:** the random seed is a global piece of data. Hence setting it is
-- an application level responsibility, libraries should never set it!
--
-- See this issue; [https://github.com/Kong/kong/issues/478](https://github.com/Kong/kong/issues/478)
-- It demonstrates the problem of using time as a random seed. Specifically when used from multiple processes.
-- So make sure to seed only once, application wide. And to not have multiple processes do that
-- simultaneously.


local M = {}
local math = require('math')
local os = require('os')
local string = require('string')
local prng = require('rand')

local MATRIX_AND = {{0,0},{0,1} }
local MATRIX_OR = {{0,1},{1,1}}
local HEXES = '0123456789abcdef'

local global_prng = prng.new()

local math_floor = math.floor
local string_sub = string.sub

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

local function INT2HEX(x)
  local s,base = '',16
  local d
  while x > 0 do
    d = x % base + 1
    x = math_floor(x/base)
    s = string_sub(HEXES, d, d)..s
  end
  while #s < 2 do s = "0" .. s end
  return s
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
-- @param hwaddr (optional) string containing a unique hex value (e.g.: `00:0c:29:69:41:c6`), to be used to compensate for the lesser `math_random()` function. Use a mac address for solid results. If omitted, a fully randomized uuid will be generated, but then you must ensure that the random seed is set properly!
-- @usage
-- local uuid = require("uuid")
-- print("here's a new uuid: ",uuid())
function M.new(hwaddr)
  -- bytes are treated as 8bit unsigned bytes.
  local bytes = { string.byte(global_prng:Generate(hwaddr), 1, -1) } -- 16 random bytes

  -- set the version
  bytes[7] = BITWISE(bytes[7], 0x0f, MATRIX_AND)
  bytes[7] = BITWISE(bytes[7], 0x40, MATRIX_OR)
  -- set the variant
  bytes[9] = BITWISE(bytes[9], 0x3f, MATRIX_AND)
  bytes[9] = BITWISE(bytes[9], 0x80, MATRIX_OR)
  return INT2HEX(bytes[1])..INT2HEX(bytes[2])..INT2HEX(bytes[3])..INT2HEX(bytes[4]).."-"..
         INT2HEX(bytes[5])..INT2HEX(bytes[6]).."-"..
         INT2HEX(bytes[7])..INT2HEX(bytes[8]).."-"..
         INT2HEX(bytes[9])..INT2HEX(bytes[10]).."-"..
         INT2HEX(bytes[11])..INT2HEX(bytes[12])..INT2HEX(bytes[13])..INT2HEX(bytes[14])..INT2HEX(bytes[15])..INT2HEX(bytes[16])
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
    global_prng:SetSeed(tostring(seed))
end

----------------------------------------------------------------------------
-- Seeds the random generator.
-- It does so in 3 possible ways;
--
-- 1. if in ngx_lua, use `ngx.time() + ngx.worker.pid()` and `tostring({})` to ensure a unique seed
-- for each worker. It should ideally be called from the `init_worker` context. Uses ASLR when possible.
-- 2. use luasocket `gettime()` function and `tostring({})`, but it only does so when LuaSocket
-- has been required already. Uses ASLR when possible.
-- 3. use `os.time()` and `tostring({})`: this only offers resolution to one second (used when
-- LuaSocket hasn't been loaded), but takes advantage of ASLR when applicable
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
    return M.randomseed(ngx.time() .. ngx.worker_pid() .. tostring({}))
  elseif package.loaded["socket"] and package.loaded["socket"].gettime then
    return M.randomseed(package.loaded["socket"].gettime()*10000 .. tostring({}))
  else
    return M.randomseed(os.time() .. tostring({}))
  end
end

return setmetatable( M, { __call = function(self, hwaddr) return self.new(hwaddr) end} )
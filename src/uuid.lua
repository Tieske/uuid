---------------------------------------------------------------------------------------
-- Copyright 2012 Rackspace (original), 2013 Thijs Schreijer (modifications)
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
-- Note that this is not a true version 4 (random) UUID.  Since os.time() precision is only 1 second, it would be hard
-- to guarantee spacial uniqueness when two hosts generate a uuid after being seeded during the same second.  This
-- is solved by using the node field from a version 1 UUID.  It represents the mac address.
-- 
-- 28-apr-2013 modified by Thijs Schreijer from the original [Rackspace code](https://github.com/kans/zirgo/blob/807250b1af6725bad4776c931c89a784c1e34db2/util/uuid.lua) as a generic Lua module
-- 

local math = require('math')
local os = require('os')
local string = require('string')

-- seed the random generator.  note that os.time() only offers resolution to one second, 
-- so preferably use luasocket gettime() function, but only when it has been required
-- already.
if package.loaded["socket"] and package.loaded["socket"].gettime then
  math.randomseed(package.loaded["socket"].gettime()*100000)
else
  math.randomseed(os.time())
end

local MATRIX_AND = {{0,0},{0,1} }
local MATRIX_OR = {{0,1},{1,1}}
local HEXES = '0123456789abcdef'

-- performs the bitwise operation specified by truth matrix on two numbers.
local function BITWISE(x, y, matrix)
  local z = 0
  local pow = 1
  while x > 0 or y > 0 do
    z = z + (matrix[x%2+1][y%2+1] * pow)
    pow = pow * 2
    x = math.floor(x/2)
    y = math.floor(y/2)
  end
  return z
end

local function INT2HEX(x)
  local s,base = '',16
  local d
  while x > 0 do
    d = x % base + 1
    x = math.floor(x/base)
    s = string.sub(HEXES, d, d)..s
  end
  if #s == 1 then s = "0" .. s end
  return s
end

----------------------------------------------------------------------------
-- Creates a new uuid. Either provide a unique hex string, or make sure the
-- random seed is properly set. The module table itself is a shortcut to this
-- function, so `my_uuid = uuid.new()` equals `my_uuid = uuid()`.
--
-- NOTE: if luasocket is required before this module, it will use the
-- `socket.gettime()` function to set the random seed, which should suffice. If
-- luasocket has not been loaded, it will set a random seed using `os.time()`.
--
-- __IMPORTANT__: requiring `uuid` WILL ALWAYS set a random seed, so if you set your own,
-- you must do so only AFTER requiring `uuid`, or it will be undone!
--
-- So for proper use there are 3 options;
--
-- 1. first require `luasocket`, then require `uuid`, and request a uuid using no 
-- parameter, eg. `my_uuid = uuid.new()`
-- 2. require `uuid` without `luasocket`, set a random seed using `math.randomseed(some_good_seed)`, 
-- and request a uuid using no parameter, eg. `my_uuid = uuid.new()`
-- 3. require `uuid` without `luasocket`, and request a uuid using an unique hex string, 
-- eg. `my_uuid = uuid.new(my_networkcard_macaddress)`
--
-- @return a properly formatted uuid string
-- @param hwaddr (optional) string containing a unique hex value (e.g.: `00:0c:29:69:41:c6`), to be used to compensate for the lesser `math.random()` function. Use a mac address for solid results. If omitted, a fully randomized uuid will be generated, but then you must ensure that the random seed is set properly!
local function new(hwaddr)
  -- bytes are treated as 8bit unsigned bytes.
  local bytes = {
      math.random(0, 255),
      math.random(0, 255),
      math.random(0, 255),
      math.random(0, 255),
      math.random(0, 255),
      math.random(0, 255),
      math.random(0, 255),
      math.random(0, 255),
      math.random(0, 255),
      math.random(0, 255),
      math.random(0, 255),
      math.random(0, 255),
      math.random(0, 255),
      math.random(0, 255),
      math.random(0, 255),
      math.random(0, 255),
    }

  if hwaddr then
    assert(type(hwaddr)=="string", "Expected hex string, got "..type(hwaddr))
    -- Cleanup provided string, assume mac address, so start from back and cleanup until we've got 12 characters
    local i,str, hwaddr = #hwaddr, hwaddr, ""
    while i>0 and #hwaddr<12 do
      local c = str:sub(i,i):lower()
      if HEXES:find(c, 1, true) then 
        -- valid HEX character, so append it
        hwaddr = c..hwaddr
      end
      i = i - 1
    end
    assert(#hwaddr == 12, "Provided string did not contain at least 12 hex characters, retrieved '"..hwaddr.."' from '"..str.."'")
    
    -- no split() in lua. :(
    bytes[11] = tonumber(hwaddr:sub(1, 2), 16)
    bytes[12] = tonumber(hwaddr:sub(3, 4), 16)
    bytes[13] = tonumber(hwaddr:sub(5, 6), 16)
    bytes[14] = tonumber(hwaddr:sub(7, 8), 16)
    bytes[15] = tonumber(hwaddr:sub(9, 10), 16)
    bytes[16] = tonumber(hwaddr:sub(11, 12), 16)
  end
  
  -- set the version
  bytes[7] = BITWISE(bytes[7], 0x0f, MATRIX_AND)
  bytes[7] = BITWISE(bytes[7], 0x40, MATRIX_OR)
  -- set the variant
  bytes[9] = BITWISE(bytes[7], 0x3f, MATRIX_AND)
  bytes[9] = BITWISE(bytes[7], 0x80, MATRIX_OR)
  return  INT2HEX(bytes[1])..INT2HEX(bytes[2])..INT2HEX(bytes[3])..INT2HEX(bytes[4]).."-"..
         INT2HEX(bytes[5])..INT2HEX(bytes[6]).."-"..
         INT2HEX(bytes[7])..INT2HEX(bytes[8]).."-"..
         INT2HEX(bytes[9])..INT2HEX(bytes[10]).."-"..
         INT2HEX(bytes[11])..INT2HEX(bytes[12])..INT2HEX(bytes[13])..INT2HEX(bytes[14])..INT2HEX(bytes[15])..INT2HEX(bytes[16])
end


return setmetatable( {new = new}, { __call = function(self, hwaddr) return self.new(hwaddr) end} )

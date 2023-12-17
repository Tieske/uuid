--- Random number generator utilities with different properties and uses.
-- @module uuid.rng

local string_format = string.format
local string_unpack = string.unpack
local string_char = string.char
local string_byte = string.byte

local math_randomseed = math.randomseed
local math_random = math.random
local math_floor = math.floor
local math_abs = math.abs

local table_concat = table.concat
local table_insert = table.insert

local sha1 = require "uuid.rng.sha1"
local lua_version = tonumber(_VERSION:match("%d%.*%d*"))  -- grab Lua version used

local rng = {}


----------------------------------------------------------------------------
-- Build in rng functions getting random numbers from different sources.
-- @section rng

do
  local rnd = function(n)
    local bytes = {}
    for i = 1, n do
      bytes[i] = string_char(math_random(0, 255))
    end
    return table_concat(bytes)
  end

  ----------------------------------------------------------------------------
  -- Returns an rng that implementats the default Lua `math.random()` function.
  -- In Lua 5.1 to 5.3 this relies on the C `rand()` function, which is low quality and
  -- predictable, so essentially a bad source of randomness. In Lua 5.4 this is
  -- improved because it includes its own (way better, but not crypto-grade) rng.
  --
  -- **Important:** ensure to use a good random seed set via `rng.math_randomseed`, and
  -- do this only once, since it is an application responsibility, not a library one.
  -- Check out `rng.seed` and `rng.generate_seed` for better seeding.
  -- @treturn function A function that returns `n` random bytes, signature: `byte_string, err = func(n)`
  -- @usage
  -- local uuid = require "uuid"
  -- uuid.rng.math_randomseed(some_really_good_seed)
  -- uuid.set_rng(uuid.rng.math_random())
  function rng.math_random()
    return rnd
  end
end



----------------------------------------------------------------------------
-- Returns an rng that implements LuaSystem's `system.random()` function.
-- which is a good source of randomness (for both Windows and Posix). Ensure
-- that LuaSystem is installed and available.
-- Since it uses LuaSystem there is no need to seed Lua's random number generator
-- before using this function.
-- @treturn function A function that returns `n` random bytes, signature: `byte_string, err = func(n)`
-- @usage
-- local uuid = require "uuid"
-- uuid.set_rng(uuid.rng.luasystem())
function rng.luasystem()
  local ok, sys = pcall(require, "system")
  if not ok then
    return nil, "luasystem not available"
  end

  if type(sys.random) ~= "function" then
    -- the `random` function is not available, probably an older version of luasystem
    return nil, "luasystem version is too old, minimum version required is 0.3"
  end

  return sys.random
end



do
  local rnd = function(n)
    local file, err = io.open("/dev/urandom", "rb")
    if not file then
      return nil, "Failed to open /dev/urandom: " .. tostring(err)
    end

    local bytes, err = file:read(n)
    file:close()

    if not bytes then
      return nil, "Failed to read bytes from /dev/urandom: " .. tostring(err)
    end

    return bytes
  end

  ----------------------------------------------------------------------------
  -- Returns an rng that reads from `/dev/urandom`, which is a good source of
  -- randomness but only available on Posix systems.
  -- Since it uses `/dev/urandom` there is no need to seed Lua's random number
  -- generator before using this function.
  -- @treturn function A function that returns `n` random bytes, signature: `byte_string, err = func(n)`
  -- @usage
  -- local uuid = require "uuid"
  -- uuid.set_rng(uuid.rng.urandom())
  function rng.urandom()
    if package.config:sub(1, 1) == "\\" then
      return nil, "/dev/urandom is not available on Windows"
    end

    local ok, err = rnd(1) -- test it to ensure we can read it
    if not ok then
      return nil, err
    end

    return rnd
  end
end




----------------------------------------------------------------------------
-- Functions to improve Lua's seeding.
-- @section seeding



----------------------------------------------------------------------------
-- Improved `math.randomseed` function.
-- Lua 5.4 takes 2 args 64bit, it uses an internal rng. Both seed values should
-- range from `math.mininteger` to `math.maxinteger` (64bit signed integers).
-- If they are not, Lua will throw an error. Hence this function does not
-- modify the seed values in the Lua 5.4 case.
--
-- Lua 5.1 to 5.3 use the C function `srand` which takes an unsigned Int.
-- The range should be from 0 to 2^32. If the seed is outside this range, it
-- will be silently truncated to fit within the range. This can lead to the same
-- sequence of random numbers being generated each time the application is run.
--
-- This function ensures that the seed is within the proper range by dropping
-- the most significant bits if it exceeds the integer range. And any negative
-- values are made positive first. It can be used as a drop-in replacement for
-- `math.randomseed()`.
--
-- **Important:** the random seed is a global piece of data. Hence setting it is
-- an application level responsibility, libraries should never set it!
-- @tparam integer seed the random seed to set 0 to 2^32-1 for Lua 5.1-5.3, `mininteger` to `maxinteger` for Lua 5.4+
-- @tparam integer seed2 second part of the seed, only for Lua 5.4+, `mininteger` to `maxinteger`
-- @return integer the seed(s) used (potentially modified inputs)
-- @usage
-- -- patch Lua's version
-- _G.math.randomseed = require("uuid").rng.math_randomseed
function rng.math_randomseed(seed, seed2)
  -- srand() takes a UInt, used in 5.1 to 5.3, so always max 32bit in size
  -- Lua 5.1 casts to an Int (incorrect) = 32bit
  -- Lua 5.2 casts to a UInt = 32bit
  -- Lua 5.3 casts to a UInt = 32bit

  -- 5.1-5.3 use the C function `srand` which takes an unsigned Int
  local bitsize = 32
  seed = math_floor(math_abs(seed))

  if seed >= (2^bitsize) then
    -- integer overflow, so reduce to range of UInt
    seed = seed % 2^bitsize
  end

  if lua_version < 5.2 then
    -- 5.1 uses (incorrect) signed int
    math_randomseed(seed - 2^(bitsize-1))
  else
    -- 5.2, 5.3 use unsigned int
    math_randomseed(seed)
  end

  return seed, nil
end

-- in case of 5.4+ we use the default Lua function, nothing to do.
if lua_version >= 5.4 then
  rng.math_randomseed = math_randomseed
end


do
  -- create a table, on modern CPUs the ASLR will make this unique.
  -- we keep the table around, to prevent it being GC'ed and the address being reused
  local unique_table = {}
  local unique_table_id = tostring(unique_table) -- string contains the memory addres of the table
  if _G._TEST then
    -- only if testing we export a function to get the unique table id
    rng.get_unique_table_id = function() return unique_table_id end
  end

  ----------------------------------------------------------------------------
  -- Returns a binary string, sha1-like (40 bytes).
  -- Generates crypto level randomness if `luasystem` or `/dev/urandom` is available.
  -- If not available it returns a sha1 hash of a combination of string values:
  --
  -- - a unique table id (relying on ASLR)
  --
  -- - the `inputdata` string if provided
  --
  -- - 10 bytes generated using `math.random` for which the quality depends on the Lua version in use
  --
  -- - the current time in seconds with microsecond precision (using OpenResty or LuaSocket), or
  --   otherwise falls back to `os.time` with second precision
  --
  -- - the current worker's `pid` and `id` (OpenResty only)
  --
  -- **Important:** ensure you understand what this does. Otherwise just use LuaSystem!!
  -- @tparam[opt] string inputdata additional entropy input to be used in the seed generation in case of a sha1 fallback
  -- @treturn string a 40 bytes long binary string
  function rng.generate_seed(inputdata)
    do -- try LuaSystem
      local ls = rng.luasystem()
      if ls then
        return ls(40)   -- this is crypto level, so good enough
      end
    end

    do -- try /dev/urandom on unix
      local ur = rng.urandom()
      if ur then
        return ur(40)  -- this is crypto level, so good enough
      end
    end

    -- fallback to sha1 of a combination of values
    local seed = {
      unique_table_id,
      inputdata, -- this might be nil, so goes last in the table constructor
    }

    do -- generate 10 bytes using math.random()
      local rd = {}
      for i = 1, 10 do
        rd[i] = string_char(math_random(0, 255))
      end
      table_insert(seed, table_concat(rd))
    end


    if _G.ngx ~= nil then
      -- Nginx/OpenResty
      ngx.update_time()                                         -- luacheck: ignore
      table_insert(seed, string_format("%.6f", ngx.now()))      -- luacheck: ignore
      table_insert(seed, string_format("%d", ngx.worker.pid())) -- luacheck: ignore
      table_insert(seed, string_format("%d", ngx.worker.id()))  -- luacheck: ignore

    elseif pcall(require, "socket") then
      -- LuaSocket
      table_insert(seed, string_format("%.6f", (require("socket").gettime())))

    else
      -- Plain Lua  :(
      table_insert(seed, string_format("%.6f", os.time()))
    end

    return sha1.bin(table_concat(seed, ":"))
  end



  ----------------------------------------------------------------------------
  -- Seeds the Lua random generator, relies on `generate_seed`.
  --
  -- **Important:** ensure you understand what `generate_seed` does!!
  --
  -- A seed will be generated by `generate_seed` (40 byte string) and after conversion
  -- in the proper format, it will be used to seed the Lua random number generator
  -- by calling `math_randomseed`.
  --
  -- For Lua 5.1 to 5.3 it will use the first 4 bytes of the generated seed to create
  -- a 32 bit integer seed. For Lua 5.4+ it will unpack the first 16 bytes in 2 64bit
  -- integers used as seeds.
  --
  -- **Important:** the random seed is a global piece of data. Hence setting it is
  -- an application level responsibility, libraries should never set it!
  -- @tparam[opt] string inputdata additional entropy passed to `generate_seed`
  -- @return the results from `rng.math_randomseed`
  function rng.seed(inputdata)
    local seed = rng.generate_seed(inputdata) -- grab a 40 byte random string
    if lua_version < 5.4 then
      -- Lua 5.1 - 5.3 need a 32 bit integer seed
      local b1, b2, b3, b4 = string_byte(seed, 1, 4)  -- grab the first 4 bytes
      return rng.math_randomseed(b1 * 2^24 + b2 * 2^16 + b3 * 2^8 + b4)
    end

    -- Lua 5.4 needs 2 64bit integers
    local seed1, seed2 = string_unpack("I8I8", seed)
    return rng.math_randomseed(seed1, seed2)
  end
end


return rng

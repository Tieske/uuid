describe("seeding Lua rng", function()

  local old_lua_version = _G._VERSION
  local old_randomseed = _G.math.randomseed
  local rng

  -- set the Lua version constant to the given version, and loads the library
  local setversion = function(v)
    v = tostring(v)
    _G._VERSION = old_lua_version:gsub("%d+%.%d+", v)
    package.loaded["uuid.rng"] = nil
    rng = require("uuid.rng")
  end


  before_each(function()
    _G._TEST = true
    stub(_G.math, "randomseed")
  end)


  after_each(function()
    _G._VERSION = old_lua_version
    _G._TEST = nil
  end)

  describe("math_randomseed()", function()

    describe("5.1", function()

      before_each(function()
        setversion("5.1")
      end)

      local tests = {
        -- order: seed1_in, seed2_in, seed1_set, seed2_set, seed1_out, seed2_out, description
        -- in is what we pass in
        -- set is what is passed to math.randomseed
        -- out is what we expect to get back
        { 0, nil, 0-2^31, nil, 0, nil, "correct seed shifted UInt32 -> Int32 (1)" },
        { 1, nil, 1-2^31, nil, 1, nil, "correct seed shifted UInt32 -> Int32 (2)" },
        { 123, nil, 123-2^31, nil, 123, nil, "sets a simple seed" },
        { 123, 456, 123-2^31, nil, 123, nil, "ignores 2nd seed" },
        { -123, nil, 123-2^31, nil, 123, nil, "negative passed in as positive" },
        { 2^31, nil, 2^31-2^31, nil, 2^31, nil , "2^31 works as expected"},
        { 2^32, nil, 0-2^31, nil, 0, nil , "2^32 gets truncated"},
      }

      for _, test in ipairs(tests) do
        it(test[7], function()
          local s1, s2 = rng.math_randomseed(test[1], test[2])
          assert.are.equal(test[5], s1)
          assert.are.equal(test[6], s2)
          if test[4] == nil then
            assert.stub(_G.math.randomseed).was.called_with(test[3])
          else
            assert.stub(_G.math.randomseed).was.called_with(test[3], test[4])
          end
        end)
      end

    end)



    for _, luaV in pairs({"5.2", "5.3"}) do
      describe(luaV, function()

        before_each(function()
          setversion(luaV)
        end)

        local tests = {
          -- order: seed1_in, seed2_in, seed1_set, seed2_set, seed1_out, seed2_out, description
          -- in is what we pass in
          -- set is what is passed to math.randomseed
          -- out is what we expect to get back
          { 0, nil, 0, nil, 0, nil, "correct seed notn shifted like 5.1" },
          { 123, nil, 123, nil, 123, nil, "sets a simple seed" },
          { 123, 456, 123, nil, 123, nil, "ignores 2nd seed" },
          { -123, nil, 123, nil, 123, nil, "negative passed in as positive" },
          { 2^31, nil, 2^31, nil, 2^31, nil , "2^31 works as expected"},
          { 2^32, nil, 0, nil, 0, nil , "2^32 gets truncated"},
        }

        for _, test in ipairs(tests) do
          it(test[7], function()
            local s1, s2 = rng.math_randomseed(test[1], test[2])
            assert.are.equal(test[5], s1)
            assert.are.equal(test[6], s2)
            if test[4] == nil then
              assert.stub(_G.math.randomseed).was.called_with(test[3])
            else
              assert.stub(_G.math.randomseed).was.called_with(test[3], test[4])
            end
          end)
        end

      end)
    end -- for lua 5.2 - 5.3



    describe("5.4", function()

      before_each(function()
        setversion("5.4")
      end)

      it("uses the default Lua 5.4 function math.randomseed", function()
        assert.are.equal(rng.math_randomseed, _G.math.randomseed)
      end)

    end)

  end)



  describe("generate_seed()", function()

    local old_math_random, random_value


    before_each(function()
      random_value = nil
      old_math_random = _G.math.random
      _G.math.random = function(...)
        if random_value then
          return random_value
        else
          return old_math_random(...)
        end
      end
      package.loaded["uuid.rng"] = nil
      _G.math.randomseed = old_randomseed
      rng = require("uuid.rng")
    end)

    after_each(function()
      package.loaded["uuid.rng"] = nil
      _G.math.random = old_math_random
    end)


    it("uses luasystem if available", function()
      rng.luasystem = function()
        return function(n)
          return ("A"):rep(n)
        end
      end

      assert.are.equal(("A"):rep(40), rng.generate_seed())
    end)

    it("uses /dev/urandom if available and lacking luasystem", function()
      rng.luasystem = function() return false end
      rng.urandom = function()
        return function(n)
          return ("B"):rep(n)
        end
      end

      assert.are.equal(("B"):rep(40), rng.generate_seed())
    end)

    it("uses a fallback with luasocket and user provided entropy", function()
      rng.luasystem = function() return false end
      rng.urandom = function() return false end
      package.loaded["socket"] = { gettime = function() return 123.123 end }
      finally(function()
        package.loaded["socket"] = nil
      end)
      local inputdata = "abc"
      random_value = 67 -- "C"

      local key = {
        rng.get_unique_table_id(),  -- unique table ID
        inputdata,                  -- user provided entropy
        ("C"):rep(10),              -- Lua rng generated random bytes
        "123.123000",               -- LuaSocket time
      }
      local seed = require("uuid.rng.sha1").bin(table.concat(key, ":"))

      if _G._VERSION < "Lua 5.4" then
        local r = rng.seed(inputdata) -- Lua 5.1 - 5.3; 1 return value
        local e = 0
        for i = 1, 4 do
          e = e * 256 + seed:byte(i)
        end
        assert.are.equal(e, r)

      else
        assert.are.equal(old_randomseed, _G.math.randomseed)
        local r1, r2 = rng.seed(inputdata) -- Lua 5.4+; 2 return values
        local e1, e2 = string.unpack("I8I8", seed)
        assert.are.equal(e1, r1)
        assert.are.equal(e2, r2)
      end
    end)

  end)


end)

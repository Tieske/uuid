describe("rng's", function()

  describe("math_random()", function()

    it("generates 1 byte", function()
      local rng = require("uuid").rng.math_random()

      assert.is.string(rng(1))
      assert.is.equal(1, #rng(1))
    end)


    it("generates 256 bytes", function()
      local rng = require("uuid").rng.math_random()

      assert.is.string(rng(256))
      assert.is.equal(256, #rng(256))
    end)

  end)



  describe("luasystem()", function()

    it("picks up system.random", function()
      package.loaded.system = {
        random = function(n)
          return string.char(0):rep(n)
        end
      }

      local rng = require("uuid").rng.luasystem()

      assert.are.equal(package.loaded.system.random, rng)
    end)

    it("errors if not available", function()
      local old_require = _G.require
      finally(function()
        _G.require = old_require
      end)
      _G.require = function(name)
        if name ~= "system" then
          return old_require(name)
        end
        return error("not found")
      end

      local rng, err = require("uuid").rng.luasystem()
      assert.is.falsy(rng)
      assert.is.equal("luasystem not available", err)
    end)

    it("errors if too old", function()
      package.loaded.system = {} -- not having 'random' function

      local rng, err = require("uuid").rng.luasystem()
      assert.is.falsy(rng)
      assert.is.equal("luasystem version is too old, minimum version required is 0.3", err)
    end)

  end)



  describe("urandom()", function()

    it("generates 1 byte", function()
      local rng = require("uuid").rng.urandom()

      assert.is.string(rng(1))
      assert.is.equal(1, #rng(1))
    end)


    it("generates 256 bytes", function()
      local rng = require("uuid").rng.urandom()

      assert.is.string(rng(256))
      assert.is.equal(256, #rng(256))
    end)

    it("fails on Windows", function()
      local old_package_config = package.config
      finally(function()
        package.config = old_package_config -- luacheck: ignore
      end)
      -- make it think this is Windows
      package.config = "\\" .. package.config:sub(2,-1) -- luacheck: ignore

      local rng, err = require("uuid").rng.urandom()
      assert.is.falsy(rng)
      assert.is.equal("/dev/urandom is not available on Windows", err)
    end)

  end)


end)

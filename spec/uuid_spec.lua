local uuid = require("uuid")

-- start tests
describe("Testing uuid library", function()

  before_each(function()
  end)

  it("tests generating a uuid", function()
    assert.is_string(uuid.new())
    assert.is_string(uuid())
  end)

  it("tests the format of the generated uuid", function()
    for i = 1, 1000 do    -- some where to short, see issue #1, so test a bunch
      local u = uuid()
      assert.are_equal("-", u:sub(9,9))
      assert.are_equal("-", u:sub(14,14))
      assert.are_equal("-", u:sub(19,19))
      assert.are_equal("-", u:sub(24,24))
      assert.are_equal(36, #u)
    end
  end)
  
  it("tests the hwaddr parameter" , function()
    assert.has_error(function() uuid("12345678901") end)        -- too short
    assert.has_error(function() uuid("123a4::xxyy;;590") end)   -- too short after clean
    assert.has_error(function() uuid(true) end)                 -- not a string
    assert.has_error(function() uuid(123) end)                  -- not a string
    assert.not_has_error(function() uuid("abcdefabcdef") end)   -- hex only
    assert.not_has_error(function() uuid("123456789012") end)   -- right size
    assert.not_has_error(function() uuid("1234567890123") end)  -- oversize
  end)
  
  it("tests uuid.seed() using luasocket gettime() if available, os.time() if unavailable", function()
    -- create a fake socket module with a spy.
    local ls = { gettime = spy.new(function() return 123.123 end) }
    package.loaded["socket"] = ls
    uuid.seed()
    package.loaded["socket"] = nil
    assert.spy(ls.gettime).was.called(1)
    
    -- do again with os.time()
    local ot = os.time
    os.time = spy.new(os.time)
    uuid.seed()
    assert.spy(os.time).was.called(1)
    os.time = ot
    
  end)

  it("tests uuid.randomseed() to properly limit the provided value", function()
    local bitsize = 32
    assert.are.equal(12345, uuid.randomseed(12345))
    assert.are.equal(12345, uuid.randomseed(12345 + 2^bitsize))
  end)
  
end)
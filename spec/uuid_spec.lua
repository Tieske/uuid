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
    local u = uuid()
    assert.are_equal("-", u:sub(9,9))
    assert.are_equal("-", u:sub(14,14))
    assert.are_equal("-", u:sub(19,19))
    assert.are_equal("-", u:sub(24,24))
    assert.are_equal(36, #u)
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
  
  it("tests using luasocket gettime() if available", function()
    -- create a fake socket module with a spy.
    local ls = { gettime = spy.new(function() return 123.123 end) }
    package.loaded["socket"] = ls
    -- clear loaded uuid module, and reload
    package.loaded["uuid"] = nil
    uuid = require("uuid")
    -- now check whether our gettime() function was called
    assert.spy(ls.gettime).was.called(1)
  end)
  
end)
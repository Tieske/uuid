
-- start tests
describe("Testing uuid library", function()
  local uuid
  local old_get_random_bytes
  before_each(function()
    uuid = require("uuid")

    old_get_random_bytes = uuid.get_random_bytes
    uuid.set_rng(function(n)
      return string.char(0):rep(n)
    end)
  end)

  after_each(function()
    uuid.get_random_bytes = old_get_random_bytes
  end)

  it("tests generating a uuid", function()
    local id = uuid.new()
    assert.are.same('00000000-0000-4000-8000-000000000000', id)
    assert.are.same(id, uuid())
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
    assert.has_error(function() uuid.new("12345678901") end)        -- too short
    assert.has_error(function() uuid.new("123a4::xxyy;;590") end)   -- too short after clean
    assert.has_error(function() uuid.new(true) end)                 -- not a string
    assert.has_error(function() uuid.new(123) end)                  -- not a string
    assert.has_no.error(function() uuid.new("abcdefabcdef") end)    -- hex only
    assert.same('00000000-0000-4000-8000-abcdefabcdef', uuid.new("abcdefabcdef"))
    assert.has_no.error(function() uuid.new("123456789012") end)    -- right size
    assert.same('00000000-0000-4000-8000-123456789012', uuid.new("123456789012"))
    assert.has_no.error(function() uuid.new("1234567890123") end)   -- oversize
    assert.same('00000000-0000-4000-8000-123456789012', uuid.new("1234567890123"))
  end)

  it("uuid.v4()", function()
    local id = uuid.v4()
    assert.are.same('00000000-0000-4000-8000-000000000000', id)
    assert.are.same(id, uuid())

    local uuid_v4_pattern = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-4%x%x%x%-[%8%9aAbB]%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"
    uuid.set_rng(uuid.rng.math_random())
    for i = 1, 1000 do
      local u = uuid.v4()
      assert.are.equal(u, u:match(uuid_v4_pattern))
    end
  end)

end)

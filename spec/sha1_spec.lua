-- This runs a few sanity tests, more tests are embedded in the
-- imported module itself.

describe("SHA1", function()

  local sha1

  before_each(function()
    package.loaded["uuid.rng.sha1"] = nil
    sha1 = require("uuid.rng.sha1")
  end)

  after_each(function()
    sha1 = nil
    package.loaded["uuid.rng.sha1"] = nil
  end)


  it("sanity", function()
    assert.are.equal("7f103bf600de51dfe91062300c14738b32725db5", sha1.hex "http://regex.info/blog/")
    assert.are.equal("a9993e364706816aba3e25717850c26c9cd0d89d", sha1.hex "abc")
    assert.are.equal("84983e441c3bd26ebaae4aa1f95129e5e54670f1", sha1.hex "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
    assert.are.equal("2fd4e1c67a2d28fced849ee1bb76e7391b93eb12", sha1.hex "The quick brown fox jumps over the lazy dog")
    assert.are.equal("de9f2c7fd25e1b3afad3e85a0bd17d9b100db4b3", sha1.hex "The quick brown fox jumps over the lazy cog")
  end)

end)

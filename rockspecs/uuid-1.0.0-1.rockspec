local package_name = "uuid"
local package_version = "1.0.0"
local rockspec_revision = "1"
local github_account_name = "Tieske"
local github_repo_name = package_name


package = package_name
version = package_version.."-"..rockspec_revision
source = {
  url = "git+https://github.com/"..github_account_name.."/"..github_repo_name..".git",
  branch = (package_version == "dev") and "master" or nil,
  tag = (package_version ~= "dev") and package_version or nil,
}

description = {
  summary = "Generates uuids in pure Lua",
  detailed = [[
    Generates uuids in pure Lua, but requires a
    good random seed or a unique string. Please check the documentation.
  ]],
  license = "Apache 2.0",
  homepage = "https://github.com/"..github_account_name.."/"..github_repo_name,
}

dependencies = {
  "lua >= 5.1, < 5.5",
}

build = {
  type = "builtin",
  modules = {
    ["uuid"] = "src/uuid.lua",
    ["uuid.rng.init"] = "src/uuid/rng/init.lua",
    ["uuid.rng.sha1"] = "src/uuid/rng/sha1.lua",
  },
  copy_directories = {
    "docs",
  },
}

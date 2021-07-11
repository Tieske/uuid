[![Build Status](https://travis-ci.com/Tieske/uuid.svg?branch=master)](https://travis-ci.com/Tieske/uuid)

uuid
====

Modified module from [Rackspace](https://github.com/kans/zirgo/blob/807250b1af6725bad4776c931c89a784c1e34db2/util/uuid.lua) original. Generates uuids in pure Lua.

Notes
=====
Please read [documentation](https://tieske.github.io/uuid/) carefully regarding random seeds or unique strings to be provided to get a decent randomized uuid value.

Home
====
[Source code](https://github.com/Tieske/uuid) is on github

License & copyright
===================
Rackspace (original) and Thijs Schreijer (modifications), Apache 2.0, see `uuid.lua`

Install
=======
Use LuaRocks. To fetch and install from a LuaRocks server do `luarocks install uuid`.
For a development installation from local source, do `luarocks make` from the main directory.

Test
====
Tests are available and can be executed using [busted](http://olivinelabs.com/busted/),
and LuaCheck for linting.

Changes
=======

0.3     11-Jul-2021

  - Fix: set proper type for UUIDv4 type
  - Feat: improve seeding for OpenResty
  - Doc: fix link in readme

0.2     09-May-2013

  - Bugfix; 0-hex was displayed as "" instead of "00", making some uuids too short
  - Bugfix; math.randomseed() overflow caused bad seeding

0.1     28-Apr-2013

  - initial version


uuid
====

Modified module from [Rackspace](https://github.com/kans/zirgo/blob/807250b1af6725bad4776c931c89a784c1e34db2/util/uuid.lua) original. Generates uuids in pure Lua.

Notes
=====
Please read [documentation](http://tieske.github.com/uuid/) carefully regarding random seeds or unique strings to be provided to get a decent randomized uuid value.

Home
====
[Source code](https://github.com/Tieske/uuid) is on github

License & copyright
===================
Rackspace (original) and Thijs Schreijer (modifications), Apache 2.0, see `uuid.lua`

Install
=======
Use LuaRocks. For an installation from local source, do `sudo luarocks make` from the main directory. To fetch and install from a LuaRocks server without manual unpacking do `sudo luarocks install uuid`.

NOTE: on windows, skip the `sudo` in the commands above.

Test
====
Tests are available and can be executed using [busted](http://olivinelabs.com/busted/)

Changes
=======

0.2     09-May-2013

  - Bugfix; 0-hex was displayed as "" instead of "00", making some uuids too short
  - Bugfix; math.randomseed() overflow caused bad seeding
  
0.1     28-Apr-2013

  - initial version


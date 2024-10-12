# CHANGELOG

## Versioning

This library is versioned based on Semantic Versioning ([SemVer](https://semver.org/)).

#### Version scoping

The scope of what is covered by the version number excludes:

- error messages; the text of the messages can change, unless specifically documented.

#### Releasing new versions

- create a release branch
- update the changelog below
- update version and copyright-years in `./LICENSE.md` (bottom) and `./src/uuid.lua` (in
  doc-comments header)
- create a new rockspec and update the version inside the new rockspec:<br/>
  `cp uuid-dev-1.rockspec ./rockspecs/uuid-X.Y.Z-1.rockspec`
- test: run `make test` and `make lint`
- clean and render the docs: run `make clean` and `make docs`
- commit the changes as `release X.Y.Z`
- push the commit, and create a release PR
- after merging tag the release commit with `X.Y.Z`
- upload to LuaRocks:<br/>
  `luarocks upload ./rockspecs/uuid-X.Y.Z-1.rockspec --api-key=ABCDEFGH`
- test the newly created rock:<br/>
  `luarocks install uuid`

## Version history

### Version 1.0.0, released 13-Oct-2024

- BREAKING: no default rng will be picked anymore, one must be set explicitly, see `set_rng`
- BREAKING: calling on the module table `uuid()` will now call `v4()` instead of `new()`
  which means it no longer supports the `hwaddr` parameter
- Change: `new` function with the `hwaddr` parameter is deprecated, will be removed later
- Change: `randomseed` has moved to `rng.math_randomseed`, alias will be removed later
- Change: `seed` has moved to `rng.seed`, alias will be removed later
- Feat: new `rng` module with multiple `rng`s available
- Feat: new `set_rng` function to set the `rng` to use
- Feat: the `rng.seed` function has a new parameter `userinput` that allows the user to specify
  additional input for seeding the Lua rng (eg. pass in a mac address).
- Feat: new `rng.luasystem` rng that uses LuaSystem for random number generation (Posix + Windows)
- Feat: new `rng.urandom` rng that uses /dev/urandom for random number generation (Posix, no Windows)
- Feat: new `rng.win_ffi` rng that uses the ffi for random number generation (Windows, no Posix)
- Feat: new `rng.math_random` rng that replaces the old rng used, based on Lua's `math.random` function.
- Feat: improved seeding, using LuaSystem, win-ffi, or /dev/urandom if available. If not, the fallback now uses
  more inputs (including a user provided one, eg. a mac address) and calculates a SHA1 used as seed.
  Also support for the Lua 5.4 `randomseed()` implementation

### Version 0.3, released 11-Jul-2021

- Fix: set proper type for UUIDv4 type
- Feat: improve seeding for OpenResty
- Doc: fix link in readme

### Version 0.2, released 09-May-2013

- Bugfix; 0-hex was displayed as "" instead of "00", making some uuids too short
- Bugfix; math.randomseed() overflow caused bad seeding

### Version 0.1, released 28-Apr-2013

  - initial version

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

### Version X.Y.Z, unreleased

- bla bla

### Version 0.3, released 11-Jul-2021

- Fix: set proper type for UUIDv4 type
- Feat: improve seeding for OpenResty
- Doc: fix link in readme

### Version 0.2, released 09-May-2013

- Bugfix; 0-hex was displayed as "" instead of "00", making some uuids too short
- Bugfix; math.randomseed() overflow caused bad seeding

### Version 0.1, released 28-Apr-2013

  - initial version

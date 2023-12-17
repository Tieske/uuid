# 1. Introduction

High quality UUIDs v4 can only be generated if the source of the random data is good enough.
If it is predictable then it might become a security risk.

Read up on the use of the `rng.math_randomseed` and `rng.seed` functions if you need a pure-Lua
implementation. Preferably the LuaSystem module is used for strong random numbers, if Windows
compatibility isn't required then falling back to /dev/urandom on Posix is a good alternative.

When using neither of those and falling back to the Lua internal rng, ensure that it is
properly seeded, and be aware of the risks (especially for Lua 5.1 to 5.3 which use the
system `rand` and `srand` functions)

**Important:** the random seed is a global piece of data. Hence setting it is
an application level responsibility, libraries should never set it!

See this issue; [https://github.com/Kong/kong/issues/478](https://github.com/Kong/kong/issues/478)
It demonstrates the problem of using time as a random seed. Specifically when used from multiple processes.
So make sure to seed only once, application wide. And to not have multiple processes do that
simultaneously.

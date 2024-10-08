local uuid = require "uuid"
print(uuid)
uuid.set_rng(uuid.rng.win_ffi())
print(uuid.v4())
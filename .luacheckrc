std             = "ngx_lua"
unused_args     = false
redefined       = false
max_line_length = false


globals = {
}


not_globals = {
    "string.len",
    "table.getn",
}


ignore = {
    --"6.", -- ignore whitespace warnings
}


exclude_files = {
    --"spec/fixtures/invalid-module.lua",
    --"spec-old-api/fixtures/invalid-module.lua",
}


files["spec/**/*.lua"] = {
    std = "ngx_lua+busted",
}


package = "shiplog"
version = "0.0.1-1"
rockspec_format = "3.0"

source = {
    url = "git://github.com/giann/shiplog",
}

description = {
    summary  = "⚓ A journal keeping cli tool",
    homepage = "https://github.com/giann/shiplog",
    license  = "MIT/X11",
}

build = {
    modules = {
    },
    type = "builtin",
    install = {
        bin = {
            "bin/shiplog"
        }
    }
}

dependencies = {
    "lua >= 5.3",
    "sirocco >= 0.0.1-5",
    "hump >= 0.4-2",
    "lpeg >= 1.0.1-1",
    "argparse >= 0.6.0-1",
    "compat53 >= 0.7-1",
    "lua-term >= 0.7-1",
    "luasql-sqlite3 >= 2.4.0-1",
}

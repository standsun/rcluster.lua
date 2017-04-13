# Name

`rcluster` - lua redis cluster client driver

# Table of Contents

* [Name](#name)
* [Description](#description)
* [Install](#install)
    * [Compile luacrc16](#compile-luacrc16)
    * [Install rcluster](#install-rcluster)
* [Install](#install)
* [Methods](#methods)
* [Example](#example)
    * [Init](#init)
    * [Operate a key](#operate-a-key)
    * [Operate multiple keys](#operate-multiple-keys)
* [Issues](#issues)
* [TODO](#todo)

# Description

The lua library is a redis client driver that support redis cluster


The library takes advantage of [lua-resty-redis](https://github.com/agentzh) and [luacrc16](https://github.com/youlu-cn/luacrc16) :

* [lua-resty-redis](https://github.com/agentzh) - Lua redis client driver which written by [agentzh](https://github.com/agentzh)
* [luacrc16](https://github.com/youlu-cn/luacrc16) - crc16 for lua which written by [youlu-cn](https://github.com/youlu-cn)

`Note:` Recommended to use the lua library in [openresty](https://github.com/openresty/openresty) environment

# Install

The following steps assume that the openresty environment have been ok and the installation path is `/usr/local/openresty/`


### Compile luacrc16

```shell
git clone https://github.com/youlu-cn/luacrc16.git
cd luacrc16
gcc crc16.c -fPIC -shared -o crc16.so
mv crc16.so /usr/local/openresty/lualib/
```

`Note:`

* If prompted lua.h lualib.h lauxlib.h does not exist when compiling, modify the crc16.c include path to absolute path.

```lua
-- modify before
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

-- modify after
#include </usr/local/openresty/luajit/include/luajit-2.1/lua.h>
#include </usr/local/openresty/luajit/include/luajit-2.1/lualib.h>
#include </usr/local/openresty/luajit/include/luajit-2.1/lauxlib.h>
```

* If the server has multiple luajit environment, recommended to use the openresty luajit.

* Paste the generated `crc16.so` to the lua_package_cpath supported directory (there paste to `/usr/local/openresty/lualib/`).

[Back to TOC](#table-of-contents)

### Install rcluster

```
git clone https://github.com/standsun/rcluster.lua.git
cd rcluster.lua
mv rcluster.lua /usr/local/openresty/lualib/resty/rcluster.lua
```

[Back to TOC](#table-of-contents)

# Methods

* Rcluster:new(cfg)
* Rcluster:init_pipeline()
* Rcluster:cancel_pipeline()
* Rcluster:commit_pipeline()
* Redis single key operation method, see agentzh's [lua-resty-redis#methods](https://github.com/openresty/lua-resty-redis#methods)

```lua
-- copy from redis.lua

local common_cmds = {
    "get",      "set",          "mget",     "mset",
    "del",      "incr",         "decr",                 -- Strings
    "llen",     "lindex",       "lpop",     "lpush",
    "lrange",   "linsert",                              -- Lists
    "hexists",  "hget",         "hset",     "hmget",
    --[[ "hmset", ]]            "hdel",                 -- Hashes
    "smembers", "sismember",    "sadd",     "srem",
    "sdiff",    "sinter",       "sunion",               -- Sets
    "zrange",   "zrangebyscore", "zrank",   "zadd",
    "zrem",     "zincrby",                              -- Sorted Sets
    "auth",     "eval",         "expire",   "script",
    "sort"                                              -- Others
}
```

[Back to TOC](#table-of-contents)

# Example

### Init

```lua
local rcluster = require 'resty.rcluster'

local redis = rcluster:new({
    --db                  = 2,            -- select(db)，可选，默认0
    --auth                = 'password',   -- auth(auth)，可选，默认nil
    --keepalive_timeout   = 10000,        -- 连接池的响应时间（毫秒） 可选，默认10000
    --max_connections     = 100,          -- 连接池最大连接数，可选，默认 100
    server  = {                              -- 必选，获取slots信息
        { host = "192.168.0.11", port = 6525 },
        { host = "192.168.0.12", port = 6525 },
        { host = "192.168.0.13", port = 6525 },
    }
})
```

### Operate a key

```lua
local res,err = redis:hget("user_info_1000","username")
```

[Back to TOC](#table-of-contents)

### Operate multiple keys

```lua
redis:init_pipeline()

redis:hget("user_info_1000","username")
redis:hset("user_info_1000","username","standsun")
redis:hget("user_info_1002","username")

local res,err = redis:commit_pipeline()
```

[Back to TOC](#table-of-contents)

# Issues 

# TODO

[Back to TOC](#table-of-contents)

# MORE

* [lua-resty-redis-cluster](https://github.com/cuiweixie/lua-resty-redis-cluster) - another openresty redis cluster client wrotten by [cuiweixie](https://github.com/cuiweixie)

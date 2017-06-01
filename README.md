# Name

`rcluster` - lua redis cluster client driver

# Table of Contents

* [Name](#name)
* [Description](#description)
* [Install](#install)
    * [Compile luacrc16](#compile-luacrc16)
    * [Install rcluster](#install-rcluster)
* [Methods](#methods)
* [Example](#example)
    * [Init](#init)
    * [Operate a key](#operate-a-key)
    * [Operate multiple keys](#operate-multiple-keys)
* [Stress Testing](#stress-testing)
    * [web server and redis cluster environment](#web server and redis cluster environment)
    * [Pressure measuring result](#pressure-measuring-result)
* [Issues](#issues)
* [TODO](#todo)

# Description

The lua library is a redis client driver that support redis cluster


The library takes advantage of [https://github.com/openresty/lua-resty-redis](https://github.com/agentzh) and [luacrc16](https://github.com/youlu-cn/luacrc16) :

* [lua-resty-redis](https://github.com/openresty/lua-resty-redis) - Lua redis client driver which written by [agentzh](https://github.com/agentzh)
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
mv src/rcluster.lua /usr/local/openresty/lualib/resty/rcluster.lua
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
    --name                = "myproject",  -- optional, default value: default
    --auth                = 'password',   -- optional, default value: nil
    --timeout             = 1000,         -- optional, default value: 3000 ms
    --keep_time           = 10000,        -- optional, default value: 10000 ms
    --keep_size           = 100,          -- optional, default value: 100
    server  = {                           -- required
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

# Stress Testing

### web server and redis cluster environment

web server cpu: `24  Intel(R) Xeon(R) CPU E5-2620 v3 @ 2.40GHz`

redis config：

```
{
    name                = "testing",
    auth                = 'guest',  -- need auth
    timeout             = 1000,
    keep_time           = 10000,
    keep_size           = 100,
    server  = {
        { host = "192.168.10.100", port = 6003},
        { host = "192.168.10.101", port = 6003},
    }
}
```

cluster slots：

```shell
192.168.10.100 :6003
192.168.10.100 :7003
192.168.10.101 :6003
192.168.10.101 :7003
192.168.10.102 :6003
192.168.10.102 :7003
192.168.10.103 :6003
192.168.10.103 :7003
192.168.10.104 :6003
192.168.10.104 :7003
192.168.10.105 :6003
192.168.10.105 :7003
192.168.10.106 :6003
192.168.10.106 :7003
192.168.10.107 :6003
192.168.10.107 :7003
```

### Pressure measuring result

- Scene 1: nginx direct output

`Load test server`

```shell
$ wrk -t2 -c2000 -d3m -T10s --latency http://example.api.com/

# result

Running 3m test @ http://example.api.com/
  2 threads and 2000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    64.76ms  165.19ms   7.29s    94.54%
    Req/Sec    50.04k     8.43k   92.22k    68.54%
  Latency Distribution
     50%   12.23ms
     75%   41.23ms
     90%  185.64ms
     99%  627.51ms
  17922852 requests in 3.00m, 3.04GB read
  Socket errors: connect 0, read 6742, write 0, timeout 2
Requests/sec:  99538.76
Transfer/sec:     17.27MB
```

`Web server`

```shell
$ dstat -tcr --net-packets -N eth2

# partial results

----system---- ----total-cpu-usage---- --io/total- --pkt/eth2-
  date/time   |usr sys idl wai hiq siq| read  writ|#recv #send
01-06 15:39:19| 10  22  61   0   0   7|   0  6.00 | 124k  132k
01-06 15:39:20|  9  20  65   0   0   7|   0  13.0 | 111k  121k
01-06 15:39:21| 10  21  63   0   0   7|   0     0 | 117k  125k
01-06 15:39:22|  9  20  64   0   0   7|   0     0 | 115k  123k
01-06 15:39:23| 10  21  62   0   0   7|   0     0 | 121k  129k
```

- Scene 2: get one user info (not using pipeline)

`Load test server`

```shell
$ wrk -t2 -c2000 -d3m -T10s --latency --script=scripts/uri.lua http://example.api.com/

# scripts/uri.lua content

request = function()
    path = "/get_one_userinfo?uid=" .. math.random(1,100000)
    return wrk.format(nil, path)
end

# result

Running 3m test @ http://example.api.com/
  2 threads and 2000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    37.64ms   53.61ms   3.01s    88.69%
    Req/Sec    38.41k    11.74k   73.31k    67.85%
  Latency Distribution
     50%   18.33ms
     75%   29.67ms
     90%  103.83ms
     99%  242.30ms
  13771552 requests in 3.00m, 3.04GB read
  Socket errors: connect 0, read 6579, write 0, timeout 0
Requests/sec:  76487.79
Transfer/sec:     17.28MB
```

`Web server`

```shell
$ dstat -tcr --net-packets -N eth2

# partial results

----system---- ----total-cpu-usage---- --io/total- --pkt/eth2-
  date/time   |usr sys idl wai hiq siq| read  writ|#recv #send
01-06 15:55:45| 39  16  35   0   0  10|   0  3.00 | 256k  263k
01-06 15:55:46| 38  16  36   0   0  10|   0     0 | 259k  264k
01-06 15:55:47| 38  16  35   0   0  10|   0  2.00 | 261k  265k
01-06 15:55:48| 38  16  35   0   0  11|   0     0 | 256k  264k
01-06 15:55:49| 39  16  35   0   0  11|   0     0 | 264k  267k
```

- Scene 3: get one user info (using pipline)

`Load test server`

```shell
$ wrk -t2 -c2000 -d3m -T10s --latency --script=scripts/uri.lua http://example.api.com/

# scripts/uri.lua content

request = function()
    path = "/get_multi_userinfo?uids=" .. math.random(1,100000)
    return wrk.format(nil, path)
end

# result

Running 3m test @ http://example.api.com/
  2 threads and 2000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    38.51ms   51.10ms   1.24s    88.86%
    Req/Sec    36.11k    10.65k   76.94k    68.69%
  Latency Distribution
     50%   20.59ms
     75%   33.10ms
     90%  100.90ms
     99%  239.68ms
  12947142 requests in 3.00m, 2.98GB read
  Socket errors: connect 0, read 3036, write 0, timeout 0
Requests/sec:  71904.74
Transfer/sec:     16.92MB
```

`Web server`

```shell
$ dstat -tcr --net-packets -N eth2

# partial result
----system---- ----total-cpu-usage---- --io/total- --pkt/eth2-
  date/time   |usr sys idl wai hiq siq| read  writ|#recv #send
01-06 16:03:51| 43  14  33   0   0  10|   0  8.00 | 257k  257k
01-06 16:03:52| 44  15  29   0   0  11|   0   107 | 269k  271k
01-06 16:03:53| 42  16  31   0   0  11|   0     0 | 264k  268k
01-06 16:03:54| 42  15  33   0   0  10|   0  1.00 | 250k  254k
01-06 16:03:55| 41  14  35   0   0  10|   0     0 | 241k  245k
01-06 16:03:56| 44  15  31   0   0  10|   0  4.00 | 268k  275k
01-06 16:03:57| 43  15  33   0   0  10|   0   109 | 257k  259k
```

- Scene 4: get 10 user info (use pipline)

`Load test server`

```shell
$ wrk -t2 -c2000 -d3m -T10s --latency --script=scripts/uri.lua http://example.api.com/

# scripts/uri.lua content
request = function()
    path = "/get_multi_userinfo?uids="
    for i = 1,10,1 do
        path = path .. math.random(1,100000) ..','
    end
    path = string.gsub(path, ",$", "")

    return wrk.format(nil, path)
end

# result

Running 3m test @ http://example.api.com/
  2 threads and 2000 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    73.30ms   51.58ms   1.29s    90.40%
    Req/Sec    14.30k     3.31k   23.21k    83.09%
  Latency Distribution
     50%   61.39ms
     75%   82.64ms
     90%  120.40ms
     99%  236.09ms
  5122467 requests in 3.00m, 2.85GB read
  Socket errors: connect 0, read 2981, write 0, timeout 0
Requests/sec:  28447.73
Transfer/sec:     16.19MB
```

`Web server`

```shell
$ dstat -tcr --net-packets -N eth2

# partial result

----system---- ----total-cpu-usage---- --io/total- --pkt/eth2-
  date/time   |usr sys idl wai hiq siq| read  writ|#recv #send
01-06 16:11:03| 61  16  11   0   0  12|   0   347 | 410k  450k
01-06 16:11:04| 61  16  13   0   0  11|   0     0 | 404k  441k
01-06 16:11:05| 62  15  11   0   0  12|   0     0 | 407k  443k
01-06 16:11:06| 63  16  10   0   0  11|   0     0 | 417k  458k
01-06 16:11:07| 58  14  17   0   0  11|   0     0 | 381k  414k
```

# Issues 

# Todo

[Back to TOC](#table-of-contents)

# More

* [lua-resty-redis-cluster](https://github.com/cuiweixie/lua-resty-redis-cluster) - another openresty redis cluster client wrotten by [cuiweixie](https://github.com/cuiweixie)
* [redis_cluster](https://github.com/hyw97m/redis_cluster) - another openresty redis cluster client wrotten by [hyw97m](https://github.com/hyw97m)

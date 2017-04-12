# rcluster （lua redis cluster client）

`rcluster` - 是支持redis cluster的lua客户端，在openresty环境下编写使用，依赖[agentzh](https://github.com/agentzh) 的 `redis.lua` ，`crc16` 算法依赖 [luacrc16](https://github.com/youlu-cn/luacrc16) 实现

* [依赖和安装](#install)
* [使用示例](#example)
* [注意事项](#notice)
* [TODO](#todo)


## 依赖和安装

假设已经搭建好openresty环境，安装路径为`/usr/local/openresty/`

#### 编译luacrc16

```
git clone https://github.com/youlu-cn/luacrc16.git
cd luacrc16
gcc crc16.c -fPIC -shared -o crc16.so

```

说明：编译时如果提示 lua.h lualib.h lauxlib.h 文件不存在，修改crc16.c的include引用为绝对路径，如果有多个luajit环境，建议使用openresty的luajit，修改后：

修改前

```
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
```

修改后

```
#include </usr/local/openresty/luajit/include/luajit-2.1/lua.h>
#include </usr/local/openresty/luajit/include/luajit-2.1/lualib.h>
#include </usr/local/openresty/luajit/include/luajit-2.1/lauxlib.h>
```

将生成的 crc16.so 文件粘贴到 lua_package_cpath 支持的目录

#### 部署rcluster

```
git clone https://github.com/standsun/rcluster.lua.git
cd rcluster.lua
mv rcluster.lua /usr/local/openresty/lualib/resty/rcluster.lua
```

## 方法

* Rcluster:new(cfg) - 初始化项目

* Rcluster:init_pipeline() -- 初始化 pipeline请求

* Rcluster:cancel_pipeline() -- 取消 pipeline 请求

* Rcluster:commit_pipeline() -- 提交 pipeline 请求

* `redis`单`key`操作方法，详见 `/usr/local/openresty/lualib/resty/rcluster.lua`

```
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

## 使用示例

#### 初始化

```
local rcluster = require 'resty.rcluster'

local redis = rcluster:new({
    --db                  = 2,            -- select(db)，可选，默认0
    --auth                = 'password',   -- auth(auth)，可选，默认nil
    --keepalive_timeout   = 10000,        -- 连接池的响应时间（毫秒） 可选，默认10000
    --max_connections     = 100,          -- 连接池最大连接数，可选，默认 100
    server  = {							  -- 必选，获取slots信息
        { host = "192.168.0.11", port = 6525 },
        { host = "192.168.0.12", port = 6525 },
        { host = "192.168.0.13", port = 6525 },
    }
})
```

#### 单请求操作

```
local res,err = redis:hget("user_info_1000","username")
```

#### 多请求操作

```
redis:init_pipeline()

redis:hget("user_info_1000","username")
redis:hset("user_info_1000","username","standsun")
redis:hget("user_info_1002","username")

local res,err = redis:commit_pipeline()
```

## 注意事项

* rcluster 内部使用了 set_keepalive 连接池，没有提供取消的方法，
* 暂未进行完整的单元测试和性能测试（还没有投入生产环境），使用时建议进行完整的压测和功能测试，最好过一下代码实现

## TODO:

* slots 结点信息一定时间内重复使用
* 请求redis超时设置
* 公用实例化的redis
* 完善错误检测
* 压测报告
* 单元测试

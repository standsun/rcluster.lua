package = "lua-resty-redis-cluster"
version = "0.1-0"
source = {
  url = "git://github.com/standsun/rcluster.lua.git"
}
description = {
  summary = "Lua Redis cluster client driver",
  license = "MIT"
}
dependencies = {
  "luacrc16 == 1.0",
  "lua >= 5.1",
}
build = {
  type = "builtin",
  modules = {
      ["resty.rcluster"] = "src/rcluster.lua"
  }
}

-- Create by sunbingchao@le.com 2017-04-11 16:24

local setmetatable = setmetatable
local rawget = rawget
local randomseed = math.randomseed
local random = math.random

local redis = require "resty.redis"

local crc16 = require 'crc16'

local _M = { 
    _VERSION = '0.01',
    cfg      = {},
}


function _M.new(self, cfg)
    self.cfg["auth"]    = cfg.auth      or nil
    self.cfg["db"]      = cfg.db        or 0
    self.cfg["timeout"] = cfg.timeout   or 10000
    self.cfg.server     = cfg.server[ math.random(1, #cfg["server"]) ] or nil

    local red, err = self:connect(self.cfg.server.host, self.cfg.server.port)

    local nodes = {}
    if not err then
        local res, err = red:cluster('slots')
        for i,node in pairs(res) do
            nodes[i] = {
                min_hash_slot = node[1],
                max_hash_slot = node[2],
                host          = node[3][1],
                port          = node[3][2]
            }
        end
    end
    self:close(red)

    return setmetatable({ nodes = nodes }, { __index = _M })
end

function _M.connect(self, host, port)
    local red = redis:new()
    local ok, err = red:connect(host, port)
    if not ok then
        return nil, err
    end

    if self.cfg.auth then
        local res, err = red:auth(self.cfg.auth)
        if not res then
            return nil, err
        end
    end

    if self.cfg.db and self.cfg.db > 0 then
        local res, err = red:auth(self.cfg.auth)
        if not res then
            return nil, err
        end
    end

    red:add_commands("cluster")

    return red
end

-- 关闭连接
-- 保持连接并将连接归还到连接池中，下次连接会先去连接池中找
function _M:close(red)
    if not red or type(red) ~= 'table' then
        return nil, "error redis handle type :" .. type(red)
    end

    local ok,err = red:set_keepalive(
        self.cfg.keepalive_timeout or 10000,
        self.cfg.max_connections or 100
    )

    if not ok then
        ngx.ctx.loger:error({
            err     = err,
            message = 'mysql close set_keepalive error'
        })
        return nil,err
    end
end

function _M._do_cmd(self, cmd, key, ...)
    local node = self.get_node(self, key)

    local res, err
    local reqs = rawget(self,'_reqs')
    if reqs then
        local hash = node.host..":"..node.port

        local req = reqs[hash]
        if not req then
            req = {
                node    = {
                    host  = node.host,
                    port  = node.port
                },
                cmds    = {}
            }
        end

        nreq_cmd = #req.cmds + 1
        req.cmds[nreq_cmd] = { 
            cmd = cmd, 
            key = key,
            arg = {...},
            counter = self._reqs_counter
        }

        self._reqs[hash] = req

        self._reqs_counter = self._reqs_counter + 1
    else
        red, err = self:connect(node.host, node.port)
        if err then return red, err end

        res, err = red[cmd](red, key, ...)

        self:close(red)
    end
    
    return res, err
end

function _M.init_pipeline(self)
    self._reqs = {}
    self._reqs_counter = 1
end

function _M.cancel_pipeline(self)
    self._reqs = nil
    self._reqs_counter = 1
end

function _M.commit_pipeline(self)
    local reqs = rawget(self,"_reqs")

    if not reqs or type(reqs) ~= 'table' or reqs == {} then
        return nil, "request not exists"
    end

    local res = {}, red, err

    for i, req in pairs(reqs) do
        if #req.cmds > 0  then
            red, err = self:connect(req.node.host, req.node.port)
            if err then return red, err end

            red:init_pipeline()
            for i,cmd in pairs(req.cmds) do
                if #cmd.arg > 0 then
                    red[cmd.cmd](red, cmd.key, unpack(cmd.arg))
                else
                    red[cmd.cmd](red, cmd.key)
                end
            end
            local result, err = red:commit_pipeline()

            for i, cmd in pairs(req.cmds) do
                res[cmd.counter] = result[i]
            end

            self:close(red)
        end
    end

    return res

end

function _M.get_node(self, key)
    local hash_slot = crc16.compute(key) % 16384
    for _, node in pairs(self.nodes) do
        if hash_slot >= node['min_hash_slot'] and hash_slot <= node['max_hash_slot'] then
            return node
        end
    end
end

setmetatable(_M, {
    __index = function(self, cmd) 

        local method = function(self, ...)
            return self._do_cmd(self, cmd, ...)
        end
        return method
    end
})

return _M

#!/usr/bin/env lua

local LC                = LC
local system_hooks      = {}

local hook_directory    = "/usr/share/liveconfig/hooks"
local hooks_config_file = "/etc/liveconfig/hooks.conf"

local function file_exists(filename)
   local f=io.open(filename,"r")
   if f~=nil then io.close(f) return true end
end

local function get_file_contents(filename)
        local f,err = io.open(filename,"r")
        if(f) then
                data=f:read("*a")
                f:close()
        end
        return data
end

defined_hooks = {}

local function hook_validated(hook)

        if (
                        type(hook)              == "table"
                and     hook["name"]            ~= nil
                and     hook["lua_module"]      ~= nil
                and     hook["lua_function"]    ~= nil
                and     string.match(hook["name"],"^[a-zA-Z0-9_]+$")
                and     string.match(hook["lua_module"],"^[a-zA-Z0-9_]+$")
                and     string.match(hook["lua_function"],"^[a-zA-Z0-9_]+$")
                and     (
                                hook["execution"]       == "pre"
                        or      hook["execution"]       == "post"
                        )
                ) then
                return true
        end
end

local function load_hooks_from_file()

        if(file_exists(hooks_config_file)) then
                data = get_file_contents(hooks_config_file)
                for line in data:gmatch("(.-)\n") do

                        if(not line:match("^#")) then
                                if(not line:match("^%s*$")) then
                                        local hook = {}
                                        line:gsub("^%s*([a-zA-Z0-9_]+)%s*,([a-zA-Z0-9_]+)\.([a-zA-Z0-9_]+)%s*,([a-zA-Z]+)%s*$",
                                                function(m1,m2,m3,m4)
                                                        hook["name"]            = m1
                                                        hook["lua_module"]      = m2
                                                        hook["lua_function"]    = m3
                                                        hook["execution"]       = m4
                                                end)
                                        LC.log.print(LC.log.INFO,
                                                   "name: >>"  ..tostring(hook["name"])         .."<<"
                                                 .." mod: >>"  ..tostring(hook["lua_module"])   .."<<"
                                                .." func: >>" ..tostring(hook["lua_function"])  .."<<"
                                                .." exec: >>"..tostring(hook["execution"])      .."<<")
                                        if(hook["name"] ~= nil and hook_validated(hook)) then
                                                LC.log.print(LC.log.INFO,"Hook definition for hook "..tostring(hook["name"]).." validated.")
                                                defined_hooks[#defined_hooks+1]=hook
                                        else
                                                LC.log.print(LC.log.WARNING,"Hook definition for hook "..tostring(hook["name"]).." invalid. Ignoring Hook.")
                                        end
                                end
                        end
                end

        end
end

local function protected_function_load(wanted_mod,wanted_func)

        local tmp_function = function(lua_module)
                return require(lua_module)
                end

        -- load the module protected from error
        LC.log.print(LC.log.INFO,"Trying to load module " .. wanted_mod)
        local res, loaded_module = pcall(tmp_function,wanted_mod)
        if(res) then
                LC.log.print(LC.log.INFO,"Loading of module " .. wanted_mod.." successful")
                -- check if the wanted function exists
                if(loaded_module[wanted_func]) then
                        LC.log.print(LC.log.INFO,"Wanted function " .. wanted_func.." exists within module " ..wanted_mod)
                        return true,loaded_module[wanted_func],loaded_module
                end
        end
end

local function exec_hook_script(hookname)
        if(hookname and type(hookname)=="string") then
                local hook_file = hook_directory .. "/" .. hookname
                if(file_exists(hook_file)) then
                        LC.log.print(LC.log.INFO,"Hookfile " .. hookname .." exists. Hook will be executed now.")
                        local ex,stdout,stderr = LC.exec(hook_file)
                else
                        LC.log.print(LC.log.INFO,"Hookfile " .. hookname .." does not exists.")
                end
        end
end

function system_hooks.load()

        load_hooks_from_file()
        LC.log.print(LC.log.INFO,"Loading hooks...")
        for i,hook in ipairs(defined_hooks) do
                local load_res,hook_function_backup,loaded_module  = protected_function_load(hook["lua_module"],hook["lua_function"])
                if(load_res) then
                        LC[hook["lua_module"]]=loaded_module
                        new_function = function(...)
                                        local res
                                        if(hook["execution"] == "pre") then
                                                exec_hook_script(hook["name"])
                                        end
                                        res = hook_function_backup(...)
                                        if(hook["execution"] == "post") then
                                                exec_hook_script(hook["name"])
                                        end
                                        return res
                                end
                        LC.log.print(LC.log.INFO,"Overwriting lua function " .. hook["lua_module"].."."..hook["lua_function"])
                        LC[hook["lua_module"]][hook["lua_function"]] = new_function
                end
        end

end

return system_hooks

#!/usr/bin/env lua

local LC                = LC
local system_hooks      = {}

local hook_directory    = "/usr/share/liveconfig/hooks"
local hooks_config_file = "/etc/liveconfig/hooks.conf"
local hooks_config_dir  = "/etc/liveconfig/hooks.conf.d"

local function file_exists(filename)
   local f=io.open(filename,"r")
   if f~=nil then io.close(f) return true end
end

local function dir_exists(dirname) 
	res = os.execute("test -d '"..dirname.."'")
	if(res==0) then return true end
end

function normalize_dirname(dirname) 

	--[[ 

	"./" 		-> ""
	"../dirname" 	-> "" (from left)
	"//" 		-> "/"

	]]--
	repeat
		dirname_old=dirname
		dirname = dirname:gsub("^%./","")
		dirname = dirname:gsub("([^%.])%./","%1")
		dirname = dirname:gsub(".%./[^/]+","")
		dirname = dirname:gsub("//","/")
	until dirname_old == dirname
	return dirname

end

function mkdir(dirname)
	if(dirname) then
		if(dir_exists(dirname)) then
			return true
		end
		dir_parts={}
		if(not dirname:match("^/")) then
			dirname = os.getenv("PWD").."/"..dirname
		end
		dirname=normalize_dirname(dirname)
		dirname:gsub("([^/]+)",function(part) dir_parts[#dir_parts+1]=part end)
	else
		return
	end
	whole_dir=""
	for i,part in ipairs(dir_parts) do
		whole_dir = whole_dir .. "/" .. part
		if(not dir_exists(whole_dir)) then
			os.execute(whole_dir)
		end
	end
end

local defined_hooks = {}

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

function get_command_output_handle(command)
	handle,err = io.popen(command,"r")
	if(handle) then 
		return handle
	end
end

function get_files(dir)
	
	local files={}
	local handle = get_command_output_handle("find "..dir.." -maxdepth 1 -type f")
	for line in handle:lines() do
		files[#files+1]=line
	end
	handle:close()
	return files
end

local function get_hook_files()

	local hook_files = {"/etc/liveconfig/hooks.conf"}
	if not dir_exists(hooks_config_dir) then
		mkdir(hooks_config_dir)
	else
		for _,filename in ipairs(get_files(hooks_config_dir)) do
        		LC.log.print(LC.log.INFO,"got filename >>"..filename.."<<")
			if(filename:match("conf$")) then
				hook_files[#hook_files+1]=filename
			end
		
		end
	end
	return hook_files
end

local function load_hooks_from_file()

	for _,hook_file in ipairs(get_hook_files()) do
        	LC.log.print(LC.log.INFO,"processing hooks file >>"..hook_file.."<<")
		if(file_exists(hook_file)) then
			datafile = io.open(hook_file,"r")
			for line in datafile:lines() do
				if(not (line:match("^#") or line:match("^%s*$"))) then
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
			datafile:close()
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
		else
			LC.log.print(LC.log.WARNING,"Wanted function " .. wanted_func.." missing within module " ..wanted_mod)
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

        LC.log.print(LC.log.INFO,"Loading hooks...")
        load_hooks_from_file()
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

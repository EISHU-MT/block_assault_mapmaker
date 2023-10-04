--[[
	Map Maker for BlockAssault
--]]
MapMaker = {
	PlayerSelectedTeamSelector = {},
	PlayerTeams = {},
	modpath = minetest.get_modpath(minetest.get_current_modname()),
	DelayToRunAutoSaver = 1, -- Seconds.
}

maps = {}

CallBacks = {
	OnExportMap = {}
}
CallBacks["register_OnExportMap"] = function(function_to_run) table.insert(CallBacks.register_OnExportMap, function_to_run) end

local storage = minetest.get_mod_storage()

MapMaker.storage = storage

do
	uncompress = core.deserialize
	compress = core.serialize
end

local new = {
	mapname = "name_this_new_map",
	mapauthor = nil,
	maptitle = "name this map",
	barrier_r = 110,
	barrier_rot = 0,
	center = { x = 0, y = 0, z = 0, r = 115, h = 140 },
	physics = {jump = 1, speed = 1, gravity = 1},
}

local c_ind_stone = minetest.get_content_id("bas:wall_block")
local c_ind_glass = minetest.get_content_id("bas:ceiling_block")
local c_ignore = minetest.get_content_id("air")
local c_stone = minetest.get_content_id("default:stone")
local c_water = minetest.get_content_id("default:water_source")
local c_air = minetest.get_content_id("air")

local context = {
	mapname = storage:get_string("mapname"),
	maptitle = storage:get_string("maptitle"),
	mapauthor = storage:get_string("mapauthor"),
	mapinitial = storage:get_string("mapinitial"),
	center = storage:get_string("center"),
	barrier_r = storage:get_int("barrier_r"),
	barrier_rot = storage:get_string("barrier_rot"),
	barriers_placed = storage:get_int("barriers_placed") == 1,
	physics = storage:get_string("physics")
}

function GetContext()
	return context
end

if context.mapname == "" then
	context.mapname = new.mapname
end
if context.mapauthor == "" then
	context.mapauthor = new.mapauthor
end
if context.maptitle == "" then
	context.maptitle = new.maptitle
end
if context.barrier_r == 0 then
	context.barrier_r = new.barrier_r
end
if context.center == "" then
	context.center = new.center
else
	context.center = uncompress(storage:get_string("center")) or { x = 0, y = 0, z = 0, r = 115, h = 140 }
end
if context.physics == "" then
	context.physics = new.physics
else
	context.physics = uncompress(storage:get_string("physics")) or {jump = 1, speed = 1, gravity = 1}
end

-- Tools for map making
minetest.register_tool(":AdminPick", {
	description = "Map Maker Pickaxe\nUsed for destroying BA.S nodes or indestructible nodes.",
	inventory_image = "default_tool_diamondpick.png",
	range = 16,
	tool_capabilities = {
		full_punch_interval = 1.0,
		max_drop_level = 3,
		groupcaps = {
			immortal = {times = {[1] = 0.5}, uses = 0, maxlevel = 3}
		},
		damage_groups = {fleshy = 1}
	}
})

-- Teams node
for _, team in pairs({"red", "blue", "green", "yellow"}) do
	minetest.register_node("map_engine:"..team, {
		description = "Terrorist block",
		paramtype = "light",
		walkable = false,
		tiles = {team.."_team.png"},
		groups = {oddly_breakable_by_hand=1,snappy=3},
		after_place_node = function(pos, player)
			MapMaker.PlayerSelectedTeamSelector[Name(player)] = table.copy(pos)
			core.show_formspec(Name(player), "MapMaker:SelectTeam", ReturnFormspecTeamEditing(player, pos))
		end,
		on_destruct = function(pos)
			MapMaker.PlayerTeams[core.pos_to_string(pos)] = nil
		end,
		on_rightclick = function(pos, node, player, itemstack, pointed_thing)
			MapMaker.PlayerSelectedTeamSelector[Name(player)] = table.copy(pos)
			core.show_formspec(Name(player), "MapMaker:SelectTeam", ReturnFormspecTeamEditing(player, pos))
		end,
	})
end

-- Disaster will begun from here.

function is_real_pos(pos)
	return type(pos) == "table" and type(pos.x) == "number" and type(pos.y) == "number" and type(pos.z) == "number"
end

local function to_2pos()
	return {
		x = context.center.x - context.center.r,
		y = context.center.y - context.center.h / 2,
		z = context.center.z - context.center.r,
	}, {
		x = context.center.x + context.center.r,
		y = context.center.y + context.center.h / 2,
		z = context.center.z + context.center.r,
	}
end

function place_barriers(name)
	show_progress_formspec(name, "Emerging area...")
	local pos1, pos2 = to_2pos()
	maps.emerge_with_callbacks(name, pos1, pos2, function()
		show_progress_formspec(name, "Placing center barrier, this may take a while...")
		minetest.after(0.1, function()
			show_progress_formspec(name, "Placing outer barriers, this may take a while...")
			minetest.after(0.1, function()
				place_outer_barrier(context.center, context.barrier_r, context.center.h)
				show_gui(name)
			end)
		end)
	end, emerge_progress)
	return true
end

function emerge(name)
	local pos1, pos2 = to_2pos()
	show_progress_formspec(name, "Emerging area...")
	maps.emerge_with_callbacks(name, pos1, pos2, function()
		show_gui(name)
	end, emerge_progress)
	return true
end

function we_select(name)
	local pos1, pos2 = to_2pos()
	worldedit.pos1[name] = pos1
	worldedit.mark_pos1(name)
	worldedit.player_notify(name, "position 1 set to " .. minetest.pos_to_string(pos1))
	worldedit.pos2[name] = pos2
	worldedit.mark_pos2(name)
	worldedit.player_notify(name, "position 2 set to " .. minetest.pos_to_string(pos2))
end

local max = math.max

function we_import(name)
	local pos1 = worldedit.pos1[name]
	local pos2 = worldedit.pos2[name]
	if pos1 and pos2 then
		local size = vector.subtract(pos2, pos1)
		local r = max(size.x, size.z) / 2
		context.center = vector.divide(vector.add(pos1, pos2), 2)
		context.center.r = r
		context.center.h = size.y
		storage:set_string("center", compress(context.center))
	end
end

function set_center(name, center)
	if center then
		for k, v in pairs(center) do
			context.center[k] = v
		end
	else
		local r   = context.center.r
		local h   = context.center.h
		local pos = minetest.get_player_by_name(name):get_pos()
		context.center = vector.floor(pos)
		context.center.r = r
		context.center.h = h
	end
	storage:set_string("center", compress(context.center))
end

local function get_barrier_node(c_id)
	return c_ind_stone
end

function set_meta(k, v)
	if v ~= context[k] then
		context[k] = v
		if type(v) == "number" then
			storage:set_int(k, v)
		else
			storage:set_string(k, v)
		end
	end
end

function place_outer_barrier(center, r, h)
	local minp = vector.subtract(center, r)
	local maxp = vector.add(center, r)
	minp.y = center.y - h / 2
	maxp.y = center.y + h / 2
	minetest.log("action", "Map maker: Loading data into LVM")
	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(minp, maxp)
	local a = VoxelArea:new{
		MinEdge = emin,
		MaxEdge = emax
	}
	local data = vm:get_data()
	-- Left
	minetest.log("action", "Map maker: Placing left wall")
	do
		local x = center.x - r
		for z = minp.z, maxp.z do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				data[vi] = get_barrier_node(data[vi])
			end
		end
	end
	-- Right
	minetest.log("action", "Map maker: Placing right wall")
	do
		local x = center.x + r
		for z = minp.z, maxp.z do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				data[vi] = get_barrier_node(data[vi])
			end
		end
	end
	-- Front
	minetest.log("action", "Map maker: Placing front wall")
	do
		local z = center.z - r
		for x = minp.x, maxp.x do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				data[vi] = get_barrier_node(data[vi])
			end
		end
	end
	-- Back
	minetest.log("action", "Map maker: Placing back wall")
	do
		local z = center.z + r
		for x = minp.x, maxp.x do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				data[vi] = get_barrier_node(data[vi])
			end
		end
	end
	-- Bedrock
	minetest.log("action", "Map maker: Placing bedrock")
	do
		local y = minp.y
		for x = minp.x, maxp.x do
			for z = minp.z, maxp.z do
				data[a:index(x, y, z)] = c_ind_stone
			end
		end
	end
	-- Ceiling
	minetest.log("action", "Map maker: Placing ceiling")
	do
		local y = maxp.y
		for x = minp.x, maxp.x do
			for z = minp.z, maxp.z do
				data[a:index(x, y, z)] = c_ind_glass
			end
		end
	end
	minetest.log("action", "Map maker: Writing to engine!")
	vm:set_data(data)
	vm:write_to_map(data)
	vm:update_map()
end



local function check_teams_before_save(name)
	local verified_teams = {
		red = false,
		blue = false,
		yellow = false,
		green = false,
	}
	for team, pos in pairs(MapMaker.PlayerTeams) do
		if verified_teams[team] == false then
			verified_teams[team] = true
		else
			core.log("error", "[MapMaker] Found unknown team '"..team.."' while checking teams.")
		end
	end
	
	if verified_teams.red and verified_teams.blue and verified_teams.green and verified_teams.yellow then -- 4 teams
		return true
	elseif verified_teams.red and verified_teams.blue and (not verified_teams.green) and (not verified_teams.yellow) then -- 2 teams
		return true
	else
		if name then
			SendError(name, "Cant find teams to process!. Check all teams again!")
		end
		return false
	end
	return false
end

function GetTeamsStatus()
	local bool = check_teams_before_save()
	if bool then
		return "Ready!"
	else
		return "Fix teams!"
	end
	return "--"
end

function export(name)
	SendAnnouce(name, "Exporting map! This may take a while")
	if not check_teams_before_save(name) then
		SendError(name, "Failed to export map!, some teams inst configured!")
		return
	end
	
	
	we_select(name)
	show_progress_formspec(name, "Exporting...")

	local path = minetest.get_worldpath() .. "/schems/" .. context.mapname .. "/"
	minetest.mkdir(path)
	local init_file, r = io.open(path.."init.lua", "w")
	local conf, r = io.open(path.."mod.conf", "w")
	if not init_file then
		error("Could not create initial file for map! Reason: "..tostring(r))
	end
	
	local meta = Settings(path .. "map.cfg")
	
	-- Run Callbacks before save
	local res = RunCallbacks(CallBacks.OnExportMap, meta)
	
	if res == false then
		SendError(name, "Something failed!")
		return
	end

	-- Reset mod_storage
	storage:set_string("center", "")
	storage:set_string("maptitle", "")
	storage:set_string("mapauthor", "")
	storage:set_string("mapname", "")
	storage:set_string("mapinitial", "")
	storage:set_string("barrier_rot", "")
	storage:set_string("barrier_r", "")
	
	-- Add initial files
	local function w(str) init_file:write("\n"..str) end
	init_file:write("--[[\n")
	init_file:write("\n	This inst a traditional mod!, This is a map for BlockAssault Game")
	init_file:write("\n	Dont modify this until you know what you doing.")
	init_file:write("\n	BAM.S. (BlockAssaultMapmaker . System)")
	init_file:write("\n--]]")
	w("local modpath = core.get_modpath(core.get_current_modname())")
	w("maps.register_map(\""..context.mapname.."\", {")
	w("	name = \""..context.maptitle.."\",")
	w("	dirname = modpath,")
	w("})")
	w("--- END OF GEN. FILE ---")
	init_file:close()
	
	conf:write("name = "..context.mapname)
	conf:write("\ndepends = bs_maps, bs_core")
	conf:close()
	
	SendWarning(name, "NOTE: If theres any mod that provides decorations (Nodes) to this game and its used in this map, modify 'mod.conf' file and add in 'depends' your mod names (need to be technical names).")
	SendWarning(name, "Before changing the 'depends' field, dont remove 'bs_maps' and 'bs_core' because they are need to work this map.")
	
	
	meta:set("name", context.maptitle)
	meta:set("author", context.mapauthor)
	if context.mapinitial ~= "" then
		meta:set("initial_stuff", context.mapinitial)
	end
	meta:set("rotation", context.barrier_rot)
	meta:set("r", context.center.r)
	meta:set("h", context.center.h)
	
	
	
	for team_name, pos in pairs(MapMaker.PlayerTeams) do
		if team_name and pos then
			core.set_node(pos, {name="air"})
			
			pos = vector.subtract(pos, context.center)
			meta:set("team." .. team_name, minetest.pos_to_string(pos))
		end
	end
	
	meta:set("physics", storage:get_string("physics"))
	meta:write()

	minetest.after(0.1, function()
		local filepath = path .. "core.mts"
		if minetest.create_schematic(worldedit.pos1[name], worldedit.pos2[name], worldedit.prob_list[name], filepath) then
			SendAnnouce(name, "Exported map successfully!")
			minetest.close_formspec(name, "")
		else
			SendError(name, "Something bad happened :/")
			show_gui(name)
		end
	end)
	SendWarning(name, "To avoid any errors in the future, please remove this world!")
	return
end

dofile(MapMaker.modpath.."/formspecs.lua")
dofile(MapMaker.modpath.."/autosaver.lua")
dofile(MapMaker.modpath.."/helpers.lua")














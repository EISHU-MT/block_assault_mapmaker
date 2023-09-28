local delay = 0
local function auto_save(dtime)
	delay = delay + dtime
	if delay >= MapMaker.DelayToRunAutoSaver then
		--for _, p in pairs(core.get_connected_players()) do
		--	SendAnnouce(p, "Autosaving progress 'MapMaker Data'")
		--end
		
		local map_maker = table.copy(MapMaker)
		map_maker.storage = nil
		
		local data = core.serialize(map_maker)
		MapMaker.storage:set_string("map_maker_data", data)
		delay = 0
	end
end

core.register_on_mods_loaded(function()
	local data = MapMaker.storage:get_string("map_maker_data")
	local data_table = core.deserialize(data)
	
	local storage
	if MapMaker.storage then
		storage = MapMaker.storage
	end
	
	if data ~= "" or data ~= " " and data_table then
		MapMaker = data_table
		MapMaker.storage = storage or minetest.get_mod_storage()
	end
end)

core.register_globalstep(auto_save)
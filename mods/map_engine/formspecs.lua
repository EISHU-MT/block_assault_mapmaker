local function GetTeamByIndex(index)
	if index == "Red" then
		return "red"
	elseif index == "Blue" then
		return "blue"
	elseif index == "Green" then
		return "green"
	elseif index == "Yellow" then
		return "yellow"
	end
end
local function GetIndexByTeam(index)
	if index == "red" then
		return 1
	elseif index == "blue" then
		return 2
	elseif index == "green" then
		return 3
	elseif index == "yellow" then
		return 4
	end
end

function GetTeamByPos(pos)
	for team_name, tpos in pairs(MapMaker.PlayerTeams) do
		if vector.equals(tpos, pos) then
			return team_name, tpos
		end
	end
	return "", vector.new()
end

function ReturnFormspecTeamEditing(player, pos)
	if GetTeamByPos(pos) and GetTeamByPos(pos) ~= "" then
		local index_to_return = GetIndexByTeam(GetTeamByPos(pos))
		if index_to_return then
			local form = "formspec_version[6]" ..
			"size[6,4]" ..
			"box[0,0;6,0.5;#00FF00]" ..
			"label[2,0.2;Team Selector]" ..
			"label[0.3,1.1;Actual Team: "..GetTeamByPos(pos).."]" ..
			"dropdown[0.2,1.5;5.6,1;;Red,Blue,Green,Yellow;"..tostring(index_to_return)..";false]" ..
			"button_exit[0.2,2.9;5.6,0.9;select;Select & Exit]"
			return form
		else
			core.log("error", "No Index found for \"team\". this maybe is a bug.")
		end
	else
		local form = "formspec_version[6]" ..
		"size[6,4]" ..
		"box[0,0;6,0.5;#00FF00]" ..
		"label[2,0.2;Team Selector]" ..
		"label[0.3,1.1;Actual Team: Select a team for here!]" ..
		"dropdown[0.2,1.5;5.6,1;team;Red,Blue,Green,Yellow;1;false]" ..
		"button_exit[0.2,2.9;5.6,0.9;select;Select & Exit]"
		return form
	end
end

function show_progress_formspec(name, text)
	minetest.show_formspec(name, "map_maker:progress",
		"size[6,1]bgcolor[#080808BB;true]" ..
		default.gui_bg ..
		default.gui_bg_img .. "label[0,0;" ..
		minetest.formspec_escape(text) .. "]")
end

function emerge_progress(ctx)
	show_progress_formspec(ctx.name,
		string.format("Emerging Area - %d/%d blocks emerged (%.1f%%)",
		ctx.current_blocks, ctx.total_blocks,
		(ctx.current_blocks / ctx.total_blocks) * 100))
end

function show_gui(name)
	local context = GetContext()
	local mapauthor = context.mapauthor or name
	
	local formspec = 
		"formspec_version[6]" ..
		"size[18,11]" ..
		"box[0,0.7;6.6,5.4;#54E616]" ..
		"box[0,0;18.1,0.7;#FF4E4E]" ..
		"label[0.1,0.3;BA.S MapMaker]" ..
		"field[0.2,1.5;2.8,0.8;posx;X;"..context.center.x.."]" ..
		"field[0.2,2.8;2.8,0.8;posy;Y;"..context.center.y.."]" ..
		"field[0.2,4.1;2.8,0.8;posz;Z;"..context.center.z.."]" ..
		"label[1,1;1. Coordinates / Area for map]" ..
		"button[3.3,1.5;3.1,1.1;set_center;Set Coords\nAs player pos]" ..
		"button[3.3,4.3;1.5,0.6;towe;To WE]" ..
		"button[4.9,4.3;1.5,0.6;fromwe;From WE]" ..
		"button[0.2,5.1;6.2,0.8;emerge;Emerge Area]" ..
		"box[6.6,3.6;5.9,2.5;#FFE500]" ..
		"label[7.2,4;3. Positions for each team]" ..
		"label[6.7,4.6;Status: ]" ..
		"label[8.1,4.6;"..GetTeamsStatus().."]" ..
		"button[6.8,5.1;5.5,0.8;giveme;Give 2 nodes for each team]" ..
		"box[6.6,0.7;5.9,2.9;#C4FF00]" ..
		"field[6.8,1.4;2.7,0.7;barrier_r;R / Rad;"..context.barrier_r.."]" ..
		"dropdown[9.6,1.4;2.7,0.7;barrier_rot;X=0,Z=0;"..(context.barrier_rot == "x" and 1 or 2)..";false]" ..
		"label[8.2,1;2. Place Barriers]" ..
		"button[6.8,2.7;5.5,0.7;place_barriers;Place Barriers]" ..
		"label[7.6,2.4;This maybe take a while]" ..
		"box[0,6.1;18,4.9;#FF9D00]" ..
		"label[0.2,6.5;5. MetaData / Data for the map]" ..
		"field[5.3,7.5;6.1,0.6;title;Title;"..minetest.formspec_escape(context.maptitle).."]" ..
		"field[5.3,8.5;6.1,0.6;name;Technical Name for map;"..minetest.formspec_escape(context.mapname).."]" ..
		"field[11.6,7.5;6.2,0.6;author;Author (Can be multiple names or a group name);"..minetest.formspec_escape(mapauthor).."]" ..
		"button[5.3,10.2;6.1,0.7;close;Close / Countinue making map]" ..
		"button[5.3,9.3;6.1,0.7;export;Export]" ..
		"box[12.5,0.7;5.5,5.4;#FF3100]" ..
		"label[14.6,2.1;Areas]" ..
		"field[3.3,2.9;3.1,0.5;posr;R;"..tostring(context.center.r).."]" ..
		"field[3.3,3.7;3.1,0.5;posh;H;"..tostring(context.center.h).."]" ..
		"box[11.6,8.3;6.2,2.5;#00A5FF]" ..
		"label[13.4,8.5;Physics (Optional)]" ..
		"field[11.8,9.1;2.7,0.7;jump;Jump;"..tostring(context.physics.jump).."]" ..
		"field[14.6,9.1;3,0.7;speed;Speed;"..tostring(context.physics.speed).."]" ..
		"field[11.8,10.1;2.7,0.6;gravity;Gravity;"..tostring(context.physics.gravity).."]" ..
		"button[14.6,9.9;3,0.8;save;Save Physics]"
		
	minetest.show_formspec(name, "MapMaker:main", formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = Name(player)
	local pname = Name(player)
	if formname == "MapMaker:SelectTeam" then
		if fields.select then
			
			local team_string = GetTeamByIndex(fields.team)
			
			if MapMaker.PlayerTeams[team_string] then
				core.set_node(MapMaker.PlayerTeams[team_string], {name="air"})
				SendWarning(player, "The team '"..team_string.."' pos is being replaced with '"..core.pos_to_string(MapMaker.PlayerSelectedTeamSelector[name]).."'")
				MapMaker.PlayerTeams[team_string] = MapMaker.PlayerSelectedTeamSelector[name]
			else
				MapMaker.PlayerTeams[team_string] = MapMaker.PlayerSelectedTeamSelector[name]
			end
			
			core.set_node(MapMaker.PlayerSelectedTeamSelector[Name(player)], {name="map_engine:"..team_string})
		elseif fields.team then
			SendAnnouce(player, "You selected \""..fields.team.."\"")
		end
	elseif formname == "MapMaker:main" then
		if fields.posx or fields.posy or fields.posz or fields.posh or fields.posr then
			set_center(name, {
				x = tonumber(fields.posx),
				y = tonumber(fields.posy),
				z = tonumber(fields.posz),
				h = tonumber(fields.posh),
				r = tonumber(fields.posr)
			})
		end
		if fields.barrier_r then
			set_meta("barrier_r", tonumber(fields.barrier_r))
		end
		if fields.title then
			set_meta("maptitle", fields.title)
		end
		if fields.author then
			set_meta("mapauthor", fields.author)
		end
		if fields.name then
			set_meta("mapname", fields.name)
		end
		if fields.initial then
			set_meta("mapinitial", fields.initial)
		end
		if fields.barrier_rot then
			set_meta("barrier_rot", fields.barrier_rot == "X=0" and "x" or "z")
		end
		if fields.set_center then
			set_center(name)
		end
		if fields.giveme then
			player:get_inventory():add_item("main", "map_engine:red")
		end
		if fields.emerge then
			emerge(name)
		end
		if fields.place_barriers then
			place_barriers(name)
		end
		if fields.towe then
			we_select(name)
		end

		if fields.fromwe then
			we_import(name)
		end
		if fields.save then
			local tabled = {
				jump = tonumber(fields.jump) or 1,
				speed = tonumber(fields.speed) or 1,
				gravity = tonumber(fields.gravity) or 1,
			}
			local src = core.serialize(tabled)
			set_meta("physics", src)
		end
		if fields.a_bomb then
			error("Unsupported: bomb area: adding")
		end
		if fields.b_bomb then
			error("Unsupported: bomb area: adding")
		end
		if fields.export then
			export(name)
		end
		if not fields.quit then
			show_gui(name)
		end
	end
end)


minetest.register_chatcommand("gui", {
	func = function(name)
		show_gui(name)
		return true
	end
})







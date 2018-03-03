-- OLD PLAYER : keep only serious players data on server
--(c) 2015-2016 rnd

oldplayer = {}

-- SETTINGS 

oldplayer.requirement = {"default:dirt 1", "default:steel_ingot 1"};
oldplayer.welcome = "*** IMPORTANT *** please have at least 1 dirt and 1 steel ingot in your inventory when leaving to register as serious player. If not, your player data will be deleted.";

-- END OF SETTINGS 


oldplayer.players = {};
local worldpath = minetest.get_worldpath();


minetest.register_on_joinplayer(function(player) 
	local name = player:get_player_name(); if name == nil then return end 
	
	-- read player inventory data
	local inv = player:get_inventory();
	local isoldplayer = inv:get_stack("oldplayer", 1):get_count();
	inv:set_size("oldplayer", 2);
	local ip = minetest.get_player_ip(name); if not ip then return end
	inv:set_stack("oldplayer", 2, ItemStack("IP".. ip)) -- string.gsub(ip,".","_")));
	
	if isoldplayer > 0 then
		oldplayer.players[name] = 1
		minetest.chat_send_player(name, "#OLDPLAYER: welcome back");
	else
		local privs = minetest.get_player_privs(name);
		if privs.kick then
			inv:set_stack("oldplayer", 1, ItemStack("oldplayer"));
			minetest.chat_send_player(name, "#OLDPLAYER: welcome moderator. setting as old player.");
			oldplayer.players[name] = 1
		else
			oldplayer.players[name] = 0
			local form = "size [6,2] textarea[0,0;6.6,3.5;help;OLDPLAYER WELCOME;".. oldplayer.welcome.."]"
			minetest.show_formspec(name, "oldplayer:welcome", form)
	--		minetest.chat_send_player(name, oldplayer.welcome);
		end
	end
	
	
end)

minetest.register_on_leaveplayer(function(player, timed_out)
	local name = player:get_player_name(); if name == nil then return end
	if oldplayer.players[name] == 1 then return end -- already old, do nothing

	local delete = false; -- should we delete player?
	
	-- read player inventory data
	local inv = player:get_inventory();

	-- does player have all the required items in inventory?
	for _,item in pairs(oldplayer.requirement) do
		if not inv:contains_item("main", item)	then 
			delete = true
		end
	end
	
	if not delete then -- set up oldplayer inventory so we know player is old next time
		inv:set_size("oldplayer", 2);
		inv:set_stack("oldplayer", 1, ItemStack("oldplayer"));
	else -- delete player profile
		minetest.remove_player(name)
		minetest.remove_player_auth(name)
	end
end)

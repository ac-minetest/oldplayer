-- OLD PLAYER : keep only serious players data on server
--(c) 2015-2016 rnd

local oldplayer = {}

-- SETTINGS 

oldplayer.requirement = {"default:dirt 1", "default:iron_lump 9"};
oldplayer.welcome = "*** IMPORTANT *** please have at least 1 dirt and 9 iron ore in your inventory when leaving to register as serious player. If not, your player data will be deleted.";

-- END OF SETTINGS 


oldplayer.players = {};
local worldpath = minetest.get_worldpath();

minetest.register_on_joinplayer(function(player) 
	local name = player:get_player_name(); if name == nil then return end 
	
	-- read player inventory data
	local inv = player:get_inventory();
	local isoldplayer = inv:get_stack("oldplayer", 1):get_count();
	if isoldplayer > 0 then
		oldplayer.players[name] = 1
	else
		oldplayer.players[name] = 0
		minetest.chat_send_player(name, oldplayer.welcome);
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
		inv:set_size("oldplayer", 1);
		inv:set_stack("oldplayer", 1, ItemStack("oldplayer"));
	else -- delete player profile
		
		local filename = worldpath .. "\\players\\" .. name;
		
		-- PROBLEM: deleting doesnt always work? seems minetest itself is saving stuff.
		-- so we wait a little and then delete
		minetest.after(10,function() 
			print("[oldplayer] removing player filename " .. filename)
			local err,msg = os.remove(filename) 
			if err==nil then 
				print ("[oldplayer] error removing player data " .. filename .. " error message: " .. msg) 
			end
			
			-- TO DO: how to remove players from auth.txt easily without editing file manually like below
			
			print("[oldplayer] removing player ".. name .." data from auth.txt")
			local f = io.open(worldpath.."\\auth.txt", "r");
			local s = f:read("*a");
			local p1,p2;
			p1 = string.find(s,"\n"..name..":"); -- careful: we need to get full name not just part so include newline char too
			if p1 then
				p1=p1+1; -- skip previous newline
				p2 = string.find(s,"\n",p1);
			end
			if p1 and p2 then
				f:close();
				f = io.open(worldpath.."\\auth.txt", "w");
				f:write(string.sub(s,1,p1-1)..string.sub(s,p2+1)); -- write back everything but player data
				f:close();
				return
			end

			f:close();
		end);

	end
		
end
)

-- "FUN STUFF", might be useful

-- STUPID DESIGN: writing path as "xxx\bin\..\worlds\xxx", have to waste time fixing that?
		-- local filename = "";
		-- local p1,p2 = string.find(worldpath,"\\bin\\..");
		-- if false then --p1 then 
			-- print("changing path");
			-- filename = string.sub(worldpath,1,p1-1)..string.sub(worldpath,p2+1).. "\\players\\" .. name;
			-- else filename = worldpath .. "\\players\\" .. name;
		-- end
		-- print("filename " .. filename );
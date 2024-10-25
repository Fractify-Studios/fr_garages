Config = {}

Config.Language = {
	["takeout"] = "Take out vehicle",
	["takeoutnotify"] = "Vehicle successfully taked out",
	["cantpark"] = "You cannot park this vehicle there",
	["tip"] = "Pull into an available parking space and press [E]",
	["keymapping"] = "Park vehicle",
}

-- How should interaction work, default is ox_target but you can rewrite it to your interaction system
-- !! IMPORTANT !!
-- Do not forgot about canInteract section, because without it players they will be able to take out other player's vehicles

Config.RegisterInteraction = function()
	exports.ox_target:addGlobalVehicle({
		label = Config.Language["takeout"],
		canInteract = function(entity)
			-- Don't forget about this
			if
				exports["fr_garages"]:inZone()
				and lib.callback.await("fr_garages:isPlayerOwner", false, GetVehicleNumberPlateText(entity))
				and lib.callback.await("fr_garages:isCarParked", false, GetVehicleNumberPlateText(entity))
			then
				return true
			else
				return false
			end
		end,
		onSelect = function(data)
			if exports["fr_garages"]:TakeOutVehicle(GetVehicleNumberPlateText(data.entity)) then
				ESX.ShowNotification(Config.Language["takeoutnotify"], "success", 3000)
			end
		end,
	})
end

Config.Parkings = {
	["main"] = {
		-- They should be on the same Z coord
		border = {
			vec3(94.2682, -1081.7063, 29),
			vec3(110.8320, -1046.1010, 29),
			vec3(151.0564, -1062.2646, 29),
			vec3(149.5050, -1086.9866, 29),
		},
		-- The height of the polyhon
		thickness = 5,
		-- Big ass red block (debug mode)
		debug = false,
		-- Parking Slots
		slots = {
			vec4(147.1915, -1081.5627, 29.1924, 179.5708),
			vec4(143.6143, -1081.1989, 29.1924, 180.8258),
			vec4(139.5879, -1080.6073, 29.1925, 185.6599),
		},
	},
}

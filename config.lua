Config = {}

Config.Language = {
	vehicle_takeout = "Take out vehicle",
	vehicle_takeout_notify = "Vehicle successfully taken out",
	vehicle_cannot_park = "You cannot park this vehicle there",
	parking_tip = "Pull into an available parking space and press [E]",
	keymapping_park_vehicle = "Park vehicle",
	garage_blip = "Garage",
}

Config.Parkings = {
	main = {
		blip_location = vec3(147.1915, -1081.5627, 29.1924),
		parking_border = {
			vec3(94.2682, -1081.7063, 29),
			vec3(110.8320, -1046.1010, 29),
			vec3(151.0564, -1062.2646, 29),
			vec3(149.5050, -1086.9866, 29),
		},
		parking_thickness = 5, -- Height of the polygon
		parking_slots = {
			vec4(147.1915, -1081.5627, 29.1924, 179.5708),
			vec4(143.6143, -1081.1989, 29.1924, 180.8258),
			vec4(139.5879, -1080.6073, 29.1925, 185.6599),
		},
		jobs = { "police" }, -- List of jobs that may use the garage. Remove this line if it should be available to everyone.
		debug = false,
	},
}

Config.Blip = {
	sprite = 357,
	colour = 5,
	scale = 1.0,
	display = 4,
	text = Config.Language.garage_blip,
}

-- [!] Important
-- Ensure you handle the canInteract section properly,
-- as failing to do so will allow players to take out other players' vehicles.
Config.RegisterInteraction = function()
	exports.ox_target:addGlobalVehicle({
		label = Config.Language.vehicle_takeout,
		canInteract = function(entity)
			if
				exports["fr_garages"]:InZone()
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
				ESX.ShowNotification(Config.Language.vehicle_takeout_notify, "success", 3000)
			end
		end,
	})
end

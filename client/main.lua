Citizen.CreateThread(Config.RegisterInteraction)

InZone = false
CurrentParking = nil
SpawnedCars = {}
SpawnedCarsByPlate = {}
CanPark = false
Slot = nil

exports("InZone", function()
	return InZone
end)

exports("CurrentParking", function()
	return CurrentParking
end)

function EnterParking(parking)
	local vehicles = lib.callback.await("fr_garages:getVehicles", false, parking)
	local tb = {}

	for i, v in pairs(Config.Parkings[parking].parking_slots) do
		tb[i] = { coords = v, data = nil, localId = nil }
	end

	SpawnedCars[parking] = tb

	for _, v in pairs(vehicles) do
		RequestModel(v.model)

		while not HasModelLoaded(v.model) do
			Wait(0)
		end

		local vehicle = CreateVehicle(
			v.model,
			SpawnedCars[parking][v.slot].coords.x,
			SpawnedCars[parking][v.slot].coords.y,
			SpawnedCars[parking][v.slot].coords.z,
			SpawnedCars[parking][v.slot].coords.w,
			false,
			false
		)

		SetModelAsNoLongerNeeded(v.model)

		ESX.Game.SetVehicleProperties(vehicle, json.decode(v.properties))

		FreezeEntityPosition(vehicle, true)
		SetVehicleDoorsLocked(vehicle, 2)

		SpawnedCars[parking][v.slot] = { SpawnedCars[parking][v.slot].coords, data = v, localId = vehicle }
		SpawnedCarsByPlate[v.plate] = vehicle

		Wait(500)
	end
end

function LeaveParking(parking)
	local tb = {}

	for i, v in pairs(Config.Parkings[parking].parking_slots) do
		tb[i] = { coords = v, data = nil, localId = nil }
	end

	for _, v in pairs(SpawnedCars[parking]) do
		if v.localId then
			DeleteEntity(v.localId)
		end
	end

	SpawnedCars[parking] = tb
end

Citizen.CreateThread(function()
	for parkingName, parking in pairs(Config.Parkings) do
		local blip = AddBlipForCoord(parking.blip_location.x, parking.blip_location.y, parking.blip_location.z)
		SetBlipSprite(blip, Config.Blip.sprite)
		SetBlipDisplay(blip, Config.Blip.display)
		SetBlipScale(blip, Config.Blip.scale)
		SetBlipColour(blip, Config.Blip.colour)
		SetBlipAsShortRange(blip, true)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(Config.Blip.text)
		EndTextCommandSetBlipName(blip)

		lib.zones.poly({
			points = parking.parking_border,
			thickness = parking.parking_thickness,
			onEnter = function()
				InZone = true
				CurrentParking = parkingName
				EnterParking(parkingName)

				lib.showTextUI(Config.Language.parking_tip, {
					position = "top-center",
				})
			end,
			onExit = function()
				InZone = false
				CurrentParking = nil

				lib.hideTextUI()

				LeaveParking(parkingName)
			end,
			inside = function()
				for _slot, v in pairs(SpawnedCars[CurrentParking]) do
					if v.localId then
						goto continue
					end

					if not IsPedInAnyVehicle(PlayerPedId()) then
						lib.hideTextUI()
						goto continue
					end

					if not v.coords then
						goto continue
					end

					if #(GetEntityCoords(PlayerPedId()) - vec3(v.coords.x, v.coords.y, v.coords.z)) < 3 then
						CanPark = true
						Slot = _slot
					end

					::continue::
				end

				Wait(1000)
			end,
			debug = parking.debug,
		})
	end
end)

function TakeOutVehicle(plate)
	if not lib.callback.await("fr_garages:isPlayerOwner", false, plate) then
		return false
	end

	TriggerServerEvent("fr_garages:takeOutVehicle", CurrentParking, plate)

	return true
end

exports("TakeOutVehicle", TakeOutVehicle)

RegisterNetEvent("fr_garages:RemoveVehicle", function(parking, plate)
	if CurrentParking ~= parking then
		return
	end

	DeleteEntity(SpawnedCarsByPlate[plate])

	for _slot, v in pairs(SpawnedCars[CurrentParking]) do
		if not v.data then
			return
		end

		if v.data.plate == plate then
			SpawnedCars[CurrentParking][_slot] = { coords = v.coords }
			break
		end
	end

	SpawnedCarsByPlate[plate] = nil
end)

RegisterNetEvent("fr_garages:tkVehicle", function(data)
	RequestModel(data.model)

	while not HasModelLoaded(data.model) do
		Wait(0)
	end

	local vehicle = CreateVehicle(data.model, data.coords.x, data.coords.y, data.coords.z, data.coords.w, true, false)

	SetModelAsNoLongerNeeded(data.model)

	ESX.Game.SetVehicleProperties(vehicle, json.decode(data.properties))
end)

function ParkVehicle()
	local playerPed = PlayerPedId()
	local vehicle = GetVehiclePedIsIn(playerPed, false)

	if not vehicle or not Slot then
		return false
	end

	if not lib.callback.await("fr_garages:isPlayerOwner", false, GetVehicleNumberPlateText(vehicle)) then
		ESX.ShowNotification(Config.Language.vehicle_cannot_park, "error", 3000)
		return false
	end

	if Config.Parkings[CurrentParking].jobs then
		if not ESX.PlayerData.job or not ESX.PlayerData.job.name then
			ESX.ShowNotification(Config.Language.vehicle_cannot_park, "error", 3000)
			return false
		end

		local allow = false
		for _, v in pairs(Config.Parkings[CurrentParking].jobs) do
			if v == ESX.PlayerData.job.name then
				allow = true
				break
			end
		end

		if not allow then
			ESX.ShowNotification(Config.Language.vehicle_cannot_park, "error", 3000)
			return false
		end
	end

	TaskLeaveVehicle(playerPed, vehicle, 0)

	Wait(2000)

	SetVehicleDoorsLocked(vehicle, 2)

	local properties = ESX.Game.GetVehicleProperties(vehicle)

	TriggerServerEvent(
		"fr_garages:parkVehicle",
		NetworkGetNetworkIdFromEntity(vehicle),
		GetVehicleNumberPlateText(vehicle),
		CurrentParking,
		Slot,
		properties
	)
end

exports("ParkVehicle", ParkVehicle)

RegisterCommand("+frpark", function()
	if not InZone or CurrentParking == nil or not IsPedInAnyVehicle(PlayerPedId(), false) then
		return
	end

	local canPark = false

	for _slot, v in pairs(Config.Parkings[CurrentParking].parking_slots) do
		if #(GetEntityCoords(PlayerPedId()) - vec3(v.x, v.y, v.z)) < 3 then
			canPark = true
			Slot = _slot
			break
		end
	end

	if not canPark then
		CanPark = false
		Slot = nil
	end

	ParkVehicle()
end, false)

RegisterKeyMapping("+frpark", Config.Language.keymapping_park_vehicle, "keyboard", "E")

RegisterNetEvent("fr_garages:vehicleParked", function(parking, slot, data)
	if parking ~= CurrentParking then
		return
	end

	RequestModel(data.model)

	while not HasModelLoaded(data.model) do
		Wait(0)
	end

	local vehicle = CreateVehicle(
		data.model,
		Config.Parkings[parking].parking_slots[slot].x,
		Config.Parkings[parking].parking_slots[slot].y,
		Config.Parkings[parking].parking_slots[slot].z,
		Config.Parkings[parking].parking_slots[slot].w,
		false,
		false
	)

	SetModelAsNoLongerNeeded(data.model)

	ESX.Game.SetVehicleProperties(vehicle, json.decode(data.properties))

	FreezeEntityPosition(vehicle, true)
	SetVehicleDoorsLocked(vehicle, 2)

	SpawnedCars[parking][slot] = { SpawnedCars[parking][slot].coords, data = data, localId = vehicle }
	SpawnedCarsByPlate[data.plate] = vehicle
end)
-- Givecar command

lib.callback.register("fr_garages:givecar", function(model)
	local coords = GetEntityCoords(PlayerPedId())
	local veh = nil
	ESX.Game.SpawnLocalVehicle(model, vector3(coords.x, coords.y, coords.z - 5), 100.0, function(vehicle)
		veh = vehicle
	end)

	while veh == nil do
		Wait(0)
	end

	local properties = ESX.Game.GetVehicleProperties(veh)

	DeleteEntity(veh)

	return properties
end)

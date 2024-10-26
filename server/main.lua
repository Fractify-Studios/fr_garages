function GetVehicles(parking)
	local result = MySQL.query.await(
		"SELECT owner, second_owner, plate, model, properties, slot FROM owned_vehicles WHERE parking = @parking",
		{
			["@parking"] = parking,
		}
	)

	return result
end

lib.callback.register("fr_garages:getVehicles", function(playerId, parking)
	return GetVehicles(parking)
end)

exports("GetVehicles", GetVehicles)

function IsPlayerOwner(playerId, plate)
	local xPlayer = ESX.GetPlayerFromId(source)

	local result = MySQL.single.await(
		"SELECT 1 FROM owned_vehicles WHERE (owner = @identifier OR second_owner = @indentifier) AND plate = @plate",
		{
			["@identifier"] = xPlayer.identifier,
			["@plate"] = plate,
		}
	)

	if not result then
		return false
	end

	return true
end

lib.callback.register("fr_garages:isPlayerOwner", IsPlayerOwner)

exports("IsPlayerOwner", IsPlayerOwner)

function IsCarParked(plate)
	local result = MySQL.single.await("SELECT 1 FROM owned_vehicles WHERE stored = 1 AND plate = @plate", {
		["@plate"] = plate,
	})

	if not result then
		return false
	end

	return true
end

lib.callback.register("fr_garages:isCarParked", function(source, plate)
	return IsCarParked(plate)
end)

exports("IsCarParked", IsCarParked)

function SetOwner(playerId, plate, second)
	second = second or false

	local xPlayer = ESX.GetPlayerFromId(playerId)

	if not xPlayer then
		return false
	end

	local query = (not second and "UPDATE owned_vehicles SET owner = @identifier WHERE plate = @plate")
		or "UPDATE owned_vehicles SET second_owner = @identifier WHERE plate = @plate"

	local result = MySQL.update.await(query, {
		["@identifier"] = xPlayer.indentifier,
		["@plate"] = plate,
	})

	return result > 0 and true or false
end

exports("SetOwner", SetOwner)

RegisterNetEvent("fr_garages:takeOutVehicle", function(parking, plate)
	local _source = source

	local result = MySQL.single.await(
		"SELECT owner, second_owner, model, properties, slot FROM owned_vehicles WHERE plate = @plate",
		{ ["@plate"] = plate }
	)

	local xPlayer = ESX.GetPlayerFromId(_source)

	if result.owner ~= xPlayer.identifier and result.second_owner ~= xPlayer.identifier then
		return
	end

	TriggerClientEvent("fr_garages:RemoveVehicle", -1, parking, plate)

	MySQL.update.await("UPDATE owned_vehicles SET stored = 0, parking = null, slot = null WHERE plate = @plate", {
		["@plate"] = plate,
	})

	TriggerClientEvent(
		"fr_garages:tkVehicle",
		_source,
		{ model = result.model, coords = Config.Parkings[parking].parking_slots[result.slot], properties = result.properties }
	)
end)

RegisterNetEvent("fr_garages:parkVehicle", function(netId, plate, parking, slot, properties)
	local _source = source

	DeleteEntity(NetworkGetEntityFromNetworkId(netId))

	MySQL.update.await(
		"UPDATE owned_vehicles SET stored = 1, parking = @parking, slot = @slot, properties = @properties WHERE plate = @plate",
		{
			["@parking"] = parking,
			["@slot"] = slot,
			["@properties"] = json.encode(properties),
			["@plate"] = plate,
		}
	)

	local result = MySQL.single.await(
		"SELECT owner, second_owner, plate, model, properties, slot FROM owned_vehicles WHERE plate = @plate",
		{
			["@plate"] = plate,
		}
	)

	if not result then
		return
	end

	TriggerClientEvent("fr_garages:vehicleParked", -1, parking, slot, result)
end)

-- Givecar command

lib.addCommand("givecar", {
	help = "Gives player a car",
	params = {
		{
			name = "target",
			type = "playerId",
			help = "A player ID",
		},
		{
			name = "model",
			type = "string",
			help = "A car model",
		},
	},
	restricted = "group.admin",
}, function(source, args, raw)
	local properties = lib.callback.await("fr_garages:givecar", args.target, args.model)

	local xPlayer = ESX.GetPlayerFromId(args.target)

	MySQL.insert.await(
		"INSERT INTO owned_vehicles(owner, plate, model, properties) VALUES(@owner, @plate, @model, @properties)",
		{
			["@owner"] = xPlayer.identifier,
			["@plate"] = properties.plate,
			["@model"] = args.model,
			["@properties"] = json.encode(properties),
		}
	)
end)

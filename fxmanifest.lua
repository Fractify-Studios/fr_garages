fx_version("cerulean")
game("gta5")

author("Fractify Studio")
description("Immersive garages system")
version("1.0.2")

lua54("yes")

shared_scripts({
	"@ox_lib/init.lua",
	"@es_extended/imports.lua",
	"config.lua",
})

client_scripts({
	"client/**.lua",
})

server_scripts({
	"@oxmysql/lib/MySQL.lua",
	"server/**.lua",
})

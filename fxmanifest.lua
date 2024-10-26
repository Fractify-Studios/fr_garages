fx_version("cerulean")
game("gta5")

author("Fractify Studios <https://fractify.pl>")
description("An immersive garage system for FiveM")
version("1.0.3")

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

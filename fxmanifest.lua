fx_version 'cerulean'
game 'gta5'

name 'HTTP API Server'
author 'Dnzx'
description 'Sistema de API HTTP'
version '1.0.0'

dependencies {
    'oxmysql',
    'vrp'
}

server_scripts {
    'src/config.lua',
    'src/utils.lua',
    'src/controllers/PlayerController.lua',
    'src/controllers/ServerController.lua',
    'src/router.lua',
    'src/server.lua'
}

server_only 'yes'

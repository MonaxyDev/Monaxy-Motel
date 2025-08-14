fx_version 'cerulean'
lua54 'yes'
author 'MONAXY | https://github.com/MonaxyDev'
game 'gta5'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

dependency '/assetpacks'

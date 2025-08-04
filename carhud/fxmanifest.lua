fx_version 'cerulean'
game 'gta5'

author 'Pitrs'
description 'Car Hud ESX'
version '1.0.0'

lua54 'yes'


shared_scripts {
    '@ox_lib/init.lua',
    'cfg.lua'
}

client_scripts {
    'cl.lua'
}

server_scripts {
    'sv.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/carhud.js'
}

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'TuServidor'
description 'Sistema Integrado Throat Mic Pro + Corporate Elite'
version '6.0.0'

ui_page 'html/throatmic.html'

shared_scripts {
    '@es_extended/locale.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

files {
    'html/throatmic.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'es_extended',
    'pma-voice',
    'oxmysql'
}

escrow_ignore {
    'client.lua',
    'server.lua',
    'fxmanifest.lua'
}
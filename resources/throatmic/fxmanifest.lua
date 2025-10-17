
fx_version 'cerulean'
game 'gta5'

author 'TuServidor'
description 'Sistema Throat Mic Pro - Comunicación Táctica'
version '3.0.0'

ui_page 'html/throatmic.html'

client_scripts {
    'client.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server.lua'
}

files {
    'html/throatmic.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'es_extended',
    'pma-voice'
}
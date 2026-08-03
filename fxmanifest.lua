fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'DrSnyder'
description 'Modern vehicle touchscreen control panel & keyfob'
version '1.0.0'

shared_scripts {
    'config.lua',
    'locales/*.lua'
}
client_script 'client/main.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/img/classes/*.png',
    'html/img/fob_frames/*.png',
    'html/img/icons/*.png'
}

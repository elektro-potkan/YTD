@echo off
if exist locale\default.~pot del locale\default.~pot
if exist locale\default.pot move locale\default.pot locale\default.~pot
dxgettext.exe *.pas *.dpr *.inc *.xfm *.dfm -r -o locale
move locale\default.po locale\default.pot

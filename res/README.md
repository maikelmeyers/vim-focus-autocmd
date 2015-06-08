Resources
==============


urxvt
-----
Add to your ```~/.Xresources``` to activate plugin:
```
URxvt*perl-ext-common: …,focus-events
```
Then do
```
xrdb ~/.Xresources          # To refresh urxvt config for new instances
cd vim-focus-autocmd/res/   # Launch from this dir (not necessary)
./setup                     # Install symlink for plugin in ~/.urxvt/ext/
```
